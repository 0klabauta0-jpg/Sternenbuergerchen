extends "res://scripts/tests/hex_runtime_selection_verifier.gd"

class ServiceController extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var fixture_lz := Vector2.ZERO
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func preview_station_craft_admission(_craft: Dictionary, _pad: String = "", _reentry: bool = false) -> Dictionary:
		return {"ok":true,"pad_id":"fixture-pad","position":fixture_lz,"ground_body_profile":{}}
	func _ground_ship_touchdown_ready(_craft: String, _position: Vector2, _visual: bool) -> bool: return true
	func get_ground_ship_blocked_cells(_craft: String = "") -> Dictionary:
		return {"ok":true,"registry_id":get_node("../SimulationRoot").get_hex_ground_terrain_registry().get_instance_id(),"blocked_cells":[]}
	func finalize_station_craft_update() -> void: pass
	func _emit_planning_state_changed() -> void: pass
	func _store_selected_mission_dropship_plan() -> void: pass
	func _refresh_world_overlays() -> void: pass
	func _refresh_mission_dropship_panel() -> void: pass
	func _update_ui(_include_heavy_surfaces: bool = true, _force_heavy_surfaces: bool = true) -> void: pass

class Flow extends "res://scripts/meta/meta_layer_flow.gd":
	func _ready() -> void: pass
	func _sync_mission_host_visibility() -> void: pass

class CompletedHomeOwner extends RefCounted:
	func get_snapshot() -> Dictionary: return {"phase":"settled","craft_id":"shuttle-real","person_id":"polisa_recruit_real"}
class HomeBase extends Node:
	func get_shuttle_person_status(_id: String) -> Dictionary: return {"ok":true,"has_bed":true,"has_task":false}

var evidence_controller: Node
var home_adapter: Node
class BaseFlow extends Node:
	var _all_team_units: Array = []
	var _aircraft_location_by_craft := {}
	var _location_registry = preload("res://scripts/mission/location_runtime_registry.gd").new()
	func _find_pending_mission_craft_transfer(_id: String) -> Dictionary: return {}
	func is_campaign_start() -> bool: return true

func _verify_evidence(kind: String, person: String, craft: String, receipt: Dictionary) -> bool:
	if kind == "boarding_polisa": return is_instance_valid(evidence_controller) and evidence_controller.verify_polisa_service_departure(person,craft,receipt)
	return is_instance_valid(home_adapter) and home_adapter._verify_polisa_service_evidence(kind,person,craft,receipt)
func _home_status(id: String) -> Dictionary:
	return home_adapter._base_personnel.get_shuttle_person_status(id) if is_instance_valid(home_adapter) and is_instance_valid(home_adapter._base_personnel) else {"ok":true,"has_bed":false,"has_task":false}

