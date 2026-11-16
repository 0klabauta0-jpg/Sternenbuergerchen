extends "res://scripts/tests/campaign_casualty_roster_verifier.gd"
## Ein auf Polisa angeworbener, lebender Rekrut darf das Speichern an der Heimatbasis nicht blockieren.
## Die Kampagnen-Heimkarte ist eine Hex-Karte: die Basis-Personalliste liegt im Stand unter hex_tactical, nicht als Top-Level-base_personnel.
## Der Rekrut entsteht ueber die Besitzer-Operationen des Anwerbewegs und durchlaeuft die Zustaende des Spiels:
## station (Resident auf Polisa, Schiff steht an der Heimatbasis) -> aboard (am Heim-Pad) -> outside (nach base_unboard auf der Heimkarte).
## R1: station.   R2: aboard.   R3: outside.   R4: Gegenproben an der Payload und am Besitzer (Resident mit Schiff) mit dem genauen Ablehnungsgrund.
## R5: Gegenprobe am Besitzer: Resident auf Polisa mit Heimzelle.
## Je Zustand: Stand gueltig, save_home_checkpoint, request_campaign_save, Laden, Fortsetzen (continue), gleicher Status, zweites Speichern.
##
## LUECKEN (kein oeffentlicher Weg im kopflosen Test, daher private Aufrufe oder Attrappen; jede Stelle ist hier genannt):
## 1. Die Stationsmission (Globus, Anwerber am Globus, request_polisa_recruit_admission) wird nicht aufgebaut. Statt
##    request_operation("station_recruit_hire") laufen _polisa_market.open/quote, _commit(station_recruit_reserve) und
##    _commit(station_recruit_finalize) direkt am Adapter (private Methode _commit); das recruit_verify ist eine Attrappe, die ok liefert.
## 2. Credits: Es gibt keine oeffentliche Gutschrift ausserhalb eines bestaetigten Auftragsabschlusses; der Test nimmt das guenstigste
##    Angebot, das das Startguthaben deckt, und schreibt keine Credits. Reicht das Startguthaben nicht, schlaegt der Aufbau laut fehl.
## 3. station -> aboard: Aufnahme in die Nutzlast-Truppe des Schiffs (register_campaign_recruit mit payload_craft_id; "assign" lehnt einen
##    Resident mit unit_busy ab) und base.mark_recruit_remote(unit, craft)
##    (oeffentlicher Besitzer-Aufruf des Abholpfads) statt bind_confirmed_polisa_player_boarding plus _restore_returning_visit_membership,
##    die eine echte Polisa-Mission mit Besuchskennung brauchen. Ohne Truppe im Schiff lehnt der Hex-Export "aboard" mit
##    base_checkpoint_aboard_context ab (gewollt: strenge Mitgliedschaft); ob das Spiel bei der Rueckkehr immer eine Truppe herstellt, ist nicht gefahren.
## 4. aboard -> outside: request_operation("base_unboard") am Heim-Pad (oeffentlich); die Ankunft ueber den Stationsshuttle
##    (admit_polisa_shuttle_home) braucht Shuttle und Quittungen und wird nicht gefahren.
## 5. station_claim_resident selbst braucht die Polisa-Mission und wird nicht gefahren; nach dem Fortsetzen wird nur belegt, dass die
##    Person weiter Resident (Status station, keine Heimzelle) ist.
## 6. Der echte Flug Polisa -> Heimatbasis wird nicht gefahren: das Schiff steht von Anfang an an der Heimatbasis (Zustand "Schiff zu Hause,
##    Resident auf Polisa" ueber die Besitzer-Operationen). Belegt wird, dass die Nutzlastpruefung des Abflugs den Residenten nicht kennt.
## 7. Private Feldleser und -schreiber ohne oeffentlichen Weg: _flow._aircraft_location_by_craft, _flow._homebase_aircraft_definitions,
##    _flow._all_team_units, _flow._campaign_start, _flow._singleplayer_runtime, _runtime._polisa_market, _runtime._supply, _runtime._simulation und die Hex-Zelle
##    (_simulation.get_hex_unit_state, oeffentlich, aber der Test greift ueber _runtime auf die Simulation zu). R4/R5 setzen fuer die
##    Gegenproben am Besitzer craft_id/status im Zustandsspeicher der Basis (base._states) und stellen ihn danach wieder her.

