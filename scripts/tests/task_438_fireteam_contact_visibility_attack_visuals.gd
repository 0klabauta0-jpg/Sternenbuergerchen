extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_438_fireteam_contact_visibility_attack_visuals.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_438 Fireteam Contact Visibility Attack Visuals ===")
	await _test_contact_turns_fire_lines_and_traces_red()
	await _test_live_close_contact_generates_fire_event_and_vfx()
	await _test_drill_enemy_bodies_and_bush_height_are_visible()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_contact_turns_fire_lines_and_traces_red() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task438_contact_visual", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	var unit: Node2D = _make_unit("task438_alpha", "team_alpha", "drill", Vector2(160.0, 160.0))
	root.add_child(unit)
	unit.call("set_runtime_status", "holding", "hold_position", 10, "fire_at_will", "defend", 1.0, 0.0, 0.0, 1, unit.global_position, "engage", "aimed", "task438_defend", 1.0)
	primary_view.call("set_unit_nodes", [unit])
	await _wait_frames(8)
	primary_view.call("set_order_visual_payload", {
		"selected_fireteam_ids": PackedStringArray(["drill"]),
		"fire_sector_overlay_enabled": true,
		"fire_sector_visual_mode": "los_line_only",
	})
	primary_view.call("set_contact_entries", [{
		"fireteam_id": "drill",
		"unit_id": "task438_enemy",
		"team_id": "team_bravo",
		"last_known_position": unit.global_position + Vector2(256.0, 0.0),
		"detection_state": "confirmed",
	}], PackedStringArray(["drill"]))
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var aim_entry: Dictionary = _find_entry(Array(snapshot.get("friendly_aim_entries", [])), "unit_id", "task438_alpha")
	_assert(not aim_entry.is_empty(), "Selected fireteam emits a fire-line entry")
	_assert(bool(aim_entry.get("contact_visual_active", false)), "Confirmed contact marks the friendly fire-line as contact-active")
	_assert(_is_contact_red(Color(aim_entry.get("line_color", Color.BLACK))), "Confirmed contact turns the friendly fire-line red")

	primary_view.call("set_order_visual_payload", {
		"selected_fireteam_ids": PackedStringArray(["drill"]),
		"fire_sector_overlay_enabled": true,
		"fire_sector_visual_mode": "los_line_only",
		"fire_event_dicts": [{
			"event_id": "task438_fire",
			"event_type": "weapon_fire",
			"attacker_unit_id": "task438_alpha",
			"target_unit_id": "task438_enemy",
			"weapon_id": "rifle",
			"attacker_position": unit.global_position,
			"target_position": unit.global_position + Vector2(256.0, 0.0),
		}],
	})
	await _wait_frames(8)
	snapshot = Dictionary(primary_view.call("get_render_snapshot"))
	var vfx_entry: Dictionary = _find_entry(Array(snapshot.get("weapon_fire_vfx_entries", [])), "event_id", "task438_fire")
	_assert(bool(vfx_entry.get("muzzle_flash_visible", false)), "Weapon-fire payload still creates a muzzle flash")
	_assert(_is_contact_red(Color(vfx_entry.get("trace_color", Color.BLACK))), "Weapon-fire trace is red for visible enemy contact")
	primary_view.queue_free()
	unit.queue_free()
	await _wait_frames(2)


func _test_live_close_contact_generates_fire_event_and_vfx() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(80)
	var setup := scene.get_node_or_null("MissionSetup")
	var controller := scene.get_node_or_null("TacticalController")
	var combat_loop := scene.get_node_or_null("CombatLoopDriver")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(setup != null and controller != null and combat_loop != null and simulation_root != null and primary_view != null, "Drill scene exposes live combat and primary 3D view")
	if setup == null or controller == null or combat_loop == null or simulation_root == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	if setup.has_method("set_fog_of_war_mode"):
		setup.call("set_fog_of_war_mode", "off")
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var friendlies: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	_assert(friendlies.size() == 4 and enemies.size() == 4, "Live drill has four friendlies and four enemies for contact")
	if friendlies.is_empty() or enemies.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return
	var friendly := friendlies[0] as Node2D
	var enemy := enemies[0] as Node2D
	_assert(friendly != null and enemy != null, "Live contact test has Node2D attacker and target")
	if friendly == null or enemy == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	enemy.global_position = Vector2(1280.0, 720.0)
	friendly.global_position = enemy.global_position + Vector2(-64.0, 0.0)
	for index in range(friendlies.size()):
		var unit := friendlies[index] as Node2D
		if unit == null:
			continue
		unit.global_position = friendly.global_position + Vector2(0.0, float(index) * 24.0)
		unit.call("set_runtime_status", "holding", "hold_position", 30, "fire_at_will", "defend", 1.0, 0.0, 0.0, 1, unit.global_position, "engage", "aimed", "task438_contact_hold", 1.0)
	var friendly_id: String = String(friendly.call("get_unit_id"))
	var enemy_id: String = String(enemy.call("get_unit_id"))
	var detection_progress: Dictionary = Dictionary(combat_loop.get("_detection_progress")).duplicate(true)
	detection_progress["%s:%s" % [friendly_id, enemy_id]] = 0
	detection_progress["%s:%s" % [enemy_id, friendly_id]] = 0
	combat_loop.set("_detection_progress", detection_progress)
	combat_loop.set("_current_tick", 100)
	combat_loop.set("_next_attack_tick", 0)
	combat_loop.call("_try_enqueue_attacks", simulation_root)
	var fire_events: Array = Array(combat_loop.call("get_fire_event_snapshot"))
	await _wait_frames(10)
	_assert(not fire_events.is_empty(), "Live close contact records a weapon-fire event")
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(render_snapshot.get("weapon_fire_vfx_visual_count", 0)) >= 1, "Live weapon-fire event reaches the primary 3D muzzle-flash path")
	var vfx_entries: Array = Array(render_snapshot.get("weapon_fire_vfx_entries", []))
	_assert(_any_vfx_trace_is_red(vfx_entries), "Live weapon-fire VFX uses a red trace")
	scene.queue_free()
	await _wait_frames(2)


