extends SceneTree
## Aufnahme-Probe Grafik 1 (27.11.): Einsatzkarten ohne und mit Einsatz-Stimmung, Standard-Zoom und Uebersicht.
## Startet MIT Fenster (ohne --headless), beendet sich selbst; harte Obergrenze ueber einen Timer.
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const OUT_DIR := "C:/dev/SternenBuergerchen-builds/grafik-2026-11-27/bilder"
const SIZE := Vector2i(1600, 900)
const SHOTS := [
	{"name": "templer", "map": "res://maps/windbruch_outpost.json", "marker": "recon_altfeld"},
	{"name": "gm02", "map": "res://maps/Ground_Mission02_128x128.json", "marker": "spawn_bravo"},
]


func _init() -> void:
	create_timer(170.0).timeout.connect(func() -> void:
		print("CAPTURE_TIMEOUT")
		quit(2))
	call_deferred("_run")


func _capture(view: Node, file: String, size: float, focus: Vector2) -> void:
	view.set("_camera_size", size)
	view.call("focus_world_position", focus)
	var vp: SubViewport = view.get("_subviewport")
	if vp == null:
		print("CAPTURE_FAIL no viewport ", file)
		return
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for i in 20:
		view.call("_request_viewport_redraw")
		await process_frame
	var image: Image = vp.get_texture().get_image()
	if image == null or image.is_empty():
		print("CAPTURE_FAIL empty ", file)
		return
	var err: int = image.save_png(OUT_DIR + "/" + file)
	print("CAPTURE ", file, " err=", err, " size=", image.get_size())


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	root.size = SIZE
	for shot in SHOTS:
		for atmosphere in [false, true]:
			var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file(String(shot.map))
			if map == null:
				print("CAPTURE_FAIL map ", shot.map)
				continue
			var view = VIEW.new()
			root.add_child(view)
			view.set_mission_atmosphere_enabled(atmosphere)
			view.configure_from_map(map)
			for i in 10:
				await process_frame
			var focus: Vector2 = map.get_marker_position(String(shot.marker), Vector2(map.get_grid_size()) * 0.5) if map.has_method("get_grid_size") else map.get_marker_position(String(shot.marker))
			var tag: String = "mit" if atmosphere else "ohne"
			print("INFO ", shot.name, " ", tag, " aktiv=", view.is_mission_atmosphere_active(), " focus=", focus)
			await _capture(view, "%s_%s_standard.png" % [shot.name, tag], 34.0, focus)
			await _capture(view, "%s_%s_nah.png" % [shot.name, tag], 14.0, focus)
			await _capture(view, "%s_%s_uebersicht.png" % [shot.name, tag], 90.0, focus)
			view.queue_free()
			for i in 3:
				await process_frame
	print("CAPTURE_DONE")
	quit(0)