func _run() -> void:
	_configure_entry()
	for scenario: String in ["R1", "R2", "R3", "R4", "R5"]:
		print("--- ", scenario)
		await call("_rc_" + scenario.to_lower())
		await _end_sortie()
	print("CAMPAIGN_RECRUIT_CHECKPOINT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _rc_status(unit_id: String) -> String:
	# export_state (oeffentlich) nennt station/aboard/outside; get_snapshot meldet beides als "away".
	var base: Node = _t6b_base()
	if base == null:
		return "<keine Basis>"
	var units: Dictionary = Dictionary(base.call("export_state")).get("units", {})
	return String(Dictionary(units.get(unit_id, {})).get("status", "<nicht in der Liste>"))

func _rc_craft_id() -> String:
	return String(Dictionary(Array(_flow.get("_homebase_aircraft_definitions"))[0]).get("craft_id", ""))

## Kampagnenstart, dann Anwerbung: Resident auf Polisa (Status station). Rueckgabe: unit_id oder "".
func _rc_hire(with_squad: bool = false) -> String:
	if not await _t6b_open("campaign", "new"):
		return ""
	if with_squad and not await _prepare_initial_base():
		return ""  # echtes Einsteigen der Startbesatzung (Nutzlast-Truppe geladen), wie campaign_recruit_transport_verifier
	var leader: Dictionary = _roster_unit(LEAD_A)
	var occupied := {}
	for profile: Dictionary in Array(_flow.get("_all_team_units")):
		occupied[String(profile.get("portrait_id", ""))] = true
	var market: RefCounted = _runtime.get("_polisa_market")
	var opened: Dictionary = market.call("open", "campaign:0", leader, occupied)
	if not _check(bool(opened.get("ok", false)) and not Array(opened.get("offers", [])).is_empty(), "Anwerbung: Markt oeffnet mit Angeboten (%s)" % [opened.get("reason", "")]):
		return ""
	var credits: int = int(_runtime.call("get_campaign_credits"))
	var offer: Dictionary = {}
	for candidate: Dictionary in Array(opened.offers):
		var price: int = int(candidate.get("price", 0))
		if price <= credits and (offer.is_empty() or price < int(offer.get("price", 0))):
			offer = candidate
	if not _check(not offer.is_empty(), "Anwerbung: ein Angebot ist mit dem Startguthaben (%d) bezahlbar" % credits):
		return ""
	var reservation_id: String = "polisa-hire:" + String(offer.id)
	var context := {"location_id": "polisa", "station_service_verified": true, "recruit_quote": Callable(market, "quote")}
	var reserved: Dictionary = _runtime.call("_commit", "singleplayer_supply", "station_recruit_reserve", {"offer_id": offer.id}, reservation_id, context)
	if not _check(bool(reserved.get("ok", false)), "Anwerbung: Reservierung gelingt (%s)" % [reserved]):
		return ""
	var hired: Dictionary = Dictionary(market.call("quote", String(offer.id)).get("profile", offer.get("profile", {}))).duplicate(true)
	var unit_id := String(offer.id)
	hired["recruit_location"] = "polisa"
	# with_squad: Aufnahme in die Nutzlast-Truppe des Heimschiffs (payload_craft_id), so wie die Abholung einen Rekruten ins Schiff legt.
	var registered: Dictionary = _flow.call("register_campaign_recruit", hired, {}, _rc_craft_id() if with_squad else "")
	if not _check(bool(registered.get("ok", false)), "Anwerbung: Rekrut kommt in den Kader (%s)" % [registered]):
		return ""
	var supply: RefCounted = _runtime.get("_supply")
	supply.call("configure_inventory", [unit_id], [], true)
	var simulation: Node = _runtime.get("_simulation")
	simulation.call("request_personnel_loadout_command", "configure_roster", {"roster": [hired]})
	simulation.call("request_personnel_loadout_command", "set_loadout", {"unit_id": unit_id, "loadout": {"armor": hired.get("armor", "suit"), "weapon_1": hired.get("weapon_1", "pistol"), "weapon_2": hired.get("weapon_2", "none")}})
	var verify := func(_id: String, _reservation: String) -> Dictionary: return {"ok": true}
	var finalized: Dictionary = _runtime.call("_commit", "singleplayer_supply", "station_recruit_finalize", {"reservation_id": reservation_id}, "final:" + reservation_id, {"recruit_verify": verify})
	if not _check(bool(finalized.get("ok", false)), "Anwerbung: Finalize gelingt (%s)" % [finalized]):
		return ""
	_check(_rc_status(unit_id) == "station", "Anwerbung: Rekrut steht auf Polisa (Status %s)" % _rc_status(unit_id))
	return unit_id

## Speichern, Laden, Fortsetzen, zweites Speichern; der Status des Rekruten bleibt gleich.
func _rc_cycle(unit_id: String, label: String, expected_status: String) -> void:
	_check(bool(_runtime.get("_simulation").call("is_hex_ground_runtime_required")), "%s: die Heimkarte der Kampagne ist eine Hex-Karte" % label)
	_check(_t6b_roster_ids().has(unit_id) and _t6b_base_ids().has(unit_id) and _rc_status(unit_id) == expected_status, "%s: Rekrut ist im Kader und in der Personalliste, Status %s (ist %s)" % [label, expected_status, _rc_status(unit_id)])
	var payload: Dictionary = _t6b_payload()
	if not _check(not payload.is_empty(), "%s: Stand laesst sich erfassen (Hex-Export: %s)" % [label, Dictionary(_runtime.get("_simulation").call("export_hex_checkpoint_state")).get("reason", "ok")]): return
	_check(payload.has("hex_tactical") and not payload.has("base_personnel") and Dictionary(payload.hex_tactical.base_personnel.units[unit_id]).get("status") == expected_status, "%s: Stand traegt die Personalliste unter hex_tactical, Status %s" % [label, expected_status])
	var verdict: Dictionary = STORE_6B.validate_payload(payload)
	_check(bool(verdict.get("ok", false)), "%s: validate_payload ist ok (%s)" % [label, verdict])
	var saved: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime, true)
	_check(bool(saved.get("ok", false)), "%s: save_home_checkpoint gelingt (%s)" % [label, String(saved.get("reason", "ok"))])
	var manual: Dictionary = _flow.call("request_campaign_save")
	_check(bool(manual.get("ok", false)), "%s: request_campaign_save gelingt (%s)" % [label, String(manual.get("reason", "ok"))])
	var loaded: Dictionary = STORE_6B.load_checkpoint()
	_check(bool(loaded.get("ok", false)) and JSON.stringify(Dictionary(loaded.get("payload", {})).get("roster", [])).contains(unit_id), "%s: Datei laesst sich laden und nennt den Rekruten (%s)" % [label, loaded.get("reason", "ok")])
	_flow.queue_free()
	await process_frame
	START.request_start(self, "campaign", "continue")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	_check(_t6b_roster_ids().has(unit_id) and _t6b_base_ids().has(unit_id) and _rc_status(unit_id) == expected_status, "%s: nach dem Fortsetzen ist der Rekrut im Kader und in der Personalliste, Status %s (ist %s; Kader %s)" % [label, expected_status, _rc_status(unit_id), _t6b_roster_ids()])
	var second: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime, true)
	_check(bool(second.get("ok", false)), "%s: zweites Speichern gelingt (%s)" % [label, String(second.get("reason", "ok"))])

