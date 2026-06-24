extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_506_tactical_decision_clarity_contract.md"
const CONTRACT_PATH: String = "res://docs/dev/tactical_decision_clarity_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

const THREAT_ANALYZER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_decision_threat_analyzer.gd")
const WAYPOINT_INTENT_PREVIEW_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/waypoint_intent_preview_resolver.gd")
const FIRETEAM_ORDER_VISUALIZER_SCRIPT: GDScript = preload("res://scripts/tactical/visuals/fireteam_order_visualizer.gd")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_506 Tactical Decision Clarity Contract ===")
	_test_threat_analyzer_unknown_safe_risky_suicidal()
	_test_threat_analyzer_friendly_fire_and_blocked_lines()
	_test_waypoint_preview_resolver_merges_threat_analysis()
	_test_visualizer_keeps_read_only_preview_payload()
	_test_docs_status_roadmap_and_primary_view_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_threat_analyzer_unknown_safe_risky_suicidal() -> void:
	var analyzer = THREAT_ANALYZER_SCRIPT.new()
	var unknown: Dictionary = Dictionary(analyzer.call("analyze_position", Vector2.ZERO, {}))
	_assert(String(unknown.get("risk_state", "")) == "unknown", "Analyzer keeps risk unknown without enemy/contact context")
	_assert(bool(unknown.get("read_only", false)) and not bool(unknown.get("ui_sets_gameplay_truth", true)), "Analyzer result is read-only")

	var safe: Dictionary = Dictionary(analyzer.call("analyze_position", Vector2.ZERO, {"enemy_units": []}))
	_assert(String(safe.get("risk_state", "")) == "safe", "Analyzer marks empty known enemy context as safe")

	var risky: Dictionary = Dictionary(analyzer.call("analyze_position", Vector2.ZERO, {
		"enemy_units": [_enemy("e1", Vector2(120.0, 0.0))],
		"cover_value_override": 0,
	}))
	_assert(String(risky.get("risk_state", "")) == "risky", "One clear enemy line is risky")
	_assert(int(risky.get("enemy_exposure_count", 0)) == 1, "Risky analysis counts one exposure")

	var suicidal: Dictionary = Dictionary(analyzer.call("analyze_position", Vector2.ZERO, {
		"enemy_units": [
			_enemy("e1", Vector2(120.0, 0.0)),
			_enemy("e2", Vector2(0.0, 120.0)),
			_enemy("e3", Vector2(-120.0, 0.0)),
		],
		"cover_value_override": 0,
	}))
	_assert(String(suicidal.get("risk_state", "")) == "suicidal", "Three clear enemy lines without cover are suicidal")
	_assert(int(suicidal.get("enemy_exposure_count", 0)) == 3, "Suicidal analysis counts three exposures")


func _test_threat_analyzer_friendly_fire_and_blocked_lines() -> void:
	var analyzer = THREAT_ANALYZER_SCRIPT.new()
	var blocked: Dictionary = Dictionary(analyzer.call("analyze_position", Vector2.ZERO, {
		"enemy_units": [_enemy("far", Vector2(600.0, 0.0), 100.0)],
	}))
	_assert(String(blocked.get("risk_state", "")) == "safe", "Out-of-range enemy line is not exposure")
	_assert(int(blocked.get("blocked_enemy_line_count", 0)) == 1, "Blocked/out-of-range line is counted")
	var blocked_line: Dictionary = Dictionary(Array(blocked.get("line_of_fire_entries", []))[0])
	_assert(String(blocked_line.get("visual_role", "")) == "blocked", "Blocked line carries blocked visual role")

	var friendly_fire: Dictionary = Dictionary(analyzer.call("analyze_position", Vector2.ZERO, {
		"enemy_units": [
			_enemy("e1", Vector2(120.0, 0.0)),
			_enemy("e2", Vector2(0.0, 120.0)),
		],
		"friendly_units": [{"unit_id": "mate", "position": Vector2(60.0, 0.0)}],
		"friendly_fire_corridor_radius": 20.0,
		"cover_value_override": 0,
	}))
	_assert(String(friendly_fire.get("risk_state", "")) == "suicidal", "Friendly-fire risk plus multiple exposures is suicidal")
	_assert(int(friendly_fire.get("friendly_fire_risk_count", 0)) == 1, "Friendly-fire corridor is counted once")


