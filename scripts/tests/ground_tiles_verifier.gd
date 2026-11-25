extends SceneTree
## Bodentexturen (Versuch): sechs kachelbare Texturen am Bodenmaterial, Schalter
## `ground_tiles_enabled` im Frontier-Profil, Umschalt-Taste ueber echte Eingabe.
## Kopflos, rechnend. Ob der Shader fehlerfrei uebersetzt, zeigt zusaetzlich die
## Ausgabe: dort darf kein "SHADER ERROR" stehen (Pruefung von aussen).

const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
const SHADER_PATH := "res://shaders/terrain/frontier_ground.gdshader"
const DIR := "res://art/ground_tiles_20261124/"
const TEXTURES := {
	"ground_tex_normal": "boden_11_fels_rot_ruhig.png",
	"ground_tex_gravel": "boden_09_fels_rot_geroell.png",
	"ground_tex_clay": "boden_06_lehm_rissig_rost.png",
	"ground_tex_rock": "boden_01_fels_dunkelrot.png",
	"ground_tex_base": "boden_03_basis_betonplatten.png",
	"ground_tex_paving": "boden_08_bodenplatten_graubraun.png",
}
const UNIFORMS := ["ground_tiles_enabled", "ground_tile_meters", "ground_tile_brightness", "ground_base_tile_gain", "ground_detail_keep", "ground_patch_scale", "ground_patch_gravel", "ground_patch_clay", "ground_patch_softness"]

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


func _run() -> void:
	_check_files_and_shader()
	_check_profile_materials()
	await _check_views_and_key()
	print("GROUND_TILES passed=%d failed=%d" % [checks - failures, failures])
	quit(1 if failures > 0 else 0)


func _check_files_and_shader() -> void:
	for uniform_name in TEXTURES:
		var path: String = DIR + String(TEXTURES[uniform_name])
		var texture := load(path) as Texture2D
		check(texture != null, "Textur laedt: " + path)
		if texture != null:
			check(texture.get_width() == 1024 and texture.get_height() == 1024, "Textur 1024 x 1024: " + path)
	var shader := load(SHADER_PATH) as Shader
	check(shader != null, "Boden-Shader laedt")
	if shader == null:
		return
	# Heimatbasis nutzt den Normalboden (11 mit Flecken 09/06), keine eigene Basis-Textur 03.
	check(shader.code.contains("const bool GROUND_BASE_OWN_TEXTURE = false;"), "Heimatbasis: Basis nutzt den Normalboden, keine eigene Textur 03")
	var names := {}
	for entry in shader.get_shader_uniform_list():
		names[String(entry["name"])] = true
	for uniform_name in TEXTURES.keys() + UNIFORMS:
		check(names.has(uniform_name), "Shader kennt Uniform " + uniform_name)


func _ground_materials(profile) -> Array:
	# Echte Bodenmaterialien des Profils: Boden, Weg, Fels, Rampe.
	var list: Array = []
	list.append(profile.surface_material_for("ground"))
	list.append(profile.surface_material_for("sand"))
	list.append(profile.surface_material_for("road"))
	list.append(profile.surface_material_for("ground", 0.08))
	list.append(profile.material_for(Color("a56847"), true))
	return list


func _check_profile_materials() -> void:
	_set_flag(true)
	var profile = PROFILE.new()
	check(_flag(), "ground_tiles_enabled ist im Frontier-Profil an (Vorgabe)")
	for material in _ground_materials(profile):
		check(material != null and material.shader != null, "Bodenmaterial hat gueltigen Shader")
		check(bool(material.get_shader_parameter("ground_tiles_enabled")), "Material: ground_tiles_enabled an")
		for uniform_name in TEXTURES:
			var texture = material.get_shader_parameter(uniform_name) as Texture2D
			check(texture != null, "Material: Textur gesetzt " + uniform_name)
			if texture != null:
				check(texture.get_width() == 1024 and texture.get_height() == 1024, "Material: Textur 1024 x 1024 " + uniform_name)
	# Kachelgroesse etwa vier Felder, Helligkeit nicht ueber dem alten Bild.
	var ground = profile.surface_material_for("ground")
	var meters = ground.get_shader_parameter("ground_tile_meters")
	check(meters != null and float(meters) >= 3.0 and float(meters) <= 5.0, "Kachelgroesse etwa vier Felder (%s)" % str(meters))
	var brightness = ground.get_shader_parameter("ground_tile_brightness")
	check(brightness != null and float(brightness) <= 1.0, "Helligkeit nicht ueber 1,0 (%s)" % str(brightness))
	# Ein nach dem Umschalten neu erzeugtes Material folgt dem Schalter.
	_set_flag(false)
	var late = PROFILE.new().surface_material_for("sand")
	check(not bool(late.get_shader_parameter("ground_tiles_enabled")), "Neues Material folgt dem Schalter (aus)")
	_set_flag(true)


