class_name StructureModelBlocking
extends RefCounted
## Begehbare und gesperrte Rechtecke (Ebene x/z, Meter) der neuen Gebaeudemodelle (data/visual/structure_model_overrides.json):
## walk_rects machen Felder begehbar (Innenraum eines Pods), block_rects sperren Waende/Grundrisse geschlossener Gebaeude,
## damit Figuren nicht durch Waende laufen oder in ein geschlossenes Gebaeude gehen.
## Gelesen von BaseInteriorNavigation (load_map: begehbar; Wegegraph: gesperrt). Bei "enabled": false passiert nichts.
const CONFIG_PATH: String = "res://data/visual/structure_model_overrides.json"
const SCALE := 4


static func _rects(key: String) -> Array[Rect2]:
	var result: Array[Rect2] = []
	if not FileAccess.file_exists(CONFIG_PATH):
		return result
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary or not bool(Dictionary(parsed).get("enabled", false)):
		return result
	for entry_variant in Array(Dictionary(parsed).get("entries", [])):
		for raw_variant in Array(Dictionary(entry_variant).get(key, [])):
			var raw: Array = raw_variant
			if raw.size() == 4:
				result.append(Rect2(float(raw[0]), float(raw[1]), float(raw[2]), float(raw[3])))
	return result


static func blocked_rects() -> Array[Rect2]:
	return _rects("block_rects")


static func walkable_rects() -> Array[Rect2]:
	return _rects("walk_rects")


## Vor der Registrierung der Karte im Wegegraph: Felder in walk_rects begehbar machen.
static func apply_to_map(map) -> void:
	for rect: Rect2 in walkable_rects():
		var low_y := floori(rect.position.y * SCALE / (sqrt(3.0) * 0.5)) - 1
		var high_y := ceili(rect.end.y * SCALE / (sqrt(3.0) * 0.5)) + 1
		for y in range(low_y, high_y + 1):
			var low_x := floori(rect.position.x * SCALE - float(y) * 0.5) - 1
			var high_x := ceili(rect.end.x * SCALE - float(y) * 0.5) + 1
			for x in range(low_x, high_x + 1):
				var tile = map.get_tile_at_grid(Vector2i(x, y))
				if tile == null:
					continue
				var plane := Vector2((float(x) + float(y) * 0.5) / SCALE, float(y) * sqrt(3.0) * 0.5 / SCALE)
				if rect.has_point(plane):
					tile.walkable = true
					tile.blocks_los = false
