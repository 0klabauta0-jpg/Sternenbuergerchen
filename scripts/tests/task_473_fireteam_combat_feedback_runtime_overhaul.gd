extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const MISSION_TACTICAL_SANDBOX_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_473_fireteam_combat_feedback_runtime_overhaul.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_473 Fireteam Combat Feedback Runtime Overhaul ===")
	_test_damage_cover_is_normalized_and_outcome_is_authoritative()
	_test_damage_miss_outcome_is_emitted_without_damage()
	_test_combat_driver_enriches_fire_events_with_resolution()
	await _test_weapon_fire_visuals_expose_small_muzzle_and_impact()
	_test_suppression_and_ad_hoc_visibility_policy()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_damage_cover_is_normalized_and_outcome_is_authoritative() -> void:
	var setup: Dictionary = _make_simulation_setup()
	var simulation: Node = setup.get("simulation")
	var target: Node = setup.get("target")
	target.call("set_runtime_status", "holding", "hold_position", 10, "fire_at_will", "defend", 1.0, 20.0, 0.0)
	var outcomes: Array = []
	simulation.damage_effect_resolved.connect(func(result: Dictionary) -> void: outcomes.append(result.duplicate(true)))
	simulation.call("_apply_damage_effect", {
		"effect_type": "damage",
		"unit_id": "target",
		"attacker_unit_id": "attacker",
		"attacker_team_id": "team_alpha",
		"damage": 40,
		"hit_chance": 0.65,
		"damage_multiplier": 1.0,
		"roll_override": 0.55,
		"weapon_id": "rifle",
		"fire_event_id": "task473_hit",
	})
	var outcome: Dictionary = Dictionary(outcomes[0]) if not outcomes.is_empty() else {}
	_assert(not outcome.is_empty(), "SimulationRoot emits an authoritative damage outcome")
	_assert(bool(outcome.get("hit", false)), "Cover score 20 no longer clamps this shot to a miss")
	_assert(float(outcome.get("target_cover_ratio", -1.0)) > 0.19 and float(outcome.get("target_cover_ratio", -1.0)) < 0.21, "Cover score is normalized before hit math")
	_assert(float(outcome.get("hit_chance_resolved", 0.0)) > 0.55, "Resolved hit chance remains readable after moderate cover")
	_assert(int(outcome.get("damage_resolved", 0)) > 0 and int(target.call("get_health")) < int(target.call("get_max_health_points")), "Resolved hit applies visible damage")
	var scene_root: Node = setup.get("root")
	scene_root.queue_free()


func _test_damage_miss_outcome_is_emitted_without_damage() -> void:
	var setup: Dictionary = _make_simulation_setup()
	var simulation: Node = setup.get("simulation")
	var target: Node = setup.get("target")
	var outcomes: Array = []
	simulation.damage_effect_resolved.connect(func(result: Dictionary) -> void: outcomes.append(result.duplicate(true)))
	simulation.call("_apply_damage_effect", {
		"effect_type": "damage",
		"unit_id": "target",
		"attacker_unit_id": "attacker",
		"attacker_team_id": "team_alpha",
		"damage": 40,
		"hit_chance": 0.35,
		"damage_multiplier": 1.0,
		"roll_override": 0.95,
		"weapon_id": "rifle",
		"fire_event_id": "task473_miss",
	})
	var outcome: Dictionary = Dictionary(outcomes[0]) if not outcomes.is_empty() else {}
	_assert(not bool(outcome.get("hit", true)) and String(outcome.get("outcome", "")) == "miss", "Misses are reported as outcomes")
	_assert(int(outcome.get("damage_resolved", -1)) == 0, "Miss outcome carries zero resolved damage")
	_assert(int(target.call("get_health")) == int(target.call("get_max_health_points")), "Miss outcome does not damage the target")
	var scene_root: Node = setup.get("root")
	scene_root.queue_free()


func _test_combat_driver_enriches_fire_events_with_resolution() -> void:
	var driver: Node = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	var fire_event_id: String = "task473_fire_01"
	driver.call("_append_fire_event", {
		"event_id": fire_event_id,
		"event_type": "weapon_fire",
		"tick": 0,
		"attacker_unit_id": "attacker",
		"target_unit_id": "target",
		"weapon_id": "rifle",
		"attacker_position": Vector2.ZERO,
		"target_position": Vector2(96.0, 0.0),
	})
	driver.call("_on_damage_effect_resolved", {
		"fire_event_id": fire_event_id,
		"outcome": "hit",
		"hit": true,
		"hit_chance_resolved": 0.58,
		"roll": 0.55,
		"damage_resolved": 38,
		"damage_multiplier_resolved": 0.96,
		"target_cover_score": 20.0,
		"target_cover_ratio": 0.2,
		"target_health_points": 62,
		"target_vital_state": "fit",
	})
	var events: Array = Array(driver.call("get_fire_event_snapshot"))
	var event: Dictionary = Dictionary(events[0]) if not events.is_empty() else {}
	_assert(String(event.get("combat_outcome", "")) == "hit", "CombatLoop fire event exposes the authoritative outcome")
	_assert(int(event.get("damage_resolved", 0)) == 38, "CombatLoop fire event exposes resolved damage")
	_assert(float(event.get("target_cover_ratio", 0.0)) == 0.2, "CombatLoop fire event carries normalized cover for UI/VFX")
	driver.queue_free()


