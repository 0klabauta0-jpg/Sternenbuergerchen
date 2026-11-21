extends "res://scripts/tests/campaign_respawn_apply_verifier.gd"
## R4a Respawn (Platz und Ausruestung): Wer mit Respawn stirbt, verliert Trupp, Einsatzauswahl, Rucksack und eigenes Loadout
## wie ein Gefallener, bleibt aber im Kader (Status, Position, respawns_used) und als Darsteller auf station.
## Echte Meta-Szene mit vier Personen (A Truppfuehrer Platz 0, Pilot Platz 1, B Truppfuehrer in ft1 mit A, C Schuetze allein in ft2).
## G1 B stirbt: weg aus Trupp und Ausruestung, Kader bleibt; W4: A schifft mit dem Trupp ein, Abflugsperre leer   G2 C stirbt: ft2 aufgeloest, Rucksack weg, Auftragsfracht im Lager (W5)
## G3 geschuetzter Pilot: behaelt Trupp, Zuteilung, Ausruestung   G4 Grenze 0: wie bisher   G5 Heimatbasis: Speichern und Fortsetzen mit Wartenden (respawning, awaiting_pickup)
## G6 park_pickup_person: scheitert die Freigabe vom Hex-Boden, bleibt der alte Zustand der Person stehen
## Hinweis: Speichern im Einsatz mit Wartenden wird abgelehnt (bekannter Mangel W7); kein Test hier stuetzt sich darauf.
## Prueft Ausruestung ueber export_state und den Loadout-Bestand (get_snapshot), nicht ueber get_loadout (das faellt auf Standards zurueck).
## Abschlusszeile: CAMPAIGN_RESPAWN_GEAR passed=%d failed=%d
## Einzeln starten: Kommandozeilenargument nach "--" (zum Beispiel "-- G1").

const GEAR_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const RESPAWN_KEEPS := ["roster", "base_personnel", "base runtime", "flow._available_team_units"]

