extends SceneTree
class ViewProbe extends "res://scripts/terrain/terrain_map_3d_view.gd":
	func _ready() -> void: pass
	func _process(_d: float) -> void: pass
class ControllerProbe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var cleared := []
	var signals_emitted := 0
	func _ready() -> void: pass
	func _process(_d: float) -> void: pass
	func _refresh_mission_dropship_panel() -> void: pass
	func _refresh_world_overlays() -> void: pass
	func _emit_planning_state_changed() -> void: signals_emitted += 1
	func _clear_fireteam_runtime_execution_for_post_drop(team: String) -> void: cleared.append(team)
	func _can_issue_local_commands() -> bool: return true
	func _is_mission_dropship_position_inside_player_area(_p: Vector2) -> bool: return true
	func _find_friendly_unit_by_id(id: String) -> Node: return _get_campaign_sortie_unit(id)
class Person extends Node2D:
	var id := ""
	func get_unit_id() -> String: return id
	func get_health() -> int: return 100
	func get_fireteam_id() -> String: return "ft1"
	func get_display_name() -> String: return id
	func get_portrait_path() -> String: return ""
class Scenario extends RefCounted:
	func is_noncombat_singleplayer() -> bool: return true
class Setup extends Node:
	var _loaded_terrain_map_data: RefCounted
	var selected_team_unit_ids := PackedStringArray(["pilot","operator1","operator2"])
	var _mission_scenario := Scenario.new()
	var selected_team_fireteam_ids := PackedStringArray(["ft1","ft1","ft1"])
	var map_file_path := "res://maps/polisa_station.json"
