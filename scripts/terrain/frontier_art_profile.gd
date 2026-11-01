class_name FrontierArtProfile
extends RefCounted
## Approved illustrated frontier family. Visual resources only; owns no map facts.

const PROFILE_ID := "frontier_illustrated_v1"
const GROUND_SHADER = preload("res://shaders/terrain/frontier_ground.gdshader")
const SURFACE_COLORS := {
	"ground": Color("c58d62"),
	"sand": Color("e3bd8c"),
	"road": Color("bda07c"),
	"rock": Color("b87551"),
	"water": Color("638f9a"),
}
var _materials: Dictionary = {}

func surface_color(surface_type: String) -> Color:
	return SURFACE_COLORS.get(surface_type, SURFACE_COLORS["ground"])

func material_for(color: Color, rock: bool = false) -> ShaderMaterial:
	var key := "%s:%s" % [color.to_html(), str(rock)]
	if _materials.has(key):
		return _materials[key]
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("rock_strata", rock)
	_materials[key] = material
	return material

func apply_environment(environment: Environment) -> void:
	environment.background_color = Color("a7cad4")
	environment.ambient_light_color = Color("b6c7ce")
	environment.ambient_light_energy = 0.28
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 0.9
	environment.adjustment_brightness = 1.0
	environment.adjustment_contrast = 1.03
	environment.adjustment_saturation = 1.04
	environment.ssao_enabled = true
	environment.ssao_radius = 0.18
	environment.ssao_intensity = 1.2

func apply_light(light: DirectionalLight3D) -> void:
	light.light_color = Color("fff8ed")
	light.light_energy = 0.85
	light.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	light.shadow_opacity = 0.62
	light.shadow_blur = 1.8
	light.shadow_normal_bias = 0.45
	light.shadow_bias = 0.025
	light.directional_shadow_max_distance = 45.0
