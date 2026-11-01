extends SceneTree
## Real map/view/setup boundary checks, then editor-to-live movement.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const EDITOR = preload("res://scenes/editor/map_editor.tscn")
const MISSION = preload("res://scenes/tests/mission_reactivity_test.tscn")
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const SCENARIO_DATA = preload("res://scripts/mission/mission_scenario_data.gd")
const CONTENT_MAP := "res://maps/frontier_workyard_24x20.json"
const SCENARIO := "res://data/mission_scenarios/frontier_workyard_24x20.json"
const OUT := "res://output/grafik_20261101/pass07_runtime/"
var passed := 0
var failed := 0
var checks: Array = []
var runtime_controls: Array = []
var movement: Dictionary = {}
var editor_authoring: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks.append({"label":label,"passed":value})
	if value:
		passed += 1
	else:
		failed += 1
		print("FAIL: ",label)

func frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func run() -> void:
	if OS.get_cmdline_user_args().has("--authoring-check"):
		check_flat_map()
		finish()
		return
	if OS.get_cmdline_user_args().has("--play-workyard"):
		await content_slice(true)
		print("AUTHORING RUN: normal mission classes; original Editor PackedScene and Meta start policies unchanged.")
		return
	if OS.get_cmdline_user_args().has("--cli-profile-check"):
		await cli_profile_check()
		finish()
		return
	var profile = PROFILE.new()
	check(profile.surface_color("road")!=profile.surface_color("ground"),"regular authored roads are distinguishable from Frontier dust")
	check(profile.has_method("surface_material_for"),"surface role chooses generic paved material independently of authored preview wear")
	if profile.has_method("surface_material_for"):
		var road: ShaderMaterial = profile.surface_material_for("road")
		check(bool(road.get_shader_parameter("paved_surface")),"stored road uses the existing paved shader route")
		check(not bool(road.get_shader_parameter("authored_paving_wear")),"regular road does not inherit coordinate-bound preview tire marks")
	var hex = MAP.create_empty("hex_setup_boundary",Vector2i(8,8),Vector2.ZERO,64.0,32.0,3,"hex_axial_v1")
	hex.set_terrain_visual_theme_id("frontier_illustrated_v1")
	var old = MAP.create_empty("old_setup_boundary",Vector2i(8,8),Vector2.ZERO)
	var view = VIEW.new()
	root.add_child(view)
	view.configure_from_map(hex)
	check(bool(view.get_render_snapshot().get("frontier_art_enabled",false)),"saved Frontier theme activates profile without a start flag")
	view.configure_from_map(old)
	check(not bool(view.get_render_snapshot().get("frontier_art_enabled",true)),"legacy map clears map-selected profile")
	view.set_frontier_art_enabled(false)
	view.configure_from_map(hex)
	check(not bool(view.get_render_snapshot().get("frontier_art_enabled",true)),"explicit false while already false survives later Frontier map")
	view.set_frontier_art_enabled(true)
	view.configure_from_map(old)
	check(bool(view.get_render_snapshot().get("frontier_art_enabled",false)),"explicit true survives later legacy map")
	check(view.has_method("clear_frontier_art_override"),"explicit override can return to saved-map selection")
	if view.has_method("clear_frontier_art_override"):
		view.clear_frontier_art_override()
		check(not bool(view.get_render_snapshot().get("frontier_art_enabled",true)),"clearing override restores legacy profile")
	view.queue_free()
	await frames(2)
	var scratch := "user://frontier_runtime_boundary_map.json"
	hex.save_to_file(scratch)
	var editor = EDITOR.instantiate()
	editor.map_file_path = scratch
	root.add_child(editor)
	await frames(7)
	check(editor.get("_terrain_registry").get_grid_topology()=="hex_axial_v1","real editor registry keeps loaded Hex topology")
	editor.queue_free()
	await frames(3)
	var mission = MISSION.instantiate()
	mission.get_node("MissionSetup").map_file_path = scratch
	root.add_child(mission)
	await frames(18)
	check(mission.get_node("TerrainRegistry").get_grid_topology()=="hex_axial_v1","regular mission setup registry keeps loaded Hex topology")
	mission.queue_free()
	await frames(4)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	check(FileAccess.file_exists(CONTENT_MAP) and FileAccess.file_exists(SCENARIO),"authored workyard map and scenario exist for the regular loader")
	if FileAccess.file_exists(CONTENT_MAP) and FileAccess.file_exists(SCENARIO):
		check_flat_map()
		await content_slice()
	finish()

