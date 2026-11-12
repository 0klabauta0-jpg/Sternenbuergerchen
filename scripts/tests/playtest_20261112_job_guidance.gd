extends SceneTree
var state := {}
func _init() -> void: call_deferred("run")
func run() -> void:
 var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
 state = {"mode":"campaign", "crafts":[], "campaign":{"selected_location_id":"homebase", "selected_job_id":"", "locations":{"homebase":{"name":"Basis"}, "satellite_crash":{"name":"Satelliten-Absturzstelle"}}, "jobs":{"satellite_recovery":{"location_id":"satellite_crash", "status":"accepted", "title":"Satellitenbergung"}}}, "space_travel":{"phase":"orbit", "craft_id":"ship", "orbit_id":"planet_orbit", "orbit_marker_id":"orbit_1", "bodies":definition.bodies, "orbits":definition.orbits, "location_orbits":definition.location_orbits, "system_version":2}}
 var view = load("res://scripts/ui/star_map_screen.gd").new()
 root.add_child(view)
 view.configure(func(): return state, func(_op, _payload): return {"ok":true})
 await process_frame
 var guidance: Label = view.find_child("AcceptedJobGuidance", true, false)
 var ok: bool = guidance != null and guidance.text.contains("Satellitenbergung") and guidance.text.contains("Mare Nostrum A")
 var canvas: Control = view.find_child("SystemMap", true, false)
 ok = ok and bool(Dictionary(canvas.get("_locations").get("satellite_crash", {})).get("accepted_job", false))
 if not ok: printerr("FAIL: Angenommener Auftrag und richtiger Zielorbit sind nicht sichtbar")
 view.free()
 print("PLAYTEST_JOB_GUIDANCE checks=2 failed=%d" % (0 if ok else 1))
 quit(0 if ok else 1)
