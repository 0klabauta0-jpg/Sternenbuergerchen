extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_288_regression_gate_coverage_gap_audit.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CROSSWALK_PATH: String = "res://docs/qa/regression_gate_coverage_crosswalk.md"
const REPORT_PATH: String = "res://docs/reviews/regression_gate_coverage_gap_audit.md"

const REQUIRED_RISK_ROWS: Array = [
	{
		"id": "perf_budget",
		"severity": "High",
		"files": [
			"res://scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd",
			"res://scripts/tests/run_task_222_performance_gate.ps1",
			"res://docs/performance/performance_regression_gate.md",
			"res://data/performance_budget_contract.json",
		],
	},
	{
		"id": "asset_locality",
		"severity": "High",
		"files": [
			"res://scripts/tests/task_247_used_asset_project_locality_audit_gate.gd",
			"res://scripts/tests/run_task_247_asset_locality_scan.ps1",
			"res://docs/reviews/used_asset_project_locality_audit.md",
		],
	},
	{
		"id": "playability_routes",
		"severity": "High",
		"files": [
			"res://scripts/tests/task_262_playability_regression_gate_and_manual_open_items.gd",
			"res://scripts/tests/task_257_button_reachability_and_interaction_verifier.gd",
			"res://scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd",
			"res://docs/qa/playability_coverage_matrix.md",
		],
	},
	{
		"id": "help_coverage",
		"severity": "High",
		"files": [
			"res://scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd",
			"res://scripts/tests/task_268_post_help_popup_playability_regression_smoke.gd",
			"res://docs/reports/contextual_help_coverage_layout_report.md",
		],
	},
	{
		"id": "tactical_e2e",
		"severity": "High",
		"files": [
			"res://scripts/tests/task_282_tactical_overhaul_playability_performance_help_gate.gd",
			"res://scripts/tests/task_281_tactical_command_multiplayer_authority_snapshot.gd",
			"res://docs/reports/tactical_overhaul_playability_performance_help_gate.md",
		],
	},
	{
		"id": "multiplayer_authority",
		"severity": "High",
		"files": [
			"res://scripts/tests/task_281_tactical_command_multiplayer_authority_snapshot.gd",
			"res://scripts/tests/task_287_editor_save_multiplayer_contract_regression_review.gd",
			"res://scripts/tests/task_228_multiplayer_editor_map_manifest_download_consent.gd",
			"res://docs/dev/tactical_multiplayer_authority_snapshot.md",
		],
	},
	{
		"id": "gameplay_truth",
		"severity": "High",
		"files": [
			"res://scripts/tests/task_284_gameplay_truth_architecture_boundary_audit.gd",
			"res://scripts/tests/run_task_284_truth_boundary_scan.ps1",
			"res://scripts/tests/task_286_ui_feedback_truth_regression_review.gd",
			"res://docs/reviews/gameplay_truth_architecture_boundary_audit.md",
		],
	},
	{
		"id": "ui_feedback_truth",
		"severity": "High",
		"files": [
			"res://scripts/tests/task_286_ui_feedback_truth_regression_review.gd",
			"res://scripts/tests/task_257_button_reachability_and_interaction_verifier.gd",
			"res://scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd",
			"res://docs/reviews/ui_feedback_truth_regression_review.md",
		],
	},
	{
		"id": "editor_save_multiplayer",
		"severity": "High",
		"files": [
			"res://scripts/tests/task_287_editor_save_multiplayer_contract_regression_review.gd",
			"res://scripts/tests/task_240_multiplayer_player_roster_ownership_contract.gd",
			"res://scripts/tests/task_228_multiplayer_editor_map_manifest_download_consent.gd",
			"res://docs/reviews/editor_save_multiplayer_contract_regression_review.md",
		],
	},
	{
		"id": "docs_truth",
		"severity": "Medium",
		"files": [
			"res://scripts/tests/task_283_post_tactical_docs_consistency_audit.gd",
			"res://scripts/tests/task_288_regression_gate_coverage_gap_audit.gd",
			"res://docs/reviews/post_tactical_docs_consistency_audit.md",
		],
	},
]

