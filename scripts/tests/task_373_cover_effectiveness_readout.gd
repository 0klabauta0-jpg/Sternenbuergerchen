extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_373_cover_effectiveness_readout.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")

var _passed: int = 0
var _failed: int = 0
var _flank_preview_call_count: int = 0


class CommandStub:
	extends RefCounted

	var command_type: String = "hold_position"
	var source_command_type: String = ""


class ReadoutUnit:
	extends Node2D

	var unit_id: String = ""
	var team_id: String = ""
	var fireteam_id: String = ""
	var cover_score: int = 0
	var command: RefCounted = CommandStub.new()

	func get_unit_id() -> String:
		return unit_id

	func get_team_id() -> String:
		return team_id

	func get_fireteam_id() -> String:
		return fireteam_id

	func get_vital_state() -> String:
		return "fit"

	func get_active_weapon_id() -> String:
		return "rifle"

	func get_current_unit_command():
		return command

	func get_effective_cover_score() -> int:
		return cover_score


class ClearLosSystem:
	extends RefCounted

	func has_line_of_sight_between_nodes(attacker, target, attack_range: float, _terrain_registry = null) -> bool:
		if attacker is Node2D and target is Node2D and attack_range >= 0.0:
			return (attacker as Node2D).global_position.distance_to((target as Node2D).global_position) <= attack_range
		return true


class BlockedLosSystem:
	extends RefCounted

	func has_line_of_sight_between_nodes(_attacker, _target, _attack_range: float, _terrain_registry = null) -> bool:
		return false


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_373 Cover Effectiveness Readout ===")
	_test_resolver_full_cover_readout()
	_test_resolver_no_los_readout()
	_test_resolver_flank_preview_readout()
	_test_hidden_contact_sanitizes_values()
	await _test_controller_feedback_snapshot_is_read_only()
	_test_docs_status_and_roadmap()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_resolver_full_cover_readout() -> void:
	var attacker: Node2D = _make_unit("alpha_full_cover", "team_alpha", Vector2.ZERO, 0)
	var target: Node2D = _make_unit("bravo_full_cover", "team_bravo", Vector2(96.0, 0.0), 80)
	var readout: Dictionary = _build_readout(attacker, target, ClearLosSystem.new())
	_assert(String(readout.get("source", "")) == "CombatFireDecisionResolver", "Full-cover readout is sourced from CombatFireDecisionResolver")
	_assert(String(readout.get("cover_state", "")) == "full_cover", "Readout classifies full cover")
	_assert(String(readout.get("range_state", "")) == "in_range", "Readout distinguishes in-range targets")
	_assert(String(readout.get("los_state", "")) == "clear", "Readout distinguishes clear LOS")
	_assert(String(readout.get("flank_state", "")) == "unknown", "Readout leaves flank unknown without a preview source")
	attacker.queue_free()
	target.queue_free()


func _test_resolver_no_los_readout() -> void:
	var attacker: Node2D = _make_unit("alpha_no_los", "team_alpha", Vector2.ZERO, 0)
	var target: Node2D = _make_unit("bravo_no_los", "team_bravo", Vector2(96.0, 0.0), 45)
	var readout: Dictionary = _build_readout(attacker, target, BlockedLosSystem.new())
	_assert(String(readout.get("los_state", "")) == "blocked", "Readout distinguishes blocked LOS")
	_assert(not bool(readout.get("combat_attackable", true)), "Blocked LOS target is not attackable")
	_assert(String(readout.get("attack_quality_label", "")) == "no_los", "Blocked LOS receives no_los quality label")
	attacker.queue_free()
	target.queue_free()


func _test_resolver_flank_preview_readout() -> void:
	_flank_preview_call_count = 0
	var attacker: Node2D = _make_unit("alpha_flank", "team_alpha", Vector2.ZERO, 0)
	var target: Node2D = _make_unit("bravo_flank", "team_bravo", Vector2(96.0, 0.0), 80)
	var readout: Dictionary = _build_readout(attacker, target, ClearLosSystem.new(), {"resolve_flank_attack_preview": Callable(self, "_preview_flank")})
	_assert(_flank_preview_call_count == 1, "Readout asks for flank preview exactly once")
	_assert(String(readout.get("flank_state", "")) == "flank", "Readout distinguishes flank-relevant attacks")
	_assert(String(readout.get("raw_cover_state", "")) == "full_cover", "Readout keeps raw cover separate")
	_assert(String(readout.get("effective_cover_state", "")) == "no_cover", "Readout applies flank preview cover override as effective cover")
	_assert(String(readout.get("attack_quality_label", "")) == "flank_opportunity", "Flank preview receives flank quality label")
	attacker.queue_free()
	target.queue_free()


