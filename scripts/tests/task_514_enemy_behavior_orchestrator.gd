extends SceneTree

const ORCHESTRATOR_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_behavior_orchestrator.gd")

const ORCHESTRATOR_PATH: String = "res://scripts/tactical/enemy_behavior_orchestrator.gd"
const DRIVER_PATH: String = "res://scripts/tests/mission_combat_loop_driver.gd"
const TASK_PATH: String = "res://docs/tasks/TASK_514_enemy_behavior_orchestrator.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"

var _passed: int = 0
var _failed: int = 0


class FakeEnemyUnit:
	extends Node2D

	var unit_id: String = "enemy_delta"

	func get_unit_id() -> String:
		return unit_id


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_514 Enemy Behavior Orchestrator ===")
	_test_team_tactics_payloads()
	_test_patrol_payloads()
	_test_limbo_and_reposition_payloads()
	_test_source_boundaries()
	_test_docs_reference_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_team_tactics_payloads() -> void:
	var orchestrator = ORCHESTRATOR_SCRIPT.new()
	var enemy := FakeEnemyUnit.new()
	enemy.global_position = Vector2(10, 20)
	var state: Dictionary = {
		"has_explicit_tactics": true,
		"advance_style": "push",
		"priority": 8,
		"moving_unit_ids": PackedStringArray(["enemy_delta"]),
		"target_positions_by_unit_id": {"enemy_delta": Vector2(240, 20)},
		"movement_posture_policy": "aggressive_ready",
		"tactic_label": "PUSH M1",
		"movement_posture_by_unit_id": {"enemy_delta": "tactical"},
		"weapon_posture_by_unit_id": {"enemy_delta": "ready"},
		"posture_policy_by_unit_id": {"enemy_delta": "aggressive_ready"},
		"move_speed_factor_by_unit_id": {"enemy_delta": 0.42},
	}
	var decision: Dictionary = Dictionary(orchestrator.call("build_team_tactics_decision", enemy, state, "enemy_delta", 18.0, 0.3))
	var command: Dictionary = Dictionary(decision.get("command", {}))
	_assert(bool(decision.get("handled", false)), "Team tactics move is handled")
	_assert(String(command.get("source_command_type", "")) == "enemy_team_tactics", "Team tactics source is preserved")
	_assert(String(command.get("command_type", "")) == "move_to_position", "Team tactics move uses move command")
	_assert(Vector2(command.get("target_position", Vector2.ZERO)) == Vector2(240, 20), "Team tactics move target is preserved")
	_assert(is_equal_approx(float(command.get("move_speed_factor", 0.0)), 0.42), "Team tactics per-unit speed is preserved")

	state["advance_style"] = "hold"
	decision = Dictionary(orchestrator.call("build_team_tactics_decision", enemy, state, "enemy_delta", 18.0, 0.3))
	command = Dictionary(decision.get("command", {}))
	_assert(bool(decision.get("handled", false)), "Hold-style team tactics blocks fallback behavior")
	_assert(command.is_empty(), "Hold-style team tactics is commandless to avoid objective-rush spam")


func _test_patrol_payloads() -> void:
	var orchestrator = ORCHESTRATOR_SCRIPT.new()
	var enemy := FakeEnemyUnit.new()
	enemy.global_position = Vector2(0, 0)
	var decision: Dictionary = Dictionary(orchestrator.call("build_patrol_decision", enemy, {
		"unit_id": "enemy_delta",
		"patrol_path": [Vector2(0, 0), Vector2(128, 0)],
		"waypoint_index": 0,
		"contact_locked": false,
		"should_hold": false,
		"waypoint_reached_distance": 18.0,
		"posture_fields": {
			"movement_posture": "travel",
			"weapon_posture": "lowered",
			"posture_policy_id": "travel_until_threat",
			"move_speed_factor": 0.55,
		},
		"default_speed_factor": 0.3,
	}))
	var command: Dictionary = Dictionary(decision.get("command", {}))
	_assert(bool(decision.get("handled", false)), "Patrol decision is handled")
	_assert(int(decision.get("waypoint_index", -1)) == 1, "Patrol advances waypoint after reaching current point")
	_assert(Vector2(command.get("target_position", Vector2.ZERO)) == Vector2(128, 0), "Patrol command targets next waypoint")
	_assert(String(command.get("source_command_type", "")) == "enemy_patrol", "Patrol source is preserved")

	decision = Dictionary(orchestrator.call("build_patrol_decision", enemy, {
		"unit_id": "enemy_delta",
		"patrol_path": [Vector2(0, 0), Vector2(128, 0)],
		"waypoint_index": 0,
		"contact_locked": false,
		"should_hold": true,
	}))
	_assert(not bool(decision.get("handled", false)) and bool(decision.get("contact_locked", false)), "Patrol contact locks without command")


