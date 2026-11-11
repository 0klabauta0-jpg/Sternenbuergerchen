extends SceneTree
const CANVAS = preload("res://scripts/ui/star_map_canvas.gd")
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(2)
		return
	var owner = TRAVEL.new()
	owner.configure()
	var canvas := CANVAS.new()
	root.add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.clip_contents = true
	await process_frame
	canvas.set_travel_snapshot(owner.get_snapshot())
	canvas.set_location_snapshot({
		"satellite_crash": {"name": "Satellitenregion"},
		"trade_outpost": {"name": "Freihafen"},
		"fortified_outpost": {"name": "Gesicherter Außenposten"},
	})
	await _picture(args[0] + "_system.png")
	var planet: Dictionary = owner.get_snapshot().bodies.planet
	owner.apply_command({"contract_category": "singleplayer_space_travel", "operation": "launch_to_orbit",
		"payload": {"craft_id": "probe"}}, {"runtime_authorized": true})
	owner.apply_command({"contract_category": "singleplayer_space_travel", "operation": "start_quantum",
		"payload": {"craft_id": "probe", "target_orbit_id": "planet_orbit"}})
	owner.apply_command({"contract_category": "singleplayer_space_travel", "operation": "advance",
		"payload": {"delta_seconds": 0.32}}, {"runtime_authorized": true})
	var departure: Dictionary = owner.get_snapshot()
	canvas.set_travel_snapshot(departure)
	var departure_screen: Vector2 = canvas.map_to_screen(GRID.pair(departure.origin_position))
	canvas.zoom_at(departure_screen, 4.0)
	canvas.pan_by(canvas.size * 0.5 - departure_screen)
	await _picture(args[0] + "_warp.png")
	canvas.reset_camera()
	owner.apply_command({"contract_category": "singleplayer_space_travel", "operation": "advance",
		"payload": {"delta_seconds": 1.08}}, {"runtime_authorized": true})
	var flight: Dictionary = owner.get_snapshot()
	canvas.set_travel_snapshot(flight)
	var route_center: Vector2 = GRID.pair(flight.origin_position).lerp(GRID.pair(flight.route_destination), 0.5)
	var origin: Vector2 = canvas.map_to_screen(route_center)
	canvas.zoom_at(origin, 3.4)
	canvas.pan_by(canvas.size * 0.5 - origin)
	await _picture(args[0] + "_route.png")
	canvas.reset_camera()
	origin = canvas.map_to_screen(GRID.pair(planet.position))
	canvas.zoom_at(origin, 32.0)
	canvas.pan_by(canvas.size * 0.5 - origin)
	await _picture(args[0] + "_surface.png")
	canvas.queue_free()
	await process_frame
	quit()

func _picture(target: String) -> void:
	for frame in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	print("STAR_CAPTURE ", target, " ", root.get_texture().get_image().save_png(target))
