extends SceneTree
## Aufnahme-Probe der Heimatbasis mit den neuen Modellen (24.11.): speichert vier Bilder 1280 x 720.
## Startet MIT Fenster (ohne --headless), beendet sich selbst; harte Obergrenze 90 Sekunden ueber einen Timer.
const OUT_DIR := "C:/dev/SternenBuergerchen-builds/modelle-2026-11-24/bilder"
const SIZE := Vector2i(1280, 720)


func _init() -> void:
	create_timer(85.0).timeout.connect(func() -> void:
		print("CAPTURE_TIMEOUT")
		quit(2))
	call_deferred("_run")


func _grid_of_plane(x: float, z: float) -> Array:
	var gy: int = roundi(z * 4.0 / (sqrt(3.0) * 0.5))
	return [roundi(x * 4.0 - float(gy) * 0.5), gy]


func _shot(base: Control, file: String, plane: Vector2, size: float, yaw: float) -> void:
	var view: Node = base.get("_view")
	view.set("_camera_size", size)
	view.set("_camera_yaw_degrees", yaw)
	view.call("focus_world_position", base.call("_world_at_grid", _grid_of_plane(plane.x, plane.y)))
	var vp: SubViewport = base.get("_viewport")
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for i in 12:
		view.call("_request_viewport_redraw")
		await process_frame
	var image: Image = vp.get_texture().get_image()
	if image == null or image.is_empty():
		print("CAPTURE_FAIL ", file)
		return
	if image.get_size() != SIZE:
		image.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	var err: int = image.save_png(OUT_DIR + "/" + file)
	print("CAPTURE ", file, " err=", err, " size=", image.get_size())


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	root.size = SIZE
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	for i in 8:
		await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	screen.call("request_operation", "navigate", {"mode": "base"})
	for i in 60:
		await process_frame
	var presenter: Control = screen.get("_operations_presenter")
	var base: Control = presenter.get("_base")
	if base == null or base.get("_view") == null:
		print("CAPTURE_FAIL no base view")
		quit(1)
		return
	await _shot(base, "01_uebersicht.png", Vector2(26.0, 9.0), 26.0, 24.0)
	await _shot(base, "02_pod.png", Vector2(12.2, 6.3), 8.0, 24.0)
	await _shot(base, "03_lager_terminals.png", Vector2(26.0, 6.5), 10.0, 24.0)
	await _shot(base, "04_tank_aufzug.png", Vector2(31.0, 15.5), 18.0, 24.0)
	print("CAPTURE_DONE")
	quit(0)
