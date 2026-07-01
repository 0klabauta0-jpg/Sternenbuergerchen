extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_747_station_scenario_homebase_visible_readiness_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/station_scenario_homebase_visible_readiness_review.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_scenario_homebase_visible_readiness_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_747 Station Scenario Homebase Visible Readiness Review ===")
	_test_docs_contract_and_report()
	await _test_visible_readiness_review()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_747: FAILED")
		quit(1)
		return
	print("TASK_747: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var homebase_text: String = _read_text(HOMEBASE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_747 task file exists")
	_assert(task_text.contains("Station Scenario Homebase Visible Readiness Review"), "TASK_747 task names visible readiness review")
	_assert(status_text.contains("TASK_747 - Station Scenario Homebase Visible Readiness Review"), "Implementation status tracks TASK_747")
	_assert(roadmap_text.contains("TASK_747 - Station Scenario Homebase Visible Readiness Review"), "Roadmap tracks TASK_747")
	_assert(contract_text.contains("Station-Scenario-Homebase-Visible-Readiness-Review"), "Mission command feedback contract documents TASK_747")
	_assert(homebase_text.contains("get_station_scenario_homebase_visible_readiness_review_snapshot"), "Homebase exposes TASK_747 snapshot")
	_assert(handbook_text.contains("TASK_747 - Station Scenario Homebase Visible Readiness Review"), "Current handbook references TASK_747")
	for key in [
		"station_scenario_homebase_visible_readiness_review.task_id",
		"station_scenario_homebase_visible_readiness_review.png_path",
		"station_scenario_homebase_visible_readiness_review.manifest_path",
		"station_scenario_homebase_visible_readiness_review.readiness_gate",
		"station_scenario_homebase_visible_readiness_review.post_summary_visible",
		"station_scenario_homebase_visible_readiness_review.next_sortie_visible",
		"station_scenario_homebase_visible_readiness_review.current_next_step_id",
		"station_scenario_homebase_visible_readiness_review.manual_review_required",
		"station_scenario_homebase_visible_readiness_review.read_only",
		"station_scenario_homebase_visible_readiness_review.recommended_next_task",
		"station_scenario_homebase_visible_readiness_review.notes",
	]:
		_assert(handbook_text.contains(key), "Current handbook exports %s" % key)
	_assert(handbook_text.contains('data-export-key="status.task_747_done"'), "Current handbook exports TASK_747 checkbox")


