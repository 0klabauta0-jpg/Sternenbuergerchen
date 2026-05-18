extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_470_fireteam_combatloop_unit_bridge_recovery.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_470 Fireteam CombatLoop Unit Bridge Recovery ===")
	await _test_drill_scene_has_explicit_enemy_fireteam()
	await _test_combat_loop_uses_registry_when_paths_are_stale()
	await _test_startup_no_unit_state_does_not_resolve_defeat()
	await _test_premature_startup_defeat_recovers_after_registration()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_drill_scene_has_explicit_enemy_fireteam() -> void:
	var scene: Node = await _make_ready_scene()
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	var setup: Node = scene.get_node_or_null("MissionSetup")
	_assert(combat_loop != null and setup != null, "Drill scene exposes CombatLoop and MissionSetup")
	if combat_loop == null or setup == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	_assert(scene.get_node_or_null("EnemyFoxtrot") != null, "Drill scene has explicit EnemyFoxtrot node")
	_assert(scene.get_node_or_null("EnemyGolf") != null, "Drill scene has explicit EnemyGolf node")
	_assert(Array(combat_loop.get("enemy_unit_paths")).size() >= 4, "CombatLoop has four configured enemy paths")
	_assert(Array(setup.get("unit_paths")).size() >= 12, "MissionSetup runtime paths include the full 4v4 drill set")
	var presence: Dictionary = Dictionary(combat_loop.call("get_unit_presence_audit_snapshot"))
	_assert(Array(presence.get("active_friendly_unit_ids", [])).size() >= 4, "Direct F6 drill reports four active friendlies")
	_assert(Array(presence.get("active_enemy_unit_ids", [])).size() >= 4, "Direct F6 drill reports four active enemies")
	scene.queue_free()
	await _wait_frames(2)


func _test_combat_loop_uses_registry_when_paths_are_stale() -> void:
	var scene: Node = await _make_ready_scene()
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	_assert(combat_loop != null, "Registry fallback test has CombatLoop")
	if combat_loop == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var stale_friendlies: Array[NodePath] = [NodePath("../MissingFriendly")]
	var stale_enemies: Array[NodePath] = [NodePath("../MissingEnemy")]
	combat_loop.set("friendly_unit_paths", stale_friendlies)
	combat_loop.set("enemy_unit_paths", stale_enemies)
	var presence: Dictionary = Dictionary(combat_loop.call("get_unit_presence_audit_snapshot"))
	_assert(Array(presence.get("active_friendly_unit_ids", [])).size() >= 4, "CombatLoop falls back to UnitRegistry for stale friendly paths")
	_assert(Array(presence.get("active_enemy_unit_ids", [])).size() >= 4, "CombatLoop falls back to UnitRegistry for stale enemy paths")

	var partial_enemies: Array[NodePath] = [NodePath("../EnemyDelta"), NodePath("../MissingEnemy")]
	combat_loop.set("enemy_unit_paths", partial_enemies)
	presence = Dictionary(combat_loop.call("get_unit_presence_audit_snapshot"))
	_assert(Array(presence.get("active_enemy_unit_ids", [])).size() >= 4, "CombatLoop supplements partial enemy paths from UnitRegistry")

	combat_loop.call("_record_contact_decision_diagnostics", "no_contact_pair", {"candidate": {"candidate_reason": "no_friendly_units"}})
	var diagnostics: Dictionary = Dictionary(combat_loop.call("get_contact_decision_diagnostics_snapshot"))
	var candidate: Dictionary = Dictionary(diagnostics.get("candidate", {}))
	_assert(int(diagnostics.get("active_friendly_count", 0)) >= 4, "#18 diagnostics refresh friendly count from registry")
	_assert(int(diagnostics.get("active_enemy_count", 0)) >= 4, "#18 diagnostics refresh enemy count from registry")
	_assert(String(candidate.get("candidate_reason", "")) != "no_friendly_units", "#18 diagnostics do not keep stale no_friendly_units candidate")
	scene.queue_free()
	await _wait_frames(2)


func _test_startup_no_unit_state_does_not_resolve_defeat() -> void:
	var scene: Node = await _make_ready_scene()
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	var unit_registry: Node = scene.get_node_or_null("UnitRegistry")
	_assert(combat_loop != null and unit_registry != null, "Startup no-unit test has CombatLoop and UnitRegistry")
	if combat_loop == null or unit_registry == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	unit_registry.call("clear")
	combat_loop.set("_combat_finished", false)
	combat_loop.set("_has_seen_active_friendly_units", false)
	combat_loop.call("_update_combat_resolution")
	_assert(not bool(combat_loop.call("is_combat_finished")), "CombatLoop does not resolve defeat before it has ever seen active friendlies")
	scene.queue_free()
	await _wait_frames(2)


func _test_premature_startup_defeat_recovers_after_registration() -> void:
	var scene: Node = await _make_ready_scene()
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	_assert(combat_loop != null, "Startup recovery test has CombatLoop")
	if combat_loop == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	combat_loop.set("_combat_finished", true)
	combat_loop.set("_resolved_without_seen_friendly", true)
	combat_loop.set("_has_seen_active_friendly_units", false)
	combat_loop.set("_winning_team_id", "team_bravo")
	combat_loop.set("_mission_result", {"result": "defeat", "winning_team_id": "team_bravo"})
	_assert(bool(combat_loop.call("_try_recover_premature_startup_resolution")), "CombatLoop recovers a premature startup defeat after friendlies register")
	_assert(not bool(combat_loop.call("is_combat_finished")), "Recovered CombatLoop is active again")
	var diagnostics: Dictionary = Dictionary(combat_loop.call("get_contact_decision_diagnostics_snapshot"))
	_assert(String(diagnostics.get("reason", "")) == "startup_presence_recovered", "Recovery writes a readable diagnostic")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("TASK_470 - Fireteam CombatLoop Unit Bridge Recovery"), "TASK_470 task file exists")
	_assert(status_text.contains("TASK_470 - Fireteam CombatLoop Unit Bridge Recovery"), "Implementation status documents TASK_470")
	_assert(roadmap_text.contains("TASK_470 - Fireteam CombatLoop Unit Bridge Recovery"), "Roadmap lists TASK_470")


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
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
