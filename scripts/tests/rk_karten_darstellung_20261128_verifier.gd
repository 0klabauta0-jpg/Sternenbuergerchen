extends SceneTree
## Paket RK (28.11.2026), kopflos:
##  (1) Sternkarte: ferner Ort hat Hinweis "Doppelklick: Kurs setzen" (Tooltip der Karte und des Markers) und die Statuszeile nennt nach dem
##      Doppelklick "Kurs zu <Ort> gesetzt – Start drücken".
##  (3) Anflugplaner mit zwischengespeicherter Suche liefert dieselben Ziele wie die fruehere Sortier-Suche; build_cached == build.
##  (2) OM-Karte: Rechtsklick = Kurs, Linksklick ins Leere = nichts, Rahmen erst ab Mindestgroesse, Hinweis sichtbar.
const SCREEN = preload("res://scripts/ui/star_map_screen.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const AREA = preload("res://scripts/core/space_area_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
const PLAN = preload("res://scripts/mission/orbit_auto_transit_planner.gd")
const CANVAS = preload("res://scripts/ui/orbit_area_canvas.gd")
var passed := 0
var failed := 0
var definition: Dictionary = {}
var site_data: Array = []
var state: Dictionary = {}
var calls: Array = []
var view: Control
var canvas: Control


func _init() -> void:
	call_deferred("_run")


func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		print("FAIL " + label)


func _frames(count: int = 3) -> void:
	for i in count:
		await process_frame


func _run() -> void:
	_planner_checks()
	await _om_checks()
	await _starmap_checks()
	print("RK_KARTEN_DARSTELLUNG_20261128 passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)


# ---------------------------------------------------------------- Punkt 3: Planer
## Die fruehere Suche (Kandidaten sortieren), unveraendert uebernommen als Vergleich.
func _reference_plan(area_id: String, start: Vector2i, direction: String, footprint: Array, blocked: Array) -> Dictionary:
	var layout: Dictionary = LAYOUT.build(area_id.trim_prefix("orbit_approach:").uri_decode())
	var area := {"coordinate_frame": "local", "space_area_id": area_id}
	var mask := {}
	for cell: Vector2i in blocked: mask[cell] = true
	for offset: Vector2i in layout.body_cells: mask[GRID.from_offset(offset)] = true
	var start_offset: Vector2i = GRID.to_offset(start)
	var candidates: Array[Vector2i] = []
	if direction == "inbound":
		candidates.assign(layout.gate_cells)
	else:
		for x in range(layout.entry_band.position.x, layout.entry_band.end.x): candidates.append(Vector2i(x, layout.entry_band.end.y - 2))
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := absi(a.x - start_offset.x); var db := absi(b.x - start_offset.x)
		if da != db: return da < db
		return a.x < b.x if a.x != b.x else a.y < b.y)
	for offset in candidates:
		var target: Vector2i = GRID.from_offset(offset)
		var clear := true
		for center: Vector2i in HEX.line(start, target):
			for part: Vector2i in footprint:
				var cell := center + part
				if not AREA.contains(cell, area) or mask.has(cell):
					clear = false; break
			if not clear: break
		if clear: return {"ok": true, "target_hex": target, "direction": direction}
	return {"ok": false, "reason": "route_blocked"}


func _planner_checks() -> void:
	var fresh: Dictionary = LAYOUT.build("moon")
	var cached: Dictionary = LAYOUT.build_cached("moon")
	_check(cached.get("ok", false) and cached.body_cells == fresh.body_cells and cached.gate_cells == fresh.gate_cells and cached.revision == fresh.revision, "build_cached liefert dasselbe wie build")
	_check(LAYOUT.build_cached("moon") == cached and not LAYOUT.build_cached("").get("ok", true), "build_cached: zweiter Aufruf gleich, ungueltiger Name wird abgewiesen")
	var area_id := "orbit_approach:moon"
	var small: Array = [Vector2i.ZERO]
	var big: Array = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 1)]
	var blocked_zone: Array = []
	for x in range(100, 140):
		for y in range(4, 8): blocked_zone.append(GRID.from_offset(Vector2i(x, y)))
	var starts: Array = [Vector2i(50, 240), Vector2i(4, 245), Vector2i(256, 100), Vector2i(500, 230), Vector2i(120, 12), Vector2i(300, 250)]
	var equal := true
	var detail := ""
	var count := 0
	for start_offset: Vector2i in starts:
		for direction in ["inbound", "outbound"]:
			for footprint in [small, big]:
				for blocked in [[], blocked_zone]:
					var start: Vector2i = GRID.from_offset(start_offset)
					var expected := _reference_plan(area_id, start, direction, footprint, blocked)
					var actual: Dictionary = PLAN.plan(area_id, start, direction, footprint, blocked, [])
					count += 1
					if bool(actual.get("ok", false)) != bool(expected.ok) or (expected.ok and actual.target_hex != expected.target_hex):
						equal = false
						detail = "%s %s fp=%d blocked=%d: erwartet %s, bekommen %s" % [str(start_offset), direction, footprint.size(), blocked.size(), str(expected), str(actual)]
	_check(equal, "Planer: %d Faelle wie die fruehere Sortier-Suche %s" % [count, detail])
	_check(not PLAN.plan(area_id, GRID.from_offset(Vector2i(50, 240)), "inbound", small, [], [Vector2i.ZERO]).get("ok", true), "Planer: Kontakt weist weiter ab")
	_check(not PLAN.plan("orbit_approach:", GRID.from_offset(Vector2i(50, 240)), "inbound", small, [], []).get("ok", true), "Planer: ungueltiger Bereich weist weiter ab")
	# Zweiter Aufruf aus dem Zwischenspeicher: gleiches Ergebnis.
	var start_a: Vector2i = GRID.from_offset(Vector2i(50, 240))
	_check(PLAN.plan(area_id, start_a, "inbound", small, [], []) == PLAN.plan(area_id, start_a, "inbound", small, [], []), "Planer: wiederholter Aufruf liefert dasselbe")