func _test_visible_readiness_review() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	root.size = Vector2i(1920, 1080)
	var scene: Node = META_LAYER_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)

	var debrief_screen: Node = scene.get_node_or_null("DebriefScreen")
	var homebase_screen: Node = scene.get_node_or_null("HomebaseScreen")
	_assert(debrief_screen != null and homebase_screen != null, "Meta fixture exposes Debrief and Homebase screens")
	if debrief_screen == null or homebase_screen == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var mission_result: Dictionary = _build_station_result()
	scene.set("_last_mission_result", mission_result.duplicate(true))
	debrief_screen.call("set_mission_result", mission_result.duplicate(true))
	scene.call("_show_debrief")
	await _wait_frames(4)
	scene.call("request_debrief_return_homebase_for_test")
	await _wait_frames(12)

	var snapshot: Dictionary = Dictionary(homebase_screen.call("get_station_scenario_homebase_visible_readiness_review_snapshot")).duplicate(true)
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_scenario_homebase_visible_readiness_review.v1", "TASK_747 snapshot schema is stable")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_747 visual gate passes")
	_assert(String(snapshot.get("readiness_gate", "")) == "pass", "TASK_747 builds on green TASK_746 readiness")
	_assert(String(snapshot.get("route_id", "")) == "station_route_aa_door_computer_cargo", "Station route remains visible")
	_assert(String(snapshot.get("scenario_id", "")) == "station_route_one_screen_multiplayer_drill", "Station scenario remains visible")
	_assert(bool(snapshot.get("post_summary_visible", false)), "Station post-Debrief summary is visible")
	_assert(bool(snapshot.get("next_sortie_visible", false)), "Station next-sortie readiness line is visible")
	_assert(String(snapshot.get("current_next_step_id", "")) == "stage_fireteam", "Visible review preserves the current actionable Station next step")
	_assert(String(snapshot.get("readiness_line", "")).begins_with("Naechste Sortie:"), "Visible review carries Station next-sortie line")
	_assert(String(snapshot.get("readiness_line", "")).contains("Fireteam bereitstellen"), "Visible review carries station action microcopy")
	_assert(String(snapshot.get("rendered_readiness_line", "")) == String(snapshot.get("readiness_line", "")), "Rendered Station readiness line matches snapshot")
	_assert(_check_passed(snapshot, "labels_inside_mission_panel"), "Station readiness labels stay inside MissionPanel")
	_assert(_check_passed(snapshot, "labels_inside_followup_panel"), "Station readiness labels stay inside FollowupPanel")
	_assert(_check_passed(snapshot, "next_sortie_below_post_summary"), "Station Next-Sortie label is below post summary")
	_assert(_check_passed(snapshot, "labels_do_not_overlap"), "Station Homebase readiness labels do not overlap")
	_assert(_check_passed(snapshot, "mission_panel_no_overflow"), "MissionPanel does not overflow")
	_assert(_check_passed(snapshot, "readiness_line_compact"), "Station readiness line stays compact")
	_assert(bool(snapshot.get("manual_review_required", false)), "TASK_747 keeps manual visible review required")
	_assert(not bool(snapshot.get("manual_review_done", true)), "TASK_747 does not claim manual review done")
	_assert(bool(snapshot.get("read_only", false)), "TASK_747 snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_747 snapshot does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "TASK_747 creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "TASK_747 creates no command")

	var image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = image != null and image.get_width() > 0 and image.get_height() > 0
	if not viewport_readback_available:
		image = _build_evidence_board(snapshot)
	_assert(image.get_width() == 1920 and image.get_height() == 1080, "TASK_747 evidence image has FullHD dimensions")
	_assert(_count_non_background_samples(image, Color(0.032, 0.044, 0.050, 1.0)) > 20, "TASK_747 evidence image has visible marks")
	var save_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(save_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "TASK_747 evidence PNG is written")
	var manifest: Dictionary = _build_manifest(snapshot, image, viewport_readback_available)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_747 manifest is written")
	_assert(String(manifest.get("gate", "")) == "pass", "TASK_747 manifest gate passes")
	_assert(bool(manifest.get("manual_review_required", false)), "TASK_747 manifest keeps manual review required")
	_assert(not bool(manifest.get("manual_review_done", true)), "TASK_747 manifest does not claim manual review done")

	scene.queue_free()
	await _wait_frames(2)


func _build_station_result() -> Dictionary:
	return {
		"scenario_id": "station_route_one_screen_multiplayer_drill",
		"mission_id": "station_route_one_screen_multiplayer_drill",
		"scenario_file_path": "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
		"route_id": "station_route_aa_door_computer_cargo",
		"winning_team_id": "team_alpha",
		"mission_outcome": "completed",
		"result": "victory",
		"win_condition_type": "station_route_cargo_extract",
		"objective_captured": true,
		"duration_seconds": 386.0,
		"selected_unit_ids": PackedStringArray(["anna_kade", "pavel_moro", "kenzo_rhee", "leon_voss"]),
		"selected_fireteam_ids": PackedStringArray(["ft_alpha"]),
		"team_states": [
			{"unit_id": "anna_kade", "display_name": "Anna Kade", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 100},
			{"unit_id": "pavel_moro", "display_name": "Pavel Moro", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 91},
			{"unit_id": "kenzo_rhee", "display_name": "Kenzo Rhee", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 87},
			{"unit_id": "leon_voss", "display_name": "Leon Voss", "fireteam_id": "ft_alpha", "vital_state": "wounded", "health_points": 68},
		],
		"mini_aar_payload": {
			"shots_fired": 42,
			"enemies_spotted": 3,
			"commands_ignored": 0,
			"friendly_fire_risk_events": 0,
			"wounded_count": 1,
			"extracted_count": 4,
		},
	}


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


