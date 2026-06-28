class_name MissionBriefingPanelPresenter
extends RefCounted

const TEAM_OWNERSHIP_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_multiplayer_team_ownership_contract.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const BRIEFING_MINIMAP_OVERLAY_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_briefing_minimap_overlay_presenter.gd")
const BRIEFING_MINIMAP_VISUAL_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_briefing_minimap_visual_presenter.gd")


func build_snapshot_from_files(scenario_path: String, map_path: String = "", play_mode: String = TEAM_OWNERSHIP_CONTRACT_SCRIPT.PLAY_MODE_MULTIPLAYER_PVP) -> Dictionary:
	var normalized_scenario_path: String = scenario_path.strip_edges()
	if normalized_scenario_path.is_empty():
		return _empty_snapshot("No scenario file selected.")
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", normalized_scenario_path)
	var resolved_map_path: String = map_path.strip_edges()
	if resolved_map_path.is_empty() and scenario != null:
		resolved_map_path = _get_object_string(scenario, "map_file_path")
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", resolved_map_path) if not resolved_map_path.is_empty() else null
	var minimap_snapshot: Dictionary = Dictionary(BRIEFING_MINIMAP_OVERLAY_PRESENTER_SCRIPT.new().call(
		"build_snapshot_from_files",
		normalized_scenario_path,
		resolved_map_path,
		play_mode
	))
	return build_snapshot(scenario, terrain_map_data, minimap_snapshot, play_mode)


func build_snapshot(scenario, terrain_map_data, minimap_snapshot: Dictionary = {}, play_mode: String = TEAM_OWNERSHIP_CONTRACT_SCRIPT.PLAY_MODE_MULTIPLAYER_PVP) -> Dictionary:
	if scenario == null or not scenario.has_method("get_briefing"):
		return _empty_snapshot("Scenario could not be loaded.")
	var briefing: Dictionary = Dictionary(scenario.call("get_briefing"))
	var minimap_visual_snapshot: Dictionary = Dictionary(BRIEFING_MINIMAP_VISUAL_PRESENTER_SCRIPT.new().call(
		"build_snapshot",
		terrain_map_data,
		minimap_snapshot
	))
	var source_path: String = String(scenario.call("get_source_path")) if scenario.has_method("get_source_path") else ""
	var title: String = String(briefing.get("title", "")).strip_edges()
	if title.is_empty():
		title = _get_object_string(scenario, "display_name")
	if title.is_empty():
		title = "Mission Briefing"
	var summary: String = String(briefing.get("summary", "")).strip_edges()
	var background_image_path: String = String(briefing.get("background_image_path", "")).strip_edges()
	var objectives: Array = _normalize_text_entries(Array(briefing.get("objectives", [])), "objective")
	var threats: Array = _normalize_text_entries(Array(briefing.get("threats", [])), "threat")
	var loadout_entries: Array = _normalize_loadout_entries(Array(briefing.get("recommended_loadout", [])))
	var loadout_card_entries: Array = _build_loadout_card_entries(loadout_entries)
	var team_spawn_lines: PackedStringArray = _build_team_spawn_lines(Array(minimap_snapshot.get("team_spawn_overlays", [])))
	var objective_lines: PackedStringArray = _build_entry_lines(objectives)
	var threat_lines: PackedStringArray = _build_entry_lines(threats)
	var loadout_lines: PackedStringArray = _build_loadout_lines(loadout_entries)
	var has_briefing: bool = not title.is_empty() or not summary.is_empty() or not objectives.is_empty() or not threats.is_empty() or not loadout_entries.is_empty()
	var has_minimap: bool = bool(minimap_snapshot.get("configured", false))
	return {
		"configured": has_briefing,
		"valid": has_briefing and (has_minimap or String(briefing.get("minimap_mode", "none")).strip_edges().to_lower() == "none"),
		"runtime_authority": "MissionBriefingPanelPresenter",
		"ui_sets_gameplay_truth": false,
		"scenario_source": "MissionScenarioData",
		"terrain_source": "TerrainMapData" if terrain_map_data != null else "",
		"minimap_source": "MissionBriefingMinimapOverlayPresenter",
		"minimap_visual_source": "MissionBriefingMinimapVisualPresenter",
		"source_path": source_path,
		"map_path": _get_object_string(scenario, "map_file_path"),
		"play_mode": play_mode,
		"title": title,
		"summary": summary,
		"background_image_path": background_image_path,
		"background_image_exists": _resource_exists(background_image_path),
		"background_image_status_text": _build_background_image_status_text(background_image_path),
		"minimap_mode": String(briefing.get("minimap_mode", "none")).strip_edges().to_lower(),
		"objectives": objectives,
		"threats": threats,
		"recommended_loadout": loadout_entries,
		"loadout_card_entries": loadout_card_entries,
		"objective_lines": objective_lines,
		"threat_lines": threat_lines,
		"loadout_lines": loadout_lines,
		"team_spawn_lines": team_spawn_lines,
		"objective_count": objectives.size(),
		"threat_count": threats.size(),
		"recommended_loadout_count": loadout_entries.size(),
		"loadout_card_count": loadout_card_entries.size(),
		"team_spawn_overlay_count": team_spawn_lines.size(),
		"minimap_snapshot": minimap_snapshot.duplicate(true),
		"minimap_visual_snapshot": minimap_visual_snapshot.duplicate(true),
		"minimap_visual_sample_count": int(minimap_visual_snapshot.get("sample_count", 0)),
		"minimap_visual_entry_count": int(minimap_visual_snapshot.get("entry_count", 0)),
		"panel_status_text": _build_panel_status_text(objectives.size(), threats.size(), team_spawn_lines.size(), loadout_entries.size()),
		"summary_line": _join_or_dash(PackedStringArray([summary])),
		"objective_text": _join_or_dash(objective_lines),
		"threat_text": _join_or_dash(threat_lines),
		"team_spawn_text": _join_or_dash(team_spawn_lines),
		"loadout_text": _join_or_dash(loadout_lines),
	}


