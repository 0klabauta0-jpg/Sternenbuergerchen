extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_600_integrated_core_loop_flow_polish_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_599_PATH: String = "res://docs/tasks/TASK_599_integrated_core_loop_playtest_evidence_pass.md"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/integrated_core_loop_flow_polish_findings.json"

const RECOMMENDED_NEXT_TASK: String = "TASK_601 - Core Loop Manual FullHD Playtest Capture"

const FLOW_FINDINGS: Array = [
	{
		"id": "manual_fullhd_capture_missing",
		"priority": "P0",
		"title": "FullHD Gesamtfluss nicht menschlich bestaetigt",
		"source": "TASK_599 open_manual_checks",
		"impact": "Spielgefuehl, Pacing und echte Klickwege sind noch nicht belegt.",
		"next_task": "TASK_601 - Core Loop Manual FullHD Playtest Capture",
	},
	{
		"id": "transition_pacing_unverified",
		"priority": "P1",
		"title": "Homebase-Dropship-Mission-Debrief Pacing nur indirekt belegt",
		"source": "TASK_599 composite flow evidence",
		"impact": "Der Flow kann technisch gruen sein und sich trotzdem zaeh anfuehlen.",
		"next_task": "TASK_602 - Core Loop Transition Pacing Polish",
	},
	{
		"id": "mission_hud_density_unverified",
		"priority": "P1",
		"title": "Mission-HUD-Dichte im Gesamtfluss offen",
		"source": "Rolling report open risks",
		"impact": "Teamchip, Threat Preview, ROE, SUP, Objective und AAR-Infos koennen zusammen zu voll wirken.",
		"next_task": "TASK_603 - Mission HUD Density Interaction Polish",
	},
	{
		"id": "host_client_feel_unverified",
		"priority": "P2",
		"title": "Host/Client-Gefuehl ueber den Core Loop offen",
		"source": "TASK_555-557 authority/readability smokes plus TASK_599 manual check",
		"impact": "Autoritaet und Snapshots sind belegt, aber Zwei-Spieler-Bediengefuehl nicht.",
		"next_task": "TASK_604 - Core Loop Host Client Feel Smoke",
	},
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_600 Integrated Core Loop Flow Polish Findings ===")
	_test_docs_report_and_contract()
	_test_manifest_write_and_shape()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_600: FAILED")
		quit(1)
		return
	print("TASK_600: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var task_599_text: String = _read_text(TASK_599_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_600 task file exists")
	_assert(task_text.contains("Integrated Core Loop Flow Polish Findings"), "TASK_600 task names flow polish findings")
	_assert(task_text.contains("integrated_core_loop_flow_polish_findings.json"), "TASK_600 task names manifest path")
	_assert(task_599_text.contains("Composite-Evidence-Manifest"), "TASK_599 remains the source evidence")
	_assert(status_text.contains("TASK_600 - Integrated Core Loop Flow Polish Findings"), "Implementation status tracks TASK_600")
	_assert(status_text.contains(RECOMMENDED_NEXT_TASK), "Implementation status names TASK_601 follow-up")
	_assert(roadmap_text.contains("TASK_600 - Integrated Core Loop Flow Polish Findings (implementiert)"), "Roadmap marks TASK_600 implemented")
	_assert(roadmap_text.contains(RECOMMENDED_NEXT_TASK), "Roadmap names TASK_601 follow-up")
	_assert(report_text.contains("TASK_600 Integrated Core-Loop Flow-Polish Findings"), "Review workbench tracks TASK_600")
	_assert(report_text.contains("flow_polish_findings.manifest_path"), "Review workbench exports flow polish manifest path")
	_assert(report_text.contains("flow_polish_manual.fullhd_route_checked"), "Review workbench exports manual flow checklist")
	_assert(report_text.contains(RECOMMENDED_NEXT_TASK), "Review workbench recommends TASK_601")
	_assert(contract_text.contains("Integrated-Core-Loop-Flow-Polish-Findings"), "Mission feedback contract documents TASK_600")


func _test_manifest_write_and_shape() -> void:
	_ensure_output_dir()
	var manifest: Dictionary = _build_manifest()
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Flow polish findings manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("schema", "")) == "sternenbuergerchen.integrated_core_loop_flow_polish_findings.v1", "Manifest schema is stable")
	_assert(String(parsed.get("gate", "")) == "pass", "Manifest gate passes")
	_assert(bool(parsed.get("read_only", false)), "Manifest is read-only")
	_assert(not bool(parsed.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	_assert(not bool(parsed.get("manual_full_playtest_done", true)), "Manifest does not claim manual full playtest")
	_assert(int(parsed.get("finding_count", 0)) == FLOW_FINDINGS.size(), "Manifest includes all flow polish findings")
	_assert(int(parsed.get("actionable_followup_count", 0)) == FLOW_FINDINGS.size(), "Every finding is actionable follow-up")
	_assert(String(parsed.get("recommended_next_task", "")) == RECOMMENDED_NEXT_TASK, "Manifest recommends TASK_601")
	var findings: Array = Array(parsed.get("findings", []))
	for finding_variant in findings:
		var finding: Dictionary = Dictionary(finding_variant)
		_assert(String(finding.get("status", "")) == "actionable_followup", "%s is actionable" % String(finding.get("id", "")))
		_assert(String(finding.get("priority", "")) != "", "%s has priority" % String(finding.get("id", "")))
		_assert(String(finding.get("next_task", "")).begins_with("TASK_"), "%s has next task" % String(finding.get("id", "")))


func _build_manifest() -> Dictionary:
	var findings: Array = []
	for finding_variant in FLOW_FINDINGS:
		var finding: Dictionary = Dictionary(finding_variant).duplicate(true)
		finding["status"] = "actionable_followup"
		finding["read_only"] = true
		finding["ui_sets_gameplay_truth"] = false
		findings.append(finding)
	return {
		"schema": "sternenbuergerchen.integrated_core_loop_flow_polish_findings.v1",
		"task_id": "TASK_600",
		"capture_type": "integrated_core_loop_flow_polish_findings",
		"gate": "pass",
		"source_task": "TASK_599",
		"source_schema": "sternenbuergerchen.integrated_core_loop_playtest_evidence.v1",
		"source_evidence_strength": "composite_regression_manifest",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_full_playtest_done": false,
		"manual_review_required": true,
		"finding_count": findings.size(),
		"actionable_followup_count": _count_actionable(findings),
		"findings": findings,
		"recommended_next_task": RECOMMENDED_NEXT_TASK,
		"recommended_followup_tasks": [
			RECOMMENDED_NEXT_TASK,
			"TASK_602 - Core Loop Transition Pacing Polish",
			"TASK_603 - Mission HUD Density Interaction Polish",
			"TASK_604 - Core Loop Host Client Feel Smoke",
		],
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	}


func _count_actionable(findings: Array) -> int:
	var count: int = 0
	for finding_variant in findings:
		var finding: Dictionary = Dictionary(finding_variant)
		if String(finding.get("status", "")) == "actionable_followup":
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
