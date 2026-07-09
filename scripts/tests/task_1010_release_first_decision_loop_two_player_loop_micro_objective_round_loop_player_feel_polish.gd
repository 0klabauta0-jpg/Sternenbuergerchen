extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1010_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings.v1"
const NEXT_TASK := "TASK_1011 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1010 Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_rework_source_builds_player_feel_surfaces()
	_test_accepted_source_still_builds_calm_acceptance_ready_polish()
	_test_controller_exports_player_feel_polish()
	_test_player_feel_polish_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1010_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish: FAILED")
		quit(1)
		return
	print("TASK_1010_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1010 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1010 player-feel polish service exists")
	_assert(task_text.contains("TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish"), "Task names TASK_1010")
	_assert(task_text.contains(NEXT_TASK), "Task names acceptance follow-up")
	_assert(status_text.contains("TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish"), "Implementation status tracks TASK_1010")
	_assert(roadmap_text.contains("TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish (implementiert"), "Roadmap marks TASK_1010 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish (TASK_1010)"), "Mission feedback contract documents TASK_1010")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish (TASK_1010)"), "Decision clarity contract documents TASK_1010")
	_assert(service_text.contains(SCHEMA), "Player-feel polish service exposes stable TASK_1010 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1010\""), "Player-feel polish service writes TASK_1010 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1009\""), "Player-feel polish service links TASK_1009")
	_assert(service_text.contains("\"player_feel_surface_specs\""), "Player-feel polish exposes surface specs")
	_assert(service_text.contains("\"player_feel_polish_line\""), "Player-feel polish exposes compact line")
	_assert(service_text.contains("\"next_grip_line\""), "Player-feel polish exposes next-grip line")
	_assert(service_text.contains("\"go_boundary_microcopy\""), "Player-feel polish exposes GO-boundary microcopy")
	_assert(service_text.contains("\"calm_hud_guidance\""), "Player-feel polish exposes calm HUD guidance")
	_assert(service_text.contains("\"creates_command\": false"), "Player-feel polish creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Player-feel polish creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_ROUND_LOOP_PLAYER_FEEL_POLISH_SCRIPT"), "Controller preloads TASK_1010 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish_snapshot"), "Controller exposes TASK_1010 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish_line"), "Command feedback exports TASK_1010 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_surface_specs"), "Command feedback exports TASK_1010 surface specs")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1010")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_polishable"), "Missing source reports non-polishable source")
	_assert(_snapshot_is_read_only(snapshot), "Blocked player-feel polish snapshot remains read-only")


