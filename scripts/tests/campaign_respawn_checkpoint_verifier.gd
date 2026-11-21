extends "res://scripts/tests/campaign_casualty_recovery_flow_verifier.gd"
## R3b Respawn (Spielstand): respawns_used, die Zustaende respawning/awaiting_pickup und die neuen Felder der
## Gefallenenliste ueberstehen Speichern und Laden an der Basis. Der Gestorbene steht als "station" (unsichtbar) in der Basis.
## Pruefstellen: MetaUnitProfile.to_dict/_apply_dict, Adapter._clean_fallen_entry, CampaignCheckpointStore.validate_payload,
## BasePersonnelRuntime.park_pickup_person/sync_roster/Wiederherstellung.
## Abschlusszeile: CAMPAIGN_RESPAWN_CHECKPOINT passed=%d failed=%d

const CP_STORE := preload("res://scripts/meta/campaign_checkpoint_store.gd")
const UNIT_PROFILE := preload("res://scripts/meta/meta_unit_profile.gd")

func _run() -> void:
	_configure_entry()
	_profile_part()
	await _roundtrip("respawning")
	await _roundtrip("awaiting_pickup")
	await _fallen_part()
	await _store_negative()
	print("CAMPAIGN_RESPAWN_CHECKPOINT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _recovery_for(status: String) -> Dictionary:
	if status == "respawning":
		return {"state": "respawning", "death_number": 3, "seconds_total": 7200.0, "seconds_remaining": 6000.0, "pickup_location_id": "polisa", "source": "left_behind"}
	return {"state": "awaiting_pickup", "pickup_location_id": "polisa"}

func _make_dead(unit_id: String, status: String, used: int) -> void:
	var units: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	for unit: Dictionary in units:
		if String(unit.get("unit_id", "")) == unit_id:
			unit["respawns_used"] = used
			unit["availability_status"] = status
			unit["status_text"] = status
			unit["recovery_state"] = _recovery_for(status)
	_flow.call("_replace_roster_units", units)

func _base_status(unit_id: String) -> String:
	return String(Dictionary(Dictionary(_base().get("_states")).get(unit_id, {})).get("status", ""))

func _profile_part() -> void:
	var profile = UNIT_PROFILE.new({"unit_id": "p1", "display_name": "P", "respawns_used": 2})
	_check(int(profile.respawns_used) == 2 and int(profile.to_dict().get("respawns_used", -1)) == 2, "Profil: respawns_used 2 ueberlebt to_dict")
	var again = UNIT_PROFILE.new(profile.to_dict())
	_check(int(again.respawns_used) == 2, "Profil: Rundlauf to_dict -> neues Profil behaelt 2")
	_check(int(UNIT_PROFILE.new({"unit_id": "p2", "display_name": "P"}).respawns_used) == 0, "Profil: fehlender Zaehler = 0")
	for bad in ["2", null, [], true, -3, {}]:
		_check(int(UNIT_PROFILE.new({"unit_id": "p3", "display_name": "P", "respawns_used": bad}).respawns_used) == 0, "Profil: falscher Typ/negativ %s = 0" % [str(bad)])
	_check(int(UNIT_PROFILE.new({"unit_id": "p4", "display_name": "P", "respawns_used": 2.9}).respawns_used) == 2, "Profil: 2.9 wird abgeschnitten (2)")

func _roundtrip(status: String) -> void:
	if not await _open("campaign", "new"): return
	_make_dead(LEADER, status, 2)
	var parked: Dictionary = _base().call("park_pickup_person", LEADER)
	_check(bool(parked.get("ok", false)), "%s: park_pickup_person ok (%s)" % [status, parked])
	_feed()
	_check(_base_status(LEADER) == "station", "%s: Basis-Zustand ist station" % status)
	var actor: Node = _base().call("get_actor", LEADER)
	_check(actor != null and not bool(actor.get("visible")), "%s: Darsteller ist unsichtbar" % status)
	_check(String(_person(LEADER).get("status", "")) == "away", "%s: Schnappschuss meldet away (nicht ansprechbar)" % status)
	var board: Dictionary = _board_one(LEADER)
	_check(not bool(board.get("ok", true)) and String(board.get("reason", "")) in ["away_from_base", "unit_wounded"], "%s: Einschiffen abgelehnt (%s)" % [status, board])
	var again: Dictionary = _base().call("park_pickup_person", LEADER)
	_check(bool(again.get("ok", false)) and bool(again.get("unchanged", false)), "%s: zweites Parken aendert nichts" % status)
	var saved: Dictionary = _flow.call("request_campaign_save")
	if not _check(bool(saved.get("ok", false)), "%s: Speichern gelingt (%s)" % [status, saved]): return
	var loaded: Dictionary = CP_STORE.load_checkpoint()
	_check(bool(loaded.get("ok", false)) and bool(CP_STORE.validate_payload(Dictionary(loaded.get("payload", {}))).get("ok", false)), "%s: gespeicherter Stand besteht validate_payload (%s)" % [status, loaded.get("reason", "")])
	await _close()
	if not await _open("campaign", "continue"): return
	var unit: Dictionary = _roster_unit(LEADER)
	_check(String(unit.get("availability_status", "")) == status and int(unit.get("respawns_used", -1)) == 2, "%s: nach Laden: Zustand und respawns_used 2 (%s)" % [status, unit.get("availability_status", "")])
	var state_after: Dictionary = Dictionary(unit.get("recovery_state", {}))
	var state_before: Dictionary = _recovery_for(status)
	var same_state: bool = String(state_after.get("state", "")) == status and String(state_after.get("pickup_location_id", "")) == "polisa" and state_after.size() == state_before.size()
	if status == "respawning":
		same_state = same_state and int(state_after.get("death_number", -1)) == 3 and String(state_after.get("source", "")) == "left_behind" and absf(float(state_after.get("seconds_remaining", -1.0)) - 6000.0) <= 10.0 and absf(float(state_after.get("seconds_total", -1.0)) - 7200.0) < 0.01
	_check(same_state, "%s: nach Laden: recovery_state unveraendert (Zeit +-10 s Takt) (%s)" % [status, state_after])
	_check(_base_status(LEADER) == "station", "%s: nach Laden: Basis-Zustand station" % status)
	var loaded_actor: Node = _base().call("get_actor", LEADER)
	_check(loaded_actor != null and not bool(loaded_actor.get("visible")), "%s: nach Laden: Darsteller unsichtbar" % status)
	var lock: Dictionary = _lock()
	_check(lock.has(LEADER), "%s: nach Laden: Sperre gilt (%s)" % [status, lock])
	var board2: Dictionary = _board_one(LEADER)
	_check(not bool(board2.get("ok", true)) and String(board2.get("reason", "")) in ["away_from_base", "unit_wounded"], "%s: nach Laden: Einschiffen abgelehnt (%s)" % [status, board2])
	# Die anderen Personen sind unberuehrt (Pilot bleibt in der Basis).
	_check(_base_status(PILOT) != "station", "%s: nach Laden: Pilot nicht auf station" % status)
	await _close()

func _fallen_part() -> void:
	if not await _open("campaign", "new"): return
	var old_entry := {"unit_id": "old_one", "display_name": "Alt", "job_id": "j", "location_id": "l"}
	var new_entry := {"unit_id": "new_one", "display_name": "Neu", "job_id": "j", "location_id": "l", "reason": "respawn_limit", "respawns_used": 3, "respawn_limit": 3}
	var odd_entry := {"unit_id": "odd_one", "display_name": "Odd", "job_id": "j", "location_id": "l", "reason": 5, "respawns_used": "3", "respawn_limit": -1}
	var float_entry := {"unit_id": "float_one", "display_name": "Fl", "job_id": "j", "location_id": "l", "reason": "respawn_limit", "respawns_used": 2.0, "respawn_limit": 2.5}
	for entry: Dictionary in [old_entry, new_entry, odd_entry, float_entry]:
		_check(bool(_runtime.call("record_fallen", entry).get("ok", false)), "Gefallene: %s wird angenommen" % entry.unit_id)
	var listed: Array = _runtime.call("get_fallen")
	var by_id: Dictionary = {}
	for entry: Dictionary in listed: by_id[String(entry.unit_id)] = entry
	_check(by_id["old_one"] == old_entry, "Gefallene: alter Eintrag ohne neue Felder bleibt unveraendert (%s)" % by_id["old_one"])
	_check(by_id["new_one"] == new_entry, "Gefallene: neuer Eintrag traegt reason, respawns_used, respawn_limit (%s)" % by_id["new_one"])
	_check(by_id["odd_one"] == {"unit_id": "odd_one", "display_name": "Odd", "job_id": "j", "location_id": "l"}, "Gefallene: falsche Typen verwerfen nur die Felder, nicht den Eintrag (%s)" % by_id["odd_one"])
	_check(by_id["float_one"].get("respawns_used") == 2 and typeof(by_id["float_one"].get("respawns_used")) == TYPE_INT and not by_id["float_one"].has("respawn_limit") and by_id["float_one"].get("reason") == "respawn_limit", "Gefallene: 2.0 wird 2 (int), 2.5 faellt weg (%s)" % by_id["float_one"])
	var saved: Dictionary = _flow.call("request_campaign_save")
	if not _check(bool(saved.get("ok", false)), "Gefallene: Speichern gelingt"): return
	var loaded: Dictionary = CP_STORE.load_checkpoint()
	_check(bool(loaded.get("ok", false)) and Array(Dictionary(loaded.get("payload", {})).get("fallen", [])).size() == 4, "Gefallene: Stand enthaelt vier Eintraege und besteht die Pruefung")
	await _close()
	if not await _open("campaign", "continue"): return
	var restored: Array = _runtime.call("get_fallen")
	var restored_by_id: Dictionary = {}
	for entry: Dictionary in restored: restored_by_id[String(entry.unit_id)] = entry
	_check(restored.size() == 4 and restored_by_id["new_one"] == new_entry and restored_by_id["old_one"] == old_entry and restored_by_id["float_one"] == by_id["float_one"], "Gefallene: nach Laden stehen alle vier Eintraege mit ihren Feldern da")
	await _close()

func _store_negative() -> void:
	if not await _open("campaign", "new"): return
	_make_dead(LEADER, "respawning", 1)
	_base().call("park_pickup_person", LEADER)
	_feed()
	var saved: Dictionary = _flow.call("request_campaign_save")
	if not _check(bool(saved.get("ok", false)), "Negativ: Speichern gelingt"): return
	var payload: Dictionary = Dictionary(CP_STORE.load_checkpoint().get("payload", {}))
	_check(bool(CP_STORE.validate_payload(payload.duplicate(true)).get("ok", false)), "Negativ: unveraenderter Stand ist gueltig")
	var altered: Dictionary = payload.duplicate(true)
	for unit: Dictionary in altered.roster:
		if String(unit.get("unit_id", "")) == LEADER:
			unit["availability_status"] = "active"
	var verdict: Dictionary = CP_STORE.validate_payload(altered)
	_check(not bool(verdict.get("ok", true)) and String(verdict.get("reason", "")).begins_with("invalid_"), "Negativ: station fuer eine aktive Nicht-Angeworbene wird abgelehnt (%s)" % verdict)
	await _close()
