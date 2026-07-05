extends SceneTree

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const REAL_WINDOW_REVIEW_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_release_candidate_real_window_firefight_sight_review.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_815_station_reentry_release_candidate_real_window_firefight_sight_review.md"
const TASK_814_PATH: String = "res://docs/tasks/TASK_814_station_reentry_release_candidate_firefight_feel_hud_polish_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const META_LAYER_PATH: String = "res://scripts/meta/meta_layer_flow.gd"
const HELPER_PATH: String = "res://scripts/mission/station_reentry_release_candidate_real_window_firefight_sight_review.gd"
const MANIFEST_PATH: String = "res://tmp/station_reentry_release_candidate_real_window_firefight_sight_review.json"
const TEST_RELEASE_DIR: String = "res://tmp/task_815_release"
const TEST_EXE_PATH: String = "res://tmp/task_815_release/Sternenbuergerchen_rel.exe"
const TEST_PCK_PATH: String = "res://tmp/task_815_release/Sternenbuergerchen_rel.pck"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_815 Station Reentry Release Candidate Real Window Firefight Sight Review ===")
	_test_docs_contract_and_report()
	_test_helper_status_routing_and_manifest()
	await _test_meta_layer_method_exists_and_stays_read_only()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_815: FAILED")
		quit(1)
		return
	print("TASK_815: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var meta_text: String = _read_text(META_LAYER_PATH)
	var helper_text: String = _read_text(HELPER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_815 task file exists")
	_assert(FileAccess.file_exists(TASK_814_PATH), "TASK_814 task remains available")
	_assert(task_text.contains("Real Window Firefight Sight Review"), "TASK_815 task names real-window firefight review")
	_assert(status_text.contains("TASK_815 - Station Reentry Release Candidate Real Window Firefight Sight Review"), "Implementation status tracks TASK_815")
	_assert(roadmap_text.contains("TASK_815 - Station Reentry Release Candidate Real Window Firefight Sight Review (implementiert)"), "Roadmap marks TASK_815 implemented")
	_assert(contract_text.contains("Station-Reentry-Release-Candidate-Real-Window-Firefight-Sight-Review"), "Mission command feedback contract documents TASK_815")
	_assert(report_text.contains("Aktueller Griff: TASK_815"), "Reentry handbook marks TASK_815 current")
	_assert(report_text.contains('data-export-key="reentry_release_candidate_real_window_firefight_sight_review.manual_review_done"'), "Reentry handbook exports TASK_815 review status")
	_assert(meta_text.contains("get_release_candidate_real_window_firefight_sight_review_snapshot"), "MetaLayer exposes TASK_815 snapshot")
	_assert(helper_text.contains("ui_sets_gameplay_truth\": false"), "TASK_815 helper explicitly remains read-only")
	_assert(helper_text.contains("needs_shortcut_refresh"), "TASK_815 helper has shortcut refresh gate")


func _test_helper_status_routing_and_manifest() -> void:
	_prepare_test_release_files()
	var source: Dictionary = _valid_task_814_source()
	var options: Dictionary = _test_options(TEST_EXE_PATH)
	var empty_review: Dictionary = REAL_WINDOW_REVIEW_SCRIPT.build_snapshot(source, {}, options)
	_assert(String(empty_review.get("schema", "")) == "sternenbuergerchen.station_reentry_release_candidate_real_window_firefight_sight_review.v1", "TASK_815 schema is stable")
	_assert(String(empty_review.get("status", "")) == "needs_real_window_firefight_review", "Missing manual review routes to real-window review")
	_assert(_snapshot_is_read_only(empty_review), "TASK_815 snapshot remains read-only")
	_assert(bool(empty_review.get("release_exe_exists", false)), "TASK_815 sees release EXE context")
	_assert(bool(empty_review.get("release_pck_exists", false)), "TASK_815 sees release PCK context")
	_assert(bool(empty_review.get("taskbar_shortcut_matches_release", false)), "TASK_815 sees shortcut target match")

	var wrong_shortcut_options: Dictionary = _test_options("res://tmp/task_815_release/old.exe")
	var wrong_shortcut: Dictionary = REAL_WINDOW_REVIEW_SCRIPT.build_snapshot(source, {"manual_review_done": true}, wrong_shortcut_options)
	_assert(String(wrong_shortcut.get("status", "")) == "needs_shortcut_refresh", "Shortcut mismatch routes to shortcut refresh")

	var partial_notes: Dictionary = {"manual_review_done": true, "visible_window_readback_available": true}
	var partial: Dictionary = REAL_WINDOW_REVIEW_SCRIPT.build_snapshot(source, partial_notes, options)
	_assert(String(partial.get("status", "")) == "needs_real_window_review_completion", "Manual review with missing checks routes to completion")
	_assert(not Array(partial.get("missing_check_ids", [])).is_empty(), "Missing real-window checks are listed")

	var issue_notes: Dictionary = _all_green_review_notes()
	issue_notes["firefight_hud_unreadable"] = true
	var with_issue: Dictionary = REAL_WINDOW_REVIEW_SCRIPT.build_snapshot(source, issue_notes, options)
	_assert(String(with_issue.get("status", "")) == "needs_visible_firefight_findings", "Active real-window issue routes to findings")
	_assert(Array(with_issue.get("active_issue_ids", [])).has("firefight_hud_unreadable"), "Active issue id is preserved")

	var accepted: Dictionary = REAL_WINDOW_REVIEW_SCRIPT.build_snapshot(source, _all_green_review_notes(), options)
	_assert(String(accepted.get("status", "")) == "ready_for_release_candidate_iteration", "Issue-free real-window review routes to release iteration")
	_assert(String(accepted.get("recommended_next_task", "")).begins_with("TASK_816"), "TASK_815 routes next to TASK_816")

	var manifest: Dictionary = REAL_WINDOW_REVIEW_SCRIPT.write_manifest(MANIFEST_PATH, source, _all_green_review_notes(), options)
	_assert(FileAccess.file_exists(MANIFEST_PATH), "TASK_815 writes a manifest")
	_assert(String(manifest.get("manifest_path", "")) == MANIFEST_PATH, "TASK_815 manifest path is stable")


func _test_meta_layer_method_exists_and_stays_read_only() -> void:
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	root.add_child(menu)
	current_scene = menu
	await _wait_frames(4)

	var singleplayer_button := menu.get_node_or_null("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton") as Button
	_assert(singleplayer_button != null, "Main menu exposes Singleplayer button")
	if singleplayer_button == null:
		menu.queue_free()
		current_scene = null
		await _wait_frames(2)
		return

	singleplayer_button.pressed.emit()
	await _wait_frames(12)

	var scene: Node = current_scene
	_assert(scene != null and scene.name == "MetaLayerTest", "Singleplayer opens MetaLayer scene for TASK_815")
	if scene == null or scene.name != "MetaLayerTest":
		return
	_assert(scene.has_method("get_release_candidate_real_window_firefight_sight_review_snapshot"), "MetaLayer exposes TASK_815 callable")
	if scene.has_method("get_release_candidate_real_window_firefight_sight_review_snapshot"):
		var snapshot: Dictionary = Dictionary(scene.call("get_release_candidate_real_window_firefight_sight_review_snapshot", {}, _test_options(TEST_EXE_PATH)))
		_assert(String(snapshot.get("task_id", "")) == "TASK_815", "MetaLayer TASK_815 snapshot returns task id")
		_assert(_snapshot_is_read_only(snapshot), "MetaLayer TASK_815 snapshot remains read-only")
		_assert(String(snapshot.get("status", "")) != "ready_for_release_candidate_iteration", "MetaLayer does not auto-accept without manual window notes")

	scene.queue_free()
	current_scene = null
	await _wait_frames(2)


func _valid_task_814_source() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_release_candidate_firefight_feel_hud_polish_review.v1",
		"task_id": "TASK_814",
		"status": "pass",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"compact_line": "FT1 Feuer | Cover half | LOS clear | Range 58",
		"player_next_action_line": "Naechster Griff: Hold oder Flank waehlen.",
		"player_why_line": "Warum: erster Gegnerkontakt ist sichtbar und das Fireteam hat Feuerlinie.",
	}


func _all_green_review_notes() -> Dictionary:
	return {
		"manual_review_done": true,
		"visible_window_readback_available": true,
		"fresh_release_exe_started": true,
		"taskbar_shortcut_target_verified": true,
		"singleplayer_homebase_actionable": true,
		"start_mission_reachable": true,
		"lz_drop_preview_go_reached": true,
		"first_firefight_hud_readable": true,
		"next_player_action_understandable": true,
		"no_stop_homebase_blockers": true,
		"no_panel_overlap_visible": true,
		"notes_exported": true,
	}


func _test_options(shortcut_target: String) -> Dictionary:
	return {
		"release_dir": TEST_RELEASE_DIR,
		"exe_path": TEST_EXE_PATH,
		"pck_path": TEST_PCK_PATH,
		"taskbar_shortcut_target": shortcut_target,
		"expected_taskbar_shortcut_target": TEST_EXE_PATH,
		"manifest_path": MANIFEST_PATH,
		"report_path": REPORT_PATH,
	}


func _prepare_test_release_files() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_RELEASE_DIR))
	_write_text(TEST_EXE_PATH, "task815 test exe placeholder")
	_write_text(TEST_PCK_PATH, "task815 test pck placeholder")


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()


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
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
