extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_471_fireteam_weapon_fire_vfx_hit_feedback_perf.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_471 Fireteam Weapon Fire VFX Hit Feedback Perf ===")
	await _test_weapon_fire_vfx_is_small_directional_and_capped()
	await _test_unit_hit_and_down_visual_state_reaches_3d_proxy()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_weapon_fire_vfx_is_small_directional_and_capped() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task471_vfx", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var events: Array = []
	for index in range(10):
		events.append({
			"event_id": "task471_fire_%02d" % index,
			"event_type": "weapon_fire",
			"attacker_unit_id": "alpha_%02d" % index,
			"target_unit_id": "enemy_%02d" % index,
			"weapon_id": "rifle",
			"attacker_position": Vector2(96.0 + float(index), 128.0),
			"target_position": Vector2(240.0, 128.0 + float(index) * 4.0),
		})
	view.call("set_order_visual_payload", {"fire_event_dicts": events})
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var entry: Dictionary = _find_entry(entries, "event_id", "task471_fire_09")
	_assert(int(snapshot.get("weapon_fire_vfx_visual_count", 0)) == 3, "Weapon-fire VFX keeps only the newest capped fire events")
	_assert(_find_entry(entries, "event_id", "task471_fire_00").is_empty(), "Old fire event is not rendered after the cap")
	_assert(not entry.is_empty(), "Newest fire event remains rendered")
	_assert(bool(entry.get("muzzle_flash_visible", false)), "Small directional muzzle flash remains visible")
	_assert(bool(entry.get("muzzle_tip_visible", false)), "Yellow muzzle tip makes the capped impulse readable")
	_assert(bool(entry.get("muzzle_texture_card_suppressed", false)) or bool(entry.get("muzzle_texture_missing", false)), "Large texture-card muzzle flash is not rendered")
	_assert(float(entry.get("muzzle_flash_pixel_size", 1.0)) <= 0.014, "Muzzle texture pixel size is capped below the old wall-sized value")
	_assert(float(entry.get("muzzle_bloom_radius", 1.0)) <= 0.12, "Muzzle bloom radius stays small")
	_assert(float(entry.get("muzzle_flash_width", 1.0)) <= 0.06, "Directional muzzle impulse stays narrow")
	_assert(float(entry.get("trace_width", 1.0)) <= 0.02, "Fire trace width stays in the performance baseline")
	_assert(bool(entry.get("impact_marker_visible", false)) and bool(entry.get("impact_cross_visible", false)), "Target-side impact marker is exposed without widening the muzzle flash")
	view.queue_free()
	await _wait_frames(2)


func _test_unit_hit_and_down_visual_state_reaches_3d_proxy() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task471_hit", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var enemy: Node2D = _make_unit("task471_enemy", "enemy_delta", "enemy", Vector2(160.0, 160.0))
	root.add_child(enemy)
	view.call("set_unit_nodes", [enemy])
	await _wait_frames(12)
	enemy.call("apply_damage", 40, {"fire_event_id": "task471_hit_1"})
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var state: Dictionary = Dictionary(Dictionary(snapshot.get("unit_proxy_state_by_id", {})).get("task471_enemy", {}))
	_assert(int(state.get("unit_health_points", 0)) == 60, "Damaged unit health reaches the 3D proxy snapshot")
	_assert(bool(state.get("unit_damage_visual_active", false)), "Damaged fit unit exposes a hit visual state")
	_assert(String(state.get("unit_status_badge_text", "")).contains("HP 60/100"), "Damaged fit unit badge shows HP")
	enemy.call("apply_damage", 80, {"fire_event_id": "task471_hit_2"})
	await _wait_frames(8)
	snapshot = Dictionary(view.call("get_render_snapshot"))
	state = Dictionary(Dictionary(snapshot.get("unit_proxy_state_by_id", {})).get("task471_enemy", {}))
	_assert(String(state.get("vital_state", "")) == "down", "Lethal damage sets the unit down state")
	_assert(bool(state.get("unit_down_pose_active", false)), "Down unit exposes a visible down-pose state")
	_assert(String(state.get("unit_status_badge_text", "")) == "DOWN", "Down unit badge is visible")
	view.queue_free()
	enemy.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("TASK_471 - Fireteam Weapon Fire VFX Hit Feedback Perf"), "TASK_471 task file exists")
	_assert(status_text.contains("TASK_471 - Fireteam Weapon Fire VFX Hit Feedback Perf"), "Implementation status documents TASK_471")
	_assert(roadmap_text.contains("TASK_471 - Fireteam Weapon Fire VFX Hit Feedback Perf"), "Roadmap lists TASK_471")


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, position_value: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.display_name = unit_id
	unit.weapon_1_id = "rifle"
	unit.weapon_2_id = "none"
	unit.global_position = position_value
	unit._ready()
	return unit


func _find_entry(entries: Array, key: String, value: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get(key, "")) == value:
			return entry
	return {}


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
