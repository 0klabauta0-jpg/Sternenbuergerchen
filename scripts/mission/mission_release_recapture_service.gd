extends RefCounted


static func build_first_contact_recapture(
	execution_recapture: Dictionary,
	first_contact_readability: Dictionary,
	release_provenance: Dictionary,
	capture_manifest: Dictionary,
	host_window: Dictionary,
	client_window: Dictionary
) -> Dictionary:
	var normalized_execution: Dictionary = execution_recapture.duplicate(true)
	var normalized_contact_readability: Dictionary = first_contact_readability.duplicate(true)
	var first_contact: Dictionary = Dictionary(normalized_contact_readability.get("first_contact", {})).duplicate(true)
	var selected_contact_count: int = int(normalized_contact_readability.get("selected_contact_count", 0))
	var contact_overlay_visible: bool = int(normalized_contact_readability.get("contact_overlay_visible_count", 0)) > 0 \
		or int(Dictionary(normalized_contact_readability.get("primary_contact_snapshot", {})).get("contact_count", 0)) > 0
	var tactical_context_visible: bool = _check_passed(normalized_contact_readability, "threat_or_cover_context_visible") \
		or int(normalized_contact_readability.get("tactical_communication_event_count", 0)) > 0 \
		or int(normalized_contact_readability.get("tactical_event_log_count", 0)) > 0
	var execution_handoff_read: bool = String(normalized_execution.get("task_id", "")) == "TASK_1171" \
		and bool(normalized_execution.get("ready_for_first_contact_recapture", false))
	var first_contact_gate_passes: bool = String(normalized_contact_readability.get("gate", "")) == "pass"
	var release_context_present: bool = _release_context_present(release_provenance, capture_manifest, host_window, client_window, false)
	var checks: Array = [
		_check("execution_recapture_handoff_read", execution_handoff_read, "TASK_1171 first-move execution recapture is read as the handoff source."),
		_check("first_contact_readability_gate_passes", first_contact_gate_passes, "TASK_542 first-contact readability remains green after the reproduced contact."),
		_check("selected_fireteam_contact_visible", selected_contact_count > 0, "Selected fireteam exposes at least one contact entry."),
		_check("first_contact_report_visible", not String(first_contact.get("report_text", "")).strip_edges().is_empty(), "First contact contains player-facing report text."),
		_check("contact_overlay_visible", contact_overlay_visible, "Contact reaches ContactMapOverlay or Primary3D render snapshot."),
		_check("tactical_context_visible", tactical_context_visible, "Threat, cover, security or event context explains why the contact matters."),
		_check("release_host_client_context_present", release_context_present, "Current release provenance and host/client FirstContact evidence are present."),
		_check("read_only", not bool(normalized_execution.get("ui_sets_gameplay_truth", true)) and not bool(normalized_contact_readability.get("ui_sets_gameplay_truth", true)), "Snapshot reads existing execution and contact feedback without creating gameplay state."),
	]
	var failed_checks: Array = _failed_check_ids(checks)
	var recaptured: bool = failed_checks.is_empty()
	return {
		"schema": "sternenbuergerchen.mission_first_contact_readability_release_recapture.v1",
		"task_id": "TASK_1172",
		"source_task_id": "TASK_1171",
		"source_task_ids": PackedStringArray(["TASK_1171", "TASK_542"]),
		"status": "recaptured" if recaptured else "blocked_by_missing_contact_or_release_context",
		"ready_for_first_engagement_recapture": recaptured,
		"execution_recapture": normalized_execution,
		"first_contact_readability": normalized_contact_readability,
		"release_provenance": release_provenance.duplicate(true),
		"capture_manifest": capture_manifest.duplicate(true),
		"host_window_artifact": host_window.duplicate(true),
		"client_window_artifact": client_window.duplicate(true),
		"execution_handoff_read": execution_handoff_read,
		"selected_contact_count": selected_contact_count,
		"first_contact": first_contact,
		"contact_overlay_visible": contact_overlay_visible,
		"tactical_context_visible": tactical_context_visible,
		"contact_report_text": String(first_contact.get("report_text", "")).strip_edges(),
		"contact_feedback_text": String(normalized_contact_readability.get("contact_feedback_text", "")).strip_edges(),
		"checks": checks,
		"failed_checks": failed_checks,
		"accepted_surfaces": ["first_contact_report_after_first_move", "contact_overlay_or_primary3d", "tactical_context_for_contact", "release_host_client_context"] if recaptured else [],
		"recommended_next_task": "TASK_1173 - First Engagement Feedback Release Recapture",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_effect": false,
		"creates_contact": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


static func build_first_engagement_recapture(
	first_contact_recapture: Dictionary,
	engagement_feedback: Dictionary,
	release_provenance: Dictionary,
	capture_manifest: Dictionary,
	host_window: Dictionary,
	client_window: Dictionary
) -> Dictionary:
	var normalized_contact_recapture: Dictionary = first_contact_recapture.duplicate(true)
	var normalized_engagement_feedback: Dictionary = engagement_feedback.duplicate(true)
	var first_fire_event: Dictionary = Dictionary(normalized_engagement_feedback.get("first_fire_event", {})).duplicate(true)
	var diagnostics: Dictionary = Dictionary(normalized_engagement_feedback.get("contact_decision_diagnostics", {})).duplicate(true)
	var first_contact_handoff_read: bool = String(normalized_contact_recapture.get("task_id", "")) == "TASK_1172" \
		and bool(normalized_contact_recapture.get("ready_for_first_engagement_recapture", false))
	var engagement_gate_passes: bool = String(normalized_engagement_feedback.get("task_id", "")) == "TASK_543" \
		and String(normalized_engagement_feedback.get("gate", "")) == "pass"
	var engagement_decision_visible: bool = _check_passed(normalized_engagement_feedback, "engagement_decision_visible")
	var target_or_block_reason_visible: bool = _check_passed(normalized_engagement_feedback, "target_or_block_reason_visible")
	var fire_event_or_block_visible: bool = _check_passed(normalized_engagement_feedback, "fire_event_or_block_visible")
	var cover_range_los_context_visible: bool = _check_passed(normalized_engagement_feedback, "cover_range_los_context_visible")
	var feedback_text_visible: bool = _check_passed(normalized_engagement_feedback, "feedback_text_visible")
	var release_context_present: bool = _release_context_present(release_provenance, capture_manifest, host_window, client_window, true)
	var checks: Array = [
		_check("first_contact_recapture_handoff_read", first_contact_handoff_read, "TASK_1172 first-contact release recapture is read before engagement feedback."),
		_check("first_engagement_feedback_gate_passes", engagement_gate_passes, "TASK_543 first-engagement feedback remains green after contact."),
		_check("engagement_decision_visible", engagement_decision_visible, "The first engagement reports fired, waiting or blocked state."),
		_check("target_or_block_reason_visible", target_or_block_reason_visible, "The first engagement names target/attacker or a concrete wait/block reason."),
		_check("fire_event_or_block_visible", fire_event_or_block_visible, "The first engagement exposes a fire event or the blocking decision."),
		_check("cover_range_los_context_visible", cover_range_los_context_visible, "The first engagement retains cover, range or LOS context."),
		_check("feedback_text_visible", feedback_text_visible, "Mission feedback names the first engagement decision for the player."),
		_check("release_host_client_first_fire_context_present", release_context_present, "Current release provenance and host/client first-fire evidence are present."),
		_check("read_only", not bool(normalized_contact_recapture.get("ui_sets_gameplay_truth", true)) and not bool(normalized_engagement_feedback.get("ui_sets_gameplay_truth", true)), "Snapshot reads existing contact and engagement feedback without creating gameplay state."),
	]
	var failed_checks: Array = _failed_check_ids(checks)
	var recaptured: bool = failed_checks.is_empty()
	return {
		"schema": "sternenbuergerchen.mission_first_engagement_feedback_release_recapture.v1",
		"task_id": "TASK_1173",
		"source_task_id": "TASK_1172",
		"source_task_ids": PackedStringArray(["TASK_1172", "TASK_543"]),
		"status": "recaptured" if recaptured else "blocked_by_missing_engagement_or_release_context",
		"ready_for_first_fire_visual_recapture": recaptured,
		"first_contact_recapture": normalized_contact_recapture,
		"engagement_feedback": normalized_engagement_feedback,
		"release_provenance": release_provenance.duplicate(true),
		"capture_manifest": capture_manifest.duplicate(true),
		"host_window_artifact": host_window.duplicate(true),
		"client_window_artifact": client_window.duplicate(true),
		"first_contact_handoff_read": first_contact_handoff_read,
		"engagement_decision_visible": engagement_decision_visible,
		"target_or_block_reason_visible": target_or_block_reason_visible,
		"fire_event_or_block_visible": fire_event_or_block_visible,
		"cover_range_los_context_visible": cover_range_los_context_visible,
		"feedback_text_visible": feedback_text_visible,
		"engagement_status": String(normalized_engagement_feedback.get("engagement_status", "")).strip_edges().to_lower(),
		"engagement_reason": String(normalized_engagement_feedback.get("engagement_reason", diagnostics.get("reason", ""))).strip_edges(),
		"first_fire_event": first_fire_event,
		"contact_decision_diagnostics": diagnostics,
		"contact_decision_text": String(normalized_engagement_feedback.get("contact_decision_text", "")).strip_edges(),
		"mission_control_status_text": String(normalized_engagement_feedback.get("mission_control_status_text", "")).strip_edges(),
		"selected_fireteam_status_text": String(normalized_engagement_feedback.get("selected_fireteam_status_text", "")).strip_edges(),
		"checks": checks,
		"failed_checks": failed_checks,
		"accepted_surfaces": ["first_engagement_after_contact", "fire_event_or_wait_block_reason", "cover_range_los_context", "release_host_client_first_fire_context"] if recaptured else [],
		"recommended_next_task": "TASK_1174 - First Fire Visual Readability Release Recapture",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_effect": false,
		"creates_contact": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


static func _release_context_present(release_provenance: Dictionary, capture_manifest: Dictionary, host_window: Dictionary, client_window: Dictionary, requires_first_fire: bool) -> bool:
	return bool(release_provenance.get("valid", false)) \
		and bool(release_provenance.get("matches_git_head", false)) \
		and bool(capture_manifest.get("gate_passed", false)) \
		and bool(capture_manifest.get("release_gate_passed", false)) \
		and bool(capture_manifest.get("deployment_converged", false)) \
		and (not requires_first_fire or bool(capture_manifest.get("first_fire_converged", false))) \
		and bool(host_window.get("exists", false)) \
		and bool(client_window.get("exists", false)) \
		and int(host_window.get("size_bytes", 0)) > 0 \
		and int(client_window.get("size_bytes", 0)) > 0


static func _check(check_id: String, passed: bool, details: String) -> Dictionary:
	return {"id": check_id, "passed": passed, "details": details}


static func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		if typeof(check_variant) != TYPE_DICTIONARY:
			continue
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


static func _failed_check_ids(checks: Array) -> Array:
	var failed_checks: Array = []
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_checks.append(String(check.get("id", "")))
	return failed_checks
