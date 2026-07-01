extends SceneTree

const FIRETEAM_CARD_CONTEXT_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_host_client_fireteam_card_context.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_773_station_reentry_host_client_identity_cue_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_773 Station Reentry Host Client Identity Cue Polish ===")
	_test_docs_contract_report_and_controller_integration()
	_test_own_team_context_is_compact_and_read_only()
	_test_foreign_team_context_marks_view_relation()
	_test_unknown_fireteam_team_stays_honest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_773: FAILED")
		quit(1)
		return
	print("TASK_773: ALL PASSED")
	quit(0)


func _test_docs_contract_report_and_controller_integration() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_773 task file exists")
	_assert(task_text.contains("Station Reentry Host Client Identity Cue Polish"), "TASK_773 task names identity cue polish")
	_assert(status_text.contains("TASK_773 - Station Reentry Host Client Identity Cue Polish"), "Implementation status tracks TASK_773")
	_assert(roadmap_text.contains("TASK_773 - Station Reentry Host Client Identity Cue Polish (implementiert)"), "Roadmap marks TASK_773 implemented")
	_assert(contract_text.contains("Station-Reentry-Host-Client-Identity-Cue-Polish"), "Mission command feedback contract documents TASK_773")
	_assert(report_text.contains("Aktueller Griff: TASK_787"), "Reentry handbook advances to TASK_787 current")
	_assert(report_text.contains('data-export-key="reentry_identity_cue.fireteam_card_relation_visible"'), "Reentry handbook exports identity cue check")
	_assert(controller_text.contains("STATION_REENTRY_HOST_CLIENT_FIRETEAM_CARD_CONTEXT_SCRIPT"), "Controller preloads identity cue presenter")
	_assert(controller_text.contains("_resolve_fireteam_team_id_from_units"), "Controller resolves fireteam team from units")


func _test_own_team_context_is_compact_and_read_only() -> void:
	var snapshot: Dictionary = Dictionary(FIRETEAM_CARD_CONTEXT_SCRIPT.call("build_context", _build_session("host", 1, "team_alpha"), _build_fireteam("blue", "team_alpha")))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_host_client_fireteam_card_context.v1", "Fireteam-card schema is stable")
	_assert(String(snapshot.get("relation", "")) == "own", "Own-team fireteam relation is own")
	_assert(String(snapshot.get("text", "")) == "OWN P1 ALPHA", "Own-team text is compact")
	_assert(bool(snapshot.get("context_is_own_team", false)), "Own-team context flag is true")
	_assert(String(snapshot.get("tooltip_text", "")).contains("Relation: own team"), "Own-team tooltip explains relation")
	_assert(_snapshot_is_read_only(snapshot), "Own-team snapshot is read-only")


func _test_foreign_team_context_marks_view_relation() -> void:
	var snapshot: Dictionary = Dictionary(FIRETEAM_CARD_CONTEXT_SCRIPT.call("build_context", _build_session("client", 2, "team_bravo"), _build_fireteam("blue", "team_alpha")))
	_assert(String(snapshot.get("relation", "")) == "foreign", "Foreign fireteam relation is foreign")
	_assert(String(snapshot.get("text", "")) == "P2 BRAVO VIEW ALPHA", "Foreign-team text shows session plus viewed fireteam team")
	_assert(bool(snapshot.get("context_is_foreign_team", false)), "Foreign-team context flag is true")
	_assert(String(snapshot.get("tooltip_text", "")).contains("Fireteam: BLUE (ALPHA)"), "Foreign-team tooltip names fireteam team")
	_assert(_snapshot_is_read_only(snapshot), "Foreign-team snapshot is read-only")


func _test_unknown_fireteam_team_stays_honest() -> void:
	var snapshot: Dictionary = Dictionary(FIRETEAM_CARD_CONTEXT_SCRIPT.call("build_context", _build_session("client", 2, "team_bravo"), _build_fireteam("blue", "")))
	_assert(String(snapshot.get("relation", "")) == "unknown", "Missing fireteam team remains unknown")
	_assert(String(snapshot.get("text", "")) == "P2 BRAVO FT ?", "Unknown-team text does not guess ownership")
	_assert(bool(snapshot.get("context_team_unknown", false)), "Unknown-team context flag is true")
	_assert(String(snapshot.get("tooltip_text", "")).contains("Relation: team unknown"), "Unknown-team tooltip explains uncertainty")
	_assert(_snapshot_is_read_only(snapshot), "Unknown-team snapshot is read-only")


func _build_session(role: String, peer_id: int, team_id: String) -> Dictionary:
	return {
		"role": role,
		"role_label": role.to_upper(),
		"peer_id": peer_id,
		"peer_label": "P%d" % peer_id,
		"team_id": team_id,
		"team_label": "ALPHA" if team_id == "team_alpha" else "BRAVO" if team_id == "team_bravo" else "",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _build_fireteam(fireteam_id: String, team_id: String) -> Dictionary:
	return {
		"fireteam_id": fireteam_id,
		"fireteam_team_id": team_id,
		"fireteam_team_label": "ALPHA" if team_id == "team_alpha" else "BRAVO" if team_id == "team_bravo" else "",
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true))


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
