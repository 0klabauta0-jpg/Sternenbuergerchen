extends SceneTree

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_810_station_reentry_release_candidate_first_mission_cta_visual_smoke.md"
const TASK_809_PATH: String = "res://docs/tasks/TASK_809_station_reentry_release_candidate_playability_polish_backlog.md"
const BUGFIX_PATH: String = "res://docs/tasks/BUGFIX_singleplayer_release_homebase_partial_save_actionability.md"
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
	print("=== TASK_810 Station Reentry Release Candidate First Mission CTA Visual Smoke ===")
	_test_docs_contract_and_report()
	await _test_singleplayer_first_homebase_cta_visual_smoke()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_810: FAILED")
		quit(1)
		return
	print("TASK_810: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var homebase_text: String = _read_text(HOMEBASE_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_810 task file exists")
	_assert(FileAccess.file_exists(TASK_809_PATH), "TASK_809 task remains available")
	_assert(FileAccess.file_exists(BUGFIX_PATH), "Partial-save actionability bugfix task remains available")
	_assert(task_text.contains("First Mission CTA Visual Smoke"), "TASK_810 task names CTA visual smoke")
	_assert(status_text.contains("TASK_810 - Station Reentry Release Candidate First Mission CTA Visual Smoke"), "Implementation status tracks TASK_810")
	_assert(roadmap_text.contains("TASK_810 - Station Reentry Release Candidate First Mission CTA Visual Smoke (implementiert)"), "Roadmap marks TASK_810 implemented")
	_assert(roadmap_text.contains("TASK_811 - Station Reentry Release Candidate First Mission Live Window Polish Findings"), "Roadmap advances to TASK_811")
	_assert(contract_text.contains("Station-Reentry-Release-Candidate-First-Mission-CTA-Visual-Smoke"), "Mission command feedback contract documents TASK_810")
	_assert(report_text.contains("Aktueller Griff: TASK_810"), "Reentry handbook marks TASK_810 current")
	_assert(report_text.contains('data-export-key="reentry_release_candidate_cta_visual_smoke.status"'), "Reentry handbook exports TASK_810 status")
	_assert(homebase_text.contains("get_release_candidate_first_mission_cta_visual_smoke_snapshot"), "Homebase exposes TASK_810 snapshot")


func _test_singleplayer_first_homebase_cta_visual_smoke() -> void:
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
	_assert(homebase != null and homebase.has_method("get_release_candidate_first_mission_cta_visual_smoke_snapshot"), "Homebase exposes TASK_810 smoke snapshot")
	if homebase == null or not homebase.has_method("get_release_candidate_first_mission_cta_visual_smoke_snapshot"):
		scene.queue_free()
		current_scene = null
		await _wait_frames(2)
		return

	var smoke: Dictionary = Dictionary(homebase.call("get_release_candidate_first_mission_cta_visual_smoke_snapshot"))
	_assert(String(smoke.get("schema", "")) == "sternenbuergerchen.station_reentry_release_candidate_first_mission_cta_visual_smoke.v1", "TASK_810 schema is stable")
	_assert(String(smoke.get("status", "")) == "pass", "First-mission CTA visual smoke passes")
	_assert(int(smoke.get("failed_count", -1)) == 0, "First-mission CTA visual smoke has no critical failures")
	_assert(_snapshot_is_read_only(smoke), "TASK_810 smoke snapshot remains read-only")
	_assert(String(smoke.get("singleplayer_path_expected", "")) == "MainMenu -> Einzelspieler -> Homebase", "Smoke documents the expected Singleplayer path")
	_assert(String(smoke.get("readiness_overall_state", "")) == "ready", "First Homebase readiness is ready")
	_assert(String(smoke.get("start_button_text", "")) == "Start Mission", "First Homebase Start Mission button is visible")
	_assert(not bool(smoke.get("start_button_disabled", true)), "First Homebase Start Mission button is enabled")
	_assert(bool(smoke.get("release_candidate_action_cue_visible", false)), "First Homebase CTA is visible")
	_assert(bool(smoke.get("release_candidate_action_cue_ready", false)), "First Homebase CTA is ready")
	_assert(String(smoke.get("release_candidate_action_cue_text", "")) == String(smoke.get("release_candidate_action_cue_expected_ready_text", "")), "First Homebase CTA uses exact expected text")
	_assert(int(smoke.get("release_candidate_action_cue_step_count", 0)) == 5, "First Homebase CTA keeps five steps")
	_assert(String(smoke.get("rendered_readiness_item_text", "")).find("STOP Team") < 0, "Visible readiness has no STOP Team blocker")
	_assert(String(smoke.get("rendered_readiness_item_text", "")).find("STOP Dropship") < 0, "Visible readiness has no STOP Dropship blocker")
	_assert(String(smoke.get("rendered_readiness_item_text", "")).find("STOP Pilot") < 0, "Visible readiness has no STOP Pilot blocker")
	_assert(String(smoke.get("rendered_readiness_item_text", "")).find("STOP Boarding") < 0, "Visible readiness has no STOP Boarding blocker")
	_assert(int(smoke.get("visible_aircraft_count", 0)) >= 1, "Flightdeck exposes at least one visible shipcard")
	_assert(not String(smoke.get("flightdeck_selected_status_text", "")).contains("Flight deck empty"), "Flightdeck status does not render empty blocker")
	_assert(int(smoke.get("payload_operator_count", 0)) > 0, "Dropship payload has operators")
	_assert(int(smoke.get("boarded_operator_count", 0)) >= int(smoke.get("payload_operator_count", 0)), "Dropship payload is boarded")
	_assert(_check_passed(smoke, "cta_inside_mission_panel"), "CTA stays inside MissionPanel")
	_assert(_check_passed(smoke, "cta_label_has_readable_bounds"), "CTA label has readable bounds")
	_assert(_check_passed(smoke, "mission_panel_no_overflow"), "MissionPanel has no overflow")

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