func _rc_r1() -> void:
	var unit_id: String = await _rc_hire()
	if unit_id.is_empty(): return
	var craft_id := _rc_craft_id()
	var location: String = String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id, ""))
	_check(location in ["homebase", "waiting_pad"], "R1: das Schiff steht an der Heimatbasis (%s)" % location)
	# Adapter validate_space_launch (crew_not_aboard) fragt nur get_payload_presence(craft) ab (singleplayer_runtime_adapter.gd), also die dem Schiff zugewiesene Nutzlast.
	# Ohne Truppe im Schiff (R1 ohne with_squad) ist die Nutzlast leer; zaehlt der Resident dort mit, waere member_count > 0.
	var presence: Dictionary = _t6b_base().get_payload_presence(craft_id)
	_check(int(presence.get("member_count", -1)) == 0 and int(presence.get("aboard_count", -1)) == 0, "R1: die dem Schiff zugewiesene Nutzlast ist leer (member_count 0, aboard_count 0); die Abflugpruefung sieht dort niemanden (%s)" % [presence])
	_check(_runtime.get("_simulation").call("get_hex_unit_state", unit_id).is_empty(), "R1: der Resident hat keine Zelle auf der Heimkarte")
	await _rc_cycle(unit_id, "R1", "station")
	_check(_runtime.get("_simulation").call("get_hex_unit_state", unit_id).is_empty() and bool(_t6b_base().call("has_station_recruits")), "R1: nach dem Fortsetzen: weiter ohne Heimzelle und weiter Resident auf Polisa")

