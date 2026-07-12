extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH := "res://docs/tasks/TASK_1173_first_engagement_feedback_release_recapture.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCHEMA := "sternenbuergerchen.mission_first_engagement_feedback_release_recapture.v1"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1173 First Engagement Feedback Release Recapture ===")
	_test_docs_and_static_hooks()
	await _test_first_engagement_release_recapture_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1173: FAILED")
		quit(1)
		return
	print("TASK_1173: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text := _read_text(TASK_PATH)
	var status_text := _read_text(STATUS_PATH)
	var roadmap_text := _read_text(ROADMAP_PATH)
	var contract_text := _read_text(COMMAND_CONTRACT_PATH)
	var controller_text := _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK 1173 task document exists")
	_assert(task_text.contains("First Engagement Feedback Release Recapture"), "Task document names TASK 1173")
	_assert(task_text.contains("get_mission_first_engagement_feedback_release_recapture_snapshot"), "Task document names snapshot contract")
	_assert(status_text.contains("TASK_1173 - First Engagement Feedback Release Recapture"), "Implementation status tracks TASK 1173")
	_assert(roadmap_text.contains("TASK_1173 - First Engagement Feedback Release Recapture"), "Roadmap tracks TASK 1173")
	_assert(contract_text.contains("get_mission_first_engagement_feedback_release_recapture_snapshot"), "Mission feedback contract documents TASK 1173")
	_assert(controller_text.contains("get_mission_first_engagement_feedback_release_recapture_snapshot"), "Controller exposes TASK 1173 snapshot")


func _test_first_engagement_release_recapture_snapshot() -> void:
	root.size = Vector2i(1280, 720)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and simulation_root != null, "Mission fixture exposes TacticalController and SimulationRoot")
	if controller == null or simulation_root == null:
		scene.queue_free()
		return
	_assert(controller.has_method("get_mission_first_engagement_feedback_release_recapture_snapshot"), "Controller has TASK 1173 public snapshot method")
	if not controller.has_method("get_mission_first_engagement_feedback_release_recapture_snapshot"):
		scene.queue_free()
		return

	var contact_recapture := _build_task_1172_handoff_fixture()
	var engagement_feedback := _build_task_543_engagement_fixture()
	var command_count_before := Array(simulation_root.get("command_queue")).size()
	var effect_count_before := Array(simulation_root.get("effects_queue")).size()
	var snapshot: Dictionary = Dictionary(controller.call("get_mission_first_engagement_feedback_release_recapture_snapshot", contact_recapture, engagement_feedback))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1173", "Snapshot identifies TASK 1173")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1172", "Snapshot links TASK 1172")
	_assert(String(snapshot.get("status", "")) == "recaptured", "Snapshot recaptures first engagement feedback")
	_assert(bool(snapshot.get("ready_for_first_fire_visual_recapture", false)), "Snapshot opens the first fire visual recapture")
	_assert(_snapshot_is_read_only(snapshot), "TASK 1173 snapshot remains read-only")
	_assert(Array(simulation_root.get("command_queue")).size() == command_count_before, "TASK 1173 snapshot enqueues no command")
	_assert(Array(simulation_root.get("effects_queue")).size() == effect_count_before, "TASK 1173 snapshot enqueues no effect")
	_assert(bool(snapshot.get("engagement_decision_visible", false)), "Engagement decision is visible")
	_assert(bool(snapshot.get("target_or_block_reason_visible", false)), "Target or concrete block reason is visible")
	_assert(bool(snapshot.get("fire_event_or_block_visible", false)), "Fire event or wait/block state is visible")
	_assert(bool(snapshot.get("cover_range_los_context_visible", false)), "Cover, range or LOS context is visible")
	_assert(bool(snapshot.get("feedback_text_visible", false)), "Player-facing engagement feedback text is visible")
	_assert(Array(snapshot.get("accepted_surfaces", [])).has("first_engagement_after_contact"), "Accepted surfaces include engagement after contact")

	scene.queue_free()
	await _wait_frames(2)


func _build_task_1172_handoff_fixture() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.mission_first_contact_readability_release_recapture.v1",
		"task_id": "TASK_1172",
		"status": "recaptured",
		"ready_for_first_engagement_recapture": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_effect": false,
		"creates_contact": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


func _build_task_543_engagement_fixture() -> Dictionary:
	var first_fire_event := {
		"attacker_unit_id": "unit_alpha",
		"target_unit_id": "enemy_probe_01",
		"weapon_id": "rifle",
		"result": "hit",
	}
	return {
		"task_id": "TASK_543",
		"gate": "pass",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"engagement_status": "fired",
		"engagement_reason": "confirmed_contact_in_clear_los",
		"contact_decision_diagnostics": {
			"status": "fired",
			"reason": "confirmed_contact_in_clear_los",
			"attacker_unit_id": "unit_alpha",
			"target_unit_id": "enemy_probe_01",
			"weapon_id": "rifle",
			"range_meters": 24.0,
			"has_clear_los": true,
		},
		"fire_event_count": 1,
		"fire_events": [first_fire_event],
		"first_fire_event": first_fire_event,
		"cover_effectiveness_readout": {"readout_text": "Partial cover | LOS clear | 24m"},
		"contact_decision_text": "CONTACT FIRE | rifle -> enemy_probe_01",
		"mission_control_status_text": "FIRE | LOS clear | 24m",
		"selected_fireteam_status_text": "ALPHA FIRE | partial cover",
		"checks": [
			{"id": "selected_fireteam_has_contact", "passed": true},
			{"id": "engagement_decision_visible", "passed": true},
			{"id": "target_or_block_reason_visible", "passed": true},
			{"id": "fire_event_or_block_visible", "passed": true},
			{"id": "cover_range_los_context_visible", "passed": true},
			{"id": "feedback_text_visible", "passed": true},
			{"id": "read_only", "passed": true},
		],
		"failed_checks": [],
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_effect", true)) \
		and not bool(snapshot.get("creates_contact", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
