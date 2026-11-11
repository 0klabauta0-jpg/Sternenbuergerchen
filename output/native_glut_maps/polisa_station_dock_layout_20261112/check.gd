extends SceneTree
const DOCK = preload("res://scripts/mission/polisa_station_dock_layout.gd")
const ORBIT = preload("res://scripts/mission/orbit_approach_layout.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label)
func _init() -> void:
	var dock := DOCK.build()
	var orbit := ORBIT.build("glut_2")
	check(dock.ok and dock.schema == "space_station_dock_layout.v1" and dock.revision == "polisa_glut2_dock_v1" and dock.body_id == "glut_2" and dock.area_id == orbit.body_map_id and dock.station_id == "polisa" and dock.target_id == "polisa_station_dock","canonical deterministic identity and revision")
	check(dock.map_bounds == Rect2i(0,0,512,256) and dock.coordinate_system == "offset_hex" and dock.station_anchor == Vector2i(256,124) and dock.station_block == Rect2i(244,116,24,12) and dock.dock_gate == Vector2i(256,133),"exact agreed offset geometry without physical metre/pad assumptions")
	var bounds: Rect2i = dock.map_bounds
	var block: Rect2i = dock.station_block
	check(bounds.encloses(block) and block.has_point(dock.station_anchor) and bounds.has_point(dock.dock_gate) and not block.has_point(dock.dock_gate),"station anchor contained and gate outside block inside bounds")
	var clear := true
	for cell: Vector2i in orbit.body_cells: clear = clear and not block.has_point(cell) and cell != dock.dock_gate
	check(clear and not block.intersects(orbit.entry_band) and not orbit.entry_band.has_point(dock.dock_gate),"block and gate exclude real body mask and arrival band")
	check(not dock.has("surface_location_id") and dock.size() == 12 and orbit.body_id == "glut_2","station target is not a planetary surface or extra body")
	var pristine := DOCK.build()
	dock.station_anchor = Vector2i.ZERO
	dock.station_block = Rect2i()
	dock["extra"] = {"changed":true}
	check(DOCK.build() == pristine and ORBIT.build("glut_2") == orbit,"repeated builds are detached values and do not mutate upstream layout")
	print("POLISA_DOCK_LAYOUT_RESULT checks=%d failures=%d runtime_wired=false visual_approved=false"%[checks,failures])
	quit(1 if failures else 0)
