extends SceneTree
## Sternkarte (Spielrunde 27.11.), Paket C:
##  (1) Doppelklick auf einen Ort: Ansicht zoomt auf den Ort, der Kurs dorthin ist vorgemerkt (Start sichtbar), es wird KEIN Flug
##      gestartet (kein space_start_quantum, kein orbit_requested). Der einfache Klick waehlt den Ort wie bisher und merkt keinen Kurs vor.
##  (2) Jeder Ortsmarker PlanetSite_* trifft an seinem sichtbaren Mittelpunkt sich selbst (keine verdeckte Klickflaeche), auch bei
##      kleinem und grossem Zoom; zwei Marker liegen nie naeher als die Mindestdistanz.
## Echte Sternkarte mit Stub-Befehlsweg und echten Mausereignissen, ohne Fenster.
const SCREEN = preload("res://scripts/ui/star_map_screen.gd")
const CANVAS = preload("res://scripts/ui/star_map_canvas.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const MIN_CENTER_DISTANCE := 20.0
var passed := 0
var failed := 0
var definition: Dictionary = {}
var site_data: Array = []
var state: Dictionary = {}
var calls: Array = []
var requested: Array = []
var view: Control
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


func _snapshot() -> Dictionary:
	return state.duplicate(true)


func _command(operation: String, payload: Dictionary = {}) -> Dictionary:
	calls.append({"operation": operation, "payload": payload.duplicate(true)})
	return {"ok": true}


func _count(operation: String) -> int:
	var total := 0
	for call in calls:
		if String(call.operation) == operation:
			total += 1
	return total


func _build_state(phase: String, orbit_id: String, selected: String) -> Dictionary:
	var marker: Dictionary = definition.orbits[orbit_id].markers[0]
	var position: Vector2 = GRID.normalized(GRID.cell_from_record(marker))
	var locations := {}
	var availability := {}
	for entry in site_data:
		var id := String(entry.id)
		if id == "homebase": continue
		locations[id] = {"name": String(entry.name), "region_position": entry.region_position}
		availability[id] = {"ok": true}
	return {"mode": "campaign", "crafts": [], "space_wings": {"wings": {}},
		"campaign": {"selected_location_id": selected, "selected_job_id": "", "locations": locations, "location_availability": availability, "jobs": {}},
		"space_travel": {"phase": phase, "craft_id": "ship", "orbit_id": orbit_id, "orbit_marker_id": "orbit_1", "position": [position.x, position.y],
			"system_version": 2, "bodies": definition.bodies, "orbits": definition.orbits, "location_orbits": definition.location_orbits,
			"target_orbit_id": "", "origin_position": [position.x, position.y], "progress": 0.0, "duration_seconds": 3.0,
			"orbit_transit_automatic": true, "orbit_transit_available": true, "fuel_reachability": {}}}


func _mouse(point: Vector2, pressed: bool, double_click: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.double_click = double_click
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(event, true)


func _move(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	root.push_input(event, true)


func _click(point: Vector2) -> void:
	_move(point)
	_mouse(point, true)
	_mouse(point, false)


func _double_click(point: Vector2) -> void:
	_click(point)
	_mouse(point, true, true)
	_mouse(point, false)


func _course() -> Dictionary:
	return view.call("get_course_snapshot")


func _pending() -> Dictionary:
	return Dictionary(_course().get("pending", {}))


func _site_center(map_canvas: Control, id: String) -> Vector2:
	var button: Control = map_canvas.get_node("PlanetSite_" + id)
	return button.get_global_rect().get_center()


func _open(test_state: Dictionary) -> void:
	state = test_state
	calls.clear()
	requested.clear()
	view = SCREEN.new()
	root.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.configure(_snapshot, _command)
	view.connect("orbit_requested", func(orbit_id: String, marker_id: String): requested.append(orbit_id + "/" + marker_id))
	await _frames(4)
	canvas = view.find_child("SystemMap", true, false)
	canvas.call("reset_camera")
	await _frames(2)


func _close() -> void:
	view.queue_free()
	await process_frame


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/locations.json"))
	var rows: Array = raw.values() if raw is Dictionary else Array(raw)
	if raw is Dictionary and raw.has("locations"):
		rows = raw.locations.values() if raw.locations is Dictionary else Array(raw.locations)
	for row in rows:
		if row is Dictionary and row.has("id"):
			site_data.append({"id": String(row.id), "name": String(row.get("name", row.id)), "region_position": row.get("region_position", [])})
	_check(site_data.size() >= 8, "Ortsdaten gelesen (%d Orte)" % site_data.size())

	# --- (1) Doppelklick: Ansicht + Kurs, kein Start. Schiff im Mondorbit, Ziel Bastion (planet_orbit).
	await _open(_build_state("orbit", "moon_orbit", "satellite_crash"))
	var target_id := "fortified_outpost"
	var target_orbit := String(definition.location_orbits[target_id])
	var button: Button = canvas.get_node_or_null("PlanetSite_" + target_id)
	_check(button != null, "Ortsmarker PlanetSite_%s vorhanden" % target_id)
	if button == null:
		print("STARMAP_SITE_DOUBLE_CLICK passed=%d failed=%d" % [passed, failed + 1])
		quit(1)
		return
	_check(button.disabled, "Fernes Ziel %s: Marker ist gesperrt (Schiff im Mondorbit), Einfachklick bleibt wirkungslos" % target_id)
	var zoom_before: float = float(canvas.call("get_camera_snapshot").zoom)
	var center := _site_center(canvas, target_id)
	_click(center)
	await _frames(2)
	_check(_count("select_destination") == 0 and _count("space_start_quantum") == 0, "Einfachklick auf fernen Ort: keine Wahl, kein Flug")
	_check(is_equal_approx(float(canvas.call("get_camera_snapshot").zoom), zoom_before), "Einfachklick: Zoom bleibt")
	_mouse(center, true, true)
	_mouse(center, false)
	await _frames(3)
	_check(float(canvas.call("get_camera_snapshot").zoom) > zoom_before * 1.5, "Doppelklick: Ansicht zoomt auf den Ort (%.2f -> %.2f)" % [zoom_before, float(canvas.call("get_camera_snapshot").zoom)])
	_check(String(_pending().get("orbit_id", "")) == target_orbit, "Doppelklick: Kurs zum Orbit %s ist vorgemerkt (%s)" % [target_orbit, str(_pending())])
	_check(int(_course().get("line_points", 0)) >= 2, "Doppelklick: Kurslinie wird gezeigt")
	var start: Button = view.find_child("StartCourse", true, false) as Button
	_check(start != null and start.visible and not start.disabled, "Doppelklick: Knopf Start ist sichtbar und freigegeben")
	_check(_count("space_start_quantum") == 0 and requested.is_empty(), "Doppelklick startet KEINEN Flug (Sprungbefehle %d, orbit_requested %d)" % [_count("space_start_quantum"), requested.size()])
	_check(_count("space_begin_approach") == 0 and _count("select_destination") == 0, "Doppelklick startet keinen Anflug und waehlt den fernen Ort nicht (Befehlsweg lehnt das ab)")
	start.pressed.emit()
	await _frames(2)
	_check(_count("space_start_quantum") == 1 and requested.size() == 1, "Erst der Knopf Start fliegt (Sprungbefehle %d)" % _count("space_start_quantum"))
	await _close()

	# --- (1b) Schiff steht schon im Orbit des Ortes: Marker ist frei. Einfachklick waehlt, Doppelklick zoomt, merkt keinen Sprung vor, startet nichts.
	await _open(_build_state("orbit", target_orbit, "satellite_crash"))
	button = canvas.get_node("PlanetSite_" + target_id)
	_check(not button.disabled, "Im Orbit des Ortes: Marker %s ist anklickbar" % target_id)
	zoom_before = float(canvas.call("get_camera_snapshot").zoom)
	center = _site_center(canvas, target_id)
	_click(center)
	await _frames(2)
	_check(_count("select_destination") == 1, "Einfachklick waehlt den Ort wie bisher (%d select_destination)" % _count("select_destination"))
	_mouse(center, true, true)
	_mouse(center, false)
	await _frames(3)
	_check(float(canvas.call("get_camera_snapshot").zoom) > zoom_before * 1.5, "Im Orbit des Ortes: Doppelklick zoomt auf den Ort")
	_check(_pending().is_empty() and _count("space_start_quantum") == 0 and _count("space_begin_approach") == 0, "Im Orbit des Ortes: Doppelklick merkt keinen Sprung vor, startet weder Sprung noch Anflug")
	await _close()

	# --- (2) Jeder Ortsmarker trifft sich selbst; bei kleinem, normalem und grossem Zoom.
	canvas = CANVAS.new()
	root.add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var picked: Array = []
	canvas.location_selected.connect(func(id: String): picked.append(id))
	canvas.set_travel_snapshot({"phase": "orbit", "orbit_id": "planet_orbit", "position": [0.8, 0.28]})
	var snapshot := {}
	for entry in site_data:
		if String(entry.id) == "homebase": continue
		snapshot[String(entry.id)] = {"available": true, "name": String(entry.name), "region_position": entry.region_position}
	canvas.set_location_snapshot(snapshot)
	await _frames(2)
	for zoom in [0.0, 0.7, 1.0, 2.0]:
		canvas.call("reset_camera")
		if zoom > 0.0: canvas.zoom_at(canvas.size * 0.5, zoom)
		await _frames(2)
		var ids: Array = snapshot.keys()
		ids.sort()
		var closest := INF
		for i in range(ids.size()):
			for j in range(i + 1, ids.size()):
				closest = minf(closest, _site_center(canvas, String(ids[i])).distance_to(_site_center(canvas, String(ids[j]))))
		_check(closest >= MIN_CENTER_DISTANCE, "Zoom %.1f: kein Ortsmarker naeher als %.0f px an einem anderen (%.1f)" % [zoom, MIN_CENTER_DISTANCE, closest])
		for id in ids:
			var marker: Control = canvas.get_node("PlanetSite_" + String(id))
			var site_point := marker.get_global_rect().get_center()
			if not Rect2(Vector2.ZERO, canvas.size).has_point(site_point):
				continue
			picked.clear()
			_click(site_point)
			await _frames(1)
			_check(picked == [String(id)], "Zoom %.1f: Marker %s trifft an seinem Mittelpunkt sich selbst (%s)" % [zoom, id, str(picked)])
	canvas.queue_free()
	await process_frame
	print("STARMAP_SITE_DOUBLE_CLICK passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
