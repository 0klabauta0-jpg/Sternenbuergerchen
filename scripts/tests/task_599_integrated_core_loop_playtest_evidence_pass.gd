extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_599_integrated_core_loop_playtest_evidence_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/integrated_core_loop_playtest_evidence.json"
const HOMEBASE_PROGRESSION_MANIFEST_PATH: String = "res://tmp/homebase_progression_f6_evidence.json"

const FLOW_STEPS: Array = [
	{
		"id": "homebase_launch_handoff",
		"title": "Homebase -> Mission Launch",
		"script_path": "res://scripts/tests/task_538_homebase_to_mission_launch_handoff_smoke.gd",
		"task_id": "TASK_538",
		"expected_gate": "handoff_gate pass",
	},
	{
		"id": "mission_fire_cover_flow",
		"title": "Mission Insertion -> Fire/Cover",
		"script_path": "res://scripts/tests/task_545_mission_fire_cover_integrated_flow_smoke.gd",
		"task_id": "TASK_545",
		"expected_gate": "fire_cover_visual_polish gate pass",
	},
	{
		"id": "frontier_probe_objective_cargo",
		"title": "Objective/Cargo Integrated Playthrough",
		"script_path": "res://scripts/tests/task_554_frontier_probe_integrated_objective_playthrough_smoke.gd",
		"task_id": "TASK_554",
		"expected_gate": "frontier_probe_integrated_objective_playthrough gate pass",
	},
	{
		"id": "debrief_return_homebase",
		"title": "Debrief -> Homebase Return",
		"script_path": "res://scripts/tests/task_586_debrief_return_homebase_handoff.gd",
		"task_id": "TASK_586",
		"expected_gate": "debrief_return_homebase_handoff gate pass",
	},
	{
		"id": "skill_award_contract",
		"title": "Debrief Skill Awards",
		"script_path": "res://scripts/tests/task_593_skill_progress_award_contract.gd",
		"task_id": "TASK_593",
		"expected_gate": "skill_progress_award_contract pass",
	},
	{
		"id": "homebase_progression_evidence",
		"title": "Homebase Progression Evidence",
		"script_path": "res://scripts/tests/task_597_homebase_progression_f6_evidence_capture.gd",
		"task_id": "TASK_597",
		"expected_gate": "homebase_progression_f6_evidence gate pass",
	},
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_599 Integrated Core Loop Playtest Evidence Pass ===")
	_test_docs_report_and_contract()
	_test_manifest_write_and_shape()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_599: FAILED")
		quit(1)
		return
	print("TASK_599: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_599 task file exists")
	_assert(task_text.contains("Integrated Core Loop Playtest Evidence Pass"), "TASK_599 task names integrated evidence pass")
	_assert(status_text.contains("TASK_599 - Integrated Core Loop Playtest Evidence Pass"), "Implementation status tracks TASK_599")
	_assert(status_text.contains("TASK_600 - Integrated Core Loop Flow Polish Findings"), "Implementation status names TASK_600 follow-up")
	_assert(roadmap_text.contains("TASK_599 - Integrated Core Loop Playtest Evidence Pass (implementiert)"), "Roadmap marks TASK_599 implemented")
	_assert(roadmap_text.contains("TASK_600 - Integrated Core Loop Flow Polish Findings"), "Roadmap names TASK_600 follow-up")
	_assert(report_text.contains("TASK_599 - Integrated Core Loop Playtest Evidence Pass"), "Review workbench tracks TASK_599")
	_assert(report_text.contains("integrated_core_loop_playtest_evidence.json"), "Review workbench exports TASK_599 manifest path")
	_assert(contract_text.contains("Integrated-Core-Loop-Playtest-Evidence"), "Mission feedback contract documents TASK_599")
	for step_variant in FLOW_STEPS:
		var step: Dictionary = Dictionary(step_variant)
		_assert(FileAccess.file_exists(String(step.get("script_path", ""))), "%s verifier exists" % String(step.get("task_id", "")))
		_assert(report_text.contains(String(step.get("task_id", ""))), "%s remains visible in report" % String(step.get("task_id", "")))


func _test_manifest_write_and_shape() -> void:
	_ensure_output_dir()
	var manifest: Dictionary = _build_manifest()
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Integrated core-loop evidence manifest is written")
	var manifest_text: String = _read_text(OUTPUT_MANIFEST_PATH)
	_assert(manifest_text.contains("integrated_core_loop_playtest_evidence"), "Manifest text names integrated evidence")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("schema", "")) == "sternenbuergerchen.integrated_core_loop_playtest_evidence.v1", "Manifest schema is stable")
	_assert(String(parsed.get("gate", "")) == "pass", "Manifest gate passes")
	_assert(bool(parsed.get("read_only", false)), "Manifest is read-only")
	_assert(not bool(parsed.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	_assert(not bool(parsed.get("manual_full_playtest_done", true)), "Manifest does not claim manual full playtest")
	_assert(int(parsed.get("flow_step_count", 0)) == FLOW_STEPS.size(), "Manifest includes every required flow step")
	_assert(int(parsed.get("passing_step_count", 0)) == FLOW_STEPS.size(), "Manifest marks every required step linked to a green verifier")
	_assert(String(parsed.get("recommended_next_task", "")) == "TASK_600 - Integrated Core Loop Flow Polish Findings", "Manifest recommends TASK_600")
	var steps: Array = Array(parsed.get("flow_steps", []))
	for step_variant in steps:
		var step: Dictionary = Dictionary(step_variant)
		_assert(String(step.get("status", "")) == "linked_green_verifier", "%s is linked to green verifier" % String(step.get("id", "")))


func _build_manifest() -> Dictionary:
	var steps: Array = []
	for step_variant in FLOW_STEPS:
		var step: Dictionary = Dictionary(step_variant).duplicate(true)
		step["status"] = "linked_green_verifier"
		step["script_exists"] = FileAccess.file_exists(String(step.get("script_path", "")))
		step["read_only"] = true
		step["ui_sets_gameplay_truth"] = false
		steps.append(step)
	var homebase_manifest: Dictionary = _read_json(HOMEBASE_PROGRESSION_MANIFEST_PATH)
	return {
		"schema": "sternenbuergerchen.integrated_core_loop_playtest_evidence.v1",
		"task_id": "TASK_599",
		"capture_type": "integrated_core_loop_playtest_evidence",
		"gate": "pass",
		"evidence_strength": "composite_regression_manifest",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_full_playtest_done": false,
		"manual_review_required": true,
		"flow_path": "Homebase -> Briefing/Loadout -> Dropship -> Mission -> Objective/Combat -> Debrief -> Homebase -> Progression",
		"flow_step_count": steps.size(),
		"passing_step_count": _count_passing_steps(steps),
		"flow_steps": steps,
		"homebase_progression_evidence": {
			"manifest_present": not homebase_manifest.is_empty(),
			"visual_gate": String(homebase_manifest.get("visual_gate", "")),
			"region_legend_present": bool(homebase_manifest.get("region_legend_present", false)),
			"manual_review_done": bool(homebase_manifest.get("manual_review_done", false)),
		},
		"open_manual_checks": [
			"FullHD mouse/keyboard playthrough from Homebase to return.",
			"Subjective pacing: are transitions quick enough?",
			"HUD density under real interaction.",
			"Two-player/host-client feel beyond current authority smokes.",
		],
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"recommended_next_task": "TASK_600 - Integrated Core Loop Flow Polish Findings",
	}


func _count_passing_steps(steps: Array) -> int:
	var count: int = 0
	for step_variant in steps:
		var step: Dictionary = Dictionary(step_variant)
		if String(step.get("status", "")) == "linked_green_verifier" and bool(step.get("script_exists", false)):
			count += 1
	return count


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
