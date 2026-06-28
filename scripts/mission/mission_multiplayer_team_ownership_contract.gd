class_name MissionMultiplayerTeamOwnershipContract
extends RefCounted

const VERTICAL_SLICE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_vertical_slice_contract.gd")
const ROSTER_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_roster_contract.gd")

const HOST_PEER_ID: int = 1
const SCENARIO_OWNER_PEER_ID: int = 0
const PLAY_MODE_SINGLEPLAYER: String = "singleplayer"
const PLAY_MODE_COOP: String = "coop"
const PLAY_MODE_MULTIPLAYER_PVP: String = "multiplayer_pvp"


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

	return {
		"configured": not team_entries.is_empty(),
		"valid": errors.is_empty() and not team_entries.is_empty(),
		"errors": errors,
		"runtime_authority": "MissionMultiplayerTeamOwnershipContract",
		"ui_sets_gameplay_truth": false,
		"play_mode": normalized_play_mode,
		"team_ownership": team_entries,
		"player_team_ids": player_team_ids,
		"npc_team_ids": npc_team_ids,
		"peer_team_assignments": peer_teams.duplicate(true),
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

	return {
		"team_id": team_id,
		"role": String(slot.get("role", "")).strip_edges(),
		"spawn_marker_id": String(slot.get("spawn_marker_id", "")).strip_edges(),
		"default_npc_owned": default_npc_owned,
		"player_assignable": assignable,
		"player_assignable_modes": PackedStringArray(slot.get("player_assignable_modes", PackedStringArray())),
		"assigned_peer_ids": assigned_peer_ids,
		"assigned_peer_count": assigned_peer_ids.size(),
		"npc_controlled": npc_controlled,
		"owner_peer_id": SCENARIO_OWNER_PEER_ID if npc_controlled else int(assigned_peer_ids[0]),
		"roster_source": ROSTER_CONTRACT_SCRIPT.ROSTER_SOURCE_SCENARIO if npc_controlled else _first_roster_source(roster_owner_snapshots),
		"character_gameplay_authority": ROSTER_CONTRACT_SCRIPT.CHARACTER_GAMEPLAY_AUTHORITY,
		"roster_owners": roster_owner_snapshots,
	}


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
