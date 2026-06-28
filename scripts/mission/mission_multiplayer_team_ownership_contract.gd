class_name MissionMultiplayerTeamOwnershipContract
extends RefCounted

const VERTICAL_SLICE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_vertical_slice_contract.gd")
const ROSTER_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_roster_contract.gd")

const HOST_PEER_ID: int = 1
const SCENARIO_OWNER_PEER_ID: int = 0
const PLAY_MODE_SINGLEPLAYER: String = "singleplayer"
const PLAY_MODE_COOP: String = "coop"
const PLAY_MODE_MULTIPLAYER_PVP: String = "multiplayer_pvp"
const TEAM_ALPHA_COLOR_HEX: String = "#5fb7ff"
const TEAM_BRAVO_COLOR_HEX: String = "#ff9b5e"
const TEAM_NPC_COLOR_HEX: String = "#9aa3ad"


static func build_team_ownership_snapshot(slice: Dictionary, session_assignments: Dictionary = {}, play_mode: String = PLAY_MODE_SINGLEPLAYER) -> Dictionary:
	var normalized_slice: Dictionary = VERTICAL_SLICE_CONTRACT_SCRIPT.call("normalize_slice", slice)
	var normalized_play_mode: String = _normalize_play_mode(play_mode, normalized_slice)
	var peer_teams: Dictionary = _normalize_peer_team_assignments(Dictionary(session_assignments.get("peer_teams", {})))
	var peer_rosters: Dictionary = Dictionary(session_assignments.get("peer_rosters", {}))
	var team_entries: Array = []
	var errors: PackedStringArray = PackedStringArray()
	var player_team_ids: PackedStringArray = PackedStringArray()
	var npc_team_ids: PackedStringArray = PackedStringArray()

	for slot_variant in Array(normalized_slice.get("team_slots", [])):
		var slot: Dictionary = Dictionary(slot_variant)
		var entry: Dictionary = _build_team_entry(slot, peer_teams, peer_rosters, normalized_play_mode, errors)
		if entry.is_empty():
			continue
		team_entries.append(entry)
		var team_id: String = String(entry.get("team_id", "")).strip_edges()
		if bool(entry.get("npc_controlled", false)):
			if not npc_team_ids.has(team_id):
				npc_team_ids.append(team_id)
		else:
			if not player_team_ids.has(team_id):
				player_team_ids.append(team_id)
	var team_readability: Array = _build_team_readability_entries(team_entries, normalized_play_mode)

	return {
		"configured": not team_entries.is_empty(),
		"valid": errors.is_empty() and not team_entries.is_empty(),
		"errors": errors,
		"runtime_authority": "MissionMultiplayerTeamOwnershipContract",
		"ui_sets_gameplay_truth": false,
		"play_mode": normalized_play_mode,
		"team_ownership": team_entries,
		"team_readability": team_readability,
		"team_readability_summary": _build_team_readability_summary(team_readability, normalized_play_mode),
		"player_team_ids": player_team_ids,
		"npc_team_ids": npc_team_ids,
		"peer_team_assignments": peer_teams.duplicate(true),
	}


static func build_default_team_readability_slice(host_team_id: String = "team_alpha", client_team_id: String = "team_bravo") -> Dictionary:
	return {
		"play_modes": PackedStringArray([
			PLAY_MODE_SINGLEPLAYER,
			PLAY_MODE_COOP,
			PLAY_MODE_MULTIPLAYER_PVP,
		]),
		"team_slots": [
			{
				"team_id": host_team_id.strip_edges(),
				"role": "attacker",
				"spawn_marker_id": "spawn_alpha",
				"npc_owned": false,
				"player_assignable_modes": PackedStringArray([
					PLAY_MODE_SINGLEPLAYER,
					PLAY_MODE_COOP,
					PLAY_MODE_MULTIPLAYER_PVP,
				]),
			},
			{
				"team_id": client_team_id.strip_edges(),
				"role": "defender",
				"spawn_marker_id": "spawn_bravo",
				"npc_owned": true,
				"player_assignable_modes": PackedStringArray([
					PLAY_MODE_MULTIPLAYER_PVP,
				]),
			},
		],
	}


