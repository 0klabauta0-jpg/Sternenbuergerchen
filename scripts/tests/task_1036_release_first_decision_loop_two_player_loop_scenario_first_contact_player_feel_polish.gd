extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1036_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings.v1"
const NEXT_TASK := "TASK_1037 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1036 Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_rework_source_builds_first_contact_polish_surfaces()
	_test_accepted_source_still_builds_playability_ready_polish()
	_test_controller_exports_first_contact_player_feel_polish()
	_test_first_contact_player_feel_polish_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1036_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish: FAILED")
		quit(1)
		return
	print("TASK_1036_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var feedback_source_text: String = _read_text("res://scripts/mission/diagnostics/mission_command_feedback_diagnostics.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1036 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1036 first-contact player-feel polish service exists")
	_assert(task_text.contains("TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish"), "Task names TASK_1036")
	_assert(task_text.contains(NEXT_TASK), "Task names first-contact playability follow-up")
	_assert(status_text.contains("TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish"), "Implementation status tracks TASK_1036")
	_assert(roadmap_text.contains("TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish (implementiert"), "Roadmap marks TASK_1036 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish (TASK_1036)"), "Mission feedback contract documents TASK_1036")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish (TASK_1036)"), "Decision clarity contract documents TASK_1036")
	_assert(service_text.contains(SCHEMA), "First-contact polish service exposes stable TASK_1036 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1036\""), "First-contact polish service writes TASK_1036 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1035\""), "First-contact polish service links TASK_1035")
	_assert(service_text.contains("\"first_contact_player_feel_surface_specs\""), "First-contact polish exposes surface specs")
	_assert(service_text.contains("\"first_contact_player_feel_polish_line\""), "First-contact polish exposes compact line")
	_assert(service_text.contains("\"first_contact_next_grip_line\""), "First-contact polish exposes next-grip line")
	_assert(service_text.contains("\"first_contact_go_boundary_microcopy\""), "First-contact polish exposes GO-boundary microcopy")
	_assert(service_text.contains("\"first_contact_calm_hud_guidance\""), "First-contact polish exposes calm HUD guidance")
	_assert(service_text.contains("\"creates_command\": false"), "First-contact polish creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "First-contact polish creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_FIRST_CONTACT_PLAYER_FEEL_POLISH_SCRIPT"), "Controller preloads TASK_1036 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish_snapshot"), "Controller exposes TASK_1036 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish_line"), "Command feedback exports TASK_1036 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_surface_specs"), "Command feedback exports TASK_1036 surface specs")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1036")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_polishable"), "Missing source reports non-polishable source")
	_assert(_snapshot_is_read_only(snapshot), "Blocked first-contact polish snapshot remains read-only")


func _test_rework_source_builds_first_contact_polish_surfaces() -> void:
	var snapshot: Dictionary = _build_snapshot(_rework_source())
	var specs: Array = Array(snapshot.get("first_contact_player_feel_surface_specs", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1036")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1036", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1035", "Snapshot links TASK_1035")
	_assert(String(snapshot.get("status", "")) == "first_contact_player_feel_polish_ready", "Rework source builds first-contact polish")
	_assert(bool(snapshot.get("active", false)), "First-contact polish is active")
	_assert(int(snapshot.get("first_contact_player_feel_surface_spec_count", 0)) == 6, "First-contact polish has six surface specs")
	_assert(String(snapshot.get("first_contact_player_feel_polish_line", "")).contains("CONTACT"), "Polish line names CONTACT")
	_assert(String(snapshot.get("first_contact_player_feel_polish_line", "")).contains("WHY"), "Polish line names WHY")
	_assert(String(snapshot.get("first_contact_player_feel_polish_line", "")).contains("GO"), "Polish line names GO")
	_assert(String(snapshot.get("first_contact_next_grip_line", "")).contains("NEXT"), "Next-grip line names NEXT")
	_assert(String(snapshot.get("first_contact_go_boundary_microcopy", "")).contains("GO"), "GO microcopy names GO")
	_assert(String(snapshot.get("first_contact_calm_hud_guidance", "")).contains("HUD"), "Calm HUD guidance names HUD")
	_assert(String(Dictionary(snapshot.get("contact_surface", {})).get("text", "")).contains("CONTACT"), "Contact surface answers contact-line friction")
	_assert(String(Dictionary(snapshot.get("why_surface", {})).get("text", "")).contains("WHY"), "WHY surface answers why/actionability friction")
	_assert(String(Dictionary(snapshot.get("next_surface", {})).get("text", "")).contains("NEXT"), "NEXT surface keeps next token")
	_assert(String(Dictionary(snapshot.get("feedback_surface", {})).get("text", "")).contains("Feedback"), "Feedback surface answers dry feedback")
	_assert(String(Dictionary(snapshot.get("go_boundary_surface", {})).get("text", "")).contains("GO"), "GO surface answers GO boundary")
	_assert(_surface_specs_are_polished(specs), "First-contact surface specs are polished")
	_assert(bool(snapshot.get("ready_for_first_contact_playability_review", false)), "First-contact polish is ready for playability review")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "First-contact polish recommends playability slice")
	_assert(_snapshot_is_read_only(snapshot), "First-contact polish remains read-only")


func _test_accepted_source_still_builds_playability_ready_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_accepted_source())
	_assert(String(snapshot.get("status", "")) == "first_contact_player_feel_polish_ready", "Accepted source still builds first-contact polish")
	_assert(String(snapshot.get("source_status", "")) == "accepted_for_first_contact_playability_slice", "Accepted source status is recorded")
	_assert(int(snapshot.get("source_issue_count", -1)) == 0, "Accepted source issue count is recorded")
	_assert(String(snapshot.get("first_contact_player_feel_polish_line", "")).contains("rund"), "Accepted polish keeps round feel")
	_assert(bool(snapshot.get("ready_for_first_contact_playability_review", false)), "Accepted polish is ready for playability review")
	_assert(String(snapshot.get("recommended_direction", "")) == "build_first_contact_playability_slice", "Accepted polish recommends playability direction")
	_assert(_snapshot_is_read_only(snapshot), "Accepted first-contact polish remains read-only")


