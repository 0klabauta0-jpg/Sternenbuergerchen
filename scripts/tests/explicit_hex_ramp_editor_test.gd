extends SceneTree
const EDITOR=preload("res://scenes/editor/map_editor.tscn")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const BUILDING=preload("res://scripts/editor/building_layout_authoring.gd")
var passed:=0
var failed:=0
func _init() -> void: call_deferred("run")
func check(ok:bool,label:String)->void:
	passed+=int(ok);failed+=int(not ok);print("PASS: " if ok else "FAIL: ",label)
func run()->void:
	var folder="res://output/native_glut_maps/explicit_ramp_editor/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var map=MAP.create_empty("Editor ramp fixture",Vector2i(16,16),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.get("_extension_metadata")["terrain_height_rules"]=TILE.EXPLICIT_HEIGHT_RULES
	map.get("_extension_metadata")["regional_terrain_version"]=2
	map.get("_extension_metadata")["regional_height_step"]=0.75
	map.save_to_file(folder+"explicit.json")
	var editor=EDITOR.instantiate();editor.set("map_file_path",folder+"explicit.json");root.add_child(editor)
	await process_frame
	map=editor.get("_terrain_map_data")
	var controls=editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/ExplicitRampControls")
	check(controls!=null and controls.visible,"Explicit map exposes plateau/ramp controls")
	check(controls.get_node("Direction").item_count==6,"Editor offers all six upward directions")
	var a=map.get_tile_at_grid(Vector2i(6,6));var b=map.get_tile_at_grid(Vector2i(7,6))
	var selected:Array[Vector2i]=[a.grid_position,b.grid_position]
	editor.set("_selected_grids",selected);editor.set("_selected_grid_position",a.grid_position)
	controls.get_node("Shape").select(1);controls.get_node("Shape").emit_signal("item_selected",1)
	controls.get_node("Direction").select(2);controls.get_node("Direction").emit_signal("item_selected",2)
	editor.get_node("UI/PropertyPanel/Margin/VBox/HeightRow/HeightSpinBox").set_value_no_signal(2)
	controls.get_node("Apply").emit_signal("pressed")
	check(a.height_level==2 and b.height_level==2 and a.ramp_direction==2 and b.ramp_direction==2,"Visible Apply changes entire selection through one patch transaction")
	check(editor.call("get_undo_debug_snapshot").undo_depth==1,"Selected ramp band is one undo step")
	check(editor.get("_terrain_registry").get_revision()>256,"Editor owner notifies terrain revision after shape edits")
	var object_rotation:float=a.object_rotation_degrees
	controls.find_child("RotateRight",true,false).emit_signal("pressed")
	check(a.ramp_direction==3 and b.ramp_direction==3 and a.height_level==2,"Selection rotation changes direction and preserves lower height")
	check(a.object_rotation_degrees==object_rotation,"Terrain rotation never changes object yaw")
	editor.call("_undo_last_change")
	check(a.ramp_direction==2 and b.ramp_direction==2 and a.explicit_hex_ramps and a.regional_grade,"Undo preserves rule flags and restores direction")
	editor.call("_redo_explicit_terrain_change")
	check(a.ramp_direction==3 and b.ramp_direction==3,"Redo reapplies the same selected band")
	check(editor.get("_selected_grids").size()==2,"Undo and redo retain the selected band")
	editor.call("_apply_tile_patch",a,{"height_level":8})
	check(a.height_level==7 and a.ramp_direction==3,"Height edit retains direction and clamps lower ramp height to7")
	check(editor.call("_reconcile_height_edges_around",a.grid_position,"cliff").is_empty(),"Legacy hill reconciliation does not rewrite explicit ramp terrain")
	check(BUILDING.fields(a).ramp_direction==3 and BUILDING.fields(a).explicit_hex_ramps,"Building substrate snapshot keeps ramp fields")
	var fields=BUILDING.fields(a);a.ramp_direction=-1;BUILDING.set_fields(a,fields)
	check(a.ramp_direction==3,"Building substrate restoration conserves ramp direction")
	var footprint=BUILDING.footprint(map,{"asset_id":"frontier_habitat_exterior","center":[6.0+3.0,6.0*sqrt(3.0)*0.5],"scale":1.0,"rotation_degrees":0.0})
	for cell in footprint:
		var tile=map.get_tile_at_grid(Vector2i(cell[0],cell[1]))
		if tile!=null:tile.height_level=7
	var placement:Dictionary=BUILDING.plan(map,"place",{"asset_id":"frontier_habitat_exterior","grid":a.grid_position,"scale":1.0})
	check(not placement.ok and String(placement.error).contains("Rampe"),"Building placement rejects ramp substrate")
	editor.get_node("UI/TopBar/Margin/HBox/BrushSizeOptionButton").select(1)
	editor.set("_height_tool_mode","set_3");editor.set("_ramp_brush_enabled",true);editor.set("_ramp_brush_shape_chosen",true);editor.set("_ramp_brush_direction",0)
	var center=map.get_tile_at_grid(Vector2i(11,11))
	editor.call("_apply_height_tool_at_world_position",center.world_position)
	var ramp_count:=0
	for tile in map.get_tiles():
		if tile.ramp_direction==0 and tile.height_level==3:ramp_count+=1
	check(ramp_count==7,"Wide height brush paints exactly the seven-cell hex footprint")
	check(not map.get_tile_at_grid(Vector2i(12,12)).ramp_direction>=0,"Hex brush excludes square-only corner cell")
	map.save_to_file(folder+"saved.json")
	var restored=MAP.load_from_file(folder+"saved.json")
	check(restored.get_tile_at_grid(a.grid_position).ramp_direction==3,"Editor-authored direction survives real map save/reload")
	var legacy=MAP.create_empty("Legacy editor",Vector2i(6,6),Vector2.ZERO,64,32,3,"hex_axial_v1");legacy.save_to_file(folder+"legacy.json")
	editor.call("_load_map",folder+"legacy.json")
	check(not editor.call("_uses_explicit_hex_terrain") and not controls.visible,"Legacy map is not silently migrated and hides new controls")
	editor.queue_free();await process_frame
	print("EXPLICIT_HEX_RAMP_EDITOR ",passed," passed, ",failed," failed")
	quit(0 if failed==0 else 1)
