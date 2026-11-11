extends SceneTree
const STATE = preload("res://scripts/core/space_combat_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var state = STATE.new()
	var failed := 0
	var cell: Vector2i = GRID.from_offset(Vector2i(400,100))
	var pose := {"position_plane":GRID.HEX.axial_to_plane(Vector2(cell)), "heading_rad":0.0, "coordinate_frame":"local", "space_area_id":"orbit_approach:moon"}
	var single: Array = state._occupied_cells(pose, [Vector2i.ZERO])
	if single != [cell]: failed += 1
	var multi: Array = state._occupied_cells(pose, [Vector2i.ZERO, Vector2i(1,0)])
	if multi.is_empty() or not multi.has(cell + Vector2i(1,0)): failed += 1
	pose.coordinate_frame = "strategic"
	pose.space_area_id = ""
	if not state._occupied_cells(pose, [Vector2i.ZERO]).is_empty(): failed += 1
	pose.coordinate_frame = "local"
	pose.space_area_id = "orbit_approach:moon"
	pose.position_plane = GRID.HEX.axial_to_plane(Vector2(GRID.from_offset(Vector2i(511,100))))
	if not state._occupied_cells(pose, [Vector2i.ZERO, Vector2i(1,0)]).is_empty(): failed += 1
	print("SPACE_COMBAT_AREA_FOOTPRINT passed=", 4 - failed, " failed=", failed)
	quit(1 if failed else 0)
