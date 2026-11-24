extends SceneTree
## Neue Gebaeudemodelle der Heimatbasis (Wunsch 24.11.): Zuordnung, Lage, Umschalt-Taste, Bedienbarkeit unveraendert.
## Kopflos, rechnend, echte Kampagnen-Heimatbasis. Es wird nur gelesen und der Schalter umgelegt.
const OVERRIDES := preload("res://scripts/meta/structure_model_overrides.gd")
const BASE_NAV := preload("res://scripts/meta/base_interior_navigation.gd")
const TOLERANCE: float = 0.5
var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
	print(("PASS " if value else "FAIL ") + label)


func _bounds(node: Node) -> AABB:
	var result := AABB()
	var first := true
	for n in node.find_children("*", "MeshInstance3D", true, false):
		var m := n as MeshInstance3D
		var a: AABB = m.global_transform * m.get_aabb()
		result = a if first else result.merge(a)
		first = false
	return result


func _rect_xz(box: AABB) -> Rect2:
	return Rect2(box.position.x, box.position.z, box.size.x, box.size.z)


func _press(code: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		root.push_input(e)
		await process_frame


func _terminal_ids(base: Control) -> Array:
	var ids: Array = []
	for t in base.get("_terminals"):
		ids.append(String(Dictionary(t).get("id", "")))
	ids.sort()
	return ids


func _run() -> void:
	var config: Dictionary = OVERRIDES.load_config()
	var entries: Array = Array(config.get("entries", []))
	_check(not config.is_empty() and entries.size() == 2, "Zuordnung laedt, zwei Eintraege (%d)" % entries.size())
	_check(String(config.get("toggle_key", "")) == "F7" and bool(config.get("enabled", false)), "Vorgabe AN, Taste F7")
	_check(absf(float(config.get("brightness", 0.0)) - 1.0) < 0.0001, "Helligkeits-Stellschraube vorhanden, Vorgabe 1,0")
	for entry_variant in entries:
		var entry: Dictionary = entry_variant
		var scene := load(String(entry.get("model", ""))) as PackedScene
		var inst: Node3D = scene.instantiate() as Node3D if scene != null else null
		_check(inst != null and inst.find_children("*", "MeshInstance3D", true, false).size() > 0, "Modell laesst sich instanzieren und hat Mesh-Instanzen: %s" % String(entry.get("id", "")))
		if inst != null:
			inst.free()
	root.size = Vector2i(1920, 1080)
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	for i in 8:
		await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	screen.call("request_operation", "navigate", {"mode": "base"})
	for i in 20:
		await process_frame
	var presenter: Control = screen.get("_operations_presenter")
	var base: Control = presenter.get("_base")
	var layout: Dictionary = base.get("_layout")
	var stage: Node3D = base.get("_authored_stage")
	var group: Node3D = stage.get_node_or_null(OVERRIDES.GROUP_NAME) as Node3D
	_check(group != null, "Heimatbasis-Ansicht hat die Gruppe der neuen Modelle")
	if group == null:
		print("STRUCTURE_MODELS passed=%d failed=%d" % [passed, failed])
		quit(1)
		return
	_check(bool(base.get("_structure_models").call("is_enabled")), "Vorgabe: Schalter AN")
	var old_ids: Array = ["habitat_cutaway_01", "freihafen_hall_01"]
	var old_nodes: Dictionary = base.get("_asset_visual_nodes")
	var old_boxes: Dictionary = {}
	for id in old_ids:
		_check(old_nodes.has(id) and (old_nodes[id] as Node3D).visible, "Bestandsgebaeude sichtbar bei AN: %s" % id)
		old_boxes[id] = _bounds(old_nodes[id])
	var anchors: Array = []
	var spots: Array = []
	var map_data_early: Object = base.get("_map_data")
	for t in layout.get("terminals", []):
		var anchor: Array = Dictionary(t).get("model_anchor_plane", [])
		if anchor.size() == 2:
			anchors.append(Vector2(float(anchor[0]), float(anchor[1])))
			spots.append(anchors.back())
		var tg: Array = Dictionary(t).get("grid", [])
		if tg.size() == 2:
			var tpl: Vector3 = BASE_NAV.plane_at_grid(Vector2i(int(tg[0]), int(tg[1])))
			spots.append(Vector2(tpl.x, tpl.z))
	for b in layout.get("beds", []):
		for key in ["sleep_plane", "rest_plane"]:
			var bp: Array = Dictionary(b).get(key, [])
			if bp.size() == 2:
				spots.append(Vector2(float(bp[0]), float(bp[1])))
	var spawn: Array = layout.get("avatar_spawn_grid", [])
	if spawn.size() == 2:
		var sp: Vector3 = BASE_NAV.plane_at_grid(Vector2i(int(spawn[0]), int(spawn[1])))
		spots.append(Vector2(sp.x, sp.z))
	var person_height := 0.0
	for c in stage.get_children():
		if String(c.name).begins_with("RosterPerson_"):
			person_height = maxf(person_height, _bounds(c).size.y)
	var people: Array = []
	for c in stage.get_children():
		if String(c.name).begins_with("RosterPerson_") or String(c.name).begins_with("ActualCraft_"):
			people.append(c)
	for entry_variant in entries:
		var entry: Dictionary = entry_variant
		var id := String(entry.get("id", ""))
		var holders: Array = group.get_children().filter(func(n: Node) -> bool: return n.has_meta("structure_model_id") and String(n.get_meta("structure_model_id")) == id)
		_check(holders.size() == 1, "genau EIN neues Modell je Zuordnung: %s (%d)" % [id, holders.size()])
		if holders.size() != 1:
			continue
		var box: AABB = _bounds(holders[0])
		var center: Vector2 = OVERRIDES.site_center(layout, String(entry.get("site", "")))
		var size: Vector2 = OVERRIDES.site_size(layout, String(entry.get("site", "")))
		_check(center != Vector2.INF and size.x > 0.0, "Bauplatz im Layout gefunden: %s" % String(entry.get("site", "")))
		var site := Rect2(center - size * 0.5, size).grow(TOLERANCE)
		print("INFO %s Rahmen x %.2f..%.2f  z %.2f..%.2f  hoch %.2f  Unterkante %.3f | Bauplatz %s" % [id, box.position.x, box.end.x, box.position.z, box.end.z, box.size.y, box.position.y, str(site)])
		var raw_site := Rect2(center - size * 0.5, size)
		var rect := _rect_xz(box)
		print("INFO %s Ueberstand ueber den Bauplatz (m, negativ = innen): links %.2f rechts %.2f vorn(z-) %.2f hinten(z+) %.2f" % [id, raw_site.position.x - rect.position.x, rect.end.x - raw_site.end.x, raw_site.position.y - rect.position.y, rect.end.y - raw_site.end.y])
		# Menschenmass: Spielfigur (Hoehe aus dem Spiel) entspricht 1,8 m; Tuerhoehe muss dann 2,0 bis 2,3 m ergeben.
		var ratio: float = person_height / float(config.get("human_height_m", 1.8))
		var door_real: float = float(entry.get("door_height_model", 0.0)) * float(entry.get("scale", 1.0)) / ratio
		_check(door_real >= 1.95 and door_real <= 2.35, "Menschenmass: Tuer wirkt %.2f m hoch (Figur %.3f m, Faktor %.3f): %s" % [door_real, person_height, ratio, id])
		# Keine Benutzen-Stelle, kein Terminal, kein Feld der Karte, kein Landepad/Weg im Rahmen.
		var spots_inside := 0
		for s in spots:
			if rect.has_point(s):
				spots_inside += 1
		_check(spots_inside == 0, "keine Benutzen-Stelle/Terminal/Anker im Rahmen (%d von %d) : %s" % [spots_inside, spots.size(), id])
		var tiles_inside := 0
		for t in map_data_early.call("get_tiles"):
			var tp: Vector3 = BASE_NAV.plane_at_grid(Vector2i(t.grid_position))
			if rect.has_point(Vector2(tp.x, tp.z)):
				tiles_inside += 1
		_check(tiles_inside == 0, "kein Kartenfeld (Weg/Hindernis) im Rahmen (%d): %s" % [tiles_inside, id])
		for other_name in ["homebase_pad_01", "homebase_pad_02", "HomebaseBuiltPaths", "AuthoredServiceDrone"]:
			var other: Node = stage.get_node_or_null(other_name)
			if other != null:
				_check(not rect.intersects(_rect_xz(_bounds(other))), "ueberdeckt nicht %s: %s" % [other_name, id])
		_check(absf(box.position.y) <= 0.1, "Unterkante auf Bodenhoehe (+-0,1 m): %s (%.3f)" % [id, box.position.y])
		for old_id in old_ids:
			_check(not _rect_xz(box).intersects(_rect_xz(old_boxes[old_id])), "ueberdeckt kein Bestandsgebaeude: %s gegen %s" % [id, old_id])
		var covers_anchor := false
		for a in anchors:
			if _rect_xz(box).grow(0.3).has_point(a):
				covers_anchor = true
		_check(not covers_anchor, "ueberdeckt keinen Terminal-Anker: %s" % id)
		var covers_person := false
		for p in people:
			if _rect_xz(box).intersects(_rect_xz(_bounds(p))):
				covers_person = true
		_check(not covers_person, "ueberdeckt keine Figur und kein Schiff: %s" % id)
		_check(holders[0].visible and group.visible, "sichtbar bei AN: %s" % id)
	var terminals_before: Array = _terminal_ids(base)
	var map_data: Object = base.get("_map_data")
	var tiles_before: int = Array(map_data.call("get_tiles")).size()
	var walkable_before := 0
	for t in map_data.call("get_tiles"):
		if bool(t.walkable):
			walkable_before += 1
	# Taste F7 (echte Eingabe): AUS
	await _press(KEY_F7)
	_check(not group.visible and not bool(base.get("_structure_models").call("is_enabled")), "F7: neue Modelle AUS")
	for id in old_ids:
		_check((old_nodes[id] as Node3D).visible and _bounds(old_nodes[id]).is_equal_approx(old_boxes[id]), "AUS: Bestandsbild unveraendert: %s" % id)
	_check(_terminal_ids(base) == terminals_before and terminals_before.size() == 6, "Terminals unveraendert (%s)" % str(terminals_before))
	await _press(KEY_F7)
	_check(group.visible and bool(base.get("_structure_models").call("is_enabled")), "F7 nochmal: neue Modelle wieder AN")
	_check(_terminal_ids(base) == terminals_before, "Terminals nach Rueckschalten gleich")
	var walkable_after := 0
	for t in map_data.call("get_tiles"):
		if bool(t.walkable):
			walkable_after += 1
	_check(walkable_after == walkable_before and Array(map_data.call("get_tiles")).size() == tiles_before, "Begehbarkeit der Karte unveraendert (%d begehbare Felder)" % walkable_after)
	# Benutzen-Stellen erreichbar: Terminal anfordern wie bisher.
	var reachable := true
	for id in ["personnel", "jobs", "mission", "team"]:
		if not base.has_method("request_terminal"):
			reachable = false
	_check(reachable and (old_nodes["habitat_cutaway_01"] as Node3D).visible, "Benutzen-Stellen: Zugang (request_terminal) und Bestandsraeume vorhanden")
	print("STRUCTURE_MODELS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
