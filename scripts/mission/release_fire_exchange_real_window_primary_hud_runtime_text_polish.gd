extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_fire_exchange_real_window_primary_hud_runtime_text_polish.v1"
const TASK_ID: String = "TASK_862"
const SOURCE_TASK_ID: String = "TASK_861"
const SOURCE_BINDING_TASK_ID: String = "TASK_859"
const SOURCE_PRIMARY_HUD_TASK_ID: String = "TASK_856"
const SOURCE_VISIBILITY_TASK_ID: String = "TASK_847"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const STYLE_ID: String = "task_862_release_fire_exchange_real_window_primary_hud_runtime_text_v1"
const NEXT_TASK: String = "TASK_863 - Release Fire Exchange Runtime Text Recapture"


static func build_runtime_text(source_text: String, contact_fire_primary_line: String, fallback_text: String = "") -> String:
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


static func build_snapshot(runtime_snapshot: Dictionary, options: Dictionary = {}) -> Dictionary:
	var resolved: Dictionary = runtime_snapshot.duplicate(true)
	var combat_hud_density: Dictionary = Dictionary(resolved.get("combat_hud_density", {})).duplicate(true)
	var primary_line: String = String(resolved.get("contact_fire_primary_line", "")).strip_edges()
	var raw_selected_text: String = String(resolved.get("raw_selected_fireteam_status_text", "")).strip_edges()
	var raw_mission_text: String = String(resolved.get("raw_mission_control_status_text", "")).strip_edges()
	var selected_text: String = build_runtime_text(
		String(resolved.get("selected_fireteam_status_text", raw_selected_text)),
		primary_line,
		String(resolved.get("selected_fireteam_fallback_text", ""))
	)
	var mission_text: String = build_runtime_text(
		String(resolved.get("mission_control_status_text", raw_mission_text)),
		primary_line,
		String(resolved.get("mission_control_fallback_text", ""))
	)
	var active: bool = bool(resolved.get("active", false)) and bool(combat_hud_density.get("visibility_persistence_active", false))
	var selected_bound: bool = not primary_line.is_empty() and selected_text.begins_with(primary_line)
	var mission_bound: bool = not primary_line.is_empty() and mission_text.begins_with(primary_line)
	var no_fire_before_contact: bool = _contains_no_fire_before_contact_fire(_join_primary_lines([selected_text, mission_text]))
	var issues: Array = []
	if not active:
		issues.append(_issue("visibility_persistence_not_active", "Release-Fire-Exchange-Persistence ist nicht aktiv."))
	if primary_line.is_empty() or not primary_line.to_upper().begins_with("CONTACT FIRE"):
		issues.append(_issue("primary_line_not_contact_fire", "Runtime-Text hat keine CONTACT-FIRE-Primaerzeile."))
	if not selected_bound:
		issues.append(_issue("selected_fireteam_runtime_text_not_contact_fire_first", "#17 Runtime-Label beginnt nicht mit CONTACT FIRE."))
	if not mission_bound:
		issues.append(_issue("mission_control_runtime_text_not_contact_fire_first", "#18 Runtime-Label beginnt nicht mit CONTACT FIRE."))
	if no_fire_before_contact:
		issues.append(_issue("debug_no_fire_before_contact_fire", "NO FIRE steht weiter vor CONTACT FIRE im Runtime-Text."))
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_binding_task_id": SOURCE_BINDING_TASK_ID,
		"source_primary_hud_task_id": SOURCE_PRIMARY_HUD_TASK_ID,
		"source_visibility_task_id": SOURCE_VISIBILITY_TASK_ID,
		"source_exchange_task_id": SOURCE_EXCHANGE_TASK_ID,
		"style_id": STYLE_ID,
		"status": "pass" if issues.is_empty() else "review",
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
		"selected_fireteam_runtime_text_contact_fire_first": selected_bound,
		"mission_control_runtime_text_contact_fire_first": mission_bound,
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
