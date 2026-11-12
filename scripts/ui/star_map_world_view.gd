extends SubViewport
## Visual-only native spheres and models. Camera matches the hex canvas.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const BODY_SHADER = preload("res://shaders/strategic_body.gdshader")
const SHIP_VISUALS = preload("res://scripts/terrain/frontier_ship_visuals.gd")
const TILT := 0.72
const DISTANCE := 350.0
const SURFACE_NORMAL := Vector3(0.21, 0.86, 0.465)
var _camera: Camera3D
var _world: Node3D
var _spheres: Dictionary = {}
var _ships: Dictionary = {}

func _ready() -> void:
	transparent_bg = true
	own_world_3d = true
	size = Vector2i(32, 32)
	render_target_update_mode = UPDATE_DISABLED
	_world = Node3D.new()
	add_child(_world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("879cb9")
	environment.environment.ambient_light_energy = 0.30
	_world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -55, 0)
	light.light_color = Color("ffecd9")
	light.light_energy = 1.6
	_world.add_child(light)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.far = 700
	_world.add_child(_camera)

func update_camera(pixel_size: Vector2, pixels_per_unit: float, center: Vector2) -> void:
	size = Vector2i(pixel_size).max(Vector2i(32, 32))
	_camera.size = float(size.y) / pixels_per_unit
	var focus := Vector3(center.x, 0, center.y)
	_camera.look_at_from_position(focus + DISTANCE * Vector3(0, TILT, sqrt(1.0 - TILT * TILT)), focus)
	render_target_update_mode = UPDATE_ONCE

func update_bodies(bodies: Dictionary) -> void:
	for id in _spheres.keys():
		if not bodies.has(id):
			_spheres[id].queue_free()
			_spheres.erase(id)
	for id in bodies:
		var body: Dictionary = bodies[id]
		if not _spheres.has(id):
			var sphere := MeshInstance3D.new()
			var mesh := SphereMesh.new()
			mesh.radial_segments = 48
			mesh.rings = 24
			mesh.radius = 1.0
			mesh.height = 2.0
			if String(body.get("kind", "")) == "station":
				var hub := BoxMesh.new(); hub.size = Vector3(1.8, .35, 1.3)
				sphere.mesh = hub
				var ring := MeshInstance3D.new()
				var torus := TorusMesh.new(); torus.inner_radius = .85; torus.outer_radius = 1.0; torus.rings = 20; torus.ring_segments = 6
				ring.mesh = torus; ring.position.y = -.2
				var hull := StandardMaterial3D.new(); hull.albedo_color = Color("c9cbbd"); hull.roughness = .85
				ring.material_override = hull; sphere.add_child(ring)
			else:
				sphere.mesh = mesh
			var material := ShaderMaterial.new()
			material.shader = BODY_SHADER
			sphere.material_override = material
			_world.add_child(sphere)
			_spheres[id] = sphere
		var sphere: MeshInstance3D = _spheres[id]
		var material := sphere.material_override as ShaderMaterial
		material.set_shader_parameter("surface_color", Color(String(body.color)))
		material.set_shader_parameter("seed", float(String(id).hash() % 997))
		material.set_shader_parameter("star", id == "sun")
		var plane: Vector2 = GRID.pair(body.position) * GRID.EXTENT
		sphere.position = Vector3(plane.x, 0, plane.y)
		sphere.scale = Vector3.ONE * float(body.radius)
	render_target_update_mode = UPDATE_ONCE

func update_ships(travel: Dictionary) -> void:
	var routes: Dictionary = travel.get("routes", {String(travel.get("craft_id", "")): travel})
	for id in _ships.keys():
		if not routes.has(id):
			_ships[id].queue_free()
			_ships.erase(id)
	for id in routes:
		var route: Dictionary = routes[id]
		if id.is_empty() or String(route.get("phase", "grounded")) in ["grounded", "surface"]:
			if _ships.has(id):
				_ships[id].hide()
			continue
		if not _ships.has(id):
			var definition: Dictionary = SHIP_VISUALS.get_for_role("dropship")
			var scene: PackedScene = load(String(definition.get("model_path", ""))) as PackedScene
			if scene == null:
				continue
			var model := scene.instantiate() as Node3D
			model.scale = Vector3.ONE * (0.84 / float(definition.bounds_size[2]))
			_world.add_child(model)
			_ships[id] = model
		var ship: Node3D = _ships[id]
		var plane: Vector2 = GRID.pair(route.get("position", [])) * GRID.EXTENT
		ship.position = Vector3(plane.x, 0, plane.y)
		ship.rotation.y = PI * 0.5 - float(route.get("heading", 0.0))
		ship.show()
	render_target_update_mode = UPDATE_ONCE

func surface_hex(body: Dictionary) -> PackedVector2Array:
	var projected := PackedVector2Array()
	var plane: Vector2 = GRID.pair(body.position) * GRID.EXTENT
	var center := Vector3(plane.x, 0.0, plane.y)
	var radius := float(body.radius)
	var u := Vector3.RIGHT.slide(SURFACE_NORMAL).normalized()
	var v := SURFACE_NORMAL.cross(u).normalized()
	var marker_radius := minf(radius * 0.32, 0.46)
	for index in range(6):
		var angle := TAU * float(index) / 6.0 + PI / 6.0
		var normal := (SURFACE_NORMAL + (cos(angle) * u + sin(angle) * v) * marker_radius / radius).normalized()
		projected.append(_camera.unproject_position(center + normal * (radius + 0.004)))
	return projected