# ---------------------------------------------------------------- Punkt 2: OM-Karte
func _area_snapshot(position: Vector2) -> Dictionary:
	var area_id := "orbit_approach:moon"
	return {"ok": true, "space_area_id": area_id, "actors": [{"craft_id": "a", "model_id": "", "footprint_cells": [],
		"flight": {"craft_id": "a", "coordinate_frame": "local", "space_area_id": area_id, "motion_mode": "tactical", "position_plane": position, "heading_rad": 0.0}}]}


func _button(c: Control, index: int, pressed: bool, point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	event.position = point
	c._gui_input(event)


func _drag(c: Control, from: Vector2, to: Vector2) -> void:
	_button(c, MOUSE_BUTTON_LEFT, true, from)
	var motion := InputEventMouseMotion.new()
	motion.position = to
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	c._gui_input(motion)
	_button(c, MOUSE_BUTTON_LEFT, false, to)


func _om_checks() -> void:
	var c: Control = CANVAS.new()
	root.add_child(c)
	c.size = Vector2(900, 520)
	await process_frame
	var ship_plane: Vector2 = HEX.axial_to_plane(Vector2(GRID.from_offset(Vector2i(256, 100))))
	c.set_projection(_area_snapshot(ship_plane), "a", {"name": "Mond"})
	var moves: Array = []
	var singles: Array = []
	var boxes: Array = []
	c.move_requested.connect(func(id: String, hex: Vector2i): moves.append([id, hex]))
	c.craft_selected.connect(func(id: String): singles.append(id))
	c.crafts_box_selected.connect(func(ids: Array, additive: bool): boxes.append([ids, additive]))
	var ship_screen: Vector2 = c.plane_to_screen(ship_plane)
	var empty_screen: Vector2 = c.hex_to_screen(GRID.from_offset(Vector2i(300, 120)))
	# Linksklick ins Leere
	_button(c, MOUSE_BUTTON_LEFT, true, empty_screen)
	_button(c, MOUSE_BUTTON_LEFT, false, empty_screen)
	_check(moves.is_empty() and singles.is_empty() and boxes.is_empty(), "Linksklick ins Leere: nichts geht los, Auswahl bleibt")
	# Rechtsklick
	_button(c, MOUSE_BUTTON_RIGHT, true, empty_screen)
	_button(c, MOUSE_BUTTON_RIGHT, false, empty_screen)
	_check(moves.size() == 1 and moves[0][0] == "a","Rechtsklick setzt den Kurs fuer das gewaehlte Schiff")
	# Rechtsklick neben ein Schiff setzt Kurs (statt zu waehlen)
	moves.clear()
	_button(c, MOUSE_BUTTON_RIGHT, true, ship_screen + Vector2(40, 30))
	_button(c, MOUSE_BUTTON_RIGHT, false, ship_screen + Vector2(40, 30))
	_check(moves.size() == 1 and singles.is_empty(), "Rechtsklick neben dem Schiff: Kurs, keine Auswahl")
	# Verwackelter Klick (unter der Mindestgroesse) bleibt ein Klick
	moves.clear()
	_drag(c, empty_screen, empty_screen + Vector2(7, 6))
	_check(not c.is_box_selecting() and boxes.is_empty() and moves.is_empty(), "Verwackelter Linksklick (7 px) ist kein Rahmen, loescht die Auswahl nicht")
	_drag(c, ship_screen + Vector2(1, 1), ship_screen + Vector2(5, 3))
	_check(singles == ["a"] and boxes.is_empty(), "Verwackelter Klick auf das Schiff waehlt es")
	# Echter Rahmen
	singles.clear()
	_drag(c, ship_screen - Vector2(50, 50), ship_screen + Vector2(50, 50))
	_check(boxes.size() == 1 and boxes[0][0] == ["a"] and moves.is_empty(), "Rahmen ab Mindestgroesse waehlt das Schiff")
	# Mittlere Taste und Rad unveraendert
	var zoom_before := float(c.get("_zoom"))
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = ship_screen
	c._gui_input(wheel)
	_check(float(c.get("_zoom")) > zoom_before, "Mausrad zoomt weiter")
	_check(String(CANVAS.HINT_TEXT).contains("Rechtsklick") and String(CANVAS.HINT_TEXT).contains("Linksklick"), "Bedienhinweis nennt beide Tasten")
	c.queue_free()
	await process_frame


# ---------------------------------------------------------------- Punkt 1: Sternkarte
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


func _command(operation: String, payload: Dictionary = {}) -> Dictionary:
	calls.append({"operation": operation, "payload": payload.duplicate(true)})
	return {"ok": true}


func _snapshot() -> Dictionary:
	return state.duplicate(true)


func _mouse(point: Vector2, pressed: bool, double_click: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.double_click = double_click
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(event, true)


func _starmap_checks() -> void:
	root.size = Vector2i(1280, 720)
	definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/locations.json"))
	var rows: Array = raw.values() if raw is Dictionary else Array(raw)
	if raw is Dictionary and raw.has("locations"):
		rows = raw.locations.values() if raw.locations is Dictionary else Array(raw.locations)
	for row in rows:
		if row is Dictionary and row.has("id"):
			site_data.append({"id": String(row.id), "name": String(row.get("name", row.id)), "region_position": row.get("region_position", [])})
	state = _build_state("orbit", "moon_orbit", "satellite_crash")
	view = SCREEN.new()
	root.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.configure(_snapshot, _command)
	await _frames(4)
	canvas = view.find_child("SystemMap", true, false)
	canvas.call("reset_camera")
	await _frames(2)
	var target_id := "fortified_outpost"
	var button: Button = canvas.get_node_or_null("PlanetSite_" + target_id)
	_check(button != null and button.disabled, "Ferner Ort: Marker vorhanden und gesperrt")
	if button == null:
		return
	# Der Name im Tooltip kommt aus dem Anzeige-Katalog (nicht aus der Rohdatei): nur pruefen, dass eine Namenszeile vor dem Hinweis steht.
	var tip_lines: PackedStringArray = button.tooltip_text.split("\n")
	_check(tip_lines.size() >= 2 and not tip_lines[0].strip_edges().is_empty() and tip_lines[1] == "Doppelklick: Kurs setzen", "Ferner Ort: Marker-Tooltip nennt Namen und Doppelklick (%s)" % button.tooltip_text.replace("\n", " | "))
	var center: Vector2 = button.get_global_rect().get_center()
	var local_center: Vector2 = center - canvas.get_global_rect().position
	_check(String(canvas.call("_get_tooltip", local_center)).split("\n")[0] == tip_lines[0], "Karten-Tooltip und Marker-Tooltip nennen denselben Namen")
	_check(String(canvas.call("_get_tooltip", local_center)).contains("Doppelklick: Kurs setzen"), "Ferner Ort: Karten-Tooltip am Marker sagt \"Doppelklick: Kurs setzen\"")
	_check(not String(canvas.call("_get_tooltip", Vector2(-50, -50))).contains("Doppelklick"), "Leere Stelle: kein Doppelklick-Hinweis")
	var before := String(view.call("get_ui_snapshot").status)
	_check(not before.contains("gesetzt"), "Vor dem Doppelklick keine Kurs-Meldung")
	_mouse(center, true, true)
	_mouse(center, false)
	await _frames(3)
	var status := String(view.call("get_ui_snapshot").status)
	var place: String = String(site_data.filter(func(e): return e.id == target_id)[0].name)
	_check(status.contains("Kurs zu") and status.contains("gesetzt") and status.contains("Start drücken"), "Nach dem Doppelklick: Statuszeile \"Kurs zu ... gesetzt – Start drücken\" (%s)" % status.replace("\n", " | "))
	_check(not Dictionary(view.call("get_course_snapshot").get("pending", {})).is_empty(), "Kurs ist vorgemerkt")
	# Wird der Kurs verworfen, verschwindet die Meldung nach dem naechsten Auffrischen.
	view.call("_discard_preview")
	view.call("refresh")
	await _frames(2)
	_check(not String(view.call("get_ui_snapshot").status).contains("Start drücken"), "Ohne vorgemerkten Kurs keine Kurs-Meldung mehr (%s)" % place)
	view.queue_free()
	await process_frame
