class_name ReleaseFirstExchangeFinalTuningPlayabilitySmokeGate
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_final_tuning_playability_smoke_gate.v1"
const TASK_ID: String = "TASK_941"
const SOURCE_TASK_ID: String = "TASK_940"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.v1"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_939"
const SOURCE_FINAL_TUNING_TASK_ID: String = "TASK_938"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_937"
const SOURCE_RECAPTURE_BASE_TASK_ID: String = "TASK_936"
const SOURCE_PLAYER_POLISH_TASK_ID: String = "TASK_935"
const ACCEPTED_STATUS: String = "accepted_for_first_exchange_playability_smoke"
const FOLLOWUP_STATUS: String = "ready_for_followup_fix_player_polish_final_tuning_followup_fix"
const MANUAL_REVIEW_STATUS: String = "needs_manual_review"
const NEXT_SMOKE_TASK: String = "TASK_942 - Release First Exchange Playability Smoke Run"
const NEXT_FIX_TASK: String = "TASK_942 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Fix"
const NEXT_REVIEW_TASK: String = "TASK_942 - Release First Exchange Manual Window Review"


static func build_snapshot(findings_snapshot: Dictionary) -> Dictionary:
	var blockers: Array = _build_blockers(findings_snapshot)
	var source_status: String = String(findings_snapshot.get("status", ""))
	var smoke_ready: bool = blockers.is_empty() \
		and source_status == ACCEPTED_STATUS \
		and bool(findings_snapshot.get("player_readability_ok", false))
	var source_needs_review: bool = blockers.is_empty() and source_status == MANUAL_REVIEW_STATUS
	var source_needs_fix: bool = blockers.is_empty() and source_status == FOLLOWUP_STATUS
	var gate: String = "blocked"
	var recommended_next: String = NEXT_REVIEW_TASK
	var reason: String = "source_blocked"
	if blockers.is_empty():
		if smoke_ready:
			gate = "smoke_ready"
			recommended_next = NEXT_SMOKE_TASK
			reason = "task_940_accepted"
		elif source_needs_fix:
			gate = "followup_fix_required"
			recommended_next = NEXT_FIX_TASK
			reason = "task_940_reports_final_tuning_rest_friction"
		else:
			gate = "manual_review_required"
			recommended_next = NEXT_REVIEW_TASK
			reason = "task_940_needs_manual_review" if source_needs_review else "task_940_not_accepted"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(findings_snapshot.get("schema", "")),
		"source_status": source_status,
		"source_recapture_task_id": String(findings_snapshot.get("source_task_id", "")),
		"source_final_tuning_task_id": String(findings_snapshot.get("source_final_tuning_task_id", "")),
		"source_findings_task_id": String(findings_snapshot.get("source_findings_task_id", "")),
		"source_recapture_base_task_id": String(findings_snapshot.get("source_recapture_task_id", "")),
		"source_player_polish_task_id": String(findings_snapshot.get("source_player_polish_task_id", "")),
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
		"recommended_direction": "run_playability_smoke_only_after_task_940_acceptance",
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
		blockers.append(_issue("source_schema_mismatch", "TASK_940-Findings-Schema fehlt oder passt nicht."))
	if String(findings_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Quelle nennt nicht TASK_940."))
	if String(findings_snapshot.get("source_task_id", "")) != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_task_mismatch", "TASK_940-Quelle nennt nicht TASK_939 als Recapture-Quelle."))
	if String(findings_snapshot.get("source_final_tuning_task_id", "")) != SOURCE_FINAL_TUNING_TASK_ID:
		blockers.append(_issue("source_final_tuning_task_mismatch", "TASK_940-Quelle nennt nicht TASK_938 als Final-Tuning."))
	if String(findings_snapshot.get("source_findings_task_id", "")) != SOURCE_FINDINGS_TASK_ID:
		blockers.append(_issue("source_findings_task_mismatch", "TASK_940-Quelle nennt nicht TASK_937 als Findings-Basis."))
	if String(findings_snapshot.get("source_recapture_task_id", "")) != SOURCE_RECAPTURE_BASE_TASK_ID:
		blockers.append(_issue("source_recapture_base_task_mismatch", "TASK_940-Quelle nennt nicht TASK_936 als Recapture-Basis."))
	if String(findings_snapshot.get("source_player_polish_task_id", "")) != SOURCE_PLAYER_POLISH_TASK_ID:
		blockers.append(_issue("source_player_polish_task_mismatch", "TASK_940-Quelle nennt nicht TASK_935 als Player-Polish."))
	if not bool(findings_snapshot.get("read_only", false)):
		blockers.append(_issue("source_not_read_only", "TASK_940-Quelle ist nicht read-only markiert."))
	if bool(findings_snapshot.get("creates_command", true)):
		blockers.append(_issue("source_creates_command", "TASK_940-Quelle darf keine Commands erzeugen."))
	if bool(findings_snapshot.get("creates_fire_event", true)):
		blockers.append(_issue("source_creates_fire_event", "TASK_940-Quelle darf keine FireEvents erzeugen."))
	if bool(findings_snapshot.get("creates_damage_event", true)):
		blockers.append(_issue("source_creates_damage_event", "TASK_940-Quelle darf keine DamageEvents erzeugen."))
	if bool(findings_snapshot.get("creates_movement", true)):
		blockers.append(_issue("source_creates_movement", "TASK_940-Quelle darf keine Movement-Entscheidung erzeugen."))
	if bool(findings_snapshot.get("sets_multiplayer_truth", true)):
		blockers.append(_issue("source_sets_multiplayer_truth", "TASK_940-Quelle darf keine Multiplayer-Wahrheit setzen."))
	if bool(findings_snapshot.get("updates_shortcuts", true)):
		blockers.append(_issue("source_updates_shortcuts", "TASK_940-Quelle darf keine Shortcuts veraendern."))
	return blockers


static func _smoke_required_checks() -> Array:
	return [
		"exe_singleplayer_start_reaches_homebase",
		"homebase_direct_sortie_start_is_actionable",
		"dropship_lz_go_reaches_mission",
		"first_go_reaches_contact_fire",
		"contact_fire_visible_in_selected_fireteam_mission_control_and_event_log",
		"fire_lane_remains_first_world_movement",
		"command_surfaces_stay_usable",
		"no_new_hud_gameplay_truth",
		"first_exchange_no_obvious_performance_spike",
		"multiplayer_snapshot_truth_unchanged",
	]


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
