extends RefCounted
## Read-only cutaway projection. Navigation and furnishings remain with the owner.
## Palette is borrowed from the active habitat GLB; its geometry is never edited.
const GEOMETRY = preload("res://scripts/meta/modular_base_geometry.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const HABITAT := "res://Assets/curated/base_access_20261109/habitat_cutaway_01.glb"
const FLOOR_SKIN := 0.02 # Render/actor projection only; navigation stays in the owner.
const WALL_HEIGHT := 1.45
const WALL_THICKNESS := 0.16
const WALL_CENTER := GEOMETRY.HALF_ROOM
const EDGE_DOOR_SIDE := [2, 1, 0, 3] # Visual +Z,+X,-Z,-X -> owner N,E,S,W.
static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}

static func build(room: Dictionary, map_data: RefCounted = null, view: Node = null) -> Node3D:
	_load_palette()
	var kind := String(room.get("type", "sleep"))
	var doors: Array = room.get("doors", [true, true, true, true])
	var key := kind + JSON.stringify(doors)
	if not _meshes.has(key): _meshes[key] = _build_meshes(kind, doors)
	var owner := Node3D.new()
	owner.name = String(room.get("id", "room"))
	owner.set_meta("visual_only", true)
	owner.set_meta("room_type", kind)
	owner.set_meta("floor_skin", FLOOR_SKIN)
	var center := GEOMETRY.center(room)
	owner.position = Vector3(center.x, 0.0, center.y)
	owner.rotation.y = float(int(room.get("rotation", 0))) * PI * 0.5
	for part: String in ["deck", "shell"]:
		var visual := MeshInstance3D.new()
		visual.name = "Deck" if part == "deck" else "CutawayShell"
		visual.mesh = _meshes[key][part]
		if part == "deck": visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		owner.add_child(visual)
	if map_data != null and view != null:
		_add_field_hexes(owner, room, map_data, view)
	var label := Label3D.new()
	label.name = "FloorDesignation"
	label.text = {"sleep":"RUHE", "storage":"LAGER", "corridor":"GANG"}.get(kind, "")
	label.font_size = 40
	label.pixel_size = 0.005
	label.modulate = Color("c5bba0")
	label.outline_size = 0
	label.no_depth_test = false
	label.position = Vector3(0, FLOOR_SKIN + 0.008, 1.9)
	label.rotation.x = -PI * 0.5
	owner.add_child(label)
	return owner

static func _load_palette() -> void:
	if not _materials.is_empty(): return
	var scene: PackedScene = load(HABITAT)
	var source := scene.instantiate()
	var original: MeshInstance3D = source.get_child(0) as MeshInstance3D
	for index in range(original.mesh.get_surface_count()):
		var material: Material = original.mesh.surface_get_material(index)
		_materials[material.resource_name.trim_prefix("M_Frontier04_")] = material
	source.free()

