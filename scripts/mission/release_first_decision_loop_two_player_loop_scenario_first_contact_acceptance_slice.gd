class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactAcceptanceSlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice.v1"
const TASK_ID: String = "TASK_1041"
const SOURCE_TASK_ID: String = "TASK_1040"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish.v1"
const REVIEW_TASK: String = "TASK_1041 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice"
const POLISH_TASK: String = "TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish"
const NEXT_TASK: String = "TASK_1042 - Release First Decision Loop Two Player Loop Scenario First Contact Integrated Playtest"

const REQUIRED_ACCEPTANCE_CHECKS: PackedStringArray = [
	"contact_readable",
	"why_actionable",
	"next_visible",
	"fire_wait_choice_clear",
	"feedback_returns_to_next",
	"go_boundary_clear",
	"hud_calm",
	"performance_feels_responsive",
	"multiplayer_boundary_preserved",
	"no_new_hud_gameplay_truth",
]


static func build_snapshot(source_polish: Dictionary, acceptance_trace: Dictionary = {}) -> Dictionary:
	var source: Dictionary = source_polish.duplicate(true)
	var trace: Dictionary = acceptance_trace.duplicate(true)
	var blockers: Array = _build_source_blockers(source)
	var trace_available: bool = bool(trace.get("trace_available", false)) or not trace.is_empty()
	var issues: Array = []
	if blockers.is_empty():
		if not trace_available:
			issues.append(_issue("first_contact_acceptance_trace_missing", "TASK_1041-Acceptance-Trace fuer den First-Contact-Griff fehlt."))
		else:
			issues = _build_trace_issues(trace)
	var passed: bool = blockers.is_empty() and trace_available and issues.is_empty()
	var status: String = "blocked"
	var gate: String = "blocked"
	var recommended_next_task: String = POLISH_TASK
	var recommended_direction: String = "fix_first_contact_acceptance_source"
	if blockers.is_empty():
		if passed:
			status = "first_contact_acceptance_slice_passed"
			gate = "first_contact_acceptance_slice_passed"
			recommended_next_task = NEXT_TASK
			recommended_direction = "run_first_contact_integrated_playtest"
		elif trace_available:
			status = "first_contact_acceptance_regression_found"
			gate = "first_contact_acceptance_regression_found"
			recommended_next_task = POLISH_TASK
			recommended_direction = "tighten_first_contact_visual_polish"
		else:
			status = "needs_first_contact_acceptance_trace"
			gate = "needs_first_contact_acceptance_trace"
			recommended_next_task = REVIEW_TASK
			recommended_direction = "run_first_contact_acceptance_trace"
	var answered_questions: Array = Array(trace.get("answered_player_questions", [])).duplicate(true)
	var completed_checks: Array = Array(trace.get("completed_checks", [])).duplicate(true)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source.get("schema", "")),
		"source_status": String(source.get("status", "")),
		"source_polish_line": String(source.get("first_contact_visual_polish_line", "")),
		"source_next_line": String(source.get("first_contact_next_line", "")),
		"source_fire_wait_microcopy": String(source.get("first_contact_fire_wait_microcopy", "")),
		"source_go_boundary_microcopy": String(source.get("first_contact_go_boundary_microcopy", "")),
		"source_surface_spec_count": int(source.get("first_contact_visual_surface_spec_count", 0)),
		"source_surface_specs": Array(source.get("first_contact_visual_surface_specs", [])).duplicate(true),
		"trace_available": trace_available,
		"required_acceptance_checks": Array(REQUIRED_ACCEPTANCE_CHECKS),
		"completed_checks": completed_checks,
		"missing_acceptance_checks": _missing_checks(completed_checks),
		"contact_readable": bool(trace.get("contact_readable", false)),
		"why_actionable": bool(trace.get("why_actionable", false)),
		"next_visible": bool(trace.get("next_visible", false)),
		"fire_wait_choice_clear": bool(trace.get("fire_wait_choice_clear", false)),
		"feedback_returns_to_next": bool(trace.get("feedback_returns_to_next", false)),
		"go_boundary_clear": bool(trace.get("go_boundary_clear", false)),
		"hud_calm": bool(trace.get("hud_calm", false)),
		"performance_feels_responsive": bool(trace.get("performance_feels_responsive", false)),
		"multiplayer_boundary_preserved": bool(trace.get("multiplayer_boundary_preserved", false)),
		"no_new_hud_gameplay_truth": bool(trace.get("no_new_hud_gameplay_truth", false)),
		"answered_player_questions": answered_questions,
		"answered_player_question_count": answered_questions.size(),
		"first_contact_acceptance_line": _build_acceptance_line(source, passed, trace_available),
		"first_contact_acceptance_slice_passed": passed,
		"ready_for_first_contact_integrated_playtest": passed,
		"status": status,
		"gate": gate,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"recommended_next_task": recommended_next_task,
		"recommended_direction": recommended_direction,
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