func _test_limbo_and_reposition_payloads() -> void:
	var orchestrator = ORCHESTRATOR_SCRIPT.new()
	var cover_command: Dictionary = Dictionary(orchestrator.call("build_limbo_cover_command", "enemy_delta", Vector2(64, 96), 0.45, "seek_cover", "contact_visible_cover_needed"))
	_assert(String(cover_command.get("command_type", "")) == "move_to_position", "Limbo cover uses move command")
	_assert(String(cover_command.get("source_command_type", "")) == "enemy_limbo_cover", "Limbo cover source is preserved")
	_assert(String(cover_command.get("enemy_bt_action", "")) == "seek_cover", "Limbo cover keeps BT action")

	var hold_command: Dictionary = Dictionary(orchestrator.call("build_limbo_contact_hold_command", "enemy_delta", "contact_hold", "contact_visible_hold_fire_lane"))
	_assert(String(hold_command.get("command_type", "")) == "hold_position", "Limbo contact uses hold command")
	_assert(String(hold_command.get("posture_policy_id", "")) == "overwatch", "Limbo contact keeps overwatch policy")

	var fallback_command: Dictionary = Dictionary(orchestrator.call("build_fallback_advance_command", "enemy_delta", Vector2(300, 400), {
		"movement_posture": "tactical",
		"weapon_posture": "ready",
		"posture_policy_id": "travel_until_threat",
		"move_speed_factor": 0.35,
	}, 0.3))
	_assert(String(fallback_command.get("source_command_type", "")) == "enemy_advance", "Fallback advance source is preserved")

	var reposition_command: Dictionary = Dictionary(orchestrator.call("build_damage_reposition_command", "enemy_delta", Vector2(120, 80), 0.45, "aggressive_ready"))
	_assert(String(reposition_command.get("source_command_type", "")) == "enemy_damage_reposition", "Damage reposition source is preserved")
	_assert(bool(reposition_command.get("requeue_until_target", false)), "Damage reposition keeps requeue contract")


func _test_source_boundaries() -> void:
	var orchestrator_source: String = _read_text(ORCHESTRATOR_PATH)
	var driver_source: String = _read_text(DRIVER_PATH)
	_assert(orchestrator_source.contains("class_name EnemyBehaviorOrchestrator"), "Enemy behavior orchestrator exists under scripts/tactical")
	_assert(not orchestrator_source.contains("enqueue_command") and not orchestrator_source.contains("enqueue_effect"), "Orchestrator does not mutate command or effect queues")
	_assert(not orchestrator_source.contains("get_node_or_null") and not orchestrator_source.contains("get_tree()"), "Orchestrator has no SceneTree dependency")
	_assert(driver_source.contains("ENEMY_BEHAVIOR_ORCHESTRATOR_SCRIPT"), "Combat driver preloads enemy behavior orchestrator")
	_assert(driver_source.contains("build_team_tactics_decision"), "Combat driver delegates team tactics payloads")
	_assert(driver_source.contains("build_patrol_decision"), "Combat driver delegates patrol payloads")
	_assert(driver_source.contains("build_damage_reposition_command"), "Combat driver delegates damage reposition payloads")


func _test_docs_reference_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(task_text.contains("TASK_514 - Enemy Behavior Orchestrator"), "TASK_514 task file exists")
	_assert(roadmap_text.contains("TASK_514 - Enemy Behavior Orchestrator"), "Roadmap lists TASK_514")
	_assert(status_text.contains("TASK_514 - Enemy Behavior Orchestrator"), "Implementation status lists TASK_514")
	_assert(report_text.contains("TASK_514 - Enemy Behavior Orchestrator"), "Review report references TASK_514")


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
