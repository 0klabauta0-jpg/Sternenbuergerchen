extends SceneTree

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_release_candidate_visible_firefight_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_816_station_reentry_release_candidate_visible_firefight_findings.md"
const TASK_815_PATH: String = "res://docs/tasks/TASK_815_station_reentry_release_candidate_real_window_firefight_sight_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const META_LAYER_PATH: String = "res://scripts/meta/meta_layer_flow.gd"
const HELPER_PATH: String = "res://scripts/mission/station_reentry_release_candidate_visible_firefight_findings.gd"
const MANIFEST_PATH: String = "res://tmp/station_reentry_release_candidate_visible_firefight_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_816 Station Reentry Release Candidate Visible Firefight Findings ===")
	_test_docs_contract_and_report()
	_test_findings_status_routing_and_manifest()
	await _test_meta_layer_method_exists_and_stays_read_only()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_816: FAILED")
		quit(1)
		return
	print("TASK_816: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var meta_text: String = _read_text(META_LAYER_PATH)
	var helper_text: String = _read_text(HELPER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_816 task file exists")
	_assert(FileAccess.file_exists(TASK_815_PATH), "TASK_815 task remains available")
	_assert(task_text.contains("Visible Firefight Findings"), "TASK_816 task names visible firefight findings")
	_assert(status_text.contains("TASK_816 - Station Reentry Release Candidate Visible Firefight Findings"), "Implementation status tracks TASK_816")
	_assert(roadmap_text.contains("TASK_816 - Station Reentry Release Candidate Visible Firefight Findings (implementiert)"), "Roadmap marks TASK_816 implemented")
	_assert(contract_text.contains("Station-Reentry-Release-Candidate-Visible-Firefight-Findings"), "Mission command feedback contract documents TASK_816")
	_assert(report_text.contains("Aktueller Griff: TASK_816"), "Reentry handbook marks TASK_816 current")
	_assert(report_text.contains('data-export-key="reentry_release_candidate_visible_firefight_findings.manual_findings_review_done"'), "Reentry handbook exports TASK_816 review status")
	_assert(meta_text.contains("get_release_candidate_visible_firefight_findings_snapshot"), "MetaLayer exposes TASK_816 snapshot")
	_assert(helper_text.contains("ui_sets_gameplay_truth\": false"), "TASK_816 helper explicitly remains read-only")
	_assert(helper_text.contains("needs_targeted_visible_firefight_polish"), "TASK_816 helper has targeted polish gate")


func _test_findings_status_routing_and_manifest() -> void:
	var not_ready: Dictionary = FINDINGS_SCRIPT.build_snapshot(_task_815_source("needs_real_window_firefight_review"), {}, {})
	_assert(String(not_ready.get("status", "")) == "needs_task_815_real_window_review", "Open TASK_815 review routes back to TASK_815")
	_assert(_snapshot_is_read_only(not_ready), "TASK_816 not-ready snapshot remains read-only")

	var source_with_issue: Dictionary = _task_815_source("needs_visible_firefight_findings", ["firefight_hud_unreadable", "performance_or_stutter"])
	var no_triage: Dictionary = FINDINGS_SCRIPT.build_snapshot(source_with_issue, {}, {})
	_assert(String(no_triage.get("status", "")) == "needs_visible_firefight_findings_review", "Missing findings review routes to review gate")
	_assert(Array(no_triage.get("active_finding_ids", [])).has("firefight_hud_unreadable"), "TASK_815 issue maps to firefight HUD finding")
	_assert(Array(no_triage.get("active_finding_ids", [])).has("performance_stutter_visible"), "TASK_815 performance issue maps to performance finding")

	var partial: Dictionary = FINDINGS_SCRIPT.build_snapshot(source_with_issue, {"manual_findings_review_done": true}, {})
	_assert(String(partial.get("status", "")) == "needs_visible_firefight_findings_completion", "Manual review with missing triage checks routes to completion")
	_assert(not Array(partial.get("missing_check_ids", [])).is_empty(), "Missing triage checks are listed")

	var targeted: Dictionary = FINDINGS_SCRIPT.build_snapshot(source_with_issue, _all_green_findings_notes(), {})
	_assert(String(targeted.get("status", "")) == "needs_targeted_visible_firefight_polish", "Active findings route to targeted polish")
	_assert(int(targeted.get("action_item_count", 0)) >= 2, "Active findings create action items")
	_assert(String(targeted.get("recommended_next_task", "")).contains("Targeted Firefight Polish"), "Targeted findings recommend TASK_817 polish")

	var source_clean: Dictionary = _task_815_source("ready_for_release_candidate_iteration")
	var clean: Dictionary = FINDINGS_SCRIPT.build_snapshot(source_clean, _all_green_findings_notes(), {})
	_assert(String(clean.get("status", "")) == "ready_for_release_candidate_acceptance", "Clean findings route to acceptance")
	_assert(String(clean.get("recommended_next_task", "")).contains("Playable Build Acceptance"), "Clean findings recommend acceptance")

	var note_issue: Dictionary = _all_green_findings_notes()
	note_issue["issues"] = {"panel_overlap_visible": true}
	var noted: Dictionary = FINDINGS_SCRIPT.build_snapshot(source_clean, note_issue, {})
	_assert(String(noted.get("status", "")) == "needs_targeted_visible_firefight_polish", "Note-only findings route to targeted polish")
	_assert(Array(noted.get("active_finding_ids", [])).has("panel_overlap_visible"), "Note-only finding is preserved")

	var manifest: Dictionary = FINDINGS_SCRIPT.write_manifest(MANIFEST_PATH, source_clean, _all_green_findings_notes(), {})
	_assert(FileAccess.file_exists(MANIFEST_PATH), "TASK_816 writes a manifest")
	_assert(String(manifest.get("manifest_path", "")) == MANIFEST_PATH, "TASK_816 manifest path is stable")


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
	_assert(scene != null and scene.name == "MetaLayerTest", "Singleplayer opens MetaLayer scene for TASK_816")
	if scene == null or scene.name != "MetaLayerTest":
		return
	_assert(scene.has_method("get_release_candidate_visible_firefight_findings_snapshot"), "MetaLayer exposes TASK_816 callable")
	if scene.has_method("get_release_candidate_visible_firefight_findings_snapshot"):
		var snapshot: Dictionary = Dictionary(scene.call("get_release_candidate_visible_firefight_findings_snapshot", {}, {}, {}))
		_assert(String(snapshot.get("task_id", "")) == "TASK_816", "MetaLayer TASK_816 snapshot returns task id")
		_assert(_snapshot_is_read_only(snapshot), "MetaLayer TASK_816 snapshot remains read-only")
		_assert(String(snapshot.get("status", "")) != "ready_for_release_candidate_acceptance", "MetaLayer does not auto-accept without window findings")

	scene.queue_free()
	current_scene = null
	await _wait_frames(2)


func _task_815_source(status: String, active_issue_ids: Array = []) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_release_candidate_real_window_firefight_sight_review.v1",
		"task_id": "TASK_815",
		"status": status,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"active_issue_ids": active_issue_ids,
		"missing_check_ids": [],
		"summary": "TASK_815 fixture",
		"firefight_hud_readout": "FT1 Feuer | Cover half | LOS clear | Range 58",
		"player_next_action_line": "Naechster Griff: Hold oder Flank waehlen.",
		"player_why_line": "Warum: erster Gegnerkontakt ist sichtbar.",
		"recommended_next_task": "TASK_816 - Station Reentry Release Candidate Visible Firefight Findings",
	}


func _all_green_findings_notes() -> Dictionary:
	return {
		"manual_findings_review_done": true,
		"firefight_findings_reviewed": true,
		"primary_issue_chosen_or_none": true,
		"action_items_exported": true,
		"no_blocker_unassigned": true,
	}


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
