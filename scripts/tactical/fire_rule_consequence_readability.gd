extends RefCounted


static func build_snapshot(source: Dictionary) -> Dictionary:
	var fire_rule: String = String(source.get("fire_rule", "")).strip_edges().to_lower()
	var selected_fireteam_ids: Array = _normalize_ids(Array(source.get("selected_fireteam_ids", [])))
	var runtime_entries: Array = Array(source.get("runtime_entries", [])).duplicate(true)
	var return_fire_windows: Dictionary = Dictionary(source.get("return_fire_window_by_fireteam", {})).duplicate(true)
	var diagnostics: Dictionary = Dictionary(source.get("contact_decision_diagnostics", {})).duplicate(true)
	var return_window_active: bool = _has_return_fire_window(selected_fireteam_ids, return_fire_windows)
	var consequence_state: String = _resolve_consequence_state(fire_rule, return_window_active, diagnostics)
	var compact_token: String = _build_compact_token(consequence_state)
	var context_token: String = _build_context_token(source, diagnostics)
	var hud_token: String = compact_token
	if not hud_token.is_empty() and _has_friendly_fire_context(source, diagnostics):
		hud_token = "%s FF" % hud_token
	var runtime_consistency: Dictionary = _build_runtime_consistency(fire_rule, runtime_entries)
	return {
		"schema": "sternenbuergerchen.fire_rule_consequence_readability.v1",
		"source": "FireRuleConsequenceReadability",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"active": not compact_token.is_empty(),
		"fire_rule": fire_rule,
		"selected_fireteam_ids": selected_fireteam_ids,
		"consequence_state": consequence_state,
		"compact_token": compact_token,
		"hud_token": hud_token,
		"consequence_line": "ROE %s" % hud_token if not hud_token.is_empty() else "",
		"detail_line": _build_detail_line(consequence_state, context_token),
		"context_token": context_token,
		"return_fire_window_active": return_window_active,
		"runtime_evidence_available": not runtime_entries.is_empty(),
		"runtime_entry_count": runtime_entries.size(),
		"runtime_entries": runtime_entries,
		"runtime_consistent": bool(runtime_consistency.get("consistent", false)),
		"runtime_mismatch_count": int(runtime_consistency.get("mismatch_count", 0)),
		"expected_fire_status": String(runtime_consistency.get("expected_fire_status", "")),
		"contact_status": String(diagnostics.get("status", "")).strip_edges().to_lower(),
		"contact_reason": String(diagnostics.get("reason", "")).strip_edges().to_lower(),
		"friendly_fire_context": _has_friendly_fire_context(source, diagnostics),
		"contact_decision_diagnostics": diagnostics,
	}


static func _resolve_consequence_state(fire_rule: String, return_window_active: bool, diagnostics: Dictionary) -> String:
	match fire_rule:
		"hold":
			return "hold_blocked"
		"return":
			return "return_ready" if return_window_active else "return_waiting"
		"free":
			var status: String = String(diagnostics.get("status", "")).strip_edges().to_lower()
			var reason: String = String(diagnostics.get("reason", "")).strip_edges().to_lower()
			if status == "fired" or reason == "fired" or reason == "cooldown":
				return "free_engaging"
			if status == "blocked" and reason != "no_contact_pair" and not reason.is_empty():
				return "free_blocked"
			return "free_ready"
		"suppress":
			return "suppress_ready"
		"mixed":
			return "mixed"
		_:
			return ""


static func _build_compact_token(consequence_state: String) -> String:
	match consequence_state:
		"hold_blocked":
			return "HF HOLD"
		"return_waiting":
			return "RF WAIT"
		"return_ready":
			return "RF RETURN"
		"free_ready":
			return "FW READY"
		"free_engaging":
			return "FW ENGAGE"
		"free_blocked":
			return "FW BLOCK"
		"suppress_ready":
			return "SUP READY"
		"mixed":
			return "MIX"
		_:
			return ""


static func _build_detail_line(consequence_state: String, context_token: String) -> String:
	var detail: String = ""
	match consequence_state:
		"hold_blocked":
			detail = "Hold Fire: freiwilliges Feuer blockiert"
		"return_waiting":
			detail = "Return Fire: wartet auf eingehenden Beschuss"
		"return_ready":
			detail = "Return Fire: Antwortfenster aktiv"
		"free_ready":
			detail = "Fire at Will: feuerbereit"
		"free_engaging":
			detail = "Fire at Will: Kontakt wird bekaempft"
		"free_blocked":
			detail = "Fire at Will: Schuss blockiert"
		"suppress_ready":
			detail = "Suppress: Druckfeuer bereit"
		"mixed":
			detail = "Mehrfachauswahl: gemischte Feuerregeln"
	if detail.is_empty() or context_token.is_empty():
		return detail
	return "%s | %s" % [detail, context_token]


static func _build_context_token(source: Dictionary, diagnostics: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	if _has_friendly_fire_context(source, diagnostics):
		parts.append("FF RISK")
	var cover_state: String = String(diagnostics.get("cover_state", "")).strip_edges().to_upper()
	var los_state: String = String(diagnostics.get("los_state", "")).strip_edges().to_upper()
	var range_state: String = String(diagnostics.get("range_state", "")).strip_edges().to_upper()
	if not cover_state.is_empty() and cover_state != "UNKNOWN":
		parts.append("COV %s" % cover_state)
	if not los_state.is_empty() and los_state != "UNKNOWN":
		parts.append("LOS %s" % los_state)
	if not range_state.is_empty() and range_state != "UNKNOWN":
		parts.append("RNG %s" % range_state)
	return " | ".join(parts)


static func _has_friendly_fire_context(source: Dictionary, diagnostics: Dictionary) -> bool:
	return bool(diagnostics.get("is_friendly_fire", false)) \
		or int(source.get("friendly_fire_risk_count", 0)) > 0 \
		or int(diagnostics.get("friendly_fire_risk_count", 0)) > 0


static func _build_runtime_consistency(fire_rule: String, runtime_entries: Array) -> Dictionary:
	var expected_status: String = _expected_fire_status(fire_rule)
	var mismatch_count: int = 0
	for entry_variant in runtime_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if fire_rule == "mixed":
			continue
		if String(entry.get("fire_rule", "")).strip_edges().to_lower() != fire_rule:
			mismatch_count += 1
			continue
		if not expected_status.is_empty() and String(entry.get("fire_status", "")).strip_edges().to_lower() != expected_status:
			mismatch_count += 1
	return {
		"consistent": mismatch_count == 0,
		"mismatch_count": mismatch_count,
		"expected_fire_status": expected_status,
	}


static func _expected_fire_status(fire_rule: String) -> String:
	if fire_rule == "hold" or fire_rule == "return":
		return "hold_fire"
	if fire_rule == "free" or fire_rule == "suppress":
		return "fire_at_will"
	return ""


static func _has_return_fire_window(selected_fireteam_ids: Array, return_fire_windows: Dictionary) -> bool:
	for fireteam_id_variant in selected_fireteam_ids:
		if return_fire_windows.has(String(fireteam_id_variant).strip_edges().to_lower()):
			return true
	return selected_fireteam_ids.is_empty() and not return_fire_windows.is_empty()


static func _normalize_ids(values: Array) -> Array:
	var result: Array = []
	for value_variant in values:
		var value: String = String(value_variant).strip_edges().to_lower()
		if value.is_empty() or result.has(value):
			continue
		result.append(value)
	result.sort()
	return result
