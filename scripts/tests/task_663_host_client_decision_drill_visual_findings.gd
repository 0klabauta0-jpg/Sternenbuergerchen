extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_663_host_client_decision_drill_visual_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CURRENT_REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const FOB_FIRETEAM_CARD_PATH: String = "res://scripts/meta/fob_fireteam_card.gd"
const MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"

const EXPECTED_STYLE_ID: String = "host_client_fireteam_context_badge_v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_663 Host Client Decision Drill Visual Findings ===")
	_test_docs_report_and_contract()
	_test_real_capture_finding_source()
	_test_review_session_card_context()
	_test_fireteam_card_status_label_context()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_663: FAILED")
		quit(1)
		return
	print("TASK_663: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(CURRENT_REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_663 task file exists")
	_assert(task_text.contains("Host Client Decision Drill Visual Findings"), "TASK_663 task names visual findings")
	_assert(status_text.contains("TASK_663 - Host Client Decision Drill Visual Findings"), "Implementation status tracks TASK_663")
	_assert(roadmap_text.contains("TASK_663 - Host Client Decision Drill Visual Findings (implementiert)"), "Roadmap marks TASK_663 implemented")
	_assert(contract_text.contains("Host-Client-Decision-Drill-Visual-Findings"), "Mission feedback contract documents TASK_663")
	_assert(report_text.contains("TASK_663 - Host Client Decision Drill Visual Findings"), "Current handbook report tracks TASK_663")
	_assert(report_text.contains('latest_completed_task: "TASK_663 - Host Client Decision Drill Visual Findings"'), "Current handbook export records TASK_663 latest")
	_assert(report_text.contains('data-export-key="host_client_decision_drill_visual_findings.fireteam_card_context_badge"'), "Current handbook exports TASK_663 badge finding")
	_assert(report_text.contains('data-note-key="notes.host_client_decision_drill_visual_findings"'), "Current handbook exports TASK_663 notes")
	_assert(controller_text.contains("REVIEW_SESSION_FIRETEAM_CARD_STYLE_ID"), "Controller defines fireteam context style id")
	_assert(controller_text.contains("_build_fireteam_review_session_card_context"), "Controller exposes fireteam review session context helper")
	_assert(controller_text.contains("review_session_context_text"), "Fireteam status snapshot exports review session context text")


func _test_real_capture_finding_source() -> void:
	_assert(FileAccess.file_exists(MANIFEST_PATH), "TASK_662 real-run manifest exists for visual findings")
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	_assert(bool(manifest.get("launch_requested", false)), "Manifest came from a launched visible run")
	_assert(bool(manifest.get("screenshot_written", false)), "Manifest records desktop screenshot")
	_assert(bool(manifest.get("host_screenshot_written", false)), "Manifest records host crop")
	_assert(bool(manifest.get("client_screenshot_written", false)), "Manifest records client crop")
	_assert(String(manifest.get("decision_drill_capture_task_id", "")) == "TASK_662", "Manifest keeps TASK_662 decision drill source")
	_assert(String(manifest.get("decision_drill_review_gate", "")) == "review_ready", "Decision drill capture is review-ready")
	_assert(not bool(manifest.get("decision_drill_review_done", true)), "Decision drill review is not falsely marked done")
	_assert(String(manifest.get("client_expected_badge_text", "")) == "CLIENT P2 BRAVO", "Capture source contains client Bravo header")
	_assert(String(manifest.get("host_expected_badge_text", "")) == "HOST P1 ALPHA", "Capture source contains host Alpha header")


func _test_review_session_card_context() -> void:
	var controller_script: GDScript = load(CONTROLLER_PATH)
	var controller: Node = controller_script.new()
	var context: Dictionary = Dictionary(controller.call("_build_fireteam_review_session_card_context", {
		"role_label": "CLIENT",
		"peer_label": "P2",
		"team_label": "BRAVO",
	}))
	_assert(bool(context.get("visible", false)), "Review session context is visible")
	_assert(String(context.get("text", "")) == "P2 BRAVO", "Review session card context is compact")
	_assert(String(context.get("full_text", "")) == "CLIENT P2 BRAVO", "Review session context keeps full tooltip text")
	_assert(String(context.get("style_id", "")) == EXPECTED_STYLE_ID, "Review session context uses TASK_663 style id")
	_assert(String(context.get("tooltip_text", "")).contains("CLIENT P2 BRAVO"), "Review session context tooltip names client Bravo")
	_assert(bool(context.get("read_only", false)), "Review session context is read-only")
	_assert(not bool(context.get("ui_sets_gameplay_truth", true)), "Review session context does not set gameplay truth")
	controller.free()


func _test_fireteam_card_status_label_context() -> void:
	var controller_script: GDScript = load(CONTROLLER_PATH)
	var card_script: GDScript = load(FOB_FIRETEAM_CARD_PATH)
	var controller: Node = controller_script.new()
	var card: Control = card_script.new()
	root.add_child(card)
	card.call("setup_card", "blue", "BLUE", true, false, "medium", "Lead Anja Voss | 5 Mitglieder", "mission_mini")
	var status_snapshot := {
		"secondary_text": "P2 BRAVO | SUPP 0% | MV - | POS G15,27",
		"primary_text": "Lead Anja Voss | EX RDY",
		"tooltip_text": "Review Session: CLIENT P2 BRAVO",
		"review_session_context_text": "P2 BRAVO",
		"review_session_context_visible": true,
		"review_session_context_style_id": EXPECTED_STYLE_ID,
	}
	controller.call("_apply_fireteam_mini_status_summary", card, status_snapshot)
	var stage_label := card.get_node_or_null("Margin/VBox/StageLabel") as Label
	_assert(stage_label != null, "Mission mini card has a stage label")
	if stage_label != null:
		_assert(stage_label.text.begins_with("P2 BRAVO | SUPP"), "Stage label starts with peer/team context")
		_assert(bool(stage_label.get_meta("review_session_fireteam_context_visible", false)), "Stage label marks review session context visible")
		_assert(String(stage_label.get_meta("review_session_fireteam_context_text", "")) == "P2 BRAVO", "Stage label stores peer/team context text")
		_assert(String(stage_label.get_meta("review_session_fireteam_context_style_id", "")) == EXPECTED_STYLE_ID, "Stage label stores peer/team context style")
	card.queue_free()
	controller.free()


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
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
