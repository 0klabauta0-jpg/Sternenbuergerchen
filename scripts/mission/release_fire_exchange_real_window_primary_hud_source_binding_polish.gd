extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_fire_exchange_real_window_primary_hud_source_binding_polish.v1"
const TASK_ID: String = "TASK_859"
const SOURCE_TASK_ID: String = "TASK_858"
const SOURCE_PRIMARY_HUD_TASK_ID: String = "TASK_856"
const SOURCE_VISIBILITY_TASK_ID: String = "TASK_847"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const STYLE_ID: String = "task_859_release_fire_exchange_real_window_primary_hud_source_binding_v1"
const NEXT_TASK: String = "TASK_860 - Release Fire Exchange Real Window Contact-Fire Recapture"


static func bind_status_text(source_text: String, contact_fire_primary_line: String, fallback_text: String = "") -> String:
	var primary_line: String = String(contact_fire_primary_line).strip_edges()
	var resolved: String = String(source_text).strip_edges()
	if resolved.is_empty():
		resolved = String(fallback_text).strip_edges()
	if primary_line.is_empty():
		return resolved
	var lines: PackedStringArray = PackedStringArray()
	lines.append(primary_line)
	var seen: Dictionary = {}
	seen[primary_line] = true
	for line_variant in resolved.split("\n", false):
		var line: String = String(line_variant).strip_edges()
		if line.is_empty() or seen.has(line):
			continue
		seen[line] = true
		lines.append(line)
	return "\n".join(lines)


static func build_snapshot(source_binding_snapshot: Dictionary, options: Dictionary = {}) -> Dictionary:
	var resolved: Dictionary = source_binding_snapshot.duplicate(true)
	var combat_hud_density: Dictionary = Dictionary(resolved.get("combat_hud_density", {})).duplicate(true)
	var primary_line: String = String(resolved.get("contact_fire_primary_line", "")).strip_edges()
	var raw_selected_text: String = String(resolved.get("raw_selected_fireteam_status_text", "")).strip_edges()
	var raw_mission_text: String = String(resolved.get("raw_mission_control_status_text", "")).strip_edges()
	var selected_text: String = bind_status_text(
		String(resolved.get("selected_fireteam_status_text", raw_selected_text)),
		primary_line,
		String(resolved.get("selected_fireteam_fallback_text", ""))
	)
	var mission_text: String = bind_status_text(
		String(resolved.get("mission_control_status_text", raw_mission_text)),
		primary_line,
		String(resolved.get("mission_control_fallback_text", ""))
	)
	var active: bool = bool(resolved.get("active", false)) and bool(combat_hud_density.get("visibility_persistence_active", false))
	var primary_text: String = _join_primary_lines([selected_text, mission_text])
	var no_fire_before_contact: bool = _contains_no_fire_before_contact_fire(primary_text)
	var issues: Array = []
	if not active:
		issues.append(_issue("visibility_persistence_not_active", "Release-Fire-Exchange-Persistence ist nicht aktiv."))
	if primary_line.is_empty() or not primary_line.to_upper().begins_with("CONTACT FIRE"):
		issues.append(_issue("primary_line_not_contact_fire", "Source-Binding hat keine CONTACT-FIRE-Primaerzeile."))
	var selected_bound: bool = not primary_line.is_empty() and selected_text.begins_with(primary_line)
	var mission_bound: bool = not primary_line.is_empty() and mission_text.begins_with(primary_line)
	if not selected_bound:
		issues.append(_issue("selected_fireteam_not_bound_to_primary_line", "#17 Real-Window-Text beginnt nicht mit der CONTACT-FIRE-Primaerzeile."))
	if not mission_bound:
		issues.append(_issue("mission_control_not_bound_to_primary_line", "#18 Real-Window-Text beginnt nicht mit der CONTACT-FIRE-Primaerzeile."))
	if no_fire_before_contact:
		issues.append(_issue("debug_no_fire_before_contact_fire", "NO FIRE steht weiter vor CONTACT FIRE im gebundenen Real-Window-Text."))
	var status: String = "pass" if issues.is_empty() else "review"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_primary_hud_task_id": SOURCE_PRIMARY_HUD_TASK_ID,
		"source_visibility_task_id": SOURCE_VISIBILITY_TASK_ID,
		"source_exchange_task_id": SOURCE_EXCHANGE_TASK_ID,
		"style_id": STYLE_ID,
		"status": status,
		"active": active,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
		"contact_fire_primary_line": primary_line,
		"raw_selected_fireteam_status_text": raw_selected_text,
		"raw_mission_control_status_text": raw_mission_text,
		"selected_fireteam_status_text": selected_text,
		"mission_control_status_text": mission_text,
		"selected_fireteam_real_window_bound_to_contact_fire": selected_bound,
		"mission_control_real_window_bound_to_contact_fire": mission_bound,
		"primary_lines_contain_debug_no_fire_before_contact_fire": no_fire_before_contact,
		"combat_hud_density": combat_hud_density,
		"issues": issues,
		"issue_count": issues.size(),
		"source": resolved,
		"options": options.duplicate(true),
		"recommended_next_task": NEXT_TASK,
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
