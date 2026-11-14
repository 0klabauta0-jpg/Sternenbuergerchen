extends SceneTree
const EDITOR = preload("res://scenes/editor/map_editor.tscn")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const PREVIEW = preload("res://scripts/editor/map_editor_height_preview.gd")
var failed := 0
class ProbeView extends Node3D:
	func _get_3d_cell_size() -> float: return 2.0
	func _get_3d_height_step() -> float: return .75
	func _grid_to_3d_position(grid: Vector2, height: float) -> Vector3:
		return Vector3((grid.x+grid.y*.5)*2.0,height,grid.y*sqrt(3.0))
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	failed += int(not ok)
	print("HEIGHT_PREVIEW ", label, ": ", "PASS" if ok else "FAIL")
func run() -> void:
	var folder := "res://output/native_glut_maps/height_preview/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var map = MAP.create_empty("Preview fixture",Vector2i(16,16),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.get("_extension_metadata")["terrain_height_rules"] = TILE.EXPLICIT_HEIGHT_RULES
	map.get("_extension_metadata")["regional_terrain_version"] = 2
	map.get("_extension_metadata")["regional_height_step"] = .75
	map.save_to_file(folder+"map.json")
	var editor = EDITOR.instantiate()
	editor.set("map_file_path",folder+"map.json")
	root.add_child(editor)
	await process_frame
	map = editor.get("_terrain_map_data")
	var center := Vector2i(6,6)
	var registry: Node = editor.get("_terrain_registry")
	var revision: int = registry.get_revision()
	var plan := PREVIEW.plan(map,center,1,"raise","cliff",true,true,2)
	check(plan.footprint.size()==7 and plan.tiles[center].height_level==1 and plan.tiles[center].ramp_direction==2,"seven_hex_planned_ramp")
	check(map.get_tile_at_grid(center).height_level==0 and registry.get_revision()==revision,"planning_has_no_owner_mutation")
	var overlay = PREVIEW.new()
	var view := ProbeView.new()
	root.add_child(view)
	view.add_child(overlay)
	overlay.show_plan(view,plan)
	overlay.show_plan(view,plan)
	check(overlay.rebuild_count==1 and overlay.get_child_count()==2,"cached_caps_outline_and_up_arrow")
	check(overlay.get_node("PlannedCaps").mesh.get_aabb().position.y>.75,"view_height_scale_used")
	var source = map.get_tile_at_grid(center)
	source.ramp_direction=4;source.height_level=TILE.MAX_HEIGHT_LEVEL-1
	var retained := PREVIEW.plan(map,center,0,"raise","cliff",false,false,0)
	check(retained.tiles[center].ramp_direction==4 and retained.tiles[center].height_level==TILE.MAX_HEIGHT_LEVEL-1,"direction_retained_and_ramp_max_guard")
	var flat := PREVIEW.plan(map,center,0,"set_8","cliff",true,false,0)
	check(flat.tiles[center].height_level==8 and flat.tiles[center].ramp_direction==-1,"plateau_exact_h8")
	var full := PREVIEW.plan(map,center,0,"set_16","cliff",true,false,0)
	check(full.tiles[center].height_level==16 and full.tiles[center].ramp_direction==-1,"plateau_exact_h16")
	source.ramp_direction=-1;source.height_level=0
	editor.get_node("UI/TopBar/Margin/HBox/BrushSizeOptionButton").select(1)
	editor.set("_height_tool_mode","raise")
	editor.set("_ramp_brush_shape_chosen",true)
	editor.set("_ramp_brush_enabled",true)
	editor.set("_ramp_brush_direction",0)
	editor.call("begin_undo_transaction","height_stroke")
	editor.call("_apply_height_tool_at_world_position",map.get_tile_at_grid(center).world_position)
	editor.call("_apply_height_tool_at_world_position",map.get_tile_at_grid(center+Vector2i(1,0)).world_position)
	check(source.height_level==1 and source.ramp_direction==0,"overlap_two_centers_raise_once")
	var visited: Dictionary = editor.get("_height_stroke_visited")
	var current := PREVIEW.plan(map,center,1,"raise","cliff",true,true,0,Callable(),visited)
	check(current.tiles[center].height_level==1,"visited_preview_announces_no_extra_raise")
	editor.set("_height_tool_enabled",true)
	editor.set("_is_painting",true)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	editor.call("_input",release)
	check(Dictionary(editor.get("_height_stroke_visited")).is_empty() and not editor.get("_is_painting"),"pre_gui_release_commits_and_resets_visited")
	editor.call("_undo_last_change")
	check(source.height_level==0 and source.ramp_direction==-1,"single_undo_restores_entire_overlap_stroke")
	editor.call("_redo_explicit_terrain_change")
	check(source.height_level==1 and source.ramp_direction==0,"redo_restores_same_stroke")
	var actual_view: Node = editor.call("_get_primary_3d_view")
	var camera: Camera3D = actual_view.get("_camera")
	var step: float = actual_view.call("_get_3d_height_step")
	var size: float = actual_view.call("_get_3d_cell_size")
	var cap_center: Vector3 = actual_view.call("_grid_to_3d_position",Vector2(center),TILE.stand_height(source)*step)
	camera.position = cap_center + Vector3(4,4,4)
	camera.look_at(cap_center)
	var profile: PackedFloat32Array = load("res://scripts/terrain/regional_hex_surface.gd").profile(source,current.tiles)
	var ring: Vector2 = load("res://scripts/terrain/regional_hex_surface.gd").ring[7]
	var sample := cap_center + Vector3(ring.x*size*.98,profile[7]*step*.98,ring.y*size*.98)
	check(actual_view.call("_pick_regional_surface",source,profile,camera.unproject_position(sample)),"real_camera_ray_hits_visible_ramp_cap")
	editor.queue_free()
	view.queue_free()
	await process_frame
	print("HEIGHT_PREVIEW failures=",failed)
	quit(0 if failed==0 else 1)
