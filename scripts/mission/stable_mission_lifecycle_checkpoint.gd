extends RefCounted
## Restricted stable, no-enemy mission lifecycle checkpoint. Active combat,
## interactions and timing-sensitive transitions remain rejected until their
## owners have complete snapshots. No UI data is used as gameplay authority.
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const RNG = preload("res://scripts/core/gameplay_rng_state.gd")
const COOLDOWN_FIELDS := ["_discipline_break_cooldown", "_misidentification_cooldown", "_medic_support_cooldown", "_recent_incoming_fire_tick_by_fireteam"]
const BLOCKING_DICTS := ["_queued_bleedout_by_unit_id", "_down_state_started_msec_by_unit_id", "_detection_progress", "_enemy_patrol_paths_by_unit_id", "_enemy_security_states_by_group_id", "_enemy_team_tactics_states_by_group_id", "_mission_interaction_runtime_states", "_mission_scenario_runtime_step_states", "_combat_outcome_by_fire_event_id"]
class PreparedLifecycle extends RefCounted:
	pass
var _preparations: Dictionary = {}

func _guard(sim: Node, driver: Node) -> Dictionary:
	if not is_instance_valid(sim) or not is_instance_valid(driver) or not sim.has_method("get_unit_registry") or not sim.has_method("is_hex_ground_runtime_active") or not is_instance_valid(sim.get_unit_registry()) or sim.is_processing_tick or not sim.command_queue.is_empty() or not sim.effects_queue.is_empty() or driver._combat_finished or driver._current_tick != sim.tick_counter or driver._objective_owned_since_msec >= 0: return _reject("mission_lifecycle_busy")
	if sim.is_hex_ground_runtime_active() and not sim.get_hex_checkpoint_guard().get("ok",false): return _reject("mission_lifecycle_busy")
	for key in BLOCKING_DICTS:
		var value: Variant = driver.get(key)
		if not value is Dictionary or not value.is_empty(): return _reject("mission_lifecycle_unsupported")
	for actor in sim.get_unit_registry().get_all_units():
		if not is_instance_valid(actor) or not actor.has_method("get_team_id") or String(actor.get_team_id()) != driver.friendly_team_id: return _reject("mission_combat_unsupported")
		if not actor.has_method("get_current_unit_command"): return _reject("mission_actor_unsupported")
		var command: RefCounted = actor.get_current_unit_command()
		if not _command_is_stable(sim,actor,command): return _reject("mission_movement_pending")
	var controller: Node = sim.get_parent().get_node_or_null("TacticalController") if is_instance_valid(sim.get_parent()) else null
	if controller != null:
		for field in ["_order_plans_by_key", "_area_orders_by_id"]:
			var plans: Variant = controller.get(field)
			if not plans is Dictionary or not plans.is_empty(): return _reject("mission_planned_orders_unsupported")
		var movement: Variant = controller.get("_fireteam_movement_controller")
		if movement == null or not movement.has_method("get_state_snapshot") or not movement.get_state_snapshot().is_empty(): return _reject("mission_movement_pending")
	return {"ok":true}

func _command_is_stable(sim: Node, actor: Node, command: RefCounted) -> bool:
	if command == null or String(command.get("command_type")) == "hold_position": return true
	# Reaching a Hex destination preserves the accepted command and its stance.
	# Its authoritatively completed intent is safe to capture; a Move label alone
	# must not make post-drop security permanently unsaveable.
	if not sim.is_hex_ground_runtime_active() or String(command.get("command_type")) != "move_to_position" or not actor.has_method("get_unit_id"): return false
	return sim.has_hex_position_arrived(String(actor.get_unit_id()),command.target_position,String(command.command_token))

func _snapshot_fields(sim: Node, driver: Node) -> Dictionary:
	var cooldowns := {}
	for field in COOLDOWN_FIELDS: cooldowns[field] = Dictionary(driver.get(field)).duplicate(true)
	return {"startup_grace":driver._combat_startup_grace_ticks, "seen_friendly":driver._has_seen_active_friendly_units, "seen_enemy":driver._has_seen_active_enemy_units, "resolved_without_friendly":driver._resolved_without_seen_friendly, "latest_tokens":sim._latest_command_token_by_unit_id.duplicate(true), "committed_tokens":sim._committed_command_token_by_unit_id.duplicate(true), "combat_cooldowns":cooldowns, "casualty_flags":driver.export_casualty_state()}

