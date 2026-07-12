extends RefCounted

const SCHEMA: String = "sternenbuergerchen.left_tactical_stack_1280_visual_findings.v1"
const TASK_ID: String = "TASK_1164"
const SOURCE_SCHEMA: String = "sternenbuergerchen.left_tactical_stack_1280_release_recapture.v1"
const SOURCE_TASK_ID: String = "TASK_1163"
const NEXT_REVIEW_TASK: String = "TASK_1164 - Left Tactical Stack 1280 Visual Findings"
const NEXT_POLISH_TASK: String = "TASK_1165 - Left Tactical Stack 1280 Detail Polish"
const NEXT_ACCEPTANCE_TASK: String = "TASK_1165 - Left Tactical Stack 1280 Acceptance Slice"


static func build_snapshot(source_snapshot: Dictionary = {}, review_notes: Dictionary = {}) -> Dictionary:
	var blocking_issues: Array = _build_source_blocking_issues(source_snapshot)
	if not blocking_issues.is_empty():
		return _base_snapshot(source_snapshot, review_notes, {
			"status": "blocked",
			"accepted": false,
			"blocking_issues": blocking_issues,
			"issues": [],
			"positive_findings": [],
			"recommended_next_task": NEXT_REVIEW_TASK,
			"recommended_direction": "provide_valid_task_1163_source",
		})

	if not bool(review_notes.get("review_available", false)):
		return _base_snapshot(source_snapshot, review_notes, {
			"status": "needs_left_stack_visual_review",
			"accepted": false,
			"blocking_issues": [],
			"issues": [_issue("left_stack_visual_review_missing", "Host-/Client-Fensterbild bewusst bewerten, bevor poliert wird.")],
			"positive_findings": _build_positive_findings(source_snapshot, review_notes),
			"recommended_next_task": NEXT_REVIEW_TASK,
			"recommended_direction": "complete_left_stack_visual_review",
		})

	var positive_findings: Array = _build_positive_findings(source_snapshot, review_notes)
	var issues: Array = _build_review_issues(review_notes)
	var accepted: bool = issues.is_empty()
	var status: String = "accepted_for_left_stack_acceptance_slice" if accepted else "ready_for_left_stack_visual_polish"
	return _base_snapshot(source_snapshot, review_notes, {
		"status": status,
		"accepted": accepted,
		"blocking_issues": [],
		"issues": issues,
		"positive_findings": positive_findings,
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"recommended_next_task": NEXT_ACCEPTANCE_TASK if accepted else NEXT_POLISH_TASK,
		"recommended_direction": "left_stack_acceptance_slice" if accepted else "polish_left_stack_details",
	})


