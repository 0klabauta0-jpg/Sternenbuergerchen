extends "res://scripts/tests/campaign_respawn_apply_verifier.gd"
## R3 Fix-Runde 1: Befunde W1/M5 (geschuetzte Personen), W3/W6/W7 (echtes Missionsende, Basiszustand, Autosave) und
## die R4-Messung. Wie die anderen Respawn-Tests nur im Wegwerfprofil: ohne bestaetigtes Profil Abbruch mit Code 2, nichts geschrieben.
## P1 Pilot   P2 campaign_outpost_recruit   P3 campaign_rescue_pilot   P4 Anwerber   P5 Grenze 0 (Beobachtung)
## Abschlusszeile: CAMPAIGN_RESPAWN_MISSION passed=%d failed=%d

const MISSION_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const PROTECTED_KEYS := ["final", "death_number", "respawn_state"]

func _run() -> void:
	var verdict: Dictionary = MISSION_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_RESPAWN_MISSION refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	_configure_entry()
	for scenario: String in ["P1", "P2", "P3", "P4", "P5"]:
		print("--- ", scenario)
		await call("_rm_" + scenario.to_lower())
		await _end_sortie()
	print("CAMPAIGN_RESPAWN_MISSION passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

## Ergebnis, in dem unit_id als Wiederkehrer (Grenze 3) mit vollem casualties-Eintrag steht, wie ihn resolve_mission liefert.
func _rm_protected_result(unit_id: String, final_entry: bool) -> Dictionary:
	var result: Dictionary = _ra_result(_t6b_states({}), "aborted", 3)
	var entry: Dictionary = {"unit_id": unit_id, "outcome": "dead", "final": final_entry, "death_number": 4 if final_entry else 1, "respawn_state": {"state": "respawning", "death_number": 1, "seconds_total": 3600, "seconds_remaining": 3600, "pickup_location_id": "polisa", "source": "left_behind"}}
	result["casualties"] = [entry]
	if final_entry:
		result["fatality_unit_ids"] = PackedStringArray([unit_id])
		result["respawn_unit_ids"] = PackedStringArray()
	else:
		result["fatality_unit_ids"] = PackedStringArray()
		result["respawn_unit_ids"] = PackedStringArray([unit_id])
	return result

func _rm_check_protected(unit_id: String, label: String) -> void:
	for final_entry: bool in [false, true]:
		var applied: Dictionary = _flow.call("_apply_campaign_casualties", _rm_protected_result(unit_id, final_entry))
		var entry: Dictionary = _casualty_entry(applied, unit_id)
		var leftovers: Array = []
		for key: String in PROTECTED_KEYS:
			if entry.has(key):
				leftovers.append(key)
		var tag: String = "%s (%s)" % [label, "Grenze erreicht" if final_entry else "Wiederkehrer"]
		_check(not entry.is_empty() and bool(entry.get("protected_from_death", false)) and String(entry.get("outcome", "")) == "wounded" and String(entry.get("severity", "")) == "severe", "%s: Eintrag geschuetzt, verwundet, schwer (%s)" % [tag, entry])
		_check(leftovers.is_empty(), "%s: Eintrag traegt keinen der Schluessel final, death_number, respawn_state (uebrig: %s)" % [tag, leftovers])
		_check(PackedStringArray(applied.get("respawn_unit_ids", PackedStringArray(["x"]))).is_empty() and PackedStringArray(applied.get("fatality_unit_ids", PackedStringArray(["x"]))).is_empty(), "%s: weder Wiederkehrer noch Gefallener" % tag)

func _rm_p1() -> void:
	if not await _t6b_new_four(): return
	_check(bool(_runtime.call("is_person_protected_from_death", PILOT_ID)), "P1: Fixture: Pilot ist geschuetzt")
	_rm_check_protected(PILOT_ID, "P1 Schiffspilot")

func _rm_p2() -> void:
	if not await _t6b_new_four(): return
	_check(bool(_runtime.call("is_person_protected_from_death", "campaign_outpost_recruit")), "P2: Fixture: Fortschritts-Rekrut ist geschuetzt")
	_rm_check_protected("campaign_outpost_recruit", "P2 campaign_outpost_recruit")

func _rm_p3() -> void:
	if not await _t6b_new_four(): return
	_check(bool(_runtime.call("is_person_protected_from_death", "campaign_rescue_pilot")), "P3: Fixture: Rettungspilot ist geschuetzt")
	_rm_check_protected("campaign_rescue_pilot", "P3 campaign_rescue_pilot")

func _rm_p4() -> void:
	if not await _t6b_new_four(): return
	_runtime.get("_polisa_market").set("_recruiter_id", LEAD_B)
	_check(bool(_runtime.call("is_person_protected_from_death", LEAD_B)), "P4: Fixture: B ist als Anwerber geschuetzt")
	_rm_check_protected(LEAD_B, "P4 Anwerber")

## Beobachtung (keine Aenderung): Was traegt der Eintrag einer geschuetzten Person bei Grenze 0, wo final seit R1 steht?
func _rm_p5() -> void:
	if not await _t6b_new_four(): return
	_runtime.get("_polisa_market").set("_recruiter_id", LEAD_B)
	var states: Array = _t6b_states({LEAD_B: "down"})
	var result: Dictionary = _ra_result(states, "aborted", 0)
	var raw_entry: Dictionary = _casualty_entry(result, LEAD_B)
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", result)
	var entry: Dictionary = _casualty_entry(applied, LEAD_B)
	print("RM_P5_LIMIT0 raw_keys=", raw_entry.keys(), " applied_keys=", entry.keys(), " final=", entry.get("final", "<fehlt>"))
	_check(bool(entry.get("protected_from_death", false)) and String(entry.get("outcome", "")) == "wounded", "P5: Grenze 0: Pilot als geschuetzt verwundet gebucht (%s)" % [entry])