func cli_profile_check() -> void:
	var view = VIEW.new()
	var old = MAP.create_empty("cli_old",Vector2i(2,2),Vector2.ZERO)
	# Map rendering needs an attached WorldRoot/camera; only the pure selector
	# is valid before _ready, as in the production bootstrap.
	view.call("_update_frontier_art_profile")
	check(bool(view.get("_frontier_art_enabled")),"CLI selector resolves before ready without requiring a render")
	root.add_child(view)
	view.configure_from_map(old)
	check(bool(view.get_render_snapshot().get("frontier_art_enabled",false)),"CLI enables a normally configured legacy map")
	view.set_frontier_art_enabled(false)
	check(not bool(view.get_render_snapshot().get("frontier_art_enabled",true)),"explicit false can override CLI as in the original setter contract")
	view.clear_frontier_art_override()
	check(bool(view.get_render_snapshot().get("frontier_art_enabled",false)),"clearing explicit choice returns to CLI default")
	view.queue_free()
	await frames(2)

func facts(data) -> Array:
	var result: Array = []
	for tile in data.get_tiles():
		result.append(tile.to_dict())
	return result

func check_flat_map() -> void:
	var data = MAP.load_from_file(CONTENT_MAP)
	var valid := not data.get_tiles().is_empty()
	for tile in data.get_tiles():
		valid = valid and int(tile.height_level)==0 and String(tile.edge_type)=="none"
	check(valid,"authored flat workyard has no stale cliff-edge facts on ground cells")