const POST_PATCH_RUN_TESTS: PackedStringArray = [
	"task_282_tactical_overhaul_playability_performance_help_gate.gd",
	"task_284_gameplay_truth_architecture_boundary_audit.gd",
	"task_286_ui_feedback_truth_regression_review.gd",
	"task_287_editor_save_multiplayer_contract_regression_review.gd",
	"task_267_contextual_help_coverage_layout_verifier.gd",
	"task_257_button_reachability_and_interaction_verifier.gd",
	"task_222_performance_regression_gate_and_manual_profile_checklist.gd",
	"task_247_used_asset_project_locality_audit_gate.gd",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_288 Regression Gate Coverage Gap Audit ===")
	_test_docs_status_and_report()
	_test_crosswalk_required_risk_rows()
	_test_crosswalk_links_and_high_risk_coverage()
	_test_gate_quality_and_manual_rest_separation()
	_test_patch_backlog_and_post_patch_run_list()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_docs_status_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_288 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("### TASK_288 - Regression Gate Coverage Gap Audit") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_288 implemented")
	_assert(roadmap_text.contains("TASK_288 - Regression Gate Coverage Gap Audit (implementiert)"), "Roadmap marks TASK_288 implemented")
	for token in ["## Findings", "Blocker", "Important", "Gate Quality", "Recommended Patch Run", "Gap Backlog", "TASK_289"]:
		_assert(report_text.contains(token), "Regression gate audit report contains %s" % token)


func _test_crosswalk_required_risk_rows() -> void:
	var crosswalk_text: String = _read_text(CROSSWALK_PATH)
	_assert(not crosswalk_text.is_empty(), "Regression gate crosswalk exists")
	for token in ["Gate Quality Legend", "Coverage Crosswalk", "Hard failure", "Warning-only", "Manual rest", "Patch Backlog", "Post Tactical Patch Run List"]:
		_assert(crosswalk_text.contains(token), "Crosswalk contains %s" % token)
	_assert(not crosswalk_text.contains("TBD") and not crosswalk_text.contains("TODO"), "Crosswalk has no placeholder TODO/TBD")
	for row_variant in REQUIRED_RISK_ROWS:
		var row_config: Dictionary = Dictionary(row_variant)
		var row_id: String = String(row_config.get("id", ""))
		var row: String = _find_markdown_table_row(crosswalk_text, row_id)
		_assert(not row.is_empty(), "Crosswalk has row for %s" % row_id)
		_assert(row.contains(String(row_config.get("severity", ""))), "Crosswalk severity for %s is documented" % row_id)


func _test_crosswalk_links_and_high_risk_coverage() -> void:
	var crosswalk_text: String = _read_text(CROSSWALK_PATH)
	for row_variant in REQUIRED_RISK_ROWS:
		var row_config: Dictionary = Dictionary(row_variant)
		var row_id: String = String(row_config.get("id", ""))
		var row: String = _find_markdown_table_row(crosswalk_text, row_id)
		for file_path_variant in Array(row_config.get("files", [])):
			var file_path: String = String(file_path_variant)
			_assert(FileAccess.file_exists(file_path), "Linked artifact exists for %s: %s" % [row_id, file_path])
			_assert(crosswalk_text.contains(file_path), "Crosswalk links %s for %s" % [file_path.get_file(), row_id])
		if String(row_config.get("severity", "")) == "High":
			_assert(row.to_lower().contains("hard") and row.to_lower().contains("res://scripts/tests/"), "High-risk row %s has an automated hard gate" % row_id)


func _test_gate_quality_and_manual_rest_separation() -> void:
	var crosswalk_text: String = _read_text(CROSSWALK_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	for token in ["Performance", "Asset locality", "Playability", "Help", "Tactical", "Truth/UI/Save"]:
		_assert(report_text.contains(token), "Gate quality table covers %s" % token)
	for row_id in ["perf_budget", "help_coverage", "tactical_e2e", "gameplay_truth"]:
		var row: String = _find_markdown_table_row(crosswalk_text, row_id)
		_assert(row.to_lower().contains("warning") or row.to_lower().contains("manual"), "Row %s separates warning/manual residuals" % row_id)
	for row_id in ["asset_locality", "editor_save_multiplayer", "multiplayer_authority"]:
		var row: String = _find_markdown_table_row(crosswalk_text, row_id)
		_assert(not row.to_lower().contains("sollte man mal"), "Row %s does not hide vague manual checks" % row_id)


func _test_patch_backlog_and_post_patch_run_list() -> void:
	var crosswalk_text: String = _read_text(CROSSWALK_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	for token in ["P1", "CommanderIntent", "AirAssetStatus", "TASK_289", "P2", "Forbidden-token", "Selection", "Disabled-Reason"]:
		_assert(crosswalk_text.contains(token) or report_text.contains(token), "Patch backlog contains %s" % token)
	for test_name in POST_PATCH_RUN_TESTS:
		_assert(crosswalk_text.contains(test_name), "Post-patch run list includes %s" % test_name)
		_assert(FileAccess.file_exists("res://scripts/tests/%s" % test_name), "Post-patch run script exists: %s" % test_name)
	_assert(crosswalk_text.contains("git diff --check"), "Post-patch run list ends with git diff --check")


func _find_markdown_table_row(markdown_text: String, row_id: String) -> String:
	for line in markdown_text.split("\n"):
		if line.begins_with("| %s " % row_id) or line.contains("| %s |" % row_id):
			return line
	return ""


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
