class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioHandoffPacket
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_handoff_packet.v1"
const TASK_ID: String = "TASK_1029"
const SOURCE_TASK_ID: String = "TASK_1028"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_delivery_review.v1"
const REVIEW_TASK: String = "TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Packet"
const POLISH_TASK: String = "TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Polish"
const NEXT_TASK: String = "TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run"

const REQUIRED_HANDOFF_PACKET_ITEMS: Array[String] = [
	"delivery_review_ready",
	"release_files_named",
	"start_instruction_written",
	"shortcut_warning_written",
	"risk_summary_written",
	"next_tester_action_written",
	"multiplayer_boundary_preserved",
	"hud_truth_boundary_preserved",
]

const ISSUE_FLAG_IDS: Array[String] = [
	"stale_handoff_package",
	"release_files_unclear",
	"start_steps_unclear",
	"risks_unaccepted",
	"visible_polish_needed",
	"handoff_not_testable",
]


static func build_snapshot(source_delivery_review: Dictionary, handoff_packet_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_delivery_review)
	var packet_available: bool = bool(handoff_packet_notes.get("handoff_packet_available", false)) or not handoff_packet_notes.is_empty()
	var handoff_packet_done: bool = bool(handoff_packet_notes.get("handoff_packet_done", false))
	var completed_items: Array = Array(handoff_packet_notes.get("completed_handoff_packet_items", [])).duplicate(true)
	var missing_items: Array = _missing_items(completed_items)
	var active_issue_flags: Array = _active_issue_flags(handoff_packet_notes)
	var issues: Array = []
	var status: String = "blocked_until_delivery_review"
	var gate: String = "blocked_until_delivery_review"
	var handoff_packet_ready: bool = false
	var ready_for_tester_run: bool = false
	var recommended_next_task: String = REVIEW_TASK
	var recommended_direction: String = "fix_delivery_review_source"

	if blockers.is_empty():
		if not packet_available:
			status = "needs_handoff_packet"
			gate = "needs_handoff_packet"
			issues.append(_issue("handoff_packet_notes_missing", "Handoff-Packet-Notizen fuer TASK_1029 fehlen."))
			recommended_direction = "write_handoff_packet"
		else:
			issues = _build_packet_issues(handoff_packet_done, missing_items, active_issue_flags, handoff_packet_notes)
			if not active_issue_flags.is_empty():
				status = "handoff_packet_regression_found"
				gate = "handoff_packet_regression_found"
				recommended_next_task = POLISH_TASK
				recommended_direction = "polish_handoff_packet_regressions"
			elif not issues.is_empty():
				status = "needs_handoff_packet_completion"
				gate = "needs_handoff_packet_completion"
				recommended_direction = "complete_handoff_packet_items"
			else:
				status = "handoff_packet_ready"
				gate = "handoff_packet_ready"
				handoff_packet_ready = true
				ready_for_tester_run = true
				recommended_next_task = NEXT_TASK
				recommended_direction = "run_tester_pass"

	var all_issues: Array = blockers + issues
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_delivery_review.get("schema", "")),
		"source_status": String(source_delivery_review.get("status", "")),
		"source_gate": String(source_delivery_review.get("gate", "")),
		"source_delivery_review_line": String(source_delivery_review.get("delivery_review_line", "")),
		"source_delivery_review_ready": bool(source_delivery_review.get("delivery_review_ready", false)),
		"source_ready_for_handoff_packet": bool(source_delivery_review.get("ready_for_handoff_packet", false)),
		"release_build_path": String(source_delivery_review.get("release_build_path", "")),
		"pck_path": String(source_delivery_review.get("pck_path", "")),
		"scenario_id": String(source_delivery_review.get("scenario_id", "")),
		"tester_instructions": String(source_delivery_review.get("tester_instructions", "")),
		"operator_goal": String(source_delivery_review.get("operator_goal", "")),
		"known_risks": Array(source_delivery_review.get("known_risks", [])).duplicate(true),
		"delivery_notes": Dictionary(source_delivery_review.get("delivery_notes", {})).duplicate(true),
		"handoff_packet_available": packet_available,
		"handoff_packet_done": handoff_packet_done,
		"handoff_notes": _handoff_notes(source_delivery_review, handoff_packet_notes),
		"test_steps": _test_steps(source_delivery_review, handoff_packet_notes),
		"required_handoff_packet_items": REQUIRED_HANDOFF_PACKET_ITEMS.duplicate(),
		"completed_handoff_packet_items": completed_items,
		"missing_handoff_packet_items": missing_items,
		"missing_handoff_packet_item_count": missing_items.size(),
		"issue_flags": active_issue_flags,
		"active_issue_count": active_issue_flags.size(),
		"handoff_packet_line": _build_handoff_packet_line(status, source_delivery_review, handoff_packet_notes),
		"handoff_packet_ready": handoff_packet_ready,
		"ready_for_tester_run": ready_for_tester_run,
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
		blockers.append(_issue("source_schema_mismatch", "TASK_1028-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1028."))
	if String(source.get("status", "")) != "delivery_review_ready":
		blockers.append(_issue("source_delivery_review_not_ready", "TASK_1028-Source ist nicht delivery_review_ready."))
	if not bool(source.get("delivery_review_ready", false)):
		blockers.append(_issue("source_delivery_review_not_ready", "TASK_1028-Delivery-Review-Flag fehlt."))
	if not bool(source.get("ready_for_handoff_packet", false)):
		blockers.append(_issue("source_not_ready_for_handoff_packet", "TASK_1028 gibt das Handoff-Packet noch nicht frei."))
	var line: String = String(source.get("delivery_review_line", "")).strip_edges()
	if line.is_empty():
		blockers.append(_issue("source_delivery_review_line_missing", "TASK_1028-Delivery-Review-Line fehlt."))
	elif not (line.contains("FOB") and line.contains("NEXT") and line.contains("GO") and line.contains("FEEDBACK")):
		blockers.append(_issue("source_delivery_review_line_incomplete", "TASK_1028-Line nennt FOB/NEXT/GO/FEEDBACK nicht gemeinsam."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1028-Source verletzt die read-only-Grenze."))
	return _dedupe_issues(blockers)


static func _build_packet_issues(handoff_packet_done: bool, missing_items: Array, issue_flags: Array, handoff_packet_notes: Dictionary) -> Array:
	var issues: Array = []
	var ids := {}
	if not handoff_packet_done:
		_append_issue_once(issues, ids, "manual_handoff_packet_open", "Handoff Packet ist noch nicht bewusst abgeschlossen.")
	if not missing_items.is_empty():
		_append_issue_once(issues, ids, "handoff_packet_items_missing", "Handoff-Packet-Items fehlen: %s." % ", ".join(PackedStringArray(missing_items)))
	for issue_id in issue_flags:
		_append_issue_once(issues, ids, "handoff_packet_issue_%s" % String(issue_id), _issue_text(String(issue_id)))
	if bool(handoff_packet_notes.get("ui_sets_gameplay_truth", false)):
		_append_issue_once(issues, ids, "handoff_ui_gameplay_truth_risk", "Handoff Packet darf keine UI-Gameplay-Wahrheit setzen.")
	if bool(handoff_packet_notes.get("creates_command", false)):
		_append_issue_once(issues, ids, "handoff_create_command", "Handoff Packet darf keinen Command erzeugen.")
	if bool(handoff_packet_notes.get("creates_movement", false)):
		_append_issue_once(issues, ids, "handoff_create_movement", "Handoff Packet darf keine Bewegung erzeugen.")
	if bool(handoff_packet_notes.get("sets_multiplayer_truth", false)):
		_append_issue_once(issues, ids, "handoff_set_multiplayer_truth", "Handoff Packet darf keine Multiplayer-Wahrheit setzen.")
	return issues


static func _active_issue_flags(handoff_packet_notes: Dictionary) -> Array:
	var active: Array = []
	for issue_id in Array(handoff_packet_notes.get("issue_flags", [])):
		var normalized: String = String(issue_id)
		if ISSUE_FLAG_IDS.has(normalized):
			active.append(normalized)
	return active


static func _missing_items(completed_items: Array) -> Array:
	var completed := {}
	for item_variant in completed_items:
		completed[String(item_variant)] = true
	var missing: Array = []
	for item_id in REQUIRED_HANDOFF_PACKET_ITEMS:
		if not completed.has(item_id):
			missing.append(item_id)
	return missing


static func _handoff_notes(source: Dictionary, notes: Dictionary) -> Dictionary:
	var delivery_notes: Dictionary = Dictionary(source.get("delivery_notes", {}))
	return {
		"start_instruction": String(notes.get("start_instruction", delivery_notes.get("start_instruction", source.get("tester_instructions", "")))),
		"shortcut_warning": String(notes.get("shortcut_warning", delivery_notes.get("shortcut_warning", ""))),
		"risk_summary": String(notes.get("risk_summary", delivery_notes.get("risk_note", ""))),
		"next_tester_action": String(notes.get("next_tester_action", NEXT_TASK)),
		"multiplayer_note": String(notes.get("multiplayer_note", "Zwei-Spieler-Kontext bleibt vorbereitet; keine Multiplayer-Wahrheit im Handoff.")),
	}


static func _test_steps(source: Dictionary, notes: Dictionary) -> Array:
	var handoff_notes: Dictionary = _handoff_notes(source, notes)
	return [
		{
			"id": "start_fresh_exe",
			"text": String(handoff_notes.get("start_instruction", "")),
			"read_only": true,
		},
		{
			"id": "avoid_stale_shortcut",
			"text": String(handoff_notes.get("shortcut_warning", "")),
			"read_only": true,
		},
		{
			"id": "verify_first_loop",
			"text": "Pruefe FOB, NEXT, GO und FEEDBACK als kleinen Spielmoment.",
			"read_only": true,
		},
		{
			"id": "record_tester_result",
			"text": String(handoff_notes.get("next_tester_action", "")),
			"read_only": true,
		},
	]


static func _build_handoff_packet_line(status: String, source: Dictionary, notes: Dictionary) -> String:
	if status == "handoff_packet_ready":
		var action: String = String(notes.get("next_tester_action", "TASK_1030 Tester Run ausfuehren.")).strip_edges()
		return "HANDOFF READY: EXE | FOB | NEXT | GO | FEEDBACK | %s" % _compact_text(action, 104)
	if status == "needs_handoff_packet":
		return "HANDOFF OFFEN: EXE | FOB | NEXT | GO | FEEDBACK brauchen ein klares Tester-Paket."
	if status == "handoff_packet_regression_found":
		return "HANDOFF BLOCKIERT: EXE | FOB | NEXT | GO | FEEDBACK brauchen Handoff-Politur."
	var source_line: String = String(source.get("delivery_review_line", "")).strip_edges()
	if source_line.is_empty():
		source_line = "EXE, FOB, NEXT, GO und FEEDBACK brauchen Handoff Packet."
	return "HANDOFF CHECK: EXE | FOB | NEXT | GO | FEEDBACK | %s" % _compact_text(source_line, 104)


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
		"stale_handoff_package":
			return "Handoff-Paket verweist auf alte Dateien oder alte Verknuepfungen."
		"release_files_unclear":
			return "Release-Dateien sind im Handoff nicht klar genug."
		"start_steps_unclear":
			return "Startschritte sind fuer den Tester nicht klar genug."
		"risks_unaccepted":
			return "Restrisiken wurden im Handoff nicht akzeptiert."
		"visible_polish_needed":
			return "Sichtbarer Spielmoment braucht vor dem Tester-Run noch Politur."
		"handoff_not_testable":
			return "Handoff-Paket ist fuer einen Tester noch nicht ausfuehrbar."
	return issue_id


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