static func _build_meshes(kind: String, doors: Array) -> Dictionary:
	var deck: Dictionary = {}
	var shell: Dictionary = {}
	var span := GEOMETRY.ROOM_SIZE
	# One continuous slab; the actual map's hex edges are projected above it.
	_box(deck, "Deck", Vector3(span, 0.08, span), Vector3(0, FLOOR_SKIN - 0.04, 0))
	if kind == "sleep":
		# Subtle soft-floor panel connects the two real, individually bought beds.
		_box(deck, "Warm", Vector3(3.3, 0.002, 1.5), Vector3(0, FLOOR_SKIN + 0.004, -1.98))
	elif kind == "storage":
		for side: float in [-1.0, 1.0]:
			for offset: float in [-2.2, -1.6, 1.6, 2.2]:
				_box(deck, "Orange", Vector3(0.30, 0.002, 0.055), Vector3(offset, FLOOR_SKIN + 0.004, side * 1.03))
	else:
		# Four-way corridor stays exactly as traversable as its shared room geometry.
		for side: float in [-1.0, 1.0]:
			for offset: float in [-1.9, 1.9]:
				_box(deck, "Orange", Vector3(1.8, 0.002, 0.045), Vector3(offset, FLOOR_SKIN + 0.004, side * 0.94))
				_box(deck, "Orange", Vector3(0.045, 0.002, 1.8), Vector3(side * 0.94, FLOOR_SKIN + 0.004, offset))
	var jamb_width := 0.09
	var wall_length := GEOMETRY.HALF_ROOM - GEOMETRY.DOOR_HALF - jamb_width
	var wall_center := (GEOMETRY.HALF_ROOM + GEOMETRY.DOOR_HALF + jamb_width) * 0.5
	# Door openings are the persisted owner projection, not assumed on all sides.
	for edge in range(4):
		var open := bool(doors[EDGE_DOOR_SIDE[edge]])
		if not open: _wall_segment(shell, GEOMETRY.DOOR_HALF * 2, 0.0, edge)
		for sign_value: float in [-1.0, 1.0]:
			var along := sign_value * wall_center
			_wall_segment(shell, wall_length, along, edge)
			# Jamb and panel mullion fit inside the existing wall-block band.
			if open:
				_edge_box(shell, "Frame", Vector3(jamb_width, WALL_HEIGHT, WALL_THICKNESS), Vector3(sign_value * (GEOMETRY.DOOR_HALF + jamb_width * 0.5), WALL_HEIGHT * 0.5, WALL_CENTER), edge)
			else:
				_wall_segment(shell, jamb_width, sign_value * (GEOMETRY.DOOR_HALF + jamb_width * 0.5), edge)
			_edge_box(shell, "PaleTrim", Vector3(0.045, 0.84, 0.015), Vector3(along, 0.93, 2.95), edge)
			if kind == "storage":
				_wall_storage(shell, edge, along)
			elif kind == "sleep":
				_edge_box(shell, "Soft", Vector3(1.30, 0.55, 0.018), Vector3(along, 0.92, 2.943), edge)
				_edge_box(shell, "Frame", Vector3(0.25, 0.37, 0.02), Vector3(along + sign_value * 0.70, 1.1, 2.94), edge)
				_edge_box(shell, "PaleTrim", Vector3(0.10, 0.24, 0.004), Vector3(along + sign_value * 0.70, 1.1, 2.924), edge)
			else:
				_edge_box(shell, "Glass", Vector3(1.35, 0.32, 0.02), Vector3(along, 1.03, 2.94), edge)
				for stripe in range(3):
					_edge_box(shell, "Frame", Vector3(0.68, 0.028, 0.01), Vector3(along, 0.7 + stripe * 0.08, 2.925), edge)
		# Continuous floor through each 1.44 m opening; threshold is just paint.
		if open:
			_edge_box(deck, "PaleTrim", Vector3(GEOMETRY.DOOR_HALF * 2, 0.002, 0.18), Vector3(0, FLOOR_SKIN + 0.004, 2.89), edge)
			for sign_value: float in [-1.0, 1.0]:
				_edge_box(deck, "Orange", Vector3(0.20, 0.002, 0.18), Vector3(sign_value * 0.55, FLOOR_SKIN + 0.006, 2.89), edge)
	return {"deck":_commit(deck), "shell":_commit(shell)}

static func _wall_segment(parts: Dictionary, length: float, along: float, edge: int) -> void:
	_edge_box(parts, "Frame", Vector3(length, 0.14, WALL_THICKNESS), Vector3(along, 0.07, WALL_CENTER), edge)
	_edge_box(parts, "CreamWarm", Vector3(length, 0.30, WALL_THICKNESS), Vector3(along, 0.29, WALL_CENTER), edge)
	_edge_box(parts, "Orange", Vector3(length, 0.07, WALL_THICKNESS), Vector3(along, 0.475, WALL_CENTER), edge)
	# The inner panel is recessed 4 cm; all relief remains inside the 16 cm hull.
	_edge_box(parts, "Cream", Vector3(length, 0.85, 0.12), Vector3(along, 0.935, WALL_CENTER + 0.02), edge)
	_edge_box(parts, "Frame", Vector3(length, 0.09, WALL_THICKNESS), Vector3(along, 1.405, WALL_CENTER), edge)

static func _wall_storage(parts: Dictionary, edge: int, along: float) -> void:
	# Recessed shallow locker relief, entirely within the physical wall hull.
	# These are wall dressing, never free-standing crates in a navigation lane.
	_edge_box(parts, "Frame", Vector3(1.72, 0.98, 0.02), Vector3(along, 0.84, 2.95), edge)
	for row in range(3):
		for column in range(2):
			var color := "CargoOlive" if row == 0 and column == 1 else "Soft"
			var x := along + (column - 0.5) * 0.79
			var y := 0.53 + row * 0.31
			_edge_box(parts, color, Vector3(0.71, 0.24, 0.012), Vector3(x, y, 2.934), edge)
			_edge_box(parts, "Orange", Vector3(0.14, 0.035, 0.004), Vector3(x, y + 0.015, 2.924), edge)
		_edge_box(parts, "Orange", Vector3(1.72, 0.035, 0.012), Vector3(along, 0.38 + row * 0.31, 2.932), edge)

