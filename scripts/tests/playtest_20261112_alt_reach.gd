extends SceneTree
func _init() -> void: call_deferred("run")
func run() -> void:
 var state := {"space_travel":{"phase":"orbit","craft_id":"ship","orbit_id":"moon_orbit","fuel_reachability":{"satellite_crash":{"ok":false,"message":"Treibstoff reicht nicht"},"trade_outpost":{"ok":true,"route_ok":false,"needed_total":8.0,"available":5.0}}},"campaign":{"location_availability":{"satellite_crash":{"ok":true},"trade_outpost":{"ok":true}},"locations":{"satellite_crash":{"name":"Satellit"},"trade_outpost":{"name":"Handel"}},"jobs":{}},"crafts":[]}
 var view = load("res://scripts/ui/star_map_screen.gd").new(); root.add_child(view); view.configure(func(): return state, func(_op,_payload): return {"ok":true})
 # Regel 8 / Auftrag 21.11.: Erreichbarkeit = naechste Etappe bezahlbar; die Zeile nennt zusaetzlich, ob der ganze Hinweg reicht. Die Verfuegbarkeit der Orte gehoert zum Zustand (ohne sie zeigt die Karte keine Zeile).
 var label: Label = view.find_child("FuelReachability",true,false)
 var event := InputEventKey.new(); event.keycode = KEY_ALT; event.pressed = true; view.call("_input",event)
 var ok: bool = label != null and label.visible and label.text.contains("Satellit") and label.text.contains("Treibstoff reicht nicht") and label.text.contains("Handel") and label.text.contains("nächste Etappe möglich, der ganze Hinweg braucht 8 (vorhanden 5)")
 event.pressed = false; view.call("_input",event); ok = ok and not label.visible
 if not ok: printerr("FAIL: Alt-Treibstoffanzeige fehlt")
 view.free(); print("PLAYTEST_ALT_REACH checks=2 failed=%d" % (0 if ok else 1)); quit(0 if ok else 1)
