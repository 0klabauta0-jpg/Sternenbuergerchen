extends SceneTree
## Polisar R09: check views of the actual model candidate (the game's station
## scene with labels and showcase figures) in a bare scene with documented
## orthographic cameras. No terrain view, no gameplay. Output: CAP_DIR or
## user://polisar_r09_views. For the "before" set with identical cameras and
## light, POLISAR_BEFORE_SCRIPT names a copy of the R08 visual script (from git
## history) and POLISAR_BEFORE_FACTS its layout_compiled.json.
## Run: godot --path . --rendering-driver opengl3 --resolution 1600x900 -s art/polisar_r09_20261114/capture_views.gd
const SCENE := "res://scenes/terrain/polisa_station_visual.tscn"
const FACTS := "res://art/polisar_r09_20261114/layout_compiled.json"
const SQ3H := 0.8660254037844386
## name, yaw, pitch, size (vertical extent in plane units), focus x, focus z (local), focus up, overlay
const VIEWS := [
	["01_draufsicht_orthografisch", 0.0, 89.9, 132.0, 0.0, 26.0, 0.0, "grid"],
	["02_gesamtkarte_yaw0_pitch68", 0.0, 68.0, 330.0, 0.0, 91.0, 0.0, ""],
	["03_nah_taktisch_yaw24_pitch50", 24.0, 50.0, 66.0, 0.0, 14.0, 0.0, ""],
	["04_hub_shops_yaw24_pitch50", 24.0, 50.0, 30.0, 0.0, 5.0, 0.0, ""],
	["05a_dock1_yaw24_pitch50", 24.0, 50.0, 46.0, -88.0, 24.0, 0.0, ""],
	["05b_dock2_yaw24_pitch50", 24.0, 50.0, 46.0, 88.0, 24.0, 0.0, ""],
	["06_kontrolle_entlang_x", 90.0, 0.0, 84.0, 0.0, 24.0, -2.2, "axis"],
]

func _init() -> void: call_deferred("_run")

func _run() -> void:
	var out := OS.get_environment("CAP_DIR")
	if out.is_empty(): out = "user://polisar_r09_views"
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1600, 900)
	var before_script := OS.get_environment("POLISAR_BEFORE_SCRIPT")
	var facts_path := OS.get_environment("POLISAR_BEFORE_FACTS") if not before_script.is_empty() else FACTS
	var facts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(facts_path))
	var world := Node3D.new()
	root.add_child(world)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("05070a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("aab6c8")
	environment.ambient_light_energy = 0.55
	var holder := WorldEnvironment.new()
	holder.environment = environment
	world.add_child(holder)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.05
	world.add_child(sun)
	if before_script.is_empty():
		world.add_child(load(SCENE).instantiate())
	else:
		var before := Node3D.new()
		before.set_script(load(before_script))
		world.add_child(before)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 1.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.current = true
	var grid := _hex_grid(facts)
	var axis := _axis_cross(facts)
	world.add_child(grid)
	world.add_child(axis)
	for view: Array in VIEWS:
		grid.visible = String(view[7]) == "grid"
		axis.visible = String(view[7]) == "axis"
		var yaw := deg_to_rad(float(view[1]))
		var pitch := deg_to_rad(float(view[2]))
		var focus := Vector3(float(view[4]), float(view[6]), float(view[5]))
		var direction := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
		camera.size = float(view[3])
		camera.position = focus + direction * 600.0
		camera.look_at(focus, Vector3.UP if float(view[2]) < 89.0 else Vector3(0, 0, -1))
		for i in 6: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + "/" + String(view[0]) + ".png")
		print("VIEW ", view[0], " yaw=", view[1], " pitch=", view[2], " size=", view[3], " focus_local=", [view[4], view[5], view[6]])
	quit(0)