func _test_waypoint_preview_resolver_merges_threat_analysis() -> void:
	var resolver = WAYPOINT_INTENT_PREVIEW_RESOLVER_SCRIPT.new()
	var analyzer = THREAT_ANALYZER_SCRIPT.new()
	var plan = _make_plan("ft1", 1, [_make_waypoint("wp_a", Vector2(100.0, 0.0))])
	var entries: Array = Array(resolver.call("build_preview_entries", [plan.call("to_dict")], [{"fireteam_id": "ft1", "position": Vector2.ZERO}], {
		"phase_index": 1,
		"selected_fireteam_ids": PackedStringArray(["ft1"]),
		"speed_world_per_second_by_fireteam": {"ft1": 100.0},
		"threat_analyzer": analyzer,
		"threat_context_by_fireteam": {
			"ft1": {
				"enemy_units": [_enemy("e1", Vector2(180.0, 0.0))],
				"cover_value_override": 0,
			},
		},
	}))
	_assert(entries.size() == 1, "Resolver builds one preview entry with threat context")
	var entry: Dictionary = Dictionary(entries[0])
	_assert(String(entry.get("risk_state", "")) == "risky", "Resolver replaces unknown risk with analyzer result")
	_assert(Dictionary(entry.get("threat_analysis", {})).get("source", "") == "TacticalDecisionThreatAnalyzer", "Resolver attaches analyzer detail")
	_assert(Array(entry.get("line_of_fire_entries", [])).size() == 1, "Resolver exposes line-of-fire entries to visuals")


func _test_visualizer_keeps_read_only_preview_payload() -> void:
	var visualizer = FIRETEAM_ORDER_VISUALIZER_SCRIPT.new()
	var entry: Dictionary = {
		"fireteam_id": "ft1",
		"ghost_path_points": [Vector2.ZERO, Vector2(100.0, 0.0)],
		"ghost_ftl_position": Vector2(100.0, 0.0),
		"risk_state": "risky",
		"line_of_fire_entries": [{"from_position": Vector2(100.0, 0.0), "to_position": Vector2(180.0, 0.0), "visual_role": "clear_friendly_shot"}],
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}
	visualizer.call("set_waypoint_intent_preview_entries", [entry])
	var snapshot: Array = Array(visualizer.call("get_waypoint_intent_preview_snapshot"))
	_assert(snapshot.size() == 1, "FireteamOrderVisualizer receives combined preview payload")
	var snapshot_entry: Dictionary = Dictionary(snapshot[0])
	_assert(String(snapshot_entry.get("risk_state", "")) == "risky", "Visualizer snapshot preserves risk state")
	_assert(bool(snapshot_entry.get("read_only", false)) and not bool(snapshot_entry.get("ui_sets_gameplay_truth", true)), "Visualizer payload stays read-only")


func _test_docs_status_roadmap_and_primary_view_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var terrain_view_text: String = _read_text("res://scripts/terrain/terrain_map_3d_view.gd")
	_assert(task_text.contains("TASK_506") and task_text.contains("Tactical Decision Clarity"), "TASK_506 task file exists")
	_assert(contract_text.contains("risk_state") and contract_text.contains("ui_sets_gameplay_truth = false"), "Contract documents preview truth boundary")
	_assert(status_text.contains("### TASK_506-TASK_509 - Tactical Decision Clarity Block") and status_text.contains("- Status: implementiert"), "Implementation status marks tactical clarity block implemented")
	_assert(roadmap_text.contains("TASK_506 - Tactical Decision Clarity Contract (implementiert)"), "Roadmap marks TASK_506 implemented")
	_assert(terrain_view_text.contains("waypoint_intent_preview_threat_line_count") and terrain_view_text.contains("_add_waypoint_intent_preview_visuals"), "Primary view exposes waypoint preview visual counters")


func _enemy(unit_id: String, position: Vector2, max_range: float = 560.0) -> Dictionary:
	return {
		"unit_id": unit_id,
		"enemy_type": "rifleman",
		"position": position,
		"max_range": max_range,
	}


func _make_plan(fireteam_id: String, phase: int, waypoints: Array):
	var plan = FIRETEAM_ORDER_PLAN_SCRIPT.new()
	plan.plan_id = "plan_%s_p%d" % [fireteam_id, phase]
	plan.fireteam_id = fireteam_id
	plan.phase = phase
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_DRAFT
	plan.waypoints = waypoints
	return plan


func _make_waypoint(waypoint_id: String, target_position: Vector2):
	var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
	waypoint.waypoint_id = waypoint_id
	waypoint.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
	waypoint.target_position = target_position
	return waypoint


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
