extends SceneTree
## Grafik 1 (27.11.): Einsatz-Stimmung. Kopflos, rechnend, ohne Karte.
## Start: godot_console.exe --headless --path . --script res://scripts/tests/mission_atmosphere_20261127_verifier.gd
## (mit umgebogenem APPDATA). Erwartet "MISSION_ATMOSPHERE passed=N failed=0".

const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
const SHADER_PATH := "res://shaders/terrain/frontier_ground.gdshader"
const SKY_PATH := "res://shaders/terrain/mission_sky.gdshader"
const NEW_TILES := {
	"ground_tex_rock_canyon": "boden_04_canyon_geschichtet.png",
	"ground_tex_rock_light": "boden_05_sandstein_hell.png",
	"ground_tex_sand": "boden_07_staub_orange_kiesel.png",
	"ground_tex_paving_edge": "boden_10_staub_rot_grauplatten.png",
}

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL " + label)
		print("FAIL ", label)


func _env(view) -> Environment:
	var holder = view.get("_environment")
	return holder.environment if holder != null else null


func _light(view) -> DirectionalLight3D:
	var world_root = view.get("_world_root")
	return world_root.get_node_or_null(VIEW.LIGHT_NAME) as DirectionalLight3D if world_root != null else null


func _make_view(frontier: bool, homebase: bool, mission: bool):
	var host := Node2D.new()
	root.add_child(host)
	var view = VIEW.new()
	view.name = "Primary3DView"
	host.add_child(view)
	view.set_process(false)
	if frontier:
		view.call("set_frontier_art_enabled", true)
	if homebase:
		view.call("set_homebase_visuals_enabled", true)
	if mission:
		view.call("set_mission_atmosphere_enabled", true)
	return view


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_check_files()
	await _check_mission()
	await _check_untouched()
	_check_zoom_helpers()
	print("MISSION_ATMOSPHERE passed=%d failed=%d" % [checks - failures, failures])
	quit(1 if failures > 0 else 0)


func _check_files() -> void:
	for uniform_name in NEW_TILES:
		var path: String = PROFILE.GROUND_TILE_DIR + String(NEW_TILES[uniform_name])
		var texture := load(path) as Texture2D
		check(texture != null, "Neue Kachel laedt: " + path)
		if texture != null:
			check(texture.get_width() == 1024 and texture.get_height() == 1024, "Kachel 1024 x 1024: " + path)
		check(String(PROFILE.GROUND_TILE_FILES.get(uniform_name, "")) == String(NEW_TILES[uniform_name]), "Profil kennt " + String(uniform_name))
	var shader := load(SHADER_PATH) as Shader
	check(shader != null, "Boden-Shader laedt")
	if shader != null:
		var names := {}
		for entry in shader.get_shader_uniform_list():
			names[String(entry["name"])] = true
		for uniform_name in NEW_TILES.keys() + ["mission_variation", "ground_rock_light_threshold"]:
			check(names.has(uniform_name), "Shader kennt Uniform " + String(uniform_name))
	check(load(SKY_PATH) as Shader != null, "Himmel-Shader laedt")
	var profile = PROFILE.new()
	var material: ShaderMaterial = profile.surface_material_for("ground")
	check(float(material.get_shader_parameter("mission_variation")) == 0.0, "Boden-Rauschen standardmaessig aus")
	profile.set_mission_atmosphere(true)
	check(float(material.get_shader_parameter("mission_variation")) > 0.0, "Boden-Rauschen an bei Einsatz-Stimmung")
	profile.homebase_palette = true
	var home_material: ShaderMaterial = profile.surface_material_for("sand")
	check(float(home_material.get_shader_parameter("mission_variation")) == 0.0, "Heimatbasis-Palette: Rauschen aus")


