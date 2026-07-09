extends SceneTree

const Slice := preload("res://scripts/mission/first_decision_release_playable_slice.gd")

const TASK_PATH := "res://docs/tasks/TASK_960_first_decision_release_playable_slice.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/first_decision_release_playable_slice.gd"
const OUTPUT_PATH := "res://tmp/first_decision_release_playable_slice_acceptance.json"
const SCHEMA := "sternenbuergerchen.first_decision_release_playable_slice.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.first_decision_playability_smoke.v1"
const NEXT_TASK := "TASK_961 - Release First Decision Integrated Playtest"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_960 First Decision Release Playable Slice ===")
	_test_docs_and_static_hooks()
	_test_missing_smoke_blocks()
	_test_unpassed_smoke_blocks()
	_test_missing_spine_needs_release_slice_trace()
	_test_complete_spine_is_release_playable()
	_test_spine_regression_routes_to_followup()
	_test_slice_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_960_first_decision_release_playable_slice: FAILED")
		quit(1)
		return
	print("TASK_960_first_decision_release_playable_slice: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_960 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_960 slice service exists")
	_assert(task_text.contains("TASK_960 - First Decision Release Playable Slice"), "Task names TASK_960")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_961 follow-up")
	_assert(status_text.contains("TASK_960 - First Decision Release Playable Slice"), "Implementation status tracks TASK_960")
	_assert(roadmap_text.contains("TASK_960 - First Decision Release Playable Slice (implementiert"), "Roadmap marks TASK_960 implemented")
	_assert(command_contract_text.contains("First Decision Release Playable Slice (TASK_960)"), "Mission feedback contract documents TASK_960")
	_assert(clarity_contract_text.contains("First Decision Release Playable Slice (TASK_960)"), "Decision clarity contract documents TASK_960")
	_assert(service_text.contains(SCHEMA), "Slice service exposes stable TASK_960 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_960\""), "Slice service writes TASK_960 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_959\""), "Slice service links TASK_959")
	_assert(service_text.contains("REQUIRED_SLICE_CHECKS"), "Slice service declares required checks")
	_assert(service_text.contains("\"read_only\": true"), "Slice service declares read-only")
	_assert(service_text.contains("\"ui_sets_gameplay_truth\": false"), "Slice service creates no UI gameplay truth")
	_assert(service_text.contains("\"creates_command\": false"), "Slice service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Slice service creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Slice service creates no multiplayer truth")


func _test_missing_smoke_blocks() -> void:
	var snapshot: Dictionary = Slice.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("gate", "")) == "blocked", "Missing smoke blocks TASK_960")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing smoke reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing smoke reports task mismatch")
	_assert(blocker_ids.has("source_smoke_not_passed"), "Missing smoke reports not passed")
	_assert(_snapshot_is_read_only(snapshot), "Blocked slice remains read-only")


func _test_unpassed_smoke_blocks() -> void:
	var source: Dictionary = _passed_smoke()
	source["gate"] = "smoke_regression_found"
	source["smoke_passed"] = false
	var snapshot: Dictionary = Slice.build_snapshot(source, _complete_spine())
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("gate", "")) == "blocked", "Unpassed smoke blocks TASK_960")
	_assert(blocker_ids.has("source_smoke_not_passed"), "Unpassed smoke reports blocker")
	_assert(not bool(snapshot.get("release_slice_playable", true)), "Blocked slice is not playable")


func _test_missing_spine_needs_release_slice_trace() -> void:
	var snapshot: Dictionary = Slice.build_snapshot(_passed_smoke(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("gate", "")) == "needs_release_slice_trace", "Passed smoke without spine needs trace")
	_assert(issue_ids.has("release_spine_trace_missing"), "Missing spine trace is named")
	_assert(int(snapshot.get("missing_slice_check_count", -1)) == Slice.REQUIRED_SLICE_CHECKS.size(), "All slice checks remain missing")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_960 - First Decision Release Playable Slice", "Missing trace loops on TASK_960")
	_assert(_snapshot_is_read_only(snapshot), "Needs-trace slice remains read-only")


