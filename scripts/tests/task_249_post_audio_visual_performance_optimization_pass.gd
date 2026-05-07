extends SceneTree

const BUDGET_PATH: String = "res://data/performance_budget_contract.json"
const REPORT_PATH: String = "res://docs/performance/audio_visual_performance_report.md"
const AUDIO_CATALOG_PATH: String = "res://data/audio_sfx_catalog.json"
const BACKGROUND_CATALOG_PATH: String = "res://data/background_image_catalog.json"
const WEAPON_VFX_CATALOG_PATH: String = "res://data/weapon_fire_vfx_catalog.json"

const AUDIO_EVENT_BUS_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_bus.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const ASSET_HARNESS: GDScript = preload("res://scripts/tests/asset_vram_shader_pipeline_harness.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_249 Post Audio Visual Performance Optimization Pass ===")
	var budget: Dictionary = _load_audio_visual_budget()
	_test_budget_and_report_contract(budget)
	await _test_audio_polyphony_pool_and_spam_budget(budget)
	_test_background_texture_budget(budget)
	await _test_weapon_fire_vfx_budget(budget)
	await _test_asset_harness_stays_inside_task_222_budget()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_budget_and_report_contract(budget: Dictionary) -> void:
	_assert(not budget.is_empty(), "Performance budget has audio_visual section")
	_assert(int(budget.get("max_audio_pool_total_players", 0)) >= 16, "Audio visual budget caps but allows the default pool")
	_assert(bool(budget.get("require_polyphony_suppression", false)), "Audio visual budget requires polyphony suppression")
	_assert(bool(budget.get("require_dedupe_suppression", false)), "Audio visual budget requires dedupe suppression")
	_assert(FileAccess.file_exists(REPORT_PATH), "Audio visual performance report exists")
	var report: String = _read_text(REPORT_PATH)
	for required_text in ["Before", "After", "Audio polyphony", "Background VRAM", "VFX", "Budgets unchanged"]:
		_assert(report.contains(required_text), "Performance report documents %s" % required_text)


func _test_audio_polyphony_pool_and_spam_budget(budget: Dictionary) -> void:
	var bus = AUDIO_EVENT_BUS_SCRIPT.new()
	bus.name = "AudioEventBusTask249"
	root.add_child(bus)
	await process_frame
	bus.player_pool.configure(8, 6)
	bus.call("apply_settings", {
		"master_volume": 80.0,
		"sfx_volume": 80.0,
		"combat_volume": 75.0,
		"movement_volume": 65.0,
		"ui_volume": 60.0,
	})
	for index in range(8):
		bus.call("emit_weapon_fire", "rifle", {
			"position": Vector3(float(index), 0.6, 1.0),
			"cooldown_msec": 0,
			"polyphony_limit": 4,
			"now_msec": 1000 + index,
		})
	for index in range(4):
		bus.call("emit_weapon_fire", "sniper", {
			"position": Vector3(float(index), 0.6, 2.0),
			"cooldown_msec": 0,
			"dedupe_key": "task249_sniper_same_event",
			"dedupe_window_msec": 5000,
			"now_msec": 2000 + index,
		})
	for index in range(6):
		bus.call("emit_movement_step", "sand", {
			"position": Vector3(float(index), 0.0, 3.0),
			"cooldown_msec": 0,
			"polyphony_limit": 3,
			"now_msec": 3000 + index,
		})
	var snapshot: Dictionary = Dictionary(bus.call("get_diagnostic_snapshot"))
	var pool: Dictionary = Dictionary(snapshot.get("pool", {}))
	var total_pool_limit: int = int(pool.get("max_2d_players", 0)) + int(pool.get("max_3d_players", 0))
	_assert(total_pool_limit <= int(budget.get("max_audio_pool_total_players", 0)), "Audio player pool remains bounded")
	_assert(int(pool.get("active_voice_count", 99)) <= int(budget.get("max_audio_active_voice_count", 0)), "Active audio voices stay below budget")
	_assert(int(snapshot.get("suppressed_polyphony_count", 0)) >= 1, "Combat/movement spam is polyphony-limited")
	_assert(int(snapshot.get("suppressed_dedupe_count", 0)) >= 1, "Repeated fire events are deduped")
	_assert(int(snapshot.get("missing_id_count", 99)) <= int(budget.get("max_audio_missing_id_count", 0)), "Audio performance pass has no missing IDs")
	_assert(int(snapshot.get("missing_resource_count", 99)) <= int(budget.get("max_audio_missing_resource_count", 0)), "Audio performance pass has no missing resources")
	bus.call("shutdown_for_tests")
	root.remove_child(bus)
	bus.free()
	await process_frame


