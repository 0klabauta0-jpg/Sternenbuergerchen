class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioShipReadinessReview
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_ship_readiness_review.v1"
const TASK_ID: String = "TASK_1026"
const SOURCE_TASK_ID: String = "TASK_1025"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance.v1"
const REVIEW_TASK: String = "TASK_1026 - Release First Decision Loop Two Player Loop Scenario Ship Readiness Review"
const POLISH_TASK: String = "TASK_1026 - Release First Decision Loop Two Player Loop Scenario Ship Readiness Polish"
const NEXT_TASK: String = "TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke"

const REQUIRED_SHIP_READINESS_ITEMS: Array[String] = [
	"release_build_path",
	"pck_path",
	"scenario_id",
	"tester_instructions",
	"operator_goal",
	"known_risks",
	"handoff_items",
	"multiplayer_boundary_note",
	"hud_truth_note",
	"ship_readiness_reviewed",
]


static func build_snapshot(source_acceptance: Dictionary, packet: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_acceptance)
	var packet_available: bool = bool(packet.get("packet_available", false)) or not packet.is_empty()
	var ship_readiness_items: Dictionary = _collect_ship_readiness_items(packet)
	var missing_items: Array = []
	var issues: Array = []
	var status: String = "blocked"
	var gate: String = "blocked"
	var ship_ready: bool = false
	var ready_for_visible_ship_smoke: bool = false
	var recommended_next_task: String = REVIEW_TASK
	var recommended_direction: String = "fix_release_candidate_acceptance_source"

	if blockers.is_empty():
		if not packet_available:
			status = "needs_ship_readiness_packet"
			gate = "needs_ship_readiness_packet"
			issues.append(_issue("ship_readiness_packet_missing", "Ship-Readiness-Paket fuer TASK_1026 fehlt."))
			recommended_direction = "collect_ship_readiness_packet"
		else:
			missing_items = _find_missing_ship_readiness_items(ship_readiness_items)
			issues = _build_packet_issues(packet, missing_items)
			if issues.is_empty():
				status = "ship_readiness_ready"
				gate = "ship_readiness_ready"
				ship_ready = true
				ready_for_visible_ship_smoke = true
				recommended_next_task = NEXT_TASK
				recommended_direction = "run_visible_ship_smoke"
			else:
				status = "ship_readiness_incomplete"
				gate = "ship_readiness_incomplete"
				recommended_next_task = POLISH_TASK
				recommended_direction = "complete_ship_readiness_packet"

	var all_issues: Array = blockers + issues
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_acceptance.get("schema", "")),
		"source_status": String(source_acceptance.get("status", "")),
		"source_gate": String(source_acceptance.get("gate", "")),
		"source_release_candidate_acceptance_line": String(source_acceptance.get("release_candidate_acceptance_line", "")),
		"source_release_candidate_accepted": bool(source_acceptance.get("release_candidate_accepted", false)),
		"source_ready_for_ship_readiness_review": bool(source_acceptance.get("ready_for_ship_readiness_review", false)),
		"source_release_build_path": String(source_acceptance.get("source_release_build_path", source_acceptance.get("release_build_path", ""))),
		"packet_available": packet_available,
		"ship_readiness_items": ship_readiness_items,
		"required_ship_readiness_items": REQUIRED_SHIP_READINESS_ITEMS.duplicate(),
		"missing_ship_readiness_items": missing_items,
		"missing_ship_readiness_item_count": missing_items.size(),
		"ship_readiness_line": _build_readiness_line(status, ship_ready, source_acceptance, packet),
		"ship_readiness_ready": ship_ready,
		"ready_for_visible_ship_smoke": ready_for_visible_ship_smoke,
		"status": status,
		"gate": gate,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(all_issues[0]).get("id", "")) if not all_issues.is_empty() else "",
		"recommended_next_task": recommended_next_task,
		"recommended_direction": recommended_direction,
		"read_only": true,
		"read_only_capture": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