func _check_mission() -> void:
	var view = _make_view(true, false, true)
	await process_frame
	check(bool(view.call("is_mission_atmosphere_active")), "Einsatz: Stimmung wirksam")
	var env := _env(view)
	var light := _light(view)
	check(env != null and light != null, "Einsatz: Umgebung und Licht vorhanden")
	if env != null and light != null:
		check(env.tonemap_mode == Environment.TONE_MAPPER_ACES, "Einsatz: ACES")
		check(light.shadow_opacity >= 0.65, "Einsatz: Schattendeckkraft >= 0,65 (%s)" % light.shadow_opacity)
		check(light.light_color.r > 0.95 and light.light_color.b < 0.9 and light.light_color.b > 0.7, "Einsatz: warme Sonne (%s)" % light.light_color.to_html())
		check(env.fog_enabled and env.fog_height_density > 0.0 and env.fog_density == 0.0, "Einsatz: Hoehennebel, kein Entfernungsnebel")
		check(env.glow_enabled and env.glow_hdr_threshold >= 1.2, "Einsatz: Glow nur fuer sehr Helles")
		check(env.background_mode == Environment.BG_SKY and env.sky != null and (env.sky.sky_material as ShaderMaterial).get_shader_parameter("screen_gradient") != true, "Einsatz: Himmel zeichnet einfarbigen Staubton hinter der Karte, Verlauf nur fuer das Umgebungslicht")
		check(env.background_color != VIEW.EDITOR_EMPTY_BACKGROUND_COLOR, "Einsatz: Hintergrund nicht BG_COLOR des Editors")
		check(env.ambient_light_source == Environment.AMBIENT_SOURCE_SKY, "Einsatz: warmes Umgebungslicht aus dem Himmelsverlauf")
		check(env.ambient_light_color.r > env.ambient_light_color.g, "Einsatz: Umgebungsfarbe warm-violett (rot vor gruen)")
		check(env.ssao_enabled, "Einsatz: SSAO bei Standard-Zoom an")
	# Zoom: Uebersicht ohne SSAO, Gitter schwaecher, zurueck mit Hysterese.
	view.set("_camera_size", 34.0)
	view.call("_update_camera_transform")
	check(_env(view).ssao_enabled, "Zoom 34: SSAO an")
	view.set("_camera_size", 100.0)
	view.call("_update_camera_transform")
	check(not _env(view).ssao_enabled, "Zoom 100: SSAO aus")
	view.set("_camera_size", 52.0)
	view.call("_update_camera_transform")
	check(not _env(view).ssao_enabled, "Zoom 52: SSAO bleibt aus (Hysterese)")
	view.set("_camera_size", 40.0)
	view.call("_update_camera_transform")
	check(_env(view).ssao_enabled, "Zoom 40: SSAO wieder an")
	# Hex-Gitter
	view.set("_active_grid_topology", "hex_axial_v1")
	view.set("_camera_size", 34.0)
	var grid_material: ShaderMaterial = view.call("_make_hex_grid_material", false)
	var near_color: Color = grid_material.get_shader_parameter("line_color")
	check(near_color.a <= 0.35 and near_color.a >= 0.2, "Gitter Standard-Zoom: Deckkraft 0,2-0,35 (%s)" % near_color.a)
	check(near_color.r < 0.5 and near_color.r > near_color.b, "Gitter: warme dunkle Rosttinte statt Cyan")
	view.set("_camera_size", 110.0)
	view.call("_update_camera_transform")
	var far_color: Color = grid_material.get_shader_parameter("line_color")
	check(far_color.a < near_color.a and far_color.a <= 0.2, "Gitter Uebersicht: noch schwaecher (%s)" % far_color.a)
	var snapshot: Dictionary = view.call("get_render_snapshot")
	check(float(snapshot.get("tile_grid_line_effective_alpha", 1.0)) <= 0.4, "Gitter ohne Hex-Weg: Deckkraft <= 0,4")
	view.get_parent().free()


func _check_untouched() -> void:
	# Editor: Frontier-Art aus, Einsatz-Anforderung bleibt wirkungslos.
	var editor_view = _make_view(false, false, true)
	await process_frame
	check(not bool(editor_view.call("is_mission_atmosphere_active")), "Editor/ohne Frontier: Stimmung unwirksam")
	var env := _env(editor_view)
	check(env != null and env.background_mode == Environment.BG_COLOR and env.background_color == VIEW.EDITOR_EMPTY_BACKGROUND_COLOR, "Editor: Hintergrund unveraendert")
	check(env != null and env.ambient_light_color == VIEW.EDITOR_AMBIENT_LIGHT_COLOR and is_equal_approx(env.ambient_light_energy, VIEW.EDITOR_AMBIENT_LIGHT_ENERGY), "Editor: Umgebungslicht unveraendert")
	check(env != null and env.tonemap_mode == Environment.TONE_MAPPER_FILMIC and not env.fog_enabled and not env.glow_enabled, "Editor: Filmic, kein Nebel, kein Glow")
	var editor_light := _light(editor_view)
	check(editor_light != null and is_equal_approx(editor_light.shadow_opacity, VIEW.EDITOR_LIGHT_SHADOW_OPACITY), "Editor: Schattendeckkraft unveraendert")
	editor_view.set("_active_grid_topology", "hex_axial_v1")
	var editor_grid: ShaderMaterial = editor_view.call("_make_hex_grid_material", false)
	check(editor_grid.get_shader_parameter("line_color").a >= 0.65, "Editor: Hex-Gitter unveraendert kraeftig")
	editor_view.get_parent().free()

	# Heimatbasis: Frontier + Heimatbasis-Palette, Einsatz-Anforderung bleibt wirkungslos.
	var home_view = _make_view(true, true, true)
	await process_frame
	check(not bool(home_view.call("is_mission_atmosphere_active")), "Heimatbasis: Stimmung unwirksam")
	var reference = PROFILE.new()
	reference.homebase_palette = true
	var reference_env := Environment.new()
	reference.apply_environment(reference_env)
	var home_env := _env(home_view)
	check(home_env != null and home_env.background_color == reference_env.background_color, "Heimatbasis: Hintergrund wie Frontier-Profil")
	check(home_env != null and home_env.ambient_light_color == reference_env.ambient_light_color and is_equal_approx(home_env.ambient_light_energy, reference_env.ambient_light_energy), "Heimatbasis: Umgebungslicht unveraendert")
	check(home_env != null and home_env.background_mode == Environment.BG_COLOR and not home_env.fog_enabled and not home_env.glow_enabled, "Heimatbasis: kein Himmel, kein Nebel, kein Glow")
	var home_light := _light(home_view)
	check(home_light != null and is_equal_approx(home_light.shadow_opacity, 0.72), "Heimatbasis: Schattendeckkraft 0,72 unveraendert")
	home_view.get_parent().free()


func _check_zoom_helpers() -> void:
	check(PROFILE.mission_grid_alpha(5.5) <= 0.35 and PROFILE.mission_grid_alpha(5.5) >= 0.2, "Gitter-Deckkraft nah ~0,28")
	check(PROFILE.mission_grid_alpha(34.0) <= 0.4, "Gitter-Deckkraft Standard <= 0,4")
	check(PROFILE.mission_grid_alpha(120.0) <= 0.16, "Gitter-Deckkraft Uebersicht ~0,12")
	check(PROFILE.mission_ssao_wanted(34.0, false) and not PROFILE.mission_ssao_wanted(100.0, true), "SSAO-Stufen")
