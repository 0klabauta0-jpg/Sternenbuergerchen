extends SceneTree
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
var count := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	count += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label)
func _initialize() -> void:
	var data := LAYOUT.build("glut_1")
	check(data.ok and data.map_bounds==Rect2i(0,0,512,256) and data.limb.nominal_width==256 and data.limb.visible_depth==4.0,"local bounds and nominal composition")
	var center: Vector2=data.limb.circle_center; var radius: float=data.limb.radius
	var edge_depth := center.y+sqrt(radius*radius-128.0*128.0)
	check(is_equal_approx(radius,2050.0) and center==Vector2(256,-2046) and is_zero_approx(edge_depth) and is_equal_approx(center.y+radius,4.0),"large circular body has four-cell sagitta, not radius four")
	var bounded: bool = data.gate_cells.size()==256
	for gate: Vector2i in data.gate_cells: bounded=bounded and LAYOUT.contains_local_cell(gate)
	check(bounded and data.gate_cells[0].x==128 and data.gate_cells[-1].x==383,"continuous nominal-width gate candidates inside local map")
	var shallow: bool = not data.body_cells.is_empty()
	for cell: Vector2i in data.body_cells: shallow=shallow and cell.y>=0 and cell.y<4 and cell.x>=128 and cell.x<384
	check(shallow,"visible body occupies at most four top rows")
	var contiguous := true
	for gate: Vector2i in data.gate_cells:
		contiguous=contiguous and not data.body_cells.has(gate) and data.body_cells.has(gate-Vector2i(0,1)) and gate.y==ceili(LAYOUT.limb_depth_at(gate.x))
	check(contiguous,"every gate immediately follows its own circular limb without overlap")
	var lower: bool = data.entry_band==Rect2i(0,224,512,32) and data.entry_band.end.y==256
	for cell: Vector2i in data.body_cells: lower=lower and not data.entry_band.has_point(cell)
	check(lower,"arrival band reaches bottom and stays separate from body")
	check(LAYOUT.build("glut_1").body_map_id==data.body_map_id and LAYOUT.build("a/b").body_map_id!=LAYOUT.build("a%2Fb").body_map_id and not LAYOUT.build("").ok and not LAYOUT.build(" glut_1").ok,"stable collision-free logical body map identity and invalid-ID rejection")
	data.body_cells.clear(); data.gate_cells.clear(); data.limb.radius=4
	var gates := LAYOUT.gate_cells("glut_1"); gates.clear()
	var fresh := LAYOUT.build("glut_1")
	check(not fresh.body_cells.is_empty() and fresh.gate_cells.size()==256 and fresh.limb.radius==2050.0 and not LAYOUT.contains_local_cell(Vector2i(512,0)) and not LAYOUT.contains_local_cell(Vector2i(-1,255)),"read-only facts are freshly allocated with strict local cell bounds")
	print("ORBIT_LAYOUT_RESULT checks=",count," failures=",failures," runtime_wired=false")
	quit(1 if failures else 0)
