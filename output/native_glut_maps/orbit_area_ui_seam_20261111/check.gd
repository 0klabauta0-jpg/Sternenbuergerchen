extends SceneTree
const SCREEN = preload("res://scripts/ui/star_map_screen.gd")
const FLOW = preload("res://scripts/meta/meta_layer_flow.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
var checks := 0
var failures := 0
var full_reads := 0
var area_reads := 0
var commands: Array = []
var area: Dictionary = {}
var runtime: Dictionary = {}
class FlowProbe extends "res://scripts/meta/meta_layer_flow.gd":
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func _exit_tree() -> void: pass
class MissingAreaAPI extends Node: pass
class AreaAPI extends Node:
	var calls: Array = []
	var snapshot: Dictionary = {}
	func get_space_area_projection(id: String) -> Dictionary:
		calls.append(id)
		return snapshot
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("%s %s" % ["PASS" if ok else "FAIL",label])
func read_full() -> Dictionary:
	full_reads += 1
	return runtime.duplicate(true)
func read_area(id: String) -> Dictionary:
	area_reads += 1
	return area.duplicate(true) if id == "cutlass" else {"ok":false}
func command(op: String,payload: Dictionary) -> Dictionary:
	commands.append([op,payload.duplicate(true)])
	return {"ok":true}
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var system: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
	var travel := {"phase":"orbit","orbit_id":"planet_orbit","orbit_marker_id":"orbit_1","craft_id":"cutlass","bodies":system.bodies,"orbits":system.orbits,"location_orbits":system.location_orbits,"routes":{"cutlass":{"phase":"orbit","revision":1}},"position":[0.5,0.5]}
	runtime = {"space_travel":travel,"crafts":[{"craft_id":"cutlass","display_name":"Cutlass"}],"campaign":{"locations":{},"jobs":{}},"space_wings":{}}
	var cell := GRID.from_offset(Vector2i(256,230))
	area = {"ok":true,"space_area_id":"orbit_approach:planet","area_revision":4,"actors":[{"craft_id":"cutlass","wing_id":"wing_1","flight":{"craft_id":"cutlass","coordinate_frame":"local","space_area_id":"orbit_approach:planet","motion_mode":"tactical","position_plane":HEX.axial_to_plane(Vector2(cell)),"heading_rad":0.0},"metadata":{},"footprint_cells":[cell]}]}
	var original := area.duplicate(true)
	var screen := SCREEN.new()
	root.add_child(screen)
	screen.configure(read_full,command,read_area)
	screen.set_process(false)
	check(screen._orbit_button.disabled and screen._orbit_craft_id.is_empty() and area_reads == 0,"default fleet focus cannot select or request orbit")
	screen._fleet_selector.item_selected.emit(0)
	check(not screen._orbit_button.disabled and screen._orbit_craft_id == "cutlass" and commands.back() == ["space_focus_craft",{"craft_id":"cutlass"}],"explicit picker selection uses existing focus command and narrow projection")
	screen._show_orbit_view()
	check(screen._orbit_visible and screen._orbit_canvas.visible and not screen._canvas.visible,"actual local actor exposes orbit canvas; system button remains")
	var full_before := full_reads
	var narrow_before := area_reads
	screen._process(0.11)
	check(full_reads == full_before and area_reads == narrow_before+1,"visible orbit tick reads only narrow provider")
	screen._orbit_canvas.move_requested.emit("cutlass",cell)
	var sent: Dictionary = commands.back()[1]
	check(commands.back()[0] == "space_move" and sent.size() == 3 and sent.craft_id == "cutlass" and sent.target_hex == cell and not String(sent.request_id).is_empty() and full_reads == full_before,"move emits strict three-field existing command without full snapshot")
	var count := commands.size()
	screen._orbit_canvas.move_requested.emit("foreign",cell)
	screen.hide()
	narrow_before = area_reads
	screen._process(0.11)
	check(commands.size() == count and area_reads == narrow_before,"foreign craft and hidden-screen ticks produce no requests or polling")
	screen.show()
	screen._show_system_view()
	narrow_before = area_reads
	screen._process(0.11)
	check(screen._canvas.visible and not screen._orbit_canvas.visible and area_reads == narrow_before,"system view remains available without hidden area polling")
	screen._show_orbit_view()
	area.actors.clear()
	screen._process(0.11)
	check(not screen._orbit_visible and screen._orbit_button.disabled and screen._canvas.visible and original.actors.size() == 1,"lost local actor fails closed to system without source mutation")
	var flow := FlowProbe.new()
	root.add_child(flow)
	var missing := MissingAreaAPI.new()
	flow.add_child(missing)
	flow._singleplayer_runtime = missing
	check(not flow._get_star_map_area_projection("cutlass").ok and not flow._get_star_map_area_projection("").ok,"Flow missing API and empty selection fail closed")
	var provider := AreaAPI.new()
	flow.add_child(provider)
	provider.snapshot = original
	flow._singleplayer_runtime = provider
	check(flow._get_star_map_area_projection("cutlass") == original and provider.calls == ["cutlass"],"Flow only delegates chosen ID to owner API")
	flow._singleplayer_runtime = null
	flow.queue_free()
	screen.queue_free()
	print("ORBIT_AREA_UI_SEAM_RESULT checks=%d failures=%d real_gameplay_activation=false" % [checks,failures])
	quit(1 if failures else 0)
