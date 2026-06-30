class_name MissionHostClientDoorRealClickFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.host_client_door_real_click_findings.v1"
const DEFAULT_FINDINGS_MANIFEST_PATH: String = "tmp/host_client_door_real_click_findings.json"
const DEFAULT_WORKBENCH_MANIFEST_PATH: String = "tmp/host_client_door_real_click_workbench.json"
const DEFAULT_CAPTURE_MANIFEST_PATH: String = "tmp/multiplayer_door_feedback_capture.json"


static func build_snapshot(capture_snapshot: Dictionary = {}, workbench_snapshot: Dictionary = {}, existing_notes: Dictionary = {}) -> Dictionary:
	var manual_review_done: bool = bool(workbench_snapshot.get("manual_review_done", false)) or _get_nested_bool(existing_notes, ["manual_review_done"], false) or _get_nested_bool(existing_notes, ["controls", "door_real_click", "manual_review_done"], false)
	var manual_click_findings_gate: String = "manual_done" if manual_review_done else "manual_still_open"
	var technical_path_gate: String = "pass" if String(capture_snapshot.get("gate", "")).strip_edges().to_lower() == "pass" else "missing_or_failed"
	var completed_check_count: int = int(workbench_snapshot.get("completed_check_count", 0))
	var required_check_count: int = int(workbench_snapshot.get("required_check_count", 0))
	var confirmed_findings: Array = _build_confirmed_findings(capture_snapshot)
	var open_manual_findings: Array = _build_open_manual_findings(workbench_snapshot)
	var negative_note_detected: bool = _has_negative_note(existing_notes) or _workbench_has_negative_note(workbench_snapshot)
	var recommended_next_task: String = _recommended_next_task(manual_review_done, negative_note_detected)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"source": "MissionHostClientDoorRealClickFindings",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_review_required": true,
		"manual_review_done": manual_review_done,
		"manual_click_findings_gate": manual_click_findings_gate,
		"technical_path_gate": technical_path_gate,
		"source_capture_schema": String(capture_snapshot.get("schema", "")),
		"source_capture_gate": String(capture_snapshot.get("gate", "")),
		"source_capture_manifest_path": String(capture_snapshot.get("manifest_path", DEFAULT_CAPTURE_MANIFEST_PATH)),
		"source_workbench_schema": String(workbench_snapshot.get("schema", "")),
		"source_workbench_status": String(workbench_snapshot.get("status", "")),
		"source_workbench_manifest_path": String(workbench_snapshot.get("manifest_path", DEFAULT_WORKBENCH_MANIFEST_PATH)),
		"completed_check_count": completed_check_count,
		"required_check_count": required_check_count,
		"confirmed_findings": confirmed_findings,
		"open_manual_findings": open_manual_findings,
		"negative_note_detected": negative_note_detected,
		"summary": _build_summary(technical_path_gate, manual_click_findings_gate, completed_check_count, required_check_count),
		"manual_next_action": "Run the real two-window Door click flow and export the TASK_700 workbench notes.",
		"recommended_next_task": recommended_next_task,
		"manifest_path": DEFAULT_FINDINGS_MANIFEST_PATH,
	}


static func _build_confirmed_findings(capture_snapshot: Dictionary) -> Array:
	var findings: Array = []
	if String(capture_snapshot.get("host_status", "")).strip_edges().to_lower() in ["accepted", "open"]:
		findings.append("host_command_feedback_visible")
	if String(capture_snapshot.get("wrong_team_status", "")).strip_edges().to_lower() == "blocked":
		findings.append("wrong_team_reject_visible")
	if String(capture_snapshot.get("state_mutation_status", "")).strip_edges().to_lower() == "blocked":
		findings.append("state_mutation_reject_visible")
	if String(capture_snapshot.get("open_status", "")).strip_edges().to_lower() == "open":
		findings.append("door_open_feedback_bound_to_runtime_producer")
	if String(capture_snapshot.get("wrong_team_reason", "")).strip_edges() == "peer_team_mismatch":
		findings.append("wrong_team_reason_peer_team_mismatch")
	if String(capture_snapshot.get("state_mutation_reason", "")).strip_edges().begins_with("state_mutation_key:"):
		findings.append("state_mutation_reason_preserved")
	return findings


