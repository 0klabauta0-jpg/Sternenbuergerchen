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
var reject_quantum := false
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
	if operation == "space_start_quantum" and reject_quantum:
		return {"ok": false, "message": "Befehlsweg lehnt ab: Treibstoff reicht nicht"}
	return {"ok": true}


## Lokaler Orbitbereich fuer "Selbst fliegen": ein Schiff in der Orbit-Ansicht.
func _area(craft_id: String) -> Dictionary:
	var area_id := "orbit_approach:planet"
	return {"ok": true, "space_area_id": area_id, "actors": [{"craft_id": craft_id, "flight": {"craft_id": craft_id, "coordinate_frame": "local", "space_area_id": area_id, "motion_mode": "tactical", "position_plane": Vector2(256, 100), "heading_rad": 0.0}}]}


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


func _open(test_state: Dictionary, with_area: bool = false) -> void:
	state = test_state
	reject_quantum = false
	calls.clear()
	previewed.clear()
	requested.clear()
	view = SCREEN.new()
	root.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if with_area:
		view.configure(_snapshot, _command, _area)
	else:
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
	await _nachbesserung_1()
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


func _orbit_position(orbit_id: String) -> Array:
	var position: Vector2 = GRID.normalized(GRID.cell_from_record(definition.orbits[orbit_id].markers[0]))
	return [position.x, position.y]


## Enter bei vorgemerktem Ziel mit dem Fokus auf einem bestimmten Bedienelement. Gibt Sprungzahl und Restziel zurueck.
func _enter_with_focus(kind: String) -> Dictionary:
	await _open(_build_state("orbit", "moon_orbit", "satellite_crash"))
	_click(_marker_point("planet_orbit"))
	await _frames(2)
	var target: Control = null
	match kind:
		"name":
			for edit in view.find_children("*", "LineEdit", true, false):
				if (edit as LineEdit).placeholder_text == "Rottenname":
					target = edit
			if target != null:
				var node: Node = target
				while node != null and node != view:
					if node is CanvasItem:
						node.show()
					node = node.get_parent()
		"tree":
			target = view.get("_navigation")
		"button":
			target = view.find_child("FuelReachabilityToggle", true, false)
		"start":
			target = _start_button()
	if target != null:
		target.grab_focus()
	else:
		var owner: Control = root.gui_get_focus_owner()
		if owner != null:
			owner.release_focus()
	await _frames(2)
	var focused: Control = root.gui_get_focus_owner()
	var focus_ok: bool = (focused == target) if target != null else (focused == null)
	_key(KEY_ENTER)
	await _frames(2)
	var result := {"focus_ok": focus_ok, "jumps": _quantum_calls().size(), "pending": not _pending().is_empty()}
	if not focus_ok:
		result["debug"] = "Ziel %s sichtbar %s Fokusmodus %s, Fokus liegt auf %s" % [str(target.get_path()) if target != null else "keins", str(target.is_visible_in_tree()) if target != null else "-", str(target.focus_mode) if target != null else "-", str(focused.get_path()) if focused != null else "nichts"]
	await _close()
	return result


