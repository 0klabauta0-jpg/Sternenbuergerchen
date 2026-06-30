extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_708_station_route_visual_evidence.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_refresh_2026_06_30.html"
const SOURCE_SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TEST_SCENARIO_PATH: String = "res://tmp/task_708_station_route_visual_evidence_scenario.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/station_route_visual_evidence.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_route_visual_evidence.json"
const TARGET_VIEWPORT: Vector2i = Vector2i(1920, 1080)
const DOOR_INTERACTION_ID: String = "station_door_visual_evidence"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_708 Station Route Visual Evidence ===")
	_test_docs()
	await _test_station_route_visual_evidence()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_708: FAILED")
		quit(1)
		return
	print("TASK_708: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_708 task file exists")
	_assert(task_text.contains("Station Route Visual Evidence"), "Task documents station route visual evidence")
	_assert(contract_text.contains("Station Route Visual Evidence"), "Interaction contract documents TASK_708")
	_assert(status_text.contains("TASK_708 - Station Route Visual Evidence"), "Implementation status tracks TASK_708")
	_assert(roadmap_text.contains("TASK_708 - Station Route Visual Evidence (implementiert)"), "Roadmap marks TASK_708 implemented")
	_assert(report_text.contains("TASK_708 - Station Route Visual Evidence"), "Report references TASK_708")
	_assert(report_text.contains('data-export-key="station_route_visual_evidence.png_path"'), "Report exports TASK_708 PNG path")
	_assert(report_text.contains('data-export-key="station_route_visual_evidence.manifest_path"'), "Report exports TASK_708 manifest path")


