extends SceneTree
var calls: Array = []
func _init() -> void: call_deferred("run")
func run() -> void:
 var def: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
 var state := {"space_wings":{"wings":{"wing":{"craft_ids":["leader","member"],"leader_craft_id":"leader"}}},"space_travel":{"phase":"orbit","craft_id":"leader","orbit_id":"moon_orbit","bodies":def.bodies,"orbits":def.orbits,"location_orbits":def.location_orbits},"campaign":{"locations":{},"jobs":{}},"crafts":[]}
 var view = load("res://scripts/ui/star_map_screen.gd").new(); root.add_child(view)
 view.configure(func(): return state, func(op, payload): calls.append([op,payload]); return {"ok":true})
 view.call("_on_map_craft_selected", "member")
 var canvas: Control = view.find_child("SystemMap", true, false)
 var ok: bool = calls.has(["space_focus_craft", {"craft_id":"leader"}]) and canvas.get("_selected_ship_id") == "member"
 if not ok: printerr("FAIL: Rottenführung und angeklicktes Schiff müssen erhalten bleiben")
 view.free(); print("PLAYTEST_WING_FOCUS checks=1 failed=%d" % (0 if ok else 1)); quit(0 if ok else 1)