func _test_hidden_contact_sanitizes_values() -> void:
	var attacker: Node2D = _make_unit("alpha_hidden", "team_alpha", Vector2.ZERO, 0)
	var target: Node2D = _make_unit("bravo_hidden", "team_bravo", Vector2(96.0, 0.0), 80)
	var readout: Dictionary = _build_readout(attacker, target, ClearLosSystem.new(), {"contact_state": "suspected", "respect_contact_state": true})
	_assert(String(readout.get("readout_state", "")) == "unknown", "Hidden contact produces unknown readout")
	_assert(String(readout.get("reason", "")) == "contact_not_visible", "Hidden contact explains visibility reason")
	_assert(not readout.has("raw_cover_score") and not readout.has("target_unit_id"), "Hidden contact exposes no hidden cover score or target id")
	attacker.queue_free()
	target.queue_free()


func _test_controller_feedback_snapshot_is_read_only() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(24)
	var controller := scene.get_node_or_null("TacticalController")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and simulation_root != null, "Mission scene exposes TacticalController and SimulationRoot")
	if controller == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	await _wait_frames(4)
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var readout: Dictionary = Dictionary(feedback.get("cover_effectiveness_readout", {}))
	var tile_readout: Dictionary = Dictionary(readout.get("selected_tile", {}))
	var hierarchy: Dictionary = Dictionary(feedback.get("command_hierarchy", {}))
	_assert(not readout.is_empty(), "Command feedback exposes cover effectiveness readout")
	_assert(bool(readout.get("read_only", false)) and not bool(readout.get("ui_may_execute_commands", true)), "Cover readout is read-only and cannot execute commands")
	_assert(String(tile_readout.get("readout_state", "")) == "estimated", "Selected tile readout is terrain-only estimated data")
	_assert(String(tile_readout.get("range_state", "")) == "unknown" and String(tile_readout.get("los_state", "")) == "unknown", "Selected tile readout does not invent range or LOS values")
	_assert(String(feedback.get("cover_effectiveness_text", "")).contains("COV"), "Feedback snapshot includes compact cover text")
	_assert(bool(hierarchy.get("visual_only", false)) and not bool(hierarchy.get("ui_sets_gameplay_truth", true)), "Command buttons stay governed by MissionCommandHierarchyContract")
	_assert(simulation_root.command_queue.size() == command_count_before, "Cover readout snapshot enqueues no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "Cover readout snapshot enqueues no SimulationRoot effects")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_status_and_roadmap() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_373 task file marks implementation complete")
	_assert(not task_text.contains("- [ ]"), "TASK_373 checklist is complete")
	_assert(status_text.contains("### TASK_373 - Cover Effectiveness Readout") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_373 implemented")
	_assert(roadmap_text.contains("TASK_373 - Cover Effectiveness Readout (implementiert)"), "Roadmap marks TASK_373 implemented")


func _make_unit(unit_id: String, team_id: String, world_position: Vector2, cover_score: int) -> Node2D:
	var unit := ReadoutUnit.new()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = "blue" if team_id == "team_alpha" else "enemy"
	unit.global_position = world_position
	unit.cover_score = cover_score
	root.add_child(unit)
	return unit


func _build_readout(attacker: Node2D, target: Node2D, los_system, extra: Dictionary = {}) -> Dictionary:
	var context: Dictionary = {
		"friendly_team_id": "team_alpha",
		"base_damage_multiplier": 1.0,
		"los_system": los_system,
		"terrain_registry": null,
	}
	for key in extra.keys():
		context[key] = extra[key]
	return Dictionary(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("build_cover_effectiveness_readout", attacker, target, context)).duplicate(true)


func _preview_flank(_attacker, _target) -> Dictionary:
	_flank_preview_call_count += 1
	return {
		"is_flank": true,
		"preview_only": true,
		"direction_label": "rear",
		"hit_chance_bonus": 0.2,
		"target_cover_override": 0.0,
	}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
