class_name MissionControlStatePresenter
extends RefCounted


static func build_snapshot(context: Dictionary) -> Dictionary:
	var has_lz := bool(context.get("has_lz", false))
	var lz_text := String(context.get("lz_text", "")).strip_edges()
	var approach_name := String(context.get("approach_name", "NW")).strip_edges()
	var drop_state := String(context.get("drop_state", "")).strip_edges().to_lower()
	var sequence_phase := String(context.get("sequence_phase", "")).strip_edges().to_lower()
	var eta_seconds := maxi(int(context.get("eta_seconds", 0)), 0)
	var preview_mode := bool(context.get("preview_mode", false))
	var requested := bool(context.get("drop_requested", false))
	var staged := bool(context.get("drop_staged", false))
	var cooldown := maxf(float(context.get("cooldown_seconds", 0.0)), 0.0)

	var ship_line := _drop_state_line(drop_state, eta_seconds)
	if drop_state.is_empty() and staged and not requested and sequence_phase.is_empty():
		ship_line = "DROP: bereit"
	if requested:
		ship_line = "DROP: angefordert"
	if not preview_mode and cooldown > 0.0 and sequence_phase.is_empty():
		ship_line = "DROP: bereit %.1fs" % cooldown
	if bool(context.get("has_live_other_craft", false)):
		ship_line = _selected_craft_state_line(String(context.get("selected_craft_state", "")))
	elif bool(context.get("other_drop_active", false)):
		ship_line = "ANDERER DROP: aktiv"
	elif not sequence_phase.is_empty():
		ship_line = _sequence_line(sequence_phase, context)
	if preview_mode:
		ship_line = "VORSCHAU | %s" % ship_line.strip_edges()

	var visible_lines := PackedStringArray([
		"LZ: %s | ANFLUG %s" % [lz_text if has_lz and not lz_text.is_empty() else "offen", _approach_short_label(approach_name)],
		ship_line,
	])
	return {
		"visible_lines": visible_lines,
		"tooltip_text": _build_tooltip(context),
		"raw_drop_state": drop_state,
		"raw_sequence_phase": sequence_phase,
		"raw_approach_name": approach_name,
		"read_only": true,
		"sets_transport_truth": false,
		"sets_multiplayer_truth": false,
	}


static func _drop_state_line(state: String, eta_seconds: int) -> String:
	match state:
		"to_mission":
			return "DROP: Anflug %ds" % eta_seconds
		"waiting":
			return "DROP: bereit"
		"to_fob":
			return "DROP: zur FOB %ds" % eta_seconds
		"to_homebase":
			return "DROP: zur Basis %ds" % eta_seconds
	return "DROP: wartet"


static func _sequence_line(phase: String, context: Dictionary) -> String:
	match phase:
		"inbound":
			return "DROP: im Anflug"
		"landed":
			return "DROP: gelandet"
		"unloading":
			return "AUSSTIEG: %d/%d" % [maxi(int(context.get("unit_index", 0)), 0), maxi(int(context.get("unit_count", 0)), 0)]
		"outbound":
			return "DROP: hebt ab"
		"complete":
			return "FIRETEAM: ausgestiegen"
	return "DROP: aktiv"


static func _selected_craft_state_line(raw_state: String) -> String:
	match raw_state.strip_edges().to_lower():
		"to_mission", "inbound":
			return "DROP: im Anflug"
		"landed":
			return "DROP: gelandet"
		"unloading":
			return "DROP: Ausstieg"
		"to_fob", "to_homebase", "outbound", "returning":
			return "DROP: Rueckflug"
		"waiting":
			return "DROP: bereit"
	return "DROP: aktiv"


static func _approach_label(raw_name: String) -> String:
	match raw_name.strip_edges().to_upper():
		"N": return "Nord"
		"NE": return "Nordost"
		"E": return "Ost"
		"SE": return "Suedost"
		"S": return "Sued"
		"SW": return "Suedwest"
		"W": return "West"
		"NW": return "Nordwest"
	return raw_name.strip_edges()


static func _approach_short_label(raw_name: String) -> String:
	match raw_name.strip_edges().to_upper():
		"NE": return "NO"
		"SE": return "SO"
	return raw_name.strip_edges().to_upper()


static func _build_tooltip(context: Dictionary) -> String:
	return "Transportdiagnose\nState: %s\nSequenz: %s\nApproach: %s\nETA: %ds" % [
		String(context.get("drop_state", "")).strip_edges(),
		String(context.get("sequence_phase", "")).strip_edges(),
		String(context.get("approach_name", "")).strip_edges(),
		maxi(int(context.get("eta_seconds", 0)), 0),
	]
