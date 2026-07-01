class_name StationReentryFirefightVisualFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_visual_findings.v1"
const EXPECTED_PACKET_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_visual_playtest_packet.v1"
const EXPECTED_PACKET_TASK_ID: String = "TASK_778"
const DEFAULT_PACKET_MANIFEST_PATH: String = "tmp/station_reentry_firefight_visual_playtest_packet.json"
const DEFAULT_FINDINGS_MANIFEST_PATH: String = "tmp/station_reentry_firefight_visual_findings.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

const REQUIRED_CHECKS: Array[Dictionary] = [
	{"id": "f6_window_open", "label": "F6-Fenster ist sichtbar offen"},
	{"id": "firefight_triggered", "label": "Erster Feuerwechsel wurde im Fenster ausgeloest"},
	{"id": "fire_trace_visible", "label": "FireTrace ist sichtbar und lesbar"},
	{"id": "impact_focus_visible", "label": "Impact/Fokus am Ziel ist sichtbar"},
	{"id": "unit_badge_visible", "label": "Unit-Badge/Status am Feuerwechsel ist sichtbar"},
	{"id": "combat_hud_next_decision_visible", "label": "Combat-HUD zeigt den naechsten Spielergriff"},
	{"id": "combat_metrics_match_hud", "label": "Combat-Metriken passen zur sichtbaren HUD-Lage"},
	{"id": "friendly_fire_risk_readable", "label": "Friendly-Fire-Risiko ist lesbar oder bewusst null"},
	{"id": "screenshot_saved", "label": "Screenshot/Evidence wurde gespeichert"},
	{"id": "workbench_json_exported", "label": "Workbench-JSON wurde exportiert"},
]

const ISSUE_TO_ACTION: Dictionary = {
	"trace_too_subtle": "TASK_544 - Mission Fire And Cover Visual Polish Pass",
	"impact_focus_unclear": "TASK_544 - Mission Fire And Cover Visual Polish Pass",
	"unit_badge_too_small": "TASK_544 - Mission Fire And Cover Visual Polish Pass",
	"combat_hud_too_dense": "TASK_546 - Mission Combat Feedback HUD Density Polish",
	"metrics_mismatch": "TASK_584 - Mini After-Action Combat Metrics",
	"friendly_fire_risk_unclear": "TASK_508 - Line-of-Fire / Threat Analyzer MVP",
	"performance_stutter_visible": "TASK_769 - Station Reentry Performance Feel Pass",
	"host_client_firefight_mismatch": "TASK_770 - Station Reentry Host Client Next Order Sync",
}

const ISSUE_FLAG_IDS: Array[String] = [
	"trace_too_subtle",
	"impact_focus_unclear",
	"unit_badge_too_small",
	"combat_hud_too_dense",
	"metrics_mismatch",
	"friendly_fire_risk_unclear",
	"performance_stutter_visible",
	"host_client_firefight_mismatch",
]


static func build_snapshot(packet_manifest: Dictionary = {}, review_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	var action_items: Array = []
	_add_packet_findings(findings, packet_manifest)
	var required_checks: Array = _build_required_checks(review_notes)
	var issue_flags: Array = _build_issue_flags(review_notes)
	var completed_check_count: int = _count_completed_checks(required_checks)
	var missing_check_ids: Array[String] = _missing_check_ids(required_checks)
	var active_issue_count: int = _add_issue_flag_findings(findings, action_items, issue_flags)
	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var manual_done: bool = _read_bool(review_notes, "reentry_firefight_visual_findings.manual_review_done")
	var visible_playtest_done: bool = _read_bool(review_notes, "reentry_firefight_visual_findings.visible_playtest_done")
	var status: String = _build_status(blocker_count, manual_done, visible_playtest_done, missing_check_ids, active_issue_count)
	if status == "needs_visible_firefight_review":
		findings.append(_finding("visible_firefight_review_open", "manual", "Sichtbarer Firefight-Fensterblick fehlt oder ist noch nicht bewusst abgeschlossen.", "TASK_778 - run visible Firefight Visual Playtest Packet"))
	elif status == "needs_firefight_review_completion":
		findings.append(_finding("firefight_visual_checks_missing", "manual", "Firefight-Review ist angefangen, aber Pflichtchecks fehlen: %s" % ", ".join(PackedStringArray(missing_check_ids)), "TASK_778 - complete missing visible Firefight checks"))
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_779",
		"source_task_id": EXPECTED_PACKET_TASK_ID,
		"runtime_authority": "read-only findings over TASK_778 visual packet and optional report notes",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"source_packet_schema": String(packet_manifest.get("schema", "")),
		"source_packet_task_id": String(packet_manifest.get("task_id", "")),
		"source_packet_status": String(packet_manifest.get("status", "")),
		"source_packet_manifest_path": String(options.get("packet_manifest_path", DEFAULT_PACKET_MANIFEST_PATH)),
		"target_id": String(packet_manifest.get("target_id", "station_reentry_firefight_visual_playtest")),
		"expected_firefight_readability": Dictionary(packet_manifest.get("expected_firefight_readability", {})).duplicate(true),
		"manual_review_required": true,
		"manual_review_done": manual_done,
		"visible_playtest_done": visible_playtest_done,
		"required_checks": required_checks,
		"required_check_count": required_checks.size(),
		"completed_check_count": completed_check_count,
		"missing_check_ids": missing_check_ids,
		"issue_flags": issue_flags,
		"active_issue_count": active_issue_count,
		"blocking_issue_count": blocker_count,
		"finding_count": findings.size(),
		"findings": findings,
		"action_items": action_items,
		"action_item_count": action_items.size(),
		"status": status,
		"summary": _build_summary(status, completed_check_count, required_checks.size(), active_issue_count),
		"recommended_next_task": _recommended_next_task(status, action_items),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_FINDINGS_MANIFEST_PATH)),
	}


