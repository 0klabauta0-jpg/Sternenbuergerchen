extends SceneTree
## Gebaeudemodelle an Muellers Farm, Shady Lab und Templanon (Wunsch 25.11.): immer da, auf der Karte am Haendler-Marker,
## nur Darstellung. Kopflos, rechnend; je Karte eine echte Einsatzansicht. Daten: data/visual/outpost_structure_models.json.
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const CONFIG_PATH := "res://data/visual/outpost_structure_models.json"
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


func _figure_height() -> float:
	var scene := load("res://Assets/kenney_space-kit/Models/GLTF format/astronautA.glb") as PackedScene
	if scene == null:
		return 0.0
	var node := scene.instantiate() as Node3D
	root.add_child(node)
	var h := _bounds(node).size.y * VIEW.UNIT_MODEL_SCALE
	node.queue_free()
	return h


func _run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH)) if FileAccess.file_exists(CONFIG_PATH) else null
	var config: Dictionary = Dictionary(parsed) if parsed is Dictionary else {}
	var entries: Array = Array(config.get("entries", []))
	_check(entries.size() == 4, "Zuordnung hat vier Orte (%d)" % entries.size())
	var figure := _figure_height()
	var human_m: float = float(config.get("human_height_m", 1.8))
	var ratio: float = figure / human_m
	print("INFO Spielfigur in der Einsatzansicht %.3f Einheiten = %.1f m, Faktor je Meter %.4f" % [figure, human_m, ratio])
	var outposts_file: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/small_outposts.json")))
	# die drei kleinen Posten stehen unter "locations", der Relaisgrat (Ort mit Auftrag und freiem Besuch) unter "visit_trade_markers"
	var outposts: Dictionary = Dictionary(outposts_file.get("locations", {})).duplicate()
	outposts.merge(Dictionary(outposts_file.get("visit_trade_markers", {})))
	for entry_variant in entries:
		var entry: Dictionary = entry_variant
		var id := String(entry.get("id", ""))
		var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file(String(entry.get("map_file_path", "")))
		_check(map != null and map.get_map_name() == String(entry.get("map_name", "?")), "Karte %s hat den Namen aus den Daten (%s)" % [String(entry.get("map_file_path", "")), String(entry.get("map_name", ""))])
		var marker := String(entry.get("marker_id", ""))
		_check(map.get_marker_ids().has(marker), "Marke %s steht auf der Karte: %s" % [marker, id])
		_check(String(Dictionary(outposts.get(String(entry.get("place_id", "")), {})).get("service_marker_id", "")) == marker, "Handelsmarke des Ortes unveraendert gleich der Modellmarke: %s" % id)
		var view = VIEW.new()
		root.add_child(view)
		view.configure_from_map(map)
		for i in range(3):
			await process_frame
		var all_holders: Array = view.find_children("*", "Node3D", true, false).filter(func(n: Node) -> bool: return n.has_meta("outpost_structure_id"))
		var same_map := 0
		for other in entries:
			if String(Dictionary(other).get("map_name", "")) == String(entry.get("map_name", "")):
				same_map += 1
		_check(all_holders.size() == same_map, "auf der Karte stehen so viele Aussenposten-Modelle wie Eintraege fuer sie (%d von %d): %s" % [all_holders.size(), same_map, id])
		var holders: Array = all_holders.filter(func(n: Node) -> bool: return String(n.get_meta("outpost_structure_id")) == id)
		_check(holders.size() == 1, "es steht GENAU EIN Aussenposten-Modell je Eintrag/Marke (%d): %s" % [holders.size(), id])
		if holders.size() != 1:
			view.queue_free()
			continue
		var holder: Node3D = holders[0]
		_check(String(holder.get_meta("outpost_structure_id")) == id, "es ist das Modell des Ortes: %s" % id)
		var box: AABB = _bounds(holder)
		_check(box.size.y > 0.1, "Modell hat Netze (Hoehe %.2f)" % box.size.y)
		var world: Vector2 = map.get_marker_position(marker)
		var marker_3d: Vector3 = view.call("_world_to_3d_position", world, 0.0)
		var center := Vector2(holder.global_position.x, holder.global_position.z)
		var offset_len := center.distance_to(Vector2(marker_3d.x, marker_3d.z))
		_check(offset_len <= float(entry.get("max_offset", 0.0)) + 0.001, "Gebaeude steht am Marker: Abstand %.2f <= %.2f: %s" % [offset_len, float(entry.get("max_offset", 0.0)), id])
		# Menschenmass
		var expected_scale: float = ratio
		var home_ref: Dictionary = Dictionary(entry.get("scale_from_home_pod", {}))
		if not home_ref.is_empty():
			# Modell nicht in Metern (Wohn-Pod der Heimatbasis): Faktor der Heimatbasis x Figur hier / Figur dort
			expected_scale = float(home_ref.get("home_scale", 0.0)) * figure / float(home_ref.get("home_figure", 1.0))
		_check(absf(holder.scale.x - expected_scale) <= 0.01 and absf(holder.scale.x - float(entry.get("scale", -1.0))) <= 0.0005, "Faktor %.4f = erwartet %.4f (Figur/1,8 m = %.4f): %s" % [holder.scale.x, expected_scale, ratio, id])
		var sy: float = float(entry.get("scale_y_factor", 1.0))
		_check(absf(holder.scale.y - holder.scale.x * sy) <= 0.0005, "Hoehen-Stauchung: Y-Skala %.4f = Faktor %.4f x %.2f: %s" % [holder.scale.y, holder.scale.x, sy, id])
		var door_real := float(entry.get("door_height_m", 0.0))
		_check(door_real >= 1.95 and door_real <= 2.35, "Tuerhoehe im Menschenmass %.2f m (aus den Daten, am Modell geschaetzt): %s" % [door_real, id])
		var real_h: float = box.size.y / ratio
		var range_m: Array = entry.get("real_height_range", [0.0, 0.0])
		_check(real_h >= float(range_m[0]) and real_h <= float(range_m[1]), "Gesamthoehe wirkt %.2f m (erlaubt %.1f bis %.1f): %s" % [real_h, float(range_m[0]), float(range_m[1]), id])
		print("INFO %s Endmasse %.2f x %.2f x %.2f Einheiten = %.1f x %.1f x %.1f m, Drehung %.1f Grad" % [id, box.size.x, box.size.z, box.size.y, box.size.x / ratio, box.size.z / ratio, real_h, rad_to_deg(holder.rotation.y)])
		# Unterkante auf Gelaende (tiefste Ecke der Grundflaeche)
		var low := INF
		var high := -INF
		for ix in range(3):
			for iz in range(3):
				var p := Vector3(lerpf(box.position.x, box.end.x, ix / 2.0), 0.0, lerpf(box.position.z, box.end.z, iz / 2.0))
				var w: Vector2 = view.call("_position_3d_to_world", p)
				var y: float = view.call("_get_world_surface_y", w)
				low = minf(low, y)
				high = maxf(high, y)
		_check(absf(box.position.y - low) <= 0.05, "Unterkante %.3f auf tiefster Gelaendeecke %.3f (Hang %.3f): %s" % [box.position.y, low, high - low, id])
		# Marker, Zielpunkte, Landeplaetze, Startpunkte: keiner im Grundriss
		var rect := Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
		var near: Array = []
		var inside := 0
		for mid in map.get_marker_ids():
			var mp: Vector2 = map.get_marker_position(String(mid))
			var m3: Vector3 = view.call("_world_to_3d_position", mp, 0.0)
			var in_rect := rect.grow(0.4).has_point(Vector2(m3.x, m3.z))
			if in_rect:
				inside += 1
			if Vector2(m3.x, m3.z).distance_to(Vector2(marker_3d.x, marker_3d.z)) < 14.0:
				near.append("%s(%.1f,%.1f%s)" % [String(mid), m3.x - marker_3d.x, m3.z - marker_3d.z, " IM GRUNDRISS" if in_rect else ""])
		print("INFO %s Marker nahe %s: %s | Grundriss x %.2f..%.2f z %.2f..%.2f" % [id, marker, ", ".join(near), rect.position.x - marker_3d.x, rect.end.x - marker_3d.x, rect.position.y - marker_3d.z, rect.end.y - marker_3d.z])
		_check(inside == 0, "kein Marker der Karte (Haendler, Landefeld, Startpunkte, Zielpunkte, Kiste) im Grundriss (+0,4): %d: %s" % [inside, id])
		# Reine Darstellung: nichts, was Wegsuche, Sicht oder Deckung aendert
		var bad := 0
		for cls in ["CollisionObject3D", "CollisionShape3D", "OccluderInstance3D", "NavigationRegion3D", "NavigationObstacle3D", "Light3D"]:
			bad += holder.find_children("*", cls, true, false).size()
		_check(bad == 0, "nur Darstellung, keine Kollision/Sichtsperre/Navigation/Licht am Modell (%d): %s" % [bad, id])
		# Frachtaufzug und Landepad
		var every_extra: Array = view.find_children("*", "Node3D", true, false).filter(func(n: Node) -> bool: return n.has_meta("outpost_extra_id"))
		var all_extras: Array = every_extra.filter(func(n: Node) -> bool: return String(n.get_meta("outpost_extra_id")).begins_with(id + "_"))
		var lifts: Array = all_extras.filter(func(n: Node) -> bool: return String(n.get_meta("outpost_extra_kind")) == "model")
		var pads: Array = all_extras.filter(func(n: Node) -> bool: return String(n.get_meta("outpost_extra_kind")) == "pad")
		_check(lifts.size() == 1 and pads.size() == 1 and all_extras.size() == 2, "genau EIN Frachtaufzug und EIN Landepad (%d/%d): %s" % [lifts.size(), pads.size(), id])
		if lifts.size() == 1 and pads.size() == 1:
			var lift: Node3D = lifts[0]
			var pad: Node3D = pads[0]
			var lift_entry: Dictionary = {}
			var pad_entry: Dictionary = {}
			for e in Array(entry.get("extras", [])):
				if String(Dictionary(e).get("kind", "")) == "pad":
					pad_entry = e
				else:
					lift_entry = e
			var lbox: AABB = _bounds(lift)
			var pbox: AABB = _bounds(pad)
			var lrect := Rect2(lbox.position.x, lbox.position.z, lbox.size.x, lbox.size.z)
			var prect := Rect2(pbox.position.x, pbox.position.z, pbox.size.x, pbox.size.z)
			var term := Vector2(marker_3d.x, marker_3d.z)
			var lift_dist := (lrect.position + lrect.size * 0.5).distance_to(term)
			_check(lift_dist <= float(lift_entry.get("max_distance", 0.0)), "Frachtaufzug wenige Schritte vom Terminal: %.2f <= %.1f Einheiten (%.1f m): %s" % [lift_dist, float(lift_entry.get("max_distance", 0.0)), lift_dist / ratio, id])
			_check(absf(lift.scale.x - 0.75 * ratio) <= 0.002 and absf(lift.scale.x - float(lift_entry.get("scale", -1.0))) <= 0.0005, "Frachtaufzug-Faktor %.4f = 0,75 x Figur/1,8 m (%.4f), wie in der Heimatbasis: %s" % [lift.scale.x, 0.75 * ratio, id])
			var lh: float = lbox.size.y / ratio
			var lr: Array = lift_entry.get("real_height_range", [0.0, 0.0])
			_check(lh >= float(lr[0]) and lh <= float(lr[1]), "Frachtaufzug wirkt %.2f m hoch (erlaubt %.1f bis %.1f): %s" % [lh, float(lr[0]), float(lr[1]), id])
			var llow := INF
			for ix in range(3):
				for iz in range(3):
					var lp := Vector3(lerpf(lbox.position.x, lbox.end.x, ix / 2.0), 0.0, lerpf(lbox.position.z, lbox.end.z, iz / 2.0))
					llow = minf(llow, float(view.call("_get_world_surface_y", view.call("_position_3d_to_world", lp))))
			_check(absf(lbox.position.y - llow) <= 0.1, "Frachtaufzug Unterkante %.3f auf tiefster Gelaendeecke %.3f: %s" % [lbox.position.y, llow, id])
			# Pad: Oberkante buendig am Gelaende, Schiffsgrundriss darin
			var pad_center := Vector3(pbox.position.x + pbox.size.x * 0.5, 0.0, pbox.position.z + pbox.size.z * 0.5)
			var pad_ground: float = view.call("_get_world_surface_y", view.call("_position_3d_to_world", Vector3(pad.position.x, 0.0, pad.position.z)))
			var pad_top: float = pbox.end.y
			print("INFO %s Pad Rahmen x %.2f..%.2f z %.2f..%.2f (mit Rampe), Oberkante %.3f, Gelaende am Pad %.3f" % [id, prect.position.x - marker_3d.x, prect.end.x - marker_3d.x, prect.position.y - marker_3d.z, prect.end.y - marker_3d.z, pad_top, pad_ground])
			_check(pad_top - pad_ground >= -0.001 and pad_top - pad_ground <= 0.05, "Pad-Oberkante %.3f liegt hoechstens 5 cm ueber dem Gelaende %.3f (Schiff sinkt nicht ein, schwebt nicht): %s" % [pad_top, pad_ground, id])
			var catalog: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string("res://data/frontier_ship_visual_catalog.json"))).get("ships", {})
			var ship: Dictionary = Dictionary(catalog.get("cutlass_01", {}))
			var bsz: Array = ship.get("bounds_size", [0, 0, 0])
			var hull := Vector2(float(bsz[0]), float(bsz[2])) * float(ship.get("scale", 1.0))
			var psz: Array = pad_entry.get("size", [0.0, 0.0])
			var pad_size := Vector2(float(psz[0]), float(psz[1]))
			var fits := (pad_size.x >= hull.x and pad_size.y >= hull.y) or (pad_size.x >= hull.y and pad_size.y >= hull.x)
			_check(fits and pad_size.x <= hull.y + 1.2 and pad_size.y <= hull.y + 1.2, "Pad %.1f x %.1f nimmt den Schiffsgrundriss %.2f x %.2f (Entermesser, Katalog) auf, ist aber nur wenig groesser: %s" % [pad_size.x, pad_size.y, hull.x, hull.y, id])
			# nichts davon ueberdeckt Marker (Terminal, Zielpunkte, Startpunkte, Kiste) oder einander
			var covered := 0
			for mid in map.get_marker_ids():
				var m3: Vector3 = view.call("_world_to_3d_position", map.get_marker_position(String(mid)), 0.0)
				var q := Vector2(m3.x, m3.z)
				if lrect.grow(0.4).has_point(q) or prect.grow(0.4).has_point(q):
					covered += 1
			_check(covered == 0, "Aufzug und Pad decken keinen Marker der Karte (%d): %s" % [covered, id])
			_check(not rect.intersects(lrect) and not rect.intersects(prect) and not lrect.intersects(prect), "Gebaeude, Aufzug und Pad ueberlappen einander nicht: %s" % id)
			# mehrere Gebaeude auf einer Karte: kein fremdes Gebaeude, kein fremder Aufzug/Pad ueberlappt dieses
			var clash := 0
			for other_node in all_holders + every_extra:
				var on: Node3D = other_node
				if on == holder or on == lift or on == pad:
					continue
				var ob: AABB = _bounds(on)
				var orect := Rect2(ob.position.x, ob.position.z, ob.size.x, ob.size.z)
				if orect.intersects(rect) or orect.intersects(lrect) or orect.intersects(prect):
					clash += 1
			_check(clash == 0, "Gebaeude, Aufzug und Pad ueberlappen kein anderes Aussenposten-Teil auf der Karte (%d): %s" % [clash, id])
			var bad2 := 0
			for cls in ["CollisionObject3D", "CollisionShape3D", "OccluderInstance3D", "NavigationRegion3D", "NavigationObstacle3D", "Light3D"]:
				bad2 += lift.find_children("*", cls, true, false).size() + pad.find_children("*", cls, true, false).size()
			_check(bad2 == 0, "Aufzug und Pad nur Darstellung (%d): %s" % [bad2, id])
		view.queue_free()
		await process_frame
	print("OUTPOST_STRUCTURE_MODELS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
