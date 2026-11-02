extends SceneTree

const SIMULATION_SCRIPT = preload("res://scripts/core/simulation_root.gd")
const UNIT_SCRIPT = preload("res://scripts/npc/test_unit.gd")
var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_cross_transport_ordering()
	_test_sender_versions_and_delta_dedupe()
	print("REVIEW_20261102_P2_VITAL_ORDER_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_cross_transport_ordering() -> void:
	var simulation = SIMULATION_SCRIPT.new()
	root.add_child(simulation)
	simulation.set_physics_process(false)
	var alpha = _make_unit(simulation, "alpha")
	var bravo = _make_unit(simulation, "bravo")
	var accepted: Dictionary = simulation.apply_multiplayer_snapshot({
		"tick": 20, "units": [_vitals("alpha", 20, "down", 0)],
	})
	_check(bool(accepted.get("accepted", false)) and alpha.get_vital_state() == "down", "New snapshot applies down state")
	simulation.call("_receive_vital_state_updates", [_vitals("alpha", 19, "fit", 90)])
	_check(alpha.get_vital_state() == "down" and alpha.get_health() == 0, "Late reliable vital update cannot resurrect snapshot state")
	simulation.call("_receive_vital_state_updates", [{"unit_id": "alpha", "vital_state": "fit", "health": 90}])
	_check(alpha.get_vital_state() == "down", "Unversioned reliable data cannot replace ordered vital state")
	simulation.call("_receive_vital_state_updates", [_vitals("alpha", 20, "fit", 99)])
	_check(alpha.get_vital_state() == "down", "Duplicate vital tick does not apply a conflicting payload")
	simulation.call("_receive_vital_state_updates", [_vitals("alpha", 21, "fit", 100)])
	_check(alpha.get_vital_state() == "fit" and alpha.get_health() == 100, "Strictly newer reliable respawn is accepted")
	simulation.call("_receive_vital_state_updates", [_vitals("bravo", 15, "fit", 70)])
	_check(bravo.get_health() == 70, "Vital ordering is per unit rather than global snapshot tick")

	simulation.call("_receive_vital_state_updates", [_vitals("bravo", 30, "down", 0)])
	var older_unit: Dictionary = _vitals("bravo", 25, "fit", 90)
	older_unit["position"] = Vector2(100, 0)
	accepted = simulation.apply_multiplayer_snapshot({"tick": 25, "units": [older_unit]})
	_check(bool(accepted.get("accepted", false)), "Snapshot may advance non-vital state behind a newer reliable vital tick")
	_check(bravo.get_vital_state() == "down" and bravo.get_health() == 0, "Older snapshot cannot replace a newer reliable vital update")
	_check(bravo.position.x > 0.0, "Older vital data does not block valid snapshot movement")
	simulation.call("_receive_vital_state_updates", [_vitals("bravo", 31, "fit", 100)])
	_check(bravo.get_vital_state() == "fit" and bravo.get_health() == 100, "Newer reliable respawn supersedes down state")
	accepted = simulation.apply_multiplayer_snapshot({"tick": 32, "units": [{"unit_id": "bravo", "position": Vector2(120, 0)}]})
	_check(bool(accepted.get("accepted", false)) and bravo.get_health() == 100, "Position-only snapshot preserves vitals")
	simulation.call("_receive_vital_state_updates", [_vitals("bravo", 32, "fit", 75)])
	_check(bravo.get_health() == 75, "Position-only snapshot does not consume a unit vital tick")
	simulation.apply_multiplayer_snapshot({"tick": 33, "units": [{"unit_id": "bravo", "vital_state": "fit", "health": 80, "bleedout_ticks": 0}]})
	_check(bravo.get_health() == 80, "Legacy snapshot vitals use their enclosing authoritative tick")
	simulation.call("_receive_vital_state_updates", [_vitals("bravo", 32, "down", 0)])
	_check(bravo.get_vital_state() == "fit" and bravo.get_health() == 80, "Legacy snapshot tick also guards the reliable path")
	_check(simulation.command_queue.is_empty() and simulation.effects_queue.is_empty(), "Remote vital application creates no gameplay commands or effects")
	alpha.free()
	bravo.free()
	simulation.free()


func _test_sender_versions_and_delta_dedupe() -> void:
	var simulation = SIMULATION_SCRIPT.new()
	root.add_child(simulation)
	simulation.set_physics_process(false)
	var unit = _make_unit(simulation, "sender")
	simulation.tick_counter = 5
	var snapshot: Dictionary = simulation.build_multiplayer_snapshot()
	var units: Array = Array(snapshot.get("units", []))
	var all_vitals: Array = Array(snapshot.get("vital_updates", []))
	_check(units.size() == 1 and int(Dictionary(units[0]).get("vital_tick", -1)) == 5, "Unit snapshot carries authoritative vital tick through normalization")
	_check(all_vitals.size() == 1 and int(Dictionary(all_vitals[0]).get("vital_tick", -1)) == 5, "Snapshot vital entries carry the same tick")
	var first: Array = simulation.call("_build_vital_state_updates")
	_check(first.size() == 1 and int(Dictionary(first[0]).get("vital_tick", -1)) == 5, "Reliable delta carries the matching authoritative tick")
	simulation.tick_counter = 6
	_check(Array(simulation.call("_build_vital_state_updates")).is_empty(), "Unchanged vitals do not emit a reliable delta every tick")
	unit.apply_damage(10)
	simulation.tick_counter = 7
	var changed: Array = simulation.call("_build_vital_state_updates")
	_check(changed.size() == 1 and int(Dictionary(changed[0]).get("vital_tick", -1)) == 7, "Changed vitals emit a new authoritative tick")
	_check(Array(simulation.call("_build_vital_state_updates")).is_empty(), "Repeated build without state change remains deduplicated")
	unit.free()
	simulation.free()


func _make_unit(simulation: Node, unit_id: String):
	var unit = UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	root.add_child(unit)
	simulation.register_known_unit(unit_id, unit)
	return unit


func _vitals(unit_id: String, tick: int, state: String, health: int) -> Dictionary:
	return {"unit_id": unit_id, "vital_tick": tick, "vital_state": state, "health": health, "bleedout_ticks": 0}


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		push_error("FAIL: " + message)
