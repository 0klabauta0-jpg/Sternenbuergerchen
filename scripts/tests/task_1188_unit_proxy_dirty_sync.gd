extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1188 Unit Proxy Dirty Sync ===")
	await _test_ten_proxy_revision_boundaries()
	await _test_twenty_eight_proxy_budget()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_ten_proxy_revision_boundaries() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task1188_dirty_proxy", Vector2i(16, 16), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var units: Array = []
	for index in range(10):
		var unit = _make_unit("task1188_unit_%02d" % index, "team_alpha" if index < 5 else "team_bravo", Vector2(96.0 + float(index % 5) * 56.0, 96.0 + float(index / 5) * 56.0))
		root.add_child(unit)
		units.append(unit)
	view.call("set_unit_nodes", units)
	await _wait_frames(8)

	_assert(view.has_method("get_unit_proxy_sync_diagnostics"), "Terrain view exposes proxy-sync revision diagnostics")
	var initial: Dictionary = _diagnostics(view)
	_assert(int(initial.get("runtime_cache_count", 0)) == 10, "Ten proxies have one cached runtime entry each")
	_assert(int(initial.get("proxy_rebuild_count", 0)) == 10, "Initial setup creates exactly ten proxies")
	_assert(int(initial.get("visual_signature_build_count", 0)) == 10, "Initial setup builds one visual signature per proxy")
	_assert(int(initial.get("recursive_node_lookup_count", 0)) > 0, "Initial proxy setup records bounded recursive cache discovery")

	await _wait_frames(12)
	var idle: Dictionary = _diagnostics(view)
	_assert(int(idle.get("proxy_rebuild_count", -1)) == int(initial.get("proxy_rebuild_count", -2)), "Idle frames do not rebuild proxies")
	_assert(int(idle.get("badge_rebuild_count", -1)) == int(initial.get("badge_rebuild_count", -2)), "Idle frames do not rebuild badges")
	_assert(int(idle.get("recursive_node_lookup_count", -1)) == int(initial.get("recursive_node_lookup_count", -2)), "Idle frames do not repeat recursive node discovery")
	_assert(int(idle.get("idle_static_state_skip_count", 0)) > 0, "Idle frames skip static proxy-state writes after the first revision")
	_assert(int(idle.get("cached_static_summary_read_count", 0)) > 0, "Idle frames aggregate proxy summary values from the runtime cache")

	var moving_unit: Node2D = units[0] as Node2D
	moving_unit.global_position += Vector2(32.0, 0.0)
	await _wait_frames(4)
	var moved: Dictionary = _diagnostics(view)
	_assert(int(moved.get("proxy_rebuild_count", -1)) == int(idle.get("proxy_rebuild_count", -2)), "Movement updates a proxy without rebuilding it")

	view.call("set_contact_entries", [{
		"fireteam_id": "task1188",
		"unit_id": "task1188_enemy",
		"team_id": "team_bravo",
		"last_known_position": Vector2(448.0, 160.0),
		"detection_state": "confirmed",
	}], PackedStringArray(["task1188"]))
	view.call("set_order_visual_payload", {
		"fire_event_dicts": [{
			"event_id": "task1188_fire",
			"event_type": "weapon_fire",
			"attacker_unit_id": "task1188_unit_00",
			"target_unit_id": "task1188_enemy",
			"attacker_position": moving_unit.global_position,
			"target_position": Vector2(448.0, 160.0),
		}],
	})
	await _wait_frames(4)
	var fire: Dictionary = _diagnostics(view)
	_assert(int(fire.get("fire_event_index_build_count", 0)) > int(moved.get("fire_event_index_build_count", -1)), "Fire payload builds an index once")
	_assert(int(fire.get("contact_index_build_count", 0)) > int(moved.get("contact_index_build_count", -1)), "Contact payload builds an index once")
	await _wait_frames(8)
	var settled_fire: Dictionary = _diagnostics(view)
	_assert(int(settled_fire.get("fire_event_index_build_count", -1)) == int(fire.get("fire_event_index_build_count", -2)), "Unchanged fire payload does not rebuild the index per frame")
	_assert(int(settled_fire.get("contact_index_build_count", -1)) == int(fire.get("contact_index_build_count", -2)), "Unchanged contacts do not rebuild the index per frame")

	moving_unit.call("apply_damage", 35, {"event_id": "task1188_damage"})
	await _wait_frames(4)
	var damaged_snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var damaged_state: Dictionary = Dictionary(Dictionary(damaged_snapshot.get("unit_proxy_state_by_id", {})).get("task1188_unit_00", {}))
	_assert(bool(damaged_state.get("unit_damage_visual_active", false)), "Vital revision reaches the proxy visual")
	var damaged: Dictionary = _diagnostics(view)
	_assert(int(damaged.get("badge_rebuild_count", -1)) == int(settled_fire.get("badge_rebuild_count", -2)), "Vital payload updates an existing badge without rebuilding it")

	view.call("set_fog_of_war_state", {
		"mode": "known_terrain",
		"team_id": "team_bravo",
		"current_visibility": {"visible_target_ids": []},
	})
	await _wait_frames(4)
	var hidden_snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var hidden_state: Dictionary = Dictionary(Dictionary(hidden_snapshot.get("unit_proxy_state_by_id", {})).get("task1188_unit_00", {}))
	var hidden: Dictionary = _diagnostics(view)
	_assert(not bool(hidden_state.get("visible", true)), "FOW hides a non-visible proxy")
	_assert(int(hidden.get("proxy_rebuild_count", -1)) == int(damaged.get("proxy_rebuild_count", -2)), "FOW visibility changes do not rebuild proxies")
	view.call("set_fog_of_war_state", {"mode": "off"})
	await _wait_frames(4)
	var shown_snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var shown_state: Dictionary = Dictionary(Dictionary(shown_snapshot.get("unit_proxy_state_by_id", {})).get("task1188_unit_00", {}))
	_assert(bool(shown_state.get("visible", false)), "FOW show restores the existing proxy")

	var enemy_unit: Node2D = units[5] as Node2D
	enemy_unit.set_meta("enemy_tactics_config", {"visual_archetype": "enemy_space_suit_orange"})
	await _wait_frames(1)
	var enemy_tactics_applied: Dictionary = _diagnostics(view)
	enemy_unit.set_meta("enemy_visual_archetype_id", "enemy_space_suit_orange")
	await _wait_frames(1)
	var enemy_archetype_meta_applied: Dictionary = _diagnostics(view)
	_assert(int(enemy_archetype_meta_applied.get("proxy_rebuild_count", -1)) == int(enemy_tactics_applied.get("proxy_rebuild_count", -2)), "An equivalent explicit enemy archetype does not replace a model")
	await _wait_frames(4)
	var enemy_tactics_settled: Dictionary = _diagnostics(view)
	_assert(int(enemy_tactics_settled.get("visual_signature_build_count", -1)) == int(enemy_archetype_meta_applied.get("visual_signature_build_count", -2)), "A stable enemy visual input refreshes the runtime cache once")
	_assert(int(enemy_tactics_settled.get("proxy_rebuild_count", -1)) == int(enemy_archetype_meta_applied.get("proxy_rebuild_count", -2)), "A stable enemy visual input does not replace a model repeatedly")

	moving_unit.set_meta("enemy_tactics_config", {
		"visual_archetype": "friendly_space_suit_white",
		"runtime_mode": "idle",
	})
	await _wait_frames(4)
	var tactics_visual: Dictionary = _diagnostics(view)
	moving_unit.set_meta("enemy_tactics_config", {
		"visual_archetype": "friendly_space_suit_white",
		"runtime_mode": "engaging",
	})
	await _wait_frames(4)
	var tactics_status_only: Dictionary = _diagnostics(view)
	_assert(int(tactics_status_only.get("visual_signature_build_count", -1)) == int(tactics_visual.get("visual_signature_build_count", -2)), "Non-visual tactics metadata does not rebuild a visual signature")
	_assert(int(tactics_status_only.get("proxy_rebuild_count", -1)) == int(tactics_visual.get("proxy_rebuild_count", -2)), "Non-visual tactics metadata does not replace a proxy model")

	moving_unit.set_meta("visual_archetype_id", "enemy_space_suit_orange")
	await _wait_frames(6)
	var replaced: Dictionary = _diagnostics(view)
	_assert(int(replaced.get("proxy_rebuild_count", 0)) == int(tactics_status_only.get("proxy_rebuild_count", -1)) + 1, "Model revision rebuilds only its affected proxy")
	_assert(int(replaced.get("runtime_cache_count", 0)) == 10, "Model replacement refreshes the cache without losing proxy coverage")
	await _wait_frames(4)
	var model_settled: Dictionary = _diagnostics(view)
	_assert(int(model_settled.get("visual_signature_build_count", -1)) == int(replaced.get("visual_signature_build_count", -2)), "A settled model revision does not rebuild its visual signature again")

	view.queue_free()
	for unit in units:
		if unit != null and is_instance_valid(unit):
			unit.queue_free()
	await _wait_frames(2)


