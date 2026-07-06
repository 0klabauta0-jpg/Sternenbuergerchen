extends SceneTree

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_826_release_mission_lz_drop_next_step_cue.md"
const TASK_811_PATH: String = "res://docs/tasks/TASK_811_station_reentry_release_candidate_mission_launch_actionability_smoke.md"
const TASK_812_PATH: String = "res://docs/tasks/TASK_812_station_reentry_release_candidate_lz_drop_preview_actionability_smoke.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const META_LAYER_PATH: String = "res://scripts/meta/meta_layer_flow.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_826 Release Mission LZ Drop Next Step Cue ===")
	_test_docs_and_snapshot_exports()
	await _test_singleplayer_start_mission_shows_lz_drop_next_step()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_826: FAILED")
		quit(1)
		return
	print("TASK_826: ALL PASSED")
	quit(0)


func _test_docs_and_snapshot_exports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var meta_text: String = _read_text(META_LAYER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_826 task file exists")
	_assert(FileAccess.file_exists(TASK_811_PATH), "TASK_811 launch smoke remains available")
	_assert(FileAccess.file_exists(TASK_812_PATH), "TASK_812 LZ/drop smoke remains available")
	_assert(task_text.contains("LZ Drop Next Step Cue"), "TASK_826 task names the LZ/drop next-step cue")
	_assert(status_text.contains("TASK_826 - Release Mission LZ Drop Next Step Cue"), "Implementation status tracks TASK_826")
	_assert(roadmap_text.contains("TASK_826 - Release Mission LZ Drop Next Step Cue (implementiert)"), "Roadmap marks TASK_826 implemented")
	_assert(meta_text.contains("selected_panel_next_step_cue_visible"), "MetaLayer launch smoke checks selected-panel next-step cue")
	_assert(meta_text.contains("insertion_next_step_id"), "MetaLayer exports insertion next-step id")


func _test_singleplayer_start_mission_shows_lz_drop_next_step() -> void:
	root.size = Vector2i(1920, 1080)
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
	_assert(scene.has_method("get_release_candidate_mission_launch_actionability_snapshot"), "MetaLayer exposes mission launch snapshot")
	if homebase == null or not scene.has_method("get_release_candidate_mission_launch_actionability_snapshot"):
		scene.queue_free()
		current_scene = null
		await _wait_frames(2)
		return

	var start_button := homebase.get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton") as Button
	_assert(start_button != null and start_button.text == "Start Mission" and not start_button.disabled, "Start Mission button is actionable")
	if start_button == null or start_button.disabled:
		scene.queue_free()
		current_scene = null
		await _wait_frames(2)
		return

	start_button.pressed.emit()
	await _wait_frames(18)

	var smoke: Dictionary = Dictionary(scene.call("get_release_candidate_mission_launch_actionability_snapshot"))
	var insertion: Dictionary = Dictionary(smoke.get("insertion", {}))
	var next_step: Dictionary = Dictionary(smoke.get("insertion_next_step", {}))
	var selected_text: String = String(smoke.get("selected_fireteam_status_text", insertion.get("selected_fireteam_status_text", ""))).strip_edges()
	_assert(String(smoke.get("schema", "")) == "sternenbuergerchen.station_reentry_release_candidate_mission_launch_actionability_smoke.v1", "Launch snapshot schema remains stable")
	_assert(String(smoke.get("status", "")) == "pass", "Mission launch actionability remains green with next-step cue")
	_assert(_snapshot_is_read_only(smoke), "Launch snapshot remains read-only")
	_assert(String(smoke.get("current_meta_view", "")) == "mission", "Start Mission opens Mission view")
	_assert(String(smoke.get("insertion_next_step_id", "")) == "set_lz", "Top-level snapshot exports set_lz as next step")
	_assert(String(next_step.get("next_step_id", "")) == "set_lz", "Insertion snapshot exports set_lz as next step")
	_assert(String(smoke.get("insertion_next_step_text", "")).contains("LZ"), "Next-step text names LZ")
	_assert(String(smoke.get("insertion_next_step_text", "")).contains("Drop"), "Next-step text names Drop follow-up")
	_assert(selected_text.contains("Naechster Griff"), "Selected Fireteam panel explains the next human action")
	_assert(selected_text.contains("LZ"), "Selected Fireteam panel names LZ before ground deployment")
	_assert(not bool(smoke.get("selected_card_has_lz", true)), "Mission still starts before LZ placement")
	_assert(bool(smoke.get("drop_button_present", false)), "Drop command remains visible")
	_assert(bool(smoke.get("drop_button_disabled", false)), "Drop remains disabled before LZ")
	_assert(_check_passed(smoke, "selected_panel_next_step_cue_visible"), "MetaLayer check sees the selected-panel next-step cue")

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
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
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
