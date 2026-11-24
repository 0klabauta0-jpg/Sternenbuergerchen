extends Node3D
## Neue Gebaeudemodelle der Heimatbasis (Taste F7 schaltet um). Nur Sicht: keine Navigation, keine Karten.
## Die Modelle stehen auf den im Layout vorgesehenen freien Bauplaetzen (expansion_areas); Bestandsgebaeude bleiben.

const CONFIG_PATH: String = "res://data/visual/structure_model_overrides.json"
const BASE_NAV := preload("res://scripts/meta/base_interior_navigation.gd")
const GROUP_NAME: String = "StructureModelOverrides"

var _enabled: bool = true
var _config: Dictionary = {}
var _models: Dictionary = {}  # id -> Node3D


static func load_config() -> Dictionary:
	if not FileAccess.file_exists(CONFIG_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return Dictionary(parsed) if parsed is Dictionary else {}


## Mitte eines Bauplatzes in Weltmetern (Ebene x/z), aus dem Layout.
static func site_center(layout: Dictionary, site_id: String) -> Vector2:
	for area_variant in Array(layout.get("expansion_areas", [])):
		var area: Dictionary = area_variant
		if String(area.get("id", "")) == site_id:
			var grid: Array = area.get("grid", [0, 0])
			var plane: Vector3 = BASE_NAV.plane_at_grid(Vector2i(int(grid[0]), int(grid[1])))
			return Vector2(plane.x, plane.z)
	return Vector2.INF


static func site_size(layout: Dictionary, site_id: String) -> Vector2:
	for area_variant in Array(layout.get("expansion_areas", [])):
		var area: Dictionary = area_variant
		if String(area.get("id", "")) == site_id:
			var size: Array = area.get("size", [0, 0])
			return Vector2(float(size[0]), float(size[1]))
	return Vector2.ZERO


func build(layout: Dictionary) -> void:
	name = GROUP_NAME
	_config = load_config()
	_enabled = bool(_config.get("enabled", true))
	var brightness: float = float(_config.get("brightness", 1.0))
	for entry_variant in Array(_config.get("entries", [])):
		var entry: Dictionary = entry_variant
		var scene := load(String(entry.get("model", ""))) as PackedScene
		if scene == null:
			push_warning("Neue Gebaeudemodelle: Modell laedt nicht: %s" % String(entry.get("model", "")))
			continue
		var center: Vector2 = site_center(layout, String(entry.get("site", "")))
		if center == Vector2.INF:
			continue
		var visual := scene.instantiate() as Node3D
		if visual == null:
			continue
		var holder := Node3D.new()
		holder.name = String(entry.get("id", "model"))
		holder.set_meta("structure_model_id", holder.name)
		var offset: Array = entry.get("offset", [0, 0, 0])
		holder.position = Vector3(center.x + float(offset[0]), float(offset[1]), center.y + float(offset[2]))
		holder.rotation.y = deg_to_rad(float(entry.get("rotation_y_deg", 0.0)))
		holder.scale = Vector3.ONE * float(entry.get("scale", 1.0))
		holder.add_child(visual)
		add_child(holder)
		for node in visual.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance := node as MeshInstance3D
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			if absf(brightness - 1.0) > 0.001:
				_tint(mesh_instance, brightness)
		_models[holder.name] = holder
	visible = _enabled


func _tint(mesh_instance: MeshInstance3D, brightness: float) -> void:
	if mesh_instance.mesh == null:
		return
	for surface in mesh_instance.mesh.get_surface_count():
		var material := mesh_instance.get_active_material(surface) as StandardMaterial3D
		if material == null:
			continue
		var copy := material.duplicate() as StandardMaterial3D
		copy.albedo_color = Color(copy.albedo_color.r * brightness, copy.albedo_color.g * brightness, copy.albedo_color.b * brightness, copy.albedo_color.a)
		mesh_instance.set_surface_override_material(surface, copy)


func is_enabled() -> bool:
	return _enabled


func set_enabled(value: bool) -> void:
	_enabled = value
	visible = value


func toggle() -> bool:
	set_enabled(not _enabled)
	return _enabled


func get_models() -> Dictionary:
	return _models
