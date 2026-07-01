extends SceneTree

const CHECK_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_host_client_polished_surface_check.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_786_station_reentry_firefight_host_client_polished_surface_check.md"
const TASK_785_PATH: String = "res://docs/tasks/TASK_785_station_reentry_firefight_command_surface_visible_findings_refresh.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_host_client_polished_surface_check.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_786 Station Reentry Firefight Host Client Polished Surface Check ===")
	_test_docs_contract_and_report()
	_test_matching_host_client_surface_passes()
	_test_quick_action_mismatch_routes_to_alignment()
	_test_identity_context_mismatch_routes_to_identity_cue()
	_test_unready_sources_block()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_786: FAILED")
		quit(1)
		return
	print("TASK_786: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_786 task file exists")
	_assert(FileAccess.file_exists(TASK_785_PATH), "TASK_785 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Host Client Polished Surface Check"), "TASK_786 task names host/client polished surface check")
	_assert(status_text.contains("TASK_786 - Station Reentry Firefight Host Client Polished Surface Check"), "Implementation status tracks TASK_786")
	_assert(roadmap_text.contains("TASK_786 - Station Reentry Firefight Host Client Polished Surface Check (implementiert)"), "Roadmap marks TASK_786 implemented")
	_assert(contract_text.contains("Station-Reentry-Firefight-Host-Client-Polished-Surface-Check"), "Mission command feedback contract documents TASK_786")
	_assert(report_text.contains("Aktueller Griff: TASK_788"), "Reentry handbook marks TASK_788 current")
	_assert(report_text.contains("station_reentry_firefight_host_client_polished_surface_check.json"), "Reentry handbook names TASK_786 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_host_client_polished_surface.same_quick_action_labels"'), "Reentry handbook exports TASK_786 quick-action sync")
	_assert(report_text.contains('data-export-key="reentry_firefight_host_client_polished_surface.peer_context_distinct"'), "Reentry handbook exports TASK_786 peer context")


func _test_matching_host_client_surface_passes() -> void:
	var snapshot: Dictionary = Dictionary(CHECK_SCRIPT.call("build_snapshot", _surface("host", 1, "team_alpha"), _surface("client", 2, "team_bravo"), {}))
	_assert(_snapshot_is_read_only(snapshot), "TASK_786 snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_host_client_polished_surface_check.v1", "TASK_786 schema is stable")
	_assert(String(snapshot.get("status", "")) == "ready_for_host_client_polished_surface_review", "Matching surfaces are ready")
	_assert(String(snapshot.get("sync_gate", "")) == "pass", "Matching surfaces pass sync gate")
	_assert(bool(snapshot.get("ready_for_visible_host_client_polished_surface_review", false)), "Ready flag is true")
	_assert(bool(snapshot.get("same_style_id", false)), "Style id matches")
	_assert(bool(snapshot.get("same_surface_priority_order", false)), "Priority order matches")
	_assert(bool(snapshot.get("same_interaction_line", false)), "Interaction line matches")
	_assert(bool(snapshot.get("same_primary_action_label", false)), "Primary action matches")
	_assert(bool(snapshot.get("same_quick_action_labels", false)), "Quick actions match")
	_assert(bool(snapshot.get("same_guard_line", false)), "Guard line matches")
	_assert(bool(snapshot.get("same_summary_line", false)), "Summary line matches")
	_assert(bool(snapshot.get("same_no_auto_command_commit", false)), "No-auto-command expectation matches")
	_assert(bool(snapshot.get("same_existing_commands_only", false)), "Existing-commands expectation matches")
	_assert(bool(snapshot.get("peer_context_distinct", false)), "Peer context is distinct")
	_assert(bool(snapshot.get("team_context_present", false)), "Team context is present")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_787"), "Clean check routes to TASK_787")


func _test_quick_action_mismatch_routes_to_alignment() -> void:
	var client: Dictionary = _surface("client", 2, "team_bravo")
	client["expected_quick_action_labels"] = ["HOLD", "FLANK", "SUP", "MOVE"]
	var snapshot: Dictionary = Dictionary(CHECK_SCRIPT.call("build_snapshot", _surface("host", 1, "team_alpha"), client, {}))
	_assert(String(snapshot.get("status", "")) == "needs_host_client_polished_surface_alignment", "Quick-action mismatch routes to alignment")
	_assert(String(snapshot.get("sync_gate", "")) == "review", "Mismatch gates to review")
	_assert(not bool(snapshot.get("same_quick_action_labels", true)), "Quick-action mismatch is recorded")
	_assert(Array(snapshot.get("failed_checks", [])).has("same_quick_action_labels"), "Failed checks include quick actions")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_770"), "Surface mismatch routes to host/client sync")
	_assert(_snapshot_is_read_only(snapshot), "Mismatch snapshot remains read-only")


func _test_identity_context_mismatch_routes_to_identity_cue() -> void:
	var client: Dictionary = _surface("client", 1, "team_bravo")
	var snapshot: Dictionary = Dictionary(CHECK_SCRIPT.call("build_snapshot", _surface("host", 1, "team_alpha"), client, {}))
	_assert(String(snapshot.get("status", "")) == "needs_host_client_polished_surface_alignment", "Peer-id mismatch routes to alignment")
	_assert(not bool(snapshot.get("peer_context_distinct", true)), "Peer context mismatch is recorded")
	_assert(Array(snapshot.get("failed_checks", [])).has("peer_context_distinct"), "Failed checks include peer context")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_773"), "Peer context mismatch routes to identity cue polish")
	_assert(_snapshot_is_read_only(snapshot), "Identity mismatch snapshot remains read-only")


func _test_unready_sources_block() -> void:
	var host: Dictionary = _surface("host", 1, "team_alpha")
	host["status"] = "needs_visible_polished_command_surface_review"
	host["manual_review_done"] = false
	var snapshot: Dictionary = Dictionary(CHECK_SCRIPT.call("build_snapshot", host, _surface("client", 2, "team_bravo"), {}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_task_785_visible_findings_ready", "Unready TASK_785 source blocks")
	_assert(not bool(snapshot.get("source_ready", true)), "Source-ready failure is recorded")
	_assert(Array(snapshot.get("failed_checks", [])).has("source_ready"), "Failed checks include source_ready")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_785"), "Unready source routes to TASK_785")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(CHECK_SCRIPT.call("build_snapshot", _surface("host", 1, "team_alpha"), _surface("client", 2, "team_bravo"), {
		"manifest_path": "tmp/station_reentry_firefight_host_client_polished_surface_check.json",
	}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_786 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_786 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_786", "Manifest records TASK_786")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_785", "Manifest records TASK_785 source")
	_assert(String(parsed.get("status", "")) == "ready_for_host_client_polished_surface_review", "Manifest records ready host/client surface status")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _surface(role: String, peer_id: int, team_id: String) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_command_surface_visible_findings_refresh.v1",
		"task_id": "TASK_785",
		"status": "ready_for_next_station_firefight_iteration",
		"manual_review_done": true,
		"visible_playtest_done": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"peer_role": role,
		"peer_id": peer_id,
		"team_id": team_id,
		"expected_command_surface_style_id": "task_783_firefight_command_surface_v1",
		"expected_surface_priority_order": ["interaction_line", "primary_action", "quick_action_rail", "guard_line"],
		"expected_interaction_line": "FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
		"expected_primary_action_label": "HOLD",
		"expected_quick_action_labels": ["HOLD", "FLANK", "HOLD FIRE", "SUP", "MOVE"],
		"expected_guard_line": "NO AUTO CMD | EXISTING BUTTONS",
		"expected_summary_line": "NEXT HOLD | QUICK FLANK / HOLD FIRE / SUP / MOVE",
		"expected_no_auto_command_commit": true,
		"expected_uses_existing_commands_only": true,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true))


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
