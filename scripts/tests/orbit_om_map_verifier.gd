extends SceneTree
## Kopflos: OM-Karte (Paket D) – Titel statt Systemliste, Anflugzone ueber die ganze Breite, Schiffskarten mit Ziehen und Ablegen,
## Rahmenauswahl, die den einfachen Klick (Kurs) nicht verschluckt.
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const PLAN = preload("res://scripts/mission/orbit_auto_transit_planner.gd")
const CANVAS = preload("res://scripts/ui/orbit_area_canvas.gd")
const PANEL = preload("res://scripts/ui/space_wing_panel.gd")
const SCREEN = preload("res://scripts/ui/star_map_screen.gd")
const DISPLAY = preload("res://scripts/mission/campaign_display_catalog.gd")
var checks := 0
var failures := 0
var wings: Dictionary = {}
var revision := 1
var calls: Array = []
var fail_assign_for := ""
var moves: Array = []
var selected_one: Array = []
var selected_box: Array = []

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", text)

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	_layout_checks()
	await _canvas_checks()
	await _panel_checks()
	await _screen_checks()
	print("ORBIT_OM_MAP checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

# ---------------------------------------------------------------- Schritt 2: Anflugzone
func _layout_checks() -> void:
	var built: Dictionary = LAYOUT.build("moon")
	check(bool(built.get("ok", false)) and built.revision == "orbit_approach_limb_v1", "Layout baut, Revision unveraendert (Speicherformat)")
	var gates: Array = built.gate_cells
	var per_column := {}
	var gate_set := {}
	for cell: Vector2i in gates:
		per_column[cell.x] = int(per_column.get(cell.x, 0)) + 1
		gate_set[cell] = true
	var margin: int = LAYOUT.ZONE_EDGE_MARGIN
	var wide_ok := true
	var min_depth := 999
	var max_depth := 0
	for column in range(margin, LAYOUT.MAP_SIZE.x - margin):
		if not per_column.has(column): wide_ok = false
		else:
			min_depth = mini(min_depth, int(per_column[column]))
			max_depth = maxi(max_depth, int(per_column[column]))
	check(wide_ok, "Zone reicht ueber die ganze Kartenbreite (ausser dem Randstreifen von %d Spalten)" % margin)
	check(min_depth >= 3 and max_depth <= 5 and LAYOUT.ZONE_DEPTH in [3, 4], "Zone ist 3 bis 4 Felder tief (Tiefe %d bis %d)" % [min_depth, max_depth])
	var edge_free := true
	for cell: Vector2i in gates:
		if (cell.x < margin or cell.x >= LAYOUT.MAP_SIZE.x - margin) and not (cell.x >= (LAYOUT.MAP_SIZE.x - LAYOUT.LIMB_WIDTH) / 2 and cell.x < (LAYOUT.MAP_SIZE.x + LAYOUT.LIMB_WIDTH) / 2): edge_free = false
		if cell.y < 1 or cell.y > 8: edge_free = false
	check(edge_free, "Keine Torzelle im Randstreifen und keine in Zeile 0: Fussabdruecke passen auf die Karte")
	check(gate_set.size() == gates.size(), "Keine Zelle doppelt in der Zone")
	var body_set := {}
	for cell: Vector2i in built.body_cells: body_set[cell] = true
	var overlap := false
	var outside := false
	for cell: Vector2i in gates:
		if body_set.has(cell): overlap = true
		if not LAYOUT.contains_local_cell(cell): outside = true
	check(not overlap and not outside, "Zone liegt ausserhalb des Planetenkoerpers und innerhalb der Karte")
	# Bisherige Torzellen gelten weiter: erste freie Zelle unter dem Bogen, 256 Spalten, in alter Reihenfolge am Anfang.
	var old_ok := true
	var index := 0
	for column in range((LAYOUT.MAP_SIZE.x - LAYOUT.LIMB_WIDTH) / 2, (LAYOUT.MAP_SIZE.x + LAYOUT.LIMB_WIDTH) / 2):
		if gates[index] != Vector2i(column, ceili(LAYOUT.limb_depth_at(column))): old_ok = false
		index += 1
	check(old_ok, "Die bisherigen 256 Torzellen stehen unveraendert am Anfang der Zone")
	var expected_body := 0
	for column in range((LAYOUT.MAP_SIZE.x - LAYOUT.LIMB_WIDTH) / 2, (LAYOUT.MAP_SIZE.x + LAYOUT.LIMB_WIDTH) / 2): expected_body += ceili(LAYOUT.limb_depth_at(column))
	check(built.body_cells.size() == expected_body and built.entry_band == LAYOUT.ENTRY_BAND, "Planetenkoerper und Eintrittsband unveraendert")
	# Planer: ein Schiff weit links findet jetzt ein Tor in seiner Naehe statt erst in Spalte 128.
	var start: Vector2i = GRID.from_offset(Vector2i(50, 240))
	var plan: Dictionary = PLAN.plan("orbit_approach:moon", start, "inbound", [Vector2i.ZERO], [], [])
	var target_offset: Vector2i = GRID.to_offset(plan.get("target_hex", Vector2i.ZERO)) if plan.get("ok", false) else Vector2i(-1, -1)
	check(bool(plan.get("ok", false)) and target_offset.x == 50 and target_offset.y >= LAYOUT.ZONE_TOP_ROW and target_offset.y < LAYOUT.ZONE_TOP_ROW + LAYOUT.ZONE_DEPTH, "Anflug-Planer waehlt das Tor in der Naehe (Spalte 50), nicht erst unter dem Bogen: %s" % str(target_offset))
	# Ecke unten links (dort tritt ein Schiff ein): mit mehrfeldrigem Fussabdruck muss das Ziel ganz auf der Karte liegen.
	var footprint: Array = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 1)]
	var corner_plan: Dictionary = PLAN.plan("orbit_approach:moon", GRID.from_offset(Vector2i(4, 245)), "inbound", footprint, [], [])
	var corner_ok := bool(corner_plan.get("ok", false))
	if corner_ok:
		var target: Vector2i = corner_plan.target_hex
		for part: Vector2i in footprint:
			if not LAYOUT.contains_local_cell(GRID.to_offset(target + part)): corner_ok = false
		check(corner_ok and GRID.to_offset(target).x >= LAYOUT.ZONE_EDGE_MARGIN, "Planer aus der linken Ecke: Ziel mit ganzem Fussabdruck auf der Karte (%s)" % str(GRID.to_offset(target)))
	else:
		check(false, "Planer aus der linken Ecke findet ein Ziel (%s)" % str(corner_plan))

