extends SceneTree
const VIEW=preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX=preload("res://scripts/terrain/hex_grid.gd")
const PROJECTION=preload("res://scripts/terrain/hex_surface_grid_projection.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const ROOT=preload("res://scripts/core/simulation_root.gd")
const PLANNER=preload("res://scripts/tactical/bottleneck_reservation_resolver.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
var passed:=0
var failed:=0
func _initialize()->void:call_deferred("run")
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failed+=1
	print(("PASS " if value else "FAIL ")+label)

func run()->void:
	for direction in range(6):
		var ramp=TILE.new({"grid_position":Vector2i.ZERO,"height_level":2,"explicit_hex_ramps":true,"ramp_direction":direction,"walkable":true})
		var ring:PackedVector3Array=PROJECTION.outline(ramp,{Vector2i.ZERO:ramp},1.0,0.5,0.0,0.012)
		var axis:Vector2=HEX.axial_to_plane(Vector2(HEX.DIRECTIONS[direction])).normalized()
		var highest:float=-INF;var lowest:float=INF
		for point in ring:
			highest=maxf(highest,point.y);lowest=minf(lowest,point.y)
			check(is_equal_approx(point.y,1.262+clampf(Vector2(point.x,point.z).dot(axis),-0.5,0.5)*0.5),"ramp corner/midpoint follows actual slope "+str(direction))
		check(is_equal_approx(highest,1.512) and is_equal_approx(lowest,1.012),"ramp connects H2 to H3 "+str(direction))
	var view=VIEW.new()
	var finish_source:=StandardMaterial3D.new()
	var palette:=Image.create(2,1,false,Image.FORMAT_RGBA8);palette.set_pixel(0,0,Color.BLACK);palette.set_pixel(1,0,Color.WHITE)
	finish_source.albedo_texture=ImageTexture.create_from_image(palette)
	var adapter=view.get("_hex_floor_adapter")
	var palette_finish:StandardMaterial3D=adapter.finish_material(finish_source)
	var quiet_image:Image=palette_finish.albedo_texture.get_image()
	check(absf(quiet_image.get_pixel(1,0).get_luminance()-quiet_image.get_pixel(0,0).get_luminance())<0.14,"derived floor palette suppresses internal ring contrast")
	check(finish_source.albedo_texture.get_image().get_pixel(0,0)==Color.BLACK and finish_source.albedo_texture.get_image().get_pixel(1,0)==Color.WHITE,"quiet palette never mutates source texture")
	check(adapter.finish_material(finish_source)==palette_finish and adapter._texture_cache.size()==1,"floor material and palette are cached across identical instances")
	var models:=Node3D.new();view.add_child(models);view.set("_map_root",models);view.set("_active_grid_topology","hex_axial_v1")
	for kind:String in ["station_set_floor_panel","station_set_floor_panel_end","station_set_balcony_floor_center","modular_floor","factory_floor"]:
		for rotation:float in [0.0,90.0]:
			var tile=TILE.new({"type_id":kind,"grid_position":Vector2i.ZERO,"object_rotation_degrees":rotation,"walkable":true})
			var scene:PackedScene=view.call("_get_asset_model_scene",kind)
			check(scene!=null,"actual floor model available "+kind)
			if scene==null:continue
			var source:Node3D=scene.instantiate();view.call("_normalize_asset_model_instance",source)
			var source_meshes:Array=[];collect(source,Transform3D.IDENTITY,source_meshes)
			var source_min:=INF;var source_max:=-INF
			for entry:Dictionary in source_meshes:
				for surface in range(entry.mesh.get_surface_count()):
					for point:Vector3 in entry.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
						var height:float=(entry.transform*point).y;source_min=minf(source_min,height);source_max=maxf(source_max,height)
			var source_is_plane:bool=source_max-source_min<0.00001
			var source_surfaces:=0;var originals:Array=[]
			for entry:Dictionary in source_meshes:
				source_surfaces+=entry.mesh.get_surface_count()
				for surface in range(entry.mesh.get_surface_count()):
					var material:Material=entry.node.get_active_material(surface)
					if material is StandardMaterial3D:originals.append({"material":material,"color":material.albedo_color,"texture":material.albedo_texture})
			check(view.call("_add_asset_model_visual",tile,0.0,kind,true),"actual floor route adapts "+kind)
			var model:Node3D=models.get_child(models.get_child_count()-1)
			var entries:Array=[];collect(model,Transform3D.IDENTITY,entries)
			var inside:=true;var seen:Dictionary={};var surfaces:=0;var uv_preserved:=true;var muted:=true
			var actual_min_y:=INF;var actual_max_y:=-INF
			for entry:Dictionary in entries:
				surfaces+=entry.mesh.get_surface_count()
				for surface in range(entry.mesh.get_surface_count()):
					var finish:StandardMaterial3D=entry.node.get_active_material(surface) as StandardMaterial3D
					muted=muted and finish!=null and maxf(finish.albedo_color.r,maxf(finish.albedo_color.g,finish.albedo_color.b))<0.85 and finish.albedo_color.get_luminance()>0.35 and finish.roughness>=0.85
					var arrays:Array=entry.mesh.surface_get_arrays(surface)
					var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
					uv_preserved=uv_preserved and arrays[Mesh.ARRAY_TEX_UV]!=null and arrays[Mesh.ARRAY_TEX_UV].size()==vertices.size()
					for vertex in vertices:
						var point:Vector3=entry.transform*vertex
						actual_min_y=minf(actual_min_y,point.y);actual_max_y=maxf(actual_max_y,point.y)
						for edge in range(6):inside=inside and Vector2(point.x,point.z).dot(Vector2.from_angle(edge*PI/3.0))<=0.50001
						for corner in range(6):
							if Vector2(point.x,point.z).distance_to(HEX.corners()[corner]*0.995)<0.0001:seen[corner]=true
			check(inside and seen.size()==6,"floor stays inside assigned Hex and reaches all six corners "+kind+str(rotation))
			check(surfaces==source_surfaces and uv_preserved,"original floor material surfaces and UVs survive "+kind)
			var bounds:Dictionary=view.call("_get_local_visual_bounds",model)
			var span:float=actual_max_y-actual_min_y
			check(span<=0.03 and (is_zero_approx(span) if source_is_plane else span>0.0),"thin floor preserves original plane/volume kind "+kind)
			check(Vector3(bounds.min).y<=actual_min_y+0.00001 and Vector3(bounds.max).y>=actual_max_y-0.00001,"conservative culling box encloses actual floor geometry "+kind)
			check(muted,"floor finish stays light with muted rough metal accents "+kind)
			var original_unchanged:=true
			for material:Dictionary in originals:original_unchanged=original_unchanged and material.material.albedo_color==material.color and material.material.albedo_texture==material.texture
			check(original_unchanged,"source materials/textures remain unchanged for other assets "+kind)
			var thin_casters_off := true
			var source_casters_preserved := true
			for entry: Dictionary in entries: thin_casters_off = thin_casters_off and entry.node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for entry: Dictionary in source_meshes: source_casters_preserved = source_casters_preserved and entry.node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			check(thin_casters_off and source_casters_preserved, "derived thin floor avoids self-shadow while original model casting is untouched " + kind)
			var builds:int=view.get("_hex_floor_adapter").build_count
			var material_builds:int=view.get("_hex_floor_adapter").material_build_count
			view.call("_add_asset_model_visual",tile,0.0,kind,true)
			check(view.get("_hex_floor_adapter").build_count==builds,"identical floor instance reuses projected mesh "+kind)
			check(view.get("_hex_floor_adapter").material_build_count==material_builds,"identical floor instance reuses immutable material copy "+kind)
			var lift:float=view.call("_hex_grid_model_support_lift",tile)
			check(lift+0.012>=actual_max_y,"contour clears actual floor top "+kind)
			check(is_equal_approx(lift,actual_max_y),"actual thin floor top and Actor support agree without legacy thick-slab offset %s [lift=%f top=%f]"%[kind,lift,actual_max_y])
			model.free();models.get_child(models.get_child_count()-1).free();source.free()
	for kind:String in ["station_set_chair_armrest","frontier_utility_fuel_01","fahrzeug_speeder","station_set_wall"]:
		check(not view.HEX_FLOOR_ADAPTER.supports(kind),"floor adaptation excludes furniture/walls/vehicles "+kind)
	var flat=TILE.new({"tile_id":"0,0","grid_position":Vector2i.ZERO,"height_level":3,"walkable":true})
	var blocked=TILE.new({"tile_id":"1,0","grid_position":Vector2i(1,0),"walkable":false})
	view.call("_rebuild_render_tile_index",[flat,blocked])
	var registry=REGISTRY.new();registry.configure_iso_grid(Vector2.ZERO,64.0,32.0,"hex_axial_v1");registry.register_tile(flat);registry.register_tile(blocked)
	view.call("set_runtime_terrain_registry",registry)
	view.call("_add_hex_grid_lines",[flat,blocked]);view.call("_refresh_hex_grid_projection_if_needed")
	var grid_node:MeshInstance3D=models.get_node("TileGridLines3D")
	var initial_mesh:Mesh=grid_node.mesh
	check(view.get("_hex_grid_parents")[models.get_instance_id()].line_count==12,"blocked neighbor never receives usable grid")
	var builds:int=view.get("_hex_grid_projection_build_count")
	for index in range(1000):view.call("_refresh_hex_grid_projection_if_needed")
	check(view.get("_hex_grid_projection_build_count")==builds and grid_node.mesh==initial_mesh,"1000 unchanged frames retain exact cached mesh/node")
	registry.set_runtime_tile_overrides([{"grid_position":Vector2i.ZERO,"walkable_override":false}])
	view.call("_refresh_hex_grid_projection_if_needed")
	check(models.get_node("TileGridLines3D")==grid_node and grid_node.mesh.get_surface_count()==0,"runtime blocking removes contour without replacing node")
	check(flat.walkable,"visual projection never mutates raw terrain truth")
	registry.clear_runtime_tile_overrides();view.call("_refresh_hex_grid_projection_if_needed")
	view.set("_fog_of_war_mode","player");view.set("_fow_visible_tile_grids",{});view.set("_hex_grid_all_dirty",true);view.call("_refresh_hex_grid_projection_if_needed")
	check(grid_node.mesh.get_surface_count()==0,"unknown/invisible cells receive no elevated grid")
	view.set("_fow_visible_tile_grids",{Vector2i.ZERO:true});view.call("_mark_hex_grid_cell_dirty",Vector2i.ZERO);view.call("_refresh_hex_grid_projection_if_needed")
	check(view.get("_hex_grid_parents")[models.get_instance_id()].line_count==12,"visible legal surface restores its contour")
	_test_motion_support(view)
	_test_painted_pad(view)
	view.free();registry.free()
	_test_revision_gap()
	print("REVIEW_HEX_SURFACE passed=%d failed=%d"%[passed,failed]);quit(1 if failed else 0)

func collect(node:Node,parent:Transform3D,result:Array)->void:
	var transform:Transform3D=parent*node.transform if node is Node3D else parent
	if node is MeshInstance3D and node.mesh!=null:result.append({"mesh":node.mesh,"transform":transform,"node":node})
	for child in node.get_children():collect(child,transform,result)

func _test_motion_support(view:Node)->void:
	var map=MAP.create_empty("surface-motion",Vector2i(4,3),Vector2.ZERO,64.0,32.0,3,"hex_axial_v1")
	map.get_tile_at_grid(Vector2i(2,1)).type_id="station_set_floor_panel"
	view.set("_terrain_map_data",map);view.call("_rebuild_render_tile_index",map.get_tiles())
	var registry=REGISTRY.new();registry.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for tile in map.get_tiles():registry.register_tile(tile)
	var owner=ROOT.new()
	# Private owner fixture: real Ground admission/plan/ticks and real Root
	# publication, without unrelated mission UI or a second scheduler.
	var ground=owner.get("_hex_ground_runtime")
	ground.configure(registry,"surface-motion",0)
	owner.set("_hex_ground_enabled",true);owner.set("_hex_ground_registry",registry)
	var actor=load("res://scripts/npc/test_unit.gd").new();actor.unit_id="surface_actor";actor.team_id="team_alpha"
	root.add_child(actor);actor.set_process(false);actor.set_physics_process(false)
	owner.set("_known_units_by_id",{"surface_actor":actor});owner.set("_hex_visual_unit_ids",{"surface_actor":true})
	var placement:Array[Dictionary]=[{"unit_id":"surface_actor","grid":Vector2i(1,1)}]
	check(ground.admit_units(placement).ok,"actual Ground admits support actor")
	var snapshot:Dictionary=ground.build_planning_snapshot()
	var plan:Dictionary=PLANNER.build_hex_plan([{"unit_id":"surface_actor","command_id":"surface-step","priority":0,"path_grid_points":[Vector2i(1,1),Vector2i(2,1)],"duration_ticks_by_step":[6]}],snapshot,registry)
	check(plan.ok and ground.commit_plan(plan,snapshot.revision).ok,"actual Ground commits step onto real Kenney floor")
	var lift:float=view.call("_hex_grid_model_support_lift",map.get_tile_at_grid(Vector2i(2,1)))
	check(lift>0.0,"actual imported floor has positive visual support")
	for tick in [2,3,4]:
		ground.advance_tick(tick);owner.set("tick_counter",tick)
		var before:PackedByteArray=var_to_bytes([ground.export_state(),owner.export_gameplay_rng_state(),owner.tick_counter])
		for read in range(25):owner.call("_project_hex_ground_actors",0.25);view.call("_get_hex_unit_motion_visual",actor)
		var motion:Dictionary=view.call("_get_hex_unit_motion_visual",actor)
		check(is_equal_approx(motion.position.y,0.06+lift*(tick+0.25)/6.0),"floor support follows actual segment before/after handoff "+str(tick))
		check(var_to_bytes([ground.export_state(),owner.export_gameplay_rng_state(),owner.tick_counter])==before,"visual reads preserve Ground/owner/RNG stamp "+str(tick))
	check(ground.stop_units(PackedStringArray(["surface_actor"]),"fixture_stop").ok,"actual stop begins Ground centering")
	owner.call("_project_hex_ground_actors",0.0)
	var stop_pose:Dictionary=view.call("_get_hex_unit_motion_visual",actor)
	check(is_equal_approx(stop_pose.position.y,0.06+lift*4.0/6.0),"stop/recentering preserves continuous support start")
	ground.advance_tick(5);owner.set("tick_counter",5);owner.call("_project_hex_ground_actors",0.0)
	check(is_equal_approx(view.call("_get_hex_unit_motion_visual",actor).position.y,0.06+lift*5.0/6.0),"centering interpolates support to occupied destination")
	ground.advance_tick(6);owner.set("tick_counter",6);owner.call("_project_hex_ground_actors",0.0)
	check(is_equal_approx(view.call("_get_hex_unit_motion_visual",actor).position.y,0.06+lift),"stationary actual actor stands above imported floor")
	check(is_equal_approx(view.call("_get_world_surface_y",actor.global_position),lift) and is_equal_approx(float(actor.get_meta("hex_ground_stand_height_logical")),0.0),"selection and actor share visual support without changing logical height")
	var checkpoint_with_projection:Dictionary=actor.export_mission_actor_checkpoint()
	check(checkpoint_with_projection.get("schema")=="mission_actor_checkpoint.v1","actual actor checkpoint remains exportable with support projection")
	owner.call("_clear_hex_actor_metadata","surface_actor")
	check(not actor.has_meta("hex_ground_surface_segment"),"lifecycle cleanup removes support receipt")
	check(var_to_bytes(checkpoint_with_projection)==var_to_bytes(actor.export_mission_actor_checkpoint()),"fluent support metadata is excluded from actual actor checkpoint schema")
	actor.free();owner.free();registry.free()

func _test_revision_gap()->void:
	var view=VIEW.new();view.set("_active_grid_topology","hex_axial_v1")
	var a=TILE.new({"tile_id":"0,0","grid_position":Vector2i.ZERO,"walkable":true})
	var b=TILE.new({"tile_id":"16,0","grid_position":Vector2i(16,0),"walkable":true})
	view.call("_rebuild_render_tile_index",[a,b]);view.set("_regional_tiles_by_chunk",{Vector2i.ZERO:[a],Vector2i(2,0):[b]})
	var registry=REGISTRY.new();registry.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1");registry.register_tile(a);registry.register_tile(b)
	view.call("set_runtime_terrain_registry",registry)
	var parents:Array=[]
	for tile in [a,b]:
		var parent:=Node3D.new();view.add_child(parent);view.set("_map_root",parent);view.call("_add_hex_grid_lines",[tile]);parents.append(parent)
	view.call("_refresh_hex_grid_projection_if_needed");registry.clear_dirty_grid_positions()
	var builds:int=view.get("_hex_grid_projection_build_count")
	a.walkable=false;registry.notify_tile_data_changed([a.grid_position]);registry.clear_dirty_grid_positions()
	b.walkable=false;registry.notify_tile_data_changed([b.grid_position])
	view.call("_refresh_hex_grid_projection_if_needed")
	check(parents[0].get_node("TileGridLines3D").mesh.get_surface_count()==0 and parents[1].get_node("TileGridLines3D").mesh.get_surface_count()==0,"skipped registry revision reconciles both distant chunks after HPA consumed first dirty list")
	check(view.get("_hex_grid_projection_build_count")==builds+2,"revision gap rebuilds exactly changed chunks")
	registry.notify_tile_data_changed([a.grid_position]);view.call("_refresh_hex_grid_projection_if_needed")
	check(view.get("_hex_grid_projection_build_count")==builds+2,"unchanged projected facts skip duplicate mesh rebuild after registry notification")
	view.free();registry.free()

func _test_painted_pad(view:Node)->void:
	# Grafikpass R2 (Nutzerentscheidung 14.11.2026): Landepads sind wieder
	# niedrige erhoehte Objekte statt Bodenfarbe. Die frueheren Erwartungen an
	# die flache Bemalung sind ersetzt. Unveraendert bleibt: keine Terrainhoehe.
	var container:=Node3D.new();view.add_child(container)
	var place=preload("res://scripts/terrain/place_reference_dressing.gd")
	var spec:={"center":[0,0],"size":[5.5,4.2],"name":"PAD"}
	var dressing:Dictionary=place.build(container,{"pads":[spec]})
	view.set("_place_dressing_root",dressing.root)
	view.call("_configure_visual_deck_lift",[spec])
	var bounds:Dictionary=view.call("_get_local_visual_bounds",dressing.root)
	var tile=TILE.new({"tile_id":"0,0","grid_position":Vector2i.ZERO,"height_level":0,"walkable":true})
	var points:PackedVector3Array=view.call("_hex_grid_outline_cached",tile,{})
	var clear:=bool(bounds.valid)
	for point in points:clear=clear and point.y>Vector3(bounds.max).y
	check(clear,"raised pad deck stays below the lifted depth-tested hex contour")
	check(is_equal_approx(float(view.call("_hex_grid_model_support_lift",tile)),place.PAD_DECK_TOP) and TILE.stand_height(tile)==0.0,"raised deck lifts only the visual standing height; terrain height stays zero")
	var outside=TILE.new({"tile_id":"9,9","grid_position":Vector2i(9,9),"height_level":0,"walkable":true})
	check(is_zero_approx(float(view.call("_hex_grid_model_support_lift",outside))),"cells beside the deck keep ground standing height")
	var deck_casts:=false
	var inlays_off:=true
	var inset_retained:=false
	for pad in dressing.root.get_children():
		for child in pad.get_children():
			if child is MeshInstance3D:
				if String(child.name)=="ChamferedDeck":deck_casts=deck_casts or child.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				else:inlays_off=inlays_off and child.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if String(child.name)=="InsetDeck":inset_retained=child.visible
	check(deck_casts and inlays_off and inset_retained,"only the solid deck bodies cast; thin inlays stay non-casting and the inset is retained")
	view.call("_configure_visual_deck_lift",[])
	var standalone=preload("res://scripts/terrain/frontier_outpost_pad.gd").new();container.add_child(standalone);standalone.build(Vector2.ZERO,Vector2(5.5,4.2),"RAISED")
	check(standalone.get_node("InsetDeck").cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"unflattened standalone pad caster route remains unchanged")
	container.free();view.set("_place_dressing_root",null)