func _rc_r2() -> void:
	var unit_id: String = await _rc_hire(true)
	if unit_id.is_empty(): return
	var craft_id := _rc_craft_id()
	var squad: Dictionary = _board_with_squad(unit_id, craft_id)
	if not _check(bool(squad.get("ok", false)), "R2: Rekrut ist in der Nutzlast-Truppe und an Bord des Heimschiffs (%s)" % [squad]): return
	await _rc_cycle(unit_id, "R2", "aboard")

## Zustand "an Bord am Heim-Pad": Truppe der Schiffsnutzlast (wie _restore_returning_visit_membership sie bei der Rueckkehr herstellt) und Bindung an Bord.
func _board_with_squad(unit_id: String, craft_id: String) -> Dictionary:
	var boarded: Dictionary = _t6b_base().call("mark_recruit_remote", unit_id, craft_id)
	return boarded if bool(boarded.get("ok", false)) else {"ok": false, "step": "board", "result": boarded}

func _rc_r3() -> void:
	var unit_id: String = await _rc_hire(true)
	if unit_id.is_empty(): return
	var craft_id := _rc_craft_id()
	var boarded: Dictionary = _board_with_squad(unit_id, craft_id)
	if not _check(bool(boarded.get("ok", false)), "R3: Rekrut geht an Bord (%s)" % [boarded]): return
	var out: Dictionary = _t6b_base().call("request_operation", "base_unboard", {"unit_id": unit_id, "craft_id": craft_id})
	print("RC_UNBOARD ", out)
	for _i in range(120):
		await process_frame
		if _rc_status(unit_id) == "outside": break
	if not _check(_rc_status(unit_id) == "outside", "R3: Rekrut steigt an der Heimatbasis aus (Status %s, %s)" % [_rc_status(unit_id), out]): return
	await _rc_cycle(unit_id, "R3", "outside")

