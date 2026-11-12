extends RefCounted
## Restricted legacy, no-enemy mission lifecycle checkpoint. Active combat,
## interactions and timing-sensitive transitions remain rejected until their
## owners have complete snapshots. No UI data is used as gameplay authority.
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const BLOCKING_DICTS := ["_queued_bleedout_by_unit_id", "_down_state_started_msec_by_unit_id", "_detection_progress", "_enemy_patrol_paths_by_unit_id", "_enemy_security_states_by_group_id", "_enemy_team_tactics_states_by_group_id", "_mission_interaction_runtime_states", "_mission_scenario_runtime_step_states", "_combat_outcome_by_fire_event_id"]
class PreparedLifecycle extends RefCounted:
	pass
var _preparations: Dictionary = {}

func _guard(sim: Node, driver: Node) -> Dictionary:
	if not is_instance_valid(sim) or not is_instance_valid(driver) or not sim.has_method("get_unit_registry") or not sim.has_method("is_hex_ground_runtime_active") or sim.is_hex_ground_runtime_active() or not is_instance_valid(sim.get_unit_registry()) or sim.is_processing_tick or not sim.command_queue.is_empty() or not sim.effects_queue.is_empty() or driver._combat_finished or driver._current_tick != sim.tick_counter or driver._objective_owned_since_msec >= 0: return _reject("mission_lifecycle_busy")
	for key in BLOCKING_DICTS:
		var value: Variant = driver.get(key)
		if not value is Dictionary or not value.is_empty(): return _reject("mission_lifecycle_unsupported")
	for actor in sim.get_unit_registry().get_all_units():
		if not is_instance_valid(actor) or not actor.has_method("get_team_id") or String(actor.get_team_id()) != driver.friendly_team_id: return _reject("mission_combat_unsupported")
		if not actor.has_method("get_current_unit_command"): return _reject("mission_actor_unsupported")
		var command: RefCounted = actor.get_current_unit_command()
		if command != null and String(command.get("command_type")) != "hold_position": return _reject("mission_movement_pending")
	var controller: Node = sim.get_parent().get_node_or_null("TacticalController") if is_instance_valid(sim.get_parent()) else null
	if controller != null:
		var movement: Variant = controller.get("_fireteam_movement_controller")
		if movement == null or not movement.has_method("get_state_snapshot") or not movement.get_state_snapshot().is_empty(): return _reject("mission_movement_pending")
	return {"ok":true}

func _snapshot_fields(sim: Node, driver: Node) -> Dictionary:
	return {"next_attack_tick":driver._next_attack_tick, "startup_grace":driver._combat_startup_grace_ticks, "seen_friendly":driver._has_seen_active_friendly_units, "seen_enemy":driver._has_seen_active_enemy_units, "resolved_without_friendly":driver._resolved_without_seen_friendly, "latest_tokens":sim._latest_command_token_by_unit_id.duplicate(true), "committed_tokens":sim._committed_command_token_by_unit_id.duplicate(true)}

func _source_stamp(sim: Node, driver: Node) -> Dictionary:
	return {"fields":_snapshot_fields(sim,driver), "start":driver._mission_started_at_msec, "offset":driver._checkpoint_elapsed_offset_msec, "limit":driver.mission_time_limit_seconds, "team":driver.friendly_team_id, "scenario_result":driver._mission_result.duplicate(true), "winner":driver._winning_team_id}

func export_state(sim: Node, driver: Node) -> Dictionary:
	var gate := _guard(sim, driver)
	if not gate.ok: return gate
	var encoded := CODEC.encode_value(_snapshot_fields(sim,driver))
	if not encoded.ok: return encoded
	var elapsed := int(round(driver._get_duration_seconds() * 1000.0))
	if elapsed < 0 or elapsed > 2678400000: return _reject("invalid_mission_elapsed")
	return {"ok":true,"schema":"stable_mission_lifecycle.v1","tick":sim.tick_counter,"rng":str(sim._combat_rng.state),"elapsed_msec":elapsed,"payload":encoded.value}