static func _build_open_manual_findings(workbench_snapshot: Dictionary) -> Array:
	var open_findings: Array = []
	var required_checks: Array = Array(workbench_snapshot.get("required_checks", []))
	for check_variant in required_checks:
		if typeof(check_variant) != TYPE_DICTIONARY:
			continue
		var check: Dictionary = Dictionary(check_variant)
		if bool(check.get("checked", false)):
			continue
		open_findings.append(String(check.get("id", "")).strip_edges())
	if open_findings.is_empty():
		open_findings = [
			"host_window_launched",
			"client_window_launched",
			"host_door_button_visible",
			"client_door_button_visible",
			"shortcut_b_triggers_hook",
			"go_required_visible",
			"wrong_team_reject_visible",
			"door_open_visible_on_host",
			"door_open_visible_on_client",
			"hud_feedback_readable",
		]
	return open_findings


static func _recommended_next_task(manual_review_done: bool, negative_note_detected: bool) -> String:
	if not manual_review_done:
		return "TASK_705 - Host/Client Door Real Click Manual Run Packet"
	if negative_note_detected:
		return "TASK_706 - Mission Door Layout/Visual Polish"
	return "TASK_706 - Host/Client Door Flow Acceptance"


static func _build_summary(technical_path_gate: String, manual_click_findings_gate: String, completed_check_count: int, required_check_count: int) -> String:
	return "Door real-click findings: technical=%s, manual=%s, checks=%d/%d" % [technical_path_gate, manual_click_findings_gate, completed_check_count, required_check_count]


static func _workbench_has_negative_note(workbench_snapshot: Dictionary) -> bool:
	var note_fields: Array = Array(workbench_snapshot.get("note_fields", []))
	for field_variant in note_fields:
		if typeof(field_variant) != TYPE_DICTIONARY:
			continue
		var text: String = String(Dictionary(field_variant).get("value", "")).to_lower()
		if _text_is_negative(text):
			return true
	return false


static func _has_negative_note(existing_notes: Dictionary) -> bool:
	var fields: Array = ["host_observation", "client_observation", "reject_feedback_notes", "door_open_notes", "timing_notes", "next_polish_action"]
	for field in fields:
		var text: String = _get_nested_string(existing_notes, ["notes", field], "").to_lower()
		if text.is_empty():
			text = _get_nested_string(existing_notes, ["controls", "door_real_click", field], "").to_lower()
		if _text_is_negative(text):
			return true
	return false


static func _text_is_negative(text: String) -> bool:
	return text.contains("unklar") or text.contains("fehlt") or text.contains("verdeckt") or text.contains("zu langsam") or text.contains("blockiert") or text.contains("kaputt") or text.contains("schlecht")


static func _get_nested_bool(source: Dictionary, path: Array, fallback: bool) -> bool:
	var current: Variant = source
	for key_variant in path:
		if typeof(current) != TYPE_DICTIONARY:
			return fallback
		var key: String = String(key_variant)
		var current_dict: Dictionary = Dictionary(current)
		if not current_dict.has(key):
			return fallback
		current = current_dict[key]
	return bool(current)


static func _get_nested_string(source: Dictionary, path: Array, fallback: String) -> String:
	var current: Variant = source
	for key_variant in path:
		if typeof(current) != TYPE_DICTIONARY:
			return fallback
		var key: String = String(key_variant)
		var current_dict: Dictionary = Dictionary(current)
		if not current_dict.has(key):
			return fallback
		current = current_dict[key]
	return String(current)
