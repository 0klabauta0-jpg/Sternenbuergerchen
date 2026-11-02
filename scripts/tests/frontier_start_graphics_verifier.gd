extends SceneTree
## Bounded default-art gate. Does not start or alter a player roster/save.
## Actual deployment/LZ/GO acceptance remains a separate normal-start check.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const BACKGROUNDS = preload("res://scripts/assets/background_image_catalog.gd")
const MENU = preload("res://scenes/ui/main_menu.tscn")
const META_SCRIPT = preload("res://scripts/meta/meta_layer_flow.gd")
const GM01 := "res://maps/Ground_Mission01_32x32.json"
const SCENARIO := "res://data/mission_scenarios/ground_mission01_default.json"
const IMAGE := "res://Assets/curated/main_menu/frontier_outpost_main_20261101.png"
const PROFILE := "frontier_illustrated_v1"
const LAYOUT_ID := "gm01_frontier_outpost_v1"
const ORIGINAL_SCENARIO_SHA := "792bff6b6dfa6fabf739a737e4e45d34c8e3729a4fdc7d6b62a74a374a27b45f"
var passed := 0
var failed := 0


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)


func run() -> void:
	check(not OS.get_cmdline_user_args().has("--frontier-art-v1"), "default profile gate runs without the Frontier CLI flag")
	check(String(ProjectSettings.get_setting("application/run/main_scene", "")) == "res://scenes/ui/main_menu.tscn", "normal project entry is the real main menu")
	# Instantiate without entering the tree: query real scene APIs while avoiding
	# _ready roster persistence, settings writes or synthetic gameplay bootstrap.
	var menu: Control = MENU.instantiate()
	var routes: Dictionary = menu.call("get_route_snapshot")
	check(String(routes.get("singleplayer", "")) == "res://scenes/meta/meta_layer_test.tscn", "normal Singleplayer route retains the Meta Homebase flow")
	check(menu.get_node_or_null("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton") is Button, "the normal Singleplayer button still exists")
	check(String(menu.call("get_background_path")) == IMAGE, "real main-menu background API chooses the new native Outpost image")
	menu.free()
	var script_resource: GDScript = META_SCRIPT
	var constants: Dictionary = script_resource.get_script_constant_map()
	check(String(constants.get("SINGLEPLAYER_RELEASE_DEFAULT_MISSION_ID", "")) == "grid_sweep", "playable default mission remains Grid Sweep")
	check(String(constants.get("DEFAULT_META_MAP_PATH", "")) == GM01 and String(constants.get("DEFAULT_META_SCENARIO_PATH", "")) == SCENARIO, "normal Meta default preserves the GM01 map and scenario")
	var raw: String = FileAccess.get_file_as_string(GM01)
	var payload: Variant = JSON.parse_string(raw)
	check(payload is Dictionary, "default map remains a valid JSON dictionary")
	if payload is Dictionary:
		check(String(payload.get("terrain_visual_theme_id", "")) == PROFILE, "GM01 explicitly selects the Frontier visual profile")
		# The user explicitly commissioned a real GM01 rebuild. The old one-line
		# byte gate described the superseded profile-only change, not this task.
		check(String(payload.get("authored_visual_layout_id", "")) == LAYOUT_ID, "saved GM01 selects the real authored Outpost composition")
		check(String(payload.get("grid_topology", "square8")) == "hex_axial_v1", "rebuilt default uses true Hex topology")
	check(FileAccess.get_sha256(SCENARIO) == ORIGINAL_SCENARIO_SHA, "scenario, enemy groups, objectives and patrol rules remain byte-identical")
	var data = MAP.load_from_file(GM01)
	check(data.get_grid_topology() == "hex_axial_v1", "normal MapData loader selects true Hex")
	check(data.get_grid_size() == Vector2i(48, 48) and data.get_tiles().size() == 2304, "rebuilt default GM01 expands to all 2304 Hex cells at the user's request")
	var view = VIEW.new()
	root.add_child(view)
	view.configure_from_map(data)
	var snapshot: Dictionary = view.get_render_snapshot()
	check(bool(snapshot.get("frontier_art_enabled", false)) and String(snapshot.get("frontier_art_profile_id", "")) == PROFILE, "actual normal map/view path activates Frontier without a test flag")
	check(int(snapshot.get("frontier_art_override", -2)) == -1, "profile activation comes from saved map data, not an explicit preview override")
	check(bool(snapshot.get("authored_visual_layout_active", false)) and String(snapshot.get("authored_visual_layout_id", "")) == LAYOUT_ID, "normal renderer installs the saved Outpost, without the isolated art-preview scene")
	view.queue_free()
	await process_frame
	await process_frame
	var workyard = MAP.load_from_file("res://maps/frontier_workyard_24x20.json")
	check(workyard.get_grid_topology() == "hex_axial_v1" and workyard.get_terrain_visual_theme_id() == PROFILE, "separate authored Hex workyard remains available")
	var background: Dictionary = BACKGROUNDS.get_entry("main_menu_shell")
	check(String(background.get("res_path", "")) == IMAGE, "existing background catalog owns the new main image path")
	check(String(background.get("origin", "")) == "project_native_godot_capture", "background provenance is a native project capture, not the old TASK199 image")
	check(String(background.get("text_safe_zone", "")) == "left_rail_520px" and String(background.get("import_profile", "")) == "ui_background_lossless_default", "existing menu readability and image loading policy are preserved")
	check(FileAccess.file_exists(IMAGE), "native Outpost image actually exists")
	if FileAccess.file_exists(IMAGE):
		check(String(background.get("sha256", "")) == FileAccess.get_sha256(IMAGE), "catalog image hash matches the actual native PNG bytes")
		check(int(background.get("file_size_bytes", 0)) == FileAccess.get_file_as_bytes(IMAGE).size(), "catalog image byte size is factual")
		var texture: Texture2D = ResourceLoader.load(IMAGE) as Texture2D
		check(texture != null, "native background imports as a real Texture2D")
		if texture != null:
			check(texture.get_width() == int(background.get("width", 0)) and texture.get_height() == int(background.get("height", 0)), "catalog dimensions match the real imported texture")
		var source: String = String(background.get("source_capture", ""))
		check(source.begins_with("res://") and FileAccess.file_exists(source), "native background links to its actual source capture metadata")
		check(not String(background.get("license_note", "")).is_empty(), "composite image license note distinguishes project geometry and constituent source licenses")
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed])
	if failed == 0:
		print("FRONTIER_START_GRAPHICS_ALL_PASS")
	quit(0 if failed == 0 else 1)
