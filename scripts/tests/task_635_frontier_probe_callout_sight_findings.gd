extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_635_frontier_probe_callout_sight_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const TERRAIN_VIEW_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_callout_sight_findings.json"
const STYLE_ID: String = "task_635_high_contrast_route_callouts"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_635 Frontier Probe Callout Sight Findings ===")
	_test_docs_and_reports()
	await _test_callout_sight_findings_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_635: FAILED")
		quit(1)
		return
	print("TASK_635: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var terrain_text: String = _read_text(TERRAIN_VIEW_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_635 task file exists")
	_assert(task_text.contains("Frontier Probe Callout Sight Findings"), "TASK_635 task names callout sight findings")
	_assert(status_text.contains("TASK_635 - Frontier Probe Callout Sight Findings"), "Implementation status tracks TASK_635")
	_assert(roadmap_text.contains("TASK_635 - Frontier Probe Callout Sight Findings (implementiert)"), "Roadmap marks TASK_635 implemented")
	_assert(contract_text.contains("Frontier-Probe-Callout-Sight-Findings"), "Mission feedback contract documents TASK_635")
	_assert(terrain_text.contains("ROUTE_CALLOUT_LABEL_VISUAL_STYLE_ID"), "Terrain view exposes route callout style id")
	_assert(terrain_text.contains("MISSION_RESULT_ROUTE_CALLOUT_OFFSET_WORLD"), "Terrain view offsets mission result with callouts")
	_assert(report_text.contains("TASK_635 Frontier Probe Callout Sight Findings"), "Rolling report tracks TASK_635")
	_assert(report_text.contains('latest_completed_task: "TASK_637 - Frontier Probe Playfeel Next Interaction"'), "Rolling report advances latest completed beyond TASK_635")
	_assert(handbook_text.contains("TASK_635 - Frontier Probe Callout Sight Findings"), "Status handbook tracks TASK_635")
	_assert(handbook_text.contains('current_task: "TASK_637 - Frontier Probe Playfeel Next Interaction"'), "Status handbook current task is TASK_637")
	var required_export_keys: Array[String] = [
		"frontier_probe_callout_sight_findings.task_id",
		"frontier_probe_callout_sight_findings.manifest_path",
		"frontier_probe_callout_sight_findings.finding",
		"frontier_probe_callout_sight_findings.label_visual_style_id",
		"frontier_probe_callout_sight_findings.route_line_count",
		"frontier_probe_callout_sight_findings.label_font_size",
		"frontier_probe_callout_sight_findings.label_outline_size",
		"frontier_probe_callout_sight_findings.mission_result_offset_applied",
		"frontier_probe_callout_sight_findings.read_only",
		"frontier_probe_callout_sight_findings.recommended_next_task",
		"frontier_probe_callout_sight_findings.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Rolling report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.frontier_probe_callout_sight_findings"'), "Rolling report exports TASK_635 free note")
	_assert(handbook_text.contains('data-export-key="status.task_635_done"'), "Status handbook exports TASK_635 checkbox")


func _test_callout_sight_findings_polish() -> void:
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

	_prepare_completed_route(scene, controller, combat_driver, simulation_root)
	await _wait_frames(12)
	var visual_snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_mini_scenario_visual_feel_polish_snapshot"))
	var primary_3d: Dictionary = Dictionary(visual_snapshot.get("primary_3d", {}))
	var entries: Array = Array(primary_3d.get("route_callout_entries", []))
	var layout: Dictionary = _extract_lz_cargo_layout(entries)
	var style_report: Dictionary = _build_style_report(primary_3d, entries, layout)
	_assert(String(visual_snapshot.get("gate", "")) == "pass", "TASK_631 visual gate remains pass")
	_assert(int(primary_3d.get("route_callout_visual_count", 0)) >= 4, "Primary3D still renders all callouts")
	_assert(int(primary_3d.get("route_callout_line_visual_count", 0)) >= 3, "Primary3D renders route connection lines")
	_assert(String(primary_3d.get("route_callout_label_visual_style_id", "")) == STYLE_ID, "Primary3D exports TASK_635 route callout style id")
	_assert(int(primary_3d.get("route_callout_label_font_size", 0)) >= 18, "Primary3D exports larger route label font")
	_assert(int(primary_3d.get("route_callout_label_outline_size", 0)) >= 7, "Primary3D exports stronger route label outline")
	_assert(bool(style_report.get("all_entries_high_contrast", false)), "All route entries use high contrast style")
	_assert(bool(style_report.get("all_entries_lifted", false)), "All route entries are lifted above old status labels")
	_assert(bool(layout.get("shared_marker_position", false)), "LZ and CARGO keep shared marker position")
	_assert(bool(layout.get("label_positions_separated", false)), "LZ and CARGO labels stay separated")
	_assert(bool(style_report.get("read_only", false)), "TASK_635 polish evidence remains read-only")
	_assert(not bool(style_report.get("ui_sets_gameplay_truth", true)), "TASK_635 polish does not set gameplay truth")
	var manifest: Dictionary = _build_manifest(visual_snapshot, primary_3d, style_report, layout)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_635 manifest is written")
	_assert(String(manifest.get("label_visual_style_id", "")) == STYLE_ID, "Manifest records high contrast style id")
	_assert(int(manifest.get("route_line_count", 0)) >= 3, "Manifest records route line count")

	scene.queue_free()
	await _wait_frames(2)


func _build_style_report(primary_3d: Dictionary, entries: Array, layout: Dictionary) -> Dictionary:
	var high_contrast_count: int = 0
	var lifted_count: int = 0
	var read_only: bool = true
	var ui_sets_truth: bool = false
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("label_visual_style_id", "")) == STYLE_ID \
				and int(entry.get("label_font_size", 0)) >= 18 \
				and int(entry.get("label_outline_size", 0)) >= 7:
			high_contrast_count += 1
		if float(entry.get("label_height", 0.0)) >= 2.2:
			lifted_count += 1
		read_only = read_only and bool(entry.get("read_only", false))
		ui_sets_truth = ui_sets_truth or bool(entry.get("ui_sets_gameplay_truth", true))
	return {
		"entry_count": entries.size(),
		"high_contrast_count": high_contrast_count,
		"lifted_count": lifted_count,
		"all_entries_high_contrast": entries.size() >= 4 and high_contrast_count == entries.size(),
		"all_entries_lifted": entries.size() >= 4 and lifted_count == entries.size(),
		"route_line_count": int(primary_3d.get("route_callout_line_visual_count", 0)),
		"label_visual_style_id": String(primary_3d.get("route_callout_label_visual_style_id", "")),
		"label_font_size": int(primary_3d.get("route_callout_label_font_size", 0)),
		"label_outline_size": int(primary_3d.get("route_callout_label_outline_size", 0)),
		"lz_cargo_shared_marker": bool(layout.get("shared_marker_position", false)),
		"lz_cargo_label_separated": bool(layout.get("label_positions_separated", false)),
		"mission_result_offset_applied": true,
		"read_only": read_only,
		"ui_sets_gameplay_truth": ui_sets_truth,
	}


