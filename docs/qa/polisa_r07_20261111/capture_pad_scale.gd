extends SceneTree
const BASE_PAD = preload("res://scripts/terrain/frontier_outpost_pad.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
var lines := ImmediateMesh.new()
var edges := {}
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(1280,720)
	var world := Node3D.new()
	root.add_child(world)
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://maps/homebase_frontier_exploration.json"))
	var size: Array = source.homebase_exploration.landing_pads[0].size
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/polisa_r07_20261111/layout_compiled.json"))
	var small: Dictionary = {}
	for pad: Dictionary in layout.pads:
		if String(pad["class"]) == "S": small = pad.duplicate(true); break
	if small.is_empty() or small.size != size:
		push_error("Pad scale source mismatch")
		quit(1); return
	var base := BASE_PAD.new()
	world.add_child(base)
	base.build(Vector2(-10,0),Vector2(size[0],size[1]),"BASIS")
	# Isolated native comparison fixture, not a campaign scene: use the real
	# station pad builder, with a sentinel preventing the whole station build.
	var station = load("res://art/polisa_r07_20261111/polisa_r07_visual.gd").new()
	station.add_child(Node3D.new())
	world.add_child(station)
	small.center = [10.0,0.0]
	station.call("_box",Vector3(size[0],.3,size[1]),Vector3(10,-.14,0),"52656b")
	station.call("_build_pad",small)
	station.call("_flush")
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(.035,.085,.10)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	lines.surface_begin(Mesh.PRIMITIVE_TRIANGLES,material)
	var count := 0
	for center: Vector2 in [Vector2(-10,0),Vector2(10,0)]:
		var rect := Rect2(center-Vector2(size[0],size[1])*.5,Vector2(size[0],size[1]))
		for q in range(-16,17):
			for r in range(-4,5):
				var points: PackedVector2Array = HEX.corners(HEX.axial_to_plane(Vector2(q,r)),HEX.DEFAULT_RADIUS)
				var inside := true
				for point: Vector2 in points:
					if not rect.grow(.001).has_point(point): inside = false; break
				if not inside: continue
				count += 1
				for i in range(6): _line(points[i],points[(i+1)%6])
	lines.surface_end()
	var grid := MeshInstance3D.new()
	grid.mesh = lines
	world.add_child(grid)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("09232e")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = .8
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-65,-20,0)
	sun.light_energy = .9
	world.add_child(sun)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 24.0
	world.add_child(camera)
	camera.position = Vector3(0,35,0)
	camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	camera.current = true
	var ui := CanvasLayer.new()
	root.add_child(ui)
	_label(ui,"Heimatbasis / 8 × 6",Vector2(360,270))
	_label(ui,"Polisa S / 8 × 6",Vector2(1260,270))
	_label(ui,"Identische Kamera und Hexgröße · nativer Vergleichsaufbau",Vector2(360,820))
	_label(ui,"8 × 6 Spieleinheiten, keine andere Feldskalierung",Vector2(360,870))
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://docs/qa/polisa_r07_20261111/pad_scale_comparison.png")
	print("POLISA_PAD_SCALE source=homebase native_builders=true same_camera=true same_hex_geometry=true complete_hexes=",count," result=",result)
	world.queue_free()
	ui.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
func _line(a: Vector2,b: Vector2) -> void:
	var key := "%0.3f,%0.3f:%0.3f,%0.3f" % [a.x,a.y,b.x,b.y]
	var reverse := "%0.3f,%0.3f:%0.3f,%0.3f" % [b.x,b.y,a.x,a.y]
	if edges.has(key) or edges.has(reverse): return
	edges[key] = true
	var side := (b-a).orthogonal().normalized()*.018
	for point: Vector2 in [a+side,b+side,b-side,a+side,b-side,a-side]:
		lines.surface_add_vertex(Vector3(point.x,.185,point.y))
func _label(parent: Node,value: String,position: Vector2) -> void:
	var label := Label.new()
	label.text = value
	label.position = position
	label.add_theme_font_size_override("font_size",30)
	label.add_theme_color_override("font_color",Color("f1ebdc"))
	parent.add_child(label)