func _test_controller_exports_first_contact_player_feel_polish() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish_snapshot"):
		_assert(false, "Controller exposes TASK_1036 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish_snapshot(_rework_source())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1036 schema matches")
	_assert(int(snapshot.get("first_contact_player_feel_surface_spec_count", 0)) == 6, "Controller TASK_1036 has six specs")
	_assert(String(snapshot.get("first_contact_player_feel_polish_line", "")).contains("WHY"), "Controller TASK_1036 line names WHY")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1036 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish"), "Command feedback embeds TASK_1036")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish_line"), "Command feedback exports TASK_1036 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_surface_specs"), "Command feedback exports TASK_1036 specs")
	controller.queue_free()


func _test_first_contact_player_feel_polish_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_rework_source())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1036 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1036", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1035", "Roundtrip keeps TASK_1035 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_findings: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1036 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1036 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_findings)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1036 service returns dictionary")
	return _read_only_fallback()


func _rework_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1035",
		"source_task_id": "TASK_1034",
		"status": "first_contact_player_feel_rework_needed",
		"gate": "first_contact_player_feel_rework_needed",
		"source_smoke_line": "CONTACT SMOKE PASS: CONTACT | WHY | NEXT | GO separat | FEEDBACK sichtbar",
		"first_contact_player_feel_summary_line": "FIRST CONTACT FEEL REWORK: WHY und GO-Grenze fuehlen sich noch nicht handlungsfaehig an.",
		"positive_findings": ["first_contact_runtime_smoke_passed", "hud_feels_calm", "multiplayer_boundary_feels_clear"],
		"issue_count": 4,
		"issues": [
			{"id": "contact_line_feels_unclear", "text": "CONTACT-Line liest sich im Spielerblick noch nicht klar genug."},
			{"id": "why_not_actionable", "text": "WHY erklaert noch nicht handlungsfaehig, warum der Kontakt wichtig ist."},
			{"id": "first_contact_feedback_feels_dry", "text": "Feedback fuehrt noch nicht angenehm zum naechsten Kontaktgriff zurueck."},
			{"id": "go_boundary_not_felt", "text": "GO-Grenze fuehlt sich im ersten Kontakt noch nicht sicher getrennt an."},
		],
		"review_available": true,
		"ready_for_first_contact_playability_slice": false,
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
	var source: Dictionary = _rework_source()
	source["status"] = "accepted_for_first_contact_playability_slice"
	source["gate"] = "first_contact_player_feel_accepted"
	source["issue_count"] = 0
	source["issues"] = []
	source["ready_for_first_contact_playability_slice"] = true
	source["first_contact_player_feel_summary_line"] = "FIRST CONTACT FEEL PASS: CONTACT, WHY, NEXT, GO und Feedback fuehlen sich rund an."
	source["positive_findings"] = [
		"first_contact_runtime_smoke_passed",
		"contact_line_feels_clear",
		"why_feels_actionable",
		"next_grip_feels_clear",
		"go_boundary_feels_safe",
		"feedback_invites_next_grip",
		"hud_feels_calm",
		"performance_feels_responsive",
		"multiplayer_boundary_feels_clear",
		"first_contact_feels_tactical",
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


func _read_only_fallback() -> Dictionary:
	return {
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


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
