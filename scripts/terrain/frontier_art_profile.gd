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
## Render-only: true when sand cells are narrow strips on firmer ground.
var trail_surface: bool = false
## Render-only: 1.0 paints roads into the ground, lower under a built road deck.
var road_paint_strength: float = 1.0

## Versuch Bodentexturen: kachelbare Texturen am Boden-Shader. Der Schalter ist
## global (alle Ansichten, alle Bodenmaterialien); AUS ergibt das bisherige Bild.
const GROUND_TILE_DIR := "res://art/ground_tiles_20261124/"
const GROUND_TILE_FILES := {
	"ground_tex_normal": "boden_11_fels_rot_ruhig.png",
	"ground_tex_gravel": "boden_09_fels_rot_geroell.png",
	"ground_tex_clay": "boden_06_lehm_rissig_rost.png",
	"ground_tex_rock": "boden_01_fels_dunkelrot.png",
	"ground_tex_base": "boden_03_basis_betonplatten.png",
	"ground_tex_paving": "boden_08_bodenplatten_graubraun.png",
	# Grafik 1 (27.11.): nur in der Einsatz-Stimmung benutzt (Shader-Schalter mission_variation).
	# 02 (comicartig, nur 512 px) bleibt bewusst draussen: Stilbruch zu den anderen Kacheln.
	"ground_tex_rock_canyon": "boden_04_canyon_geschichtet.png",
	"ground_tex_rock_light": "boden_05_sandstein_hell.png",
	"ground_tex_sand": "boden_07_staub_orange_kiesel.png",
	"ground_tex_paving_edge": "boden_10_staub_rot_grauplatten.png",
}
## Stellschrauben (die Vorgaben im Shader sind dieselben Werte).
const GROUND_TILE_METERS := 4.0       # Kantenlaenge einer Kachel in Metern, ein Feld ist etwa 1 m
const GROUND_TILE_BRIGHTNESS := 0.92  # die EINE Helligkeit fuer alle Bodentexturen
const GROUND_BASE_TILE_GAIN := 0.45   # Heimatbasis-Beton ist sehr hell, wird extra gedaempft
const GROUND_DETAIL_KEEP := 0.35      # Rest der zoomabhaengigen Abdunklung (Kiesel, Risse, Wellen)
static var ground_tiles_enabled: bool = true
static var _ground_tile_textures: Dictionary = {}
static var _ground_tile_materials: Array = []

static func ground_tiles_on() -> bool:
	return ground_tiles_enabled

## Legt den Schalter um und gibt ihn an alle noch lebenden Bodenmaterialien weiter.
static func set_ground_tiles(on: bool) -> void:
	ground_tiles_enabled = on
	var alive: Array = []
	for ref in _ground_tile_materials:
		var material = ref.get_ref()
		if material != null:
			material.set_shader_parameter("ground_tiles_enabled", on)
			alive.append(ref)
	_ground_tile_materials = alive

## Jedes Material mit dem Boden-Shader meldet sich hier an: Texturen setzen, Schalter uebernehmen.
static func register_ground_material(material: ShaderMaterial) -> void:
	material.set_shader_parameter("ground_tiles_enabled", ground_tiles_enabled)
	material.set_shader_parameter("ground_tile_meters", GROUND_TILE_METERS)
	material.set_shader_parameter("ground_tile_brightness", GROUND_TILE_BRIGHTNESS)
	material.set_shader_parameter("ground_base_tile_gain", GROUND_BASE_TILE_GAIN)
	material.set_shader_parameter("ground_detail_keep", GROUND_DETAIL_KEEP)
	for uniform_name in GROUND_TILE_FILES:
		material.set_shader_parameter(uniform_name, _ground_texture(String(uniform_name)))
	if _ground_tile_materials.size() >= 256:
		var alive: Array = []
		for ref in _ground_tile_materials:
			if ref.get_ref() != null:
				alive.append(ref)
		_ground_tile_materials = alive
	_ground_tile_materials.append(weakref(material))

## Die Texturen kommen mit Mipmaps an den Shader, auch wenn der Import keine erzeugt hat.
static func _ground_texture(uniform_name: String) -> Texture2D:
	if _ground_tile_textures.has(uniform_name):
		return _ground_tile_textures[uniform_name]
	var source := load(GROUND_TILE_DIR + String(GROUND_TILE_FILES[uniform_name])) as Texture2D
	var result: Texture2D = source
	if source != null:
		var image := source.get_image()
		if image != null and not image.is_empty():
			if image.is_compressed():
				image.decompress()
			if not image.has_mipmaps():
				image.generate_mipmaps()
			result = ImageTexture.create_from_image(image)
	_ground_tile_textures[uniform_name] = result
	return result

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
	register_ground_material(material)
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
	# One cascade: texel size is constant across the picture and there are no
	# cascade seams that travel through the view while zooming.
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	light.directional_shadow_fade_start = 0.95
	light.shadow_normal_bias = 0.25
	light.shadow_bias = 0.04
	if homebase_palette or quiet_tactical_surface:
		# Flat rock crowns and wide ground showed striped self-shadowing.
		# That was tuned against four cascades with a large bias (1.0 / 0.075),
		# which detached shadows from building bases. With one cascade the
		# texel size is the same everywhere, so the small bias above holds;
		# flat ground caps cast no shadow anyway (hex_ground_batch.gd).
		light.shadow_normal_bias = 0.25
		light.shadow_bias = 0.04
	# Start width; the map view re-sets it from the camera size (see below).
	light.directional_shadow_max_distance = SHADOW_DISTANCE_STAGES[0][1]

