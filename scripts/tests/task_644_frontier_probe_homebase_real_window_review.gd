extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_644_frontier_probe_homebase_real_window_review.md"
const TASK_642_PATH: String = "res://docs/tasks/TASK_642_frontier_probe_homebase_visible_readiness_review.md"
const TASK_643_PATH: String = "res://docs/tasks/TASK_643_frontier_probe_homebase_readiness_visual_polish_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const STATE_HANDBOOK_PATH: String = "res://docs/reports/project_state_handbook_2026_06_30.html"
const TASK_642_PNG_PATH: String = "res://tmp/frontier_probe_homebase_visible_readiness_review.png"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/frontier_probe_homebase_real_window_review.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_homebase_real_window_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_644 Frontier Probe Homebase Real Window Review ===")
	_test_docs_and_reports()
	await _test_real_window_review_packet()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_644: FAILED")
		quit(1)
		return
	print("TASK_644: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var task_642_text: String = _read_text(TASK_642_PATH)
	var task_643_text: String = _read_text(TASK_643_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var state_handbook_text: String = _read_text(STATE_HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_644 task file exists")
	_assert(task_text.contains("Frontier Probe Homebase Real Window Review"), "TASK_644 task names real window review")
	_assert(task_642_text.contains("Frontier Probe Homebase Visible Readiness Review"), "TASK_642 source task remains available")
	_assert(task_643_text.contains("Frontier Probe Homebase Readiness Visual Polish Findings"), "TASK_643 source task remains available")
	_assert(status_text.contains("TASK_644 - Frontier Probe Homebase Real Window Review"), "Implementation status tracks TASK_644")
	_assert(roadmap_text.contains("TASK_644 - Frontier Probe Homebase Real Window Review (implementiert)"), "Roadmap marks TASK_644 implemented")
	_assert(contract_text.contains("Frontier-Probe-Homebase-Real-Window-Review"), "Mission feedback contract documents TASK_644")
	_assert(report_text.contains("TASK_644 Frontier Probe Homebase Real Window Review"), "Rolling report tracks TASK_644")
	_assert(report_text.contains('latest_completed_task: "TASK_644 - Frontier Probe Homebase Real Window Review"'), "Rolling report marks TASK_644 latest completed")
	_assert(handbook_text.contains("TASK_644 - Frontier Probe Homebase Real Window Review"), "Status handbook tracks TASK_644")
	_assert(handbook_text.contains('current_task: "TASK_644 - Frontier Probe Homebase Real Window Review"'), "Status handbook current task is TASK_644")
	_assert(state_handbook_text.contains("TASK_644 - Frontier Probe Homebase Real Window Review"), "State handbook tracks TASK_644")
	for key in [
		"frontier_probe_homebase_real_window_review.task_id",
		"frontier_probe_homebase_real_window_review.png_path",
		"frontier_probe_homebase_real_window_review.manifest_path",
		"frontier_probe_homebase_real_window_review.real_window_review_gate",
		"frontier_probe_homebase_real_window_review.visible_window_readback_available",
		"frontier_probe_homebase_real_window_review.generated_evidence_board",
		"frontier_probe_homebase_real_window_review.post_summary_visible",
		"frontier_probe_homebase_real_window_review.next_sortie_visible",
		"frontier_probe_homebase_real_window_review.manual_review_required",
		"frontier_probe_homebase_real_window_review.read_only",
		"frontier_probe_homebase_real_window_review.recommended_next_task",
		"frontier_probe_homebase_real_window_review.notes",
	]:
		_assert(report_text.contains(key), "Rolling report exports %s" % key)
	_assert(report_text.contains('data-note-key="notes.frontier_probe_homebase_real_window_review"'), "Rolling report exports TASK_644 free note")
	_assert(handbook_text.contains('data-export-key="status.task_644_done"'), "Status handbook exports TASK_644 checkbox")


func _test_real_window_review_packet() -> void:
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

	var mission_result: Dictionary = _build_frontier_probe_result()
	scene.set("_last_mission_result", mission_result.duplicate(true))
	debrief_screen.call("set_mission_result", mission_result.duplicate(true))
	scene.call("_show_debrief")
	await _wait_frames(4)
	scene.call("request_debrief_return_homebase_for_test")
	await _wait_frames(18)

	var snapshot: Dictionary = Dictionary(homebase_screen.call("get_frontier_probe_homebase_visible_readiness_review_snapshot")).duplicate(true)
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.frontier_probe_homebase_visible_readiness_review.v1", "TASK_644 source snapshot schema is stable")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_644 source visual gate passes")
	_assert(bool(snapshot.get("post_summary_visible", false)), "Post-Debrief summary is visible in source snapshot")
	_assert(bool(snapshot.get("next_sortie_visible", false)), "Next-sortie readiness is visible in source snapshot")
	_assert(_check_passed(snapshot, "labels_do_not_overlap"), "Homebase readiness labels do not overlap")
	_assert(_check_passed(snapshot, "mission_panel_no_overflow"), "MissionPanel does not overflow")
	_assert(bool(snapshot.get("read_only", false)), "Source snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Source snapshot does not set gameplay truth")

	var image: Image = _capture_viewport_image_or_empty()
	var visible_window_readback_available: bool = image != null and image.get_width() == 1920 and image.get_height() == 1080
	var used_task_642_board: bool = false
	if not visible_window_readback_available:
		image = _load_task_642_board_or_empty()
		used_task_642_board = image != null and image.get_width() == 1920 and image.get_height() == 1080
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		image = _build_minimal_review_board()
	_assert(image.get_width() == 1920 and image.get_height() == 1080, "TASK_644 review PNG is FullHD")
	_assert(_count_non_dark_samples(image) > 20, "TASK_644 review PNG has visible content")
	var save_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(save_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "TASK_644 review PNG is written")
	var manifest: Dictionary = _build_manifest(snapshot, image, visible_window_readback_available, used_task_642_board)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_644 manifest is written")
	_assert(String(manifest.get("gate", "")) == "pass", "TASK_644 manifest gate passes")
	_assert(["review_ready", "manual_open"].has(String(manifest.get("real_window_review_gate", ""))), "TASK_644 manifest exposes real window review gate")
	_assert(bool(manifest.get("manual_review_required", false)), "TASK_644 manifest keeps manual review required")
	_assert(not bool(manifest.get("manual_review_done", true)), "TASK_644 manifest does not claim manual review done")
	_assert(bool(manifest.get("read_only", false)), "TASK_644 manifest is read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "TASK_644 manifest does not set gameplay truth")
	_assert(not bool(manifest.get("creates_navigation", true)), "TASK_644 manifest creates no navigation")
	_assert(not bool(manifest.get("creates_command", true)), "TASK_644 manifest creates no command")
	if not bool(manifest.get("visible_window_readback_available", false)):
		_assert(String(manifest.get("real_window_review_gate", "")) == "manual_open", "Headless fallback keeps real window review open")

	scene.queue_free()
	await _wait_frames(2)


func _build_frontier_probe_result() -> Dictionary:
	return {
		"scenario_id": "frontier_probe_vertical_slice",
		"mission_id": "frontier_probe_vertical_slice",
		"scenario_file_path": "res://data/mission_scenarios/frontier_probe_vertical_slice.json",
		"route_id": "frontier_probe_aa_computer_cargo",
		"winning_team_id": "team_alpha",
		"mission_outcome": "completed",
		"result": "victory",
		"win_condition_type": "frontier_probe_cargo_extract",
		"objective_captured": true,
		"duration_seconds": 312.0,
		"selected_unit_ids": PackedStringArray(["lead_alpha", "rifle_alpha", "medic_alpha"]),
		"selected_fireteam_ids": PackedStringArray(["ft_alpha"]),
		"progression_award_summary": {
			"schema": "sternenbuergerchen.skill_progress_award_summary.v1",
			"authority": "MissionProgressionResolver",
			"source": "progression_unit_updates",
			"award_applied": true,
			"total_xp_delta": 18,
			"listed_awards": [
				{"unit_id": "lead_alpha", "xp_delta": 8, "skill_gain_count": 1, "ftl_tactical_gain": 0.015},
			],
			"read_only": true,
			"ui_sets_gameplay_truth": false,
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


func _load_task_642_board_or_empty() -> Image:
	if not FileAccess.file_exists(TASK_642_PNG_PATH):
		return Image.new()
	var image := Image.new()
	var error: Error = image.load(TASK_642_PNG_PATH)
	if error != OK:
		return Image.new()
	return image


func _build_minimal_review_board() -> Image:
	var image: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.047, 0.052, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 90), Color(0.02, 0.075, 0.09, 1.0))
	_fill_rect(image, Rect2i(48, 140, 1824, 120), Color(0.11, 0.15, 0.18, 1.0))
	_fill_rect(image, Rect2i(80, 180, 720, 36), Color(0.62, 0.95, 0.78, 1.0))
	_fill_rect(image, Rect2i(80, 222, 920, 36), Color(0.66, 0.80, 1.0, 1.0))
	_fill_rect(image, Rect2i(80, 900, 940, 34), Color(0.86, 0.70, 0.18, 1.0))
	return image


func _build_manifest(snapshot: Dictionary, image: Image, visible_window_readback_available: bool, used_task_642_board: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.frontier_probe_homebase_real_window_review.v1",
		"task_id": "TASK_644",
		"source_task_ids": PackedStringArray(["TASK_642", "TASK_643"]),
		"snapshot_schema": String(snapshot.get("schema", "")),
		"gate": "pass" if String(snapshot.get("gate", "")) == "pass" else "fail",
		"real_window_review_gate": "review_ready" if visible_window_readback_available else "manual_open",
		"visible_window_readback_available": visible_window_readback_available,
		"generated_evidence_board": not visible_window_readback_available,
		"used_task_642_labeled_board": used_task_642_board,
		"png_path": ProjectSettings.globalize_path(OUTPUT_PNG_PATH),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"viewport": {"width": image.get_width(), "height": image.get_height()},
		"readiness_gate": String(snapshot.get("readiness_gate", "")),
		"route_id": String(snapshot.get("route_id", "")),
		"scenario_id": String(snapshot.get("scenario_id", "")),
		"current_next_step_id": String(snapshot.get("current_next_step_id", "")),
		"readiness_line": String(snapshot.get("readiness_line", "")),
		"post_summary_visible": bool(snapshot.get("post_summary_visible", false)),
		"next_sortie_visible": bool(snapshot.get("next_sortie_visible", false)),
		"post_summary_rect": Dictionary(snapshot.get("post_summary_rect", {})).duplicate(true),
		"next_sortie_rect": Dictionary(snapshot.get("next_sortie_rect", {})).duplicate(true),
		"mission_panel_rect": Dictionary(snapshot.get("mission_panel_rect", {})).duplicate(true),
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"recommended_next_task": "Runtime Homebase UI polish only if real-window friction is visible",
	}


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _count_non_dark_samples(image: Image) -> int:
	var count: int = 0
	var step_x: int = maxi(1, image.get_width() / 64)
	var step_y: int = maxi(1, image.get_height() / 36)
	for y in range(0, image.get_height(), step_y):
		for x in range(0, image.get_width(), step_x):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.r + pixel.g + pixel.b > 0.30:
				count += 1
	return count


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var x0: int = clampi(rect.position.x, 0, image.get_width())
	var y0: int = clampi(rect.position.y, 0, image.get_height())
	var x1: int = clampi(rect.position.x + rect.size.x, 0, image.get_width())
	var y1: int = clampi(rect.position.y + rect.size.y, 0, image.get_height())
	for y in range(y0, y1):
		for x in range(x0, x1):
			image.set_pixel(x, y, color)


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_644 manifest for writing")
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
