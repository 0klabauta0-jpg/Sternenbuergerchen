extends SceneTree

const MISSION_INTERACTION_MANUAL_SIGHT_NOTES_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_manual_sight_notes.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_690_mission_interaction_manual_sight_notes.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const WORKBENCH_PATH: String = "res://docs/reports/mission_interaction_manual_sight_notes_2026_06_30.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/mission_interaction_manual_sight_notes.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_690 Mission Interaction Manual Sight Notes ===")
	_test_docs()
	_test_snapshot_contract()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_690: FAILED")
		quit(1)
		return
	print("TASK_690: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_690 task file exists")
	_assert(task_text.contains("Mission Interaction Manual Sight Notes"), "Task documents manual sight notes")
	_assert(contract_text.contains("Manual Sight Notes"), "Interaction contract documents manual sight notes")
	_assert(status_text.contains("TASK_690 - Mission Interaction Manual Sight Notes"), "Implementation status tracks TASK_690")
	_assert(roadmap_text.contains("TASK_690 - Mission Interaction Manual Sight Notes (implementiert)"), "Roadmap marks TASK_690 implemented")
	_assert(handbook_text.contains("TASK_690 - Mission Interaction Manual Sight Notes"), "Current handbook references TASK_690")
	_assert(handbook_text.contains('data-export-key="mission_interaction_manual_sight_notes.manifest_path"'), "Current handbook exports TASK_690 manifest path")
	_assert(FileAccess.file_exists(WORKBENCH_PATH), "Manual sight notes workbench exists")
	_assert(workbench_text.contains("JSON exportieren"), "Workbench exposes JSON export button")
	_assert(workbench_text.contains('data-export-key="manual.real_window_launched"'), "Workbench exports real-window check")
	_assert(workbench_text.contains('data-export-key="manual.next_polish_action"'), "Workbench exports next polish action")


func _test_snapshot_contract() -> void:
	var polish_findings: Dictionary = {
		"schema": "sternenbuergerchen.mission_interaction_visual_polish_findings.v1",
		"status": "needs_manual_review",
		"summary": "technisch gruen, manueller Sichtlauf offen, budget 15/32",
		"manifest_path": "tmp/mission_interaction_visual_polish_findings.json",
	}
	var evidence_manifest: Dictionary = {
		"schema": "sternenbuergerchen.mission_interaction_fullhd_evidence.v1",
		"png_path": "tmp/mission_interaction_fullhd_evidence.png",
		"manifest_path": "tmp/mission_interaction_fullhd_evidence.json",
		"manual_fullhd_review_required": true,
		"manual_fullhd_review_done": false,
	}
	var snapshot: Dictionary = Dictionary(MISSION_INTERACTION_MANUAL_SIGHT_NOTES_SCRIPT.call("build_snapshot", polish_findings, evidence_manifest, {}))
	_assert(_snapshot_is_read_only(snapshot), "Manual sight notes snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.mission_interaction_manual_sight_notes.v1", "Manual sight notes schema is stable")
	_assert(bool(snapshot.get("manual_review_required", false)), "Manual review remains required")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Manual review is not auto-completed")
	_assert(String(snapshot.get("status", "")) == "awaiting_manual_notes", "Snapshot waits for manual notes")
	_assert(int(snapshot.get("required_check_count", 0)) >= 6, "Snapshot defines required manual checks")
	_assert(int(snapshot.get("note_field_count", 0)) >= 5, "Snapshot defines note fields")
	_assert(String(snapshot.get("source_polish_schema", "")) == "sternenbuergerchen.mission_interaction_visual_polish_findings.v1", "Snapshot keeps polish source schema")
	_assert(String(snapshot.get("source_evidence_schema", "")) == "sternenbuergerchen.mission_interaction_fullhd_evidence.v1", "Snapshot keeps evidence source schema")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_691"), "Snapshot recommends next manual review task")


func _test_manifest_write() -> void:
	_ensure_output_dir()
	var snapshot: Dictionary = Dictionary(MISSION_INTERACTION_MANUAL_SIGHT_NOTES_SCRIPT.call("build_snapshot", _fake_polish(), _fake_evidence(), {}))
	snapshot["task_id"] = "TASK_690"
	snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Manual sight notes manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_690", "Manifest records TASK_690")
	_assert(String(parsed.get("status", "")) == "awaiting_manual_notes", "Manifest records open manual notes status")
	_assert(not bool(parsed.get("manual_review_done", true)), "Manifest does not claim manual review done")


func _fake_polish() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.mission_interaction_visual_polish_findings.v1",
		"status": "needs_manual_review",
		"summary": "technisch gruen, manueller Sichtlauf offen, budget 15/32",
		"manifest_path": "tmp/mission_interaction_visual_polish_findings.json",
	}


func _fake_evidence() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.mission_interaction_fullhd_evidence.v1",
		"png_path": "tmp/mission_interaction_fullhd_evidence.png",
		"manifest_path": "tmp/mission_interaction_fullhd_evidence.json",
		"manual_fullhd_review_required": true,
		"manual_fullhd_review_done": false,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_690 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


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
