extends SceneTree
var runtime := {"crafts":[{"craft_id":"a","display_name":"Alpha"},{"craft_id":"b","display_name":"Bravo"}],"space_wings":{"revision":1,"wings":{"one":{"name":"Erste","craft_ids":["a"],"leader_craft_id":"a"},"two":{"name":"Zweite","craft_ids":["b"],"leader_craft_id":"b"}}}}
func _init() -> void: call_deferred("run")
func run() -> void:
 var panel = load("res://scripts/ui/space_wing_panel.gd").new(); root.add_child(panel)
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 panel.configure(func(): return runtime, func(_op, _payload): return {"ok":true})
 await process_frame
 var ok: bool = panel.has_method("select_wing") and panel.has_method("selected_wing_ids")
 if ok:
  for entry in [["one", false], ["two", true]]:
   var button: Control = panel.find_child("WingTab_" + entry[0], true, false)
   var point := button.get_global_rect().get_center()
   for down in [true, false]:
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down; event.position = point; event.global_position = point; event.ctrl_pressed = entry[1]
    root.push_input(event, true)
   await process_frame
  ok = panel.call("selected_wing_ids") == ["one", "two"]
  panel.call("select_wing", "one", true)
  ok = ok and panel.call("selected_wing_ids") == ["two"]
  await process_frame
  var first: Control = panel.find_child("WingTab_one", true, false)
  var second: Control = panel.find_child("WingTab_two", true, false)
  var start := first.get_global_rect().position + Vector2(2, 2)
  var finish := second.get_global_rect().end - Vector2(2, 2)
  var press := InputEventMouseButton.new(); press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = start; press.global_position = start
  root.push_input(press, true)
  var motion := InputEventMouseMotion.new(); motion.position = finish; motion.global_position = finish; motion.button_mask = MOUSE_BUTTON_MASK_LEFT
  root.push_input(motion, true)
  var release := InputEventMouseButton.new(); release.button_index = MOUSE_BUTTON_LEFT; release.pressed = false; release.position = finish; release.global_position = finish
  root.push_input(release, true)
  ok = ok and panel.call("selected_wing_ids") == ["one", "two"]
  panel.call("select_wing", "one", true)
  runtime.space_wings.wings.erase("two"); panel.refresh(runtime)
  ok = ok and panel.call("selected_wing_ids").is_empty()
 if not ok: printerr("FAIL: Rottenauswahl oder Aktualisierung unvollständig")
 panel.free(); print("PLAYTEST_WING_CARDS checks=3 failed=%d" % (0 if ok else 1)); quit(0 if ok else 1)
