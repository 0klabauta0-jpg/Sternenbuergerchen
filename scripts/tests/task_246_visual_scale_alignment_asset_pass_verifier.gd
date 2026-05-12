extends SceneTree

const NPC_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const BACKGROUND_CATALOG_PATH: String = "res://data/background_image_catalog.json"
const VFX_CATALOG_PATH: String = "res://data/weapon_fire_vfx_catalog.json"
const MATRIX_DOC_PATH: String = "res://docs/reviews/asset_scale_alignment_matrix.md"
const MANUAL_CHECK_PATH: String = "res://docs/manual_checks/visual_scale_alignment_checklist.md"
const TERRAIN_VIEW_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"
const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const MULTIPLAYER_LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const BACKGROUND_IMAGE_CATALOG_SCRIPT: GDScript = preload("res://scripts/assets/background_image_catalog.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_loop_driver.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_246 Visual Scale Alignment Asset Pass Verifier ===")
	_test_npc_scale_socket_contract()
	_test_visual_loadout_resource_alignment()
	_test_weapon_fire_vfx_catalog_alignment()
	await _test_runtime_muzzle_audio_impact_anchor_alignment()
	await _test_background_crop_and_fixed_window_contract()
	_test_terrain_height_anchor_source_contract()
	_test_documentation_matrix_and_manual_checklist()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_npc_scale_socket_contract() -> void:
	var mapping: Dictionary = _load_json(NPC_VISUAL_MAPPING_PATH)
	_assert(not mapping.is_empty(), "NPC visual mapping JSON exists")
	var defaults: Dictionary = Dictionary(mapping.get("defaults", {}))
	_assert(_float_in_range(float(defaults.get("scale", 0.0)), 0.18, 0.28), "Default NPC visual scale stays within 2.5D readability bounds")
	var sockets: Dictionary = Dictionary(defaults.get("sockets", {}))
	for socket_name in ["HeadSocket", "RightHandSocket", "BackSocket"]:
		var socket: Dictionary = Dictionary(sockets.get(socket_name, {}))
		_assert(not socket.is_empty(), "Socket is defined: %s" % socket_name)
		_assert(_array_vector3_is_valid(socket.get("fallback_anchor", [])), "Socket has a Vector3 fallback anchor: %s" % socket_name)
		_assert(_array_vector3_length(socket.get("offset", [])) <= 0.001, "Socket keeps neutral gameplay offset: %s" % socket_name)
	var helmet_attachment: Dictionary = Dictionary(defaults.get("helmet_attachment", {}))
	var blaster_attachment: Dictionary = Dictionary(defaults.get("blaster_attachment", {}))
	_assert(String(helmet_attachment.get("socket_name", "")) == "HeadSocket", "Helmet attachment targets HeadSocket")
	_assert(float(helmet_attachment.get("max_scale", 1.0)) <= 0.011, "Helmet max scale stays in calibrated TASK_174 bounds")
	_assert(_array_vector3_length(helmet_attachment.get("offset", [])) <= 0.001, "Helmet offset does not move gameplay anchor")
	_assert(String(blaster_attachment.get("socket_name", "")) == "RightHandSocket", "Default blaster attachment targets RightHandSocket")
	_assert(_float_in_range(float(blaster_attachment.get("scale", 0.0)), 0.006, 0.015), "Default blaster scale stays hand-held")
	_assert(_array_vector3_length(blaster_attachment.get("offset", [])) <= 0.001, "Default blaster offset does not move gameplay anchor")
	for visual_id in ["team_alpha", "team_bravo", "default"]:
		var visual_entry: Dictionary = Dictionary(Dictionary(mapping.get("unit_visuals", {})).get(visual_id, {}))
		_assert(_float_in_range(float(visual_entry.get("scale", 0.0)), 0.18, 0.28), "%s scale stays in shared NPC range" % visual_id)
		_assert(ResourceLoader.exists(String(visual_entry.get("model_path", ""))), "%s model is project-loadable" % visual_id)
		_assert(ResourceLoader.exists(String(visual_entry.get("skin_path", ""))), "%s skin is project-loadable" % visual_id)
	for archetype_id in ["friendly_space_suit_white", "enemy_space_suit_orange"]:
		var archetype: Dictionary = Dictionary(Dictionary(mapping.get("visual_archetypes", {})).get(archetype_id, {}))
		var compatibility: Dictionary = Dictionary(archetype.get("socket_compatibility", {}))
		_assert(bool(compatibility.get("uses_default_socket_contract", false)), "%s uses the default socket contract" % archetype_id)
		_assert(Array(compatibility.get("weapon_sockets", [])).has("RightHandSocket"), "%s supports right-hand weapons" % archetype_id)
		_assert(Array(compatibility.get("weapon_sockets", [])).has("BackSocket"), "%s supports back-mounted weapons" % archetype_id)