# ---------------------------------------------------------------- Schritt 4: Rahmenauswahl auf der OM-Karte
func _area_snapshot(position: Vector2, body_id: String = "moon") -> Dictionary:
	var area_id := "orbit_approach:" + body_id
	return {"ok": true, "space_area_id": area_id, "actors": [{"craft_id": "a", "model_id": "", "footprint_cells": [],
		"flight": {"craft_id": "a", "coordinate_frame": "local", "space_area_id": area_id, "motion_mode": "tactical", "position_plane": position, "heading_rad": 0.0}}]}

func _mouse(canvas: Control, pressed: bool, point: Vector2, ctrl: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.ctrl_pressed = ctrl
	canvas._gui_input(event)

func _motion(canvas: Control, point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	canvas._gui_input(event)

func _canvas_checks() -> void:
	var canvas: Control = CANVAS.new()
	root.add_child(canvas)
	canvas.size = Vector2(900, 520)
	await process_frame
	var ship_plane: Vector2 = HEX.axial_to_plane(Vector2(GRID.from_offset(Vector2i(256, 100))))
	canvas.set_projection(_area_snapshot(ship_plane), "a", {"name": "Mond"})
	check(canvas.get_selected_craft_id() == "a", "Schiff a ist im Orbitbereich gewaehlt")
	canvas.move_requested.connect(func(id: String, hex: Vector2i): moves.append([id, hex]))
	canvas.craft_selected.connect(func(id: String): selected_one.append(id))
	canvas.crafts_box_selected.connect(func(ids: Array, additive: bool): selected_box.append([ids, additive]))
	var ship_screen: Vector2 = canvas.plane_to_screen(ship_plane)
	var empty_screen: Vector2 = canvas.hex_to_screen(GRID.from_offset(Vector2i(300, 120)))
	# Einfacher Klick auf freie Flaeche: Kurs (erst beim Loslassen).
	_mouse(canvas, true, empty_screen)
	check(moves.is_empty(), "Druck allein setzt noch keinen Kurs")
	_mouse(canvas, false, empty_screen)
	check(moves.size() == 1 and moves[0][0] == "a", "Einfacher Klick setzt den Kurs")
	# Kleine Bewegung (unter der Schwelle) bleibt ein Klick.
	moves.clear()
	_mouse(canvas, true, empty_screen)
	_motion(canvas, empty_screen + Vector2(3, 2))
	check(not canvas.is_box_selecting(), "Unter der Schwelle kein Rahmen")
	_mouse(canvas, false, empty_screen + Vector2(3, 2))
	check(moves.size() == 1 and selected_box.is_empty(), "Kleine Bewegung = Klick, kein Rahmen")
	# Rahmen um das Schiff: Auswahl, kein Kurs.
	moves.clear()
	var corner_a: Vector2 = ship_screen - Vector2(60, 60)
	var corner_b: Vector2 = ship_screen + Vector2(60, 60)
	_mouse(canvas, true, corner_a)
	_motion(canvas, corner_b)
	check(canvas.is_box_selecting(), "Ab der Schwelle beginnt der Rahmen")
	_mouse(canvas, false, corner_b)
	check(selected_box.size() == 1 and selected_box[0][0] == ["a"] and selected_box[0][1] == false and moves.is_empty() and not canvas.is_box_selecting(), "Rahmen waehlt Schiff a, setzt keinen Kurs")
	# Rahmen daneben: leere Auswahl, kein Kurs.
	selected_box.clear()
	_mouse(canvas, true, empty_screen + Vector2(40, 40))
	_motion(canvas, empty_screen + Vector2(120, 100))
	_mouse(canvas, false, empty_screen + Vector2(120, 100))
	check(selected_box.size() == 1 and selected_box[0][0].is_empty() and moves.is_empty(), "Leerer Rahmen: leere Auswahl, kein Kurs")
	# Klick auf das Schiff: waehlt es, setzt keinen Kurs.
	_mouse(canvas, true, ship_screen + Vector2(2, 2))
	_mouse(canvas, false, ship_screen + Vector2(2, 2))
	check(selected_one == ["a"] and moves.is_empty(), "Klick auf ein Schiff waehlt es, ohne Kurs")
	# Strg-Klick auf das Schiff: Auswahl ergaenzen.
	selected_box.clear()
	_mouse(canvas, true, ship_screen, true)
	_mouse(canvas, false, ship_screen, true)
	check(selected_box.size() == 1 and selected_box[0][1] == true, "Strg-Klick ergaenzt die Auswahl")
	canvas.queue_free()
	await process_frame

# ---------------------------------------------------------------- Schritt 3: Schiffskarten
func _runtime() -> Dictionary:
	return {"crafts": [{"craft_id": "a", "display_name": "Alpha"}, {"craft_id": "b", "display_name": "Bravo"}, {"craft_id": "c", "display_name": "Charlie"}],
		"space_wings": {"revision": revision, "wings": wings.duplicate(true)}}

func _command(_operation: String, payload: Dictionary) -> Dictionary:
	var command: Dictionary = payload.command
	var op := String(command.operation)
	var data: Dictionary = command.payload
	calls.append([op, data.duplicate(true)])
	match op:
		"wing_create": wings[data.wing_id] = {"name": data.wing_id, "craft_ids": [], "leader_craft_id": ""}
		"wing_assign":
			if fail_assign_for == String(data.wing_id): return {"ok": false, "reason": "pilot_missing"}
			wings[data.wing_id].craft_ids.append(data.craft_id)
			if String(wings[data.wing_id].leader_craft_id).is_empty(): wings[data.wing_id].leader_craft_id = data.craft_id
		"wing_remove":
			wings[data.wing_id].craft_ids.erase(data.craft_id)
			if wings[data.wing_id].craft_ids.is_empty(): wings.erase(data.wing_id)
		"wing_rename": wings[data.wing_id].name = data.name
	revision += 1
	return {"ok": true}

func _ops() -> Array:
	var result: Array = []
	for entry in calls: result.append(entry[0])
	return result

func _panel_checks() -> void:
	wings = {"w1": {"name": "solo:a", "craft_ids": ["a"], "leader_craft_id": "a"}, "w2": {"name": "solo:b", "craft_ids": ["b"], "leader_craft_id": "b"}}
	var panel: Control = PANEL.new()
	root.add_child(panel)
	panel.configure(func(): return _runtime(), _command)
	await process_frame
	check(panel.find_children("*", "OptionButton", true, false).is_empty(), "Keine Auswahlfelder (OptionButton) mehr in der Schiffsliste")
	check(panel.find_child("ShipCard_a", true, false) != null and panel.find_child("ShipCard_b", true, false) != null, "Schiffe als Karten (ShipCard_*)")
	var free_box := panel.find_child("WingFreeShips", true, false)
	check(free_box != null and free_box.find_child("ShipCard_c", true, false) != null, "Schiff ohne Gruppe steht in der Ablage 'Ohne Gruppe'")
	check(panel.find_children("WingTab_*", "Button", true, false).size() == 2, "Reiter fuer beide Gruppen bleiben")
	var drag := {"kind": "space_craft", "craft_id": "a", "wing_id": "w1"}
	check(panel.call("_can_drop_craft", Vector2.ZERO, drag) and not panel.call("_can_drop_craft", Vector2.ZERO, {"kind": "x"}) and not panel.call("_can_drop_craft", Vector2.ZERO, "text"), "Nur Schiffskarten lassen sich ablegen")
	# Ablegen auf eine andere Gruppe: wing_remove, dann wing_assign.
	calls.clear()
	panel.call("_drop_craft", Vector2.ZERO, drag, "w2")
	check(_ops() == ["wing_remove", "wing_assign"] and calls[0][1] == {"wing_id": "w1", "craft_id": "a"} and calls[1][1] == {"wing_id": "w2", "craft_id": "a"}, "Ablegen auf Gruppe = wing_remove + wing_assign (%s)" % str(_ops()))
	check(wings.has("w2") and wings.w2.craft_ids == ["b", "a"] and not wings.has("w1"), "Zustand: a steht jetzt in w2")
	# Ablegen auf 'Neue Schiffsgruppe'.
	calls.clear()
	panel.call("_drop_craft", Vector2.ZERO, {"kind": "space_craft", "craft_id": "a", "wing_id": "w2"}, PANEL.NEW_WING)
	check(_ops() == ["wing_remove", "wing_create", "wing_assign"], "Neue Gruppe = wing_remove, wing_create, wing_assign (%s)" % str(_ops()))
	check(wings.size() == 2 and wings.w2.craft_ids == ["b"], "Zustand: neue Gruppe mit a, w2 nur noch mit b")
	var new_id := ""
	for id in wings:
		if id != "w2": new_id = String(id)
	# Ablegen auf 'Ohne Gruppe'.
	calls.clear()
	panel.call("_drop_craft", Vector2.ZERO, {"kind": "space_craft", "craft_id": "b", "wing_id": "w2"}, PANEL.FREE_SHIPS)
	check(_ops() == ["wing_remove"] and not wings.has("w2"), "Ohne Gruppe = nur wing_remove")
	# Gleiche Gruppe: nichts passiert.
	calls.clear()
	panel.call("_drop_craft", Vector2.ZERO, {"kind": "space_craft", "craft_id": "a", "wing_id": new_id}, new_id)
	check(calls.is_empty(), "Ablegen auf die eigene Gruppe sendet nichts")
	# Scheitert die Zuordnung: das Schiff kommt in seine alte Gruppe zurueck, der Grund steht im Rueckmeldefeld.
	wings["w9"] = {"name": "Neun", "craft_ids": ["c"], "leader_craft_id": "c"}
	revision += 1
	panel.call("refresh", _runtime())
	fail_assign_for = "w9"
	calls.clear()
	panel.call("_drop_craft", Vector2.ZERO, {"kind": "space_craft", "craft_id": "a", "wing_id": new_id}, "w9")
	fail_assign_for = ""
	check(wings.has(new_id) and wings[new_id].craft_ids == ["a"] and wings.w9.craft_ids == ["c"], "Abgelehnte Zuordnung: a bleibt in seiner Gruppe (%s)" % str(_ops()))
	check(not String(panel.call("get_feedback")).is_empty(), "Abgelehnte Zuordnung: Grund steht im Rueckmeldefeld")
	# Volle Gruppe: gar nicht erst entfernen.
	wings["wf"] = {"name": "Voll", "craft_ids": ["x1", "x2", "x3", "x4", "x5", "x6"], "leader_craft_id": "x1"}
	revision += 1
	panel.call("refresh", _runtime())
	calls.clear()
	panel.call("_drop_craft", Vector2.ZERO, {"kind": "space_craft", "craft_id": "a", "wing_id": new_id}, "wf")
	check(calls.is_empty() and String(panel.call("get_feedback")).contains("sechs"), "Volle Gruppe: keine Befehle, Hinweis im Rueckmeldefeld")
	panel.queue_free()
	await process_frame

# ---------------------------------------------------------------- Schritt 1: Titel statt Systemliste, Liste links
func _screen_checks() -> void:
	root.size = Vector2i(1500, 900)
	wings = {"w1": {"name": "solo:a", "craft_ids": ["a"], "leader_craft_id": "a"}, "w2": {"name": "solo:b", "craft_ids": ["b"], "leader_craft_id": "b"}}
	var area := _area_snapshot(HEX.axial_to_plane(Vector2(GRID.from_offset(Vector2i(256, 100)))), "moon")
	var runtime := _runtime()
	runtime["campaign"] = {"selected_location_id": "homebase", "selected_job_id": "", "locations": {}, "jobs": {}}
	runtime["space_travel"] = {"phase": "orbit", "craft_id": "a", "orbit_id": "moon_orbit", "position": [0.25, 0.62], "target_orbit_id": "", "origin_position": [0.25, 0.62],
		"progress": 0.0, "orbit_transit_automatic": true, "orbit_transit_available": false}
	var view: Control = SCREEN.new()
	root.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.configure(func(): return runtime.duplicate(true), func(_op, _payload = {}): return {"ok": true}, func(_craft_id: String): return area.duplicate(true))
	for i in 4: await process_frame
	var tree: Control = view.get("_navigation")
	var caption: Label = view.find_child("SystemCaption", true, false)
	var column: Control = view.find_child("OrbitShipColumn", true, false)
	var wing_panel: Control = view.find_child("SpaceWingPanel", true, false)
	check(tree.visible and caption.text.begins_with("SYSTEM") and column != null and not column.visible, "Systemansicht: Systemliste und Systemzeile wie bisher, Schiffsspalte aus")
	check(wing_panel != null and wing_panel.get_parent() == view.get("_details_information"), "Systemansicht: Schiffsgruppen im Zielfeld rechts")
	view.set("_orbit_craft_id", "a")
	view.call("_refresh_orbit_projection")
	view.call("_show_orbit_view")
	for i in 3: await process_frame
	check(bool(view.get("_orbit_visible")), "Orbit-Ansicht ist offen")
	check(not tree.visible and not view.get("_navigation_toggle").visible, "OM-Karte: keine Systemliste links")
	check(caption.text == DISPLAY.body_name("moon", {}) + " Orbit", "OM-Karte: oben der Name des OM, z. B. \"Vespa Orbit\" (hier \"%s\")" % caption.text)
	check(column.visible and wing_panel.get_parent() == view.get("_orbit_left_box"), "OM-Karte: Schiffs-/Gruppenliste links")
	check(view.find_child("ShipCard_a", true, false) != null and view.find_child("ShipCard_a", true, false).is_visible_in_tree(), "OM-Karte: Schiffskarten sichtbar")
	view.call("_show_system_view")
	for i in 2: await process_frame
	check(tree.visible and caption.text.begins_with("SYSTEM") and not column.visible and wing_panel.get_parent() == view.get("_details_information"), "Zurueck zur Systemansicht: alles wie vorher")
	view.queue_free()
	await process_frame
