extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1006_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings.v1"
const NEXT_TASK := "TASK_1007 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1006 Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_issue_source_builds_round_loop_surfaces()
	_test_accepted_source_still_exports_polish_contract()
	_test_controller_exports_round_loop_visual_polish()
	_test_round_loop_visual_polish_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1006_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish: FAILED")
		quit(1)
		return
	print("TASK_1006_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1006 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1006 round-loop visual polish service exists")
	_assert(task_text.contains("TASK_1006 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish"), "Task names TASK_1006")
	_assert(task_text.contains(NEXT_TASK), "Task names round-loop playability follow-up")
	_assert(status_text.contains("TASK_1006 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish"), "Implementation status tracks TASK_1006")
	_assert(roadmap_text.contains("TASK_1006 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish (implementiert"), "Roadmap marks TASK_1006 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish (TASK_1006)"), "Mission feedback contract documents TASK_1006")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish (TASK_1006)"), "Decision clarity contract documents TASK_1006")
	_assert(service_text.contains(SCHEMA), "Round-loop visual polish service exposes stable TASK_1006 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1006\""), "Round-loop visual polish service writes TASK_1006 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1005\""), "Round-loop visual polish service links TASK_1005")
	_assert(service_text.contains("\"round_loop_surface_specs\""), "Round-loop visual polish exposes surface specs")
	_assert(service_text.contains("\"round_surface\""), "Round-loop visual polish exposes ROUND surface")
	_assert(service_text.contains("\"next_surface\""), "Round-loop visual polish exposes NEXT surface")
	_assert(service_text.contains("\"go_surface\""), "Round-loop visual polish exposes GO surface")
	_assert(service_text.contains("\"selected_fireteam_runtime_surface\""), "Round-loop visual polish exposes selected fireteam surface")
	_assert(service_text.contains("\"mission_control_runtime_surface\""), "Round-loop visual polish exposes mission control surface")
	_assert(service_text.contains("\"command_feedback_runtime_surface\""), "Round-loop visual polish exposes command feedback surface")
	_assert(service_text.contains("\"creates_command\": false"), "Round-loop visual polish creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Round-loop visual polish creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_ROUND_LOOP_VISUAL_POLISH_SCRIPT"), "Controller preloads TASK_1006 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish_snapshot"), "Controller exposes TASK_1006 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish_line"), "Command feedback exports TASK_1006 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish_surface_specs"), "Command feedback exports TASK_1006 surface specs")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1006")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_polishable"), "Missing source reports non-polishable source")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_issue_source_builds_round_loop_surfaces() -> void:
	var snapshot: Dictionary = _build_snapshot(_issue_source())
	var specs: Array = Array(snapshot.get("round_loop_surface_specs", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1006")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1006", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1005", "Snapshot links TASK_1005")
	_assert(String(snapshot.get("status", "")) == "round_loop_visual_polish_ready", "Issue source builds round-loop visual polish")
	_assert(bool(snapshot.get("active", false)), "Round-loop visual polish is active")
	_assert(int(snapshot.get("round_loop_surface_spec_count", 0)) == 6, "Round-loop visual polish has six surface specs")
	_assert(String(snapshot.get("round_loop_polish_line", "")).contains("ROUND"), "Round-loop polish line names ROUND")
	_assert(String(snapshot.get("round_loop_polish_line", "")).contains("NEXT"), "Round-loop polish line names NEXT")
	_assert(String(snapshot.get("round_loop_polish_line", "")).contains("GO"), "Round-loop polish line names GO")
	_assert(String(Dictionary(snapshot.get("round_surface", {})).get("text", "")).contains("ROUND"), "ROUND surface keeps round text")
	_assert(String(Dictionary(snapshot.get("next_surface", {})).get("text", "")).contains("NEXT"), "NEXT surface keeps next text")
	_assert(String(Dictionary(snapshot.get("go_surface", {})).get("text", "")).contains("GO"), "GO surface keeps go text")
	_assert(String(Dictionary(snapshot.get("selected_fireteam_runtime_surface", {})).get("text", "")).contains("ROUND"), "Selected surface keeps runtime text")
	_assert(String(Dictionary(snapshot.get("mission_control_runtime_surface", {})).get("text", "")).contains("NEXT"), "Mission surface keeps runtime text")
	_assert(String(Dictionary(snapshot.get("command_feedback_runtime_surface", {})).get("text", "")).contains("GO"), "Feedback surface keeps runtime text")
	_assert(_surface_specs_are_polished(specs), "Round-loop surface specs are polished")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Round-loop polish recommends playability slice")
	_assert(_snapshot_is_read_only(snapshot), "Round-loop visual polish remains read-only")


func _test_accepted_source_still_exports_polish_contract() -> void:
	var snapshot: Dictionary = _build_snapshot(_accepted_source())
	_assert(String(snapshot.get("status", "")) == "round_loop_visual_polish_ready", "Accepted source keeps round-loop visual polish ready")
	_assert(String(snapshot.get("source_status", "")) == "accepted_for_round_loop_playability_slice", "Accepted source status is recorded")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Accepted source recommends playability slice")
	_assert(String(snapshot.get("recommended_direction", "")) == "build_round_loop_playability_slice", "Accepted source recommends playability direction")
	_assert(_snapshot_is_read_only(snapshot), "Accepted polish remains read-only")


func _test_controller_exports_round_loop_visual_polish() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish_snapshot(_issue_source())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1006 schema matches")
	_assert(int(snapshot.get("round_loop_surface_spec_count", 0)) == 6, "Controller TASK_1006 has six specs")
	_assert(String(snapshot.get("round_loop_polish_line", "")).contains("NEXT"), "Controller TASK_1006 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1006 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish"), "Command feedback embeds TASK_1006")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish_line"), "Command feedback exports TASK_1006 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish_surface_specs"), "Command feedback exports TASK_1006 specs")
	controller.queue_free()


func _test_round_loop_visual_polish_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_issue_source())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1006 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1006", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1005", "Roundtrip keeps TASK_1005 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_findings: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1006 service is loadable")
		return {
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_fire_event": false,
			"creates_damage_event": false,
			"creates_movement": false,
			"sets_multiplayer_truth": false,
		}
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1006 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_findings)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1006 service returns dictionary")
	return {}


