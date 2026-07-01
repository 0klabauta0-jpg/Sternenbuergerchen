extends RefCounted

const SCHEMA: String = "sternenbuergerchen.station_reentry_host_client_fireteam_card_context.v1"
const STYLE_ID: String = "host_client_fireteam_context_badge_v2"
const SOURCE_STYLE_ID: String = "host_client_role_peer_badge_v1"


static func build_context(session_snapshot: Dictionary = {}, fireteam_context: Dictionary = {}) -> Dictionary:
	var session: Dictionary = session_snapshot.duplicate(true)
	var fireteam: Dictionary = fireteam_context.duplicate(true)
	var peer_label: String = String(session.get("peer_label", "")).strip_edges()
	var session_team_id: String = String(session.get("team_id", "")).strip_edges().to_lower()
	var session_team_label: String = _resolve_team_label(session_team_id, String(session.get("team_label", "")))
	var role_label: String = String(session.get("role_label", "")).strip_edges().to_upper()
	var fireteam_id: String = String(fireteam.get("fireteam_id", "")).strip_edges().to_lower()
	var fireteam_team_id: String = String(fireteam.get("fireteam_team_id", "")).strip_edges().to_lower()
	var fireteam_team_label: String = _resolve_team_label(fireteam_team_id, String(fireteam.get("fireteam_team_label", "")))
	var session_tokens: PackedStringArray = PackedStringArray()
	if not peer_label.is_empty():
		session_tokens.append(peer_label)
	if not session_team_label.is_empty():
		session_tokens.append(session_team_label)
	var session_text: String = " ".join(session_tokens).strip_edges()
	if session_text.is_empty() and not role_label.is_empty():
		session_text = role_label
	var relation: String = "unknown"
	if not session_team_id.is_empty() and not fireteam_team_id.is_empty():
		relation = "own" if session_team_id == fireteam_team_id else "foreign"
	var relation_label: String = "OWN" if relation == "own" else "VIEW" if relation == "foreign" else "FT ?"
	var text: String = _build_compact_text(relation, relation_label, session_text, fireteam_team_label)
	var tooltip_text: String = _build_tooltip_text(role_label, session_text, session_team_label, fireteam_id, fireteam_team_label, relation)
	return {
		"schema": SCHEMA,
		"visible": not text.is_empty(),
		"text": text,
		"full_text": tooltip_text,
		"style_id": STYLE_ID,
		"source_style_id": SOURCE_STYLE_ID,
		"relation": relation,
		"relation_label": relation_label,
		"session_team_id": session_team_id,
		"session_team_label": session_team_label,
		"fireteam_id": fireteam_id,
		"fireteam_team_id": fireteam_team_id,
		"fireteam_team_label": fireteam_team_label,
		"context_is_own_team": relation == "own",
		"context_is_foreign_team": relation == "foreign",
		"context_team_unknown": relation == "unknown",
		"tooltip_text": tooltip_text,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
	}


static func _build_compact_text(relation: String, relation_label: String, session_text: String, fireteam_team_label: String) -> String:
	if relation == "own":
		if session_text.is_empty():
			return relation_label
		return "%s %s" % [relation_label, session_text]
	if relation == "foreign":
		var team_suffix: String = fireteam_team_label if not fireteam_team_label.is_empty() else "FT ?"
		if session_text.is_empty():
			return "VIEW %s" % team_suffix
		return "%s VIEW %s" % [session_text, team_suffix]
	if session_text.is_empty():
		return relation_label
	return "%s %s" % [session_text, relation_label]


static func _build_tooltip_text(role_label: String, session_text: String, session_team_label: String, fireteam_id: String, fireteam_team_label: String, relation: String) -> String:
	var parts: PackedStringArray = PackedStringArray()
	if not role_label.is_empty():
		parts.append(role_label)
	if not session_text.is_empty():
		parts.append(session_text)
	var session_part: String = " ".join(parts).strip_edges()
	var fireteam_part: String = fireteam_id.to_upper() if not fireteam_id.is_empty() else "?"
	var fireteam_team_part: String = fireteam_team_label if not fireteam_team_label.is_empty() else "?"
	var relation_text: String = "own team" if relation == "own" else "viewing other team" if relation == "foreign" else "team unknown"
	var session_team_part: String = session_team_label if not session_team_label.is_empty() else "?"
	return "Review Session: %s | Session Team: %s | Fireteam: %s (%s) | Relation: %s" % [
		session_part if not session_part.is_empty() else "?",
		session_team_part,
		fireteam_part,
		fireteam_team_part,
		relation_text,
	]


static func _resolve_team_label(team_id: String, fallback_label: String = "") -> String:
	var fallback: String = fallback_label.strip_edges().to_upper()
	if not fallback.is_empty():
		return fallback
	var normalized: String = team_id.strip_edges().to_lower()
	match normalized:
		"team_alpha":
			return "ALPHA"
		"team_bravo":
			return "BRAVO"
	if normalized.begins_with("team_"):
		normalized = normalized.substr("team_".length())
	return normalized.to_upper()
