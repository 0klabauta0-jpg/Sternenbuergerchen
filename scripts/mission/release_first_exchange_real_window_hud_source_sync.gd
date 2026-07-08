class_name ReleaseFirstExchangeRealWindowHudSourceSync
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_real_window_hud_source_sync.v1"
const TASK_ID: String = "TASK_883"
const SOURCE_TASK_ID: String = "TASK_882"
const SOURCE_TRACE_TASK_ID: String = "TASK_879"
const SOURCE_STATUS_TASK_ID: String = "TASK_876"
const SOURCE_RUNTIME_TEXT_TASK_ID: String = "TASK_862"
const SOURCE_PRIMARY_HUD_TASK_ID: String = "TASK_856"
const STYLE_ID: String = "task_883_release_first_exchange_real_window_hud_source_sync_v1"
const NEXT_TASK: String = "TASK_884 - Release First Exchange HUD Source Sync Recapture"


static func build_snapshot(source_snapshot: Dictionary, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = source_snapshot.duplicate(true)
	var combat_hud_density: Dictionary = Dictionary(source.get("combat_hud_density", {})).duplicate(true)
	var primary_line: String = String(source.get("contact_fire_primary_line", "")).strip_edges()
	var active: bool = bool(source.get("active", false)) and primary_line.to_upper().begins_with("CONTACT FIRE")
	var raw_selected_text: String = String(source.get("raw_selected_fireteam_status_text", source.get("selected_fireteam_status_text", ""))).strip_edges()
	var raw_mission_text: String = String(source.get("raw_mission_control_status_text", source.get("mission_control_status_text", ""))).strip_edges()
	var selected_text: String = bind_status_text(
		String(source.get("selected_fireteam_status_text", raw_selected_text)),
		primary_line,
		String(source.get("selected_fireteam_fallback_text", ""))
	)
	var mission_text: String = bind_status_text(
		String(source.get("mission_control_status_text", raw_mission_text)),
		primary_line,
		String(source.get("mission_control_fallback_text", ""))
	)
	var event_log_display: Dictionary = sync_event_log_display(
		Dictionary(source.get("event_log_display", {})),
		source,
		primary_line
	)
	var event_entries: Array = Array(event_log_display.get("entries", []))
	var first_event: Dictionary = Dictionary(event_entries[0]) if not event_entries.is_empty() and typeof(event_entries[0]) == TYPE_DICTIONARY else {}
	var selected_contact_fire_first: bool = selected_text.to_upper().begins_with("CONTACT FIRE")
	var mission_contact_fire_first: bool = mission_text.to_upper().begins_with("CONTACT FIRE")
	var event_log_contact_fire_first: bool = String(first_event.get("short_text", first_event.get("map_label", ""))).to_upper().contains("CONTACT FIRE")
	var no_fire_before_contact: bool = _contains_no_fire_before_contact_fire(_join_primary_lines([selected_text, mission_text]))
	var issues: Array = []
	if not active:
		issues.append(_issue("source_not_active", "TASK_883 hat keine aktive CONTACT-FIRE-Quelle bekommen."))
	if not selected_contact_fire_first:
		issues.append(_issue("selected_fireteam_not_contact_fire_first", "#17 beginnt nicht mit CONTACT FIRE."))
	if not mission_contact_fire_first:
		issues.append(_issue("mission_control_not_contact_fire_first", "#18 beginnt nicht mit CONTACT FIRE."))
	if not event_log_contact_fire_first:
		issues.append(_issue("event_log_not_contact_fire_first", "#19 Event Log zeigt CONTACT FIRE nicht als erste Display-Zeile."))
	if no_fire_before_contact:
		issues.append(_issue("debug_no_fire_before_contact_fire", "NO FIRE steht vor CONTACT FIRE in primaeren HUD-Zeilen."))
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_trace_task_id": SOURCE_TRACE_TASK_ID,
		"source_status_task_id": SOURCE_STATUS_TASK_ID,
		"source_runtime_text_task_id": SOURCE_RUNTIME_TEXT_TASK_ID,
		"source_primary_hud_task_id": SOURCE_PRIMARY_HUD_TASK_ID,
		"style_id": STYLE_ID,
		"status": "pass" if issues.is_empty() else "review",
		"active": active,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
		"contact_fire_primary_line": primary_line,
		"selected_fireteam_status_text": selected_text,
		"mission_control_status_text": mission_text,
		"event_log_display": event_log_display,
		"event_log_entries": event_entries,
		"event_log_first_entry": first_event,
		"selected_fireteam_contact_fire_first": selected_contact_fire_first,
		"mission_control_contact_fire_first": mission_contact_fire_first,
		"event_log_contact_fire_first": event_log_contact_fire_first,
		"primary_lines_contain_debug_no_fire_before_contact_fire": no_fire_before_contact,
		"combat_hud_density": combat_hud_density,
		"source": source,
		"options": options.duplicate(true),
		"issues": issues,
		"issue_count": issues.size(),
		"recommended_next_task": NEXT_TASK,
	}