func _empty_snapshot(reason: String) -> Dictionary:
	return {
		"configured": false,
		"valid": false,
		"runtime_authority": "MissionBriefingPanelPresenter",
		"ui_sets_gameplay_truth": false,
		"reason": reason,
		"title": "",
		"summary": "",
		"objectives": [],
		"threats": [],
		"recommended_loadout": [],
		"loadout_card_entries": [],
		"background_image_path": "",
		"background_image_exists": false,
		"background_image_status_text": reason,
		"objective_lines": PackedStringArray(),
		"threat_lines": PackedStringArray(),
		"loadout_lines": PackedStringArray(),
		"team_spawn_lines": PackedStringArray(),
		"minimap_visual_snapshot": {},
		"minimap_visual_sample_count": 0,
		"minimap_visual_entry_count": 0,
		"panel_status_text": reason,
		"objective_text": "-",
		"threat_text": "-",
		"team_spawn_text": "-",
		"loadout_text": "-",
	}


func _get_object_string(object, property_name: String) -> String:
	if object == null:
		return ""
	return String(object.get(property_name)).strip_edges()


func _normalize_text_entries(entries: Array, kind: String) -> Array:
	var result: Array = []
	for index in range(entries.size()):
		var entry_variant: Variant = entries[index]
		var normalized: Dictionary = {
			"kind": kind,
			"text": "",
			"target_id": "",
			"display_text": "",
			"ui_sets_gameplay_truth": false,
		}
		if typeof(entry_variant) == TYPE_DICTIONARY:
			var entry: Dictionary = Dictionary(entry_variant)
			normalized["text"] = String(entry.get("text", "")).strip_edges()
			normalized["target_id"] = String(entry.get("target_id", "")).strip_edges()
		else:
			normalized["text"] = String(entry_variant).strip_edges()
		if String(normalized.get("text", "")).is_empty():
			continue
		normalized["display_text"] = _format_targeted_text(String(normalized.get("text", "")), String(normalized.get("target_id", "")))
		result.append(normalized)
	return result


func _normalize_loadout_entries(entries: Array) -> Array:
	var result: Array = []
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var weapon_ids: PackedStringArray = PackedStringArray()
		for weapon_variant in Array(entry.get("weapon_ids", [])):
			var weapon_id: String = String(weapon_variant).strip_edges()
			if not weapon_id.is_empty():
				weapon_ids.append(weapon_id)
		var normalized: Dictionary = {
			"label": String(entry.get("label", "Loadout")).strip_edges(),
			"role_id": String(entry.get("role_id", "")).strip_edges(),
			"armor_id": String(entry.get("armor_id", "")).strip_edges(),
			"weapon_ids": weapon_ids,
			"weapon_summary": _join_or_dash(weapon_ids),
			"count": int(entry.get("count", 0)),
			"reason": String(entry.get("reason", "")).strip_edges(),
			"ui_sets_gameplay_truth": false,
		}
		normalized["display_text"] = _format_loadout_entry(normalized)
		result.append(normalized)
	return result


