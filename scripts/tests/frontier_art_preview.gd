extends Node
## Native art/Hex migration slice. Synthetic base fixture; no campaign state.
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const SIM = preload("res://scripts/core/simulation_root.gd")
const ACTOR = preload("res://scripts/tests/frontier_art_preview_actor.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
const BACKDROP = preload("res://scripts/terrain/frontier_art_geology.gd")
const DRESSING = preload("res://scripts/terrain/frontier_art_dressing.gd")
const PAD = preload("res://scripts/terrain/frontier_outpost_pad.gd")
const CLOSED_BUILDING = preload("res://scripts/terrain/frontier_closed_buildings.gd")
const WORKLIFE = preload("res://scripts/terrain/frontier_worklife.gd")
const ART_ROOT := "res://Assets/curated/frontier_illustrated_20261101/"
const MODEL_SCALE := 0.35
const SHIP_SCALE := 0.22 # Deliberately compact fiction scale, not SC canonical metres.
const CAPTURE_ROOT := "res://docs/reports/assets/grafik-2026-11-01/engine_pass06_environment/after/"

var _view
var _data
var _registry
var _units
var _sim
var _stage: Node3D
var _crew: Array = []
var _status: Label
var _capture_mode := false
var _profile = PROFILE.new()
var _model_facts: Array = []
var _current_view_id := "overview"
var _preview_zoom_factor := 1.0
var _external_visual_owners: Dictionary = {}
var _pad_facts: Array = []
var _closed_shells: Array[Node3D] = []
var _cutaway_buildings: Array[Node3D] = []
var _buildings_closed := true
var _worklife: Node3D

func _ready() -> void:
	_capture_mode = OS.get_cmdline_user_args().has("--capture-frontier-art")
	_view = VIEW.new()
	_view.name = "Primary3DView"
	add_child(_view)
	_view.set_frontier_art_enabled(true)
	_view.set_hex_grid_visible(false)
	_view.set_editor_shadow_readability_enabled(true)
	var world: Node3D = _view.get_node("ViewportContainer/SubViewport/WorldRoot")
	_stage = Node3D.new()
	_stage.name = "ApprovedFrontierArt"
	world.add_child(_stage)
	_add_continuous_backdrop_ground()
	_data = MAP.create_empty("frontier_hex_base_preview",Vector2i(22,18),Vector2.ZERO,64.0,32.0,3,"hex_axial_v1")
	_make_terrain()
	_add_structure("habitat_cutaway_01",Vector2(8.3,6.2),"structures_pass04")
	_add_structure("freihafen_hall_01",Vector2(13.2,6.2),"structures_pass04")
	_add_structure("utility_fuel_01",Vector2(16.1,8.2),"structures_pass04")
	_add_landing_pad(Vector2(6.5,10.9),Vector2(5.0,4.4),"01")
	_add_landing_pad(Vector2(19.2,11.8),Vector2(4.2,4.1),"02")
	_add_ship("cutlass_01",Vector2(6.5,10.9),0.0)
	_add_ship("buccaneer_01",Vector2(19.2,11.8),-25.0)
	_add_solar_array(Vector2(9.1,3.8))
	var backdrop = BACKDROP.new()
	_stage.add_child(backdrop)
	_reserve_footprints(backdrop.build(_profile,Vector2(12.0,5.0)),true,backdrop)
	var dressing = DRESSING.new()
	dressing.name = "FrontierWorkingGround"
	_stage.add_child(dressing)
	_reserve_footprints(dressing.build(_profile))
	_worklife = WORKLIFE.new()
	_worklife.name = "FrontierUseGroups"
	_stage.add_child(_worklife)
	_reserve_footprints(_worklife.build())
	_registry = REGISTRY.new()
	_registry.name = "TerrainRegistry"
	add_child(_registry)
	_registry.configure_iso_grid(Vector2.ZERO,64.0,32.0,"hex_axial_v1")
	for tile in _data.get_tiles():
		_registry.register_tile(tile)
	_units = UNITS.new()
	_units.name = "UnitRegistry"
	add_child(_units)
	_sim = SIM.new()
	_sim.name = "SimulationRoot"
	_sim.unit_registry_path = NodePath("../UnitRegistry")
	_sim.terrain_registry_path = NodePath("../TerrainRegistry")
	_sim.unit_minimum_spacing_enabled = false
	_sim.local_avoidance_enabled = false
	_sim.bottleneck_reservation_enabled = false
	add_child(_sim)
	_view.set_external_terrain_object_visuals(_external_visual_owners)
	_view.configure_from_map(_data)
	var crew_places := [Vector2(10.7,8.9),Vector2(10.4,10.9),Vector2(15.1,9.5),Vector2(11.8,8.9)]
	for index in range(4):
		_add_citizen(["operator","pilot","mechanic","medic"][index],crew_places[index])
		_crew[index]["visual"].rotation_degrees.y = [-150.0,-95.0,140.0,-90.0][index]
	_build_ui()
	_set_buildings_closed(true)
	_camera_view("outpost")
	if _capture_mode:
		call_deferred("_capture_all")

func _make_terrain() -> void:
	for tile in _data.get_tiles():
		var p: Vector2 = HEX.axial_to_plane(Vector2(tile.grid_position))
		var corridor := absf(p.y-9.6)<0.9 or (p.distance_to(Vector2(6.0,10.4))<2.1)
		tile.surface_type = "road" if corridor else "ground"

func _reserve_footprints(footprints: Array, blocks_sight: bool = false, visual_owner: Node3D = null) -> void:
	# Authoritative fixture construction happens before registry registration.
	# The visual builders only return envelopes; they cannot mutate gameplay.
	for tile in _data.get_tiles():
		var p: Vector2 = HEX.axial_to_plane(Vector2(tile.grid_position))
		for footprint in footprints:
			if footprint.has_point(p):
				tile.walkable = false
				if blocks_sight:
					tile.blocks_los = true
					tile.object_height = 4
					if visual_owner != null:
						_external_visual_owners[tile.grid_position] = visual_owner
				break

func _add_continuous_backdrop_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "DistantGroundVisualOnly"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(120.0,100.0)
	ground.mesh = mesh
	# This flat fixture uses a continuous painted surface above the individual
	# cell caps. Hex facts, raised cells, picking and grid overlays remain intact.
	ground.position = Vector3(12.0,0.0015,6.0)
	ground.material_override = _profile.material_for(_profile.surface_color("ground"))
	_stage.add_child(ground)
	_view.set_flat_ground_visual_owner(ground)

func _add_structure(model: String, plane: Vector2, family: String = "structures") -> void:
	var path := ART_ROOT+family+"/"+model+".glb"
	if not ResourceLoader.exists(path):
		push_error("Missing approved frontier structure: "+path)
		return
	var visual: Node3D = load(path).instantiate()
	visual.name = model
	visual.scale = Vector3.ONE*MODEL_SCALE
	visual.position = Vector3(plane.x,0.0,plane.y)
	_stage.add_child(visual)
	var bounds: AABB = _combined_bounds(visual)
	_model_facts.append({"id":model,"path":path,"source_sha256":FileAccess.get_sha256(path),"bounds_world":str(bounds),"scale":MODEL_SCALE})
	if model in ["habitat_cutaway_01","freihafen_hall_01"]:
		var shell = CLOSED_BUILDING.new()
		shell.name = "ClosedExterior_"+model
		_stage.add_child(shell)
		shell.build(bounds,model=="freihafen_hall_01")
		_closed_shells.append(shell)
		_cutaway_buildings.append(visual)
	# This fixture reserves the visible footprint in authoritative terrain facts.
	for tile in _data.get_tiles():
		var p: Vector2 = HEX.axial_to_plane(Vector2(tile.grid_position))
		if p.x>bounds.position.x-0.3 and p.x<bounds.end.x+0.3 and p.y>bounds.position.z-0.3 and p.y<bounds.end.z+0.3:
			tile.walkable = false

func _combined_bounds(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.find_children("*","MeshInstance3D",true,false):
		var mesh := child as MeshInstance3D
		var current: AABB = mesh.global_transform * mesh.get_aabb()
		result = current if first else result.merge(current)
		first = false
	return result

func _add_ship(model: String, plane: Vector2, yaw: float) -> void:
	var path := ART_ROOT+"ships_pass04_r02/"+model+".glb"
	if not ResourceLoader.exists(path):
		push_error("Missing frontier ship candidate: "+path)
		return
	var visual: Node3D = load(path).instantiate()
	visual.name = model
	visual.scale = Vector3.ONE*SHIP_SCALE
	visual.position = Vector3(plane.x,PAD.DECK_HEIGHT,plane.y)
	visual.rotation_degrees.y = yaw
	_stage.add_child(visual)
	var bounds := _combined_bounds(visual)
	_model_facts.append({"id":model,"path":path,"source_sha256":FileAccess.get_sha256(path),"bounds_world":str(bounds),"bounds_min":[bounds.position.x,bounds.position.y,bounds.position.z],"bounds_size":[bounds.size.x,bounds.size.y,bounds.size.z],"scale":SHIP_SCALE,"yaw_degrees":yaw,"canonical_star_citizen_dimensions":false,"status":"new simplified static reference reconstruction"})

func _add_citizen(role: String, plane: Vector2) -> void:
	var path := ART_ROOT+"citizens_pass02/"+role+".glb"
	if not ResourceLoader.exists(path):
		push_error("Missing approved frontier citizen: "+path)
		return
	var actor = ACTOR.new()
	actor.name = role
	actor.unit_id = "frontier_"+role
	add_child(actor)
	var grid: Vector2i = HEX.round_axial(HEX.plane_to_axial(plane))
	actor.position = _registry.grid_to_world(grid)
	_units.register_unit(actor.unit_id,actor)
	var visual: Node3D = load(path).instantiate()
	visual.name = "Citizen_"+role
	visual.scale = Vector3.ONE*MODEL_SCALE
	_stage.add_child(visual)
	var players: Array = visual.find_children("*","AnimationPlayer",true,false)
	var player: AnimationPlayer = players[0] if not players.is_empty() else null
	var idle := _animation_name(player,"idle")
	var walk := _animation_name(player,"walk")
	if player != null and not idle.is_empty():
		player.play(idle)
	var entry := {"role":role,"actor":actor,"visual":visual,"player":player,"idle":idle,"walk":walk,"last_position":actor.position,"walking":false}
	_crew.append(entry)
	_model_facts.append({"id":role,"path":path,"source_sha256":FileAccess.get_sha256(path),"scale":MODEL_SCALE,"animations":player.get_animation_list() if player else PackedStringArray()})

func _animation_name(player: AnimationPlayer, suffix: String) -> String:
	if player == null:
		return ""
	for name in player.get_animation_list():
		if String(name).to_lower().ends_with(suffix):
			return name
	return ""

func _set_buildings_closed(closed: bool) -> void:
	_buildings_closed = closed
	for shell in _closed_shells:
		shell.visible = closed
	for building in _cutaway_buildings:
		building.visible = not closed

func _process(_delta: float) -> void:
	for entry in _crew:
		var actor: Node2D = entry["actor"]
		var visual: Node3D = entry["visual"]
		var previous: Vector3 = visual.position
		visual.position = _view.call("_world_to_surface_3d_position",actor.position,0.003)
		var moving: bool = actor.position.distance_squared_to(entry["last_position"])>0.00001
		var displacement: Vector3 = visual.position-previous
		if moving and displacement.length_squared()>0.00001:
			visual.rotation.y = atan2(displacement.x,displacement.z)
		var player: AnimationPlayer = entry["player"]
		if moving != entry["walking"] and player != null:
			var clip: String = entry["walk"] if moving else entry["idle"]
			if not clip.is_empty():
				player.play(clip,0.18)
		entry["walking"] = moving
		entry["last_position"] = actor.position
	if _view != null and not _crew.is_empty():
		_view.call("_request_viewport_redraw",true,250)

func _add_box(parent: Node3D, size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance

func _add_landing_pad(plane: Vector2, size: Vector2, designation: String) -> void:
	var pad = PAD.new()
	pad.name = "OutpostLandingPad_"+designation
	_stage.add_child(pad)
	var reservation: Rect2 = pad.build(plane,size,designation,-1.0 if designation=="02" else 1.0)
	_reserve_footprints([reservation])
	_pad_facts.append({"id":designation,"center":[plane.x,plane.y],"size":[size.x,size.y],"deck_height":PAD.DECK_HEIGHT,"reservation":str(reservation),"visual_only":true})

func _add_solar_array(plane: Vector2) -> void:
	var root := Node3D.new()
	root.name = "SolarArray"
	root.position = Vector3(plane.x,0.0,plane.y)
	_stage.add_child(root)
	for i in range(3):
		var x := float(i)*0.85-0.85
		_add_box(root,Vector3(0.07,0.4,0.07),Vector3(x,0.2,0.0),Color("505955"))
		var panel := _add_box(root,Vector3(0.78,0.04,0.95),Vector3(x,0.52,0.0),Color("244d63"))
		panel.rotation.x = deg_to_rad(-25.0)
		for z in [-0.40,0.0,0.40]:
			var crossbar := _add_box(panel,Vector3(0.75,0.008,0.012),Vector3(0.0,0.025,z),Color("9aa7a8"))
			crossbar.name = "PanelCellRow"
	for tile in _data.get_tiles():
		if HEX.axial_to_plane(Vector2(tile.grid_position)).distance_to(plane)<1.7:
			tile.walkable = false

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(22,18)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08,0.13,0.15,0.92)
	style.set_content_margin_all(12)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel",style)
	layer.add_child(panel)
	_status = Label.new()
	_status.text = "STERNENBÜRGERCHEN  /  HEX-BASIS\nGrafik- und Bewegungsprobe · kein Kampagnenstand\n1 Übersicht   2 Halle   3 Citizens   4 Gelände   5 Basis\n6 Außenposten   7 Cutlass   8 Buccaneer   9 Versorgung\n0 Arbeitsbereiche\nC Außenhülle / Schnitt   G Hexraster\nLeertaste Gehen   Mausrad Zoom"
	_status.add_theme_font_size_override("font_size",15)
	panel.add_child(_status)

func _camera_view(id: String, reset_zoom: bool = true) -> void:
	_current_view_id = id
	if reset_zoom:
		_preview_zoom_factor = 1.0
	var focus := Vector2(11.8,7.2)
	var size := 12.0
	var pitch := 50.0
	var yaw := 24.0
	var target_height := 0.2
	if id=="crew":
		focus = Vector2(12.15,9.4)
		size = 2.5
		pitch = 12.0
		yaw = 0.0
	elif id=="workshop":
		focus = Vector2(13.2,6.8)
		size = 4.2
		pitch = 42.0
	elif id=="landscape":
		focus = Vector2(12.0,5.6)
		size = 23.0
		pitch = 46.0
	elif id=="cutaway":
		focus = Vector2(8.3,6.2)
		size = 3.6
		pitch = 50.0
	elif id=="outpost":
		focus = Vector2(12.9,9.2)
		size = 18.0
		pitch = 50.0
	elif id in ["cutlass_front","cutlass_rear"]:
		focus = Vector2(6.5,10.9)
		size = 4.8
		pitch = 28.0
		yaw = 24.0 if id=="cutlass_front" else 204.0
		target_height = 0.65
	elif id in ["buccaneer_front","buccaneer_rear"]:
		focus = Vector2(19.2,11.8)
		size = 3.8
		pitch = 44.0 if id=="buccaneer_front" else 28.0
		yaw = -1.0 if id=="buccaneer_front" else 179.0
		target_height = 0.55
	elif id=="utility":
		focus = Vector2(16.1,8.2)
		size = 2.5
		pitch = 28.0
		target_height = 0.42
	elif id=="lived_outpost":
		focus = Vector2(11.7,7.8)
		size = 10.5
		pitch = 50.0
	elif id=="ground_detail":
		focus = Vector2(15.5,8.9)
		size = 4.8
		pitch = 58.0
	elif id=="geology_detail":
		focus = Vector2(20.1,2.5)
		size = 8.5
		pitch = 38.0
	size *= _preview_zoom_factor
	_view.set("_focus_grid_position",HEX.plane_to_axial(focus))
	_view.set("_camera_size",size)
	_view.set("_camera_pitch_degrees",pitch)
	_view.set("_camera_yaw_degrees",yaw)
	_view.call("_update_camera_transform")
	# The small art-preview shots use their own precise camera framing; the mission
	# camera policy and minimum heights remain unchanged.
	var camera: Camera3D = _view.get_node("ViewportContainer/SubViewport/WorldRoot/Camera3D")
	camera.far = 100.0
	var target := Vector3(focus.x,0.3 if id=="crew" else target_height,focus.y)
	var distance := 18.0
	var pitch_rad := deg_to_rad(pitch)
	var yaw_rad := deg_to_rad(yaw)
	camera.position = target + Vector3(sin(yaw_rad)*cos(pitch_rad),sin(pitch_rad),cos(yaw_rad)*cos(pitch_rad))*distance
	camera.look_at(target,Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _camera_view("overview")
			KEY_2: _camera_view("workshop")
			KEY_3: _camera_view("crew")
			KEY_4: _camera_view("landscape")
			KEY_5: _camera_view("cutaway")
			KEY_6: _camera_view("outpost")
			KEY_7: _camera_view("cutlass_front")
			KEY_8: _camera_view("buccaneer_front")
			KEY_9: _camera_view("utility")
			KEY_0: _camera_view("lived_outpost")
			KEY_C: _set_buildings_closed(not _buildings_closed)
			KEY_G:
				_view.set_hex_grid_visible(not bool(_view.get("_hex_grid_visible")))
				_camera_view(_current_view_id,false)
			KEY_SPACE: _walk_demo()
			KEY_ESCAPE: get_tree().quit()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP or event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			_preview_zoom_factor = clampf(_preview_zoom_factor * (0.9 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.1),0.45,2.8)
			_camera_view(_current_view_id,false)
		elif event.button_index==MOUSE_BUTTON_LEFT:
			var grid = _view.screen_to_grid_position(event.position)
			if grid != null: _view.set_selected_grid_positions([grid])

func _walk_demo() -> void:
	if _crew.is_empty():
		return
	var actor: Node2D = _crew[0]["actor"]
	var target_grid := HEX.round_axial(HEX.plane_to_axial(Vector2(15.0,10.8)))
	_sim.enqueue_command({"type":"move_to_position","unit_id":actor.unit_id,"target_position":_registry.grid_to_world(target_grid),"requeue_until_target":true,"local_avoidance_enabled":false})

func _capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output/grafik_20261101"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_ROOT))
	_view.call("_request_viewport_redraw",true,60000)
	for i in range(30): await get_tree().process_frame
	var captures: Array = []
	for id in ["overview","hex_grid","crew","workshop","landscape","cutaway","outpost","cutlass_front","cutlass_rear","buccaneer_front","buccaneer_rear","utility","closed_outpost","closed_habitat","closed_hall","lived_outpost","ground_detail","geology_detail","baseline"]:
		_view.set_frontier_art_enabled(id!="baseline")
		_view.set_hex_grid_visible(id=="hex_grid")
		_set_buildings_closed(String(id).begins_with("closed_") or id in ["lived_outpost","ground_detail","geology_detail"])
		_view.call("_request_viewport_redraw",true,60000)
		var camera_id: String = {"closed_outpost":"outpost","closed_habitat":"cutaway","closed_hall":"workshop"}.get(id,id)
		_camera_view("overview" if id in ["hex_grid","baseline"] else camera_id)
		for i in range(12): await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var path: String = CAPTURE_ROOT+String(id)+".png"
		var error := image.save_png(path)
		var camera: Camera3D = _view.get_node("ViewportContainer/SubViewport/WorldRoot/Camera3D")
		captures.append({"id":id,"path":path,"error":error,"camera_size":_view.get_camera_size(),"camera_transform":str(camera.global_transform),"camera_projection":camera.projection,"viewport_size":str(get_viewport().get_visible_rect().size),"profile_enabled":id!="baseline","building_shells_visible":_buildings_closed})
	_view.set_frontier_art_enabled(true)
	_camera_view("crew")
	_walk_demo()
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	var walk_error := get_viewport().get_texture().get_image().save_png(CAPTURE_ROOT+"walk_pose.png")
	captures.append({"id":"walk_pose","path":CAPTURE_ROOT+"walk_pose.png","error":walk_error,"camera_size":_view.get_camera_size(),"profile_enabled":true})
	var renderer: String = RenderingServer.get_current_rendering_method()+" / "+RenderingServer.get_current_rendering_driver_name()
	var sources := {}
	for source in ["res://scripts/tests/frontier_art_preview.gd","res://scripts/terrain/frontier_art_geology.gd","res://scripts/terrain/frontier_art_dressing.gd","res://scripts/terrain/frontier_art_profile.gd","res://scripts/terrain/frontier_outpost_pad.gd","res://scripts/terrain/frontier_closed_buildings.gd","res://scripts/terrain/frontier_worklife.gd","res://shaders/terrain/frontier_contact_paint.gdshader","res://shaders/terrain/frontier_ground.gdshader","res://shaders/terrain/frontier_building_wear.gdshader"]:
		sources[source] = FileAccess.get_sha256(source)
	var snapshot: Dictionary = _view.get_render_snapshot()
	var report := {"report_ready":false,"pass":"06_environment","report_revision":"env06","engine":Engine.get_version_info(),"renderer":renderer,"launch_arguments":OS.get_cmdline_args(),"synthetic_fixture":true,"active_campaign_integration":false,"grid_topology":_data.get_grid_topology(),"tile_count":_data.get_tiles().size(),"actors":_crew.size(),"models":_model_facts,"worklife_sources":_worklife.source_facts,"use_groups":_worklife.use_groups,"contact_gravel_count":_worklife.gravel_count,"pads":_pad_facts,"captures":captures,"structure_and_citizen_scale":MODEL_SCALE,"stylized_ship_scale":SHIP_SCALE,"canonical_star_citizen_dimensions":false,"movement_authority":"SimulationRoot","unit_spacing_enabled":false,"local_avoidance_enabled":false,"light":_view.call("_build_editor_light_snapshot"),"runtime_sources_sha256":sources,"missing_asset_mapping_count":snapshot.get("missing_asset_mapping_count",-1),"flat_hex_cap_count":snapshot.get("ground_multimesh_tile_count",-1),"comparison_note":"Twelve fixed environment cameras, resolution, renderer, global light and crew placement preserved from pass05. Geology erosion and bounded blocked-area foot relief revised; painterly soil, rock, paving and building wear revised. All primary GLBs unchanged, ships stay under separate Astra revision. Hex height/navigation/picking facts remain authoritative and unchanged."}
	var report_file := FileAccess.open("res://output/grafik_20261101/pass06_environment_after_capture.json",FileAccess.WRITE)
	if report_file == null:
		push_error("Cannot write frontier engine capture report")
		get_tree().quit(1)
		return
	report_file.store_string(JSON.stringify(report,"  "))
	print("FRONTIER_ENGINE_CAPTURE ",JSON.stringify(report))
	get_tree().quit()
