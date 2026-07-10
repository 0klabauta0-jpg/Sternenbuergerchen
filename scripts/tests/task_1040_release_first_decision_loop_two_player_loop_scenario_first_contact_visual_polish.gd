extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1040_release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings.v1"
const NEXT_TASK := "TASK_1041 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1040 Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_issue_source_builds_first_contact_surfaces()
	_test_accepted_source_still_exports_polish_contract()
	_test_controller_exports_first_contact_visual_polish()
	_test_first_contact_visual_polish_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1040_release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish: FAILED")
		quit(1)
		return
	print("TASK_1040_release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1040 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1040 first-contact visual polish service exists")
	_assert(task_text.contains("TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish"), "Task names TASK_1040")
	_assert(task_text.contains(NEXT_TASK), "Task names first-contact acceptance follow-up")
	_assert(status_text.contains("TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish"), "Implementation status tracks TASK_1040")
	_assert(roadmap_text.contains("TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish (implementiert"), "Roadmap marks TASK_1040 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish (TASK_1040)"), "Mission feedback contract documents TASK_1040")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish (TASK_1040)"), "Decision clarity contract documents TASK_1040")
	_assert(service_text.contains(SCHEMA), "First-contact visual polish service exposes stable TASK_1040 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1040\""), "First-contact visual polish service writes TASK_1040 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1039\""), "First-contact visual polish service links TASK_1039")
	_assert(service_text.contains("\"first_contact_visual_surface_specs\""), "First-contact visual polish exposes surface specs")
	_assert(service_text.contains("\"contact_surface\""), "First-contact visual polish exposes CONTACT surface")
	_assert(service_text.contains("\"why_surface\""), "First-contact visual polish exposes WHY surface")
	_assert(service_text.contains("\"next_surface\""), "First-contact visual polish exposes NEXT surface")
	_assert(service_text.contains("\"fire_wait_surface\""), "First-contact visual polish exposes FIRE/WAIT surface")
	_assert(service_text.contains("\"feedback_surface\""), "First-contact visual polish exposes FEEDBACK surface")
	_assert(service_text.contains("\"go_boundary_surface\""), "First-contact visual polish exposes GO surface")
	_assert(service_text.contains("\"hud_multiplayer_surface\""), "First-contact visual polish exposes HUD/MP surface")
	_assert(service_text.contains("\"creates_command\": false"), "First-contact visual polish creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "First-contact visual polish creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_FIRST_CONTACT_VISUAL_POLISH_SCRIPT"), "Controller preloads TASK_1040 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish_snapshot"), "Controller exposes TASK_1040 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish_line"), "Command feedback exports TASK_1040 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_visual_surface_specs"), "Command feedback exports TASK_1040 surface specs")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1040")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_polishable"), "Missing source reports non-polishable source")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_issue_source_builds_first_contact_surfaces() -> void:
	var snapshot: Dictionary = _build_snapshot(_issue_source())
	var specs: Array = Array(snapshot.get("first_contact_visual_surface_specs", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1040")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1040", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1039", "Snapshot links TASK_1039")
	_assert(String(snapshot.get("status", "")) == "first_contact_visual_polish_ready", "Issue source builds first-contact polish")
	_assert(bool(snapshot.get("active", false)), "First-contact visual polish is active")
	_assert(int(snapshot.get("first_contact_visual_surface_spec_count", 0)) == 7, "First-contact visual polish has seven surface specs")
	_assert(String(snapshot.get("first_contact_visual_polish_line", "")).contains("CONTACT"), "Polish line names CONTACT")
	_assert(String(snapshot.get("first_contact_visual_polish_line", "")).contains("FIRE/WAIT"), "Polish line names FIRE/WAIT")
	_assert(String(snapshot.get("first_contact_visual_polish_line", "")).contains("GO"), "Polish line names GO")
	_assert(String(Dictionary(snapshot.get("contact_surface", {})).get("text", "")).contains("CONTACT"), "CONTACT surface keeps token")
	_assert(String(Dictionary(snapshot.get("why_surface", {})).get("text", "")).contains("WHY"), "WHY surface keeps token")
	_assert(String(Dictionary(snapshot.get("next_surface", {})).get("text", "")).contains("NEXT"), "NEXT surface keeps token")
	_assert(String(Dictionary(snapshot.get("fire_wait_surface", {})).get("text", "")).contains("FIRE/WAIT"), "FIRE/WAIT surface keeps token")
	_assert(String(Dictionary(snapshot.get("feedback_surface", {})).get("text", "")).contains("Feedback"), "Feedback surface keeps readable feedback")
	_assert(String(Dictionary(snapshot.get("go_boundary_surface", {})).get("text", "")).contains("GO"), "GO surface keeps token")
	_assert(String(Dictionary(snapshot.get("hud_multiplayer_surface", {})).get("text", "")).contains("HUD"), "HUD/MP surface keeps boundary")
	_assert(String(snapshot.get("first_contact_fire_wait_microcopy", "")).contains("FIRE/WAIT"), "Fire/wait microcopy is exported")
	_assert(String(snapshot.get("first_contact_go_boundary_microcopy", "")).contains("GO"), "GO microcopy is exported")
	_assert(_surface_specs_are_polished(specs), "First-contact visual surface specs are polished")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "First-contact polish recommends acceptance slice")
	_assert(_snapshot_is_read_only(snapshot), "First-contact visual polish remains read-only")


func _test_accepted_source_still_exports_polish_contract() -> void:
	var snapshot: Dictionary = _build_snapshot(_accepted_source())
	_assert(String(snapshot.get("status", "")) == "first_contact_visual_polish_ready", "Accepted source keeps first-contact polish ready")
	_assert(String(snapshot.get("source_status", "")) == "accepted_for_first_contact_acceptance_slice", "Accepted source status is recorded")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Accepted source recommends acceptance slice")
	_assert(String(snapshot.get("recommended_direction", "")) == "build_first_contact_acceptance_slice", "Accepted source recommends acceptance direction")
	_assert(_snapshot_is_read_only(snapshot), "Accepted polish remains read-only")


func _test_controller_exports_first_contact_visual_polish() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish_snapshot"):
		_assert(false, "Controller exposes TASK_1040 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish_snapshot(_issue_source())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1040 schema matches")
	_assert(int(snapshot.get("first_contact_visual_surface_spec_count", 0)) == 7, "Controller TASK_1040 has seven specs")
	_assert(String(snapshot.get("first_contact_visual_polish_line", "")).contains("WHY"), "Controller TASK_1040 line names WHY")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1040 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish"), "Command feedback embeds TASK_1040")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish_line"), "Command feedback exports TASK_1040 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_visual_surface_specs"), "Command feedback exports TASK_1040 specs")
	controller.queue_free()


