class_name FirstDecisionMicroScenarioPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.first_decision_micro_scenario_polish.v1"
const TASK_ID: String = "TASK_956"
const SOURCE_TASK_ID: String = "TASK_955"
const HUD_SOURCE_TASK_ID: String = "TASK_950"
const VISUAL_SOURCE_TASK_ID: String = "TASK_952"
const SOURCE_SMOKE_SCHEMA: String = "sternenbuergerchen.decision_overlay_playability_smoke.v1"
const HUD_SCHEMA: String = "sternenbuergerchen.order_preview_threat_overlay_f6_hud.v1"
const VISUAL_SCHEMA: String = "sternenbuergerchen.decision_overlay_f6_visual_polish.v1"
const NEXT_TASK: String = "TASK_957 - First Decision Real Playthrough Capture"


static func build_snapshot(source_smoke: Dictionary, hud_snapshot: Dictionary, visual_polish: Dictionary) -> Dictionary:
	var blockers: Array = _build_blockers(source_smoke, hud_snapshot, visual_polish)
	var cards: Array = Array(hud_snapshot.get("visible_choice_cards", []))
	var badges: Array = Array(visual_polish.get("visual_badges", []))
	var recommended_choice_id: String = String(hud_snapshot.get("recommended_choice_id", source_smoke.get("recommended_choice_id", ""))).strip_edges()
	var ordered_cards: Array = _ordered_cards(cards, recommended_choice_id)
	var choice_rows: Array = _build_choice_rows(ordered_cards, badges)
	var recommended_row: Dictionary = Dictionary(choice_rows[0]) if not choice_rows.is_empty() else {}
	var primary_cue_line: String = _build_primary_cue_line(recommended_row)
	var why_line: String = _build_why_line(recommended_row)
	var before_go_line: String = "Vor GO: Preview zeigt Ziel/Pfad/Risiko; kein Befehl"
	var after_go_line: String = "Nach GO: Bewegung startet; Kontakt-Feedback beobachten"
	var checks: Array = _build_checks(primary_cue_line, why_line, before_go_line, after_go_line, choice_rows, source_smoke)
	var failed_checks: Array = _failed_check_ids(checks)
	var status: String = "blocked" if not blockers.is_empty() else ("ready_for_first_decision_micro_scenario" if failed_checks.is_empty() else "needs_first_decision_micro_scenario_polish")
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"hud_source_task_id": HUD_SOURCE_TASK_ID,
		"visual_source_task_id": VISUAL_SOURCE_TASK_ID,
		"source_smoke_schema": String(source_smoke.get("schema", "")),
		"source_smoke_gate": String(source_smoke.get("gate", "")),
		"hud_schema": String(hud_snapshot.get("schema", "")),
		"visual_schema": String(visual_polish.get("schema", "")),
		"recommended_choice_id": recommended_choice_id,
		"ordered_choice_ids": _ordered_choice_ids(ordered_cards),
		"choice_rows": choice_rows,
		"choice_row_count": choice_rows.size(),
		"primary_cue_line": primary_cue_line,
		"why_line": why_line,
		"before_go_line": before_go_line,
		"after_go_line": after_go_line,
		"answered_player_questions": Array(source_smoke.get("answered_player_questions", [])),
		"checks": checks,
		"failed_checks": failed_checks,
		"status": status,
		"gate": "blocked" if not blockers.is_empty() else ("pass" if failed_checks.is_empty() else "review"),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"recommended_next_task": NEXT_TASK,
		"recommended_direction": "capture_first_decision_real_playthrough_after_micro_polish",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