static func get_team_entry(snapshot: Dictionary, team_id: String) -> Dictionary:
	var normalized_team_id: String = team_id.strip_edges()
	for entry_variant in Array(snapshot.get("team_ownership", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("team_id", "")).strip_edges() == normalized_team_id:
			return entry.duplicate(true)
	return {}


static func _build_team_entry(slot: Dictionary, peer_teams: Dictionary, peer_rosters: Dictionary, play_mode: String, errors: PackedStringArray) -> Dictionary:
	var team_id: String = String(slot.get("team_id", "")).strip_edges()
	if team_id.is_empty():
		errors.append("team_slot_missing_team_id")
		return {}

	var assigned_peer_ids: PackedInt32Array = _get_peer_ids_for_team(peer_teams, team_id)
	if assigned_peer_ids.is_empty() and _should_autoseed_host_for_team(slot, play_mode):
		assigned_peer_ids.append(HOST_PEER_ID)

	var assignable: bool = _is_slot_player_assignable(slot, play_mode)
	var default_npc_owned: bool = bool(slot.get("npc_owned", false))
	var npc_controlled: bool = default_npc_owned and assigned_peer_ids.is_empty()
	if not assigned_peer_ids.is_empty() and not assignable:
		errors.append("team_%s_not_player_assignable_in_%s" % [team_id, play_mode])
		npc_controlled = true

	var roster_owner_snapshots: Array = []
	for peer_id in assigned_peer_ids:
		var roster_entry: Dictionary = Dictionary(peer_rosters.get(peer_id, peer_rosters.get(str(peer_id), {})))
		roster_owner_snapshots.append(_build_peer_owner_snapshot(peer_id, roster_entry))

	var entry: Dictionary = {
		"team_id": team_id,
		"role": String(slot.get("role", "")).strip_edges(),
		"spawn_marker_id": String(slot.get("spawn_marker_id", "")).strip_edges(),
		"default_npc_owned": default_npc_owned,
		"player_assignable": assignable,
		"player_assignable_modes": PackedStringArray(slot.get("player_assignable_modes", PackedStringArray())),
		"assigned_peer_ids": assigned_peer_ids,
		"assigned_peer_count": assigned_peer_ids.size(),
		"npc_controlled": npc_controlled,
		"owner_peer_id": _resolve_owner_peer_id(assigned_peer_ids, npc_controlled),
		"roster_source": ROSTER_CONTRACT_SCRIPT.ROSTER_SOURCE_SCENARIO if npc_controlled else _first_roster_source(roster_owner_snapshots),
		"character_gameplay_authority": ROSTER_CONTRACT_SCRIPT.CHARACTER_GAMEPLAY_AUTHORITY,
		"roster_owners": roster_owner_snapshots,
	}
	var display_fields: Dictionary = _build_team_display_fields(entry, play_mode)
	for key in display_fields.keys():
		entry[key] = display_fields[key]
	return entry


static func _build_team_readability_entries(team_entries: Array, play_mode: String) -> Array:
	var result: Array = []
	for entry_variant in team_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var display_entry: Dictionary = {
			"team_id": String(entry.get("team_id", "")),
			"display_name": String(entry.get("display_name", "")),
			"short_label": String(entry.get("short_label", "")),
			"role_label": String(entry.get("role_label", "")),
			"team_color_hex": String(entry.get("team_color_hex", TEAM_NPC_COLOR_HEX)),
			"ownership_label": String(entry.get("ownership_label", "")),
			"control_label": String(entry.get("control_label", "")),
			"peer_label": String(entry.get("peer_label", "")),
			"spawn_marker_id": String(entry.get("spawn_marker_id", "")),
			"spawn_label": String(entry.get("spawn_label", "")),
			"ui_chip_text": String(entry.get("ui_chip_text", "")),
			"badge_text": String(entry.get("badge_text", "")),
			"spawn_chip_text": String(entry.get("spawn_chip_text", "")),
			"readability_tone": String(entry.get("readability_tone", "")),
			"play_mode": play_mode,
			"npc_controlled": bool(entry.get("npc_controlled", false)),
			"assigned_peer_ids": PackedInt32Array(entry.get("assigned_peer_ids", PackedInt32Array())),
			"ui_sets_gameplay_truth": false,
		}
		result.append(display_entry)
	return result


static func _build_team_display_fields(entry: Dictionary, play_mode: String) -> Dictionary:
	var team_id: String = String(entry.get("team_id", "")).strip_edges()
	var role: String = String(entry.get("role", "")).strip_edges()
	var npc_controlled: bool = bool(entry.get("npc_controlled", false))
	var assigned_peer_ids: PackedInt32Array = PackedInt32Array(entry.get("assigned_peer_ids", PackedInt32Array()))
	var short_label: String = _team_short_label(team_id)
	var ownership_label: String = _build_ownership_label(assigned_peer_ids, npc_controlled)
	var spawn_marker_id: String = String(entry.get("spawn_marker_id", "")).strip_edges()
	var spawn_label: String = _spawn_label(spawn_marker_id)
	return {
		"display_name": _team_display_name(team_id, role),
		"short_label": short_label,
		"role_label": _role_label(role),
		"team_color_hex": _team_color_hex(team_id),
		"ownership_label": ownership_label,
		"control_label": _build_control_label(npc_controlled, play_mode),
		"peer_label": _build_peer_label(assigned_peer_ids, npc_controlled),
		"spawn_label": spawn_label,
		"ui_chip_text": "%s: %s" % [short_label, ownership_label],
		"badge_text": _build_badge_text(short_label, ownership_label, spawn_marker_id),
		"spawn_chip_text": "%s | %s" % [short_label, spawn_label],
		"readability_tone": "npc" if npc_controlled else "player",
	}


static func _build_team_readability_summary(readability_entries: Array, play_mode: String) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for entry_variant in readability_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var short_label: String = String(entry.get("short_label", "")).strip_edges()
		var ownership_label: String = String(entry.get("ownership_label", "")).strip_edges()
		if short_label.is_empty() or ownership_label.is_empty():
			continue
		parts.append("%s -> %s" % [short_label, ownership_label])
	var prefix: String = _play_mode_label(play_mode)
	if parts.is_empty():
		return "%s: no team ownership display" % prefix
	return "%s: %s" % [prefix, " | ".join(parts)]


static func _resolve_owner_peer_id(assigned_peer_ids: PackedInt32Array, npc_controlled: bool) -> int:
	if npc_controlled:
		return SCENARIO_OWNER_PEER_ID
	if assigned_peer_ids.is_empty():
		return -1
	return int(assigned_peer_ids[0])


static func _team_display_name(team_id: String, role: String) -> String:
	var short_label: String = _team_short_label(team_id)
	var role_label: String = _role_label(role)
	if role_label.is_empty():
		return short_label
	return "%s %s" % [short_label, role_label]


static func _team_short_label(team_id: String) -> String:
	match team_id.strip_edges().to_lower():
		"team_alpha":
			return "Alpha"
		"team_bravo":
			return "Bravo"
		_:
			var label: String = team_id.strip_edges()
			if label.is_empty():
				return "Team"
			return label.capitalize()


static func _role_label(role: String) -> String:
	match role.strip_edges().to_lower():
		"attacker":
			return "Attack"
		"defender":
			return "Defense"
		"neutral", "":
			return ""
		_:
			return role.strip_edges().capitalize()


static func _team_color_hex(team_id: String) -> String:
	match team_id.strip_edges().to_lower():
		"team_alpha":
			return TEAM_ALPHA_COLOR_HEX
		"team_bravo":
			return TEAM_BRAVO_COLOR_HEX
		_:
			return TEAM_NPC_COLOR_HEX


static func _build_ownership_label(assigned_peer_ids: PackedInt32Array, npc_controlled: bool) -> String:
	if npc_controlled:
		return "NPC / Scenario"
	if assigned_peer_ids.is_empty():
		return "Unassigned"
	var parts: PackedStringArray = PackedStringArray()
	for peer_id in assigned_peer_ids:
		if peer_id == HOST_PEER_ID:
			parts.append("Host Peer 1")
		else:
			parts.append("Peer %d" % peer_id)
	return " + ".join(parts)


static func _build_control_label(npc_controlled: bool, play_mode: String) -> String:
	if npc_controlled:
		return "NPC controlled"
	if play_mode == PLAY_MODE_MULTIPLAYER_PVP:
		return "PvP player controlled"
	return "Player controlled"


static func _build_peer_label(assigned_peer_ids: PackedInt32Array, npc_controlled: bool) -> String:
	if npc_controlled:
		return "Scenario AI"
	if assigned_peer_ids.is_empty():
		return "No peer"
	return _build_ownership_label(assigned_peer_ids, false)


static func _spawn_label(spawn_marker_id: String) -> String:
	if spawn_marker_id.strip_edges().is_empty():
		return "Spawn not set"
	return "Spawn %s" % spawn_marker_id.strip_edges()


static func _build_badge_text(short_label: String, ownership_label: String, spawn_marker_id: String) -> String:
	var spawn_text: String = spawn_marker_id.strip_edges()
	if spawn_text.is_empty():
		spawn_text = "spawn ?"
	return "%s | %s | %s" % [short_label, ownership_label, spawn_text]


static func _play_mode_label(play_mode: String) -> String:
	match play_mode.strip_edges().to_lower():
		PLAY_MODE_MULTIPLAYER_PVP:
			return "PvP"
		PLAY_MODE_COOP:
			return "Coop"
		_:
			return "Singleplayer"


static func _build_peer_owner_snapshot(peer_id: int, roster_entry: Dictionary) -> Dictionary:
	var ownership: Dictionary = ROSTER_CONTRACT_SCRIPT.call("normalize_snapshot_unit_ownership", roster_entry, peer_id, ROSTER_CONTRACT_SCRIPT.ROSTER_SOURCE_PLAYER, roster_entry.get("roster_mode", ROSTER_CONTRACT_SCRIPT.ROSTER_MODE_PLAYER_ROSTERS))
	ownership["peer_id"] = peer_id
	ownership["owner_peer_id"] = int(ownership.get("owner_peer_id", peer_id))
	ownership["character_gameplay_authority"] = ROSTER_CONTRACT_SCRIPT.CHARACTER_GAMEPLAY_AUTHORITY
	return ownership


static func _first_roster_source(roster_owner_snapshots: Array) -> String:
	if roster_owner_snapshots.is_empty():
		return ROSTER_CONTRACT_SCRIPT.ROSTER_SOURCE_PLAYER
	return String(Dictionary(roster_owner_snapshots[0]).get("roster_source", ROSTER_CONTRACT_SCRIPT.ROSTER_SOURCE_PLAYER))


static func _should_autoseed_host_for_team(slot: Dictionary, play_mode: String) -> bool:
	if play_mode == PLAY_MODE_MULTIPLAYER_PVP:
		return false
	if bool(slot.get("npc_owned", false)):
		return false
	return _is_slot_player_assignable(slot, play_mode)


static func _is_slot_player_assignable(slot: Dictionary, play_mode: String) -> bool:
	var modes: PackedStringArray = PackedStringArray(slot.get("player_assignable_modes", PackedStringArray()))
	if modes.is_empty():
		return not bool(slot.get("npc_owned", false))
	return modes.has(play_mode)


static func _get_peer_ids_for_team(peer_teams: Dictionary, team_id: String) -> PackedInt32Array:
	var result: PackedInt32Array = PackedInt32Array()
	var normalized_team_id: String = team_id.strip_edges()
	for peer_id_variant in peer_teams.keys():
		if String(peer_teams.get(peer_id_variant, "")).strip_edges() != normalized_team_id:
			continue
		var peer_id: int = int(peer_id_variant)
		if peer_id > 0 and not result.has(peer_id):
			result.append(peer_id)
	return result


static func _normalize_peer_team_assignments(peer_teams: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for peer_id_variant in peer_teams.keys():
		var peer_id: int = int(peer_id_variant)
		var team_id: String = String(peer_teams.get(peer_id_variant, "")).strip_edges()
		if peer_id <= 0 or team_id.is_empty():
			continue
		result[peer_id] = team_id
	return result


static func _normalize_play_mode(play_mode: String, slice: Dictionary) -> String:
	var normalized: String = play_mode.strip_edges().to_lower()
	var play_modes: PackedStringArray = PackedStringArray(slice.get("play_modes", PackedStringArray()))
	if not normalized.is_empty() and play_modes.has(normalized):
		return normalized
	if play_modes.has(PLAY_MODE_SINGLEPLAYER):
		return PLAY_MODE_SINGLEPLAYER
	return normalized