func _source_stamp(sim: Node, driver: Node) -> Dictionary:
	return {"fields":_snapshot_fields(sim,driver), "start":driver._mission_started_at_msec, "offset":driver._checkpoint_elapsed_offset_msec, "limit":driver.mission_time_limit_seconds, "team":driver.friendly_team_id, "scenario_result":driver._mission_result.duplicate(true), "winner":driver._winning_team_id}

func export_state(sim: Node, driver: Node) -> Dictionary:
	var gate := _guard(sim, driver)
	if not gate.ok: return gate
	var encoded := CODEC.encode_value(_snapshot_fields(sim,driver))
	if not encoded.ok: return encoded
	var elapsed := int(round(driver._get_duration_seconds() * 1000.0))
	if elapsed < 0 or elapsed > 2678400000: return _reject("invalid_mission_elapsed")
	return {"ok":true,"schema":"stable_mission_lifecycle.v1","tick":sim.tick_counter,"rng":str(sim._combat_rng.state),"rng_streams":RNG.capture(sim),"elapsed_msec":elapsed,"payload":encoded.value}

func prepare_restore(sim: Node, driver: Node, state: Dictionary) -> Dictionary:
	var gate := _guard(sim,driver)
	if not gate.ok: return gate
	if state.size()!=(7 if state.has("rng_streams") else 6) or not state.has_all(["ok","schema","tick","rng","elapsed_msec","payload"]) or state.ok != true or state.schema != "stable_mission_lifecycle.v1" or not _integer(state.tick,0,1000000000000) or not _integer(state.elapsed_msec,0,2678400000) or typeof(state.rng)!=TYPE_STRING or not state.rng.is_valid_int() or str(int(state.rng))!=state.rng: return _reject("invalid_mission_lifecycle")
	var streams: Variant = state.get("rng_streams", RNG.from_legacy(state.rng))
	if not RNG.validate(streams) or streams.combat != state.rng: return _reject("invalid_mission_lifecycle_rng")
	var decoded := CODEC.decode_value(state.payload)
	if not decoded.ok or not decoded.value is Dictionary: return _reject("invalid_mission_lifecycle")
	var data: Dictionary = decoded.value
	var fields := ["startup_grace","seen_friendly","seen_enemy","resolved_without_friendly","latest_tokens","committed_tokens"]
	# Gefechtstakt: neue Staende haben keinen gemeinsamen Schussplatz mehr. Alte Staende tragen das Feld noch: angenommen, geprueft, ignoriert.
	if data.has("next_attack_tick"):
		fields.append("next_attack_tick")
		if not _integer(data.next_attack_tick,0,1000000000000): return _reject("invalid_mission_lifecycle")
	if data.has("combat_cooldowns"):
		fields.append("combat_cooldowns")
		if not data.combat_cooldowns is Dictionary or data.combat_cooldowns.size() != COOLDOWN_FIELDS.size() or not data.combat_cooldowns.has_all(COOLDOWN_FIELDS): return _reject("invalid_mission_cooldowns")
		for field in COOLDOWN_FIELDS:
			var values: Variant = data.combat_cooldowns[field]
			if not values is Dictionary or values.size() > 128: return _reject("invalid_mission_cooldowns")
			for id in values:
				if not id is String or id.is_empty() or not _integer(values[id],0,1000000000000): return _reject("invalid_mission_cooldowns")
	# Ausfall-Merker des Drivers (Kampagne). Staende vor dieser Erweiterung haben das Feld nicht: dann sind die Merker leer.
	var casualty_ids: Array = []
	for actor in sim.get_unit_registry().get_all_units(): casualty_ids.append(String(actor.get_unit_id()))
	if data.has("casualty_flags"):
		fields.append("casualty_flags")
		var casualty_checked: Dictionary = driver.validate_casualty_state(data.casualty_flags, casualty_ids)
		if not casualty_checked.get("ok",false): return _reject("invalid_mission_casualty_flags")
	if data.size()!=fields.size() or not data.has_all(fields) or not _integer(data.startup_grace,0,1000000) or typeof(data.seen_friendly)!=TYPE_BOOL or typeof(data.seen_enemy)!=TYPE_BOOL or typeof(data.resolved_without_friendly)!=TYPE_BOOL or not data.latest_tokens is Dictionary or not data.committed_tokens is Dictionary: return _reject("invalid_mission_lifecycle")
	for id in data.latest_tokens:
		if typeof(id)!=TYPE_STRING or typeof(data.latest_tokens[id])!=TYPE_STRING: return _reject("invalid_mission_lifecycle")
	for id in data.committed_tokens:
		if typeof(id)!=TYPE_STRING or typeof(data.committed_tokens[id])!=TYPE_STRING: return _reject("invalid_mission_lifecycle")
	for id in _preparations.keys():
		if _preparations[id].handle.get_ref()==null: _preparations.erase(id)
	if _preparations.size()>=32: return _reject("mission_lifecycle_capacity")
	var handle := PreparedLifecycle.new()
	_preparations[handle.get_instance_id()] = {"handle":weakref(handle),"sim":weakref(sim),"driver":weakref(driver),"source_tick":sim.tick_counter,"source_rng":sim._combat_rng.state,"source_stamp":_source_stamp(sim,driver),"data":data,"casualty_ids":casualty_ids,"tick":int(state.tick),"rng":int(state.rng),"elapsed":int(state.elapsed_msec)}
	_preparations[handle.get_instance_id()]["rng_streams"] = streams.duplicate(true)
	_preparations[handle.get_instance_id()]["source_rng_streams"] = RNG.capture(sim)
	return {"ok":true,"prepared":handle}

