extends RefCounted
## One Root-owned host checkpoint. Prepared components remain their own owners.
const SCHEMA="hex_tactical_checkpoint.v1"
class PreparedCheckpoint extends RefCounted:
	pass
var _owner:WeakRef
var _prepared:Dictionary={}

func _init(owner:Node)->void:_owner=weakref(owner)

func guard()->Dictionary:
	var owner:Node=_owner.get_ref()
	if not is_instance_valid(owner) or owner.is_queued_for_deletion() or not owner.is_hex_ground_runtime_active() or owner._should_skip_local_tick_processing():return _reject("checkpoint_owner_unavailable")
	if owner.tick_counter!=owner._hex_ground_runtime.get_current_tick():return _reject("checkpoint_clock_unsynced")
	if not owner.command_queue.is_empty() or not owner.effects_queue.is_empty() or not owner._hex_facing_pending.is_empty():return _reject("checkpoint_pending_work")
	for record in owner._hex_respawn_records.values():
		if record.status!="committed" and owner._hex_respawn_binding(record).get("ok",false):return _reject("checkpoint_pending_respawn")
	for name in ["MissionTestSetup","MissionSetup"]:
		var setup:Node=owner.get_parent().get_node_or_null(name)
		if setup==null:continue
		if setup.has_method("get_runtime_selection_status"):
			var status:Dictionary=setup.call("get_runtime_selection_status")
			if status.get("applying",false) or status.get("queued",false):return _reject("checkpoint_pending_selection")
		if setup.has_method("get_hex_setup_status") and int(setup.call("get_hex_setup_status").get("pending_count",0))>0:return _reject("checkpoint_pending_setup")
	var issue:String=owner._hex_ground_runtime._save_context_issue()
	if not issue.is_empty():return _reject(issue)
	if is_instance_valid(owner._base_personnel_owner):
		issue=owner._base_personnel_owner._checkpoint_issue()
		if not issue.is_empty():return _reject(issue)
	return {"ok":true}

func export_state()->Dictionary:
	var checked:Dictionary=guard()
	if not checked.ok:return checked
	var owner:Node=_owner.get_ref()
	var registry:Node=owner.get_hex_ground_terrain_registry()
	var ground:Dictionary=owner._hex_ground_runtime.export_state()
	var movement:Dictionary=owner._hex_movement_runtime.export_state()
	if ground.get("schema")!="hex_ground_v2":return ground
	if movement.get("schema")!="hex_movement_v1":return movement
	var base:Dictionary={};var transport:Dictionary={}
	if is_instance_valid(owner._base_personnel_owner):
		base=owner._base_personnel_owner.export_checkpoint_state()
		if base.get("version")!=2:return base
		transport=_portable_transport(owner._base_personnel_owner._checkpoint_transport_context(base))
	var state:Dictionary={"schema":SCHEMA,"map_id":ground.map_id,"grid_frame":registry.get_checkpoint_grid_frame(),"map_fingerprint":registry.get_checkpoint_map_fingerprint(),"tick":owner.tick_counter,"rng_state":str(owner._combat_rng.state),"terrain_overrides":registry.export_checkpoint_overrides(),"ground":ground,"movement":movement,"base_personnel":base,"transport":transport}
	checked=validate_shape(state)
	return {"ok":true,"state":state} if checked.ok else checked

