extends SceneTree

const RESOLVER: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")

class UnitDouble extends Node2D:
	var unit_id: String
	var team_id: String
	func _init(id_value: String, team_value: String, position_value: Vector2) -> void:
		unit_id = id_value
		team_id = team_value
		position = position_value
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return team_id
	func get_vital_state() -> String: return "fit"
	func get_active_weapon_id() -> String: return "rifle"
	func get_current_unit_command() -> Resource: return CommandResource.new()

class CommandResource extends Resource:
	var command_type: String = "engage_area"

class LosDouble extends Node:
	var calls: int = 0
	var max_range_seen: float = -1.0
	func has_line_of_sight_between_nodes(source, target, max_range: float, _registry = null) -> bool:
		calls += 1
		max_range_seen = max_range
		return source.global_position.distance_to(target.global_position) <= max_range

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var attacker := UnitDouble.new("attacker", "blue", Vector2(0, 0))
	var target := UnitDouble.new("target", "red", Vector2(4, 0))
	var los := LosDouble.new()
	root.add_child(attacker)
	root.add_child(target)
	root.add_child(los)
	var reuse_calls := {"count": 0}
	var context := _context(los, func(_source, _target, _record): reuse_calls["count"] += 1)
	var first := bool(RESOLVER.is_target_attackable(attacker, target, context))
	_assert(first and los.calls == 0 and int(reuse_calls["count"]) == 1, "Valid observed LOS prevalidation bypasses LOS and records reuse")
	_assert(_fallback(attacker, target, los, context, {"source_position": Vector2(99, 0)}), "Position mismatch falls back to LOS")
	_assert(_fallback(attacker, target, los, context, {"context_valid": false}), "Invalid context falls back to LOS")
	_assert(_fallback(attacker, target, los, context, {"validation_tick": 8}), "Tick mismatch falls back to LOS")
	_assert(_fallback(attacker, target, los, context, {"clear": false}), "Unclear observation falls back to LOS")
	_assert(_fallback(attacker, target, los, context, {"validated_range": 2.0}), "Insufficient validated range falls back to LOS")
	target.position = Vector2(9, 0)
	var outside_context := _context(los, func(_source, _target, _record): reuse_calls["count"] += 1)
	outside_context["observed_los_prevalidation"]["pairs"]["attacker"]["target"]["target_position"] = Vector2(9, 0)
	outside_context["observed_los_prevalidation"]["pairs"]["attacker"]["target"]["validated_range"] = 10.0
	var calls_before_outside_range: int = los.calls
	var reuse_before_outside_range: int = int(reuse_calls["count"])
	var outside_result := bool(RESOLVER.is_target_attackable(attacker, target, outside_context))
	_assert(not outside_result and los.calls == calls_before_outside_range + 1 and int(reuse_calls["count"]) == reuse_before_outside_range, "Outside current attack range is not reused or attackable")
	target.position = Vector2(4, 0)
	_assert(_fallback(target, attacker, los, context, {}), "Reverse ordered pair falls back to LOS")
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _context(los, reuse: Callable) -> Dictionary:
	return {"los_system": los, "get_weapon_attack_range": func(_a, _t): return 8.0, "observed_los_prevalidation": {"enabled": true, "context_valid": true, "current_tick": 7, "validation_tick": 7, "pairs": {"attacker": {"target": {"source_position": Vector2(0, 0), "target_position": Vector2(4, 0), "validated_range": 5.0, "clear": true}}}}, "record_observed_terrain_los_reuse": reuse}

func _fallback(attacker, target, los, base: Dictionary, overrides: Dictionary) -> bool:
	var context := base.duplicate(true)
	var prevalidation: Dictionary = context["observed_los_prevalidation"]
	for key in overrides:
		if key == "context_valid" or key == "validation_tick":
			prevalidation[key] = overrides[key]
		else:
			prevalidation["pairs"]["attacker"]["target"][key] = overrides[key]
	var before: int = los.calls
	var result := bool(RESOLVER.is_target_attackable(attacker, target, context))
	_assert(los.calls == before + 1 and result, "Fallback remains LOS-backed")
	return los.calls == before + 1 and result

func _assert(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS: %s" % message)
	else:
		failed += 1
		push_error("FAIL: %s" % message)
