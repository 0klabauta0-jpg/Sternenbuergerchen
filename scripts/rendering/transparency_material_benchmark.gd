extends Node3D

const MATERIAL_PRESET_FACTORY_SCRIPT: GDScript = preload("res://scripts/rendering/material_preset_factory.gd")


func _ready() -> void:
	if get_child_count() == 0:
		build_preview_nodes()


func build_preview_nodes() -> void:
	for child in get_children():
		child.queue_free()
	var preset_ids: PackedStringArray = MATERIAL_PRESET_FACTORY_SCRIPT.call("get_preset_ids")
	var x_offset: float = -1.6
	for preset_id_variant in preset_ids:
		var preset_id: String = String(preset_id_variant)
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = _node_name_for_preset(preset_id)
		var quad := QuadMesh.new()
		quad.size = Vector2(1.0, 1.0)
		mesh_instance.mesh = quad
		mesh_instance.position = Vector3(x_offset, 0.0, 0.0)
		mesh_instance.set_surface_override_material(0, MATERIAL_PRESET_FACTORY_SCRIPT.call("create_material", preset_id, _preview_color_for_preset(preset_id)))
		mesh_instance.set_meta("transparency_preset_id", preset_id)
		add_child(mesh_instance)
		x_offset += 1.6


func get_benchmark_snapshot() -> Dictionary:
	var preset_nodes: Array = []
	for child in get_children():
		if not (child is MeshInstance3D):
			continue
		preset_nodes.append({
			"node_name": child.name,
			"preset_id": String(child.get_meta("transparency_preset_id", "")),
			"has_mesh": (child as MeshInstance3D).mesh != null,
			"has_material": (child as MeshInstance3D).get_surface_override_material(0) != null,
		})
	return {
		"scene_id": "transparent_material_benchmark",
		"visual_only": true,
		"ui_sets_gameplay_truth": false,
		"preset_nodes": preset_nodes,
		"preset_node_count": preset_nodes.size(),
	}


func _node_name_for_preset(preset_id: String) -> String:
	match preset_id:
		"cutout_scissor":
			return "CutoutScissor"
		"dither_hash":
			return "DitherHash"
		"true_blend":
			return "TrueBlend"
		_:
			return "UnknownPreset"


func _preview_color_for_preset(preset_id: String) -> Color:
	match preset_id:
		"cutout_scissor":
			return Color(0.3, 0.9, 0.55, 0.75)
		"dither_hash":
			return Color(0.7, 0.9, 0.35, 0.55)
		"true_blend":
			return Color(0.35, 0.8, 1.0, 0.45)
		_:
			return Color.WHITE