func _test_drill_enemy_bodies_and_bush_height_are_visible() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(90)
	var setup := scene.get_node_or_null("MissionSetup")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(setup != null and primary_view != null, "Drill scene exposes setup and primary view for visual audit")
	if setup == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	if setup.has_method("set_fog_of_war_mode"):
		setup.call("set_fog_of_war_mode", "off")
	await _wait_frames(8)
	var presence: Dictionary = Dictionary(setup.call("get_expected_unit_presence_snapshot"))
	var enemy_ids: Array = Array(presence.get("enemy_unit_ids", []))
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var visible_ids: Array = Array(snapshot.get("visible_unit_proxy_ids", []))
	var state_by_id: Dictionary = Dictionary(snapshot.get("unit_proxy_state_by_id", {}))
	_assert(enemy_ids.size() == 4 and _contains_all(visible_ids, enemy_ids), "All four hostile proxies are visible")
	_assert(_all_enemy_bodies_visible(state_by_id, enemy_ids), "All four hostile proxies expose a visible body/readability core, not only IDLE/base markers")
	_assert(_bushes_are_grounded_above_surface(Array(snapshot.get("nature_prop_visual_entries", []))), "Bush props stay on ground tiles and render above the tile surface")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("TASK_438 - Fireteam Contact Visibility Attack Visuals"), "TASK_438 task file exists")
	_assert(status_text.contains("TASK_438 - Fireteam Contact Visibility Attack Visuals"), "Implementation status documents TASK_438")
	_assert(roadmap_text.contains("TASK_438 - Fireteam Contact Visibility Attack Visuals"), "Roadmap lists TASK_438")


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


func _all_enemy_bodies_visible(state_by_id: Dictionary, enemy_ids: Array) -> bool:
	if enemy_ids.size() < 4:
		return false
	for enemy_id_variant in enemy_ids:
		var enemy_id: String = String(enemy_id_variant).strip_edges()
		var state: Dictionary = Dictionary(state_by_id.get(enemy_id, {}))
		if state.is_empty():
			return false
		if not bool(state.get("visible", false)):
			return false
		if bool(state.get("missing_unit_model", false)) or bool(state.get("unit_visual_error", false)):
			return false
		if not bool(state.get("uses_animated_character_model", false)):
			return false
		if not bool(state.get("unit_body_visual_visible", false)):
			return false
		if not bool(state.get("unit_body_readability_core_visible", false)):
			return false
	return true


func _bushes_are_grounded_above_surface(entries: Array) -> bool:
	var bush_count: int = 0
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("visual_type_id", "")) != "nature_bush_cover":
			continue
		bush_count += 1
		if String(entry.get("type_id", "")) != "ground_flat":
			return false
		var surface_y: float = float(entry.get("surface_y", 0.0))
		var world_y: float = float(entry.get("world_y", 0.0))
		if world_y - surface_y < 0.10:
			return false
	return bush_count >= 6


func _any_vfx_trace_is_red(entries: Array) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if _is_contact_red(Color(entry.get("trace_color", Color.BLACK))):
			return true
	return false


func _is_contact_red(color: Color) -> bool:
	return color.r >= 0.9 and color.g <= 0.45 and color.b <= 0.32 and color.a >= 0.75


func _find_entry(entries: Array, key: String, expected_value: Variant) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if entry.get(key) == expected_value:
			return entry
	return {}


func _contains_all(values: Array, expected_values: Array) -> bool:
	for expected_variant in expected_values:
		if not values.has(expected_variant):
			return false
	return true


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