func _rc_r4() -> void:
	var unit_id: String = await _rc_hire()
	if unit_id.is_empty(): return
	var payload: Dictionary = _t6b_payload()
	if not _check(not payload.is_empty() and bool(STORE_6B.validate_payload(payload).get("ok", false)), "R4: Ausgangsstand (Resident auf Polisa) ist gueltig (%s)" % [STORE_6B.validate_payload(payload)]): return
	var cases: Array = []
	var without_recruit: Dictionary = payload.duplicate(true)
	Dictionary(without_recruit.hex_tactical.base_personnel.units).erase(unit_id)
	cases.append(["Rekrut aus der Personalliste im Hex-Stand entfernt", without_recruit, "invalid_hex_checkpoint_roster"])
	var no_list: Dictionary = payload.duplicate(true)
	Dictionary(no_list.hex_tactical).erase("base_personnel")
	cases.append(["Personalliste aus hex_tactical entfernt (Formfehler)", no_list, "invalid_hex_checkpoint"])
	var bare: Dictionary = payload.duplicate(true)
	bare.erase("hex_tactical")
	cases.append(["gar keine Personalliste (weder hex_tactical noch base_personnel)", bare, "checkpoint_recruit_presence_missing"])
	var mirrored: Dictionary = payload.duplicate(true)
	mirrored["base_personnel"] = payload.hex_tactical.base_personnel.duplicate(true)
	cases.append(["Top-Level-base_personnel in einem Hex-Stand", mirrored, "invalid_hex_checkpoint_mirror"])
	var foreign: Dictionary = payload.duplicate(true)
	foreign.hex_tactical.base_personnel.units[PILOT_ID]["status"] = "station"
	cases.append(["Status station bei einer Person, die kein Polisa-Rekrut ist", foreign, "invalid_station_personnel"])
	var with_craft: Dictionary = payload.duplicate(true)
	with_craft.hex_tactical.base_personnel.units[unit_id]["craft_id"] = _rc_craft_id()
	cases.append(["Resident auf Polisa mit craft_id", with_craft, "invalid_station_personnel"])
	var with_bed: Dictionary = payload.duplicate(true)
	with_bed.hex_tactical.base_personnel.units[unit_id]["bed_id"] = "bed_1"
	cases.append(["Resident auf Polisa mit bed_id", with_bed, "invalid_station_personnel"])
	for entry: Array in cases:
		var verdict: Dictionary = STORE_6B.validate_payload(entry[1])
		_check(not bool(verdict.get("ok", false)) and String(verdict.get("reason", "")) == String(entry[2]), "R4: %s: abgelehnt mit %s (ist %s)" % [entry[0], entry[2], verdict.get("reason", "ok")])
	# Gegenprobe am Besitzer: ein Resident auf Polisa, dem ein Schiff zugeschrieben ist, wird vom Basis-Export abgelehnt.
	var base: Node = _t6b_base()
	var unit_state: Dictionary = Dictionary(base.get("_states")).get(unit_id, {})
	if not _check(not unit_state.is_empty() and bool(Dictionary(base.call("export_checkpoint_state")).get("version", 0) == 2), "R4: Ausgangsstand der Basis (Resident auf Polisa) laesst sich exportieren"): return
	unit_state["craft_id"] = _rc_craft_id()
	var with_ship: Dictionary = base.call("export_checkpoint_state")
	unit_state["craft_id"] = ""
	_check(not bool(with_ship.get("ok", true)) and String(with_ship.get("reason", "")) == "base_checkpoint_station_context", "R4: Resident auf Polisa mit craft_id: abgelehnt mit base_checkpoint_station_context (ist %s)" % [with_ship.get("reason", "ok")])
	_check(Dictionary(base.call("export_checkpoint_state")).get("version", 0) == 2, "R4: nach der Gegenprobe ist der Basis-Export wieder gueltig")

## Gegenprobe am Besitzer: ein Resident auf Polisa, der zugleich eine Zelle auf der Heimkarte hat, wird abgelehnt.
func _rc_r5() -> void:
	var unit_id: String = await _rc_hire(true)
	if unit_id.is_empty(): return
	var craft_id := _rc_craft_id()
	var boarded: Dictionary = _board_with_squad(unit_id, craft_id)
	if not _check(bool(boarded.get("ok", false)), "R5: Rekrut geht an Bord (%s)" % [boarded]): return
	var out: Dictionary = _t6b_base().call("request_operation", "base_unboard", {"unit_id": unit_id, "craft_id": craft_id})
	for _i in range(120):
		await process_frame
		if _rc_status(unit_id) == "outside": break
	if not _check(_rc_status(unit_id) == "outside" and not _runtime.get("_simulation").call("get_hex_unit_state", unit_id).is_empty(), "R5: Rekrut steht draussen und hat eine Heimzelle (Status %s, %s)" % [_rc_status(unit_id), out]): return
	var base: Node = _t6b_base()
	var unit_state: Dictionary = Dictionary(base.get("_states")).get(unit_id, {})
	if not _check(not unit_state.is_empty() and Dictionary(base.call("export_checkpoint_state")).get("version", 0) == 2, "R5: Ausgangsstand (draussen) laesst sich exportieren"): return
	unit_state["status"] = "station"
	var with_cell: Dictionary = base.call("export_checkpoint_state")
	unit_state["status"] = "outside"
	_check(not bool(with_cell.get("ok", true)) and String(with_cell.get("reason", "")) == "base_checkpoint_station_context", "R5: Resident auf Polisa mit Heimzelle: abgelehnt mit base_checkpoint_station_context (ist %s)" % [with_cell.get("reason", "ok")])
	_check(Dictionary(base.call("export_checkpoint_state")).get("version", 0) == 2, "R5: nach der Gegenprobe ist der Basis-Export wieder gueltig")
