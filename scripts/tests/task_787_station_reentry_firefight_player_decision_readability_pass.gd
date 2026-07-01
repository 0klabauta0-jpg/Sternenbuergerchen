extends SceneTree

const DECISION_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_player_decision_readability_pass.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_787_station_reentry_firefight_player_decision_readability_pass.md"
const TASK_786_PATH: String = "res://docs/tasks/TASK_786_station_reentry_firefight_host_client_polished_surface_check.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_player_decision_readability_pass.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_787 Station Reentry Firefight Player Decision Readability Pass ===")
	_test_docs_contract_and_report()
	_test_ready_surface_builds_decision_card()
	_test_missing_guard_routes_to_polish()
	_test_missing_quick_actions_routes_to_readability_polish()
	_test_unready_source_blocks()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_787: FAILED")
		quit(1)
		return
	print("TASK_787: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_787 task file exists")
	_assert(FileAccess.file_exists(TASK_786_PATH), "TASK_786 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Player Decision Readability Pass"), "TASK_787 task names player decision readability pass")
	_assert(status_text.contains("TASK_787 - Station Reentry Firefight Player Decision Readability Pass"), "Implementation status tracks TASK_787")
	_assert(roadmap_text.contains("TASK_787 - Station Reentry Firefight Player Decision Readability Pass (implementiert)"), "Roadmap marks TASK_787 implemented")
	_assert(contract_text.contains("Station-Reentry-Firefight-Player-Decision-Readability-Pass"), "Mission command feedback contract documents TASK_787")
	_assert(report_text.contains("Aktueller Griff: TASK_790"), "Reentry handbook marks TASK_790 current")
	_assert(report_text.contains("station_reentry_firefight_player_decision_readability_pass.json"), "Reentry handbook names TASK_787 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_player_decision.decision_line_visible"'), "Reentry handbook exports TASK_787 decision-line check")
	_assert(report_text.contains('data-export-key="reentry_firefight_player_decision.guard_visible"'), "Reentry handbook exports TASK_787 guard check")


func _test_ready_surface_builds_decision_card() -> void:
	var snapshot: Dictionary = Dictionary(DECISION_SCRIPT.call("build_snapshot", _surface(), {}))
	_assert(_snapshot_is_read_only(snapshot), "TASK_787 snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_player_decision_readability_pass.v1", "TASK_787 schema is stable")
	_assert(String(snapshot.get("status", "")) == "ready_for_visible_player_decision_review", "Ready source builds readable decision")
	_assert(bool(snapshot.get("ready_for_visible_player_decision_review", false)), "Ready flag is true")
	_assert(String(snapshot.get("primary_action_label", "")) == "HOLD", "Primary action is HOLD")
	_assert(Array(snapshot.get("quick_action_labels", [])).has("HOLD FIRE"), "Quick actions keep HOLD FIRE visible")
	_assert(String(snapshot.get("decision_line", "")).begins_with("NEXT HOLD"), "Decision line starts with NEXT HOLD")
	_assert(String(snapshot.get("reason_line", "")).contains("FF HIT"), "Reason line includes firefight pressure")
	_assert(String(snapshot.get("guard_line", "")).contains("NO AUTO CMD"), "Guard line names no-auto-command")
	_assert(String(snapshot.get("guard_line", "")).contains("EXISTING BUTTONS"), "Guard line names existing buttons")
	_assert(bool(snapshot.get("text_budget_ok", false)), "Text budget is green")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_788"), "Clean decision routes to TASK_788")
	var card: Dictionary = Dictionary(snapshot.get("decision_card", {}))
	_assert(String(card.get("confirm", "")).contains("GO"), "Decision card names GO/existing confirmation")
	_assert(_snapshot_is_read_only(card), "Decision card remains read-only")


func _test_missing_guard_routes_to_polish() -> void:
	var source: Dictionary = _surface()
	source["host_view"]["guard_line"] = ""
	source["host_view"]["no_auto_command_commit"] = false
	source["host_view"]["uses_existing_commands_only"] = false
	var snapshot: Dictionary = Dictionary(DECISION_SCRIPT.call("build_snapshot", source, {}))
	_assert(String(snapshot.get("status", "")) == "needs_player_decision_readability_polish", "Missing guard routes to readability polish")
	_assert(not bool(snapshot.get("guard_visible", true)), "Missing guard is recorded")
	_assert(Array(snapshot.get("failed_checks", [])).has("guard_visible"), "Failed checks include guard")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_783"), "Guard issue routes to command surface polish")
	_assert(_snapshot_is_read_only(snapshot), "Guard issue snapshot remains read-only")


func _test_missing_quick_actions_routes_to_readability_polish() -> void:
	var source: Dictionary = _surface()
	source["host_view"]["quick_action_labels"] = ["HOLD"]
	var snapshot: Dictionary = Dictionary(DECISION_SCRIPT.call("build_snapshot", source, {}))
	_assert(String(snapshot.get("status", "")) == "needs_player_decision_readability_polish", "Too few quick actions routes to readability polish")
	_assert(not bool(snapshot.get("quick_actions_visible", true)), "Quick-action issue is recorded")
	_assert(Array(snapshot.get("failed_checks", [])).has("quick_actions_visible"), "Failed checks include quick actions")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_787"), "Quick-action readability issue stays in TASK_787 polish")
	_assert(_snapshot_is_read_only(snapshot), "Quick-action issue snapshot remains read-only")


func _test_unready_source_blocks() -> void:
	var source: Dictionary = _surface()
	source["status"] = "needs_host_client_polished_surface_alignment"
	source["sync_gate"] = "review"
	source["ready_for_visible_host_client_polished_surface_review"] = false
	var snapshot: Dictionary = Dictionary(DECISION_SCRIPT.call("build_snapshot", source, {}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_host_client_surface_ready", "Unready TASK_786 source blocks")
	_assert(not bool(snapshot.get("source_ready", true)), "Source-ready failure is recorded")
	_assert(Array(snapshot.get("failed_checks", [])).has("source_ready"), "Failed checks include source_ready")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_786"), "Unready source routes to TASK_786")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(DECISION_SCRIPT.call("build_snapshot", _surface(), {
		"manifest_path": "tmp/station_reentry_firefight_player_decision_readability_pass.json",
	}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_787 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_787 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_787", "Manifest records TASK_787")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_786", "Manifest records TASK_786 source")
	_assert(String(parsed.get("status", "")) == "ready_for_visible_player_decision_review", "Manifest records ready decision status")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _surface() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_host_client_polished_surface_check.v1",
		"task_id": "TASK_786",
		"source_task_id": "TASK_785",
		"status": "ready_for_host_client_polished_surface_review",
		"sync_gate": "pass",
		"ready_for_visible_host_client_polished_surface_review": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"peer_context_distinct": true,
		"team_context_present": true,
		"host_view": {
			"primary_action_label": "HOLD",
			"quick_action_labels": ["HOLD", "FLANK", "HOLD FIRE", "SUP", "MOVE"],
			"interaction_line": "FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
			"summary_line": "NEXT HOLD | QUICK FLANK / HOLD FIRE / SUP / MOVE",
			"guard_line": "NO AUTO CMD | EXISTING BUTTONS",
			"no_auto_command_commit": true,
			"uses_existing_commands_only": true,
		},
		"client_view": {
			"primary_action_label": "HOLD",
			"quick_action_labels": ["HOLD", "FLANK", "HOLD FIRE", "SUP", "MOVE"],
			"interaction_line": "FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
			"summary_line": "NEXT HOLD | QUICK FLANK / HOLD FIRE / SUP / MOVE",
			"guard_line": "NO AUTO CMD | EXISTING BUTTONS",
			"no_auto_command_commit": true,
			"uses_existing_commands_only": true,
		},
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