## ---- Grafik 1 (27.11.): Einsatz-Stimmung -------------------------------------
## Nur Darstellung. Wird von der Kartenansicht NUR eingeschaltet, wenn der Einsatz
## sie ausdruecklich anfordert (set_mission_atmosphere_enabled); Heimatbasis,
## Raumstation und Karteneditor bleiben bei ihren Werten.
const MISSION_SKY_SHADER = preload("res://shaders/terrain/mission_sky.gdshader")
const MISSION_SHADOW_OPACITY := 0.70
const MISSION_AMBIENT_ENERGY := 0.60       # Sky-Ambient: Verlauf violett (oben) bis rostorange (unten)
const MISSION_AMBIENT_COLOR := Color("9c8aa8")  # nur Rueckfall/Anzeige, solange die Quelle der Himmel ist
const MISSION_BACKGROUND_COLOR := Color("8f5a44")  # Kartenrand: staubiger Bodenton, etwas dunkler als der Boden
const MISSION_FOG_COLOR := Color("c9996f")  # warmer Staub
const MISSION_FOG_HEIGHT := 1.0             # Meter ueber der Bodenebene: darunter sammelt sich Staub
const MISSION_FOG_HEIGHT_DENSITY := 0.07
const MISSION_GLOW_THRESHOLD := 1.5
const MISSION_GLOW_INTENSITY := 0.30
const MISSION_GRID_COLOR := Color(0.36, 0.19, 0.12, 1.0)  # warme dunkle Rosttinte (Elfenbein war in Nahsicht zu auffaellig)
const MISSION_GRID_ALPHA_NEAR := 0.28
const MISSION_GRID_ALPHA_FAR := 0.12
const MISSION_GRID_FADE_FROM := 34.0        # Kameragroesse "Standard"
const MISSION_GRID_FADE_TO := 90.0
const MISSION_SSAO_OFF_ABOVE := 56.0        # SSAO nur ab Standard-Zoom; Hysterese gegen Flackern
const MISSION_SSAO_ON_BELOW := 48.0
const MISSION_VARIATION_STRENGTH := 1.0
var mission_atmosphere: bool = false
var _mission_sky: Sky

func apply_mission_environment(environment: Environment, ssao_on: bool, draw_sky: bool) -> void:
	if _mission_sky == null:
		_mission_sky = Sky.new()
		var sky_material := ShaderMaterial.new()
		sky_material.shader = MISSION_SKY_SHADER
		_mission_sky.sky_material = sky_material
		_mission_sky.radiance_size = Sky.RADIANCE_SIZE_32
	if environment.sky != _mission_sky:
		environment.sky = _mission_sky
	# draw_sky=false (echte Karten mit eigenem dunklen Aussenrand) zeichnet die Farbe,
	# nutzt den Himmel aber trotzdem fuer das Umgebungslicht.
	# Nachbesserung 27.11.: der sichtbare Himmelsverlauf liess die Karte wie eine Insel in der
	# Luft schweben. Der Himmel zeichnet hinter der Karte darum einen einfarbigen staubigen
	# Bodenton (mission_sky.gdshader, offmap_color); sein Verlauf speist nur das Umgebungslicht.
	# (BG_COLOR mit demselben Ton wurde unter ACES fast schwarz.)
	environment.background_mode = Environment.BG_SKY if draw_sky else Environment.BG_COLOR
	if draw_sky:
		environment.background_color = MISSION_BACKGROUND_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 1.0
	environment.ambient_light_color = MISSION_AMBIENT_COLOR
	environment.ambient_light_energy = MISSION_AMBIENT_ENERGY
	environment.ssao_enabled = ssao_on
	# Duenner Staub nur in Senken: ohne Entfernungsnebel, nur Hoehennebel unter MISSION_FOG_HEIGHT.
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	environment.fog_density = 0.0
	environment.fog_light_color = MISSION_FOG_COLOR
	environment.fog_light_energy = 1.0
	environment.fog_sun_scatter = 0.0
	environment.fog_aerial_perspective = 0.0
	environment.fog_sky_affect = 0.0
	environment.fog_height = MISSION_FOG_HEIGHT
	environment.fog_height_density = MISSION_FOG_HEIGHT_DENSITY
	# Glow nur fuer sehr helle Stellen (Lampen, Muendungsfeuer, Triebwerke).
	environment.glow_enabled = true
	environment.glow_hdr_threshold = MISSION_GLOW_THRESHOLD
	environment.glow_intensity = MISSION_GLOW_INTENSITY
	environment.glow_strength = 0.9
	environment.glow_bloom = 0.0
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE

