class_name MaterialPresetFactory
extends RefCounted

const PRESET_CUTOUT_SCISSOR: String = "cutout_scissor"
const PRESET_DITHER_HASH: String = "dither_hash"
const PRESET_TRUE_BLEND: String = "true_blend"


static func get_preset_ids() -> PackedStringArray:
	return PackedStringArray([
		PRESET_CUTOUT_SCISSOR,
		PRESET_DITHER_HASH,
		PRESET_TRUE_BLEND,
	])


static func create_material(preset_id: String, albedo_color: Color = Color(1.0, 1.0, 1.0, 1.0)) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = "%s_material" % preset_id
	material.albedo_color = albedo_color
	material.vertex_color_use_as_albedo = false
	material.cull_mode = BaseMaterial3D.CULL_BACK
	match preset_id:
		PRESET_CUTOUT_SCISSOR:
			_apply_cutout_scissor(material)
		PRESET_DITHER_HASH:
			_apply_dither_hash(material)
		PRESET_TRUE_BLEND:
			_apply_true_blend(material)
		_:
			_apply_cutout_scissor(material)
	return material


static func create_all_presets() -> Dictionary:
	var result: Dictionary = {}
	for preset_id in get_preset_ids():
		result[String(preset_id)] = create_material(String(preset_id), _preview_color_for_preset(String(preset_id)))
	return result


static func build_preset_contract() -> Dictionary:
	return {
		"schema_version": 1,
		"factory_id": "material_preset_factory_v1",
		"visual_only": true,
		"ui_sets_gameplay_truth": false,
		"presets": {
			PRESET_CUTOUT_SCISSOR: {
				"transparency": "alpha_scissor",
				"use_for": ["hard_cutout_vegetation", "fences", "grates", "decals_with_hard_edges"],
				"avoid_for": ["glass", "smoke", "soft_holograms"],
			},
			PRESET_DITHER_HASH: {
				"transparency": "alpha_hash",
				"use_for": ["soft_vegetation_edges", "hair_cards", "noisy_energy_edges"],
				"avoid_for": ["large_smooth_glass", "dense_smoke"],
			},
			PRESET_TRUE_BLEND: {
				"transparency": "alpha_blend",
				"use_for": ["glass", "holograms", "smoke", "energy_effects"],
				"avoid_for": ["mass_instanced_cutouts", "solid_cover_props"],
			},
		},
	}


static func _apply_cutout_scissor(material: StandardMaterial3D) -> void:
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.5
	material.no_depth_test = false
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY


static func _apply_dither_hash(material: StandardMaterial3D) -> void:
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_HASH
	material.set("alpha_hash_scale", 0.6)
	material.no_depth_test = false
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY


static func _apply_true_blend(material: StandardMaterial3D) -> void:
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.no_depth_test = false
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	if material.albedo_color.a >= 0.99:
		var color: Color = material.albedo_color
		color.a = 0.55
		material.albedo_color = color


static func _preview_color_for_preset(preset_id: String) -> Color:
	match preset_id:
		PRESET_CUTOUT_SCISSOR:
			return Color(0.3, 0.9, 0.55, 0.75)
		PRESET_DITHER_HASH:
			return Color(0.7, 0.9, 0.35, 0.55)
		PRESET_TRUE_BLEND:
			return Color(0.35, 0.8, 1.0, 0.45)
		_:
			return Color.WHITE