func _test_complete_spine_is_release_playable() -> void:
	var snapshot: Dictionary = Slice.build_snapshot(_passed_smoke(), _complete_spine())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Slice snapshot schema matches")
	_assert(String(snapshot.get("task_id", "")) == "TASK_960", "Slice snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_959", "Slice snapshot links TASK_959")
	_assert(String(snapshot.get("gate", "")) == "release_slice_playable", "Complete spine is playable")
	_assert(bool(snapshot.get("release_slice_playable", false)), "Playable flag is set")
	_assert(int(snapshot.get("missing_slice_check_count", -1)) == 0, "No slice checks missing")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Playable slice has no issues")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Playable slice recommends TASK_961")
	_assert(String(snapshot.get("recommended_direction", "")) == "run_integrated_first_decision_release_playtest", "Playable slice recommends integrated playtest")
	_assert(_covered_stages_complete(Array(snapshot.get("covered_release_stages", []))), "Playable slice covers release stages")
	_assert(_snapshot_is_read_only(snapshot), "Playable slice remains read-only")


func _test_spine_regression_routes_to_followup() -> void:
	var trace: Dictionary = _complete_spine()
	trace["post_go_feedback_visible"] = false
	trace["performance_hotpath_ok"] = false
	var snapshot: Dictionary = Slice.build_snapshot(_passed_smoke(), trace)
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("gate", "")) == "release_slice_regression_found", "Spine regressions fail slice")
	_assert(issue_ids.has("post_go_feedback_missing"), "Slice names missing post-GO feedback")
	_assert(issue_ids.has("performance_hotpath_not_ok"), "Slice names hotpath regression")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Regressions still recommend TASK_961 follow-up")
	_assert(not bool(snapshot.get("release_slice_playable", true)), "Regression slice is not playable")


func _test_slice_roundtrip() -> void:
	var snapshot: Dictionary = Slice.build_snapshot(_passed_smoke(), _complete_spine())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_960 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_960", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_959", "Roundtrip keeps TASK_959 link")
	_assert(String(roundtrip.get("gate", "")) == "release_slice_playable", "Roundtrip keeps slice gate")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _passed_smoke() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_959",
		"source_task_id": "TASK_958",
		"gate": "smoke_passed",
		"smoke_passed": true,
		"recommended_next_task": "TASK_960 - First Decision Release Playable Slice",
		"answered_player_questions": [
			"what_should_i_do_next",
			"why_is_that_choice_good",
			"where_will_the_fireteam_go",
			"what_changes_only_after_go",
		],
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


func _complete_spine() -> Dictionary:
	return {
		"trace_available": true,
		"launch_argument": "--release-singleplayer-lz-drop-preview",
		"homebase_ready": true,
		"fireteam_ready": true,
		"flightdeck_ready": true,
		"dropship_payload_ready": true,
		"mission_loaded": true,
		"lz_selected": true,
		"drop_completed": true,
		"fireteam_deployed": true,
		"decision_preview_visible": true,
		"next_why_visible": true,
		"risk_preview_visible": true,
		"go_boundary_preserved": true,
		"go_confirmed": true,
		"post_go_feedback_visible": true,
		"command_queue_lifecycle_clear": true,
		"performance_hotpath_ok": true,
		"no_new_hud_gameplay_truth": true,
		"multiplayer_snapshot_boundary_preserved": true,
	}


func _covered_stages_complete(stages: Array) -> bool:
	return stages.has("homebase_ready") \
		and stages.has("flightdeck_payload") \
		and stages.has("mission_lz_drop") \
		and stages.has("first_decision_preview") \
		and stages.has("go_and_post_go_feedback")


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _issue_ids(issues: Array) -> Array:
	var result: Array = []
	for issue_variant in issues:
		if typeof(issue_variant) == TYPE_DICTIONARY:
			result.append(String(Dictionary(issue_variant).get("id", "")))
	return result


func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed)
	return {}


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
