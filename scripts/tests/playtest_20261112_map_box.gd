extends SceneTree
var selected := []
func _init() -> void: call_deferred("run")
func run() -> void:
 var canvas = load("res://scripts/ui/star_map_canvas.gd").new(); root.add_child(canvas); canvas.size = Vector2(1000,600)
 await process_frame
 var def: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
 canvas.set_travel_snapshot({"phase":"orbit","craft_id":"a","orbit_id":"moon_orbit","routes":{"a":{"phase":"orbit","position":[0.4,0.4]},"b":{"phase":"orbit","position":[0.6,0.5]}},"system_version":2,"bodies":def.bodies,"orbits":def.orbits})
 if not canvas.has_signal("crafts_box_selected"):
  printerr("FAIL: Auswahlrahmen fehlt"); canvas.free(); quit(1); return
 canvas.connect("crafts_box_selected",func(ids, _add): selected = ids)
 var a: Vector2 = canvas.map_to_screen(Vector2(0.4,0.4)); var b: Vector2 = canvas.map_to_screen(Vector2(0.6,0.5))
 var start := a - Vector2(20,20); var end := b + Vector2(20,20)
 var press := InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.pressed=true; press.position=start; press.global_position=start; canvas.call("_gui_input",press)
 var motion := InputEventMouseMotion.new(); motion.position=end; motion.global_position=end; motion.button_mask=MOUSE_BUTTON_MASK_LEFT; canvas.call("_input",motion)
 var release := InputEventMouseButton.new(); release.button_index=MOUSE_BUTTON_LEFT; release.pressed=false; release.position=end; release.global_position=end; canvas.call("_input",release)
 selected.sort(); var ok: bool = selected == ["a","b"]
 if not ok: printerr("FAIL: Rahmen erfasst nicht beide Schiffe: ",selected)
 canvas.free(); print("PLAYTEST_MAP_BOX checks=1 failed=%d" % (0 if ok else 1)); quit(0 if ok else 1)