class FlowProbe extends "res://scripts/meta/meta_layer_flow.gd":
	func _ready() -> void: pass
	func _process(_d: float) -> void: pass
	func _refresh_homebase_screen() -> void: pass
	func _refresh_singleplayer_services() -> void: pass
	func _get_fob_screen(): return null
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const ROOT = preload("res://scripts/core/simulation_root.gd")
var count := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	count += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var flow := FlowProbe.new(); root.add_child(flow)
	flow._current_meta_view="homebase"
	var place := Node2D.new(); flow.add_child(place)
	place.set_meta("location_id","polisa")
	# Deliberately no campaign_ground_pilot_id: a mode flag must not exempt station ships.
	var identity := {"craft_id":"source","location_id":"polisa","scenario_id":"polisa_visit","job_id":"","unit_ids":["operator1","operator2"],"fireteam_ids":["ft1","ft1"]}
	place.set_meta("singleplayer_mission_identity",identity)
	place.set_meta("singleplayer_visit_identities",{"source":identity})
	var setup := Setup.new(); setup.name="MissionSetup"; setup._loaded_terrain_map_data=load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/polisa_station.json"); place.add_child(setup)
	var registry = load("res://scripts/terrain/terrain_registry.gd").new(); registry.name="TerrainRegistry"; registry.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for tile in setup._loaded_terrain_map_data.get_tiles(): registry.register_tile(tile)
	place.add_child(registry)
	var simulation = ROOT.new(); simulation.name="SimulationRoot"; place.add_child(simulation); simulation.set_physics_process(false)
	var view := ViewProbe.new(); view.name="Primary3DView"; place.add_child(view)
	var c := ControllerProbe.new(); c.name="TacticalController"; place.add_child(c)
	var actors := {}
	var unit_registry = load("res://scripts/registries/unit_registry.gd").new(); unit_registry.name="BaseFixtureRegistry"; flow.add_child(unit_registry)
	for id in setup.selected_team_unit_ids:
		var person := Person.new(); person.id=id; place.add_child(person); actors[id]=person
		simulation.register_known_unit(id,person); unit_registry.register_unit(id,person); c._deployed_unit_ids[id]=true
	var source := {"craft_id":"source","model_id":"cutlass","craft_type":"dropship","display_name":"Source","crew_capacity":8}
	flow._homebase_aircraft_definitions=[source]
	flow._aircraft_location_by_craft={"source":"mission"}; flow._craft_location_runtime={"source":"polisa"}; flow._assigned_aircraft_pilot_by_craft={"source":"pilot"}
	flow._location_registry.register_location("polisa",place)
	var admitted := c.admit_station_craft(source,"polisa_pad_01","source-fixture")
	if not admitted.get("ok",false): print(admitted); quit(1); return
	c._update_mission_dropship_card_fields("source",{"pilot_unit_id":"pilot"})
	var adapter = ADAPTER.new(); flow.add_child(adapter); flow._singleplayer_runtime=adapter; adapter._flow=flow
	adapter._campaign=ADAPTER.CAMPAIGN.new(); adapter._campaign.configure()
	adapter._campaign._departures_by_craft_id.source={"destination_location_id":"polisa","job_id":""}
	adapter._supply=ADAPTER.SUPPLY.new(); adapter._supply.configure(flow._homebase_aircraft_definitions); adapter._supply.configure_inventory(Array(setup.selected_team_unit_ids),["source"],false)
	adapter._supply.configure_preset_supply({"credits":3000,"stock":{}})
	adapter._travel=ADAPTER.TRAVEL.new(); adapter._travel.configure(); adapter._travel.commit_surface_registration(adapter._travel.prepare_surface_registration("source","polisa","source-surface"))
	adapter._ship_equipment=load("res://scripts/core/singleplayer_ship_equipment_state.gd").new(); adapter._ship_equipment.configure(flow._homebase_aircraft_definitions)
	adapter._simulation=simulation; simulation.configure_singleplayer_owners(adapter._campaign,adapter._supply,null,adapter._travel); simulation.configure_ship_equipment(adapter._ship_equipment)
	adapter._pad_by_craft={"source":"homebase_pad_01"}
	var base=load("res://scripts/core/base_personnel_runtime.gd").new(); flow.add_child(base); adapter._base_personnel=base
	base._flow=flow; base._sim=simulation; base._registry=unit_registry
	base._states={"pilot":{"status":"aboard","craft_id":"source"},"operator1":{"status":"aboard","craft_id":"source"},"operator2":{"status":"aboard","craft_id":"source"}}
	var before_credits: int=adapter._supply.get_supply_snapshot().credits
	var purchase: Dictionary=adapter.request_operation("station_buy_ship",{"craft_id":"source","offer_id":"polisa_ship_buccaneer","delivery_mode":"local","acquisition_pad_id":"polisa_pad_04","service_location_id":"polisa","request_id":"vertical-buy"})
	check(purchase.get("ok",false) and purchase.get("delivery_location_id","")=="polisa","actual Adapter/Supply/Root/Flow local purchase succeeds")
	if not purchase.get("ok",false): print(purchase); flow.queue_free(); await process_frame; quit(1); return
	var target := String(purchase.craft_id)
	check(adapter._supply.get_supply_snapshot().credits==before_credits-int(purchase.cost) and adapter._pad_by_craft[target]=="homebase_pad_02","one debit plus real reserved home return pad")
	check(c._is_parked_campaign_dropship(target) and c._parallel_drop_sequences_by_craft[target].units.is_empty() and adapter._travel.get_snapshot(target).phase=="surface","real new parked empty Sequence and surface Travelowner published")
	check(not c.get_campaign_pilot_flight_guard(target).ok and not c.request_campaign_crew_boarding(target).ok,"station-born empty ship has no modeflag flight/boarding exemption")
	check(flow._current_meta_view=="homebase" and flow._aircraft_location_by_craft[target]=="mission" and flow._craft_location_runtime[target]=="polisa","purchase preserves view while actual local binding published")
	var pilot_before: Vector2=actors.pilot.position
	var handoff: Dictionary=adapter.request_operation("station_handoff_crew",{"craft_id":target,"target_craft_id":target,"source_craft_id":"source","unit_ids":["pilot"],"pilot_id":"pilot","service_location_id":"polisa","request_id":"vertical-handoff"})
	check(handoff.get("ok",false) and actors.pilot.position==pilot_before and simulation.effects_queue.is_empty(),"actual Adapter->Flow->Tactical handoff has no actor teleport or presence effect")
	if not handoff.get("ok",false): print(handoff); flow.queue_free(); await process_frame; quit(1); return
	var visits: Dictionary=place.get_meta("singleplayer_visit_identities")
	check(visits[target].unit_ids==["pilot"] and visits.source.unit_ids==["operator1","operator2"] and not flow._assigned_aircraft_pilot_by_craft.has("source") and flow._assigned_aircraft_pilot_by_craft[target]=="pilot","Flow visits/fireteams/globalpilot unique including legacy sourcepilot completion")
	check(base._states.pilot.craft_id==target and base._states.operator1.craft_id=="source" and base._states.operator2.craft_id=="source","real BasePersonnel remote bindings handed off exactly")
	# Fixture placement at the target is explicit; handoff above never moves actors.
	actors.pilot.position=c._parallel_drop_sequences_by_craft[target].position
	var boarding: Dictionary=adapter.request_operation("station_board_crew",{"craft_id":target,"service_location_id":"polisa"})
	check(boarding.get("reason","")=="pilot_boarding_pending" and simulation.effects_queue.size()==1 and simulation.effects_queue[0].unit_id=="pilot" and simulation.effects_queue[0].effect_type=="dropship_embark_unit","actual existing Root queue receives exactly transferred pilot embark")
	check(c._deployed_unit_ids.has("operator1") and c._deployed_unit_ids.has("operator2") and not c.get_campaign_pilot_flight_guard(target).ok,"operators remain while pending real presence blocks target departure")
	print("POLISA_VERTICAL_RESULT checks=",count," failures=",failures," presence_boundary=queued_not_committed")
	flow.queue_free(); await process_frame
	quit(1 if failures else 0)
