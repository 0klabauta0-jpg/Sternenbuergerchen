extends "res://scripts/tests/hex_runtime_selection_verifier.gd"

class ServiceController extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var fixture_lz := Vector2.ZERO
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func preview_station_craft_admission(_craft: Dictionary, _pad: String = "", _reentry: bool = false) -> Dictionary:
		return {"ok":true,"pad_id":"fixture-pad","position":fixture_lz,"ground_body_profile":{}}
	## Fixture-Eingabe: Das Einsteigen misst in Hex-Besuchen gegen den Zugangspunkt am Schiffsrumpf (seit b5227ab21), nicht gegen die
	## Landeposition. Das gebundene ground_body_profile gibt es in dieser Attrappe nicht; der Zugangspunkt liegt hier auf der Landeposition (Feld (1,0)).
	func get_campaign_ground_ship_access(_id: String) -> Dictionary: return {"ok":true,"position":fixture_lz}
	## Wie in polisa_shuttle_full_loop_verifier: Die echte Funktion verlangt ein gebundenes ground_body_profile je Schiff (read_bound) und
	## liefert in dieser Attrappe einen Fehler; ohne diese Eingabe laeuft die Besatzung nicht zum Schiff zurueck. Hier: keine Rumpfzellen.
	func get_ground_ship_blocked_cells(_craft: String = "") -> Dictionary:
		return {"ok":true,"registry_id":get_node("../SimulationRoot").get_hex_ground_terrain_registry().get_instance_id(),"source_signature":"fixture","blocked_cells":[]}
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
func _verify_evidence(kind: String, person: String, craft: String, receipt: Dictionary) -> bool:
	return kind == "boarding_polisa" and is_instance_valid(evidence_controller) and evidence_controller.verify_polisa_service_departure(person,craft,receipt)
func _home_status(_id: String) -> Dictionary: return {"ok":true,"has_bed":false,"has_task":false}

func _run() -> void:
	var rig: Dictionary = _selection_rig(PackedStringArray(["a"]))
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
	var flow := Flow.new(); root.add_child(flow)
	flow._location_registry.register_location("polisa", rig.scene)
	flow._active_mission = rig.scene
	var saved_instance: int = rig.scene.get_instance_id()
	flow._release_active_mission()
	_check(is_instance_valid(flow._location_registry.get_location("polisa")) and flow._location_registry.get_location("polisa").get_instance_id() == saved_instance and rig.units.get_unit(recruit) != null, "persistent station and actor survive view release")
	var base := HomeBase.new(); root.add_child(base)
	var cleanup: Dictionary = controller.retire_polisa_service_after_home("shuttle-real",recruit,CompletedHomeOwner.new(),base)
	_check(cleanup.get("ok", false), "real selection owner retires remote pilot and recruit after home handoff")
	_check(rig.units.get_unit(recruit) == null and rig.units.get_unit(pilot) == null and rig.units.get_unit("a") == rig.actors.a, "cleanup frees both slots and preserves other player")
	base.free()
	flow.free(); rig.scene.free()
	print("RESULTS: %d passed, %d failed" % [passed,failed])
	if failed == 0: print("POLISA_SHUTTLE_REAL_GROUND_PASS")
	quit(0 if failed == 0 else 1)
