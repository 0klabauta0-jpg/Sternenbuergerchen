extends SceneTree

const Findings := preload("res://scripts/mission/release_firefight_world_label_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_841_release_firefight_world_label_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_firefight_world_label_visual_findings.gd"
const ACTUAL_RECAPTURE_PATH := "res://tmp/release_firefight_world_label_real_window_recapture.json"
const OUTPUT_PATH := "res://tmp/release_firefight_world_label_visual_findings.json"
const SCHEMA := "sternenbuergerchen.release_firefight_world_label_visual_findings.v1"
const DENSITY_MODE := "release_firefight_declutter"
const STYLE_ID := "task_839_release_firefight_world_label_declutter_v1"
const NEXT_TASK := "TASK_842 - Release Firefight Insertion Residue Declutter"
const SECONDARY_NEXT_TASK := "TASK_843 - Release First Firefight Contact Framing"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_841 Release Firefight World Label Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_manifest_blocks()
	_test_review_ready_manifest_builds_findings()
	_test_optional_actual_recapture_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_841_release_firefight_world_label_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_841_release_firefight_world_label_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_841 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_841 read-only analyzer exists")
	_assert(task_text.contains("Release Firefight World Label Visual Findings"), "Task names visual findings")
	_assert(status_text.contains("TASK_841 - Release Firefight World Label Visual Findings"), "Implementation status tracks TASK_841")
	_assert(roadmap_text.contains("TASK_841 - Release Firefight World Label Visual Findings (implementiert)"), "Roadmap marks TASK_841 implemented")
	_assert(roadmap_text.contains("TASK_842 - Release Firefight Insertion Residue Declutter"), "Roadmap names TASK_842 follow-up")
	_assert(contract_text.contains("Release-Firefight-World-Label-Visual-Findings"), "Contract documents TASK_841")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_841 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_841\""), "Analyzer writes TASK_841 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_840\""), "Analyzer links TASK_840 source")
	_assert(service_text.contains(NEXT_TASK), "Analyzer recommends TASK_842")
	_assert(service_text.contains(SECONDARY_NEXT_TASK), "Analyzer recommends TASK_843 as secondary")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"ui_sets_gameplay_truth\": false"), "Analyzer declares no gameplay truth mutation")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")


func _test_missing_manifest_blocks() -> void:
	var snapshot: Dictionary = Findings.build_snapshot({}, {})
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing recapture manifest blocks visual findings")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 4, "Missing manifest creates blocker set")
	_assert(_issue_ids(Array(snapshot.get("blocking_issues", []))).has("recapture_not_review_ready"), "Missing manifest reports recapture_not_review_ready")
	_assert(_issue_ids(Array(snapshot.get("blocking_issues", []))).has("window_screenshot_missing"), "Missing manifest reports window_screenshot_missing")
	_assert(not bool(snapshot.get("density_mode_ok", true)), "Missing manifest fails density mode check")
	_assert(not bool(snapshot.get("style_id_ok", true)), "Missing manifest fails style id check")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot is still read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot still creates no commands")


func _test_review_ready_manifest_builds_findings() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_recapture_manifest(), _manual_review_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_841")
	_assert(String(snapshot.get("task_id", "")) == "TASK_841", "Snapshot task id matches TASK_841")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_840", "Snapshot links TASK_840")
	_assert(String(snapshot.get("recapture_gate", "")) == "review_ready", "Snapshot accepts TASK_840 review_ready gate")
	_assert(bool(snapshot.get("density_mode_ok", false)), "Snapshot accepts expected density mode")
	_assert(bool(snapshot.get("style_id_ok", false)), "Snapshot accepts expected style id")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Review-ready manifest has no technical blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_polish", "Manual notes produce ready_for_polish")
	_assert(bool(snapshot.get("manual_notes_present", false)), "Snapshot records manual notes present")
	_assert(int(snapshot.get("positive_finding_count", 0)) >= 3, "Snapshot records positive visual findings")
	_assert(issue_ids.has("insertion_residue_world_labels"), "Snapshot records insertion residue finding")
	_assert(issue_ids.has("first_firefight_no_fire_contact"), "Snapshot records no-fire-contact warning")
	_assert(issue_ids.has("map_text_near_units_crowded"), "Snapshot records crowded map-text finding")
	_assert(String(snapshot.get("primary_issue_id", "")) == "insertion_residue_world_labels", "Insertion residue is primary issue")
	_assert(int(snapshot.get("warning_count", 0)) >= 1, "Snapshot records warning count")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_842")
	_assert(String(snapshot.get("secondary_recommended_next_task", "")) == SECONDARY_NEXT_TASK, "Snapshot recommends TASK_843 secondary")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "Snapshot creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")


func _test_optional_actual_recapture_manifest() -> void:
	if not FileAccess.file_exists(ACTUAL_RECAPTURE_PATH):
		_assert(true, "TASK_840 recapture manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(ACTUAL_RECAPTURE_PATH)
	var snapshot: Dictionary = Findings.build_snapshot(manifest, _manual_review_notes())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual recapture builds TASK_841 schema")
	_assert(bool(snapshot.get("read_only", false)), "Actual recapture snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual recapture snapshot sets no gameplay truth")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Actual recapture snapshot keeps TASK_842 recommendation")


func _test_manifest_roundtrip() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_recapture_manifest(), _manual_review_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_841 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_841", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip manifest keeps next task")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "insertion_residue_world_labels", "Roundtrip manifest keeps primary issue")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip manifest keeps read-only boundary")


func _good_recapture_manifest() -> Dictionary:
	return {
		"gate": "review_ready",
		"expected_world_label_density_mode": DENSITY_MODE,
		"expected_world_label_declutter_style_id": STYLE_ID,
		"window_screenshot_written": true,
		"window_screenshot_path": "tmp/release_firefight_world_label_real_window.png",
		"required_checks": [
			"world_labels_less_dense_than_task_837",
			"event_log_or_fallback_still_carries_detail",
			"command_matrix_go_still_visible",
			"fire_vfx_trace_and_impact_visible",
			"friendly_fire_warning_preserved",
			"critical_unit_state_badges_preserved",
		],
		"manual_review_required": true,
		"manual_review_done": false,
	}


func _manual_review_notes() -> Dictionary:
	return {
		"manual_notes_present": true,
		"world_label_density_improved": true,
		"hud_detail_surfaces_readable": true,
		"command_matrix_visible": true,
		"insertion_residue_world_labels": true,
		"first_firefight_no_fire_contact": true,
		"map_text_near_units_crowded": true,
	}


func _issue_ids(issues: Array) -> Array:
	var ids: Array = []
	for issue_variant in issues:
		ids.append(String(Dictionary(issue_variant).get("id", "")))
	return ids


func _read_json_dict(path: String) -> Dictionary:
	var text: String = _read_text(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed)
	return {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
