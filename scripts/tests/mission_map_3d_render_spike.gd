extends Node3D

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_renderer.gd")

@export var map_path: String = "res://maps/test_mission_32x32_slots8.json"

var render_result: Dictionary = {}


func _ready() -> void:
	_ensure_camera_and_light()
	render_map()


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
	camera.size = 58.0
	camera.position = Vector3(32.0, 34.0, 46.0)
	camera.look_at(Vector3(31.0, 0.0, 31.0), Vector3.UP)

	var light := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if light == null:
		light = DirectionalLight3D.new()
		light.name = "DirectionalLight3D"
		add_child(light)
	light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	light.light_energy = 1.6
