class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioNextPlayableSlicePlan
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.v1"
const TASK_ID: String = "TASK_1032"
const SOURCE_TASK_ID: String = "TASK_1031"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.v1"
const PLAN_TASK: String = "TASK_1032 - Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan"
const POLISH_TASK: String = "TASK_1032 - Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan Polish"
const NEXT_TASK: String = "TASK_1033 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Hook"
const DEFAULT_SLICE_ID: String = "first_contact_decision"

const REQUIRED_PLAN_ITEMS: Array[String] = [
	"accepted_tester_run_reused",
	"slice_goal_chosen",
	"first_contact_readability_reused",
	"first_engagement_feedback_reused",
	"fire_cover_visuals_reused",
	"combat_hud_density_reused",
	"player_questions_defined",
	"two_player_role_boundary_defined",
	"multiplayer_boundary_preserved",
	"next_task_named",
]

const ISSUE_FLAG_IDS: Array[String] = [
	"ambiguous_slice_goal",
	"ignores_existing_contact_stack",
	"combat_truth_in_ui_risk",
	"missing_player_question",
	"performance_budget_unclear",
	"multiplayer_boundary_unclear",
]


static func build_snapshot(source_acceptance: Dictionary, next_slice_plan_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_acceptance)
	var plan_available: bool = bool(next_slice_plan_notes.get("next_slice_plan_available", false)) or not next_slice_plan_notes.is_empty()
	var plan_done: bool = bool(next_slice_plan_notes.get("next_slice_plan_done", false))
	var completed_items: Array = Array(next_slice_plan_notes.get("completed_plan_items", [])).duplicate(true)
	var missing_items: Array = _missing_plan_items(completed_items)
	var active_issue_flags: Array = _active_issue_flags(next_slice_plan_notes)
	var issues: Array = []
	var status: String = "blocked_until_tester_run_acceptance"
	var gate: String = "blocked_until_tester_run_acceptance"
	var next_playable_slice_plan_ready: bool = false
	var ready_for_first_contact_runtime_hook: bool = false
	var recommended_next_task: String = PLAN_TASK
	var recommended_direction: String = "accept_tester_run_first"

	if blockers.is_empty():
		if not plan_available:
			status = "needs_next_playable_slice_plan"
			gate = "needs_next_playable_slice_plan"
			issues.append(_issue("next_slice_plan_missing", "Naechster spielbarer Slice ist noch nicht bewusst geplant."))
			recommended_direction = "write_next_slice_plan"
		else:
			issues = _build_plan_issues(plan_done, missing_items, active_issue_flags, next_slice_plan_notes)
			if not active_issue_flags.is_empty():
				status = "next_playable_slice_plan_regression_found"
				gate = "next_playable_slice_plan_regression_found"
				recommended_next_task = POLISH_TASK
				recommended_direction = "polish_next_slice_plan"
			elif not issues.is_empty():
				status = "needs_next_playable_slice_plan_completion"
				gate = "needs_next_playable_slice_plan_completion"
				recommended_direction = "complete_next_slice_plan"
			else:
				status = "next_playable_slice_plan_ready"
				gate = "next_playable_slice_plan_ready"
				next_playable_slice_plan_ready = true
				ready_for_first_contact_runtime_hook = true
				recommended_next_task = NEXT_TASK
				recommended_direction = "hook_first_contact_runtime"

	var all_issues: Array = blockers + issues
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_acceptance.get("schema", "")),
		"source_status": String(source_acceptance.get("status", "")),
		"source_gate": String(source_acceptance.get("gate", "")),
		"source_acceptance_line": String(source_acceptance.get("acceptance_line", "")),
		"source_tester_run_accepted": bool(source_acceptance.get("tester_run_accepted", false)),
		"source_ready_for_next_playable_slice": bool(source_acceptance.get("ready_for_next_playable_slice", false)),
		"release_build_path": String(source_acceptance.get("release_build_path", "")),
		"pck_path": String(source_acceptance.get("pck_path", "")),
		"scenario_id": String(source_acceptance.get("scenario_id", "")),
		"known_risks": Array(source_acceptance.get("known_risks", [])).duplicate(true),
		"source_acceptance_notes": Dictionary(source_acceptance.get("acceptance_notes", {})).duplicate(true),
		"next_slice_plan_available": plan_available,
		"next_slice_plan_done": plan_done,
		"selected_slice_id": _selected_slice_id(next_slice_plan_notes),
		"plan_summary": String(next_slice_plan_notes.get("plan_summary", "")),
		"player_goal": String(next_slice_plan_notes.get("player_goal", "")),
		"two_player_note": String(next_slice_plan_notes.get("two_player_note", "")),
		"performance_note": String(next_slice_plan_notes.get("performance_note", "")),
		"next_task_note": String(next_slice_plan_notes.get("next_task_note", "")),
		"required_plan_items": REQUIRED_PLAN_ITEMS.duplicate(),
		"completed_plan_items": completed_items,
		"missing_plan_items": missing_items,
		"missing_plan_item_count": missing_items.size(),
		"issue_flags": active_issue_flags,
		"active_issue_count": active_issue_flags.size(),
		"slice_plan": _slice_plan(next_slice_plan_notes),
		"next_slice_line": _build_next_slice_line(status, next_slice_plan_notes),
		"next_playable_slice_plan_ready": next_playable_slice_plan_ready,
		"ready_for_first_contact_runtime_hook": ready_for_first_contact_runtime_hook,
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
		blockers.append(_issue("source_schema_mismatch", "TASK_1031-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1031."))
	if String(source.get("status", "")) != "tester_run_accepted":
		blockers.append(_issue("source_acceptance_not_ready", "TASK_1031-Source ist nicht tester_run_accepted."))
	if not bool(source.get("tester_run_accepted", false)):
		blockers.append(_issue("source_acceptance_not_ready", "TASK_1031-Tester-Run-Acceptance-Flag fehlt."))
	if not bool(source.get("ready_for_next_playable_slice", false)):
		blockers.append(_issue("source_acceptance_not_ready", "TASK_1031 gibt den naechsten spielbaren Slice noch nicht frei."))
	var line: String = String(source.get("acceptance_line", "")).strip_edges()
	if line.is_empty():
		blockers.append(_issue("source_acceptance_line_missing", "TASK_1031-Acceptance-Line fehlt."))
	elif not (line.contains("EXE") and line.contains("FOB") and line.contains("NEXT") and line.contains("GO") and line.contains("FEEDBACK")):
		blockers.append(_issue("source_acceptance_line_incomplete", "TASK_1031-Line nennt EXE/FOB/NEXT/GO/FEEDBACK nicht gemeinsam."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1031-Source verletzt die read-only-Grenze."))
	return _dedupe_issues(blockers)


static func _build_plan_issues(plan_done: bool, missing_items: Array, issue_flags: Array, plan_notes: Dictionary) -> Array:
	var issues: Array = []
	var ids := {}
	if not plan_done:
		_append_issue_once(issues, ids, "next_slice_plan_open", "Naechster spielbarer Slice ist noch nicht bewusst abgeschlossen.")
	if not missing_items.is_empty():
		_append_issue_once(issues, ids, "next_slice_plan_items_missing", "Plan-Items fehlen: %s." % ", ".join(PackedStringArray(missing_items)))
	for issue_id in issue_flags:
		_append_issue_once(issues, ids, "next_slice_plan_issue_%s" % String(issue_id), _issue_text(String(issue_id)))
	if bool(plan_notes.get("ui_sets_gameplay_truth", false)):
		_append_issue_once(issues, ids, "next_slice_plan_ui_gameplay_truth_risk", "Plan darf keine UI-Gameplay-Wahrheit setzen.")
	if bool(plan_notes.get("creates_command", false)):
		_append_issue_once(issues, ids, "next_slice_plan_create_command", "Plan darf keinen Command erzeugen.")
	if bool(plan_notes.get("creates_movement", false)):
		_append_issue_once(issues, ids, "next_slice_plan_create_movement", "Plan darf keine Bewegung erzeugen.")
	if bool(plan_notes.get("sets_multiplayer_truth", false)):
		_append_issue_once(issues, ids, "next_slice_plan_set_multiplayer_truth", "Plan darf keine Multiplayer-Wahrheit setzen.")
	return issues


static func _slice_plan(plan_notes: Dictionary) -> Dictionary:
	return {
		"slice_id": _selected_slice_id(plan_notes),
		"title": "Erster Kontakt mit lesbarer Kampfentscheidung",
		"player_goal": String(plan_notes.get("player_goal", "Der Spieler liest Kontakt, Deckung/LOS, Fire/Wait und den naechsten Griff vor der naechsten Entscheidung.")),
		"runtime_beats": [
			"mission_entry_context",
			"move_or_next_order",
			"first_contact_report",
			"cover_los_readout",
			"first_engagement_feedback",
			"fire_or_wait_reason",
			"feedback_to_next_choice",
		],
		"reuse_contracts": [
			"first_contact_readability",
			"first_engagement_feedback",
			"fire_cover_visual_polish",
			"combat_hud_density",
		],
		"player_questions": [
			"Wer sieht wen?",
			"Warum ist das sicher oder gefaehrlich?",
			"Warum schiesst das Fireteam oder wartet es?",
			"Was ist der naechste Griff?",
		],
		"two_player_roles": {
			"alpha": "liest Kontakt, Cover/LOS und gibt GO fuer den ersten Griff",
			"bravo": "bleibt als zweiter Spieler-/Multiplayer-Rand mit eigener Sicht und ohne UI-Wahrheit erhalten",
		},
		"next_task": NEXT_TASK,
	}


static func _build_next_slice_line(status: String, plan_notes: Dictionary) -> String:
	if status == "next_playable_slice_plan_ready":
		return "NEXT SLICE READY: CONTACT | COVER | LOS | FIRE/WAIT | FEEDBACK | TASK_1033"
	if status == "blocked_until_tester_run_acceptance":
		return "NEXT SLICE BLOCKED: TASK_1031 Acceptance fehlt."
	if status == "next_playable_slice_plan_regression_found":
		return "NEXT SLICE PLAN BLOCKED: Kontakt-/Cover-/LOS-Plan polieren."
	if status == "needs_next_playable_slice_plan":
		return "NEXT SLICE OFFEN: erster Kontakt, Cover/LOS, Fire/Wait und Feedback planen."
	var summary: String = String(plan_notes.get("plan_summary", "Plan vervollstaendigen.")).strip_edges()
	return "NEXT SLICE CHECK: %s" % _compact_text(summary, 96)


static func _selected_slice_id(plan_notes: Dictionary) -> String:
	var selected: String = String(plan_notes.get("selected_slice_id", DEFAULT_SLICE_ID)).strip_edges()
	return DEFAULT_SLICE_ID if selected.is_empty() else selected


static func _active_issue_flags(plan_notes: Dictionary) -> Array:
	var active: Array = []
	for issue_id in Array(plan_notes.get("issue_flags", [])):
		var normalized: String = String(issue_id)
		if ISSUE_FLAG_IDS.has(normalized):
			active.append(normalized)
	return active


static func _missing_plan_items(completed_items: Array) -> Array:
	var completed := {}
	for item_variant in completed_items:
		completed[String(item_variant)] = true
	var missing: Array = []
	for item_id in REQUIRED_PLAN_ITEMS:
		if not completed.has(item_id):
			missing.append(item_id)
	return missing


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
		"ambiguous_slice_goal":
			return "Naechster spielbarer Slice ist zu unscharf."
		"ignores_existing_contact_stack":
			return "Plan ignoriert bestehende First-Contact-/First-Engagement-Snapshots."
		"combat_truth_in_ui_risk":
			return "Plan riskiert Combat-Wahrheit im UI statt im Runtime-/Simulationspfad."
		"missing_player_question":
			return "Plan beantwortet die Spielerfrage nicht sichtbar genug."
		"performance_budget_unclear":
			return "Plan nennt kein klares Hotpath-/Performance-Budget."
		"multiplayer_boundary_unclear":
			return "Plan trennt lokalen Spielerblick und Multiplayer-Wahrheit nicht klar."
	return issue_id


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