static func _build_source_blocking_issues(source_snapshot: Dictionary) -> Array:
	var issues: Array = []
	if String(source_snapshot.get("schema", "")) != SOURCE_SCHEMA:
		issues.append(_issue("source_schema_mismatch", "TASK_1164 braucht den TASK_1163-Recapture-Snapshot."))
	if String(source_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		issues.append(_issue("source_task_mismatch", "Quelle muss TASK_1163 sein."))
	var source_readability: Dictionary = Dictionary(source_snapshot.get("source_readability", {}))
	var release_capture: Dictionary = Dictionary(source_snapshot.get("release_capture", {}))
	var review_ready: bool = bool(source_readability.get("readability_ready", false)) \
		and bool(source_readability.get("event_log_readability_ready", false)) \
		and bool(source_readability.get("mini_event_no_overlap", false)) \
		and String(release_capture.get("expected_resolution", "")) == "1280x720" \
		and bool(release_capture.get("manual_visual_review_required", false))
	if not review_ready:
		issues.append(_issue("source_not_review_ready", "TASK_1163-Quelle ist noch nicht review-ready."))
	return issues


static func _build_positive_findings(source_snapshot: Dictionary, review_notes: Dictionary) -> Array:
	var findings: Array = []
	var source_readability: Dictionary = Dictionary(source_snapshot.get("source_readability", {}))
	if bool(source_readability.get("readability_ready", false)):
		findings.append(_finding("left_stack_source_readable", "TASK_1163 bestaetigt den linken Stack strukturell."))
	if int(source_readability.get("visible_card_count", 0)) >= 2:
		findings.append(_finding("two_fireteam_cards_visible", "Mindestens zwei Fireteam-Mini-Cards sind sichtbar."))
	if int(source_readability.get("focused_card_count", 0)) == 1:
		findings.append(_finding("single_primary_focus", "Genau ein Fireteam traegt den Primaerfokus."))
	if bool(source_readability.get("event_log_readability_ready", false)):
		findings.append(_finding("event_log_readability_ready", "Das Ereignislog haelt seinen 1280er Lesbarkeitsvertrag."))
	if bool(source_readability.get("mini_event_no_overlap", false)):
		findings.append(_finding("mini_event_surfaces_separated", "Mini-Cards und Ereignislog ueberlappen nicht."))
	for key in [
		"mini_cards_readable",
		"primary_focus_clear",
		"event_log_readable",
		"event_log_not_blocking_cards",
		"host_client_consistent",
		"member_strip_readable",
		"event_filter_label_readable",
		"desktop_capture_trusted",
	]:
		if bool(review_notes.get(key, false)):
			findings.append(_finding(key, _positive_label_for_key(key)))
	return findings


static func _build_review_issues(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if not bool(review_notes.get("member_strip_readable", false)):
		issues.append(_issue("mini_card_member_strip_too_small", "Mini-Card-Member-/Detailstrip bleibt im 1280er Spielerblick zu klein."))
	if not bool(review_notes.get("event_filter_label_readable", false)):
		issues.append(_issue("event_log_filter_label_dense", "Eventlog-Filter/Zaehler wirkt gedrungen und braucht ruhigere Leseflaeche."))
	if not bool(review_notes.get("desktop_capture_trusted", false)):
		issues.append(_issue("combined_desktop_capture_untrusted", "Kombiniertes Desktop-Capture kann durch fremde Fenster ueberlagert werden."))
	if not bool(review_notes.get("mini_cards_readable", false)):
		issues.append(_issue("mini_cards_not_readable", "Fireteam-Mini-Cards sind nicht ausreichend lesbar."))
	if not bool(review_notes.get("primary_focus_clear", false)):
		issues.append(_issue("primary_focus_not_clear", "Primaerfokus ist im linken Stack nicht klar genug."))
	if not bool(review_notes.get("event_log_readable", false)):
		issues.append(_issue("event_log_not_readable", "Ereignislog ist im linken Stack nicht ausreichend lesbar."))
	if not bool(review_notes.get("event_log_not_blocking_cards", false)):
		issues.append(_issue("event_log_blocks_cards", "Ereignislog konkurriert sichtbar mit den Fireteam-Mini-Cards."))
	if not bool(review_notes.get("host_client_consistent", false)):
		issues.append(_issue("host_client_left_stack_inconsistent", "Host und Client lesen den linken Stack nicht konsistent."))
	return issues


static func _base_snapshot(source_snapshot: Dictionary, review_notes: Dictionary, state: Dictionary) -> Dictionary:
	var issues: Array = Array(state.get("issues", []))
	var positive_findings: Array = Array(state.get("positive_findings", []))
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_snapshot.get("schema", "")),
		"source_status": String(source_snapshot.get("status", "")),
		"source_readability": Dictionary(source_snapshot.get("source_readability", {})).duplicate(true),
		"release_capture": Dictionary(source_snapshot.get("release_capture", {})).duplicate(true),
		"review_notes": review_notes.duplicate(true),
		"status": String(state.get("status", "")),
		"accepted": bool(state.get("accepted", false)),
		"blocking_issues": Array(state.get("blocking_issues", [])).duplicate(true),
		"blocking_issue_count": Array(state.get("blocking_issues", [])).size(),
		"issues": issues.duplicate(true),
		"issue_count": issues.size(),
		"primary_issue_id": String(state.get("primary_issue_id", "")),
		"positive_findings": positive_findings.duplicate(true),
		"positive_finding_count": positive_findings.size(),
		"recommended_next_task": String(state.get("recommended_next_task", NEXT_REVIEW_TASK)),
		"recommended_direction": String(state.get("recommended_direction", "")),
		"left_stack_visual_findings_summary_line": _build_summary_line(issues),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_effect": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


static func _build_summary_line(issues: Array) -> String:
	if issues.is_empty():
		return "MINI klar | EVENT lesbar | FOCUS eindeutig | naechster Slice bereit"
	return "MINI/Event-Details polieren | FOCUS bleibt | %d Befunde" % issues.size()


static func _positive_label_for_key(key: String) -> String:
	match key:
		"mini_cards_readable":
			return "Mini-Cards sind im Fenster lesbar."
		"primary_focus_clear":
			return "Primaerfokus ist klar."
		"event_log_readable":
			return "Ereignislog ist lesbar."
		"event_log_not_blocking_cards":
			return "Ereignislog blockiert die Mini-Cards nicht."
		"host_client_consistent":
			return "Host und Client zeigen konsistente linke Stack-Flaechen."
		"member_strip_readable":
			return "Member-/Detailstrip ist lesbar."
		"event_filter_label_readable":
			return "Eventlog-Filter ist lesbar."
		"desktop_capture_trusted":
			return "Kombiniertes Desktop-Capture ist vertrauenswuerdig."
	return key


static func _issue(id: String, summary: String) -> Dictionary:
	return {
		"id": id,
		"summary": summary,
		"severity": "visual",
	}


static func _finding(id: String, summary: String) -> Dictionary:
	return {
		"id": id,
		"summary": summary,
	}
