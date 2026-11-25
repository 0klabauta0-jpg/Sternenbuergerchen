extends SceneTree
## Kopflos: Hintergrundbild der Sternkarte liegt mit seiner Mitte auf der Sonne, auch nach Zoom und Verschieben.
const CANVAS = preload("res://scripts/ui/star_map_canvas.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
var passed := 0
var failed := 0


func check(ok: bool, text: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", text)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	check(FileAccess.file_exists(CANVAS.BACKGROUND_PATH), "Hintergrunddatei vorhanden")
	var canvas: Control = CANVAS.new()
	root.add_child(canvas)
	canvas.size = Vector2(1000, 600)
	await process_frame
	await process_frame
	check(canvas.get_background_texture() != null, "Hintergrundbild geladen")
	var sun: Vector2 = GRID.pair(canvas._bodies.sun.position)
	for state in [[1.0, Vector2.ZERO], [3.7, Vector2(120, -80)]]:
		canvas._camera_zoom = state[0]
		canvas._camera_pan = state[1]
		var rect: Rect2 = canvas.get_background_rect()
		check(canvas.screen_to_map(rect.get_center()).distance_to(sun) < 0.0001, "Bildmitte in Kartenkoordinaten = Sonne (Zoom %s)" % state[0])
		check(rect.get_center().distance_to(canvas.map_to_screen(sun)) < 0.01, "Bildmitte = Bildschirmpunkt der Sonne (Zoom %s)" % state[0])
	canvas._camera_zoom = CANVAS.MIN_ZOOM
	canvas._camera_pan = Vector2.ZERO
	var min_rect: Rect2 = canvas.get_background_rect()
	check(min_rect.encloses(Rect2(canvas.map_to_screen(Vector2.ZERO), canvas.map_to_screen(Vector2.ONE) - canvas.map_to_screen(Vector2.ZERO))), "Bild deckt bei kleinstem Zoom die ganze Karte")
	print("STARMAP_BACKGROUND passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
