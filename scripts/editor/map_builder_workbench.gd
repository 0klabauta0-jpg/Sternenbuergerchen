@tool
class_name MapBuilderWorkbench
extends Node3D

const IMPORTER_SCRIPT: GDScript = preload("res://scripts/editor/map_builder_scene_importer.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const DEFAULT_MANIFEST_PATH: String = "res://data/map_builder_workbench_manifest.json"

@export var manifest_path: String = DEFAULT_MANIFEST_PATH
@export var map_name: String = "map_builder_workbench_demo"
@export var grid_size: Vector2i = Vector2i(8, 6)
@export var terrain_visual_theme_id: String = "ground_mission_mixed_v1"
@export var output_path: String = "res://maps/map_builder_workbench_output.json"
@export var auto_configure_on_ready: bool = true
@export var seed_demo_layout_when_empty: bool = true

var _manifest: Dictionary = {}
var _item_type_map: Dictionary = {}
var _item_manifest_by_id: Dictionary = {}
var _mesh_library: MeshLibrary
var _last_warnings: Array[String] = []


func _ready() -> void:
	if auto_configure_on_ready:
		call_deferred("configure_workbench")


func configure_workbench(force_rebuild: bool = false) -> Dictionary:
	_last_warnings.clear()
	_manifest = _load_manifest()
	_apply_manifest_defaults()
	_mesh_library = _build_mesh_library(force_rebuild)
	var grid_map := get_grid_map()
	if grid_map != null:
		_configure_grid_map(grid_map)
		if seed_demo_layout_when_empty and grid_map.get_used_cells().is_empty():
			_seed_demo_grid(grid_map)
	var prop_root := get_prop_root()
	if prop_root != null and seed_demo_layout_when_empty and prop_root.get_child_count() == 0:
		_seed_demo_props(prop_root)
	return get_workbench_snapshot()


func get_grid_map() -> GridMap:
	return get_node_or_null("GridMap") as GridMap


func get_prop_root() -> Node3D:
	return get_node_or_null("AssetPlacerProps") as Node3D


func get_mesh_library() -> MeshLibrary:
	if _mesh_library == null:
		configure_workbench()
	return _mesh_library


func get_gridmap_item_type_map() -> Dictionary:
	if _item_type_map.is_empty():
		configure_workbench()
	return _item_type_map.duplicate(true)


func compile_to_map_data() -> Dictionary:
	configure_workbench()
	var importer = IMPORTER_SCRIPT.new()
	return importer.call("build_map_from_scene_authoring", get_grid_map(), get_gridmap_item_type_map(), get_prop_root(), {
		"map_name": map_name,
		"grid_size": grid_size,
		"terrain_visual_theme_id": terrain_visual_theme_id,
	})


func save_compiled_map(path_override: String = "") -> Dictionary:
	var target_path: String = path_override.strip_edges() if not path_override.strip_edges().is_empty() else output_path
	var result: Dictionary = Dictionary(compile_to_map_data())
	if not bool(result.get("ok", false)):
		result["save_error"] = ERR_INVALID_DATA
		return result
	var map_data = result.get("map_data", null)
	if map_data == null or not map_data.has_method("save_to_file"):
		result["ok"] = false
		result["save_error"] = ERR_INVALID_DATA
		return result
	var save_error: int = int(map_data.call("save_to_file", target_path))
	result["save_error"] = save_error
	result["output_path"] = target_path
	result["ok"] = save_error == OK
	return result


func get_workbench_snapshot() -> Dictionary:
	var grid_map := get_grid_map()
	var prop_root := get_prop_root()
	var used_cells: Array = grid_map.get_used_cells() if grid_map != null else []
	var mesh_item_count: int = _mesh_library.get_item_list().size() if _mesh_library != null else 0
	return {
		"manifest_path": manifest_path,
		"map_name": map_name,
		"grid_size": grid_size,
		"terrain_visual_theme_id": terrain_visual_theme_id,
		"output_path": output_path,
		"mesh_library_item_count": mesh_item_count,
		"grid_used_cell_count": used_cells.size(),
		"prop_node_count": prop_root.get_child_count() if prop_root != null else 0,
		"item_type_map_count": _item_type_map.size(),
		"warnings": _last_warnings.duplicate(),
	}


func _load_manifest() -> Dictionary:
	if not FileAccess.file_exists(manifest_path):
		_last_warnings.append("Map builder manifest not found: %s" % manifest_path)
		return {}
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		_last_warnings.append("Could not open map builder manifest: %s" % manifest_path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		_last_warnings.append("Map builder manifest is not a Dictionary: %s" % manifest_path)
		return {}
	return Dictionary(parsed)


func _apply_manifest_defaults() -> void:
	var demo_layout: Dictionary = Dictionary(_manifest.get("demo_layout", {}))
	map_name = String(demo_layout.get("map_name", map_name)).strip_edges()
	grid_size = _coerce_vector2i(demo_layout.get("grid_size", grid_size))
	terrain_visual_theme_id = String(demo_layout.get("terrain_visual_theme_id", terrain_visual_theme_id)).strip_edges()
	var compiler: Dictionary = Dictionary(_manifest.get("compiler", {}))
	output_path = String(compiler.get("default_output_path", output_path)).strip_edges()


func _build_mesh_library(_force_rebuild: bool = false) -> MeshLibrary:
	var library := MeshLibrary.new()
	_item_type_map.clear()
	_item_manifest_by_id.clear()
	var mesh_section: Dictionary = Dictionary(_manifest.get("mesh_library", {}))
	var items: Array = Array(mesh_section.get("items", []))
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	for item_variant in items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = Dictionary(item_variant)
		var item_id: int = int(item.get("item_id", -1))
		var type_id: String = String(item.get("type_id", "")).strip_edges().to_lower()
		if item_id < 0 or type_id.is_empty():
			_last_warnings.append("Skipped MeshLibrary item with missing id/type: %s" % str(item))
			continue
		if catalog != null and catalog.has_method("has_type") and not bool(catalog.call("has_type", type_id)):
			_last_warnings.append("MeshLibrary type_id missing in TerrainTileCatalog: %s" % type_id)
			continue
		var mesh: Mesh = _load_first_mesh(String(item.get("model_path", "")))
		if mesh == null:
			_last_warnings.append("MeshLibrary item has no loadable mesh: %s" % type_id)
			continue
		library.create_item(item_id)
		library.set_item_name(item_id, "%s | %s" % [String(item.get("label", type_id)), type_id])
		library.set_item_mesh(item_id, mesh)
		library.set_item_mesh_transform(item_id, _build_item_transform(item))
		var preview_path: String = String(item.get("preview_path", "")).strip_edges()
		var preview: Texture2D = load(preview_path) as Texture2D if not preview_path.is_empty() else null
		if preview != null and library.has_method("set_item_preview"):
			library.call("set_item_preview", item_id, preview)
		_item_type_map[item_id] = {
			"type_id": type_id,
		}
		_item_manifest_by_id[item_id] = item.duplicate(true)
	return library


func _configure_grid_map(grid_map: GridMap) -> void:
	var mesh_section: Dictionary = Dictionary(_manifest.get("mesh_library", {}))
	grid_map.cell_size = _coerce_vector3(mesh_section.get("grid_cell_size", Vector3(1.0, 0.5, 1.0)))
	grid_map.mesh_library = _mesh_library
	grid_map.set_meta("sb_builder_manifest_path", manifest_path)
	grid_map.set_meta("sb_item_type_map", _item_type_map.duplicate(true))


func _seed_demo_grid(grid_map: GridMap) -> void:
	var demo_layout: Dictionary = Dictionary(_manifest.get("demo_layout", {}))
	for cell_variant in Array(demo_layout.get("cells", [])):
		if typeof(cell_variant) != TYPE_DICTIONARY:
			continue
		var cell_entry: Dictionary = Dictionary(cell_variant)
		var cell: Vector3i = _coerce_vector3i(cell_entry.get("grid", Vector3i.ZERO))
		var item_id: int = int(cell_entry.get("item_id", -1))
		if item_id < 0:
			continue
		var orientation: int = _orientation_for_yaw(float(cell_entry.get("rotation_degrees", 0.0)), grid_map)
		grid_map.set_cell_item(cell, item_id, orientation)


func _seed_demo_props(prop_root: Node3D) -> void:
	var demo_layout: Dictionary = Dictionary(_manifest.get("demo_layout", {}))
	for prop_variant in Array(demo_layout.get("props", [])):
		if typeof(prop_variant) != TYPE_DICTIONARY:
			continue
		var prop: Dictionary = Dictionary(prop_variant)
		var type_id: String = String(prop.get("type_id", "")).strip_edges().to_lower()
		if type_id.is_empty():
			continue
		var node := Node3D.new()
		node.name = _make_node_name(type_id)
		var grid_position: Vector2i = _coerce_vector2i(prop.get("grid_position", Vector2i.ZERO))
		var rotation_degrees: float = float(prop.get("rotation_degrees", 0.0))
		var object_scale: float = float(prop.get("object_scale", 1.0))
		node.position = Vector3(grid_position.x, 0.0, grid_position.y)
		node.rotation_degrees.y = rotation_degrees
		node.scale = Vector3.ONE * object_scale
		node.set_meta("sb_type_id", type_id)
		node.set_meta("sb_grid_position", grid_position)
		node.set_meta("sb_rotation_degrees", rotation_degrees)
		node.set_meta("sb_object_scale", object_scale)
		prop_root.add_child(node)
		if _should_attach_visual_previews():
			_attach_prop_visual(node, type_id, object_scale)


func _attach_prop_visual(node: Node3D, type_id: String, object_scale: float) -> void:
	var prop_info: Dictionary = _find_sample_prop(type_id)
	if prop_info.is_empty():
		return
	var mesh: Mesh = _load_first_mesh(String(prop_info.get("model_path", "")))
	if mesh == null:
		return
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "PreviewMesh"
	mesh_instance.mesh = mesh
	var visual_scale: float = float(prop_info.get("scale", 1.0))
	mesh_instance.scale = Vector3.ONE * visual_scale / maxf(object_scale, 0.001)
	node.add_child(mesh_instance)


func _should_attach_visual_previews() -> bool:
	return DisplayServer.get_name() != "headless"


func _find_sample_prop(type_id: String) -> Dictionary:
	var prop_section: Dictionary = Dictionary(_manifest.get("asset_placer_props", {}))
	for prop_variant in Array(prop_section.get("sample_assets", [])):
		if typeof(prop_variant) != TYPE_DICTIONARY:
			continue
		var prop: Dictionary = Dictionary(prop_variant)
		if String(prop.get("type_id", "")).strip_edges().to_lower() == type_id:
			return prop
	return {}


func _load_first_mesh(path: String) -> Mesh:
	var trimmed_path: String = path.strip_edges()
	if trimmed_path.is_empty():
		return null
	var resource: Resource = load(trimmed_path)
	if resource is Mesh:
		return resource as Mesh
	if resource is PackedScene:
		var instance: Node = (resource as PackedScene).instantiate()
		var mesh: Mesh = _find_first_mesh(instance)
		instance.queue_free()
		return mesh
	return null


func _find_first_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D:
		var mesh: Mesh = (node as MeshInstance3D).mesh
		if mesh != null:
			return mesh
	for child in node.get_children():
		var child_mesh: Mesh = _find_first_mesh(child)
		if child_mesh != null:
			return child_mesh
	return null


func _build_item_transform(item: Dictionary) -> Transform3D:
	var scale_value: float = maxf(float(item.get("scale", 1.0)), 0.001)
	var rotation_degrees: float = float(item.get("rotation_degrees_offset", 0.0))
	var basis := Basis(Vector3.UP, deg_to_rad(rotation_degrees)).scaled(Vector3.ONE * scale_value)
	var origin := Vector3(0.0, float(item.get("y_offset", 0.0)), 0.0)
	return Transform3D(basis, origin)


func _orientation_for_yaw(rotation_degrees: float, grid_map: GridMap) -> int:
	if grid_map == null or not grid_map.has_method("get_orthogonal_index_from_basis"):
		return 0
	var snapped_rotation: float = snappedf(rotation_degrees, 90.0)
	var basis := Basis(Vector3.UP, deg_to_rad(snapped_rotation))
	return int(grid_map.call("get_orthogonal_index_from_basis", basis))


func _coerce_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		var vector2: Vector2 = value
		return Vector2i(roundi(vector2.x), roundi(vector2.y))
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2i(roundi(float(dict.get("x", 0))), roundi(float(dict.get("y", 0))))
	if value is Array:
		var array: Array = Array(value)
		if array.size() >= 2:
			return Vector2i(roundi(float(array[0])), roundi(float(array[1])))
	return Vector2i.ZERO


func _coerce_vector3(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector3(float(dict.get("x", 0.0)), float(dict.get("y", 0.0)), float(dict.get("z", 0.0)))
	if value is Array:
		var array: Array = Array(value)
		if array.size() >= 3:
			return Vector3(float(array[0]), float(array[1]), float(array[2]))
	return Vector3.ZERO


func _coerce_vector3i(value: Variant) -> Vector3i:
	if value is Vector3i:
		return value
	if value is Vector3:
		var vector3: Vector3 = value
		return Vector3i(roundi(vector3.x), roundi(vector3.y), roundi(vector3.z))
	if value is Array:
		var array: Array = Array(value)
		if array.size() >= 3:
			return Vector3i(roundi(float(array[0])), roundi(float(array[1])), roundi(float(array[2])))
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector3i(roundi(float(dict.get("x", 0))), roundi(float(dict.get("y", 0))), roundi(float(dict.get("z", 0))))
	return Vector3i.ZERO


func _make_node_name(type_id: String) -> String:
	var parts := type_id.split("_", false)
	var result := ""
	for part in parts:
		result += part.capitalize()
	return result
