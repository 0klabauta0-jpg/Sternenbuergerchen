extends RefCounted
## Gebaeudemodelle der kleinen Aussenposten (Daten: data/visual/outpost_structure_models.json). Nur Darstellung: kein
## Kollisionskoerper, keine Sicht-/Deckungssperre, keine Navigation. Die Einsatzansicht ruft build() nach dem Kartenaufbau.
const CONFIG_PATH: String = "res://data/visual/outpost_structure_models.json"
const NODE_NAME: String = "OutpostStructureModels"


static func load_config() -> Dictionary:
	if not FileAccess.file_exists(CONFIG_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return Dictionary(parsed) if parsed is Dictionary else {}


## Tiefste Gelaendehoehe unter der (gedrehten) Grundflaeche, 3 x 3 Proben. half = halbe Breite/Tiefe in Einheiten.
static func lowest_ground(view: Node, center: Vector3, rotation_y: float, half: Vector2) -> float:
	var low: float = INF
	var basis := Basis(Vector3.UP, rotation_y)
	for ix in range(3):
		for iz in range(3):
			var local := Vector3(lerpf(-half.x, half.x, ix / 2.0), 0.0, lerpf(-half.y, half.y, iz / 2.0))
			var world: Vector2 = view.call("_position_3d_to_world", center + basis * local)
			low = minf(low, float(view.call("_get_world_surface_y", world)))
	return 0.0 if low == INF else low


## Haengt je passendem Eintrag (Kartenname + Marke vorhanden) genau ein Gebaeude in parent. Gibt den Wurzelknoten zurueck oder null.
static func build(view: Node, parent: Node, map_data) -> Node3D:
	var config: Dictionary = load_config()
	if map_data == null or parent == null or not bool(config.get("enabled", true)):
		return null
	var map_name: String = String(map_data.call("get_map_name"))
	var marker_ids: PackedStringArray = map_data.call("get_marker_ids")
	var root: Node3D = null
	for entry_variant in Array(config.get("entries", [])):
		var entry: Dictionary = entry_variant
		if String(entry.get("map_name", "")) != map_name or not marker_ids.has(String(entry.get("marker_id", ""))):
			continue
		var scene := load(String(entry.get("model", ""))) as PackedScene
		if scene == null:
			push_warning("Aussenposten-Modell laedt nicht: %s" % String(entry.get("model", "")))
			continue
		var visual := scene.instantiate() as Node3D
		if visual == null:
			continue
		var scale_factor: float = float(entry.get("scale", 1.0))
		var marker_world: Vector2 = map_data.call("get_marker_position", String(entry.get("marker_id", "")))
		var marker_3d: Vector3 = view.call("_world_to_3d_position", marker_world, 0.0)
		var offset: Array = entry.get("offset", [0.0, 0.0])
		var rotation_y: float = deg_to_rad(float(entry.get("rotation_y_deg", 0.0)))
		var center := Vector3(marker_3d.x + float(offset[0]), 0.0, marker_3d.z + float(offset[1]))
		var footprint: Array = entry.get("footprint_m", [0.0, 0.0])
		var half := Vector2(float(footprint[0]), float(footprint[1])) * 0.5 * scale_factor
		center.y = lowest_ground(view, center, rotation_y, half)
		var holder := Node3D.new()
		holder.name = String(entry.get("id", "model"))
		holder.set_meta("outpost_structure_id", String(entry.get("id", "model")))
		holder.position = center
		holder.rotation.y = rotation_y
		holder.scale = Vector3.ONE * scale_factor
		holder.add_child(visual)
		if root == null:
			root = Node3D.new()
			root.name = NODE_NAME
			parent.add_child(root)
		root.add_child(holder)
	return root