func prepare_restore(sim: Node, driver: Node, state: Dictionary) -> Dictionary:
	var gate := _guard(sim,driver)
	if not gate.ok: return gate
	if state.size()!=6 or not state.has_all(["ok","schema","tick","rng","elapsed_msec","payload"]) or state.ok != true or state.schema != "stable_mission_lifecycle.v1" or not _integer(state.tick,0,1000000000000) or not _integer(state.elapsed_msec,0,2678400000) or typeof(state.rng)!=TYPE_STRING or not state.rng.is_valid_int() or str(int(state.rng))!=state.rng: return _reject("invalid_mission_lifecycle")
	var decoded := CODEC.decode_value(state.payload)
	if not decoded.ok or not decoded.value is Dictionary: return _reject("invalid_mission_lifecycle")
	var data: Dictionary = decoded.value
	var fields := ["next_attack_tick","startup_grace","seen_friendly","seen_enemy","resolved_without_friendly","latest_tokens","committed_tokens"]
	if data.size()!=fields.size() or not data.has_all(fields) or not _integer(data.next_attack_tick,0,1000000000000) or not _integer(data.startup_grace,0,1000000) or typeof(data.seen_friendly)!=TYPE_BOOL or typeof(data.seen_enemy)!=TYPE_BOOL or typeof(data.resolved_without_friendly)!=TYPE_BOOL or not data.latest_tokens is Dictionary or not data.committed_tokens is Dictionary: return _reject("invalid_mission_lifecycle")
	for id in data.latest_tokens:
		if typeof(id)!=TYPE_STRING or typeof(data.latest_tokens[id])!=TYPE_STRING: return _reject("invalid_mission_lifecycle")
	for id in data.committed_tokens:
		if typeof(id)!=TYPE_STRING or typeof(data.committed_tokens[id])!=TYPE_STRING: return _reject("invalid_mission_lifecycle")
	for id in _preparations.keys():
		if _preparations[id].handle.get_ref()==null: _preparations.erase(id)
	if _preparations.size()>=32: return _reject("mission_lifecycle_capacity")
	var handle := PreparedLifecycle.new()
	_preparations[handle.get_instance_id()] = {"handle":weakref(handle),"sim":weakref(sim),"driver":weakref(driver),"source_tick":sim.tick_counter,"source_rng":sim._combat_rng.state,"source_stamp":_source_stamp(sim,driver),"data":data,"tick":int(state.tick),"rng":int(state.rng),"elapsed":int(state.elapsed_msec)}
	return {"ok":true,"prepared":handle}

func validate_restore(handle: RefCounted) -> Dictionary:
	if handle==null or not _preparations.has(handle.get_instance_id()): return _reject("mission_lifecycle_unknown")
	var record: Dictionary = _preparations[handle.get_instance_id()]
	var sim: Node = record.sim.get_ref()
	var driver: Node = record.driver.get_ref()
	if record.handle.get_ref()!=handle or not _guard(sim,driver).get("ok",false) or sim.tick_counter!=record.source_tick or sim._combat_rng.state!=record.source_rng or _source_stamp(sim,driver)!=record.source_stamp: return _reject("mission_lifecycle_changed")
	return {"ok":true}

func _publish_restore(handle: RefCounted) -> void:
	var record: Dictionary = _preparations[handle.get_instance_id()]
	_preparations.erase(handle.get_instance_id())
	var sim: Node = record.sim.get_ref()
	var driver: Node = record.driver.get_ref()
	sim.tick_counter=record.tick
	sim._combat_rng.state=record.rng
	sim._latest_command_token_by_unit_id=record.data.latest_tokens
	sim._committed_command_token_by_unit_id=record.data.committed_tokens
	driver._current_tick=record.tick
	driver._next_attack_tick=record.data.next_attack_tick
	driver._combat_startup_grace_ticks=record.data.startup_grace
	driver._has_seen_active_friendly_units=record.data.seen_friendly
	driver._has_seen_active_enemy_units=record.data.seen_enemy
	driver._resolved_without_seen_friendly=record.data.resolved_without_friendly
	driver.restore_checkpoint_elapsed_time(record.elapsed)

func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and floor(float(value))==float(value) and float(value)>=minimum and float(value)<=maximum
func _reject(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