func _make_view(homebase: bool):
	var host := Node2D.new()
	root.add_child(host)
	var view = VIEW.new()
	view.name = "Primary3DView"
	host.add_child(view)
	view.set_process(false)
	view.call("set_frontier_art_enabled", true)
	if homebase:
		view.call("set_homebase_visuals_enabled", true)
	return view


func _check_views_and_key() -> void:
	root.size = Vector2i(1280, 720)
	_set_flag(true)
	var home = _make_view(true)
	var mission = _make_view(false)
	for pair in [["Heimatbasis", home], ["Einsatzkarte", mission]]:
		var view = pair[1]
		var tag: String = pair[0]
		check(view.has_method("toggle_ground_tiles"), tag + ": toggle_ground_tiles vorhanden")
		var profile = view.get("_frontier_art_profile")
		check(profile != null, tag + ": Profil vorhanden")
		if profile == null or not view.has_method("toggle_ground_tiles"):
			continue
		var materials := _ground_materials(profile)
		var before := _states(materials)
		check(not before.has(false), tag + ": Ausgangszustand alle an")
		view.call("toggle_ground_tiles")
		check(not _states(materials).has(true), tag + ": nach Umschalten alle %d Materialien aus" % materials.size())
		check(not _flag(), tag + ": Profilschalter aus")
		await process_frame
		view.call("toggle_ground_tiles")
		check(_states(materials) == before, tag + ": zweimal Umschalten stellt den Ausgangszustand her")
		await process_frame
	# Taste: echte Eingabe, genau ein Wechsel, beide Ansichten folgen.
	var view_consts: Dictionary = (VIEW as Script).get_script_constant_map()
	var key_name := String(view_consts.get("GROUND_TILES_KEY_NAME", ""))
	check(key_name == "F9", "Umschalt-Taste ist F9")
	var key_code: int = int(view_consts.get("GROUND_TILES_KEY", 0))
	check(key_code == KEY_F9, "Konstante GROUND_TILES_KEY = KEY_F9")
	var home_materials := _ground_materials(home.get("_frontier_art_profile")) if home.get("_frontier_art_profile") != null else []
	var mission_materials := _ground_materials(mission.get("_frontier_art_profile")) if mission.get("_frontier_art_profile") != null else []
	var event := InputEventKey.new()
	event.keycode = KEY_F9
	event.physical_keycode = KEY_F9
	event.pressed = true
	root.push_input(event)
	check(not _flag(), "Taste F9: genau ein Wechsel (aus)")
	check(not _states(home_materials).has(true) and not _states(mission_materials).has(true), "Taste F9: beide Ansichten aus")
	await process_frame
	var event2 := InputEventKey.new()
	event2.keycode = KEY_F9
	event2.physical_keycode = KEY_F9
	event2.pressed = true
	root.push_input(event2)
	check(_flag(), "Taste F9: zweiter Druck stellt wieder an")
	check(not _states(home_materials).has(false) and not _states(mission_materials).has(false), "Taste F9: beide Ansichten wieder an")
	await process_frame
	# Loslassen und Wiederholung loesen nichts aus.
	var release := InputEventKey.new()
	release.keycode = KEY_F9
	release.physical_keycode = KEY_F9
	release.pressed = false
	root.push_input(release)
	var echo := InputEventKey.new()
	echo.keycode = KEY_F9
	echo.physical_keycode = KEY_F9
	echo.pressed = true
	echo.echo = true
	root.push_input(echo)
	check(_flag(), "Loslassen und Echo loesen keinen Wechsel aus")
	home.get_parent().free()
	mission.get_parent().free()


func _flag() -> bool:
	var script: Script = PROFILE
	return script.has_method("ground_tiles_on") and bool(script.call("ground_tiles_on"))


func _set_flag(on: bool) -> void:
	var script: Script = PROFILE
	if script.has_method("set_ground_tiles"):
		script.call("set_ground_tiles", on)


func _states(materials: Array) -> Array:
	var states: Array = []
	for material in materials:
		states.append(material.get_shader_parameter("ground_tiles_enabled") == true)
	return states
