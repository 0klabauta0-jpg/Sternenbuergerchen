extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")


func _init() -> void:
	print("REVIEW2_CANARY_INIT")
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _initialize() -> void:
	print("REVIEW2_CANARY_INITIALIZE")


func _run() -> void:
	print("REVIEW2_CANARY_RUN")
	var file := FileAccess.open("user://review2_isolation_canary.json", FileAccess.READ)
	if file == null:
		push_error("Isolation autoload did not create its canary")
		quit(1)
		return
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	if String(data.get("user_dir", "")).replace("\\", "/").to_lower() != OS.get_user_data_dir().replace("\\", "/").to_lower():
		push_error("Isolation canary resolved a different data directory")
		quit(1)
		return
	print("REVIEW2_ISOLATION_CANARY_PASS")
	quit(0)