func content_slice(play: bool = false) -> void:
	var scenario = SCENARIO_DATA.load_from_file(SCENARIO)
	check(bool(scenario.validate().get("valid",false)),"regular scenario validates against authored map and markers")
	var data = MAP.load_from_file(CONTENT_MAP)
	check(data.get_grid_size()==Vector2i(24,20) and data.get_tiles().size()==480,"regular loader receives the complete bounded 24x20 map")
	var original_facts := facts(data)
	var editor = EDITOR.instantiate()
	editor.map_file_path = CONTENT_MAP
	root.add_child(editor)
	await frames(8)
	check(bool(editor.load_mission_scenario_for_editor(SCENARIO)),"existing editor scenario action loads the new content")
	var editor_registry = editor.get("_terrain_registry")
	var editor_view = editor.get_node("Primary3DView")
	check(editor_registry.get_grid_topology()=="hex_axial_v1" and editor_view.get_render_snapshot().get("grid_topology","")=="hex_axial_v1","saved Hex topology agrees between real editor registry and view")
	check(editor_view.get_render_snapshot().get("frontier_art_profile_id","")=="frontier_illustrated_v1","editor chooses saved visual family without CLI or preview setter")
	var save_map := "user://pass07_workyard_saved.json"
	var save_scenario := "user://pass07_workyard_scenario.json"
	editor.call("_on_save_as_file_selected",save_map)
	var reloaded = MAP.load_from_file(save_map)
	check(reloaded.get_grid_topology()=="hex_axial_v1" and reloaded.get_terrain_visual_theme_id()=="frontier_illustrated_v1" and facts(reloaded)==original_facts,"real editor Save As roundtrip preserves topology, theme and all tile facts")
	editor.call("_load_map",save_map)
	check(editor.save_mission_scenario_from_editor(save_scenario)==OK,"editor saves a separate scenario for regular Live Test")
	editor_authoring = editor.get_authoring_validation_snapshot(false)
	check(int(editor_authoring.get("error_count",-1))==0 and Array(editor_authoring.get("warnings",[]))==["map_has_no_cover_tiles"],"real authoring validation has zero errors and only the explicitly unimplemented-cover advisory")
	await capture("runtime_editor",editor_view)
	var mission = editor.create_live_test_scene_from_current_scenario()
	var setup = mission.get_node("MissionSetup")
	var baseline_mission = MISSION.instantiate()
	check(setup.defer_friendly_runtime_activation==baseline_mission.get_node("MissionSetup").defer_friendly_runtime_activation,"ordinary editor Live Test preserves original PackedScene activation policy")
	baseline_mission.free()
	check(not setup.defer_friendly_runtime_activation,"existing regular authoring mission starts active independently of deferred Meta deployment")
	setup.allow_full_roster_when_selection_empty = false
	setup.selected_team_unit_ids = PackedStringArray(["unit_alpha","unit_bravo","unit_delta","unit_hotel"])
	setup.selected_team_fireteam_ids = PackedStringArray(["blue","blue","blue","blue"])
	setup.selected_fireteam_definitions = [{"id":"blue","label":"BLUE","lead_unit_id":"unit_alpha","respawn_enabled":false,"loadout":"medium"}]
	editor.queue_free()
	await frames(3)
	root.add_child(mission)
	await frames(22)
	var registry = mission.get_node("TerrainRegistry")
	var view = mission.get_node("Primary3DView")
	var sim = mission.get_node("SimulationRoot")
	var live_data = setup.get("_loaded_terrain_map_data")
	check(live_data.get_grid_topology()=="hex_axial_v1" and registry.get_grid_topology()=="hex_axial_v1" and view.get_render_snapshot().get("grid_topology","")=="hex_axial_v1","real mission map, registry and renderer share Hex topology")
	check(facts(live_data)==original_facts,"regular setup preserves authored map facts")
	check(view.get_render_snapshot().get("frontier_art_profile_id","")=="frontier_illustrated_v1","regular mission chooses map profile without preview code")
	check(int(view.get_render_snapshot().get("missing_asset_mapping_count",-1))==0,"regular map and unit renderer has no missing asset mappings")
	var map_root: Node3D = view.get_node("ViewportContainer/SubViewport/WorldRoot/MapRoot3D")
	var props := map_root.find_children("Asset_frontier_utility_fuel_01_*","Node3D",false,false)
	check(props.size()==1 and int(view.get_render_snapshot().get("asset_model_count",0))==1,"normal object-layer pipeline loads exactly one utility GLB")
	if props.size()==1:
		var bounds := mesh_bounds(props[0])
		check(absf(bounds.position.y)<0.0001 and absf(bounds.size.y-0.9345)<0.001,"mapped original GLB stands on tile zero at 0.35 scale")
	var origin: Vector2 = registry.grid_to_world(Vector2i(6,9))
	var goal: Vector2 = registry.grid_to_world(Vector2i(16,9))
	for grid in [Vector2i(6,9),Vector2i(11,9),Vector2i(16,9)]:
		check(view.world_to_grid_position(registry.grid_to_world(grid))==grid,"renderer/registry agree on authored marker or anchor %s"%grid)
	var path: Array = PATHFINDER.new().find_path(Vector2i(6,9),Vector2i(16,9),registry)
	var legal := path.size()>10
	for i in range(path.size()):
		legal = legal and registry.is_walkable(path[i]) and (i==0 or registry.are_grid_neighbors(path[i-1],path[i]))
	check(legal and not path.has(Vector2i(11,9)),"stored utility reservation forces legal six-neighbor detour")
	var revision: int = registry.get_revision()
	view.set_frontier_art_enabled(false)
	view.set_frontier_art_enabled(true)
	view.clear_frontier_art_override()
	check(facts(live_data)==original_facts and registry.get_revision()==revision and PATHFINDER.new().find_path(Vector2i(6,9),Vector2i(16,9),registry)==path,"map profile changes do not mutate facts, revision or path")
	var units = mission.get_node("UnitRegistry")
	var lead: Node2D = units.get_unit("unit_alpha")
	check(lead!=null and units.get_unit("unit_hotel")!=null and lead.get_script().resource_path!="res://scripts/tests/frontier_art_preview_actor.gd","active authoring mission registers real roster units, not preview actors")
	var controller = mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams",PackedStringArray(["blue"]),false)
	view.focus_world_position(origin.lerp(goal,0.5))
	view.set("_camera_size",15.0)
	view.call("_update_camera_transform")
	await capture("runtime_mission_start",view)
	if play:
		print("WORKYARD PLAY: click a Hex target, MOVE, GO. Original Editor Live Test activation; no Meta/player-LZ deployment was exercised.")
		return
	var start: Vector2 = lead.global_position
	var tick_before: int = sim.tick_counter
	controller.select_tile_from_world_position_for_test(goal)
	check(bool(controller.issue_move()),"normal mission MOVE accepts the selected tile for BLUE")
	check(bool(controller.execute_selected_fireteam_orders()),"normal mission GO executes the real fireteam plan")
	var trace: Array = []
	var blocked_samples := 0
	var illegal_jumps := 0
	var previous: Vector2i = registry.world_to_grid(lead.global_position)
	trace.append([previous.x,previous.y])
	var old_time_scale: float = Engine.time_scale
	Engine.time_scale = 3.0 # Actual engine physics, accelerated wall time only.
	for _frame in range(1800):
		await physics_frame
		var current: Vector2i = registry.world_to_grid(lead.global_position)
		if not registry.is_walkable(current):
			blocked_samples += 1
		if current!=previous:
			if not registry.are_grid_neighbors(previous,current):
				illegal_jumps += 1
			trace.append([current.x,current.y])
			previous = current
		if registry.get_movement_distance(lead.global_position,goal)<85.0:
			break
	Engine.time_scale = old_time_scale
	movement = {"start_world":start,"end_world":lead.global_position,"goal_world":goal,"displacement_world":lead.global_position.distance_to(start),"remaining_physical_world":registry.get_movement_distance(lead.global_position,goal),"physics_ticks":sim.tick_counter-tick_before,"sampled_grid_trace":trace,"blocked_samples":blocked_samples,"nonneighbor_jumps":illegal_jumps,"engine_time_scale":3.0,"teleports":false,"entry":"TacticalController MOVE + GO -> FireteamMovementController -> SimulationRoot"}
	check(lead.global_position.distance_to(start)>300.0 and registry.get_movement_distance(lead.global_position,goal)<85.0,"real FTL movement reaches the far side of the utility reservation")
	check(blocked_samples==0 and illegal_jumps==0 and trace.size()>10 and sim.tick_counter>tick_before,"actual engine movement traverses legal Hex cells without reservation penetration or teleports")
	await capture("runtime_mission_after_move",view)
	view.focus_world_position(registry.grid_to_world(Vector2i(11,9)))
	view.set("_camera_size",6.0)
	view.call("_update_camera_transform")
	await capture("runtime_utility_close",view)
	mission.queue_free()
	await frames(5)
	for temporary in [save_map,save_scenario]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))

