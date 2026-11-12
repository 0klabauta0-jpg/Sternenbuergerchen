extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var base = load("res://scripts/meta/explorable_homebase.gd").new()
	root.add_child(base)
	base.set_transport_snapshot({"mode":"campaign","crafts":[],"space_travel":{"service_shuttle_home":{"phase":"inbound","craft_id":"service","landing_pad_id":"pad_2","pad_visual":{"phase":"inbound","progress":0.5}}}})
	var projection: Array = base.get("_transport_projection")
	if projection.size() != 1 or projection[0].get("craft_id") != "service" or projection[0].get("service_only") != true:
		printerr("FAIL: service shuttle projection"); base.free(); quit(1); return
	base.free()
	print("PASS: base projects foreign shuttle separately")
	quit(0)
