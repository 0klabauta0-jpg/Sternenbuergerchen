extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_648_homebase_next_sortie_action_cue.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const STATE_HANDBOOK_PATH: String = "res://docs/reports/project_state_handbook_2026_06_30.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/homebase_next_sortie_action_cue.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_648 Homebase Next Sortie Action Cue ===")
	_test_docs_and_reports()
	await _test_next_sortie_action_cue()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_648: FAILED")
		quit(1)
		return
	print("TASK_648: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var state_handbook_text: String = _read_text(STATE_HANDBOOK_PATH)
	var homebase_text: String = _read_text(HOMEBASE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_648 task file exists")
	_assert(task_text.contains("Homebase Next Sortie Action Cue"), "TASK_648 task names action cue")
	_assert(status_text.contains("TASK_648 - Homebase Next Sortie Action Cue"), "Implementation status tracks TASK_648")
	_assert(roadmap_text.contains("TASK_648 - Homebase Next Sortie Action Cue (implementiert)"), "Roadmap marks TASK_648 implemented")
	_assert(contract_text.contains("Homebase-Next-Sortie-Action-Cue"), "Mission feedback contract documents TASK_648")
	_assert(homebase_text.contains("review_gains_non_blocking"), "Homebase exposes non-blocking review-gains cue")
	_assert(report_text.contains("TASK_648 Homebase Next Sortie Action Cue"), "Rolling report tracks TASK_648")
	_assert(report_text.contains('latest_completed_task: "TASK_648 - Homebase Next Sortie Action Cue"'), "Rolling report marks TASK_648 latest completed")
	_assert(handbook_text.contains("TASK_648 - Homebase Next Sortie Action Cue"), "Status handbook tracks TASK_648")
	_assert(handbook_text.contains('current_task: "TASK_648 - Homebase Next Sortie Action Cue"'), "Status handbook current task is TASK_648")
	_assert(state_handbook_text.contains("TASK_648 - Homebase Next Sortie Action Cue"), "State handbook tracks TASK_648")
	for key in [
		"homebase_next_sortie_action_cue.task_id",
		"homebase_next_sortie_action_cue.manifest_path",
		"homebase_next_sortie_action_cue.current_next_step_id",
		"homebase_next_sortie_action_cue.readiness_line",
		"homebase_next_sortie_action_cue.review_gains_non_blocking",
		"homebase_next_sortie_action_cue.read_only",
		"homebase_next_sortie_action_cue.notes",
	]:
		_assert(report_text.contains(key), "Rolling report exports %s" % key)
	_assert(report_text.contains('data-note-key="notes.homebase_next_sortie_action_cue"'), "Rolling report exports TASK_648 free note")
	_assert(handbook_text.contains('data-export-key="status.task_648_done"'), "Status handbook exports TASK_648 checkbox")


func _test_next_sortie_action_cue() -> void:
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

	var snapshot: Dictionary = Dictionary(homebase_screen.call("get_frontier_probe_homebase_next_sortie_readiness_snapshot")).duplicate(true)
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.frontier_probe_homebase_next_sortie_readiness.v1", "TASK_648 reuses stable next-sortie schema")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_648 next-sortie gate passes")
	_assert(String(snapshot.get("current_next_step_id", "")) == "stage_fireteam", "Action cue points to stage fireteam when no payload exists")
	_assert(String(snapshot.get("readiness_line", "")).contains("now: Stage fireteam"), "Rendered line names the actionable next step")
	_assert(_step_exists(snapshot, "review_roster_gains"), "Review gains remain listed")
	_assert(_step_is_ready(snapshot, "review_roster_gains"), "Review gains are informationally ready")
	_assert(bool(snapshot.get("review_gains_non_blocking", false)), "Review gains are non-blocking")
	_assert(int(snapshot.get("payload_operator_count", -1)) == 0, "Fixture has no staged payload")
	_assert(bool(snapshot.get("read_only", false)), "TASK_648 snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_648 snapshot does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "TASK_648 creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "TASK_648 creates no command")

	var manifest: Dictionary = _build_manifest(snapshot)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_648 manifest is written")
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.homebase_next_sortie_action_cue_manifest.v1", "TASK_648 manifest schema is stable")
	_assert(String(manifest.get("current_next_step_id", "")) == "stage_fireteam", "Manifest records actionable next step")
	_assert(bool(manifest.get("review_gains_non_blocking", false)), "Manifest records non-blocking review gains")

	scene.queue_free()
	await _wait_frames(2)


func _build_manifest(snapshot: Dictionary) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.homebase_next_sortie_action_cue_manifest.v1",
		"task_id": "TASK_648",
		"snapshot_schema": String(snapshot.get("schema", "")),
		"gate": String(snapshot.get("gate", "")),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"current_next_step_id": String(snapshot.get("current_next_step_id", "")),
		"readiness_line": String(snapshot.get("readiness_line", "")),
		"review_gains_non_blocking": bool(snapshot.get("review_gains_non_blocking", false)),
		"payload_operator_count": int(snapshot.get("payload_operator_count", 0)),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"recommended_next_task": "TASK_649 - Core Loop Re-entry Playfeel Review or Host/Client Click Feel",
	}


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


func _step_exists(snapshot: Dictionary, step_id: String) -> bool:
	for step_variant in Array(snapshot.get("readiness_steps", [])):
		var step: Dictionary = Dictionary(step_variant)
		if String(step.get("id", "")).strip_edges() == step_id:
			return true
	return false


func _step_is_ready(snapshot: Dictionary, step_id: String) -> bool:
	for step_variant in Array(snapshot.get("readiness_steps", [])):
		var step: Dictionary = Dictionary(step_variant)
		if String(step.get("id", "")).strip_edges() == step_id:
			return bool(step.get("ready", false))
	return false


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_648 manifest for writing")
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
