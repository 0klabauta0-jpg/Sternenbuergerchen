extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_868_release_first_exchange_los_setup_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_task868_verified_2026_07_08.html"
const META_LAYER_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"
const FIXTURE_SCRIPT_PATH := "res://scripts/tests/release_first_exchange_fixture.gd"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const SCHEMA := "sternenbuergerchen.release_first_exchange_los_setup_polish.v1"
const STYLE_ID := "task_868_release_first_exchange_los_setup_polish_v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_868 Release First Exchange LOS Setup Polish ===")
	_test_docs_and_static_hooks()
	await _test_meta_layer_los_setup_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_868_release_first_exchange_los_setup_polish: FAILED")
		quit(1)
		return
	print("TASK_868_release_first_exchange_los_setup_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var meta_text: String = _read_text(META_LAYER_SCRIPT_PATH)
	var fixture_text: String = _read_text(FIXTURE_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_868 task file exists")
	_assert(task_text.contains("Release First Exchange LOS Setup Polish"), "Task names LOS setup polish")
	_assert(status_text.contains("TASK_868 - Release First Exchange LOS Setup Polish"), "Implementation status tracks TASK_868")
	_assert(roadmap_text.contains("TASK_868 - Release First Exchange LOS Setup Polish (implementiert)"), "Roadmap marks TASK_868 implemented")
	_assert(roadmap_text.contains("TASK_869"), "Roadmap names TASK_869 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-LOS-Setup-Polish"), "Contract documents TASK_868")
	_assert(report_text.contains("TASK_868") and report_text.contains("LOS-Setup"), "Spielstand report tracks TASK_868")
	_assert(meta_text.contains("get_release_first_exchange_los_setup_polish_snapshot"), "MetaLayer exposes TASK_868 snapshot")
	_assert(meta_text.contains(STYLE_ID), "MetaLayer exposes TASK_868 style id")
	_assert(meta_text.contains("pair_candidate_count"), "Placement records bounded pair candidate count")
	_assert(FileAccess.file_exists(FIXTURE_SCRIPT_PATH), "Release fixture isolates deterministic setup")
	_assert(meta_text.contains("release_first_exchange_fixture.gd"), "MetaLayer delegates release setup to explicit fixture")
	_assert(fixture_text.contains("_stabilize_target_enemy"), "Release target enemy is stabilized inside fixture")
	_assert(fixture_text.contains("enemy_ids.append(enemy_id)"), "Fixture force step keeps validated target enemy first")
	_assert(fixture_text.contains("\"synthetic_fixture\": true"), "Fixture marks setup evidence as synthetic")
	_assert(meta_text.contains("\"creates_fire_event\": false"), "TASK_868 snapshot declares no fire-event creation")
	_assert(meta_text.contains("\"creates_damage_event\": false"), "TASK_868 snapshot declares no damage-event creation")
	_assert(meta_text.contains("\"sets_multiplayer_truth\": false"), "TASK_868 snapshot declares no multiplayer truth mutation")


func _test_meta_layer_los_setup_polish() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight apply hook")
	_assert(scene.has_method("get_release_first_exchange_los_setup_polish_snapshot"), "MetaLayer exposes TASK_868 callable")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink") or not scene.has_method("get_release_first_exchange_los_setup_polish_snapshot"):
		scene.queue_free()
		await _wait_frames(1)
		return

	var snapshot: Dictionary = Dictionary(scene.call(
		"get_release_first_exchange_los_setup_polish_snapshot",
		{},
		{},
		{
			"source_snapshot": _build_good_source_snapshot(),
			"setup_evidence": _build_good_setup_evidence(),
		}
	))
	var setup: Dictionary = Dictionary(snapshot.get("setup_evidence", {})).duplicate(true)
	if String(snapshot.get("status", "")) != "pass":
		print("TASK_868_DIAGNOSTIC %s" % JSON.stringify({
			"issues": snapshot.get("issues", []),
			"source_status": snapshot.get("source_status", ""),
			"setup": setup,
			"diagnostics_status": snapshot.get("diagnostics_status", ""),
			"diagnostics_los_state": snapshot.get("diagnostics_los_state", ""),
			"diagnostics_range_state": snapshot.get("diagnostics_range_state", ""),
		}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Meta snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_868", "Meta snapshot task id is TASK_868")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Meta snapshot exposes TASK_868 style")
	_assert(String(snapshot.get("status", "")) == "pass", "TASK_868 gate passes: %s" % JSON.stringify(snapshot.get("issues", [])))
	_assert(bool(snapshot.get("placement_verified_attackable", false)), "Placement is verified attackable")
	_assert(int(snapshot.get("placement_attempt_count", 0)) > 0, "Placement records attempts")
	_assert(int(snapshot.get("pair_candidate_count", 0)) > 0, "Placement records pair candidates")
	_assert(String(snapshot.get("placement_range_state", "")).strip_edges().to_lower() == "in_range", "Placement target is in range")
	_assert(String(snapshot.get("placement_los_state", "")).strip_edges().to_lower() != "blocked", "Placement LOS is not blocked")
	_assert(bool(snapshot.get("placement_combat_attackable", false)), "Placement readout is combat attackable")
	_assert(bool(snapshot.get("first_exchange_visible", false)), "First exchange remains visible")
	_assert(String(snapshot.get("framing_state", "")).strip_edges().to_lower() == "fire_exchange", "Framing is fire exchange")
	_assert(int(snapshot.get("fire_event_count", 0)) > 0 or not String(snapshot.get("first_fire_event_id", "")).strip_edges().is_empty(), "FireEvent evidence remains present")
	_assert(String(snapshot.get("diagnostics_status", "")).strip_edges().to_lower() == "fired", "Diagnostics stay fired")
	_assert(String(snapshot.get("diagnostics_range_state", "")).strip_edges().to_lower() == "in_range", "Diagnostics stay in range")
	_assert(String(snapshot.get("diagnostics_los_state", "")).strip_edges().to_lower() != "blocked", "Diagnostics LOS stays non-blocked")
	_assert(bool(snapshot.get("read_only", false)), "Meta snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Meta snapshot does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Meta snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Meta snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Meta snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Meta snapshot sets no multiplayer truth")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_869"), "Snapshot recommends TASK_869 recapture")

	scene.queue_free()
	await _wait_frames(2)


func _build_good_source_snapshot() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.release_first_exchange_tension_tuning.v1",
		"task_id": "TASK_844",
		"status": "pass",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"framing_state": "fire_exchange",
		"first_exchange_visible": true,
		"fire_event_count": 1,
		"first_fire_event_id": "fire_evt_868",
		"tactical_exchange": {
			"schema": "sternenbuergerchen.release_first_exchange_tension_tuning.v1",
			"task_id": "TASK_844",
			"gate": "pass",
			"first_exchange_visible": true,
			"framing_state": "fire_exchange",
			"fire_event_count": 1,
			"first_fire_event_id": "fire_evt_868",
			"contact_decision_diagnostics": {
				"status": "fired",
				"reason": "fired",
				"los_state": "clear",
				"range_state": "in_range",
				"combat_attackable": true,
				"attacker_unit_id": "alpha_1",
				"target_unit_id": "enemy_1",
			},
		},
	}


func _build_good_setup_evidence() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.release_first_exchange_los_setup_polish.setup.v1",
		"task_id": "TASK_868",
		"style_id": STYLE_ID,
		"fireteam_id": "ft1",
		"friendly_unit_id": "alpha_1",
		"enemy_unit_id": "enemy_1",
		"friendly_position": Vector2(512.0, 288.0),
		"enemy_position": Vector2(554.0, 288.0),
		"placement_verified_attackable": true,
		"placement_attempt_count": 1,
		"placement_offset": Vector2(42.0, 0.0),
		"pair_candidate_count": 1,
		"placement_readout": {
			"range_state": "in_range",
			"los_state": "clear",
			"combat_attackable": true,
			"distance_world": 42.0,
		},
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


func _instantiate_scene(path: String) -> Node:
	var packed_scene := ResourceLoader.load(path) as PackedScene
	if packed_scene == null:
		return null
	var node := packed_scene.instantiate()
	root.add_child(node)
	return node


func _wait_frames(count: int) -> void:
	for _index in range(count):
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
