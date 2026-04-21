extends SceneTree

const COMMANDER_COMMAND_SCRIPT: GDScript = preload("res://scripts/command/commander_command.gd")
const TRANSLATOR_SCRIPT: GDScript = preload("res://scripts/command/command_to_ftltask_translator.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const PHASE_STATE_SCRIPT: GDScript = preload("res://scripts/command/phase_state.gd")
const AD_HOC_ORDER_SCRIPT: GDScript = preload("res://scripts/command/ad_hoc_order.gd")
const UNIT_LOADOUT_MODIFIERS_SCRIPT: GDScript = preload("res://scripts/command/unit_loadout_modifiers.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_097 Tactical Contract Verifier ===")
	_test_commander_command_supports_engage()
	_test_fireteam_waypoint_accepts_planned_contract()
	_test_fireteam_order_plan_keeps_dictionary_waypoints()
	_test_ad_hoc_order_defaults_resume_plan_after_true()
	_test_runtime_models_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_commander_command_supports_engage() -> void:
	var command = COMMANDER_COMMAND_SCRIPT.new(
		{
			"command_type": "engage",
			"priority": 10,
			"unit_id": "blue",
			"team_id": "team_alpha",
			"target_position": Vector2(128.0, 96.0),
			"phase": COMMANDER_COMMAND_SCRIPT.PHASE_ASSAULT,
		}
	)
	_assert(command.is_valid(), "CommanderCommand accepts engage as planned command type")
	var translator = TRANSLATOR_SCRIPT.new()
	var task = translator.translate(command)
	_assert(task != null and bool(task.call("is_valid")), "Translator accepts engage command")
	if task != null:
		_assert(String(task.get("task_type")) == "engage_in_area", "Engage translates to engage_in_area")


func _test_fireteam_waypoint_accepts_planned_contract() -> void:
	var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new(
		{
			"waypoint_id": "wp_1",
			"command_type": "flank",
			"target_position": Vector2(200.0, 120.0),
			"status": "pending",
		}
	)
	_assert(waypoint.is_valid(), "FireteamWaypoint accepts flank as planned waypoint type")
	var engage_waypoint = FIRETEAM_WAYPOINT_SCRIPT.new(
		{
			"waypoint_id": "wp_2",
			"command_type": "engage",
			"target_position": Vector2(220.0, 140.0),
		}
	)
	_assert(engage_waypoint.is_valid(), "FireteamWaypoint accepts engage in the planning contract")


func _test_fireteam_order_plan_keeps_dictionary_waypoints() -> void:
	var plan = FIRETEAM_ORDER_PLAN_SCRIPT.new(
		{
			"plan_id": "plan_blue_1",
			"fireteam_id": "blue",
			"phase": 1,
			"status": "pending",
			"active_waypoint_index": -1,
			"waypoints": [
				{
					"waypoint_id": "wp_a",
					"command_type": "move",
					"target_position": Vector2(32.0, 48.0),
				},
				{
					"waypoint_id": "wp_b",
					"command_type": "take",
					"target_area_id": "objective_alpha",
				},
			],
		}
	)
	_assert(plan.is_valid(), "FireteamOrderPlan accepts dictionary-compatible waypoint arrays")
	var serialized: Dictionary = plan.to_dict()
	_assert(Array(serialized.get("waypoints", [])).size() == 2, "FireteamOrderPlan serializes all waypoints")


func _test_ad_hoc_order_defaults_resume_plan_after_true() -> void:
	var order = AD_HOC_ORDER_SCRIPT.new(
		{
			"fireteam_id": "gold",
			"order_type": "focus_fire",
			"target_unit_id": "enemy_1",
		}
	)
	_assert(order.is_valid(), "AdHocOrder accepts focus_fire as runtime order type")
	_assert(order.resume_plan_after, "AdHocOrder keeps resume_plan_after true by default for the first slice")


func _test_runtime_models_roundtrip() -> void:
	var behavior_profile = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.new(
		{
			"fireteam_id": "blue",
			"leader_unit_id": "unit_alpha",
			"advance_style": "bounding",
			"cover_priority": 0.45,
			"fire_discipline": "semi_disciplined",
			"cohesion_threshold": 120.0,
			"suppression_threshold": 3,
		}
	)
	_assert(behavior_profile.is_valid(), "FireteamBehaviorProfile validates as lightweight runtime result")

	var phase_state = PHASE_STATE_SCRIPT.new(
		{
			"phase_index": 1,
			"display_name": "ASSAULT",
			"status": "active",
			"is_editable": true,
			"started_tick": 15,
		}
	)
	_assert(phase_state.is_valid(), "PhaseState validates active global phase data")

	var loadout_modifiers = UNIT_LOADOUT_MODIFIERS_SCRIPT.new(
		{
			"unit_id": "unit_alpha",
			"armor_id": "heavy",
			"weapon_1_id": "special",
			"weapon_2_id": "rifle",
			"accuracy_mod": 0.02,
			"speed_mod": -0.05,
			"toughness_mod": 0.06,
			"cover_mod": 0.06,
			"range_class": "any",
		}
	)
	_assert(loadout_modifiers.is_valid(), "UnitLoadoutModifiers validates additive mission modifiers")

	var roundtrip = UNIT_LOADOUT_MODIFIERS_SCRIPT.call("from_dict", loadout_modifiers.to_dict())
	_assert(roundtrip != null and roundtrip.is_valid(), "UnitLoadoutModifiers roundtrip stays dictionary-compatible")


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)