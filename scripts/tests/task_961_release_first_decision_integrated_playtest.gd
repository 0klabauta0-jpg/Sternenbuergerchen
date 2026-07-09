extends SceneTree

const Playtest := preload("res://scripts/mission/release_first_decision_integrated_playtest.gd")

const TASK_PATH := "res://docs/tasks/TASK_961_release_first_decision_integrated_playtest.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_integrated_playtest.gd"
const TOOL_PATH := "res://scripts/tools/capture_release_first_decision_integrated_playtest.ps1"
const OUTPUT_PATH := "res://tmp/release_first_decision_integrated_playtest_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_integrated_playtest.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.first_decision_release_playable_slice.v1"
const NEXT_TASK := "TASK_962 - Release First Decision Playtest Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_961 Release First Decision Integrated Playtest ===")
	_test_docs_and_static_hooks()
	_test_missing_slice_blocks()
	_test_unplayable_slice_blocks()
	_test_missing_manifest_needs_playtest_run()
	_test_complete_manifest_passes_integrated_playtest()
	_test_manifest_regression_routes_to_findings()
	_test_playtest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_961_release_first_decision_integrated_playtest: FAILED")
		quit(1)
		return
	print("TASK_961_release_first_decision_integrated_playtest: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_961 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_961 playtest service exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_961 capture tool exists")
	_assert(task_text.contains("TASK_961 - Release First Decision Integrated Playtest"), "Task names TASK_961")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_962 follow-up")
	_assert(status_text.contains("TASK_961 - Release First Decision Integrated Playtest"), "Implementation status tracks TASK_961")
	_assert(roadmap_text.contains("TASK_961 - Release First Decision Integrated Playtest (implementiert"), "Roadmap marks TASK_961 implemented")
	_assert(command_contract_text.contains("Release First Decision Integrated Playtest (TASK_961)"), "Mission feedback contract documents TASK_961")
	_assert(clarity_contract_text.contains("Release First Decision Integrated Playtest (TASK_961)"), "Decision clarity contract documents TASK_961")
	_assert(service_text.contains(SCHEMA), "Playtest service exposes stable TASK_961 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_961\""), "Playtest service writes TASK_961 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_960\""), "Playtest service links TASK_960")
	_assert(service_text.contains("REQUIRED_PLAYTEST_CHECKS"), "Playtest service declares required checks")
	_assert(service_text.contains("\"read_only\": true"), "Playtest service declares read-only")
	_assert(service_text.contains("\"ui_sets_gameplay_truth\": false"), "Playtest service creates no UI gameplay truth")
	_assert(service_text.contains("\"creates_command\": false"), "Playtest service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Playtest service creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Playtest service creates no multiplayer truth")
	_assert(tool_text.contains("release_first_decision_integrated_playtest.json"), "Capture tool writes TASK_961 manifest")
	_assert(tool_text.contains("--release-singleplayer-lz-drop-preview"), "Capture tool uses first decision deep-link")
	_assert(tool_text.contains("manual_playtest_done = $false"), "Capture tool does not auto-pass manual playtest")
	_assert(tool_text.contains("updates_shortcuts = $false"), "Capture tool updates no shortcuts")


func _test_missing_slice_blocks() -> void:
	var snapshot: Dictionary = Playtest.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("gate", "")) == "blocked", "Missing slice blocks TASK_961")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing slice reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing slice reports task mismatch")
	_assert(blocker_ids.has("source_slice_not_playable"), "Missing slice reports not playable")
	_assert(_snapshot_is_read_only(snapshot), "Blocked playtest remains read-only")


func _test_unplayable_slice_blocks() -> void:
	var source: Dictionary = _playable_slice()
	source["gate"] = "release_slice_regression_found"
	source["release_slice_playable"] = false
	var snapshot: Dictionary = Playtest.build_snapshot(source, _complete_manifest())
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("gate", "")) == "blocked", "Unplayable slice blocks TASK_961")
	_assert(blocker_ids.has("source_slice_not_playable"), "Unplayable source reports blocker")
	_assert(not bool(snapshot.get("integrated_playtest_passed", true)), "Blocked playtest does not pass")


