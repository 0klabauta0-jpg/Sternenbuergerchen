extends Node3D
## Polisar R09: the Blender-built station model plus what stays live in Godot:
## text labels, the three armour showcase figures and the map extent frame.
## Geometry source: art/polisar_r09_20261114/build_station.py (same layout facts
## as the map tiles). Visual only: no collision, navigation or docking owner.
const FACTS := "res://art/polisar_r09_20261114/layout_compiled.json"
const MODEL: PackedScene = preload("res://Assets/curated/polisar_r09_20261114/polisar_station.glb")
const ARMOR = preload("res://scripts/terrain/personnel_armor_visual.gd")
const PERSON = preload("res://Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb")
const HULL := "d8dad0"
const STEEL := "7d898b"
const CYAN := "7fe0dc"
const HIDDEN_NODES: PackedStringArray = ["Daecher"]
var _showcase_count := 0

func _ready() -> void:
	if get_child_count() > 0: return
	name = "PolisarR09Visual"
	var facts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FACTS))
	var model: Node3D = MODEL.instantiate()
	model.name = "PolisarModel"
	add_child(model)
	var triangles := 0
	var mesh_nodes := 0
	for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if String(part.name) in HIDDEN_NODES:
			# Roofs stay a separate part for a later cutaway rule; closed rooms would hide the shops.
			part.visible = false
			continue
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_nodes += 1
		for surface in range(part.mesh.get_surface_count()):
			triangles += part.mesh.surface_get_array_index_len(surface) / 3
	set_meta("station_deck_owns_flat_ground", true) # Live, successfully built deck; root view owns cap/raster policy.
	for room: Dictionary in facts.rooms: _label_room(room)
	for item: Dictionary in facts.furniture:
		if String(item.kind) == "armor": _build_showcase(item)
	for pad: Dictionary in facts.pads:
		var c := Vector2(float(pad.center[0]), float(pad.center[1]))
		var depth := float(pad.size[1])
		var text_size := .022 if String(pad["class"]) == "S" else (.034 if String(pad["class"]) == "M" else .05)
		_label(String(pad.number) + " " + String(pad["class"]), Vector3(c.x, .05, c.y - depth * .5 + .95), text_size, true, false)
	var engineering: Dictionary = facts.engineering
	for port: Dictionary in engineering.outer_ports:
		_label(String(port.label), Vector3(float(port.center[0]), float(engineering.axle_y) + 5.4, float(port.center[1]) + 2.0), .075, false, true)
	for block: Dictionary in facts.rear_decoration:
		if String(block.kind) == "sign":
			var r: Array = block.rect
			_label(String(facts.display_name), Vector3((float(r[0]) + float(r[2])) * .5 - 1.2, float(block.height) - 1.2, float(r[3]) + .46), .085, false, false)
	_build_space_extent(facts)
	set_meta("polisa_visual_metrics", {"static_triangles": triangles, "static_mesh_nodes": mesh_nodes, "primitive_boxes": 0,
		"showcase_rigs": _showcase_count, "collision_nodes": 0, "dynamic_lights": 0, "layout_sha256": facts.layout_sha256})

func _label_room(room: Dictionary) -> void:
	var r: Array = room.rect
	var c := Vector2((float(r[0]) + float(r[2])) * .5, (float(r[1]) + float(r[3])) * .5)
	var depth := float(r[3]) - float(r[1])
	_label(String(room.title), Vector3(c.x, .06, c.y + depth * .34), .028, true, false)
	# Small upright title on the sign bar of the rear wall, never a front billboard wall.
	if String(room.door_side) == "front" and String(room.id) != "armor":
		_label(String(room.title), Vector3(c.x, 3.02, float(r[1]) + .66), .02, false, false)

func _build_showcase(item: Dictionary) -> void:
	var r: Array = item.rect
	var c := Vector2((float(r[0]) + float(r[2])) * .5, (float(r[1]) + float(r[3])) * .5)
	var model: Node3D = PERSON.instantiate()
	model.name = "Showcase_" + String(item.armor)
	model.position = Vector3(c.x, float(item.height) + .08, c.y)
	add_child(model)
	ARMOR.apply_to_model(model, String(item.armor))
	for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
		player.play("idle"); player.advance(0); player.pause()
	model.process_mode = Node.PROCESS_MODE_DISABLED
	_showcase_count += 1
	_label({"light": "LEICHT", "medium": "MITTEL", "heavy": "SCHWER"}[String(item.armor)], Vector3(c.x, 3.2, c.y - .3), .021, false, true)

func _build_space_extent(facts: Dictionary) -> void:
	# A visual perimeter of the declared map extent, not extra navigable tiles.
	var o := Vector2(float(facts.origin_plane[0]), float(facts.origin_plane[1]))
	var r: Array = facts.space_bounds
	var lo := Vector2(float(r[0]), float(r[1])) - o
	var hi := Vector2(float(r[2]), float(r[3])) - o
	var frame := SurfaceTool.new()
	frame.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z: float in [lo.y, hi.y]: _box(frame, Vector3(hi.x - lo.x, .03, 1.2), Vector3((lo.x + hi.x) * .5, -.25, z))
	for x: float in [lo.x, hi.x]: _box(frame, Vector3(1.2, .03, hi.y - lo.y), Vector3(x, -.25, (lo.y + hi.y) * .5))
	_commit(frame, "PolisarMapExtent", CYAN, true)
	var stars := SurfaceTool.new()
	stars.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(110):
		var x := lo.x + 4 + fposmod(float(index * 73), hi.x - lo.x - 8)
		var z := lo.y + 4 + fposmod(float(index * 97), hi.y - lo.y - 8)
		var size := .12 if index % 5 else .24
		_box(stars, Vector3(size, .025, size), Vector3(x, -18, z))
	_commit(stars, "PolisarStars", STEEL, false)
	_label(String(facts.display_name) + " ORBIT / 512 x 256", Vector3(0, .02, hi.y + 20), .16, true, false)

func _box(surface: SurfaceTool, size: Vector3, position: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	surface.append_from(mesh, 0, Transform3D(Basis.IDENTITY, position))

func _commit(surface: SurfaceTool, node_name: String, color: String, glow: bool) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color)
	material.roughness = .78
	if glow:
		material.emission_enabled = true
		material.emission = Color(color)
		material.emission_energy_multiplier = .42
	var part := MeshInstance3D.new()
	part.name = node_name
	part.mesh = surface.commit()
	part.material_override = material
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(part)

func _label(text: String, position: Vector3, pixel_size: float, floor_label: bool = false, billboard: bool = true) -> void:
	var label := Label3D.new()
	label.text = text; label.position = position; label.pixel_size = pixel_size; label.font_size = 36
	label.modulate = Color(HULL); label.outline_size = 3
	label.no_depth_test = not floor_label and billboard
	if floor_label: label.rotation_degrees.x = -90
	elif billboard: label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