func _build_loadout_card_entries(entries: Array) -> Array:
	var result: Array = []
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var label: String = String(entry.get("label", "Loadout")).strip_edges()
		var weapon_summary: String = String(entry.get("weapon_summary", "-")).strip_edges()
		var armor_id: String = String(entry.get("armor_id", "")).strip_edges()
		var reason: String = String(entry.get("reason", "")).strip_edges()
		var subtitle_parts: PackedStringArray = PackedStringArray()
		if not weapon_summary.is_empty() and weapon_summary != "-":
			subtitle_parts.append("Weapons: %s" % weapon_summary)
		if not armor_id.is_empty():
			subtitle_parts.append("Armor: %s" % armor_id)
		var subtitle: String = _join_or_dash(subtitle_parts)
		var body: String = reason if not reason.is_empty() else String(entry.get("display_text", "")).strip_edges()
		result.append({
			"label": label,
			"subtitle": subtitle,
			"body": body,
			"weapon_summary": weapon_summary,
			"armor_id": armor_id,
			"count": int(entry.get("count", 0)),
			"role_id": String(entry.get("role_id", "")).strip_edges(),
			"ui_sets_gameplay_truth": false,
		})
	return result


func _build_team_spawn_lines(team_spawn_overlays: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for entry_variant in team_spawn_overlays:
		var entry: Dictionary = Dictionary(entry_variant)
		var text: String = String(entry.get("compact_text", entry.get("text", ""))).strip_edges()
		if text.is_empty():
			text = _format_targeted_text(String(entry.get("team_label", "Team")).strip_edges(), String(entry.get("target_id", "")).strip_edges())
		if not text.is_empty():
			result.append(text)
	return result


func _build_entry_lines(entries: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var line: String = String(entry.get("display_text", "")).strip_edges()
		if not line.is_empty():
			result.append(line)
	return result


func _build_loadout_lines(entries: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var line: String = String(entry.get("display_text", "")).strip_edges()
		if not line.is_empty():
			result.append(line)
	return result


func _format_targeted_text(text: String, target_id: String) -> String:
	if target_id.strip_edges().is_empty():
		return text
	return "%s @ %s" % [text, target_id.strip_edges()]


func _format_loadout_entry(entry: Dictionary) -> String:
	var label: String = String(entry.get("label", "Loadout")).strip_edges()
	var armor_id: String = String(entry.get("armor_id", "")).strip_edges()
	var weapon_text: String = ", ".join(PackedStringArray(entry.get("weapon_ids", PackedStringArray())))
	var parts: PackedStringArray = PackedStringArray()
	if not weapon_text.is_empty():
		parts.append(weapon_text)
	if not armor_id.is_empty():
		parts.append("armor %s" % armor_id)
	var reason: String = String(entry.get("reason", "")).strip_edges()
	var suffix: String = " | %s" % reason if not reason.is_empty() else ""
	if parts.is_empty():
		return "%s%s" % [label, suffix]
	return "%s: %s%s" % [label, " / ".join(parts), suffix]


func _resource_exists(path: String) -> bool:
	var normalized: String = path.strip_edges()
	return not normalized.is_empty() and ResourceLoader.exists(normalized)


func _build_background_image_status_text(path: String) -> String:
	var normalized: String = path.strip_edges()
	if normalized.is_empty():
		return "Briefing image: none"
	if _resource_exists(normalized):
		return "Briefing image: %s" % normalized.get_file()
	return "Briefing image missing: %s" % normalized


func _build_panel_status_text(objective_count: int, threat_count: int, team_count: int, loadout_count: int) -> String:
	return "Briefing: %d Ziele | %d Bedrohungen | %d Team-Spawns | %d Loadout-Hinweise" % [
		objective_count,
		threat_count,
		team_count,
		loadout_count,
	]


func _join_or_dash(lines: PackedStringArray) -> String:
	var filtered: PackedStringArray = PackedStringArray()
	for line in lines:
		var text: String = String(line).strip_edges()
		if not text.is_empty():
			filtered.append(text)
	if filtered.is_empty():
		return "-"
	return " | ".join(filtered)