## Top-view aids: the real hex raster of the map (cell centres x = q + r/2,
## z = r*sqrt(3)/2 in world plane), the map boundary and ship proxies in hex scale.
func _hex_grid(facts: Dictionary) -> Node3D:
	var node := Node3D.new()
	var origin := Vector2(float(facts.origin_plane[0]), float(facts.origin_plane[1]))
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES)
	var radius := 1.0 / sqrt(3.0)
	var boundary := float(facts.get("map_boundary_local_z", float(facts.space_bounds[1]) - origin.y))
	for r in range(int(floor((boundary + origin.y) / SQ3H)), int((boundary + origin.y + 112.0) / SQ3H)):
		var z := r * SQ3H - origin.y
		if z < boundary: continue
		for column in range(-126, 127):
			var x := float(column) + (0.5 if (r & 1) else 0.0) - origin.x
			for corner in range(3):
				var a := deg_to_rad(30.0 + 60.0 * corner)
				var b := deg_to_rad(90.0 + 60.0 * corner)
				lines.surface_add_vertex(Vector3(x + cos(a) * radius, -6.5, z + sin(a) * radius))
				lines.surface_add_vertex(Vector3(x + cos(b) * radius, -6.5, z + sin(b) * radius))
	lines.surface_end()
	node.add_child(_lines(lines, Color("2c4a5c")))
	var marks := ImmediateMesh.new()
	marks.surface_begin(Mesh.PRIMITIVE_LINES)
	marks.surface_add_vertex(Vector3(-130, 6.0, boundary)); marks.surface_add_vertex(Vector3(130, 6.0, boundary))
	marks.surface_end()
	node.add_child(_lines(marks, Color("e2b044")))
	# ship proxies: light fighter and medium fighter one hex each, Cutlass two neighbouring hexes
	for proxy: Array in [["leichter Jäger · 1 Hex", Vector2(-40.0, 62.0), 1], ["mittlerer Jäger · 1 Hex", Vector2(-28.0, 62.0), 1], ["Cutlass · 2 Hex", Vector2(34.0, 62.0), 2]]:
		var place: Vector2 = proxy[1]
		var r: int = int(round((place.y + origin.y) / SQ3H))
		var z: float = r * SQ3H - origin.y
		var x0: float = round(place.x) + (0.5 if (r & 1) else 0.0)
		for cell in range(int(proxy[2])):
			var body := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = radius; mesh.bottom_radius = radius; mesh.height = 0.2; mesh.radial_segments = 6
			body.mesh = mesh
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("7fe0dc"); material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			body.material_override = material
			body.position = Vector3(x0 + cell, 0.0, z)
			node.add_child(body)
		var label := Label3D.new()
		label.text = String(proxy[0]); label.pixel_size = 0.05; label.font_size = 40
		label.rotation_degrees.x = -90
		label.position = Vector3(x0 + 0.5, 0.2, z + 2.6)
		node.add_child(label)
	var note := Label3D.new()
	note.text = "Kartengrenze (oben: Dekoration, unten: Spielfeld)"
	note.pixel_size = 0.05; note.font_size = 40; note.modulate = Color("e2b044")
	note.rotation_degrees.x = -90
	note.position = Vector3(-92, 6.2, boundary + 2.2)
	node.add_child(note)
	return node

## Control view along X: a cross through the authored axle line (z, up).
func _axis_cross(facts: Dictionary) -> Node3D:
	var node := Node3D.new()
	var engineering: Dictionary = facts.engineering
	var z := float(engineering.get("axle_z", engineering.ring_z))
	var y := float(engineering.get("axle_y", engineering.ring_center_y))
	var reach := float(engineering.ring_radius) + 4.0
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for x: float in [130.0]:
		lines.surface_add_vertex(Vector3(x, y, z - reach)); lines.surface_add_vertex(Vector3(x, y, z + reach))
		lines.surface_add_vertex(Vector3(x, y - reach, z)); lines.surface_add_vertex(Vector3(x, y + reach, z))
	lines.surface_end()
	node.add_child(_lines(lines, Color("ff5a3c")))
	return node

func _lines(mesh: Mesh, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	part.material_override = material
	return part