static func _build_source_blockers(source: Dictionary) -> Array:
	var blockers: Array = []
	if String(source.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1040-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1040."))
	if String(source.get("status", "")) != "first_contact_visual_polish_ready":
		blockers.append(_issue("source_not_ready_for_first_contact_acceptance", "TASK_1040-Source ist nicht first_contact_visual_polish_ready."))
	if int(source.get("first_contact_visual_surface_spec_count", 0)) != 7:
		blockers.append(_issue("source_surface_specs_incomplete", "TASK_1040 muss sieben First-Contact-Surface-Specs liefern."))
	var polish_line: String = String(source.get("first_contact_visual_polish_line", "")).strip_edges()
	if polish_line.is_empty():
		blockers.append(_issue("source_polish_line_missing", "TASK_1040-Polish-Line fehlt."))
	if not polish_line.contains("CONTACT") or not polish_line.contains("WHY") or not polish_line.contains("NEXT") or not polish_line.contains("FIRE/WAIT") or not polish_line.contains("GO"):
		blockers.append(_issue("source_polish_line_incomplete", "TASK_1040-Polish-Line muss CONTACT, WHY, NEXT, FIRE/WAIT und GO nennen."))
	if String(source.get("first_contact_fire_wait_microcopy", "")).strip_edges().is_empty():
		blockers.append(_issue("source_fire_wait_microcopy_missing", "TASK_1040-FIRE/WAIT-Microcopy fehlt."))
	if String(source.get("first_contact_go_boundary_microcopy", "")).strip_edges().is_empty():
		blockers.append(_issue("source_go_microcopy_missing", "TASK_1040-GO-Microcopy fehlt."))
	if not _surface_specs_are_read_only(Array(source.get("first_contact_visual_surface_specs", []))):
		blockers.append(_issue("source_surface_specs_not_read_only", "TASK_1040-Surface-Specs verletzen read-only oder Command-Grenzen."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1040-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_trace_issues(trace: Dictionary) -> Array:
	var issues: Array = []
	if not bool(trace.get("contact_readable", false)):
		issues.append(_issue("contact_not_readable", "CONTACT ist im Acceptance-Trace nicht lesbar."))
	if not bool(trace.get("why_actionable", false)):
		issues.append(_issue("why_not_actionable", "WHY ist im Acceptance-Trace nicht handlungsfaehig."))
	if not bool(trace.get("next_visible", false)):
		issues.append(_issue("next_not_visible", "NEXT ist im Acceptance-Trace nicht sichtbar."))
	if not bool(trace.get("fire_wait_choice_clear", false)):
		issues.append(_issue("fire_wait_choice_unclear", "FIRE/WAIT ist im Trace keine klare Wahl."))
	if not bool(trace.get("feedback_returns_to_next", false)):
		issues.append(_issue("feedback_does_not_return_to_next", "Feedback fuehrt nicht sichtbar zu NEXT zurueck."))
	if not bool(trace.get("go_boundary_clear", false)):
		issues.append(_issue("go_boundary_unclear", "GO-Grenze ist im Acceptance-Trace nicht klar."))
	if not bool(trace.get("hud_calm", false)):
		issues.append(_issue("hud_not_calm", "HUD wirkt im Acceptance-Trace nicht ruhig."))
	if not bool(trace.get("performance_feels_responsive", false)):
		issues.append(_issue("performance_feels_sluggish", "First-Contact-Griff fuehlt sich nicht responsiv an."))
	if not bool(trace.get("multiplayer_boundary_preserved", false)):
		issues.append(_issue("multiplayer_boundary_risk", "Multiplayer-Grenze ist nicht belegt."))
	if not bool(trace.get("no_new_hud_gameplay_truth", false)):
		issues.append(_issue("hud_gameplay_truth_risk", "HUD-read-only-Grenze ist nicht belegt."))
	if Array(trace.get("answered_player_questions", [])).size() < 7:
		issues.append(_issue("player_question_coverage_too_low", "Zu wenige First-Contact-Spielerfragen sind im Trace beantwortet."))
	if bool(trace.get("ui_sets_gameplay_truth", false)):
		issues.append(_issue("ui_sets_gameplay_truth", "Trace meldet UI-Gameplay-Wahrheit."))
	if bool(trace.get("creates_command", false)):
		issues.append(_issue("trace_creates_command", "Trace darf keinen Command erzeugen."))
	if bool(trace.get("creates_movement", false)):
		issues.append(_issue("trace_creates_movement", "Trace darf kein Movement erzeugen."))
	if bool(trace.get("sets_multiplayer_truth", false)):
		issues.append(_issue("trace_sets_multiplayer_truth", "Trace darf keine Multiplayer-Wahrheit setzen."))
	return issues


static func _missing_checks(completed_checks: Array) -> Array:
	var completed := {}
	for check_variant in completed_checks:
		completed[String(check_variant)] = true
	var missing: Array = []
	for check_id in REQUIRED_ACCEPTANCE_CHECKS:
		if not completed.has(String(check_id)):
			missing.append(String(check_id))
	return missing


static func _surface_specs_are_read_only(specs: Array) -> bool:
	if specs.size() != 7:
		return false
	for spec_variant in specs:
		if typeof(spec_variant) != TYPE_DICTIONARY:
			return false
		var spec := Dictionary(spec_variant)
		if not bool(spec.get("read_only", false)):
			return false
		if bool(spec.get("ui_sets_gameplay_truth", true)):
			return false
		if bool(spec.get("creates_command", true)) or bool(spec.get("creates_movement", true)):
			return false
		if String(spec.get("surface_id", "")).strip_edges().is_empty() or String(spec.get("text", "")).strip_edges().is_empty():
			return false
	return true


static func _build_acceptance_line(source: Dictionary, passed: bool, trace_available: bool) -> String:
	var base: String = String(source.get("first_contact_visual_polish_line", "")).strip_edges()
	if base.is_empty():
		base = "CONTACT | WHY | NEXT | FIRE/WAIT | GO separat"
	if not base.contains("CONTACT"):
		base = "CONTACT | %s" % base
	if not base.contains("WHY"):
		base = "%s | WHY" % base
	if not base.contains("NEXT"):
		base = "%s | NEXT" % base
	if not base.contains("FIRE/WAIT"):
		base = "%s | FIRE/WAIT" % base
	if not base.contains("GO"):
		base = "%s | GO separat" % base
	if not trace_available:
		return "%s | Acceptance offen" % _compact_text(base, 112)
	var result_text: String = "PASS" if passed else "CHECK"
	return "%s | %s" % [_compact_text(base, 112), result_text]


static func _compact_text(text: String, max_length: int) -> String:
	var normalized: String = text.strip_edges()
	if normalized.length() <= max_length:
		return normalized
	return normalized.substr(0, maxi(max_length - 3, 0)).strip_edges() + "..."


static func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_movement", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false))


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