func _test_visual_loadout_resource_alignment() -> void:
	var mapping: Dictionary = _load_json(NPC_VISUAL_MAPPING_PATH)
	var loadouts: Dictionary = Dictionary(mapping.get("visual_loadouts", {}))
	for loadout_id in ["standard_rifle", "compact_blaster", "medictool_blaster", "heavy_blaster", "sniper_rifle", "rocket_launcher"]:
		var loadout: Dictionary = Dictionary(loadouts.get(loadout_id, {}))
		_assert(not loadout.is_empty(), "Visual loadout exists: %s" % loadout_id)
		_assert(_is_project_loadable(String(loadout.get("helmet_path", ""))), "%s helmet path is project-loadable" % loadout_id)
		_assert(_is_project_loadable(String(loadout.get("blaster_path", ""))), "%s weapon model path is project-loadable" % loadout_id)
		var attachment: Dictionary = _merged_blaster_attachment(mapping, loadout)
		var socket_name: String = String(attachment.get("socket_name", "")).strip_edges()
		_assert(["RightHandSocket", "BackSocket"].has(socket_name), "%s uses an allowed visual weapon socket" % loadout_id)
		_assert(_array_vector3_length(attachment.get("offset", [])) <= 0.001, "%s keeps visual-only attachment offset neutral" % loadout_id)
		_assert(_float_in_range(float(attachment.get("scale", 0.0)), 0.006, 0.016), "%s weapon scale stays in visible bounded range" % loadout_id)
	var weapon_loadouts: Dictionary = Dictionary(mapping.get("weapon_visual_loadouts", {}))
	var required_weapon_map: Dictionary = {
		"rifle": "standard_rifle",
		"smg": "standard_rifle",
		"sniper": "sniper_rifle",
		"rocket_launcher": "rocket_launcher",
		"panzerfaust": "rocket_launcher",
		"medictool": "medictool_blaster",
		"rail_gun": "heavy_blaster",
	}
	for weapon_id in required_weapon_map.keys():
		_assert(String(weapon_loadouts.get(weapon_id, "")) == String(required_weapon_map[weapon_id]), "Weapon maps to stable visual loadout: %s" % weapon_id)
	_assert(_loadout_socket(loadouts, "sniper_rifle") == "RightHandSocket", "Sniper rifle stays on RightHandSocket")
	_assert(_loadout_socket(loadouts, "rocket_launcher") == "BackSocket", "Rocket launcher stays on BackSocket")
	_assert(absf(_loadout_scale(loadouts, "sniper_rifle") - 0.010) <= 0.001, "Sniper scale remains calibrated")
	_assert(absf(_loadout_scale(loadouts, "rocket_launcher") - 0.008) <= 0.001, "Rocket launcher scale remains calibrated")


