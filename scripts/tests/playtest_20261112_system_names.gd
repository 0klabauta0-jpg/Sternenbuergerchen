extends SceneTree
func _init() -> void:
 var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
 var ok: bool = data.bodies.sun.name == "Börner" and data.bodies.planet.name == "Mare Nostrum"
 for body: Dictionary in data.bodies.values():
  if String(body.name).contains("Glut"): ok = false
 if not ok: printerr("FAIL: Systemnamen noch nicht aktualisiert")
 print("PLAYTEST_SYSTEM_NAMES checks=1 failed=%d" % (0 if ok else 1))
 quit(0 if ok else 1)
