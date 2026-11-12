extends "res://scripts/tests/polisa_real_visit_board_retire_probe.gd"
class Runtime extends Node:
	var personnel: Node
	func get_base_personnel_runtime() -> Node: return personnel
	func has_pending_polisa_recruit(_craft: String) -> bool: return false

func _run() -> void:
	var id := "polisa_recruit_on_ship"
	var visit: Dictionary = _visit_rig({"visitor":["pilot",id]})
	visit.units.name="UnitRegistry"
	visit.sim.unit_registry_path=visit.sim.get_path_to(visit.units)
	var base_rig: Dictionary = _admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0)])
	var base = load("res://scripts/core/base_personnel_runtime.gd").new()
	base_rig.scene.add_child(base)
	base._flow=visit.flow; base._sim=base_rig.sim; base._terrain=base_rig.terrain; base._registry=base_rig.units
	base_rig.sim.configure_base_personnel(base)
	var home_actor=load("res://scripts/core/base_personnel_actor.gd").new()
	home_actor.unit_id=id; home_actor.visible=false; base.add_child(home_actor)
	base_rig.units.register_unit(id,home_actor); base_rig.sim.register_known_unit(id,home_actor)
	base._states[id]={"unit_id":id,"status":"station","craft_id":"","bed_id":"","action":{},"last_result":{}}
	visit.flow._homebase_aircraft_definitions=[{"craft_id":"visitor"}]
	var runtime:=Runtime.new(); runtime.personnel=base; visit.flow.add_child(runtime)
	visit.flow._singleplayer_runtime=runtime
	visit.flow._finish_space_surface_departure("visitor")
	_check(visit.flow._aircraft_location_by_craft.visitor=="starmap" and base._states[id].status=="aboard" and base._states[id].craft_id=="visitor","real Flow retirement binds verified recruit to departing player ship")
	_check(visit.sim.get_hex_unit_state(id).is_empty() and bool(visit.actors[id].get_meta("dropship_embarked",false)),"departure proof contains actual station Hex release")
	_dispose_visit(visit); base_rig.scene.free()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0: print("POLISA_PLAYER_DEPARTURE_FLOW_PASS")
	quit(0 if failed==0 else 1)
