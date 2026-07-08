class_name ReleaseFireExchangeVisualPolishFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_fire_exchange_visual_polish_findings.v1"
const TASK_ID: String = "TASK_849"
const SOURCE_TASK_ID: String = "TASK_848"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_845"
const SOURCE_VISIBILITY_TASK_ID: String = "TASK_847"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const EXPECTED_ACCEPTANCE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_recapture_acceptance.v1"
const NEXT_TASK: String = "TASK_850 - Release Fire Exchange Focused Visual Polish"


static func build_snapshot(acceptance_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var acceptance_schema: String = String(acceptance_manifest.get("schema", "")).strip_edges()
	var acceptance_task_id: String = String(acceptance_manifest.get("task_id", "")).strip_edges()
	var acceptance_status: String = String(acceptance_manifest.get("status", "")).strip_edges()
	var recapture_gate: String = String(acceptance_manifest.get("recapture_gate", "")).strip_edges()
	var window_screenshot_written: bool = bool(acceptance_manifest.get("window_screenshot_written", false))
	var manual_notes_present: bool = not review_notes.is_empty()
	var manual_visual_review_done: bool = bool(review_notes.get("manual_visual_review_done", manual_notes_present))

	var blockers: Array = _build_blockers(
		acceptance_schema,
		acceptance_task_id,
		acceptance_status,
		recapture_gate,
		window_screenshot_written
	)
	var positives: Array = _build_positive_findings(acceptance_manifest, review_notes)
	var issues: Array = _build_issue_findings(review_notes)

	var status: String = "blocked" if not blockers.is_empty() else "needs_manual_review"
	if status != "blocked" and manual_notes_present:
		status = "ready_for_polish"

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"source_visibility_task_id": SOURCE_VISIBILITY_TASK_ID,
		"source_exchange_task_id": SOURCE_EXCHANGE_TASK_ID,
		"acceptance_schema": acceptance_schema,
		"acceptance_schema_ok": acceptance_schema == EXPECTED_ACCEPTANCE_SCHEMA,
		"acceptance_task_id": acceptance_task_id,
		"acceptance_status": acceptance_status,
		"recapture_gate": recapture_gate,
		"window_screenshot_written": window_screenshot_written,
		"window_screenshot_path": String(acceptance_manifest.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(acceptance_manifest.get("desktop_screenshot_path", "")),
		"manual_review_required": true,
		"manual_visual_review_done": manual_visual_review_done,
		"manual_notes_present": manual_notes_present,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"positive_findings": positives,
		"positive_finding_count": positives.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": NEXT_TASK,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


static func _build_positive_findings(acceptance_manifest: Dictionary, review_notes: Dictionary) -> Array:
	var positives: Array = []
	if bool(acceptance_manifest.get("window_screenshot_written", false)):
		positives.append({
			"id": "real_window_capture_available",
			"text": "Der frische Release-Fenster-Screenshot liegt vor und ist als Review-Evidenz verwendbar.",
		})
	if _review_flag(review_notes, "terrain_context_readable", true):
		positives.append({
			"id": "terrain_context_readable",
			"text": "Terrain, Strasse, Einheitengruppe und taktischer Raum sind im Screenshot grundsaetzlich lesbar.",
		})
	if _review_flag(review_notes, "unit_cluster_visible", true):
		positives.append({
			"id": "unit_cluster_visible",
			"text": "Der Spieler kann die eigene Einheitengruppe im Weltbild erkennen.",
		})
	return positives


static func _build_issue_findings(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "start_overlay_competes_with_combat", true):
		issues.append({
			"id": "start_overlay_competes_with_combat",
			"severity": "polish",
			"text": "Das Start-/Automatik-Overlay bleibt im Capture sichtbar und konkurriert mit dem ersten Feuerwechsel.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "world_lines_dominate_exchange", true):
		issues.append({
			"id": "world_lines_dominate_exchange",
			"severity": "polish",
			"text": "Dicke gruen/blaue Weltlinien dominieren das Bild und ziehen Aufmerksamkeit vom Fire-Exchange ab.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "fire_trace_or_impact_not_readable", true):
		issues.append({
			"id": "fire_trace_or_impact_not_readable",
			"severity": "polish",
			"text": "FireTrace, Impact oder Hit-Evidence sind im Weltbild nicht klar genug, um den ersten Schusswechsel sofort zu verstehen.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "hud_contact_fire_not_confirmed", true):
		issues.append({
			"id": "hud_contact_fire_not_confirmed",
			"severity": "polish",
			"text": "#17/#18/#19 bestaetigen den CONTACT-FIRE-Moment im sichtbaren Fenster nicht eindeutig genug.",
			"recommended_task": NEXT_TASK,
		})
	return issues


static func _review_flag(review_notes: Dictionary, key: String, default_value: bool) -> bool:
	if review_notes.has(key):
		return bool(review_notes.get(key))
	return default_value


static func _build_blockers(
	acceptance_schema: String,
	acceptance_task_id: String,
	acceptance_status: String,
	recapture_gate: String,
	window_screenshot_written: bool
) -> Array:
	var blockers: Array = []
	if acceptance_schema != EXPECTED_ACCEPTANCE_SCHEMA:
		blockers.append({"id": "acceptance_schema_mismatch", "text": "TASK_848-Acceptance-Schema fehlt oder passt nicht."})
	if acceptance_task_id != SOURCE_TASK_ID:
		blockers.append({"id": "acceptance_task_mismatch", "text": "Manifest nennt nicht TASK_848 als Quelle."})
	if acceptance_status != "ready_for_manual_acceptance" and acceptance_status != "accepted":
		blockers.append({"id": "acceptance_not_ready", "text": "TASK_848-Acceptance ist nicht bereit fuer visuelle Findings."})
	if recapture_gate != "review_ready" and recapture_gate != "manual_open":
		blockers.append({"id": "recapture_not_review_ready", "text": "Recapture-Gate ist nicht review_ready/manual_open."})
	if not window_screenshot_written:
		blockers.append({"id": "window_screenshot_missing", "text": "Fenster-Screenshot fehlt."})
	return blockers
