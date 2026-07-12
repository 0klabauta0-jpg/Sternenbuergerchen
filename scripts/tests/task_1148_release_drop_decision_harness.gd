extends SceneTree

const HARNESS_PATH := "res://scripts/tools/capture_release_host_client_entry_playtest.ps1"

var _failed := 0


func _initialize() -> void:
	var source := FileAccess.get_file_as_string(HARNESS_PATH)
	for token in [
		"DropDecision",
		"--release-multiplayer-drop-decision",
		"first_decision_accepted",
		"release_host_client_drop_decision_playtest.json",
		"release_host_client_drop_decision_host_window.png",
		"release_host_client_drop_decision_client_window.png",
		"deployed_unit_ids",
		"embarked_unit_ids",
		"deployment_converged",
		"1600x900",
	]:
		_assert(source.contains(token), "Release harness contains %s" % token)
	print("TASK_1148 release Drop/Decision harness: %d/10 PASS" % (10 - _failed))
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
