class_name StationRouteWindowPlaytestNotes
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_route_window_playtest_notes.v1"
const DEFAULT_REPORT_PATH: String = "docs/reports/station_route_window_playtest_notes_2026_07_01.html"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_route_window_playtest_notes.json"


static func build_snapshot(evidence_manifest: Dictionary = {}, existing_notes: Dictionary = {}) -> Dictionary:
	var manual_review_required: bool = bool(evidence_manifest.get("manual_window_review_required", true))
	var manual_review_done: bool = _manual_review_done(evidence_manifest, existing_notes)
	var required_checks: Array = _build_required_checks(existing_notes)
	var note_fields: Array = _build_note_fields(existing_notes)
	var completed_check_count: int = _count_completed_checks(required_checks)
	var rating: String = String(existing_notes.get("rating", "open"))
	var status: String = "complete" if manual_review_done else "awaiting_manual_notes"
	var recommended_next_task: String = _recommended_next_task(manual_review_done, rating, existing_notes)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"runtime_authority": "manual station route review notes only",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_window_review_required": manual_review_required,
		"manual_window_review_done": manual_review_done,
		"manual_review_required": manual_review_required,
		"manual_review_done": manual_review_done,
		"manual_review_status": status,
		"status": status,
		"rating": rating,
		"source_evidence_schema": String(evidence_manifest.get("schema", "")),
		"source_evidence_status": String(evidence_manifest.get("status", "")),
		"source_evidence_png_path": String(evidence_manifest.get("png_path", "tmp/station_route_visual_evidence.png")),
		"source_evidence_manifest_path": String(evidence_manifest.get("manifest_path", "tmp/station_route_visual_evidence.json")),
		"generated_evidence_board": bool(evidence_manifest.get("generated_evidence_board", false)),
		"viewport_readback_available": bool(evidence_manifest.get("viewport_readback_available", false)),
		"door_runtime_visual_state": String(evidence_manifest.get("door_runtime_visual_state", "")),
		"door_layout_tone": String(evidence_manifest.get("door_layout_tone", "")),
		"all_gates_complete": bool(evidence_manifest.get("all_gates_complete", false)),
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


static func _manual_review_done(evidence_manifest: Dictionary, existing_notes: Dictionary) -> bool:
	if bool(existing_notes.get("manual_window_review_done", false)):
		return true
	var checks: Dictionary = Dictionary(existing_notes.get("checks", {}))
	if bool(checks.get("manual_window_review_done", false)):
		return true
	return bool(evidence_manifest.get("manual_window_review_done", false))


static func _build_required_checks(existing_notes: Dictionary) -> Array:
	return [
		_check("real_window_launched", "Echte Godot-Fensteransicht gestartet", existing_notes),
		_check("door_open_readable", "Door closed/open/opening ist ohne Suche lesbar", existing_notes),
		_check("computer_state_clear", "Computer-Control-Schritt ist erkennbar", existing_notes),
		_check("cargo_state_clear", "Cargo-Landing/Departed-Schritt ist erkennbar", existing_notes),
		_check("hud_not_blocking_route", "HUD verdeckt Door/Computer/Cargo nicht", existing_notes),
		_check("camera_default_ok", "Kamera/Zoom zeigt die Stationsroute brauchbar", existing_notes),
		_check("framerate_feels_ok", "Fensterlauf fuehlt sich fluessig genug an", existing_notes),
		_check("manual_window_review_done", "Menschlicher Sichtentscheid bewusst gesetzt", existing_notes),
	]


static func _build_note_fields(existing_notes: Dictionary) -> Array:
	return [
		_note_field("overall_readability", "Gesamteindruck Lesbarkeit", existing_notes),
		_note_field("door_notes", "Door-Notizen", existing_notes),
		_note_field("computer_cargo_notes", "Computer-/Cargo-Notizen", existing_notes),
		_note_field("hud_overlap_notes", "HUD-/Overlap-Notizen", existing_notes),
		_note_field("performance_notes", "Performance-/Fensterlauf-Notizen", existing_notes),
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


static func _recommended_next_task(manual_review_done: bool, rating: String, existing_notes: Dictionary) -> String:
	if not manual_review_done:
		return "TASK_709 - Station Route Window Playtest Notes"
	if rating == "needs_polish" or rating == "blocked" or _has_negative_note(existing_notes):
		return "TASK_710 - Station Route Visual Polish Findings"
	return "TASK_710 - Station Route Host/Client Door Flow Acceptance"


static func _has_negative_note(existing_notes: Dictionary) -> bool:
	var notes: Dictionary = Dictionary(existing_notes.get("notes", {}))
	for value in notes.values():
		var text: String = String(value).to_lower()
		if text.contains("zu klein") or text.contains("verdeckt") or text.contains("unklar") or text.contains("ruckelt") or text.contains("blockiert"):
			return true
	return false


static func _build_summary(manual_review_done: bool, completed_check_count: int, required_check_count: int) -> String:
	if manual_review_done:
		return "Stationsroute-Fensterbefund notiert, %d/%d Checks gesetzt" % [completed_check_count, required_check_count]
	return "Stationsroute-Fensterbefund offen, %d/%d Checks gesetzt" % [completed_check_count, required_check_count]
