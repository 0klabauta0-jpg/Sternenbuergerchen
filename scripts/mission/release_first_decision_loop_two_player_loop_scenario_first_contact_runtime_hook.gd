class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactRuntimeHook
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.v1"
const TASK_ID: String = "TASK_1033"
const SOURCE_TASK_ID: String = "TASK_1032"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.v1"
const REVIEW_TASK: String = "TASK_1033 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Hook"
const NEXT_TASK: String = "TASK_1034 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke"


static func build_snapshot(source_plan: Dictionary, runtime_context: Dictionary = {}) -> Dictionary:
	var source_blockers: Array = _build_source_blockers(source_plan)
	var issues: Array = []
	var status: String = "blocked_until_next_playable_slice_plan"
	var gate: String = "blocked_until_next_playable_slice_plan"
	var ready: bool = false
	var recommended_next_task: String = REVIEW_TASK
	var recommended_direction: String = "fix_next_playable_slice_plan"

	if source_blockers.is_empty():
		if runtime_context.is_empty():
			status = "needs_first_contact_runtime_hook_context"
			gate = "needs_first_contact_runtime_hook_context"
			issues.append(_issue("runtime_context_missing", "First-Contact-Runtime-Kontext fehlt."))
			recommended_direction = "connect_existing_first_contact_snapshots"
		else:
			issues = _build_runtime_issues(runtime_context)
			if issues.is_empty():
				status = "first_contact_runtime_hook_ready"
				gate = "first_contact_runtime_hook_ready"
				ready = true
				recommended_next_task = NEXT_TASK
				recommended_direction = "run_first_contact_runtime_smoke"
			else:
				status = "first_contact_runtime_hook_review"
				gate = "first_contact_runtime_hook_review"
				recommended_direction = "fix_first_contact_runtime_hook"

	var all_issues: Array = source_blockers + issues
	var source_slice_plan: Dictionary = Dictionary(source_plan.get("slice_plan", {})).duplicate(true)
	var runtime_steps: Array = _build_runtime_steps(source_slice_plan)
	var question_answers: Dictionary = _build_player_question_answers(runtime_context)
	var compact_line: String = _build_runtime_line(status, runtime_context)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_plan.get("schema", "")),
		"source_status": String(source_plan.get("status", "")),
		"source_gate": String(source_plan.get("gate", "")),
		"source_selected_slice_id": String(source_plan.get("selected_slice_id", "")),
		"source_next_slice_line": String(source_plan.get("next_slice_line", "")),
		"active": ready,
		"first_contact_runtime_hook_ready": ready,
		"status": status,
		"gate": gate,
		"first_contact_runtime_line": compact_line,
		"mission_control_runtime_line": compact_line,
		"selected_fireteam_runtime_line": _build_selected_fireteam_line(runtime_context, ready),
		"runtime_steps": runtime_steps,
		"runtime_step_count": runtime_steps.size(),
		"player_question_answers": question_answers,
		"command_matrix_runtime_hooks": _build_command_matrix_hooks(ready),
		"reused_contracts": [
			"first_contact_readability",
			"first_engagement_feedback",
			"fire_cover_visual_polish",
			"combat_hud_density",
		],
		"first_contact_readability": Dictionary(runtime_context.get("first_contact_readability", {})).duplicate(true),
		"first_engagement_feedback": Dictionary(runtime_context.get("first_engagement_feedback", {})).duplicate(true),
		"fire_cover_visual_polish": Dictionary(runtime_context.get("fire_cover_visual_polish", {})).duplicate(true),
		"combat_hud_density": Dictionary(runtime_context.get("combat_hud_density", {})).duplicate(true),
		"requires_existing_go_path": true,
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": source_blockers,
		"blocking_issue_count": source_blockers.size(),
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


