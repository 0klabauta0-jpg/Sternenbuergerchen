class_name MissionMultiplayerDoorFeedbackCapture
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.mission_multiplayer_door_feedback_capture.v1"


static func build_snapshot(capture_context: Dictionary = {}) -> Dictionary:
	var host_feedback: Dictionary = Dictionary(capture_context.get("host_feedback", {}))
	var wrong_team_feedback: Dictionary = Dictionary(capture_context.get("wrong_team_feedback", {}))
	var state_mutation_feedback: Dictionary = Dictionary(capture_context.get("state_mutation_feedback", {}))
	var open_feedback: Dictionary = Dictionary(capture_context.get("open_feedback", {}))
	var host_authority: Dictionary = Dictionary(capture_context.get("host_authority", {}))
	var wrong_team_authority: Dictionary = Dictionary(capture_context.get("wrong_team_authority", {}))
	var state_mutation_authority: Dictionary = Dictionary(capture_context.get("state_mutation_authority", {}))
	var open_authority: Dictionary = Dictionary(capture_context.get("open_authority", {}))

	var checks: Array = [
		_check("host_feedback_present", not host_feedback.is_empty(), "Host Door feedback is captured."),
		_check("host_accept_visible", _status_is_one_of(host_feedback, PackedStringArray(["accepted", "open"])) and bool(host_authority.get("host_command_accepted", false)), "Host readout exposes accepted/open Own-Team command."),
		_check("wrong_team_blocked", String(wrong_team_feedback.get("status", "")).strip_edges().to_lower() == "blocked" and bool(wrong_team_authority.get("foreign_team_rejected", false)), "Wrong-team client readout is blocked."),
		_check("wrong_team_reason_visible", String(wrong_team_feedback.get("detail_line", "")).contains(String(wrong_team_authority.get("foreign_team_reject_reason", ""))), "Wrong-team reject reason is visible."),
		_check("state_mutation_blocked", String(state_mutation_feedback.get("status", "")).strip_edges().to_lower() == "blocked" and bool(state_mutation_authority.get("state_mutation_rejected", false)), "State-mutation client payload is blocked."),
		_check("state_mutation_reason_visible", String(state_mutation_feedback.get("detail_line", "")).contains("state_mutation_key"), "State-mutation reject reason is visible."),
		_check("open_feedback_producer_bound", String(open_feedback.get("status", "")).strip_edges().to_lower() == "open" and bool(open_authority.get("door_runtime_open_override", false)), "Open readout is bound to Door Runtime producer."),
		_check("read_only", _all_read_only([host_feedback, wrong_team_feedback, state_mutation_feedback, open_feedback, host_authority, wrong_team_authority, state_mutation_authority, open_authority]), "Capture reads snapshots and does not set gameplay truth."),
	]
	var failed_checks: PackedStringArray = PackedStringArray()
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_checks.append(String(check.get("id", "")))
	return {
		"schema": SNAPSHOT_SCHEMA,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"source": "MissionMultiplayerDoorFeedbackCapture",
		"host_status": String(host_feedback.get("status", "")).strip_edges().to_lower(),
		"wrong_team_status": String(wrong_team_feedback.get("status", "")).strip_edges().to_lower(),
		"state_mutation_status": String(state_mutation_feedback.get("status", "")).strip_edges().to_lower(),
		"open_status": String(open_feedback.get("status", "")).strip_edges().to_lower(),
		"host_line": String(host_feedback.get("summary_line", "")).strip_edges(),
		"wrong_team_line": String(wrong_team_feedback.get("summary_line", "")).strip_edges(),
		"state_mutation_line": String(state_mutation_feedback.get("summary_line", "")).strip_edges(),
		"open_line": String(open_feedback.get("summary_line", "")).strip_edges(),
		"wrong_team_reason": String(wrong_team_authority.get("foreign_team_reject_reason", "")).strip_edges(),
		"state_mutation_reason": String(state_mutation_authority.get("state_mutation_reject_reason", "")).strip_edges(),
		"host_feedback": host_feedback.duplicate(true),
		"wrong_team_feedback": wrong_team_feedback.duplicate(true),
		"state_mutation_feedback": state_mutation_feedback.duplicate(true),
		"open_feedback": open_feedback.duplicate(true),
		"checks": checks,
		"failed_checks": failed_checks,
		"gate": "pass" if failed_checks.is_empty() else "review",
		"summary": _build_summary(host_feedback, wrong_team_feedback, state_mutation_feedback, open_feedback, failed_checks),
	}


static func _status_is_one_of(feedback: Dictionary, allowed: PackedStringArray) -> bool:
	return allowed.has(String(feedback.get("status", "")).strip_edges().to_lower())


static func _all_read_only(snapshots: Array) -> bool:
	for snapshot_variant in snapshots:
		if typeof(snapshot_variant) != TYPE_DICTIONARY:
			return false
		var snapshot: Dictionary = Dictionary(snapshot_variant)
		if snapshot.is_empty():
			return false
		if not bool(snapshot.get("read_only", false)):
			return false
		if bool(snapshot.get("ui_sets_gameplay_truth", true)):
			return false
	return true


static func _check(id: String, passed: bool, detail: String) -> Dictionary:
	return {
		"id": id,
		"passed": passed,
		"detail": detail,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _build_summary(host_feedback: Dictionary, wrong_team_feedback: Dictionary, state_mutation_feedback: Dictionary, open_feedback: Dictionary, failed_checks: PackedStringArray) -> String:
	if failed_checks.is_empty():
		return "Door feedback capture OK: host accepted/open, wrong-team and state-mutation blocked, producer-open visible."
	return "Door feedback capture review: %s" % ", ".join(failed_checks)
