extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_636_frontier_probe_real_f6_recapture.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/frontier_probe_real_f6_recapture.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_real_f6_recapture.json"
const STYLE_ID: String = "task_635_high_contrast_route_callouts"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_636 Frontier Probe Real F6 Re-Capture ===")
	_test_docs_and_reports()
	await _test_real_f6_recapture_package()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_636: FAILED")
		quit(1)
		return
	print("TASK_636: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_636 task file exists")
	_assert(task_text.contains("Frontier Probe Real F6 Re-Capture"), "TASK_636 task names real F6 recapture")
	_assert(status_text.contains("TASK_636 - Frontier Probe Real F6 Re-Capture"), "Implementation status tracks TASK_636")
	_assert(roadmap_text.contains("TASK_636 - Frontier Probe Real F6 Re-Capture (implementiert)"), "Roadmap marks TASK_636 implemented")
	_assert(contract_text.contains("Frontier-Probe-Real-F6-Re-Capture"), "Mission feedback contract documents TASK_636")
	_assert(report_text.contains("TASK_636 Frontier Probe Real F6 Re-Capture"), "Rolling report tracks TASK_636")
	_assert(report_text.contains('latest_completed_task: "TASK_638 - Frontier Probe Debrief Handoff Feel"'), "Rolling report marks TASK_638 latest completed")
	_assert(handbook_text.contains("TASK_636 - Frontier Probe Real F6 Re-Capture"), "Status handbook tracks TASK_636")
	_assert(handbook_text.contains('current_task: "TASK_638 - Frontier Probe Debrief Handoff Feel"'), "Status handbook current task is TASK_638")
	var required_export_keys: Array[String] = [
		"frontier_probe_real_f6_recapture.task_id",
		"frontier_probe_real_f6_recapture.png_path",
		"frontier_probe_real_f6_recapture.manifest_path",
		"frontier_probe_real_f6_recapture.viewport_readback_available",
		"frontier_probe_real_f6_recapture.generated_evidence_board",
		"frontier_probe_real_f6_recapture.post_polish_style_id",
		"frontier_probe_real_f6_recapture.route_line_count",
		"frontier_probe_real_f6_recapture.label_font_size",
		"frontier_probe_real_f6_recapture.label_outline_size",
		"frontier_probe_real_f6_recapture.label_overlap_polish_gate",
		"frontier_probe_real_f6_recapture.lz_cargo_shared_marker",
		"frontier_probe_real_f6_recapture.lz_cargo_label_separated",
		"frontier_probe_real_f6_recapture.manual_review_required",
		"frontier_probe_real_f6_recapture.manual_review_done",
		"frontier_probe_real_f6_recapture.real_window_review_done",
		"frontier_probe_real_f6_recapture.read_only",
		"frontier_probe_real_f6_recapture.recommended_next_task",
		"frontier_probe_real_f6_recapture.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Rolling report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.frontier_probe_real_f6_recapture"'), "Rolling report exports TASK_636 free note")
	_assert(handbook_text.contains('data-export-key="status.task_636_done"'), "Status handbook exports TASK_636 checkbox")


func _test_real_f6_recapture_package() -> void:
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
	var style_report: Dictionary = _build_style_report(primary_3d, entries)
	var image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = image != null and image.get_width() > 0 and image.get_height() > 0
	if not viewport_readback_available:
		image = _build_callout_review_board(visual_snapshot, primary_3d, layout)
	_assert(String(visual_snapshot.get("gate", "")) == "pass", "TASK_631 route visual gate remains pass")
	_assert(int(visual_snapshot.get("route_callout_count", 0)) >= 4, "Review sees all four route callouts")
	_assert(int(primary_3d.get("route_callout_visual_count", 0)) >= 4, "Primary3D exposes all route callouts")
	_assert(String(primary_3d.get("route_callout_label_visual_style_id", "")) == STYLE_ID, "Primary3D keeps TASK_635 high contrast callout style")
	_assert(int(primary_3d.get("route_callout_line_visual_count", 0)) >= 3, "Primary3D keeps route connection lines visible")
	_assert(int(primary_3d.get("route_callout_label_font_size", 0)) >= 18, "Primary3D keeps route label font size readable")
	_assert(int(primary_3d.get("route_callout_label_outline_size", 0)) >= 7, "Primary3D keeps route label outline readable")
	_assert(bool(style_report.get("all_entries_high_contrast", false)), "All route entries carry high contrast style metadata")
	_assert(String(primary_3d.get("route_callout_summary", "")).contains("LZ -> AA -> COM 18s -> CARGO"), "Primary3D route summary stays readable")
	_assert(bool(layout.get("shared_marker_position", false)), "LZ and CARGO keep shared marker position")
	_assert(bool(layout.get("label_positions_separated", false)), "LZ and CARGO label positions are separated")
	_assert(String(_label_overlap_gate(layout)) == "pass", "TASK_636 overlap polish gate remains pass")
	_assert(image.get_width() == 1920 and image.get_height() == 1080, "Real F6 callout review image has FullHD dimensions")
	_assert(_count_visible_samples(image) > 0, "Real F6 callout review image has visible pixels")
	var save_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(save_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "TASK_636 PNG is written")
	var manifest: Dictionary = _build_manifest(visual_snapshot, primary_3d, style_report, layout, image, viewport_readback_available)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_636 manifest is written")
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.frontier_probe_real_f6_recapture.v1", "Manifest uses stable TASK_636 schema")
	_assert(String(manifest.get("source_task_id", "")) == "TASK_635", "Manifest links to TASK_635 source polish")
	_assert(String(manifest.get("post_polish_style_id", "")) == STYLE_ID, "Manifest records post-polish style id")
	_assert(int(manifest.get("route_line_count", 0)) >= 3, "Manifest records visible route line count")
	_assert(int(manifest.get("label_font_size", 0)) >= 18, "Manifest records readable label font size")
	_assert(int(manifest.get("label_outline_size", 0)) >= 7, "Manifest records readable label outline size")
	_assert(String(manifest.get("label_overlap_polish_gate", "")) == "pass", "Manifest records overlap polish pass")
	_assert(bool(manifest.get("manual_review_required", false)), "Manifest requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Manifest does not claim manual review done")
	_assert(not bool(manifest.get("real_window_review_done", true)), "Manifest keeps real window review open")
	_assert(bool(manifest.get("read_only", false)), "Manifest is read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	if DisplayServer.get_name().strip_edges().to_lower() != "headless":
		_assert(viewport_readback_available, "Non-headless run captured a real viewport readback")

	scene.queue_free()
	await _wait_frames(2)


func _capture_viewport_image_or_empty() -> Image:
	if DisplayServer.get_name().strip_edges().to_lower() == "headless":
		return Image.new()
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		return Image.new()
	var image: Image = viewport_texture.get_image()
	if image == null:
		return Image.new()
	return image


func _build_callout_review_board(visual_snapshot: Dictionary, primary_3d: Dictionary, layout: Dictionary) -> Image:
	var image: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.047, 0.052, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 104), Color(0.02, 0.075, 0.09, 1.0))
	_fill_rect(image, Rect2i(0, 984, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_draw_grid(image, Rect2i(360, 128, 1200, 780), Color(0.07, 0.12, 0.13, 1.0))
	_fill_rect(image, Rect2i(72, 148, 260, 666), Color(0.075, 0.11, 0.12, 1.0))
	_draw_rect_outline(image, Rect2i(72, 148, 260, 666), Color(0.20, 0.44, 0.50, 1.0), 3)
	_fill_rect(image, Rect2i(1590, 148, 260, 666), Color(0.075, 0.11, 0.12, 1.0))
	_draw_rect_outline(image, Rect2i(1590, 148, 260, 666), Color(0.20, 0.44, 0.50, 1.0), 3)
	_draw_route_lanes(image, Array(visual_snapshot.get("route_callouts", [])), layout)
	_draw_swatch_panel(image)
	var callout_count: int = int(visual_snapshot.get("route_callout_count", 0))
	var primary_count: int = int(primary_3d.get("route_callout_visual_count", 0))
	_fill_rect(image, Rect2i(96, 204, clampi(48 + callout_count * 30, 48, 210), 28), Color(0.45, 0.85, 0.60, 1.0))
	_fill_rect(image, Rect2i(96, 252, clampi(48 + primary_count * 30, 48, 210), 28), Color(0.56, 0.72, 1.0, 1.0))
	_fill_rect(image, Rect2i(1618, 204, 198, 24), Color(0.86, 0.70, 0.18, 1.0))
	_fill_rect(image, Rect2i(1618, 252, 178, 24), Color(0.24, 0.74, 0.46, 1.0))
	_fill_rect(image, Rect2i(1618, 300, 218, 24), Color(0.92, 0.36, 0.30, 1.0))
	_fill_rect(image, Rect2i(96, 756, 216 if bool(layout.get("label_positions_separated", false)) else 64, 26), Color(0.24, 0.74, 0.46, 1.0))
	return image


func _draw_route_lanes(image: Image, callouts: Array, layout: Dictionary) -> void:
	var marker_points: Array[Vector2i] = [
		Vector2i(560, 690),
		Vector2i(820, 470),
		Vector2i(1110, 380),
		Vector2i(1360, 690),
	]
	for index in range(marker_points.size() - 1):
		_draw_connection_line(image, marker_points[index], marker_points[index + 1], Color(0.82, 0.86, 0.88, 1.0))
	for index in range(marker_points.size()):
		var callout: Dictionary = Dictionary(callouts[index]) if index < callouts.size() else {}
		var color: Color = _tone_color(String(callout.get("tone", "unknown")))
		var marker: Vector2i = marker_points[index]
		_fill_rect(image, Rect2i(marker.x - 18, marker.y - 18, 36, 36), color)
		_draw_rect_outline(image, Rect2i(marker.x - 24, marker.y - 24, 48, 48), color, 3)
	var lz_label := Vector2i(510, 632)
	var cargo_label := Vector2i(1410, 746)
	if not bool(layout.get("label_positions_separated", false)):
		cargo_label = lz_label + Vector2i(18, 18)
	_fill_rect(image, Rect2i(lz_label.x - 46, lz_label.y - 24, 92, 48), Color(0.18, 0.42, 0.28, 1.0))
	_draw_rect_outline(image, Rect2i(lz_label.x - 46, lz_label.y - 24, 92, 48), Color(0.46, 0.85, 0.60, 1.0), 4)
	_fill_rect(image, Rect2i(cargo_label.x - 46, cargo_label.y - 24, 92, 48), Color(0.48, 0.38, 0.12, 1.0))
	_draw_rect_outline(image, Rect2i(cargo_label.x - 46, cargo_label.y - 24, 92, 48), Color(1.0, 0.82, 0.30, 1.0), 4)


func _draw_swatch_panel(image: Image) -> void:
	var y: int = 356
	for color in [
		Color(0.46, 0.85, 0.60, 1.0),
		Color(1.0, 0.55, 0.48, 1.0),
		Color(0.61, 0.74, 1.0, 1.0),
		Color(1.0, 0.82, 0.30, 1.0),
		Color(0.82, 0.86, 0.88, 1.0),
	]:
		_fill_rect(image, Rect2i(96, y, 34, 24), color)
		_fill_rect(image, Rect2i(146, y + 7, 130, 8), Color(color.r, color.g, color.b, 0.75))
		_draw_rect_outline(image, Rect2i(96, y, 180, 24), Color(0.12, 0.20, 0.22, 1.0), 1)
		y += 44


func _build_style_report(primary_3d: Dictionary, entries: Array) -> Dictionary:
	var high_contrast_count: int = 0
	var read_only: bool = true
	var ui_sets_truth: bool = false
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("label_visual_style_id", "")) == STYLE_ID \
				and int(entry.get("label_font_size", 0)) >= 18 \
				and int(entry.get("label_outline_size", 0)) >= 7 \
				and float(entry.get("label_height", 0.0)) >= 2.2:
			high_contrast_count += 1
		read_only = read_only and bool(entry.get("read_only", false))
		ui_sets_truth = ui_sets_truth or bool(entry.get("ui_sets_gameplay_truth", true))
	return {
		"entry_count": entries.size(),
		"high_contrast_count": high_contrast_count,
		"all_entries_high_contrast": entries.size() >= 4 and high_contrast_count == entries.size(),
		"route_line_count": int(primary_3d.get("route_callout_line_visual_count", 0)),
		"label_visual_style_id": String(primary_3d.get("route_callout_label_visual_style_id", "")),
		"label_font_size": int(primary_3d.get("route_callout_label_font_size", 0)),
		"label_outline_size": int(primary_3d.get("route_callout_label_outline_size", 0)),
		"read_only": read_only,
		"ui_sets_gameplay_truth": ui_sets_truth,
	}


func _build_manifest(visual_snapshot: Dictionary, primary_3d: Dictionary, style_report: Dictionary, layout: Dictionary, image: Image, viewport_readback_available: bool) -> Dictionary:
	var manual_checks: Array = [
		{"id": "real_window_launched", "label": "Real F6 window launched", "done": false},
		{"id": "lz_cargo_separated_visible", "label": "LZ/CARGO labels are visibly separated", "done": false},
		{"id": "aa_com_cargo_not_occluded", "label": "AA/COM/CARGO are not occluded at default camera", "done": false},
		{"id": "zoom_readability_ok", "label": "Zoom readability is acceptable", "done": false},
		{"id": "callout_noise_ok", "label": "Callout lines and labels are not too loud", "done": false},
	]
	return {
		"schema": "sternenbuergerchen.frontier_probe_real_f6_recapture.v1",
		"task_id": "TASK_636",
		"source_task_id": "TASK_635",
		"capture_type": "frontier_probe_real_f6_recapture",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"display_server": DisplayServer.get_name(),
		"viewport_readback_available": viewport_readback_available,
		"generated_evidence_board": not viewport_readback_available,
		"viewport": {
			"width": image.get_width(),
			"height": image.get_height(),
		},
		"png_path": ProjectSettings.globalize_path(OUTPUT_PNG_PATH),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"source_gate": String(visual_snapshot.get("gate", "")),
		"route_id": String(visual_snapshot.get("route_id", "")),
		"route_callout_count": int(visual_snapshot.get("route_callout_count", 0)),
		"route_callout_summary": String(visual_snapshot.get("route_callout_summary", "")),
		"mission_control_route_line": String(visual_snapshot.get("mission_control_route_line", "")),
		"primary_3d_route_callout_count": int(primary_3d.get("route_callout_visual_count", 0)),
		"primary_3d_route_callout_entries": Array(primary_3d.get("route_callout_entries", [])),
		"primary_3d_route_callout_summary": String(primary_3d.get("route_callout_summary", "")),
		"post_polish_style_id": String(style_report.get("label_visual_style_id", "")),
		"route_line_count": int(style_report.get("route_line_count", 0)),
		"label_font_size": int(style_report.get("label_font_size", 0)),
		"label_outline_size": int(style_report.get("label_outline_size", 0)),
		"all_entries_high_contrast": bool(style_report.get("all_entries_high_contrast", false)),
		"label_overlap_polish_gate": _label_overlap_gate(layout),
		"lz_cargo_shared_marker": bool(layout.get("shared_marker_position", false)),
		"lz_cargo_label_separated": bool(layout.get("label_positions_separated", false)),
		"layout": layout,
		"manual_checks": manual_checks,
		"manual_review_required": true,
		"manual_review_done": false,
		"real_window_review_done": false,
		"recommended_next_task": "TASK_637 - Frontier Probe Playfeel Next Interaction",
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
	var lz_offset: Vector2 = Vector2(lz_entry.get("label_offset_world", Vector2.ZERO))
	var cargo_offset: Vector2 = Vector2(cargo_entry.get("label_offset_world", Vector2.ZERO))
	return {
		"shared_marker_position": lz_world.distance_squared_to(cargo_world) <= 1.0,
		"label_positions_separated": lz_label_world.distance_squared_to(cargo_label_world) >= 900.0,
		"offsets_separated": lz_offset.distance_squared_to(cargo_offset) >= 900.0,
		"overlap_group_count": mini(int(lz_entry.get("overlap_group_count", 0)), int(cargo_entry.get("overlap_group_count", 0))),
		"lz_overlap_index": int(lz_entry.get("overlap_index", -1)),
		"cargo_overlap_index": int(cargo_entry.get("overlap_index", -1)),
		"lz_world_position": lz_world,
		"cargo_world_position": cargo_world,
		"lz_label_world_position": lz_label_world,
		"cargo_label_world_position": cargo_label_world,
		"lz_label_offset_world": lz_offset,
		"cargo_label_offset_world": cargo_offset,
	}


func _label_overlap_gate(layout: Dictionary) -> String:
	var passed: bool = bool(layout.get("shared_marker_position", false)) \
		and bool(layout.get("label_positions_separated", false)) \
		and bool(layout.get("offsets_separated", false)) \
		and int(layout.get("overlap_group_count", 0)) >= 2
	return "pass" if passed else "fail"


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


func _draw_grid(image: Image, rect: Rect2i, color: Color) -> void:
	_draw_rect_outline(image, rect, color, 2)
	for x in range(rect.position.x + 96, rect.position.x + rect.size.x, 96):
		_fill_rect(image, Rect2i(x, rect.position.y, 1, rect.size.y), color)
	for y in range(rect.position.y + 96, rect.position.y + rect.size.y, 96):
		_fill_rect(image, Rect2i(rect.position.x, y, rect.size.x, 1), color)


func _draw_connection_line(image: Image, from_point: Vector2i, to_point: Vector2i, color: Color) -> void:
	var steps: int = maxi(abs(to_point.x - from_point.x), abs(to_point.y - from_point.y))
	if steps <= 0:
		return
	for step in range(steps + 1):
		var t: float = float(step) / float(steps)
		var point := Vector2i(roundi(lerpf(float(from_point.x), float(to_point.x), t)), roundi(lerpf(float(from_point.y), float(to_point.y), t)))
		_fill_rect(image, Rect2i(point.x - 3, point.y - 3, 7, 7), color)


func _tone_color(tone: String) -> Color:
	match tone.strip_edges().to_lower():
		"safe":
			return Color(0.46, 0.85, 0.60, 1.0)
		"danger":
			return Color(1.0, 0.55, 0.48, 1.0)
		"objective":
			return Color(0.61, 0.74, 1.0, 1.0)
		"cargo":
			return Color(1.0, 0.82, 0.30, 1.0)
		_:
			return Color(0.70, 0.74, 0.76, 1.0)


func _draw_rect_outline(image: Image, rect: Rect2i, color: Color, thickness: int = 2) -> void:
	var safe_thickness: int = maxi(1, thickness)
	_fill_rect(image, Rect2i(rect.position.x, rect.position.y, rect.size.x, safe_thickness), color)
	_fill_rect(image, Rect2i(rect.position.x, rect.position.y + rect.size.y - safe_thickness, rect.size.x, safe_thickness), color)
	_fill_rect(image, Rect2i(rect.position.x, rect.position.y, safe_thickness, rect.size.y), color)
	_fill_rect(image, Rect2i(rect.position.x + rect.size.x - safe_thickness, rect.position.y, safe_thickness, rect.size.y), color)


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var x0: int = clampi(rect.position.x, 0, image.get_width())
	var y0: int = clampi(rect.position.y, 0, image.get_height())
	var x1: int = clampi(rect.position.x + rect.size.x, 0, image.get_width())
	var y1: int = clampi(rect.position.y + rect.size.y, 0, image.get_height())
	for y in range(y0, y1):
		for x in range(x0, x1):
			image.set_pixel(x, y, color)


func _count_visible_samples(image: Image) -> int:
	var count: int = 0
	var step_x: int = maxi(1, image.get_width() / 48)
	var step_y: int = maxi(1, image.get_height() / 27)
	for y in range(0, image.get_height(), step_y):
		for x in range(0, image.get_width(), step_x):
			if image.get_pixel(x, y).a > 0.01:
				count += 1
	return count


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_636 manifest for writing")
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