static func _add_field_hexes(owner: Node3D, room: Dictionary, map_data: RefCounted, view: Node) -> void:
	if String(map_data.call("get_grid_topology")) != HEX.TOPOLOGY_ID: return
	var cell_size: float = view.call("_get_3d_cell_size")
	var center := GEOMETRY.center(room)
	var half := GEOMETRY.HALF_ROOM
	var bounds := Rect2(center - Vector2.ONE * half, Vector2.ONE * GEOMETRY.ROOM_SIZE)
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for dx: float in [-half - cell_size, half + cell_size]:
		for dy: float in [-half - cell_size, half + cell_size]:
			var axial := HEX.plane_to_axial((center + Vector2(dx, dy)) / cell_size)
			minimum = minimum.min(axial)
			maximum = maximum.max(axial)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, view.call("_make_hex_grid_material", false))
	var edges := {}
	var cells: Array[Vector2i] = []
	var inverse := Basis(Vector3.UP, -float(int(room.get("rotation", 0))) * PI * 0.5)
	for q in range(floori(minimum.x), ceili(maximum.x) + 1):
		for r in range(floori(minimum.y), ceili(maximum.y) + 1):
			var grid := Vector2i(q, r)
			if map_data.call("get_tile_at_grid", grid) == null: continue
			# Read the same coarse cell projection used for the outdoor terrain.
			var projected: Vector3 = view.call("_grid_to_3d_position", Vector2(grid), 0.0)
			var corners := HEX.corners(Vector2(projected.x, projected.z), cell_size * HEX.DEFAULT_RADIUS)
			var intersects := false
			for index in range(6):
				var clipped := _clip_edge(corners[index], corners[(index + 1) % 6], bounds)
				if clipped.is_empty(): continue
				intersects = true
				var a := inverse * Vector3(clipped[0].x - center.x, FLOOR_SKIN + 0.009, clipped[0].y - center.y)
				var b := inverse * Vector3(clipped[1].x - center.x, FLOOR_SKIN + 0.009, clipped[1].y - center.y)
				var key: String = view.call("_get_grid_edge_key", a, b)
				if edges.has(key): continue
				edges[key] = true
				view.call("_add_hex_grid_coverage_quad", mesh, a, b, 0.04)
			if intersects: cells.append(grid)
	mesh.surface_end()
	if edges.is_empty(): return
	var visual := MeshInstance3D.new()
	visual.name = "FieldHexProjection"
	visual.mesh = mesh
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	owner.add_child(visual)
	owner.set_meta("floor_hex_projection", {"source":"TerrainMapData", "topology":HEX.TOPOLOGY_ID, "cell_size":cell_size, "cells":cells, "edge_count":edges.size()})

static func _clip_edge(start: Vector2, end: Vector2, bounds: Rect2) -> PackedVector2Array:
	var delta := end - start
	var enter := 0.0
	var leave := 1.0
	for axis in range(2):
		if absf(delta[axis]) < 0.00001:
			if start[axis] < bounds.position[axis] or start[axis] > bounds.end[axis]: return PackedVector2Array()
			continue
		var a := (bounds.position[axis] - start[axis]) / delta[axis]
		var b := (bounds.end[axis] - start[axis]) / delta[axis]
		enter = maxf(enter, minf(a, b))
		leave = minf(leave, maxf(a, b))
		if enter >= leave: return PackedVector2Array()
	return PackedVector2Array([start + delta * enter, start + delta * leave])

static func _edge_box(parts: Dictionary, palette: String, size: Vector3, position: Vector3, edge: int) -> void:
	var basis := Basis(Vector3.UP, float(edge) * PI * 0.5)
	_box(parts, palette, size, basis * position, basis)

static func _box(parts: Dictionary, palette: String, size: Vector3, position: Vector3, basis := Basis.IDENTITY) -> void:
	if not parts.has(palette):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_material(_materials[palette])
		parts[palette] = surface
	var box := BoxMesh.new()
	box.size = size
	parts[palette].append_from(box, 0, Transform3D(basis, position))

static func _commit(parts: Dictionary) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for surface: SurfaceTool in parts.values(): surface.commit(mesh)
	return mesh
