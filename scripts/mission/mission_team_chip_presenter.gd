class_name MissionTeamChipPresenter
extends RefCounted

const TEAM_OWNERSHIP_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_multiplayer_team_ownership_contract.gd")


func build_snapshot(network_contract_snapshot: Dictionary, play_mode: String = "") -> Dictionary:
	var peer_teams: Dictionary = Dictionary(network_contract_snapshot.get("peer_teams", {})).duplicate(true)
	var resolved_play_mode: String = _resolve_play_mode(peer_teams, play_mode)
	var authority_visual: Dictionary = build_authority_visual_snapshot(network_contract_snapshot)
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
		"tooltip_text": _build_tooltip_text(chips),
		"authority_visual": authority_visual,
		"authority_visible": bool(authority_visual.get("visible", false)),
		"authority_compact_text": String(authority_visual.get("compact_text", "")),
		"authority_tooltip_text": String(authority_visual.get("tooltip_text", "")),
	}


func build_authority_visual_snapshot(network_contract_snapshot: Dictionary) -> Dictionary:
	var accepted_count: int = int(network_contract_snapshot.get("accepted_count", 0))
	var rejected_count: int = int(network_contract_snapshot.get("rejected_count", 0))
	var last_rejection: Dictionary = Dictionary(network_contract_snapshot.get("last_rejection", {})).duplicate(true)
	var last_reason: String = String(last_rejection.get("reason", "")).strip_edges()
	var last_peer_id: int = int(last_rejection.get("peer_id", 0))
	var last_reject_label: String = _build_reject_reason_label(last_reason)
	var last_reject_target: String = _build_reject_target_label(last_rejection)
	var feedback_line: String = _build_authority_feedback_line(accepted_count, rejected_count, last_peer_id, last_reject_label)
	var feedback_detail: String = _build_authority_feedback_detail(last_peer_id, last_reject_label, last_reject_target)
	var visible_feedback_text: String = _build_visible_feedback_text(rejected_count, last_peer_id, last_reject_label)
	var visible: bool = accepted_count > 0 or rejected_count > 0 or not last_reason.is_empty()
	var compact_text := ""
	if visible:
		compact_text = "AUTH OK%d/RJ%d" % [accepted_count, rejected_count]
	var attention_tone: String = _build_authority_tone(accepted_count, rejected_count)
	var tooltip_parts: PackedStringArray = PackedStringArray()
	if visible:
		tooltip_parts.append("Authority: %d accepted, %d rejected" % [accepted_count, rejected_count])
		if not visible_feedback_text.is_empty():
			tooltip_parts.append("Visible cue: %s" % visible_feedback_text)
		if not feedback_line.is_empty():
			tooltip_parts.append(feedback_line)
		if not feedback_detail.is_empty():
			tooltip_parts.append(feedback_detail)
		if not last_reason.is_empty():
			var peer_text: String = "Peer %d" % last_peer_id if last_peer_id > 0 else "Peer ?"
			tooltip_parts.append("Last reject: %s | %s" % [peer_text, last_reason])
	return {
		"schema": "sternenbuergerchen.host_client_authority_visual.v1",
		"task_id": "TASK_625",
		"visible": visible,
		"accepted_count": accepted_count,
		"rejected_count": rejected_count,
		"last_reject_reason": last_reason,
		"last_reject_label": last_reject_label,
		"last_reject_target": last_reject_target,
		"last_reject_peer_id": last_peer_id,
		"compact_text": compact_text,
		"visible_feedback_text": visible_feedback_text,
		"visible_feedback_ready": not visible_feedback_text.is_empty(),
		"feedback_line": feedback_line,
		"feedback_detail": feedback_detail,
		"tooltip_text": "\n".join(tooltip_parts),
		"input_feedback_ready": visible and (not feedback_line.is_empty() or not compact_text.is_empty()),
		"attention_tone": attention_tone,
		"tone": attention_tone,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _build_authority_tone(accepted_count: int, rejected_count: int) -> String:
	if rejected_count > 0 and accepted_count > 0:
		return "mixed"
	if rejected_count > 0:
		return "reject"
	if accepted_count > 0:
		return "accepted"
	return "idle"


func _build_authority_feedback_line(accepted_count: int, rejected_count: int, peer_id: int, reject_label: String) -> String:
	if rejected_count > 0:
		var peer_text: String = "P%d" % peer_id if peer_id > 0 else "P?"
		var reason_text: String = reject_label.strip_edges()
		if reason_text.is_empty():
			reason_text = "command blocked"
		return "AUTH BLOCKED %s: %s" % [peer_text, reason_text]
	if accepted_count > 0:
		return "AUTH ACCEPTED"
	return ""


func _build_visible_feedback_text(rejected_count: int, peer_id: int, reject_label: String) -> String:
	if rejected_count <= 0:
		return ""
	var peer_text: String = "P%d" % peer_id if peer_id > 0 else "P?"
	var reason_text: String = reject_label.strip_edges()
	if reason_text.is_empty():
		reason_text = "command blocked"
	return "BLOCK %s %s" % [peer_text, reason_text]


func _build_authority_feedback_detail(peer_id: int, reject_label: String, target_label: String) -> String:
	if reject_label.strip_edges().is_empty():
		return ""
	var peer_text: String = "Peer %d" % peer_id if peer_id > 0 else "Peer"
	var target_text: String = target_label.strip_edges()
	if target_text.is_empty():
		return "%s command blocked by server authority." % peer_text
	return "%s cannot command %s." % [peer_text, target_text]


func _build_reject_reason_label(reason: String) -> String:
	match reason.strip_edges().to_lower():
		"peer_team_mismatch":
			return "wrong team"
		"unit_team_mismatch":
			return "unit belongs to another team"
		"fireteam_not_assigned_to_peer":
			return "fireteam not assigned"
		"fireteam_role_missing_fireteam":
			return "fireteam missing"
		"state_mutation_key:damage":
			return "state change blocked"
		"spectator_cannot_command":
			return "spectator cannot command"
		"host_required":
			return "host command required"
		"request_on_non_authority":
			return "not the authority"
		"peer_has_no_team":
			return "peer has no team"
		"":
			return ""
	return reason.strip_edges().replace("_", " ")


func _build_reject_target_label(last_rejection: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var team_id: String = String(last_rejection.get("team_id", "")).strip_edges()
	var fireteam_id: String = String(last_rejection.get("fireteam_id", "")).strip_edges()
	var unit_id: String = String(last_rejection.get("unit_id", "")).strip_edges()
	if not team_id.is_empty():
		parts.append(team_id)
	if not fireteam_id.is_empty():
		parts.append("FT %s" % fireteam_id)
	if not unit_id.is_empty():
		parts.append(unit_id)
	return " / ".join(parts)


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
		"compact_owner_label": _compact_owner_label(ownership_label),
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


func _build_tooltip_text(chips: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("Mission Team Ownership")
	for chip_variant in chips:
		var chip: Dictionary = Dictionary(chip_variant)
		var short_label: String = String(chip.get("short_label", "")).strip_edges()
		var ownership_label: String = String(chip.get("ownership_label", "")).strip_edges()
		var spawn_marker_id: String = String(chip.get("spawn_marker_id", "")).strip_edges()
		if short_label.is_empty() or ownership_label.is_empty():
			continue
		parts.append("%s: %s @ %s" % [
			short_label,
			ownership_label,
			spawn_marker_id if not spawn_marker_id.is_empty() else "spawn not set",
		])
	if parts.size() <= 1:
		parts.append("Teams: not configured")
	return "\n".join(parts)


func _build_compact_chip_text(team_id: String, short_label: String, ownership_label: String, spawn_marker_id: String) -> String:
	var label: String = short_label.strip_edges()
	if label.is_empty():
		label = "Team"
	var owner: String = _compact_owner_label(ownership_label)
	if owner.is_empty():
		owner = "?"
	return "%s %s %s %s" % [_team_icon_text(team_id), label, owner, _spawn_icon_text(spawn_marker_id)]


func _compact_owner_label(ownership_label: String) -> String:
	var owner: String = ownership_label.strip_edges()
	if owner.is_empty():
		return "?"
	var lower_owner: String = owner.to_lower()
	if lower_owner == "host peer 1":
		return "Host"
	if lower_owner.begins_with("peer "):
		return "P%s" % owner.substr(5).strip_edges()
	if lower_owner.contains("npc"):
		return "NPC"
	return owner


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
