extends Node3D

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_renderer.gd")

@export var map_path: String = "res://maps/test_mission_32x32_slots8.json"

var render_result: Dictionary = {}


func _ready() -> void:
	_ensure_camera_and_light()
	render_map()
	_frame_camera_on_objects()


func render_map() -> Dictionary:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", map_path)
	var map_root := get_node_or_null("MapRoot") as Node3D
	if map_root == null:
		map_root = Node3D.new()
		map_root.name = "MapRoot"
		add_child(map_root)
	var renderer = TERRAIN_MAP_3D_RENDERER_SCRIPT.new()
	render_result = renderer.call("render_map", map_data, map_root)
	return render_result


func _ensure_camera_and_light() -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14.0
	camera.position = Vector3(16.0, 18.0, 23.0)
	camera.look_at(Vector3(15.5, 0.0, 15.5), Vector3.UP)

	var light := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if light == null:
		light = DirectionalLight3D.new()
		light.name = "DirectionalLight3D"
		add_child(light)
	light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	light.light_energy = 1.6


func _frame_camera_on_objects() -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		return
	var stats: Dictionary = Dictionary(render_result.get("stats", {}))
	var focus: Vector3 = Vector3(stats.get("object_focus", Vector3(15.5, 0.0, 15.5)))
	var camera_offset := Vector3(7.5, 9.0, 10.5)
	camera.size = 12.0 if int(stats.get("object_count", 0)) > 0 else 26.0
	camera.position = focus + camera_offset
	camera.look_at(focus, Vector3.UP)