func _test_station_route_visual_evidence() -> void:
	_ensure_output_dir()
	_write_test_scenario()
	root.size = TARGET_VIEWPORT
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var mission_setup: Node = scene.get_node_or_null("MissionSetup")
	_assert(controller != null and combat_driver != null and mission_setup != null, "Mission scene exposes controller, driver and setup")
	if controller == null or combat_driver == null or mission_setup == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", TEST_SCENARIO_PATH)), "Combat driver configures TASK_708 scenario")
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	_assert(not fireteam_id.is_empty(), "Verifier selects a fireteam")

	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	var station_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, station_position)
	await _wait_frames(2)
	combat_driver.call("update_mission_interaction_runtime_progress", _progress_payload(DOOR_INTERACTION_ID, "operating", true, 2.0, fireteam_id, "open_station_door", "door_open", "door", "breach"))
	await _wait_frames(4)
	controller.call("_sync_primary_3d_mission_status_visuals")
	await _wait_frames(4)
	var primary_view: Node = controller.call("_get_primary_3d_view")
	var door_render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
	var door_entries: Array = Array(door_render_snapshot.get("mission_interaction_object_reaction_entries", []))
	_assert(_entry_field_equals(door_entries, DOOR_INTERACTION_ID, "runtime_visual_state", "open"), "Door open appears in render snapshot")
	_assert(_entry_field_equals(door_entries, DOOR_INTERACTION_ID, "door_layout_tone", "success"), "Door open success tone appears in render snapshot")

	combat_driver.call("update_mission_interaction_runtime_progress", _progress_payload("station_computer", "operating", true, 18.0, fireteam_id, "occupy_station_computer", "computer_controlled", "computer", "take"))
	await _wait_frames(4)
	controller.call("_sync_primary_3d_mission_status_visuals")
	await _wait_frames(4)
	var computer_snapshot: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(String(computer_snapshot.get("next_step_id", "")) == "cargo_touchdown_extract", "Computer control advances to cargo")

	var cargo_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "spawn_alpha", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, cargo_position)
	await _wait_frames(2)
	combat_driver.call("update_mission_interaction_runtime_progress", _progress_payload("cargo_landing_hold", "holding", true, 12.0, fireteam_id, "cargo_touchdown_extract", "cargo_departed", "hold_zone", "defend"))
	await _wait_frames(4)
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(4)

	var complete_snapshot: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var final_render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
	var final_entries: Array = Array(final_render_snapshot.get("mission_interaction_object_reaction_entries", []))
	_assert(bool(complete_snapshot.get("all_gates_complete", false)), "Station route completes objective gates")
	_assert(String(complete_snapshot.get("next_line", "")) == "OBJECTIVES complete", "Station route complete line is stable")
	_assert(_snapshot_is_read_only(complete_snapshot), "Station route objective snapshot remains read-only")
	_assert(_entry_field_equals(final_entries, DOOR_INTERACTION_ID, "runtime_visual_state", "open"), "Final render snapshot keeps Door open readout")
	_assert(int(final_render_snapshot.get("mission_interaction_object_reaction_visual_count", 0)) > 0, "Final render snapshot has object reaction visuals")

	var viewport_image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = viewport_image != null and viewport_image.get_width() == TARGET_VIEWPORT.x and viewport_image.get_height() == TARGET_VIEWPORT.y
	var evidence_image: Image = viewport_image if viewport_readback_available else _build_review_board(final_render_snapshot, complete_snapshot, command_feedback, final_entries)
	_assert(evidence_image.get_width() == TARGET_VIEWPORT.x and evidence_image.get_height() == TARGET_VIEWPORT.y, "Evidence PNG image has FullHD dimensions")
	_assert(_count_visible_samples(evidence_image) > 0, "Evidence PNG image has visible pixels")
	var png_error: Error = evidence_image.save_png(OUTPUT_PNG_PATH)
	_assert(png_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "Station route evidence PNG is written")

	var manifest: Dictionary = _build_manifest(final_render_snapshot, complete_snapshot, command_feedback, final_entries, evidence_image, viewport_readback_available)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Station route evidence manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("schema", "")) == "sternenbuergerchen.station_route_visual_evidence.v1", "Manifest schema is stable")
	_assert(String(parsed.get("task_id", "")) == "TASK_708", "Manifest records TASK_708")
	_assert(String(parsed.get("door_runtime_visual_state", "")) == "open", "Manifest records Door open")
	_assert(String(parsed.get("door_layout_tone", "")) == "success", "Manifest records Door success tone")
	_assert(String(parsed.get("complete_next_line", "")) == "OBJECTIVES complete", "Manifest records route completion")
	_assert(bool(parsed.get("manual_window_review_required", false)), "Manifest keeps manual window review required")
	_assert(not bool(parsed.get("manual_window_review_done", true)), "Manifest does not claim manual window review done")
	_assert(bool(parsed.get("read_only", false)), "Manifest is read-only evidence")
	_assert(not bool(parsed.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")

	scene.queue_free()
	await _wait_frames(2)


func _progress_payload(interaction_id: String, state: String, complete: bool, seconds: float, fireteam_id: String, step_id: String, required_state: String, interaction_type: String, command_type: String) -> Dictionary:
	return {
		"interaction_id": interaction_id,
		"state": state,
		"complete": complete,
		"hold_seconds": seconds,
		"duration_seconds": seconds,
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": step_id,
		"required_state": required_state,
		"interaction_type": interaction_type,
		"command_type": command_type,
	}


func _build_manifest(render_snapshot: Dictionary, objective_snapshot: Dictionary, command_feedback: Dictionary, entries: Array, image: Image, viewport_readback_available: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_visual_evidence.v1",
		"task_id": "TASK_708",
		"source_task_ids": ["TASK_706", "TASK_707"],
		"viewport": {"width": image.get_width(), "height": image.get_height()},
		"display_server": DisplayServer.get_name(),
		"viewport_readback_available": viewport_readback_available,
		"generated_evidence_board": not viewport_readback_available,
		"png_path": ProjectSettings.globalize_path(OUTPUT_PNG_PATH),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"door_interaction_id": DOOR_INTERACTION_ID,
		"door_runtime_visual_state": _entry_string(entries, DOOR_INTERACTION_ID, "runtime_visual_state"),
		"door_layout_tone": _entry_string(entries, DOOR_INTERACTION_ID, "door_layout_tone"),
		"door_layout_readout": _entry_string(entries, DOOR_INTERACTION_ID, "door_layout_readout"),
		"render_object_reaction_count": int(render_snapshot.get("mission_interaction_object_reaction_count", 0)),
		"render_object_reaction_visual_count": int(render_snapshot.get("mission_interaction_object_reaction_visual_count", 0)),
		"complete_next_line": String(objective_snapshot.get("next_line", "")),
		"all_gates_complete": bool(objective_snapshot.get("all_gates_complete", false)),
		"command_feedback_next_line": String(command_feedback.get("mission_interaction_objective_next_line", "")),
		"manual_checks": [
			{"id": "real_window_launched", "label": "Stationsroute im echten Fenster gestartet", "done": false},
			{"id": "door_open_readable", "label": "Door Open ist ohne Suche lesbar", "done": false},
			{"id": "computer_state_clear", "label": "Computer-/Cargo-Folge ist im HUD klar", "done": false},
			{"id": "hud_not_blocking_route", "label": "HUD verdeckt die Stationsobjekte nicht", "done": false}
		],
		"manual_window_review_required": true,
		"manual_window_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"recommended_next_task": "TASK_709 - Station Route Window Playtest Notes",
	}


func _build_review_board(render_snapshot: Dictionary, objective_snapshot: Dictionary, command_feedback: Dictionary, entries: Array) -> Image:
	var image: Image = Image.create(TARGET_VIEWPORT.x, TARGET_VIEWPORT.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.045, 0.047, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 112), Color(0.018, 0.066, 0.080, 1.0))
	_fill_rect(image, Rect2i(0, 968, 1920, 112), Color(0.018, 0.066, 0.080, 1.0))
	_fill_rect(image, Rect2i(52, 150, 496, 760), Color(0.070, 0.096, 0.104, 1.0))
	_draw_rect_outline(image, Rect2i(52, 150, 496, 760), Color(0.20, 0.42, 0.48, 1.0), 3)
	_fill_rect(image, Rect2i(600, 150, 720, 760), Color(0.055, 0.071, 0.070, 1.0))
	_draw_grid(image, Rect2i(650, 196, 620, 668), Color(0.11, 0.15, 0.15, 1.0))
	_fill_rect(image, Rect2i(1372, 150, 496, 760), Color(0.070, 0.096, 0.104, 1.0))
	_draw_rect_outline(image, Rect2i(1372, 150, 496, 760), Color(0.20, 0.42, 0.48, 1.0), 3)
	var door_tone: String = _entry_string(entries, DOOR_INTERACTION_ID, "door_layout_tone")
	var door_color := Color(0.46, 0.96, 0.62, 1.0) if door_tone == "success" else Color(1.0, 0.38, 0.30, 1.0)
	_fill_rect(image, Rect2i(720, 404, 112, 92), door_color)
	_fill_rect(image, Rect2i(870, 384, 144, 112), Color(0.38, 0.78, 1.0, 1.0))
	_fill_rect(image, Rect2i(1052, 438, 144, 58), Color(1.0, 0.80, 0.34, 1.0))
	var object_visuals: int = int(render_snapshot.get("mission_interaction_object_reaction_visual_count", 0))
	_fill_rect(image, Rect2i(100, 220, clampi(object_visuals * 24, 24, 390), 42), Color(1.0, 0.80, 0.34, 1.0))
	if bool(objective_snapshot.get("all_gates_complete", false)):
		_fill_rect(image, Rect2i(100, 310, 360, 42), Color(0.46, 0.96, 0.62, 1.0))
	if String(command_feedback.get("mission_interaction_objective_next_line", "")).contains("OBJECTIVES"):
		_fill_rect(image, Rect2i(100, 400, 300, 42), Color(0.46, 0.96, 0.62, 1.0))
	_fill_rect(image, Rect2i(1418, 220, 340, 42), door_color)
	_fill_rect(image, Rect2i(1418, 310, 300, 42), Color(0.38, 0.78, 1.0, 1.0))
	_fill_rect(image, Rect2i(1418, 400, 280, 42), Color(1.0, 0.80, 0.34, 1.0))
	return image


func _write_test_scenario() -> void:
	_ensure_output_dir()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_SCENARIO_PATH))
	var scenario: Dictionary = Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}
	var vertical_slice: Dictionary = Dictionary(scenario.get("vertical_slice", {}))
	var interactions: Array = Array(vertical_slice.get("interaction_points", [])).duplicate(true)
	interactions.insert(1, {
		"interaction_id": DOOR_INTERACTION_ID,
		"display_name": "Station Door Visual Evidence",
		"interaction_type": "door",
		"marker_id": "objective_point",
		"required_order": "breach",
		"duration_seconds": 2.0,
		"radius_world": 128.0,
		"required_team": "team_alpha",
		"step_id": "open_station_door",
		"gate_id": "open_station_door",
		"required_state": "door_open",
		"asset_hint": "station_set_door_single_closed"
	})
	vertical_slice["interaction_points"] = interactions
	scenario["vertical_slice"] = vertical_slice
	var file := FileAccess.open(TEST_SCENARIO_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_708 temp scenario for writing")
		return
	file.store_string(JSON.stringify(scenario, "\t"))
	file.close()
	_assert(FileAccess.file_exists(TEST_SCENARIO_PATH), "TASK_708 temp scenario is written")


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", MAP_PATH)
		mission_setup.set("scenario_file_path", TEST_SCENARIO_PATH)
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


func _entry_field_equals(entries: Array, interaction_id: String, field_name: String, expected_value: String) -> bool:
	return _entry_string(entries, interaction_id, field_name) == expected_value


func _entry_string(entries: Array, interaction_id: String, field_name: String) -> String:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("interaction_id", "")).strip_edges() == interaction_id:
			return String(entry.get(field_name, "")).strip_edges()
	return ""


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


func _count_visible_samples(image: Image) -> int:
	var count: int = 0
	var width: int = image.get_width()
	var height: int = image.get_height()
	if width <= 0 or height <= 0:
		return 0
	var step_y: int = maxi(1, floori(float(height) / 24.0))
	var step_x: int = maxi(1, floori(float(width) / 24.0))
	for y in range(0, height, step_y):
		for x in range(0, width, step_x):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a > 0.01 and (pixel.r > 0.05 or pixel.g > 0.05 or pixel.b > 0.05):
				count += 1
	return count


func _draw_grid(image: Image, rect: Rect2i, color: Color) -> void:
	_draw_rect_outline(image, rect, color, 2)
	for x in range(rect.position.x + 64, rect.position.x + rect.size.x, 64):
		_fill_rect(image, Rect2i(x, rect.position.y, 1, rect.size.y), color)
	for y in range(rect.position.y + 64, rect.position.y + rect.size.y, 64):
		_fill_rect(image, Rect2i(rect.position.x, y, rect.size.x, 1), color)


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


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_708 manifest for writing")
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
	for _index in range(maxi(count, 0)):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
