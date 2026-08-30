extends SceneTree

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	var fob_source := _read("res://scripts/meta/fob_screen.gd")
	var payload_guard := fob_source.find("if not visible_fireteam_ids.is_empty() or visible_member_count > 0:")
	var label_creation := fob_source.find("var drop_label := Label.new()", payload_guard)
	var nested_fireteam_guard := fob_source.find("if not visible_fireteam_ids.is_empty():", payload_guard)
	_check(payload_guard >= 0 and label_creation > payload_guard and label_creation < nested_fireteam_guard, "Dropship label is created only inside the non-empty payload guard")

	var ui_harness_source := _read("res://scripts/tests/ui_hud_comic_bubble_performance_harness.gd")
	_check(ui_harness_source.contains("await _drain_owned_ui_delays(scene_parent)"), "UI performance harness drains short owned UI delays")
	_check(ui_harness_source.contains("func _drain_owned_ui_delays"), "UI delay drain has an explicit helper")

	var task_096_source := _read("res://scripts/tests/task_096_recovery_verifier.gd")
	_check(not task_096_source.contains("TASK1146 ORPHANS AFTER"), "TASK_096 no longer carries temporary orphan diagnostics")
	_check(task_096_source.contains("await _wait_cleanup_frames()"), "TASK_096 keeps deterministic queue-free cleanup frames")

	var gate_source := _read("res://scripts/tests/run_task_1146_headless_resource_leak_gate.ps1")
	_check(gate_source.contains("--verbose"), "Leak gate requests Godot ownership details")
	_check(gate_source.contains("Leaked instance"), "Leak gate blocks leaked ObjectDB instances")
	_check(gate_source.contains("RID allocations"), "Leak gate blocks leaked RID allocations")
	_check(gate_source.contains("ObjectDB instances leaked"), "Leak gate blocks ObjectDB cleanup warnings")
	_check(gate_source.contains('"^ERROR:"'), "Leak gate blocks engine errors during cleanup")
	_check(gate_source.contains("task_222_performance_regression_gate_and_manual_profile_checklist.gd"), "Leak gate covers TASK_222")
	_check(gate_source.contains("$verifierExit = $process.ExitCode"), "Leak gate captures each verifier exit before later commands can overwrite it")
	_finish()


func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("TASK_1146 PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("TASK_1146 FAIL: %s" % failure)
	quit(1)
