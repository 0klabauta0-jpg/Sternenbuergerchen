extends SceneTree
const CANVAS = preload("res://scripts/ui/orbit_area_canvas.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
var checks := 0
var failures := 0
var requests: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("%s %s" % ["PASS" if ok else "FAIL",label])
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var canvas := CANVAS.new()
	root.add_child(canvas)
	canvas.size = Vector2(1000,600)
	var cell := GRID.from_offset(Vector2i(256,230))
	var flight := {"craft_id":"cutlass","position_plane":HEX.axial_to_plane(Vector2(cell)),"heading_rad":0.3,"coordinate_frame":"local","space_area_id":"orbit_approach:planet","motion_mode":"tactical","revision":8}
	var snapshot := {"ok":true,"space_area_id":"orbit_approach:planet","area_revision":5,"actors":[{"craft_id":"cutlass","wing_id":"wing_1","flight":flight,"metadata":{"name":"cutlass"},"footprint_cells":[cell,cell+Vector2i(1,0)]}]}
	var pristine := snapshot.duplicate(true)
	canvas.move_requested.connect(func(id: String,target: Vector2i): requests.append([id,target]))
	canvas.set_projection(snapshot)
	check(canvas.get_selected_craft_id().is_empty() and not canvas.request_move_at(canvas.hex_to_screen(cell)) and requests.is_empty(),"no first-craft selection or request fallback")
	canvas.set_projection(snapshot,"cutlass")
	var point := canvas.hex_to_screen(cell)
	check(canvas.screen_to_hex(point) == cell and canvas.screen_to_plane(point).is_equal_approx(flight.position_plane),"axial/plane/screen inverse uses actual DTO pose geometry")
	check(canvas.request_move_at(point) and requests == [["cutlass",cell]] and snapshot == pristine,"signal contains only selected ID and target cell; source immutable")
	var copied: Dictionary = canvas.get_projection()
	copied.actors[0].flight.position_plane = Vector2.ZERO
	snapshot.actors[0].metadata.name = "external mutation"
	check(canvas.get_projection().actors[0].metadata.name == "cutlass" and canvas.get_projection().actors[0].flight.position_plane == flight.position_plane,"deep input and output ownership")
	var fixed := canvas.screen_to_plane(Vector2(333,222))
	canvas.zoom_at(Vector2(333,222),12)
	canvas.pan_by(Vector2(40,-20))
	check(canvas.screen_to_plane(Vector2(373,202)).is_equal_approx(fixed) and canvas.screen_to_hex(canvas.hex_to_screen(cell)) == cell and canvas.get_projection().actors[0].flight == pristine.actors[0].flight,"camera anchor and pan do not mutate Flight")
	check(canvas.recenter_selected() and canvas.hex_to_screen(cell).is_equal_approx(canvas.size*0.5),"explicit selected recenter only")
	canvas.reset_camera()
	var layout: Dictionary = LAYOUT.build("planet")
	var body_cell := GRID.from_offset(layout.body_cells[0])
	var gate_cell := GRID.from_offset(layout.gate_cells[0])
	check(not canvas.request_move_at(canvas.hex_to_screen(body_cell)) and canvas.request_move_at(canvas.hex_to_screen(gate_cell)) and not canvas.request_move_at(canvas.hex_to_screen(GRID.from_offset(Vector2i(512,230)))),"same offset body mask and free gate; local bounds reject")
	canvas.set_projection(pristine,"missing")
	var no_fallback := not canvas.recenter_selected() and not canvas.request_move_at(point)
	var foreign := pristine.duplicate(true)
	foreign.actors[0].flight.space_area_id = "orbit_approach:moon"
	canvas.set_projection(foreign,"cutlass")
	check(no_fallback and canvas.get_selected_craft_id().is_empty() and not canvas.request_move_at(point),"missing or foreign selected craft fails closed")
	canvas.set_projection(pristine,"cutlass")
	var cached_layout: Dictionary = canvas._layout
	var cached_mask: Dictionary = canvas._body_mask
	var moved := pristine.duplicate(true)
	moved.actors[0].flight.position_plane += Vector2(1,0)
	canvas.set_projection(moved,"cutlass")
	var static_cached := is_same(cached_layout,canvas._layout) and is_same(cached_mask,canvas._body_mask)
	var lod: Dictionary = canvas.get_visible_grid_projection()
	var bounds: Rect2i = lod.offset_bounds
	var count := ceili(float(bounds.size.x)/lod.stride)*ceili(float(bounds.size.y)/lod.stride)
	canvas.zoom_at(canvas.size*0.5,48)
	var near: Dictionary = canvas.get_visible_grid_projection()
	check(static_cached and count <= 5000 and lod.stride > 1 and near.stride == 1 and near.offset_bounds.get_area() < 131072 and not canvas.is_processing(),"position update retains static cache; bounded viewport LOD; no process")
	canvas.set_projection({"ok":false},"cutlass")
	check(canvas.get_selected_craft_id().is_empty() and not canvas.request_move_at(point) and pristine.actors[0].flight == flight,"unavailable DTO clears input projection without runtime mutation")
	canvas.queue_free()
	print("ORBIT_AREA_CANVAS_RESULT checks=%d failures=%d runtime_wired=false visual_acceptance=false" % [checks,failures])
	quit(1 if failures else 0)