static func _build_blockers(source_smoke: Dictionary, hud_snapshot: Dictionary, visual_polish: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_smoke.get("schema", "")) != SOURCE_SMOKE_SCHEMA:
		blockers.append(_issue("source_smoke_schema_mismatch", "TASK_955-Smoke-Schema fehlt oder passt nicht."))
	if String(source_smoke.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_smoke_task_mismatch", "Source nennt nicht TASK_955."))
	if String(source_smoke.get("gate", "")) != "smoke_passed" or not bool(source_smoke.get("smoke_passed", false)):
		blockers.append(_issue("source_smoke_not_passed", "TASK_955-Smoke ist nicht bestanden."))
	if String(hud_snapshot.get("schema", "")) != HUD_SCHEMA or String(hud_snapshot.get("task_id", "")) != HUD_SOURCE_TASK_ID:
		blockers.append(_issue("hud_source_mismatch", "TASK_950-HUD-Source fehlt oder passt nicht."))
	if String(hud_snapshot.get("gate", "")) != "pass":
		blockers.append(_issue("hud_source_not_pass", "TASK_950-HUD-Source ist nicht pass."))
	if String(visual_polish.get("schema", "")) != VISUAL_SCHEMA or String(visual_polish.get("task_id", "")) != VISUAL_SOURCE_TASK_ID:
		blockers.append(_issue("visual_source_mismatch", "TASK_952-Visual-Source fehlt oder passt nicht."))
	if String(visual_polish.get("gate", "")) != "pass":
		blockers.append(_issue("visual_source_not_pass", "TASK_952-Visual-Source ist nicht pass."))
	if not _snapshot_is_read_only(source_smoke) or not _snapshot_is_read_only(hud_snapshot) or not _snapshot_is_read_only(visual_polish):
		blockers.append(_issue("source_not_read_only", "Eine TASK_956-Quelle verletzt die read-only-Grenze."))
	return blockers


static func _ordered_cards(cards: Array, recommended_choice_id: String) -> Array:
	var by_id: Dictionary = {}
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		by_id[String(card.get("choice_id", ""))] = card
	var ordered: Array = []
	if by_id.has(recommended_choice_id):
		ordered.append(Dictionary(by_id.get(recommended_choice_id, {})))
	for risk_state in ["risky", "suicidal", "safe"]:
		for card_variant in cards:
			var card: Dictionary = Dictionary(card_variant)
			if String(card.get("choice_id", "")) == recommended_choice_id:
				continue
			if String(card.get("risk_state", "")) == risk_state:
				ordered.append(card)
	return ordered


static func _build_choice_rows(ordered_cards: Array, badges: Array) -> Array:
	var badge_by_risk: Dictionary = {}
	for badge_variant in badges:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		badge_by_risk[String(badge.get("risk_state", ""))] = badge
	var rows: Array = []
	for index in range(ordered_cards.size()):
		var card: Dictionary = Dictionary(ordered_cards[index])
		var risk_state: String = String(card.get("risk_state", "unknown")).strip_edges().to_lower()
		var badge: Dictionary = Dictionary(badge_by_risk.get(risk_state, {}))
		var label: String = String(card.get("line_label", badge.get("label", "Preview"))).strip_edges()
		var line_count: int = maxi(int(card.get("line_of_fire_entry_count", 0)), 0)
		rows.append({
			"choice_id": String(card.get("choice_id", "")),
			"priority": index + 1,
			"risk_state": risk_state,
			"risk_token": _risk_token(risk_state),
			"player_label": label,
			"reason_short": _reason_short(risk_state, line_count),
			"go_hint": "GO bestaetigt" if index == 0 else "erst pruefen",
			"eta_seconds_estimate": float(card.get("eta_seconds_estimate", 0.0)),
			"line_of_fire_entry_count": line_count,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return rows


static func _build_primary_cue_line(recommended_row: Dictionary) -> String:
	var label: String = String(recommended_row.get("player_label", "Gedeckt")).strip_edges()
	if label.is_empty():
		label = "Gedeckt"
	return "NEXT %s pruefen -> GO" % label


static func _build_why_line(recommended_row: Dictionary) -> String:
	var reason: String = String(recommended_row.get("reason_short", "Deckung ok, 0 Feindlinie")).strip_edges()
	if not reason.contains("Deckung"):
		reason = "Deckung ok; %s" % reason
	if not reason.contains("Feindlinie"):
		reason = "%s, 0 Feindlinie" % reason
	return "WHY %s" % reason


static func _build_checks(primary_line: String, why_line: String, before_go_line: String, after_go_line: String, rows: Array, source_smoke: Dictionary) -> Array:
	return [
		_check("primary_cue_short", _line_ok(primary_line, 84), "NEXT/GO-Cue ist kurz genug."),
		_check("why_line_short", _line_ok(why_line, 96), "WHY-Zeile ist kurz genug."),
		_check("before_go_boundary_readable", _line_ok(before_go_line, 96) and before_go_line.contains("kein Befehl"), "Preview-Grenze vor GO bleibt lesbar."),
		_check("after_go_feedback_readable", _line_ok(after_go_line, 96) and after_go_line.contains("Feedback"), "Post-GO-Feedback ist als naechster Schritt benannt."),
		_check("three_choice_rows", rows.size() == 3, "Drei Choice-Zeilen bleiben erhalten."),
		_check("choice_rows_hide_raw_ids", _rows_hide_raw_ids(rows), "Choice-Zeilen zeigen keine internen Choice-IDs."),
		_check("answered_first_decision_questions", _answered_questions_complete(Array(source_smoke.get("answered_player_questions", []))), "Smoke-Fragen bleiben beantwortet."),
	]


static func _failed_check_ids(checks: Array) -> Array:
	var failed: Array = []
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed.append(String(check.get("id", "")))
	return failed


static func _ordered_choice_ids(cards: Array) -> Array:
	var ids: Array = []
	for card_variant in cards:
		ids.append(String(Dictionary(card_variant).get("choice_id", "")))
	return ids


static func _risk_token(risk_state: String) -> String:
	match risk_state:
		"safe":
			return "SAFE"
		"risky":
			return "RISKY"
		"suicidal":
			return "SUICIDAL"
		_:
			return "UNKNOWN"


static func _reason_short(risk_state: String, line_count: int) -> String:
	match risk_state:
		"safe":
			return "Deckung ok, %d Feindlinie" % line_count
		"risky":
			return "%d Feindlinie, Querung" % maxi(line_count, 1)
		"suicidal":
			return "%d Feindlinien, Killzone" % maxi(line_count, 3)
		_:
			return "Risiko unklar"


static func _line_ok(line: String, max_len: int) -> bool:
	return not line.strip_edges().is_empty() and line.length() <= max_len and not _contains_raw_choice_id(line)


static func _rows_hide_raw_ids(rows: Array) -> bool:
	if rows.size() != 3:
		return false
	for row_variant in rows:
		var row: Dictionary = Dictionary(row_variant)
		if _contains_raw_choice_id(String(row.get("player_label", ""))):
			return false
		if _contains_raw_choice_id(String(row.get("reason_short", ""))):
			return false
	return true


static func _answered_questions_complete(questions: Array) -> bool:
	return questions.has("where_will_the_fireteam_go") \
		and questions.has("why_is_this_move_risky") \
		and questions.has("which_choice_is_best") \
		and questions.has("what_changes_only_after_go")


static func _contains_raw_choice_id(text: String) -> bool:
	return text.contains("covered_push") or text.contains("exposed_crossing") or text.contains("kill_zone_dash")


static func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_movement", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false))


static func _check(check_id: String, passed: bool, text: String) -> Dictionary:
	return {
		"id": check_id,
		"passed": passed,
		"text": text,
	}


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
