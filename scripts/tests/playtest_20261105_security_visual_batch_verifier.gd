extends SceneTree
## Real security state/facing calculation with counted presentation sinks.
var _passed := 0
var _failed := 0


class ProbeUnit:
	extends Node2D
	var is_fireteam_lead := true
	func get_unit_id() -> String:
		return "security_probe"
	func get_vital_state() -> String:
		return "fit"
	func get_accuracy_skill() -> float:
		return 0.6
	func get_leadership_skill() -> float:
		return 0.9
	func get_trait_ids() -> PackedStringArray:
		return PackedStringArray()


class CountingController extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var fixture_units: Array = []
	var fixture_active := true
	var order_visual_calls := 0
	var status_panel_calls := 0
	var badge_calls := 0
	var revision_calls := 0
	func _ready() -> void:
		set_process(false)
	func _get_available_fireteam_ids() -> PackedStringArray:
		return PackedStringArray(["probe"])
	func get_active_behavior_profile(_fireteam_id: String) -> Dictionary:
		return {"command_type": "defend", "metadata": {"command_type": "defend", "security_mode": "directional"}}
	func _is_fireteam_runtime_active(_fireteam_id: String) -> bool:
		return fixture_active
	func _get_fireteam_units(_fireteam_id: String, _include_hidden: bool = true) -> Array:
		return fixture_units.duplicate()
	func _resolve_fireteam_leader_for_behavior(_fireteam_id: String):
		return fixture_units[0]
	func get_fireteam_movement_state(_fireteam_id: String) -> Dictionary:
		return {}
	func get_fireteam_contact_snapshot(_fireteam_id: String) -> Array:
		return [{"unit_id": "threat", "position": Vector2(100, 100), "detection_state": "confirmed"}]
	func _get_area_execution_security_context(_fireteam_id: String) -> Dictionary:
		return {}
	func _record_fireteam_security_revision(_fireteam_id: String) -> void:
		revision_calls += 1
	func _sync_unit_overwatch_badges() -> void:
		badge_calls += 1
	func _refresh_order_visuals() -> void:
		order_visual_calls += 1
	func _refresh_fireteam_status_panel() -> void:
		status_panel_calls += 1


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)


func _combat_refresh(controller: Node) -> void:
	# The legacy path is exercised before the new bounded presentation entry
	# exists, so RED measures its repeated work rather than a missing-method error.
	controller.call("refresh_fireteam_security_state_for_combat" if controller.has_method("refresh_fireteam_security_state_for_combat") else "refresh_fireteam_security_state")


func _run() -> void:
	var fixture := Node.new()
	root.add_child(fixture)
	var unit := ProbeUnit.new()
	fixture.add_child(unit)
	var controller := CountingController.new()
	controller.fixture_units = [unit]
	fixture.add_child(controller)
	controller.refresh_fireteam_security_state()
	controller.order_visual_calls = 0
	controller.status_panel_calls = 0
	controller.badge_calls = 0
	controller.revision_calls = 0
	_check(controller.has_method("refresh_fireteam_security_state_for_combat"), "Combat has a state-only security entry with bounded presentation")
	for tick in range(8):
		unit.position = Vector2(tick + 1, 0)
		_combat_refresh(controller)
		var state: Dictionary = controller.get_fireteam_security_state("probe")
		_check(state.get("anchor_position") == unit.position, "Combat refresh %d immediately updates authoritative security anchor" % tick)
		var assignments: Array = Array(state.get("member_assignments", []))
		_check(not assignments.is_empty() and is_equal_approx(float(unit.get_meta("security_facing_angle", -999.0)), float(Dictionary(assignments[0]).get("center_angle", -998.0))), "Combat refresh %d immediately applies the matching unit facing" % tick)
	_check(controller.badge_calls == 8 and controller.revision_calls == 8, "All eight combat refreshes keep badges and security revisions current")
	_check(controller.order_visual_calls == 0 and controller.status_panel_calls == 0, "Eight combat ticks do not rebuild world/HUD presentation eight times")
	controller.refresh_fireteam_security_state()
	_check(controller.order_visual_calls == 1 and controller.status_panel_calls == 1, "Existing process/manual refresh flushes accumulated security presentation once")
	unit.position += Vector2(1, 0)
	controller.refresh_fireteam_security_state()
	_check(controller.order_visual_calls == 2 and controller.status_panel_calls == 2, "Manual command security refresh remains immediate")
	controller.fixture_active = false
	_combat_refresh(controller)
	_check(controller.get_fireteam_security_state("probe").is_empty(), "Inactive fireteam clears authoritative security during the combat update")
	_check(not bool(unit.get_meta("security_facing_active", false)), "Inactive fireteam removes unit facing immediately")
	controller.refresh_fireteam_security_state()
	_check(controller.order_visual_calls == 3 and controller.status_panel_calls == 3, "Pending removal presentation flushes once even if subsequent state is unchanged")
	fixture.free()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	print("PLAYTEST_SECURITY_VISUAL_BATCH_ALL_PASS" if _failed == 0 else "PLAYTEST_SECURITY_VISUAL_BATCH_FAILED")
	quit(0 if _failed == 0 else 1)
