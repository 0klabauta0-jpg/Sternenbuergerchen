extends SubViewportContainer
## The same curated white astronaut, rendered in a private UI viewport.
var _viewport: SubViewport
var _figure: Node3D
var _helmet: Node3D
var _armor: MeshInstance3D
var _backpack: MeshInstance3D
var _tool: MeshInstance3D
var _medgun: MeshInstance3D

func _ready() -> void:
	custom_minimum_size = Vector2(244, 190)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(300, 480)
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	add_child(_viewport)
	var stage := Node3D.new()
	_viewport.add_child(stage)
	var packed: PackedScene = load("res://assets/curated/crew/white_astronaut.glb")
	_figure = packed.instantiate()
	stage.add_child(_figure)
	var bounds: AABB = _bounds(_figure, Transform3D.IDENTITY)
	var scale_factor: float = 1.95 / maxf(bounds.size.y, 0.01)
	_figure.scale = Vector3.ONE * scale_factor
	_figure.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_factor
	var helmets: Array[Node] = _figure.find_children("White_Astro_Helmet", "Node3D", true, false)
	if not helmets.is_empty(): _helmet = helmets[0]
	for node: Node in _figure.find_children("*", "AnimationPlayer", true, false):
		var player := node as AnimationPlayer
		if player.has_animation("Idle"):
			player.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
			player.play("Idle")
			player.advance(0)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.75
	camera.position = Vector3(2.3, 1.5, 5.5)
	camera.look_at(Vector3(0, 1.02, 0))
	var light := DirectionalLight3D.new()
	stage.add_child(light)
	light.rotation_degrees = Vector3(-38, -25, 0)
	light.light_energy = 1.2
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d7e8ed")
	environment.environment.ambient_light_energy = 0.7
	stage.add_child(environment)
	# Small separate presentation markers follow confirmed equipped slots.
	_armor = _box(stage, Vector3(0.48, 0.42, 0.13), Vector3(0, 1.2, 0.25), Color("bbcbd2"))
	_backpack = _box(stage, Vector3(0.43, 0.52, 0.25), Vector3(0, 1.1, -0.25), Color("7c929a"))
	_tool = _box(stage, Vector3(0.1, 0.32, 0.12), Vector3(-0.33, 0.75, 0.08), Color("dfad67"))
	_medgun = _box(stage, Vector3(0.12, 0.24, 0.14), Vector3(0.33, 0.76, 0.08), Color("8fcab4"))
	present({})

func present(equipment: Dictionary) -> void:
	if _armor == null: return
	if _helmet != null: _helmet.visible = not str(equipment.get("helmet", "basic_helmet")).is_empty()
	_armor.visible = not str(equipment.get("armor", "")).is_empty()
	_backpack.visible = not str(equipment.get("backpack", "")).is_empty()
	_tool.visible = not str(equipment.get("tool", "")).is_empty() and equipment.get("tool") != "medgun"
	_medgun.visible = equipment.get("tool") == "medgun"

func _box(parent: Node3D, dimensions: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance

func _bounds(node: Node, transform: Transform3D) -> AABB:
	var current: Transform3D = transform * node.transform if node is Node3D else transform
	var result := AABB()
	if node is MeshInstance3D and node.mesh != null: result = current * node.get_aabb()
	for child: Node in node.get_children():
		var child_bounds: AABB = _bounds(child, current)
		if child_bounds.size != Vector3.ZERO: result = child_bounds if result.size == Vector3.ZERO else result.merge(child_bounds)
	return result
