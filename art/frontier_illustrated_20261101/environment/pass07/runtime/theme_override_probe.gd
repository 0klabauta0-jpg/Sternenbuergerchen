extends SceneTree
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool,label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		print("FAIL: ",label)

func active_lighting(view) -> Dictionary:
	var environment: Environment = view.get("_environment").environment
	var light = view.get_node("ViewportContainer/SubViewport/WorldRoot/SunLight3D")
	return {"bg":environment.background_color,"ambient_color":environment.ambient_light_color,"ambient":environment.ambient_light_energy,"tonemap":environment.tonemap_mode,"exposure":environment.tonemap_exposure,"ssao":environment.ssao_enabled,"brightness":environment.adjustment_brightness,"contrast":environment.adjustment_contrast,"saturation":environment.adjustment_saturation,"light_color":light.light_color,"energy":light.light_energy,"rotation":light.rotation_degrees,"shadow_opacity":light.shadow_opacity,"shadow_blur":light.shadow_blur,"normal_bias":light.shadow_normal_bias,"bias":light.shadow_bias,"shadow_distance":light.directional_shadow_max_distance}

func run() -> void:
	var plain = MAP.create_empty("plain",Vector2i(3,3),Vector2.ZERO)
	var themed = MAP.create_empty("themed_square",Vector2i(3,3),Vector2.ZERO)
	themed.set_terrain_visual_theme_id("frontier_illustrated_v1")
	var hex_plain = MAP.create_empty("hex_plain",Vector2i(3,3),Vector2.ZERO,64,32,3,"hex_axial_v1")
	var view = VIEW.new()
	root.add_child(view)
	view.configure_from_map(plain)
	var baseline := active_lighting(view)
	view.configure_from_map(themed)
	check(bool(view.get_render_snapshot()["frontier_art_enabled"]) and view.get_render_snapshot()["grid_topology"]=="square8","theme does not silently change square map topology")
	check(active_lighting(view)!=baseline,"theme selection actually changes light and environment")
	view.set_frontier_art_enabled(true) # Already effectively true; intent must still persist.
	view.configure_from_map(plain)
	check(bool(view.get_render_snapshot()["frontier_art_enabled"]),"explicit true while already true persists onto plain map")
	view.clear_frontier_art_override()
	check(active_lighting(view)==baseline,"return to plain map restores every active environment/light setting")
	view.configure_from_map(hex_plain)
	check(not bool(view.get_render_snapshot()["frontier_art_enabled"]),"Hex topology alone never selects the Frontier art profile")
	view.configure_from_map(themed)
	view.configure_from_map(null)
	check(not bool(view.get_render_snapshot()["frontier_art_enabled"]),"null map clears old theme selection without render recursion")
	view.queue_free()
	await process_frame
	print("FRONTIER_THEME_OVERRIDE_RESULT ",JSON.stringify({"passed":passed,"failed":failed}))
	quit(1 if failed else 0)