func _test_first_contact_visual_polish_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_issue_source())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1040 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1040", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1039", "Roundtrip keeps TASK_1039 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_findings: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1040 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1040 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_findings)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1040 service returns dictionary")
	return _read_only_fallback()


func _issue_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1039",
		"source_task_id": "TASK_1038",
		"status": "ready_for_first_contact_visual_polish",
		"first_contact_visual_findings_summary_line": "FIRST CONTACT VISUAL POLISH: CONTACT und WHY brauchen mehr Gewicht.",
		"source_first_contact_playability_line": "FIRST CONTACT PASS: CONTACT rund | WHY klar | NEXT bereit | GO separat | FIRE/WAIT lesbar",
		"issue_count": 4,
		"issues": [
			{"id": "contact_surface_not_visible", "text": "CONTACT braucht mehr Gewicht."},
			{"id": "why_surface_not_actionable", "text": "WHY muss handlungsfaehiger werden."},
			{"id": "fire_wait_choice_not_visible", "text": "FIRE/WAIT braucht klare Wahlflaeche."},
			{"id": "feedback_line_not_visible", "text": "Feedback muss sichtbar werden."},
		],
		"positive_findings": [
			{"id": "next_surface_visible", "text": "NEXT bleibt sichtbar."},
			{"id": "go_boundary_visible", "text": "GO separat ist sichtbar."},
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
	source["status"] = "accepted_for_first_contact_acceptance_slice"
	source["issue_count"] = 0
	source["issues"] = []
	source["first_contact_visual_findings_summary_line"] = "FIRST CONTACT VISUAL PASS: CONTACT | WHY | NEXT | FIRE/WAIT | FEEDBACK | GO separat"
	source["accepted"] = true
	source["ready_for_first_contact_acceptance_slice"] = true
	return source


func _surface_specs_are_polished(specs: Array) -> bool:
	if specs.size() != 7:
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
		if float(spec.get("min_height", 0.0)) < 28.0:
			return false
		if int(spec.get("max_lines", 0)) < 1:
			return false
		if int(spec.get("line_budget", 0)) < 44:
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
