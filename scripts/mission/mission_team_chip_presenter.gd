class_name MissionTeamChipPresenter
extends RefCounted

const TEAM_OWNERSHIP_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_multiplayer_team_ownership_contract.gd")


func build_snapshot(network_contract_snapshot: Dictionary, play_mode: String = "") -> Dictionary:
	var peer_teams: Dictionary = Dictionary(network_contract_snapshot.get("peer_teams", {})).duplicate(true)
	var resolved_play_mode: String = _resolve_play_mode(peer_teams, play_mode)
	var ownership_snapshot: Dictionary = Dictionary(TEAM_OWNERSHIP_CONTRACT_SCRIPT.call(
		"build_team_ownership_snapshot",
		TEAM_OWNERSHIP_CONTRACT_SCRIPT.call("build_default_team_readability_slice"),
		{"peer_teams": peer_teams},
		resolved_play_mode
	))
	var chips: Array = []
	for entry_variant in Array(ownership_snapshot.get("team_readability", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		chips.append(_build_chip_entry(entry))
	return {
		"configured": bool(ownership_snapshot.get("configured", false)),
		"valid": bool(ownership_snapshot.get("valid", false)),
		"errors": PackedStringArray(ownership_snapshot.get("errors", PackedStringArray())),
		"runtime_authority": "MissionTeamChipPresenter",
		"source_authority": String(ownership_snapshot.get("runtime_authority", "MissionMultiplayerTeamOwnershipContract")),
		"ui_sets_gameplay_truth": false,
		"play_mode": resolved_play_mode,
		"chip_count": chips.size(),
		"chips": chips,
		"summary_text": String(ownership_snapshot.get("team_readability_summary", "")),
		"status_text": _build_status_text(chips),
		"compact_status_text": _build_compact_status_text(chips),
	}


func _build_chip_entry(entry: Dictionary) -> Dictionary:
	var short_label: String = String(entry.get("short_label", "")).strip_edges()
	var ownership_label: String = String(entry.get("ownership_label", "")).strip_edges()
	var spawn_marker_id: String = String(entry.get("spawn_marker_id", "")).strip_edges()
	var spawn_label: String = String(entry.get("spawn_label", "")).strip_edges()
	var chip_text: String = String(entry.get("badge_text", "")).strip_edges()
	if chip_text.is_empty():
		chip_text = "%s | %s | %s" % [short_label, ownership_label, spawn_marker_id]
	return {
		"team_id": String(entry.get("team_id", "")).strip_edges(),
		"short_label": short_label,
		"team_color_hex": String(entry.get("team_color_hex", "")),
		"icon_text": _team_icon_text(String(entry.get("team_id", ""))),
		"spawn_icon_text": _spawn_icon_text(spawn_marker_id),
		"compact_text": _build_compact_chip_text(String(entry.get("team_id", "")), short_label, ownership_label, spawn_marker_id),
		"icon_tooltip": _build_icon_tooltip(short_label, ownership_label, spawn_marker_id),
		"visual_priority": _team_visual_priority(String(entry.get("team_id", ""))),
		"ownership_label": ownership_label,
		"control_label": String(entry.get("control_label", "")),
		"spawn_marker_id": spawn_marker_id,
		"spawn_label": spawn_label,
		"chip_text": chip_text,
		"spawn_chip_text": String(entry.get("spawn_chip_text", "%s | %s" % [short_label, spawn_label])),
		"readability_tone": String(entry.get("readability_tone", "")),
		"npc_controlled": bool(entry.get("npc_controlled", false)),
		"assigned_peer_ids": PackedInt32Array(entry.get("assigned_peer_ids", PackedInt32Array())),
		"ui_sets_gameplay_truth": false,
	}


func _build_status_text(chips: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for chip_variant in chips:
		var chip: Dictionary = Dictionary(chip_variant)
		var short_label: String = String(chip.get("short_label", "")).strip_edges()
		var ownership_label: String = String(chip.get("ownership_label", "")).strip_edges()
		var spawn_marker_id: String = String(chip.get("spawn_marker_id", "")).strip_edges()
		if short_label.is_empty() or ownership_label.is_empty():
			continue
		if spawn_marker_id.is_empty():
			parts.append("%s: %s" % [short_label, ownership_label])
		else:
			parts.append("%s: %s @ %s" % [short_label, ownership_label, spawn_marker_id])
	if parts.is_empty():
		return "Teams: not configured"
	return "Teams: %s" % " | ".join(parts)


func _build_compact_status_text(chips: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for chip_variant in chips:
		var chip: Dictionary = Dictionary(chip_variant)
		var compact_text: String = String(chip.get("compact_text", "")).strip_edges()
		if compact_text.is_empty():
			continue
		parts.append(compact_text)
	if parts.is_empty():
		return "Teams: not configured"
	return "Teams: %s" % " | ".join(parts)


func _build_compact_chip_text(team_id: String, short_label: String, ownership_label: String, spawn_marker_id: String) -> String:
	var label: String = short_label.strip_edges()
	if label.is_empty():
		label = "Team"
	var owner: String = ownership_label.strip_edges()
	if owner.is_empty():
		owner = "?"
	return "%s %s %s @ %s" % [_team_icon_text(team_id), label, owner, _spawn_icon_text(spawn_marker_id)]


func _build_icon_tooltip(short_label: String, ownership_label: String, spawn_marker_id: String) -> String:
	var owner: String = ownership_label.strip_edges()
	if owner.is_empty():
		owner = "Owner not set"
	var spawn: String = spawn_marker_id.strip_edges()
	if spawn.is_empty():
		spawn = "spawn not set"
	return "%s | %s | %s" % [short_label, owner, spawn]


func _team_icon_text(team_id: String) -> String:
	match team_id.strip_edges().to_lower():
		"team_alpha":
			return "[A]"
		"team_bravo":
			return "[B]"
		_:
			return "[T]"


func _spawn_icon_text(spawn_marker_id: String) -> String:
	match spawn_marker_id.strip_edges().to_lower():
		"spawn_alpha":
			return "A-LZ"
		"spawn_bravo":
			return "B-LZ"
		"":
			return "LZ?"
		_:
			return spawn_marker_id.strip_edges()


func _team_visual_priority(team_id: String) -> int:
	match team_id.strip_edges().to_lower():
		"team_alpha":
			return 10
		"team_bravo":
			return 20
		_:
			return 90


func _resolve_play_mode(peer_teams: Dictionary, requested_play_mode: String) -> String:
	var normalized: String = requested_play_mode.strip_edges().to_lower()
	if normalized in [
		TEAM_OWNERSHIP_CONTRACT_SCRIPT.PLAY_MODE_SINGLEPLAYER,
		TEAM_OWNERSHIP_CONTRACT_SCRIPT.PLAY_MODE_COOP,
		TEAM_OWNERSHIP_CONTRACT_SCRIPT.PLAY_MODE_MULTIPLAYER_PVP,
	]:
		return normalized
	for peer_id_variant in peer_teams.keys():
		var peer_id: int = int(peer_id_variant)
		var team_id: String = String(peer_teams.get(peer_id_variant, "")).strip_edges()
		if peer_id > 1 and team_id == "team_bravo":
			return TEAM_OWNERSHIP_CONTRACT_SCRIPT.PLAY_MODE_MULTIPLAYER_PVP
	return TEAM_OWNERSHIP_CONTRACT_SCRIPT.PLAY_MODE_COOP
