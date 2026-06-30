extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_657_frontier_probe_f6_visual_polish_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CURRENT_REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_f6_visual_polish_findings.json"
const EXPECTED_ONE_SCREEN_LINE: String = "PLAN LZ -> AA -> COM 18s -> CARGO | NEXT AA"
const REDUNDANT_NEXT_LINE: String = "NEXT AA ausschalten | Cargo blockiert"
const STYLE_ID: String = "task_657_mission_control_one_screen_anchor"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_657 Frontier Probe F6 Visual Polish Findings ===")
	_test_docs_and_report()
	await _test_visual_polish_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_657: FAILED")
		quit(1)
		return
	print("TASK_657: ALL PASSED")
	quit(0)


func _test_docs_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(CURRENT_REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_657 task file exists")
	_assert(task_text.contains("Frontier Probe F6 Visual Polish Findings"), "TASK_657 task names visual polish findings")
	_assert(status_text.contains("TASK_657 - Frontier Probe F6 Visual Polish Findings"), "Implementation status tracks TASK_657")
	_assert(roadmap_text.contains("TASK_657 - Frontier Probe F6 Visual Polish Findings (implementiert)"), "Roadmap marks TASK_657 implemented")
	_assert(contract_text.contains("Frontier-Probe-F6-Visual-Polish-Findings"), "Mission feedback contract documents TASK_657")
	_assert(report_text.contains("TASK_657 - Frontier Probe F6 Visual Polish Findings"), "Current handbook report tracks TASK_657")
	_assert(report_text.contains('latest_completed_task: "TASK_657 - Frontier Probe F6 Visual Polish Findings"'), "Current handbook export records TASK_657 latest")
	_assert(report_text.contains('recommended_next_task: "TASK_658 - Frontier Probe One-Screen Player Decision Drill"'), "Current handbook recommends TASK_658")
	_assert(report_text.contains('data-export-key="status.task_657_done"'), "Current handbook exports TASK_657 done status")
	_assert(report_text.contains('data-export-key="f6_visual_polish.style_id"'), "Current handbook exports TASK_657 style id")
	_assert(report_text.contains('data-note-key="notes.f6_visual_polish_findings"'), "Current handbook exports TASK_657 notes")
	_assert(controller_text.contains("get_frontier_probe_f6_visual_polish_findings_snapshot"), "Controller exposes TASK_657 snapshot")


func _test_visual_polish_snapshot() -> void:
	_ensure_output_dir()
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_driver != null and simulation_root != null, "Mission scene exposes controller, combat driver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	_prepare_frontier_probe_scene(scene, controller, combat_driver, simulation_root)
	var snapshot: Dictionary = await _capture_polish_snapshot(controller)
	var label_snapshot: Dictionary = Dictionary(snapshot.get("mission_control_label", {}))
	var route_badges: Array = Array(snapshot.get("route_token_badges", []))
	var next_badge: Dictionary = Dictionary(snapshot.get("next_badge", {}))
	var visual_tuning: Dictionary = Dictionary(snapshot.get("visual_tuning", {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.frontier_probe_f6_visual_polish_findings.v1", "TASK_657 snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_657", "Snapshot records TASK_657")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Snapshot records stable style id")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_657 visual polish gate passes")
	_assert(String(snapshot.get("one_screen_line", "")) == EXPECTED_ONE_SCREEN_LINE, "Snapshot keeps compatible one-screen line")
	_assert(bool(visual_tuning.get("one_screen_line_visible", false)), "Visual tuning still sees one-screen line")
	_assert(bool(visual_tuning.get("duplicate_next_line_suppressed", false)), "Visual tuning still suppresses duplicate NEXT")
	_assert(String(visual_tuning.get("mission_control_status_text", "")).contains(EXPECTED_ONE_SCREEN_LINE), "Mission Control contains one-screen line")
	_assert(not String(visual_tuning.get("mission_control_status_text", "")).contains(REDUNDANT_NEXT_LINE), "Mission Control omits redundant NEXT detail")
	_assert(route_badges.size() >= 4, "Route token badges exported")
	_assert(_has_badge(route_badges, "LZ") and _has_badge(route_badges, "AA") and _has_badge(route_badges, "COM 18s") and _has_badge(route_badges, "CARGO"), "Route badges name LZ, AA, COM and CARGO")
	_assert(String(next_badge.get("label", "")) == "NEXT AA", "Next badge exposes current next token")
	_assert(String(next_badge.get("tone", "")) == "accent_next", "Next badge carries accent tone")
	_assert(int(snapshot.get("line_char_margin", 0)) >= 24, "One-screen line keeps breathing room")
	_assert(bool(label_snapshot.get("polish_meta_present", false)), "Mission Control label carries TASK_657 polish meta")
	_assert(String(label_snapshot.get("polish_task", "")) == "TASK_657", "Mission Control label records TASK_657")
	_assert(String(label_snapshot.get("polish_style_id", "")) == STYLE_ID, "Mission Control label records style id")
	_assert(bool(label_snapshot.get("autowrap_enabled", false)), "Mission Control label keeps autowrap enabled")
	_assert(bool(label_snapshot.get("clip_text", false)), "Mission Control label keeps clip guard")
	_assert(int(label_snapshot.get("outline_size", 0)) >= 1, "Mission Control label keeps outline guard")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot does not set gameplay truth")
	var manifest: Dictionary = _build_manifest(snapshot)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_657 manifest is written")
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.frontier_probe_f6_visual_polish_findings_manifest.v1", "Manifest uses TASK_657 schema")
	_assert(bool(manifest.get("mission_control_label_polished", false)), "Manifest records polished label")
	_assert(bool(manifest.get("duplicate_next_line_suppressed", false)), "Manifest records duplicate NEXT suppression")
	_assert(String(manifest.get("recommended_next_task", "")) == "TASK_658 - Frontier Probe One-Screen Player Decision Drill", "Manifest recommends TASK_658")

	scene.queue_free()
	await _wait_frames(2)


func _capture_polish_snapshot(controller: Node) -> Dictionary:
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(4)
	return Dictionary(controller.call("get_frontier_probe_f6_visual_polish_findings_snapshot")).duplicate(true)


func _build_manifest(snapshot: Dictionary) -> Dictionary:
	var label_snapshot: Dictionary = Dictionary(snapshot.get("mission_control_label", {}))
	var visual_tuning: Dictionary = Dictionary(snapshot.get("visual_tuning", {}))
	return {
		"schema": "sternenbuergerchen.frontier_probe_f6_visual_polish_findings_manifest.v1",
		"task_id": "TASK_657",
		"source_task_ids": PackedStringArray(["TASK_655", "TASK_656"]),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"style_id": String(snapshot.get("style_id", "")),
		"one_screen_line": String(snapshot.get("one_screen_line", "")),
		"route_token_badges": Array(snapshot.get("route_token_badges", [])),
		"next_badge": Dictionary(snapshot.get("next_badge", {})),
		"line_char_margin": int(snapshot.get("line_char_margin", 0)),
		"mission_control_label_polished": bool(label_snapshot.get("polish_meta_present", false)),
		"duplicate_next_line_suppressed": bool(visual_tuning.get("duplicate_next_line_suppressed", false)),
		"checks": Array(snapshot.get("checks", [])),
		"gate": String(snapshot.get("gate", "")),
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"recommended_next_task": "TASK_658 - Frontier Probe One-Screen Player Decision Drill",
	}


func _prepare_frontier_probe_scene(scene: Node, controller: Node, combat_driver: Node, simulation_root: Node) -> void:
	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assign_fireteam_ids(friendly_units.slice(0, mini(2, friendly_units.size())), "blue")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var objective_status = simulation_root.call("get_objective_status") if simulation_root.has_method("get_objective_status") else null
	if objective_status != null:
		objective_status.owning_team_id = "team_alpha"
		objective_status.capturing_team_id = "team_alpha"
		objective_status.capture_progress = 1.0
		controller.call("select_tile_from_world_position_for_test", objective_status.position)
	combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
	combat_driver.call("set_mission_cargo_touchdown_state", "blocked")
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", LARGE_MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", true)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _assign_fireteam_ids(units: Array, fireteam_id: String) -> void:
	for unit_variant in units:
		var unit := unit_variant as Node
		if unit != null and unit.has_method("set_fireteam_id"):
			unit.call("set_fireteam_id", fireteam_id)


func _collect_team_units(root_node: Node, team_id: String) -> Array:
	var result: Array = []
	for node in _collect_nodes(root_node):
		if not node.has_method("get_team_id") or not node.has_method("get_unit_id"):
			continue
		if String(node.call("get_team_id")).strip_edges() == team_id:
			result.append(node)
	return result


func _collect_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _has_badge(badges: Array, label: String) -> bool:
	for badge_variant in badges:
		var badge: Dictionary = Dictionary(badge_variant)
		if String(badge.get("label", "")).strip_edges() == label:
			return true
	return false


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_657 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


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
