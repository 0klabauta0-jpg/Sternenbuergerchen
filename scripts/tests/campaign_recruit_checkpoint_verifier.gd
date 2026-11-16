extends "res://scripts/tests/campaign_casualty_roster_verifier.gd"
## Ein auf Polisa angeworbener, lebender Rekrut darf das Speichern an der Heimatbasis nicht blockieren.
## Die Kampagnen-Heimkarte ist eine Hex-Karte: die Basis-Personalliste liegt im Stand unter hex_tactical, nicht als Top-Level-base_personnel.
## Der Rekrut entsteht ueber die Operationen des Anwerbewegs (Markt oeffnen, station_recruit_reserve, register_campaign_recruit,
## station_recruit_finalize mit echtem Beleg im Versorgungsstand); nur die Stationsmission (Globus, Aufnahme-Akteur) fehlt im kopflosen Test.
## R1: Rekrut noch auf Polisa (Status station).   R2: Rekrut an der Heimatbasis (Status outside).
## Je Fall: Stand gueltig, save_home_checkpoint, request_campaign_save, Laden, Fortsetzen, Rekrut da, zweites Speichern.
## R3: Gegenproben an der Payload.

func _run() -> void:
	_configure_entry()
	for scenario: String in ["R1", "R2", "R3"]:
		print("--- ", scenario)
		await call("_rc_" + scenario.to_lower())
		await _end_sortie()
	print("CAMPAIGN_RECRUIT_CHECKPOINT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

## Kampagnenstart, dann Anwerbung ueber die Besitzer-Operationen. at_station: Profil traegt recruit_location=polisa (so legt der Adapter es an).
func _rc_hire(at_station: bool) -> String:
	if not await _t6b_open("campaign", "new"):
		return ""
	var leader: Dictionary = _roster_unit(LEAD_A)
	var occupied := {}
	for profile: Dictionary in Array(_flow.get("_all_team_units")):
		occupied[String(profile.get("portrait_id", ""))] = true
	var market: RefCounted = _runtime.get("_polisa_market")
	var opened: Dictionary = market.call("open", "campaign:0", leader, occupied)
	if not _check(bool(opened.get("ok", false)) and not Array(opened.get("offers", [])).is_empty(), "Anwerbung: Markt oeffnet mit Angeboten (%s)" % [opened.get("reason", "")]):
		return ""
	var offer: Dictionary = opened.offers[0]
	var supply: RefCounted = _runtime.get("_supply")
	if int(supply.call("get_supply_snapshot").get("credits", 0)) < int(offer.get("price", 0)):
		supply.set("_credits", 5000)  # Nur Startguthaben fuer den Test; die Anwerbung selbst bucht der Besitzer.
	var reservation_id: String = "polisa-hire:" + String(offer.id)
	var context := {"location_id": "polisa", "station_service_verified": true, "recruit_quote": Callable(market, "quote")}
	var reserved: Dictionary = _runtime.call("_commit", "singleplayer_supply", "station_recruit_reserve", {"offer_id": offer.id}, reservation_id, context)
	if not _check(bool(reserved.get("ok", false)), "Anwerbung: Reservierung gelingt (%s)" % [reserved]):
		return ""
	var quote: Dictionary = market.call("quote", String(offer.id))
	var hired: Dictionary = Dictionary(quote.get("profile", offer.get("profile", {}))).duplicate(true)
	var unit_id := String(offer.id)
	if at_station:
		hired["recruit_location"] = "polisa"
	var registered: Dictionary = _flow.call("register_campaign_recruit", hired)
	if not _check(bool(registered.get("ok", false)), "Anwerbung: Rekrut kommt in den Kader (%s)" % [registered]):
		return ""
	supply.call("configure_inventory", [unit_id], [], true)
	var simulation: Node = _runtime.get("_simulation")
	simulation.call("request_personnel_loadout_command", "configure_roster", {"roster": [hired]})
	simulation.call("request_personnel_loadout_command", "set_loadout", {"unit_id": unit_id, "loadout": {"armor": hired.get("armor", "suit"), "weapon_1": hired.get("weapon_1", "pistol"), "weapon_2": hired.get("weapon_2", "none")}})
	var verify := func(_id: String, _reservation: String) -> Dictionary: return {"ok": true}
	var finalized: Dictionary = _runtime.call("_commit", "singleplayer_supply", "station_recruit_finalize", {"reservation_id": reservation_id}, "final:" + reservation_id, {"recruit_verify": verify})
	if not _check(bool(finalized.get("ok", false)), "Anwerbung: Finalize gelingt (%s)" % [finalized]):
		return ""
	_flow.set("_active_singleplayer_identity", {"job_id": JOB_6B, "location_id": LOCATION_6B, "craft_id": String(Dictionary(Array(_flow.get("_homebase_aircraft_definitions"))[0]).get("craft_id", ""))})
	_flow.call("_sync_wound_lock")
	var state: Dictionary = Dictionary(Dictionary(_t6b_base().get("_states")).get(unit_id, {}))
	print("RC_STATE ", unit_id, " status=", state.get("status", "<none>"), " at_station=", at_station)
	return unit_id

func _rc_cycle(unit_id: String, label: String) -> void:
	var hex_required: bool = bool(_runtime.get("_simulation").call("is_hex_ground_runtime_required"))
	_check(hex_required, "%s: die Heimkarte der Kampagne ist eine Hex-Karte" % label)
	_check(_t6b_roster_ids().has(unit_id) and _t6b_base_ids().has(unit_id), "%s: Rekrut ist im Kader und in der Personalliste" % label)
	var payload: Dictionary = _t6b_payload()
	if not _check(not payload.is_empty(), "%s: Stand laesst sich erfassen" % label): return
	_check(payload.has("hex_tactical") and not payload.has("base_personnel"), "%s: Stand traegt die Personalliste unter hex_tactical" % label)
	var verdict: Dictionary = STORE_6B.validate_payload(payload)
	_check(bool(verdict.get("ok", false)), "%s: validate_payload ist ok (%s)" % [label, verdict])
	var start: RefCounted = _flow.get("_campaign_start")
	var saved: Dictionary = start.call("save_home_checkpoint", _flow, _runtime, true)
	_check(bool(saved.get("ok", false)), "%s: save_home_checkpoint gelingt (%s)" % [label, saved])
	var manual: Dictionary = _flow.call("request_campaign_save")
	_check(bool(manual.get("ok", false)), "%s: request_campaign_save gelingt (%s)" % [label, manual])
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
	_check(_t6b_roster_ids().has(unit_id) and _t6b_base_ids().has(unit_id), "%s: nach dem Fortsetzen ist der Rekrut im Kader und in der Personalliste (%s / %s)" % [label, _t6b_roster_ids(), _t6b_base_ids()])
	var second: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime, true)
	_check(bool(second.get("ok", false)), "%s: zweites Speichern gelingt (%s)" % [label, second])