func _run() -> void:
	var rig: Dictionary = _selection_rig(PackedStringArray(["a"]))
	# The inherited four-cell strip cannot hold a returning crew; extend the fixture terrain.
	for x in range(-3, 8):
		for y in range(-3, 8):
			var grid := Vector2i(x,y)
			if y == 0 and x >= 0 and x <= 3: continue
			rig.terrain.register_tile(TILE.new({"grid_position":grid,"tile_id":str(grid),"explicit_hex_ramps":true}))
	rig.scene.set_meta("location_id", "polisa")
	rig.scene.set_meta("campaign_ground_pilot_id", "a")
	rig.scene.set_meta("singleplayer_visit_identities", {"source":{"craft_id":"source","unit_ids":["a"],"fireteam_ids":["ft1"]}})
	rig.sim.name = "SimulationRoot"
	rig.setup.name = "MissionSetup"
	rig.setup.simulation_root_path = rig.setup.get_path_to(rig.sim)
	var extra := SelectionActor.new()
	extra.unit_id = "__unused_friendly_slot_2"; extra.team_id = "team_unused"
	rig.scene.add_child(extra); extra.set_process(false); extra.set_physics_process(false); extra.visible=false
	rig.setup.unit_paths.append(rig.setup.get_path_to(extra))
	rig.setup._friendly_unit_slot_paths.append(rig.setup.get_path_to(extra))
	var recruit := "polisa_recruit_real"
	var recruit_result: Dictionary = rig.setup.request_polisa_recruit_admission({"unit_id":recruit,"display_name":"Recruit"}, Vector2i(1,0))
	if not recruit_result.get("ok", false): print("RECRUIT_FIXTURE: ", recruit_result)
	_check(recruit_result.get("ok", false) and rig.setup.get_polisa_recruit_admission(recruit).get("ok", false), "real MissionSetup/Hex recruit admission")
	var pilot := "station_shuttle_pilot_real"
	var pilot_result: Dictionary = rig.setup.request_polisa_recruit_admission({"unit_id":pilot,"display_name":"Pilot"}, Vector2i(3,0))
	if not pilot_result.get("ok", false): print("PILOT_FIXTURE: ", pilot_result)
	_check(pilot_result.get("ok", false) and rig.setup.get_polisa_recruit_admission(pilot).get("ok", false), "real MissionSetup/Hex station pilot admission")
	var pilot_actor: Node = rig.units.get_unit(pilot)
	_check(is_instance_valid(pilot_actor) and String(pilot_actor.call("get_fireteam_id")).is_empty(), "station pilot has no player-command fireteam")
	_check(not rig.leader.get_assigned_units().has(pilot_actor), "foreign station pilot is not a player RuntimeLeader member")
	var controller := ServiceController.new(); controller.name="TacticalController"; controller.fixture_lz=rig.terrain.grid_to_world(Vector2i(1,0)); rig.scene.add_child(controller)
	pilot_actor.call("set_fireteam_id", "ft1")
	controller._apply_unit_click_selection(pilot_actor, false)
	_check(controller._selected_fireteam_ids.is_empty(), "foreign pilot cannot be selected even if a fireteam is assigned")
	pilot_actor.call("set_fireteam_id", "")
	controller._parallel_drop_sequences_by_craft["source"] = {"craft_id":"source","phase":"complete","position":controller.fixture_lz,"lz_position":controller.fixture_lz,"units":[rig.actors.a],"embarked_unit_ids":{}}
	controller._update_mission_dropship_card_fields("source", {"craft_id":"source","pilot_unit_id":"a"})
	var registration: Dictionary = controller.register_polisa_recruit_person(recruit,"source")
	_check(registration.get("ok", false), "real controller registers admitted recruit")
	var lifecycle = load("res://scripts/mission/polisa_shuttle_station_lifecycle.gd").new()
	var admitted: Dictionary = lifecycle.admit(rig.scene,"shuttle-real",pilot,recruit,"source")
	_check(admitted.get("ok", false), "real controller admits shuttle and transfers visit")
	var walk: Dictionary = lifecycle.request_boarding_walk(rig.scene,"shuttle-real")
	if walk.get("ok", false): print("WALK_FIXTURE: ", rig.sim.command_queue)
	_check(walk.get("ok", false), "real root receives planned crew walking commands")
	if walk.get("ok", false):
		for _i in range(80): rig.sim._physics_process(0.1)
		var boarding: Dictionary = lifecycle.request_boarding(rig.scene,"shuttle-real")
		if not boarding.get("ok", false): print("BOARDING_FIXTURE: ", boarding, " recruit=",rig.sim.get_hex_unit_state(recruit)," pilot=",rig.sim.get_hex_unit_state(pilot))
		for _i in range(10): rig.sim._physics_process(0.1)
		_check(boarding.get("ok", false) or boarding.get("reason") == "pilot_boarding_pending", "real controller initiates boarding")
		_check(lifecycle.verify_boarded(rig.scene,recruit,"shuttle-real"), "real actor/hex boarding proof")
		if lifecycle.verify_boarded(rig.scene,recruit,"shuttle-real"):
			var outbound: bool = controller._apply_selected_mission_dropship_return("shuttle-real")
			_check(outbound, "real controller begins visible outbound")
			var receipt := {}
			if outbound:
				for _i in range(600):
					controller._update_drop_sequence(0.1)
					receipt = controller.get_polisa_service_departure("shuttle-real")
					if not receipt.is_empty(): break
			_check(not receipt.is_empty() and controller.verify_polisa_service_departure(recruit,"shuttle-real",receipt), "real outbound endpoint yields actor-bound proof")
			if not receipt.is_empty():
				evidence_controller = controller
				var service = load("res://scripts/core/polisa_shuttle_service.gd").new()
				service.configure(Callable(self,"_verify_evidence"), Callable(self,"_home_status"))
				_check(service.begin(recruit,"shuttle-real",receipt).get("ok", false) and service.get_snapshot().phase == "to_home", "real outbound receipt starts separate FleetTravel owner")
				_test_complete_return(rig, service, recruit, controller)
	var flow := Flow.new(); root.add_child(flow)
	flow._location_registry.register_location("polisa", rig.scene)
	flow._active_mission = rig.scene
	var saved_instance: int = rig.scene.get_instance_id()
	flow._release_active_mission()
	_check(is_instance_valid(flow._location_registry.get_location("polisa")) and flow._location_registry.get_location("polisa").get_instance_id() == saved_instance and rig.units.get_unit(recruit) != null, "persistent station and actor survive view release")
	flow.free(); rig.scene.free()
	print("RESULTS: %d passed, %d failed" % [passed,failed])
	if failed == 0: print("POLISA_SHUTTLE_FULL_LOOP_PASS")
	quit(0 if failed == 0 else 1)

