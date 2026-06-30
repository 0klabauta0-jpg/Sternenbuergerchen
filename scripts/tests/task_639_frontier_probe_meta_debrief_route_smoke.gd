extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_639_frontier_probe_meta_debrief_route_smoke.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const META_LAYER_PATH: String = "res://scripts/meta/meta_layer_flow.gd"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_meta_debrief_route_smoke.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_639 Frontier Probe Meta Debrief Route Smoke ===")
	_test_docs_and_reports()
	await _test_meta_debrief_route_smoke()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_639: FAILED")
		quit(1)
		return
	print("TASK_639: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var meta_layer_text: String = _read_text(META_LAYER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_639 task file exists")
	_assert(task_text.contains("Frontier Probe Meta Debrief Route Smoke"), "TASK_639 task names meta debrief route smoke")
	_assert(status_text.contains("TASK_639 - Frontier Probe Meta Debrief Route Smoke"), "Implementation status tracks TASK_639")
	_assert(roadmap_text.contains("TASK_639 - Frontier Probe Meta Debrief Route Smoke (implementiert)"), "Roadmap marks TASK_639 implemented")
	_assert(contract_text.contains("Frontier-Probe-Meta-Debrief-Route-Smoke"), "Mission feedback contract documents TASK_639")
	_assert(meta_layer_text.contains("get_frontier_probe_meta_debrief_route_smoke_snapshot"), "MetaLayerFlow exposes TASK_639 snapshot")
	_assert(report_text.contains("TASK_639 Frontier Probe Meta Debrief Route Smoke"), "Rolling report tracks TASK_639")
	_assert(report_text.contains('latest_completed_task: "TASK_646 - Homebase MissionPanel Density Playfeel Review"'), "Rolling report advances latest completed beyond TASK_639")
	_assert(handbook_text.contains("TASK_639 - Frontier Probe Meta Debrief Route Smoke"), "Status handbook tracks TASK_639")
	_assert(handbook_text.contains('current_task: "TASK_646 - Homebase MissionPanel Density Playfeel Review"'), "Status handbook current task advances beyond TASK_639")
	for key in [
		"frontier_probe_meta_debrief_route_smoke.task_id",
		"frontier_probe_meta_debrief_route_smoke.manifest_path",
		"frontier_probe_meta_debrief_route_smoke.route_id",
		"frontier_probe_meta_debrief_route_smoke.debrief_visible_before_return",
		"frontier_probe_meta_debrief_route_smoke.homebase_visible_after_return",
		"frontier_probe_meta_debrief_route_smoke.return_action_available",
		"frontier_probe_meta_debrief_route_smoke.mission_result_preserved",
		"frontier_probe_meta_debrief_route_smoke.read_only",
		"frontier_probe_meta_debrief_route_smoke.recommended_next_task",
		"frontier_probe_meta_debrief_route_smoke.notes",
	]:
		_assert(report_text.contains(key), "Rolling report exports %s" % key)
	_assert(report_text.contains('data-note-key="notes.frontier_probe_meta_debrief_route_smoke"'), "Rolling report exports TASK_639 free note")
	_assert(handbook_text.contains('data-export-key="status.task_639_done"'), "Status handbook exports TASK_639 checkbox")


