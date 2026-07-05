extends SceneTree

const HOMEBASE_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_809_station_reentry_release_candidate_playability_polish_backlog.md"
const TASK_808_PATH: String = "res://docs/tasks/TASK_808_station_reentry_firefight_release_candidate_tester_run_acceptance.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const HOMEBASE_SCRIPT_PATH: String = "res://scripts/meta/homebase_screen.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_809 Station Reentry Release Candidate Playability Polish Backlog ===")
	_test_docs_contract_and_report()
	await _test_blocked_homebase_has_actionable_stop_cue()
	await _test_singleplayer_release_start_has_ready_action_cue()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_809: FAILED")
		quit(1)
		return
	print("TASK_809: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var homebase_text: String = _read_text(HOMEBASE_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_809 task file exists")
	_assert(FileAccess.file_exists(TASK_808_PATH), "TASK_808 task remains available")
	_assert(task_text.contains("Release Candidate Playability Polish Backlog"), "TASK_809 task names playability polish")
	_assert(status_text.contains("TASK_809 - Station Reentry Release Candidate Playability Polish Backlog"), "Implementation status tracks TASK_809")
	_assert(roadmap_text.contains("TASK_809 - Station Reentry Release Candidate Playability Polish Backlog (implementiert)"), "Roadmap marks TASK_809 implemented")
	_assert(roadmap_text.contains("TASK_810 - Station Reentry Release Candidate First Mission CTA Visual Smoke"), "Roadmap advances to TASK_810")
	_assert(contract_text.contains("Station-Reentry-Release-Candidate-Playability-Polish-Backlog"), "Mission command feedback contract documents TASK_809")
	_assert(report_text.contains("TASK_809 Ready-Cue sichtbar"), "Reentry handbook keeps TASK_809 cue check")
	_assert(report_text.contains('data-export-key="reentry_release_candidate_playability_polish.release_candidate_action_cue_ready"'), "Reentry handbook exports TASK_809 cue check")
	_assert(homebase_text.contains("get_release_candidate_playability_polish_snapshot"), "Homebase exposes TASK_809 snapshot")


func _test_blocked_homebase_has_actionable_stop_cue() -> void:
	var homebase: Control = HOMEBASE_SCENE.instantiate()
	root.add_child(homebase)
	await _wait_frames(4)
	var snapshot: Dictionary = Dictionary(homebase.call("get_release_candidate_playability_polish_snapshot"))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_release_candidate_playability_polish.v1", "TASK_809 schema is stable")
	_assert(_snapshot_is_read_only(snapshot), "Blocked cue snapshot remains read-only")
	_assert(bool(snapshot.get("release_candidate_action_cue_visible", false)), "Blocked homebase still shows action cue")
	_assert(String(snapshot.get("release_candidate_action_cue_text", "")).contains("STOP-Chips"), "Blocked cue tells player to resolve STOP chips")
	_assert(not bool(snapshot.get("release_candidate_action_cue_ready", true)), "Blocked cue is not marked ready")
	homebase.queue_free()
	await _wait_frames(2)


func _test_singleplayer_release_start_has_ready_action_cue() -> void:
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
	await _wait_frames(12)

	var scene: Node = current_scene
	_assert(scene != null and scene.name == "MetaLayerTest", "Singleplayer opens MetaLayer scene")
	if scene == null or scene.name != "MetaLayerTest":
		return
	var homebase := scene.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "Singleplayer exposes HomebaseScreen")
	if homebase == null:
		scene.queue_free()
		current_scene = null
		await _wait_frames(2)
		return

	var snapshot: Dictionary = Dictionary(homebase.call("get_release_candidate_playability_polish_snapshot"))
	var startflow: Dictionary = Dictionary(homebase.call("get_pre_mission_startflow_visual_snapshot"))
	_assert(_snapshot_is_read_only(snapshot), "Ready cue snapshot remains read-only")
	_assert(String(snapshot.get("readiness_overall_state", "")) == "ready", "Singleplayer release start is ready")
	_assert(String(snapshot.get("start_button_text", "")) == "Start Mission", "Ready cue keeps Start Mission button")
	_assert(not bool(snapshot.get("start_button_disabled", true)), "Ready cue leaves Start Mission enabled")
	_assert(bool(snapshot.get("release_candidate_action_cue_visible", false)), "Ready cue is visible")
	_assert(bool(snapshot.get("release_candidate_action_cue_ready", false)), "Ready cue is marked ready")
	_assert(String(snapshot.get("release_candidate_action_cue_text", "")) == String(snapshot.get("release_candidate_action_cue_expected_ready_text", "")), "Ready cue uses exact expected text")
	_assert(String(snapshot.get("release_candidate_action_cue_text", "")).contains("Start Mission -> LZ waehlen -> Drop -> Preview lesen -> GO"), "Ready cue names first playable chain")
	_assert(int(snapshot.get("release_candidate_action_cue_step_count", 0)) == 5, "Ready cue exports five action steps")
	_assert(String(startflow.get("release_candidate_action_cue_text", "")) == String(snapshot.get("release_candidate_action_cue_text", "")), "Startflow snapshot carries the same cue")
	scene.queue_free()
	current_scene = null
	await _wait_frames(2)


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
