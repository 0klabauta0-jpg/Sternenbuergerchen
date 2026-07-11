extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TACTICAL_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const FIRETEAM_SECURITY_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_security_controller.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_464_fireteam_contact_scan_fire_feedback_readability.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_464 Fireteam Contact Scan Fire Feedback Readability ===")
	await _test_canvas_hidden_enemy_stays_combat_target()
	await _test_security_scan_facing_overrides_static_map_facing()
	await _test_hostile_base_is_underfoot_readability_marker()
	_test_selected_cards_use_readable_runtime_labels()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_canvas_hidden_enemy_stays_combat_target() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(90)
	var setup := scene.get_node_or_null("MissionSetup")
	var controller := scene.get_node_or_null("TacticalController")
	var combat_loop := scene.get_node_or_null("CombatLoopDriver")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_assert(setup != null and controller != null and combat_loop != null and simulation_root != null, "Drill scene exposes setup, controller, combat loop and simulation")
	if setup == null or controller == null or combat_loop == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	if setup.has_method("set_fog_of_war_mode"):
		setup.call("set_fog_of_war_mode", "off")
	var friendlies: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	_assert(friendlies.size() >= 1 and enemies.size() >= 1, "Drill scene has friendly and enemy units")
	if friendlies.is_empty() or enemies.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return
	var friendly := friendlies[0] as Node2D
	var enemy := enemies[0] as Node2D
	enemy.global_position = Vector2(1280.0, 720.0)
	friendly.global_position = enemy.global_position + Vector2(-56.0, 0.0)
	enemy.visible = false
	friendly.call("set_runtime_status", "holding", "hold_position", 30, "fire_at_will", "engage", 1.0, 0.0, 0.0, 1, friendly.global_position, "engage", "aimed", "task464_contact_hold", 1.0, 80.0)
	var friendly_id: String = String(friendly.call("get_unit_id"))
	var enemy_id: String = String(enemy.call("get_unit_id"))
	combat_loop.set("_detection_progress", {"%s:%s" % [friendly_id, enemy_id]: 0})
	combat_loop.set("_current_tick", 120)
	combat_loop.set("_next_attack_tick", 0)
	combat_loop.call("_try_enqueue_attacks", simulation_root)
	var diagnostics: Dictionary = Dictionary(combat_loop.call("get_contact_decision_diagnostics_snapshot"))
	_assert(String(diagnostics.get("reason", "")) == "fired", "Canvas-hidden active enemy can still be selected and fired on")
	scene.queue_free()
	await _wait_frames(2)


func _test_security_scan_facing_overrides_static_map_facing() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task464_security_scan", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var unit = _make_unit("task464_alpha", "team_alpha", "drill", Vector2(128.0, 128.0))
	root.add_child(unit)
	unit.set_meta("facing_angle", 0.0)
	unit.set_meta("map_facing_angle", 0.0)
	unit.set_meta("security_facing_active", true)
	unit.set_meta("security_facing_angle", PI * 0.5)
	var direction: Vector2 = Vector2(view.call("_resolve_unit_explicit_facing_direction", unit)).normalized()
	_assert(direction.dot(Vector2.DOWN) > 0.95, "Security scan facing wins over stale static map facing")
	_assert(float(FIRETEAM_SECURITY_CONTROLLER_SCRIPT.DEFENSE_SCAN_HALF_ANGLE) > 0.25, "Defense scan half-angle is wide enough for visible left/right sweep")
	view.queue_free()
	unit.queue_free()
	await _wait_frames(2)


func _test_hostile_base_is_underfoot_readability_marker() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task464_hostile_base", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var enemy = _make_unit("task464_enemy", "team_bravo", "enemy", Vector2(128.0, 128.0))
	root.add_child(enemy)
	view.call("set_unit_nodes", [enemy])
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var state_by_id: Dictionary = Dictionary(snapshot.get("unit_proxy_state_by_id", {}))
	var state: Dictionary = Dictionary(state_by_id.get("task464_enemy", {}))
	_assert(bool(state.get("unit_team_base_visible", false)), "Hostile proxy still has a team base marker")
	_assert(float(state.get("unit_team_base_radius", 1.0)) < 0.20, "Hostile team base is smaller than the body footprint")
	_assert(float(state.get("unit_team_base_alpha", 1.0)) <= 0.36, "Hostile team base is transparent enough to not cover the model")
	_assert(float(state.get("unit_team_base_y", 0.0)) < -0.03, "Hostile team base is lowered under the feet")
	view.queue_free()
	enemy.queue_free()
	await _wait_frames(2)


func _test_selected_cards_use_readable_runtime_labels() -> void:
	var controller: Node = TACTICAL_CONTROLLER_SCRIPT.new()
	var unit = _make_unit("task464_card", "team_alpha", "drill", Vector2.ZERO)
	unit.call("set_tactical_stance_indicator", "cautious", 1)
	unit.call("set_runtime_status", "engaging", "move_to_position", 12, "fire_at_will", "engage", 0.65, 75.0, 8.0, -1, Vector2(64.0, 0.0), "engage", "aimed", "task464", 1.2, 80.0)
	var runtime_line: String = String(controller.call("_build_live_fireteam_card_runtime_line", unit))
	var detail_line: String = String(controller.call("_build_live_fireteam_card_detail_line", unit))
	_assert(runtime_line.contains("Angreifen") and runtime_line.contains("Feuer frei") and runtime_line.contains("VORS"), "#17 runtime line uses readable compact command/fire/stance labels: %s" % runtime_line)
	_assert(detail_line.contains("Waffe im Anschlag") and detail_line.contains("Kampfbewegung") and detail_line.contains("Zielbereit 80%"), "#17 detail line explains weapon posture, movement posture and aim readiness")
	controller.queue_free()
	unit.queue_free()


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("TASK_464 - Fireteam Contact Scan Fire Feedback Readability"), "TASK_464 task file exists")
	_assert(status_text.contains("TASK_464 - Fireteam Contact Scan Fire Feedback Readability"), "Implementation status documents TASK_464")
	_assert(roadmap_text.contains("TASK_464 - Fireteam Contact Scan Fire Feedback Readability"), "Roadmap lists TASK_464")
	_assert(contract_text.contains("TASK_464 Contact-/Scan-/Feedback-Lesbarkeit"), "Behavior contract documents TASK_464")


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, position_value: Vector2):
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


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	push_error("  FAIL: %s" % message)
