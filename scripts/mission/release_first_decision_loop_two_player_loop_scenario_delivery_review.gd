class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioDeliveryReview
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_delivery_review.v1"
const TASK_ID: String = "TASK_1028"
const SOURCE_TASK_ID: String = "TASK_1027"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke.v1"
const REVIEW_TASK: String = "TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Review"
const POLISH_TASK: String = "TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Polish"
const NEXT_TASK: String = "TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Packet"

const REQUIRED_DELIVERY_REVIEW_CHECKS: Array[String] = [
	"visible_ship_smoke_passed",
	"release_files_named",
	"start_instruction_written",
	"known_risks_reviewed",
	"known_risks_accepted",
	"shortcut_warning_written",
	"multiplayer_boundary_preserved",
	"hud_truth_boundary_preserved",
	"next_handoff_task_chosen",
]

const ISSUE_FLAG_IDS: Array[String] = [
	"stale_delivery_package",
	"release_files_missing",
	"start_instruction_unclear",
	"risks_not_accepted",
	"visible_polish_needed",
	"handoff_not_ready",
]


static func build_snapshot(source_visible_smoke: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_visible_smoke)
	var review_available: bool = bool(review_notes.get("review_available", false)) or not review_notes.is_empty()
	var delivery_review_done: bool = bool(review_notes.get("delivery_review_done", false))
	var completed_checks: Array = Array(review_notes.get("completed_delivery_review_checks", [])).duplicate(true)
	var missing_checks: Array = _missing_checks(completed_checks)
	var active_issue_flags: Array = _active_issue_flags(review_notes)
	var issues: Array = []
	var status: String = "blocked_until_visible_ship_smoke"
	var gate: String = "blocked_until_visible_ship_smoke"
	var delivery_review_ready: bool = false
	var ready_for_handoff_packet: bool = false
	var recommended_next_task: String = REVIEW_TASK
	var recommended_direction: String = "fix_visible_ship_smoke_source"

	if blockers.is_empty():
		if not review_available:
			status = "needs_delivery_review"
			gate = "needs_delivery_review"
			issues.append(_issue("delivery_review_notes_missing", "Delivery-Review-Notizen fuer TASK_1028 fehlen."))
			recommended_direction = "write_delivery_review"
		else:
			issues = _build_review_issues(delivery_review_done, missing_checks, active_issue_flags, review_notes)
			if not active_issue_flags.is_empty():
				status = "delivery_review_regression_found"
				gate = "delivery_review_regression_found"
				recommended_next_task = POLISH_TASK
				recommended_direction = "polish_delivery_review_regressions"
			elif not issues.is_empty():
				status = "needs_delivery_review_completion"
				gate = "needs_delivery_review_completion"
				recommended_direction = "complete_delivery_review_checks"
			else:
				status = "delivery_review_ready"
				gate = "delivery_review_ready"
				delivery_review_ready = true
				ready_for_handoff_packet = true
				recommended_next_task = NEXT_TASK
				recommended_direction = "cut_handoff_packet"

	var all_issues: Array = blockers + issues
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_visible_smoke.get("schema", "")),
		"source_status": String(source_visible_smoke.get("status", "")),
		"source_gate": String(source_visible_smoke.get("gate", "")),
		"source_visible_ship_smoke_line": String(source_visible_smoke.get("visible_ship_smoke_line", "")),
		"source_visible_ship_smoke_passed": bool(source_visible_smoke.get("visible_ship_smoke_passed", false)),
		"source_ready_for_delivery_review": bool(source_visible_smoke.get("ready_for_delivery_review", false)),
		"release_build_path": String(source_visible_smoke.get("release_build_path", "")),
		"pck_path": String(source_visible_smoke.get("pck_path", "")),
		"scenario_id": String(source_visible_smoke.get("scenario_id", "")),
		"tester_instructions": String(source_visible_smoke.get("tester_instructions", "")),
		"operator_goal": String(source_visible_smoke.get("operator_goal", "")),
		"known_risks": Array(source_visible_smoke.get("known_risks", [])).duplicate(true),
		"review_available": review_available,
		"manual_delivery_review_required": true,
		"delivery_review_done": delivery_review_done,
		"delivery_notes": _delivery_notes(review_notes),
		"required_delivery_review_checks": REQUIRED_DELIVERY_REVIEW_CHECKS.duplicate(),
		"completed_delivery_review_checks": completed_checks,
		"missing_delivery_review_checks": missing_checks,
		"missing_delivery_review_check_count": missing_checks.size(),
		"issue_flags": active_issue_flags,
		"active_issue_count": active_issue_flags.size(),
		"delivery_review_line": _build_delivery_review_line(status, source_visible_smoke, review_notes),
		"delivery_review_ready": delivery_review_ready,
		"ready_for_handoff_packet": ready_for_handoff_packet,
		"status": status,
		"gate": gate,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(all_issues[0]).get("id", "")) if not all_issues.is_empty() else "",
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
		blockers.append(_issue("source_schema_mismatch", "TASK_1027-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1027."))
	if String(source.get("status", "")) != "visible_ship_smoke_passed":
		blockers.append(_issue("source_visible_smoke_not_passed", "TASK_1027-Source ist nicht visible_ship_smoke_passed."))
	if not bool(source.get("visible_ship_smoke_passed", false)):
		blockers.append(_issue("source_visible_smoke_not_passed", "TASK_1027-Visible-Smoke-Flag fehlt."))
	if not bool(source.get("ready_for_delivery_review", false)):
		blockers.append(_issue("source_not_ready_for_delivery_review", "TASK_1027 gibt den Delivery-Review noch nicht frei."))
	var line: String = String(source.get("visible_ship_smoke_line", "")).strip_edges()
	if line.is_empty():
		blockers.append(_issue("source_visible_smoke_line_missing", "TASK_1027-Visible-Smoke-Line fehlt."))
	elif not (line.contains("FOB") and line.contains("NEXT") and line.contains("GO") and line.contains("FEEDBACK")):
		blockers.append(_issue("source_visible_smoke_line_incomplete", "TASK_1027-Line nennt FOB/NEXT/GO/FEEDBACK nicht gemeinsam."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1027-Source verletzt die read-only-Grenze."))
	return _dedupe_issues(blockers)


static func _build_review_issues(delivery_review_done: bool, missing_checks: Array, issue_flags: Array, review_notes: Dictionary) -> Array:
	var issues: Array = []
	var ids := {}
	if not delivery_review_done:
		_append_issue_once(issues, ids, "manual_delivery_review_open", "Delivery Review ist noch nicht manuell abgeschlossen.")
	if not missing_checks.is_empty():
		_append_issue_once(issues, ids, "delivery_review_checks_missing", "Delivery-Review-Checks fehlen: %s." % ", ".join(PackedStringArray(missing_checks)))
	for issue_id in issue_flags:
		_append_issue_once(issues, ids, "delivery_review_issue_%s" % String(issue_id), _issue_text(String(issue_id)))
	if bool(review_notes.get("ui_sets_gameplay_truth", false)):
		_append_issue_once(issues, ids, "review_ui_gameplay_truth_risk", "Delivery Review darf keine UI-Gameplay-Wahrheit setzen.")
	if bool(review_notes.get("creates_command", false)):
		_append_issue_once(issues, ids, "review_create_command", "Delivery Review darf keinen Command erzeugen.")
	if bool(review_notes.get("creates_movement", false)):
		_append_issue_once(issues, ids, "review_create_movement", "Delivery Review darf keine Bewegung erzeugen.")
	if bool(review_notes.get("sets_multiplayer_truth", false)):
		_append_issue_once(issues, ids, "review_set_multiplayer_truth", "Delivery Review darf keine Multiplayer-Wahrheit setzen.")
	return issues


static func _active_issue_flags(review_notes: Dictionary) -> Array:
	var active: Array = []
	for issue_id in Array(review_notes.get("issue_flags", [])):
		var normalized: String = String(issue_id)
		if ISSUE_FLAG_IDS.has(normalized):
			active.append(normalized)
	return active


static func _missing_checks(completed_checks: Array) -> Array:
	var completed := {}
	for check_variant in completed_checks:
		completed[String(check_variant)] = true
	var missing: Array = []
	for check_id in REQUIRED_DELIVERY_REVIEW_CHECKS:
		if not completed.has(check_id):
			missing.append(check_id)
	return missing


static func _delivery_notes(review_notes: Dictionary) -> Dictionary:
	return {
		"start_instruction": String(review_notes.get("start_instruction", "")),
		"shortcut_warning": String(review_notes.get("shortcut_warning", "")),
		"risk_note": String(review_notes.get("risk_note", "")),
		"handoff_note": String(review_notes.get("handoff_note", "")),
	}


static func _build_delivery_review_line(status: String, source: Dictionary, review_notes: Dictionary) -> String:
	if status == "delivery_review_ready":
		var handoff_note: String = String(review_notes.get("handoff_note", "Handoff-Paket kann geschnitten werden.")).strip_edges()
		return "DELIVERY READY: EXE | FOB | NEXT | GO | FEEDBACK | %s" % _compact_text(handoff_note, 104)
	if status == "needs_delivery_review":
		return "DELIVERY REVIEW OFFEN: EXE | FOB | NEXT | GO | FEEDBACK muessen als Paket freigegeben werden."
	if status == "delivery_review_regression_found":
		return "DELIVERY REVIEW BLOCKIERT: EXE | FOB | NEXT | GO | FEEDBACK brauchen gezielte Politur."
	var source_line: String = String(source.get("visible_ship_smoke_line", "")).strip_edges()
	if source_line.is_empty():
		source_line = "EXE, FOB, NEXT, GO und FEEDBACK brauchen Delivery Review."
	return "DELIVERY REVIEW CHECK: EXE | FOB | NEXT | GO | FEEDBACK | %s" % _compact_text(source_line, 104)


static func _compact_text(text: String, max_length: int) -> String:
	var normalized: String = text.strip_edges()
	if normalized.length() <= max_length:
		return normalized
	return normalized.substr(0, maxi(max_length - 3, 0)).strip_edges() + "..."


static func _append_issue_once(issues: Array, ids: Dictionary, issue_id: String, text: String) -> void:
	if ids.has(issue_id):
		return
	ids[issue_id] = true
	issues.append(_issue(issue_id, text))


static func _dedupe_issues(issues: Array) -> Array:
	var result: Array = []
	var ids := {}
	for issue_variant in issues:
		if typeof(issue_variant) != TYPE_DICTIONARY:
			continue
		var issue: Dictionary = Dictionary(issue_variant)
		var issue_id: String = String(issue.get("id", ""))
		if ids.has(issue_id):
			continue
		ids[issue_id] = true
		result.append(issue)
	return result


static func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_movement", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false))


static func _issue_text(issue_id: String) -> String:
	match issue_id:
		"stale_delivery_package":
			return "Delivery-Paket verweist auf alte Dateien oder veraltete Notizen."
		"release_files_missing":
			return "Release-Dateien sind im Delivery Review nicht eindeutig benannt."
		"start_instruction_unclear":
			return "Startanweisung ist fuer den naechsten Tester nicht klar genug."
		"risks_not_accepted":
			return "Bekannte Risiken wurden nicht akzeptiert oder nicht benannt."
		"visible_polish_needed":
			return "Der sichtbare Spielmoment braucht vor der Uebergabe noch Politur."
		"handoff_not_ready":
			return "Handoff-Paket ist noch nicht bereit."
	return issue_id


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
