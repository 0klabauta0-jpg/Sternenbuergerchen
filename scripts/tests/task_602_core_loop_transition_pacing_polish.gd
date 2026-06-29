extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_602_core_loop_transition_pacing_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_601_PATH: String = "res://docs/tasks/TASK_601_core_loop_manual_fullhd_playtest_capture.md"
const CAPTURE_MANIFEST_PATH: String = "res://tmp/core_loop_manual_fullhd_playtest_capture.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/core_loop_transition_pacing_polish.json"

const RECOMMENDED_NEXT_TASK: String = "TASK_603 - Mission HUD Density Interaction Polish"

const TRANSITION_BUDGETS: Array = [
	{"id": "homebase_to_briefing", "label": "Homebase -> Briefing", "target_seconds": 3.0, "tolerance_seconds": 1.0, "severity_if_over": "medium"},
	{"id": "briefing_to_dropship", "label": "Briefing -> Dropship", "target_seconds": 4.0, "tolerance_seconds": 1.5, "severity_if_over": "medium"},
	{"id": "dropship_to_mission", "label": "Dropship -> Mission", "target_seconds": 6.0, "tolerance_seconds": 2.0, "severity_if_over": "high"},
	{"id": "mission_first_order", "label": "Mission -> First Order", "target_seconds": 5.0, "tolerance_seconds": 2.0, "severity_if_over": "high"},
	{"id": "mission_to_debrief", "label": "Mission -> Debrief", "target_seconds": 4.0, "tolerance_seconds": 1.5, "severity_if_over": "medium"},
	{"id": "debrief_to_progression", "label": "Debrief -> Progression", "target_seconds": 3.0, "tolerance_seconds": 1.0, "severity_if_over": "medium"},
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_602 Core Loop Transition Pacing Polish ===")
	_test_docs_report_and_contract()
	_test_manifest_write_and_shape()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_602: FAILED")
		quit(1)
		return
	print("TASK_602: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var task_601_text: String = _read_text(TASK_601_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_602 task file exists")
	_assert(task_text.contains("Core Loop Transition Pacing Polish"), "TASK_602 task names transition pacing")
	_assert(task_text.contains("core_loop_transition_pacing_polish.json"), "TASK_602 task names manifest path")
	_assert(task_601_text.contains("TASK_602") and task_601_text.contains("Pacing-Polish"), "TASK_601 points to TASK_602")
	_assert(status_text.contains("TASK_602 - Core Loop Transition Pacing Polish"), "Implementation status tracks TASK_602")
	_assert(status_text.contains(RECOMMENDED_NEXT_TASK), "Implementation status names TASK_603 follow-up")
	_assert(roadmap_text.contains("TASK_602 - Core Loop Transition Pacing Polish (implementiert)"), "Roadmap marks TASK_602 implemented")
	_assert(roadmap_text.contains(RECOMMENDED_NEXT_TASK), "Roadmap names TASK_603 follow-up")
	_assert(report_text.contains("TASK_602 Core-Loop Transition Pacing Polish"), "Review workbench tracks TASK_602")
	_assert(report_text.contains("core_loop_pacing.manifest_path"), "Review workbench exports pacing manifest path")
	_assert(report_text.contains("core_loop_pacing_manual.homebase_to_briefing_checked"), "Review workbench exports pacing manual checks")
	_assert(report_text.contains(RECOMMENDED_NEXT_TASK), "Review workbench recommends TASK_603")
	_assert(contract_text.contains("Core-Loop-Transition-Pacing-Polish"), "Mission feedback contract documents TASK_602")


func _test_manifest_write_and_shape() -> void:
	_ensure_output_dir()
	var manifest: Dictionary = _build_manifest()
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Pacing polish manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("schema", "")) == "sternenbuergerchen.core_loop_transition_pacing_polish.v1", "Manifest schema is stable")
	_assert(String(parsed.get("gate", "")) == "pass", "Manifest gate passes")
	_assert(bool(parsed.get("read_only", false)), "Manifest is read-only")
	_assert(not bool(parsed.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	_assert(not bool(parsed.get("manual_review_done", true)), "Manifest does not claim manual review done")
	_assert(int(parsed.get("transition_budget_count", 0)) == TRANSITION_BUDGETS.size(), "Manifest contains every transition budget")
	_assert(float(parsed.get("total_target_seconds", 0.0)) >= 20.0, "Manifest has non-trivial total pacing target")
	_assert(String(parsed.get("recommended_next_task", "")) == RECOMMENDED_NEXT_TASK, "Manifest recommends TASK_603")
	for budget_variant in Array(parsed.get("transition_budgets", [])):
		var budget: Dictionary = Dictionary(budget_variant)
		_assert(float(budget.get("target_seconds", 0.0)) > 0.0, "%s has target seconds" % String(budget.get("id", "")))
		_assert(float(budget.get("tolerance_seconds", 0.0)) > 0.0, "%s has tolerance seconds" % String(budget.get("id", "")))
		_assert(String(budget.get("severity_if_over", "")) != "", "%s has severity" % String(budget.get("id", "")))


func _build_manifest() -> Dictionary:
	var budgets: Array = []
	for budget_variant in TRANSITION_BUDGETS:
		var budget: Dictionary = Dictionary(budget_variant).duplicate(true)
		budget["status"] = "budget_ready"
		budget["measurement_status"] = "manual_open"
		budget["read_only"] = true
		budget["ui_sets_gameplay_truth"] = false
		budgets.append(budget)
	return {
		"schema": "sternenbuergerchen.core_loop_transition_pacing_polish.v1",
		"task_id": "TASK_602",
		"capture_type": "core_loop_transition_pacing_polish",
		"gate": "pass",
		"source_task": "TASK_601",
		"source_schema": "sternenbuergerchen.core_loop_manual_fullhd_playtest_capture.v1",
		"source_capture_manifest_present": FileAccess.file_exists(CAPTURE_MANIFEST_PATH),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_review_required": true,
		"manual_review_done": false,
		"transition_budget_count": budgets.size(),
		"transition_budgets": budgets,
		"total_target_seconds": _sum_float_key(budgets, "target_seconds"),
		"total_tolerance_seconds": _sum_float_key(budgets, "tolerance_seconds"),
		"budget_policy": "flag over target + tolerance before changing runtime pacing",
		"recommended_next_task": RECOMMENDED_NEXT_TASK,
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	}


func _sum_float_key(items: Array, key: String) -> float:
	var total: float = 0.0
	for item_variant in items:
		var item: Dictionary = Dictionary(item_variant)
		total += float(item.get(key, 0.0))
	return total


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