func _test_background_texture_budget(budget: Dictionary) -> void:
	var catalog: Dictionary = _load_json(BACKGROUND_CATALOG_PATH)
	var backgrounds: Array = Array(catalog.get("backgrounds", []))
	var runtime_contract: Dictionary = Dictionary(catalog.get("runtime_contract", {}))
	var total_estimated_vram: int = 0
	var max_dimension: int = 0
	for entry_variant in backgrounds:
		var entry: Dictionary = Dictionary(entry_variant)
		var path: String = String(entry.get("res_path", ""))
		var width: int = int(entry.get("width", 0))
		var height: int = int(entry.get("height", 0))
		total_estimated_vram += width * height * 4
		max_dimension = maxi(max_dimension, maxi(width, height))
		_assert(ResourceLoader.exists(path), "Background resource stays loadable: %s" % String(entry.get("background_id", "")))
	_assert(String(runtime_contract.get("load_policy", "")) == "screen_on_demand", "Backgrounds keep screen-on-demand load policy")
	_assert(max_dimension <= int(budget.get("max_background_texture_dimension", 0)), "Background max dimension stays below budget")
	_assert(total_estimated_vram <= int(budget.get("max_background_total_estimated_vram_bytes", 0)), "Background estimated VRAM stays below budget")


func _test_weapon_fire_vfx_budget(budget: Dictionary) -> void:
	var catalog: Dictionary = _load_json(WEAPON_VFX_CATALOG_PATH)
	var muzzle_entries: Array = Array(catalog.get("muzzle_flashes", []))
	_assert(muzzle_entries.size() <= int(budget.get("max_muzzle_texture_count", 0)), "Muzzle texture count stays bounded")
	for entry_variant in muzzle_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		_assert(ResourceLoader.exists(String(entry.get("path", ""))), "Muzzle texture is loadable: %s" % String(entry.get("id", "")))
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task249_vfx_budget", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 2)
	var view = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var fire_events: Array = []
	for index in range(10):
		fire_events.append(_build_fire_event("task249_fire_%02d" % index, "rocket_launcher" if index % 3 == 0 else "rifle", Vector2(0.0, 64.0 + float(index * 8)), Vector2(192.0, 64.0 + float(index * 8)), "team_alpha"))
	view.call("set_order_visual_payload", {"phase_index": 1, "fire_event_dicts": fire_events})
	await _wait_frames(8)
	var render_snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	_assert(int(render_snapshot.get("weapon_fire_vfx_visual_count", 99)) <= int(budget.get("max_weapon_fire_vfx_visual_count", 0)), "Weapon-fire VFX count stays below budget")
	_assert(int(render_snapshot.get("missing_asset_mapping_count", 0)) == 0, "VFX performance pass has no missing asset mappings")
	_assert(not bool(render_snapshot.get("audio_sets_gameplay_state", false)), "VFX/audio diagnostics do not claim gameplay mutation")
	view.queue_free()
	await process_frame


func _test_asset_harness_stays_inside_task_222_budget() -> void:
	var budget: Dictionary = _load_json(BUDGET_PATH)
	var asset_budget: Dictionary = Dictionary(Dictionary(budget.get("project_budget", {})).get("assets", {}))
	var harness = ASSET_HARNESS.new()
	var result: Dictionary = await harness.run_all(root)
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	var assets: Dictionary = Dictionary(result.get("assets", {}))
	_assert(bool(summary.get("all_paths_res", false)), "Asset performance harness keeps res:// paths")
	_assert(bool(summary.get("all_assets_loadable", false)), "Asset performance harness loads all measured assets")
	_assert(bool(summary.get("warmup_side_effect_free", false)), "Asset performance harness warmup remains side-effect free")
	_assert(float(assets.get("estimated_texture_vram_bytes", 9999999999.0)) <= float(asset_budget.get("max_texture_estimated_vram_bytes", 0.0)), "Curated asset texture VRAM remains within TASK_222 budget")
	_assert(float(Dictionary(assets.get("max_glb_file", {})).get("file_bytes", 999999999.0)) <= float(asset_budget.get("max_single_glb_file_bytes", 0.0)), "Largest GLB remains within TASK_222 budget")


func _build_fire_event(event_id: String, weapon_id: String, attacker_position: Vector2, target_position: Vector2, attacker_team_id: String) -> Dictionary:
	return {
		"event_id": event_id,
		"event_type": "weapon_fire",
		"source": "task_249_performance",
		"tick": 249,
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
	}


func _load_audio_visual_budget() -> Dictionary:
	var budget: Dictionary = _load_json(BUDGET_PATH)
	return Dictionary(Dictionary(budget.get("project_budget", {})).get("audio_visual", {}))


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