func _test_twenty_eight_proxy_budget() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task1188_scale_proxy", Vector2i(32, 32), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	view.call("set_runtime_frame_timing_debug_enabled", true)
	var units: Array = []
	for index in range(28):
		var column: int = index % 7
		var row: int = index / 7
		var unit = _make_unit("task1188_scale_%02d" % index, "team_alpha" if index < 14 else "team_bravo", Vector2(128.0 + float(column) * 64.0, 128.0 + float(row) * 64.0))
		root.add_child(unit)
		units.append(unit)
	view.call("set_unit_nodes", units)
	await _wait_frames(12)

	var samples: Array[float] = []
	var frame_count: int = 0
	var started_msec: int = Time.get_ticks_msec()
	while frame_count < 3600 or Time.get_ticks_msec() - started_msec < 60000:
		await process_frame
		frame_count += 1
		var frame_snapshot: Dictionary = Dictionary(view.call("get_runtime_frame_timing_debug_snapshot"))
		var scopes: Dictionary = Dictionary(frame_snapshot.get("scopes_usec", {}))
		var sample: Variant = scopes.get("unit_proxy_sync_usec", null)
		if typeof(sample) == TYPE_INT or typeof(sample) == TYPE_FLOAT:
			samples.append(float(sample))
	samples.sort()
	var p99_usec: float = _percentile(samples, 0.99)
	print("TASK_1188_SCALE_JSON=%s" % JSON.stringify({"unit_count": 28, "frame_count": frame_count, "duration_msec": Time.get_ticks_msec() - started_msec, "proxy_sync_p99_usec": p99_usec}))
	_assert(samples.size() >= 3600, "28-proxy scale run collects at least 3,600 proxy-sync samples")
	_assert(Time.get_ticks_msec() - started_msec >= 60000, "28-proxy scale run covers at least 60 seconds")
	_assert(p99_usec <= 8000.0, "28 proxies stay within the 8 ms p99 sync budget")

	view.queue_free()
	for unit in units:
		if unit != null and is_instance_valid(unit):
			unit.queue_free()
	await _wait_frames(2)


func _make_unit(unit_id: String, team_id: String, position_value: Vector2) -> Node2D:
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.set("unit_id", unit_id)
	unit.set("team_id", team_id)
	unit.set("fireteam_id", "task1188")
	unit.set("display_name", unit_id)
	unit.set("weapon_1_id", "rifle")
	unit.global_position = position_value
	return unit


func _diagnostics(view: Node) -> Dictionary:
	if view == null or not view.has_method("get_unit_proxy_sync_diagnostics"):
		return {}
	return Dictionary(view.call("get_unit_proxy_sync_diagnostics"))


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _percentile(sorted_values: Array[float], percentile: float) -> float:
	if sorted_values.is_empty():
		return INF
	var index: int = clampi(ceili(float(sorted_values.size()) * percentile) - 1, 0, sorted_values.size() - 1)
	return sorted_values[index]


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
