extends SceneTree

const HARNESS_PATH := "res://scripts/tools/capture_release_host_client_entry_playtest.ps1"


func _initialize() -> void:
	var failures := 0
	if not FileAccess.file_exists(HARNESS_PATH):
		push_error("FAIL: release Host/Join harness exists")
		quit(1)
		return
	var source := FileAccess.get_file_as_string(HARNESS_PATH)
	for token in [
		"Sternenbuergerchen_rel.exe",
		"--release-multiplayer-host",
		"--release-multiplayer-join",
		"--release-multiplayer-auto-start",
		"--release-multiplayer-trace=",
		"mission_started",
		"release_host_client_entry_playtest.json",
		"release_host_client_host_window.png",
		"release_host_client_client_window.png",
	]:
		if source.contains(token):
			print("PASS: harness contains %s" % token)
		else:
			failures += 1
			push_error("FAIL: harness contains %s" % token)
	if source.to_lower().contains("$host = start-process"):
		failures += 1
		push_error("FAIL: harness does not overwrite PowerShell's reserved Host variable")
	else:
		print("PASS: harness avoids PowerShell's reserved Host variable")
	if failures == 0:
		print("TASK_1147 release Host/Join harness: 10/10 PASS")
		quit(0)
	else:
		quit(1)