func _extract_lz_cargo_layout(entries: Array) -> Dictionary:
	var lz_entry: Dictionary = {}
	var cargo_entry: Dictionary = {}
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var short_label: String = String(entry.get("short_label", "")).strip_edges()
		if short_label == "LZ":
			lz_entry = entry
		elif short_label == "CARGO":
			cargo_entry = entry
	if lz_entry.is_empty() or cargo_entry.is_empty():
		return {}
	var lz_world: Vector2 = Vector2(lz_entry.get("world_position", Vector2.ZERO))
	var cargo_world: Vector2 = Vector2(cargo_entry.get("world_position", Vector2.ZERO))
	var lz_label_world: Vector2 = Vector2(lz_entry.get("label_world_position", lz_world))
	var cargo_label_world: Vector2 = Vector2(cargo_entry.get("label_world_position", cargo_world))
	return {
		"shared_marker_position": lz_world.distance_squared_to(cargo_world) <= 1.0,
		"label_positions_separated": lz_label_world.distance_squared_to(cargo_label_world) >= 900.0,
		"lz_world_position": lz_world,
		"cargo_world_position": cargo_world,
		"lz_label_world_position": lz_label_world,
		"cargo_label_world_position": cargo_label_world,
	}


func _build_manifest(visual_snapshot: Dictionary, primary_3d: Dictionary, style_report: Dictionary, layout: Dictionary) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.frontier_probe_callout_sight_findings.v1",
		"task_id": "TASK_635",
		"source_task_id": "TASK_634",
		"finding": "real_f6_callouts_too_quiet_result_label_competes",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"source_gate": String(visual_snapshot.get("gate", "")),
		"route_callout_count": int(primary_3d.get("route_callout_visual_count", 0)),
		"route_line_count": int(style_report.get("route_line_count", 0)),
		"label_visual_style_id": String(style_report.get("label_visual_style_id", "")),
		"label_font_size": int(style_report.get("label_font_size", 0)),
		"label_outline_size": int(style_report.get("label_outline_size", 0)),
		"mission_result_offset_applied": bool(style_report.get("mission_result_offset_applied", false)),
		"all_entries_high_contrast": bool(style_report.get("all_entries_high_contrast", false)),
		"all_entries_lifted": bool(style_report.get("all_entries_lifted", false)),
		"layout": layout,
		"primary_3d_route_callout_entries": Array(primary_3d.get("route_callout_entries", [])),
		"recommended_next_task": "TASK_636 - Frontier Probe Real F6 Re-Capture",
	}


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_635 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _prepare_completed_route(scene: Node, controller: Node, combat_driver: Node, simulation_root: Node) -> void:
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
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	combat_driver.call("set_mission_scenario_runtime_step_state", "occupy_station_computer", "computer_controlled")
	combat_driver.call("set_mission_cargo_touchdown_state", "departed")
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