func _test_rework_source_builds_player_feel_surfaces() -> void:
	var snapshot: Dictionary = _build_snapshot(_rework_source())
	var specs: Array = Array(snapshot.get("player_feel_surface_specs", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1010")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1010", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1009", "Snapshot links TASK_1009")
	_assert(String(snapshot.get("status", "")) == "round_loop_player_feel_polish_ready", "Rework source builds player-feel polish")
	_assert(bool(snapshot.get("active", false)), "Player-feel polish is active")
	_assert(int(snapshot.get("player_feel_surface_spec_count", 0)) == 6, "Player-feel polish has six surface specs")
	_assert(String(snapshot.get("player_feel_polish_line", "")).contains("FEEL"), "Polish line names FEEL")
	_assert(String(snapshot.get("player_feel_polish_line", "")).contains("NEXT"), "Polish line names NEXT")
	_assert(String(snapshot.get("player_feel_polish_line", "")).contains("GO"), "Polish line names GO")
	_assert(String(snapshot.get("next_grip_line", "")).contains("NEXT"), "Next-grip line names NEXT")
	_assert(String(snapshot.get("go_boundary_microcopy", "")).contains("GO"), "GO microcopy names GO")
	_assert(String(snapshot.get("calm_hud_guidance", "")).contains("HUD"), "Calm HUD guidance names HUD")
	_assert(String(Dictionary(snapshot.get("entry_surface", {})).get("text", "")).contains("Start"), "Entry surface answers start friction")
	_assert(String(Dictionary(snapshot.get("rhythm_surface", {})).get("text", "")).contains("ROUND"), "Rhythm surface keeps ROUND token")
	_assert(String(Dictionary(snapshot.get("feedback_surface", {})).get("text", "")).contains("Feedback"), "Feedback surface answers dry feedback")
	_assert(String(Dictionary(snapshot.get("go_boundary_surface", {})).get("text", "")).contains("GO"), "GO surface answers GO boundary")
	_assert(_surface_specs_are_polished(specs), "Player-feel surface specs are polished")
	_assert(bool(snapshot.get("ready_for_acceptance_review", false)), "Player-feel polish is ready for acceptance review")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Player-feel polish recommends acceptance slice")
	_assert(_snapshot_is_read_only(snapshot), "Player-feel polish remains read-only")


func _test_accepted_source_still_builds_calm_acceptance_ready_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_accepted_source())
	_assert(String(snapshot.get("status", "")) == "round_loop_player_feel_polish_ready", "Accepted source still builds player-feel polish")
	_assert(String(snapshot.get("source_status", "")) == "accepted_for_round_loop_acceptance_slice", "Accepted source status is recorded")
	_assert(int(snapshot.get("source_issue_count", -1)) == 0, "Accepted source issue count is recorded")
	_assert(String(snapshot.get("player_feel_polish_line", "")).contains("rund"), "Accepted polish keeps round feel")
	_assert(bool(snapshot.get("ready_for_acceptance_review", false)), "Accepted polish is ready for acceptance review")
	_assert(String(snapshot.get("recommended_direction", "")) == "build_round_loop_acceptance_slice", "Accepted polish recommends acceptance direction")
	_assert(_snapshot_is_read_only(snapshot), "Accepted polish remains read-only")


func _test_controller_exports_player_feel_polish() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish_snapshot"):
		_assert(false, "Controller exposes TASK_1010 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish_snapshot(_rework_source())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1010 schema matches")
	_assert(int(snapshot.get("player_feel_surface_spec_count", 0)) == 6, "Controller TASK_1010 has six specs")
	_assert(String(snapshot.get("player_feel_polish_line", "")).contains("NEXT"), "Controller TASK_1010 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1010 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish"), "Command feedback embeds TASK_1010")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish_line"), "Command feedback exports TASK_1010 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_surface_specs"), "Command feedback exports TASK_1010 specs")
	controller.queue_free()


func _test_player_feel_polish_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_rework_source())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1010 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1010", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1009", "Roundtrip keeps TASK_1009 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_findings: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1010 service is loadable")
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
		_assert(false, "TASK_1010 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_findings)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1010 service returns dictionary")
	return {}


func _rework_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1009",
		"source_task_id": "TASK_1008",
		"status": "round_loop_player_feel_rework_needed",
		"gate": "round_loop_player_feel_rework_needed",
		"source_integrated_playtest_line": "ENTRY Mission | ROUND gelesen | NEXT bereit | GO separat | FEEDBACK NEXT bereit",
		"player_feel_summary_line": "FEEL REWORK: Feedback erklaert den naechsten Griff noch nicht angenehm genug.",
		"positive_findings": ["round_loop_integrated_path_present", "hud_feels_calm", "multiplayer_boundary_feels_clear"],
		"issue_count": 4,
		"issues": [
			{"id": "entry_feels_unclear", "text": "Entry/Start fuehlt sich noch unklar an."},
			{"id": "round_next_go_rhythm_not_clear", "text": "ROUND/NEXT/GO liest sich noch nicht als Rhythmus."},
			{"id": "feedback_feels_dry", "text": "Feedback erklaert den naechsten Griff noch nicht angenehm genug."},
			{"id": "go_boundary_not_felt", "text": "Confirm-/GO-Grenze ist im Gefuehl nicht klar genug."},
		],
		"review_available": true,
		"ready_for_round_loop_acceptance_slice": false,
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


func _accepted_source() -> Dictionary:
	var source: Dictionary = _rework_source()
	source["status"] = "accepted_for_round_loop_acceptance_slice"
	source["gate"] = "round_loop_player_feel_accepted"
	source["issue_count"] = 0
	source["issues"] = []
	source["ready_for_round_loop_acceptance_slice"] = true
	source["player_feel_summary_line"] = "FEEL PASS: ROUND/NEXT/GO/FEEDBACK fuehlt sich rund und ruhig an."
	source["positive_findings"] = [
		"round_loop_integrated_path_present",
		"entry_feels_clear",
		"round_next_go_rhythm_feels_clear",
		"feedback_invites_next_grip",
		"go_boundary_feels_clear",
		"hud_feels_calm",
		"performance_feels_responsive",
		"multiplayer_boundary_feels_clear",
	]
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
		if float(spec.get("min_height", 0.0)) < 26.0:
			return false
		if int(spec.get("line_budget", 0)) < 40:
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