func _test_weapon_fire_vfx_catalog_alignment() -> void:
	var catalog: Dictionary = _load_json(VFX_CATALOG_PATH)
	_assert(not catalog.is_empty(), "Weapon fire VFX catalog exists")
	_assert(bool(Dictionary(catalog.get("runtime_contract", {})).get("no_damage_logic", false)), "Muzzle VFX catalog declares no damage logic")
	var default_by_weapon: Dictionary = Dictionary(catalog.get("default_by_weapon", {}))
	for weapon_id in ["rifle", "smg", "sniper", "rocket_launcher", "rail_gun"]:
		_assert(default_by_weapon.has(weapon_id), "Muzzle VFX maps weapon: %s" % weapon_id)
	var muzzle_ids: Dictionary = {}
	for entry_variant in Array(catalog.get("muzzle_flashes", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		var entry_id: String = String(entry.get("id", "")).strip_edges()
		var path: String = String(entry.get("path", "")).strip_edges()
		muzzle_ids[entry_id] = true
		_assert(path.begins_with("res://Assets/curated/kenney/particles/muzzle/"), "Muzzle texture uses curated project path: %s" % entry_id)
		_assert(ResourceLoader.exists(path), "Muzzle texture is project-loadable: %s" % entry_id)
		_assert(_float_in_range(float(entry.get("barrel_offset_world", 0.0)), 16.0, 48.0), "Muzzle barrel offset stays plausible: %s" % entry_id)
		_assert(_float_in_range(float(entry.get("pixel_size", 0.0)), 0.006, 0.018), "Muzzle pixel size stays bounded: %s" % entry_id)
	for required_id in ["muzzle_flash_01", "muzzle_flash_02", "muzzle_flash_04", "muzzle_flash_05"]:
		_assert(muzzle_ids.has(required_id), "Muzzle ID remains available: %s" % required_id)


func _test_runtime_muzzle_audio_impact_anchor_alignment() -> void:
	var view: Node = _make_primary_view()
	view.call("set_order_visual_payload", {
		"phase_index": 1,
		"fire_event_dicts": [
			_build_fire_event("task246_rocket_fire", "rocket_launcher", Vector2(0.0, 128.0), Vector2(192.0, 128.0), "team_alpha"),
		],
	})
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var rocket_entry: Dictionary = _find_event_entry(entries, "task246_rocket_fire")
	_assert(not rocket_entry.is_empty(), "Runtime creates a muzzle alignment entry for rocket fire")
	_assert(String(rocket_entry.get("weapon_id", "")) == "rocket_launcher", "Runtime VFX entry preserves weapon ID")
	_assert(String(rocket_entry.get("muzzle_id", "")) == "muzzle_flash_05", "Rocket fire uses the heavy muzzle flash")
	_assert(typeof(rocket_entry.get("muzzle_position", null)) == TYPE_VECTOR2, "Runtime VFX entry records muzzle world position")
	_assert(String(rocket_entry.get("audio_event_id", "")) == "combat_heavy_weapon", "Weapon fire SFX uses the same fire-event context")
	_assert(int(snapshot.get("weapon_fire_sfx_count", 0)) >= 1, "Visible muzzle fire emits one weapon-fire SFX")
	view.queue_free()
	await process_frame

	var simulation = SIMULATION_ROOT_SCRIPT.new()
	simulation.name = "SimulationRootForTask246"
	var driver = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.simulation_root_path = NodePath("../SimulationRootForTask246")
	root.add_child(simulation)
	root.add_child(driver)
	await process_frame
	var impact_result: Dictionary = Dictionary(driver.call("emit_impact_sfx_for_tests", {
		"weapon_id": "rocket_launcher",
		"unit_id": "task246_impact_target",
		"fire_event_id": "task246_rocket_fire",
		"attacker_team_id": "team_alpha",
	}, null))
	var audio_snapshot: Dictionary = Dictionary(driver.call("get_audio_sfx_debug_snapshot"))
	var event_counts: Dictionary = Dictionary(audio_snapshot.get("played_count_by_event", {}))
	_assert(String(impact_result.get("event_id", "")) == "impact_metal_heavy", "Rocket impact maps to heavy metal impact SFX")
	_assert(int(event_counts.get("explosion_large", 0)) >= 1, "Rocket impact emits compatible explosion SFX")
	driver.queue_free()
	simulation.queue_free()
	await process_frame


func _test_background_crop_and_fixed_window_contract() -> void:
	var loaded: Dictionary = Dictionary(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("load_catalog"))
	var backgrounds: Dictionary = Dictionary(loaded.get("backgrounds", {}))
	_assert(PackedStringArray(loaded.get("diagnostics", PackedStringArray())).is_empty(), "Background catalog has no alignment diagnostics")
	for background_id in ["main_menu_shell", "multiplayer_lobby_hangar", "mission_select_desert_outpost", "loading_asteroid_flight", "debrief_desert_explosion_base"]:
		var entry: Dictionary = Dictionary(backgrounds.get(background_id, {}))
		_assert(not entry.is_empty(), "Background entry exists: %s" % background_id)
		_assert(_is_project_loadable(String(entry.get("res_path", ""))), "Background resource is project-loadable: %s" % background_id)
		_assert(int(entry.get("width", 0)) <= 2048 and int(entry.get("height", 0)) <= 2048, "Background fits UI texture size budget: %s" % background_id)
		_assert(not String(entry.get("crop_anchor", "")).is_empty(), "Background defines crop anchor: %s" % background_id)
		_assert(_float_in_range(float(entry.get("dim_strength", 0.0)), 0.30, 0.75), "Background defines readable dim strength: %s" % background_id)
		_assert(not String(entry.get("text_safe_zone", "")).is_empty(), "Background defines text safe zone: %s" % background_id)
	await _test_main_menu_fixed_window()
	await _test_lobby_fixed_window()


func _test_main_menu_fixed_window() -> void:
	var packed_scene := ResourceLoader.load(MAIN_MENU_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Main menu scene loads for fixed-window check")
	if packed_scene == null:
		return
	var main_menu := packed_scene.instantiate() as Control
	root.add_child(main_menu)
	await process_frame
	var background := main_menu.get_node_or_null("Background") as TextureRect
	var rail := main_menu.get_node_or_null("MenuRail") as Control
	_assert(main_menu.custom_minimum_size == Vector2(1920.0, 1080.0), "Main menu keeps Full-HD fixed minimum size")
	_assert(background != null and background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Main menu background uses covered crop")
	_assert(rail != null and is_equal_approx(rail.offset_right - rail.offset_left, 520.0), "Main menu left rail keeps fixed 520px width")
	main_menu.queue_free()
	await process_frame


func _test_lobby_fixed_window() -> void:
	var packed_scene := ResourceLoader.load(MULTIPLAYER_LOBBY_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Multiplayer lobby scene loads for fixed-window check")
	if packed_scene == null:
		return
	var lobby := packed_scene.instantiate() as Control
	root.add_child(lobby)
	await process_frame
	var panel := lobby.get_node_or_null("Panel") as Control
	var background := lobby.get_node_or_null("Background") as TextureRect
	_assert(lobby.custom_minimum_size == Vector2(1280.0, 720.0), "Lobby keeps 1280x720 fixed minimum size")
	_assert(panel != null and is_equal_approx(panel.offset_right - panel.offset_left, 720.0), "Lobby panel keeps fixed 720px width")
	_assert(panel != null and is_equal_approx(panel.offset_bottom - panel.offset_top, 560.0), "Lobby panel keeps fixed 560px height")
	_assert(background != null and background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Lobby background uses covered crop without resizing panel")
	lobby.queue_free()
	await process_frame


func _test_terrain_height_anchor_source_contract() -> void:
	var source: String = _read_text(TERRAIN_VIEW_PATH)
	_assert(source.contains("func _world_to_surface_3d_position"), "Terrain view has a single surface anchor helper")
	_assert(source.contains("return _world_to_3d_position(world_position, _get_world_surface_y(world_position) + y_offset)"), "Surface helper composes terrain height plus visual offset")
	_assert(source.contains("return float(tile_data.height_level) * _get_3d_height_step()"), "Terrain surface derives from height_level")
	_assert(source.contains("object_height") and source.contains("top_y + (object_height * 0.5)"), "Object visuals sit on height_level + object_height")
	_assert(source.contains("_world_to_surface_3d_position(muzzle_position, 0.78)"), "Muzzle trace and weapon SFX use terrain surface anchors")
	_assert(source.contains("_world_to_surface_3d_position(unit_world_position, 0.06)"), "Unit proxies use terrain surface anchors")


func _test_documentation_matrix_and_manual_checklist() -> void:
	_assert(FileAccess.file_exists(MATRIX_DOC_PATH), "Alignment matrix document exists")
	_assert(FileAccess.file_exists(MANUAL_CHECK_PATH), "Visual alignment manual checklist exists")
	var matrix_text: String = _read_text(MATRIX_DOC_PATH)
	var manual_text: String = _read_text(MANUAL_CHECK_PATH)
	for required_text in ["Sniper Rifle", "Rocket Launcher", "muzzle_flash_05", "multiplayer_lobby_hangar", "height_level"]:
		_assert(matrix_text.contains(required_text), "Alignment matrix includes %s" % required_text)
	_assert(manual_text.contains("NPCs und Attachments"), "Manual checklist covers NPC attachments")
	_assert(manual_text.contains("Backgrounds und feste Fenster"), "Manual checklist covers fixed-window backgrounds")


func _make_primary_view() -> Node:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task246_visual_alignment", Vector2i(5, 5), Vector2.ZERO, 64.0, 32.0, 2)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	return primary_view


func _build_fire_event(event_id: String, weapon_id: String, attacker_position: Vector2, target_position: Vector2, attacker_team_id: String) -> Dictionary:
	return {
		"event_id": event_id,
		"event_type": "weapon_fire",
		"source": "task_246_alignment_verifier",
		"tick": 1,
		"sequence": 1,
		"attacker_unit_id": "%s_attacker" % event_id,
		"attacker_team_id": attacker_team_id,
		"target_unit_id": "%s_target" % event_id,
		"target_team_id": "team_bravo" if attacker_team_id == "team_alpha" else "team_alpha",
		"weapon_id": weapon_id,
		"weapon_tile_range": 25,
		"weapon_range_world": 1800.0,
		"attacker_position": attacker_position,
		"target_position": target_position,
	}


func _merged_blaster_attachment(mapping: Dictionary, loadout: Dictionary) -> Dictionary:
	var defaults: Dictionary = Dictionary(mapping.get("defaults", {}))
	var attachment: Dictionary = Dictionary(defaults.get("blaster_attachment", {})).duplicate(true)
	var override_attachment: Dictionary = Dictionary(loadout.get("blaster_attachment", {}))
	for key in override_attachment.keys():
		attachment[key] = override_attachment[key]
	return attachment


func _loadout_socket(loadouts: Dictionary, loadout_id: String) -> String:
	return String(Dictionary(Dictionary(loadouts.get(loadout_id, {})).get("blaster_attachment", {})).get("socket_name", "")).strip_edges()


func _loadout_scale(loadouts: Dictionary, loadout_id: String) -> float:
	return float(Dictionary(Dictionary(loadouts.get(loadout_id, {})).get("blaster_attachment", {})).get("scale", 0.0))


func _find_event_entry(entries: Array, event_id: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("event_id", "")) == event_id:
			return entry
	return {}


func _is_project_loadable(path: String) -> bool:
	var normalized_path: String = path.strip_edges()
	return normalized_path.begins_with("res://") and not normalized_path.contains("C:/") and not normalized_path.contains("C:" + "\\") and ResourceLoader.exists(normalized_path)


func _float_in_range(value: float, min_value: float, max_value: float) -> bool:
	return value >= min_value and value <= max_value


func _array_vector3_is_valid(value: Variant) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	return Array(value).size() >= 3


func _array_vector3_length(value: Variant) -> float:
	if typeof(value) != TYPE_ARRAY:
		return 999.0
	var values: Array = Array(value)
	if values.size() < 3:
		return 999.0
	return Vector3(float(values[0]), float(values[1]), float(values[2])).length()


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
