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
	_check(entries.size() == 3, "Zuordnung hat drei Orte (%d)" % entries.size())
	var figure := _figure_height()
	var human_m: float = float(config.get("human_height_m", 1.8))
	var ratio: float = figure / human_m
	print("INFO Spielfigur in der Einsatzansicht %.3f Einheiten = %.1f m, Faktor je Meter %.4f" % [figure, human_m, ratio])
	var outposts: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/small_outposts.json"))).get("locations", {})
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
		var holders: Array = view.find_children("*", "Node3D", true, false).filter(func(n: Node) -> bool: return n.has_meta("outpost_structure_id"))
		_check(holders.size() == 1, "auf der Karte steht GENAU EIN Aussenposten-Modell (%d): %s" % [holders.size(), id])
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
		_check(absf(holder.scale.x - ratio) <= 0.01 and absf(holder.scale.x - float(entry.get("scale", -1.0))) <= 0.0005, "Faktor %.4f = Figur/1,8 m (%.4f): %s" % [holder.scale.x, ratio, id])
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
		_check(absf(box.position.y - low) <= 0.1, "Unterkante %.3f auf tiefster Gelaendeecke %.3f (Hang %.3f): %s" % [box.position.y, low, high - low, id])
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
		view.queue_free()
		await process_frame
	print("OUTPOST_STRUCTURE_MODELS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
