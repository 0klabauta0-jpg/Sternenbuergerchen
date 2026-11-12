extends SceneTree
var requests: Array = []
func _init() -> void: call_deferred("run")
func run() -> void:
 var canvas = load("res://scripts/ui/star_map_canvas.gd").new()
 root.add_child(canvas)
 canvas.size = Vector2(1000, 600)
 await process_frame
 var def: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
 var routes := {"ship_a":{"phase":"orbit", "position":[0.4,0.4]}, "ship_b":{"phase":"orbit", "position":[0.65,0.55]}}
 canvas.call("set_travel_snapshot", {"phase":"orbit", "craft_id":"ship_a", "routes":routes, "orbit_id":"moon_orbit", "system_version":2, "bodies":def.bodies, "orbits":def.orbits})
 if not canvas.has_signal("craft_selected"):
  printerr("FAIL: Schiffsauswahl fehlt")
  canvas.free(); quit(1); return
 canvas.connect("craft_selected", func(id): requests.append(id))
 var point: Vector2 = canvas.call("map_to_screen", Vector2(0.65, 0.55))
 var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true; event.position = point; event.global_position = point
 canvas.call("_gui_input", event)
 var ok := requests == ["ship_b"]
 if not ok: printerr("FAIL: Klick auf Schiff wählt es nicht")
 canvas.free(); print("PLAYTEST_SHIP_CLICK checks=1 failed=%d" % (0 if ok else 1)); quit(0 if ok else 1)