static func _add_packet_findings(findings: Array, packet_manifest: Dictionary) -> void:
	if packet_manifest.is_empty():
		findings.append(_finding("missing_task_778_packet", "blocker", "TASK_778-Firefight-Visual-Paket fehlt.", "TASK_778 - rerun Station Reentry Firefight Visual Playtest Packet"))
		return
	if String(packet_manifest.get("schema", "")) != EXPECTED_PACKET_SCHEMA:
		findings.append(_finding("unexpected_task_778_packet_schema", "blocker", "TASK_778-Paket hat ein unerwartetes Schema.", "TASK_778 verifier rerun"))
	if String(packet_manifest.get("task_id", "")) != EXPECTED_PACKET_TASK_ID:
		findings.append(_finding("unexpected_task_778_packet_task", "blocker", "Paket gehoert nicht zu TASK_778.", "TASK_778 verifier rerun"))
	if String(packet_manifest.get("status", "")) != "ready_to_capture_station_reentry_firefight_visual":
		findings.append(_finding("task_778_packet_not_ready", "blocker", "TASK_778-Paket ist nicht capture-bereit.", "TASK_778 repair or rerun"))
	if not bool(packet_manifest.get("read_only", false)) \
			or bool(packet_manifest.get("ui_sets_gameplay_truth", true)) \
			or bool(packet_manifest.get("creates_command", true)) \
			or bool(packet_manifest.get("creates_fire_event", true)) \
			or bool(packet_manifest.get("creates_damage_event", true)):
		findings.append(_finding("task_778_packet_not_readonly", "blocker", "TASK_778-Paket verletzt read-only/UI-Truth-Regeln.", "TASK_778 verifier rerun"))