func _test_complete_return(station: Dictionary, service: RefCounted, recruit: String, controller: Node) -> void:
	var cells: Array[Vector2i] = []
	for x in range(-3, 8):
		for y in range(-3, 8): cells.append(Vector2i(x,y))
	var home: Dictionary = _admission_rig(cells)
	home.scene.set_script(load("res://scripts/meta/singleplayer_runtime_adapter.gd"))
	home_adapter = home.scene
	var flow := BaseFlow.new(); home.scene.add_child(flow)
	flow._all_team_units = [{"unit_id":recruit,"display_name":"Recruit","recruit_location":"polisa"}]
	flow._location_registry.register_location("polisa", station.scene)
	var base = load("res://scripts/core/base_personnel_runtime.gd").new(); home.scene.add_child(base)
	base._flow = flow; base._sim = home.sim; base._terrain = home.terrain; base._registry = home.units
	base._layout = {"avatar_spawn_grid":[0,0],"interiors":[{"id":"habitat_cutaway_01","door_grid":[0,0]}],"beds":[],"landing_pads":[{"id":"homebase_pad_01","grid":[3,0],"interaction_grid":[3,0],"built":true}]}
	base._source_layout = {"beds":[]}; base._hex_required = true
	var actor = load("res://scripts/core/base_personnel_actor.gd").new(); actor.unit_id=recruit; actor.visible=false; base.add_child(actor)
	home.units.register_unit(recruit,actor); home.sim.register_known_unit(recruit,actor)
	base._states[recruit] = {"unit_id":recruit,"name":"Recruit","status":"station","craft_id":"","bed_id":"","action":{},"last_result":{},"auto_rest_enabled":true}
	home.sim.configure_base_personnel(base); home.sim.tick_processed.connect(base._on_tick)
	home_adapter._base_personnel=base; home_adapter._flow=flow; home_adapter._polisa_shuttle=service
	var landing = load("res://scripts/core/polisa_shuttle_home_lifecycle.gd").new()
	landing.configure(home_adapter._reserve_service_home_pad,home_adapter._validate_service_home_pad,home_adapter._release_service_home_pad)
	home_adapter._polisa_shuttle_home=landing
	for i in range(60):
		service.advance(1.0); home_adapter._advance_polisa_shuttle_home(1.0)
		if service.get_snapshot().phase == "home_waiting": break
	_check(service.get_snapshot().phase == "home_waiting" and base._states[recruit].status == "outside" and not home.sim.get_hex_unit_state(recruit).is_empty(),"real FleetTravel and actual base Hex owner deliver person home")
	for i in range(300): service.advance(1.0)
	_check(service.get_snapshot().phase == "return_boarding_required","five minutes without real bed or task requests return")
	for i in range(120):
		home_adapter._advance_polisa_shuttle_home(0.1); home.sim._physics_process(0.1)
		if service.get_snapshot().phase == "to_station": break
	_check(service.get_snapshot().phase == "to_station" and home.sim.get_hex_unit_state(recruit).is_empty(),"actual base Hex movement and boarding starts return flight")
	for i in range(500):
		service.advance(0.1); home_adapter._advance_polisa_shuttle_home(0.1)
		controller._update_drop_sequence(0.1); station.sim._physics_process(0.1)
		if service.get_snapshot().phase == "idle": break
	if service.get_snapshot().phase != "idle":
		var seq: Dictionary = controller._parallel_drop_sequences_by_craft["shuttle-real"]
		print("ADAPTER_DIAG: ", load("res://scripts/mission/hex_ground_deployment_adapter.gd").new().advance_phase(station.sim,seq,seq.lz_position + controller._get_unload_offset(0,"NW"),Callable(controller,"get_ground_ship_blocked_cells")))
		print("RETURN_DIAG: ", service.get_snapshot().phase, " last=", controller.get("_last_command_text"), " ground=", station.sim.get_hex_ground_planning_snapshot(), " sequence=", controller.get("_parallel_drop_sequences_by_craft"))
	_check(service.get_snapshot().phase == "idle" and Dictionary(station.scene.get_meta("singleplayer_station_personnel", {})).has(recruit),"return flight completes station landing, resident transfer and teardown")
	home_adapter = null
	home.scene.free()
