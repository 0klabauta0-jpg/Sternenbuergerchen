extends RefCounted
## Host-side interaction policy and pending-use lifecycle, owned by CombatDriver.
## The weak host adapter reads existing mission facts and commits through its
## established progress boundary. There is no second unit/gate/completion state.

var _owner_ref: WeakRef
var _bindings: Dictionary = {}
var _pending: Dictionary = {}


func _init(owner: Node) -> void:
	_owner_ref = weakref(owner)


func _host() -> Node:
	var owner = _owner_ref.get_ref() if _owner_ref != null else null
	return owner if is_instance_valid(owner) and not owner.is_queued_for_deletion() else null


func configure(normalized_bindings: Array) -> void:
	_bindings.clear()
	for entry in normalized_bindings:
		var binding: Dictionary = Dictionary(entry)
		var interaction_id: String = String(binding.get("interaction_id", ""))
		# Ambiguous authored IDs remain unavailable instead of last-writer wins.
		_bindings[interaction_id] = {} if _bindings.has(interaction_id) else binding.duplicate(true)


func clear_pending() -> void:
	_pending.clear()


func get_pending_snapshot() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.pending_network_mission_interactions.v1",
		"pending_count": _pending.size(),
		"entries": _pending.duplicate(true),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func accept_command(command: Dictionary, peer_id: int) -> void:
	var host: Node = _host()
	if host == null:
		return
	var is_interaction: bool = String(command.get("source_context", "")) in ["mission_interaction_door_breach_command", "mission_interaction_use_intent_command"]
	# An accepted replacement order supersedes its operator's old Use, even
	# while the operator is still physically inside the interaction radius.
	if String(command.get("command_type", "")) in ["move_to_position", "hold_position", "engage_area", "retreat", "seek_cover", "move", "engage", "take", "defend", "flank"]:
		for old_id in _pending.keys():
			var old: Dictionary = _pending[old_id]
			if String(old.get("unit_id", "")) == String(command.get("unit_id", "")) and (not is_interaction or String(old_id) != String(command.get("interaction_id", ""))):
				_cancel(String(old_id), old)
	if not ["mission_interaction_door_breach_command", "mission_interaction_use_intent_command"].has(String(command.get("source_context", "")).strip_edges()):
		return
	var resolved: Dictionary = resolve_host_interaction(command)
	if not bool(resolved.get("accepted", false)):
		return
	command = Dictionary(resolved.get("command", {}))
	var interaction_id: String = String(command.get("interaction_id", "")).strip_edges()
	var unit_id: String = String(command.get("unit_id", "")).strip_edges()
	var target_position: Variant = command.get("target_position", null)
	if interaction_id.is_empty() or unit_id.is_empty() or typeof(target_position) != TYPE_VECTOR2:
		return
	var previous_pending: Dictionary = Dictionary(_pending.get(interaction_id, {}))
	var fireteam_id: String = String(command.get("fireteam_id", "")).strip_edges().to_lower()
	var continues_existing: bool = not previous_pending.is_empty() and String(previous_pending.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id and String(previous_pending.get("unit_id", "")) == unit_id and int(previous_pending.get("unit_instance_id", 0)) == int(resolved.get("unit_instance_id", 0))
	var next_pending: Dictionary = {
		"interaction_id": interaction_id,
		"unit_id": unit_id,
		"peer_id": maxi(peer_id, 0),
		"target_position": Vector2(target_position),
		"radius_world": maxf(float(command.get("interaction_radius_world", 72.0)), 1.0),
		"hold_seconds": 0.0,
		"duration_seconds": maxf(float(command.get("duration_seconds", 0.0)), 0.0),
		"fireteam_id": fireteam_id,
		"team_id": String(command.get("team_id", String(host.get("friendly_team_id")))).strip_edges().to_lower(),
		"step_id": String(command.get("step_id", "")).strip_edges(),
		"gate_id": String(command.get("gate_id", command.get("step_id", ""))).strip_edges(),
		"required_state": String(command.get("required_state", "door_open")).strip_edges(),
		"interaction_type": String(command.get("interaction_type", "door")).strip_edges().to_lower(),
		"command_type": String(command.get("command_type", "")).strip_edges().to_lower(),
		"source_context": String(command.get("source_context", "")),
		"unit_instance_id": int(resolved.get("unit_instance_id", 0)),
		"unit_command_instance_id": int(resolved.get("unit_command_instance_id", 0)),
	}
	if continues_existing:
		next_pending["hold_seconds"] = float(previous_pending.get("hold_seconds", 0.0))
	_pending[interaction_id] = next_pending


func validate_command(command: Dictionary, _peer_id: int) -> Dictionary:
	if not ["mission_interaction_door_breach_command", "mission_interaction_use_intent_command"].has(String(command.get("source_context", "")).strip_edges()):
		return {"accepted": true}
	var resolved: Dictionary = resolve_host_interaction(command)
	if not bool(resolved.get("accepted", false)):
		return resolved
	var canonical_command: Dictionary = Dictionary(resolved.get("command", {}))
	var interaction_id: String = String(canonical_command.get("interaction_id", ""))
	var requested_fireteam_id: String = String(canonical_command.get("fireteam_id", ""))
	var pending: Dictionary = Dictionary(_pending.get(interaction_id, {}))
	var owner_fireteam_id: String = String(pending.get("fireteam_id", "")).strip_edges().to_lower()
	if not owner_fireteam_id.is_empty() and owner_fireteam_id != requested_fireteam_id:
		return {"accepted": false, "reason": "interaction_reserved_by_other_fireteam"}
	return resolved


func resolve_host_interaction(command: Dictionary) -> Dictionary:
	var host: Node = _host()
	if host == null:
		return {"accepted": false, "reason": "interaction_owner_unavailable"}
	if not bool(host.get("_runs_local_authority")) or bool(host.get("_combat_finished")):
		return {"accepted": false, "reason": "interaction_mission_inactive"}
	var interaction_id: String = String(command.get("interaction_id", "")).strip_edges()
	var binding: Dictionary = Dictionary(_bindings.get(interaction_id, {}))
	if binding.is_empty():
		return {"accepted": false, "reason": "interaction_unknown"}
	var map_data = host.call("_get_mission_interaction_door_runtime_map_data")
	var marker_id: String = String(binding.get("marker_id", ""))
	if map_data == null or not map_data.has_method("has_marker") or not bool(map_data.call("has_marker", marker_id)):
		return {"accepted": false, "reason": "interaction_marker_unavailable"}
	var target_position: Vector2 = Vector2(map_data.call("get_marker_position", marker_id, Vector2.ZERO))
	var footprint: Dictionary = preload("res://scripts/mission/mission_door_footprint.gd").validate_binding(binding, map_data)
	if not footprint.get("ok", false):
		return {"accepted":false, "reason":String(footprint.get("reason", "invalid_door_footprint"))}
	if interaction_id=="ship_return" and host.get_parent().has_meta("campaign_ground_pilot_id"):
		var controller:Node=host.get_node_or_null("../TacticalController")
		var identity:Dictionary=host.get_parent().get_meta("singleplayer_mission_identity",{})
		if controller==null or not controller.has_method("get_campaign_ground_ship_access"):return {"accepted":false,"reason":"ground_ship_access_unavailable"}
		var access:Dictionary=controller.get_campaign_ground_ship_access(String(identity.get("craft_id","")))
		if not access.get("ok",false):return {"accepted":false,"reason":access.get("reason","ground_ship_access_unavailable")}
		target_position=access.position
	var radius: float = float(binding.get("radius_world", 0.0))
	var duration: float = float(binding.get("duration_seconds", 0.0))
	if not target_position.is_finite() or not is_finite(radius) or not is_finite(duration) or radius <= 0.0 or duration < 0.0:
		return {"accepted": false, "reason": "interaction_binding_invalid"}
	var registry = host.call("_get_unit_registry")
	var unit = registry.call("get_unit", String(command.get("unit_id", ""))) if registry != null and registry.has_method("get_unit") else null
	if not is_instance_valid(unit) or not (unit is Node2D) or not unit.is_inside_tree() or unit.is_queued_for_deletion() or bool(unit.get_meta("dropship_embarked", false)) or not bool(host.call("_is_unit_fit_for_gate_count", unit)):
		return {"accepted": false, "reason": "interaction_unit_unavailable"}
	var team_id: String = String(unit.call("get_team_id")) if unit.has_method("get_team_id") else ""
	var fireteam_id: String = String(unit.call("get_fireteam_id")).to_lower() if unit.has_method("get_fireteam_id") else ""
	var required_team: String = String(binding.get("required_team", "")).to_lower()
	if required_team == "player":
		required_team = String(host.get("friendly_team_id"))
	if team_id.is_empty() or fireteam_id.is_empty() or String(command.get("team_id", "")) != team_id or String(command.get("fireteam_id", "")).to_lower() != fireteam_id or (not required_team in ["", "any"] and required_team != team_id):
		return {"accepted": false, "reason": "interaction_owner_mismatch"}
	if bool(Dictionary(Dictionary(host.get("_mission_interaction_runtime_states")).get(interaction_id, {})).get("complete", false)):
		return {"accepted": false, "reason": "interaction_already_complete"}
	var step_id: String = String(binding.get("step_id", ""))
	var required_step_id: String = String(binding.get("requires_step_id", ""))
	var completed_steps: Array = Array(Dictionary(host.get("_mission_scenario_runtime_gate_snapshot")).get("completed_step_ids", []))
	if not required_step_id.is_empty() and not completed_steps.has(required_step_id):
		return {"accepted": false, "reason": "interaction_prerequisite_incomplete"}
	for gate_variant in Array(Dictionary(host.get("_mission_scenario_runtime_gate_snapshot")).get("gates", [])):
		var gate: Dictionary = Dictionary(gate_variant)
		if String(gate.get("step_id", "")) != step_id:
			continue
		if bool(gate.get("complete", false)):
			return {"accepted": false, "reason": "interaction_already_complete"}
		if not String(gate.get("blocked_by_step_id", "")).is_empty():
			return {"accepted": false, "reason": "interaction_prerequisite_incomplete"}
	var required_order: String = String(binding.get("required_order", "take"))
	var canonical: Dictionary = command.duplicate(true)
	canonical.merge({
		"contract_category": "commander_command", "interaction_id": interaction_id,
		"command_type": "defend" if required_order in ["hold", "defend"] else "take",
		"target_position": target_position, "interaction_radius_world": radius,
		"duration_seconds": duration, "step_id": step_id,
		"gate_id": String(binding.get("gate_id", step_id)),
		"required_state": String(binding.get("required_state", "")),
		"interaction_type": String(binding.get("interaction_type", "")),
		"required_order": required_order, "team_id": team_id, "fireteam_id": fireteam_id,
	}, true)
	var active_command = unit.call("get_current_unit_command") if unit.has_method("get_current_unit_command") else null
	return {"accepted": true, "command": canonical, "unit_instance_id": unit.get_instance_id(), "unit_command_instance_id": active_command.get_instance_id() if active_command != null else 0}


func _cancel(interaction_id: String, pending: Dictionary) -> void:
	var host: Node = _host()
	if host == null:
		return
	pending["hold_seconds"] = 0.0
	pending["state"] = "interrupted"
	if not bool(Dictionary(Dictionary(host.get("_mission_interaction_runtime_states")).get(interaction_id, {})).get("complete", false)):
		_publish(pending, false)
	_pending.erase(interaction_id)


func advance(delta: float) -> void:
	var host: Node = _host()
	if host == null:
		return
	for interaction_id_variant in _pending.keys().duplicate():
		var interaction_id: String = String(interaction_id_variant)
		var pending: Dictionary = Dictionary(_pending.get(interaction_id, {})).duplicate(true)
		var resolved: Dictionary = resolve_host_interaction(pending)
		if not bool(resolved.get("accepted", false)) or int(resolved.get("unit_instance_id", 0)) != int(pending.get("unit_instance_id", 0)):
			_cancel(interaction_id, pending)
			continue
		var unit = host.call("_resolve_runtime_unit_by_id", String(pending.get("unit_id", "")))
		if unit == null or not (unit is Node2D):
			continue
		if int(resolved.get("unit_command_instance_id", 0)) != int(pending.get("unit_command_instance_id", 0)):
			var active_command = unit.call("get_current_unit_command") if unit.has_method("get_current_unit_command") else null
			var active_target: Variant = active_command.get("target_position") if active_command != null else null
			# The host may realize the same Use as Move -> Hold. Other commands,
			# targets or cleared commands invalidate the old arrival/hold receipt.
			if active_command == null or String(active_command.get("source_command_type")) != String(pending.get("command_type", "")) or typeof(active_target) != TYPE_VECTOR2 or not active_target.is_finite() or active_target.distance_to(Vector2(pending.get("target_position", Vector2.ZERO))) > float(pending.get("radius_world", 0.0)):
				_cancel(interaction_id, pending)
				continue
			pending["unit_command_instance_id"] = resolved["unit_command_instance_id"]
		var canonical: Dictionary = Dictionary(resolved.get("command", {}))
		if pending.get("target_position", Vector2.ZERO) != canonical.get("target_position", Vector2.ZERO):
			pending["hold_seconds"] = 0.0
		pending["target_position"] = canonical["target_position"]
		pending["radius_world"] = canonical["interaction_radius_world"]
		var target_position: Vector2 = Vector2(pending.get("target_position", Vector2.ZERO))
		if not (unit as Node2D).global_position.is_finite() or (unit as Node2D).global_position.distance_to(target_position) > float(pending.get("radius_world", 72.0)):
			var had_hold_progress: bool = float(pending.get("hold_seconds", 0.0)) > 0.0
			pending["hold_seconds"] = 0.0
			_pending[interaction_id] = pending
			if had_hold_progress:
				_publish(pending, false)
			continue
		var duration_seconds: float = maxf(float(pending.get("duration_seconds", 0.0)), 0.0)
		var hold_seconds: float = maxf(float(pending.get("hold_seconds", 0.0)) + maxf(delta, 0.0), 0.0)
		var complete: bool = duration_seconds <= 0.0 or hold_seconds + 0.001 >= duration_seconds
		pending["hold_seconds"] = hold_seconds
		_pending[interaction_id] = pending
		var published: bool = _publish(pending, complete)
		if complete and published:
			_pending.erase(interaction_id)


func _publish(pending: Dictionary, complete: bool) -> bool:
	var host: Node = _host()
	if host == null:
		return false
	var interaction_id: String = String(pending.get("interaction_id", "")).strip_edges()
	if interaction_id.is_empty():
		return false
	var duration_seconds: float = maxf(float(pending.get("duration_seconds", 0.0)), 0.0)
	var hold_seconds: float = maxf(float(pending.get("hold_seconds", 0.0)), 0.0)
	var published: Dictionary = host.call("update_mission_interaction_runtime_progress", {
		"interaction_id": interaction_id,
		"state": "complete" if complete else String(pending.get("state", "holding" if String(pending.get("interaction_type", "")) == "hold_zone" else "operating")),
		"complete": complete,
		"hold_seconds": hold_seconds,
		"duration_seconds": duration_seconds,
		"fireteam_id": String(pending.get("fireteam_id", "")),
		"team_id": String(pending.get("team_id", String(host.get("friendly_team_id")))),
		"step_id": String(pending.get("step_id", "")),
		"gate_id": String(pending.get("gate_id", "")),
		"required_state": String(pending.get("required_state", "")),
		"interaction_type": String(pending.get("interaction_type", "")),
		"command_type": String(pending.get("command_type", "")),
		"can_complete_zero_duration": complete and duration_seconds <= 0.0,
	})
	return not published.is_empty() and bool(published.get("accepted", true))