func mesh_bounds(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.find_children("*","MeshInstance3D",true,false):
		var part: AABB = child.global_transform * child.get_aabb()
		result = part if first else result.merge(part)
		first = false
	return result

func capture(id: String,view) -> void:
	if not OS.get_cmdline_user_args().has("--native-controls"):
		return
	await frames(12)
	await RenderingServer.frame_post_draw
	var path := OUT+id+".png"
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	var camera: Camera3D = view.get_node("ViewportContainer/SubViewport/WorldRoot/Camera3D")
	runtime_controls.append({"id":id,"path":path,"sha256":FileAccess.get_sha256(path),"error":OK,"map_path":CONTENT_MAP,"map_sha256":FileAccess.get_sha256(CONTENT_MAP),"theme_id":"frontier_illustrated_v1","grid_topology":"hex_axial_v1","entry_scene":EDITOR.resource_path if id=="runtime_editor" else MISSION.resource_path,"mission_entry_scene":MISSION.resource_path,"fact_source":"saved TerrainMapData -> TerrainRegistry; fixed authoring reservation, no runtime visual-to-nav","camera":str(camera.global_transform),"size":camera.size,"resolution":str(root.size),"snapshot":view.get_render_snapshot(),"entry":"regular editor / mission, original PackedScene activation policy"})

func finish() -> void:
	var report := {"passed":passed,"failed":failed,"checks":checks,"movement":movement,"runtime_controls":runtime_controls,"scope":"regular Editor Save/Reload and MissionSetup/real FTL; original active authoring policy, not Meta/LZ deployment acceptance","engine":Engine.get_version_info()}
	report["map_path"] = CONTENT_MAP
	report["map_sha256"] = FileAccess.get_sha256(CONTENT_MAP)
	report["scenario_path"] = SCENARIO
	report["scenario_sha256"] = FileAccess.get_sha256(SCENARIO)
	report["entry_scene"] = MISSION.resource_path
	report["editor_authoring"] = editor_authoring
	report["marker_explanation"] = "White flat diamond is saved rally_workyard (custom marker); not a hole, spawn fallback or terrain error. Utility close-up crops parts of HUD/figures and proves model contact only."
	report["facts_source"] = "TerrainMapData JSON -> TerrainRegistry -> SimulationRoot; visual renderer never creates walkability"
	report["renderer"] = {"method":RenderingServer.get_current_rendering_method(),"driver":RenderingServer.get_current_rendering_driver_name(),"adapter":RenderingServer.get_video_adapter_name()}
	var hashes := {}
	for path in ["res://scripts/terrain/terrain_map_3d_view.gd","res://scripts/terrain/frontier_art_profile.gd","res://scripts/editor/map_editor.gd","res://scripts/tests/mission_test_setup.gd","res://scripts/terrain/terrain_map_data.gd","res://scripts/terrain/terrain_registry.gd","res://scripts/terrain/hex_grid.gd","res://scripts/core/simulation_root.gd","res://shaders/terrain/frontier_ground.gdshader","res://data/terrain_tile_catalog.json","res://data/terrain_3d_asset_mapping.json","res://data/terrain_surface_visual_theme_catalog.json","res://Assets/curated/frontier_illustrated_20261101/structures_pass04/utility_fuel_01.glb"]:
		hashes[path] = FileAccess.get_sha256(path)
	report["source_sha256"] = hashes
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var suffix := "native" if OS.get_cmdline_user_args().has("--native-controls") else "cli" if OS.get_cmdline_user_args().has("--cli-profile-check") else "headless"
	var file := FileAccess.open(OUT+suffix+"_check.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	print("FRONTIER_RUNTIME_SLICE_RESULT ",JSON.stringify(report))
	quit(1 if failed else 0)