func validate_restore(handle: RefCounted) -> Dictionary:
	if handle==null or not _preparations.has(handle.get_instance_id()): return _reject("mission_lifecycle_unknown")
	var record: Dictionary = _preparations[handle.get_instance_id()]
	var sim: Node = record.sim.get_ref()
	var driver: Node = record.driver.get_ref()
	if record.handle.get_ref()!=handle or not _guard(sim,driver).get("ok",false) or sim.tick_counter!=record.source_tick or sim._combat_rng.state!=record.source_rng or _source_stamp(sim,driver)!=record.source_stamp: return _reject("mission_lifecycle_changed")
	if RNG.capture(sim) != record.source_rng_streams: return _reject("mission_lifecycle_changed")
	return {"ok":true}

func _publish_restore(handle: RefCounted) -> void:
	var record: Dictionary = _preparations[handle.get_instance_id()]
	_preparations.erase(handle.get_instance_id())
	var sim: Node = record.sim.get_ref()
	var driver: Node = record.driver.get_ref()
	sim.tick_counter=record.tick
	RNG.publish(sim, record.rng_streams)
	sim._latest_command_token_by_unit_id=record.data.latest_tokens
	sim._committed_command_token_by_unit_id=record.data.committed_tokens
	driver._current_tick=record.tick
	driver._combat_startup_grace_ticks=record.data.startup_grace
	driver._has_seen_active_friendly_units=record.data.seen_friendly
	driver._has_seen_active_enemy_units=record.data.seen_enemy
	driver._resolved_without_seen_friendly=record.data.resolved_without_friendly
	for field in COOLDOWN_FIELDS: driver.set(field, Dictionary(record.data.get("combat_cooldowns",{}).get(field,{})).duplicate(true))
	driver.restore_casualty_state(record.data.get("casualty_flags", {"was_downed_unit_ids":[]}), record.casualty_ids)
	driver.restore_checkpoint_elapsed_time(record.elapsed)
	# FT-0b Regel 11: Unterdrueckung steht nicht im Speicherstand; nach dem Wiederherstellen beginnt sie leer.
	if driver.has_method("reset_suppression"): driver.reset_suppression()

func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and floor(float(value))==float(value) and float(value)>=minimum and float(value)<=maximum
func _reject(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