func _rc_r1() -> void:
	var unit_id: String = await _rc_hire(true)
	if unit_id.is_empty(): return
	_check(String(Dictionary(Dictionary(_t6b_base().get("_states")).get(unit_id, {})).get("status", "")) == "station", "R1: Rekrut steht auf Polisa (Status station)")
	# Gewollt: das Hex-Format der Basisliste kennt den Status station nicht (hex_base_boarding_verifier: "station personnel blocks incomplete
	# home checkpoint"). Ein Rekrut auf Polisa gehoert zu einem Schiff, das nicht an der Heimatbasis steht; ein Heimstand mit ihm ist im
	# Spiel nicht erreichbar. Hier nur: der Stand wird vom Basis-Besitzer abgelehnt, nicht erst vom Pruefer der Datei.
	var exported: Dictionary = _runtime.get("_simulation").call("export_hex_checkpoint_state")
	_check(not bool(exported.get("ok", false)) and String(exported.get("reason", "")) == "base_checkpoint_invalid_unit", "R1: Rekrut auf Polisa: der Hex-Besitzer lehnt den Heimstand ab (Grund %s)" % [exported.get("reason", "")])
	var guarded: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime, true)
	_check(not bool(guarded.get("ok", false)) and String(guarded.get("reason", "")) != "checkpoint_recruit_presence_missing", "R1: Speichern wird abgelehnt, aber nicht mit dem Grund der Dateipruefung (Grund %s)" % [guarded.get("reason", "")])

func _rc_r2() -> void:
	var unit_id: String = await _rc_hire(false)
	if unit_id.is_empty(): return
	_check(String(Dictionary(Dictionary(_t6b_base().get("_states")).get(unit_id, {})).get("status", "")) != "station", "R2: Rekrut ist an der Heimatbasis (Status nicht station)")
	await _rc_cycle(unit_id, "R2")

func _rc_r3() -> void:
	var unit_id: String = await _rc_hire(false)
	if unit_id.is_empty(): return
	var payload: Dictionary = _t6b_payload()
	if not _check(not payload.is_empty() and bool(STORE_6B.validate_payload(payload).get("ok", false)), "R3: Ausgangsstand ist gueltig (%s)" % [STORE_6B.validate_payload(payload)]): return
	var without_recruit: Dictionary = payload.duplicate(true)
	Dictionary(without_recruit.hex_tactical.base_personnel.units).erase(unit_id)
	var r_without: Dictionary = STORE_6B.validate_payload(without_recruit)
	_check(not bool(r_without.get("ok", false)), "R3: Rekrut aus der Personalliste im Hex-Stand entfernt: abgelehnt (Grund %s)" % [r_without.get("reason", "")])
	var no_list: Dictionary = payload.duplicate(true)
	Dictionary(no_list.hex_tactical).erase("base_personnel")
	var r_none: Dictionary = STORE_6B.validate_payload(no_list)
	_check(not bool(r_none.get("ok", false)), "R3: Personalliste ganz entfernt: abgelehnt (Grund %s)" % [r_none.get("reason", "")])
	# Ohne jede Personalliste (weder hex_tactical noch base_personnel) greift die Anwesenheitspruefung selbst.
	var bare: Dictionary = payload.duplicate(true)
	bare.erase("hex_tactical")
	_check(String(STORE_6B.validate_payload(bare).get("reason", "")) == "checkpoint_recruit_presence_missing", "R3: gar keine Personalliste: checkpoint_recruit_presence_missing (Grund %s)" % [STORE_6B.validate_payload(bare).get("reason", "")])
	var mirrored: Dictionary = payload.duplicate(true)
	mirrored["base_personnel"] = payload.hex_tactical.base_personnel.duplicate(true)
	var r_mirror: Dictionary = STORE_6B.validate_payload(mirrored)
	_check(String(r_mirror.get("reason", "")) == "invalid_hex_checkpoint_mirror", "R3: Top-Level-base_personnel in einem Hex-Stand bleibt abgelehnt (Grund %s)" % [r_mirror.get("reason", "")])
