extends RefCounted
## Technical starting geometry only. Unwired; callers cache by area/revision.
const ORBIT = preload("res://scripts/mission/orbit_approach_layout.gd")
const SCHEMA := "space_station_dock_layout.v1"
const REVISION := "polisa_glut2_dock_v1"
const BODY_ID := "glut_2"
const AREA_ID := "orbit_approach:glut_2"

static func build() -> Dictionary:
	var orbit: Dictionary = ORBIT.build(BODY_ID)
	if not orbit.get("ok",false) or orbit.get("body_id") != BODY_ID or orbit.get("body_map_id") != AREA_ID:
		return {"ok":false,"reason":"orbit_layout_mismatch"}
	var bounds := Rect2i(0,0,512,256)
	var anchor := Vector2i(256,124)
	var block := Rect2i(244,116,24,12)
	var gate := Vector2i(256,133)
	if orbit.get("map_bounds") != bounds or not bounds.encloses(block) or not bounds.has_point(anchor) or not bounds.has_point(gate) or not block.has_point(anchor):
		return {"ok":false,"reason":"station_out_of_bounds"}
	if block.has_point(gate): return {"ok":false,"reason":"gate_inside_station"}
	var entry: Rect2i = orbit.entry_band
	if block.intersects(entry) or entry.has_point(gate): return {"ok":false,"reason":"entry_band_overlap"}
	# Existing authoring mask is bounded to256 columns with at most4 rows.
	for cell: Vector2i in orbit.body_cells:
		if block.has_point(cell) or cell == gate: return {"ok":false,"reason":"body_overlap"}
	return {"ok":true,"schema":SCHEMA,"revision":REVISION,"body_id":BODY_ID,
		"area_id":AREA_ID,"station_id":"polisa","target_id":"polisa_station_dock",
		"map_bounds":bounds,"coordinate_system":"offset_hex","station_anchor":anchor,
		"station_block":block,"dock_gate":gate}