func apply_mission_light(light: DirectionalLight3D) -> void:
	light.light_color = Color("ffe9c9")
	light.shadow_opacity = MISSION_SHADOW_OPACITY

static func mission_ssao_wanted(camera_size: float, previously_on: bool) -> bool:
	return camera_size <= (MISSION_SSAO_OFF_ABOVE if previously_on else MISSION_SSAO_ON_BELOW)

## Gitter-Deckkraft zur Kameragroesse: 0,35 bis Standard-Zoom, dann weich Richtung 0,15.
## In Hundertstel gerundet, damit sich beim Zoomen nicht jeden Schritt etwas aendert.
static func mission_grid_alpha(camera_size: float) -> float:
	var t := smoothstep(MISSION_GRID_FADE_FROM, MISSION_GRID_FADE_TO, camera_size)
	return snappedf(lerpf(MISSION_GRID_ALPHA_NEAR, MISSION_GRID_ALPHA_FAR, t), 0.01)

## Schaltet die Einsatz-Stimmung des Bodens (Rauschen, neue Kacheln) an allen Materialien dieses Profils.
func set_mission_atmosphere(on: bool) -> void:
	if mission_atmosphere == on:
		return
	mission_atmosphere = on
	for material in _materials.values():
		material.set_shader_parameter("mission_variation", _mission_variation_value())

func _mission_variation_value() -> float:
	return MISSION_VARIATION_STRENGTH if mission_atmosphere and not homebase_palette else 0.0

## Shadow reach in fixed stages tied to the orthogonal camera size S: the
## camera sits about 1.32 * S from the focus and the top edge of the picture
## about 2.03 * S, so every stage keeps width >= 2.1 * S up to its end size.
## Inside a stage the width never changes (no moving cascade or texel grid).
## `previous` is the width used so far (0 for none); stepping down needs a 10 %
## margin, so wheel steps back and forth over a stage edge do not flip it.
const SHADOW_DISTANCE_STAGES := [[26.0, 60.0], [50.0, 110.0], [115.0, 250.0]]
const SHADOW_DISTANCE_REACH := 2.1
const SHADOW_DISTANCE_ROUND := 50.0
const SHADOW_DISTANCE_SHRINK_MARGIN := 0.9

static func _shadow_distance_stage(size: float) -> float:
	for stage in SHADOW_DISTANCE_STAGES:
		if size <= float(stage[0]):
			return float(stage[1])
	return ceilf(SHADOW_DISTANCE_REACH * size / SHADOW_DISTANCE_ROUND) * SHADOW_DISTANCE_ROUND

static func shadow_distance_for_size(size: float, previous: float) -> float:
	var wanted := _shadow_distance_stage(size)
	if previous <= wanted:
		return wanted
	# Smaller than before: only drop when the size is clearly inside the lower stage.
	var lowered := _shadow_distance_stage(size / SHADOW_DISTANCE_SHRINK_MARGIN)
	return minf(previous, lowered)

func configure_surface_blend(tiles: Array, axis_q: Vector2, axis_r: Vector2) -> void:
	_blend=load("res://scripts/terrain/terrain_surface_blend.gd").build(tiles)
	if _blend.is_empty(): return
	var sand_cells := 0
	for tile in tiles:
		if String(tile.surface_type) == "sand": sand_cells += 1
	trail_surface = sand_cells > 0 and float(sand_cells) < float(tiles.size()) * 0.30
	_blend_texture=ImageTexture.create_from_image(_blend.image)
	var inverse := Transform2D(axis_q,axis_r,Vector2.ZERO).affine_inverse()
	_world_to_grid=Vector4(inverse.x.x,inverse.y.x,inverse.x.y,inverse.y.y)
	for material in _materials.values(): _apply_blend(material,bool(material.get_shader_parameter("rock_strata")))

func _apply_blend(material: ShaderMaterial, rock: bool) -> void:
	material.set_shader_parameter("homebase_palette", homebase_palette)
	material.set_shader_parameter("mission_variation", _mission_variation_value())
	material.set_shader_parameter("quiet_tactical_surface", quiet_tactical_surface)
	material.set_shader_parameter("trail_surface", trail_surface and not rock)
	material.set_shader_parameter("road_paint_strength", road_paint_strength)
	material.set_shader_parameter("surface_blending",not rock and not _blend.is_empty())
	if rock or _blend.is_empty(): return
	material.set_shader_parameter("surface_mask",_blend_texture)
	material.set_shader_parameter("surface_bounds",_blend.bounds)
	material.set_shader_parameter("world_to_grid",_world_to_grid)