func _test_meta_debrief_route_smoke() -> void:
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
	await _wait_frames(6)

	var before_snapshot: Dictionary = Dictionary(scene.call("get_frontier_probe_meta_debrief_route_smoke_snapshot")).duplicate(true)
	_assert(String(before_snapshot.get("schema", "")) == "sternenbuergerchen.frontier_probe_meta_debrief_route_smoke.v1", "TASK_639 snapshot schema is stable")
	_assert(String(before_snapshot.get("gate", "")) == "pass", "TASK_639 gate passes before return")
	_assert(String(before_snapshot.get("current_stage", "")) == "debrief_review", "Before return stage is Debrief review")
	_assert(bool(before_snapshot.get("frontier_probe_result_present", false)), "Frontier Probe result is detected")
	_assert(String(before_snapshot.get("route_id", "")) == "frontier_probe_aa_computer_cargo", "Route id is preserved")
	_assert(String(before_snapshot.get("scenario_id", "")) == "frontier_probe_vertical_slice", "Scenario id is preserved")
	_assert(bool(before_snapshot.get("debrief_visible", false)), "Debrief is visible before return")
	_assert(not bool(before_snapshot.get("homebase_visible", true)), "Homebase is hidden before return")
	_assert(bool(before_snapshot.get("return_action_available", false)), "Return action is available before return")
	_assert(bool(before_snapshot.get("mission_result_preserved", false)), "Mission result is preserved before return")
	_assert(bool(before_snapshot.get("active_mission_released", false)), "Active mission is released before return")
	_assert(bool(before_snapshot.get("read_only", false)), "TASK_639 snapshot is read-only")
	_assert(not bool(before_snapshot.get("ui_sets_gameplay_truth", true)), "TASK_639 snapshot does not set gameplay truth")
	_assert(not bool(before_snapshot.get("creates_navigation", true)), "TASK_639 snapshot does not create navigation")
	_assert(_check_passed(before_snapshot, "task_586_handoff_gate_passes"), "TASK_639 reuses passing TASK_586 handoff")

	scene.call("request_debrief_return_homebase_for_test")
	await _wait_frames(6)
	var after_snapshot: Dictionary = Dictionary(scene.call("get_frontier_probe_meta_debrief_route_smoke_snapshot")).duplicate(true)
	_assert(String(after_snapshot.get("gate", "")) == "pass", "TASK_639 gate passes after return")
	_assert(String(after_snapshot.get("current_stage", "")) == "homebase_returned", "After return stage is Homebase returned")
	_assert(bool(after_snapshot.get("homebase_visible", false)), "Homebase is visible after return")
	_assert(not bool(after_snapshot.get("debrief_visible", true)), "Debrief is hidden after return")
	_assert(bool(after_snapshot.get("navigation_visible", false)), "Navigation is visible after return")
	_assert(bool(after_snapshot.get("mission_result_preserved", false)), "Mission result stays preserved after return")
	_assert(bool(after_snapshot.get("after_return_ready", false)), "After-return gate is ready")
	_assert(String(Dictionary(after_snapshot.get("last_mission_result", {})).get("route_id", "")) == "frontier_probe_aa_computer_cargo", "Last mission result keeps Frontier Probe route")

	var manifest: Dictionary = _build_manifest(before_snapshot, after_snapshot)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_639 manifest is written")
	_assert(bool(manifest.get("debrief_visible_before_return", false)), "Manifest records Debrief before return")
	_assert(bool(manifest.get("homebase_visible_after_return", false)), "Manifest records Homebase after return")

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
		"team_states": [
			{"unit_id": "lead_alpha", "display_name": "Lead Alpha", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 100},
			{"unit_id": "rifle_alpha", "display_name": "Rifle Alpha", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 88},
			{"unit_id": "medic_alpha", "display_name": "Medic Alpha", "fireteam_id": "ft_alpha", "vital_state": "wounded", "health_points": 42},
		],
		"fireteam_tactical_debrief": [
			{"fireteam_id": "ft_alpha", "summary_text": "AA disabled, station computer held, cargo extracted."},
		],
		"mini_aar_debrief": {
			"schema": "sternenbuergerchen.mini_aar_debrief_screen_stub.v1",
			"summary_text": "FIRE 0 | SUP 0 | Cargo departed",
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		},
	}


func _build_manifest(before_snapshot: Dictionary, after_snapshot: Dictionary) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.frontier_probe_meta_debrief_route_smoke_manifest.v1",
		"task_id": "TASK_639",
		"snapshot_schema": String(before_snapshot.get("schema", "")),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"route_id": String(before_snapshot.get("route_id", "")),
		"scenario_id": String(before_snapshot.get("scenario_id", "")),
		"before_gate": String(before_snapshot.get("gate", "")),
		"after_gate": String(after_snapshot.get("gate", "")),
		"debrief_visible_before_return": bool(before_snapshot.get("debrief_visible", false)),
		"homebase_visible_before_return": bool(before_snapshot.get("homebase_visible", false)),
		"return_action_available": bool(before_snapshot.get("return_action_available", false)),
		"homebase_visible_after_return": bool(after_snapshot.get("homebase_visible", false)),
		"debrief_visible_after_return": bool(after_snapshot.get("debrief_visible", false)),
		"navigation_visible_after_return": bool(after_snapshot.get("navigation_visible", false)),
		"mission_result_preserved": bool(before_snapshot.get("mission_result_preserved", false)) and bool(after_snapshot.get("mission_result_preserved", false)),
		"active_mission_released": bool(before_snapshot.get("active_mission_released", false)) and bool(after_snapshot.get("active_mission_released", false)),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"recommended_next_task": "TASK_640 - Frontier Probe Post Debrief Homebase Readability",
	}


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_639 manifest for writing")
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