static func _build_required_checks(review_notes: Dictionary) -> Array:
	var checks: Array = []
	for check_def in REQUIRED_CHECKS:
		var id: String = String(check_def.get("id", ""))
		checks.append({
			"id": id,
			"label": String(check_def.get("label", id)),
			"checked": _read_bool(review_notes, "reentry_firefight_visual_findings.%s" % id) \
					or _read_bool(review_notes, "reentry_firefight_visual_packet.%s" % id),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return checks


static func _build_issue_flags(review_notes: Dictionary) -> Array:
	var flags: Array = []
	for id in ISSUE_FLAG_IDS:
		flags.append({
			"id": String(id),
			"label": _issue_label(String(id)),
			"active": _read_bool(review_notes, "reentry_firefight_visual_findings.issues.%s" % String(id)),
			"recommended_task": String(ISSUE_TO_ACTION.get(id, "")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return flags


static func _issue_label(id: String) -> String:
	match id:
		"trace_too_subtle":
			return "FireTrace ist im Fenster zu schwach oder geht im Raster unter"
		"impact_focus_unclear":
			return "Impact/Fokus am Ziel ist nicht klar genug"
		"unit_badge_too_small":
			return "Unit-Badge/Status ist im Feuerwechsel zu klein oder unruhig"
		"combat_hud_too_dense":
			return "Combat-HUD ist im Feuerwechsel zu dicht"
		"metrics_mismatch":
			return "Combat-Metriken passen nicht zur sichtbaren Lage"
		"friendly_fire_risk_unclear":
			return "Friendly-Fire-Risiko ist nicht lesbar"
		"performance_stutter_visible":
			return "Feuerwechsel wirkt im Fenster zaeh oder stottert"
		"host_client_firefight_mismatch":
			return "Host/Client sehen den Firefight-Zustand nicht gleich"
	return id


static func _add_issue_flag_findings(findings: Array, action_items: Array, issue_flags: Array) -> int:
	var count: int = 0
	for flag_variant in issue_flags:
		if typeof(flag_variant) != TYPE_DICTIONARY:
			continue
		var flag: Dictionary = Dictionary(flag_variant)
		if not bool(flag.get("active", false)):
			continue
		count += 1
		var id: String = String(flag.get("id", ""))
		var label: String = String(flag.get("label", id))
		var next_task: String = String(flag.get("recommended_task", "TASK_544 - Mission Fire And Cover Visual Polish Pass"))
		findings.append(_finding("firefight_visual_issue_%s" % id, "polish", label, next_task))
		action_items.append({
			"id": id,
			"label": label,
			"recommended_task": next_task,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return count


static func _build_status(blocker_count: int, manual_done: bool, visible_playtest_done: bool, missing_check_ids: Array, active_issue_count: int) -> String:
	if blocker_count > 0:
		return "blocked"
	if not manual_done or not visible_playtest_done:
		return "needs_visible_firefight_review"
	if not missing_check_ids.is_empty():
		return "needs_firefight_review_completion"
	if active_issue_count > 0:
		return "needs_targeted_firefight_visual_polish"
	return "ready_for_next_station_firefight_iteration"


static func _build_summary(status: String, completed_check_count: int, required_check_count: int, active_issue_count: int) -> String:
	if status == "blocked":
		return "TASK_779 blockiert: TASK_778-Firefight-Visual-Paket fehlt oder ist ungueltig."
	if status == "needs_visible_firefight_review":
		return "Sichtbarer Firefight-Review offen, %d/%d Checks gesetzt." % [completed_check_count, required_check_count]
	if status == "needs_firefight_review_completion":
		return "Firefight-Visual-Review unvollstaendig, %d/%d Checks gesetzt." % [completed_check_count, required_check_count]
	if status == "needs_targeted_firefight_visual_polish":
		return "%d konkrete Firefight-Visual-Follow-up-Flag(s)." % active_issue_count
	return "Firefight-Visual-Review ist sauber genug fuer den naechsten Station-Firefight-Schritt."


static func _recommended_next_task(status: String, action_items: Array) -> String:
	if status == "blocked":
		return "TASK_778 - rerun Station Reentry Firefight Visual Playtest Packet"
	if status == "needs_visible_firefight_review":
		return "TASK_778 - run visible Firefight Visual Playtest Packet"
	if status == "needs_firefight_review_completion":
		return "TASK_778 - complete missing visible Firefight checks"
	if status == "needs_targeted_firefight_visual_polish":
		if not action_items.is_empty() and typeof(action_items[0]) == TYPE_DICTIONARY:
			return String(Dictionary(action_items[0]).get("recommended_task", "TASK_544 - Mission Fire And Cover Visual Polish Pass"))
		return "TASK_544 - Mission Fire And Cover Visual Polish Pass"
	return "TASK_780 - Station Reentry Firefight Interaction Polish"


static func _missing_check_ids(required_checks: Array) -> Array[String]:
	var missing: Array[String] = []
	for check_variant in required_checks:
		if typeof(check_variant) != TYPE_DICTIONARY:
			continue
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("checked", false)):
			missing.append(String(check.get("id", "")))
	return missing


static func _count_completed_checks(required_checks: Array) -> int:
	var count: int = 0
	for check_variant in required_checks:
		if typeof(check_variant) == TYPE_DICTIONARY and bool(Dictionary(check_variant).get("checked", false)):
			count += 1
	return count


static func _read_bool(source: Dictionary, dotted_key: String) -> bool:
	var direct_value: Variant = _get_path(source, dotted_key)
	if typeof(direct_value) == TYPE_BOOL:
		return bool(direct_value)
	var controls: Dictionary = Dictionary(source.get("controls", {}))
	var control_value: Variant = _get_path(controls, dotted_key)
	return bool(control_value) if typeof(control_value) == TYPE_BOOL else false


static func _get_path(source: Dictionary, dotted_key: String) -> Variant:
	var cursor: Variant = source
	for part in dotted_key.split("."):
		if typeof(cursor) != TYPE_DICTIONARY:
			return null
		var dict: Dictionary = Dictionary(cursor)
		if not dict.has(part):
			return null
		cursor = dict.get(part)
	return cursor


static func _finding(id: String, severity: String, message: String, suggested_next: String) -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"suggested_next": suggested_next,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _count_findings_by_severity(findings: Array, severity: String) -> int:
	var count: int = 0
	for finding_variant in findings:
		if typeof(finding_variant) == TYPE_DICTIONARY and String(Dictionary(finding_variant).get("severity", "")) == severity:
			count += 1
	return count
