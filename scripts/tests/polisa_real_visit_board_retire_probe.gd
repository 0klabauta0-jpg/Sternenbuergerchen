extends "res://scripts/tests/hex_deployment_phase_verifier.gd"
## Run against the current integrated AP6 source in an isolated project copy.
## Actor presentation and landed-card lookup are fixture inputs; Flow, visit,
## controller boarding/retirement, Root, ground and registry are real code.
class VisitFlow extends "res://scripts/meta/meta_layer_flow.gd":
	func _ready() -> void: pass
	func _remember_location(_instance: Node) -> void: pass
class VisitController extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var fixture_crew: Array = []
	func _ready() -> void: pass
	func _get_campaign_sortie_units() -> Array: return fixture_crew
	func _find_mission_dropship_card_entry(id: String) -> Dictionary: return {"craft_id":id,"pilot_unit_id":"pilot"}
	func _find_raw_mission_dropship_card_entry(id: String) -> Dictionary: return {"craft_id":id,"pilot_unit_id":"pilot"}
	func _is_parked_campaign_dropship(_id: String) -> bool: return true
	func _store_selected_mission_dropship_plan() -> void: pass
	func _emit_planning_state_changed() -> void: pass
	func _refresh_world_overlays() -> void: pass
	func get_local_command_team_id(_units: Array = []) -> String: return "blue"
class CrewActor extends Actor:
	func get_fireteam_id() -> String: return "team"

func _run() -> void:
	var rig: Dictionary = _admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(0,1)])
	rig.scene.set_meta("location_id", "polisa"); rig.sim.name = "SimulationRoot"
	var controller = VisitController.new(); controller.name = "TacticalController"; rig.scene.add_child(controller)
	var actor = CrewActor.new(); actor.unit_id = "pilot"; rig.scene.add_child(actor)
	rig.units.register_unit("pilot", actor); rig.sim.register_known_unit("pilot", actor)
	assert(rig.sim.admit_hex_ground_actor_group(PackedStringArray(["pilot"]), Vector2i.ZERO).ok)
	rig.sim.enqueue_command(_command("pilot", rig.terrain.grid_to_world(Vector2i(2,0))))
	rig.sim._physics_process(0.1)
	_check(not rig.sim.get_hex_movement_readout("pilot").is_empty(), "fixture has an actual accepted ground movement intent")
	controller.fixture_crew = [actor]; controller._deployed_unit_ids["pilot"] = true
	controller._parallel_drop_sequences_by_craft["visitor"] = {"phase":controller.DROP_SEQUENCE_COMPLETE,"position":actor.global_position,"lz_position":actor.global_position,"embarked_unit_ids":{}}
	var flow = VisitFlow.new(); flow._location_registry.register_location("polisa", rig.scene)
	flow._craft_location_runtime["visitor"] = "polisa"; flow._aircraft_location_by_craft["visitor"] = "mission"
	flow._bind_location_visit(rig.scene, {"craft_id":"visitor","location_id":"polisa","unit_ids":["pilot"],"fireteam_ids":["team"]})
	_check(controller.get_campaign_pilot_flight_guard("visitor").get("reason") == "pilot_not_aboard", "real guard rejects deployed pilot")
	var before: Dictionary = rig.sim.get_hex_ground_planning_snapshot()
	var boarding: Dictionary = flow.board_polisa_craft_crew("visitor")
	_check(not boarding.get("ok",false) or rig.sim.get_hex_unit_state("pilot").is_empty(), "public boarding never reports success while pilot remains on ground")
	_check(rig.sim.get_hex_ground_planning_snapshot() != before or not rig.sim.effects_queue.is_empty(), "public boarding creates a committed or pending Root transition")
	# Retirement is a separate public Flow call. Do not regard queued effects as
	# successful release; current Root presence and registry identity are checked.
	flow._finish_space_surface_departure("visitor")
	_check(not rig.units.get_unit("pilot") == null, "retirement keeps known actor identity")
	_check(rig.sim.get_hex_unit_state("pilot").is_empty() or controller._deployed_unit_ids.has("pilot"), "retirement projection waits for actual Root presence release")
	rig.sim._physics_process(0.1)
	_check(rig.sim.get_hex_unit_state("pilot").is_empty() and rig.sim.get_hex_movement_readout("pilot").is_empty() and rig.units.get_unit("pilot") == actor, "Root releases ground and movement while retaining actor identity")
	flow.free(); rig.scene.free()
	print("POLISA_REAL_VISIT_BOARD_RETIRE passed=", passed, " failed=", failed)
	quit(1 if failed else 0)
