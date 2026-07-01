extends SceneTree

const SYNC_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_host_client_next_order_sync.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_770_station_reentry_host_client_next_order_sync.md"
const TASK_769_PATH: String = "res://docs/tasks/TASK_769_station_reentry_performance_feel_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_host_client_next_order_sync.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_770 Station Reentry Host Client Next Order Sync ===")
	_test_docs_contract_and_report()
	_test_sync_contract()
	_test_mismatch_routes_to_review()
	_write_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_770: FAILED")
		quit(1)
		return
	print("TASK_770: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_770 task file exists")
	_assert(task_text.contains("Station Reentry Host Client Next Order Sync"), "TASK_770 task names host/client sync")
	_assert(FileAccess.file_exists(TASK_769_PATH), "TASK_769 task remains available")
	_assert(status_text.contains("TASK_770 - Station Reentry Host Client Next Order Sync"), "Implementation status tracks TASK_770")
	_assert(roadmap_text.contains("TASK_770 - Station Reentry Host Client Next Order Sync (implementiert)"), "Roadmap marks TASK_770 implemented")
	_assert(contract_text.contains("Station-Reentry-Host-Client-Next-Order-Sync"), "Mission command feedback contract documents TASK_770")
	_assert(report_text.contains("Aktueller Griff: TASK_770"), "Reentry handbook marks TASK_770 current")
	_assert(report_text.contains('data-export-key="reentry_host_client.same_next_order"'), "Reentry handbook exports TASK_770 sync check")
	_assert(controller_text.contains("STATION_REENTRY_HOST_CLIENT_NEXT_ORDER_SYNC_SCRIPT"), "Controller preloads TASK_770 contract")
	_assert(controller_text.contains("get_station_reentry_host_client_next_order_sync_snapshot"), "Controller exposes TASK_770 snapshot")


func _test_sync_contract() -> void:
	var snapshot: Dictionary = Dictionary(SYNC_SCRIPT.call("build_snapshot", _build_peer_snapshot("host", 1, "team_alpha"), _build_peer_snapshot("client", 2, "team_bravo"), {}))
	_assert(_snapshot_is_read_only(snapshot), "TASK_770 snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_host_client_next_order_sync.v1", "TASK_770 schema is stable")
	_assert(String(snapshot.get("sync_gate", "")) == "pass", "Matching host/client views pass sync gate")
	_assert(bool(snapshot.get("ready_for_visible_host_client_playtest", false)), "Snapshot is ready for visible host/client playtest")
	_assert(bool(snapshot.get("same_next_order", false)), "Host and client have same next order")
	_assert(bool(snapshot.get("same_route_line", false)), "Host and client have same route line")
	_assert(bool(snapshot.get("same_cue_line", false)), "Host and client have same cue line")
	_assert(bool(snapshot.get("peer_context_distinct", false)), "Peer context stays distinct")
	_assert(bool(snapshot.get("team_context_present", false)), "Team context is present")
	_assert(bool(snapshot.get("text_budget_ok", false)), "Text budget is green")
	_assert(bool(snapshot.get("read_only_sources", false)), "Source snapshots are read-only")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_771"), "TASK_770 routes to visible host/client export")


func _test_mismatch_routes_to_review() -> void:
	var client: Dictionary = _build_peer_snapshot("client", 2, "team_bravo")
	client["next_order_text"] = "WP 1/1 HOLD | WARTET AUF GO | Ziel 544,288 | PREVIEW Dist 120m | ETA~2s | RISK ? no intel"
	var snapshot: Dictionary = Dictionary(SYNC_SCRIPT.call("build_snapshot", _build_peer_snapshot("host", 1, "team_alpha"), client, {}))
	_assert(String(snapshot.get("sync_gate", "")) == "review", "Mismatching next order routes to review")
	_assert(not bool(snapshot.get("same_next_order", true)), "Mismatch is recorded")
	_assert(Array(snapshot.get("failed_checks", [])).has("same_next_order"), "Failed checks name next-order mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Mismatch snapshot still remains read-only")


func _write_manifest() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(SYNC_SCRIPT.call("build_snapshot", _build_peer_snapshot("host", 1, "team_alpha"), _build_peer_snapshot("client", 2, "team_bravo"), {}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_770 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_770 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_770", "Manifest records TASK_770")
	_assert(bool(parsed.get("ready_for_visible_host_client_playtest", false)), "Manifest records host/client playtest readiness")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _build_peer_snapshot(role: String, peer_id: int, team_id: String) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_performance_feel_pass.v1",
		"task_id": "TASK_769",
		"performance_gate": "pass",
		"ready_for_visible_playtest": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"peer_role": role,
		"peer_id": peer_id,
		"team_id": team_id,
		"next_order_text": "WP 1/1 MOVE | WARTET AUF GO | Ziel 544,288 | PREVIEW Dist 120m | ETA~2s | RISK ? no intel",
		"station_route_line": "ROUTE AA > DOOR > COM > CARGO | NEXT AA",
		"station_cue_line": "CUE AA: BLUE naeher ran | 3.9km",
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true))


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
