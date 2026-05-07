extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")

const VFX_CATALOG_PATH: String = "res://data/weapon_fire_vfx_catalog.json"
const INVENTORY_PATH: String = "res://docs/assets/weapon_fire_vfx_inventory.md"
const MUZZLE_ROOT: String = "res://Assets/curated/kenney/particles/muzzle/"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_205 Weapon Fire VFX Muzzle Flash Particles ===")
	_test_muzzle_assets_are_loadable_and_project_local()
	await _test_fire_events_render_exactly_one_vfx_per_event()
	await _test_snapshot_fire_events_drive_vfx_without_combat()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_muzzle_assets_are_loadable_and_project_local() -> void:
	var catalog: Dictionary = _load_json(VFX_CATALOG_PATH)
	var muzzle_entries: Array = Array(catalog.get("muzzle_flashes", []))
	_assert(FileAccess.file_exists(INVENTORY_PATH), "Weapon fire VFX inventory exists")
	_assert(FileAccess.file_exists("%sLicense.txt" % MUZZLE_ROOT), "Muzzle subset carries the source license")
	_assert(muzzle_entries.size() == 5, "Muzzle subset stays within the V1 cap")
	var ids: Dictionary = {}
	for entry_variant in muzzle_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var entry_id: String = String(entry.get("id", "")).strip_edges()
		var path: String = String(entry.get("path", "")).strip_edges()
		ids[entry_id] = true
		_assert(path.begins_with(MUZZLE_ROOT), "Muzzle asset uses project-local curated path: %s" % path)
		_assert(not path.contains("Users/") and not path.contains("Pictures/"), "Muzzle asset path contains no local source path")
		_assert(ResourceLoader.exists(path), "Muzzle texture is import-loadable: %s" % path)
		var texture := load(path) as Texture2D
		_assert(texture != null and texture.get_size().x > 0.0, "Muzzle texture loads as Texture2D: %s" % entry_id)
	_assert(ids.has("muzzle_flash_01") and ids.has("muzzle_flash_05"), "Stable muzzle IDs cover default and heavy variants")


func _test_fire_events_render_exactly_one_vfx_per_event() -> void:
	var primary_view: Node = _make_primary_view()
	primary_view.call(
		"set_order_visual_payload",
		{
			"phase_index": 1,
			"fire_event_dicts": [
				_build_fire_event("fire_a", "rifle", Vector2(0.0, 128.0), Vector2(180.0, 128.0), "team_alpha"),
				_build_fire_event("fire_b", "smg", Vector2(64.0, 160.0), Vector2(180.0, 160.0), "team_bravo"),
			],
		}
	)
	for _index in range(6):
		await process_frame
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	_assert(bool(snapshot.get("weapon_fire_vfx_catalog_loaded", false)), "Primary map loads the weapon fire VFX catalog")
	_assert(int(snapshot.get("weapon_fire_vfx_visual_count", 0)) == 2, "Each fire event creates exactly one muzzle VFX token")
	_assert(_entry_has_muzzle(entries, "fire_a", "muzzle_flash_01"), "Rifle fire uses the default rifle muzzle flash")
	_assert(_entry_has_muzzle(entries, "fire_b", "muzzle_flash_02"), "SMG fire uses the SMG muzzle flash")
	primary_view.queue_free()
	await process_frame


func _test_snapshot_fire_events_drive_vfx_without_combat() -> void:
	var server_contract = MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new()
	var server_snapshot: Dictionary = Dictionary(server_contract.call(
		"build_state_snapshot",
		{
			"tick": 21,
			"fire_events": [
				_build_fire_event("fire_snapshot", "sniper", Vector2(0.0, 128.0), Vector2(220.0, 128.0), "team_bravo"),
			],
		}
	))
	var client_simulation: Node = SIMULATION_ROOT_SCRIPT.new()
	var apply_result: Dictionary = Dictionary(client_simulation.call("apply_multiplayer_snapshot", server_snapshot))
	var last_state: Dictionary = Dictionary(client_simulation.call("get_last_server_state"))
	var primary_view: Node = _make_primary_view()
	primary_view.call("set_order_visual_payload", {"phase_index": 1, "fire_event_dicts": Array(last_state.get("fire_events", []))})
	for _index in range(6):
		await process_frame
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	_assert(bool(apply_result.get("accepted", false)), "Client accepts fire-event snapshot")
	_assert(client_simulation.command_queue.is_empty(), "Snapshot fire event does not enqueue client commands")
	_assert(client_simulation.effects_queue.is_empty(), "Snapshot fire event does not enqueue client damage effects")
	_assert(int(snapshot.get("weapon_fire_vfx_visual_count", 0)) == 1, "Snapshot fire event creates one client-side visual token")
	_assert(_entry_has_muzzle(entries, "fire_snapshot", "muzzle_flash_04"), "Sniper snapshot fire uses the sniper muzzle variant")
	primary_view.queue_free()
	client_simulation.free()
	await process_frame


func _make_primary_view() -> Node:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task205_weapon_fire_vfx", Vector2i(5, 5), Vector2.ZERO, 64.0, 32.0, 2)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	return primary_view


func _build_fire_event(event_id: String, weapon_id: String, attacker_position: Vector2, target_position: Vector2, attacker_team_id: String) -> Dictionary:
	return {
		"event_id": event_id,
		"event_type": "weapon_fire",
		"source": "standard",
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


func _entry_has_muzzle(entries: Array, event_id: String, muzzle_id: String) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("event_id", "")) == event_id and String(entry.get("muzzle_id", "")) == muzzle_id:
			return true
	return false


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
