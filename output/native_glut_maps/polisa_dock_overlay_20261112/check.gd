extends SceneTree
const CANVAS = preload("res://scripts/ui/orbit_area_canvas.gd")
const DOCK = preload("res://scripts/mission/polisa_station_dock_layout.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
var checks := 0
var failures := 0
var moves: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label)
func _init() -> void: call_deferred("run")
func run() -> void:
	var canvas := CANVAS.new()
	root.add_child(canvas)
	canvas.size = Vector2(1000,600)
	var descriptor := DOCK.build()
	var craft_cell := GRID.from_offset(Vector2i(260,150))
	var snapshot := {"ok":true,"space_area_id":DOCK.AREA_ID,"area_revision":1,"actors":[{"craft_id":"ship","wing_id":"wing","flight":{"craft_id":"ship","coordinate_frame":"local","space_area_id":DOCK.AREA_ID,"motion_mode":"tactical","position_plane":HEX.axial_to_plane(Vector2(craft_cell)),"heading_rad":0.0},"footprint_cells":[craft_cell],"metadata":{}}]}
	canvas.move_requested.connect(func(id: String,target: Vector2i): moves.append([id,target]))
	canvas.set_projection(snapshot,"ship")
	var missing := not canvas._dock_visible and canvas._dock_projection.is_empty()
	snapshot.dock_targets = [{"target_id":"polisa_station_dock","revision":"stale"}]
	canvas.set_projection(snapshot,"ship")
	check(missing and not canvas._dock_visible and canvas._dock_projection.is_empty(),"no inferred overlay without exact current Root target revision")
	snapshot.dock_targets = [{"target_id":"polisa_station_dock","revision":DOCK.REVISION}]
	var original := snapshot.duplicate(true)
	canvas.set_projection(snapshot,"ship")
	check(canvas._dock_visible and canvas._dock_projection.descriptor == descriptor and canvas._dock_cache.size() == 1,"exact target DTO selects only shared detached station geometry")
	var gate: Vector2i = GRID.from_offset(descriptor.dock_gate)
	check(canvas._dock_projection.gate_axial == gate and canvas._dock_projection.anchor_plane == HEX.axial_to_plane(Vector2(GRID.from_offset(descriptor.station_anchor))) and canvas.screen_to_hex(canvas.hex_to_screen(gate)) == gate,"explicit offset-to-axial-to-plane projection and gate picking")
	check(not canvas.request_move_at(canvas.hex_to_screen(GRID.from_offset(descriptor.station_anchor))) and moves.is_empty() and canvas.request_move_at(canvas.hex_to_screen(gate)) and moves == [["ship",gate]],"station block suppresses Move; gate sends only existing ID/cell intent, no docking action")
	var cached: Dictionary = canvas._dock_projection
	var moved := snapshot.duplicate(true)
	moved.actors[0].flight.position_plane += Vector2(1,0)
	canvas.set_projection(moved,"ship")
	check(is_same(cached,canvas._dock_projection) and canvas._dock_cache.size() == 1 and snapshot == original,"ship pose update retains static descriptor/plane cache and source values")
	canvas.zoom_at(Vector2(400,200),4)
	canvas.pan_by(Vector2(20,15))
	check(is_same(cached,canvas._dock_projection) and canvas.screen_to_hex(canvas.hex_to_screen(gate)) == gate,"camera changes only projection; shared dock geometry remains cached")
	moved.dock_targets[0].revision = "wrong"
	canvas.set_projection(moved,"ship")
	var hidden := not canvas._dock_visible and canvas._dock_projection.is_empty()
	moved.space_area_id = "orbit_approach:moon"
	canvas.set_projection(moved,"ship")
	check(hidden and not canvas._dock_visible,"wrong revision or other area immediately removes station drawing")
	canvas.set_projection(original,"")
	var copied: Dictionary = canvas.get_projection()
	copied.dock_targets[0].revision = "mutated outside"
	var before := moves.size()
	check(canvas._dock_visible and is_same(cached,canvas._dock_projection) and not canvas.request_move_at(canvas.hex_to_screen(gate)) and moves.size() == before and canvas.get_projection().dock_targets[0].revision == DOCK.REVISION,"cached redraw restores without selecting ship or granting docking authority; DTO copy detached")
	var boundary_covered := true
	var hull: PackedVector2Array = canvas._dock_projection.station_polygon_plane
	for offset in [Vector2i(244,126),Vector2i(267,117)]:
		for corner: Vector2 in HEX.corners(HEX.axial_to_plane(Vector2(GRID.from_offset(offset)))):
			# Hull-boundary points count as covered too.
			var distance := INF
			for index in hull.size(): distance = minf(distance,corner.distance_to(Geometry2D.get_closest_point_to_segment(corner,hull[index],hull[(index+1)%hull.size()])))
			boundary_covered = boundary_covered and (Geometry2D.is_point_in_polygon(corner,hull) or distance < 0.0001)
	check(boundary_covered,"station hull covers both odd/even-row side-boundary hexes")
	canvas.queue_free()
	print("POLISA_DOCK_OVERLAY_RESULT checks=%d failures=%d docking_commands=false visual_approved=false"%[checks,failures])
	quit(1 if failures else 0)