static func _build_source_blockers(source_plan: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_plan.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1032-Source-Schema fehlt oder passt nicht."))
	if String(source_plan.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1032."))
	if String(source_plan.get("status", "")) != "next_playable_slice_plan_ready":
		blockers.append(_issue("source_plan_not_ready", "TASK_1032-Plan ist nicht bereit."))
	if not bool(source_plan.get("next_playable_slice_plan_ready", false)):
		blockers.append(_issue("source_plan_not_ready", "TASK_1032-Plan-Ready-Flag fehlt."))
	if not bool(source_plan.get("ready_for_first_contact_runtime_hook", false)):
		blockers.append(_issue("source_plan_not_ready", "TASK_1032 gibt den First-Contact-Runtime-Hook nicht frei."))
	if String(source_plan.get("selected_slice_id", "")) != "first_contact_decision":
		blockers.append(_issue("source_slice_mismatch", "TASK_1032 waehlt nicht den First-Contact-Decision-Slice."))
	var slice_plan: Dictionary = Dictionary(source_plan.get("slice_plan", {}))
	var reuse_contracts: Array = Array(slice_plan.get("reuse_contracts", []))
	for contract_id in ["first_contact_readability", "first_engagement_feedback", "fire_cover_visual_polish", "combat_hud_density"]:
		if not reuse_contracts.has(contract_id):
			blockers.append(_issue("source_reuse_contract_missing", "TASK_1032 nennt %s nicht als wiederverwendeten Contract." % contract_id))
	if not _snapshot_is_read_only(source_plan):
		blockers.append(_issue("source_not_read_only", "TASK_1032-Source verletzt die read-only-Grenze."))
	return _dedupe_issues(blockers)


static func _build_runtime_issues(runtime_context: Dictionary) -> Array:
	var issues: Array = []
	var first_contact: Dictionary = Dictionary(runtime_context.get("first_contact_readability", {}))
	var engagement: Dictionary = Dictionary(runtime_context.get("first_engagement_feedback", {}))
	var fire_cover: Dictionary = Dictionary(runtime_context.get("fire_cover_visual_polish", {}))
	var combat_hud: Dictionary = Dictionary(runtime_context.get("combat_hud_density", {}))
	if String(first_contact.get("gate", "")) != "pass":
		issues.append(_issue("first_contact_readability_not_passed", "First-Contact-Readability ist nicht gruen."))
	if int(first_contact.get("selected_contact_count", 0)) <= 0:
		issues.append(_issue("first_contact_missing", "Kein lesbarer erster Kontakt vorhanden."))
	if String(engagement.get("gate", "")) != "pass":
		issues.append(_issue("first_engagement_feedback_not_passed", "First-Engagement-Feedback ist nicht gruen."))
	if String(fire_cover.get("gate", "")) != "pass":
		issues.append(_issue("fire_cover_visual_polish_not_passed", "Fire-/Cover-Visual-Polish ist nicht gruen."))
	if String(combat_hud.get("gate", "")) != "pass":
		issues.append(_issue("combat_hud_density_not_passed", "Combat-HUD-Density ist nicht gruen."))
	var hud_density: Dictionary = Dictionary(combat_hud.get("combat_hud_density", {}))
	if not _combat_hud_has_cover_los_range_context(hud_density):
		issues.append(_issue("cover_los_range_context_missing", "Combat-HUD-Density nennt Cover, LOS und Range nicht gemeinsam."))
	if not _context_is_read_only(first_contact) or not _context_is_read_only(engagement) or not _context_is_read_only(fire_cover) or not _context_is_read_only(hud_density):
		issues.append(_issue("runtime_context_not_read_only", "Ein wiederverwendeter Runtime-Snapshot verletzt die read-only-Grenze."))
	if bool(runtime_context.get("ui_sets_gameplay_truth", false)):
		issues.append(_issue("context_sets_gameplay_truth", "Runtime-Hook-Kontext darf keine Gameplay-Wahrheit setzen."))
	if bool(runtime_context.get("creates_command", false)):
		issues.append(_issue("context_creates_command", "Runtime-Hook-Kontext darf keinen Command erzeugen."))
	if bool(runtime_context.get("creates_movement", false)):
		issues.append(_issue("context_creates_movement", "Runtime-Hook-Kontext darf keine Bewegung erzeugen."))
	if bool(runtime_context.get("creates_fire_event", false)):
		issues.append(_issue("context_creates_fire_event", "Runtime-Hook-Kontext darf kein FireEvent erzeugen."))
	if bool(runtime_context.get("creates_damage_event", false)):
		issues.append(_issue("context_creates_damage_event", "Runtime-Hook-Kontext darf kein DamageEvent erzeugen."))
	if bool(runtime_context.get("sets_multiplayer_truth", false)):
		issues.append(_issue("context_sets_multiplayer_truth", "Runtime-Hook-Kontext darf keine Multiplayer-Wahrheit setzen."))
	return _dedupe_issues(issues)


static func _build_runtime_steps(source_slice_plan: Dictionary) -> Array:
	var beats: Array = Array(source_slice_plan.get("runtime_beats", []))
	if beats.is_empty():
		beats = ["first_contact_report", "cover_los_readout", "first_engagement_feedback", "fire_or_wait_reason", "feedback_to_next_choice"]
	var steps: Array = []
	var index: int = 0
	for beat_variant in beats:
		var step_id: String = String(beat_variant)
		steps.append({
			"step_id": step_id,
			"index": index,
			"label": _label_for_step(step_id),
			"runtime_state": "active" if index == 0 else "pending",
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
		index += 1
	return steps


static func _build_player_question_answers(runtime_context: Dictionary) -> Dictionary:
	var first_contact: Dictionary = Dictionary(runtime_context.get("first_contact_readability", {}))
	var engagement: Dictionary = Dictionary(runtime_context.get("first_engagement_feedback", {}))
	var combat_hud: Dictionary = Dictionary(runtime_context.get("combat_hud_density", {}))
	var first_contact_entry: Dictionary = Dictionary(first_contact.get("first_contact", {}))
	var contact_text: String = String(first_contact_entry.get("report_text", first_contact.get("contact_feedback_text", "Kontakt unklar"))).strip_edges()
	var engagement_text: String = String(engagement.get("contact_decision_text", engagement.get("engagement_reason", "Fire/Wait unklar"))).strip_edges()
	var hud_line: String = String(combat_hud.get("compact_line", Dictionary(combat_hud.get("combat_hud_density", {})).get("compact_line", ""))).strip_edges()
	return {
		"Wer sieht wen?": "Kontakt: %s" % contact_text,
		"Warum ist das sicher oder gefaehrlich?": "COVER/LOS/RANGE: %s" % (hud_line if not hud_line.is_empty() else "noch nicht lesbar"),
		"Warum schiesst das Fireteam oder wartet es?": "FIRE/WAIT: %s" % (engagement_text if not engagement_text.is_empty() else "noch nicht lesbar"),
		"Was ist der naechste Griff?": "NEXT lesen, WHY pruefen, GO separat bestaetigen.",
	}


static func _build_command_matrix_hooks(active: bool) -> Array:
	return [
		{
			"hook_id": "contact",
			"label": "CONTACT",
			"action": "read_first_contact",
			"enabled": active,
			"read_only": true,
		},
		{
			"hook_id": "why",
			"label": "WHY",
			"action": "read_cover_los_fire_wait_reason",
			"enabled": active,
			"read_only": true,
		},
		{
			"hook_id": "next",
			"label": "NEXT",
			"action": "select_next_runtime_prompt",
			"enabled": active,
			"read_only": true,
		},
		{
			"hook_id": "go",
			"label": "GO",
			"action": "execute_existing_go_path",
			"enabled": active,
			"auto_executes": false,
			"read_only": true,
		},
	]


static func _build_runtime_line(status: String, runtime_context: Dictionary) -> String:
	if status == "first_contact_runtime_hook_ready":
		return "CONTACT READY: CONTACT | COVER | LOS | FIRE/WAIT | FEEDBACK | GO separat"
	if status == "blocked_until_next_playable_slice_plan":
		return "CONTACT BLOCKED: TASK_1032 Next-Slice-Plan fehlt."
	if status == "needs_first_contact_runtime_hook_context":
		return "CONTACT OFFEN: First-Contact-, Cover/LOS- und Combat-HUD-Snapshots verbinden."
	return "CONTACT CHECK: CONTACT | COVER | LOS | FIRE/WAIT | FEEDBACK pruefen."


static func _build_selected_fireteam_line(runtime_context: Dictionary, active: bool) -> String:
	var fireteam_id: String = String(runtime_context.get("selected_fireteam_id", "FT")).strip_edges()
	var role_id: String = String(runtime_context.get("selected_role_id", "alpha")).strip_edges().to_upper()
	return "%s %s | CONTACT/COVER/LOS lesen | GO separat" % [fireteam_id, role_id] if active else "%s %s | CONTACT Hook pruefen | GO separat" % [fireteam_id, role_id]


static func _combat_hud_has_cover_los_range_context(hud_density: Dictionary) -> bool:
	return bool(hud_density.get("contains_cover_context", false)) \
		and bool(hud_density.get("contains_los_context", false)) \
		and bool(hud_density.get("contains_range_context", false))


static func _context_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", false))


static func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_movement", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false))


static func _label_for_step(step_id: String) -> String:
	match step_id:
		"first_contact_report":
			return "CONTACT"
		"cover_los_readout":
			return "COVER/LOS"
		"first_engagement_feedback":
			return "FIRE/WAIT"
		"fire_or_wait_reason":
			return "WHY"
		"feedback_to_next_choice":
			return "FEEDBACK"
		_:
			return step_id.to_upper()


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


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
