extends Node3D

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

@export var map_file_path: String = "res://maps/Ground_Mission01_32x32.json"

var _primary_view: CanvasLayer = null


func _ready() -> void:
	_ensure_primary_view()
	_load_map_into_primary_view()


func get_calibration_snapshot() -> Dictionary:
	if _primary_view == null or not _primary_view.has_method("get_render_snapshot"):
		return {}
	return Dictionary(_primary_view.call("get_render_snapshot"))


func _ensure_primary_view() -> void:
	_primary_view = get_node_or_null("Primary3DView") as CanvasLayer
	if _primary_view != null:
		return
	_primary_view = TERRAIN_MAP_3D_VIEW_SCRIPT.new() as CanvasLayer
	_primary_view.name = "Primary3DView"
	add_child(_primary_view)


func _load_map_into_primary_view() -> void:
	if _primary_view == null:
		return
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", map_file_path)
	if terrain_map_data == null or Array(terrain_map_data.call("get_tiles")).is_empty():
		terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "mission_map_3d_calibration", Vector2i(8, 8), Vector2.ZERO)
	_primary_view.call("configure_from_map", terrain_map_data)
	_primary_view.call("focus_map_center")