func _test_weapon_fire_visuals_expose_small_muzzle_and_impact() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task473_vfx", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var events: Array = []
	for index in range(5):
		events.append({
			"event_id": "task473_fire_%02d" % index,
			"event_type": "weapon_fire",
			"attacker_unit_id": "alpha_%02d" % index,
			"target_unit_id": "enemy_%02d" % index,
			"weapon_id": "rifle",
			"combat_outcome": "hit" if index == 4 else "miss",
			"damage_resolved": 38 if index == 4 else 0,
			"hit_chance_resolved": 0.58,
			"attacker_position": Vector2(96.0 + float(index), 128.0),
			"target_position": Vector2(240.0, 128.0 + float(index) * 4.0),
		})
	view.call("set_order_visual_payload", {"fire_event_dicts": events})
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var entry: Dictionary = _find_entry(entries, "event_id", "task473_fire_04")
	_assert(int(snapshot.get("weapon_fire_vfx_visual_count", 0)) == 3, "Weapon-fire VFX caps visible events for performance")
	_assert(not entry.is_empty(), "Newest weapon-fire VFX remains visible")
	_assert(float(entry.get("muzzle_flash_length_world", 99.0)) <= 10.0, "Muzzle impulse is a short flash, not a wall-sized column")
	_assert(float(entry.get("trace_width", 99.0)) <= 0.013, "Fire trace remains thin")
	_assert(bool(entry.get("impact_marker_visible", false)) and bool(entry.get("impact_cross_visible", false)), "Target-side impact marker makes shot landing readable")
	_assert(String(entry.get("combat_outcome", "")) == "hit", "VFX entry exposes hit/miss outcome")
	view.queue_free()
	await _wait_frames(2)


func _test_suppression_and_ad_hoc_visibility_policy() -> void:
	var controller: Node = MISSION_TACTICAL_SANDBOX_CONTROLLER_SCRIPT.new()
	controller.set("_selected_fireteam_ids", PackedStringArray(["drill"]))
	controller.set("_suppression_state_by_fireteam", {
		"drill": {"value": 2.0, "threshold": 2.0, "is_suppressed": true, "is_heavily_suppressed": false},
	})
	_assert(not bool(controller.call("_is_fireteam_go_recovery_blocked", "drill")), "Light suppression does not block GO recovery like a pinned interrupt")
	controller.set("_suppression_state_by_fireteam", {
		"drill": {"value": 3.7, "threshold": 2.0, "is_suppressed": true, "is_heavily_suppressed": true},
	})
	_assert(bool(controller.call("_is_fireteam_go_recovery_blocked", "drill")), "Heavy suppression remains the pinned/recovery block")
	controller.set("_suppression_interrupt_pending_by_fireteam", {})
	controller.set("_ad_hoc_execution_by_fireteam", {})
	controller.set("_ad_hoc_resume_state_by_fireteam", {})
	_assert(not bool(controller.call("_selected_fireteams_have_ad_hoc_panel_context")), "Combat alone does not expose the Ad-Hoc overlay over #16")
	controller.set("_suppression_interrupt_pending_by_fireteam", {"drill": true})
	_assert(bool(controller.call("_selected_fireteams_have_ad_hoc_panel_context")), "Ad-Hoc overlay appears for real recovery context")
	controller.queue_free()


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("TASK 473") and task_text.contains("Combat Feedback Runtime Overhaul"), "TASK_473 task file exists")
	_assert(status_text.contains("TASK_473 - Fireteam Combat Feedback Runtime Overhaul"), "Implementation status documents TASK_473")
	_assert(roadmap_text.contains("TASK_473 - Fireteam Combat Feedback Runtime Overhaul"), "Roadmap lists TASK_473")


func _make_simulation_setup() -> Dictionary:
	var scene_root := Node.new()
	root.add_child(scene_root)
	var registry = UNIT_REGISTRY_SCRIPT.new()
	registry.name = "UnitRegistry"
	scene_root.add_child(registry)
	var simulation = SIMULATION_ROOT_SCRIPT.new()
	simulation.name = "SimulationRoot"
	simulation.unit_registry_path = NodePath("../UnitRegistry")
	scene_root.add_child(simulation)
	var attacker := _make_unit("attacker", "team_alpha", "blue", Vector2.ZERO)
	var target := _make_unit("target", "team_bravo", "red", Vector2(96.0, 0.0))
	scene_root.add_child(attacker)
	scene_root.add_child(target)
	registry.call("register_unit", "attacker", attacker)
	registry.call("register_unit", "target", target)
	return {"root": scene_root, "simulation": simulation, "attacker": attacker, "target": target}


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, position_value: Vector2) -> Node2D:
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.display_name = unit_id
	unit.weapon_1_id = "rifle"
	unit.weapon_2_id = "none"
	unit.global_position = position_value
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
