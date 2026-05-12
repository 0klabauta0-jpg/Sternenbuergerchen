extends SceneTree

const AUDIO_EVENT_BUS_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_bus.gd")
const BACKGROUND_IMAGE_CATALOG_SCRIPT: GDScript = preload("res://scripts/assets/background_image_catalog.gd")
const CURATED_ASSET_CATALOG_SCRIPT: GDScript = preload("res://scripts/assets/curated_asset_catalog.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_loop_driver.gd")

const AUDIO_CATALOG_PATH: String = "res://data/audio_sfx_catalog.json"
const BACKGROUND_CATALOG_PATH: String = "res://data/background_image_catalog.json"
const VFX_CATALOG_PATH: String = "res://data/weapon_fire_vfx_catalog.json"
const NPC_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const REPORT_PATH: String = "res://docs/reports/audio_visual_import_and_playback_smoke.md"
const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const MULTIPLAYER_LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"

const REQUIRED_IMPORT_ASSETS: PackedStringArray = [
	"res://Assets/used/audio/kenney_all_in_one/ui/ui_click_soft_01.ogg",
	"res://Assets/used/audio/kenney_all_in_one/combat/combat_heavy_laser_01.ogg",
	"res://Assets/used/audio/kenney_all_in_one/explosion/explosion_large_low_01.ogg",
	"res://Assets/used/backgrounds/ai_generated/bg_hangar_shiphall.png",
	"res://Assets/curated/kenney/particles/muzzle/muzzle_05.png",
	"res://Assets/curated/kenney/particles/particle_heal_pulse.png",
	"res://Assets/Comic/comic-1.png",
	"res://Assets/kenney_ui-pack/PNG/Blue/Default/button_square_flat.png",
	"res://Assets/used/npc/animated_characters/models/characterMedium.fbx",
	"res://Assets/used/npc/weapon_pack/models/sniper.glb",
	"res://Assets/used/npc/weapon_pack/models/rocketlauncherModern.glb",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_248 Audio Visual Import and Playback Smoke ===")
	_test_imported_resource_samples()
	await _test_audio_playback_and_settings_smoke()
	await _test_background_and_visual_load_smoke()
	await _test_mission_snapshot_audio_visual_read_only_smoke()
	await _test_missing_asset_diagnostics_are_isolated()
	_test_report_documents_smoke()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_imported_resource_samples() -> void:
	for path in REQUIRED_IMPORT_ASSETS:
		_assert(FileAccess.file_exists(path), "Imported sample exists: %s" % path)
		_assert(FileAccess.file_exists(path + ".import"), "Imported sample has .import metadata: %s" % path)
		_assert(ResourceLoader.exists(path), "ResourceLoader sees imported sample: %s" % path)
	var audio_catalog: Dictionary = _load_json(AUDIO_CATALOG_PATH)
	var background_catalog: Dictionary = _load_json(BACKGROUND_CATALOG_PATH)
	var vfx_catalog: Dictionary = _load_json(VFX_CATALOG_PATH)
	var npc_mapping: Dictionary = _load_json(NPC_VISUAL_MAPPING_PATH)
	_assert(Array(audio_catalog.get("entries", [])).size() >= 25, "Audio catalog has playback breadth")
	_assert(Array(background_catalog.get("backgrounds", [])).size() >= 5, "Background catalog has loaded screen backgrounds")
	_assert(Array(vfx_catalog.get("muzzle_flashes", [])).size() >= 5, "Muzzle VFX catalog has particle samples")
	_assert(Dictionary(npc_mapping.get("visual_loadouts", {})).has("rocket_launcher"), "NPC visual mapping includes expanded weapon visuals")


func _test_audio_playback_and_settings_smoke() -> void:
	var bus = AUDIO_EVENT_BUS_SCRIPT.new()
	bus.name = "AudioEventBusTask248"
	root.add_child(bus)
	await process_frame
	bus.call("apply_settings", {
		"master_volume": 75.0,
		"sfx_volume": 80.0,
		"ui_volume": 65.0,
		"combat_volume": 70.0,
		"movement_volume": 60.0,
		"ambient_volume": 50.0,
	})
	var ui_result: Dictionary = Dictionary(bus.call("emit_ui_action", "click", {"now_msec": 1000}))
	var combat_result: Dictionary = Dictionary(bus.call("emit_weapon_fire", "sniper", {"position": Vector3(1.0, 0.8, 2.0), "now_msec": 2000}))
	var movement_result: Dictionary = Dictionary(bus.call("emit_movement_step", "rock", {"position": Vector3(2.0, 0.0, 2.0), "now_msec": 3000}))
	var impact_result: Dictionary = Dictionary(bus.call("emit_impact", "metal_heavy", {"position": Vector3(3.0, 0.0, 2.0), "now_msec": 4000}))
	var explosion_result: Dictionary = Dictionary(bus.call("emit_explosion", "large", {"position": Vector3(4.0, 0.0, 2.0), "now_msec": 5000}))
	_assert(bool(ui_result.get("played", false)) and String(ui_result.get("event_id", "")) == "ui_click", "UI click SFX plays")
	_assert(bool(combat_result.get("played", false)) and String(combat_result.get("event_id", "")) == "combat_sniper_shot", "Combat shot SFX plays")
	_assert(bool(movement_result.get("played", false)) and String(movement_result.get("event_id", "")) == "movement_footstep_rock", "Movement step SFX plays")
	_assert(bool(impact_result.get("played", false)) and String(impact_result.get("event_id", "")) == "impact_metal_heavy", "Impact SFX plays")
	_assert(bool(explosion_result.get("played", false)) and String(explosion_result.get("event_id", "")) == "explosion_large", "Explosion SFX plays")
	var snapshot: Dictionary = Dictionary(bus.call("get_diagnostic_snapshot"))
	var event_counts: Dictionary = Dictionary(snapshot.get("played_count_by_event", {}))
	for event_id in ["ui_click", "combat_sniper_shot", "movement_footstep_rock", "impact_metal_heavy", "explosion_large"]:
		_assert(int(event_counts.get(event_id, 0)) >= 1, "Playback diagnostics count %s" % event_id)
	_assert(int(snapshot.get("missing_id_count", 0)) == 0, "Primary playback has no missing audio IDs")
	_assert(int(snapshot.get("missing_resource_count", 0)) == 0, "Primary playback has no missing audio resources")
	_assert(not bool(snapshot.get("audio_sets_gameplay_state", true)), "Audio bus declares no gameplay mutation")
	bus.call("stop_all_for_tests")
	bus.call("apply_settings", {"master_volume": 80.0, "sfx_volume": 80.0, "combat_audio_enabled": false})
	var muted_combat: Dictionary = Dictionary(bus.call("emit_weapon_fire", "rifle", {"now_msec": 7000}))
	_assert(not bool(muted_combat.get("played", true)) and String(muted_combat.get("reason", "")).contains("settings"), "Combat mute suppresses weapon-fire playback")
	bus.call("shutdown_for_tests")
	root.remove_child(bus)
	bus.free()
	await process_frame


func _test_background_and_visual_load_smoke() -> void:
	var loaded_backgrounds: Dictionary = Dictionary(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("load_catalog"))
	_assert(PackedStringArray(loaded_backgrounds.get("diagnostics", PackedStringArray())).is_empty(), "Background catalog loads without diagnostics")
	var hangar_texture := BACKGROUND_IMAGE_CATALOG_SCRIPT.call("load_texture", "multiplayer_lobby_hangar") as Texture2D
	var main_menu_texture := BACKGROUND_IMAGE_CATALOG_SCRIPT.call("load_texture", "main_menu_shell") as Texture2D
	_assert(hangar_texture != null and hangar_texture.get_width() > 0, "Lobby hangar background texture loads")
	_assert(main_menu_texture != null and main_menu_texture.get_width() > 0, "Main menu background texture loads")
	await _test_background_scene_instance(MAIN_MENU_SCENE_PATH, "main_menu_shell", "Main menu")
	await _test_background_scene_instance(MULTIPLAYER_LOBBY_SCENE_PATH, "multiplayer_lobby_hangar", "Multiplayer lobby")
	for asset_id in ["weapon_visual_sniper_model", "weapon_visual_rocket_launcher_model", "particle_heal_pulse", "ui_button_square_blue"]:
		var resolved: Dictionary = Dictionary(CURATED_ASSET_CATALOG_SCRIPT.call("resolve_asset", asset_id))
		var path: String = String(resolved.get("path", ""))
		_assert(bool(resolved.get("ok", false)), "Curated visual asset resolves: %s" % asset_id)
		_assert(ResourceLoader.exists(path), "Curated visual asset ResourceLoader exists: %s" % asset_id)
	var muzzle_catalog: Dictionary = _load_json(VFX_CATALOG_PATH)
	_assert(_catalog_entry_path_loads(muzzle_catalog, "muzzle_flashes", "muzzle_flash_05"), "Heavy muzzle flash texture loads")


func _test_background_scene_instance(scene_path: String, expected_background_id: String, label: String) -> void:
	var packed_scene := ResourceLoader.load(scene_path) as PackedScene
	_assert(packed_scene != null, "%s scene loads" % label)
	if packed_scene == null:
		return
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	var snapshot: Dictionary = {}
	if scene.has_method("get_background_catalog_snapshot"):
		snapshot = Dictionary(scene.call("get_background_catalog_snapshot"))
	elif scene.has_method("get_lobby_ui_snapshot"):
		snapshot = Dictionary(Dictionary(scene.call("get_lobby_ui_snapshot")).get("background", {}))
	var background := scene.get_node_or_null("Background") as TextureRect
	_assert(String(snapshot.get("background_id", "")) == expected_background_id, "%s exposes expected background ID" % label)
	_assert(background != null and background.texture != null, "%s background TextureRect has texture" % label)
	scene.queue_free()
	await process_frame


func _test_mission_snapshot_audio_visual_read_only_smoke() -> void:
	var simulation = SIMULATION_ROOT_SCRIPT.new()
	simulation.name = "SimulationRootTask248"
	var bus = AUDIO_EVENT_BUS_SCRIPT.new()
	bus.name = "AudioEventBus"
	simulation.add_child(bus)
	root.add_child(simulation)
	await process_frame
	var before_commands: int = _array_property_size(simulation, "command_queue")
	var before_effects: int = _array_property_size(simulation, "effects_queue")
	var snapshot_contract = MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new()
	var server_snapshot: Dictionary = Dictionary(snapshot_contract.call("build_state_snapshot", {
		"tick": 248,
		"fire_events": [
			_build_fire_event("task248_snapshot_fire", "rocket_launcher", Vector2(0.0, 128.0), Vector2(192.0, 128.0), "team_alpha"),
		],
	}))
	var apply_result: Dictionary = Dictionary(simulation.call("apply_multiplayer_snapshot", server_snapshot))
	_assert(bool(apply_result.get("accepted", false)), "SimulationRoot accepts visible audio/visual snapshot")
	_assert(_array_property_size(simulation, "command_queue") == before_commands, "Snapshot audio/visual apply does not enqueue commands")
	_assert(_array_property_size(simulation, "effects_queue") == before_effects, "Snapshot audio/visual apply does not enqueue effects")
	var sim_audio: Dictionary = Dictionary(simulation.call("get_snapshot_audio_debug_snapshot"))
	_assert(int(sim_audio.get("played_count", 0)) >= 1, "Visible snapshot fire event emits read-only shot audio")

	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task248_smoke_map", Vector2i(5, 5), Vector2.ZERO, 64.0, 32.0, 2)
	var view = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var last_state: Dictionary = Dictionary(simulation.call("get_last_server_state"))
	view.call("set_order_visual_payload", {"phase_index": 1, "fire_event_dicts": Array(last_state.get("fire_events", []))})
	await _wait_frames(8)
	var render_snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	_assert(int(render_snapshot.get("weapon_fire_vfx_visual_count", 0)) >= 1, "Snapshot fire event creates muzzle flash VFX")
	_assert(bool(render_snapshot.get("weapon_fire_vfx_catalog_loaded", false)), "Terrain view has loaded VFX catalog")
	var step_result: Dictionary = Dictionary(view.call("emit_movement_step_sfx_for_tests", "task248_unit", "sand", true, true, 10000))
	_assert(bool(step_result.get("played", false)), "Mission view movement step SFX plays")

	var driver = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.simulation_root_path = NodePath("../SimulationRootTask248")
	root.add_child(driver)
	await process_frame
	var impact_result: Dictionary = Dictionary(driver.call("emit_impact_sfx_for_tests", {
		"weapon_id": "rocket_launcher",
		"unit_id": "task248_target",
		"fire_event_id": "task248_snapshot_fire",
		"attacker_team_id": "team_alpha",
	}, null))
	var driver_audio: Dictionary = Dictionary(driver.call("get_audio_sfx_debug_snapshot"))
	var event_counts: Dictionary = Dictionary(driver_audio.get("played_count_by_event", {}))
	_assert(String(impact_result.get("event_id", "")) == "impact_metal_heavy", "Mission driver impact SFX uses heavy impact")
	_assert(int(event_counts.get("explosion_large", 0)) >= 1, "Mission driver explosion SFX plays")
	_assert(_array_property_size(simulation, "command_queue") == before_commands, "Audio/visual smoke keeps command queue unchanged")
	_assert(_array_property_size(simulation, "effects_queue") == before_effects, "Audio/visual smoke keeps effects queue unchanged")
	driver.queue_free()
	view.queue_free()
	if bus.has_method("shutdown_for_tests"):
		bus.call("shutdown_for_tests")
	simulation.queue_free()
	await process_frame


func _test_missing_asset_diagnostics_are_isolated() -> void:
	var missing_bus = AUDIO_EVENT_BUS_SCRIPT.new()
	root.add_child(missing_bus)
	await process_frame
	var missing_audio: Dictionary = Dictionary(missing_bus.call("emit_audio_event", "task248_missing_audio_probe", {"now_msec": 12000}))
	var missing_audio_snapshot: Dictionary = Dictionary(missing_bus.call("get_diagnostic_snapshot"))
	_assert(not bool(missing_audio.get("played", true)) and String(missing_audio.get("reason", "")) == "missing_audio_id", "Missing audio ID reports diagnostic")
	_assert(int(missing_audio_snapshot.get("missing_id_count", 0)) == 1, "Isolated missing audio probe increments missing ID count")
	missing_bus.call("shutdown_for_tests")
	root.remove_child(missing_bus)
	missing_bus.free()

	var rect := TextureRect.new()
	var missing_background: Dictionary = Dictionary(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("apply_to_texture_rect", rect, "task248_missing_background_probe"))
	_assert(not bool(missing_background.get("ok", true)) and String(missing_background.get("reason", "")) == "missing_background_id", "Missing background ID reports diagnostic")
	rect.free()
	var missing_asset: Dictionary = Dictionary(CURATED_ASSET_CATALOG_SCRIPT.call("resolve_asset", "task248_missing_visual_probe"))
	_assert(not bool(missing_asset.get("ok", true)), "Missing curated asset reports diagnostic")
	await process_frame


func _test_report_documents_smoke() -> void:
	_assert(FileAccess.file_exists(REPORT_PATH), "Audio visual smoke report exists")
	var report: String = _read_text(REPORT_PATH)
	for required_text in [
		"UI click",
		"Combat shot",
		"Movement step",
		"Impact",
		"Explosion",
		"Backgrounds",
		"Missing probes are isolated",
		"TASK_249",
	]:
		_assert(report.contains(required_text), "Smoke report includes %s" % required_text)


func _catalog_entry_path_loads(catalog: Dictionary, collection_key: String, entry_id: String) -> bool:
	for entry_variant in Array(catalog.get(collection_key, [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("id", "")) != entry_id:
			continue
		var path: String = String(entry.get("path", ""))
		return ResourceLoader.exists(path)
	return false


func _build_fire_event(event_id: String, weapon_id: String, attacker_position: Vector2, target_position: Vector2, attacker_team_id: String) -> Dictionary:
	return {
		"event_id": event_id,
		"event_type": "weapon_fire",
		"source": "task_248_smoke",
		"tick": 248,
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
		"visible_to_local": true,
		"visibility_context": "visible_fire_event",
	}


func _array_property_size(node: Node, property_name: String) -> int:
	if node == null:
		return -1
	var value: Variant = node.get(property_name)
	return Array(value).size() if typeof(value) == TYPE_ARRAY else -1


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
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