static func validate_shape(state:Variant)->Dictionary:
	var keys:Array=["schema","map_id","grid_frame","map_fingerprint","tick","rng_state","terrain_overrides","ground","movement","base_personnel","transport"]
	if not state is Dictionary or state.size()!=keys.size():return {"ok":false,"reason":"invalid_hex_checkpoint"}
	for key in keys:
		if not state.has(key):return {"ok":false,"reason":"invalid_hex_checkpoint"}
	if state.schema!=SCHEMA or not state.map_id is String or state.map_id.is_empty() or not state.map_fingerprint is String or state.map_fingerprint.length()!=64:return {"ok":false,"reason":"invalid_hex_checkpoint_version"}
	if not _integer(state.tick,0,1000000000000) or not state.rng_state is String or state.rng_state.length()>20 or not state.rng_state.is_valid_int() or str(int(state.rng_state))!=state.rng_state:return {"ok":false,"reason":"invalid_hex_checkpoint_clock"}
	for key in ["grid_frame","ground","movement","base_personnel","transport"]:
		if not state[key] is Dictionary:return {"ok":false,"reason":"invalid_hex_checkpoint_block"}
	if not state.terrain_overrides is Array or state.terrain_overrides.size()>4096 or state.ground.get("schema")!="hex_ground_v2" or state.movement.get("schema")!="hex_movement_v1" or state.ground.get("map_id")!=state.map_id or state.movement.get("map_id")!=state.map_id or state.ground.get("tick")!=state.tick or state.movement.get("tick")!=state.tick:return {"ok":false,"reason":"invalid_hex_checkpoint_context"}
	if not state.base_personnel.is_empty() and state.base_personnel.get("version")!=2:return {"ok":false,"reason":"invalid_hex_base_version"}
	var frame:Dictionary=state.grid_frame
	if frame.size()!=4 or frame.get("topology")!="hex_axial_v1" or not frame.get("origin") is Array or frame.origin.size()!=2:return {"ok":false,"reason":"invalid_hex_grid_frame"}
	for value in frame.origin:
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)):return {"ok":false,"reason":"invalid_hex_grid_frame"}
	for key in ["half_width","half_height"]:
		var value:Variant=frame.get(key)
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)) or value<=0:return {"ok":false,"reason":"invalid_hex_grid_frame"}
	if not _valid_transport(state.transport):return {"ok":false,"reason":"invalid_hex_transport"}
	return {"ok":true}

