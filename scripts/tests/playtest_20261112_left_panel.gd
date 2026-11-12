extends SceneTree

func _init() -> void:
 call_deferred("run")

func run() -> void:
 var view = load("res://scripts/ui/star_map_screen.gd").new()
 root.add_child(view)
 view.configure(func(): return {}, func(_operation, _payload): return {"ok": true})
 await process_frame
 var body: Control = view.find_child("SystemAndDetails", true, false)
 var details: Control = view.find_child("DetailsPanel", true, false)
 var map: Control = view.find_child("SystemMap", true, false)
 var ok: bool = body.get_children().find(details) < body.get_children().find(map.get_parent())
 ok = ok and details.is_ancestor_of(view.find_child("CloseStarMap", true, false))
 ok = ok and details.is_ancestor_of(view.find_child("ViewHomebase", true, false))
 if not ok: printerr("FAIL: Steuerung steht nicht links von der Karte")
 view.free()
 print("PLAYTEST_LEFT_PANEL checks=1 failed=%d" % (0 if ok else 1))
 quit(0 if ok else 1)
