extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_fire_exchange_contact_fire_primary_hud_polish.v1"
const TASK_ID: String = "TASK_856"
const SOURCE_TASK_ID: String = "TASK_855"
const SOURCE_READABILITY_TASK_ID: String = "TASK_853"
const SOURCE_VISIBILITY_TASK_ID: String = "TASK_847"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const STYLE_ID: String = "task_856_release_fire_exchange_contact_fire_primary_hud_polish_v1"
const NEXT_TASK: String = "TASK_857 - Release Fire Exchange Contact-Fire Primary HUD Recapture"


static func build_snapshot(primary_hud_snapshot: Dictionary, options: Dictionary = {}) -> Dictionary:
	var resolved: Dictionary = primary_hud_snapshot.duplicate(true)
	var combat_hud_density: Dictionary = Dictionary(resolved.get("combat_hud_density", {})).duplicate(true)
	var persistence: Dictionary = Dictionary(combat_hud_density.get("visibility_persistence", resolved.get("visibility_persistence", {}))).duplicate(true)
	var primary_line: String = String(resolved.get("contact_fire_primary_line", "")).strip_edges()
	var selected_text: String = String(resolved.get("selected_fireteam_status_text", "")).strip_edges()
	var mission_text: String = String(resolved.get("mission_control_status_text", "")).strip_edges()
	var compact_line: String = String(combat_hud_density.get("compact_line", resolved.get("compact_line", ""))).strip_edges()
	var active: bool = bool(resolved.get("active", false)) and bool(combat_hud_density.get("visibility_persistence_active", false))
	var primary_text: String = _join_primary_lines([primary_line, selected_text, mission_text])
	var primary_upper: String = primary_text.to_upper()
	var contact_index: int = primary_upper.find("CONTACT FIRE")
	var no_fire_index: int = primary_upper.find("NO FIRE")
	var no_fire_before_contact: bool = no_fire_index >= 0 and (contact_index < 0 or no_fire_index < contact_index)
	var issues: Array = []
	if not active:
		issues.append(_issue("visibility_persistence_not_active", "Release-Fire-Exchange-Persistence ist nicht aktiv."))
	if primary_line.is_empty() or not primary_line.to_upper().begins_with("CONTACT FIRE"):
		issues.append(_issue("primary_line_not_contact_fire", "Primaerzeile beginnt nicht mit CONTACT FIRE."))
	if not selected_text.contains(primary_line):
		issues.append(_issue("selected_fireteam_missing_primary_line", "#17 Selected Fireteam enthaelt die CONTACT-FIRE-Primaerzeile nicht."))
	if not mission_text.contains(primary_line):
		issues.append(_issue("mission_control_missing_primary_line", "#18 Mission Control enthaelt die CONTACT-FIRE-Primaerzeile nicht."))
	if no_fire_before_contact:
		issues.append(_issue("debug_no_fire_before_contact_fire", "NO FIRE steht vor CONTACT FIRE in der Primaerlesung."))
	if compact_line.is_empty():
		issues.append(_issue("compact_fire_line_missing", "Underlying Combat-HUD-Line fehlt."))
	var status: String = "pass" if issues.is_empty() else "review"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_readability_task_id": SOURCE_READABILITY_TASK_ID,
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
		"compact_line": compact_line,
		"selected_fireteam_status_text": selected_text,
		"mission_control_status_text": mission_text,
		"primary_lines_text": primary_text,
		"primary_lines_contain_debug_no_fire_before_contact_fire": no_fire_before_contact,
		"selected_fireteam_contains_contact_fire_primary": selected_text.contains(primary_line) and not primary_line.is_empty(),
		"mission_control_contains_contact_fire_primary": mission_text.contains(primary_line) and not primary_line.is_empty(),
		"visibility_persistence": persistence,
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


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
