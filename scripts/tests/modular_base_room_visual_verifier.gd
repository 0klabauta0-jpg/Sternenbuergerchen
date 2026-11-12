extends SceneTree
const VISUAL = preload("res://scripts/meta/modular_base_room_visual.gd")
const GEOMETRY = preload("res://scripts/meta/modular_base_geometry.gd")
const BASE_VIEW = preload("res://scripts/meta/explorable_homebase.gd")
var failed := 0
var checks := 0
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failed += 1
func run() -> void:
	for kind: String in ["sleep", "storage", "corridor"]:
		var room := {"id":"visual_fixture", "type":kind, "x":1, "y":1, "rotation":1}
		var before := JSON.stringify(room)
		var visual: Node3D = VISUAL.build(room)
		var second: Node3D = VISUAL.build(room)
		check(JSON.stringify(room) == before, kind + ": source plan remains unchanged")
		check(visual.get_node("Deck").mesh == second.get_node("Deck").mesh and visual.get_node("CutawayShell").mesh == second.get_node("CutawayShell").mesh, kind + ": geometry is cached across rooms")
		check(visual.find_children("*", "MeshInstance3D", true, false).size() == 2, kind + ": batched deck and shell only")
		check(visual.find_children("*", "CollisionObject3D", true, false).is_empty(), kind + ": visual adds no colliders")
		var shell: Mesh = visual.get_node("CutawayShell").mesh
		check(shell.get_aabb().size.is_equal_approx(Vector3(6.16, 1.45, 6.16)), kind + ": 16 cm wall hull centered at module boundary")
		var within_wall := true
		var doorway_clear := true
		for surface in range(shell.get_surface_count()):
			var arrays := shell.surface_get_arrays(surface)
			for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				var point := Vector2(vertex.x, vertex.z).abs()
				within_wall = within_wall and (point.x >= 2.92 - 0.00001 or point.y >= 2.92 - 0.00001)
				if point.x < GEOMETRY.DOOR_HALF - 0.00001 or point.y < GEOMETRY.DOOR_HALF - 0.00001: doorway_clear = false
		check(within_wall, kind + ": every shell/locker vertex fits the thinner physical wall")
		check(doorway_clear, kind + ": all four 1.44 m doorways remain clear")
		check(shell.get_surface_count() <= 12, kind + ": at most one surface per original material")
		visual.free(); second.free()
	var doors := [true, false, true, false]
	var door_room := {"id":"door_fixture", "type":"sleep", "x":0, "y":0, "rotation":0, "doors":doors}
	var door_visual: Node3D = VISUAL.build(door_room)
	var door_mesh: Mesh = door_visual.get_node("CutawayShell").mesh
	for side in range(4):
		check(_door_blocked(door_mesh, side) != bool(doors[side]), "door ray matches persisted N/E/S/W side " + str(side))
	door_visual.free()
	var map_data: RefCounted = preload("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/campaign_intro_base.json")
	var field: Node = preload("res://scripts/terrain/terrain_map_3d_view.gd").new()
	root.add_child(field)
	field.set("_terrain_map_data", map_data)
	field.call("_read_map_transform")
	var initial_map: int = map_data.call("get_tiles").size()
	var world_edges: Array = []
	for rotation in range(2):
		door_room.rotation = rotation
		var hex_room: Node3D = VISUAL.build(door_room, map_data, field)
		var projection: Dictionary = hex_room.get_meta("floor_hex_projection", {})
		check(projection.get("source", "") == "TerrainMapData" and int(projection.get("edge_count", 0)) > 60, "actual coarse terrain hexes projected, rotation " + str(rotation))
		var actual_cells := true
		for cell: Vector2i in projection.get("cells", []): actual_cells = actual_cells and map_data.call("get_tile_at_grid", cell) != null
		check(actual_cells, "only existing map cells draw floor edges")
		check(hex_room.find_children("*", "MeshInstance3D", true, false).size() == 3, "hex overlay is one additional mesh per module")
		var mesh: Mesh = hex_room.get_node("FieldHexProjection").mesh
		var arrays: Array = mesh.surface_get_arrays(0)
		var edges := {}
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for index in range(0, vertices.size(), 6):
			var a: Vector3 = hex_room.transform * ((vertices[index] + vertices[index + 5]) * 0.5)
			var b: Vector3 = hex_room.transform * ((vertices[index + 1] + vertices[index + 2]) * 0.5)
			edges[field.call("_get_grid_edge_key", a, b)] = true
		world_edges.append(edges)
		hex_room.free()
	check(world_edges[0] == world_edges[1], "world hex edges remain fixed when the room rotates 90 degrees")
	check(map_data.call("get_tiles").size() == initial_map, "floor projection does not mutate source map")
	field.free()
	var view: Node = BASE_VIEW.new()
	var stage := Node3D.new()
	var room := {"id":"standing_fixture", "type":"sleep", "x":0, "y":0, "rotation":0}
	view.call("_sync_modular_room_visuals", stage, {"rooms":[room], "beds":[]})
	var center := GEOMETRY.center(room)
	check(is_equal_approx(float(view.call("_standing_y", Vector3(center.x, 0, center.y))), 0.02), "module actor feet use the same 20 mm visual floor level")
	check(not view.get("_modular_floor_cells").has(Vector2i(1, 0)), "standing cache contains only confirmed modules")
	check(is_equal_approx(float(view.call("_standing_y", Vector3(center.x + 6, 0, center.y))), 0.0), "adjacent unbuilt module retains terrain standing height")
	view.free(); stage.free()
	print("MODULAR_ROOM_VISUAL ", checks - failed, " passed, ", failed, " failed")
	quit(0 if failed == 0 else 1)

func _door_blocked(mesh: Mesh, side: int) -> bool:
	var direction: Vector3 = [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT][side]
	for surface in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for index in range(vertices.size()): indices.append(index)
		for index in range(0, indices.size(), 3):
			if Geometry3D.ray_intersects_triangle(Vector3(0, 0.8, 0), direction, vertices[indices[index]], vertices[indices[index + 1]], vertices[indices[index + 2]]) != null: return true
	return false
