extends RefCounted
## Authored wall-center material split on the same immutable thin Hex floor.
const SHADER = preload("res://shaders/terrain/station_floor_boundary.gdshader")
var _materials: Dictionary = {}
var build_count := 0

func material_for(source: Material, bounds: Rect2, exterior: Color) -> Material:
	var standard := source as StandardMaterial3D
	if standard == null or not bounds.has_area(): return source
	var key: String = str([source.get_instance_id(), bounds, exterior])
	if _materials.has(key): return _materials[key]
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("inside_color", standard.albedo_color)
	material.set_shader_parameter("outside_color", exterior)
	material.set_shader_parameter("has_floor_texture", standard.albedo_texture != null)
	if standard.albedo_texture != null: material.set_shader_parameter("floor_texture", standard.albedo_texture)
	material.set_shader_parameter("floor_bounds", Vector4(bounds.position.x, bounds.position.y, bounds.end.x, bounds.end.y))
	material.set_shader_parameter("floor_metallic", standard.metallic)
	material.set_shader_parameter("floor_roughness", standard.roughness)
	_materials[key] = material
	build_count += 1
	return material

func apply_model(node: Node, bounds: Rect2, exterior: Color) -> void:
	if not bounds.has_area(): return
	if node is MeshInstance3D and node.mesh != null:
		if node.material_override != null:
			node.material_override = material_for(node.material_override, bounds, exterior)
		else:
			for surface in range(node.mesh.get_surface_count()):
				node.set_surface_override_material(surface, material_for(node.get_active_material(surface), bounds, exterior))
	for child: Node in node.get_children(): apply_model(child, bounds, exterior)
