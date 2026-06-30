extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_INTERACTION_VISUAL_POLISH_FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_visual_polish_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_689_mission_interaction_visual_polish_findings.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/mission_interaction_visual_polish_findings.json"
const TARGET_VIEWPORT: Vector2i = Vector2i(1920, 1080)
const VISUAL_BUDGET_LIMIT: int = 32

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_689 Mission Interaction Visual Polish Findings ===")
	_test_docs()
	_test_blocker_contract()
	await _test_visual_polish_findings()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_689: FAILED")
		quit(1)
		return
	print("TASK_689: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_689 task file exists")
	_assert(task_text.contains("Mission Interaction Visual Polish Findings"), "Task documents visual polish findings")
	_assert(contract_text.contains("Visual Polish Findings"), "Interaction contract documents visual polish findings")
	_assert(status_text.contains("TASK_689 - Mission Interaction Visual Polish Findings"), "Implementation status tracks TASK_689")
	_assert(roadmap_text.contains("TASK_689 - Mission Interaction Visual Polish Findings (implementiert)"), "Roadmap marks TASK_689 implemented")
	_assert(handbook_text.contains("TASK_689 - Mission Interaction Visual Polish Findings"), "Current handbook references TASK_689")
	_assert(handbook_text.contains('data-export-key="mission_interaction_visual_polish_findings.manifest_path"'), "Current handbook exports TASK_689 manifest path")


func _test_blocker_contract() -> void:
	var blocker_snapshot: Dictionary = Dictionary(MISSION_INTERACTION_VISUAL_POLISH_FINDINGS_SCRIPT.call("build_snapshot", {}, {}, {"visual_budget_limit": VISUAL_BUDGET_LIMIT}))
	_assert(_snapshot_is_read_only(blocker_snapshot), "Polish findings blocker snapshot is read-only")
	_assert(int(blocker_snapshot.get("blocking_issue_count", 0)) > 0, "Missing render data produces blockers")
	_assert(String(blocker_snapshot.get("status", "")) == "blocked", "Missing render data blocks technical polish gate")


func _test_visual_polish_findings() -> void:
	_ensure_output_dir()
	root.size = TARGET_VIEWPORT
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var mission_setup: Node = scene.get_node_or_null("MissionSetup")
	_assert(controller != null and combat_driver != null and mission_setup != null, "Mission scene exposes controller, combat driver and setup")
	if controller == null or combat_driver == null or mission_setup == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	_assert(not fireteam_id.is_empty(), "Verifier selects a fireteam")
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	var station_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, station_position)
	combat_driver.call("update_mission_interaction_runtime_progress", {
		"interaction_id": "station_computer",
		"state": "operating",
		"complete": false,
		"progress": 0.5,
		"hold_seconds": 9.0,
		"duration_seconds": 18.0,
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": "occupy_station_computer",
		"required_state": "computer_controlled",
		"interaction_type": "computer",
		"command_type": "take",
	})
	await _wait_frames(4)
	controller.call("_sync_primary_3d_mission_status_visuals")
	await _wait_frames(4)

	var primary_view: Node = controller.call("_get_primary_3d_view")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "Primary 3D view exposes render snapshot")
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
	var evidence_manifest: Dictionary = {
		"schema": "sternenbuergerchen.mission_interaction_fullhd_evidence.v1",
		"visual_budget": int(render_snapshot.get("mission_interaction_visual_state_count", 0)) + int(render_snapshot.get("mission_interaction_object_reaction_visual_count", 0)) + int(render_snapshot.get("route_callout_visual_count", 0)),
		"manual_fullhd_review_required": true,
		"manual_fullhd_review_done": false,
	}
	var findings: Dictionary = Dictionary(MISSION_INTERACTION_VISUAL_POLISH_FINDINGS_SCRIPT.call("build_snapshot", render_snapshot, evidence_manifest, {"visual_budget_limit": VISUAL_BUDGET_LIMIT}))
	_assert(_snapshot_is_read_only(findings), "Polish findings snapshot is read-only")
	_assert(String(findings.get("schema", "")) == "sternenbuergerchen.mission_interaction_visual_polish_findings.v1", "Polish findings schema is stable")
	_assert(int(findings.get("blocking_issue_count", -1)) == 0, "Current mission visual polish has no technical blockers")
	_assert(bool(findings.get("manual_review_open", false)), "Polish findings keep manual sight review open")
	_assert(String(findings.get("status", "")) == "needs_manual_review", "Current polish status waits for manual review")
	_assert(bool(findings.get("within_visual_budget", false)), "Current mission visual polish remains within budget")
	_assert(int(findings.get("visual_state_count", 0)) >= 3, "Polish findings see visual states")
	_assert(int(findings.get("object_reaction_count", 0)) >= 3, "Polish findings see object reactions")
	_assert(String(findings.get("recommended_next_task", "")).contains("Manual Sight"), "Polish findings recommend manual sight notes")

	var manifest: Dictionary = findings.duplicate(true)
	manifest["task_id"] = "TASK_689"
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	manifest["source_task_ids"] = ["TASK_688", "TASK_687", "TASK_686"]
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Polish findings manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_689", "Manifest records TASK_689")
	_assert(int(parsed.get("blocking_issue_count", -1)) == 0, "Manifest records zero blockers")
	_assert(bool(parsed.get("manual_review_open", false)), "Manifest records manual review open")

	scene.queue_free()
	await _wait_frames(2)


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", false)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _select_first_available_fireteam(controller: Node, mission_setup: Node) -> String:
	var available_ids: PackedStringArray = PackedStringArray(controller.call("_get_available_fireteam_ids"))
	var candidate_id: String = ""
	if not available_ids.is_empty():
		candidate_id = String(available_ids[0]).strip_edges().to_lower()
	else:
		var configured_ids: PackedStringArray = PackedStringArray(mission_setup.get("selected_team_fireteam_ids"))
		if not configured_ids.is_empty():
			candidate_id = String(configured_ids[0]).strip_edges().to_lower()
	if candidate_id.is_empty():
		candidate_id = "ft1"
	controller.call("_set_selected_fireteams", PackedStringArray([candidate_id]), false)
	var selected_ids: PackedStringArray = PackedStringArray(controller.call("get_selected_fireteam_ids"))
	return String(selected_ids[0]).strip_edges().to_lower() if not selected_ids.is_empty() else ""


func _move_fireteam_units(scene: Node, fireteam_id: String, center_position: Vector2) -> void:
	var offset_index: int = 0
	for child in scene.get_children():
		if not (child is Node2D):
			continue
		if not child.has_method("get_fireteam_id"):
			continue
		if String(child.call("get_fireteam_id")).strip_edges().to_lower() != fireteam_id:
			continue
		var offset: Vector2 = Vector2(float(offset_index % 2) * 10.0, float(int(offset_index / 2)) * 10.0)
		(child as Node2D).global_position = center_position + offset
		offset_index += 1


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_689 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
