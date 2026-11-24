extends SceneTree
## Sternkarte (Wunsch 24.11.): Die Heimatbasis ist am Himmelskoerper der Heimat IMMER mit einem eigenen Marker (Haus + "Heimatbasis")
## gekennzeichnet, unabhaengig von Zoom, Auswahl und Auftrag. Der Marker des angenommenen Auftrags bleibt daneben sichtbar; die beiden
## verdecken sich nicht. Echte Leinwand mit dem echten Sternensystem, rechnerisch (Rechtecke der Marker), ohne Fenster.
var passed := 0
var failed := 0
var canvas: Control


func _init() -> void:
	call_deferred("_run")


func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
	print(("PASS " if value else "FAIL ") + label)


func _frames(count: int = 3) -> void:
	for i in count:
		await process_frame


func _home_rect() -> Rect2:
	return canvas.call("get_home_marker_rect") if canvas.has_method("get_home_marker_rect") else Rect2()


func _job_rect(id: String) -> Rect2:
	return canvas.call("get_job_marker_rect", id) if canvas.has_method("get_job_marker_rect") else Rect2()


func _inside(rect: Rect2) -> bool:
	return rect.has_area() and Rect2(Vector2.ZERO, canvas.size).encloses(rect)


func _draws() -> int:
	var value: Variant = canvas.get("_home_marker_draws")
	return int(value) if value != null else -1


func _center_on_home() -> void:
	# Kamera so schieben, dass der Heimatkoerper in der Mitte der Leinwand liegt (Zoom bleibt).
	var point: Vector2 = canvas.map_to_screen(canvas.location_map_point("homebase"))
	canvas.pan_by(canvas.size * 0.5 - point)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	canvas = load("res://scripts/ui/star_map_canvas.gd").new()
	root.add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.set_travel_snapshot({"phase": "orbit", "orbit_id": "planet_orbit", "position": [0.8, 0.28]})
	var sites := {"satellite_crash": {"available": true, "name": "Aschental"}, "trade_outpost": {"available": false, "name": "Kestrel", "reason": "Gesperrt"}}
	canvas.set_location_snapshot(sites)
	await _frames(4)
	_check(canvas.has_method("get_home_marker_rect") and canvas.has_method("get_job_marker_rect"), "Leinwand bietet die Marker-Rechtecke an (get_home_marker_rect, get_job_marker_rect)")
	# --- Fall 1: ohne Auftrag
	_check(_inside(_home_rect()), "ohne Auftrag: Heimat-Marker vorhanden und innerhalb der Karte (%s)" % str(_home_rect()))
	_check(_draws() > 0, "ohne Auftrag: Heimat-Marker wird tatsaechlich gezeichnet (Zeichnungen %d)" % _draws())
	# --- Auswahl aendert nichts
	var selected := sites.duplicate(true)
	selected["satellite_crash"]["selected"] = true
	canvas.set_location_snapshot(selected)
	await _frames(2)
	_check(_inside(_home_rect()), "mit gewaehltem Ort: Heimat-Marker bleibt")
	# --- Fall 2: Auftrag an anderem Koerper
	var other := sites.duplicate(true)
	other["satellite_crash"]["accepted_job"] = true
	canvas.set_location_snapshot(other)
	await _frames(2)
	var home_rect: Rect2 = _home_rect()
	var job_rect: Rect2 = _job_rect("satellite_crash")
	_check(_inside(home_rect), "Auftrag an anderem Koerper: Heimat-Marker sichtbar")
	_check(_inside(job_rect), "Auftrag an anderem Koerper: Auftragsmarker sichtbar (%s)" % str(job_rect))
	_check(not home_rect.intersects(job_rect), "Auftrag an anderem Koerper: die Rechtecke ueberschneiden sich nicht (%s / %s)" % [str(home_rect), str(job_rect)])
	# --- Fall 3: Auftrag am Heimatkoerper
	var at_home := other.duplicate(true)
	at_home["satellite_crash"]["accepted_job"] = false
	at_home["homebase"] = {"available": true, "name": "Heimathafen", "accepted_job": true}
	canvas.set_location_snapshot(at_home)
	await _frames(2)
	home_rect = _home_rect()
	job_rect = _job_rect("homebase")
	_check(_inside(home_rect), "Auftrag am Heimatkoerper: Heimat-Marker sichtbar")
	_check(_inside(job_rect), "Auftrag am Heimatkoerper: Auftragsmarker sichtbar (%s)" % str(job_rect))
	_check(not home_rect.intersects(job_rect), "Auftrag am Heimatkoerper: die Rechtecke liegen nebeneinander (%s / %s)" % [str(home_rect), str(job_rect)])
	# --- Zoomstufen: Heimatkoerper mittig, Marker bleiben sichtbar und getrennt (Fall 3 und Fall 2)
	for zoom: float in [1.0, 1.45, 3.0, 8.0, 20.0]:
		canvas.set_location_snapshot(at_home)
		canvas.zoom_at(canvas.size * 0.5, zoom)
		await _frames(2)
		_center_on_home()
		await _frames(2)
		home_rect = _home_rect()
		job_rect = _job_rect("homebase")
		_check(_inside(home_rect) and _inside(job_rect) and not home_rect.intersects(job_rect), "Zoom %.2f, Auftrag am Heimatkoerper: beide Marker sichtbar und getrennt (%s / %s)" % [zoom, str(home_rect), str(job_rect)])
		canvas.set_location_snapshot(sites)
		await _frames(2)
		_check(_inside(_home_rect()), "Zoom %.2f, ohne Auftrag: Heimat-Marker sichtbar" % zoom)
	canvas.queue_free()
	await process_frame
	print("STARMAP_HOME_MARKER passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
