extends SceneTree
var calls := []
func _init() -> void: call_deferred("run")
func run() -> void:
 var def: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
 var state := {"space_wings":{"wings":{"one":{"name":"One","craft_ids":["a","b"],"leader_craft_id":"a"},"two":{"name":"Two","craft_ids":["c"],"leader_craft_id":"c"}}},"space_travel":{"phase":"orbit","craft_id":"a","orbit_id":"moon_orbit","bodies":def.bodies,"orbits":def.orbits,"location_orbits":def.location_orbits},"campaign":{"locations":{},"jobs":{}},"crafts":[]}
 var view = load("res://scripts/ui/star_map_screen.gd").new(); root.add_child(view)
 view.configure(func(): return state, func(op, payload): calls.append([op,payload]); return {"ok":payload.get("craft_id", "") != "b", "message":"Kein Treibstoff"})
 var panel = view.find_child("SpaceWingPanel", true, false)
 panel.select_wing("one",false); panel.select_wing("two",true); calls.clear()
 # Stufe 1: Klick merkt vor, erst Start springt (fuer das ganze Geschwader).
 view.call("_preview_jump", "glut_1a_orbit", "orbit_1")
 if not calls.is_empty(): printerr("FAIL: Vormerken darf noch keinen Sprung senden")
 view.call("_start_pending")
 var ids := []
 for call in calls:
  if call[0] == "space_start_quantum": ids.append(call[1].craft_id)
 var err: Label = view.find_child("CommandError",true,false)
 var ok: bool = ids == ["a","b","c"] and err.text.contains("b") and err.text.contains("Treibstoff")
 if not ok: printerr("FAIL: Gruppensprung und Teilablehnung nicht korrekt: ", ids, " ", err.text)
 view.free(); print("PLAYTEST_GROUP_JUMP checks=2 failed=%d" % (0 if ok else 1)); quit(0 if ok else 1)
