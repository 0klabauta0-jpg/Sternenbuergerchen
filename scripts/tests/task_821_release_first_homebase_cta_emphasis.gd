extends SceneTree

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_821_release_first_homebase_cta_emphasis.md"
const TASK_810_PATH: String = "res://docs/tasks/TASK_810_station_reentry_release_candidate_first_mission_cta_visual_smoke.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HOMEBASE_SCRIPT_PATH: String = "res://scripts/meta/homebase_screen.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_821 Release First Homebase CTA Emphasis ===")
	_test_docs_and_contract()
	await _test_singleplayer_homebase_cta_emphasis()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_821: FAILED")
		quit(1)
		return
	print("TASK_821: ALL PASSED")
	quit(0)


func _test_docs_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var homebase_text: String = _read_text(HOMEBASE_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_821 task file exists")
	_assert(FileAccess.file_exists(TASK_810_PATH), "TASK_810 source task remains available")
	_assert(task_text.contains("Release First Homebase CTA Emphasis"), "TASK_821 task names CTA emphasis")
	_assert(status_text.contains("TASK_821 - Release First Homebase CTA Emphasis"), "Implementation status tracks TASK_821")
	_assert(roadmap_text.contains("TASK_821 - Release First Homebase CTA Emphasis (implementiert)"), "Roadmap marks TASK_821 implemented")
	_assert(contract_text.contains("Release-First-Homebase-CTA-Emphasis"), "Mission command feedback contract documents TASK_821")
	_assert(homebase_text.contains("get_release_candidate_first_homebase_cta_emphasis_snapshot"), "Homebase exposes TASK_821 snapshot")


func _test_singleplayer_homebase_cta_emphasis() -> void:
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	root.add_child(menu)
	current_scene = menu
	await _wait_frames(4)

	var singleplayer_button := menu.get_node_or_null("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton") as Button
	_assert(singleplayer_button != null, "Main menu exposes Singleplayer button")
	if singleplayer_button == null:
		menu.queue_free()
		await _wait_frames(2)
		return
	singleplayer_button.pressed.emit()
	await _wait_frames(14)

	var scene: Node = current_scene
	_assert(scene != null and scene.name == "MetaLayerTest", "Singleplayer opens MetaLayer scene")
	if scene == null or scene.name != "MetaLayerTest":
		return
	var homebase := scene.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "Singleplayer exposes HomebaseScreen")
	_assert(homebase != null and homebase.has_method("get_release_candidate_first_homebase_cta_emphasis_snapshot"), "Homebase exposes TASK_821 callable")
	if homebase == null or not homebase.has_method("get_release_candidate_first_homebase_cta_emphasis_snapshot"):
		scene.queue_free()
		current_scene = null
		await _wait_frames(2)
		return

	var snapshot: Dictionary = Dictionary(homebase.call("get_release_candidate_first_homebase_cta_emphasis_snapshot"))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_release_candidate_first_homebase_cta_emphasis.v1", "TASK_821 schema is stable")
	_assert(String(snapshot.get("status", "")) == "pass", "CTA emphasis snapshot passes")
	_assert(int(snapshot.get("failed_count", -1)) == 0, "CTA emphasis has no critical failures")
	_assert(_snapshot_is_read_only(snapshot), "CTA emphasis remains read-only")
	_assert(String(snapshot.get("source_status", "")) == "pass", "CTA emphasis builds on green TASK_810 source")
	_assert(String(snapshot.get("release_candidate_action_cue_style_id", "")) == "task_821_release_first_homebase_cta_v1", "CTA emphasis style id is applied")
	_assert(String(snapshot.get("release_candidate_action_cue_priority", "")) == "primary", "CTA emphasis priority is primary")
	_assert(int(snapshot.get("release_candidate_action_cue_font_size", 0)) >= 10, "CTA emphasis font size is raised")
	_assert(float(snapshot.get("release_candidate_action_cue_min_height", 0.0)) >= 88.0, "CTA emphasis min height is raised")
	_assert(bool(snapshot.get("start_button_release_candidate_primary_cta", false)), "Start Mission button is marked primary CTA")
	_assert(String(snapshot.get("start_button_release_candidate_action_cue_text", "")) == String(snapshot.get("release_candidate_action_cue_text", "")), "Start Mission button carries same CTA text")
	_assert(_check_passed(snapshot, "start_button_carries_same_cue"), "Verifier sees the button/cue bridge")

	scene.queue_free()
	current_scene = null
	await _wait_frames(2)


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _wait_frames(count: int) -> void:
	for _index in range(count):
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