func _nachbesserung_1() -> void:
	# --- W1: Enter startet nur, wenn es gemeint ist
	var named: Dictionary = await _enter_with_focus("name")
	_check(bool(named.focus_ok) and int(named.jumps) == 0 and bool(named.pending), "W1: Fokus im Rottennamen-Feld + Enter: kein Sprung, Ziel bleibt (%s)" % str(named))
	var tree_case: Dictionary = await _enter_with_focus("tree")
	_check(bool(tree_case.focus_ok) and int(tree_case.jumps) == 0 and bool(tree_case.pending), "W1: Fokus im Systembaum + Enter: kein Sprung (%s)" % str(tree_case))
	var button_case: Dictionary = await _enter_with_focus("button")
	_check(bool(button_case.focus_ok) and int(button_case.jumps) == 0 and bool(button_case.pending), "W1: Fokus auf anderem Knopf + Enter: kein Sprung (%s)" % str(button_case))
	var none_case: Dictionary = await _enter_with_focus("none")
	_check(bool(none_case.focus_ok) and int(none_case.jumps) == 1 and not bool(none_case.pending), "W1: ohne Fokus + Enter: genau ein Sprung (%s)" % str(none_case))
	var start_case: Dictionary = await _enter_with_focus("start")
	_check(bool(start_case.focus_ok) and int(start_case.jumps) == 1 and not bool(start_case.pending), "W1: Fokus auf Start + Enter: genau ein Sprung (%s)" % str(start_case))

	# --- K1: abgelehnter Start behaelt den Kurs
	await _open(_build_state("orbit", "moon_orbit", "satellite_crash"))
	reject_quantum = true
	_click(_marker_point("planet_orbit"))
	await _frames(2)
	_press_start()
	await _frames(2)
	var error_node: Label = view.find_child("CommandError", true, false) as Label
	_check(_quantum_calls().size() == 1, "K1: der Befehlsweg wurde gefragt (%d)" % _quantum_calls().size())
	_check(String(_pending().get("orbit_id", "")) == "planet_orbit" and int(_course().get("line_points", 0)) >= 2, "K1: abgelehnter Start behaelt Ziel und Kurslinie (%s, %s Punkte)" % [str(_pending()), str(_course().get("line_points", 0))])
	_check(error_node != null and error_node.visible and error_node.text.contains("Treibstoff reicht nicht"), "K1: der Grund wird gezeigt (%s)" % (error_node.text if error_node != null else "kein Feld"))
	_check(_start_button() != null and _start_button().visible, "K1: Start bleibt sichtbar")
	reject_quantum = false
	_press_start()
	await _frames(2)
	_check(_pending().is_empty() and int(_course().get("line_points", -1)) == 0 and _quantum_calls().size() == 2, "K1: beim zweiten Versuch (Erfolg) wird geleert (%s, %d Befehle)" % [str(_pending()), _quantum_calls().size()])
	await _close()

	# --- K2: Schiffswechsel / Schiffsgruppenwechsel verwirft das Ziel
	await _open(_build_state("orbit", "moon_orbit", "satellite_crash"))
	_click(_marker_point("planet_orbit"))
	await _frames(2)
	_check(not _pending().is_empty(), "K2: Vorbereitung, Ziel vorgemerkt")
	state.space_travel.craft_id = "ship_two"
	view.call("refresh")
	await _frames(2)
	_check(_pending().is_empty() and int(_course().get("line_points", -1)) == 0, "K2: Schiffswechsel verwirft das Ziel, Kurslinie leer (%s)" % str(_pending()))
	_check(_start_button() == null or not _start_button().visible, "K2: Start ist nach dem Schiffswechsel weg")
	await _close()
	var wing_state := _build_state("orbit", "moon_orbit", "satellite_crash")
	wing_state["space_wings"] = {"wings": {"w1": {"name": "Rotte A", "craft_ids": ["ship"], "leader_craft_id": ""}}}
	await _open(wing_state)
	_click(_marker_point("planet_orbit"))
	await _frames(2)
	_check(not _pending().is_empty(), "K2: Vorbereitung (Rotte), Ziel vorgemerkt")
	view.get("_wing_panel").call("select_wing", "w1")
	view.call("refresh")
	await _frames(2)
	_check(_pending().is_empty() and int(_course().get("line_points", -1)) == 0, "K2: Wechsel der Schiffsgruppe verwirft das Ziel (%s)" % str(_pending()))
	await _close()

	# --- K3/K4: ehrlicher Text
	var multi := _build_state("orbit", "moon_orbit", "fortified_outpost")
	multi.space_travel.fuel_reachability = {"fortified_outpost": {"ok": true, "route_ok": true}, "relay_ridge": {"ok": true, "route_ok": false, "needed_total": 120.0, "available": 80.0}}
	await _open(multi)
	_click(_marker_point("planet_orbit"))
	await _frames(2)
	var shown := String(_course().get("text", ""))
	_check(shown.contains("Bastion Silex") and shown.contains("Treibstoff") and not shown.contains("Reicht nur bis zum Orbit"), "K3: Orbit mit zwei Orten nennt den Ort der Treibstoffzahl, keine Warnung bei gedecktem Hinweg (%s)" % shown.replace("\n", " | "))
	state.campaign.selected_location_id = "relay_ridge"
	view.call("refresh")
	await _frames(2)
	shown = String(_course().get("text", ""))
	_check(shown.contains("Relaisgrat") and not shown.contains("Bastion Silex"), "K3: gewaehlter Ort wechselt, der Text folgt (%s)" % shown.replace("\n", " | "))
	_check(shown.contains("Reicht nur bis zum Orbit – dort tanken oder den Nottankdienst rufen."), "K4: nur die naechste Etappe bezahlbar: zweite Zeile warnt (%s)" % shown.replace("\n", " | "))
	_check(shown.contains("120") and _start_button() != null and not _start_button().disabled, "K4: Zahl steht da, Start bleibt frei")
	await _close()

	# --- K6: Selbst fliegen oeffnet die Orbit-Ansicht auch nach verdeckter Karte
	var manual_state := _build_state("orbit", "moon_orbit", "satellite_crash")
	manual_state.space_travel.orbit_transit_automatic = false
	await _open(manual_state, true)
	_click(_marker_point("planet_orbit"))
	await _frames(2)
	_press_start()
	await _frames(2)
	_check(_quantum_calls().size() == 1 and not bool(_course().get("orbit_view_open", true)), "K6: Start gesendet, Orbit-Ansicht noch zu (%d Befehle)" % _quantum_calls().size())
	view.hide()
	state.space_travel.phase = "quantum"
	state.space_travel.target_orbit_id = "planet_orbit"
	await _frames(3)
	state.space_travel.phase = "orbit"
	state.space_travel.orbit_id = "planet_orbit"
	state.space_travel.orbit_marker_id = "orbit_1"
	state.space_travel.position = _orbit_position("planet_orbit")
	state.space_travel.target_orbit_id = ""
	await _frames(3)
	view.show()
	await _frames(3)
	await create_timer(0.4).timeout
	_check(bool(_course().get("orbit_view_open", false)), "K6: Karte war beim Sprung verdeckt, beim Sichtbarwerden oeffnet sich die Orbit-Ansicht")
	await _close()

	# --- Esc bei vorgemerktem Ziel, mit dem echten Autoload GlobalEscapeMenu
	await _open(_build_state("orbit", "moon_orbit", "satellite_crash"))
	var menu: Node = root.get_node_or_null("GlobalEscapeMenu")
	_check(menu != null and menu.has_method("is_overlay_open"), "Esc: der echte Autoload GlobalEscapeMenu steht im Pruefbaum")
	if menu != null and menu.has_method("is_overlay_open"):
		_click(_marker_point("planet_orbit"))
		await _frames(2)
		_check(not _pending().is_empty() and not bool(menu.call("is_overlay_open")), "Esc: Ziel vorgemerkt, Menue zu")
		_key(KEY_ESCAPE)
		await _frames(2)
		_check(_pending().is_empty() and not bool(menu.call("is_overlay_open")), "Esc 1 (Ziel vorgemerkt): Ziel verworfen, Spielmenue NICHT offen")
		_key(KEY_ESCAPE)
		await _frames(2)
		_check(bool(menu.call("is_menu_visible")), "Esc 2 (nichts vorgemerkt): Spielmenue oeffnet wie bisher")
		view.call("_preview_jump", "planet_orbit", "orbit_1")
		await _frames(2)
		_key(KEY_ENTER)
		await _frames(2)
		_check(_quantum_calls().is_empty() and not _pending().is_empty(), "Enter bei offenem Spielmenue startet nichts, Ziel bleibt")
		# Enter bedient im Menue den fokussierten Menueknopf (kann es schliessen): fuer die Esc-Pruefung neu oeffnen.
		if not bool(menu.call("is_overlay_open")):
			menu.call("open_menu")
		await _frames(2)
		_key(KEY_ESCAPE)
		await _frames(2)
		_check(not bool(menu.call("is_overlay_open")) and not _pending().is_empty(), "Esc bei offenem Spielmenue schliesst das Menue, das Ziel bleibt (Menue offen %s, Ziel %s)" % [str(menu.call("is_overlay_open")), str(_pending())])
		_key(KEY_ESCAPE)
		await _frames(2)
		_check(_pending().is_empty() and not bool(menu.call("is_overlay_open")), "Esc danach verwirft das Ziel, Menue bleibt zu (Menue offen %s, Ziel %s)" % [str(menu.call("is_overlay_open")), str(_pending())])
		if bool(menu.call("is_overlay_open")):
			menu.call("close_menu")
	await _close()
