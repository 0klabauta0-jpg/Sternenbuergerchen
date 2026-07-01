extends SceneTree

const WAYPOINT_INTENT_PREVIEW_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/waypoint_intent_preview_resolver.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_768_station_reentry_first_mission_preview_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_768 Station Reentry First Mission Preview Polish ===")
	_test_docs_contract_and_report()
	_test_waypoint_preview_contract_without_go()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_768: FAILED")
		quit(1)
		return
	print("TASK_768: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_768 task file exists")
	_assert(task_text.contains("Station Reentry First Mission Preview Polish"), "TASK_768 task names preview polish")
	_assert(status_text.contains("TASK_768 - Station Reentry First Mission Preview Polish"), "Implementation status tracks TASK_768")
	_assert(roadmap_text.contains("TASK_768 - Station Reentry First Mission Preview Polish (implementiert)"), "Roadmap marks TASK_768 implemented")
	_assert(contract_text.contains("get_station_reentry_first_mission_preview_polish_snapshot"), "Mission command feedback contract documents TASK_768")
	_assert(controller_text.contains("get_station_reentry_first_mission_preview_polish_snapshot"), "TacticalController exposes TASK_768 snapshot")
	_assert(controller_text.contains("PREVIEW Dist"), "Waypoint intent text explicitly names PREVIEW")
	_assert(FileAccess.file_exists(HANDBOOK_PATH), "TASK_768 handbook report exists")
	_assert(handbook_text.contains("JSON exportieren"), "TASK_768 handbook exposes JSON export")
	_assert(handbook_text.contains("TASK_768") and handbook_text.contains("TASK_769"), "Reentry handbook preserves TASK_768 context and current follow-up")
	_assert(handbook_text.contains("data-export-key=\"manual.first_preview_visible\""), "TASK_768 handbook exports manual preview check")


func _test_waypoint_preview_contract_without_go() -> void:
	var resolver = WAYPOINT_INTENT_PREVIEW_RESOLVER_SCRIPT.new()
	var entries: Array = Array(resolver.call(
		"build_preview_entries",
		[_build_plan()],
		[{"fireteam_id": "blue", "position": Vector2(128.0, 96.0)}],
		{
			"phase_index": 0,
			"selected_fireteam_ids": PackedStringArray(["blue"]),
			"speed_world_per_second_by_fireteam": {"blue": 64.0},
		}
	))
	_assert(entries.size() == 1, "Resolver returns one selected pending Station preview entry")
	var entry: Dictionary = Dictionary(entries[0]) if not entries.is_empty() else {}
	_assert(bool(entry.get("read_only", false)), "Preview entry is read-only")
	_assert(not bool(entry.get("ui_sets_gameplay_truth", true)), "Preview entry does not set gameplay truth")
	_assert(String(entry.get("fireteam_id", "")) == "blue", "Preview entry keeps selected fireteam id")
	_assert(typeof(entry.get("ghost_ftl_position", null)) == TYPE_VECTOR2, "Preview entry exposes ghost position")
	_assert(Array(entry.get("ghost_path_points", [])).size() >= 2, "Preview entry exposes path points")
	_assert(int(entry.get("ghost_path_segment_count", 0)) == 1, "Preview entry exposes path segment count")
	_assert(float(entry.get("distance_world", -1.0)) > 0.0, "Preview entry exposes distance")
	_assert(float(entry.get("eta_seconds_estimate", -1.0)) > 0.0, "Preview entry exposes ETA")
	_assert(String(entry.get("risk_state", "")) == "unknown", "Preview entry keeps honest unknown risk without contact context")
	_assert(String(entry.get("risk_reason", "")) == "no_threat_context", "Preview entry explains missing threat context")


func _build_plan() -> Dictionary:
	return {
		"plan_id": "task_768_station_first_preview",
		"fireteam_id": "blue",
		"phase": 0,
		"status": "draft",
		"active_waypoint_index": -1,
		"waypoints": [
			{
				"waypoint_id": "task_768_move",
				"command_type": "move",
				"status": "pending",
				"target_position": Vector2(224.0, 160.0),
			},
		],
	}


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