func prepare(state:Dictionary)->Dictionary:
	var checked:Dictionary=guard()
	if not checked.ok:return checked
	checked=validate_shape(state)
	if not checked.ok:return checked
	var owner:Node=_owner.get_ref()
	var registry:Node=owner.get_hex_ground_terrain_registry()
	if state.map_id!=owner.get_hex_ground_planning_snapshot().map_id or state.grid_frame!=registry.get_checkpoint_grid_frame() or state.map_fingerprint!=registry.get_checkpoint_map_fingerprint():return _reject("checkpoint_map_mismatch")
	for id in _prepared.keys():
		if _prepared[id].handle.get_ref()==null:_discard(id)
	if _prepared.size()>=32:return _reject("checkpoint_prepare_capacity")
	var terrain:Dictionary=registry.prepare_checkpoint_overrides(state.terrain_overrides)
	if not terrain.ok:return terrain
	var target_registry:Node=registry.get_checkpoint_target_registry(terrain.prepared)
	var ground_state:Dictionary=state.ground.duplicate(true)
	var movement_state:Dictionary=state.movement.duplicate(true)
	# Revisions are derived counters. Exact map/frame/override values bind portability.
	ground_state.terrain_revision=target_registry.get_revision()
	movement_state.terrain_revision=target_registry.get_revision()
	var ground:Dictionary=owner._hex_ground_runtime.prepare_restore_state(ground_state,target_registry)
	if not ground.ok:
		registry.discard_checkpoint_preparation_id(terrain.prepared.get_instance_id())
		return ground
	var target_ground=owner._hex_ground_runtime.get_prepared_restore_ground(ground.prepared)
	var movement:Dictionary=owner._hex_movement_runtime.prepare_restore_state(movement_state,target_ground,target_registry)
	if not movement.ok:
		registry.discard_checkpoint_preparation_id(terrain.prepared.get_instance_id())
		return movement
	var base:Dictionary={}
	if not state.base_personnel.is_empty():
		if not is_instance_valid(owner._base_personnel_owner):
			registry.discard_checkpoint_preparation_id(terrain.prepared.get_instance_id())
			return _reject("checkpoint_base_owner_missing")
		base=owner._base_personnel_owner.prepare_restore_state(state.base_personnel,ground.prepared,movement.prepared)
		if not base.ok:
			registry.discard_checkpoint_preparation_id(terrain.prepared.get_instance_id())
			return base
		if state.transport!=_portable_transport(owner._base_personnel_owner._checkpoint_transport_context(state.base_personnel)):
			registry.discard_checkpoint_preparation_id(terrain.prepared.get_instance_id())
			return _reject("checkpoint_transport_mismatch")
	elif is_instance_valid(owner._base_personnel_owner):
		registry.discard_checkpoint_preparation_id(terrain.prepared.get_instance_id())
		return _reject("checkpoint_base_missing")
	if state.base_personnel.is_empty() and not state.transport.is_empty():
		registry.discard_checkpoint_preparation_id(terrain.prepared.get_instance_id())
		return _reject("checkpoint_transport_without_base")
	var commands:Dictionary={}
	for intent in movement_state.accepted_intents:
		if intent.status in ["arrived","canceled"]:continue
		var unpacked:Dictionary=owner._hex_movement_runtime._save_unpack_command(intent.command_intent)
		if unpacked.ok:commands[intent.unit_id]=unpacked.command
	var actors:Dictionary={};var actor_models:Dictionary={};var registered:Dictionary={}
	var actor_ids:Array=[];var source_identities:Dictionary={}
	for id in owner._known_units_by_id:
		var actor=owner._resolve_known_unit_for_contract(id)
		if is_instance_valid(actor) and actor is Node2D and actor.has_method("get_unit_id") and String(actor.call("get_unit_id"))==id:actor_ids.append(id)
	for id in target_ground.get_unit_ids():
		if not actor_ids.has(id):actor_ids.append(id)
	for id in actor_ids:
		var actor=owner._resolve_known_unit_for_contract(id)
		if not is_instance_valid(actor) or (target_ground.has_unit(id) and owner.get_unit_registry().get_unit(id)!=actor):
			registry.discard_checkpoint_preparation_id(terrain.prepared.get_instance_id())
			return _reject("checkpoint_actor_unbound")
		source_identities[id]=owner._hex_payload_identity(id)
		actors[id]=actor.get_instance_id()
		registered[id]=owner.get_unit_registry().get_unit(id)==actor
		if actor.has_method("prepare_hex_checkpoint_runtime"):
			var prepared_actor:Dictionary=actor.call("prepare_hex_checkpoint_runtime",owner,Dictionary(commands.get(id,{})))
			if not prepared_actor.ok:
				registry.discard_checkpoint_preparation_id(terrain.prepared.get_instance_id())
				return prepared_actor
			actor_models[id]=prepared_actor.prepared
	var handle:=PreparedCheckpoint.new()
	_prepared[handle.get_instance_id()]={"handle":weakref(handle),"phase":"prepared","state":state.duplicate(true),"terrain":terrain.prepared,"ground":ground.prepared,"movement":movement.prepared,"base":base.get("prepared"),"registry":weakref(registry),"base_owner":weakref(owner._base_personnel_owner) if is_instance_valid(owner._base_personnel_owner) else null,"context":owner.get_hex_ground_context_revision(),"unit_registry":owner.get_unit_registry().get_instance_id(),"actors":actors,"registered":registered,"source_identities":source_identities,"known_ids":owner._known_units_by_id.keys(),"actor_models":actor_models,"commands":commands,"source_rng":owner._combat_rng.state,"source_tick":owner.tick_counter}
	return {"ok":true,"prepared":handle}

