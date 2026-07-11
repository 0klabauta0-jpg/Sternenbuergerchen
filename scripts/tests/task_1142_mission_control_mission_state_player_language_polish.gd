extends SceneTree

const STATE_PRESENTER := preload("res://scripts/ui/mission_control_state_presenter.gd")
const TEAM_PRESENTER := preload("res://scripts/mission/mission_team_chip_presenter.gd")

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	var cases := [
		[{"has_lz": false, "approach_name": "NW", "drop_state": "", "sequence_phase": ""}, "LZ: offen | ANFLUG NW", "", "DROP: wartet"],
		[{"has_lz": true, "lz_text": "G3,4", "approach_name": "SE", "drop_state": "to_mission", "eta_seconds": 7}, "LZ: G3,4 | ANFLUG SO", "", "DROP: Anflug 7s"],
		[{"drop_state": "waiting"}, "", "", "DROP: bereit"],
		[{"drop_state": "to_fob", "eta_seconds": 4}, "", "", "DROP: zur FOB 4s"],
		[{"sequence_phase": "landed"}, "", "", "DROP: gelandet"],
		[{"sequence_phase": "unloading", "unit_index": 2, "unit_count": 4}, "", "", "AUSSTIEG: 2/4"],
		[{"sequence_phase": "outbound"}, "", "", "DROP: hebt ab"],
		[{"sequence_phase": "complete"}, "", "", "FIRETEAM: ausgestiegen"],
	]
	for case_variant in cases:
		var case: Array = Array(case_variant)
		var snapshot: Dictionary = STATE_PRESENTER.build_snapshot(Dictionary(case[0]))
		var lines: PackedStringArray = PackedStringArray(snapshot.get("visible_lines", PackedStringArray()))
		var visible := "\n".join(lines)
		for expected_index in range(1, 4):
			var expected := String(case[expected_index])
			if not expected.is_empty():
				_check(visible.contains(expected), "Mission state contains %s" % expected)
		for raw_token in ["inbound", "outbound", "to_fob", "staged", "off-map", "Preview"]:
			_check(not visible.contains(raw_token), "Mission state hides raw token %s" % raw_token)
		_check(bool(snapshot.get("read_only", false)), "Mission state snapshot is read-only")
		_check(not bool(snapshot.get("sets_transport_truth", true)), "Mission state presenter sets no transport truth")

	var preview: Dictionary = STATE_PRESENTER.build_snapshot({"preview_mode": true, "drop_staged": true})
	_check("\n".join(PackedStringArray(preview.get("visible_lines", PackedStringArray()))).contains("VORSCHAU"), "Preview is named in German")
	_check(String(preview.get("raw_drop_state", "missing")) == "", "Raw drop state remains available")

	var team_presenter = TEAM_PRESENTER.new()
	var team_snapshot: Dictionary = team_presenter.build_snapshot({"peer_teams": {1: "team_alpha"}})
	_check(String(team_snapshot.get("display_text", "")).begins_with("Einsatz:"), "Visible team chip uses player language")
	_check(String(team_snapshot.get("status_text", "")).begins_with("Teams:"), "Raw team status remains compatible")

	if _failures.is_empty():
		print("TASK_1142 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
