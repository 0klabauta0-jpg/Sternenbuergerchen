extends SceneTree
## Sternkarte, Stufe 1 (Wunsch 24.11.): Ein Klick auf einen Orbitmarker zeigt erst den Kurs, erst "Start" fliegt los.
## Doppelklick zoomt auf Koerper/Ort, Orte tragen ihre Namen, Wahl "Automatik / Selbst fliegen" beim Kurs,
## die drei Aktionsknoepfe fuellen ihre Spalte. Echte Sternkarte mit Stub-Befehlsweg und echten Mausereignissen, ohne Fenster.
const SCREEN = preload("res://scripts/ui/star_map_screen.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
var passed := 0
var failed := 0
var definition: Dictionary = {}
var state: Dictionary = {}
var calls: Array = []
var previewed: Array = []
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
	if operation == "space_set_orbit_automatic":
		state.space_travel.orbit_transit_automatic = bool(payload.get("enabled", true))
	return {"ok": true}


func _quantum_calls() -> Array:
	var result: Array = []
	for call in calls:
		if String(call.operation) == "space_start_quantum":
			result.append(call)
	return result


func _build_state(phase: String, orbit_id: String, selected: String) -> Dictionary:
	var marker: Dictionary = definition.orbits[orbit_id].markers[0]
	var position: Vector2 = GRID.normalized(GRID.cell_from_record(marker))
	var names := {"satellite_crash": "Aschental", "trade_outpost": "Kestrel", "fortified_outpost": "Bastion Silex", "relay_ridge": "Relaisgrat"}
	var locations := {}
	var availability := {}
	for id in names:
		locations[id] = {"name": names[id]}
		if id == "relay_ridge":
			locations[id]["region_position"] = [0.42578125, 0.1875]
		availability[id] = {"ok": true}
	return {"mode": "campaign", "crafts": [], "space_wings": {"wings": {}},
		"campaign": {"selected_location_id": selected, "selected_job_id": "", "locations": locations, "location_availability": availability, "jobs": {}},
		"space_travel": {"phase": phase, "craft_id": "ship", "orbit_id": orbit_id, "orbit_marker_id": "orbit_1", "position": [position.x, position.y],
			"system_version": 2, "bodies": definition.bodies, "orbits": definition.orbits, "location_orbits": definition.location_orbits,
			"target_orbit_id": "", "origin_position": [position.x, position.y], "progress": 0.0, "duration_seconds": 3.0,
			"orbit_transit_automatic": true, "orbit_transit_available": true, "fuel_reachability": {}}}


func _mouse(point: Vector2, index: MouseButton, pressed: bool, double_click: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = index
	event.pressed = pressed
	event.double_click = double_click
	if index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
		event.button_mask = (1 << (int(index) - 1)) if pressed else 0
	root.push_input(event, true)


func _move(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	root.push_input(event, true)


func _click(point: Vector2, index: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	_move(point)
	_mouse(point, index, true)
	_mouse(point, index, false)


func _key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	root.push_input(event)
	var release := InputEventKey.new()
	release.keycode = keycode
	release.physical_keycode = keycode
	release.pressed = false
	root.push_input(release)


func _marker_point(orbit_id: String) -> Vector2:
	var cell := GRID.cell_from_record(definition.orbits[orbit_id].markers[0])
	return canvas.get_global_rect().position + canvas.map_to_screen(GRID.normalized(cell))


func _course() -> Dictionary:
	return view.call("get_course_snapshot") if view.has_method("get_course_snapshot") else {}


func _pending() -> Dictionary:
	return Dictionary(_course().get("pending", {}))


func _label_text(name: String) -> String:
	var node: Node = view.find_child(name, true, false)
	return String(node.get("text")) if node != null else ""


func _start_button() -> Button:
	return view.find_child("StartCourse", true, false) as Button


func _press_start() -> void:
	var button: Button = _start_button()
	if button != null:
		button.pressed.emit()


func _open(test_state: Dictionary) -> void:
	state = test_state
	calls.clear()
	previewed.clear()
	requested.clear()
	view = SCREEN.new()
	root.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.configure(_snapshot, _command)
	if view.has_signal("orbit_previewed"):
		view.connect("orbit_previewed", func(orbit_id: String, marker_id: String): previewed.append(orbit_id + "/" + marker_id))
	if view.has_signal("orbit_requested"):
		view.connect("orbit_requested", func(orbit_id: String, marker_id: String): requested.append(orbit_id + "/" + marker_id))
	await _frames(4)
	canvas = view.find_child("SystemMap", true, false)
	canvas.call("reset_camera")
	await _frames(2)


func _close() -> void:
	view.queue_free()
	await process_frame


func _free_point() -> Vector2:
	for candidate in [Vector2(24, 24), Vector2(24, canvas.size.y - 24), Vector2(canvas.size.x * 0.5, canvas.size.y - 24), Vector2(canvas.size.x * 0.5, 24)]:
		if String(canvas.call("body_at", candidate)) == "" and Dictionary(canvas.call("orbit_marker_at", candidate)).is_empty():
			return canvas.get_global_rect().position + candidate
	return canvas.get_global_rect().position + Vector2(24, 24)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
	await _open(_build_state("orbit", "moon_orbit", "satellite_crash"))
	_check(view.has_signal("orbit_previewed") and view.has_signal("orbit_requested"), "Sternkarte kennt die Signale orbit_previewed und orbit_requested")
	_check(view.has_method("get_course_snapshot") and _start_button() != null, "Sternkarte bietet Kursauskunft und den Knopf Start an")
	# --- Linksklick auf Marker: nur vormerken
	var point_a := _marker_point("planet_orbit")
	_check(Rect2(Vector2.ZERO, Vector2(1280, 720)).has_point(point_a), "Marker liegt im Bild (%s)" % str(point_a))
	_click(point_a)
	await _frames(2)
	_check(requested.is_empty() and _quantum_calls().is_empty(), "Linksklick auf Marker: kein orbit_requested, kein Sprung (angefordert %d, Spruenge %d)" % [requested.size(), _quantum_calls().size()])
	_check(previewed == ["planet_orbit/orbit_1"], "Linksklick auf Marker: orbit_previewed kam genau einmal (%s)" % str(previewed))
	_check(String(_pending().get("orbit_id", "")) == "planet_orbit", "Linksklick: Ziel ist vorgemerkt (%s)" % str(_pending()))
	_check(int(_course().get("line_points", 0)) >= 2, "Linksklick: Kurslinie hat mindestens 2 Punkte (%s)" % str(_course().get("line_points", 0)))
	var text := String(_course().get("text", ""))
	_check(text.contains("Mare Nostrum") and text.contains("Treibstoff"), "Kurstext nennt Ziel und Treibstoff (%s)" % text.replace("\n", " | "))
	_check(_start_button() != null and _start_button().visible and not _start_button().disabled, "Start ist sichtbar und freigegeben")
	# --- Rechtsklick auf anderen Marker: ersetzt, kein Sprung
	_click(_marker_point("glut_1a_orbit"), MOUSE_BUTTON_RIGHT)
	await _frames(2)
	_check(requested.is_empty() and _quantum_calls().is_empty(), "Rechtsklick auf Marker: kein Sprung")
	_check(String(_pending().get("orbit_id", "")) == "glut_1a_orbit" and previewed.size() == 2, "Rechtsklick auf Marker merkt das Ziel vor (%s, %d Vorschauen)" % [str(_pending()), previewed.size()])
	# --- Linksklick auf wieder anderen Marker: Ziel ersetzt
	_click(_marker_point("glut_1b_orbit"))
	await _frames(2)
	_check(String(_pending().get("orbit_id", "")) == "glut_1b_orbit" and requested.is_empty() and _quantum_calls().is_empty(), "Klick auf anderen Marker ersetzt das Ziel, weiter kein Sprung (%s)" % str(_pending()))
	# --- Esc verwirft
	_key(KEY_ESCAPE)
	await _frames(2)
	_check(_pending().is_empty() and int(_course().get("line_points", -1)) == 0, "Esc verwirft das Ziel, Linie leer (%s / %s)" % [str(_pending()), str(_course().get("line_points", -1))])
	# --- Rechtsklick auf freie Flaeche verwirft
	_click(_marker_point("planet_orbit"))
	await _frames(2)
	_check(not _pending().is_empty(), "Vorbereitung: Ziel wieder vorgemerkt")
	_click(_free_point(), MOUSE_BUTTON_RIGHT)
	await _frames(2)
	_check(_pending().is_empty() and int(_course().get("line_points", -1)) == 0, "Rechtsklick auf freie Flaeche verwirft das Ziel, Linie leer")
	_check(requested.is_empty() and _quantum_calls().is_empty(), "Verwerfen startet keinen Sprung")
	# --- Start (Knopf)
	_click(_marker_point("planet_orbit"))
	await _frames(2)
	_press_start()
	await _frames(2)
	_check(requested == ["planet_orbit/orbit_1"], "Start: genau ein orbit_requested mit dem vorgemerkten Ziel (%s)" % str(requested))
	var quantum := _quantum_calls()
	_check(quantum.size() == 1 and String(quantum[0].payload.get("target_orbit_id", "")) == "planet_orbit" and String(quantum[0].payload.get("target_orbit_marker_id", "")) == "orbit_1", "Start: genau ein Sprungbefehl zum vorgemerkten Ziel (%s)" % str(quantum))
	_check(_pending().is_empty(), "Nach Start ist nichts mehr vorgemerkt")
	# --- Start (Enter)
	_click(_marker_point("glut_1a_orbit"))
	await _frames(2)
	_key(KEY_ENTER)
	await _frames(2)
	_check(requested == ["planet_orbit/orbit_1", "glut_1a_orbit/orbit_1"] and _quantum_calls().size() == 2, "Enter wirkt wie Start (%s, %d Spruenge)" % [str(requested), _quantum_calls().size()])
	# --- Doppelklick und Namen
	var planet_point: Vector2 = canvas.get_global_rect().position + canvas.map_to_screen(GRID.pair(definition.bodies.planet.position))
	canvas.call("reset_camera")
	await _frames(2)
	var zoom_before: float = float(canvas.call("get_camera_snapshot").zoom)
	planet_point = canvas.get_global_rect().position + canvas.map_to_screen(GRID.pair(definition.bodies.planet.position))
	_move(planet_point)
	_mouse(planet_point, MOUSE_BUTTON_LEFT, true)
	_mouse(planet_point, MOUSE_BUTTON_LEFT, false)
	await _frames(2)
	_check(is_equal_approx(float(canvas.call("get_camera_snapshot").zoom), zoom_before), "Einfachklick auf Koerper aendert den Zoom nicht (%.2f)" % float(canvas.call("get_camera_snapshot").zoom))
	_mouse(planet_point, MOUSE_BUTTON_LEFT, true, true)
	_mouse(planet_point, MOUSE_BUTTON_LEFT, false)
	await _frames(3)
	var zoom_after: float = float(canvas.call("get_camera_snapshot").zoom)
	var middle: Vector2 = canvas.call("map_to_screen", GRID.pair(definition.bodies.planet.position))
	_check(zoom_after > zoom_before * 1.5, "Doppelklick auf Koerper zoomt hinein (%.2f -> %.2f)" % [zoom_before, zoom_after])
	_check(middle.distance_to(canvas.size * 0.5) <= 6.0, "Doppelklick: Koerper liegt in der Bildmitte (%s / %s)" % [str(middle), str(canvas.size * 0.5)])
	var labels: Dictionary = canvas.call("get_location_labels") if canvas.has_method("get_location_labels") else {}
	_check(labels.has("fortified_outpost") and labels.has("relay_ridge"), "Leinwand liefert Ortsnamen (get_location_labels: %s)" % str(labels.keys()))
	for id in ["fortified_outpost", "relay_ridge"]:
		var entry: Dictionary = labels.get(id, {})
		_check(bool(entry.get("visible", false)) and Rect2(Vector2.ZERO, canvas.size).encloses(Rect2(entry.get("rect", Rect2()))), "Mare Nostrum, Ort %s: Name sichtbar und im Bild (%s)" % [id, str(entry)])
	_check(String(Dictionary(labels.get("fortified_outpost", {})).get("text", "")) == "Bastion Silex" and String(Dictionary(labels.get("relay_ridge", {})).get("text", "")) == "Relaisgrat", "Namen kommen aus dem Anzeige-Katalog (Bastion Silex, Relaisgrat)")
	var single_letter := false
	for id in labels:
		var shown := String(Dictionary(labels[id]).get("text", ""))
		if bool(Dictionary(labels[id]).get("visible", false)) and (shown.length() <= 1 or shown in ["A", "B", "C"]):
			single_letter = true
	_check(not single_letter and not labels.is_empty(), "Kein sichtbarer Ortsname ist nur A, B oder C")
	var two: Rect2 = Rect2(Dictionary(labels.get("fortified_outpost", {})).get("rect", Rect2()))
	var one: Rect2 = Rect2(Dictionary(labels.get("relay_ridge", {})).get("rect", Rect2()))
	_check(not two.intersects(one), "Die zwei Ortsnamen des Planeten ueberdecken sich nicht (%s / %s)" % [str(two), str(one)])
	# --- Aktionsknoepfe fuellen die Spalte
	await _close()
	await _open(_build_state("orbit", "moon_orbit", "satellite_crash"))
	await _width_check("LandHomebase", "An Mondbasis landen")
	state = _build_state("orbit", "planet_orbit", "fortified_outpost")
	view.call("refresh")
	await _frames(3)
	await _width_check("BeginApproach", "Anflug starten")
	state = _build_state("quantum", "moon_orbit", "satellite_crash")
	state.space_travel.target_orbit_id = "planet_orbit"
	view.call("refresh")
	await _frames(3)
	await _width_check("AbortQuantum", "Sprung abbrechen")
	await _close()
	# --- Treibstoff zu knapp
	var tight := _build_state("orbit", "moon_orbit", "satellite_crash")
	tight.space_travel.fuel_reachability = {"satellite_crash": {"ok": false, "message": "Treibstoff reicht nicht"}}
	await _open(tight)
	_click(_marker_point("glut_1a_orbit"))
	await _frames(2)
	_check(_start_button() != null and _start_button().disabled, "Treibstoff zu knapp: Start ist gesperrt")
	_check(not String(_course().get("text", "")).is_empty() and String(_course().get("text", "")).contains("reicht nicht"), "Treibstoff zu knapp: Grundtext nennt den Grund (%s)" % String(_course().get("text", "")).replace("\n", " | "))
	_press_start()
	await _frames(2)
	_check(requested.is_empty() and _quantum_calls().is_empty(), "Gesperrtes Start fliegt auch ueber das Signal nicht los")
	await _close()
	# --- Umschalter Automatik / Selbst fliegen
	await _open(_build_state("orbit", "moon_orbit", "satellite_crash"))
	var automatic: Button = view.find_child("OrbitModeAutomatic", true, false) as Button
	var manual: Button = view.find_child("OrbitModeManual", true, false) as Button
	_check(automatic != null and manual != null, "Beide Umschaltknoepfe (Automatik, Selbst fliegen) sind vorhanden")
	if automatic != null and manual != null:
		_check(automatic.button_pressed and not manual.button_pressed, "Vorgabe ist Automatik")
		_check(absf(automatic.size.x - manual.size.x) <= 2.0 and automatic.is_visible_in_tree() and manual.is_visible_in_tree(), "Die zwei Umschaltknoepfe sind gleich gross (%s / %s)" % [str(automatic.size), str(manual.size)])
		manual.pressed.emit()
		await _frames(2)
		var toggles: Array = []
		for call in calls:
			if String(call.operation) == "space_set_orbit_automatic":
				toggles.append(call.payload)
		_check(toggles == [{"craft_id": "ship", "enabled": false}], "Selbst fliegen: Automatik wird ueber den Befehlsweg ausgeschaltet (%s)" % str(toggles))
		_check(manual.button_pressed and not automatic.button_pressed, "Selbst fliegen ist als Wahl markiert")
		await _close()
		await _open(state)
		automatic = view.find_child("OrbitModeAutomatic", true, false) as Button
		manual = view.find_child("OrbitModeManual", true, false) as Button
		_check(manual != null and manual.button_pressed and automatic != null and not automatic.button_pressed, "Nach erneutem Oeffnen der Karte steht die Wahl weiter auf Selbst fliegen")
	await _close()
	await process_frame
	print("STARMAP_COURSE_PREVIEW passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)


func _width_check(node_name: String, label: String) -> void:
	var button: Button = view.find_child(node_name, true, false) as Button
	if button == null or not button.is_visible_in_tree():
		_check(false, "%s: Knopf sichtbar" % label)
		return
	var parent: Control = button.get_parent() as Control
	_check(absf(button.size.x - parent.size.x) <= 2.0 and parent.size.x > 100.0, "%s fuellt die Spaltenbreite (Knopf %.1f, Spalte %.1f)" % [label, button.size.x, parent.size.x])
