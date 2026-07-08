class_name ReleaseFirefightWorldLabelVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_firefight_world_label_visual_findings.v1"
const TASK_ID: String = "TASK_841"
const SOURCE_TASK_ID: String = "TASK_840"
const EXPECTED_DENSITY_MODE: String = "release_firefight_declutter"
const EXPECTED_STYLE_ID: String = "task_839_release_firefight_world_label_declutter_v1"
const NEXT_TASK: String = "TASK_842 - Release Firefight Insertion Residue Declutter"
const SECONDARY_NEXT_TASK: String = "TASK_843 - Release First Firefight Contact Framing"


static func build_snapshot(recapture_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var manifest_gate: String = String(recapture_manifest.get("gate", "")).strip_edges()
	var density_mode: String = String(recapture_manifest.get("expected_world_label_density_mode", "")).strip_edges()
	var style_id: String = String(recapture_manifest.get("expected_world_label_declutter_style_id", "")).strip_edges()
	var required_checks: Array = Array(recapture_manifest.get("required_checks", []))
	var screenshot_written: bool = bool(recapture_manifest.get("window_screenshot_written", false))
	var manual_review_done: bool = bool(recapture_manifest.get("manual_review_done", false))
	var manual_notes_present: bool = not review_notes.is_empty()

	var positives: Array = _build_positive_findings(review_notes, required_checks)
	var issues: Array = _build_issue_findings(review_notes)
	var blocking_issues: Array = _build_blocking_issues(manifest_gate, density_mode, style_id, screenshot_written)
	var warnings: Array = []
	for issue in issues:
		if String(Dictionary(issue).get("severity", "")) == "warning":
			warnings.append(issue)

	var status: String = "blocked" if not blocking_issues.is_empty() else "ready_for_polish"
	if status == "ready_for_polish" and not manual_notes_present:
		status = "needs_manual_review"

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_declutter_task_id": "TASK_839",
		"source_capture_task_id": "TASK_837",
		"recapture_gate": manifest_gate,
		"recapture_manifest_present": not recapture_manifest.is_empty(),
		"window_screenshot_written": screenshot_written,
		"window_screenshot_path": String(recapture_manifest.get("window_screenshot_path", "")),
		"expected_world_label_density_mode": density_mode,
		"expected_world_label_declutter_style_id": style_id,
		"density_mode_ok": density_mode == EXPECTED_DENSITY_MODE,
		"style_id_ok": style_id == EXPECTED_STYLE_ID,
		"manual_review_required": true,
		"manual_review_done": manual_review_done,
		"manual_notes_present": manual_notes_present,
		"positive_findings": positives,
		"positive_finding_count": positives.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blocking_issues,
		"blocking_issue_count": blocking_issues.size(),
		"warning_count": warnings.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"recommended_next_task": NEXT_TASK,
		"secondary_recommended_next_task": SECONDARY_NEXT_TASK,
		"status": status,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


static func _build_positive_findings(review_notes: Dictionary, required_checks: Array) -> Array:
	var positives: Array = []
	if bool(review_notes.get("world_label_density_improved", false)) or required_checks.has("world_labels_less_dense_than_task_837"):
		positives.append({
			"id": "world_label_density_improved",
			"text": "Routine-Welttexte sind sichtbar reduziert; Karte, HUD und Command-Matrix konkurrieren weniger stark.",
		})
	if bool(review_notes.get("hud_detail_surfaces_readable", false)) or required_checks.has("event_log_or_fallback_still_carries_detail"):
		positives.append({
			"id": "hud_detail_surfaces_readable",
			"text": "Selected Fireteam, Mission Control und Event-Log tragen die Entscheidungsdetails weiter.",
		})
	if bool(review_notes.get("command_matrix_visible", false)) or required_checks.has("command_matrix_go_still_visible"):
		positives.append({
			"id": "command_matrix_visible",
			"text": "GO und Fire-Rule bleiben im unteren Command-Bereich lesbar.",
		})
	return positives


static func _build_issue_findings(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "insertion_residue_visible", "insertion_residue_world_labels", true):
		issues.append({
			"id": "insertion_residue_world_labels",
			"severity": "polish",
			"text": "Approach-/ETA-Welttext und die gruene Dropship-Route bleiben im Firefight sichtbar und fuehlen sich wie Insertionsreste an.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "first_firefight_has_no_fire", "first_firefight_no_fire_contact", true):
		issues.append({
			"id": "first_firefight_no_fire_contact",
			"severity": "warning",
			"text": "Der Capture zeigt starke Entscheidungslesbarkeit, aber noch keinen eigentlichen Schusswechsel: `NO FIRE LOS/RANGE` dominiert.",
			"recommended_task": SECONDARY_NEXT_TASK,
		})
	if bool(review_notes.get("map_text_near_units_crowded", true)):
		issues.append({
			"id": "map_text_near_units_crowded",
			"severity": "polish",
			"text": "Resttexte nahe der oberen Einheitengruppe kleben zu nah am Bewegungs-/Kontaktbereich.",
			"recommended_task": NEXT_TASK,
		})
	return issues


static func _review_flag(review_notes: Dictionary, primary_key: String, alias_key: String, default_value: bool) -> bool:
	if review_notes.has(primary_key):
		return bool(review_notes.get(primary_key))
	if review_notes.has(alias_key):
		return bool(review_notes.get(alias_key))
	return default_value


static func _build_blocking_issues(manifest_gate: String, density_mode: String, style_id: String, screenshot_written: bool) -> Array:
	var blockers: Array = []
	if manifest_gate != "review_ready":
		blockers.append({"id": "recapture_not_review_ready", "text": "TASK_840-Recapture ist nicht review_ready."})
	if not screenshot_written:
		blockers.append({"id": "window_screenshot_missing", "text": "TASK_840-Window-Screenshot fehlt."})
	if density_mode != EXPECTED_DENSITY_MODE:
		blockers.append({"id": "density_mode_mismatch", "text": "Recapture nennt nicht den erwarteten Declutter-Density-Mode."})
	if style_id != EXPECTED_STYLE_ID:
		blockers.append({"id": "style_id_mismatch", "text": "Recapture nennt nicht die erwartete TASK_839-Style-ID."})
	return blockers
