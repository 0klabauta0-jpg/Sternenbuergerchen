extends SceneTree
var requests: Array = []
func _init() -> void: call_deferred("run")
func run() -> void:
 var canvas = load("res://scripts/ui/star_map_canvas.gd").new()
 root.add_child(canvas)
 canvas.size = Vector2(1000, 600)
 await process_frame
 var def: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
 canvas.call("set_travel_snapshot", {"phase":"orbit", "craft_id":"ship", "orbit_id":"moon_orbit", "orbit_marker_id":"orbit_1", "system_version":2, "bodies":def.bodies, "orbits":def.orbits})
 # Stufe 1: Rechtsklick auf einen Marker merkt das Ziel nur vor (orbit_previewed); orbit_requested kommt erst mit "Start".
 var started: Array = []
 canvas.orbit_requested.connect(func(orbit, marker): started.append([orbit, marker]))
 canvas.orbit_previewed.connect(func(orbit, marker): requests.append([orbit, marker]))
 var target: Dictionary = def.orbits.glut_1a_orbit.markers[0]
 var grid = load("res://scripts/core/strategic_hex_grid.gd")
 var point: Vector2 = canvas.call("map_to_screen", grid.normalized(Vector2i(target.hex[0], target.hex[1])))
 var event := InputEventMouseButton.new()
 event.button_index = MOUSE_BUTTON_RIGHT
 event.pressed = true
 event.position = point
 event.global_position = point
 canvas.call("_input", event)
 var ok := requests == [["glut_1a_orbit", "orbit_1"]] and started.is_empty()
 if not ok: printerr("FAIL: Rechtsklick auf Orbit merkt das Ziel vor und startet keinen Sprung")
 canvas.free()
 print("PLAYTEST_RIGHT_CLICK checks=1 failed=%d" % (0 if ok else 1))
 quit(0 if ok else 1)
