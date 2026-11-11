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
class Simulation extends Node:
	var units := {}
	var effects_queue := []
	func _resolve_known_unit(id: String) -> Node: return units.get(id)
	func register_known_unit(id: String,unit: Node) -> void: units[id]=unit
	func enqueue_effect(effect: Dictionary) -> void: effects_queue.append(effect)
class Scenario extends RefCounted:
	func is_noncombat_singleplayer() -> bool: return true
class Setup extends Node:
	var _loaded_terrain_map_data: RefCounted
	var selected_team_unit_ids := PackedStringArray(["pilot","operator1","operator2"])
	var _mission_scenario := Scenario.new()
var count := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	count += 1
	if not ok: failures += 1; print("FAIL ",label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var place := Node2D.new(); root.add_child(place)
	place.set_meta("location_id","polisa"); place.set_meta("campaign_ground_pilot_id","pilot")
	place.set_meta("singleplayer_mission_identity",{"craft_id":"source"})
	place.set_meta("singleplayer_visit_identities",{"source":{"unit_ids":["pilot","operator1","operator2"]}})
	var setup := Setup.new(); setup.name="MissionSetup"; setup._loaded_terrain_map_data=load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/polisa_station.json"); place.add_child(setup)
	var registry = load("res://scripts/terrain/terrain_registry.gd").new(); registry.name="TerrainRegistry"; registry.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for tile in setup._loaded_terrain_map_data.get_tiles(): registry.register_tile(tile)
	place.add_child(registry)
	var simulation := Simulation.new(); simulation.name="SimulationRoot"; place.add_child(simulation)
	var view := ViewProbe.new(); view.name="Primary3DView"; place.add_child(view)
	var c := ControllerProbe.new(); place.add_child(c)
	for id in setup.selected_team_unit_ids:
		var person := Person.new(); person.id=id; place.add_child(person); simulation.units[id]=person; c._deployed_unit_ids[id]=true
	var source := {"craft_id":"source","model_id":"cutlass","craft_type":"dropship","display_name":"Source","crew_capacity":8}
	var target := {"craft_id":"target","model_id":"buccaneer","craft_type":"fighter","display_name":"Target","crew_capacity":1}
	var preview := c.preview_station_craft_admission(source,"polisa_pad_01")
	check(preview.ok,"real R08marker/registry/renderer preflight")
	check(c._mission_drop_cards.is_empty() and c._parallel_drop_sequences_by_craft.is_empty(),"preflight read only")
	check(c.admit_station_craft(source,"polisa_pad_01","source-buy").ok,"real source admission")
	check(c.admit_station_craft(target,"polisa_pad_04","target-buy").ok,"real target admission")
	check(c.signals_emitted==0,"admission emit-free before Flowpublish")
	check(c._is_parked_campaign_dropship("source") and c._is_parked_campaign_dropship("target"),"actual existing parked guard accepts both")
	check(c._parallel_drop_sequences_by_craft.target.units.is_empty() and c._parallel_drop_sequences_by_craft.target.embarked_unit_ids.is_empty(),"target genuinely uncrewed")
	check(c.admit_station_craft(target,"polisa_pad_04","target-buy").get("replayed",false),"admission idempotence")
	check(not c.admit_station_craft(target,"polisa_pad_05","target-buy").ok,"conflicting replay rejected")
	check(not c.preview_station_craft_admission({"craft_id":"third","model_id":"cutlass","crew_capacity":8},"polisa_pad_04").ok,"occupied actual pad rejected")
	c._update_mission_dropship_card_fields("source",{"pilot_unit_id":"pilot"})
	var memberships := {"source":["pilot","operator1","operator2"],"target":[]}
	check(not c.preview_station_crew_handoff("source","target",PackedStringArray(["operator1"]),"operator1",memberships).ok,"partial normal ft1 rejected")
	check(c.preview_station_crew_handoff("source","target",PackedStringArray(["pilot"]),"pilot",memberships).ok,"known sourcepilot tempft1 may transfer alone")
	c._update_mission_dropship_card_fields("historical",{"state":"ready","pilot_unit_id":"pilot","crew_capacity":8})
	check(c.preview_station_crew_handoff("source","target",PackedStringArray(["pilot"]),"pilot",memberships).ok,"historical ready card outside active membership cannot own local pilot")
	check(c.assign_campaign_pilot("source","pilot").ok,"raw source pilot assignment ignores historical ready alias")
	check(not c.assign_campaign_pilot("target","operator1").ok,"raw pilot assignment cannot move foreign visit member")
	c.signals_emitted=0 # Explicit successful assignment published before transaction checks below.
	var handoff := c.commit_station_crew_handoff("source","target",PackedStringArray(["pilot"]),"pilot",memberships,"crew-1")
	check(handoff.ok and c.signals_emitted==0,"handoff emit-free commit")
	place.set_meta("singleplayer_visit_identities",{"source":{"unit_ids":["operator1","operator2"]},"target":{"unit_ids":["pilot"]}})
	check(c._campaign_craft_crew_ids("target")==PackedStringArray(["pilot"]) and c._campaign_craft_crew_ids("source")==PackedStringArray(["operator1","operator2"]),"exact published craft membership")
	check(not c.get_campaign_pilot_flight_guard("target").ok,"deployed targetpilot cannot depart")
	var target_position: Vector2=c._parallel_drop_sequences_by_craft.target.position
	simulation.units.pilot.position=target_position
	var boarding := c.request_campaign_crew_boarding("target")
	check(boarding.get("reason","")=="pilot_boarding_pending" and simulation.effects_queue.size()==1 and simulation.effects_queue[0].unit_id=="pilot","real existing boarding enqueues exact pilot only")
	check(c._deployed_unit_ids.has("operator1") and c._deployed_unit_ids.has("operator2"),"source operators remain local")
	check(not c.get_campaign_pilot_flight_guard("target").ok,"pending effect blocks departure")
	simulation.effects_queue.clear(); simulation.units.pilot.set_meta("dropship_embarked",true)
	check(c.get_campaign_pilot_flight_guard("target").ok,"target guard accepts its own committed aboard pilot")
	check(c._can_deploy_parked_campaign_crew("target"),"nonprimary local craft can deploy its actual crew")
	var entry: Dictionary = c._build_mission_dropship_visual_entry(c._find_raw_mission_dropship_card_entry("target"),1,false,Vector2.ZERO,false,false,2)
	check(entry.get("model_id","")=="buccaneer" and view._get_frontier_dropship_visual_entry(entry).asset_id=="buccaneer_01","actual card->render selects existing Buccaneer")
	c._order_plans_by_key["ft1|test"]={"keep":true}
	c.retire_location_craft_visit("target",PackedStringArray(["pilot"]))
	check(c.cleared.is_empty() and c._order_plans_by_key.has("ft1|test"),"returning pilot does not clear remaining ft1 execution")
	c.finalize_station_craft_update()
	check(c.signals_emitted==2,"only boarding and explicit finalize publish planning")
	print("POLISA_CONTROLLER_RESULT checks=",count," failures=",failures)
	place.queue_free(); await process_frame
	quit(1 if failures else 0)
