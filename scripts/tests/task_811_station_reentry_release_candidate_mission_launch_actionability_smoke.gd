extends SceneTree

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_811_station_reentry_release_candidate_mission_launch_actionability_smoke.md"
const TASK_810_PATH: String = "res://docs/tasks/TASK_810_station_reentry_release_candidate_first_mission_cta_visual_smoke.md"
const TASK_539_PATH: String = "res://docs/tasks/TASK_539_mission_insertion_first_order_readability_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const META_LAYER_PATH: String = "res://scripts/meta/meta_layer_flow.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_811 Station Reentry Release Candidate Mission Launch Actionability Smoke ===")
	_test_docs_contract_and_report()
	await _test_singleplayer_start_mission_opens_actionable_mission()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_811: FAILED")
		quit(1)
		return
	print("TASK_811: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var meta_text: String = _read_text(META_LAYER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_811 task file exists")
	_assert(FileAccess.file_exists(TASK_810_PATH), "TASK_810 task remains available")
	_assert(FileAccess.file_exists(TASK_539_PATH), "TASK_539 insertion readability task remains available")
	_assert(task_text.contains("Mission Launch Actionability Smoke"), "TASK_811 task names launch actionability")
	_assert(status_text.contains("TASK_811 - Station Reentry Release Candidate Mission Launch Actionability Smoke"), "Implementation status tracks TASK_811")
	_assert(roadmap_text.contains("TASK_811 - Station Reentry Release Candidate Mission Launch Actionability Smoke (implementiert)"), "Roadmap marks TASK_811 implemented")
	_assert(roadmap_text.contains("TASK_812 - Station Reentry Release Candidate LZ Drop Preview Actionability Smoke"), "Roadmap advances to TASK_812")
	_assert(contract_text.contains("Station-Reentry-Release-Candidate-Mission-Launch-Actionability-Smoke"), "Mission command feedback contract documents TASK_811")
	_assert(report_text.contains("TASK_811"), "Reentry handbook preserves TASK_811 context")
	_assert(report_text.contains('data-export-key="reentry_release_candidate_mission_launch_actionability.status"'), "Reentry handbook exports TASK_811 status")
	_assert(meta_text.contains("get_release_candidate_mission_launch_actionability_snapshot"), "MetaLayer exposes TASK_811 snapshot")


func _test_singleplayer_start_mission_opens_actionable_mission() -> void:
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
	_assert(scene.has_method("get_release_candidate_mission_launch_actionability_snapshot"), "MetaLayer exposes launch actionability snapshot")
	if homebase == null or not scene.has_method("get_release_candidate_mission_launch_actionability_snapshot"):
		scene.queue_free()
		current_scene = null
		await _wait_frames(2)
		return

	var start_button := homebase.get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton") as Button
	_assert(start_button != null, "Homebase exposes visible Start Mission button")
	_assert(start_button != null and start_button.text == "Start Mission" and not start_button.disabled, "Start Mission button is actionable before launch")
	if start_button == null or start_button.disabled:
		scene.queue_free()
		current_scene = null
		await _wait_frames(2)
		return

	start_button.pressed.emit()
	await _wait_frames(18)

	var smoke: Dictionary = Dictionary(scene.call("get_release_candidate_mission_launch_actionability_snapshot"))
	var handoff: Dictionary = Dictionary(smoke.get("handoff", {}))
	var insertion: Dictionary = Dictionary(smoke.get("insertion", {}))
	_assert(String(smoke.get("schema", "")) == "sternenbuergerchen.station_reentry_release_candidate_mission_launch_actionability_smoke.v1", "TASK_811 schema is stable")
	_assert(String(smoke.get("status", "")) == "pass", "Mission launch actionability smoke passes")
	_assert(int(smoke.get("failed_count", -1)) == 0, "Mission launch actionability smoke has no critical failures")
	_assert(_snapshot_is_read_only(smoke), "TASK_811 smoke snapshot remains read-only")
	_assert(String(smoke.get("singleplayer_path_expected", "")) == "MainMenu -> Einzelspieler -> Homebase -> Start Mission -> Mission", "Smoke documents the expected launch path")
	_assert(String(smoke.get("current_meta_view", "")) == "mission", "Start Mission opens the Mission view")
	_assert(bool(smoke.get("active_mission_exists", false)), "Start Mission creates an active mission")
	_assert(bool(smoke.get("mission_host_visible", false)), "MissionHost is visible after Start Mission")
	_assert(String(handoff.get("handoff_gate", "")) == "pass", "Homebase-to-Mission handoff remains green")
	_assert(String(insertion.get("gate", "")) == "pass", "Mission insertion readability remains green")
	_assert(String(smoke.get("insertion_gate", "")) == "pass", "TASK_811 exports insertion pass gate")
	_assert(int(smoke.get("selected_payload_count", 0)) >= 2, "Mission insertion sees the boarded payload")
	_assert(not bool(smoke.get("selected_card_has_lz", true)), "Mission launch starts before LZ placement")
	_assert(bool(smoke.get("set_lz_button_present", false)), "Set LZ is visible as next step")
	_assert(bool(smoke.get("drop_button_present", false)), "Drop command is visible")
	_assert(bool(smoke.get("drop_button_disabled", false)), "Drop waits for LZ before enabling")
	_assert(_check_passed(smoke, "selected_fireteam_and_order_controls_visible"), "Fireteam and first order controls are readable")
	_assert(_check_passed(smoke, "read_only_boundaries"), "TASK_811 boundaries stay read-only")

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
