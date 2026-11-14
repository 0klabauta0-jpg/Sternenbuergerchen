class_name FrontierArtProfile
extends RefCounted
## Approved illustrated frontier family. Visual resources only; owns no map facts.

const PROFILE_ID := "frontier_illustrated_v1"
const GROUND_SHADER = preload("res://shaders/terrain/frontier_ground.gdshader")
const SURFACE_COLORS := {
	"ground": Color("a65c40"),
	"sand": Color("cf8a57"),
	"road": Color("858973"),
	"rock": Color("af573b"),
	"water": Color("638f9a"),
}
var _materials: Dictionary = {}
var _blend: Dictionary = {}
var _blend_texture: ImageTexture
var _world_to_grid := Vector4(1,0,0,1)
var homebase_palette: bool = false
var quiet_tactical_surface: bool = false

func surface_color(surface_type: String) -> Color:
	return SURFACE_COLORS.get(surface_type, SURFACE_COLORS["ground"])

func surface_material_for(surface_type: String, slope_softening: float = 0.0) -> ShaderMaterial:
	return material_for(surface_color(surface_type), false, surface_type == "road", slope_softening)

func material_for(color: Color, rock: bool = false, paved: bool = false, slope_softening: float = 0.0) -> ShaderMaterial:
	var key := "%s:%s:%s:%0.2f" % [color.to_html(), str(rock), str(paved), slope_softening]
	if _materials.has(key):
		return _materials[key]
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("rock_strata", rock)
	material.set_shader_parameter("paved_surface", paved)
	material.set_shader_parameter("slope_normal_softening", slope_softening)
	# Location-specific wear belongs to authored dressing, never generic maps.
	material.set_shader_parameter("authored_paving_wear", false)
	_apply_blend(material,rock)
	_materials[key] = material
	return material

func apply_environment(environment: Environment) -> void:
	environment.background_color = Color("aa6e58")
	# Grafikpass R1: cooler sky fill against a warmer sun, so shaded faces
	# turn towards violet-blue as in the landscape references.
	environment.ambient_light_color = Color("a9b6d8")
	environment.ambient_light_energy = 0.36
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	# Lower exposure keeps cream hulls and petrol roofs from clipping to white.
	environment.tonemap_exposure = 0.84
	environment.adjustment_brightness = 1.0
	environment.adjustment_contrast = 1.05
	environment.adjustment_saturation = 1.0
	environment.ssao_enabled = true
	environment.ssao_radius = 0.22
	environment.ssao_intensity = 1.35

func apply_light(light: DirectionalLight3D) -> void:
	light.light_color = Color("ffe9c9")
	light.light_energy = 0.98
	light.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	light.shadow_opacity = 0.72
	light.shadow_blur = 1.8
	light.shadow_normal_bias = 0.45
	light.shadow_bias = 0.025
	if homebase_palette or quiet_tactical_surface:
		# Flat rock crowns and wide ground showed striped self-shadowing.
		light.shadow_normal_bias = 1.0
		light.shadow_bias = 0.075
	light.directional_shadow_max_distance = 45.0

func configure_surface_blend(tiles: Array, axis_q: Vector2, axis_r: Vector2) -> void:
	_blend=load("res://scripts/terrain/terrain_surface_blend.gd").build(tiles)
	if _blend.is_empty(): return
	_blend_texture=ImageTexture.create_from_image(_blend.image)
	var inverse := Transform2D(axis_q,axis_r,Vector2.ZERO).affine_inverse()
	_world_to_grid=Vector4(inverse.x.x,inverse.y.x,inverse.x.y,inverse.y.y)
	for material in _materials.values(): _apply_blend(material,bool(material.get_shader_parameter("rock_strata")))

func _apply_blend(material: ShaderMaterial, rock: bool) -> void:
	material.set_shader_parameter("homebase_palette", homebase_palette)
	material.set_shader_parameter("quiet_tactical_surface", quiet_tactical_surface)
	material.set_shader_parameter("surface_blending",not rock and not _blend.is_empty())
	if rock or _blend.is_empty(): return
	material.set_shader_parameter("surface_mask",_blend_texture)
	material.set_shader_parameter("surface_bounds",_blend.bounds)
	material.set_shader_parameter("world_to_grid",_world_to_grid)