func _build_evidence_board(snapshot: Dictionary) -> Image:
	var image: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.032, 0.044, 0.050, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 92), Color(0.018, 0.072, 0.088, 1.0))
	_fill_rect(image, Rect2i(0, 990, 1920, 90), Color(0.018, 0.072, 0.088, 1.0))
	var mission_rect: Rect2i = _rect_from_snapshot(snapshot, "mission_panel_rect")
	var followup_rect: Rect2i = _rect_from_snapshot(snapshot, "followup_panel_rect")
	var post_rect: Rect2i = _rect_from_snapshot(snapshot, "post_summary_rect")
	var next_rect: Rect2i = _rect_from_snapshot(snapshot, "next_sortie_rect")
	_fill_rect(image, mission_rect, Color(0.11, 0.15, 0.18, 1.0))
	_draw_rect_outline(image, mission_rect, Color(0.35, 0.56, 0.66, 1.0), 4)
	_fill_rect(image, followup_rect.grow(5), Color(0.07, 0.18, 0.20, 1.0))
	_draw_rect_outline(image, followup_rect.grow(5), Color(0.32, 0.72, 0.72, 1.0), 4)
	_fill_rect(image, post_rect.grow(4), Color(0.24, 0.56, 0.42, 1.0))
	_draw_rect_outline(image, post_rect.grow(4), Color(0.62, 0.95, 0.78, 1.0), 3)
	_fill_rect(image, next_rect.grow(4), Color(0.28, 0.43, 0.70, 1.0))
	_draw_rect_outline(image, next_rect.grow(4), Color(0.66, 0.80, 1.0, 1.0), 3)
	_fill_rect(image, Rect2i(70, 130, 460, 38), Color(0.32, 0.72, 0.72, 1.0))
	_fill_rect(image, Rect2i(70, 190, 460, 38), Color(0.62, 0.95, 0.78, 1.0))
	_fill_rect(image, Rect2i(70, 250, 460, 38), Color(0.66, 0.80, 1.0, 1.0))
	_fill_rect(image, Rect2i(70, 310, 460, 38), Color(0.86, 0.70, 0.18, 1.0))
	_fill_rect(image, Rect2i(70, 910, 900, 34), Color(0.58, 0.88, 0.66, 1.0))
	return image


func _build_manifest(snapshot: Dictionary, image: Image, viewport_readback_available: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_scenario_homebase_visible_readiness_review_manifest.v1",
		"task_id": "TASK_747",
		"snapshot_schema": String(snapshot.get("schema", "")),
		"gate": String(snapshot.get("gate", "")),
		"capture_type": "station_scenario_homebase_visible_readiness_review",
		"viewport_readback_available": viewport_readback_available,
		"generated_evidence_board": not viewport_readback_available,
		"png_path": ProjectSettings.globalize_path(OUTPUT_PNG_PATH),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"viewport": {"width": image.get_width(), "height": image.get_height()},
		"readiness_gate": String(snapshot.get("readiness_gate", "")),
		"route_id": String(snapshot.get("route_id", "")),
		"scenario_id": String(snapshot.get("scenario_id", "")),
		"current_next_step_id": String(snapshot.get("current_next_step_id", "")),
		"readiness_line": String(snapshot.get("readiness_line", "")),
		"rendered_readiness_line": String(snapshot.get("rendered_readiness_line", "")),
		"post_summary_visible": bool(snapshot.get("post_summary_visible", false)),
		"next_sortie_visible": bool(snapshot.get("next_sortie_visible", false)),
		"followup_panel_visible": bool(snapshot.get("followup_panel_visible", false)),
		"post_summary_rect": Dictionary(snapshot.get("post_summary_rect", {})).duplicate(true),
		"next_sortie_rect": Dictionary(snapshot.get("next_sortie_rect", {})).duplicate(true),
		"followup_panel_rect": Dictionary(snapshot.get("followup_panel_rect", {})).duplicate(true),
		"mission_panel_rect": Dictionary(snapshot.get("mission_panel_rect", {})).duplicate(true),
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"recommended_next_task": "TASK_748 - Station Scenario Homebase Readiness Visual Polish Findings",
	}


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _rect_from_snapshot(snapshot: Dictionary, key: String) -> Rect2i:
	var rect: Dictionary = Dictionary(snapshot.get(key, {}))
	return Rect2i(
		int(round(float(rect.get("x", 0.0)))),
		int(round(float(rect.get("y", 0.0)))),
		maxi(1, int(round(float(rect.get("width", 1.0))))),
		maxi(1, int(round(float(rect.get("height", 1.0)))))
	)


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


func _count_non_background_samples(image: Image, background: Color) -> int:
	var count: int = 0
	var step_x: int = maxi(1, image.get_width() / 96)
	var step_y: int = maxi(1, image.get_height() / 54)
	for y in range(0, image.get_height(), step_y):
		for x in range(0, image.get_width(), step_x):
			if _color_delta(image.get_pixel(x, y), background) > 0.05:
				count += 1
	return count


func _color_delta(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a)


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_747 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame
