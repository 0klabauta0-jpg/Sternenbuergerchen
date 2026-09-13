extends RefCounted
## Small rendering helpers. No simulation state or input ownership.

static func material(color: Color, metal: float = 0.0, glow: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.84
	mat.metallic = metal
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	return mat

static func box(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color, metal: float = 0.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.material_override = material(color, metal)
	parent.add_child(instance)
	instance.position = at
	return instance

static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color, sides: int = 12) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	instance.mesh = mesh
	instance.material_override = material(color)
	parent.add_child(instance)
	instance.position = at
	return instance

static func label(parent: Node3D, text: String, at: Vector3, color: Color, size: int = 24) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.position = at
	node.font_size = size
	node.pixel_size = 0.030
	node.modulate = color
	node.outline_modulate = Color("17242c")
	node.outline_size = 5
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.no_depth_test = true
	parent.add_child(node)
	return node

static func ring(parent: Node3D, radius: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.055
	mesh.outer_radius = radius + 0.055
	mesh.rings = 32
	mesh.ring_segments = 5
	node.mesh = mesh
	node.material_override = material(color, 0.0, 0.7)
	node.position.y = 0.065
	parent.add_child(node)
	return node

static func collider(parent: Node3D, kind: String, id: String, size: Vector3, offset: Vector3 = Vector3.ZERO) -> void:
	var body := StaticBody3D.new()
	body.set_meta("kind", kind)
	body.set_meta("id", id)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position = offset + Vector3(0, size.y * 0.5, 0)
	body.add_child(shape)
	parent.add_child(body)

static func asset(parent: Node3D, name: String, at: Vector3, dimensions: Vector3, yaw: float = 0.0) -> Node3D:
	var pivot := Node3D.new()
	parent.add_child(pivot)
	pivot.position = at
	pivot.rotation.y = yaw
	var pack := "space-station"
	if name.begins_with("character"):
		pack = "characters"
	elif name.begins_with("crate"):
		pack = "blaster"
	elif name == "workbench":
		pack = "survival"
	elif name == "craft_cargoA":
		pack = "space"
	elif name == "white_astronaut":
		pack = "crew"
	var path := "res://assets/curated/%s/%s.glb" % [pack,name]
	if name == "craft_cargoA" and FileAccess.file_exists("res://assets/local/entersaebel.glb"):
		path = "res://assets/local/entersaebel.glb"
	if name == "freibeuter":
		path = "res://assets/local/freibeuter/freibeuter.glb"
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Required curated asset missing: " + name)
		return pivot
	var instance := packed.instantiate() as Node3D
	pivot.add_child(instance)
	var bounds := _bounds(instance, Transform3D.IDENTITY)
	var ratio := Vector3(dimensions.x / maxf(bounds.size.x, 0.001), dimensions.y / maxf(bounds.size.y, 0.001), dimensions.z / maxf(bounds.size.z, 0.001))
	if name in ["craft_cargoA","freibeuter"]:
		ratio = Vector3.ONE * dimensions.z / maxf(bounds.size.z,0.001)
	if name == "white_astronaut":
		ratio = Vector3.ONE * dimensions.y / maxf(bounds.size.y,0.001)
	instance.scale = ratio
	instance.position = -Vector3(bounds.position.x + bounds.size.x * 0.5, bounds.position.y, bounds.position.z + bounds.size.z * 0.5) * ratio
	if name == "floor":
		_tint(instance,material(Color("899da5"),0.15))
	return pivot

static func _tint(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_tint(child,mat)

static func fade_asset(node: Node, opacity: float) -> void:
	# Keep the imported wall textures; fade only this instance, never the shared asset.
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in range(instance.mesh.get_surface_count()):
			var source := instance.get_active_material(surface) as StandardMaterial3D
			if source != null:
				var faded := source.duplicate() as StandardMaterial3D
				faded.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				faded.albedo_color.a = opacity
				instance.set_surface_override_material(surface,faded)
	for child in node.get_children():
		fade_asset(child,opacity)

static func _bounds(node: Node3D, transform: Transform3D) -> AABB:
	var current := transform * node.transform
	var result := AABB()
	var valid := false
	if node is MeshInstance3D:
		result = current * (node as MeshInstance3D).get_aabb()
		valid = true
	for child in node.get_children():
		if child is Node3D:
			var child_bounds := _bounds(child, current)
			if child_bounds.size.length_squared() > 0.0:
				result = result.merge(child_bounds) if valid else child_bounds
				valid = true
	return result

static func set_pickable(node: Node, enabled: bool) -> void:
	if node is CollisionObject3D:
		(node as CollisionObject3D).collision_layer=1 if enabled else 0
	for child in node.get_children(): set_pickable(child,enabled)
