extends SceneTree
var failed := 0
var picked: Array[String]=[]
func _init() -> void: call_deferred("_run")
func _run() -> void:
	root.size=Vector2i(1280,720)
	var canvas: Control=load("res://scripts/ui/star_map_canvas.gd").new(); root.add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.location_selected.connect(func(id:String): picked.append(id))
	canvas.set_travel_snapshot({"phase":"orbit","orbit_id":"planet_orbit","position":[0.8,0.28]})
	canvas.set_location_snapshot({"satellite_crash":{"available":true,"name":"Satellit"},"trade_outpost":{"available":false,"name":"Handel","reason":"Gesperrt"}})
	await process_frame
	canvas.zoom_at(Vector2(700,330),1.4); canvas.pan_by(Vector2(-70,50))
	await process_frame
	var target: Control=canvas.get_node("PlanetSite_satellite_crash")
	_check(target.get_rect().get_center().distance_to(canvas.map_to_screen(canvas.location_map_point("satellite_crash")))<1,"marker follows camera transform")
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.pressed=pressed; event.position=target.global_position+target.size*.5; event.global_position=event.position; root.push_input(event,true)
	await process_frame
	_check(picked==["satellite_crash"],"actual transformed marker click emits selection exactly once")
	var locked: Button=canvas.get_node("PlanetSite_trade_outpost")
	_check(locked.disabled,"locked planet site retains right-list gate")
	_check(canvas.get("_ship_texture")!=null,"ship marker uses existing revision-matched isometric preview")
	canvas.queue_free(); await process_frame; print("PLANET_SITES failed=",failed); quit(1 if failed else 0)
func _check(value: bool,label: String) -> void:
	if not value: failed+=1
	print("PASS: " if value else "FAIL: ",label)
