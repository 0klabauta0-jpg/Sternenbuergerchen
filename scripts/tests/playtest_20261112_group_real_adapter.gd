extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
class Flow extends Node:
 var _last_mission_result := {}
 var _selected_mission_id := ""
var fleet
var sim
var adapter
var view
func _init() -> void: call_deferred("run")
func snapshot() -> Dictionary:
 return {"mode":"skirmish", "space_travel":adapter.get_space_travel_snapshot(), "space_wings":sim.get_space_wing_snapshot(), "campaign":{"locations":{},"jobs":{}}, "crafts":[{"craft_id":"a","display_name":"Alpha"},{"craft_id":"b","display_name":"Bravo"}]}
func click(point: Vector2, ctrl: bool = false, mouse_button: int = MOUSE_BUTTON_LEFT) -> void:
 for down in [true,false]:
  var e := InputEventMouseButton.new(); e.button_index = mouse_button; e.pressed = down; e.position = point; e.global_position = point; e.ctrl_pressed = ctrl
  root.push_input(e, true)
func run() -> void:
 root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
 fleet = FLEET.new(); assert(fleet.configure().ok)
 for id in ["a","b"]:
  fleet.register_craft(id)
  assert(fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":"launch_to_orbit","payload":{"craft_id":id},"request_id":"launch"},{"runtime_authorized":true}).ok)
 sim = ROOT.new(); root.add_child(sim); sim.configure_singleplayer_owners(null,null,null,fleet)
 assert(sim.reconcile_space_wings(["a","b"],{"a":"pilot_a","b":"pilot_b"},{"runtime_authorized":true}).ok)
 var flow = Flow.new(); root.add_child(flow)
 adapter = ADAPTER.new(); root.add_child(adapter); adapter._simulation = sim; adapter._travel = fleet; adapter._flow = flow; adapter._space_route_requested = true
 view = load("res://scripts/ui/star_map_screen.gd").new(); root.add_child(view); view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 view.configure(snapshot, adapter.request_operation)
 await process_frame; await process_frame
 var panel = view.find_child("SpaceWingPanel",true,false)
 var ids: Array = sim.get_space_wing_snapshot().wings.keys(); ids.sort()
 for index in range(ids.size()):
  var tab: Control = panel.find_child("WingTab_" + String(ids[index]).validate_node_name(),true,false)
  if tab == null: printerr("FAIL missing tab"); quit(1); return
  click(tab.get_global_rect().get_center(), index > 0)
  await process_frame
 if OS.has_environment("WING_UI_CAPTURE"):
  await process_frame
  await RenderingServer.frame_post_draw
  var output := OS.get_environment("WING_UI_CAPTURE")
  root.get_texture().get_image().save_png(output)
 var ok: bool = panel.selected_wing_ids().size() == 2
 var canvas: Control = view.find_child("SystemMap",true,false)
 panel.select_wing(String(ids[0]), false)
 await process_frame
 var grid = load("res://scripts/core/strategic_hex_grid.gd")
 var ship_pos: Vector2 = canvas.call("map_to_screen",grid.pair(fleet.get_craft_snapshot("a").position))
 var local_start := ship_pos - Vector2(25,25)
 var local_end := ship_pos + Vector2(25,25)
 var drag_start: Vector2 = canvas.get_global_transform_with_canvas() * local_start
 var drag_end: Vector2 = canvas.get_global_transform_with_canvas() * local_end
 var press := InputEventMouseButton.new(); press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = drag_start; press.global_position = drag_start
 root.push_input(press, true)
 var motion := InputEventMouseMotion.new(); motion.position = drag_end; motion.global_position = drag_end; motion.button_mask = MOUSE_BUTTON_MASK_LEFT
 root.push_input(motion, true)
 var release := InputEventMouseButton.new(); release.button_index = MOUSE_BUTTON_LEFT; release.pressed = false; release.position = drag_end; release.global_position = drag_end
 root.push_input(release, true)
 await process_frame
 ok = ok and panel.selected_wing_ids().size() == 2
 var orbit: Dictionary = canvas.call("get_orbit_definitions").glut_1a_orbit
 var cell = load("res://scripts/core/strategic_hex_grid.gd").cell_from_record(orbit.markers[0])
 var target: Vector2 = canvas.get_global_transform_with_canvas() * canvas.call("map_to_screen",load("res://scripts/core/strategic_hex_grid.gd").normalized(cell))
 click(target, false, MOUSE_BUTTON_RIGHT)
 await process_frame
 for id in ["a","b"]:
  var s: Dictionary = fleet.get_craft_snapshot(id)
  ok = ok and s.phase == "quantum" and s.target_orbit_id == "glut_1a_orbit"
 if not ok: printerr("FAIL actual group jump ", panel.selected_wing_ids(), " a=", fleet.get_craft_snapshot("a").phase, " b=", fleet.get_craft_snapshot("b").phase, " error=", view.get_ui_snapshot().error)
 view.free(); adapter.free(); flow.free(); sim.free()
 print("PLAYTEST_GROUP_REAL_ADAPTER checks=3 failed=%d" % (0 if ok else 1)); quit(0 if ok else 1)