func _run() -> void:
	var verdict: Dictionary = GEAR_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_RESPAWN_GEAR refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	_configure_entry()
	var selected: Array = []
	for arg: String in OS.get_cmdline_user_args():
		if not arg.strip_edges().is_empty():
			selected.append(arg.strip_edges().to_upper())
	for scenario: String in ["G1", "G2", "G3", "G4", "G5", "G6"]:
		if not selected.is_empty() and not selected.has(scenario):
			continue
		print("--- ", scenario)
		await call("_rg_" + scenario.to_lower())
		await _end_sortie()
	print("CAMPAIGN_RESPAWN_GEAR passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

## Stellen, an denen die Person haengt und die nicht zu den erlaubten gehoeren.
func _rg_stray(unit_id: String, allowed: Array) -> Array:
	return _t6b_where(_t6b_payload(), unit_id).filter(func(place: String) -> bool: return not allowed.has(place))

func _rg_inventory() -> Dictionary:
	return Dictionary(Dictionary(_runtime.get("_supply").call("export_state")).get("inventory", {}))

func _rg_loadouts() -> Dictionary:
	return Dictionary(_runtime.get("_simulation").call("get_personnel_loadout_state").call("get_snapshot"))

func _rg_team_members(team_id: String) -> Array:
	for team: Dictionary in Array(Dictionary(_screen.call("get_operations_snapshot")).get("fireteams", [])):
		if String(team.get("id", "")) == team_id:
			return Array(team.get("members", [])).map(func(member: Variant) -> String: return String(Dictionary(member).get("id", "")) if typeof(member) == TYPE_DICTIONARY else String(member))
	return []

func _rg_team_ids() -> Array:
	return Array(Dictionary(_screen.call("get_operations_snapshot")).get("fireteams", [])).map(func(team: Dictionary) -> String: return String(team.get("id", "")))

func _rg_g1() -> void:
	if not await _t6b_new_four(): return
	var fixture_places: Array = _t6b_where(_t6b_payload(), LEAD_B)
	_check(fixture_places.any(func(place: String) -> bool: return place.begins_with("fireteam ")) and fixture_places.has("supply.inventory") and fixture_places.has("loadout state"), "G1: Fixture: B steht in einem Trupp und hat Rucksack und Loadout (%s)" % [fixture_places])
	var roster_before: Array = _t6b_roster_ids()
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", _ra_result(_t6b_states({LEAD_B: "down"}), "aborted", 3))
	_check(PackedStringArray(applied.get("respawn_unit_ids", PackedStringArray())) == PackedStringArray([LEAD_B]), "G1: B ist Wiederkehrer")
	var b: Dictionary = _roster_unit(LEAD_B)
	_check(String(b.get("availability_status", "")) == "respawning" and int(b.get("respawns_used", -1)) == 1 and _t6b_roster_ids() == roster_before, "G1: B bleibt im Kader, gleiche Reihenfolge, respawning, respawns_used 1")
	_check(_ra_base_status(LEAD_B) == "station" and _t6b_base().call("get_actor", LEAD_B) != null, "G1: B steht als Darsteller auf station")
	var stray: Array = _rg_stray(LEAD_B, RESPAWN_KEEPS)
	_check(stray.is_empty(), "G1: B haengt nur noch an Kader und Basis, nicht an Trupp, Auswahl, Schiff, Rucksack, Loadout (uebrig: %s)" % [stray])
	_check(not _rg_inventory().has("unit:%s:backpack" % LEAD_B) and not _rg_loadouts().has(LEAD_B), "G1: Rucksack und eigenes Loadout von B sind weg (Container-Bestand und Loadout-Snapshot)")
	_check(not _rg_team_members(_team_id).has(LEAD_B) and _rg_team_members(_team_id).has(LEAD_A), "G1: der Trupp besteht ohne B weiter mit A (%s)" % [_rg_team_members(_team_id)])
	# W4: A laesst sich mit dem Trupp einschiffen, der Abflug ist nicht gesperrt.
	_craft_id = String(Dictionary(Array(_flow.get("_homebase_aircraft_definitions"))[0]).get("craft_id", ""))
	var team_board: Dictionary = _screen.call("request_operation", "board", {"craft_id": _craft_id, "fireteam_id": _team_id})
	_check(bool(team_board.get("ok", false)), "G1 (W4): der Trupp wird dem Schiff zugeteilt (%s)" % [team_board])
	var walk: Dictionary = _screen.call("request_operation", "base_board", {"craft_id": _craft_id, "fireteam_id": _team_id, "whole_fireteam": true})
	_check(bool(walk.get("ok", false)), "G1 (W4): der Trupp geht an Bord (%s)" % [walk])
	_check(await _wait(func(): return _ra_base_status(LEAD_A) == "aboard", 60000, "G1 (W4): A ist an Bord"), "G1 (W4): A steht aboard")
	var block: Dictionary = _t6b_base().call("get_departure_block", _craft_id)
	_check(block.is_empty(), "G1 (W4): Abflugsperre ist leer (%s)" % [block])
	_check(_ra_base_status(LEAD_B) == "station", "G1 (W4): B bleibt auf station und fliegt nicht mit")

func _rg_g2() -> void:
	if not await _t6b_new_four(): return
	var supply: RefCounted = _runtime.get("_supply")
	Dictionary(Dictionary(supply.get("_inventory"))["unit:%s:backpack" % SHOOTER_C]["items"])["satellite_chip"] = 1
	var before_ids: Array = _rg_team_ids()
	var payload_before: Dictionary = _t6b_payload()
	var team_c: String = String(_t6b_team_ids(payload_before)[-1])
	_check(Array(_t6b_team(payload_before, team_c).get("member_unit_ids", [])) == [SHOOTER_C], "G2: Fixture: der zweite Trupp besteht nur aus C")
	_flow.call("_apply_campaign_casualties", _ra_result(_t6b_states({SHOOTER_C: "down"}), "aborted", 3))
	_check(String(_roster_unit(SHOOTER_C).get("availability_status", "")) == "respawning" and _t6b_roster_ids() == [LEAD_A, PILOT_ID, LEAD_B, SHOOTER_C], "G2: C ist respawning, Kader unveraendert")
	var stray: Array = _rg_stray(SHOOTER_C, RESPAWN_KEEPS)
	_check(stray.is_empty(), "G2: C haengt nur noch an Kader und Basis (uebrig: %s)" % [stray])
	_check(not _rg_team_ids().has(team_c) and _rg_team_ids().size() == before_ids.size() - 1, "G2: der leer gewordene Trupp von C ist aufgeloest (%s)" % [_rg_team_ids()])
	var exported: Dictionary = Dictionary(supply.call("export_state"))
	var quantities: Dictionary = Dictionary(exported.get("item_quantities", {}))
	_check(not Dictionary(exported.get("inventory", {})).has("unit:%s:backpack" % SHOOTER_C) and not _rg_loadouts().has(SHOOTER_C), "G2 (W5): Rucksack und Loadout von C sind weg")
	_check(int(quantities.get("satellite_chip", 0)) == 1 and not quantities.has("mining_tool"), "G2: Auftragsfracht im Basislager, der uebrige Rucksackinhalt verloren (%s)" % [quantities])

func _rg_g3() -> void:
	if not await _t6b_new_four(): return
	var before: Array = _t6b_where(_t6b_payload(), PILOT_ID)
	var loadout_before: bool = _rg_loadouts().has(PILOT_ID)
	var inventory_before: bool = _rg_inventory().has("unit:%s:backpack" % PILOT_ID)
	var result: Dictionary = _ra_result(_t6b_states({}), "aborted", 3)
	result["respawn_unit_ids"] = PackedStringArray([PILOT_ID])
	result["casualties"] = [{"unit_id": PILOT_ID, "outcome": "dead", "final": false, "death_number": 1, "respawn_state": {"state": "respawning", "death_number": 1, "seconds_total": 3600, "seconds_remaining": 3600, "pickup_location_id": "polisa", "source": "left_behind"}}]
	_flow.call("_apply_campaign_casualties", result)
	var after: Array = _t6b_where(_t6b_payload(), PILOT_ID)
	_check(String(_roster_unit(PILOT_ID).get("availability_status", "")) == "wounded", "G3: der geschuetzte Pilot ist verwundet statt respawning")
	_check(after == before and after.has("flow pilot assignment"), "G3: der Pilot behaelt alle Plaetze und die Pilotenzuteilung (vorher %s, nachher %s)" % [before, after])
	_check(_rg_loadouts().has(PILOT_ID) == loadout_before and _rg_inventory().has("unit:%s:backpack" % PILOT_ID) == inventory_before, "G3: der Pilot behaelt Loadout und Rucksack wie vorher (%s / %s)" % [loadout_before, inventory_before])

func _rg_g4() -> void:
	if not await _t6b_new_four(): return
	_flow.call("_apply_campaign_casualties", _ra_result(_t6b_states({SHOOTER_C: "down"}), "aborted", 0))
	_check(_t6b_roster_ids() == [LEAD_A, PILOT_ID, LEAD_B] and not _ra_fallen(SHOOTER_C).is_empty(), "G4: Grenze 0: C ist aus dem Kader und steht in der Gefallenenliste")
	var stray: Array = _rg_stray(SHOOTER_C, [])
	_check(stray.is_empty() and not _rg_inventory().has("unit:%s:backpack" % SHOOTER_C) and not _rg_loadouts().has(SHOOTER_C), "G4: Grenze 0: C ist ueberall weg (uebrig: %s)" % [stray])
	_check(_flow.call("_campaign_roster_problems", Array(_flow.get("_all_team_units"))).is_empty(), "G4: Kader bleibt spielbar")

## park_pickup_person (R3-Fix-Runde, W6): Scheitert die Freigabe vom Hex-Boden, bleibt der alte Zustand der Person stehen.
## Der Fehlschlag wird erzwungen, indem der Darsteller von C zum Loeschen vorgemerkt wird (Freigabe: base_actor_unbound).
func _rg_g6() -> void:
	if not await _t6b_new_four(): return
	var base: Node = _t6b_base()
	var hex_required: bool = bool(base.call("_requires_hex_ground"))
	print("RG_G6 requires_hex_ground=", hex_required)
	if not _check(hex_required, "G6: Fixture: die Basis laeuft auf dem Hex-Boden (sonst gibt es keine Freigabe, die scheitern kann)"): return
	var actor: Node = base.call("get_actor", SHOOTER_C)
	if not _check(actor != null, "G6: Fixture: C hat einen Darsteller"): return
	var before: Dictionary = Dictionary(base.get("_states"))[SHOOTER_C].duplicate(true)
	actor.queue_free()
	var parked: Dictionary = Dictionary(base.call("park_pickup_person", SHOOTER_C))
	var after: Dictionary = Dictionary(base.get("_states"))[SHOOTER_C].duplicate(true)
	print("RG_G6 parked=", parked, " before=", before, " after=", after)
	_check(not bool(parked.get("ok", true)), "G6: die Freigabe scheitert und park_pickup_person meldet es (%s)" % [parked])
	_check(JSON.stringify(after, "", true) == JSON.stringify(before, "", true), "G6: bei Fehlschlag steht der alte Zustand von C unveraendert da (vorher %s, nachher %s)" % [before, after])

## Heimatbasis: B respawning, C awaiting_pickup, beide ohne Rucksack und Trupp; Speichern und Fortsetzen.
func _rg_g5() -> void:
	if not await _t6b_new_four(): return
	var supply: RefCounted = _runtime.get("_supply")
	var bag_b: Dictionary = Dictionary(supply.get("_inventory"))["unit:%s:backpack" % LEAD_B]
	bag_b["capacity"] = 12
	Dictionary(bag_b["items"])["mining_tool"] = 1
	_flow.call("_apply_campaign_casualties", _ra_result(_t6b_states({LEAD_B: "down", SHOOTER_C: "down"}), "aborted", 3))
	_ra_set(SHOOTER_C, {"availability_status": "awaiting_pickup", "status_text": "awaiting_pickup", "recovery_state": {"state": "awaiting_pickup", "pickup_location_id": "polisa"}})
	_flow.call("_sync_wound_lock")
	var b_before: Dictionary = _roster_unit(LEAD_B).duplicate(true)
	var remaining_before: float = float(Dictionary(b_before.get("recovery_state", {})).get("seconds_remaining", -1.0))
	_check(String(b_before.get("availability_status", "")) == "respawning" and remaining_before > 0.0 and String(_roster_unit(SHOOTER_C).get("availability_status", "")) == "awaiting_pickup", "G5: Aufbau: B respawning mit Restzeit, C awaiting_pickup")
	_check(_rg_stray(LEAD_B, RESPAWN_KEEPS).is_empty() and _rg_stray(SHOOTER_C, RESPAWN_KEEPS).is_empty(), "G5: Aufbau: beide in keinem Trupp, ohne Rucksack")
	var saved: Dictionary = _flow.call("request_campaign_save")
	if not _check(bool(saved.get("ok", false)), "G5: Speichern an der Basis gelingt (%s)" % [saved.get("reason", "")]): return
	await _end_sortie()
	await create_timer(0.5).timeout
	if not await _t6b_open("campaign", "continue"): return
	var b: Dictionary = _roster_unit(LEAD_B)
	var c: Dictionary = _roster_unit(SHOOTER_C)
	var remaining_after: float = float(Dictionary(b.get("recovery_state", {})).get("seconds_remaining", -1.0))
	_check(String(b.get("availability_status", "")) == "respawning" and String(c.get("availability_status", "")) == "awaiting_pickup", "G5: nach dem Fortsetzen: B respawning, C awaiting_pickup")
	_check(remaining_after > 0.0 and remaining_after <= remaining_before and remaining_after > remaining_before - 120.0, "G5: Restzeit von B bleibt erhalten (%s -> %s)" % [remaining_before, remaining_after])
	_check(_ra_base_status(LEAD_B) == "station" and _ra_base_status(SHOOTER_C) == "station", "G5: beide stehen auf station")
	var stray_b: Array = _rg_stray(LEAD_B, RESPAWN_KEEPS + ["supply.inventory"])
	var stray_c: Array = _rg_stray(SHOOTER_C, RESPAWN_KEEPS + ["supply.inventory"])
	_check(stray_b.is_empty() and stray_c.is_empty(), "G5: beide in keinem Trupp, keiner Auswahl, nicht auf dem Schiff (%s / %s)" % [stray_b, stray_c])
	var bag: Dictionary = Dictionary(_rg_inventory().get("unit:%s:backpack" % LEAD_B, {}))
	var items: Dictionary = Dictionary(bag.get("items", {}))
	print("RG_G5_BACKPACK_B present=", _rg_inventory().has("unit:%s:backpack" % LEAD_B), " items=", items)
	_check(int(items.get("mining_tool", 0)) == 0, "G5: der fruehere Rucksackinhalt von B ist nicht zurueck (Rucksack leer neu angelegt: %s)" % [not bag.is_empty()])
	_check(bool(STORE_6B.validate_payload(_t6b_payload()).get("ok", false)), "G5: der neu gebaute Stand ist gueltig")