func validate(prepared:RefCounted)->Dictionary:
	var record:Dictionary=_record(prepared)
	if record.is_empty() or record.phase!="prepared":return _reject("checkpoint_preparation_unknown")
	var checked:Dictionary=guard()
	if not checked.ok:return checked
	var owner:Node=_owner.get_ref()
	if record.registry.get_ref()!=owner.get_hex_ground_terrain_registry() or record.context!=owner.get_hex_ground_context_revision() or record.unit_registry!=owner.get_unit_registry().get_instance_id() or record.source_tick!=owner.tick_counter or record.source_rng!=owner._combat_rng.state:return _reject("checkpoint_context_changed")
	if owner._known_units_by_id.keys()!=record.known_ids:return _reject("checkpoint_actor_changed")
	for id in record.actors:
		if owner._hex_payload_identity(id)!=record.source_identities[id]:return _reject("checkpoint_actor_changed")
		var actor=owner._resolve_known_unit_for_contract(id)
		if not is_instance_valid(actor) or actor.is_queued_for_deletion() or actor.get_instance_id()!=record.actors[id] or (owner.get_unit_registry().get_unit(id)==actor)!=record.registered[id]:return _reject("checkpoint_actor_changed")
		if record.actor_models.has(id) and not actor.call("validate_runtime_identity_change",record.actor_models[id]).get("ok",false):return _reject("checkpoint_actor_changed")
	for pair in [[record.registry.get_ref(),record.terrain],[owner._hex_ground_runtime,record.ground],[owner._hex_movement_runtime,record.movement]]:
		checked=pair[0].call("validate_checkpoint_preparation" if pair[0] is Node else "validate_prepared_restore",pair[1])
		if not checked.ok:return checked
	if record.base!=null:
		var base:Node=record.base_owner.get_ref()
		if not is_instance_valid(base) or base!=owner._base_personnel_owner:return _reject("checkpoint_base_changed")
		checked=base.validate_prepared_restore(record.base)
		if not checked.ok:return checked
	return {"ok":true}

func commit(prepared:RefCounted,publish:bool=true)->Dictionary:
	var checked:Dictionary=validate(prepared)
	if not checked.ok:return checked
	var record:Dictionary=_record(prepared)
	var owner:Node=_owner.get_ref()
	var next_context:int=owner._hex_ground_context_revision+1
	# ALL participants validated; from here until phase=published there are no callbacks.
	record.registry.get_ref()._publish_checkpoint_preparation(record.terrain)
	owner._hex_ground_runtime._publish_prepared_restore(record.ground,checked)
	owner._hex_movement_runtime._publish_prepared_restore(record.movement,checked)
	owner.tick_counter=int(record.state.tick)
	owner._combat_rng.state=int(record.state.rng_state)
	owner._hex_ground_context_revision=next_context
	owner.command_queue.clear();owner.effects_queue.clear()
	owner._hex_facing_pending={};owner._hex_facing_seen={};owner._hex_boundary_facing={}
	owner._hex_facing_replay_keys.clear();owner._hex_facing_replay_cursor=0
	owner._last_hex_ground_events.clear();owner._last_hex_lifecycle_resolution.clear()
	owner._latest_command_token_by_unit_id={};owner._committed_command_token_by_unit_id={}
	for id in owner._known_units_by_id:owner._hex_unit_lifecycle_revision[id]=int(owner._hex_unit_lifecycle_revision.get(id,0))+1
	if record.base!=null:record.base_owner.get_ref()._publish_prepared_restore(record.base,checked,next_context)
	for id in record.actor_models:owner._resolve_known_unit_for_contract(id)._publish_runtime_identity_change(record.actor_models[id],checked)
	owner._hex_visual_unit_ids={}
	for id in record.actors:owner._hex_visual_unit_ids[id]=true
	owner._hex_projection_terrain_revision=-1
	record.phase="published";record["post_context"]=next_context;record["post_identities"]={}
	for id in record.actors:record.post_identities[id]={"context":next_context,"lifecycle":int(owner._hex_unit_lifecycle_revision.get(id,0)),"actor":int(record.actors[id])}
	return finalize(prepared) if publish else {"ok":true,"committed":true,"published":false}