static func bind_status_text(source_text: String, contact_fire_primary_line: String, fallback_text: String = "") -> String:
	var primary_line: String = String(contact_fire_primary_line).strip_edges()
	var resolved: String = String(source_text).strip_edges()
	if resolved.is_empty():
		resolved = String(fallback_text).strip_edges()
	if primary_line.is_empty():
		return resolved
	var lines: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {}
	lines.append(primary_line)
	seen[primary_line] = true
	for line_variant in resolved.split("\n", false):
		var line: String = String(line_variant).strip_edges()
		if line.is_empty() or seen.has(line):
			continue
		seen[line] = true
		lines.append(line)
	return "\n".join(lines)


static func sync_event_log_display(event_log_display: Dictionary, source_snapshot: Dictionary, contact_fire_primary_line: String) -> Dictionary:
	var primary_line: String = String(contact_fire_primary_line).strip_edges()
	var display: Dictionary = event_log_display.duplicate(true)
	if primary_line.is_empty():
		return display
	var entries: Array = []
	for entry_variant in Array(display.get("entries", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		if String(entry.get("event_id", "")) == "task_883_real_window_contact_fire_source_sync":
			continue
		entries.append(entry)
	var contact_entry: Dictionary = _build_contact_fire_event_entry(source_snapshot, primary_line, entries)
	entries.insert(0, contact_entry)
	display["entries"] = entries
	display["display_count"] = entries.size()
	display["fallback_active"] = true
	display["fallback_entry"] = contact_entry.duplicate(true)
	display["style_id"] = STYLE_ID
	display["release_first_exchange_real_window_hud_source_sync_active"] = true
	display["event_log_contact_fire_first"] = true
	display["read_only"] = true
	display["ui_sets_gameplay_truth"] = false
	display["creates_command"] = false
	display["creates_fire_event"] = false
	display["creates_damage_event"] = false
	display["creates_movement"] = false
	display["sets_multiplayer_truth"] = false
	return display


static func _build_contact_fire_event_entry(source_snapshot: Dictionary, primary_line: String, existing_entries: Array) -> Dictionary:
	var selected_ids: Array = Array(source_snapshot.get("selected_fireteam_ids", []))
	var fireteam_id: String = String(selected_ids[0]).strip_edges().to_lower() if not selected_ids.is_empty() else String(source_snapshot.get("fireteam_id", "")).strip_edges().to_lower()
	var event_time: int = int(source_snapshot.get("created_msec", 0))
	for entry_variant in existing_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		event_time = maxi(event_time, int(Dictionary(entry_variant).get("created_msec", 0)) + 1)
	if event_time <= 0:
		event_time = int(source_snapshot.get("now_msec", 0))
	var short_text: String = String(source_snapshot.get("event_log_short_text", "CONTACT FIRE: Feuerwechsel lesen")).strip_edges()
	if short_text.is_empty() or not short_text.to_upper().contains("CONTACT FIRE"):
		short_text = "CONTACT FIRE: Feuerwechsel lesen"
	var detail_parts: PackedStringArray = PackedStringArray()
	detail_parts.append(primary_line)
	var mission_text: String = String(source_snapshot.get("mission_control_status_text", "")).strip_edges()
	if not mission_text.is_empty():
		detail_parts.append(mission_text)
	return {
		"event_id": "task_883_real_window_contact_fire_source_sync",
		"event_type": "release_first_exchange_contact_fire_source_sync",
		"fireteam_id": fireteam_id,
		"created_msec": event_time,
		"severity": "tactical",
		"short_text": short_text,
		"detail_text": " | ".join(detail_parts),
		"map_label": String(source_snapshot.get("event_log_map_label", "CONTACT FIRE")).strip_edges(),
		"source": "release_first_exchange_real_window_hud_source_sync",
		"style_id": STYLE_ID,
		"task_id": TASK_ID,
		"source_status_task_id": SOURCE_STATUS_TASK_ID,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


static func _join_primary_lines(lines: Array) -> String:
	var result: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {}
	for line_variant in lines:
		var line: String = String(line_variant).strip_edges()
		if line.is_empty() or seen.has(line):
			continue
		seen[line] = true
		result.append(line)
	return "\n".join(result)


static func _contains_no_fire_before_contact_fire(text: String) -> bool:
	var upper: String = String(text).to_upper()
	var contact_index: int = upper.find("CONTACT FIRE")
	var no_fire_index: int = upper.find("NO FIRE")
	return no_fire_index >= 0 and (contact_index < 0 or no_fire_index < contact_index)


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
