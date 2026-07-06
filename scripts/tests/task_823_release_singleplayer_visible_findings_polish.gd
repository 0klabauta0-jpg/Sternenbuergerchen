extends SceneTree

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const TASK_PATH: String = "res://docs/tasks/TASK_823_release_singleplayer_visible_findings_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const SCRIPT_PATH: String = "res://scripts/ui/main_menu_screen.gd"
const SINGLEPLAYER_ROUTE: String = "res://scenes/meta/meta_layer_test.tscn"
const STYLE_ID: String = "task_823_release_singleplayer_first_play_cta_v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_823 Release Singleplayer Visible Findings Polish ===")
	_test_docs_and_script_hooks()
	await _test_main_menu_first_play_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_823: FAILED")
		quit(1)
		return
	print("TASK_823: ALL PASSED")
	quit(0)


func _test_docs_and_script_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var script_text: String = _read_text(SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_823 task file exists")
	_assert(task_text.contains("Release Singleplayer Visible Findings Polish"), "Task names visible findings polish")
	_assert(status_text.contains("TASK_823 - Release Singleplayer Visible Findings Polish"), "Implementation status tracks TASK_823")
	_assert(roadmap_text.contains("TASK_823 - Release Singleplayer Visible Findings Polish (implementiert)"), "Roadmap marks TASK_823 implemented")
	_assert(script_text.contains("get_release_singleplayer_visible_findings_polish_snapshot"), "Main menu exposes TASK_823 snapshot")
	_assert(script_text.contains(STYLE_ID), "Main menu script contains stable TASK_823 style id")


func _test_main_menu_first_play_polish() -> void:
	var packed_scene := ResourceLoader.load(MAIN_MENU_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Main menu scene loads")
	if packed_scene == null:
		return
	var screen := packed_scene.instantiate() as Control
	_assert(screen != null, "Main menu instantiates")
	if screen == null:
		return
	root.add_child(screen)
	await process_frame
	await process_frame
	_assert(screen.has_method("get_release_singleplayer_visible_findings_polish_snapshot"), "Main menu has TASK_823 callable")
	if not screen.has_method("get_release_singleplayer_visible_findings_polish_snapshot"):
		screen.queue_free()
		return
	var snapshot: Dictionary = Dictionary(screen.call("get_release_singleplayer_visible_findings_polish_snapshot"))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.release_singleplayer_visible_findings_polish.v1", "Snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_823", "Snapshot task id is TASK_823")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot does not claim gameplay truth")
	_assert(not bool(snapshot.get("creates_simulation_root", true)), "Main menu still does not create SimulationRoot")
	_assert(String(snapshot.get("singleplayer_route", "")) == SINGLEPLAYER_ROUTE, "Singleplayer route remains unchanged")
	_assert(String(snapshot.get("singleplayer_style_id", "")) == STYLE_ID, "Singleplayer carries TASK_823 style id")
	_assert(String(snapshot.get("singleplayer_priority", "")) == "primary", "Singleplayer is primary")
	_assert(float(snapshot.get("singleplayer_min_height", 0.0)) >= 74.0, "Singleplayer CTA is taller")
	_assert(int(snapshot.get("singleplayer_font_size", 0)) >= 18, "Singleplayer CTA font is raised")
	_assert(int(snapshot.get("singleplayer_font_size", 0)) > int(snapshot.get("secondary_font_size", 0)), "Primary font is larger than secondary")
	_assert(String(snapshot.get("singleplayer_action_hint", "")).contains("Sortie"), "Singleplayer action hint names sortie start")
	_assert(String(snapshot.get("multiplayer_priority", "")) == "secondary", "Multiplayer remains secondary")
	_assert(String(snapshot.get("editor_priority", "")) == "secondary", "Editor remains secondary")
	_assert(String(snapshot.get("settings_priority", "")) == "secondary", "Settings remains secondary")
	_assert(String(snapshot.get("mission_save_priority", "")) == "support", "Mission save is support")
	_assert(String(snapshot.get("mission_load_priority", "")) == "support", "Mission load is support")

	var route_snapshot: Dictionary = Dictionary(screen.call("get_route_snapshot"))
	_assert(String(route_snapshot.get("singleplayer", "")) == SINGLEPLAYER_ROUTE, "Route snapshot keeps Singleplayer target")
	_assert(bool(route_snapshot.get("release_first_play_primary", false)), "Route snapshot marks first play primary")
	screen.queue_free()
	await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
