extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_479_fireteam_runtime_hotpath_guards.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_479 Fireteam Runtime Hotpath Guards ===")
	await _test_hotpath_audit_reports_central_policy()
	await _test_registry_filter_marks_unregistered_friendly_inactive()
	await _test_down_enemy_stays_registered_but_leaves_combat_candidates()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_hotpath_audit_reports_central_policy() -> void:
	var scene: Node = await _make_ready_scene()
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	_assert(combat_loop != null, "Drill scene exposes CombatLoop for hotpath audit")
	if combat_loop == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var audit: Dictionary = Dictionary(combat_loop.call("get_combat_hotpath_audit_snapshot"))
	_assert(String(audit.get("authority_root", "")) == "SimulationRoot", "Hotpath audit keeps SimulationRoot as authority")
	_assert(String(audit.get("combat_candidate_policy", "")) == "registered_Node2D_and_vital_fit", "Hotpath audit documents combat-candidate filter")
	_assert(not bool(audit.get("per_unit_area2d_ai", true)), "Hotpath audit rejects per-unit Area2D AI")
	_assert(String(audit.get("navigation_authority", "")) == "existing_TerrainRegistry_HPA_AStar_path", "Hotpath audit keeps existing navigation authority")
	_assert(int(audit.get("active_friendly_count", 0)) >= 4, "Hotpath audit sees registered active friendlies")
	_assert(int(audit.get("active_enemy_count", 0)) >= 4, "Hotpath audit sees registered active enemies")
	_assert(int(audit.get("combat_friendly_count", 0)) >= 4, "Hotpath audit sees fit friendly combat candidates")
	_assert(int(audit.get("combat_enemy_count", 0)) >= 4, "Hotpath audit sees fit enemy combat candidates")
	_assert(int(audit.get("potential_combat_pair_count", 0)) >= 16, "Hotpath audit exposes potential combat pair count")

	scene.queue_free()
	await _wait_frames(2)


func _test_registry_filter_marks_unregistered_friendly_inactive() -> void:
	var scene: Node = await _make_ready_scene()
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	var unit_registry: Node = scene.get_node_or_null("UnitRegistry")
	_assert(combat_loop != null and unit_registry != null, "Registry filter test has CombatLoop and UnitRegistry")
	if combat_loop == null or unit_registry == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var before: Dictionary = Dictionary(combat_loop.call("get_unit_presence_audit_snapshot"))
	var active_friendly_ids: Array = Array(before.get("active_friendly_unit_ids", []))
	_assert(active_friendly_ids.size() >= 4, "Presence audit starts with four active friendlies")
	if active_friendly_ids.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return

	var removed_id: String = String(active_friendly_ids[0])
	var removed_unit: Node = unit_registry.call("get_unit", removed_id)
	unit_registry.call("unregister_unit", removed_id)

	var after: Dictionary = Dictionary(combat_loop.call("get_unit_presence_audit_snapshot"))
	var active_after: Array = Array(after.get("active_friendly_unit_ids", []))
	var inactive_after: Array = Array(after.get("inactive_friendly_unit_ids", []))
	var combat_after: Array = Array(after.get("combat_friendly_unit_ids", []))
	_assert(not active_after.has(removed_id), "Unregistered friendly is no longer active in CombatLoop")
	_assert(inactive_after.has(removed_id), "Unregistered friendly appears as inactive slot in Presence audit")
	_assert(not combat_after.has(removed_id), "Unregistered friendly is not a combat candidate")

	if removed_unit != null:
		unit_registry.call("register_unit", removed_id, removed_unit)
	scene.queue_free()
	await _wait_frames(2)


func _test_down_enemy_stays_registered_but_leaves_combat_candidates() -> void:
	var scene: Node = await _make_ready_scene()
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	var unit_registry: Node = scene.get_node_or_null("UnitRegistry")
	_assert(combat_loop != null and unit_registry != null, "Down-filter test has CombatLoop and UnitRegistry")
	if combat_loop == null or unit_registry == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var before: Dictionary = Dictionary(combat_loop.call("get_unit_presence_audit_snapshot"))
	var active_enemy_ids: Array = Array(before.get("active_enemy_unit_ids", []))
	_assert(active_enemy_ids.size() >= 4, "Presence audit starts with four active enemies")
	if active_enemy_ids.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return

	var downed_id: String = String(active_enemy_ids[0])
	var enemy: Node = unit_registry.call("get_unit", downed_id)
	_assert(enemy != null and enemy.has_method("apply_damage"), "Enemy test unit can receive damage")
	if enemy != null and enemy.has_method("apply_damage"):
		enemy.call("apply_damage", 9999, {"source": "task_479_hotpath_guard"})
	await _wait_frames(1)

	var after: Dictionary = Dictionary(combat_loop.call("get_unit_presence_audit_snapshot"))
	_assert(Array(after.get("active_enemy_unit_ids", [])).has(downed_id), "Downed enemy remains an active registered runtime enemy")
	_assert(not Array(after.get("combat_enemy_unit_ids", [])).has(downed_id), "Downed enemy is removed from combat candidates")

	combat_loop.call("_update_contact_tracking")
	var audit: Dictionary = Dictionary(combat_loop.call("get_combat_hotpath_audit_snapshot"))
	var potential_pairs: int = int(audit.get("potential_combat_pair_count", 0))
	var scanned_pairs: int = int(audit.get("last_contact_tracking_scan_pair_count", 0))
	_assert(scanned_pairs <= potential_pairs, "Contact tracking scan count is bounded by combat candidate pairs")

	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("TASK_479 - Fireteam Runtime Hotpath Guards"), "TASK_479 task file exists")
	_assert(status_text.contains("TASK_479 - Fireteam Runtime Hotpath Guards"), "Implementation status documents TASK_479")
	_assert(roadmap_text.contains("TASK_479 - Fireteam Runtime Hotpath Guards"), "Roadmap lists TASK_479")
	_assert(contract_text.contains("TASK_479 Runtime-Hotpath-Guards"), "Behavior contract documents TASK_479")


func _make_ready_scene():
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(120)
	var setup := scene.get_node_or_null("MissionSetup")
	if setup != null and setup.has_method("set_fog_of_war_mode"):
		setup.call("set_fog_of_war_mode", "off")
	await _wait_frames(8)
	return scene


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
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
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