func finalize(prepared:RefCounted)->Dictionary:
	var record:Dictionary=_record(prepared)
	if record.is_empty():return _reject("checkpoint_preparation_unknown")
	if record.phase=="finalized":return {"ok":true,"replayed":true,"committed":true}
	if record.phase!="published":return _reject("checkpoint_not_committed")
	record.phase="finalized"
	var owner:Node=_owner.get_ref()
	if not _publication_current(record):return {"ok":true,"committed":true,"context_changed":true}
	# Visibility is projection. All presence/base models already agree before signals.
	for id in record.actors:
		var actor=owner._resolve_known_unit_for_contract(id)
		if not owner._hex_ground_runtime.has_unit(id):actor.visible=false
		elif record.base!=null:actor.visible=true
		if not _publication_current(record):return {"ok":true,"committed":true,"context_changed":true}
	owner._project_hex_ground_actors(0.0)
	for id in record.actor_models:
		if not _publication_current(record):return {"ok":true,"committed":true,"context_changed":true}
		owner._resolve_known_unit_for_contract(id).finalize_runtime_identity_change(record.actor_models[id],Callable(self,"_publication_current").bind(record))
	if not _publication_current(record):return {"ok":true,"committed":true,"context_changed":true}
	if record.base!=null:
		var result:Dictionary=record.base_owner.get_ref().finalize_prepared_restore(record.base)
		if result.get("context_changed",false):return {"ok":true,"committed":true,"context_changed":true}
	if is_instance_valid(record.registry.get_ref()):record.registry.get_ref().discard_checkpoint_preparation_id(record.terrain.get_instance_id())
	return {"ok":true,"committed":true,"published":true}

func _publication_current(record:Dictionary)->bool:
	var owner:Node=_owner.get_ref()
	if not is_instance_valid(owner) or owner.is_queued_for_deletion() or owner.get_hex_ground_context_revision()!=record.post_context or owner.tick_counter!=record.state.tick or owner.get_hex_ground_terrain_registry()!=record.registry.get_ref() or owner.get_unit_registry().get_instance_id()!=record.unit_registry:return false
	for id in record.actors:
		var actor=owner._resolve_known_unit_for_contract(id)
		if not is_instance_valid(actor) or actor.is_queued_for_deletion() or actor.get_instance_id()!=record.actors[id]:return false
		if owner._hex_payload_identity(id)!=record.post_identities[id]:return false
	return true

func _record(prepared:RefCounted)->Dictionary:
	if prepared==null:return {}
	var record:Dictionary=_prepared.get(prepared.get_instance_id(),{})
	return record if not record.is_empty() and record.handle.get_ref()==prepared else {}

func _discard(id:int)->void:
	var record:Dictionary=_prepared[id]
	if is_instance_valid(record.registry.get_ref()):record.registry.get_ref().discard_checkpoint_preparation_id(record.terrain.get_instance_id())
	_prepared.erase(id)

func _notification(what:int)->void:
	if what==NOTIFICATION_PREDELETE:
		# RefCounted script teardown cannot dispatch another method on self.
		for record in _prepared.values():
			var registry:Node=record.registry.get_ref()
			if is_instance_valid(registry):registry.discard_checkpoint_preparation_id(record.terrain.get_instance_id())
		_prepared.clear()

static func _portable_transport(witness:Dictionary)->Dictionary:
	var result:Dictionary=witness.duplicate(true)
	for craft in result:
		for team in result[craft].teams:result[craft].teams[team]=Array(result[craft].teams[team])
	return result

static func _valid_transport(witness:Dictionary)->bool:
	if witness.size()>8:return false
	for craft in witness:
		if not craft is String or craft.is_empty() or craft.length()>256:return false
		var value:Variant=witness[craft]
		if not value is Dictionary or value.size()!=3 or not value.get("pilot") is String or value.pilot.length()>256 or not value.get("home") is bool or not value.get("teams") is Dictionary or value.teams.size()>64:return false
		for team in value.teams:
			var members:Variant=value.teams[team]
			if not team is String or team.is_empty() or team.length()>256 or not members is Array or members.size()>64:return false
			var seen:Dictionary={}
			for id in members:
				if not id is String or id.is_empty() or id.length()>256 or seen.has(id):return false
				seen[id]=true
	return true

static func _integer(value:Variant,minimum:int,maximum:int)->bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value)==floorf(float(value)) and value>=minimum and value<=maximum

func _reject(reason:String)->Dictionary:return {"ok":false,"reason":reason}