func _issue_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1005",
		"source_task_id": "TASK_1004",
		"status": "ready_for_round_loop_visual_polish",
		"source_runtime_surface_specs": [
			{"surface_id": "round_loop_status_surface", "token": "ROUND", "text": "ROUND 2 abgeschlossen", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false},
			{"surface_id": "next_decision_surface", "token": "NEXT", "text": "NEXT Micro-Ziel waehlen", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false},
			{"surface_id": "go_boundary_surface", "token": "GO", "text": "GO separat bestaetigen", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false},
		],
		"source_selected_fireteam_runtime_line": "ROUND 2 stabil | NEXT bereit",
		"source_mission_control_runtime_line": "NEXT Micro-Ziel waehlen | GO separat",
		"source_command_feedback_runtime_line": "ROUND LOOP: Feedback gelesen | GO separat bleibt",
		"issue_count": 4,
		"issues": [
			{"id": "round_surface_not_visible", "text": "ROUND braucht mehr Gewicht."},
			{"id": "next_surface_not_visible", "text": "NEXT braucht klarere Flaeche."},
			{"id": "go_separation_not_visible", "text": "GO-Grenze muss staerker werden."},
			{"id": "player_round_loop_not_readable", "text": "Round-Loop liest sich noch nicht rund."},
		],
		"read_only": true,
		"read_only_capture": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


func _accepted_source() -> Dictionary:
	var source: Dictionary = _issue_source()
	source["status"] = "accepted_for_round_loop_playability_slice"
	source["issue_count"] = 0
	source["issues"] = []
	return source


func _surface_specs_are_polished(specs: Array) -> bool:
	if specs.size() != 6:
		return false
	for spec_variant in specs:
		var spec := Dictionary(spec_variant)
		if String(spec.get("surface_id", "")).is_empty():
			return false
		if String(spec.get("role", "")).is_empty():
			return false
		if String(spec.get("text", "")).strip_edges().is_empty():
			return false
		if String(spec.get("style_id", "")).is_empty():
			return false
		if float(spec.get("min_height", 0.0)) < 24.0:
			return false
		if int(spec.get("max_lines", 0)) < 1:
			return false
		if int(spec.get("line_budget", 0)) < 32:
			return false
		if not bool(spec.get("autowrap", false)):
			return false
		if bool(spec.get("creates_command", true)):
			return false
	return true


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