static func _build_source_blockers(source: Dictionary) -> Array:
	var blockers: Array = []
	if String(source.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1025-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1025."))
	if String(source.get("status", "")) != "release_candidate_accepted":
		blockers.append(_issue("source_rc_not_accepted", "TASK_1025-Source ist nicht release_candidate_accepted."))
	if not bool(source.get("release_candidate_accepted", false)):
		blockers.append(_issue("source_accept_flag_missing", "TASK_1025-Acceptance-Flag fehlt."))
	if not bool(source.get("ready_for_ship_readiness_review", false)):
		blockers.append(_issue("source_not_ready_for_ship_readiness", "TASK_1025 ist nicht fuer Ship-Readiness freigegeben."))
	var line: String = String(source.get("release_candidate_acceptance_line", "")).strip_edges()
	if line.is_empty():
		blockers.append(_issue("source_acceptance_line_missing", "TASK_1025-Acceptance-Line fehlt."))
	elif not (line.contains("FOB") and line.contains("NEXT") and line.contains("GO") and line.contains("FEEDBACK")):
		blockers.append(_issue("source_acceptance_line_incomplete", "TASK_1025-Acceptance-Line nennt FOB/NEXT/GO/FEEDBACK nicht gemeinsam."))
	if int(source.get("issue_count", 0)) > 0:
		blockers.append(_issue("source_issues_present", "TASK_1025-Source enthaelt noch Issues."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1025-Source verletzt die read-only-Grenze."))
	return blockers


static func _collect_ship_readiness_items(packet: Dictionary) -> Dictionary:
	var items: Dictionary = {}
	for item_id in REQUIRED_SHIP_READINESS_ITEMS:
		items[item_id] = packet.get(item_id)
	return items


static func _find_missing_ship_readiness_items(items: Dictionary) -> Array:
	var missing: Array = []
	for item_id in REQUIRED_SHIP_READINESS_ITEMS:
		var value: Variant = items.get(item_id)
		if _value_is_missing(value):
			missing.append(item_id)
	return missing


static func _build_packet_issues(packet: Dictionary, missing_items: Array) -> Array:
	var issues: Array = []
	var ids := {}
	if not missing_items.is_empty():
		_append_issue_once(issues, ids, "ship_readiness_items_missing", "Ship-Readiness-Items fehlen: %s." % ", ".join(PackedStringArray(missing_items)))
	if missing_items.has("tester_instructions"):
		_append_issue_once(issues, ids, "tester_instructions_missing", "Testerhinweise fuer die Release-EXE fehlen.")
	if missing_items.has("known_risks"):
		_append_issue_once(issues, ids, "known_risks_missing", "Bekannte Restrisiken fehlen.")
	if missing_items.has("handoff_items"):
		_append_issue_once(issues, ids, "handoff_items_missing", "Uebergabe-Items fehlen.")
	if missing_items.has("release_build_path"):
		_append_issue_once(issues, ids, "release_build_path_missing", "Release-EXE-Pfad fehlt.")
	if not bool(packet.get("ship_readiness_reviewed", false)):
		_append_issue_once(issues, ids, "ship_readiness_review_open", "Ship-Readiness-Review ist noch nicht abgeschlossen.")
	if bool(packet.get("ui_sets_gameplay_truth", false)):
		_append_issue_once(issues, ids, "packet_ui_gameplay_truth_risk", "Ship-Readiness-Paket darf keine UI-Gameplay-Wahrheit setzen.")
	if bool(packet.get("creates_command", false)):
		_append_issue_once(issues, ids, "packet_creates_command", "Ship-Readiness-Paket darf keinen Command erzeugen.")
	if bool(packet.get("creates_movement", false)):
		_append_issue_once(issues, ids, "packet_creates_movement", "Ship-Readiness-Paket darf keine Bewegung erzeugen.")
	if bool(packet.get("sets_multiplayer_truth", false)):
		_append_issue_once(issues, ids, "packet_sets_multiplayer_truth", "Ship-Readiness-Paket darf keine Multiplayer-Wahrheit setzen.")
	return issues


static func _append_issue_once(issues: Array, ids: Dictionary, issue_id: String, text: String) -> void:
	if ids.has(issue_id):
		return
	ids[issue_id] = true
	issues.append(_issue(issue_id, text))


static func _value_is_missing(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL:
			return true
		TYPE_BOOL:
			return not bool(value)
		TYPE_STRING:
			return String(value).strip_edges().is_empty()
		TYPE_ARRAY:
			return Array(value).is_empty()
		TYPE_DICTIONARY:
			return Dictionary(value).is_empty()
	return false


static func _build_readiness_line(status: String, ready: bool, source: Dictionary, packet: Dictionary) -> String:
	if ready:
		var goal: String = String(packet.get("operator_goal", "kleiner FOB/NEXT/GO/FEEDBACK-Spielmoment")).strip_edges()
		return "SHIP READY: FOB | NEXT | GO | FEEDBACK | %s" % _compact_text(goal, 104)
	if status == "needs_ship_readiness_packet":
		return "SHIP PACKET OFFEN: FOB | NEXT | GO | FEEDBACK | Build, Testerhinweise und Risiken fehlen."
	var source_line: String = String(source.get("release_candidate_acceptance_line", "")).strip_edges()
	if source_line.is_empty():
		source_line = "FOB, NEXT, GO und FEEDBACK brauchen Ship-Readiness."
	return "SHIP CHECK: FOB | NEXT | GO | FEEDBACK | %s" % _compact_text(source_line, 104)


static func _compact_text(text: String, max_length: int) -> String:
	var normalized: String = text.strip_edges()
	if normalized.length() <= max_length:
		return normalized
	return normalized.substr(0, maxi(max_length - 3, 0)).strip_edges() + "..."


static func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_movement", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false))


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