func _test_missing_manifest_needs_playtest_run() -> void:
	var snapshot: Dictionary = Playtest.build_snapshot(_playable_slice(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("gate", "")) == "needs_integrated_playtest_run", "Playable slice without manifest needs playtest")
	_assert(issue_ids.has("integrated_playtest_manifest_missing"), "Missing manifest is named")
	_assert(int(snapshot.get("missing_playtest_check_count", -1)) == Playtest.REQUIRED_PLAYTEST_CHECKS.size(), "All playtest checks remain missing")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_961 - Release First Decision Integrated Playtest", "Missing manifest loops on TASK_961")
	_assert(_snapshot_is_read_only(snapshot), "Needs-run playtest remains read-only")


func _test_complete_manifest_passes_integrated_playtest() -> void:
	var snapshot: Dictionary = Playtest.build_snapshot(_playable_slice(), _complete_manifest())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Playtest snapshot schema matches")
	_assert(String(snapshot.get("task_id", "")) == "TASK_961", "Playtest snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_960", "Playtest snapshot links TASK_960")
	_assert(String(snapshot.get("gate", "")) == "integrated_playtest_passed", "Complete manifest passes playtest")
	_assert(bool(snapshot.get("integrated_playtest_passed", false)), "Integrated playtest flag is set")
	_assert(int(snapshot.get("missing_playtest_check_count", -1)) == 0, "No playtest checks missing")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Passing playtest has no issues")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passing playtest recommends TASK_962")
	_assert(String(snapshot.get("recommended_direction", "")) == "cut_release_first_decision_playtest_findings", "Passing playtest recommends findings")
	_assert(_covered_stages_complete(Array(snapshot.get("observed_release_stages", []))), "Passing playtest observes release stages")
	_assert(_snapshot_is_read_only(snapshot), "Passing playtest remains read-only")


func _test_manifest_regression_routes_to_findings() -> void:
	var manifest: Dictionary = _complete_manifest()
	manifest["post_go_feedback_observed"] = false
	manifest["performance_ok"] = false
	var snapshot: Dictionary = Playtest.build_snapshot(_playable_slice(), manifest)
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("gate", "")) == "integrated_playtest_regression_found", "Manifest regressions fail playtest")
	_assert(issue_ids.has("post_go_feedback_missing"), "Playtest names missing post-GO feedback")
	_assert(issue_ids.has("performance_not_ok"), "Playtest names performance regression")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Regressions recommend TASK_962")
	_assert(not bool(snapshot.get("integrated_playtest_passed", true)), "Regression playtest does not pass")


func _test_playtest_roundtrip() -> void:
	var snapshot: Dictionary = Playtest.build_snapshot(_playable_slice(), _complete_manifest())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_961 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_961", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_960", "Roundtrip keeps TASK_960 link")
	_assert(String(roundtrip.get("gate", "")) == "integrated_playtest_passed", "Roundtrip keeps playtest gate")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _playable_slice() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_960",
		"source_task_id": "TASK_959",
		"gate": "release_slice_playable",
		"release_slice_playable": true,
		"recommended_next_task": "TASK_961 - Release First Decision Integrated Playtest",
		"covered_release_stages": [
			"homebase_ready",
			"flightdeck_payload",
			"mission_lz_drop",
			"first_decision_preview",
			"go_and_post_go_feedback",
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


func _complete_manifest() -> Dictionary:
	return {
		"manifest_available": true,
		"schema": SCHEMA,
		"task_id": "TASK_961",
		"launch_argument": "--release-singleplayer-lz-drop-preview",
		"release_exe_launched": true,
		"selected_process_id": 961,
		"capture_process_id": 961,
		"correct_window_content_confirmed": true,
		"window_capture_trusted": true,
		"window_screenshot_written": true,
		"homebase_to_mission_observed": true,
		"dropship_lz_drop_observed": true,
		"first_decision_preview_observed": true,
		"go_executed": true,
		"post_go_feedback_observed": true,
		"no_command_before_go_confirmed": true,
		"performance_ok": true,
		"no_new_hud_gameplay_truth": true,
		"multiplayer_snapshot_boundary_preserved": true,
		"manual_playtest_done": true,
		"updates_shortcuts": false,
	}


func _covered_stages_complete(stages: Array) -> bool:
	return stages.has("release_launch") \
		and stages.has("homebase_to_mission") \
		and stages.has("dropship_lz_drop") \
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
