class_name MissionHostClientDoorRealClickWorkbench
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.host_client_door_real_click_workbench.v1"
const DEFAULT_REPORT_PATH: String = "docs/reports/host_client_door_real_click_workbench_2026_06_30.html"
const DEFAULT_MANIFEST_PATH: String = "tmp/host_client_door_real_click_workbench.json"
const DEFAULT_CAPTURE_MANIFEST_PATH: String = "tmp/multiplayer_door_feedback_capture.json"


static func build_snapshot(capture_snapshot: Dictionary = {}, existing_notes: Dictionary = {}) -> Dictionary:
	var manual_review_required: bool = true
	var manual_review_done: bool = _get_nested_bool(existing_notes, ["manual_review_done"], false) or _get_nested_bool(existing_notes, ["controls", "door_real_click", "manual_review_done"], false)
	var required_checks: Array = _build_required_checks(existing_notes)
	var note_fields: Array = _build_note_fields(existing_notes)
	var completed_check_count: int = _count_completed_checks(required_checks)
	var status: String = "complete" if manual_review_done else "awaiting_real_click_notes"
	return {
		"schema": SNAPSHOT_SCHEMA,
		"runtime_authority": "manual host/client click notes only",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_review_required": manual_review_required,
		"manual_review_done": manual_review_done,
		"manual_review_status": status,
		"status": status,
		"source_capture_schema": String(capture_snapshot.get("schema", "")),
		"source_capture_gate": String(capture_snapshot.get("gate", "")),
		"source_capture_summary": String(capture_snapshot.get("summary", "")),
		"source_capture_manifest_path": String(capture_snapshot.get("manifest_path", DEFAULT_CAPTURE_MANIFEST_PATH)),
		"report_path": DEFAULT_REPORT_PATH,
		"manifest_path": DEFAULT_MANIFEST_PATH,
		"required_checks": required_checks,
		"required_check_count": required_checks.size(),
		"completed_check_count": completed_check_count,
		"note_fields": note_fields,
		"note_field_count": note_fields.size(),
		"summary": _build_summary(manual_review_done, completed_check_count, required_checks.size()),
		"recommended_next_task": _recommended_next_task(manual_review_done, existing_notes),
	}


static func _build_required_checks(existing_notes: Dictionary) -> Array:
	return [
		_check("host_window_launched", "Host-Fenster gestartet und Mission geladen", existing_notes),
		_check("client_window_launched", "Client-Fenster verbunden und Mission geladen", existing_notes),
		_check("host_door_button_visible", "Host sieht Door-Breach-Button und Tooltip", existing_notes),
		_check("client_door_button_visible", "Client sieht Door-Breach-Button und Tooltip", existing_notes),
		_check("shortcut_b_triggers_hook", "Shortcut B triggert denselben Door-Hook wie der Button", existing_notes),
		_check("go_required_visible", "GO-Pflicht bleibt sichtbar, kein Sofort-Commit im UI", existing_notes),
		_check("wrong_team_reject_visible", "Falsches Team bekommt lesbares Reject-Feedback", existing_notes),
		_check("door_open_visible_on_host", "Door-Open ist im Host-Fenster sichtbar", existing_notes),
		_check("door_open_visible_on_client", "Door-Open ist im Client-Fenster sichtbar", existing_notes),
		_check("hud_feedback_readable", "HUD-Feedback ist ohne Log-Suche lesbar", existing_notes),
	]


static func _build_note_fields(existing_notes: Dictionary) -> Array:
	return [
		_note_field("host_observation", "Host-Beobachtung", existing_notes),
		_note_field("client_observation", "Client-Beobachtung", existing_notes),
		_note_field("reject_feedback_notes", "Reject-Feedback-Notizen", existing_notes),
		_note_field("door_open_notes", "Door-Open-Notizen", existing_notes),
		_note_field("timing_notes", "Timing-/Delay-Notizen", existing_notes),
		_note_field("next_polish_action", "Naechste konkrete Polish-Aktion", existing_notes),
	]


static func _check(id: String, label: String, existing_notes: Dictionary) -> Dictionary:
	var checked: bool = _get_nested_bool(existing_notes, ["checks", id], false) or _get_nested_bool(existing_notes, ["controls", "door_real_click", id], false)
	return {
		"id": id,
		"label": label,
		"checked": checked,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _note_field(id: String, label: String, existing_notes: Dictionary) -> Dictionary:
	var value: String = _get_nested_string(existing_notes, ["notes", id], "")
	if value.is_empty():
		value = _get_nested_string(existing_notes, ["controls", "door_real_click", id], "")
	return {
		"id": id,
		"label": label,
		"value": value,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _count_completed_checks(required_checks: Array) -> int:
	var count: int = 0
	for check_variant in required_checks:
		if typeof(check_variant) == TYPE_DICTIONARY and bool(Dictionary(check_variant).get("checked", false)):
			count += 1
	return count


static func _recommended_next_task(manual_review_done: bool, existing_notes: Dictionary) -> String:
	if not manual_review_done:
		return "TASK_702 - Host/Client Door Real Click Findings"
	if _has_negative_note(existing_notes):
		return "TASK_702 - Mission Door Layout/Visual Polish"
	return "TASK_702 - Host/Client Door Flow Acceptance"


static func _has_negative_note(existing_notes: Dictionary) -> bool:
	var fields: Array = ["host_observation", "client_observation", "reject_feedback_notes", "door_open_notes", "timing_notes", "next_polish_action"]
	for field in fields:
		var text: String = _get_nested_string(existing_notes, ["notes", field], "").to_lower()
		if text.is_empty():
			text = _get_nested_string(existing_notes, ["controls", "door_real_click", field], "").to_lower()
		if text.contains("unklar") or text.contains("fehlt") or text.contains("verdeckt") or text.contains("zu langsam") or text.contains("blockiert") or text.contains("kaputt"):
			return true
	return false


static func _build_summary(manual_review_done: bool, completed_check_count: int, required_check_count: int) -> String:
	if manual_review_done:
		return "Host/Client-Door-Klicklauf notiert, %d/%d Checks gesetzt" % [completed_check_count, required_check_count]
	return "Host/Client-Door-Klicklauf offen, %d/%d Checks gesetzt" % [completed_check_count, required_check_count]


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
