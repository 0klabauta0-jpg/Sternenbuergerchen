extends SceneTree
## Sternkarte, Rueckmeldung beim Anflug (Spielrunde 25.11.): Selbst fliegen wechselt nach dem Start von selbst auf die Orbit-Karte,
## eine Statuszeile sagt, welches Schiff wohin fliegt, jedes Spielerschiff traegt eine Marke mit Namen, die zwei Durchflug-Knoepfe
## sind klein und stehen in einer Zeile. Echte Sternkarte mit Stub-Befehlsweg, ohne Fenster.
const SCREEN = preload("res://scripts/ui/star_map_screen.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const MIN_BUTTON_HEIGHT := 26.0
var passed := 0
var failed := 0
var definition: Dictionary = {}
var state: Dictionary = {}
var calls: Array = []
var opened: Array = []
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


func _area(craft_id: String) -> Dictionary:
	var area_id := "orbit_approach:planet"
	return {"ok": true, "space_area_id": area_id, "actors": [{"craft_id": craft_id, "flight": {"craft_id": craft_id, "coordinate_frame": "local", "space_area_id": area_id, "motion_mode": "tactical", "position_plane": Vector2(256, 100), "heading_rad": 0.0}}]}


func _build_state(phase: String, orbit_id: String, automatic: bool) -> Dictionary:
	var marker: Dictionary = definition.orbits[orbit_id].markers[0]
	var position: Vector2 = GRID.normalized(GRID.cell_from_record(marker))
	var locations := {"satellite_crash": {"name": "Aschental"}, "trade_outpost": {"name": "Kestrel"}}
	var availability := {"satellite_crash": {"ok": true}, "trade_outpost": {"ok": true}}
	return {"mode": "campaign", "crafts": [{"craft_id": "ship", "display_name": "Entermesser 1"}], "space_wings": {"wings": {}},
		"campaign": {"selected_location_id": "satellite_crash", "selected_job_id": "", "locations": locations, "location_availability": availability, "jobs": {}},
		"space_travel": {"phase": phase, "craft_id": "ship", "orbit_id": orbit_id, "orbit_marker_id": "orbit_1", "position": [position.x, position.y],
			"system_version": 2, "bodies": definition.bodies, "orbits": definition.orbits, "location_orbits": definition.location_orbits,
			"target_orbit_id": "", "origin_position": [position.x, position.y], "progress": 0.0, "duration_seconds": 3.0,
			"orbit_transit_automatic": automatic, "orbit_transit_available": true, "fuel_reachability": {}}}


func _open(test_state: Dictionary) -> void:
	state = test_state
	calls.clear()
	opened.clear()
	view = SCREEN.new()
	root.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.configure(_snapshot, _command, _area)
	view.connect("orbit_view_opened", func(craft_id: String): opened.append(craft_id))
	await _frames(4)
	canvas = view.find_child("SystemMap", true, false)
	canvas.call("reset_camera")
	await _frames(2)


func _close() -> void:
	view.queue_free()
	await process_frame


func _course() -> Dictionary:
	return view.call("get_course_snapshot")


func _flight_label() -> Label:
	return view.find_child("FlightStatus", true, false) as Label


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))

	# --- (a) Selbst fliegen: nach "Anflug starten" wechselt die Ansicht von selbst auf die Orbit-Karte
	await _open(_build_state("orbit", "moon_orbit", false))
	_check(view.has_signal("orbit_view_opened"), "(a) Sternkarte kennt das Signal orbit_view_opened")
	_check(not bool(_course().get("orbit_view_open", true)) and opened.is_empty(), "(a) vor dem Start ist die Orbit-Karte zu")
	view.call("_begin_approach")
	await _frames(3)
	var approach_calls: Array = []
	for call in calls:
		if String(call.operation) == "space_begin_approach":
			approach_calls.append(call)
	_check(approach_calls.size() == 1, "(a) Anflug wurde ueber den Befehlsweg gesendet (%d)" % approach_calls.size())
	_check(bool(_course().get("orbit_view_open", false)) and opened == ["ship"], "(a) Selbst fliegen: Ansicht ist auf die Orbit-Karte gewechselt, Schiff 'ship' (%s)" % str(opened))
	await _close()
	await _open(_build_state("orbit", "moon_orbit", true))
	view.call("_begin_approach")
	await _frames(3)
	_check(not bool(_course().get("orbit_view_open", true)) and opened.is_empty(), "(a) Automatik: Ansicht bleibt auf der Sternkarte, kein Wechsel (%s)" % str(opened))
	await _close()

	# --- (b) Statuszeile mit Schiffsname, solange ein Schiff unterwegs ist
	var quantum := _build_state("quantum", "moon_orbit", true)
	quantum.space_travel.target_orbit_id = "planet_orbit"
	quantum.space_travel.target_orbit_marker_id = "orbit_1"
	await _open(quantum)
	var label := _flight_label()
	_check(label != null and label.is_visible_in_tree() and label.text.contains("Entermesser 1") and label.text.contains("→"), "(b) Warp-Sprung: Statuszeile nennt das Schiff und das Ziel (%s)" % (label.text.replace("\n", " | ") if label != null else "fehlt"))
	state.space_travel.phase = "orbit"
	state.space_travel.target_orbit_id = ""
	state.space_travel.orbit_transit = {"status": "flying", "direction": "inbound", "location_id": "satellite_crash"}
	view.call("refresh")
	await _frames(2)
	_check(label.is_visible_in_tree() and label.text.contains("Entermesser 1") and label.text.contains("Aschental"), "(b) Durchflug zum Planeten: Zeile nennt Schiff und Ort (%s)" % label.text.replace("\n", " | "))
	state.space_travel.erase("orbit_transit")
	view.call("refresh")
	await _frames(2)
	_check(not label.is_visible_in_tree(), "(b) Steht das Schiff im Orbit, ist die Statuszeile weg")
	await _close()

	# --- (c) Schiffsmarke mit Namen an der Schiffsposition / neben dem Ortssymbol
	await _open(quantum)
	var marks: Array = canvas.call("get_ship_marks")
	_check(marks.size() == 1 and String(marks[0].name) == "Entermesser 1" and String(marks[0].craft_id) == "ship", "(c) unterwegs: genau eine Schiffsmarke mit Namen (%s)" % str(marks))
	if marks.size() == 1:
		var mark_rect: Rect2 = marks[0].rect
		_check(mark_rect.has_area() and Rect2(Vector2.ZERO, canvas.size).intersects(mark_rect), "(c) Marke liegt auf der Karte (%s in %s)" % [str(mark_rect), str(canvas.size)])
		var ship_point: Vector2 = canvas.call("map_to_screen", GRID.pair(quantum.space_travel.position))
		_check((marks[0].point as Vector2).distance_to(ship_point) <= 40.0 and not bool(marks[0].at_site), "(c) Marke sitzt nahe der Schiffsposition (%.1f px)" % (marks[0].point as Vector2).distance_to(ship_point))
	await _close()
	var landed := _build_state("surface", "planet_orbit", true)
	landed.space_travel.location_id = "satellite_crash"
	await _open(landed)
	marks = canvas.call("get_ship_marks")
	if marks.size() == 1:
		var site_point: Vector2 = canvas.call("_location_anchor", "satellite_crash")
		var gap := (marks[0].point as Vector2).distance_to(site_point)
		_check(bool(marks[0].at_site) and gap >= 9.0 and gap <= 60.0, "(c) am Ort: Marke steht versetzt neben dem Ortssymbol (%.1f px)" % gap)
	else:
		_check(false, "(c) am Ort: eine Marke erwartet (%d)" % marks.size())
	await _close()

	# --- (d) Durchflug-Knoepfe: klein, eine Zeile, ueberdecken die Karte nicht
	await _open(_build_state("orbit", "moon_orbit", true))
	var automatic := view.find_child("OrbitModeAutomatic", true, false) as Button
	var manual := view.find_child("OrbitModeManual", true, false) as Button
	_check(automatic != null and manual != null and automatic.is_visible_in_tree() and manual.is_visible_in_tree(), "(d) beide Knoepfe sichtbar")
	if automatic != null and manual != null:
		_check(automatic.size.y <= MIN_BUTTON_HEIGHT + 4.0 and manual.size.y <= MIN_BUTTON_HEIGHT + 4.0, "(d) Hoehe hoechstens %.0f px (%.1f / %.1f)" % [MIN_BUTTON_HEIGHT + 4.0, automatic.size.y, manual.size.y])
		_check(absf(automatic.get_global_rect().position.y - manual.get_global_rect().position.y) <= 2.0 and automatic.get_global_rect().end.x <= manual.get_global_rect().position.x + 1.0, "(d) beide in einer Zeile nebeneinander")
		_check(absf(automatic.size.x - manual.size.x) <= 2.0 and automatic.size.x <= 130.0, "(d) gleich breit und schmal (%.1f / %.1f)" % [automatic.size.x, manual.size.x])
		_check(not automatic.get_global_rect().intersects(canvas.get_global_rect()) and not manual.get_global_rect().intersects(canvas.get_global_rect()), "(d) die Knoepfe liegen nicht ueber der Systemkarte")
		manual.pressed.emit()
		await _frames(2)
		var toggles: Array = []
		for call in calls:
			if String(call.operation) == "space_set_orbit_automatic":
				toggles.append(call.payload)
		_check(toggles == [{"craft_id": "ship", "enabled": false}], "(d) Funktion unveraendert: Selbst fliegen schaltet Automatik aus (%s)" % str(toggles))
	await _close()

	await process_frame
	print("STARMAP_APPROACH_FEEDBACK passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
