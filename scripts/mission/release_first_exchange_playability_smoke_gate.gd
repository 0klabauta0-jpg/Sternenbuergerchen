class_name ReleaseFirstExchangePlayabilitySmokeGate
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_playability_smoke_gate.v1"
const TASK_ID: String = "TASK_919"
const SOURCE_TASK_ID: String = "TASK_918"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_final_world_read_visual_findings.v1"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_917"
const SOURCE_FINAL_TASK_ID: String = "TASK_916"
const ACCEPTED_STATUS: String = "accepted_for_first_exchange_playability_smoke"
const FOLLOWUP_STATUS: String = "ready_for_final_world_read_followup_fix"
const MANUAL_REVIEW_STATUS: String = "needs_manual_review"
const NEXT_SMOKE_TASK: String = "TASK_920 - Release First Exchange Playability Smoke Run"
const NEXT_FIX_TASK: String = "TASK_920 - Release First Exchange Final World Read Followup Fix"
const NEXT_REVIEW_TASK: String = "TASK_920 - Release First Exchange Manual Window Review"


static func build_snapshot(findings_snapshot: Dictionary) -> Dictionary:
	var blockers: Array = _build_blockers(findings_snapshot)
	var source_status: String = String(findings_snapshot.get("status", ""))
	var smoke_ready: bool = blockers.is_empty() and source_status == ACCEPTED_STATUS and bool(findings_snapshot.get("player_readability_ok", false))
	var source_needs_review: bool = blockers.is_empty() and source_status == MANUAL_REVIEW_STATUS
	var source_needs_fix: bool = blockers.is_empty() and source_status == FOLLOWUP_STATUS
	var gate: String = "blocked"
	var recommended_next: String = NEXT_REVIEW_TASK
	var reason: String = "source_blocked"
	if blockers.is_empty():
		if smoke_ready:
			gate = "smoke_ready"
			recommended_next = NEXT_SMOKE_TASK
			reason = "task_918_accepted"
		elif source_needs_fix:
			gate = "followup_fix_required"
			recommended_next = NEXT_FIX_TASK
			reason = "task_918_reports_world_read_rest_friction"
		else:
			gate = "manual_review_required"
			recommended_next = NEXT_REVIEW_TASK
			reason = "task_918_needs_manual_review" if source_needs_review else "task_918_not_accepted"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(findings_snapshot.get("schema", "")),
		"source_status": source_status,
		"source_recapture_task_id": String(findings_snapshot.get("source_task_id", "")),
		"source_final_task_id": String(findings_snapshot.get("source_final_task_id", "")),
		"source_branch": String(findings_snapshot.get("branch", "")),
		"source_git_head": String(findings_snapshot.get("git_head", "")),
		"source_review_screenshot_path": String(findings_snapshot.get("review_screenshot_path", "")),
		"source_window_screenshot_path": String(findings_snapshot.get("window_screenshot_path", "")),
		"source_final_contact_fire": bool(findings_snapshot.get("final_source_contact_fire", false)),
		"source_player_readability_ok": bool(findings_snapshot.get("player_readability_ok", false)),
		"source_primary_issue_id": String(findings_snapshot.get("primary_issue_id", "")),
		"source_issue_count": int(findings_snapshot.get("issue_count", 0)),
		"source_positive_findings": Array(findings_snapshot.get("positive_findings", [])),
		"source_issues": Array(findings_snapshot.get("issues", [])),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"gate": gate,
		"smoke_ready": smoke_ready,
		"manual_review_required": gate == "manual_review_required",
		"followup_fix_required": gate == "followup_fix_required",
		"reason": reason,
		"smoke_required_checks": _smoke_required_checks(),
		"recommended_next_task": recommended_next,
		"recommended_direction": "run_playability_smoke_only_after_task_918_acceptance",
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


static func _build_blockers(findings_snapshot: Dictionary) -> Array:
	var blockers: Array = []
	if String(findings_snapshot.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_918-Findings-Schema fehlt oder passt nicht."))
	if String(findings_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Quelle nennt nicht TASK_918."))
	if String(findings_snapshot.get("source_task_id", "")) != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_task_mismatch", "TASK_918-Quelle nennt nicht TASK_917 als Recapture-Quelle."))
	if String(findings_snapshot.get("source_final_task_id", "")) != SOURCE_FINAL_TASK_ID:
		blockers.append(_issue("source_final_task_mismatch", "TASK_918-Quelle nennt nicht TASK_916 als Final-Polish."))
	if not bool(findings_snapshot.get("read_only", false)):
		blockers.append(_issue("source_not_read_only", "TASK_918-Quelle ist nicht read-only markiert."))
	if bool(findings_snapshot.get("creates_command", true)):
		blockers.append(_issue("source_creates_command", "TASK_918-Quelle darf keine Commands erzeugen."))
	if bool(findings_snapshot.get("creates_fire_event", true)):
		blockers.append(_issue("source_creates_fire_event", "TASK_918-Quelle darf keine FireEvents erzeugen."))
	if bool(findings_snapshot.get("creates_damage_event", true)):
		blockers.append(_issue("source_creates_damage_event", "TASK_918-Quelle darf keine DamageEvents erzeugen."))
	if bool(findings_snapshot.get("creates_movement", true)):
		blockers.append(_issue("source_creates_movement", "TASK_918-Quelle darf keine Movement-Entscheidung erzeugen."))
	if bool(findings_snapshot.get("sets_multiplayer_truth", true)):
		blockers.append(_issue("source_sets_multiplayer_truth", "TASK_918-Quelle darf keine Multiplayer-Wahrheit setzen."))
	return blockers


static func _smoke_required_checks() -> Array:
	return [
		"exe_singleplayer_start_reaches_homebase",
		"homebase_direct_sortie_start_is_actionable",
		"dropship_lz_go_reaches_mission",
		"contact_fire_visible_in_selected_fireteam_mission_control_and_event_log",
		"fire_lane_remains_first_world_movement",
		"command_surfaces_stay_usable",
		"no_new_hud_gameplay_truth",
		"first_exchange_no_obvious_performance_spike",
	]


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
