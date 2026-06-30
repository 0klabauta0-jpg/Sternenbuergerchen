class_name MissionInteractionManualSightNotes
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.mission_interaction_manual_sight_notes.v1"
const DEFAULT_REPORT_PATH: String = "docs/reports/mission_interaction_manual_sight_notes_2026_06_30.html"
const DEFAULT_MANIFEST_PATH: String = "tmp/mission_interaction_manual_sight_notes.json"


static func build_snapshot(polish_findings: Dictionary = {}, evidence_manifest: Dictionary = {}, existing_notes: Dictionary = {}) -> Dictionary:
	var manual_review_required: bool = bool(evidence_manifest.get("manual_fullhd_review_required", true))
	var manual_review_done: bool = bool(existing_notes.get("manual_review_done", false)) or bool(evidence_manifest.get("manual_fullhd_review_done", false))
	var required_checks: Array = _build_required_checks(existing_notes)
	var note_fields: Array = _build_note_fields(existing_notes)
	var completed_check_count: int = _count_completed_checks(required_checks)
	var status: String = "complete" if manual_review_done else "awaiting_manual_notes"
	var recommended_next_task: String = "TASK_691 - Mission Interaction Visual Polish"
	if not manual_review_done:
		recommended_next_task = "TASK_691 - Mission Interaction Manual Sight Review"
	elif _has_negative_note(existing_notes):
		recommended_next_task = "TASK_691 - Mission Interaction Visual Polish"
	return {
		"schema": SNAPSHOT_SCHEMA,
		"runtime_authority": "manual review notes only",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_review_required": manual_review_required,
		"manual_review_done": manual_review_done,
		"manual_review_status": status,
		"status": status,
		"source_polish_schema": String(polish_findings.get("schema", "")),
		"source_evidence_schema": String(evidence_manifest.get("schema", "")),
		"source_polish_status": String(polish_findings.get("status", "")),
		"source_polish_summary": String(polish_findings.get("summary", "")),
		"source_evidence_png_path": String(evidence_manifest.get("png_path", "tmp/mission_interaction_fullhd_evidence.png")),
		"source_evidence_manifest_path": String(evidence_manifest.get("manifest_path", "tmp/mission_interaction_fullhd_evidence.json")),
		"source_polish_manifest_path": String(polish_findings.get("manifest_path", "tmp/mission_interaction_visual_polish_findings.json")),
		"report_path": DEFAULT_REPORT_PATH,
		"manifest_path": DEFAULT_MANIFEST_PATH,
		"required_checks": required_checks,
		"required_check_count": required_checks.size(),
		"completed_check_count": completed_check_count,
		"note_fields": note_fields,
		"note_field_count": note_fields.size(),
		"summary": _build_summary(manual_review_done, completed_check_count, required_checks.size()),
		"recommended_next_task": recommended_next_task,
	}


static func _build_required_checks(existing_notes: Dictionary) -> Array:
	return [
		_check("real_window_launched", "Echte Godot-Fensteransicht gestartet", existing_notes),
		_check("labels_readable", "AA/COM/CARGO-Labels sind in FullHD lesbar", existing_notes),
		_check("object_proxies_helpful", "Objekt-Proxies helfen beim Erkennen der Interactions", existing_notes),
		_check("hud_not_blocked", "HUD verdeckt keine wichtige Missionsentscheidung", existing_notes),
		_check("proxy_scale_ok", "Proxy-Groessen wirken nicht zu dominant", existing_notes),
		_check("label_scale_ok", "Label-Groessen wirken nicht zu klein oder zu gross", existing_notes),
	]


static func _build_note_fields(existing_notes: Dictionary) -> Array:
	return [
		_note_field("overall_readability", "Gesamteindruck Lesbarkeit", existing_notes),
		_note_field("label_notes", "Label-Notizen", existing_notes),
		_note_field("object_proxy_notes", "Objekt-Proxy-Notizen", existing_notes),
		_note_field("hud_overlap_notes", "HUD-/Overlap-Notizen", existing_notes),
		_note_field("next_polish_action", "Naechste konkrete Polish-Aktion", existing_notes),
	]


static func _check(id: String, label: String, existing_notes: Dictionary) -> Dictionary:
	var checks: Dictionary = Dictionary(existing_notes.get("checks", {}))
	return {
		"id": id,
		"label": label,
		"checked": bool(checks.get(id, false)),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _note_field(id: String, label: String, existing_notes: Dictionary) -> Dictionary:
	var notes: Dictionary = Dictionary(existing_notes.get("notes", {}))
	return {
		"id": id,
		"label": label,
		"value": String(notes.get(id, "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _count_completed_checks(required_checks: Array) -> int:
	var count: int = 0
	for check_variant in required_checks:
		if typeof(check_variant) == TYPE_DICTIONARY and bool(Dictionary(check_variant).get("checked", false)):
			count += 1
	return count


static func _has_negative_note(existing_notes: Dictionary) -> bool:
	var notes: Dictionary = Dictionary(existing_notes.get("notes", {}))
	for value in notes.values():
		var text: String = String(value).to_lower()
		if text.contains("zu klein") or text.contains("verdeckt") or text.contains("stoert") or text.contains("unklar"):
			return true
	return false


static func _build_summary(manual_review_done: bool, completed_check_count: int, required_check_count: int) -> String:
	if manual_review_done:
		return "manueller Sichtlauf notiert, %d/%d Checks gesetzt" % [completed_check_count, required_check_count]
	return "manueller Sichtlauf offen, %d/%d Checks gesetzt" % [completed_check_count, required_check_count]
