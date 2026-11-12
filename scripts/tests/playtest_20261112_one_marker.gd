extends SceneTree
func _init() -> void: call_deferred("run")
func run() -> void:
 var canvas = load("res://scripts/ui/star_map_canvas.gd").new()
 root.add_child(canvas)
 await process_frame
 var definitions: Dictionary = canvas.call("get_orbit_definitions")
 var snapshot: Dictionary = canvas.call("get_camera_snapshot")
 var ok: bool = int(snapshot.orbit_marker_count) == definitions.size()
 if not ok: printerr("FAIL: Mehr als ein Orbitmarker pro Himmelskörper sichtbar")
 canvas.free()
 print("PLAYTEST_ONE_MARKER checks=1 failed=%d" % (0 if ok else 1))
 quit(0 if ok else 1)
