class_name SimulationRoot
extends Node

signal air_support_ground_fired(event: Dictionary)

const UNIT_PROFILE_MATH_SCRIPT=preload("res://scripts/npc/unit_profile_math.gd")
const PERSONNEL_LOADOUT_STATE = preload("res://scripts/core/personnel_loadout_state.gd")
const BASE_PERSONNEL_ACTOR_SCRIPT=preload("res://scripts/core/base_personnel_actor.gd")
var _personnel_loadout_owner: RefCounted = PERSONNEL_LOADOUT_STATE.new()


func get_personnel_loadout_state() -> RefCounted:
	return _personnel_loadout_owner


func configure_personnel_loadouts(owner: RefCounted) -> void:
	_personnel_loadout_owner = owner


func request_personnel_loadout_command(operation: String, payload: Dictionary) -> void:
	match operation:
		"configure_roster":
			_personnel_loadout_owner.call("configure_roster", Array(payload.get("roster", [])))
		"restore":
			_personnel_loadout_owner.call("restore_snapshot", Dictionary(payload.get("loadouts", {})))
		"import_fireteam_loadouts":
			_personnel_loadout_owner.call("import_fireteam_loadouts", Array(payload.get("definitions", [])), Dictionary(payload.get("members", {})))
		"reconcile_context":
			_personnel_loadout_owner.call("reconcile_context", Dictionary(payload.get("defaults", {})), Array(payload.get("definitions", [])), Dictionary(payload.get("members", {})), PackedStringArray(payload.get("retained_unit_ids", [])))
		"set_loadout":
			_personnel_loadout_owner.call("set_loadout", String(payload.get("unit_id", "")), Dictionary(payload.get("loadout", {})))
		"set_slot":
			_personnel_loadout_owner.call("set_slot", String(payload.get("unit_id", "")), String(payload.get("key", "")), String(payload.get("value", "")))

var _base_personnel_owner: Node
var _skirmish_economy_owner: RefCounted
var _skirmish_transaction: Callable

func configure_skirmish_economy(owner: RefCounted, transaction: Callable) -> void:
	_skirmish_economy_owner = owner
	_skirmish_transaction = transaction

func request_skirmish_command(command: Dictionary) -> Dictionary:
	if _skirmish_economy_owner == null:
		return {"ok": false, "reason": "skirmish_economy_unavailable"}
	return _skirmish_economy_owner.call("apply_command", command.duplicate(true), _skirmish_transaction)

func configure_base_personnel(owner: Node) -> void:
	_base_personnel_owner = owner

func request_base_personnel_command(operation: String, payload: Dictionary) -> Dictionary:
	if not is_instance_valid(_base_personnel_owner):
		return {"ok":false,"reason":"base_personnel_unavailable"}
	return _base_personnel_owner.call("apply_operation", operation, payload.duplicate(true))


## Internal base-owner capability. A base projection is deliberately not a
## tactical command actor; it may only use this exact configured owner/registry.
func _validate_base_ground_people(owner:Node,unit_ids:PackedStringArray,require_physical:bool=true)->Dictionary:
	if _should_skip_local_tick_processing():return {"ok":false,"reason":"not_authority"}
	if not is_hex_ground_runtime_active():return {"ok":false,"reason":"hex_ground_inactive"}
	if not is_instance_valid(owner) or owner!=_base_personnel_owner or owner.get_parent()!=get_parent():return {"ok":false,"reason":"wrong_base_owner"}
	if unit_ids.is_empty() or unit_ids.size()>64:return {"ok":false,"reason":"invalid_base_group"}
	var registry:Node=get_unit_registry()
	if not is_instance_valid(registry) or owner.call("get_unit_registry")!=registry or owner.call("get_simulation_root")!=self or owner.call("get_terrain_registry")!=_hex_ground_registry:return {"ok":false,"reason":"wrong_base_registry"}
	if get_parent()==get_tree().root or not get_parent().is_ancestor_of(registry):return {"ok":false,"reason":"invalid_base_scope"}
	var actors:Dictionary={}
	var states:Dictionary=owner.get("_states")
	for id in unit_ids:
		if id.is_empty() or id!=id.strip_edges() or actors.has(id) or not states.has(id):return {"ok":false,"reason":"invalid_base_person"}
		if require_physical and (String(states[id].get("status",""))=="aboard" or not bool(owner.call("_unit_is_home",id))):return {"ok":false,"reason":"base_person_not_on_ground"}
		var actor:Node=registry.call("get_unit",id)
		if not is_instance_valid(actor) or actor.get_parent()!=owner or actor.get_script()!=BASE_PERSONNEL_ACTOR_SCRIPT or owner.call("get_actor",id)!=actor or _known_units_by_id.get(id)!=actor or actor.is_queued_for_deletion():return {"ok":false,"reason":"base_actor_unbound"}
		if String(actor.call("get_unit_id"))!=id:return {"ok":false,"reason":"base_actor_identity"}
		actors[id]=actor
	return {"ok":true,"actors":actors}


func admit_base_ground_people(owner:Node,placements:Array[Dictionary])->Dictionary:
	var ids:=PackedStringArray()
	for entry in placements:
		if not entry.get("unit_id") is String:return {"ok":false,"reason":"invalid_base_person"}
		ids.append(entry.unit_id)
	var checked:Dictionary=_validate_base_ground_people(owner,ids)
	if not checked.ok:return checked
	var mask: Dictionary = _get_hex_respawn_ship_mask()
	if not mask.get("ok", false): return mask
	for entry in placements:
		if mask.blocked_cells.has(entry.get("grid")): return {"ok":false,"reason":"base_clearance_blocked"}
	return admit_hex_ground_units(placements)


func _validate_base_ground_move(owner:Node,id:String,target:Vector2,token:String)->Dictionary:
	var checked:Dictionary=_validate_base_ground_people(owner,PackedStringArray([id]))
	if not checked.ok:return checked
	if not target.is_finite() or token.is_empty() or token.length()>128:return {"ok":false,"reason":"invalid_base_move"}
	if not _hex_ground_runtime.has_unit(id):return {"ok":false,"reason":"base_person_not_admitted"}
	if not _hex_ground_registry.call("is_walkable",_hex_ground_registry.call("world_to_grid",target)):return {"ok":false,"reason":"target_blocked"}
	var mask: Dictionary = _get_hex_respawn_ship_mask()
	if not mask.get("ok", false): return mask
	if mask.blocked_cells.has(_hex_ground_registry.world_to_grid(target)): return {"ok":false,"reason":"target_blocked"}
	return checked


func request_base_ground_move(owner:Node,id:String,target:Vector2,token:String)->Dictionary:
	var checked:Dictionary=_validate_base_ground_move(owner,id,target,token)
	if not checked.ok:return checked
	return _hex_movement_runtime.stage_move({"type":"move_to_position","source_command_type":"base_personnel","unit_id":id,"target_position":target,"command_token":token,"move_speed_factor":1.0},checked.actors[id])


func plan_base_ground_approaches(owner:Node,unit_ids:PackedStringArray,anchor:Vector2i)->Dictionary:
	var checked:Dictionary=_validate_base_ground_people(owner,unit_ids)
	if not checked.ok:return checked
	var snapshot:Dictionary=_hex_ground_runtime.build_planning_snapshot()
	var clearance: Dictionary = _add_base_ground_clearance(snapshot)
	if not clearance.ok: return clearance
	for id in unit_ids:
		if not snapshot.units_by_id.has(id):return {"ok":false,"reason":"base_person_not_admitted"}
		var grid:Vector2i=snapshot.units_by_id[id].grid
		snapshot.units_by_id.erase(id)
		if snapshot.occupant_by_grid.get(grid)==id:snapshot.occupant_by_grid.erase(grid)
	var plan:Dictionary=HEX_ADMISSION_SCRIPT.new().plan_group(unit_ids,anchor,_hex_ground_registry,snapshot,19)
	if not plan.ok:return plan
	for entry in plan.placements:
		if HEX_GRID_SCRIPT.distance(anchor,entry.grid)>2:return {"ok":false,"reason":"boarding_approach_unavailable"}
	return plan


func release_base_ground_people(owner:Node,unit_ids:PackedStringArray,reason:String)->Dictionary:
	if unit_ids.is_empty():return {"ok":true}
	if reason.is_empty():return {"ok":false,"reason":"invalid_base_release"}
	var checked:Dictionary=_validate_base_ground_people(owner,unit_ids,false)
	if not checked.ok:return checked
	for id in unit_ids:
		_discard_pending_move_commands_for_unit(id)
		release_hex_ground_unit(id,reason)
		checked.actors[id].set_meta("dropship_embarked",true)
	return {"ok":true}


func prepare_base_ground_deployment(owner:Node,unit_ids:PackedStringArray,anchor:Vector2i)->Dictionary:
	var checked:Dictionary=_validate_base_ground_people(owner,unit_ids,false)
	if not checked.ok:return checked
	var states:Dictionary=owner.get("_states")
	for id in unit_ids:
		if String(states[id].status)!="aboard" or not bool(owner.call("_unit_is_home",id)):return {"ok":false,"reason":"base_person_not_aboard_home"}
	if _hex_deployment_serial>=HEX_GROUND_RUNTIME_SCRIPT.MAX_TICK:return {"ok":false,"reason":"admission_serial_exhausted"}
	var snapshot:Dictionary=_hex_ground_runtime.build_planning_snapshot()
	var clearance: Dictionary = _add_base_ground_clearance(snapshot)
	if not clearance.ok: return clearance
	var plan:Dictionary=HEX_ADMISSION_SCRIPT.new().plan_group(unit_ids,anchor,_hex_ground_registry,snapshot)
	if not plan.ok:return plan
	_hex_deployment_serial+=1
	var admission_id:String="hex_admission:%d:%d"%[_hex_ground_context_revision,_hex_deployment_serial]
	var placements:Array[Dictionary]=[]
	placements.assign(plan.placements)
	var result:Dictionary=_hex_ground_runtime.reserve_admission_group(admission_id,placements,snapshot.revision)
	if result.ok:_hex_movement_runtime.notify_ground_events([{"event_type":"hex_admission_prepared"}])
	return result


func commit_base_ground_deployment(owner:Node,admission_id:String,publish_actor_projection:bool=true)->Dictionary:
	var ticket:Dictionary=get_hex_ground_deployment(admission_id)
	if not ticket.ok:return ticket
	var ids:PackedStringArray=ticket.remaining_unit_ids
	var checked:Dictionary=_validate_base_ground_people(owner,ids,false)
	if not checked.ok:return checked
	var states:Dictionary=owner.get("_states")
	for id in ids:
		if String(states[id].status)!="aboard" or not bool(owner.call("_unit_is_home",id)):return {"ok":false,"reason":"base_person_not_aboard_home"}
	var placements:Array[Dictionary]=[]
	placements.assign(ticket.placements)
	var committed:Dictionary=_hex_ground_runtime.admit_units(placements,admission_id)
	if not committed.ok:return committed
	for id in ids:
		_hex_visual_unit_ids[id]=true
	if publish_actor_projection:_publish_base_ground_actors(ids)
	return committed

## Station personnel use a separate service ship, not a player's aboard state.
func prepare_polisa_home_ground(owner: Node, id: String, anchor: Vector2i) -> Dictionary:
	var ids := PackedStringArray([id])
	var checked := _validate_base_ground_people(owner, ids, false)
	if not checked.ok: return checked
	if String(owner.get("_states")[id].get("status", "")) != "station": return {"ok":false,"reason":"not_station_personnel"}
	if _hex_deployment_serial >= HEX_GROUND_RUNTIME_SCRIPT.MAX_TICK: return {"ok":false,"reason":"admission_serial_exhausted"}
	var snapshot: Dictionary = _hex_ground_runtime.build_planning_snapshot()
	var plan: Dictionary = {"ok":false,"reason":"no_arrival_space"}
	var planner = HEX_ADMISSION_SCRIPT.new()
	for radius in range(9):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				var candidate := anchor + Vector2i(x, y)
				if HEX_GRID_SCRIPT.distance(anchor, candidate) != radius: continue
				plan = planner.plan_group(ids, candidate, _hex_ground_registry, snapshot, 1)
				if plan.get("ok", false): break
			if plan.get("ok", false): break
		if plan.get("ok", false): break
	if not plan.get("ok", false): return plan
	_hex_deployment_serial += 1
	var admission_id := "hex_admission:%d:%d" % [_hex_ground_context_revision, _hex_deployment_serial]
	var placements: Array[Dictionary] = []
	placements.assign(plan.placements)
	return _hex_ground_runtime.reserve_admission_group(admission_id, placements, snapshot.revision)

func commit_polisa_home_ground(owner: Node, admission_id: String, id: String) -> Dictionary:
	var ticket := get_hex_ground_deployment(admission_id)
	if not ticket.ok: return ticket
	if ticket.remaining_unit_ids != PackedStringArray([id]): return {"ok":false,"reason":"admission_identity_changed"}
	var checked := _validate_base_ground_people(owner, PackedStringArray([id]), false)
	if not checked.ok: return checked
	if String(owner.get("_states")[id].get("status", "")) != "station": return {"ok":false,"reason":"not_station_personnel"}
	var placements: Array[Dictionary] = []
	placements.assign(ticket.placements)
	var committed: Dictionary = _hex_ground_runtime.admit_units(placements, admission_id)
	if committed.ok: _hex_visual_unit_ids[id] = true
	return committed


## Presentation follows the complete multi-owner model publication. In particular,
## no Actor metadata or transform is sent between Ground and Base/Payload tails.
func _publish_base_ground_actors(unit_ids:PackedStringArray)->void:
	for id in unit_ids:
		var actor=_resolve_known_unit_for_contract(id)
		if is_instance_valid(actor) and _hex_ground_runtime.has_unit(id):actor.set_meta("dropship_embarked",false)
	_project_hex_ground_actors(0.0)

signal tick_processed(tick: int)
signal hex_ground_events_committed(events: Array[Dictionary])
signal singleplayer_command_committed(command: Dictionary, result: Dictionary)

var _singleplayer_campaign_owner: RefCounted
var _singleplayer_supply_owner: RefCounted
var _campaign_onboarding_owner: RefCounted
var _singleplayer_space_travel_owner: RefCounted
var _ship_equipment_owner: RefCounted
var _departure_adapter: WeakRef
var _departure_group_receipts: Dictionary = {}


func configure_ship_equipment(owner: RefCounted) -> void:
	_ship_equipment_owner = owner


func configure_singleplayer_owners(campaign: RefCounted, supply: RefCounted, onboarding: RefCounted = null, travel: RefCounted = null) -> void:
	if _singleplayer_space_travel_owner != travel:
		_space_move_receipts.clear()
		_space_fire_receipts.clear()
		_space_fire_rng = 1
	if _singleplayer_campaign_owner != campaign or _singleplayer_supply_owner != supply:
		_departure_group_receipts.clear()
		_departure_adapter = null
	_singleplayer_campaign_owner = campaign
	_singleplayer_supply_owner = supply
	_campaign_onboarding_owner = onboarding
	_singleplayer_space_travel_owner = travel

func configure_departure_adapter(adapter: Node) -> Dictionary:
	if not is_instance_valid(adapter) or not adapter.has_method("preview_departure") or not adapter.has_method("_built_home_pad_ids"): return {"ok":false, "reason":"invalid_adapter"}
	if _departure_adapter != null and _departure_adapter.get_ref() != adapter: return {"ok":false, "reason":"adapter_already_bound"}
	_departure_adapter = weakref(adapter)
	return {"ok":true}

func has_confirmed_cancelled_departure(adapter: Node, craft_id: String, departure_id: String) -> bool:
	if _should_skip_local_tick_processing() or _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter or _singleplayer_space_travel_owner == null or _singleplayer_supply_owner == null: return false
	var id := String(_local_return_latest_by_craft.get(craft_id, ""))
	if departure_id.is_empty() or not id.begins_with("local-cancel:" + departure_id + ":") or not _local_return_receipts.has(id): return false
	var receipt: Dictionary = _local_return_receipts[id]
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if receipt.fleet != _singleplayer_space_travel_owner or receipt.supply != _singleplayer_supply_owner or receipt.supply_epoch != _singleplayer_supply_owner.get("_route_prepare_epoch") or receipt.flight != flight or flight == null: return false
	var snapshot: Dictionary = flight.get_snapshot()
	if snapshot.get("coordinate_frame") != "local" or snapshot.get("motion_mode") != "tactical" or snapshot.get("space_area_id") != receipt.travel_context.target_area_id or _singleplayer_space_travel_owner.get_craft_snapshot(craft_id).get("phase") != "orbit": return false
	var check: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(receipt.travel_candidate, receipt.travel_context)
	return check.get("ok", false) and check.get("replayed", false)

func commit_singleplayer_departure(adapter: Node, craft_id: String, request_id: String, approach_request_id: String = "", station_dock: bool = false) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter: return {"ok":false, "reason":"adapter_required"}
	if craft_id.strip_edges().is_empty() or request_id.strip_edges().is_empty() or _singleplayer_supply_owner == null or _singleplayer_campaign_owner == null: return {"ok":false, "reason":"invalid_departure"}
	if _departure_group_receipts.has(request_id):
		var receipt: Dictionary = _departure_group_receipts[request_id]
		if receipt.craft_id != craft_id: return {"ok":false, "reason":"request_id_conflict"}
		if bool(receipt.get("station_dock", false)) != station_dock: return {"ok":false, "reason":"request_id_conflict"}
		if receipt.supply != _singleplayer_supply_owner or receipt.campaign != _singleplayer_campaign_owner or receipt.supply_epoch != _singleplayer_supply_owner.get("_route_prepare_epoch") or receipt.campaign_epoch != _singleplayer_campaign_owner.get("_departure_preparation_epoch"): return {"ok":false, "reason":"owner_changed"}
		if receipt.approach_request_id != approach_request_id:
			return _commit_singleplayer_reapproach(adapter, craft_id, request_id, approach_request_id, receipt)
		if not approach_request_id.is_empty() and (receipt.fleet != _singleplayer_space_travel_owner or _singleplayer_space_travel_owner == null or receipt.fleet_epoch != _singleplayer_space_travel_owner.get("_space_area_epoch") or receipt.flight != _singleplayer_space_travel_owner.get_flight_state(craft_id)): return {"ok":false, "reason":"owner_changed"}
		if not approach_request_id.is_empty():
			var travel_replay: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(receipt.travel_candidate, receipt.travel_context)
			if not travel_replay.get("ok", false) or not travel_replay.get("replayed", false): return {"ok":false, "reason":"owner_changed"}
		var replay: Dictionary = receipt.result.duplicate(true)
		replay["replayed"] = true
		if replay.has("travel_result"): replay.travel_result["replayed"] = true
		return replay
	if _departure_group_receipts.size() >= 1024: return {"ok":false, "reason":"receipt_capacity"}
	# Adapter re-reads boarding, selection and actual pad immediately before
	# preparation. UI-provided pilot, fuel and departure data are not accepted.
	var gate: Dictionary = adapter.preview_departure(craft_id)
	if not gate.get("ok", false): return gate
	var departure: Dictionary = gate.get("departure", {})
	if departure.get("craft_id") != craft_id: return {"ok":false, "reason":"invalid_departure"}
	if station_dock and (approach_request_id.is_empty() or departure.get("destination_location_id") != "polisa"): return {"ok":false, "reason":"station_destination_required"}
	var pads: Array = adapter._built_home_pad_ids()
	if not _singleplayer_supply_owner.bind_route_fuel_preparation_authority(self): return {"ok":false, "reason":"supply_authority_unavailable"}
	var bound: Dictionary = _singleplayer_campaign_owner.configure_departure_preparation_authority(self)
	if not bound.get("ok", false): return bound
	var fuel := {"contract_category":"singleplayer_supply", "operation":"consume_route_fuel", "payload":departure.duplicate(true), "request_id":request_id + ":fuel"}
	var binding := {"contract_category":"singleplayer_campaign", "operation":"bind_departure", "payload":departure.duplicate(true), "request_id":request_id}
	var activation := {}
	if not String(departure.get("job_id", "")).is_empty():
		activation = {"contract_category":"singleplayer_campaign", "operation":"activate_job", "payload":{"job_id":departure.job_id, "craft_id":craft_id}, "request_id":request_id + ":active"}
	var supply_candidate: Dictionary = _singleplayer_supply_owner.prepare_route_fuel(fuel, {"route_fuel_authority":self, "departure_authorized":true, "require_return_reserve":true})
	if not supply_candidate.get("ok", false): return supply_candidate
	var campaign_context := {"authority":self, "transaction_id":request_id, "built_home_pad_ids":pads.duplicate()}
	var campaign_candidate: Dictionary = _singleplayer_campaign_owner.prepare_departure(binding, activation, campaign_context)
	if not campaign_candidate.get("ok", false): return campaign_candidate
	var travel_context := {}
	var travel_candidate := {}
	var travel_validation := {}
	var flight_validation := {}
	var actor_validation := {}
	var station_landing := false
	var flight: RefCounted
	if not approach_request_id.is_empty():
		if _singleplayer_space_travel_owner == null: return {"ok":false, "reason":"travel_unavailable"}
		flight = _singleplayer_space_travel_owner.get_flight_state(craft_id)
		if flight == null: return {"ok":false, "reason":"unknown_actor"}
		var pose: Dictionary = flight.get_snapshot()
		var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
		var area_id := String(pose.get("space_area_id", ""))
		station_landing = not station_dock and departure.get("destination_location_id") == "polisa" and pose.get("coordinate_frame") == "local"
		if pose.get("coordinate_frame") == "local":
			var area_revision: int = _space_combat_state.get_area_revision(area_id)
			var gate_preview: Dictionary
			if station_dock:
				gate_preview = preview_station_dock_deactivation(craft_id, "polisa_station_dock", "polisa_glut2_dock_v1", pose.revision, travel.get("revision", -1), area_revision, _space_wing_state.get_snapshot().revision, {"runtime_authorized":true,"actor_id":"singleplayer"})
			elif station_landing:
				gate_preview = preview_station_landing_deactivation(craft_id, pose.revision, travel.get("revision", -1), area_revision, _space_wing_state.get_snapshot().revision, {"runtime_authorized":true,"actor_id":"singleplayer"})
			else:
				gate_preview = preview_surface_deactivation(craft_id, String(departure.destination_location_id), pose.revision, travel.get("revision", -1), area_revision, _space_wing_state.get_snapshot().revision, {"runtime_authorized":true,"actor_id":"singleplayer"})
			if not gate_preview.get("ok", false): return gate_preview
			flight_validation = flight.validate_space_activity_transition(gate_preview.activity_proposal, gate_preview.activity_tick)
			actor_validation = _space_combat_state.validate_deactivation(craft_id, pose.revision, area_revision)
			if not flight_validation.get("ok", false) or not actor_validation.get("ok", false): return {"ok":false, "reason":"space_deactivation_invalid"}
		elif station_dock or pose.get("coordinate_frame") != "strategic" or not area_id.is_empty(): return {"ok":false, "reason":"invalid_area"}
		var fleet_bound: Dictionary = _singleplayer_space_travel_owner.configure_space_area_transition_authority(self)
		if not fleet_bound.get("ok", false): return fleet_bound
		var travel_payload := {"craft_id":craft_id, "location_id":String(departure.destination_location_id)}
		var travel_operation := "begin_station_dock" if station_dock else ("begin_station_landing" if station_landing else "begin_approach")
		if station_dock: travel_payload.merge({"target_id":"polisa_station_dock", "layout_revision":"polisa_glut2_dock_v1"})
		travel_context = {"request_id":approach_request_id,"request_signature":JSON.stringify({"operation":travel_operation,"payload":travel_payload}, "", true),"operation":travel_operation,"payload":travel_payload,"source_area_id":area_id,"target_area_id":area_id,"expected_travel_revision":travel.get("revision", -1),"expected_phase":"orbit","context_id":("station-dock:" if station_dock else "departure:") + request_id}
		var context_bound: Dictionary = _singleplayer_space_travel_owner.bind_space_area_transition_context(travel_context, self)
		if not context_bound.get("ok", false): return context_bound
		travel_candidate = _singleplayer_space_travel_owner.prepare_space_area_transition(craft_id, travel_context.expected_travel_revision, area_id, area_id, travel_context)
		if not travel_candidate.get("ok", false):
			_singleplayer_space_travel_owner.release_space_area_transition_context(travel_context.context_id, self)
			return travel_candidate
		travel_validation = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(travel_candidate, travel_context)
	var sv: Dictionary = _singleplayer_supply_owner.validate_prepared_route_fuel(supply_candidate, self)
	var cv: Dictionary = _singleplayer_campaign_owner.validate_prepared_departure(campaign_candidate, campaign_context)
	if not sv.get("ok", false) or not cv.get("ok", false) or sv.get("patch", {}).get("mode") != "apply" or cv.get("replayed", false) or (not approach_request_id.is_empty() and (not travel_validation.get("ok", false) or travel_validation.get("replayed", false))):
		if not travel_context.is_empty(): _singleplayer_space_travel_owner.release_space_area_transition_context(travel_context.context_id, self)
		return {"ok":false, "reason":"departure_validation_failed"}
	# No callbacks or fallible operations between first owner write and receipt.
	var fuel_result: Dictionary = _singleplayer_supply_owner._publish_prepared_route_fuel(supply_candidate, sv)
	var campaign_result: Dictionary = _singleplayer_campaign_owner._publish_prepared_departure(campaign_candidate, cv)
	var result := {"ok":true, "departure":departure.duplicate(true)}
	if not travel_context.is_empty():
		if not flight_validation.is_empty():
			flight._publish_space_activity_transition(flight_validation)
			_space_combat_state._publish_deactivation(actor_validation)
		result["travel_result"] = _singleplayer_space_travel_owner._publish_prepared_space_area_transition(travel_candidate, travel_validation)
	var events: Array = [{"command":fuel, "result":fuel_result}, {"command":binding, "result":campaign_result.binding_result}]
	if not activation.is_empty(): events.append({"command":activation, "result":campaign_result.activation_result})
	if not travel_context.is_empty():
		var travel_command := {"contract_category":"singleplayer_space_travel", "operation":travel_context.operation, "payload":travel_context.payload.duplicate(true), "request_id":approach_request_id}
		events.append({"command":travel_command, "result":result.travel_result})
	_departure_group_receipts[request_id] = {"craft_id":craft_id, "station_dock":station_dock, "station_landing":station_landing, "approach_request_id":approach_request_id, "result":result.duplicate(true), "supply":_singleplayer_supply_owner, "campaign":_singleplayer_campaign_owner, "supply_epoch":_singleplayer_supply_owner.get("_route_prepare_epoch"), "campaign_epoch":_singleplayer_campaign_owner.get("_departure_preparation_epoch"), "fleet":_singleplayer_space_travel_owner if not travel_context.is_empty() else null, "fleet_epoch":_singleplayer_space_travel_owner.get("_space_area_epoch") if not travel_context.is_empty() else -1, "flight":flight, "travel_candidate":travel_candidate.duplicate(true), "travel_context":travel_context.duplicate(true), "events":events.duplicate(true), "events_published":false}
	return result

func _commit_singleplayer_reapproach(adapter: Node, craft_id: String, request_id: String, approach_request_id: String, receipt: Dictionary) -> Dictionary:
	if approach_request_id.is_empty() or not adapter.has_method("preview_reapproach") or _singleplayer_space_travel_owner == null or receipt.fleet != _singleplayer_space_travel_owner: return {"ok":false, "reason":"request_id_conflict"}
	var cancellation_id := String(_local_return_latest_by_craft.get(craft_id, ""))
	if not cancellation_id.begins_with("local-cancel:" + request_id + ":") or not _local_return_receipts.has(cancellation_id): return {"ok":false, "reason":"request_id_conflict"}
	var cancellation: Dictionary = _local_return_receipts[cancellation_id]
	var old_travel: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(receipt.travel_candidate, receipt.travel_context)
	var cancel_travel: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(cancellation.travel_candidate, cancellation.travel_context)
	if not old_travel.get("ok", false) or not old_travel.get("replayed", false) or not cancel_travel.get("ok", false) or not cancel_travel.get("replayed", false): return {"ok":false, "reason":"owner_changed"}
	var gate: Dictionary = adapter.preview_reapproach(craft_id)
	if not gate.get("ok", false): return gate
	if gate.get("departure") != receipt.result.get("departure"): return {"ok":false, "reason":"departure_changed"}
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if flight == null or flight != receipt.flight or _space_combat_state.get_actor(craft_id) != flight: return {"ok":false, "reason":"owner_changed"}
	var pose: Dictionary = flight.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
	var area_revision: int = _space_combat_state.get_area_revision(String(pose.space_area_id))
	var station_dock: bool = bool(receipt.get("station_dock", false))
	var station_landing: bool = bool(receipt.get("station_landing", false))
	var preview: Dictionary
	if station_dock:
		preview = preview_station_dock_deactivation(craft_id, "polisa_station_dock", "polisa_glut2_dock_v1", pose.revision, travel.get("revision", -1), area_revision, _space_wing_state.get_snapshot().revision, {"runtime_authorized":true, "actor_id":"singleplayer"})
	elif station_landing:
		preview = preview_station_landing_deactivation(craft_id, pose.revision, travel.get("revision", -1), area_revision, _space_wing_state.get_snapshot().revision, {"runtime_authorized":true, "actor_id":"singleplayer"})
	else:
		preview = preview_surface_deactivation(craft_id, String(gate.departure.destination_location_id), pose.revision, travel.get("revision", -1), area_revision, _space_wing_state.get_snapshot().revision, {"runtime_authorized":true, "actor_id":"singleplayer"})
	if not preview.get("ok", false): return preview
	var fv: Dictionary = flight.validate_space_activity_transition(preview.activity_proposal, preview.activity_tick)
	var av: Dictionary = _space_combat_state.validate_deactivation(craft_id, pose.revision, area_revision)
	if not fv.get("ok", false) or not av.get("ok", false): return {"ok":false, "reason":"space_deactivation_invalid"}
	var payload := {"craft_id":craft_id, "location_id":String(gate.departure.destination_location_id)}
	var operation := "begin_station_dock" if station_dock else ("begin_station_landing" if station_landing else "begin_approach")
	if station_dock: payload.merge({"target_id":"polisa_station_dock", "layout_revision":"polisa_glut2_dock_v1"})
	var context := {"request_id":approach_request_id,"request_signature":JSON.stringify({"operation":operation,"payload":payload}, "", true),"operation":operation,"payload":payload,"source_area_id":pose.space_area_id,"target_area_id":pose.space_area_id,"expected_travel_revision":travel.revision,"expected_phase":"orbit","context_id":("station-dock:" if station_dock else "reapproach:") + approach_request_id}
	var bound: Dictionary = _singleplayer_space_travel_owner.bind_space_area_transition_context(context, self)
	if not bound.get("ok", false): return bound
	var candidate: Dictionary = _singleplayer_space_travel_owner.prepare_space_area_transition(craft_id, travel.revision, pose.space_area_id, pose.space_area_id, context)
	var tv: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(candidate, context) if candidate.get("ok", false) else candidate
	if not tv.get("ok", false) or tv.get("replayed", false):
		_singleplayer_space_travel_owner.release_space_area_transition_context(context.context_id, self)
		return {"ok":false, "reason":"travel_validation_failed"}
	flight._publish_space_activity_transition(fv)
	_space_combat_state._publish_deactivation(av)
	var travel_result: Dictionary = _singleplayer_space_travel_owner._publish_prepared_space_area_transition(candidate, tv)
	var result := {"ok":true, "departure":gate.departure.duplicate(true), "travel_result":travel_result}
	var command := {"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":approach_request_id}
	receipt.approach_request_id = approach_request_id
	receipt.travel_candidate = candidate.duplicate(true)
	receipt.travel_context = context.duplicate(true)
	receipt.result = result.duplicate(true)
	receipt.events = [{"command":command, "result":travel_result.duplicate(true)}]
	receipt.events_published = false
	return result

func publish_singleplayer_departure_events(adapter: Node, request_id: String) -> void:
	# Adapter has already recorded its token and, for an approach, the outer
	# request receipt. Mark first so observer reentry cannot publish twice.
	if _should_skip_local_tick_processing() or _departure_adapter == null or _departure_adapter.get_ref() != adapter or not _departure_group_receipts.has(request_id): return
	var receipt: Dictionary = _departure_group_receipts[request_id]
	if receipt.events_published: return
	receipt.events_published = true
	var events: Array = receipt.events.duplicate(true)
	for event in events:
		singleplayer_command_committed.emit(event.command, event.result)


var _space_encounter_owner: RefCounted
var _space_runtime_tick: Callable
const SPACE_COMBAT_STATE = preload("res://scripts/core/space_combat_state.gd")
const AIR_DEFENSE_APPROACH_PLAN_SCRIPT = preload("res://scripts/mission/air_defense_approach_plan.gd")
const SPACE_FLIGHT_STATE = preload("res://scripts/core/space_flight_state.gd")
const SPACE_GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const SPACE_AREA_GRID = preload("res://scripts/core/space_area_grid.gd")
const SPACE_NAVIGATION = preload("res://scripts/tactical/space_navigation_resolver.gd")
const SPACE_FLIGHT_RESOLVER = preload("res://scripts/tactical/space_flight_resolver.gd")
const SPACE_GUIDANCE_RESOLVER = preload("res://scripts/tactical/space_guidance_resolver.gd")
const SPACE_AREA_TRANSITION = preload("res://scripts/tactical/space_area_transition_resolver.gd")
const SPACE_ORBIT_ENTRY_SEARCH = preload("res://scripts/tactical/space_orbit_entry_search.gd")
const ORBIT_LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
const ORBIT_SURFACE_LOCATIONS = preload("res://scripts/mission/orbit_surface_locations.gd")
const ORBIT_AUTO_TRANSIT = preload("res://scripts/mission/orbit_auto_transit_planner.gd")
const SPACE_COMMAND_CONTRACT = preload("res://scripts/mission/space_combat_command_contract.gd")
const SPACE_TARGETING = preload("res://scripts/tactical/space_targeting_resolver.gd")
const SPACE_WEAPON = preload("res://scripts/tactical/space_weapon_resolver.gd")
const SPACE_WING_STATE = preload("res://scripts/core/space_wing_state.gd")
var _space_combat_state: RefCounted = SPACE_COMBAT_STATE.new()
var _space_fire_receipts: Dictionary = {}
var _space_fire_rng: int = 1
var _space_wing_state: RefCounted = SPACE_WING_STATE.new()
var _fixture_area_tokens: Dictionary = {}
var _fixture_area_receipts: Dictionary = {}
var _fixture_area_requests: Dictionary = {}
var _fixture_area_blockers: Dictionary = {}
var _fixture_area_sequence := 0
var _space_move_receipts: Dictionary = {}
var _fixture_surface_group_receipts: Dictionary = {}
var _fixture_surface_group_serial := 0
var _local_return_receipts: Dictionary = {}
var _local_return_latest_by_craft: Dictionary = {}
var _warp_entry_searches: Dictionary = {}
var _warp_completion_intents: Dictionary = {}
var _warp_entry_receipts: Dictionary = {}
var _warp_entry_latest_by_craft: Dictionary = {}
var _warp_departure_receipts: Dictionary = {}
var _launch_receipts: Dictionary = {}

func prepare_space_area_transition(craft_id: String, area_id: String, target_pose: Dictionary, expected_flight_revision: int, expected_travel_revision: int, authority_context: Dictionary) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if authority_context.get("runtime_authorized") != true: return {"ok":false, "reason":"runtime_authority_required"}
	_purge_fixture_area_tokens()
	if authority_context.get("fixture") != true or not craft_id.begins_with("space_fixture_") or _singleplayer_space_travel_owner == null:
		return {"ok":false, "reason":"fixture_only"}
	var owner_script: Script = _singleplayer_space_travel_owner.get_script()
	var real_travel_fixture: bool = owner_script != null and owner_script.resource_path == "res://scripts/core/singleplayer_fleet_travel_state.gd"
	var fake_travel_fixture: bool = _singleplayer_space_travel_owner.has_method("is_space_area_transition_fixture") and _singleplayer_space_travel_owner.is_space_area_transition_fixture()
	if not real_travel_fixture and not fake_travel_fixture: return {"ok":false, "reason":"fixture_only"}
	for method in ["get_flight_state", "get_snapshot", "prepare_space_area_transition", "validate_prepared_space_area_transition", "commit_prepared_space_area_transition"]:
		if not _singleplayer_space_travel_owner.has_method(method): return {"ok":false, "reason":"fixture_only"}
	if typeof(authority_context.get("actor_id")) != TYPE_STRING or typeof(authority_context.get("request_id")) != TYPE_STRING or String(authority_context.request_id).is_empty() or typeof(authority_context.get("owned_crafts")) != TYPE_ARRAY or typeof(authority_context.get("craft_pilots")) != TYPE_DICTIONARY:
		return {"ok":false, "reason":"invalid_context"}
	if String(authority_context.actor_id).strip_edges().is_empty() or String(authority_context.request_id).strip_edges().is_empty(): return {"ok":false, "reason":"invalid_context"}
	if not SPACE_COMMAND_CONTRACT._finite(target_pose): return {"ok":false, "reason":"invalid_target"}
	if not SPACE_COMMAND_CONTRACT._finite(authority_context.get("fixture_footprint", [])): return {"ok":false, "reason":"invalid_footprint"}
	if real_travel_fixture and (typeof(authority_context.get("payload")) != TYPE_DICTIONARY or not SPACE_COMMAND_CONTRACT._finite(authority_context.payload)):
		return {"ok":false, "reason":"invalid_context"}
	var request_key := var_to_str([authority_context.actor_id, authority_context.request_id])
	var signature: String = SPACE_COMMAND_CONTRACT.request_signature({"craft_id":craft_id, "area_id":area_id, "target":target_pose, "flight_revision":expected_flight_revision, "travel_revision":expected_travel_revision, "operation":authority_context.get("operation", ""), "payload":authority_context.get("payload", {}), "fixture_footprint":authority_context.get("fixture_footprint", [])})
	if _fixture_area_requests.has(request_key):
		var prior: Dictionary = _fixture_area_requests[request_key]
		if prior.signature != signature: return {"ok":false, "reason":"request_id_conflict"}
		var existing: Dictionary = _fixture_area_tokens.get(prior.token, _fixture_area_receipts.get(prior.token, {}))
		if not existing.is_empty() and existing.context == authority_context and existing.owner == _singleplayer_space_travel_owner:
			return {"ok":true, "token":prior.token, "replayed":true}
		return {"ok":false, "reason":"context_changed"}
	if _fixture_area_tokens.size() >= 128: return {"ok":false, "reason":"fixture_capacity"}
	var existing_flight: RefCounted = _space_combat_state.get_actor(craft_id)
	var inactive_flight: RefCounted = _space_combat_state.get_inactive_actor(craft_id)
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if flight == null or (existing_flight != null and existing_flight != flight) or (inactive_flight != null and inactive_flight != flight) or flight.get_snapshot().get("craft_id") != craft_id: return {"ok":false, "reason":"unknown_actor"}
	var surface_exit: bool = inactive_flight != null and real_travel_fixture and authority_context.get("operation") == "enter_orbit"
	if inactive_flight != null and not surface_exit: return {"ok":false, "reason":"invalid_phase"}
	var needs_admission: bool = existing_flight == null and not surface_exit
	if needs_admission and typeof(authority_context.get("fixture_footprint")) != TYPE_ARRAY: return {"ok":false, "reason":"invalid_footprint"}
	var travel: Dictionary = _singleplayer_space_travel_owner.get_snapshot(craft_id)
	if travel.get("revision") != expected_travel_revision: return {"ok":false, "reason":"stale_travel_revision"}
	var orbit_id := String(travel.get("orbit_id", ""))
	if real_travel_fixture:
		var operation := String(authority_context.get("operation", ""))
		if operation == "advance" and travel.get("phase") == "quantum":
			orbit_id = String(travel.get("target_orbit_id", ""))
		elif operation == "enter_orbit" and travel.get("phase") in ["surface", "approach"]:
			orbit_id = String(Dictionary(travel.get("location_orbits", {})).get(travel.get("location_id", ""), ""))
		else: return {"ok":false, "reason":"invalid_phase"}
	else:
		if travel.get("phase") != "orbit": return {"ok":false, "reason":"invalid_phase"}
	var orbit: Dictionary = Dictionary(travel.get("orbits", {})).get(orbit_id, {})
	var body_id: String = String(orbit.get("body_id", ""))
	var layout: Dictionary = ORBIT_LAYOUT.build(body_id)
	if not layout.get("ok", false) or layout.body_map_id != area_id: return {"ok":false, "reason":"wrong_orbit"}
	var metadata: Dictionary = _space_combat_state.get_metadata(craft_id)
	var footprint: Array = authority_context.fixture_footprint if needs_admission else metadata.get("footprint_hexes", [])
	var wing_revision: int = _space_wing_state.get_snapshot().revision
	var area_revision: int = _space_combat_state.get_area_revision(area_id)
	if surface_exit:
		var return_preview: Dictionary = preview_surface_reactivation(craft_id, String(travel.get("location_id", "")), target_pose, expected_flight_revision, expected_travel_revision, area_revision, wing_revision, authority_context)
		if not return_preview.get("ok", false): return return_preview
	else:
		var geometry: Dictionary = SPACE_AREA_TRANSITION.preview(flight, expected_flight_revision, body_id, target_pose, footprint, _space_combat_state, tick_counter)
		if not geometry.get("ok", false): return geometry
		var wings: Dictionary = _space_wing_state.preview_flying_wings(authority_context.actor_id, [craft_id], authority_context.owned_crafts, authority_context.craft_pilots)
		if not wings.get("ok", false): return wings
		wing_revision = wings.expected_revision
	_fixture_area_sequence += 1
	var token := "fixture-area:%d" % _fixture_area_sequence
	var travel_context: Dictionary = authority_context
	if real_travel_fixture:
		if typeof(authority_context.get("payload")) != TYPE_DICTIONARY: return {"ok":false, "reason":"invalid_context"}
		var payload: Dictionary = authority_context.payload.duplicate(true)
		var operation := String(authority_context.operation)
		travel_context = {"request_id":authority_context.request_id, "request_signature":JSON.stringify({"operation":operation, "payload":payload}, "", true), "operation":operation, "payload":payload, "source_area_id":flight.get_snapshot().space_area_id, "target_area_id":area_id, "expected_travel_revision":expected_travel_revision, "expected_phase":String(travel.phase), "context_id":token}
		var bound_owner: Dictionary = _singleplayer_space_travel_owner.configure_space_area_transition_authority(self)
		if not bound_owner.get("ok", false): return bound_owner
		var bound_context: Dictionary = _singleplayer_space_travel_owner.bind_space_area_transition_context(travel_context, self)
		if not bound_context.get("ok", false): return bound_context
	var travel_candidate: Dictionary = _singleplayer_space_travel_owner.prepare_space_area_transition(craft_id, expected_travel_revision, flight.get_snapshot().space_area_id, area_id, travel_context)
	if not travel_candidate.get("ok", false):
		if real_travel_fixture: _singleplayer_space_travel_owner.release_space_area_transition_context(token, self)
		return {"ok":false, "reason":"travel_prepare_failed"}
	_fixture_area_tokens[token] = {"craft_id":craft_id, "area_id":area_id, "body_id":body_id, "target":target_pose.duplicate(true), "footprint":footprint.duplicate(), "needs_admission":needs_admission, "surface_exit":surface_exit, "location_id":String(travel.get("location_id", "")), "area_revision":area_revision, "flight_revision":expected_flight_revision, "travel_revision":expected_travel_revision, "wing_revision":wing_revision, "context":authority_context.duplicate(true), "travel_context":travel_context.duplicate(true), "real_travel_fixture":real_travel_fixture, "travel_candidate":travel_candidate.duplicate(true), "owner":_singleplayer_space_travel_owner, "request_key":request_key, "expires_usec":Time.get_ticks_usec() + 30000000}
	_fixture_area_requests[request_key] = {"signature":signature, "token":token}
	return {"ok":true, "token":token}

func commit_space_area_transition(token: String, authority_context: Dictionary) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if authority_context.get("runtime_authorized") != true: return {"ok":false, "reason":"runtime_authority_required"}
	_purge_fixture_area_tokens()
	if _fixture_area_receipts.has(token):
		var receipt: Dictionary = _fixture_area_receipts[token]
		if receipt.context != authority_context or receipt.owner != _singleplayer_space_travel_owner: return {"ok":false, "reason":"context_changed"}
		if receipt.get("real_travel_fixture", false):
			var verified: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(receipt.travel_candidate, receipt.travel_context)
			if not verified.get("ok", false) or not verified.get("replayed", false): return {"ok":false, "reason":"owner_changed"}
		var replay: Dictionary = receipt.result.duplicate(true)
		replay["replayed"] = true
		return replay
	if not _fixture_area_tokens.has(token): return {"ok":false, "reason":"unknown_token"}
	var prepared: Dictionary = _fixture_area_tokens[token]
	if prepared.context != authority_context: return {"ok":false, "reason":"context_changed"}
	if prepared.owner != _singleplayer_space_travel_owner:
		_drop_fixture_area_token(token)
		return {"ok":false, "reason":"context_changed"}
	var existing_flight: RefCounted = _space_combat_state.get_actor(prepared.craft_id)
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(prepared.craft_id)
	if flight == null: return _reject_fixture_area_token(token, "actor_changed")
	if prepared.surface_exit:
		if existing_flight != null or _space_combat_state.get_inactive_actor(prepared.craft_id) != flight: return _reject_fixture_area_token(token, "actor_changed")
	elif (prepared.needs_admission and existing_flight != null) or (not prepared.needs_admission and existing_flight != flight):
		return _reject_fixture_area_token(token, "actor_changed")
	if _singleplayer_space_travel_owner.get_snapshot(prepared.craft_id).get("revision") != prepared.travel_revision: return _reject_fixture_area_token(token, "stale_travel_revision")
	if _space_wing_state.get_snapshot().revision != prepared.wing_revision: return _reject_fixture_area_token(token, "stale_wing_revision")
	var travel_validation: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(prepared.travel_candidate, prepared.travel_context)
	if not travel_validation.get("ok", false) or travel_validation.get("replayed", false): return _reject_fixture_area_token(token, "travel_validation_failed")
	var indexed := false
	if prepared.surface_exit:
		var return_preview: Dictionary = preview_surface_reactivation(prepared.craft_id, prepared.location_id, prepared.target, prepared.flight_revision, prepared.travel_revision, prepared.area_revision, prepared.wing_revision, authority_context)
		if not return_preview.get("ok", false): return _reject_fixture_area_token(token, String(return_preview.get("reason", "invalid_geometry")))
		var activity: Dictionary = flight.validate_space_activity_transition(return_preview.activity_proposal, return_preview.activity_tick)
		var reactivation: Dictionary = _space_combat_state.validate_reactivation(prepared.craft_id, return_preview.activity_proposal, return_preview.activity_tick)
		if not activity.get("ok", false) or not reactivation.get("ok", false): return _reject_fixture_area_token(token, "reactivation_invalid")
		flight._publish_space_activity_transition(activity)
		_space_combat_state._publish_reactivation(reactivation)
		indexed = true
	else:
		var geometry: Dictionary = SPACE_AREA_TRANSITION.preview(flight, prepared.flight_revision, prepared.body_id, prepared.target, prepared.footprint, _space_combat_state, tick_counter)
		if not geometry.get("ok", false): return _reject_fixture_area_token(token, String(geometry.get("reason", "invalid_geometry")))
		var movement_validation: Dictionary = flight.validate_area_transition(geometry.proposal, tick_counter)
		if not movement_validation.get("ok", false): return _reject_fixture_area_token(token, "flight_changed")
		var admission := {}
		if prepared.needs_admission:
			var definition := {"craft_id":prepared.craft_id, "faction_id":"player", "control_domain":"player", "footprint_hexes":prepared.footprint}
			admission = _space_combat_state.validate_new_local_admission(definition, flight, geometry.proposal, tick_counter)
			if not admission.get("ok", false): return _reject_fixture_area_token(token, "admission_invalid")
		var wings: Dictionary = _space_wing_state.ensure_flying_wings(authority_context.actor_id, [prepared.craft_id], authority_context.owned_crafts, authority_context.craft_pilots, prepared.wing_revision)
		assert(wings.get("ok", false))
		var movement: Dictionary = flight._publish_area_transition(movement_validation)
		assert(movement.get("ok", false))
		_space_combat_state.release_navigation_claim(prepared.craft_id)
		var cell: Vector2i = SPACE_GRID.HEX.round_axial(SPACE_GRID.HEX.plane_to_axial(geometry.proposal.position_plane))
		if prepared.needs_admission:
			_space_combat_state._publish_new_local_admission(admission)
			indexed = true
		else:
			indexed = _space_combat_state.update_actor_cell(prepared.craft_id, cell)
	assert(indexed)
	var travel_result: Dictionary = _singleplayer_space_travel_owner._publish_prepared_space_area_transition(prepared.travel_candidate, travel_validation) if prepared.real_travel_fixture else _singleplayer_space_travel_owner.commit_prepared_space_area_transition(prepared.travel_candidate, prepared.travel_context)
	assert(travel_result.get("ok", false))
	var result := {"ok":true, "replayed":false}
	_fixture_area_receipts[token] = {"context":prepared.context, "owner":prepared.owner, "result":result.duplicate(true), "real_travel_fixture":prepared.real_travel_fixture, "travel_candidate":prepared.travel_candidate.duplicate(true), "travel_context":prepared.travel_context.duplicate(true)}
	_fixture_area_tokens.erase(token)
	return result

func release_space_area_transition(token: String, authority_context: Dictionary) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if authority_context.get("runtime_authorized") != true: return {"ok":false, "reason":"runtime_authority_required"}
	_purge_fixture_area_tokens()
	if _fixture_area_receipts.has(token):
		var receipt: Dictionary = _fixture_area_receipts[token]
		if receipt.context != authority_context: return {"ok":false, "reason":"context_changed"}
		return {"ok":false, "reason":"already_committed"}
	if not _fixture_area_tokens.has(token): return {"ok":false, "reason":"unknown_token"}
	var prepared: Dictionary = _fixture_area_tokens[token]
	if prepared.context != authority_context: return {"ok":false, "reason":"context_changed"}
	_drop_fixture_area_token(token)
	return {"ok":true}

func _reject_fixture_area_token(token: String, reason: String) -> Dictionary:
	_drop_fixture_area_token(token)
	return {"ok":false, "reason":reason}

func _drop_fixture_area_token(token: String) -> void:
	if not _fixture_area_tokens.has(token): return
	var prepared: Dictionary = _fixture_area_tokens[token]
	if prepared.get("real_travel_fixture", false) and is_instance_valid(prepared.owner):
		prepared.owner.release_space_area_transition_context(String(prepared.travel_context.context_id), self)
	_fixture_area_requests.erase(_fixture_area_tokens[token].request_key)
	_fixture_area_tokens.erase(token)

func _purge_fixture_area_tokens() -> void:
	for token in _fixture_area_tokens.keys():
		var prepared: Dictionary = _fixture_area_tokens[token]
		if prepared.owner != _singleplayer_space_travel_owner or Time.get_ticks_usec() >= prepared.expires_usec:
			_drop_fixture_area_token(token)

func get_space_wing_snapshot() -> Dictionary:
	return _space_wing_state.get_snapshot()

func check_space_wing_replay(command: Dictionary, actor_id: String) -> Dictionary:
	return _space_wing_state.check_replay(command, actor_id)

func reconcile_space_wings(crafts: Array, pilots: Dictionary, authority_context: Dictionary) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if authority_context.get("runtime_authorized") != true:
		return {"ok": false, "reason": "runtime_authority_required"}
	if _singleplayer_space_travel_owner == null: return {"ok":false, "reason":"travel_unavailable"}
	var flying: Array = []
	var routes: Dictionary = _singleplayer_space_travel_owner.get_snapshot().get("routes", {})
	for craft_id in routes:
		if String(Dictionary(routes[craft_id]).get("phase", "")) in ["orbit", "quantum", "stopped", "approach"]: flying.append(craft_id)
	return _space_wing_state.reconcile_flying_wings("singleplayer", flying, crafts, pilots)

func admit_space_actor(definition: Dictionary, authority_context: Dictionary) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if authority_context.get("runtime_authorized") != true:
		return {"ok": false, "reason": "runtime_authority_required"}
	if typeof(definition.get("craft_id")) != TYPE_STRING or typeof(definition.get("faction_id")) != TYPE_STRING or typeof(definition.get("control_domain")) != TYPE_STRING or typeof(definition.get("start_hex")) != TYPE_VECTOR2I:
		return {"ok": false, "reason": "invalid_actor"}
	var cell: Vector2i = definition.start_hex
	if not SPACE_GRID.contains(cell):
		return {"ok": false, "reason": "invalid_actor_cell"}
	var craft_id: String = definition.craft_id
	var flight: RefCounted
	if definition.control_domain == "player":
		if _singleplayer_space_travel_owner == null or not _singleplayer_space_travel_owner.has_method("get_flight_state"):
			return {"ok": false, "reason": "flight_unavailable"}
		if String(_singleplayer_space_travel_owner.get_snapshot(craft_id).get("phase", "")) not in ["orbit", "stopped"]:
			return {"ok": false, "reason": "travel_active"}
		flight = _singleplayer_space_travel_owner.get_flight_state(craft_id)
		if flight == null or SPACE_GRID.cell_at(Vector2(flight.get_snapshot().position_plane) / SPACE_GRID.EXTENT) != cell:
			return {"ok": false, "reason": "flight_position_mismatch"}
	else:
		if _singleplayer_space_travel_owner != null and _singleplayer_space_travel_owner.has_method("get_flight_state") and _singleplayer_space_travel_owner.get_flight_state(craft_id) != null:
			return {"ok": false, "reason": "craft_identity_conflict"}
		flight = SPACE_FLIGHT_STATE.new()
		if not flight.configure(craft_id, {"position_plane": SPACE_GRID.HEX.axial_to_plane(Vector2(cell)), "motion_mode": "tactical"}).ok:
			return {"ok": false, "reason": "invalid_actor"}
	return _space_combat_state.admit_actor(definition, flight)

func get_space_actor(craft_id: String) -> RefCounted:
	return _space_combat_state.get_actor(craft_id)

func request_singleplayer_space_fire(command: Dictionary, authority_context: Dictionary) -> Dictionary:
	# Server-only command. Contacts, ownership, order and shot geometry are
	# rebuilt here from live owners; no client visibility or damage is trusted.
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if authority_context.get("runtime_authorized") != true or authority_context.get("actor_id") != "singleplayer": return {"ok":false, "reason":"runtime_authority_required"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	for field in ["request_id", "craft_id", "target_id", "weapon_slot"]:
		if typeof(command.get(field)) != TYPE_STRING or String(command[field]).strip_edges().is_empty(): return {"ok":false, "reason":"invalid_command"}
	if command.size() != 4: return {"ok":false, "reason":"invalid_command"}
	var id: String = command.request_id
	var signature := JSON.stringify(command, "", true)
	if _space_fire_receipts.has(id):
		var prior: Dictionary = _space_fire_receipts[id]
		if prior.signature != signature: return {"ok":false, "reason":"request_id_conflict"}
		var replay: Dictionary = prior.result.duplicate(true); replay["replayed"] = true; return replay
	if _space_fire_receipts.size() >= 4096: return {"ok":false, "reason":"receipt_capacity"}
	var shooter: RefCounted = _space_combat_state.get_actor(command.craft_id)
	var target: RefCounted = _space_combat_state.get_actor(command.target_id)
	if shooter == null or target == null or _singleplayer_space_travel_owner == null or _singleplayer_space_travel_owner.get_flight_state(command.craft_id) != shooter: return {"ok":false, "reason":"unknown_actor"}
	if _base_personnel_owner == null or not _base_personnel_owner.is_pilot_aboard(command.craft_id): return {"ok":false, "reason":"pilot_not_aboard"}
	var pose: Dictionary = shooter.get_snapshot()
	var target_pose: Dictionary = target.get_snapshot()
	if pose.get("motion_mode") != "tactical" or target_pose.get("motion_mode") != "tactical" or pose.get("space_area_id") != target_pose.get("space_area_id"): return {"ok":false, "reason":"different_area"}
	var wing_id: String = _space_wing_state.get_craft_wing(command.craft_id, "singleplayer")
	var wing: Dictionary = _space_wing_state.get_snapshot().wings.get(wing_id, {})
	var order: Dictionary = wing.get("order", {})
	if order.get("verb") != "attack_target" or order.get("target_id") != command.target_id: return {"ok":false, "reason":"attack_order_required"}
	var target_metadata: Dictionary = _space_combat_state.get_metadata(command.target_id)
	if target_metadata.get("control_domain") != "enemy": return {"ok":false, "reason":"not_hostile"}
	if target_metadata.get("faction_id") == _space_combat_state.get_metadata(command.craft_id).get("faction_id"): return {"ok":false, "reason":"not_hostile"}
	var source_systems: Dictionary = _space_combat_state.get_ship_systems(command.craft_id)
	var target_systems: Dictionary = _space_combat_state.get_ship_systems(command.target_id)
	if source_systems.is_empty() or target_systems.is_empty() or float(target_systems.state.hull) <= 0.0: return {"ok":false, "reason":"systems_unavailable"}
	var weapon := {}
	for candidate: Dictionary in source_systems.stats.weapons:
		if candidate.get("slot_id") == command.weapon_slot: weapon = candidate.duplicate(true); break
	if weapon.is_empty(): return {"ok":false, "reason":"unknown_weapon"}
	weapon["accuracy"] = 1.0 # Provisional deterministic start; no client accuracy.
	var area_id := String(pose.space_area_id)
	var ids: Array = _space_combat_state.get_area_actor_ids(area_id)
	if ids.size() > 256: return {"ok":false, "reason":"contact_capacity"}
	var actors := {}
	for actor_id: String in ids:
		var actor: RefCounted = _space_combat_state.get_actor(actor_id)
		if actor == null: continue
		var p: Dictionary = actor.get_snapshot()
		var metadata: Dictionary = _space_combat_state.get_metadata(actor_id)
		actors[actor_id] = {"id":actor_id, "position":p.position_plane, "heading_rad":p.heading_rad, "faction_id":metadata.faction_id, "area_id":area_id, "sensor_range":12.0}
	if not actors.has(command.craft_id) or not actors.has(command.target_id): return {"ok":false, "reason":"unknown_actor"}
	var opaque: Array = []
	if area_id.begins_with("orbit_approach:"):
		var layout: Dictionary = ORBIT_LAYOUT.build(area_id.trim_prefix("orbit_approach:").uri_decode())
		if not layout.get("ok", false) or layout.body_map_id != area_id: return {"ok":false, "reason":"invalid_area"}
		for cell in layout.body_cells: opaque.append(SPACE_GRID.from_offset(cell))
	var world := {"actors":actors, "opaque_cells":opaque}
	var contacts: Dictionary = SPACE_TARGETING.collect_contacts(world, String(actors[command.craft_id].faction_id))
	if not contacts.get("ok", false): return contacts
	world["known_targets"] = contacts.contacts
	world["hostile_factions"] = [target_metadata.faction_id]
	var start := SPACE_GRID.HEX.round_axial(SPACE_GRID.HEX.plane_to_axial(pose.position_plane))
	var end := SPACE_GRID.HEX.round_axial(SPACE_GRID.HEX.plane_to_axial(target_pose.position_plane))
	var occupied := {}
	for cell: Vector2i in SPACE_GRID.HEX.line(start, end):
		if not SPACE_AREA_GRID.contains(cell, pose): return {"ok":false, "reason":"line_blocked"}
		var query: Array[Vector2i] = [cell]
		occupied[cell] = _space_combat_state.query_cells(query, area_id)
	world["occupants_by_cell"] = occupied
	var proposal: Dictionary = SPACE_WEAPON.resolve_shot(actors[command.craft_id], actors[command.target_id], weapon, order, world, id, _space_fire_rng)
	if not proposal.get("ok", false): return proposal
	var hit: Dictionary = _space_combat_state._commit_ship_impact(proposal.event)
	if not hit.get("ok", false): return hit
	_space_fire_rng = int(proposal.rng_state)
	var result := {"ok":true, "replayed":false, "event":proposal.event.duplicate(true), "impact":hit.duplicate(true)}
	_space_fire_receipts[id] = {"signature":signature, "result":result.duplicate(true)}
	return result

func _bind_owned_space_systems(craft_id: String) -> Dictionary:
	# The actual equipment owner, not a command payload, supplies combat data.
	if _ship_equipment_owner == null or _singleplayer_space_travel_owner == null or _space_combat_state.get_actor(craft_id) == null or _space_combat_state.get_actor(craft_id) != _singleplayer_space_travel_owner.get_flight_state(craft_id):
		return {"ok":false, "reason":"equipment_owner_unavailable"}
	var stats: Dictionary = _ship_equipment_owner.get_space_combat_stats(craft_id)
	if not stats.get("ok", false): return stats
	return _space_combat_state.ensure_ship_systems(craft_id, stats)

func get_space_actors_at(cells: Array[Vector2i]) -> Array[String]:
	return _space_combat_state.query_cells(cells)

func get_space_area_revision(area_id: String) -> int:
	return _space_combat_state.get_area_revision(area_id)

func commit_singleplayer_space_launch(adapter: Node, craft_id: String, request_id: String) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter or not adapter.has_method("validate_space_launch") or not adapter.has_method("preview_space_warp_entry"): return {"ok":false, "reason":"adapter_required"}
	if craft_id.is_empty() or request_id.is_empty() or _singleplayer_space_travel_owner == null: return {"ok":false, "reason":"invalid_launch"}
	if _launch_receipts.has(request_id):
		var prior: Dictionary = _launch_receipts[request_id]
		if prior.context.operation != "launch_to_orbit": return {"ok":false, "reason":"request_id_conflict"}
		if prior.craft_id != craft_id or prior.fleet != _singleplayer_space_travel_owner or prior.flight != _singleplayer_space_travel_owner.get_flight_state(craft_id) or prior.get("equipment") != _ship_equipment_owner: return {"ok":false, "reason":"owner_changed"}
		var replay_check: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(prior.candidate, prior.context)
		if not replay_check.get("ok", false) or not replay_check.get("replayed", false): return {"ok":false, "reason":"owner_changed"}
		var replay: Dictionary = prior.result.duplicate(true); replay["replayed"] = true; return replay
	if _launch_receipts.size() >= 1024: return {"ok":false, "reason":"receipt_capacity"}
	var gate: Dictionary = adapter.validate_space_launch(craft_id, false)
	if not gate.get("ok", false): return gate
	var pilot: Dictionary = adapter.preview_space_warp_entry(craft_id)
	if not pilot.get("ok", false): return pilot
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if flight == null or _space_combat_state.get_actor(craft_id) != null or _space_combat_state.get_inactive_actor(craft_id) != null: return {"ok":false, "reason":"actor_unavailable"}
	var pose: Dictionary = flight.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
	var equipment_snapshot: Dictionary = _ship_equipment_owner.get_snapshot(craft_id) if _ship_equipment_owner != null else {}
	var launch_mass: Variant = null
	if equipment_snapshot.has("space_loadout"):
		var profile: Dictionary = _ship_equipment_owner.get_space_flight_profile(craft_id)
		if not profile.get("ok", false): return profile
		launch_mass = profile.mass
	var wing: Dictionary = _space_wing_state.preview_flying_wings("singleplayer", [craft_id], pilot.owned_crafts, pilot.craft_pilots)
	if not wing.get("ok", false): return wing
	var payload := {"craft_id":craft_id}
	var context := {"request_id":request_id, "request_signature":JSON.stringify({"operation":"launch_to_orbit", "payload":payload}, "", true), "operation":"launch_to_orbit", "payload":payload, "source_area_id":"", "target_area_id":"", "expected_travel_revision":travel.get("revision", -1), "expected_phase":"grounded", "context_id":"space-launch:" + request_id}
	var bound: Dictionary = _singleplayer_space_travel_owner.configure_space_area_transition_authority(self)
	if not bound.get("ok", false): return bound
	bound = _singleplayer_space_travel_owner.bind_space_area_transition_context(context, self)
	if not bound.get("ok", false): return bound
	var candidate: Dictionary = _singleplayer_space_travel_owner.prepare_space_area_transition(craft_id, context.expected_travel_revision, "", "", context)
	var tv: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(candidate, context) if candidate.get("ok", false) else candidate
	var fv: Dictionary = flight.validate_travel_pose(pose.revision, candidate.state.launch_pose.position, candidate.state.launch_pose.heading, launch_mass) if candidate.get("ok", false) else candidate
	if not tv.get("ok", false) or tv.get("replayed", false) or not fv.get("ok", false) or (_ship_equipment_owner != null and _ship_equipment_owner.get_snapshot(craft_id) != equipment_snapshot):
		_singleplayer_space_travel_owner.release_space_area_transition_context(context.context_id, self)
		return {"ok":false, "reason":"launch_validation_failed"}
	var committed_wing: Dictionary = _space_wing_state.ensure_flying_wings("singleplayer", [craft_id], pilot.owned_crafts, pilot.craft_pilots, wing.expected_revision)
	if not committed_wing.get("ok", false):
		_singleplayer_space_travel_owner.release_space_area_transition_context(context.context_id, self)
		return committed_wing
	flight._publish_travel_pose(fv)
	var travel_result: Dictionary = _singleplayer_space_travel_owner._publish_prepared_space_area_transition(candidate, tv)
	var result := {"ok":true, "replayed":false, "receipt_id":request_id, "travel_result":travel_result}
	var command := {"contract_category":"singleplayer_space_travel", "operation":"launch_to_orbit", "payload":payload, "request_id":request_id}
	_launch_receipts[request_id] = {"craft_id":craft_id, "fleet":_singleplayer_space_travel_owner, "flight":flight, "equipment":_ship_equipment_owner, "candidate":candidate.duplicate(true), "context":context.duplicate(true), "result":result.duplicate(true), "command":command, "event_published":false}
	return result

func publish_singleplayer_space_launch_event(adapter: Node, request_id: String) -> void:
	if _should_skip_local_tick_processing() or _departure_adapter == null or _departure_adapter.get_ref() != adapter or not _launch_receipts.has(request_id): return
	var receipt: Dictionary = _launch_receipts[request_id]
	if receipt.event_published or receipt.fleet != _singleplayer_space_travel_owner: return
	var valid: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(receipt.candidate, receipt.context)
	if not valid.get("ok", false) or not valid.get("replayed", false): return
	if receipt.has("supply") and (receipt.supply != _singleplayer_supply_owner or receipt.supply_epoch != _singleplayer_supply_owner.get("_route_prepare_epoch")): return
	if receipt.has("equipment") and receipt.equipment != _ship_equipment_owner: return
	receipt.event_published = true
	if receipt.has("fuel_event"): singleplayer_command_committed.emit(receipt.fuel_event.command.duplicate(true), receipt.fuel_event.result.duplicate(true))
	if receipt.fleet != _singleplayer_space_travel_owner or (receipt.has("supply") and (receipt.supply != _singleplayer_supply_owner or receipt.supply_epoch != _singleplayer_supply_owner.get("_route_prepare_epoch"))) or (receipt.has("equipment") and receipt.equipment != _ship_equipment_owner): return
	if receipt.flight != _singleplayer_space_travel_owner.get_flight_state(receipt.craft_id): return
	valid = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(receipt.candidate, receipt.context)
	if not valid.get("ok", false) or not valid.get("replayed", false): return
	singleplayer_command_committed.emit(receipt.command.duplicate(true), receipt.result.travel_result.duplicate(true))

func preview_station_purchase_local_admission(adapter: Node, craft_id: String) -> Dictionary:
	# Read-only first admission. No fabricated prior local actor or departure.
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter or not adapter.has_method("preview_station_orbit_departure"): return {"ok":false, "reason":"adapter_required"}
	if _singleplayer_space_travel_owner == null or _singleplayer_supply_owner == null or _ship_equipment_owner == null: return {"ok":false, "reason":"owner_unavailable"}
	var purchase: Dictionary = _singleplayer_supply_owner.get_station_ship_purchase(craft_id)
	if purchase.get("craft_id") != craft_id or purchase.get("origin_kind") != "local_station_purchase" or purchase.get("origin_location_id") != "polisa" or String(purchase.get("origin_receipt_id", "")).is_empty(): return {"ok":false, "reason":"station_purchase_required"}
	var visit: Dictionary = adapter.preview_station_orbit_departure(craft_id)
	if not visit.get("ok", false): return visit
	if visit.get("outward_token") != "local-purchase:" + String(purchase.origin_receipt_id) or typeof(visit.get("route")) != TYPE_DICTIONARY or visit.route.get("craft_id") != craft_id or visit.route.get("origin_location_id") != "polisa" or visit.route.get("destination_location_id") != "homebase": return {"ok":false, "reason":"purchase_visit_mismatch"}
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if flight == null or _space_combat_state.get_actor(craft_id) != null or _space_combat_state.get_inactive_actor(craft_id) != null: return {"ok":false, "reason":"actor_unavailable"}
	var pose: Dictionary = flight.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
	if pose.get("craft_id") != craft_id or pose.get("coordinate_frame") != "strategic" or pose.get("motion_mode") == "tactical" or not String(pose.get("space_area_id", "")).is_empty() or travel.get("phase") != "surface" or travel.get("location_id") != "polisa": return {"ok":false, "reason":"station_birth_changed"}
	var profile: Dictionary = _ship_equipment_owner.get_space_flight_profile(craft_id)
	if not profile.get("ok", false): return profile
	if profile.get("model_id") != purchase.get("model_id"): return {"ok":false, "reason":"equipment_purchase_mismatch"}
	var layout: Dictionary = SPACE_AREA_GRID.station_dock_layout()
	if not layout.get("ok", false): return {"ok":false, "reason":"station_layout_changed"}
	var target: Vector2 = SPACE_GRID.HEX.axial_to_plane(Vector2(SPACE_GRID.from_offset(layout.dock_gate)))
	var proposal := {"expected_revision":pose.revision, "coordinate_frame":"local", "space_area_id":layout.area_id, "position_plane":target, "velocity_plane":Vector2.ZERO, "angular_velocity":0.0, "heading_rad":0.0, "mass":profile.mass, "motion_mode":"tactical"}
	var tick := tick_counter + 1
	var definition := {"craft_id":craft_id, "faction_id":"player", "control_domain":"player", "footprint_hexes":profile.footprint_hexes}
	var admission: Dictionary = _space_combat_state.validate_new_local_admission(definition, flight, proposal, tick)
	if not admission.get("ok", false): return admission
	var wing: Dictionary = _space_wing_state.preview_flying_wings("singleplayer", [craft_id], visit.owned_crafts, visit.craft_pilots)
	if not wing.get("ok", false): return wing
	return {"ok":true, "craft_id":craft_id, "purchase_receipt_id":purchase.origin_receipt_id, "target_id":layout.target_id, "layout_revision":layout.revision, "space_area_id":layout.area_id, "flight_revision":pose.revision, "travel_revision":travel.revision, "area_revision":_space_combat_state.get_area_revision(layout.area_id), "wing_revision":wing.expected_revision, "equipment_revision":profile.equipment_revision, "footprint_cells":admission.cells.duplicate()}

func is_station_purchase_local_admission_current(craft_id: String) -> bool:
	if _singleplayer_supply_owner == null or _singleplayer_space_travel_owner == null: return false
	var purchase: Dictionary = _singleplayer_supply_owner.get_station_ship_purchase(craft_id)
	if purchase.get("craft_id") != craft_id or purchase.get("origin_kind") != "local_station_purchase" or String(purchase.get("origin_receipt_id", "")).is_empty(): return false
	var id := "station-birth:" + String(purchase.origin_receipt_id) + ":" + craft_id
	var receipt: Dictionary = _launch_receipts.get(id, {})
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if receipt.is_empty() or flight == null or receipt.get("flight") != flight or receipt.get("fleet") != _singleplayer_space_travel_owner or _space_combat_state.get_actor(craft_id) != flight: return false
	var pose: Dictionary = flight.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
	return pose.get("coordinate_frame") == "local" and pose.get("motion_mode") == "tactical" and pose.get("space_area_id") == "orbit_approach:glut_2" and travel.get("phase") == "orbit" and travel.get("orbit_id") == "polisa_orbit" and travel.get("revision") == Dictionary(receipt.get("result", {}).get("travel_result", {})).get("revision")

func commit_station_purchase_local_admission(adapter: Node, craft_id: String) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter: return {"ok":false, "reason":"adapter_required"}
	if _singleplayer_supply_owner == null or _singleplayer_space_travel_owner == null or _ship_equipment_owner == null: return {"ok":false, "reason":"owner_unavailable"}
	var purchase: Dictionary = _singleplayer_supply_owner.get_station_ship_purchase(craft_id)
	if purchase.get("craft_id") != craft_id or purchase.get("origin_kind") != "local_station_purchase" or String(purchase.get("origin_receipt_id", "")).is_empty(): return {"ok":false, "reason":"station_purchase_required"}
	var id := "station-birth:" + String(purchase.origin_receipt_id) + ":" + craft_id
	if _launch_receipts.has(id):
		var previous: Dictionary = _launch_receipts[id]
		if previous.get("craft_id") != craft_id or previous.get("fleet") != _singleplayer_space_travel_owner or previous.get("flight") != _singleplayer_space_travel_owner.get_flight_state(craft_id) or previous.get("supply") != _singleplayer_supply_owner or previous.get("supply_epoch") != _singleplayer_supply_owner.get("_route_prepare_epoch") or previous.get("equipment") != _ship_equipment_owner: return {"ok":false, "reason":"owner_changed"}
		var replay: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(previous.candidate, previous.context)
		if not replay.get("ok", false) or not replay.get("replayed", false): return {"ok":false, "reason":"owner_changed"}
		var result: Dictionary = previous.result.duplicate(true); result["replayed"] = true; return result
	if _launch_receipts.size() >= 1024: return {"ok":false, "reason":"receipt_capacity"}
	var preview: Dictionary = preview_station_purchase_local_admission(adapter, craft_id)
	if not preview.get("ok", false): return preview
	var visit: Dictionary = adapter.preview_station_orbit_departure(craft_id)
	if not visit.get("ok", false) or visit.get("outward_token") != "local-purchase:" + String(purchase.origin_receipt_id): return {"ok":false, "reason":"purchase_visit_mismatch"}
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	var pose: Dictionary = flight.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
	var profile: Dictionary = _ship_equipment_owner.get_space_flight_profile(craft_id)
	var layout: Dictionary = SPACE_AREA_GRID.station_dock_layout()
	if pose.revision != preview.flight_revision or travel.revision != preview.travel_revision or profile.get("equipment_revision") != preview.equipment_revision or layout.get("revision") != preview.layout_revision or _space_combat_state.get_area_revision(layout.area_id) != preview.area_revision: return {"ok":false, "reason":"birth_context_changed"}
	var proposal := {"expected_revision":pose.revision, "coordinate_frame":"local", "space_area_id":layout.area_id, "position_plane":SPACE_GRID.HEX.axial_to_plane(Vector2(SPACE_GRID.from_offset(layout.dock_gate))), "velocity_plane":Vector2.ZERO, "angular_velocity":0.0, "heading_rad":0.0, "mass":profile.mass, "motion_mode":"tactical"}
	var tick := tick_counter + 1
	var definition := {"craft_id":craft_id, "faction_id":"player", "control_domain":"player", "footprint_hexes":profile.footprint_hexes}
	var movement: Dictionary = flight.validate_area_transition(proposal, tick)
	var admission: Dictionary = _space_combat_state.validate_new_local_admission(definition, flight, proposal, tick)
	var wing: Dictionary = _space_wing_state.preview_flying_wings("singleplayer", [craft_id], visit.owned_crafts, visit.craft_pilots)
	if not movement.get("ok", false) or not admission.get("ok", false) or not wing.get("ok", false) or wing.expected_revision != preview.wing_revision: return {"ok":false, "reason":"birth_admission_changed"}
	if not _singleplayer_supply_owner.bind_route_fuel_preparation_authority(self): return {"ok":false, "reason":"supply_authority_unavailable"}
	var fuel := {"contract_category":"singleplayer_supply", "operation":"consume_route_fuel", "payload":visit.route.duplicate(true), "request_id":"return:" + String(visit.outward_token) + ":fuel"}
	var fuel_candidate: Dictionary = _singleplayer_supply_owner.prepare_route_fuel(fuel, {"route_fuel_authority":self,"departure_authorized":true,"require_return_reserve":false})
	if not fuel_candidate.get("ok", false): return fuel_candidate
	var payload := {"craft_id":craft_id, "location_id":"polisa", "target_id":layout.target_id, "layout_revision":layout.revision}
	var context := {"request_id":id,"request_signature":JSON.stringify({"operation":"depart_station_purchase","payload":payload}, "", true),"operation":"depart_station_purchase","payload":payload,"source_area_id":"","target_area_id":layout.area_id,"expected_travel_revision":travel.revision,"expected_phase":"surface","context_id":id}
	var bound: Dictionary = _singleplayer_space_travel_owner.configure_space_area_transition_authority(self)
	if not bound.get("ok", false): return bound
	bound = _singleplayer_space_travel_owner.bind_space_area_transition_context(context, self)
	if not bound.get("ok", false): return bound
	var candidate: Dictionary = _singleplayer_space_travel_owner.prepare_space_area_transition(craft_id, travel.revision, "", layout.area_id, context)
	var tv: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(candidate, context) if candidate.get("ok", false) else candidate
	var sv: Dictionary = _singleplayer_supply_owner.validate_prepared_route_fuel(fuel_candidate, self)
	if not tv.get("ok", false) or tv.get("replayed", false) or not sv.get("ok", false):
		_singleplayer_space_travel_owner.release_space_area_transition_context(id, self)
		return {"ok":false, "reason":"birth_validation_failed"}
	var committed_wing: Dictionary = _space_wing_state.ensure_flying_wings("singleplayer", [craft_id], visit.owned_crafts, visit.craft_pilots, wing.expected_revision)
	if not committed_wing.get("ok", false):
		_singleplayer_space_travel_owner.release_space_area_transition_context(id, self)
		return committed_wing
	var fuel_result: Dictionary = _singleplayer_supply_owner._publish_prepared_route_fuel(fuel_candidate, sv)
	flight._publish_area_transition(movement)
	_space_combat_state._publish_new_local_admission(admission)
	_bind_owned_space_systems(craft_id)
	var travel_result: Dictionary = _singleplayer_space_travel_owner._publish_prepared_space_area_transition(candidate, tv)
	var result := {"ok":true,"replayed":false,"receipt_id":id,"travel_result":travel_result}
	var command := {"contract_category":"singleplayer_space_travel","operation":"depart_station_purchase","payload":payload,"request_id":id}
	var receipt := {"craft_id":craft_id,"fleet":_singleplayer_space_travel_owner,"flight":flight,"supply":_singleplayer_supply_owner,"supply_epoch":_singleplayer_supply_owner.get("_route_prepare_epoch"),"equipment":_ship_equipment_owner,"candidate":candidate.duplicate(true),"context":context.duplicate(true),"result":result.duplicate(true),"command":command,"event_published":false}
	if sv.patch.mode == "apply": receipt["fuel_event"] = {"command":fuel,"result":fuel_result}
	_launch_receipts[id] = receipt
	return result

func commit_singleplayer_station_orbit(adapter: Node, craft_id: String, request_id: String) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter or not adapter.has_method("preview_station_orbit_departure"): return {"ok":false, "reason":"adapter_required"}
	if craft_id.is_empty() or request_id.is_empty() or _singleplayer_space_travel_owner == null or _singleplayer_supply_owner == null: return {"ok":false, "reason":"invalid_launch"}
	if _launch_receipts.has(request_id):
		var prior: Dictionary = _launch_receipts[request_id]
		if prior.craft_id != craft_id or prior.fleet != _singleplayer_space_travel_owner or prior.flight != _singleplayer_space_travel_owner.get_flight_state(craft_id) or prior.context.operation != "enter_orbit" or prior.get("equipment") != _ship_equipment_owner or prior.get("supply") != _singleplayer_supply_owner or prior.get("supply_epoch") != _singleplayer_supply_owner.get("_route_prepare_epoch"): return {"ok":false, "reason":"owner_changed"}
		var replay_check: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(prior.candidate, prior.context)
		if not replay_check.get("ok", false) or not replay_check.get("replayed", false): return {"ok":false, "reason":"owner_changed"}
		var replay: Dictionary = prior.result.duplicate(true); replay["replayed"] = true; return replay
	if _launch_receipts.size() >= 1024: return {"ok":false, "reason":"receipt_capacity"}
	var pilot: Dictionary = adapter.preview_station_orbit_departure(craft_id)
	if not pilot.get("ok", false): return pilot
	if typeof(pilot.get("route")) != TYPE_DICTIONARY or pilot.route.get("craft_id") != craft_id or pilot.route.get("origin_location_id") != "polisa" or pilot.route.get("destination_location_id") != "homebase" or typeof(pilot.get("outward_token")) != TYPE_STRING or String(pilot.outward_token).is_empty(): return {"ok":false, "reason":"invalid_return_context"}
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if flight == null or _space_combat_state.get_actor(craft_id) != null or _space_combat_state.get_inactive_actor(craft_id) != null: return {"ok":false, "reason":"actor_unavailable"}
	var pose: Dictionary = flight.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
	if travel.get("phase") != "surface" or travel.get("location_id") != "polisa": return {"ok":false, "reason":"station_visit_required"}
	var equipment_snapshot: Dictionary = _ship_equipment_owner.get_snapshot(craft_id) if _ship_equipment_owner != null else {}
	var launch_mass: Variant = null
	if equipment_snapshot.has("space_loadout"):
		var profile: Dictionary = _ship_equipment_owner.get_space_flight_profile(craft_id)
		if not profile.get("ok", false): return profile
		launch_mass = profile.mass
	var wing: Dictionary = _space_wing_state.preview_flying_wings("singleplayer", [craft_id], pilot.owned_crafts, pilot.craft_pilots)
	if not wing.get("ok", false): return wing
	if not _singleplayer_supply_owner.bind_route_fuel_preparation_authority(self): return {"ok":false, "reason":"supply_authority_unavailable"}
	var fuel := {"contract_category":"singleplayer_supply", "operation":"consume_route_fuel", "payload":pilot.route.duplicate(true), "request_id":"return:" + String(pilot.outward_token) + ":fuel"}
	var fuel_candidate: Dictionary = _singleplayer_supply_owner.prepare_route_fuel(fuel, {"route_fuel_authority":self,"departure_authorized":true,"require_return_reserve":false})
	if not fuel_candidate.get("ok", false): return fuel_candidate
	var payload := {"craft_id":craft_id}
	var context := {"request_id":request_id, "request_signature":JSON.stringify({"operation":"enter_orbit", "payload":payload}, "", true), "operation":"enter_orbit", "payload":payload, "source_area_id":"", "target_area_id":"", "expected_travel_revision":travel.revision, "expected_phase":"surface", "context_id":"station-orbit:" + request_id}
	var bound: Dictionary = _singleplayer_space_travel_owner.configure_space_area_transition_authority(self)
	if not bound.get("ok", false): return bound
	bound = _singleplayer_space_travel_owner.bind_space_area_transition_context(context, self)
	if not bound.get("ok", false): return bound
	var candidate: Dictionary = _singleplayer_space_travel_owner.prepare_space_area_transition(craft_id, travel.revision, "", "", context)
	var tv: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(candidate, context) if candidate.get("ok", false) else candidate
	var fv: Dictionary = flight.validate_travel_pose(pose.revision, candidate.state.launch_pose.position, candidate.state.launch_pose.heading, launch_mass) if candidate.get("ok", false) else candidate
	var sv: Dictionary = _singleplayer_supply_owner.validate_prepared_route_fuel(fuel_candidate, self)
	if not tv.get("ok", false) or tv.get("replayed", false) or not fv.get("ok", false) or not sv.get("ok", false) or (_ship_equipment_owner != null and _ship_equipment_owner.get_snapshot(craft_id) != equipment_snapshot):
		_singleplayer_space_travel_owner.release_space_area_transition_context(context.context_id, self)
		return {"ok":false, "reason":"launch_validation_failed"}
	var committed_wing: Dictionary = _space_wing_state.ensure_flying_wings("singleplayer", [craft_id], pilot.owned_crafts, pilot.craft_pilots, wing.expected_revision)
	if not committed_wing.get("ok", false):
		_singleplayer_space_travel_owner.release_space_area_transition_context(context.context_id, self)
		return committed_wing
	var fuel_result: Dictionary = _singleplayer_supply_owner._publish_prepared_route_fuel(fuel_candidate, sv)
	flight._publish_travel_pose(fv)
	var travel_result: Dictionary = _singleplayer_space_travel_owner._publish_prepared_space_area_transition(candidate, tv)
	var result := {"ok":true, "replayed":false, "receipt_id":request_id, "travel_result":travel_result}
	var command := {"contract_category":"singleplayer_space_travel", "operation":"enter_orbit", "payload":payload, "request_id":request_id}
	var receipt := {"craft_id":craft_id, "fleet":_singleplayer_space_travel_owner, "flight":flight, "equipment":_ship_equipment_owner, "supply":_singleplayer_supply_owner, "supply_epoch":_singleplayer_supply_owner.get("_route_prepare_epoch"), "candidate":candidate.duplicate(true), "context":context.duplicate(true), "result":result.duplicate(true), "command":command, "event_published":false}
	if sv.patch.mode == "apply": receipt["fuel_event"] = {"command":fuel, "result":fuel_result}
	_launch_receipts[request_id] = receipt
	return result

func commit_singleplayer_home_landing(adapter: Node, craft_id: String, request_id: String) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter or not adapter.has_method("preview_space_home_landing"): return {"ok":false, "reason":"adapter_required"}
	if craft_id.is_empty() or request_id.is_empty() or _singleplayer_space_travel_owner == null: return {"ok":false, "reason":"invalid_landing"}
	if _launch_receipts.has(request_id):
		var prior: Dictionary = _launch_receipts[request_id]
		if prior.craft_id != craft_id or prior.fleet != _singleplayer_space_travel_owner or prior.flight != _singleplayer_space_travel_owner.get_flight_state(craft_id) or prior.context.operation != "land_homebase": return {"ok":false, "reason":"owner_changed"}
		var replay_check: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(prior.candidate, prior.context)
		if not replay_check.get("ok", false) or not replay_check.get("replayed", false): return {"ok":false, "reason":"owner_changed"}
		var replay: Dictionary = prior.result.duplicate(true); replay["replayed"] = true; return replay
	if _launch_receipts.size() >= 1024: return {"ok":false, "reason":"receipt_capacity"}
	var pilot: Dictionary = adapter.preview_space_home_landing(craft_id)
	if not pilot.get("ok", false): return pilot
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if flight == null or _space_combat_state.get_actor(craft_id) != flight or _space_wing_state.get_craft_wing(craft_id, "singleplayer").is_empty(): return {"ok":false, "reason":"unknown_actor"}
	var pose: Dictionary = flight.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
	if pose.get("coordinate_frame") != "local" or pose.get("motion_mode") != "tactical" or pose.get("space_area_id") != "orbit_approach:moon" or travel.get("phase") != "orbit" or travel.get("orbit_id") != "moon_orbit": return {"ok":false, "reason":"moon_orbit_required"}
	var metadata: Dictionary = _space_combat_state.get_metadata(craft_id)
	if metadata.get("control_domain") != "player": return {"ok":false, "reason":"not_owned"}
	var cells: Array[Vector2i] = _space_combat_state.preview_footprint(pose, metadata.get("footprint_hexes", []))
	if cells.is_empty() or not _space_combat_state.actor_cells_match(craft_id, pose.space_area_id, cells): return {"ok":false, "reason":"stale_spatial_index"}
	var layout: Dictionary = ORBIT_LAYOUT.build("moon")
	var body := {}; var gates := {}
	for cell in layout.body_cells: body[cell] = true
	for cell in layout.gate_cells: gates[cell] = true
	var at_gate := false
	for cell in cells:
		var offset: Vector2i = SPACE_GRID.to_offset(cell)
		if body.has(offset): return {"ok":false, "reason":"body_blocked"}
		if gates.has(offset): at_gate = true
	if not at_gate: return {"ok":false, "reason":"not_at_home_gate"}
	var area_revision: int = _space_combat_state.get_area_revision(pose.space_area_id)
	var payload := {"craft_id":craft_id}
	var context := {"request_id":request_id, "request_signature":JSON.stringify({"operation":"land_homebase", "payload":payload}, "", true), "operation":"land_homebase", "payload":payload, "source_area_id":pose.space_area_id, "target_area_id":"", "expected_travel_revision":travel.revision, "expected_phase":"orbit", "context_id":"home-land:" + request_id}
	var bound: Dictionary = _singleplayer_space_travel_owner.configure_space_area_transition_authority(self)
	if not bound.get("ok", false): return bound
	bound = _singleplayer_space_travel_owner.bind_space_area_transition_context(context, self)
	if not bound.get("ok", false): return bound
	var candidate: Dictionary = _singleplayer_space_travel_owner.prepare_space_area_transition(craft_id, travel.revision, pose.space_area_id, "", context)
	var tv: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(candidate, context) if candidate.get("ok", false) else candidate
	var proposal := {"expected_revision":pose.revision, "coordinate_frame":"strategic", "space_area_id":"", "position_plane":candidate.get("state", {}).get("home_pose", {}).get("position", Vector2.ZERO), "motion_mode":"grounded", "velocity_plane":Vector2.ZERO, "angular_velocity":0.0}
	var fv: Dictionary = flight.validate_area_transition(proposal, tick_counter + 1)
	var av: Dictionary = _space_combat_state.validate_local_departure(craft_id, proposal, tick_counter + 1, area_revision, "grounded")
	if not tv.get("ok", false) or tv.get("replayed", false) or not fv.get("ok", false) or not av.get("ok", false):
		_singleplayer_space_travel_owner.release_space_area_transition_context(context.context_id, self)
		return {"ok":false, "reason":"landing_validation_failed"}
	flight._publish_area_transition(fv)
	_space_combat_state._publish_local_departure(av)
	var travel_result: Dictionary = _singleplayer_space_travel_owner._publish_prepared_space_area_transition(candidate, tv)
	var result := {"ok":true, "replayed":false, "receipt_id":request_id, "travel_result":travel_result}
	var command := {"contract_category":"singleplayer_space_travel", "operation":"land_homebase", "payload":payload, "request_id":request_id}
	_launch_receipts[request_id] = {"craft_id":craft_id, "fleet":_singleplayer_space_travel_owner, "flight":flight, "candidate":candidate.duplicate(true), "context":context.duplicate(true), "result":result.duplicate(true), "command":command, "event_published":false}
	return result

func commit_singleplayer_warp_departure(adapter: Node, command: Dictionary) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter or not adapter.has_method("preview_space_warp_entry"): return {"ok":false, "reason":"adapter_required"}
	if _singleplayer_space_travel_owner == null or _ship_equipment_owner == null: return {"ok":false, "reason":"owner_unavailable"}
	if command.size() not in [3, 4] or typeof(command.get("craft_id")) != TYPE_STRING or String(command.craft_id).is_empty() or typeof(command.get("request_id")) != TYPE_STRING or String(command.request_id).is_empty() or typeof(command.get("target_orbit_id")) != TYPE_STRING or String(command.target_orbit_id).is_empty(): return {"ok":false, "reason":"invalid_command"}
	for key in command:
		if key not in ["craft_id", "target_orbit_id", "target_orbit_marker_id", "request_id"]: return {"ok":false, "reason":"invalid_command"}
	if command.has("target_orbit_marker_id") and typeof(command.target_orbit_marker_id) != TYPE_STRING: return {"ok":false, "reason":"invalid_command"}
	var signature := SPACE_COMMAND_CONTRACT.request_signature(command)
	if _warp_departure_receipts.has(command.request_id):
		var receipt: Dictionary = _warp_departure_receipts[command.request_id]
		if receipt.signature != signature: return {"ok":false, "reason":"request_id_conflict"}
		if receipt.fleet != _singleplayer_space_travel_owner or receipt.equipment != _ship_equipment_owner or receipt.flight != _singleplayer_space_travel_owner.get_flight_state(command.craft_id): return {"ok":false, "reason":"owner_changed"}
		var replay_check: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(receipt.candidate, receipt.context)
		if not replay_check.get("ok", false) or not replay_check.get("replayed", false): return {"ok":false, "reason":"owner_changed"}
		var replay: Dictionary = receipt.result.duplicate(true); replay["replayed"] = true; return replay
	if _warp_departure_receipts.size() >= 1024: return {"ok":false, "reason":"receipt_capacity"}
	var pilot: Dictionary = adapter.preview_space_warp_entry(command.craft_id)
	if not pilot.get("ok", false): return pilot
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(command.craft_id)
	if flight == null or _space_combat_state.get_actor(command.craft_id) != flight: return {"ok":false, "reason":"unknown_actor"}
	var pose: Dictionary = flight.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(command.craft_id)
	var profile: Dictionary = _ship_equipment_owner.get_space_flight_profile(command.craft_id)
	if not profile.get("ok", false): return profile
	var equipment: Dictionary = _ship_equipment_owner.get_quantum_effect(command.craft_id)
	var area_revision: int = _space_combat_state.get_area_revision(String(pose.get("space_area_id", "")))
	var wing_revision: int = _space_wing_state.get_snapshot().revision
	var preview: Dictionary = preview_warp_departure(command.craft_id, command.target_orbit_id, pose.revision, travel.get("revision", -1), area_revision, wing_revision, {"runtime_authorized":true, "actor_id":"singleplayer"})
	if not preview.get("ok", false): return preview
	if adapter.has_method("requires_surface_orbit_exit_band") and adapter.requires_surface_orbit_exit_band(command.craft_id):
		var area_layout: Dictionary = ORBIT_LAYOUT.build(String(pose.space_area_id).trim_prefix("orbit_approach:").uri_decode())
		if not area_layout.get("ok", false) or area_layout.body_map_id != pose.space_area_id: return {"ok":false, "reason":"invalid_area"}
		var cells: Array[Vector2i] = _space_combat_state.preview_actor_cells(command.craft_id, {})
		if cells.is_empty(): return {"ok":false, "reason":"invalid_footprint"}
		for cell in cells:
			if not area_layout.entry_band.has_point(SPACE_GRID.to_offset(cell)): return {"ok":false, "reason":"space_exit_band_required", "message":"Zum Sprung zuerst den unteren Weltraumrand erreichen"}
	var orbit: Dictionary = Dictionary(travel.orbits).get(String(travel.orbit_id), {})
	var body: Dictionary = Dictionary(travel.bodies).get(String(orbit.get("body_id", "")), {})
	var payload := {"craft_id":command.craft_id, "target_orbit_id":command.target_orbit_id}
	if command.has("target_orbit_marker_id"): payload["target_orbit_marker_id"] = command.target_orbit_marker_id
	var context := {"request_id":command.request_id, "request_signature":JSON.stringify({"operation":"start_quantum", "payload":payload}, "", true), "operation":"start_quantum", "payload":payload, "source_area_id":pose.space_area_id, "target_area_id":"", "expected_travel_revision":travel.revision, "expected_phase":"orbit", "context_id":"warp-departure:" + String(command.request_id), "origin_position":body.get("position", []), "warp_multiplier":equipment.get("quantum_duration_multiplier", 0.0)}
	var bound: Dictionary = _singleplayer_space_travel_owner.configure_space_area_transition_authority(self)
	if not bound.get("ok", false): return bound
	bound = _singleplayer_space_travel_owner.bind_space_area_transition_context(context, self)
	if not bound.get("ok", false): return bound
	var candidate: Dictionary = _singleplayer_space_travel_owner.prepare_space_area_transition(command.craft_id, travel.revision, pose.space_area_id, "", context)
	var tv: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(candidate, context) if candidate.get("ok", false) else candidate
	if not tv.get("ok", false) or tv.get("replayed", false):
		_singleplayer_space_travel_owner.release_space_area_transition_context(context.context_id, self)
		return {"ok":false, "reason":"travel_validation_failed"}
	var proposal: Dictionary = preview.area_proposal.duplicate(true)
	proposal["heading_rad"] = candidate.state.warp.heading
	proposal["velocity_plane"] = Vector2.ZERO; proposal["angular_velocity"] = 0.0
	var fv: Dictionary = flight.validate_area_transition(proposal, preview.transition_tick)
	var av: Dictionary = _space_combat_state.validate_local_departure(command.craft_id, proposal, preview.transition_tick, area_revision)
	if not fv.get("ok", false) or not av.get("ok", false):
		_singleplayer_space_travel_owner.release_space_area_transition_context(context.context_id, self)
		return {"ok":false, "reason":"departure_validation_failed"}
	flight._publish_area_transition(fv)
	_space_combat_state._publish_local_departure(av)
	var travel_result: Dictionary = _singleplayer_space_travel_owner._publish_prepared_space_area_transition(candidate, tv)
	var result := {"ok":true, "replayed":false, "receipt_id":String(command.request_id), "travel_result":travel_result}
	var event_command := {"contract_category":"singleplayer_space_travel", "operation":"start_quantum", "payload":payload, "request_id":command.request_id}
	_warp_departure_receipts[command.request_id] = {"signature":signature, "fleet":_singleplayer_space_travel_owner, "flight":flight, "equipment":_ship_equipment_owner, "candidate":candidate.duplicate(true), "context":context.duplicate(true), "result":result.duplicate(true), "command":event_command, "event_published":false}
	return result

func publish_singleplayer_warp_departure_event(adapter: Node, receipt_id: String) -> void:
	if _should_skip_local_tick_processing() or _departure_adapter == null or _departure_adapter.get_ref() != adapter or not _warp_departure_receipts.has(receipt_id): return
	var receipt: Dictionary = _warp_departure_receipts[receipt_id]
	if receipt.event_published or receipt.fleet != _singleplayer_space_travel_owner or receipt.equipment != _ship_equipment_owner: return
	var valid: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(receipt.candidate, receipt.context)
	if not valid.get("ok", false) or not valid.get("replayed", false): return
	receipt.event_published = true
	singleplayer_command_committed.emit(receipt.command.duplicate(true), receipt.result.travel_result.duplicate(true))

func is_singleplayer_warp_entry_pending(craft_id: String) -> bool:
	if not _warp_completion_intents.has(craft_id) or _singleplayer_space_travel_owner == null: return false
	var intent: Dictionary = _warp_completion_intents[craft_id]
	if intent.fleet != _singleplayer_space_travel_owner or intent.owner_stamp != _singleplayer_space_travel_owner.get_craft_area_owner_stamp(craft_id): return false
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	var progress: Dictionary = _singleplayer_space_travel_owner.get_craft_quantum_progress(craft_id)
	return flight != null and flight == intent.flight and flight.get_snapshot().get("revision") == intent.flight_revision and progress.get("phase") == "quantum" and progress.get("revision") == intent.travel_revision and progress.get("target_orbit_id") == intent.target_orbit_id

func advance_singleplayer_warp_entry(adapter: Node, craft_id: String, delta: float) -> Dictionary:
	# Internal bounded owner path; adapter tick is intentionally not connected
	# until the inverse local-to-strategic transition is also available.
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter or not adapter.has_method("preview_space_warp_entry"): return {"ok":false, "reason":"adapter_required"}
	if not is_finite(delta) or delta <= 0.0 or delta > 60.0 or _singleplayer_space_travel_owner == null or _ship_equipment_owner == null: return {"ok":false, "reason":"invalid_entry_context"}
	var latest_id := String(_warp_entry_latest_by_craft.get(craft_id, ""))
	var current_flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if not latest_id.is_empty() and current_flight != null and current_flight.get_snapshot().get("motion_mode") == "tactical" and _singleplayer_space_travel_owner.get_craft_snapshot(craft_id).get("phase") == "orbit":
		var receipt: Dictionary = _warp_entry_receipts[latest_id]
		if receipt.fleet != _singleplayer_space_travel_owner or receipt.flight != current_flight or receipt.equipment != _ship_equipment_owner or current_flight.get_snapshot().get("space_area_id") != receipt.context.target_area_id: return {"ok":false, "reason":"owner_changed"}
		var replay_check: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(receipt.candidate, receipt.context)
		if not replay_check.get("ok", false) or not replay_check.get("replayed", false): return {"ok":false, "reason":"owner_changed"}
		var replay: Dictionary = receipt.result.duplicate(true)
		replay["replayed"] = true; replay.travel_result["replayed"] = true
		return replay
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if flight == null or _space_combat_state.get_actor(craft_id) != null or _space_combat_state.get_inactive_actor(craft_id) != null: _warp_entry_searches.erase(craft_id); return {"ok":false, "reason":"actor_unavailable"}
	var pose: Dictionary = flight.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
	if travel.get("phase") != "quantum" or pose.get("coordinate_frame") != "strategic" or not String(pose.get("space_area_id", "")).is_empty(): _warp_entry_searches.erase(craft_id); return {"ok":false, "reason":"quantum_completion_required"}
	if not is_singleplayer_warp_entry_pending(craft_id):
		_warp_entry_searches.erase(craft_id)
		_warp_completion_intents.erase(craft_id)
		if float(travel.get("elapsed_seconds", 0.0)) + delta < float(travel.get("duration_seconds", 0.0)): return {"ok":false, "reason":"quantum_not_complete"}
		_warp_completion_intents[craft_id] = {"fleet":_singleplayer_space_travel_owner, "owner_stamp":_singleplayer_space_travel_owner.get_craft_area_owner_stamp(craft_id), "flight":flight, "flight_revision":pose.revision, "travel_revision":travel.revision, "target_orbit_id":travel.target_orbit_id, "completion_delta":delta}
	var pilot_context: Dictionary = adapter.preview_space_warp_entry(craft_id)
	if not pilot_context.get("ok", false): _warp_entry_searches.erase(craft_id); return pilot_context
	var orbit: Dictionary = Dictionary(travel.get("orbits", {})).get(String(travel.get("target_orbit_id", "")), {})
	var body_id := String(orbit.get("body_id", ""))
	var layout: Dictionary = ORBIT_LAYOUT.build(body_id)
	if not layout.get("ok", false): return {"ok":false, "reason":"invalid_body"}
	var equipment_snapshot: Dictionary = _ship_equipment_owner.get_snapshot(craft_id)
	var state: Dictionary = _warp_entry_searches.get(craft_id, {})
	if not state.is_empty() and (state.flight != flight or state.flight_revision != pose.revision or state.travel_revision != travel.revision or state.equipment_owner != _ship_equipment_owner or state.equipment_snapshot != equipment_snapshot or state.body_id != body_id):
		_warp_entry_searches.erase(craft_id)
		return {"ok":false, "reason":"entry_context_changed"}
	if state.is_empty():
		if _warp_entry_searches.size() >= 64 or _warp_entry_receipts.size() >= 1024: return {"ok":false, "reason":"entry_capacity"}
		var profile: Dictionary = _ship_equipment_owner.get_space_flight_profile(craft_id)
		if not profile.get("ok", false): return profile
		if not is_equal_approx(float(profile.mass), float(pose.mass)): return {"ok":false, "reason":"flight_mass_mismatch"}
		var search = SPACE_ORBIT_ENTRY_SEARCH.new()
		var started: Dictionary = search.begin(body_id, [{"craft_id":craft_id, "flight":flight, "footprint_hexes":profile.footprint_hexes, "entry_heading":0.0}], _space_combat_state)
		if not started.get("ok", false): return started
		state = {"search":search, "flight":flight, "flight_revision":pose.revision, "travel_revision":travel.revision, "equipment_owner":_ship_equipment_owner, "equipment_snapshot":equipment_snapshot, "body_id":body_id, "footprint":profile.footprint_hexes.duplicate(), "delta":_warp_completion_intents[craft_id].completion_delta}
		_warp_entry_searches[craft_id] = state
	var search_result: Dictionary = state.search.advance(256)
	if not search_result.get("ok", false): _warp_entry_searches.erase(craft_id); return search_result
	if search_result.status == "pending": return {"ok":true, "status":"pending"}
	var target := {"position_plane":search_result.allocations[craft_id].position_plane, "heading_rad":0.0, "velocity_plane":Vector2.ZERO, "angular_velocity":0.0}
	var tick := tick_counter + 1
	var geometry: Dictionary = SPACE_AREA_TRANSITION.preview(flight, pose.revision, body_id, target, state.footprint, _space_combat_state, tick)
	if not geometry.get("ok", false): _warp_entry_searches.erase(craft_id); return geometry
	var wing: Dictionary = _space_wing_state.preview_flying_wings("singleplayer", [craft_id], pilot_context.owned_crafts, pilot_context.craft_pilots)
	if not wing.get("ok", false): _warp_entry_searches.erase(craft_id); return wing
	var definition := {"craft_id":craft_id, "faction_id":"player", "control_domain":"player", "footprint_hexes":state.footprint}
	var admission: Dictionary = _space_combat_state.validate_new_local_admission(definition, flight, geometry.proposal, tick)
	var movement: Dictionary = flight.validate_area_transition(geometry.proposal, tick)
	if not admission.get("ok", false) or not movement.get("ok", false): _warp_entry_searches.erase(craft_id); return {"ok":false, "reason":"admission_invalid"}
	var bound: Dictionary = _singleplayer_space_travel_owner.configure_space_area_transition_authority(self)
	if not bound.get("ok", false): _warp_entry_searches.erase(craft_id); return bound
	var id := "warp-arrival:%s:%d" % [craft_id, int(travel.revision)]
	var payload := {"craft_id":craft_id, "delta_seconds":state.delta}
	var context := {"request_id":id, "request_signature":JSON.stringify({"operation":"advance", "payload":payload}, "", true), "operation":"advance", "payload":payload, "source_area_id":"", "target_area_id":layout.body_map_id, "expected_travel_revision":travel.revision, "expected_phase":"quantum", "context_id":id}
	bound = _singleplayer_space_travel_owner.bind_space_area_transition_context(context, self)
	if not bound.get("ok", false): _warp_entry_searches.erase(craft_id); return bound
	var candidate: Dictionary = _singleplayer_space_travel_owner.prepare_space_area_transition(craft_id, travel.revision, "", layout.body_map_id, context)
	var tv: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(candidate, context) if candidate.get("ok", false) else candidate
	if not tv.get("ok", false) or tv.get("replayed", false):
		_singleplayer_space_travel_owner.release_space_area_transition_context(id, self); _warp_entry_searches.erase(craft_id)
		return {"ok":false, "reason":"travel_validation_failed"}
	# The wing owner mutates first only after all other participants validate;
	# all remaining operations are synchronous internal publication tails.
	var committed_wing: Dictionary = _space_wing_state.ensure_flying_wings("singleplayer", [craft_id], pilot_context.owned_crafts, pilot_context.craft_pilots, wing.expected_revision)
	if not committed_wing.get("ok", false):
		_singleplayer_space_travel_owner.release_space_area_transition_context(id, self); _warp_entry_searches.erase(craft_id)
		return committed_wing
	flight._publish_area_transition(movement)
	_space_combat_state._publish_new_local_admission(admission)
	_bind_owned_space_systems(craft_id)
	var arrival: Dictionary = _singleplayer_space_travel_owner._publish_prepared_space_area_transition(candidate, tv)
	_warp_entry_searches.erase(craft_id)
	_warp_completion_intents.erase(craft_id)
	var result := {"ok":true, "status":"complete", "space_area_id":layout.body_map_id, "travel_result":arrival, "receipt_id":id, "replayed":false}
	var command := {"contract_category":"singleplayer_space_travel", "operation":"advance", "payload":payload.duplicate(true), "request_id":id}
	_warp_entry_receipts[id] = {"fleet":_singleplayer_space_travel_owner, "flight":flight, "equipment":_ship_equipment_owner, "candidate":candidate.duplicate(true), "context":context.duplicate(true), "result":result.duplicate(true), "command":command, "event_published":false}
	_warp_entry_latest_by_craft[craft_id] = id
	return result

func publish_singleplayer_warp_entry_event(adapter: Node, receipt_id: String) -> void:
	if _should_skip_local_tick_processing() or _departure_adapter == null or _departure_adapter.get_ref() != adapter or not _warp_entry_receipts.has(receipt_id): return
	var receipt: Dictionary = _warp_entry_receipts[receipt_id]
	if receipt.event_published or receipt.fleet != _singleplayer_space_travel_owner or receipt.equipment != _ship_equipment_owner: return
	var verified: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(receipt.candidate, receipt.context)
	if not verified.get("ok", false) or not verified.get("replayed", false): return
	receipt.event_published = true
	singleplayer_command_committed.emit(receipt.command.duplicate(true), receipt.result.travel_result.duplicate(true))

func preview_singleplayer_local_return_fuel(adapter: Node, craft_id: String) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter or not adapter.has_method("preview_local_surface_return") or _singleplayer_supply_owner == null: return {"ok":false, "reason":"adapter_required"}
	var gate: Dictionary = adapter.preview_local_surface_return(craft_id)
	if not gate.get("ok", false): return gate
	if typeof(gate.get("route")) != TYPE_DICTIONARY or gate.route.get("craft_id") != craft_id or typeof(gate.get("outward_token")) != TYPE_STRING or String(gate.outward_token).is_empty(): return {"ok":false, "reason":"invalid_return_context"}
	if not _singleplayer_supply_owner.bind_route_fuel_preparation_authority(self): return {"ok":false, "reason":"supply_authority_unavailable"}
	var fuel := {"contract_category":"singleplayer_supply", "operation":"consume_route_fuel", "payload":gate.route.duplicate(true), "request_id":"return:" + String(gate.outward_token) + ":fuel"}
	var candidate: Dictionary = _singleplayer_supply_owner.prepare_route_fuel(fuel, {"route_fuel_authority":self,"departure_authorized":true,"require_return_reserve":false})
	if not candidate.get("ok", false): return candidate
	var result: Dictionary = candidate.result.duplicate(true)
	result["deferred"] = true
	return result

func commit_singleplayer_local_return(adapter: Node, craft_id: String) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter or not adapter.has_method("preview_local_surface_return"): return {"ok":false, "reason":"adapter_required"}
	if _singleplayer_space_travel_owner == null or _singleplayer_supply_owner == null: return {"ok":false, "reason":"owner_unavailable"}
	var latest_key := String(_local_return_latest_by_craft.get(craft_id, ""))
	var current_flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if not latest_key.is_empty() and current_flight != null and _singleplayer_space_travel_owner.get_craft_snapshot(craft_id).get("phase") == "orbit" and current_flight.get_snapshot().get("motion_mode") == "tactical":
		var previous: Dictionary = _local_return_receipts[latest_key]
		if previous.supply != _singleplayer_supply_owner or previous.fleet != _singleplayer_space_travel_owner or previous.flight != current_flight or previous.supply_epoch != _singleplayer_supply_owner.get("_route_prepare_epoch"): return {"ok":false, "reason":"owner_changed"}
		if current_flight.get_snapshot().get("space_area_id") != previous.travel_context.target_area_id: return {"ok":false, "reason":"return_context_changed"}
		var replay_check: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(previous.travel_candidate, previous.travel_context)
		if not replay_check.get("ok", false) or not replay_check.get("replayed", false): return {"ok":false, "reason":"owner_changed"}
		return {"ok":true, "replayed":true, "receipt_id":latest_key}
	var current_travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
	var current_phase := String(current_travel.get("phase", ""))
	var is_cancel := current_phase == "approach"
	if is_cancel and not adapter.has_method("preview_local_approach_cancel"): return {"ok":false, "reason":"adapter_required"}
	var gate: Dictionary = adapter.preview_local_approach_cancel(craft_id) if is_cancel else adapter.preview_local_surface_return(craft_id)
	if not gate.get("ok", false): return gate
	if typeof(gate.get("route")) != TYPE_DICTIONARY or typeof(gate.get("outward_token")) != TYPE_STRING or String(gate.outward_token).is_empty(): return {"ok":false, "reason":"invalid_return_context"}
	var route: Dictionary = gate.route
	if route.get("craft_id") != craft_id or route.get("destination_location_id") != "homebase": return {"ok":false, "reason":"invalid_return_context"}
	var key := ("local-cancel:" if is_cancel else "local-return:") + String(gate.outward_token) + ":" + craft_id
	if is_cancel: key += ":" + str(current_travel.get("revision", -1))
	if _local_return_receipts.has(key):
		var previous: Dictionary = _local_return_receipts[key]
		if previous.supply != _singleplayer_supply_owner or previous.fleet != _singleplayer_space_travel_owner or previous.flight != _singleplayer_space_travel_owner.get_flight_state(craft_id): return {"ok":false, "reason":"owner_changed"}
		var replay_check: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(previous.travel_candidate, previous.travel_context)
		if not replay_check.get("ok", false) or not replay_check.get("replayed", false) or previous.supply_epoch != _singleplayer_supply_owner.get("_route_prepare_epoch"): return {"ok":false, "reason":"owner_changed"}
		return {"ok":true, "replayed":true, "receipt_id":key}
	if _local_return_receipts.size() >= 1024: return {"ok":false, "reason":"receipt_capacity"}
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if flight == null or _space_combat_state.get_inactive_actor(craft_id) != flight: return {"ok":false, "reason":"unknown_actor"}
	var pose: Dictionary = flight.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
	if pose.get("coordinate_frame") != "local" or pose.get("motion_mode") != "inactive" or travel.get("phase") != ("approach" if is_cancel else "surface") or route.get("origin_location_id") != travel.get("location_id"): return {"ok":false, "reason":"return_context_changed"}
	var departure_receipt: Dictionary = _departure_group_receipts.get(String(gate.outward_token), {})
	var station_dock: bool = travel.location_id == "polisa" and bool(departure_receipt.get("station_dock", false))
	var station_landing: bool = travel.location_id == "polisa" and bool(departure_receipt.get("station_landing", false))
	if travel.location_id == "polisa" and not station_dock and not station_landing: return {"ok":false, "reason":"station_departure_receipt_required"}
	if station_dock or station_landing:
		if departure_receipt.get("craft_id") != craft_id or departure_receipt.get("fleet") != _singleplayer_space_travel_owner or departure_receipt.get("flight") != flight: return {"ok":false, "reason":"owner_changed"}
		var dock_check: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(departure_receipt.travel_candidate, departure_receipt.travel_context)
		if not dock_check.get("ok", false) or not dock_check.get("replayed", false): return {"ok":false, "reason":"owner_changed"}
	if is_cancel:
		var departure: Dictionary = _departure_group_receipts.get(String(gate.outward_token), {})
		if departure.get("craft_id") != craft_id or departure.get("fleet") != _singleplayer_space_travel_owner or departure.get("flight") != flight or Dictionary(departure.get("travel_context", {})).get("payload", {}).get("location_id") != travel.location_id: return {"ok":false, "reason":"no_departure_receipt"}
		var departure_check: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(departure.travel_candidate, departure.travel_context)
		if not departure_check.get("ok", false) or not departure_check.get("replayed", false): return {"ok":false, "reason":"owner_changed"}
	var orbit_id := String(Dictionary(travel.get("location_orbits", {})).get(travel.location_id, ""))
	var body_id := String(Dictionary(Dictionary(travel.get("orbits", {})).get(orbit_id, {})).get("body_id", ""))
	var layout: Dictionary = ORBIT_LAYOUT.build(body_id)
	if not layout.get("ok", false) or layout.body_map_id != pose.space_area_id: return {"ok":false, "reason":"area_body_mismatch"}
	var area_revision: int = _space_combat_state.get_area_revision(pose.space_area_id)
	var wing_revision: int = _space_wing_state.get_snapshot().revision
	var chosen := {}
	var context := {"runtime_authorized":true, "actor_id":"singleplayer"}
	# At most 256 gates, checked only on a return request, in stable order.
	var gate_offsets: Array = [SPACE_AREA_GRID.station_dock_layout().get("dock_gate")] if station_dock else ([SPACE_GRID.to_offset(SPACE_GRID.HEX.round_axial(SPACE_GRID.HEX.plane_to_axial(pose.position_plane)))] if station_landing else layout.gate_cells)
	for offset in gate_offsets:
		if typeof(offset) != TYPE_VECTOR2I: return {"ok":false, "reason":"station_layout_changed"}
		var target := {"position_plane":pose.position_plane if station_landing else SPACE_GRID.HEX.axial_to_plane(Vector2(SPACE_GRID.from_offset(offset))), "velocity_plane":Vector2.ZERO, "angular_velocity":0.0}
		var proposal := target.duplicate(true); proposal.merge({"expected_revision":pose.revision, "motion_mode":"tactical"}, true)
		if not _space_combat_state.preview_reactivation(craft_id, proposal, tick_counter + 1).get("ok", false): continue
		var candidate: Dictionary
		if station_dock or station_landing:
			if _space_wing_state.get_craft_wing(craft_id, "singleplayer").is_empty(): return {"ok":false, "reason":"wing_required"}
			candidate = {"ok":true, "activity_proposal":proposal, "activity_tick":tick_counter + 1}
		else:
			candidate = preview_surface_reactivation(craft_id, travel.location_id, target, pose.revision, travel.revision, area_revision, wing_revision, context)
		if candidate.get("ok", false): chosen = candidate; break
	if chosen.is_empty(): return {"ok":false, "reason":"return_gate_unavailable"}
	var fuel := {}
	var fuel_candidate := {}
	if not is_cancel:
		if not _singleplayer_supply_owner.bind_route_fuel_preparation_authority(self): return {"ok":false, "reason":"supply_authority_unavailable"}
		fuel = {"contract_category":"singleplayer_supply", "operation":"consume_route_fuel", "payload":route.duplicate(true), "request_id":"return:" + String(gate.outward_token) + ":fuel"}
		fuel_candidate = _singleplayer_supply_owner.prepare_route_fuel(fuel, {"route_fuel_authority":self,"departure_authorized":true,"require_return_reserve":false})
		if not fuel_candidate.get("ok", false): return fuel_candidate
	var bound: Dictionary = _singleplayer_space_travel_owner.configure_space_area_transition_authority(self)
	if not bound.get("ok", false): return bound
	var payload := {"craft_id":craft_id}
	var operation := "undock_station" if station_dock else ("depart_station_landing" if station_landing else "enter_orbit")
	if station_dock: payload.merge({"location_id":"polisa", "target_id":"polisa_station_dock", "layout_revision":"polisa_glut2_dock_v1"})
	if station_landing: payload["location_id"] = "polisa"
	var transition_id := ("station-undock:" + key) if station_dock else (("station-landing-return:" + key) if station_landing else key)
	var travel_context := {"request_id":transition_id, "request_signature":JSON.stringify({"operation":operation, "payload":payload}, "", true), "operation":operation, "payload":payload, "source_area_id":pose.space_area_id, "target_area_id":pose.space_area_id, "expected_travel_revision":travel.revision, "expected_phase":String(travel.phase), "context_id":transition_id}
	bound = _singleplayer_space_travel_owner.bind_space_area_transition_context(travel_context, self)
	if not bound.get("ok", false): return bound
	var travel_candidate: Dictionary = _singleplayer_space_travel_owner.prepare_space_area_transition(craft_id, travel.revision, pose.space_area_id, pose.space_area_id, travel_context)
	var tv: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(travel_candidate, travel_context) if travel_candidate.get("ok", false) else travel_candidate
	var sv: Dictionary = {"ok":true} if is_cancel else _singleplayer_supply_owner.validate_prepared_route_fuel(fuel_candidate, self)
	var fv: Dictionary = flight.validate_space_activity_transition(chosen.activity_proposal, chosen.activity_tick)
	var av: Dictionary = _space_combat_state.validate_reactivation(craft_id, chosen.activity_proposal, chosen.activity_tick)
	if not tv.get("ok", false) or tv.get("replayed", false) or not sv.get("ok", false) or not fv.get("ok", false) or not av.get("ok", false):
		_singleplayer_space_travel_owner.release_space_area_transition_context(transition_id, self)
		return {"ok":false, "reason":"return_validation_failed"}
	# Silent synchronous tail: all owner validations and boarding are complete.
	var fuel_result: Dictionary = {} if is_cancel else _singleplayer_supply_owner._publish_prepared_route_fuel(fuel_candidate, sv)
	flight._publish_space_activity_transition(fv)
	_space_combat_state._publish_reactivation(av)
	var travel_result: Dictionary = _singleplayer_space_travel_owner._publish_prepared_space_area_transition(travel_candidate, tv)
	var travel_command := {"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":transition_id}
	var events: Array = []
	if not is_cancel and sv.patch.mode == "apply": events.append({"command":fuel,"result":fuel_result})
	events.append({"command":travel_command,"result":travel_result})
	_local_return_receipts[key] = {"supply":_singleplayer_supply_owner,"supply_epoch":_singleplayer_supply_owner.get("_route_prepare_epoch"),"fleet":_singleplayer_space_travel_owner,"flight":flight,"travel_candidate":travel_candidate.duplicate(true),"travel_context":travel_context.duplicate(true),"events":events,"events_published":false}
	_local_return_latest_by_craft[craft_id] = key
	return {"ok":true,"replayed":false,"receipt_id":key}

func publish_singleplayer_local_return_events(adapter: Node, receipt_id: String) -> void:
	if _should_skip_local_tick_processing() or _departure_adapter == null or _departure_adapter.get_ref() != adapter: return
	if not _local_return_receipts.has(receipt_id): return
	var receipt: Dictionary = _local_return_receipts[receipt_id]
	if receipt.events_published or receipt.supply != _singleplayer_supply_owner or receipt.fleet != _singleplayer_space_travel_owner or receipt.supply_epoch != _singleplayer_supply_owner.get("_route_prepare_epoch"): return
	var verified: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(receipt.travel_candidate, receipt.travel_context)
	if not verified.get("ok", false) or not verified.get("replayed", false): return
	receipt.events_published = true
	var events: Array = receipt.events.duplicate(true)
	for event in events: singleplayer_command_committed.emit(event.command, event.result)

func commit_fixture_surface_group(bundle: Dictionary, context: Dictionary) -> Dictionary:
	# Exercise the real owner tails together, never accept production craft here.
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if context.get("runtime_authorized") != true or context.get("fixture") != true or context.get("actor_id") != "singleplayer": return {"ok":false, "reason":"fixture_only"}
	if bundle.size() != 6 or not bundle.has_all(["request_id", "craft_id", "location_id", "fuel_command", "binding_command", "activation_command"]): return {"ok":false, "reason":"invalid_bundle"}
	for key in ["request_id", "craft_id", "location_id"]:
		if typeof(bundle[key]) != TYPE_STRING or String(bundle[key]).strip_edges().is_empty(): return {"ok":false, "reason":"invalid_bundle"}
	if not String(bundle.craft_id).begins_with("space_fixture_"): return {"ok":false, "reason":"fixture_only"}
	if typeof(context.get("built_home_pad_ids")) != TYPE_ARRAY: return {"ok":false, "reason":"invalid_context"}
	for key in ["fuel_command", "binding_command", "activation_command"]:
		if typeof(bundle[key]) != TYPE_DICTIONARY: return {"ok":false, "reason":"invalid_bundle"}
	if _singleplayer_space_travel_owner == null or _singleplayer_supply_owner == null or _singleplayer_campaign_owner == null: return {"ok":false, "reason":"owner_unavailable"}
	for pair in [[_singleplayer_space_travel_owner, "res://scripts/core/singleplayer_fleet_travel_state.gd"], [_singleplayer_supply_owner, "res://scripts/core/singleplayer_supply_state.gd"], [_singleplayer_campaign_owner, "res://scripts/core/singleplayer_campaign_state.gd"]]:
		if pair[0].get_script() == null or pair[0].get_script().resource_path != pair[1]: return {"ok":false, "reason":"fixture_owner_required"}
	var signature := SPACE_COMMAND_CONTRACT.request_signature({"bundle":bundle, "pads":context.built_home_pad_ids})
	if _fixture_surface_group_receipts.has(bundle.request_id):
		var prior: Dictionary = _fixture_surface_group_receipts[bundle.request_id]
		if prior.signature != signature: return {"ok":false, "reason":"request_id_conflict"}
		if prior.fleet != _singleplayer_space_travel_owner or prior.supply != _singleplayer_supply_owner or prior.campaign != _singleplayer_campaign_owner: return {"ok":false, "reason":"owner_changed"}
		if prior.flight != _singleplayer_space_travel_owner.get_flight_state(bundle.craft_id): return {"ok":false, "reason":"owner_changed"}
		if prior.fleet_epoch != _singleplayer_space_travel_owner.get("_space_area_epoch") or prior.supply_epoch != _singleplayer_supply_owner.get("_route_prepare_epoch") or prior.campaign_epoch != _singleplayer_campaign_owner.get("_departure_preparation_epoch"): return {"ok":false, "reason":"owner_changed"}
		var travel_replay: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(prior.travel_candidate, prior.travel_context)
		if not travel_replay.get("ok", false) or not travel_replay.get("replayed", false): return {"ok":false, "reason":"owner_changed"}
		return {"ok":true, "replayed":true}
	if _fixture_surface_group_receipts.size() >= 128: return {"ok":false, "reason":"fixture_capacity"}
	var fuel: Dictionary = bundle.fuel_command
	var binding: Dictionary = bundle.binding_command
	if typeof(fuel.get("payload")) != TYPE_DICTIONARY or typeof(binding.get("payload")) != TYPE_DICTIONARY: return {"ok":false, "reason":"invalid_bundle"}
	var fp: Dictionary = fuel.get("payload", {})
	var bp: Dictionary = binding.get("payload", {})
	if fuel.get("operation") != "consume_route_fuel" or binding.get("operation") != "bind_departure" or fp.get("craft_id") != bundle.craft_id or bp.get("craft_id") != bundle.craft_id or fp.get("destination_location_id") != bundle.location_id or bp.get("destination_location_id") != bundle.location_id or fp.get("origin_location_id") != bp.get("origin_location_id"):
		return {"ok":false, "reason":"bundle_mismatch"}
	var flight: RefCounted = _space_combat_state.get_actor(bundle.craft_id)
	if flight == null or _singleplayer_space_travel_owner.get_flight_state(bundle.craft_id) != flight: return {"ok":false, "reason":"unknown_actor"}
	var pose: Dictionary = flight.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(bundle.craft_id)
	var area_revision: int = _space_combat_state.get_area_revision(String(pose.space_area_id))
	var wing_revision: int = _space_wing_state.get_snapshot().revision
	var preview: Dictionary = preview_surface_deactivation(bundle.craft_id, bundle.location_id, pose.revision, travel.get("revision", -1), area_revision, wing_revision, context)
	if not preview.get("ok", false): return preview
	if not _singleplayer_supply_owner.bind_route_fuel_preparation_authority(self): return {"ok":false, "reason":"supply_authority_unavailable"}
	var campaign_binding: Dictionary = _singleplayer_campaign_owner.configure_departure_preparation_authority(self)
	if not campaign_binding.get("ok", false): return campaign_binding
	var fleet_binding: Dictionary = _singleplayer_space_travel_owner.configure_space_area_transition_authority(self)
	if not fleet_binding.get("ok", false): return fleet_binding
	var supply_candidate: Dictionary = _singleplayer_supply_owner.prepare_route_fuel(fuel, {"route_fuel_authority":self, "departure_authorized":true, "require_return_reserve":true})
	if not supply_candidate.get("ok", false): return supply_candidate
	var campaign_context := {"authority":self, "transaction_id":String(bundle.request_id), "built_home_pad_ids":context.built_home_pad_ids.duplicate()}
	var campaign_candidate: Dictionary = _singleplayer_campaign_owner.prepare_departure(binding, bundle.activation_command, campaign_context)
	if not campaign_candidate.get("ok", false): return campaign_candidate
	_fixture_surface_group_serial += 1
	var payload := {"craft_id":bundle.craft_id, "location_id":bundle.location_id}
	var travel_context := {"request_id":String(bundle.request_id) + ":approach", "request_signature":JSON.stringify({"operation":"begin_approach", "payload":payload}, "", true), "operation":"begin_approach", "payload":payload, "source_area_id":pose.space_area_id, "target_area_id":pose.space_area_id, "expected_travel_revision":travel.revision, "expected_phase":"orbit", "context_id":"fixture-group:%d" % _fixture_surface_group_serial}
	var bound: Dictionary = _singleplayer_space_travel_owner.bind_space_area_transition_context(travel_context, self)
	if not bound.get("ok", false): return bound
	var travel_candidate: Dictionary = _singleplayer_space_travel_owner.prepare_space_area_transition(bundle.craft_id, travel.revision, pose.space_area_id, pose.space_area_id, travel_context)
	if not travel_candidate.get("ok", false):
		_singleplayer_space_travel_owner.release_space_area_transition_context(travel_context.context_id, self)
		return travel_candidate
	var sv: Dictionary = _singleplayer_supply_owner.validate_prepared_route_fuel(supply_candidate, self)
	var cv: Dictionary = _singleplayer_campaign_owner.validate_prepared_departure(campaign_candidate, campaign_context)
	var tv: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(travel_candidate, travel_context)
	var fv: Dictionary = flight.validate_space_activity_transition(preview.activity_proposal, preview.activity_tick)
	var av: Dictionary = _space_combat_state.validate_deactivation(bundle.craft_id, pose.revision, area_revision)
	if not sv.get("ok", false) or not cv.get("ok", false) or not tv.get("ok", false) or not fv.get("ok", false) or not av.get("ok", false) or sv.get("patch", {}).get("mode") != "apply" or cv.get("replayed", false) or tv.get("replayed", false):
		_singleplayer_space_travel_owner.release_space_area_transition_context(travel_context.context_id, self)
		return {"ok":false, "reason":"group_validation_failed"}
	# All participants have just been validated. No external callbacks or awaits
	# occur between the first mutation and the group receipt.
	flight._publish_space_activity_transition(fv)
	_space_combat_state._publish_deactivation(av)
	_singleplayer_supply_owner._publish_prepared_route_fuel(supply_candidate, sv)
	_singleplayer_campaign_owner._publish_prepared_departure(campaign_candidate, cv)
	_singleplayer_space_travel_owner._publish_prepared_space_area_transition(travel_candidate, tv)
	_fixture_surface_group_receipts[bundle.request_id] = {"signature":signature, "flight":flight, "fleet":_singleplayer_space_travel_owner, "supply":_singleplayer_supply_owner, "campaign":_singleplayer_campaign_owner, "fleet_epoch":_singleplayer_space_travel_owner.get("_space_area_epoch"), "supply_epoch":_singleplayer_supply_owner.get("_route_prepare_epoch"), "campaign_epoch":_singleplayer_campaign_owner.get("_departure_preparation_epoch"), "travel_candidate":travel_candidate.duplicate(true), "travel_context":travel_context.duplicate(true)}
	return {"ok":true, "replayed":false}

func get_space_radar_contacts(craft_id: String) -> Dictionary:
	# The existing space index contains spacecraft only. In atmosphere this is
	# consequently air-to-air radar, never a query for ground personnel.
	if _should_skip_local_tick_processing() or _singleplayer_space_travel_owner == null: return {"ok":false, "reason":"not_authority"}
	var flight: RefCounted = _space_combat_state.get_actor(craft_id)
	if flight == null or _singleplayer_space_travel_owner.get_flight_state(craft_id) != flight or _space_wing_state.get_craft_wing(craft_id, "singleplayer").is_empty(): return {"ok":false, "reason":"not_owned"}
	var pose: Dictionary = flight.get_snapshot()
	var area_id := String(pose.get("space_area_id", ""))
	if area_id.is_empty() or pose.get("motion_mode") != "tactical": return {"ok":false, "reason":"not_active_local"}
	var metadata: Dictionary = _space_combat_state.get_metadata(craft_id)
	var faction := String(metadata.get("faction_id", ""))
	if faction.is_empty(): return {"ok":false, "reason":"faction_unavailable"}
	var ids: Array = _space_combat_state.get_area_actor_ids(area_id)
	if ids.size() > 256: return {"ok":false, "reason":"contact_capacity"}
	var actors := {craft_id:{"id":craft_id, "position":pose.position_plane, "heading_rad":pose.heading_rad, "faction_id":faction, "area_id":area_id, "sensor_range":12.0}}
	for id: String in ids:
		if id == craft_id: continue
		var target: RefCounted = _space_combat_state.get_actor(id)
		var target_meta: Dictionary = _space_combat_state.get_metadata(id)
		if target == null or String(target_meta.get("faction_id", "")).is_empty() or target_meta.get("faction_id") == faction: continue
		var target_pose: Dictionary = target.get_snapshot()
		if target_pose.get("motion_mode") != "tactical" or target_pose.get("space_area_id") != area_id: continue
		actors[id] = {"id":id, "position":target_pose.position_plane, "faction_id":target_meta.faction_id, "area_id":area_id}
	var opaque: Array = []
	if area_id.begins_with("orbit_approach:"):
		var layout: Dictionary = ORBIT_LAYOUT.build(area_id.trim_prefix("orbit_approach:").uri_decode())
		if not layout.get("ok", false) or layout.body_map_id != area_id: return {"ok":false, "reason":"invalid_area"}
		for cell in layout.body_cells: opaque.append(SPACE_GRID.from_offset(cell))
	var collected: Dictionary = SPACE_TARGETING.collect_contacts({"actors":actors, "opaque_cells":opaque}, faction)
	if not collected.get("ok", false): return collected
	return {"ok":true, "craft_id":craft_id, "space_area_id":area_id, "range":12.0, "contacts":collected.contacts}

func get_space_area_snapshot(area_id: String, actor_id: String) -> Dictionary:
	if actor_id != "singleplayer" or _singleplayer_space_travel_owner == null:
		return {"ok":false, "reason":"actor_unavailable"}
	if area_id.is_empty(): return {"ok":false, "reason":"invalid_area"}
	var actors: Array[Dictionary] = []
	for craft_id in _space_combat_state.get_area_actor_ids(area_id):
		var flight: RefCounted = _space_combat_state.get_actor(craft_id)
		if flight == null or _singleplayer_space_travel_owner.get_flight_state(craft_id) != flight: continue
		var wing_id: String = _space_wing_state.get_craft_wing(craft_id, actor_id)
		if wing_id.is_empty(): continue
		var pose: Dictionary = flight.get_snapshot()
		if pose.get("space_area_id") != area_id or pose.get("motion_mode") != "tactical": continue
		var entry := {"craft_id":craft_id, "wing_id":wing_id, "flight":pose, "metadata":_space_combat_state.get_metadata(craft_id), "footprint_cells":_space_combat_state.get_indexed_actor_cells(craft_id)}
		var systems: Dictionary = _space_combat_state.get_ship_systems(craft_id)
		if not systems.is_empty(): entry["systems"] = systems.state.duplicate(true)
		actors.append(entry)
	var observed := {}
	for own: Dictionary in actors:
		var radar: Dictionary = get_space_radar_contacts(own.craft_id)
		if radar.get("ok", false):
			for contact_id: String in radar.contacts: observed[contact_id] = true
	for contact_id: String in observed:
		var flight: RefCounted = _space_combat_state.get_actor(contact_id)
		if flight == null: continue
		var pose: Dictionary = flight.get_snapshot()
		var meta: Dictionary = _space_combat_state.get_metadata(contact_id)
		actors.append({"craft_id":contact_id, "flight":pose, "metadata":{"faction_id":meta.get("faction_id", ""), "control_domain":meta.get("control_domain", "")}, "footprint_cells":_space_combat_state.get_indexed_actor_cells(contact_id), "radar_contact":true})
	return {"ok":true, "space_area_id":area_id, "area_revision":_space_combat_state.get_area_revision(area_id), "actors":actors, "dock_targets":SPACE_AREA_GRID.dock_targets(area_id)}

func preview_station_dock(craft_id: String, target_id: String, layout_revision: String, expected_flight_revision: int, expected_travel_revision: int, expected_area_revision: int, expected_wing_revision: int, authority_context: Dictionary, require_dock_gate: bool = true) -> Dictionary:
	# Read-only gate evidence; never a reservation or boarding authorization.
	if authority_context.get("runtime_authorized") != true: return {"ok":false, "reason":"runtime_authority_required"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	var actor_id: Variant = authority_context.get("actor_id")
	if typeof(actor_id) != TYPE_STRING or String(actor_id).strip_edges().is_empty(): return {"ok":false, "reason":"invalid_actor"}
	var layout: Dictionary = SPACE_AREA_GRID.station_dock_layout()
	if not layout.get("ok", false) or target_id != layout.target_id or layout_revision != layout.revision: return {"ok":false, "reason":"station_layout_changed"}
	if _singleplayer_space_travel_owner == null: return {"ok":false, "reason":"travel_unavailable"}
	var flight: RefCounted = _space_combat_state.get_actor(craft_id)
	if flight == null or flight != _singleplayer_space_travel_owner.get_flight_state(craft_id): return {"ok":false, "reason":"unknown_actor"}
	var metadata: Dictionary = _space_combat_state.get_metadata(craft_id)
	if metadata.get("control_domain") != "player": return {"ok":false, "reason":"not_owned"}
	var pose: Dictionary = flight.get_snapshot()
	if pose.get("craft_id") != craft_id or pose.get("revision") != expected_flight_revision: return {"ok":false, "reason":"stale_flight_revision"}
	if pose.get("coordinate_frame") != "local" or pose.get("motion_mode") != "tactical" or pose.get("space_area_id") != layout.area_id: return {"ok":false, "reason":"station_area_required"}
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
	if travel.get("revision") != expected_travel_revision: return {"ok":false, "reason":"stale_travel_revision"}
	if travel.get("phase") != "orbit" or travel.get("orbit_id") != "polisa_orbit" or Dictionary(travel.get("location_orbits", {})).get("polisa") != "polisa_orbit": return {"ok":false, "reason":"station_orbit_required"}
	if _space_combat_state.get_area_revision(layout.area_id) != expected_area_revision: return {"ok":false, "reason":"stale_area_revision"}
	if _space_wing_state.get_snapshot().revision != expected_wing_revision: return {"ok":false, "reason":"stale_wing_revision"}
	var wing_id: String = _space_wing_state.get_craft_wing(craft_id, actor_id)
	if wing_id.is_empty(): return {"ok":false, "reason":"wing_required"}
	var cells: Array[Vector2i] = _space_combat_state.preview_footprint(pose, metadata.get("footprint_hexes", []))
	if cells.is_empty() or not _space_combat_state.actor_cells_match(craft_id, layout.area_id, cells): return {"ok":false, "reason":"stale_spatial_index"}
	if require_dock_gate and SPACE_GRID.from_offset(layout.dock_gate) not in cells: return {"ok":false, "reason":"not_at_station_gate"}
	for occupant in _space_combat_state.query_cells(cells, layout.area_id):
		if occupant != craft_id: return {"ok":false, "reason":"occupied"}
	for claimant in _space_combat_state.query_navigation_claims(cells, layout.area_id):
		if claimant != craft_id: return {"ok":false, "reason":"navigation_claimed"}
	return {"ok":true, "craft_id":craft_id, "target_id":target_id, "layout_revision":layout.revision, "space_area_id":layout.area_id, "wing_id":wing_id, "flight_revision":pose.revision, "travel_revision":travel.revision, "area_revision":expected_area_revision, "wing_revision":expected_wing_revision, "footprint_cells":cells}

func preview_station_dock_deactivation(craft_id: String, target_id: String, layout_revision: String, expected_flight_revision: int, expected_travel_revision: int, expected_area_revision: int, expected_wing_revision: int, authority_context: Dictionary, require_dock_gate: bool = true) -> Dictionary:
	var gate: Dictionary = preview_station_dock(craft_id, target_id, layout_revision, expected_flight_revision, expected_travel_revision, expected_area_revision, expected_wing_revision, authority_context, require_dock_gate)
	if not gate.get("ok", false): return gate
	var flight: RefCounted = _space_combat_state.get_actor(craft_id)
	var proposal := {"expected_revision":expected_flight_revision, "motion_mode":"inactive"}
	var tick := tick_counter + 1
	var flight_check: Dictionary = flight.validate_space_activity_transition(proposal, tick)
	if not flight_check.get("ok", false): return flight_check
	var actor_check: Dictionary = _space_combat_state.validate_deactivation(craft_id, expected_flight_revision, expected_area_revision)
	if not actor_check.get("ok", false): return actor_check
	gate["activity_proposal"] = proposal
	gate["activity_tick"] = tick
	return gate

func preview_station_landing_deactivation(craft_id: String, expected_flight_revision: int, expected_travel_revision: int, expected_area_revision: int, expected_wing_revision: int, authority_context: Dictionary) -> Dictionary:
	# The destination is the station visit. Landing occurs on its existing map;
	# the distinct optional space dock gate is not required for this operation.
	return preview_station_dock_deactivation(craft_id, "polisa_station_dock", "polisa_glut2_dock_v1", expected_flight_revision, expected_travel_revision, expected_area_revision, expected_wing_revision, authority_context, false)

func preview_surface_approach(craft_id: String, location_id: String, expected_flight_revision: int, expected_travel_revision: int, expected_area_revision: int, expected_wing_revision: int, authority_context: Dictionary) -> Dictionary:
	# Read-only geometric evidence, never authorization or a reservation.
	if authority_context.get("runtime_authorized") != true: return {"ok":false, "reason":"runtime_authority_required"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	var actor_id: Variant = authority_context.get("actor_id")
	if typeof(actor_id) != TYPE_STRING or String(actor_id).strip_edges().is_empty(): return {"ok":false, "reason":"invalid_actor"}
	if _singleplayer_space_travel_owner == null: return {"ok":false, "reason":"travel_unavailable"}
	var flight: RefCounted = _space_combat_state.get_actor(craft_id)
	if flight == null or flight != _singleplayer_space_travel_owner.get_flight_state(craft_id): return {"ok":false, "reason":"unknown_actor"}
	var metadata: Dictionary = _space_combat_state.get_metadata(craft_id)
	if metadata.get("control_domain") != "player": return {"ok":false, "reason":"not_owned"}
	var snapshot: Dictionary = flight.get_snapshot()
	if snapshot.revision != expected_flight_revision: return {"ok":false, "reason":"stale_flight_revision"}
	if snapshot.coordinate_frame != "local" or String(snapshot.space_area_id).is_empty(): return {"ok":false, "reason":"not_in_local_area"}
	var travel: Dictionary = _singleplayer_space_travel_owner.get_snapshot(craft_id)
	if travel.get("revision") != expected_travel_revision: return {"ok":false, "reason":"stale_travel_revision"}
	if travel.get("phase") != "orbit": return {"ok":false, "reason":"invalid_phase"}
	var orbit_id: String = String(Dictionary(travel.get("location_orbits", {})).get(location_id, ""))
	if orbit_id.is_empty() or orbit_id != String(travel.get("orbit_id", "")): return {"ok":false, "reason":"location_orbit_mismatch"}
	var orbit: Dictionary = Dictionary(travel.get("orbits", {})).get(orbit_id, {})
	var body_id := String(orbit.get("body_id", ""))
	var body: Dictionary = Dictionary(travel.get("bodies", {})).get(body_id, {})
	if String(body.get("id", "")) != body_id or not ORBIT_SURFACE_LOCATIONS.contains(body, location_id):
		return {"ok":false, "reason":"not_surface_destination"}
	var layout: Dictionary = ORBIT_LAYOUT.build(body_id)
	if not layout.get("ok", false) or layout.body_map_id != snapshot.space_area_id: return {"ok":false, "reason":"area_body_mismatch"}
	if _space_combat_state.get_area_revision(snapshot.space_area_id) != expected_area_revision: return {"ok":false, "reason":"stale_area_revision"}
	if _space_wing_state.get_snapshot().revision != expected_wing_revision: return {"ok":false, "reason":"stale_wing_revision"}
	var wing_id: String = _space_wing_state.get_craft_wing(craft_id, actor_id)
	if wing_id.is_empty(): return {"ok":false, "reason":"wing_required"}
	var cells: Array[Vector2i] = _space_combat_state.preview_footprint(snapshot, metadata.get("footprint_hexes", []))
	if cells.is_empty(): return {"ok":false, "reason":"invalid_footprint"}
	if not _space_combat_state.actor_cells_match(craft_id, snapshot.space_area_id, cells): return {"ok":false, "reason":"stale_spatial_index"}
	var body_cells := {}
	var gate_cells := {}
	for cell in layout.body_cells: body_cells[cell] = true
	for cell in layout.gate_cells: gate_cells[cell] = true
	var at_gate := false
	for cell in cells:
		var offset: Vector2i = SPACE_GRID.to_offset(cell)
		if body_cells.has(offset): return {"ok":false, "reason":"body_blocked"}
		if gate_cells.has(offset): at_gate = true
	for occupant in _space_combat_state.query_cells(cells, snapshot.space_area_id):
		if occupant != craft_id: return {"ok":false, "reason":"occupied"}
	for claimant in _space_combat_state.query_navigation_claims(cells, snapshot.space_area_id):
		if claimant != craft_id: return {"ok":false, "reason":"navigation_claimed"}
	if not at_gate: return {"ok":false, "reason":"not_at_approach_gate"}
	return {"ok":true, "craft_id":craft_id, "location_id":location_id, "space_area_id":snapshot.space_area_id, "wing_id":wing_id, "flight_revision":snapshot.revision, "travel_revision":travel.revision, "area_revision":expected_area_revision, "wing_revision":expected_wing_revision, "layout_revision":layout.revision, "footprint_cells":cells}

func preview_surface_deactivation(craft_id: String, location_id: String, expected_flight_revision: int, expected_travel_revision: int, expected_area_revision: int, expected_wing_revision: int, authority_context: Dictionary) -> Dictionary:
	var gate: Dictionary = preview_surface_approach(craft_id, location_id, expected_flight_revision, expected_travel_revision, expected_area_revision, expected_wing_revision, authority_context)
	if not gate.get("ok", false): return gate
	var flight: RefCounted = _space_combat_state.get_actor(craft_id)
	var proposal := {"expected_revision":expected_flight_revision, "motion_mode":"inactive"}
	var tick := tick_counter + 1
	var validation: Dictionary = flight.validate_space_activity_transition(proposal, tick)
	if not validation.get("ok", false): return validation
	gate["activity_proposal"] = proposal
	gate["activity_tick"] = tick
	return gate

func preview_surface_reactivation(craft_id: String, location_id: String, target_pose: Dictionary, expected_flight_revision: int, expected_travel_revision: int, expected_area_revision: int, expected_wing_revision: int, authority_context: Dictionary) -> Dictionary:
	# Read-only preflight for a previously inactive local Flight object.
	if authority_context.get("runtime_authorized") != true: return {"ok":false, "reason":"runtime_authority_required"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	var actor_id: Variant = authority_context.get("actor_id")
	if typeof(actor_id) != TYPE_STRING or String(actor_id).strip_edges().is_empty(): return {"ok":false, "reason":"invalid_actor"}
	if _singleplayer_space_travel_owner == null: return {"ok":false, "reason":"travel_unavailable"}
	var flight: RefCounted = _space_combat_state.get_inactive_actor(craft_id)
	if flight == null or flight != _singleplayer_space_travel_owner.get_flight_state(craft_id): return {"ok":false, "reason":"unknown_actor"}
	if _space_combat_state.get_metadata(craft_id).get("control_domain") != "player": return {"ok":false, "reason":"not_owned"}
	var snapshot: Dictionary = flight.get_snapshot()
	if snapshot.revision != expected_flight_revision: return {"ok":false, "reason":"stale_flight_revision"}
	if snapshot.coordinate_frame != "local" or snapshot.motion_mode != "inactive": return {"ok":false, "reason":"not_inactive_local"}
	var travel: Dictionary = _singleplayer_space_travel_owner.get_snapshot(craft_id)
	if travel.get("revision") != expected_travel_revision: return {"ok":false, "reason":"stale_travel_revision"}
	if travel.get("phase") not in ["surface", "approach"]: return {"ok":false, "reason":"invalid_phase"}
	if String(travel.get("location_id", "")) != location_id: return {"ok":false, "reason":"location_mismatch"}
	var orbit_id := String(Dictionary(travel.get("location_orbits", {})).get(location_id, ""))
	var orbit: Dictionary = Dictionary(travel.get("orbits", {})).get(orbit_id, {})
	var body_id := String(orbit.get("body_id", ""))
	var body: Dictionary = Dictionary(travel.get("bodies", {})).get(body_id, {})
	if body_id.is_empty() or String(body.get("id", "")) != body_id or not ORBIT_SURFACE_LOCATIONS.contains(body, location_id):
		return {"ok":false, "reason":"not_surface_destination"}
	var layout: Dictionary = ORBIT_LAYOUT.build(body_id)
	if not layout.get("ok", false) or layout.body_map_id != snapshot.space_area_id: return {"ok":false, "reason":"area_body_mismatch"}
	if _space_combat_state.get_area_revision(snapshot.space_area_id) != expected_area_revision: return {"ok":false, "reason":"stale_area_revision"}
	if _space_wing_state.get_snapshot().revision != expected_wing_revision: return {"ok":false, "reason":"stale_wing_revision"}
	var wing_id: String = _space_wing_state.get_craft_wing(craft_id, actor_id)
	if wing_id.is_empty(): return {"ok":false, "reason":"wing_required"}
	for key in target_pose:
		if key not in ["position_plane", "velocity_plane", "heading_rad", "angular_velocity", "assist_mode"]: return {"ok":false, "reason":"invalid_target"}
	var proposal: Dictionary = target_pose.duplicate(true)
	proposal.merge({"expected_revision":expected_flight_revision, "motion_mode":"tactical"}, true)
	var tick := tick_counter + 1
	var availability: Dictionary = _space_combat_state.preview_reactivation(craft_id, proposal, tick)
	if not availability.get("ok", false): return availability
	var body_cells := {}
	var gate_cells := {}
	for cell in layout.body_cells: body_cells[cell] = true
	for cell in layout.gate_cells: gate_cells[cell] = true
	var at_gate := false
	for cell in availability.cells:
		var offset: Vector2i = SPACE_GRID.to_offset(cell)
		if body_cells.has(offset): return {"ok":false, "reason":"body_blocked"}
		if gate_cells.has(offset): at_gate = true
	if not at_gate: return {"ok":false, "reason":"not_at_approach_gate"}
	return {"ok":true, "craft_id":craft_id, "location_id":location_id, "space_area_id":snapshot.space_area_id, "wing_id":wing_id, "flight_revision":snapshot.revision, "travel_revision":travel.revision, "area_revision":expected_area_revision, "wing_revision":expected_wing_revision, "layout_revision":layout.revision, "footprint_cells":availability.cells, "activity_proposal":proposal, "activity_tick":tick}

func preview_warp_departure(craft_id: String, target_orbit_id: String, expected_flight_revision: int, expected_travel_revision: int, expected_area_revision: int, expected_wing_revision: int, authority_context: Dictionary) -> Dictionary:
	# Preview only; prepared Travel/Economy and a coordinated commit are required.
	if authority_context.get("runtime_authorized") != true: return {"ok":false, "reason":"runtime_authority_required"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	var actor_id: Variant = authority_context.get("actor_id")
	if typeof(actor_id) != TYPE_STRING or String(actor_id).strip_edges().is_empty(): return {"ok":false, "reason":"invalid_actor"}
	if _singleplayer_space_travel_owner == null: return {"ok":false, "reason":"travel_unavailable"}
	var flight: RefCounted = _space_combat_state.get_actor(craft_id)
	if flight == null or flight != _singleplayer_space_travel_owner.get_flight_state(craft_id): return {"ok":false, "reason":"unknown_actor"}
	var metadata: Dictionary = _space_combat_state.get_metadata(craft_id)
	if metadata.get("control_domain") != "player": return {"ok":false, "reason":"not_owned"}
	var snapshot: Dictionary = flight.get_snapshot()
	if snapshot.revision != expected_flight_revision: return {"ok":false, "reason":"stale_flight_revision"}
	if snapshot.coordinate_frame != "local" or snapshot.motion_mode != "tactical": return {"ok":false, "reason":"not_active_local"}
	var travel: Dictionary = _singleplayer_space_travel_owner.get_snapshot(craft_id)
	if travel.get("revision") != expected_travel_revision: return {"ok":false, "reason":"stale_travel_revision"}
	if travel.get("phase") != "orbit": return {"ok":false, "reason":"invalid_phase"}
	var orbits: Dictionary = travel.get("orbits", {})
	if not orbits.has(target_orbit_id): return {"ok":false, "reason":"unknown_orbit"}
	var source: Dictionary = orbits.get(String(travel.get("orbit_id", "")), {})
	var target: Dictionary = orbits[target_orbit_id]
	var body_id := String(source.get("body_id", ""))
	if body_id.is_empty(): return {"ok":false, "reason":"invalid_source_orbit"}
	if String(target.get("body_id", "")) == body_id: return {"ok":false, "reason":"already_in_orbit"}
	var body: Dictionary = Dictionary(travel.get("bodies", {})).get(body_id, {})
	var layout: Dictionary = ORBIT_LAYOUT.build(body_id)
	if String(body.get("id", "")) != body_id or not layout.get("ok", false) or layout.body_map_id != snapshot.space_area_id:
		return {"ok":false, "reason":"area_body_mismatch"}
	if _space_combat_state.get_area_revision(snapshot.space_area_id) != expected_area_revision: return {"ok":false, "reason":"stale_area_revision"}
	if _space_wing_state.get_snapshot().revision != expected_wing_revision: return {"ok":false, "reason":"stale_wing_revision"}
	var wing_id: String = _space_wing_state.get_craft_wing(craft_id, actor_id)
	if wing_id.is_empty(): return {"ok":false, "reason":"wing_required"}
	var cells: Array[Vector2i] = _space_combat_state.preview_footprint(snapshot, metadata.get("footprint_hexes", []))
	if cells.is_empty(): return {"ok":false, "reason":"invalid_footprint"}
	if not _space_combat_state.actor_cells_match(craft_id, snapshot.space_area_id, cells): return {"ok":false, "reason":"stale_spatial_index"}
	var body_cells := {}
	for cell in layout.body_cells: body_cells[cell] = true
	for cell in cells:
		if body_cells.has(SPACE_GRID.to_offset(cell)): return {"ok":false, "reason":"body_blocked"}
	for occupant in _space_combat_state.query_cells(cells, snapshot.space_area_id):
		if occupant != craft_id: return {"ok":false, "reason":"occupied"}
	for claimant in _space_combat_state.query_navigation_claims(cells, snapshot.space_area_id):
		if claimant != craft_id: return {"ok":false, "reason":"navigation_claimed"}
	var position: Variant = body.get("position")
	if typeof(position) != TYPE_ARRAY or position.size() != 2: return {"ok":false, "reason":"invalid_body_position"}
	for value in position:
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or float(value) < 0.0 or float(value) > 1.0: return {"ok":false, "reason":"invalid_body_position"}
	var proposal := {"expected_revision":expected_flight_revision, "coordinate_frame":"strategic", "space_area_id":"", "position_plane":SPACE_GRID.pair(position) * SPACE_GRID.EXTENT, "motion_mode":"travel"}
	var tick := tick_counter + 1
	var validation: Dictionary = flight.validate_area_transition(proposal, tick)
	if not validation.get("ok", false): return validation
	return {"ok":true, "craft_id":craft_id, "target_orbit_id":target_orbit_id, "source_area_id":snapshot.space_area_id, "wing_id":wing_id, "flight_revision":snapshot.revision, "travel_revision":travel.revision, "area_revision":expected_area_revision, "wing_revision":expected_wing_revision, "layout_revision":layout.revision, "area_proposal":proposal, "transition_tick":tick}

func set_space_flight_control(craft_id: String, intent: Dictionary, hull: Dictionary, power: Dictionary, authority_context: Dictionary) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if authority_context.get("runtime_authorized") != true:
		return {"ok": false, "reason": "runtime_authority_required"}
	# The current tick adapter has no authoritative map-obstacle or equipment source.
	if not craft_id.begins_with("space_fixture_"):
		return {"ok": false, "reason": "fixture_only"}
	var flight: RefCounted = _space_combat_state.get_actor(craft_id)
	if flight == null or flight.get_snapshot().motion_mode != "tactical":
		return {"ok": false, "reason": "not_tactical"}
	var flight_pose: Dictionary = flight.get_snapshot()
	var environment := "atmosphere" if String(flight_pose.get("space_area_id", "")).begins_with("atmosphere:") else "space"
	var validation: Dictionary = SPACE_FLIGHT_RESOLVER.step(flight_pose, intent, hull, power, 0.0, environment)
	if not validation.get("ok", false):
		return validation
	_space_combat_state.set_flight_control(craft_id, {"intent":intent, "hull":hull, "power":power})
	return {"ok": true}

func get_space_flight_status(craft_id: String) -> Dictionary:
	return _space_combat_state.get_flight_status(craft_id)

func start_singleplayer_orbit_transit(adapter: Node, craft_id: String, location_id: String, direction: String, request_id: String) -> Dictionary:
	if _should_skip_local_tick_processing() or is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter: return {"ok":false, "reason":"adapter_required"}
	if _singleplayer_space_travel_owner == null or location_id == "polisa" or request_id.is_empty(): return {"ok":false, "reason":"invalid_context"}
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if flight == null or _space_combat_state.get_actor(craft_id) != flight: return {"ok":false, "reason":"not_owned"}
	var pose: Dictionary = flight.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
	var orbit_id := String(Dictionary(travel.get("location_orbits", {})).get(location_id, ""))
	var orbit: Dictionary = Dictionary(travel.get("orbits", {})).get(orbit_id, {})
	var body_id := String(orbit.get("body_id", ""))
	var body: Dictionary = Dictionary(travel.get("bodies", {})).get(body_id, {})
	if travel.get("phase") != "orbit" or String(travel.get("orbit_id", "")) != orbit_id or body_id.is_empty() or not ORBIT_SURFACE_LOCATIONS.contains(body, location_id) or pose.get("space_area_id") != "orbit_approach:" + body_id.uri_encode(): return {"ok":false, "reason":"invalid_surface_context"}
	if not is_instance_valid(_base_personnel_owner) or not _base_personnel_owner.is_pilot_aboard(craft_id): return {"ok":false, "reason":"pilot_not_aboard"}
	var radar: Dictionary = get_space_radar_contacts(craft_id)
	if not radar.get("ok", false): return radar
	if not Array(radar.contacts).is_empty(): return {"ok":false, "reason":"contact_detected"}
	# The radar decides which distant contacts are known. The existing
	# collision and swept-footprint owner remains authoritative for all actors.
	var metadata: Dictionary = _space_combat_state.get_metadata(craft_id)
	var start := SPACE_GRID.HEX.round_axial(SPACE_GRID.HEX.plane_to_axial(pose.position_plane))
	var plan: Dictionary = ORBIT_AUTO_TRANSIT.plan(pose.space_area_id, start, direction, Array(metadata.get("footprint_hexes", [])), [], radar.contacts)
	if not plan.get("ok", false): return plan
	var line: Array[Vector2i] = SPACE_GRID.HEX.line(start, plan.target_hex)
	for claimant in _space_combat_state.query_navigation_claims(line, pose.space_area_id):
		if claimant != craft_id: return {"ok":false, "reason":"navigation_claimed"}
	var result: Dictionary = request_singleplayer_space_move({"craft_id":craft_id, "target_hex":plan.target_hex, "request_id":request_id})
	if not result.get("ok", false) or result.get("replayed", false): return result
	var control: Dictionary = _space_combat_state.get_flight_controls().get(craft_id, {})
	if control.is_empty(): return {"ok":false, "reason":"control_unavailable"}
	control["orbit_auto_transit"] = true
	control["orbit_auto_location_id"] = location_id
	control["orbit_auto_direction"] = direction
	_space_combat_state.set_flight_control(craft_id, control)
	_space_combat_state.set_flight_status(craft_id, {"ok":true, "reason":"transit"})
	return {"ok":true, "target_hex":plan.target_hex, "direction":direction}

func stop_singleplayer_orbit_transit(adapter: Node, craft_id: String) -> Dictionary:
	if _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter: return {"ok":false, "reason":"adapter_required"}
	var control: Dictionary = _space_combat_state.get_flight_controls().get(craft_id, {})
	var flight: RefCounted = _space_combat_state.get_actor(craft_id)
	if flight == null or not control.get("orbit_auto_transit", false): return {"ok":false, "reason":"not_auto_transit"}
	control["goal"] = {"target_plane":flight.get_snapshot().position_plane}
	control["orbit_auto_transit"] = false
	control["orbit_auto_braking"] = true
	_space_combat_state.release_navigation_claim(craft_id)
	_space_combat_state.set_flight_control(craft_id, control)
	return {"ok":true}

func request_singleplayer_space_move(command: Dictionary) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	# The adapter supplies only this strict payload; all authority is read here.
	if command.size() != 3 or not command.has_all(["craft_id", "target_hex", "request_id"]): return {"ok":false, "reason":"invalid_command"}
	if typeof(command.craft_id) != TYPE_STRING or String(command.craft_id).strip_edges().is_empty() or typeof(command.request_id) != TYPE_STRING or String(command.request_id).strip_edges().is_empty() or typeof(command.target_hex) != TYPE_VECTOR2I: return {"ok":false, "reason":"invalid_command"}
	var id: String = command.craft_id
	var signature := SPACE_COMMAND_CONTRACT.request_signature(command)
	if _space_move_receipts.has(command.request_id):
		var receipt: Dictionary = _space_move_receipts[command.request_id]
		if receipt.signature != signature: return {"ok":false, "reason":"request_id_conflict"}
		return {"ok":true, "replayed":true}
	if _space_move_receipts.size() >= 1024: return {"ok":false, "reason":"receipt_capacity"}
	if _singleplayer_space_travel_owner == null or _ship_equipment_owner == null or not is_instance_valid(_base_personnel_owner): return {"ok":false, "reason":"runtime_unavailable"}
	var flight: RefCounted = _space_combat_state.get_actor(id)
	if flight == null or _singleplayer_space_travel_owner.get_flight_state(id) != flight: return {"ok":false, "reason":"not_owned"}
	if _space_wing_state.get_craft_wing(id, "singleplayer").is_empty(): return {"ok":false, "reason":"wing_required"}
	if not _base_personnel_owner.is_pilot_aboard(id): return {"ok":false, "reason":"pilot_not_aboard"}
	var pose: Dictionary = flight.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(id)
	if pose.motion_mode != "tactical" or pose.coordinate_frame != "local" or travel.get("phase") != "orbit": return {"ok":false, "reason":"not_active_local"}
	if not SPACE_AREA_GRID.contains(command.target_hex, pose): return {"ok":false, "reason":"invalid_target"}
	var profile: Dictionary = _ship_equipment_owner.get_space_flight_profile(id)
	if not profile.get("ok", false): return profile
	if not is_equal_approx(float(profile.mass), float(pose.mass)): return {"ok":false, "reason":"flight_mass_mismatch"}
	var area_id: String = pose.space_area_id
	if not area_id.begins_with("orbit_approach:"): return {"ok":false, "reason":"invalid_area"}
	var layout: Dictionary = ORBIT_LAYOUT.build(area_id.trim_prefix("orbit_approach:").uri_decode())
	if not layout.get("ok", false) or layout.body_map_id != area_id: return {"ok":false, "reason":"invalid_area"}
	var orbit: Dictionary = Dictionary(travel.get("orbits", {})).get(String(travel.get("orbit_id", "")), {})
	if String(orbit.get("body_id", "")) != String(layout.body_id): return {"ok":false, "reason":"area_body_mismatch"}
	var target_plane: Vector2 = SPACE_GRID.HEX.axial_to_plane(Vector2(command.target_hex))
	var cells: Array[Vector2i] = _space_combat_state.preview_actor_cells(id, {"position_plane":target_plane})
	if cells.is_empty(): return {"ok":false, "reason":"invalid_target"}
	for cell in cells:
		if layout.body_cells.has(SPACE_GRID.to_offset(cell)): return {"ok":false, "reason":"blocked_target"}
	for occupant in _space_combat_state.query_cells(cells, area_id):
		if occupant != id: return {"ok":false, "reason":"occupied"}
	for claimant in _space_combat_state.query_navigation_claims(cells, area_id):
		if claimant != id: return {"ok":false, "reason":"navigation_claimed"}
	var goal := {"target_plane":target_plane}
	var guidance: Dictionary = SPACE_GUIDANCE_RESOLVER.resolve(pose, goal, profile.hull, profile.power)
	if not guidance.get("ok", false): return guidance
	var claim: Dictionary = _space_combat_state.record_navigation_claim(id, area_id, cells)
	if not claim.get("ok", false): return claim
	_space_combat_state.set_flight_control(id, {"goal":goal, "hull":profile.hull, "power":profile.power, "singleplayer_move":true, "equipment_snapshot":_ship_equipment_owner.get_snapshot(id), "equipment_owner_id":_ship_equipment_owner.get_instance_id(), "area_id":area_id})
	_space_move_receipts[command.request_id] = {"signature":signature}
	return {"ok":true, "replayed":false}

func set_space_fixture_goal(craft_id: String, goal: Dictionary, hull: Dictionary, power: Dictionary, authority_context: Dictionary) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if authority_context.get("runtime_authorized") != true:
		return {"ok":false, "reason":"runtime_authority_required"}
	if not craft_id.begins_with("space_fixture_"):
		return {"ok":false, "reason":"fixture_only"}
	var flight: RefCounted = _space_combat_state.get_actor(craft_id)
	if flight == null or flight.get_snapshot().motion_mode != "tactical":
		return {"ok":false, "reason":"not_tactical"}
	var validation: Dictionary = SPACE_GUIDANCE_RESOLVER.resolve(flight.get_snapshot(), goal, hull, power)
	if not validation.get("ok", false): return validation
	_space_combat_state.set_flight_control(craft_id, {"goal":goal, "hull":hull, "power":power})
	return {"ok":true}

func _advance_space_flights(delta: float, tick: int) -> void:
	_space_combat_state.advance_ship_systems(delta)
	var controls: Dictionary = _space_combat_state.get_flight_controls()
	var ids: Array = controls.keys()
	ids.sort()
	var groups := {}
	for craft_id in ids:
		var flight: RefCounted = _space_combat_state.get_actor(craft_id)
		var control: Dictionary = controls[craft_id]
		if flight == null or flight.get_snapshot().motion_mode != "tactical":
			if control.get("singleplayer_move", false) or control.get("air_support_move", false): _space_combat_state.clear_flight_control(craft_id)
			continue
		# A synchronous area admission can publish at this same root tick just
		# before the flight phase. Keep the command for the next newer tick.
		if int(flight.get_snapshot().get("tick", -1)) >= tick: continue
		if control.get("air_support_move", false):
			var mission: Node = control.mission_root.get_ref() if control.get("mission_root") is WeakRef else null
			if not is_instance_valid(mission) or not mission._air_support_motion_context_valid(craft_id, self, control.equipment_snapshot):
				_space_combat_state.clear_flight_control(craft_id)
				_space_combat_state.set_flight_status(craft_id, {"ok":false, "reason":"movement_context_changed"})
				continue
			var air_pose: Dictionary = flight.get_snapshot()
			if air_pose.position_plane.distance_to(control.goal.target_plane) < 0.02 and air_pose.velocity_plane.length() < 0.02:
				_space_combat_state.clear_flight_control(craft_id)
				_space_combat_state.set_flight_status(craft_id, {"ok":true, "reason":"arrived"})
				continue
		if control.get("singleplayer_move", false):
			var pose: Dictionary = flight.get_snapshot()
			var live_equipment: Dictionary = _ship_equipment_owner.get_snapshot(craft_id) if _ship_equipment_owner != null else {}
			if _singleplayer_space_travel_owner == null or _singleplayer_space_travel_owner.get_flight_state(craft_id) != flight or _singleplayer_space_travel_owner.get_craft_snapshot(craft_id).get("phase") != "orbit" or not is_instance_valid(_base_personnel_owner) or not _base_personnel_owner.is_pilot_aboard(craft_id) or _space_wing_state.get_craft_wing(craft_id, "singleplayer").is_empty() or pose.space_area_id != control.area_id or _ship_equipment_owner == null or _ship_equipment_owner.get_instance_id() != control.equipment_owner_id or live_equipment != control.equipment_snapshot:
				_space_combat_state.clear_flight_control(craft_id)
				_space_combat_state.set_flight_status(craft_id, {"ok":false, "reason":"movement_context_changed"})
				continue
			if control.get("orbit_auto_transit", false) and tick % 5 == 0:
				var radar: Dictionary = get_space_radar_contacts(craft_id)
				if not radar.get("ok", false) or not Array(radar.get("contacts", [])).is_empty():
					control["goal"] = {"target_plane":pose.position_plane}
					control["orbit_auto_transit"] = false
					control["orbit_auto_braking"] = true
					_space_combat_state.release_navigation_claim(craft_id)
					_space_combat_state.set_flight_control(craft_id, control)
			if pose.position_plane.distance_to(control.goal.target_plane) < 0.02 and pose.velocity_plane.length() < 0.02:
				_space_combat_state.clear_flight_control(craft_id)
				_space_combat_state.set_flight_status(craft_id, {"ok":not control.get("orbit_auto_braking", false), "reason":"interrupted" if control.get("orbit_auto_braking", false) else "arrived"})
				continue
		var intent: Dictionary = control.get("intent", {})
		if control.has("goal"):
			var guidance: Dictionary = SPACE_GUIDANCE_RESOLVER.resolve(flight.get_snapshot(), control.goal, control.hull, control.power)
			if not guidance.get("ok", false):
				_space_combat_state.set_flight_status(craft_id, guidance)
				continue
			intent = guidance.intent
			if control.get("air_support_move", false): intent["assist_mode"] = "coupled"
		var current_pose: Dictionary = flight.get_snapshot()
		var environment := "atmosphere" if String(current_pose.get("space_area_id", "")).begins_with("atmosphere:") else "space"
		var proposal: Dictionary = SPACE_FLIGHT_RESOLVER.step(current_pose, intent, control.hull, control.power, delta, environment)
		if not proposal.get("ok", false):
			_space_combat_state.set_flight_status(craft_id, proposal)
			continue
		proposal["craft_id"] = craft_id
		var snapshot: Dictionary = flight.get_snapshot()
		var key := var_to_str([snapshot.coordinate_frame, snapshot.space_area_id])
		if not groups.has(key):
			groups[key] = {"world":{"coordinate_frame":snapshot.coordinate_frame, "space_area_id":snapshot.space_area_id}, "proposals":[]}
		groups[key].proposals.append(proposal)
	var group_ids: Array = groups.keys()
	group_ids.sort()
	for key in group_ids:
		var group: Dictionary = groups[key]
		var proposals: Array[Dictionary] = []
		proposals.assign(group.proposals)
		var result: Dictionary = commit_space_fleet_motion(proposals, tick, group.world, {"runtime_authorized":true, "fixture":true, "internal_flight_tick":self})
		if not result.get("ok", false):
			for proposal in proposals:
				if Dictionary(controls.get(proposal.craft_id, {})).get("singleplayer_move", false) or Dictionary(controls.get(proposal.craft_id, {})).get("air_support_move", false): _space_combat_state.clear_flight_control(proposal.craft_id)
				_space_combat_state.set_flight_status(proposal.craft_id, result)
			continue
		for craft_id in result.accepted:
			_space_combat_state.set_flight_status(craft_id, {"ok":true, "reason":""})
		for craft_id in result.rejected:
			if Dictionary(controls.get(craft_id, {})).get("singleplayer_move", false) or Dictionary(controls.get(craft_id, {})).get("air_support_move", false): _space_combat_state.clear_flight_control(craft_id)
			_space_combat_state.set_flight_status(craft_id, {"ok":false, "reason":result.rejected[craft_id]})

func enter_space_tactical(craft_id: String, tick: int, authority_context: Dictionary) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if authority_context.get("runtime_authorized") != true:
		return {"ok": false, "reason": "runtime_authority_required"}
	var flight: RefCounted = _space_combat_state.get_actor(craft_id)
	if flight == null:
		return {"ok": false, "reason": "unknown_actor"}
	var snapshot: Dictionary = flight.get_snapshot()
	if snapshot.motion_mode == "tactical":
		return {"ok": false, "reason": "already_tactical"}
	var metadata: Dictionary = _space_combat_state.get_metadata(craft_id)
	if metadata.get("control_domain") == "player" and (_singleplayer_space_travel_owner == null or String(_singleplayer_space_travel_owner.get_snapshot(craft_id).get("phase", "")) not in ["orbit", "stopped"]):
		return {"ok": false, "reason": "travel_active"}
	return flight.commit_motion({"expected_revision":snapshot.revision, "motion_mode":"tactical"}, tick)

func commit_space_actor_motion(craft_id: String, proposal: Dictionary, tick: int, authority_context: Dictionary) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if authority_context.get("runtime_authorized") != true:
		return {"ok": false, "reason": "runtime_authority_required"}
	var flight: RefCounted = _space_combat_state.get_actor(craft_id)
	if flight == null:
		return {"ok": false, "reason": "unknown_actor"}
	if flight.get_snapshot().get("coordinate_frame", "strategic") != "strategic":
		return {"ok":false, "reason":"local_area_not_ready"}
	if String(flight.get_snapshot().motion_mode) != "tactical":
		return {"ok": false, "reason": "not_tactical"}
	if proposal.get("motion_mode", "tactical") != "tactical":
		return {"ok": false, "reason": "invalid_motion_mode"}
	var position: Variant = proposal.get("position_plane")
	if typeof(position) != TYPE_VECTOR2 or not position.is_finite():
		return {"ok": false, "reason": "invalid_position"}
	var cell: Vector2i = SPACE_GRID.cell_at(position / SPACE_GRID.EXTENT)
	if not SPACE_GRID.contains(cell):
		return {"ok": false, "reason": "invalid_actor_cell"}
	var validation: Dictionary = flight.validate_motion(proposal, tick)
	if not validation.get("ok", false):
		return validation
	var cells: Array[Vector2i] = _space_combat_state.preview_actor_cells(craft_id, proposal)
	if cells.is_empty():
		return {"ok": false, "reason": "invalid_footprint"}
	for occupant in _space_combat_state.query_cells(cells):
		if occupant != craft_id:
			return {"ok": false, "reason": "occupied"}
	var metadata: Dictionary = _space_combat_state.get_metadata(craft_id)
	var actor: Dictionary = flight.get_snapshot()
	actor["footprint_hexes"] = metadata.footprint_hexes
	var move: Dictionary = proposal.duplicate(true)
	move["craft_id"] = craft_id
	var clearance: Dictionary = SPACE_NAVIGATION.preview_swept_cells(actor, move)
	if not clearance.get("ok", false):
		return {"ok": false, "reason": String(clearance.get("reason", "invalid_sweep"))}
	var swept_cells: Array[Vector2i] = []
	swept_cells.assign(clearance.cells)
	for occupant in _space_combat_state.query_cells(swept_cells):
		if occupant != craft_id:
			return {"ok": false, "reason": "blocked"}
	for claimant in _space_combat_state.query_navigation_claims(swept_cells, ""):
		if claimant != craft_id: return {"ok":false, "reason":"navigation_claimed"}
	var result: Dictionary = flight.commit_motion(proposal, tick)
	if not result.get("ok", false):
		return result
	_space_combat_state.update_actor_cell(craft_id, cell)
	return result

func commit_space_fleet_motion(proposals: Array[Dictionary], tick: int, world: Dictionary, authority_context: Dictionary) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if authority_context.get("runtime_authorized") != true:
		return {"ok": false, "reason": "runtime_authority_required"}
	if proposals.is_empty():
		return {"ok": false, "reason": "empty_batch"}
	var area := {"coordinate_frame":world.get("coordinate_frame", "strategic"), "space_area_id":world.get("space_area_id", "")}
	if not SPACE_AREA_GRID.contains(Vector2i.ZERO, area): return {"ok":false, "reason":"invalid_area"}
	var actors: Array[Dictionary] = []
	for snapshot in _space_combat_state.get_area_flight_snapshots(String(area.space_area_id)):
		if snapshot.motion_mode == "tactical" and snapshot.get("coordinate_frame", "strategic") == area.coordinate_frame and snapshot.get("space_area_id", "") == area.space_area_id:
			actors.append(snapshot)
	var seen := {}
	for proposal in proposals:
		var id: Variant = proposal.get("craft_id")
		if typeof(id) != TYPE_STRING or String(id).is_empty() or seen.has(id):
			return {"ok": false, "reason": "invalid_actor"}
		seen[id] = true
		var flight: RefCounted = _space_combat_state.get_actor(id)
		if flight == null or flight.get_snapshot().motion_mode != "tactical":
			return {"ok": false, "reason": "not_tactical"}
		var snapshot: Dictionary = flight.get_snapshot()
		if snapshot.coordinate_frame != area.coordinate_frame or snapshot.space_area_id != area.space_area_id:
			return {"ok":false, "reason":"area_mismatch"}
		if String(snapshot.space_area_id).begins_with("atmosphere:") and proposal.get("assist_mode", snapshot.assist_mode) != "coupled": return {"ok":false, "reason":"atmosphere_requires_coupled"}
		if area.coordinate_frame == "local" and (authority_context.get("fixture") != true or not String(id).begins_with("space_fixture_")):
			var own_control: Dictionary = _space_combat_state.get_flight_controls().get(id, {})
			if authority_context.get("internal_flight_tick") != self or not (own_control.get("singleplayer_move", false) or own_control.get("air_support_move", false)): return {"ok":false, "reason":"local_area_not_ready"}
		if proposal.get("motion_mode", "tactical") != "tactical":
			return {"ok": false, "reason": "invalid_motion_mode"}
		var valid: Dictionary = flight.validate_motion(proposal, tick)
		if not valid.get("ok", false): return valid
		if _space_combat_state.preview_actor_cells(id, proposal).is_empty():
			return {"ok": false, "reason": "invalid_footprint"}
	var navigation_world: Dictionary = world.duplicate(true)
	if area.coordinate_frame == "local":
		var local_id := String(area.space_area_id)
		if not local_id.begins_with("orbit_approach:") and not local_id.begins_with("atmosphere:"): return {"ok":false, "reason":"invalid_area"}
		if local_id.begins_with("orbit_approach:") and not _fixture_area_blockers.has(local_id):
			var body_id := local_id.trim_prefix("orbit_approach:").uri_decode()
			var layout: Dictionary = ORBIT_LAYOUT.build(body_id)
			if not layout.get("ok", false) or layout.body_map_id != local_id: return {"ok":false, "reason":"invalid_area"}
			var body_cells: Array[Vector2i] = []
			for offset in layout.body_cells: body_cells.append(SPACE_GRID.from_offset(offset))
			_fixture_area_blockers[local_id] = body_cells
		if typeof(navigation_world.get("blocked_cells", [])) != TYPE_ARRAY: return {"ok":false, "reason":"invalid_world"}
		var blockers: Array = navigation_world.get("blocked_cells", []).duplicate()
		if local_id.begins_with("orbit_approach:"): blockers.append_array(_fixture_area_blockers[local_id])
		navigation_world["blocked_cells"] = blockers
	var clearance: Dictionary = SPACE_NAVIGATION.resolve_motion(actors, proposals, navigation_world)
	if not clearance.get("ok", false): return clearance
	var accepted: Dictionary = clearance.accepted
	var ids: Array = accepted.keys()
	ids.sort()
	for id in ids:
		var swept_cells: Array[Vector2i] = []
		swept_cells.assign(clearance.swept_cells[id])
		if String(area.space_area_id).begins_with("atmosphere:"):
			var control: Dictionary = _space_combat_state.get_flight_controls().get(id, {})
			var mission: Node = control.mission_root.get_ref() if control.get("mission_root") is WeakRef else null
			if not control.get("air_support_move", false) or not is_instance_valid(mission) or not mission._air_support_cells_on_map(swept_cells):
				clearance.rejected[id] = "map_edge"
				accepted.erase(id)
				continue
		for claimant in _space_combat_state.query_navigation_claims(swept_cells, String(area.space_area_id)):
			if claimant != id:
				clearance.rejected[id] = "navigation_claimed"
				accepted.erase(id)
				break
	ids = accepted.keys()
	ids.sort()
	for id in ids:
		var cells: Array[Vector2i] = _space_combat_state.preview_actor_cells(id, accepted[id])
		for occupant in _space_combat_state.query_cells(cells, String(area.space_area_id)):
			if occupant != id:
				return {"ok": false, "reason": "occupied"}
	for id in ids:
		var flight: RefCounted = _space_combat_state.get_actor(id)
		var result: Dictionary = flight.commit_motion(accepted[id], tick)
		assert(result.get("ok", false))
		var cell: Vector2i = SPACE_GRID.cell_at(Vector2(flight.get_snapshot().position_plane) / SPACE_GRID.EXTENT)
		var indexed: bool = _space_combat_state.update_actor_cell(id, cell)
		assert(indexed)
	return {"ok": true, "accepted": ids, "rejected": clearance.rejected}

func configure_space_runtime_tick(callback: Callable) -> void:
	_space_runtime_tick = callback
	set_physics_process(callback.is_valid())

func configure_space_encounter(owner: RefCounted) -> void:
	_space_encounter_owner = owner

func request_singleplayer_command(command: Dictionary, authority_context: Dictionary = {}) -> Dictionary:
	if command.get("contract_category") == "space_combat" and _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	# Only the owning runtime adapter supplies authority_context. UI payload is
	# never interpreted as runtime evidence, service location or departure proof.
	var owner: RefCounted
	match String(command.get("contract_category", "")):
		"space_combat":
			owner = _space_wing_state
		"campaign_space":
			owner = _space_encounter_owner
		"singleplayer_campaign":
			owner = _singleplayer_campaign_owner
		"singleplayer_supply":
			owner = _singleplayer_supply_owner
		"campaign_onboarding":
			owner = _campaign_onboarding_owner
		"singleplayer_space_travel":
			owner = _singleplayer_space_travel_owner
		_:
			return {"ok": false, "reason": "unknown_singleplayer_contract"}
	if owner == null:
		return {"ok": false, "reason": "singleplayer_owner_unavailable"}
	var context: Dictionary = authority_context.duplicate(true)
	# These capabilities and the travel effect come only from the bound owner.
	# A UI payload or stale adapter projection cannot supply installed parts.
	context.erase("prepare_ship_component_install")
	context.erase("commit_ship_component_install")
	context.erase("repair_callback")
	if command.get("contract_category")=="singleplayer_supply" and command.get("operation")=="repair":
		context["repair_callback"]=Callable(self,"_repair_ground_ship_at_service")
	if String(command.get("contract_category", "")) == "singleplayer_supply" and String(command.get("operation", "")) == "station_install_ship_component":
		if _ship_equipment_owner == null:
			return {"ok": false, "reason": "ship_equipment_unavailable", "message": "Warp-Werkstatt nicht verfuegbar"}
		context["prepare_ship_component_install"] = Callable(_ship_equipment_owner, "prepare_install")
		context["commit_ship_component_install"] = Callable(_ship_equipment_owner, "commit_prepared_install")
	if String(command.get("contract_category", "")) == "singleplayer_space_travel" and String(command.get("operation", "")) == "start_quantum":
		var craft_id := String(Dictionary(command.get("payload", {})).get("craft_id", ""))
		var effect: Dictionary = _ship_equipment_owner.call("get_quantum_effect", craft_id) if _ship_equipment_owner != null else {}
		context["quantum_duration_multiplier"] = float(effect.get("quantum_duration_multiplier", 1.0))
	var equipment_commit: bool = String(command.get("contract_category", "")) == "singleplayer_supply" and String(command.get("operation", "")) == "inventory_equip"
	var unit_id: String = String(Dictionary(command.get("payload", {})).get("unit_id", ""))
	if equipment_commit:
		if not bool(_personnel_loadout_owner.call("has_unit", unit_id)):
			return {"ok": false, "reason": "inventory_access", "message": "Person ist hier nicht erreichbar"}
		context["loadout"] = _personnel_loadout_owner.call("get_loadout", unit_id)
	var result: Dictionary = owner.call("apply_command", command.duplicate(true), context)
	if equipment_commit and bool(result.get("ok", false)) and not bool(result.get("replayed", false)):
		# The Supply owner has validated the complete slot change. Publish both
		# sides synchronously before listeners can observe a committed command.
		_personnel_loadout_owner.call("set_loadout", unit_id, Dictionary(result.loadout))
	singleplayer_command_committed.emit(command.duplicate(true), result.duplicate(true))
	return result
signal damage_effect_resolved(result: Dictionary)
signal fire_rule_committed(state: Dictionary)
signal dropship_command_committed(command: Dictionary)
signal commander_intent_committed(command: Dictionary)
signal multiplayer_snapshot_applied(snapshot: Dictionary)
signal network_command_result_received(result: Dictionary)
signal network_command_accepted(command: Dictionary, peer_id: int)

const MOVE_SPEED_PER_SECOND: float = 80.0
const DAMAGE_MODEL_SCRIPT: GDScript = preload("res://scripts/core/damage_model.gd")
const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const CONTACT_PATH_RECOMPUTE_INTERVAL_MSEC: int = 600
const LOCAL_AVOIDANCE_MIN_FORWARD_PROGRESS_FACTOR: float = 0.35
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HPA_NAVIGATION_GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_pathfinder.gd")
const REGIONAL_NAVIGATION_MIN_TILES: int = 512 * 256
const REGIONAL_NAVIGATION_EXPANSIONS_PER_SLICE: int = 24
const REGIONAL_NAVIGATION_EXPANSIONS_PER_TICK: int = 96
const NATIVE_NAVIGATION_SCRIPT: GDScript = preload("res://scripts/terrain/native_navigation.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const LOCAL_AVOIDANCE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/local_avoidance_resolver.gd")
const BOTTLENECK_RESERVATION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/bottleneck_reservation_resolver.gd")
const MULTIPLAYER_COMMAND_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_command_contract.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const HEX_GROUND_RUNTIME_SCRIPT: GDScript = preload("res://scripts/core/hex_ground_runtime.gd")
const HEX_MOVEMENT_RUNTIME_SCRIPT=preload("res://scripts/core/hex_movement_command_runtime.gd")
const HEX_GRID_SCRIPT: GDScript = preload("res://scripts/terrain/hex_grid.gd")
const CAPTURE_PROGRESS_PER_TICK: float = 0.01
const HPA_NAVIGATION_CLUSTER_SIZE: int = 8
const SNAPSHOT_CHUNK_PAYLOAD_BYTES: int = 1000
const SNAPSHOT_MAX_CHUNK_COUNT: int = 256
const SNAPSHOT_MAX_RAW_BYTES: int = 8 * 1024 * 1024
const SNAPSHOT_REASSEMBLY_MAX_PENDING_TICKS: int = 32
const SNAPSHOT_REASSEMBLY_TIMEOUT_MSEC: int = 1500
const NETWORK_COMMAND_DEDUPE_MAX_IDS: int = 2048
const SNAPSHOT_COMPRESSION_MODE: int = FileAccess.COMPRESSION_ZSTD

const HIT_CHANCE_MIN: float = 0.05
const HIT_CHANCE_MAX: float = 0.95
const ATTACKER_COVER_HIT_BONUS_FACTOR: float = 0.05
const TARGET_COVER_HIT_PENALTY_FACTOR: float = 0.35
const TARGET_COVER_DAMAGE_PENALTY_FACTOR: float = 0.2
const DAMAGE_MULTIPLIER_MIN: float = 0.1
const HEIGHT_ADVANTAGE_ACCURACY_BONUS: float = 0.1
const HEIGHT_DISADVANTAGE_ACCURACY_PENALTY: float = 0.05

@export var is_server_authoritative: bool = false
@export var unit_registry_path: NodePath
@export var terrain_registry_path: NodePath
@export var audio_event_bus_path: NodePath
@export var combat_rng_seed: int = 1
@export var terrain_move_debug_enabled: bool = false
@export var navigation_budget_enabled: bool = true
@export var native_navigation_enabled: bool = true
@export_range(0, 64, 1) var navigation_max_new_path_queries_per_tick: int = 4
@export var navigation_debug_enabled: bool = false
@export_range(1, 128, 1) var navigation_debug_query_history_limit: int = 24
@export var navigation_cover_aware_enabled: bool = false
@export_range(0.0, 8.0, 0.1) var navigation_default_exposure_weight: float = 0.8
@export_range(0.0, 8.0, 0.1) var navigation_default_cover_weight: float = 0.25
@export_range(1.0, 64.0, 1.0) var navigation_exposure_max_grid_distance: float = 8.0
@export var runtime_tick_budget_debug_enabled: bool = false
@export var unit_minimum_spacing_enabled: bool = true
@export_range(8.0, 192.0, 1.0) var unit_minimum_spacing_distance: float = 36.0
@export_range(1, 8, 1) var unit_minimum_spacing_solver_iterations: int = 4
@export var unit_minimum_spacing_debug_enabled: bool = false
@export var local_avoidance_enabled: bool = false
@export var local_avoidance_debug_enabled: bool = false
@export_range(4.0, 96.0, 1.0) var local_avoidance_agent_radius: float = 18.0
@export_range(8.0, 192.0, 1.0) var local_avoidance_neighbor_radius: float = 56.0
@export_range(8.0, 192.0, 1.0) var local_avoidance_spatial_cell_size: float = 64.0
@export_range(1, 32, 1) var local_avoidance_max_neighbors: int = 8
@export_range(0.1, 5.0, 0.1) var local_avoidance_stuck_threshold_seconds: float = 1.0
@export_range(0.0, 60.0, 1.0) var local_avoidance_stuck_speed_threshold: float = 5.0
@export var bottleneck_reservation_enabled: bool = false
@export var bottleneck_reservation_debug_enabled: bool = false
@export_range(1, 64, 1) var bottleneck_reservation_horizon_ticks: int = 16

var command_queue: Array = []
var effects_queue: Array = []
var tick_counter: int = 0
var is_processing_tick: bool = false
var _last_tick_delta: float = 0.0
var _contact_path_recompute_ready_at_msec: Dictionary = {}
var _objective_status: RefCounted = null
var _terrain_pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
var _last_terrain_move_debug_by_unit_id: Dictionary = {}
var _last_discarded_move_command: Dictionary = {}
var _discarded_move_command_count: int = 0
var _discarded_move_command_counts_by_reason: Dictionary = {}
var _latest_command_token_by_unit_id: Dictionary = {}
var _committed_command_token_by_unit_id: Dictionary = {}
var _known_units_by_id: Dictionary = {}
var _peer_team_assignments: Dictionary = {1: "team_alpha"}
var _peer_role_assignments: Dictionary = {1: "commander"}
var _peer_fireteam_assignments: Dictionary = {}
var _last_network_command_rejection: Dictionary = {}
var _last_network_command_result: Dictionary = {}
var _network_command_accept_count: int = 0
var _network_command_reject_count: int = 0
var _accepted_network_dropship_command_ids: Dictionary = {}
var _accepted_network_dropship_command_id_order: Array = []
var _network_command_dedupe_hit_count: int = 0
var _network_command_preflight_validator: Callable = Callable()
var _multiplayer_snapshot_context: Dictionary = {}
var _authoritative_fire_rules_by_fireteam: Dictionary = {}
var _air_asset_status_by_id: Dictionary = {}
var _last_applied_snapshot_tick: int = -1
var _last_applied_vital_tick_by_unit_id: Dictionary = {}
var _snapshot_apply_count: int = 0
var _snapshot_out_of_order_count: int = 0
var _snapshot_missing_unit_count: int = 0
var _last_snapshot_reject_reason: String = ""
var _snapshot_audio_event_ids_played: Dictionary = {}
var _snapshot_audio_played_count: int = 0
var _snapshot_audio_suppressed_count: int = 0
var _last_snapshot_audio_result: Dictionary = {}
var _audio_event_bus = null
var _last_broadcast_vital_state_by_unit_id: Dictionary = {}
var _last_server_state: Dictionary = {}
var _incoming_snapshot_chunks_by_tick: Dictionary = {}
var _snapshot_transport_last_chunk_count: int = 0
var _snapshot_transport_last_max_chunk_payload_bytes: int = 0
var _snapshot_transport_last_raw_bytes: int = 0
var _snapshot_transport_last_wire_bytes: int = 0
var _snapshot_transport_reassembled_count: int = 0
var _snapshot_transport_reassembly_failure_count: int = 0
var _snapshot_transport_expired_tick_count: int = 0
var _snapshot_transport_evicted_tick_count: int = 0
var _snapshot_transport_stale_chunk_count: int = 0
var _snapshot_transport_next_prune_msec: int = 0
var _snapshot_transport_last_pack_usec: int = 0
var _snapshot_transport_last_reassembly_usec: int = 0
var _snapshot_broadcast_paused: bool = false
var _snapshot_blocked_peer_ids: Dictionary = {}
var _combat_rng := RandomNumberGenerator.new()
var _hpa_navigation_graph = null
var _hpa_pathfinder = HPA_PATHFINDER_SCRIPT.new()
var _native_navigation = NATIVE_NAVIGATION_SCRIPT.new()
var _navigation_backend_debug: Dictionary = {}
var _navigation_prewarm_debug: Dictionary = {}
var _hpa_navigation_registry = null
var _hpa_navigation_tile_count: int = -1
var _hpa_navigation_registry_revision: int = -1
var _hpa_navigation_build_count: int = 0
var _hpa_navigation_cache_hit_count: int = 0
var _hpa_navigation_last_build_stats: Dictionary = {}
var _navigation_new_path_queries_this_tick: int = 0
var _navigation_path_queries_this_tick: int = 0
var _regional_navigation_expansions_this_tick: int = 0
var _regional_navigation_admissions: Dictionary = {}
var _regional_navigation_last_service_tick: Dictionary = {}
var _navigation_delayed_this_tick: int = 0
var _navigation_fallback_queries_this_tick: int = 0
var _navigation_unreachable_queries_this_tick: int = 0
var _navigation_last_delay_reason: String = ""
var _navigation_last_tick_queries: Array = []
var _navigation_most_expensive_query: Dictionary = {}
var _navigation_last_path_metrics: Dictionary = {}
var _runtime_tick_budget_debug_snapshot: Dictionary = {}
var _runtime_frame_budget_debug = preload("res://scripts/core/frame_timing_accumulator.gd").new()
var _runtime_command_type_count: Dictionary = {}
var _runtime_command_type_usec: Dictionary = {}
var _runtime_command_requeue_count: Dictionary = {}
var _local_avoidance_resolver = LOCAL_AVOIDANCE_RESOLVER_SCRIPT.new()
var _bottleneck_reservation_resolver = BOTTLENECK_RESERVATION_RESOLVER_SCRIPT.new()
var _multiplayer_command_contract = MULTIPLAYER_COMMAND_CONTRACT_SCRIPT.new()
var _multiplayer_snapshot_contract = MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new()
var _unit_minimum_spacing_debug_snapshot: Dictionary = {}
var _local_avoidance_prepared_tick: int = -1
var _local_avoidance_debug_by_unit_id: Dictionary = {}
var _local_avoidance_stuck_seconds_by_unit_id: Dictionary = {}
var _bottleneck_reservation_debug_snapshot: Dictionary = {}
var _last_damage_effect_resolution: Dictionary = {}
var _hex_ground_runtime = HEX_GROUND_RUNTIME_SCRIPT.new()
var _air_ground_impact_receipts: Dictionary = {}
var _hex_ground_registry: Node
var _hex_ground_enabled := false
var _hex_ground_context_revision := 0
const HEX_FACING_PRIORITIES := {"noise_reaction":10,"combat_reaction":20,"security_assignment":30,"movement":40}
const HEX_FACING_REPLAY_CAPACITY := 4096
var _hex_facing_pending: Dictionary = {}
var _hex_facing_seen: Dictionary = {}
var _hex_facing_replay_keys: Array[String] = []
var _hex_facing_replay_cursor := 0
var _last_hex_ground_events: Array[Dictionary] = []
var _hex_movement_runtime=HEX_MOVEMENT_RUNTIME_SCRIPT.new()
var _hex_visual_unit_ids:Dictionary={}
var _hex_projection_terrain_revision:=-1
var _hex_boundary_facing:Dictionary={}
const HEX_ADMISSION_SCRIPT=preload("res://scripts/mission/hex_ground_admission.gd")
var _hex_deployment_serial:=0
var _last_hex_lifecycle_resolution:Dictionary={}
var _hex_unit_lifecycle_revision:Dictionary={}
var _hex_respawn_records:Dictionary={}
var _hex_respawn_sequence:=0


## Called by the owning map runtime, never interpreted from a UI/network payload.
## Validate before replacing the current context, so failed loads preserve it.
static func validate_hex_ground_map_data(map_data:RefCounted)->Dictionary:
	if map_data == null or not map_data.has_method("get_tactical_grid_rules") or not map_data.has_method("get_grid_topology") or not map_data.has_method("has_load_issue"):
		return {"ok": false, "reason": "invalid_map_data"}
	if bool(map_data.call("has_load_issue")):
		return {"ok": false, "reason": "map_load_issue"}
	if not map_data.has_method("get_map_name") or not map_data.has_method("get_grid_size"):
		return {"ok": false, "reason": "invalid_map_context"}
	var map_size: Variant = map_data.call("get_grid_size")
	if String(map_data.call("get_map_name")).strip_edges().is_empty() or typeof(map_size) != TYPE_VECTOR2I or map_size.x <= 0 or map_size.y <= 0:
		return {"ok": false, "reason": "invalid_map_context"}
	var rules:String=String(map_data.call("get_tactical_grid_rules"))
	if not rules.is_empty() and (rules!="hex_tactical_v1" or String(map_data.call("get_grid_topology"))!=HEX_GROUND_RUNTIME_SCRIPT.TOPOLOGY):return {"ok":false,"reason":"unsupported_tactical_grid_rules"}
	return {"ok":true}


func configure_hex_ground_runtime(map_data: RefCounted, terrain_registry: Node) -> Dictionary:
	if _should_skip_local_tick_processing():
		return {"ok": false, "reason": "not_authority"}
	var map_context:Dictionary=validate_hex_ground_map_data(map_data)
	if not map_context.ok:return map_context
	if tick_counter<0 or tick_counter>HEX_GROUND_RUNTIME_SCRIPT.MAX_TICK:return {"ok":false,"reason":"invalid_map_context"}
	if not is_instance_valid(terrain_registry) or not terrain_registry.has_method("get_grid_topology") or String(terrain_registry.call("get_grid_topology")) != String(map_data.call("get_grid_topology")):
		return {"ok": false, "reason": "invalid_terrain_registry"}
	var rules := String(map_data.call("get_tactical_grid_rules"))
	if rules.is_empty():
		_clear_hex_movement_context()
		_hex_ground_runtime.clear()
		_hex_ground_registry = null
		_hex_ground_enabled = false
		_hex_ground_context_revision += 1
		_hex_facing_pending.clear()
		_hex_facing_seen.clear()
		_hex_facing_replay_keys.clear()
		_hex_facing_replay_cursor = 0
		_last_hex_ground_events.clear()
		return {"ok": true, "enabled": false}
	if rules != "hex_tactical_v1" or String(map_data.call("get_grid_topology")) != HEX_GROUND_RUNTIME_SCRIPT.TOPOLOGY:
		return {"ok": false, "reason": "unsupported_tactical_grid_rules"}
	if not is_instance_valid(terrain_registry) or not terrain_registry.has_method("get_grid_topology") or String(terrain_registry.call("get_grid_topology")) != HEX_GROUND_RUNTIME_SCRIPT.TOPOLOGY:
		return {"ok": false, "reason": "invalid_hex_registry"}
	for method in ["is_walkable","get_stand_height_at","grid_to_world","world_to_grid_float","get_movement_distance","get_cover_at","get_tile_at_grid"]:
		if not terrain_registry.has_method(method):
			return {"ok": false, "reason": "invalid_hex_registry"}
	_clear_hex_movement_context()
	_hex_ground_runtime.configure(terrain_registry, String(map_data.call("get_map_name")), tick_counter)
	_hex_ground_registry = terrain_registry
	_hex_ground_enabled = true
	_hex_ground_context_revision += 1
	_hex_facing_pending.clear()
	_hex_facing_seen.clear()
	_hex_facing_replay_keys.clear()
	_hex_facing_replay_cursor = 0
	_last_hex_ground_events.clear()
	_hex_movement_runtime.configure(self,terrain_registry,_hex_ground_runtime)
	return {"ok": true, "enabled": true}


func _clear_hex_movement_context() -> void:
	_air_ground_impact_receipts.clear()
	for id in _hex_ground_runtime.get_unit_ids():_clear_hex_actor_metadata(String(id))
	_hex_movement_runtime.clear()
	_hex_visual_unit_ids.clear()
	_hex_boundary_facing.clear()
	_hex_projection_terrain_revision=-1
	_hex_unit_lifecycle_revision.clear()
	_last_hex_lifecycle_resolution.clear()


func _clear_hex_actor_metadata(unit_id:String) -> void:
	var actor=_resolve_known_unit_for_contract(unit_id)
	if not is_instance_valid(actor):return
	for key in ["hex_ground_stand_height_logical","hex_ground_moving","hex_ground_facing_angle","hex_ground_surface_segment"]:
		if actor.has_meta(key):actor.remove_meta(key)


func get_hex_movement_readout(unit_id:String) -> Dictionary:
	return _hex_movement_runtime.get_readout(unit_id) if is_hex_ground_runtime_active() else {}

func _commit_air_ground_impact(event: Dictionary) -> Dictionary:
	# Root-private tail: a future air-fire coordinator must first validate the
	# real craft, pilot, order, visibility, weapon and seeded dispersion. Never
	# forward an event from a client or a visual directly to this method.
	if _should_skip_local_tick_processing() or _air_ground_registry() == null: return {"ok":false, "reason":"ground_unavailable"}
	if event.size() != 5 or typeof(event.get("event_id")) != TYPE_STRING or String(event.event_id).strip_edges().is_empty() or typeof(event.get("impact_hex")) != TYPE_VECTOR2I or typeof(event.get("pilot_id")) != TYPE_STRING or String(event.pilot_id).strip_edges().is_empty() or typeof(event.get("team_id")) != TYPE_STRING or String(event.team_id).strip_edges().is_empty() or typeof(event.get("damage")) != TYPE_INT or int(event.damage) <= 0: return {"ok":false, "reason":"invalid_impact"}
	var signature := var_to_str(event)
	var id: String = event.event_id
	if _air_ground_impact_receipts.has(id):
		var previous: Dictionary = _air_ground_impact_receipts[id]
		if previous.signature != signature: return {"ok":false, "reason":"event_id_conflict"}
		var replay: Dictionary = previous.result.duplicate(true); replay["replayed"] = true; return replay
	if _air_ground_impact_receipts.size() >= 4096: return {"ok":false, "reason":"receipt_capacity"}
	var lookup: Dictionary = _air_ground_occupant(event.impact_hex)
	if not lookup.get("ok", false): return lookup
	var target_id: String = lookup.unit_id
	if not target_id.is_empty():
		var target = _resolve_unit(target_id)
		if not is_instance_valid(target) or not target.has_method("apply_damage") or _air_ground_unit_grid(target_id) != event.impact_hex: return {"ok":false, "reason":"ground_actor_unavailable"}
	var result := {"ok":true, "replayed":false, "impact_hex":event.impact_hex, "unit_id":target_id}
	# Store first: damage-resolution signals may re-enter the Root.
	_air_ground_impact_receipts[id] = {"signature":signature, "result":result.duplicate(true)}
	if not target_id.is_empty():
		_apply_damage_effect({"effect_type":"damage", "unit_id":target_id, "attacker_unit_id":event.pilot_id, "attacker_team_id":event.team_id, "allow_friendly_fire":true, "damage":event.damage, "hit_chance":1.0, "roll_override":0.0})
	return result


func get_hex_movement_audit_snapshot() -> Dictionary:
	return _hex_movement_runtime.get_audit() if is_hex_ground_runtime_active() else {}


func has_hex_destination_arrived(unit_id:String,command_id:String) -> bool:
	return is_hex_ground_runtime_active() and _hex_movement_runtime.has_arrived(unit_id,command_id)


func get_hex_logical_unit_position(unit_id:String) -> Variant:
	var state:Dictionary=get_hex_unit_state(unit_id)
	return _hex_ground_registry.call("grid_to_world",state.grid) if not state.is_empty() else null


func has_hex_position_arrived(unit_id:String,target_position:Vector2,command_id:String) -> bool:
	if not is_hex_ground_runtime_active() or not target_position.is_finite() or command_id.is_empty():return false
	var state:Dictionary=get_hex_unit_state(unit_id)
	if state.is_empty() or state.movement_state.moving or state.route_state.has_commitments:return false
	var target_grid:Vector2i=_hex_ground_registry.call("world_to_grid",target_position)
	if state.grid!=target_grid:return false
	var order:Dictionary=get_hex_movement_readout(unit_id)
	if not order.is_empty() and order.goal_grid==target_grid and has_hex_destination_arrived(unit_id,command_id):return true
	# Covering members receive an explicit Hold for this stage, not a Move goal.
	var actor=_resolve_known_unit_for_contract(unit_id)
	if not is_instance_valid(actor) or not actor.has_method("get_current_unit_command"):return false
	var command=actor.call("get_current_unit_command")
	if command==null or String(command.command_type)!="hold_position" or String(command.command_token)!=command_id:return false
	var command_target:Variant=command.target_position
	return typeof(command_target)==TYPE_VECTOR2 and Vector2(command_target).is_finite() and _hex_ground_registry.call("world_to_grid",Vector2(command_target))==target_grid


func _commit_hex_movement_facing(unit_id:String,direction:int) -> void:
	if direction<0 or direction>5 or not is_hex_ground_runtime_active():return
	_hex_ground_runtime.commit_facing(unit_id,direction)
	_hex_boundary_facing[unit_id]=true


func _project_hex_ground_actors(fraction:float) -> void:
	if not is_hex_ground_runtime_active():return
	for id in _hex_visual_unit_ids.keys():
		var actor=_resolve_known_unit_for_contract(id)
		if not is_instance_valid(actor) or not actor is Node2D or not _hex_ground_runtime.has_unit(id):
			_hex_visual_unit_ids.erase(id)
			continue
		var projection:Dictionary=get_hex_motion_projection(id,fraction)
		if projection.is_empty():continue
		(actor as Node2D).global_position=projection.position_world
		actor.set_meta("facing_angle",projection.facing_angle)
		actor.set_meta("map_facing_angle",projection.facing_angle)
		actor.set_meta("hex_ground_stand_height_logical",projection.stand_height_logical)
		actor.set_meta("hex_ground_moving",projection.moving)
		actor.set_meta("hex_ground_facing_angle",projection.facing_angle)
		actor.set_meta("hex_ground_surface_segment",projection.surface_segment)
		if not _hex_ground_runtime.has_motion_commitments(id):_hex_visual_unit_ids.erase(id)


func is_hex_ground_runtime_active() -> bool:
	return _hex_ground_enabled and is_instance_valid(_hex_ground_registry)


func is_hex_ground_runtime_required()->bool:
	return _hex_ground_enabled


func get_hex_ground_terrain_registry() -> Node:
	return _hex_ground_registry if is_hex_ground_runtime_active() else null


func get_hex_ground_context_revision() -> int:
	return _hex_ground_context_revision


func get_hex_combat_geometry(attacker_id: String, target_id: String) -> Dictionary:
	if not is_hex_ground_runtime_active():
		return {"handled":false}
	var source := get_hex_unit_state(attacker_id)
	var destination := get_hex_unit_state(target_id)
	if source.is_empty() or destination.is_empty():
		return {"handled":true,"valid":false,"distance_world":-1.0,"target_cover_score":-1}
	var origin: Vector2 = _hex_ground_registry.call("grid_to_world",Vector2i.ZERO)
	var neighbor: Vector2 = _hex_ground_registry.call("grid_to_world",Vector2i(1,0))
	var spacing: float = _hex_ground_registry.call("get_movement_distance",origin,neighbor)
	var target = _resolve_known_unit_for_contract(target_id)
	return {"handled":true,"valid":true,
		"distance_world":float(HEX_GRID_SCRIPT.distance(source.grid,destination.grid))*spacing,
		"target_cover_score":roundi(_extract_effective_cover_score(target))}


func get_hex_unit_state(unit_id: String) -> Dictionary:
	return _hex_ground_runtime.read_unit(unit_id) if is_hex_ground_runtime_active() else {}


## Read-only lifetime of an admitted actor; never an admission or command token.
func get_hex_actor_execution_binding(unit_id:String)->Dictionary:
	if not is_hex_ground_runtime_active() or not _hex_ground_runtime.has_unit(unit_id):return {}
	var actor=_known_units_by_id.get(unit_id,null)
	var registry=get_unit_registry()
	if not is_instance_valid(actor) or actor.is_queued_for_deletion() or not actor.is_inside_tree():return {}
	if registry==null or not registry.has_method("get_unit") or registry.call("get_unit",unit_id)!=actor:return {}
	if not actor.has_method("get_unit_id") or String(actor.call("get_unit_id"))!=unit_id or bool(actor.get_meta("dropship_embarked",false)):return {}
	var result:Dictionary=_hex_payload_identity(unit_id)
	result["root_id"]=get_instance_id()
	return result


var _hex_checkpoint_transaction:RefCounted

func _get_hex_checkpoint_transaction()->RefCounted:
	if _hex_checkpoint_transaction==null:_hex_checkpoint_transaction=preload("res://scripts/core/hex_checkpoint_transaction.gd").new(self)
	return _hex_checkpoint_transaction

func get_hex_checkpoint_guard()->Dictionary:
	return _get_hex_checkpoint_transaction().guard()

func export_hex_checkpoint_state()->Dictionary:
	return _get_hex_checkpoint_transaction().export_state()

func prepare_hex_checkpoint_restore(state:Dictionary, actor_checkpoint:Dictionary={})->Dictionary:
	return _get_hex_checkpoint_transaction().prepare(state, actor_checkpoint)

func validate_prepared_hex_checkpoint_restore(prepared:RefCounted)->Dictionary:
	return _get_hex_checkpoint_transaction().validate(prepared)

func commit_hex_checkpoint_restore(prepared:RefCounted,publish:bool=true)->Dictionary:
	var result:Dictionary=_get_hex_checkpoint_transaction().commit(prepared,publish)
	if publish:_prewarm_finalized_hex_checkpoint(result)
	return result

func finalize_hex_checkpoint_restore(prepared:RefCounted)->Dictionary:
	var result:Dictionary=_get_hex_checkpoint_transaction().finalize(prepared)
	_prewarm_finalized_hex_checkpoint(result)
	return result

func _prewarm_finalized_hex_checkpoint(result:Dictionary)->void:
	# Restore publishes terrain overrides. Refresh derived navigation only after
	# all owners and callbacks have finalized, never inside the atomic publish.
	if result.get("ok",false) and result.get("committed",false) and not result.get("context_changed",false) and not result.get("replayed",false) and is_hex_ground_runtime_active():
		prewarm_navigation(get_hex_ground_terrain_registry())

func restore_hex_checkpoint_state(state:Dictionary)->Dictionary:
	var prepared:Dictionary=prepare_hex_checkpoint_restore(state)
	return commit_hex_checkpoint_restore(prepared.prepared) if prepared.get("ok",false) else prepared


## Setup owns requested selection; Root commits exact actor/index lifetimes.
func commit_hex_actor_identity_changes(requester:Node,changes:Array[Dictionary],presentation_only:bool=false)->Dictionary:
	if presentation_only:
		if not _should_skip_local_tick_processing() or is_hex_ground_runtime_active():return {"ok":false,"reason":"invalid_presentation_owner"}
	elif _should_skip_local_tick_processing() or not is_hex_ground_runtime_active():return {"ok":false,"reason":"hex_identity_owner_inactive"}
	var scope:Node=get_parent()
	var registry=get_unit_registry()
	if scope==null or scope==get_tree().root or not is_instance_valid(requester) or not scope.is_ancestor_of(requester) or not requester.has_method("_get_simulation_root") or requester.call("_get_simulation_root")!=self:return {"ok":false,"reason":"invalid_identity_requester"}
	if registry==null or not scope.is_ancestor_of(registry) or not registry.has_method("apply_lookup_bindings") or not registry.has_method("get_unit") or changes.size()>64:return {"ok":false,"reason":"identity_registry_unavailable"}
	var actors:Dictionary={}
	var targets:Dictionary={}
	var operations:Dictionary={}
	var validations:Array[Dictionary]=[]
	for change in changes:
		var actor:Variant=change.get("actor")
		var old_id:String=String(change.get("old_id",""))
		var next_id:String=String(change.get("next_id",""))
		if not is_instance_valid(actor) or not actor is Node2D or actor.is_queued_for_deletion() or not scope.is_ancestor_of(actor) or actors.has(actor.get_instance_id()) or old_id.is_empty() or next_id.is_empty() or targets.has(next_id):return {"ok":false,"reason":"invalid_identity_group"}
		if not actor.has_method("get_unit_id") or String(actor.call("get_unit_id"))!=old_id or not actor.has_method("validate_runtime_identity_change"):return {"ok":false,"reason":"identity_actor_mismatch"}
		var known:Variant=_known_units_by_id.get(old_id)
		var registered:Variant=registry.get_unit(old_id)
		if (known!=null and known!=actor) or (registered!=null and registered!=actor) or (is_hex_ground_runtime_active() and _hex_ground_runtime.has_unit(old_id) and known!=actor):return {"ok":false,"reason":"identity_source_conflict"}
		var checked:Dictionary=actor.call("validate_runtime_identity_change",change.get("prepared"))
		if not checked.get("ok",false):return checked
		if checked.get("owner_id",0)!=get_instance_id() or checked.get("unit_id","")!=next_id or checked.get("reset",false)!=bool(change.get("reset",false)):return {"ok":false,"reason":"identity_prepared_mismatch"}
		validations.append(checked)
		actors[actor.get_instance_id()]=true;targets[next_id]=true
		if not bool(change.get("reset",false)):
			if old_id!=next_id:return {"ok":false,"reason":"identity_reset_required"}
			continue
		if operations.has(old_id):return {"ok":false,"reason":"identity_index_overlap"}
		operations[old_id]={"unit_id":old_id,"expected":registered,"next":null}
		if next_id!=old_id:
			if _known_units_by_id.has(next_id) or registry.has_unit(next_id) or operations.has(next_id):return {"ok":false,"reason":"identity_target_conflict"}
			operations[next_id]={"unit_id":next_id,"expected":null,"next":null}
		if bool(change.get("register_new",false)):operations[next_id].next=actor
	var index_changes:Array[Dictionary]=[]
	for operation in operations.values():index_changes.append(operation)
	# Last fallible operation; this API has no callbacks and changes indexes only.
	var swapped:Dictionary=registry.call("apply_lookup_bindings",index_changes)
	if not swapped.get("ok",false):return swapped
	for change in changes:
		if bool(change.get("reset",false)):unregister_known_unit(String(change.old_id))
	for index in range(changes.size()):changes[index].actor.call("_publish_runtime_identity_change",changes[index].prepared,validations[index])
	for change in changes:
		if bool(change.get("reset",false)) and bool(change.get("known_new",false)):register_known_unit(String(change.next_id),change.actor)
	var receipt:Dictionary={"ok":true,"root_id":get_instance_id(),"registry_id":registry.get_instance_id(),"context":_hex_ground_context_revision,"actors":{},"identities":{}}
	for change in changes:
		receipt.actors[change.next_id]=change.actor.get_instance_id()
		receipt.identities[change.next_id]=_hex_payload_identity(String(change.next_id))
	return receipt


func is_hex_actor_identity_commit_current(receipt:Dictionary)->bool:
	if receipt.get("root_id",0)!=get_instance_id() or receipt.get("context",-1)!=_hex_ground_context_revision or is_queued_for_deletion():return false
	var registry=get_unit_registry()
	if not is_instance_valid(registry) or registry.get_instance_id()!=receipt.get("registry_id",0):return false
	for id in Dictionary(receipt.get("identities",{})):
		if _hex_payload_identity(id)!=receipt.identities[id]:return false
		var actor:Variant=instance_from_id(int(receipt.actors[id]))
		if not is_instance_valid(actor) or actor.is_queued_for_deletion() or not actor.has_method("get_unit_id") or String(actor.call("get_unit_id"))!=id:return false
	return true


func get_hex_motion_projection(unit_id: String, interpolation_fraction: float, height_step_world: float = 1.0) -> Dictionary:
	return _hex_ground_runtime.get_motion_projection(unit_id,interpolation_fraction,height_step_world) if is_hex_ground_runtime_active() else {}


func get_hex_ground_planning_snapshot() -> Dictionary:
	if not is_hex_ground_runtime_active():
		return {}
	var snapshot: Dictionary = _hex_ground_runtime.build_planning_snapshot()
	snapshot["current_tick"] = tick_counter
	return snapshot


func commit_hex_ground_plan(plan: Dictionary, expected_revision: int) -> Dictionary:
	if _should_skip_local_tick_processing():
		return {"ok":false,"reason":"not_authority"}
	if not is_hex_ground_runtime_active():
		return {"ok":false,"reason":"hex_ground_inactive"}
	if int(_hex_ground_runtime.get_current_tick()) != tick_counter:
		return {"ok":false,"reason":"hex_clock_unsynced"}
	var result:Dictionary=_hex_ground_runtime.commit_plan(plan,expected_revision)
	if result.ok:
		for segment in plan.accepted_steps:_hex_visual_unit_ids[segment.unit_id]=true
	return result


func get_hex_ground_events() -> Array[Dictionary]:
	return _last_hex_ground_events.duplicate(true)


func can_block_hex_ground_cells(grids:Array,terrain_registry:Node) -> Dictionary:
	if _should_skip_local_tick_processing():return {"ok":false,"reason":"not_authority"}
	if not is_hex_ground_runtime_active():return {"ok":false,"reason":"hex_ground_inactive"}
	if terrain_registry!=_hex_ground_registry:return {"ok":false,"reason":"wrong_hex_registry"}
	if int(_hex_ground_runtime.get_current_tick())!=tick_counter:return {"ok":false,"reason":"hex_clock_unsynced"}
	return _hex_ground_runtime.can_block_cells(grids)


func stop_hex_ground_units(unit_ids: PackedStringArray, reason: String) -> Dictionary:
	if _should_skip_local_tick_processing():return {"ok":false,"reason":"not_authority"}
	if not is_hex_ground_runtime_active():return {"ok":false,"reason":"hex_ground_inactive"}
	if int(_hex_ground_runtime.get_current_tick())!=tick_counter:return {"ok":false,"reason":"hex_clock_unsynced"}
	var result:Dictionary=_hex_ground_runtime.stop_units(unit_ids,reason)
	if result.ok:
		_hex_movement_runtime.mark_external_stop(unit_ids,reason)
		for id in result.affected_unit_ids:_hex_visual_unit_ids[id]=true
	if result.ok and not result.events.is_empty():
		_last_hex_ground_events.append_array(result.events)
		_hex_movement_runtime.notify_ground_events(result.events)
		hex_ground_events_committed.emit(result.events.duplicate(true))
	return result


func _advance_hex_ground_tick() -> void:
	_last_hex_ground_events.clear()
	if not is_hex_ground_runtime_active():return
	_last_hex_ground_events = _hex_ground_runtime.advance_tick(tick_counter)
	_hex_movement_runtime.notify_ground_events(_last_hex_ground_events)
	var revision:int=_hex_ground_registry.call("get_revision")
	if _hex_projection_terrain_revision!=revision:
		for id in _hex_ground_runtime.get_unit_ids():_hex_visual_unit_ids[id]=true
		_hex_projection_terrain_revision=revision
	if not _last_hex_ground_events.is_empty():
		hex_ground_events_committed.emit(_last_hex_ground_events.duplicate(true))


## Internal runtime admission boundary; lifecycle adapters choose placements.
func admit_hex_ground_units(placements: Array[Dictionary]) -> Dictionary:
	if _should_skip_local_tick_processing():
		return {"ok": false, "reason": "not_authority"}
	if not is_hex_ground_runtime_active():
		return {"ok": false, "reason": "hex_ground_inactive"}
	var result:Dictionary=_hex_ground_runtime.admit_units(placements)
	if result.ok:
		for id in result.admitted_unit_ids:_hex_visual_unit_ids[id]=true
		_project_hex_ground_actors(0.0)
	return result


func release_hex_ground_unit(unit_id: String, reason: String) -> void:
	if _should_skip_local_tick_processing():
		return
	if _hex_ground_runtime.has_unit(unit_id) or _hex_ground_runtime.has_pending_admission(unit_id) or _known_units_by_id.has(unit_id):
		_hex_unit_lifecycle_revision[unit_id]=int(_hex_unit_lifecycle_revision.get(unit_id,0))+1
	_clear_hex_actor_metadata(unit_id)
	_hex_visual_unit_ids.erase(unit_id)
	_hex_movement_runtime.release_unit(unit_id)
	_hex_ground_runtime.release_unit(unit_id, reason)
	_hex_facing_pending.erase(unit_id)


## Synchronous internal lifecycle boundary. These are actual registered mission
## actors, not base personnel projections or caller-supplied actor references.
func _validate_hex_ground_actor_group(unit_ids:PackedStringArray,allow_staged:bool=false)->Dictionary:
	if _should_skip_local_tick_processing():return {"ok":false,"reason":"not_authority"}
	if not is_hex_ground_runtime_active():return {"ok":false,"reason":"hex_ground_inactive"}
	if unit_ids.is_empty() or unit_ids.size()>64:return {"ok":false,"reason":"invalid_admission_group"}
	var registry=get_unit_registry()
	if registry==null or not registry.has_method("get_unit"):return {"ok":false,"reason":"unit_registry_unavailable"}
	for method in ["has_unit","register_unit"]:
		if not registry.has_method(method):return {"ok":false,"reason":"unit_registry_unavailable"}
	var scope:Node=get_parent()
	if scope==null or scope==get_tree().root or not scope.is_ancestor_of(registry):return {"ok":false,"reason":"invalid_mission_scope"}
	var actors:Dictionary={}
	for id in unit_ids:
		if id.is_empty() or id!=id.strip_edges() or actors.has(id):return {"ok":false,"reason":"invalid_admission_unit"}
		var registered=registry.call("get_unit",id)
		if registry.call("has_unit",id) and not is_instance_valid(registered):return {"ok":false,"reason":"stale_unit_registry_entry","unit_id":id}
		var actor=_resolve_known_unit_for_contract(id) if allow_staged else registered
		if is_instance_valid(registered) and registered!=actor:return {"ok":false,"reason":"mission_actor_lookup_conflict","unit_id":id}
		if not is_instance_valid(actor) or not actor is Node2D or not scope.is_ancestor_of(actor) or _resolve_known_unit_for_contract(id)!=actor:return {"ok":false,"reason":"mission_actor_unavailable","unit_id":id}
		var bound=_known_units_by_id.get(id,null)
		if not is_instance_valid(bound) or bound!=actor:return {"ok":false,"reason":"mission_actor_unbound","unit_id":id}
		if not actor.is_inside_tree() or actor.is_queued_for_deletion():return {"ok":false,"reason":"mission_actor_exiting","unit_id":id}
		if not actor.has_method("get_unit_id") or String(actor.call("get_unit_id"))!=id or not actor.has_method("assign_unit_command") or not actor.has_method("get_current_unit_command"):return {"ok":false,"reason":"invalid_mission_actor","unit_id":id}
		actors[id]=actor
	return {"ok":true,"actors":actors}


## Read-only goal planning for already admitted actors. Commands still travel
## through the normal movement owner; no placement, reservation or pose is written.
func plan_hex_ground_actor_approach(unit_ids:PackedStringArray,anchor_world:Vector2,radius:float,excluded_cells:Array[Vector2i]=[])->Dictionary:
	var checked:Dictionary=_validate_hex_ground_actor_group(unit_ids)
	if not checked.ok:return checked
	if not anchor_world.is_finite() or not is_finite(radius) or radius<=0.0 or radius>128.0:return {"ok":false,"reason":"invalid_approach_radius"}
	var snapshot:Dictionary=_hex_ground_runtime.build_planning_snapshot()
	var clearance:Dictionary=_add_base_ground_clearance(snapshot)
	if not clearance.ok:return clearance
	for id in unit_ids:
		if not snapshot.units_by_id.has(id):return {"ok":false,"reason":"approach_actor_not_admitted"}
		var grid:Vector2i=snapshot.units_by_id[id].grid
		snapshot.units_by_id.erase(id)
		if snapshot.occupant_by_grid.get(grid)==id:snapshot.occupant_by_grid.erase(grid)
	if excluded_cells.size()>64:return {"ok":false,"reason":"approach_exclusion_budget"}
	for cell in excluded_cells:snapshot.external_admission_blocked_grids[cell]=true
	var anchor:Vector2i=_hex_ground_registry.world_to_grid(anchor_world)
	var blocked:Dictionary=snapshot.external_admission_blocked_grids
	if blocked.has(anchor) or not _hex_ground_registry.is_walkable(anchor):return {"ok":false,"reason":"approach_anchor_blocked"}
	# A waiting foreign crew member can occupy the access itself. Search legal
	# neighboring anchors without erasing that actor, its reservation or any hull.
	var candidates:Array[Vector2i]=[anchor]
	var seen:Dictionary={anchor:true}
	var cursor:=0
	while cursor<candidates.size() and cursor<64:
		var cell:Vector2i=candidates[cursor];cursor+=1
		for next:Vector2i in _hex_ground_registry.get_legal_hex_neighbors(cell):
			if seen.has(next) or blocked.has(next):continue
			seen[next]=true
			if _hex_ground_registry.grid_to_world(next).distance_to(anchor_world)>radius:
				blocked[next]=true
			elif candidates.size()<64:candidates.append(next)
	var expanded:=0
	for candidate in candidates:
		if expanded>=64:break
		var plan:Dictionary=HEX_ADMISSION_SCRIPT.new().plan_group(unit_ids,candidate,_hex_ground_registry,snapshot,64-expanded)
		expanded+=int(plan.get("expanded",0))
		if not plan.ok:continue
		var targets:Dictionary={}
		for entry in plan.placements:
			var target:Vector2=_hex_ground_registry.grid_to_world(entry.grid)
			if target.distance_to(anchor_world)>radius:break
			targets[entry.unit_id]=target
		if targets.size()==unit_ids.size():return {"ok":true,"targets":targets,"expanded":expanded}
	return {"ok":false,"reason":"approach_space_unavailable","expanded":expanded}


func admit_hex_ground_actor_group(unit_ids:PackedStringArray,anchor_grid:Vector2i,excluded_cells:Array[Vector2i]=[])->Dictionary:
	var checked:Dictionary=_validate_hex_ground_actor_group(unit_ids)
	if not checked.ok:return checked
	if excluded_cells.size()>4096:return {"ok":false,"reason":"footprint_budget"}
	var snapshot:Dictionary=_hex_ground_runtime.build_planning_snapshot()
	var blocked:Dictionary={}
	for grid in excluded_cells:blocked[grid]=true
	snapshot["external_admission_blocked_grids"]=blocked
	var plan:Dictionary=HEX_ADMISSION_SCRIPT.new().plan_group(unit_ids,anchor_grid,_hex_ground_registry,snapshot)
	if not plan.ok:return plan
	var placements:Array[Dictionary]=[]
	placements.assign(plan.placements)
	var result:Dictionary=_hex_ground_runtime.admit_units(placements)
	if not result.ok:return result
	# Complete the model before publishing any transform/visibility change.
	for id in unit_ids:
		checked.actors[id].set_meta("dropship_embarked",false)
		_hex_visual_unit_ids[id]=true
	_project_hex_ground_actors(0.0)
	for id in unit_ids:checked.actors[id].visible=true
	result.placements=plan.placements
	return result


## One initial/staged group with authored per-actor anchors. Root alone owns the
## final placement; a wave owner may defer presentation until its phase commits.
func admit_hex_ground_setup_actors(candidates:Array[Dictionary],allow_staged:bool=false,publish:bool=true,excluded_cells:Array[Vector2i]=[])->Dictionary:
	var ids:=PackedStringArray()
	for entry in candidates:
		if not entry.get("unit_id") is String:return {"ok":false,"reason":"invalid_admission_unit"}
		ids.append(entry.unit_id)
		if entry.has("identity") and not _is_current_hex_payload({"unit_id":entry.unit_id,"_hex_lifecycle":entry.identity}):return {"ok":false,"reason":"stale_hex_lifecycle"}
	var checked:Dictionary=_validate_hex_ground_actor_group(ids,allow_staged)
	if not checked.ok:return checked
	if excluded_cells.size()>4096:return {"ok":false,"reason":"footprint_budget"}
	var snapshot:Dictionary=_hex_ground_runtime.build_planning_snapshot()
	var blocked:Dictionary={}
	for grid in excluded_cells:blocked[grid]=true
	snapshot["external_admission_blocked_grids"]=blocked
	var plan:Dictionary=HEX_ADMISSION_SCRIPT.new().plan_anchored_group(candidates,_hex_ground_registry,snapshot)
	if not plan.ok:return plan
	var placements:Array[Dictionary]=[]
	placements.assign(plan.placements)
	var result:Dictionary=_hex_ground_runtime.admit_units(placements)
	if not result.ok:return result
	var registry:Node=get_unit_registry()
	for id in ids:
		if not registry.has_unit(id):registry.register_unit(id,checked.actors[id])
		_hex_visual_unit_ids[id]=true
	if publish:_publish_hex_setup_actors(ids)
	result.placements=plan.placements
	return result


func _publish_hex_setup_actors(unit_ids:PackedStringArray,publication_guard:Callable=Callable())->void:
	var context:int=_hex_ground_context_revision
	var guarded:bool=publication_guard.is_valid()
	if guarded and not publication_guard.call():return
	for id in unit_ids:
		var actor=_resolve_known_unit_for_contract(id)
		if is_instance_valid(actor) and _hex_ground_runtime.has_unit(id):actor.set_meta("dropship_embarked",false)
	_project_hex_ground_actors(0.0)
	for id in unit_ids:
		if context!=_hex_ground_context_revision:return
		if guarded and (not publication_guard.is_valid() or not publication_guard.call()):return
		var actor=_resolve_known_unit_for_contract(id)
		if is_instance_valid(actor) and _hex_ground_runtime.has_unit(id):actor.visible=true


func get_hex_ground_revision()->int:
	return int(_hex_ground_runtime.get("_revision")) if is_hex_ground_runtime_active() else -1


func _hex_respawn_actor(manager:Node,unit_id:String,team_id:String)->Dictionary:
	var checked:Dictionary=_validate_hex_ground_actor_group(PackedStringArray([unit_id]))
	if not checked.ok:return checked
	if int(_hex_ground_runtime.get_current_tick())!=tick_counter:return {"ok":false,"reason":"hex_clock_unsynced"}
	if not is_instance_valid(manager) or manager.is_queued_for_deletion() or manager.get_script()!=preload("res://scripts/core/respawn_manager.gd"):return {"ok":false,"reason":"respawn_manager_unbound"}
	if manager.simulation_root_path.is_empty() or manager.unit_registry_path.is_empty() or manager.get_node_or_null(manager.simulation_root_path)!=self or manager.get_node_or_null(manager.unit_registry_path)!=get_unit_registry() or not get_parent().is_ancestor_of(manager):return {"ok":false,"reason":"respawn_manager_unbound"}
	var actor:Node=checked.actors[unit_id]
	if not _hex_ground_runtime.has_unit(unit_id) or _hex_ground_runtime.has_pending_admission(unit_id) or bool(actor.get_meta("dropship_embarked",false)):return {"ok":false,"reason":"respawn_ground_unavailable"}
	if not actor.has_method("prepare_actor_respawn") or not actor.has_method("get_team_id") or String(actor.call("get_team_id"))!=team_id or actor.get("_respawn_manager")!=manager:return {"ok":false,"reason":"respawn_actor_unbound"}
	return {"ok":true,"actor":actor}


## Timer creation and its medical BEGIN form one model transaction.
func begin_hex_respawn(manager:Node,unit_id:String,team_id:String,spawn_type:String)->Dictionary:
	var checked:Dictionary=_hex_respawn_actor(manager,unit_id,team_id)
	if not checked.ok:return checked
	if manager.has_pending_respawn(unit_id):return {"ok":false,"reason":"respawn_already_pending"}
	for key in _hex_respawn_records.keys():
		if _hex_respawn_records.size()<256:break
		var old:Dictionary=_hex_respawn_records[key]
		if old.status=="committed" or not _hex_respawn_binding(old).ok:_hex_respawn_records.erase(key)
	if _hex_respawn_records.size()>=256:return {"ok":false,"reason":"respawn_ticket_capacity"}
	var actor:Node=checked.actor
	var prepared:Dictionary=actor.call("prepare_actor_respawn",self,"begin")
	if not prepared.ok:return prepared
	var validation:Dictionary=actor.call("validate_prepared_actor_respawn",prepared.prepared)
	if not validation.ok:return validation
	var respawn_time:float=manager.get_respawn_time(spawn_type)
	var next_sequence:int=_hex_respawn_sequence+1
	var ticket:String="hex_respawn:%d:%d"%[get_instance_id(),next_sequence]
	var manager_entry:Dictionary={"hex_ticket":ticket,"root":weakref(self),"time_remaining":respawn_time,"respawn_time":respawn_time,"team_id":team_id,"spawn_type":spawn_type,"started":false}
	var stopped:Dictionary=_hex_ground_runtime.stop_units(PackedStringArray([unit_id]),"respawn_begin")
	if not stopped.ok:return stopped
	# From the first Ground write onward: assignment-only owner tails, no signals.
	_hex_movement_runtime.mark_external_stop(PackedStringArray(stopped.affected_unit_ids),"respawn_begin")
	_hex_movement_runtime.release_unit(unit_id)
	_hex_unit_lifecycle_revision[unit_id]=int(_hex_unit_lifecycle_revision.get(unit_id,0))+1
	_hex_facing_pending.erase(unit_id)
	_discard_pending_move_commands_for_unit(unit_id)
	_hex_respawn_sequence=next_sequence
	var record:Dictionary={"ticket":ticket,"unit_id":unit_id,"team_id":team_id,"manager":weakref(manager),"actor":weakref(actor),"identity":_hex_payload_identity(unit_id),"status":"pending","reason":"","in_flight":false,"last_stamp":"","completion_published":false}
	_hex_respawn_records[ticket]=record
	actor.call("_publish_prepared_actor_respawn",prepared.prepared,validation)
	manager.call("_publish_hex_respawn_begin",unit_id,manager_entry)
	var owner_ref:WeakRef=weakref(self)
	var finalized:Dictionary=actor.call("finalize_actor_respawn",prepared.prepared)
	var owner=owner_ref.get_ref()
	if finalized.get("ok",false) and not finalized.get("context_changed",false) and is_instance_valid(owner) and not owner.is_queued_for_deletion() and owner._hex_respawn_binding(record).ok and actor.call("is_actor_respawn_publication_current",prepared.prepared):
		manager.call("_finalize_hex_respawn_started",unit_id,ticket)
	return {"ok":true,"ticket":ticket}


func _hex_respawn_binding(record:Dictionary)->Dictionary:
	var manager:Node=record.manager.get_ref()
	if not _is_current_hex_payload({"unit_id":record.unit_id,"_hex_lifecycle":record.identity}):return {"ok":false,"reason":"stale_hex_respawn"}
	var checked:Dictionary=_hex_respawn_actor(manager,record.unit_id,record.team_id)
	if not checked.ok:return checked
	if checked.actor!=record.actor.get_ref() or not manager.has_pending_respawn(record.unit_id) or manager._pending_respawns[record.unit_id].get("hex_ticket","")!=record.ticket:return {"ok":false,"reason":"stale_hex_respawn"}
	return checked


func get_hex_respawn_receipt(ticket:String)->Dictionary:
	if not _hex_respawn_records.has(ticket):return {"ok":false,"status":"stale","reason":"unknown_hex_respawn"}
	var record:Dictionary=_hex_respawn_records[ticket]
	# Successful lifecycle advancement does not invalidate its historical receipt.
	if record.status!="committed" and not _hex_respawn_binding(record).ok:return {"ok":false,"status":"stale","unit_id":record.unit_id}
	return {"ok":true,"status":record.status,"reason":record.reason,"unit_id":record.unit_id,"ticket":ticket}


## Same accepted physical producer as deployment/waves; no new ship geometry.
func _get_hex_respawn_ship_mask()->Dictionary:
	var producer:Node=get_node_or_null("../TacticalController")
	if producer == null and is_instance_valid(_base_personnel_owner): producer = _base_personnel_owner
	if producer==null:return {"ok":true,"source_signature":"","blocked_cells":[]}
	if not producer.has_method("get_ground_ship_blocked_cells"):return {"ok":false,"reason":"respawn_ship_mask_unavailable"}
	var mask:Dictionary=producer.call("get_ground_ship_blocked_cells")
	if not mask.get("ok",false) or int(mask.get("registry_id",0))!=_hex_ground_registry.get_instance_id() or not mask.get("blocked_cells") is Array or mask.blocked_cells.size()>4096:return {"ok":false,"reason":"respawn_ship_mask_unavailable"}
	for grid in mask.blocked_cells:
		if not grid is Vector2i:return {"ok":false,"reason":"respawn_ship_mask_unavailable"}
	return mask


func _add_base_ground_clearance(snapshot: Dictionary) -> Dictionary:
	var mask: Dictionary = _get_hex_respawn_ship_mask()
	if not mask.get("ok", false): return mask
	var blocked := {}
	for grid in mask.blocked_cells: blocked[grid] = true
	snapshot["external_admission_blocked_grids"] = blocked
	return {"ok":true}


func _hex_respawn_retry_stamp(target:Vector2i,mask:Dictionary)->String:
	return str([get_hex_ground_revision(),_hex_ground_registry.get_revision(),target,mask.get("source_signature","")])


func enqueue_hex_respawn(ticket:String,world_position:Vector2)->Dictionary:
	if not _hex_respawn_records.has(ticket):return {"ok":false,"reason":"unknown_hex_respawn"}
	var record:Dictionary=_hex_respawn_records[ticket]
	if record.status=="committed":return {"ok":true,"status":"committed"}
	if record.status in ["stale","cancelled"]:return {"ok":false,"status":record.status,"reason":record.reason}
	var checked:Dictionary=_hex_respawn_binding(record)
	if not checked.ok:return checked
	if not world_position.is_finite():return {"ok":false,"reason":"invalid_respawn_position"}
	if record.in_flight:return {"ok":true,"status":"queued"}
	var target:Vector2i=_hex_ground_registry.call("world_to_grid",world_position)
	var mask:Dictionary=_get_hex_respawn_ship_mask()
	if not mask.ok:
		record.status="blocked"
		record.reason=mask.reason
		return mask
	var stamp:String=_hex_respawn_retry_stamp(target,mask)
	if stamp==record.last_stamp:return {"ok":true,"status":"blocked"}
	record.last_stamp=stamp
	if mask.blocked_cells.has(target):
		record.status="blocked"
		record.reason="respawn_ship_blocked"
		return {"ok":true,"status":"blocked"}
	record.in_flight=true
	record.status="queued"
	enqueue_effect({"effect_type":"respawn","unit_id":record.unit_id,"priority":10,"spawn_position":world_position,"_hex_respawn_ticket":ticket,"_hex_lifecycle":record.identity.duplicate(true)})
	return {"ok":true,"status":"queued"}


func _apply_hex_respawn_effect(effect:Dictionary)->void:
	var ticket:String=String(effect.get("_hex_respawn_ticket",""))
	if not _hex_respawn_records.has(ticket):return
	var record:Dictionary=_hex_respawn_records[ticket]
	if record.status=="committed" or not record.in_flight:return
	record.in_flight=false
	var checked:Dictionary=_hex_respawn_binding(record)
	if not checked.ok:return
	var actor:Node=checked.actor
	var target:Vector2i=_hex_ground_registry.call("world_to_grid",effect.spawn_position)
	var mask:Dictionary=_get_hex_respawn_ship_mask()
	if not mask.ok or mask.blocked_cells.has(target):
		record.status="blocked"
		record.reason=mask.get("reason","respawn_ship_blocked")
		if mask.ok:record.last_stamp=_hex_respawn_retry_stamp(target,mask)
		return
	var world:Vector2=_hex_ground_registry.call("grid_to_world",target)
	var prepared:Dictionary=actor.call("prepare_actor_respawn",self,"complete",world)
	if not prepared.ok:
		record.status="stale"
		record.reason=prepared.reason
		return
	var validation:Dictionary=actor.call("validate_prepared_actor_respawn",prepared.prepared)
	if not validation.ok:return
	var moved:Dictionary=_hex_ground_runtime.relocate_unit(record.unit_id,target,get_hex_ground_revision())
	if not moved.ok:
		record.status="blocked"
		record.reason=moved.reason
		return
	var id:String=record.unit_id
	_hex_movement_runtime.release_unit(id)
	_hex_unit_lifecycle_revision[id]=int(_hex_unit_lifecycle_revision.get(id,0))+1
	_hex_facing_pending.erase(id)
	_discard_pending_move_commands_for_unit(id)
	_hex_visual_unit_ids[id]=true
	actor.call("_publish_prepared_actor_respawn",prepared.prepared,validation)
	var manager:Node=record.manager.get_ref()
	manager.call("_publish_hex_respawn_complete",id,ticket)
	record.status="committed"
	record.reason=""
	var committed_identity:Dictionary=_hex_payload_identity(id)
	var owner_ref:WeakRef=weakref(self)
	var finalized:Dictionary=actor.call("finalize_actor_respawn",prepared.prepared)
	var owner=owner_ref.get_ref()
	if not finalized.get("ok",false) or finalized.get("context_changed",false) or not is_instance_valid(owner) or owner.is_queued_for_deletion() or not owner._is_current_hex_payload({"unit_id":id,"_hex_lifecycle":committed_identity}):return
	manager=record.manager.get_ref()
	if not is_instance_valid(manager) or manager.is_queued_for_deletion():return
	owner._project_hex_ground_actors(0.0)
	owner=owner_ref.get_ref()
	manager=record.manager.get_ref()
	if is_instance_valid(owner) and not owner.is_queued_for_deletion() and owner._is_current_hex_payload({"unit_id":id,"_hex_lifecycle":committed_identity}) and owner._hex_respawn_actor(manager,id,record.team_id).ok and actor.call("is_actor_respawn_publication_current",prepared.prepared) and not record.completion_published:
		record.completion_published=true
		manager.call("_finalize_hex_respawn_completed",id,ticket)


func embark_hex_ground_actor_group(unit_ids:PackedStringArray,publish:bool=true)->Dictionary:
	if is_queued_for_deletion():return {"ok":false,"reason":"hex_owner_exiting"}
	var checked:Dictionary=_validate_hex_ground_actor_group(unit_ids,true)
	if not checked.ok:return checked
	for id in unit_ids:
		_discard_pending_move_commands_for_unit(id)
		release_hex_ground_unit(id,"embarked")
	var identities:Dictionary={}
	for id in unit_ids:identities[id]=_hex_payload_identity(id)
	var receipt:Dictionary={"ok":true,"root_id":get_instance_id(),"embarked_unit_ids":unit_ids.duplicate(),"identities":identities}
	if publish:_publish_hex_embarked_actors(receipt)
	return receipt


func _hex_embark_receipt_current(receipt:Dictionary)->bool:
	if is_queued_for_deletion() or receipt.get("root_id",0)!=get_instance_id() or not is_hex_ground_runtime_active():return false
	for id in receipt.embarked_unit_ids:
		if not _is_current_hex_payload({"unit_id":id,"_hex_lifecycle":receipt.identities[id]}) or _hex_ground_runtime.has_unit(id):return false
	return true


func _publish_hex_embarked_actors(receipt:Dictionary)->void:
	if not _hex_embark_receipt_current(receipt):return
	for id in receipt.embarked_unit_ids:
		var actor=_resolve_known_unit_for_contract(id)
		if is_instance_valid(actor):actor.set_meta("dropship_embarked",true)
	var lifetime:WeakRef=weakref(self)
	for id in receipt.embarked_unit_ids:
		var owner=lifetime.get_ref()
		if not is_instance_valid(owner) or owner.is_queued_for_deletion():return
		# One re-entered member must not strand the remaining committed members.
		if not owner._is_current_hex_payload({"unit_id":id,"_hex_lifecycle":receipt.identities[id]}) or not owner.get_hex_unit_state(id).is_empty():continue
		var actor=owner._resolve_known_unit_for_contract(id)
		if is_instance_valid(actor):actor.visible=false


func has_hex_pending_admission(unit_id:String)->bool:
	return is_hex_ground_runtime_active() and _hex_ground_runtime.has_pending_admission(unit_id)


func prepare_hex_ground_deployment(unit_ids:PackedStringArray,anchor_grid:Vector2i,excluded_cells:Array[Vector2i]=[])->Dictionary:
	var checked:Dictionary=_validate_hex_ground_actor_group(unit_ids,true)
	if not checked.ok:return checked
	if _hex_deployment_serial>=HEX_GROUND_RUNTIME_SCRIPT.MAX_TICK:return {"ok":false,"reason":"admission_serial_exhausted"}
	var snapshot:Dictionary=_hex_ground_runtime.build_planning_snapshot()
	if excluded_cells.size()>4096:return {"ok":false,"reason":"footprint_budget"}
	var blocked:Dictionary={}
	for grid in excluded_cells:blocked[grid]=true
	snapshot["external_admission_blocked_grids"]=blocked
	var plan:Dictionary=HEX_ADMISSION_SCRIPT.new().plan_group(unit_ids,anchor_grid,_hex_ground_registry,snapshot)
	if not plan.ok:return plan
	_hex_deployment_serial+=1
	var admission_id:String="hex_admission:%d:%d"%[_hex_ground_context_revision,_hex_deployment_serial]
	var placements:Array[Dictionary]=[]
	placements.assign(plan.placements)
	var result:Dictionary=_hex_ground_runtime.reserve_admission_group(admission_id,placements,snapshot.revision)
	if result.ok:_hex_movement_runtime.notify_ground_events([{"event_type":"hex_admission_prepared"}])
	return result


func get_hex_ground_deployment(admission_id:String)->Dictionary:
	if not is_hex_ground_runtime_active():return {"ok":false,"reason":"hex_ground_inactive"}
	return _hex_ground_runtime.get_admission_group(admission_id)


func get_hex_ground_deployment_receipt(admission_id:String,unit_id:String)->Dictionary:
	var state:Dictionary=get_hex_unit_state(unit_id)
	if admission_id.is_empty() or state.is_empty() or String(state.get("admission_id",""))!=admission_id:return {"ok":false,"reason":"deployment_not_committed"}
	return {"ok":true,"unit_id":unit_id,"admission_id":admission_id,"grid":state.grid,"position_world":get_hex_logical_unit_position(unit_id)}


func cancel_hex_ground_deployment(admission_id:String,reason:String)->Dictionary:
	if _should_skip_local_tick_processing():return {"ok":false,"reason":"not_authority"}
	if not is_hex_ground_runtime_active():return {"ok":false,"reason":"hex_ground_inactive"}
	var result:Dictionary=_hex_ground_runtime.cancel_admission_group(admission_id,reason)
	if result.ok and not result.released_unit_ids.is_empty():_hex_movement_runtime.notify_ground_events([{"event_type":"hex_admission_cancelled"}])
	return result


func get_last_hex_lifecycle_resolution()->Dictionary:
	return _last_hex_lifecycle_resolution.duplicate(true)


func _apply_hex_dropship_deploy_effect(effect:Dictionary)->Dictionary:
	var id:String=String(effect.get("unit_id",""))
	var checked:Dictionary=_validate_hex_ground_actor_group(PackedStringArray([id]),true)
	if not checked.ok:return checked
	var actor:Node2D=checked.actors[id]
	var admission_id:String=String(effect.get("admission_id",""))
	if admission_id.is_empty():
		# Existing presence refreshes may publish an already committed actor, but
		# cannot admit a new person or teleport an existing logical position.
		if _hex_ground_runtime.has_unit(id) and not bool(actor.get_meta("dropship_embarked",false)):
			_project_hex_ground_actors(0.0)
			actor.visible=bool(effect.get("visible",true))
			return {"ok":true,"unit_id":id,"already_present":true}
		return {"ok":false,"reason":"admission_ticket_required","unit_id":id}
	var ticket:Dictionary=_hex_ground_runtime.get_admission_group(admission_id)
	if not ticket.ok:return ticket
	var placement:Array[Dictionary]=[]
	for entry in ticket.placements:
		if entry.unit_id==id:placement.append(entry)
	if placement.is_empty():return {"ok":false,"reason":"admission_ticket_mismatch","unit_id":id}
	var result:Dictionary=_hex_ground_runtime.admit_units(placement,admission_id)
	if not result.ok:return result
	# Actor/registry preflight was complete before the Ground write. UnitRegistry
	# registration has no callbacks; publish visibility/activation afterwards.
	var registry=get_unit_registry()
	if not registry.has_unit(id):registry.register_unit(id,actor)
	actor.set_meta("dropship_embarked",false)
	_hex_visual_unit_ids[id]=true
	_apply_dropship_runtime_activation(id,actor,effect)
	_project_hex_ground_actors(0.0)
	actor.visible=bool(effect.get("visible",true))
	var status:String=String(effect.get("runtime_status",""))
	if not status.is_empty() and actor.has_method("set_runtime_status"):actor.call("set_runtime_status",status)
	if actor.has_method("refresh_terrain_readability"):actor.call("refresh_terrain_readability")
	return {"ok":true,"unit_id":id,"admission_id":admission_id,"grid":placement[0].grid}


## Internal runtime intents, never accepted as client/UI-provided facing state.
## A delayed reaction can specify its already skill-derived ready tick.
func queue_hex_facing_intent(unit_id: String, direction: int, command_id: String, reason: String, ready_tick: int = -1) -> Dictionary:
	if _should_skip_local_tick_processing():
		return {"ok":false,"reason":"not_authority"}
	if not is_hex_ground_runtime_active() or get_hex_unit_state(unit_id).is_empty():
		return {"ok":false,"reason":"hex_unit_unavailable"}
	if direction < 0 or direction > 5 or command_id.strip_edges().is_empty() or not HEX_FACING_PRIORITIES.has(reason):
		return {"ok":false,"reason":"invalid_facing_intent"}
	if tick_counter < 0 or tick_counter == 9223372036854775807 or ready_tick < -1:
		return {"ok":false,"reason":"invalid_facing_tick"}
	var unit = _resolve_known_unit_for_contract(unit_id)
	if not is_instance_valid(unit):
		return {"ok":false,"reason":"runtime_unit_unavailable"}
	var order := _get_hex_facing_order(unit)
	if reason in ["noise_reaction","combat_reaction"]:
		var command_type := String(order.get("command_type",""))
		var source_type := String(order.get("source_command_type",""))
		if command_type in ["hold_position","retreat","seek_cover"] or source_type in ["defend","take","retreat"] or (command_type == "move_to_position" and source_type not in ["engage","flank"]):
			return {"ok":false,"reason":"assignment_locks_facing"}
	var replay_key := JSON.stringify([unit_id,command_id])
	if _hex_facing_seen.has(replay_key):
		return {"ok":true,"replayed":true}
	var order_key := JSON.stringify(order)
	var previous: Dictionary = _hex_facing_pending.get(unit_id,{})
	if not previous.is_empty() and String(previous.get("order_key","")) == order_key and int(previous.get("priority",0)) > int(HEX_FACING_PRIORITIES[reason]):
		return {"ok":false,"reason":"higher_priority_facing_pending"}
	if _hex_facing_replay_keys.size() < HEX_FACING_REPLAY_CAPACITY:
		_hex_facing_replay_keys.append(replay_key)
	else:
		_hex_facing_seen.erase(_hex_facing_replay_keys[_hex_facing_replay_cursor])
		_hex_facing_replay_keys[_hex_facing_replay_cursor] = replay_key
		_hex_facing_replay_cursor = (_hex_facing_replay_cursor+1) % HEX_FACING_REPLAY_CAPACITY
	_hex_facing_seen[replay_key] = true
	# Security readouts renew their assignment IDs. A direction already owned
	# by Ground does not create future work or keep stable saves permanently busy.
	# Record the accepted ID first; competing and delayed turns retain their path.
	if previous.is_empty() and ready_tick <= tick_counter + 1 and int(get_hex_unit_state(unit_id).facing_dir) == direction:
		return {"ok":true,"replayed":false,"unchanged":true}
	var resolved_ready := maxi(ready_tick,tick_counter+1)
	if not previous.is_empty() and String(previous.get("order_key","")) == order_key and int(previous.get("priority",0)) == int(HEX_FACING_PRIORITIES[reason]) and int(previous.get("direction",-1)) == direction:
		resolved_ready = mini(resolved_ready,int(previous["ready_tick"]))
	_hex_facing_pending[unit_id] = {"direction":direction,"ready_tick":resolved_ready,
		"priority":HEX_FACING_PRIORITIES[reason],"order_key":order_key}
	return {"ok":true,"replayed":false}


func _get_hex_facing_order(unit) -> Dictionary:
	if not is_instance_valid(unit) or not unit.has_method("get_current_unit_command"):
		return {}
	var command = unit.call("get_current_unit_command")
	if command == null or not command.has_method("to_dict"):
		return {}
	var data: Dictionary = command.call("to_dict")
	var result: Dictionary = {}
	# Exclude continually derived cover/skill readouts; only the actual order
	# identity and its policy can invalidate an intent between ticks.
	for key in ["command_type","source_command_type","command_token","target_position","target_area_id","phase","fire_rule","movement_posture"]:
		result[key] = data.get(key)
	return result


func _commit_hex_facing_intents() -> void:
	if _should_skip_local_tick_processing() or not is_hex_ground_runtime_active():
		return
	var unit_ids: Array = _hex_facing_pending.keys()
	unit_ids.sort()
	for unit_id in unit_ids:
		var intent: Dictionary = _hex_facing_pending[unit_id]
		if _hex_boundary_facing.has(unit_id):continue
		if int(intent["ready_tick"]) > tick_counter:
			continue
		_hex_facing_pending.erase(unit_id)
		var unit = _resolve_known_unit_for_contract(unit_id)
		if not is_instance_valid(unit) or String(intent["order_key"]) != JSON.stringify(_get_hex_facing_order(unit)):
			continue
		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
			continue
		if _hex_ground_runtime.commit_facing(String(unit_id),int(intent["direction"])):_hex_visual_unit_ids[unit_id]=true


func _init() -> void:
	_combat_rng.seed = int(combat_rng_seed)


func _ready() -> void:
	set_combat_rng_seed(combat_rng_seed)


func _hex_payload_identity(unit_id:String)->Dictionary:
	var actor=_resolve_known_unit_for_contract(unit_id)
	return {"context":_hex_ground_context_revision,"lifecycle":int(_hex_unit_lifecycle_revision.get(unit_id,0)),"actor":actor.get_instance_id() if is_instance_valid(actor) else 0}


func _is_current_hex_payload(payload:Dictionary)->bool:
	if not payload.has("_hex_lifecycle"):return true
	return is_hex_ground_runtime_active() and payload._hex_lifecycle is Dictionary and payload._hex_lifecycle==_hex_payload_identity(String(payload.get("unit_id","")))


func enqueue_command(cmd: Dictionary) -> void:
	if typeof(cmd) != TYPE_DICTIONARY:
		push_warning("SimulationRoot.enqueue_command expects a Dictionary command.")
		return
	if not _is_current_hex_payload(cmd):
		_record_discarded_move_command(cmd,"stale_hex_lifecycle")
		return
	if is_hex_ground_runtime_active() and _extract_command_type(cmd) in ["move_to_position","engage_area"] and not String(cmd.get("unit_id","")).is_empty():
		var target:Variant=cmd.get("target_position")
		if not target is Vector2 or not target.is_finite():
			_record_discarded_move_command(cmd,"invalid_target_position")
			return

	var queued_command: Dictionary = cmd.duplicate(true)
	if is_hex_ground_runtime_active() and _extract_command_type(cmd) in ["move_to_position","engage_area","hold_position"] and not String(cmd.get("unit_id","")).is_empty():
		queued_command["_hex_lifecycle"]=_hex_payload_identity(String(cmd.unit_id))
	var command_token: String = String(queued_command.get("command_token", "")).strip_edges()
	var unit_id: String = String(queued_command.get("unit_id", "")).strip_edges()
	if not command_token.is_empty() and not unit_id.is_empty():
		_latest_command_token_by_unit_id[unit_id] = command_token
	if not command_token.is_empty():
		for index in range(command_queue.size()):
			var pending_command: Dictionary = Dictionary(command_queue[index])
			if String(pending_command.get("command_token", "")).strip_edges() != command_token:
				continue
			_retain_regional_navigation(pending_command, queued_command)
			command_queue[index] = queued_command
			return

	command_queue.append(queued_command)


func _retain_regional_navigation(pending: Dictionary, replacement: Dictionary) -> void:
	if not pending.has("_regional_navigation_search") and not pending.has("_regional_navigation_route"):
		return
	if pending.get("unit_id") != replacement.get("unit_id") or _extract_command_type(pending) != _extract_command_type(replacement):
		return
	if not Vector2(pending.get("target_position", Vector2.ZERO)).is_equal_approx(Vector2(replacement.get("target_position", Vector2.ZERO))):
		return
	var registry = _get_terrain_registry()
	if _build_navigation_cost_options(pending, registry) != _build_navigation_cost_options(replacement, registry):
		return
	for key in ["_regional_navigation_search", "_regional_navigation_route", "path", "navigation_resolved_target_position",
			"navigation_path_terrain_revision", "local_avoidance_repath_requested", "local_avoidance_deadlock"]:
		if pending.has(key) and not replacement.has(key):
			replacement[key] = pending[key]
		elif pending.has(key) and key == "path" and Array(replacement[key]).is_empty():
			replacement[key] = pending[key]


func enqueue_effect(effect: Dictionary) -> void:
	if typeof(effect) != TYPE_DICTIONARY:
		push_warning("SimulationRoot.enqueue_effect expects a Dictionary effect.")
		return

	if not _is_current_hex_payload(effect):return
	if is_hex_ground_runtime_active() and _extract_effect_type(effect) in ["dropship_embark_unit","dropship_deploy_unit"]:
		var queued:Dictionary=effect.duplicate(true)
		queued["_hex_lifecycle"]=_hex_payload_identity(String(effect.get("unit_id","")))
		effects_queue.append(queued)
	else:effects_queue.append(effect)


func get_air_asset_status_snapshot(asset_id: String = "") -> Dictionary:
	var normalized_id: String = asset_id.strip_edges()
	if normalized_id.is_empty():
		var result: Dictionary = {}
		var asset_ids: Array = _air_asset_status_by_id.keys()
		asset_ids.sort()
		for id_variant in asset_ids:
			var key: String = String(id_variant)
			result[key] = Dictionary(_air_asset_status_by_id.get(key, {})).duplicate(true)
		return result
	return Dictionary(_air_asset_status_by_id.get(normalized_id, {})).duplicate(true)


func set_terrain_move_debug_enabled(enabled: bool) -> void:
	terrain_move_debug_enabled = enabled
	if not terrain_move_debug_enabled:
		_last_terrain_move_debug_by_unit_id.clear()


func get_terrain_move_debug_snapshot(unit_id: String = "") -> Variant:
	if unit_id.strip_edges().is_empty():
		var result: Array = []
		var unit_ids: Array = _last_terrain_move_debug_by_unit_id.keys()
		unit_ids.sort()
		for unit_id_variant in unit_ids:
			result.append(Dictionary(_last_terrain_move_debug_by_unit_id.get(unit_id_variant, {})).duplicate(true))
		return result
	return Dictionary(_last_terrain_move_debug_by_unit_id.get(unit_id.strip_edges(), {})).duplicate(true)


func clear_discarded_move_command_debug() -> void:
	_last_discarded_move_command.clear()
	_discarded_move_command_count = 0
	_discarded_move_command_counts_by_reason.clear()


func get_discarded_move_command_count(reason: String = "") -> int:
	var normalized_reason: String = reason.strip_edges().to_lower()
	if normalized_reason.is_empty():
		return _discarded_move_command_count
	return int(_discarded_move_command_counts_by_reason.get(normalized_reason, 0))


func get_last_discarded_move_command() -> Dictionary:
	return _last_discarded_move_command.duplicate(true)


func set_navigation_budget_enabled(enabled: bool) -> void:
	navigation_budget_enabled = enabled


func set_navigation_max_new_path_queries_per_tick(limit: int) -> void:
	navigation_max_new_path_queries_per_tick = maxi(0, limit)


func set_navigation_debug_enabled(enabled: bool) -> void:
	navigation_debug_enabled = enabled
	if not navigation_debug_enabled:
		_navigation_last_tick_queries.clear()
		_navigation_most_expensive_query.clear()
		_navigation_last_path_metrics.clear()


func get_navigation_debug_snapshot() -> Dictionary:
	return {
		"enabled": navigation_debug_enabled,
		"budget_enabled": navigation_budget_enabled,
		"tick": tick_counter,
		"max_new_path_queries_per_tick": navigation_max_new_path_queries_per_tick,
		"new_path_queries_this_tick": _navigation_new_path_queries_this_tick,
		"path_queries_this_tick": _navigation_path_queries_this_tick,
		"fallback_queries_this_tick": _navigation_fallback_queries_this_tick,
		"unreachable_queries_this_tick": _navigation_unreachable_queries_this_tick,
		"delayed_this_tick": _navigation_delayed_this_tick,
		"pending_query_count": _count_pending_navigation_queries(),
		"last_delay_reason": _navigation_last_delay_reason,
		"last_queries": _duplicate_dictionary_array(_navigation_last_tick_queries),
		"most_expensive_query": _navigation_most_expensive_query.duplicate(true),
		"last_path_metrics": _navigation_last_path_metrics.duplicate(true),
		"hpa_navigation": _get_hpa_navigation_debug_snapshot(),
		"navigation_backend": get_navigation_backend_debug_snapshot(),
	}


func get_navigation_backend_debug_snapshot() -> Dictionary:
	var snapshot: Dictionary = _native_navigation.get_debug_snapshot()
	snapshot.merge(_navigation_backend_debug, true)
	snapshot["enabled"] = native_navigation_enabled
	snapshot["prewarm"] = _navigation_prewarm_debug.duplicate(true)
	if not native_navigation_enabled:
		snapshot["last_backend"] = "gdscript"
		snapshot["fallback_reason"] = "native_navigation_disabled"
	return snapshot


func prewarm_navigation(terrain_registry = null) -> Dictionary:
	# Call only after the loader has registered tiles and initial runtime overrides.
	# This prepares derived data; it does not enqueue commands or spend query budget.
	var started: int = Time.get_ticks_usec()
	if terrain_registry == null:
		terrain_registry = _get_terrain_registry()
	if not is_instance_valid(terrain_registry):
		_clear_navigation_prepared_data()
		_navigation_prewarm_debug = {
			"ready": false, "native_prepared": false, "backend": "none",
			"reason": "terrain_registry_unavailable", "duration_usec": Time.get_ticks_usec() - started,
			"graph_prepare_usec": 0, "native_prepare_usec": 0, "registry_revision": -1, "tile_count": 0,
		}
		return _navigation_prewarm_debug.duplicate(true)
	var graph_started: int = Time.get_ticks_usec()
	# Productive HexGround and large-map moves use incremental direct search.
	# Only prepare the HPA graph for callers that actually use it.
	var incremental: bool = _uses_regional_navigation(terrain_registry) or (is_hex_ground_runtime_active() and terrain_registry == get_hex_ground_terrain_registry())
	var graph = null if incremental else _ensure_hpa_navigation_graph(terrain_registry)
	var graph_prepare_usec: int = Time.get_ticks_usec() - graph_started
	var native_started: int = Time.get_ticks_usec()
	var native_prepared: bool = false
	var reason: String = "native_navigation_disabled"
	if native_navigation_enabled:
		native_prepared = _native_navigation.prepare(terrain_registry, {}, graph)
		reason = "prepared" if native_prepared else String(_native_navigation.get_debug_snapshot().get("fallback_reason", "native_preparation_failed"))
		_navigation_backend_debug = {"last_backend": "native" if native_prepared else "gdscript_fallback", "fallback_reason": "" if native_prepared else reason}
	else:
		_set_gdscript_navigation_backend(reason)
	_navigation_prewarm_debug = {
		"ready": true, "native_prepared": native_prepared,
		"backend": "native" if native_prepared else "gdscript", "reason": reason,
		"search_mode": "regional_hex" if incremental else "hpa",
		"duration_usec": Time.get_ticks_usec() - started, "graph_prepare_usec": graph_prepare_usec,
		"native_prepare_usec": Time.get_ticks_usec() - native_started,
		"registry_revision": _get_terrain_registry_revision(terrain_registry),
		"tile_count": int(terrain_registry.call("get_tile_count")) if terrain_registry.has_method("get_tile_count") else _hpa_navigation_tile_count,
	}
	return _navigation_prewarm_debug.duplicate(true)


func _clear_navigation_prepared_data() -> void:
	_hpa_navigation_graph = null
	_hpa_navigation_registry = null
	_hpa_navigation_tile_count = -1
	_hpa_navigation_registry_revision = -1
	_hpa_navigation_last_build_stats.clear()
	_native_navigation.clear_prepared_data()
	_navigation_backend_debug = {"last_backend": "none", "fallback_reason": "terrain_registry_unavailable"}


func _set_gdscript_navigation_backend(reason: String) -> void:
	_navigation_backend_debug = {
		"last_backend": "gdscript", "fallback_reason": reason,
		"result_cache_hit": false, "snapshot_reused": false, "graph_reused": false,
		"snapshot_prepare_usec": 0, "native_query_usec": 0,
		"target_cost_compute_count": 0, "edge_cost_compute_count": 0,
	}


func create_regional_navigation_search(from_grid: Vector2i, to_grid: Vector2i, terrain_registry, options: Dictionary = {}):
	var search
	if native_navigation_enabled:
		search = _native_navigation.create_regional_search(from_grid, to_grid, terrain_registry, options)
	else:
		search = TERRAIN_PATHFINDER_SCRIPT.RegionalHexSearch.new(from_grid, to_grid, _get_terrain_registry_revision(terrain_registry), options, terrain_registry)
	_note_regional_navigation_backend(search)
	return search


func _note_regional_navigation_backend(search) -> String:
	if search is TERRAIN_PATHFINDER_SCRIPT.RegionalHexSearch:
		var reason: String = "native_navigation_disabled" if not native_navigation_enabled else String(_native_navigation.get_debug_snapshot().get("fallback_reason", "regional_fallback"))
		_set_gdscript_navigation_backend(reason)
		return "gdscript"
	_navigation_backend_debug = {"last_backend": "native", "fallback_reason": "", "search_mode": "regional_hex", "result_cache_hit": false}
	return "native"


func _get_hpa_navigation_debug_snapshot() -> Dictionary:
	return {
		"has_graph": _hpa_navigation_graph != null,
		"cluster_size": HPA_NAVIGATION_CLUSTER_SIZE,
		"tile_count": _hpa_navigation_tile_count,
		"registry_revision": _hpa_navigation_registry_revision,
		"build_count": _hpa_navigation_build_count,
		"cache_hit_count": _hpa_navigation_cache_hit_count,
		"last_build_stats": _hpa_navigation_last_build_stats.duplicate(true),
	}


func set_runtime_tick_budget_debug_enabled(enabled: bool) -> void:
	runtime_tick_budget_debug_enabled = enabled
	if not runtime_tick_budget_debug_enabled:
		_runtime_tick_budget_debug_snapshot.clear()
		_runtime_frame_budget_debug.clear()
		_runtime_command_type_count.clear()
		_runtime_command_type_usec.clear()
		_runtime_command_requeue_count.clear()
		_runtime_command_ordering_usec = 0
		_runtime_command_apply_usec = 0


func get_runtime_tick_budget_debug_snapshot() -> Dictionary:
	return _runtime_tick_budget_debug_snapshot.duplicate(true)


func get_runtime_frame_budget_debug_snapshot(process_frame: int = -1) -> Dictionary:
	var frame_id := Engine.get_process_frames() if process_frame < 0 else process_frame
	var result: Dictionary = _runtime_frame_budget_debug.get_snapshot(frame_id)
	result["enabled"] = runtime_tick_budget_debug_enabled
	result["known_empty_current_frame"] = runtime_tick_budget_debug_enabled and frame_id == Engine.get_process_frames() and not bool(result.has_sample)
	result["read_only"] = true
	return result


func _record_runtime_tick_budget_debug_snapshot(delta: float, tick_started_usec: int, profile_scopes: Dictionary, command_count: int, effect_count: int) -> void:
	var record_started_usec := Time.get_ticks_usec()
	_runtime_tick_budget_debug_snapshot = {
		"enabled": runtime_tick_budget_debug_enabled,
		"process_frame": Engine.get_process_frames(),
		"tick": tick_counter,
		"delta": delta,
		"total_tick_usec": Time.get_ticks_usec() - tick_started_usec,
		"scopes_usec": profile_scopes.duplicate(true),
		"command_count": command_count,
		"command_type_count": _runtime_command_type_count.duplicate(true),
		"command_type_usec": _runtime_command_type_usec.duplicate(true),
		"command_requeue_count": _runtime_command_requeue_count.duplicate(true),
		"effect_count": effect_count,
		"command_queue_after_tick": command_queue.size(),
		"effect_queue_after_tick": effects_queue.size(),
		"registered_unit_count": _count_runtime_registered_units(),
		"known_unit_count": _known_units_by_id.size(),
		"navigation": get_navigation_debug_snapshot(),
		"hex_movement":get_hex_movement_audit_snapshot(),
		"unit_minimum_spacing": get_unit_minimum_spacing_debug_snapshot(),
		"hotpath_audit": {
			"authority_root": "SimulationRoot",
			"command_queue_scope": "drain_order_apply",
			"effect_queue_scope": "drain_order_apply",
			"unit_lookup_source": "UnitRegistry_or_known_units",
			"viewer_paths_read_only": true,
		},
	}
	var record_usec := Time.get_ticks_usec() - record_started_usec
	_runtime_tick_budget_debug_snapshot["debug_record_usec"] = record_usec
	var frame_scopes: Dictionary = profile_scopes.duplicate()
	frame_scopes["debug_record_usec"] = record_usec
	_runtime_frame_budget_debug.record_sample(Engine.get_process_frames(), Time.get_ticks_usec() - tick_started_usec, frame_scopes, tick_counter)


func _count_runtime_registered_units() -> int:
	var unit_registry = _get_unit_registry()
	if unit_registry != null and unit_registry.has_method("get_all_units"):
		return Array(unit_registry.call("get_all_units")).size()
	return _known_units_by_id.size()


func set_local_avoidance_enabled(enabled: bool) -> void:
	local_avoidance_enabled = enabled
	_local_avoidance_prepared_tick = -1
	if not local_avoidance_enabled:
		_local_avoidance_resolver.clear()


func set_local_avoidance_debug_enabled(enabled: bool) -> void:
	local_avoidance_debug_enabled = enabled
	if not local_avoidance_debug_enabled:
		_local_avoidance_debug_by_unit_id.clear()


func get_local_avoidance_debug_snapshot(unit_id: String = "") -> Variant:
	if unit_id.strip_edges().is_empty():
		var result: Array = []
		var unit_ids: Array = _local_avoidance_debug_by_unit_id.keys()
		unit_ids.sort()
		for unit_id_variant in unit_ids:
			result.append(Dictionary(_local_avoidance_debug_by_unit_id.get(unit_id_variant, {})).duplicate(true))
		return result
	return Dictionary(_local_avoidance_debug_by_unit_id.get(unit_id.strip_edges(), {})).duplicate(true)


func set_bottleneck_reservation_enabled(enabled: bool) -> void:
	bottleneck_reservation_enabled = enabled
	if not bottleneck_reservation_enabled:
		_bottleneck_reservation_resolver.clear()
		_bottleneck_reservation_debug_snapshot.clear()


func set_bottleneck_reservation_debug_enabled(enabled: bool) -> void:
	bottleneck_reservation_debug_enabled = enabled
	if not bottleneck_reservation_debug_enabled:
		_bottleneck_reservation_debug_snapshot.clear()


func get_bottleneck_reservation_debug_snapshot() -> Dictionary:
	return _bottleneck_reservation_debug_snapshot.duplicate(true)


func resolve_bottleneck_reservation_for_commands(commands: Array, candidates: Array, options: Dictionary = {}) -> Dictionary:
	if is_hex_ground_runtime_active():return {}
	if not bottleneck_reservation_enabled:
		return {}
	var plan_options: Dictionary = options.duplicate(true)
	if not plan_options.has("start_tick"):
		plan_options["start_tick"] = tick_counter
	if not plan_options.has("horizon_ticks"):
		plan_options["horizon_ticks"] = bottleneck_reservation_horizon_ticks
	var plan: Dictionary = Dictionary(_bottleneck_reservation_resolver.call("build_reservation_plan", commands, candidates, plan_options))
	var decisions_by_unit_id: Dictionary = Dictionary(plan.get("decisions_by_unit_id", {}))
	for command_variant in commands:
		if typeof(command_variant) != TYPE_DICTIONARY:
			continue
		var command: Dictionary = Dictionary(command_variant)
		var unit_id: String = String(command.get("unit_id", ""))
		if decisions_by_unit_id.has(unit_id):
			_bottleneck_reservation_resolver.call("apply_reservation_metadata", command, Dictionary(decisions_by_unit_id.get(unit_id, {})))
	if bottleneck_reservation_debug_enabled:
		_bottleneck_reservation_debug_snapshot = plan.duplicate(true)
	return plan


func resolve_bottleneck_reservation_for_command(command: Dictionary, bottleneck_cells: Array, current_tick: int = -1, options: Dictionary = {}) -> Dictionary:
	if is_hex_ground_runtime_active():return {}
	if not bottleneck_reservation_enabled:
		return {}
	var plan_options: Dictionary = options.duplicate(true)
	if not plan_options.has("horizon_ticks"):
		plan_options["horizon_ticks"] = bottleneck_reservation_horizon_ticks
	var resolved_tick: int = tick_counter if current_tick < 0 else current_tick
	var decision: Dictionary = Dictionary(_bottleneck_reservation_resolver.call("resolve_command", command, bottleneck_cells, resolved_tick, plan_options))
	if bottleneck_reservation_debug_enabled:
		_bottleneck_reservation_debug_snapshot = _bottleneck_reservation_resolver.call("get_debug_snapshot")
	return decision


func set_unit_minimum_spacing_enabled(enabled: bool) -> void:
	unit_minimum_spacing_enabled = enabled
	if not unit_minimum_spacing_enabled:
		_unit_minimum_spacing_debug_snapshot.clear()


func get_unit_minimum_spacing_debug_snapshot() -> Dictionary:
	return _unit_minimum_spacing_debug_snapshot.duplicate(true)


func clear_queues() -> void:
	command_queue.clear()
	effects_queue.clear()


func get_tick() -> int:
	return tick_counter


func set_combat_rng_seed(seed_value: int) -> void:
	combat_rng_seed = seed_value
	_combat_rng.seed = int(seed_value)


func get_next_combat_roll() -> float:
	if is_inside_tree() and _should_skip_local_tick_processing(): return NAN
	return _combat_rng.randf()


func export_gameplay_rng_state() -> Dictionary:
	return preload("res://scripts/core/gameplay_rng_state.gd").capture(self)


func get_last_damage_effect_resolution() -> Dictionary:
	return _last_damage_effect_resolution.duplicate(true)


func register_known_unit(unit_id: String, unit: Node) -> bool:
	if unit_id.is_empty() or unit == null:
		return false
	if is_hex_ground_runtime_active():
		var registry=get_unit_registry()
		var registered=registry.call("get_unit",unit_id) if registry!=null and registry.has_method("get_unit") else null
		if is_instance_valid(registered) and registered!=unit:return false
		var previous=_known_units_by_id.get(unit_id,null)
		if is_instance_valid(previous) and previous!=unit:return false
		if unit.has_method("get_unit_id") and String(unit.call("get_unit_id"))!=unit_id:return false

	_known_units_by_id[unit_id] = unit
	var on_exit:Callable=Callable(self,"_on_hex_known_unit_tree_exiting").bind(unit_id,unit.get_instance_id())
	if not unit.tree_exiting.is_connected(on_exit):unit.tree_exiting.connect(on_exit)
	if is_hex_ground_runtime_active() and _hex_ground_runtime.has_unit(unit_id):
		_hex_visual_unit_ids[unit_id]=true
		_project_hex_ground_actors(0.0)
	return true


func _on_hex_known_unit_tree_exiting(unit_id:String,instance_id:int)->void:
	if not is_hex_ground_runtime_active():return
	var known=_known_units_by_id.get(unit_id,null)
	var registry=get_unit_registry()
	var registered=registry.call("get_unit",unit_id) if registry!=null else null
	if is_instance_valid(known) and known.get_instance_id()==instance_id:
		unregister_known_unit(unit_id)
	elif not is_instance_valid(known) and is_instance_valid(registered) and registered.get_instance_id()==instance_id:
		release_hex_ground_unit(unit_id,"actor_exiting")
	if is_instance_valid(registered) and registered.get_instance_id()==instance_id:registry.call("unregister_unit",unit_id)


func unregister_known_unit(unit_id: String) -> void:
	_discard_pending_move_commands_for_unit(unit_id)
	if is_hex_ground_runtime_active():release_hex_ground_unit(unit_id,"unregistered")
	_known_units_by_id.erase(unit_id)
	_latest_command_token_by_unit_id.erase(unit_id)
	_committed_command_token_by_unit_id.erase(unit_id)
	_contact_path_recompute_ready_at_msec.erase(unit_id)


func set_peer_team(peer_id: int, team_id: String) -> void:
	if peer_id <= 0:
		return

	var normalized_team_id: String = team_id.strip_edges()
	if normalized_team_id.is_empty():
		_peer_team_assignments.erase(peer_id)
		return

	_peer_team_assignments[peer_id] = normalized_team_id
	if not _peer_role_assignments.has(peer_id):
		_peer_role_assignments[peer_id] = "commander"


func set_peer_team_assignments(assignments: Dictionary) -> void:
	_peer_team_assignments.clear()
	for raw_peer_id in assignments.keys():
		var peer_id: int = int(raw_peer_id)
		var team_id: String = String(assignments[raw_peer_id]).strip_edges()
		if peer_id <= 0 or team_id.is_empty():
			continue

		_peer_team_assignments[peer_id] = team_id

	if not _peer_team_assignments.has(1):
		_peer_team_assignments[1] = "team_alpha"
	if not _peer_role_assignments.has(1):
		_peer_role_assignments[1] = "commander"


func get_peer_team(peer_id: int) -> String:
	if peer_id <= 0:
		return ""

	return String(_peer_team_assignments.get(peer_id, ""))


func set_peer_role(peer_id: int, role_id: String) -> void:
	if peer_id <= 0:
		return
	var normalized_role_id: String = role_id.strip_edges().to_lower()
	if normalized_role_id.is_empty():
		_peer_role_assignments.erase(peer_id)
		return
	if not MULTIPLAYER_COMMAND_CONTRACT_SCRIPT.call("is_allowed_role", normalized_role_id):
		push_warning("SimulationRoot rejected an unknown multiplayer peer role.")
		return
	_peer_role_assignments[peer_id] = normalized_role_id


func set_peer_role_assignments(assignments: Dictionary) -> void:
	_peer_role_assignments.clear()
	for raw_peer_id in assignments.keys():
		set_peer_role(int(raw_peer_id), String(assignments[raw_peer_id]))
	if not _peer_role_assignments.has(1):
		_peer_role_assignments[1] = "commander"


func get_peer_role(peer_id: int) -> String:
	if peer_id <= 0:
		return ""
	return String(_peer_role_assignments.get(peer_id, "commander"))


func set_peer_fireteams(peer_id: int, fireteam_ids: Variant) -> void:
	if peer_id <= 0:
		return
	var normalized_fireteam_ids: PackedStringArray = PackedStringArray()
	for fireteam_id_variant in Array(fireteam_ids):
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or normalized_fireteam_ids.has(fireteam_id):
			continue
		normalized_fireteam_ids.append(fireteam_id)
	if normalized_fireteam_ids.is_empty():
		_peer_fireteam_assignments.erase(peer_id)
		return
	_peer_fireteam_assignments[peer_id] = normalized_fireteam_ids


func set_peer_fireteam_assignments(assignments: Dictionary) -> void:
	_peer_fireteam_assignments.clear()
	for raw_peer_id in assignments.keys():
		set_peer_fireteams(int(raw_peer_id), assignments[raw_peer_id])


func get_peer_fireteams(peer_id: int) -> PackedStringArray:
	if peer_id <= 0:
		return PackedStringArray()
	return PackedStringArray(_peer_fireteam_assignments.get(peer_id, PackedStringArray()))


func get_network_command_contract_snapshot() -> Dictionary:
	return {
		"accepted_count": _network_command_accept_count,
		"rejected_count": _network_command_reject_count,
		"last_rejection": _last_network_command_rejection.duplicate(true),
		"peer_teams": _peer_team_assignments.duplicate(true),
		"peer_roles": _peer_role_assignments.duplicate(true),
		"peer_fireteams": _duplicate_peer_fireteam_assignments(),
	}


func get_last_server_state() -> Dictionary:
	return _last_server_state.duplicate(true)


func get_last_network_command_result() -> Dictionary:
	return _last_network_command_result.duplicate(true)


func set_network_command_preflight_validator(validator: Callable) -> void:
	_network_command_preflight_validator = validator


func clear_network_command_preflight_validator(validator: Callable = Callable()) -> void:
	if not validator.is_valid() or _network_command_preflight_validator == validator:
		_network_command_preflight_validator = Callable()


func get_authoritative_fire_rule_state(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() or not _authoritative_fire_rules_by_fireteam.has(normalized_fireteam_id):
		return {}
	return Dictionary(_authoritative_fire_rules_by_fireteam[normalized_fireteam_id]).duplicate(true)


func get_authoritative_fire_rule_snapshot() -> Array:
	var fireteam_ids: Array = _authoritative_fire_rules_by_fireteam.keys()
	fireteam_ids.sort()
	var result: Array = []
	for fireteam_id_variant in fireteam_ids:
		result.append(Dictionary(_authoritative_fire_rules_by_fireteam[fireteam_id_variant]).duplicate(true))
	return result


# Session identity is assigned by the verified Lobby before scene activation.
# No gameplay, sight or transport ownership is stored in this projection binding.
const MULTIPLAYER_TERRAIN_FOG = preload("res://scripts/multiplayer/multiplayer_terrain_fog_projection.gd")
var _multiplayer_terrain_fog_sent: Dictionary = {}
const VISIBLE_MULTIPLAYER_PROJECTION = preload("res://scripts/multiplayer/multiplayer_visible_snapshot_projection.gd")
var _multiplayer_runtime_context: Dictionary = {}
var _multiplayer_runtime_context_required: bool = false
var _multiplayer_local_team: String = ""
var _multiplayer_raw_snapshot_context: Dictionary = {}
var _multiplayer_replica_visible_ids: Dictionary = {}
var _multiplayer_has_full_projection: bool = false
var _multiplayer_presence_guard_active: bool = false


func validate_multiplayer_runtime_context_binding(context: Dictionary, local_team: String) -> Dictionary:
	if not _valid_multiplayer_runtime_context(context) or local_team.is_empty() or local_team != local_team.strip_edges().to_lower():
		return {"ok":false,"reason":"invalid_multiplayer_runtime_context"}
	if not _multiplayer_runtime_context.is_empty() and context != _multiplayer_runtime_context:
		return {"ok":false,"reason":"multiplayer_runtime_context_already_bound"}
	return {"ok":true}


func bind_multiplayer_runtime_context(context: Dictionary, local_team: String) -> Dictionary:
	var validation: Dictionary=validate_multiplayer_runtime_context_binding(context,local_team)
	if not validation.ok: return validation
	_multiplayer_runtime_context_required=true
	if not _multiplayer_runtime_context.is_empty():
		if context != _multiplayer_runtime_context:
			return {"ok":false,"reason":"multiplayer_runtime_context_already_bound"}
		if _multiplayer_local_team != local_team:
			_reset_multiplayer_terrain_fog_binding(local_team)
			_multiplayer_replica_visible_ids.clear()
			_multiplayer_has_full_projection=false
			_incoming_snapshot_chunks_by_tick.clear()
		_multiplayer_local_team = local_team
		refresh_multiplayer_replica_presence()
		return {"ok":true}
	_multiplayer_runtime_context = context.duplicate(true)
	_reset_multiplayer_terrain_fog_binding(local_team)
	_multiplayer_local_team = local_team
	_incoming_snapshot_chunks_by_tick.clear()
	_last_applied_snapshot_tick = -1
	_last_applied_vital_tick_by_unit_id.clear()
	_multiplayer_replica_visible_ids.clear()
	_multiplayer_has_full_projection = false
	refresh_multiplayer_replica_presence()
	return {"ok":true}


func clear_multiplayer_runtime_context() -> void:
	_reset_multiplayer_terrain_fog_binding("")
	_multiplayer_runtime_context_required = requires_multiplayer_runtime_context()
	_multiplayer_runtime_context.clear()
	_multiplayer_local_team = ""
	_multiplayer_snapshot_context.clear()
	_multiplayer_raw_snapshot_context.clear()
	_last_server_state.clear()
	_multiplayer_replica_visible_ids.clear()
	_multiplayer_has_full_projection = false
	_incoming_snapshot_chunks_by_tick.clear()
	refresh_multiplayer_replica_presence()


func _reset_multiplayer_terrain_fog_binding(team: String) -> void:
	_multiplayer_terrain_fog_sent.clear()
	var setup = get_parent().get_node_or_null("MissionSetup") if get_parent() != null else null
	if setup != null and setup.has_method("reset_multiplayer_terrain_fog_projection"):
		setup.reset_multiplayer_terrain_fog_projection(team)


func get_multiplayer_runtime_context() -> Dictionary:
	return _multiplayer_runtime_context.duplicate(true)


func _valid_multiplayer_runtime_context(context: Dictionary) -> bool:
	for key in context:
		if key not in ["schema","runtime_token","map_id","map_hash","scenario_hash"] or not context[key] is String:
			return false
	if context.get("schema") != "multiplayer.runtime_context.v1": return false
	var token: String = context.get("runtime_token","")
	var map_hash: String = context.get("map_hash","")
	var map_id: String = context.get("map_id","")
	if token.length()!=32 or not token.is_valid_hex_number(false) or map_hash.length()!=64 or not map_hash.is_valid_hex_number(false): return false
	if map_id.is_empty() or map_id.length()>256 or map_id!=map_id.strip_edges(): return false
	if context.has("scenario_hash"):
		var scenario: String=context.scenario_hash
		if scenario.length()!=64 or not scenario.is_valid_hex_number(false): return false
	return true


func requires_multiplayer_runtime_context() -> bool:
	if _multiplayer_runtime_context_required or is_hex_ground_runtime_required(): return true
	# Clients do not configure the authoritative Ground owner. The actual loaded
	# map declaration must still prevent a contextless Hex client/host downgrade.
	var setup = get_parent().get_node_or_null("MissionSetup") if get_parent()!=null else null
	var map = setup.get("_loaded_terrain_map_data") if setup!=null else null
	return map!=null and map.has_method("get_tactical_grid_rules") and String(map.call("get_tactical_grid_rules"))=="hex_tactical_v1"


func uses_legacy_multiplayer_wire() -> bool:
	return not requires_multiplayer_runtime_context() and _multiplayer_runtime_context.is_empty()


func accepts_multiplayer_runtime_context(context: Dictionary) -> bool:
	if _multiplayer_runtime_context.is_empty(): return context.is_empty() and uses_legacy_multiplayer_wire()
	return context == _multiplayer_runtime_context


func _multiplayer_wire_ready() -> bool:
	return not _multiplayer_runtime_context.is_empty() or uses_legacy_multiplayer_wire()


func submit_multiplayer_command(command: Dictionary) -> void:
	if _has_active_multiplayer_peer() and not multiplayer.is_server():
		if not _multiplayer_wire_ready(): return
		request_command.rpc_id(1,command,_multiplayer_runtime_context.duplicate(true))
	else:
		request_command(command,_multiplayer_runtime_context.duplicate(true))


func _multiplayer_replica_mode() -> bool:
	return requires_multiplayer_runtime_context() and is_inside_tree() and _has_active_multiplayer_peer() and not multiplayer.is_server()


# Registry/Known union only. Source calls this again after actor admission;
# no SceneTree traversal, no gameplay registration/removal or selection mutation.
func refresh_multiplayer_replica_presence() -> void:
	if not _multiplayer_replica_mode() or _multiplayer_presence_guard_active: return
	_multiplayer_presence_guard_active = true
	var units: Dictionary = _known_units_by_id.duplicate()
	var registry = _get_unit_registry()
	if registry != null and registry.has_method("get_all_units"):
		for unit in registry.call("get_all_units"):
			if is_instance_valid(unit) and unit.has_method("get_unit_id"):
				units[String(unit.call("get_unit_id"))] = unit
	for id in units:
		var actor = units[id]
		if not is_instance_valid(actor) or not actor is CanvasItem: continue
		var guard: Callable = Callable(self,"_on_multiplayer_replica_visibility_changed").bind(actor.get_instance_id(),String(id))
		if not actor.visibility_changed.is_connected(guard): actor.visibility_changed.connect(guard)
		if not _multiplayer_replica_actor_allowed(actor,String(id)): actor.hide()
	_multiplayer_presence_guard_active = false


func _multiplayer_replica_actor_allowed(actor: Node, id: String) -> bool:
	if _multiplayer_runtime_context.is_empty(): return false
	if _multiplayer_has_full_projection: return _multiplayer_replica_visible_ids.has(id)
	return actor.has_method("get_team_id") and String(actor.call("get_team_id")) == _multiplayer_local_team


func _on_multiplayer_replica_visibility_changed(instance_id: int, id: String) -> void:
	if not _multiplayer_replica_mode() or _multiplayer_presence_guard_active: return
	var actor = instance_from_id(instance_id)
	if not is_instance_valid(actor) or not actor is CanvasItem or not actor.visible: return
	if not _multiplayer_replica_actor_allowed(actor,id):
		_multiplayer_presence_guard_active = true
		actor.hide()
		_multiplayer_presence_guard_active = false


func _get_multiplayer_visibility_context(raw: Dictionary, team: String) -> Dictionary:
	var own := PackedStringArray()
	var known: Dictionary = {}
	var fireteams: Dictionary = {}
	# Assigned teams/fireteams remain authoritative while all their actors are
	# embarked (and therefore absent from the current ground registry snapshot).
	for peer_id in _peer_fireteam_assignments:
		var assigned_team: String=get_peer_team(int(peer_id))
		if assigned_team.is_empty(): continue
		for ft in _peer_fireteam_assignments[peer_id]:
			if fireteams.has(ft) and fireteams[ft]!=assigned_team: return {}
			fireteams[ft]=assigned_team
	for unit: Dictionary in raw.get("units",[]):
		var id: String=String(unit.get("unit_id",""))
		var unit_team: String=String(unit.get("team_id",""))
		known[id]=unit_team
		if unit_team==team: own.append(id)
		var ft: String=String(unit.get("fireteam_id",""))
		if not ft.is_empty():
			if fireteams.has(ft) and fireteams[ft]!=unit_team: return {}
			fireteams[ft]=unit_team
	var driver = get_parent().get_node_or_null("CombatLoopDriver") if get_parent()!=null else null
	if driver==null or not driver.has_method("get_multiplayer_visible_unit_ids"): return {}
	var visible := PackedStringArray()
	for id in driver.call("get_multiplayer_visible_unit_ids",team):
		if known.has(id) and not visible.has(id): visible.append(id)
	var crafts: Dictionary = {}
	for card: Dictionary in raw.get("dropship",{}).get("mission_drop_cards",[]):
		var craft: String=String(card.get("craft_id",""))
		var teams: Dictionary={}
		for id in Array(card.get("embarked_unit_ids",[]))+[card.get("pilot_unit_id","")]:
			if known.has(id): teams[known[id]]=true
		for ft in card.get("boarded_fireteam_ids",[]):
			if fireteams.has(ft): teams[fireteams[ft]]=true
		var explicit: String=String(card.get("team_id",""))
		if not explicit.is_empty(): teams[explicit]=true
		if not craft.is_empty() and teams.size()==1: crafts[craft]=teams.keys()[0]
	var assets: Dictionary={}
	for asset: Dictionary in raw.get("air_asset_status",[]):
		if not String(asset.get("asset_id","")).is_empty() and not String(asset.get("team_id","")).is_empty():
			assets[asset.asset_id]=asset.team_id
	return {"reference_provenance":"host_raw","own_unit_ids":own,"visible_unit_ids":visible,"fireteam_team_ids":fireteams,"craft_team_ids":crafts,"asset_team_ids":assets}


func project_multiplayer_state_for_peer(peer_id: int, raw_state: Dictionary = {}) -> Dictionary:
	if _multiplayer_runtime_context.is_empty(): return {"ok":false,"reason":"multiplayer_runtime_context_required"}
	var raw: Dictionary = raw_state if not raw_state.is_empty() else _build_raw_multiplayer_tick_state()
	var team: String=get_peer_team(peer_id)
	var context: Dictionary=_get_multiplayer_visibility_context(raw,team)
	if context.is_empty(): return {"ok":false,"reason":"current_team_visibility_unavailable"}
	var projected: Dictionary=VISIBLE_MULTIPLAYER_PROJECTION.new().project_state(raw,team,context)
	if projected.get("ok",false):
		projected["runtime_context"]=_multiplayer_runtime_context.duplicate(true)
		_attach_multiplayer_terrain_fog(projected,team,false)
	return projected


func _attach_multiplayer_terrain_fog(projected: Dictionary, team: String, throttle: bool) -> void:
	var setup = get_node_or_null("../MissionSetup")
	if setup == null or not setup.has_method("get_multiplayer_terrain_fog_revision"): return
	var revision: String = setup.get_multiplayer_terrain_fog_revision(team)
	if revision.is_empty(): return
	var context_key: String = String(_multiplayer_runtime_context.get("runtime_token","")) + "|" + team
	var sent: Dictionary = _multiplayer_terrain_fog_sent.get(context_key,{})
	var now: int = Time.get_ticks_msec()
	# Repeat an unchanged revision at most once a second, repairing dropped
	# unreliable packets and new/rejoined recipients without per-tick tile lists.
	if throttle and sent.get("revision") == revision and now - int(sent.get("time",0)) < 1000: return
	projected["terrain_fog"] = setup.get_multiplayer_terrain_fog_snapshot(team)
	if throttle: _multiplayer_terrain_fog_sent[context_key] = {"revision":revision,"time":now}


func set_multiplayer_snapshot_context(context: Dictionary) -> void:
	for key in context:
		_multiplayer_raw_snapshot_context[key] = context[key].duplicate(true) if context[key] is Dictionary or context[key] is Array else context[key]
	var normalized_context: Dictionary = Dictionary(_multiplayer_snapshot_contract.call("normalize_display_context", context))
	var next_context: Dictionary = _multiplayer_snapshot_context.duplicate(true)
	if context.has("dropship"):
		next_context["dropship"] = Dictionary(normalized_context.get("dropship", {})).duplicate(true)
	if context.has("contacts"):
		next_context["contacts"] = Array(normalized_context.get("contacts", [])).duplicate(true)
	if context.has("enemy_security"):
		next_context["enemy_security"] = Array(normalized_context.get("enemy_security", [])).duplicate(true)
	if context.has("enemy_team_tactics"):
		next_context["enemy_team_tactics"] = Array(normalized_context.get("enemy_team_tactics", [])).duplicate(true)
	if context.has("character_gameplay"):
		next_context["character_gameplay"] = Array(normalized_context.get("character_gameplay", [])).duplicate(true)
	if context.has("fire_events"):
		next_context["fire_events"] = Array(normalized_context.get("fire_events", [])).duplicate(true)
	if context.has("feedback_bubbles"):
		next_context["feedback_bubbles"] = Array(normalized_context.get("feedback_bubbles", [])).duplicate(true)
	if context.has("fireteam_tactical"):
		next_context["fireteam_tactical"] = Array(normalized_context.get("fireteam_tactical", [])).duplicate(true)
	if context.has("commander_intents"):
		next_context["commander_intents"] = Array(normalized_context.get("commander_intents", [])).duplicate(true)
	if context.has("fireteam_plan_status"):
		next_context["fireteam_plan_status"] = Array(normalized_context.get("fireteam_plan_status", [])).duplicate(true)
	if context.has("communication_events"):
		next_context["communication_events"] = Array(normalized_context.get("communication_events", [])).duplicate(true)
	if context.has("tactical_rules"):
		next_context["tactical_rules"] = Array(normalized_context.get("tactical_rules", [])).duplicate(true)
	if context.has("breakout_states"):
		next_context["breakout_states"] = Array(normalized_context.get("breakout_states", [])).duplicate(true)
	if context.has("air_asset_status") or context.has("air_asset_statuses"):
		next_context["air_asset_status"] = Array(normalized_context.get("air_asset_status", [])).duplicate(true)
	if context.has("mission_interactions"):
		next_context["mission_interactions"] = Dictionary(normalized_context.get("mission_interactions", {})).duplicate(true)
	if context.has("mission_result"):
		next_context["mission_result"] = Dictionary(normalized_context.get("mission_result", {})).duplicate(true)
	_multiplayer_snapshot_context = next_context


func clear_multiplayer_snapshot_context() -> void:
	_multiplayer_snapshot_context.clear()
	_multiplayer_raw_snapshot_context.clear()


func get_multiplayer_snapshot_debug_snapshot() -> Dictionary:
	return {
		"last_applied_tick": _last_applied_snapshot_tick,
		"apply_count": _snapshot_apply_count,
		"out_of_order_count": _snapshot_out_of_order_count,
		"missing_unit_count": _snapshot_missing_unit_count,
		"last_reject_reason": _last_snapshot_reject_reason,
		"audio": get_snapshot_audio_debug_snapshot(),
		"transfer_contract": Dictionary(_multiplayer_snapshot_contract.call("get_transfer_contract")).duplicate(true),
	}


func get_snapshot_transport_debug_snapshot() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.snapshot_chunk_transport_debug.v1",
		"chunk_payload_budget_bytes": SNAPSHOT_CHUNK_PAYLOAD_BYTES,
		"last_chunk_count": _snapshot_transport_last_chunk_count,
		"last_max_chunk_payload_bytes": _snapshot_transport_last_max_chunk_payload_bytes,
		"last_raw_bytes": _snapshot_transport_last_raw_bytes,
		"last_wire_bytes": _snapshot_transport_last_wire_bytes,
		"reassembled_snapshot_count": _snapshot_transport_reassembled_count,
		"reassembly_failure_count": _snapshot_transport_reassembly_failure_count,
		"last_pack_usec": _snapshot_transport_last_pack_usec,
		"last_reassembly_usec": _snapshot_transport_last_reassembly_usec,
		"pending_tick_count": _incoming_snapshot_chunks_by_tick.size(),
		"max_pending_tick_count": SNAPSHOT_REASSEMBLY_MAX_PENDING_TICKS,
		"reassembly_timeout_msec": SNAPSHOT_REASSEMBLY_TIMEOUT_MSEC,
		"expired_tick_count": _snapshot_transport_expired_tick_count,
		"evicted_tick_count": _snapshot_transport_evicted_tick_count,
		"stale_chunk_count": _snapshot_transport_stale_chunk_count,
		"broadcast_paused": _snapshot_broadcast_paused,
		"blocked_peer_ids": _snapshot_blocked_peer_ids.keys(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func set_snapshot_broadcast_paused(paused: bool) -> void:
	_snapshot_broadcast_paused = paused


func set_snapshot_peer_blocked(peer_id: int, blocked: bool) -> void:
	if peer_id <= 1:
		return
	if blocked:
		_snapshot_blocked_peer_ids[peer_id] = true
	else:
		_snapshot_blocked_peer_ids.erase(peer_id)


func get_snapshot_audio_debug_snapshot() -> Dictionary:
	return {
		"played_count": _snapshot_audio_played_count,
		"suppressed_count": _snapshot_audio_suppressed_count,
		"played_event_ids": _snapshot_audio_event_ids_played.keys(),
		"last_result": _last_snapshot_audio_result.duplicate(true),
		"read_only_audio_events": true,
		"audio_sets_gameplay_state": false,
	}


func build_multiplayer_snapshot() -> Dictionary:
	return _build_tick_state()


func apply_multiplayer_snapshot(snapshot: Dictionary) -> Dictionary:
	return _apply_remote_state(snapshot)


func set_objective_status(objective_status) -> bool:
	if objective_status == null:
		_objective_status = null
		return true

	if not _is_valid_objective_status(objective_status):
		push_warning("SimulationRoot.set_objective_status expects a valid ObjectiveStatus-like object.")
		return false

	_objective_status = objective_status
	return true


func get_objective_status():
	return _objective_status


@rpc("any_peer", "reliable")
func request_command(command_dict: Dictionary, runtime_context: Dictionary = {}) -> void:
	# Existing in-process authority callers are trusted; remote RPCs must carry
	# the exact session identity, including when the caller omits the argument.
	if not accepts_multiplayer_runtime_context(runtime_context):
		if not runtime_context.is_empty() or not is_inside_tree() or multiplayer.get_remote_sender_id() != 0:
			return
	if not is_server_authoritative:
		enqueue_command(command_dict)
		return

	if _has_active_multiplayer_peer() and not multiplayer.is_server():
		_record_network_command_rejection(
			{
				"accepted": false,
				"reason": "request_on_non_authority",
			},
			command_dict,
			multiplayer.get_unique_id()
		)
		push_warning("SimulationRoot.request_command can only be executed on the authority while server-authoritative mode is active.")
		return

	var sending_peer_id: int = multiplayer.get_remote_sender_id()
	if sending_peer_id <= 0:
		sending_peer_id = 1

	var result: Dictionary = submit_network_command_for_peer(command_dict, sending_peer_id)
	_send_network_command_result(sending_peer_id, result, command_dict)
	if not bool(result.get("accepted", false)):
		push_warning("SimulationRoot rejected a network command: %s." % String(result.get("reason", "unknown")))
		return


@rpc("authority", "reliable")
func _receive_network_command_result(result: Dictionary, runtime_context: Dictionary = {}) -> void:
	if not accepts_multiplayer_runtime_context(runtime_context): return
	_last_network_command_result = result.duplicate(true)
	network_command_result_received.emit(_last_network_command_result.duplicate(true))


func _send_network_command_result(peer_id: int, result: Dictionary, command: Dictionary) -> void:
	if not _multiplayer_wire_ready(): return
	var payload: Dictionary = {
		"schema": "sternenbuergerchen.network_command_result.v1",
		"accepted": bool(result.get("accepted", false)),
		"reason": String(result.get("reason", "")).strip_edges(),
		"category": String(result.get("category", command.get("contract_category", ""))).strip_edges().to_lower(),
		"command_type": String(result.get("command_type", command.get("command_type", ""))).strip_edges().to_lower(),
		"team_id": String(result.get("team_id", command.get("team_id", ""))).strip_edges(),
		"fireteam_id": String(result.get("fireteam_id", command.get("fireteam_id", ""))).strip_edges().to_lower(),
		"craft_id": String(command.get("craft_id", "")).strip_edges(),
		"command_id": String(command.get("command_id", "")).strip_edges(),
		"duplicate": bool(result.get("duplicate", false)),
		"fire_rule": String(command.get("fire_rule", "")).strip_edges().to_lower(),
		"source_context": String(command.get("source_context", "")).strip_edges(),
		"interaction_id": String(command.get("interaction_id", "")).strip_edges(),
		"peer_id": peer_id,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}
	if _has_active_multiplayer_peer() and multiplayer.is_server() and peer_id > 1:
		_receive_network_command_result.rpc_id(peer_id, payload, _multiplayer_runtime_context.duplicate(true))
		return
	_receive_network_command_result(payload, _multiplayer_runtime_context.duplicate(true))


func validate_network_command_for_peer(command_dict: Dictionary, peer_id: int = 1) -> Dictionary:
	if typeof(command_dict) != TYPE_DICTIONARY:
		return {
			"accepted": false,
			"reason": "command_not_dictionary",
		}
	var validation: Dictionary = Dictionary(_multiplayer_command_contract.call("validate", command_dict, _build_network_command_context(command_dict, peer_id))).duplicate(true)
	if not bool(validation.get("accepted", false)) or not _network_command_preflight_validator.is_valid():
		return validation
	var accepted_command: Dictionary = Dictionary(validation.get("command", command_dict)).duplicate(true)
	var preflight_variant: Variant = _network_command_preflight_validator.call(accepted_command, peer_id)
	if typeof(preflight_variant) != TYPE_DICTIONARY:
		return validation
	var preflight: Dictionary = Dictionary(preflight_variant)
	if bool(preflight.get("accepted", true)):
		if typeof(preflight.get("command", null)) == TYPE_DICTIONARY:
			var canonical_command: Dictionary = Dictionary(preflight.get("command", {})).duplicate(true)
			validation["command"] = canonical_command
			for result_key in ["category", "command_type", "team_id", "fireteam_id"]:
				var command_key: String = "contract_category" if result_key == "category" else result_key
				if canonical_command.has(command_key):
					validation[result_key] = canonical_command[command_key]
		return validation
	validation["accepted"] = false
	validation["reason"] = String(preflight.get("reason", "network_command_preflight_rejected")).strip_edges()
	return validation


func submit_network_command_for_peer(command_dict: Dictionary, peer_id: int = 1) -> Dictionary:
	if not is_server_authoritative:
		enqueue_command(command_dict)
		return {
			"accepted": true,
			"reason": "",
			"peer_id": peer_id,
			"command": command_dict.duplicate(true),
		}

	var sending_peer_id: int = peer_id if peer_id > 0 else 1
	var validation: Dictionary = validate_network_command_for_peer(command_dict, sending_peer_id)
	if not bool(validation.get("accepted", false)):
		_record_network_command_rejection(validation, command_dict, sending_peer_id)
		return validation

	var accepted_command: Dictionary = Dictionary(validation.get("command", command_dict)).duplicate(true)
	var command_id: String = String(accepted_command.get("command_id", "")).strip_edges()
	if String(validation.get("category", "")).strip_edges() == "dropship_command" and not command_id.is_empty():
		if _accepted_network_dropship_command_ids.has(command_id):
			_network_command_dedupe_hit_count += 1
			validation["duplicate"] = true
			validation["command"] = accepted_command
			return validation
		_register_accepted_network_dropship_command_id(command_id)
	_network_command_accept_count += 1
	enqueue_command(accepted_command)
	network_command_accepted.emit(accepted_command.duplicate(true), sending_peer_id)
	return validation


func _register_accepted_network_dropship_command_id(command_id: String) -> void:
	var normalized_command_id: String = command_id.strip_edges()
	if normalized_command_id.is_empty() or _accepted_network_dropship_command_ids.has(normalized_command_id):
		return
	_accepted_network_dropship_command_ids[normalized_command_id] = true
	_accepted_network_dropship_command_id_order.append(normalized_command_id)
	while _accepted_network_dropship_command_id_order.size() > NETWORK_COMMAND_DEDUPE_MAX_IDS:
		var expired_command_id: String = String(_accepted_network_dropship_command_id_order.pop_front())
		_accepted_network_dropship_command_ids.erase(expired_command_id)


func get_network_command_dedupe_debug_snapshot() -> Dictionary:
	return {
		"cached_id_count": _accepted_network_dropship_command_ids.size(),
		"max_cached_ids": NETWORK_COMMAND_DEDUPE_MAX_IDS,
		"dedupe_hit_count": _network_command_dedupe_hit_count,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


@rpc("authority", "unreliable_ordered")
func _receive_tick_state(state_dict: Dictionary) -> void:
	_apply_remote_state(state_dict)


@rpc("authority", "unreliable")
func _receive_bound_tick_state_chunk(tick: int, chunk_index: int, chunk_count: int, raw_size: int, compressed: bool, chunk: PackedByteArray, runtime_token: String) -> void:
	# The full map/scenario context is already bound to this Root and remains in
	# the reassembled snapshot. Repeating it on every 1000-byte chunk exceeds MTU.
	if _multiplayer_runtime_context.is_empty() or runtime_token != String(_multiplayer_runtime_context.get("runtime_token", "")):
		return
	_receive_tick_state_chunk(tick, chunk_index, chunk_count, raw_size, compressed, chunk, _multiplayer_runtime_context)


@rpc("authority", "unreliable")
func _receive_tick_state_chunk(tick: int, chunk_index: int, chunk_count: int, raw_size: int, compressed: bool, chunk: PackedByteArray, runtime_context: Dictionary = {}) -> void:
	if not accepts_multiplayer_runtime_context(runtime_context): return
	if tick < 0 or chunk_count <= 0 or chunk_count > SNAPSHOT_MAX_CHUNK_COUNT or chunk_index < 0 or chunk_index >= chunk_count or raw_size <= 0 or raw_size > SNAPSHOT_MAX_RAW_BYTES:
		_snapshot_transport_reassembly_failure_count += 1
		return
	if chunk.size() > SNAPSHOT_CHUNK_PAYLOAD_BYTES:
		_snapshot_transport_reassembly_failure_count += 1
		return
	if tick <= _last_applied_snapshot_tick:
		_snapshot_transport_stale_chunk_count += 1
		return
	_prune_incoming_snapshot_chunks(tick)
	var entry: Dictionary = Dictionary(_incoming_snapshot_chunks_by_tick.get(tick, {}))
	if not entry.is_empty() and (int(entry.get("chunk_count", -1)) != chunk_count or int(entry.get("raw_size", -1)) != raw_size or bool(entry.get("compressed", false)) != compressed):
		_snapshot_transport_reassembly_failure_count += 1
		return
	if entry.is_empty():
		entry = {
			"first_received_msec": Time.get_ticks_msec(),
			"chunk_count": chunk_count,
			"raw_size": raw_size,
			"compressed": compressed,
			"chunks": {},
		}
	var chunks: Dictionary = Dictionary(entry.get("chunks", {}))
	chunks[chunk_index] = chunk.duplicate()
	entry["chunks"] = chunks
	_incoming_snapshot_chunks_by_tick[tick] = entry
	_prune_incoming_snapshot_chunks(tick)
	if not _incoming_snapshot_chunks_by_tick.has(tick):
		return
	if chunks.size() < chunk_count:
		return
	var reassembly_started_usec: int = Time.get_ticks_usec()
	var wire_bytes := PackedByteArray()
	for index in range(chunk_count):
		if not chunks.has(index):
			_snapshot_transport_reassembly_failure_count += 1
			return
		wire_bytes.append_array(PackedByteArray(chunks[index]))
	_incoming_snapshot_chunks_by_tick.erase(tick)
	var raw_bytes: PackedByteArray = wire_bytes.decompress(raw_size, SNAPSHOT_COMPRESSION_MODE) if compressed else wire_bytes
	if raw_bytes.size() != raw_size:
		_snapshot_transport_reassembly_failure_count += 1
		return
	var decoded: Variant = bytes_to_var(raw_bytes)
	if typeof(decoded) != TYPE_DICTIONARY:
		_snapshot_transport_reassembly_failure_count += 1
		return
	if int(decoded.get("tick", -1)) != tick:
		_snapshot_transport_reassembly_failure_count += 1
		return
	_snapshot_transport_reassembled_count += 1
	_apply_remote_state(Dictionary(decoded))
	_prune_incoming_snapshot_chunks(tick)
	_snapshot_transport_last_reassembly_usec = Time.get_ticks_usec() - reassembly_started_usec


func _prune_incoming_snapshot_chunks(_latest_tick: int) -> void:
	var now_msec: int = Time.get_ticks_msec()
	for tick_variant in _incoming_snapshot_chunks_by_tick.keys():
		var entry: Dictionary = _incoming_snapshot_chunks_by_tick[tick_variant]
		if int(tick_variant) <= _last_applied_snapshot_tick:
			_incoming_snapshot_chunks_by_tick.erase(tick_variant)
		elif now_msec - int(entry.get("first_received_msec", now_msec)) >= SNAPSHOT_REASSEMBLY_TIMEOUT_MSEC:
			_incoming_snapshot_chunks_by_tick.erase(tick_variant)
			_snapshot_transport_expired_tick_count += 1
	if _incoming_snapshot_chunks_by_tick.size() > SNAPSHOT_REASSEMBLY_MAX_PENDING_TICKS:
		var pending_ticks: Array = _incoming_snapshot_chunks_by_tick.keys()
		pending_ticks.sort()
		while _incoming_snapshot_chunks_by_tick.size() > SNAPSHOT_REASSEMBLY_MAX_PENDING_TICKS:
			_incoming_snapshot_chunks_by_tick.erase(pending_ticks.pop_front())
			_snapshot_transport_evicted_tick_count += 1


@rpc("authority", "reliable")
func _receive_vital_state_updates(vital_updates: Array, runtime_context: Dictionary = {}, recipient_team: String = "") -> void:
	if not accepts_multiplayer_runtime_context(runtime_context): return
	if not _multiplayer_runtime_context.is_empty() and recipient_team != _multiplayer_local_team: return
	for vital_update in vital_updates:
		if typeof(vital_update) != TYPE_DICTIONARY:
			continue

		var unit_id: String = String(vital_update.get("unit_id", "")).strip_edges()
		var unit = _resolve_known_unit(unit_id)
		if unit == null or not unit.has_method("apply_remote_vital_update"):
			continue
		if not _accept_remote_vital_tick(unit_id, vital_update):
			continue

		unit.call("apply_remote_vital_update", vital_update)


func _has_remote_vital_fields(payload: Dictionary) -> bool:
	return payload.has("vital_state") or payload.has("health") or payload.has("bleedout_ticks")


func _accept_remote_vital_tick(unit_id: String, payload: Dictionary, snapshot_tick: int = -1) -> bool:
	if not _has_remote_vital_fields(payload):
		return false
	var previous_tick: int = int(_last_applied_vital_tick_by_unit_id.get(unit_id, -1))
	var vital_tick: int = int(payload.get("vital_tick", snapshot_tick))
	if vital_tick < 0:
		# Legacy reliable data is usable only before this unit has ordered state.
		return previous_tick < 0
	if vital_tick <= previous_tick:
		return false
	_last_applied_vital_tick_by_unit_id[unit_id] = vital_tick
	return true


func _copy_current_remote_vitals(unit, payload: Dictionary) -> void:
	var current_vitals: Dictionary = _build_unit_vital_update(unit)
	if current_vitals.is_empty():
		for key in ["vital_state", "health", "bleedout_ticks", "vital_tick"]:
			payload.erase(key)
		return
	payload.merge(current_vitals, true)
	payload["vital_tick"] = int(_last_applied_vital_tick_by_unit_id.get(String(current_vitals["unit_id"]), -1))


func _process(_delta: float) -> void:
	_project_hex_ground_actors(Engine.get_physics_interpolation_fraction())
	# A stopped packet stream must not retain incomplete buffers indefinitely.
	if _incoming_snapshot_chunks_by_tick.is_empty():
		return
	var now_msec: int = Time.get_ticks_msec()
	if now_msec < _snapshot_transport_next_prune_msec:
		return
	_snapshot_transport_next_prune_msec = now_msec + 250
	_prune_incoming_snapshot_chunks(-1)


# Commands are committed before effects on every authoritative physics tick.
func _physics_process(delta: float) -> void:
	if _should_skip_local_tick_processing():
		return
	if _space_runtime_tick.is_valid():
		_space_runtime_tick.call(delta)
		_space_combat_state.sync_moved_actors()

	_last_tick_delta = maxf(delta, 0.0)
	var profile_enabled: bool = runtime_tick_budget_debug_enabled
	var tick_started_usec: int = Time.get_ticks_usec() if profile_enabled else 0
	var profile_scopes: Dictionary = {}
	var scope_started_usec: int = 0

	tick_counter += 1
	if _space_runtime_tick.is_valid():
		_advance_space_flights(delta, tick_counter)
	_advance_air_support_orders(delta)
	is_processing_tick = true
	_hex_boundary_facing.clear()
	_begin_navigation_budget_tick()
	_advance_hex_ground_tick()
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	_prepare_local_avoidance_tick()
	if profile_enabled:
		profile_scopes["local_avoidance_prepare_usec"] = Time.get_ticks_usec() - scope_started_usec

	var commands: Array = _drain_queue(command_queue)
	var command_count: int = commands.size()
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
		_process_commands_profiled(commands, delta)
		profile_scopes["command_ordering_usec"] = _runtime_command_ordering_usec
		profile_scopes["command_apply_usec"] = _runtime_command_apply_usec
	else:
		_process_commands(commands, delta)
	if profile_enabled:
		profile_scopes["command_queue_usec"] = Time.get_ticks_usec() - scope_started_usec

	if profile_enabled:scope_started_usec=Time.get_ticks_usec()
	if is_hex_ground_runtime_active():_hex_movement_runtime.tick(delta)
	if profile_enabled:profile_scopes["hex_move_plan_usec"]=Time.get_ticks_usec()-scope_started_usec
	_commit_hex_facing_intents()
	_project_hex_ground_actors(0.0)
	var effects: Array = _drain_queue(effects_queue)
	var effect_count: int = effects.size()
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	_process_effects(effects, delta)
	if _hex_movement_runtime.flush_stops():_project_hex_ground_actors(0.0)
	if profile_enabled:
		profile_scopes["effect_queue_usec"] = Time.get_ticks_usec() - scope_started_usec
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	_enforce_unit_minimum_spacing()
	if profile_enabled:
		profile_scopes["unit_minimum_spacing_usec"] = Time.get_ticks_usec() - scope_started_usec
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	_update_objective_capture()
	if profile_enabled:
		profile_scopes["objective_capture_usec"] = Time.get_ticks_usec() - scope_started_usec

	_finish_navigation_budget_tick()
	is_processing_tick = false
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	_broadcast_tick_state()
	if profile_enabled:
		profile_scopes["snapshot_broadcast_usec"] = Time.get_ticks_usec() - scope_started_usec
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	tick_processed.emit(tick_counter)
	if profile_enabled:
		profile_scopes["tick_signal_emit_usec"] = Time.get_ticks_usec() - scope_started_usec
		_record_runtime_tick_budget_debug_snapshot(delta, tick_started_usec, profile_scopes, command_count, effect_count)


func get_last_tick_delta() -> float:
	return _last_tick_delta


func _should_skip_local_tick_processing() -> bool:
	if not is_server_authoritative:
		return false

	if not _has_active_multiplayer_peer():
		return false

	return not multiplayer.is_server()


func _has_active_multiplayer_peer() -> bool:
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer == null:
		return false

	return peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED


func _is_valid_network_command(command_dict: Dictionary) -> bool:
	return bool(validate_network_command_for_peer(command_dict, 1).get("accepted", false))


func _build_network_command_context(command_dict: Dictionary, peer_id: int) -> Dictionary:
	var unit_id: String = String(command_dict.get("unit_id", "")).strip_edges()
	var unit = _resolve_known_unit_for_contract(unit_id)
	var unit_team_id: String = ""
	var unit_fireteam_id: String = ""
	if unit != null:
		if unit.has_method("get_team_id"):
			unit_team_id = String(unit.call("get_team_id")).strip_edges()
		if unit.has_method("get_fireteam_id"):
			unit_fireteam_id = String(unit.call("get_fireteam_id")).strip_edges().to_lower()

	var craft_id: String = String(command_dict.get("craft_id", "")).strip_edges()
	var craft_exists := false
	var craft_fireteam_ids := PackedStringArray()
	if not craft_id.is_empty():
		var dropship_context: Dictionary = Dictionary(_multiplayer_snapshot_context.get("dropship", {}))
		for card_variant in Array(dropship_context.get("mission_drop_cards", [])):
			if typeof(card_variant) != TYPE_DICTIONARY:
				continue
			var card: Dictionary = Dictionary(card_variant)
			if String(card.get("craft_id", "")).strip_edges() != craft_id:
				continue
			craft_exists = true
			craft_fireteam_ids = PackedStringArray(Array(card.get("boarded_fireteam_ids", [])))
			break

	return {
		"peer_id": peer_id,
		"peer_role": get_peer_role(peer_id),
		"peer_team_id": get_peer_team(peer_id),
		"peer_fireteam_ids": get_peer_fireteams(peer_id),
		"unit_team_id": unit_team_id,
		"unit_fireteam_id": unit_fireteam_id,
		"craft_exists": craft_exists,
		"craft_fireteam_ids": craft_fireteam_ids,
	}


func _resolve_known_unit_for_contract(unit_id: String):
	if unit_id.strip_edges().is_empty():
		return null

	if _known_units_by_id.has(unit_id):
		return _known_units_by_id.get(unit_id, null)

	var unit_registry = _get_unit_registry()
	if unit_registry != null and unit_registry.has_method("get_unit"):
		return unit_registry.call("get_unit", unit_id)

	return null


func _record_network_command_rejection(validation: Dictionary, command_dict: Dictionary, peer_id: int) -> void:
	_network_command_reject_count += 1
	_last_network_command_rejection = {
		"peer_id": peer_id,
		"reason": String(validation.get("reason", "unknown")),
		"category": String(validation.get("category", "")),
		"command_type": _extract_command_type(command_dict),
		"team_id": String(command_dict.get("team_id", "")),
		"unit_id": String(command_dict.get("unit_id", "")),
		"fireteam_id": String(command_dict.get("fireteam_id", "")),
	}


func _duplicate_peer_fireteam_assignments() -> Dictionary:
	var result: Dictionary = {}
	for peer_id_variant in _peer_fireteam_assignments.keys():
		result[peer_id_variant] = PackedStringArray(_peer_fireteam_assignments[peer_id_variant])
	return result


func _is_peer_allowed_for_team(peer_id: int, team_id: String) -> bool:
	if team_id.is_empty():
		return false

	if not _has_active_multiplayer_peer():
		return peer_id == 1 and team_id == "team_alpha"

	return get_peer_team(peer_id) == team_id


func _broadcast_tick_state() -> void:
	if not _multiplayer_wire_ready(): return
	if _snapshot_broadcast_paused or not is_server_authoritative or not _has_active_multiplayer_peer() or not multiplayer.is_server():
		return

	var recipient_peer_ids: PackedInt32Array = _get_snapshot_recipient_peer_ids()
	if recipient_peer_ids.is_empty():
		return
	if not _multiplayer_runtime_context.is_empty():
		var raw: Dictionary = _build_raw_multiplayer_tick_state()
		var updates: Array = _build_vital_state_updates()
		var recipients_by_team: Dictionary={}
		for peer_id in recipient_peer_ids:
			var team: String=get_peer_team(peer_id)
			var team_peers: PackedInt32Array=recipients_by_team.get(team,PackedInt32Array())
			team_peers.append(peer_id)
			recipients_by_team[team]=team_peers
		for team: String in recipients_by_team:
			var visibility: Dictionary=_get_multiplayer_visibility_context(raw,team)
			var projected: Dictionary=VISIBLE_MULTIPLAYER_PROJECTION.new().project_state(raw,team,visibility)
			if not projected.get("ok",false): continue
			projected["runtime_context"]=_multiplayer_runtime_context.duplicate(true)
			_attach_multiplayer_terrain_fog(projected,team,true)
			_broadcast_tick_state_chunks(projected,recipients_by_team[team])
			var reliable: Dictionary=VISIBLE_MULTIPLAYER_PROJECTION.new().project_reliable_vitals(updates,raw,team,visibility) if not updates.is_empty() else {}
			if reliable.get("ok",false):
				for peer_id in recipients_by_team[team]:
					_receive_vital_state_updates.rpc_id(peer_id,reliable.vital_updates,_multiplayer_runtime_context.duplicate(true),team)
		return
	var state_dict: Dictionary = _build_tick_state()
	_broadcast_tick_state_chunks(state_dict, recipient_peer_ids)

	var vital_updates: Array = _build_vital_state_updates()
	if not vital_updates.is_empty():
		for peer_id in recipient_peer_ids:
			_receive_vital_state_updates.rpc_id(peer_id, vital_updates)


func _broadcast_tick_state_chunks(state_dict: Dictionary, recipient_peer_ids: PackedInt32Array) -> void:
	if not _multiplayer_wire_ready(): return
	var pack_started_usec: int = Time.get_ticks_usec()
	var raw_bytes: PackedByteArray = var_to_bytes(state_dict)
	if raw_bytes.size() > SNAPSHOT_MAX_RAW_BYTES:
		push_warning("SimulationRoot snapshot exceeds raw transport capacity: %d bytes." % raw_bytes.size())
		return
	var compressed_bytes: PackedByteArray = raw_bytes.compress(SNAPSHOT_COMPRESSION_MODE)
	var use_compression: bool = not compressed_bytes.is_empty() and compressed_bytes.size() < raw_bytes.size()
	var wire_bytes: PackedByteArray = compressed_bytes if use_compression else raw_bytes
	var chunk_count: int = maxi((wire_bytes.size() + SNAPSHOT_CHUNK_PAYLOAD_BYTES - 1) / SNAPSHOT_CHUNK_PAYLOAD_BYTES, 1)
	if chunk_count > SNAPSHOT_MAX_CHUNK_COUNT:
		push_warning("SimulationRoot snapshot exceeds chunk transport capacity: %d chunks." % chunk_count)
		return
	_snapshot_transport_last_chunk_count = chunk_count
	_snapshot_transport_last_max_chunk_payload_bytes = 0
	_snapshot_transport_last_raw_bytes = raw_bytes.size()
	_snapshot_transport_last_wire_bytes = wire_bytes.size()
	for chunk_index in range(chunk_count):
		var start_offset: int = chunk_index * SNAPSHOT_CHUNK_PAYLOAD_BYTES
		var end_offset: int = mini(start_offset + SNAPSHOT_CHUNK_PAYLOAD_BYTES, wire_bytes.size())
		var chunk: PackedByteArray = wire_bytes.slice(start_offset, end_offset)
		_snapshot_transport_last_max_chunk_payload_bytes = maxi(_snapshot_transport_last_max_chunk_payload_bytes, chunk.size())
		for peer_id in recipient_peer_ids:
			if _multiplayer_runtime_context.is_empty():
				_receive_tick_state_chunk.rpc_id(peer_id, tick_counter, chunk_index, chunk_count, raw_bytes.size(), use_compression, chunk)
			else:
				_receive_bound_tick_state_chunk.rpc_id(peer_id, tick_counter, chunk_index, chunk_count, raw_bytes.size(), use_compression, chunk, String(_multiplayer_runtime_context.runtime_token))
	_snapshot_transport_last_pack_usec = Time.get_ticks_usec() - pack_started_usec


func _get_snapshot_recipient_peer_ids() -> PackedInt32Array:
	var result := PackedInt32Array()
	for peer_id_variant in multiplayer.get_peers():
		var peer_id: int = int(peer_id_variant)
		if peer_id > 1 and not _snapshot_blocked_peer_ids.has(peer_id):
			result.append(peer_id)
	return result


func _build_tick_state() -> Dictionary:
	return Dictionary(_multiplayer_snapshot_contract.call("build_state_snapshot",_build_raw_multiplayer_tick_state()))


func _build_raw_multiplayer_tick_state() -> Dictionary:
	var snapshot_context: Dictionary = _multiplayer_raw_snapshot_context.duplicate(true)
	return {
		"schema_version":1,"snapshot_type":"state","transfer_mode":"unreliable",
		"tick": tick_counter,
		"units": _build_unit_snapshots(),
		"vital_updates": _build_all_vital_state_snapshots(),
		"objective": _build_objective_snapshot(),
		"dropship": snapshot_context.get("dropship", {}),
		"contacts": snapshot_context.get("contacts", []),
		"enemy_security": snapshot_context.get("enemy_security", []),
		"enemy_team_tactics": snapshot_context.get("enemy_team_tactics", []),
		"character_gameplay": snapshot_context.get("character_gameplay", []),
		"fire_events": snapshot_context.get("fire_events", []),
		"feedback_bubbles": snapshot_context.get("feedback_bubbles", []),
		"fireteam_tactical": snapshot_context.get("fireteam_tactical", []),
		"commander_intents": snapshot_context.get("commander_intents", []),
		"fireteam_plan_status": snapshot_context.get("fireteam_plan_status", []),
		"communication_events": snapshot_context.get("communication_events", []),
		"tactical_rules": _build_authoritative_tactical_rules_snapshot(snapshot_context.get("tactical_rules", [])),
		"breakout_states": snapshot_context.get("breakout_states", []),
		"air_asset_status": _build_air_asset_status_snapshots(snapshot_context.get("air_asset_status", snapshot_context.get("air_asset_statuses", []))),
		"mission_interactions": snapshot_context.get("mission_interactions", {}),
		"mission_result": snapshot_context.get("mission_result", {}),
	}


func _build_unit_snapshots() -> Array:
	var unit_snapshots: Array = []
	for unit in _get_snapshot_units():
		var unit_snapshot: Dictionary = _build_unit_snapshot(unit)
		if unit_snapshot.is_empty():
			continue

		unit_snapshots.append(unit_snapshot)
	return unit_snapshots


func _build_air_asset_status_snapshots(context_statuses: Variant = []) -> Array:
	var by_asset_id: Dictionary = {}
	for status_variant in Array(context_statuses):
		if typeof(status_variant) != TYPE_DICTIONARY:
			continue
		var status: Dictionary = Dictionary(status_variant).duplicate(true)
		var asset_id: String = String(status.get("asset_id", "")).strip_edges()
		if asset_id.is_empty():
			continue
		by_asset_id[asset_id] = status
	for asset_id_variant in _air_asset_status_by_id.keys():
		var asset_id: String = String(asset_id_variant).strip_edges()
		if asset_id.is_empty():
			continue
		by_asset_id[asset_id] = Dictionary(_air_asset_status_by_id.get(asset_id_variant, {})).duplicate(true)
	var keys: Array = by_asset_id.keys()
	keys.sort()
	var result: Array = []
	for key_variant in keys:
		result.append(Dictionary(by_asset_id.get(key_variant, {})).duplicate(true))
	return result


func _build_objective_snapshot() -> Dictionary:
	if not _is_valid_objective_status(_objective_status):
		return {}
	if _objective_status.has_method("to_dict"):
		return Dictionary(_objective_status.call("to_dict")).duplicate(true)
	return {}


func _build_all_vital_state_snapshots() -> Array:
	var updates: Array = []
	for unit in _get_snapshot_units():
		var vital_update: Dictionary = _build_unit_vital_update(unit)
		if vital_update.is_empty():
			continue

		vital_update["vital_tick"] = tick_counter
		updates.append(vital_update)
	return updates


func _build_vital_state_updates() -> Array:
	var updates: Array = []
	for unit in _get_snapshot_units():
		var vital_update: Dictionary = _build_unit_vital_update(unit)
		if vital_update.is_empty():
			continue

		var unit_id: String = String(vital_update.get("unit_id", ""))
		if unit_id.is_empty():
			continue

		var previous_update: Dictionary = _last_broadcast_vital_state_by_unit_id.get(unit_id, {})
		if previous_update == vital_update:
			continue

		_last_broadcast_vital_state_by_unit_id[unit_id] = vital_update.duplicate(true)
		# Dedupe the content before attaching its transport version.
		vital_update["vital_tick"] = tick_counter
		updates.append(vital_update)

	return updates


func _get_snapshot_units() -> Array:
	var snapshot_units: Array = []
	var unit_registry = _get_unit_registry()
	if unit_registry != null and unit_registry.has_method("get_all_units"):
		for unit in unit_registry.call("get_all_units"):
			if unit == null or not unit.has_method("get_unit_id"):
				continue

			snapshot_units.append(unit)
		return snapshot_units

	for unit in _known_units_by_id.values():
		if unit == null or not unit.has_method("get_unit_id"):
			continue

		if unit is CanvasItem and not (unit as CanvasItem).visible:
			continue

		snapshot_units.append(unit)

	return snapshot_units


func _build_unit_snapshot(unit) -> Dictionary:
	if unit == null or not unit.has_method("get_unit_id"):
		return {}

	var unit_id: String = String(unit.call("get_unit_id"))
	if unit_id.is_empty():
		return {}

	var snapshot: Dictionary = {
		"unit_id": unit_id,
		"visible": true,
	}
	if unit.has_method("get_team_id"):
		snapshot["team_id"] = String(unit.call("get_team_id")).strip_edges()
	if unit.has_method("get_fireteam_id"):
		snapshot["fireteam_id"] = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
	if unit is Node2D:
		snapshot["position"] = (unit as Node2D).global_position
		if unit.has_meta("facing_angle"):
			snapshot["facing_angle"] = float(unit.get_meta("facing_angle", 0.0))

	if unit is CanvasItem:
		snapshot["visible"] = bool((unit as CanvasItem).visible)

	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("to_dict"):
			var runtime_dict: Dictionary = runtime_status.call("to_dict")
			snapshot["runtime_state"] = String(runtime_dict.get("status", ""))
			snapshot["fire_mode"] = String(runtime_dict.get("fire_status", ""))
			snapshot["active_command_type"] = String(runtime_dict.get("active_command_type", ""))
			snapshot["source_command_type"] = String(runtime_dict.get("source_command_type", ""))
			snapshot["move_speed_factor"] = float(runtime_dict.get("move_speed_factor", 1.0))
			snapshot["sight_range_factor"] = float(runtime_dict.get("sight_range_factor", 1.0))
			snapshot["movement_posture"] = String(runtime_dict.get("movement_posture", "idle"))
			snapshot["weapon_posture"] = String(runtime_dict.get("weapon_posture", "lowered"))
			snapshot["posture_policy_id"] = String(runtime_dict.get("posture_policy_id", ""))
			if runtime_dict.has("target_position"):
				snapshot["target_position"] = runtime_dict["target_position"]
			if runtime_dict.has("phase"):
				snapshot["phase"] = int(runtime_dict.get("phase", -1))

	if unit.has_method("get_vital_status"):
		var vital_status = unit.call("get_vital_status")
		if vital_status != null and vital_status.has_method("to_dict"):
			var vital_dict: Dictionary = vital_status.call("to_dict")
			snapshot["vital_state"] = String(vital_dict.get("state", ""))
			snapshot["health"] = int(vital_dict.get("health_points", 0))
			snapshot["bleedout_ticks"] = int(vital_dict.get("bleedout_ticks", 0))
			snapshot["vital_tick"] = tick_counter

	if unit.has_method("get_tactical_stance_badge_snapshot"):
		var stance_snapshot_variant: Variant = unit.call("get_tactical_stance_badge_snapshot")
		if typeof(stance_snapshot_variant) == TYPE_DICTIONARY:
			snapshot.merge(Dictionary(stance_snapshot_variant), true)
	if unit.has_method("get_active_weapon_id"):
		var raw_active_weapon_id: String = String(unit.call("get_active_weapon_id")).strip_edges()
		if not raw_active_weapon_id.is_empty():
			var active_weapon_id: String = WEAPON_DATA_SCRIPT.call("sanitize_weapon_id", raw_active_weapon_id)
			if bool(WEAPON_DATA_SCRIPT.call("is_attack_weapon_id", active_weapon_id)):
				snapshot["active_weapon_id"] = active_weapon_id
				snapshot["weapon_tile_range"] = int(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", active_weapon_id))
				snapshot["weapon_range_world"] = float(WEAPON_DATA_SCRIPT.call("get_effective_world_range", active_weapon_id, _get_terrain_registry()))
	if unit is Node:
		_copy_enemy_meta_to_snapshot(unit as Node, snapshot)

	return snapshot


func _copy_enemy_meta_to_snapshot(unit: Node, snapshot: Dictionary) -> void:
	for string_key in [
		"enemy_security_group_id",
		"enemy_security_mode",
		"enemy_tactics_group_id",
		"enemy_tactic_profile_id",
		"enemy_visual_archetype_id",
		"enemy_advance_style",
		"enemy_role",
		"enemy_tactic_label",
		"enemy_movement_posture",
		"enemy_weapon_posture",
		"enemy_posture_policy_id",
		"enemy_limbo_behavior_action",
		"enemy_limbo_behavior_source",
		"enemy_limbo_behavior_reason",
	]:
		if unit.has_meta(string_key):
			snapshot[string_key] = String(unit.get_meta(string_key, ""))
	if unit.has_meta("enemy_facing_angle"):
		snapshot["enemy_facing_angle"] = float(unit.get_meta("enemy_facing_angle", 0.0))


func _build_unit_vital_update(unit) -> Dictionary:
	if unit == null or not unit.has_method("get_unit_id") or not unit.has_method("get_vital_status"):
		return {}

	var unit_id: String = String(unit.call("get_unit_id"))
	if unit_id.is_empty():
		return {}

	var vital_status = unit.call("get_vital_status")
	if vital_status == null or not vital_status.has_method("to_dict"):
		return {}

	return {
		"unit_id": unit_id,
		"vital_state": String(vital_status.state),
		"health": int(vital_status.health_points),
		"bleedout_ticks": int(vital_status.bleedout_ticks),
	}


func _apply_remote_state(state_dict: Dictionary) -> Dictionary:
	var terrain_fog: Dictionary = {}
	var apply_context: Dictionary=_multiplayer_runtime_context.duplicate(true)
	var full_projection: bool = false
	if state_dict.get("schema_version") == 2:
		if state_dict.get("ok") != true or state_dict.get("projection_schema") != "multiplayer.visible_state.v1" or state_dict.get("projection_scope") != "full_recipient_state" or state_dict.get("recipient_team") != _multiplayer_local_team or not state_dict.get("runtime_context") is Dictionary or not accepts_multiplayer_runtime_context(state_dict.runtime_context) or _multiplayer_runtime_context.is_empty() or not state_dict.get("snapshot") is Dictionary:
			return {"accepted":false,"reason":"invalid_recipient_projection"}
		if state_dict.has("terrain_fog"):
			if not MULTIPLAYER_TERRAIN_FOG.validate(state_dict.terrain_fog,_multiplayer_local_team):
				return {"accepted":false,"reason":"invalid_terrain_fog_projection"}
			terrain_fog = state_dict.terrain_fog
		var inner: Dictionary=state_dict.snapshot
		if typeof(state_dict.get("schema_version"))!=TYPE_INT or typeof(state_dict.get("tick"))!=TYPE_INT or typeof(inner.get("tick"))!=TYPE_INT or state_dict.tick!=inner.tick:
			return {"accepted":false,"reason":"projection_tick_conflict"}
		if typeof(inner.get("schema_version"))!=TYPE_INT or inner.schema_version!=1 or inner.get("snapshot_type")!="state" or inner.get("transfer_mode")!="unreliable" or not inner.get("units") is Array:
			return {"accepted":false,"reason":"invalid_recipient_snapshot"}
		var ids: Dictionary={}
		for entry in inner.units:
			if not entry is Dictionary or not entry.get("unit_id") is String or entry.unit_id.is_empty() or ids.has(entry.unit_id):
				return {"accepted":false,"reason":"invalid_recipient_units"}
			ids[entry.unit_id]=true
		state_dict=inner.duplicate(true)
		full_projection=true
	elif requires_multiplayer_runtime_context():
		return {"accepted":false,"reason":"recipient_projection_required"}
	if typeof(state_dict) != TYPE_DICTIONARY:
		_last_snapshot_reject_reason = "snapshot_not_dictionary"
		return {
			"accepted": false,
			"reason": _last_snapshot_reject_reason,
		}

	var validation: Dictionary = Dictionary(_multiplayer_snapshot_contract.call("validate_for_apply", state_dict, _last_applied_snapshot_tick))
	if not bool(validation.get("accepted", false)):
		_last_snapshot_reject_reason = String(validation.get("reason", "unknown"))
		if _last_snapshot_reject_reason == "out_of_order_snapshot":
			_snapshot_out_of_order_count += 1
		return validation

	var snapshot: Dictionary = Dictionary(validation.get("snapshot", {})).duplicate(true)
	if full_projection:
		_multiplayer_replica_visible_ids.clear()
		for entry: Dictionary in snapshot.get("units",[]):
			if entry.get("visible",true): _multiplayer_replica_visible_ids[entry.unit_id]=true
		_multiplayer_has_full_projection=true
		refresh_multiplayer_replica_presence()
		if not accepts_multiplayer_runtime_context(apply_context): return {"accepted":true,"context_changed":true}
	_last_applied_snapshot_tick = int(snapshot.get("tick", _last_applied_snapshot_tick))
	_snapshot_apply_count += 1
	_last_snapshot_reject_reason = ""
	if full_projection:
		var setup = get_node_or_null("../MissionSetup")
		if setup != null and setup.has_method("apply_multiplayer_terrain_fog_snapshot"):
			setup.apply_multiplayer_terrain_fog_snapshot(terrain_fog,PackedStringArray(_multiplayer_replica_visible_ids.keys()))
	_emit_snapshot_audio_events(snapshot)
	if not accepts_multiplayer_runtime_context(apply_context): return {"accepted":true,"context_changed":true}

	var objective_dict: Variant = snapshot.get("objective", {})
	if typeof(objective_dict) == TYPE_DICTIONARY:
		_apply_remote_objective_state(objective_dict)
		if not accepts_multiplayer_runtime_context(apply_context): return {"accepted":true,"context_changed":true}

	var unit_snapshots: Variant = snapshot.get("units", [])
	if not (unit_snapshots is Array):
		return {
			"accepted": true,
			"tick": _last_applied_snapshot_tick,
			"missing_unit_count": 0,
		}

	var missing_unit_count: int = 0
	for unit_snapshot in unit_snapshots:
		if typeof(unit_snapshot) != TYPE_DICTIONARY:
			continue

		var unit = _resolve_known_unit(String(unit_snapshot.get("unit_id", "")))
		if unit == null:
			missing_unit_count += 1
			continue

		if _has_remote_vital_fields(unit_snapshot) and not _accept_remote_vital_tick(String(unit_snapshot["unit_id"]), unit_snapshot, _last_applied_snapshot_tick):
			# Keep movement/runtime updates while retaining the newer vital projection.
			_copy_current_remote_vitals(unit, unit_snapshot)
		if unit.has_method("apply_remote_snapshot"):
			unit.call("apply_remote_snapshot", unit_snapshot)
			if not accepts_multiplayer_runtime_context(apply_context): return {"accepted":true,"context_changed":true}
			continue

		_apply_remote_snapshot_fallback(unit, unit_snapshot)
		if not accepts_multiplayer_runtime_context(apply_context): return {"accepted":true,"context_changed":true}

	for vital_update in Array(snapshot.get("vital_updates", [])):
		var unit_id: String = String(vital_update.get("unit_id", ""))
		if int(vital_update.get("vital_tick", _last_applied_snapshot_tick)) >= int(_last_applied_vital_tick_by_unit_id.get(unit_id, -1)):
			continue
		var unit = _resolve_known_unit(unit_id)
		if unit != null:
			_copy_current_remote_vitals(unit, vital_update)
	_last_server_state = snapshot.duplicate(true)
	_snapshot_missing_unit_count += missing_unit_count
	multiplayer_snapshot_applied.emit(snapshot.duplicate(true))
	return {
		"accepted": true,
		"tick": _last_applied_snapshot_tick,
		"missing_unit_count": missing_unit_count,
	}


func _emit_snapshot_audio_events(snapshot: Dictionary) -> void:
	var bus = _resolve_audio_event_bus()
	if bus == null or not bus.has_method("emit_weapon_fire"):
		return
	for fire_event_variant in Array(snapshot.get("fire_events", [])):
		if typeof(fire_event_variant) != TYPE_DICTIONARY:
			continue
		var fire_event: Dictionary = Dictionary(fire_event_variant)
		var event_id: String = String(fire_event.get("event_id", "")).strip_edges()
		if event_id.is_empty():
			continue
		var position: Variant = fire_event.get("muzzle_position", fire_event.get("attacker_position", Vector2.ZERO))
		var result: Dictionary = Dictionary(bus.call("emit_weapon_fire", String(fire_event.get("weapon_id", "")), {
			"position": position,
			"unit_id": String(fire_event.get("attacker_unit_id", "")),
			"team_id": String(fire_event.get("attacker_team_id", "")),
			"target_unit_id": String(fire_event.get("target_unit_id", "")),
			"from_multiplayer_snapshot": true,
			"network_read_only": true,
			"source": "multiplayer_snapshot",
			"visible_to_local": bool(fire_event.get("visible_to_local", true)),
			"visibility_context": String(fire_event.get("visibility_context", "snapshot_visible")),
			"dedupe_key": event_id,
			"dedupe_window_msec": 5000,
		})).duplicate(true)
		_last_snapshot_audio_result = result.duplicate(true)
		if bool(result.get("played", false)):
			_snapshot_audio_event_ids_played[event_id] = true
			_snapshot_audio_played_count += 1
		else:
			_snapshot_audio_suppressed_count += 1


func _resolve_audio_event_bus():
	if _audio_event_bus != null and is_instance_valid(_audio_event_bus) and _audio_event_bus.has_method("emit_weapon_fire"):
		return _audio_event_bus
	_audio_event_bus = null
	if audio_event_bus_path != NodePath():
		var path_bus := get_node_or_null(audio_event_bus_path)
		if path_bus != null and path_bus.has_method("emit_weapon_fire"):
			_audio_event_bus = path_bus
			return _audio_event_bus
	var child_bus := get_node_or_null("AudioEventBus")
	if child_bus != null and child_bus.has_method("emit_weapon_fire"):
		_audio_event_bus = child_bus
		return _audio_event_bus
	var parent_node := get_parent()
	if parent_node != null:
		var sibling_bus := parent_node.get_node_or_null("AudioEventBus")
		if sibling_bus != null and sibling_bus.has_method("emit_weapon_fire"):
			_audio_event_bus = sibling_bus
			return _audio_event_bus
	return null


func _apply_remote_objective_state(objective_dict: Dictionary) -> void:
	if objective_dict.is_empty():
		return

	if not _is_valid_objective_status(_objective_status):
		_objective_status = OBJECTIVE_STATUS_SCRIPT.new()

	_objective_status.objective_id = String(objective_dict.get("objective_id", _objective_status.objective_id))
	_objective_status.position = _coerce_vector2(objective_dict.get("position", _objective_status.position), _objective_status.position)
	_objective_status.capture_radius = _extract_float(objective_dict.get("capture_radius", _objective_status.capture_radius), _objective_status.capture_radius)
	_objective_status.owning_team_id = String(objective_dict.get("owning_team_id", _objective_status.owning_team_id))
	_objective_status.capture_progress = clampf(_extract_float(objective_dict.get("capture_progress", _objective_status.capture_progress), _objective_status.capture_progress), 0.0, 1.0)
	_objective_status.capturing_team_id = String(objective_dict.get("capturing_team_id", _objective_status.capturing_team_id))
	_objective_status.set_contested(bool(objective_dict.get("contested", _objective_status.is_contested())))
	if objective_dict.has("timer_state") or objective_dict.has("countdown_seconds"):
		var timer_source: String = String(objective_dict.get("timer_source", objective_dict.get("source", ""))).strip_edges()
		var timer_state: String = String(objective_dict.get("timer_state", "none")).strip_edges().to_lower()
		if timer_source.is_empty() or timer_state == "none":
			_objective_status.clear_countdown()
		else:
			_objective_status.set_countdown(
				_extract_float(objective_dict.get("countdown_seconds", 0.0), 0.0),
				timer_state,
				timer_source,
				_extract_float(objective_dict.get("countdown_total_seconds", objective_dict.get("countdown_seconds", 0.0)), 0.0),
				String(objective_dict.get("timer_label", ""))
			)


func _apply_remote_snapshot_fallback(unit, unit_snapshot: Dictionary) -> void:
	if unit == null:
		return

	if unit is CanvasItem:
		(unit as CanvasItem).visible = bool(unit_snapshot.get("visible", true))

	if unit is Node2D:
		var target_position: Vector2 = _coerce_vector2(unit_snapshot.get("position", (unit as Node2D).global_position), (unit as Node2D).global_position)
		(unit as Node2D).global_position = (unit as Node2D).global_position.lerp(target_position, 0.75)
		if unit_snapshot.has("facing_angle") and unit is Node:
			(unit as Node).set_meta("facing_angle", float(unit_snapshot.get("facing_angle", 0.0)))


func _resolve_known_unit(unit_id: String):
	if unit_id.is_empty():
		return null

	var unit = _known_units_by_id.get(unit_id, null)
	if unit != null:
		return unit

	return _resolve_unit(unit_id)


func _process_commands(commands: Array, delta: float) -> void:
	var ordered_commands: Array = _order_payloads(commands)

	for cmd in ordered_commands:
		_apply_command(cmd, delta)


var _runtime_command_ordering_usec: int = 0
var _runtime_command_apply_usec: int = 0

func _process_commands_profiled(commands: Array, delta: float) -> void:
	_runtime_command_type_count.clear()
	_runtime_command_type_usec.clear()
	_runtime_command_requeue_count.clear()
	var ordering_started_usec: int = Time.get_ticks_usec()
	var ordered_commands: Array = _order_payloads(commands)
	_runtime_command_ordering_usec = Time.get_ticks_usec() - ordering_started_usec
	var apply_loop_started_usec: int = Time.get_ticks_usec()
	for cmd in ordered_commands:
		var command_type: String = _normalize_runtime_command_type(cmd)
		_runtime_command_type_count[command_type] = int(_runtime_command_type_count.get(command_type, 0)) + 1
		if not _runtime_command_requeue_count.has(command_type):
			_runtime_command_requeue_count[command_type] = 0
		var queue_size_before: int = command_queue.size()
		var apply_started_usec: int = Time.get_ticks_usec()
		_apply_command(cmd, delta)
		var apply_usec: int = Time.get_ticks_usec() - apply_started_usec
		_runtime_command_type_usec[command_type] = int(_runtime_command_type_usec.get(command_type, 0)) + apply_usec
		if command_queue.size() > queue_size_before:
			_runtime_command_requeue_count[command_type] = int(_runtime_command_requeue_count.get(command_type, 0)) + 1
	_runtime_command_apply_usec = Time.get_ticks_usec() - apply_loop_started_usec


func _normalize_runtime_command_type(cmd: Variant) -> String:
	if typeof(cmd) != TYPE_DICTIONARY:
		return "unknown"
	var command_type: String = String((cmd as Dictionary).get("command_type", (cmd as Dictionary).get("type", ""))).strip_edges().to_lower()
	return command_type if not command_type.is_empty() else "unknown"


func _process_effects(effects: Array, delta: float) -> void:
	var ordered_effects: Array = _order_payloads(effects)

	for effect in ordered_effects:
		_apply_effect(effect, delta)


func _apply_command(cmd: Dictionary, delta: float) -> void:
	if typeof(cmd) != TYPE_DICTIONARY:
		push_warning("SimulationRoot can only apply Dictionary commands.")
		return
	if not _is_current_hex_payload(cmd):
		_record_discarded_move_command(cmd,"stale_hex_lifecycle")
		return

	if delta < 0.0:
		push_warning("SimulationRoot received a negative physics delta while applying a command.")
		return
	if String(cmd.get("contract_category", "")) in ["singleplayer_campaign", "singleplayer_supply", "campaign_onboarding", "singleplayer_space_travel"]:
		# Queued UI-origin requests cannot inject a trusted runtime context.
		request_singleplayer_command(cmd)
		return
	if String(cmd.get("contract_category", "")).strip_edges().to_lower() == "commander_intent":
		commander_intent_committed.emit(cmd.duplicate(true))
		return

	match _extract_command_type(cmd):
		"move_to_position":
			_apply_move_command(cmd, delta)
		"engage_area":
			_apply_move_command(cmd, delta)
		"hold_position":
			_apply_unit_command_status(cmd)
		"set_fire_rule":
			_apply_fire_rule_command(cmd)
		"set_lz", "clear_lz", "call_dropship", "set_dropship_approach", "set_dropship_approach_style", "set_dropship_approach_path", "return_dropship":
			_apply_dropship_command(cmd)
		_:
			# TODO: Authoritative gameplay state commits belong here once systems exist.
			pass


func _apply_dropship_command(command: Dictionary) -> void:
	dropship_command_committed.emit(command.duplicate(true))


func _apply_fire_rule_command(command: Dictionary) -> void:
	var fireteam_id: String = String(command.get("fireteam_id", "")).strip_edges().to_lower()
	var fire_rule: String = String(command.get("fire_rule", "")).strip_edges().to_lower()
	if fireteam_id.is_empty() or not fire_rule in ["hold", "return", "free", "suppress"]:
		return
	var previous: Dictionary = Dictionary(_authoritative_fire_rules_by_fireteam.get(fireteam_id, {}))
	var revision: int = int(previous.get("revision", 0)) + 1
	_authoritative_fire_rules_by_fireteam[fireteam_id] = {
		"fireteam_id": fireteam_id,
		"team_id": String(command.get("team_id", previous.get("team_id", ""))).strip_edges(),
		"fire_rule": fire_rule,
		"revision": revision,
		"command_id": String(command.get("command_id", "roe:%s:%d" % [fireteam_id, revision])).strip_edges(),
		"runtime_authority": "SimulationRoot",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}
	fire_rule_committed.emit(get_authoritative_fire_rule_state(fireteam_id))


func _build_authoritative_tactical_rules_snapshot(context_rules: Variant) -> Array:
	var by_fireteam: Dictionary = {}
	for entry_variant in Array(context_rules):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		var fireteam_id: String = String(entry.get("fireteam_id", "")).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			by_fireteam[fireteam_id] = entry
	for entry_variant in get_authoritative_fire_rule_snapshot():
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		by_fireteam[String(entry.get("fireteam_id", ""))] = entry
	var fireteam_ids: Array = by_fireteam.keys()
	fireteam_ids.sort()
	var result: Array = []
	for fireteam_id_variant in fireteam_ids:
		result.append(Dictionary(by_fireteam[fireteam_id_variant]).duplicate(true))
	return result


func _apply_effect(effect: Dictionary, delta: float) -> void:
	if typeof(effect) != TYPE_DICTIONARY:
		push_warning("SimulationRoot can only apply Dictionary effects.")
		return
	if not _is_current_hex_payload(effect):
		_last_hex_lifecycle_resolution={"ok":false,"reason":"stale_hex_lifecycle","unit_id":effect.get("unit_id","")}
		return

	if delta < 0.0:
		push_warning("SimulationRoot received a negative physics delta while applying an effect.")
		return

	match _extract_effect_type(effect):
		"damage":
			_apply_damage_effect(effect)
		"heal":
			_apply_heal_effect(effect)
		"bleedout":
			_apply_bleedout_effect(effect)
		"respawn":
			_apply_respawn_effect(effect)
		"dropship_embark_unit":
			_apply_dropship_embark_unit_effect(effect)
		"dropship_deploy_unit":
			_apply_dropship_deploy_unit_effect(effect)
		"air_asset_status_update":
			_apply_air_asset_status_update_effect(effect)
		"apply_loadout_modifiers":
			_apply_loadout_modifiers_effect(effect)
		"set_unit_combat_posture":
			_apply_unit_combat_posture_effect(effect)
		_:
			# TODO: Deterministic effect commits belong here once systems exist.
			pass


func _drain_queue(queue: Array) -> Array:
	var drained: Array = queue.duplicate(false)
	queue.clear()
	return drained


func _order_payloads(payloads: Array) -> Array:
	var decorated: Array = []
	var index: int = 0

	for payload in payloads:
		if typeof(payload) != TYPE_DICTIONARY:
			push_warning("SimulationRoot expected queued payloads to be dictionaries.")
			index += 1
			continue

		decorated.append(
			{
				"index": index,
				"priority": _extract_priority(payload),
				"payload": payload,
			}
		)
		index += 1

	decorated.sort_custom(_sort_payload_entries)

	var ordered: Array = []
	for entry in decorated:
		ordered.append(entry["payload"])

	return ordered


func _extract_priority(payload: Dictionary) -> int:
	if not payload.has("priority"):
		return 0

	var priority: Variant = payload["priority"]
	if typeof(priority) == TYPE_INT or typeof(priority) == TYPE_FLOAT:
		return int(priority)

	push_warning("SimulationRoot expected payload priority to be numeric.")
	return 0


func _sort_payload_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_priority: int = int(a["priority"])
	var b_priority: int = int(b["priority"])

	if a_priority == b_priority:
		return int(a["index"]) < int(b["index"])

	return a_priority > b_priority


func _extract_command_type(cmd: Dictionary) -> String:
	if cmd.has("command_type"):
		return String(cmd["command_type"])

	if cmd.has("type"):
		return String(cmd["type"])

	return ""


func _extract_effect_type(effect: Dictionary) -> String:
	if effect.has("effect_type"):
		return String(effect["effect_type"])

	return ""


func _apply_move_command(cmd: Dictionary, delta: float) -> void:
	var unit_id: String = String(cmd.get("unit_id", ""))
	if unit_id.is_empty():
		_record_discarded_move_command(cmd, "missing_unit_id")
		push_warning("SimulationRoot move command expects a non-empty unit_id.")
		return

	var target_position: Variant = cmd.get("target_position", null)
	if typeof(target_position) != TYPE_VECTOR2:
		_record_discarded_move_command(cmd, "invalid_target_position", {"unit_id": unit_id})
		push_warning("SimulationRoot move command expects a Vector2 target_position.")
		return
	if is_hex_ground_runtime_active() and not Vector2(target_position).is_finite():
		_record_discarded_move_command(cmd,"invalid_target_position",{"unit_id":unit_id})
		return

	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_unit"):
		_record_discarded_move_command(cmd, "missing_unit_registry", {"unit_id": unit_id})
		push_warning("SimulationRoot requires a direct UnitRegistry reference for move commands.")
		return

	var unit = unit_registry.call("get_unit", unit_id)
	if unit == null:
		_record_discarded_move_command(cmd, "unit_not_registered", {"unit_id": unit_id})
		return

	if not (unit is Node2D):
		_record_discarded_move_command(cmd, "unit_not_node2d", {"unit_id": unit_id})
		push_warning("SimulationRoot move command expects a Node2D-compatible unit.")
		return

	if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
		_record_discarded_move_command(cmd, "unit_not_fit", {"unit_id": unit_id})
		if is_hex_ground_runtime_active():_hex_movement_runtime.stage_stop(unit_id,"unit_not_fit")
		return

	if _is_stale_tokenized_move_command(cmd, unit):
		_record_discarded_move_command(cmd, "stale_command_token", {"unit_id": unit_id})
		return
	if is_hex_ground_runtime_active() and not _hex_ground_runtime.has_unit(unit_id):
		_record_discarded_move_command(cmd,"hex_unit_not_admitted",{"unit_id":unit_id})
		return

	var command_applied:bool=_apply_unit_command_status(cmd,unit)
	if is_hex_ground_runtime_active():
		if not command_applied:
			_record_discarded_move_command(cmd,"invalid_hex_unit_command",{"unit_id":unit_id})
			return
		var staged:Dictionary=_hex_movement_runtime.stage_move(cmd,unit)
		if not staged.ok:_record_discarded_move_command(cmd,String(staged.reason),{"unit_id":unit_id})
		return

	if unit.has_method("set_target_position"):
		unit.call("set_target_position", target_position)

	var node_2d: Node2D = unit
	var move_speed_factor: float = _extract_move_speed_factor(cmd, unit)
	if move_speed_factor <= 0.0:
		return

	var terrain_registry = _get_terrain_registry()
	if terrain_registry != null:
		_apply_move_command_with_terrain(cmd, node_2d, target_position, move_speed_factor, delta, terrain_registry)
		return

	var current_position: Vector2 = node_2d.position
	var direction: Vector2 = target_position - current_position
	var step_distance: float = MOVE_SPEED_PER_SECOND * move_speed_factor * delta
	if direction.length() <= step_distance:
		_store_unit_facing_from_positions(unit, current_position, target_position)
		node_2d.position = target_position
		if unit.has_method("refresh_terrain_readability"):
			unit.call("refresh_terrain_readability")
		_update_local_avoidance_agent_position(unit_id, node_2d.global_position)
		return

	if direction.is_zero_approx():
		return

	var desired_velocity: Vector2 = direction.normalized() * (step_distance / maxf(delta, 0.0001))
	var safe_velocity: Vector2 = _resolve_local_avoidance_velocity(cmd, node_2d, current_position, desired_velocity, desired_velocity.length(), delta, null)
	var displacement: Vector2 = safe_velocity * delta
	if displacement.length() > step_distance:
		displacement = displacement.normalized() * step_distance
	var next_position: Vector2 = current_position + displacement
	_store_unit_facing_from_positions(unit, current_position, next_position)
	node_2d.position = next_position
	_update_local_avoidance_agent_position(unit_id, node_2d.global_position)
	if unit.has_method("refresh_terrain_readability"):
		unit.call("refresh_terrain_readability")
	if bool(cmd.get("requeue_until_target", true)):
		enqueue_command(cmd)


func _apply_unit_command_status(cmd: Dictionary, unit = null) -> bool:
	var target_unit = unit
	if target_unit == null:
		var unit_id: String = String(cmd.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			return false
		var unit_registry = _get_unit_registry()
		if unit_registry != null and unit_registry.has_method("get_unit"):
			target_unit = unit_registry.call("get_unit", unit_id)
		if target_unit == null:
			target_unit = _resolve_known_unit(unit_id)
	if target_unit == null or not target_unit.has_method("assign_unit_command"):
		return false

	var status_data:Dictionary=cmd
	if is_hex_ground_runtime_active() and not cmd.has("command_type"):
		status_data=cmd.duplicate(false)
		status_data["command_type"]=_extract_command_type(cmd)
	var command = UNIT_COMMAND_SCRIPT.call("from_dict", status_data)
	if command == null or not command.has_method("is_valid") or not bool(command.call("is_valid")):
		return false

	var applied:Variant=target_unit.call("assign_unit_command",command)
	if is_hex_ground_runtime_active() and applied is bool and not applied:return false
	if is_hex_ground_runtime_active() and _extract_command_type(cmd)=="hold_position":_hex_movement_runtime.stage_stop(String(cmd.get("unit_id","")),"hold_position")
	var command_token: String = String(cmd.get("command_token", "")).strip_edges()
	var unit_id: String = String(cmd.get("unit_id", "")).strip_edges()
	if not unit_id.is_empty():
		_committed_command_token_by_unit_id[unit_id] = command_token
		if command_token.is_empty():
			# An authoritative untokenized Hold supersedes already queued Moves.
			_latest_command_token_by_unit_id[unit_id] = ""
	_apply_unit_command_facing(cmd, target_unit)
	return true


func _apply_unit_command_facing(cmd: Dictionary, unit) -> void:
	if unit == null or not (unit is Node) or not cmd.has("facing_angle"):
		return
	var facing_value: Variant = cmd.get("facing_angle", null)
	if not (typeof(facing_value) == TYPE_FLOAT or typeof(facing_value) == TYPE_INT):
		return
	var unit_node: Node = unit as Node
	var facing_angle: float = float(facing_value)
	unit_node.set_meta("facing_angle", facing_angle)
	unit_node.set_meta("map_facing_angle", facing_angle)
	if cmd.has("security_mode"):
		unit_node.set_meta("security_facing_angle", facing_angle)
		unit_node.set_meta("security_facing_active", true)


func _apply_move_command_with_terrain(
	cmd: Dictionary,
	unit_node: Node2D,
	target_position: Vector2,
	move_speed_factor: float,
	delta: float,
	terrain_registry
) -> void:
	var path_world_points: Array = _extract_or_build_path_world_points(cmd, unit_node, unit_node.global_position, target_position, terrain_registry)
	if path_world_points.is_empty():
		return

	if _is_local_avoidance_enabled_for_command(cmd):
		_apply_move_command_with_terrain_avoidance(cmd, unit_node, target_position, move_speed_factor, delta, terrain_registry, path_world_points)
		return

	var current_position: Vector2 = unit_node.global_position
	var previous_position: Vector2 = current_position
	var hex_metric: bool = _uses_hex_movement_metric(terrain_registry)
	var step_distance: float = MOVE_SPEED_PER_SECOND * move_speed_factor * _extract_surface_speed_factor(unit_node) * delta
	while step_distance > 0.0 and not path_world_points.is_empty():
		var next_waypoint: Vector2 = _coerce_vector2(path_world_points[0], target_position)
		var direction_to_waypoint: Vector2 = next_waypoint - current_position
		if direction_to_waypoint.is_zero_approx():
			path_world_points.pop_front()
			continue

		var distance_to_waypoint: float = direction_to_waypoint.length()
		if hex_metric:
			distance_to_waypoint = float(terrain_registry.call("get_movement_distance", current_position, next_waypoint))
		if distance_to_waypoint <= step_distance:
			current_position = next_waypoint
			step_distance -= distance_to_waypoint
			path_world_points.pop_front()
			continue

		if hex_metric:
			current_position = current_position.lerp(next_waypoint, step_distance / distance_to_waypoint)
		else:
			current_position += direction_to_waypoint.normalized() * step_distance
		step_distance = 0.0

	_store_unit_facing_from_positions(unit_node, previous_position, current_position)
	unit_node.global_position = current_position
	_update_local_avoidance_agent_position(_extract_unit_id_for_path_recompute(unit_node), unit_node.global_position)
	cmd["path"] = path_world_points.duplicate(true)
	if unit_node.has_method("refresh_terrain_readability"):
		unit_node.call("refresh_terrain_readability")

	var resolved_target_position: Vector2 = _coerce_vector2(cmd.get("navigation_resolved_target_position", target_position), target_position)
	if bool(cmd.get("requeue_until_target", true)) and (not path_world_points.is_empty() or current_position.distance_to(resolved_target_position) > 0.5):
		enqueue_command(cmd)


func _uses_hex_movement_metric(terrain_registry) -> bool:
	return terrain_registry != null and terrain_registry.has_method("get_grid_topology") and String(terrain_registry.call("get_grid_topology")) == "hex_axial_v1"


func _apply_move_command_with_terrain_avoidance(
	cmd: Dictionary,
	unit_node: Node2D,
	target_position: Vector2,
	move_speed_factor: float,
	delta: float,
	terrain_registry,
	path_world_points: Array
) -> void:
	var current_position: Vector2 = unit_node.global_position
	var previous_position: Vector2 = current_position
	while not path_world_points.is_empty():
		var first_waypoint: Vector2 = _coerce_vector2(path_world_points[0], target_position)
		if current_position.distance_to(first_waypoint) > 0.001:
			break
		path_world_points.pop_front()

	if path_world_points.is_empty():
		unit_node.global_position = current_position
		cmd["path"] = []
		_update_local_avoidance_agent_position(_extract_unit_id_for_path_recompute(unit_node), unit_node.global_position)
		if unit_node.has_method("refresh_terrain_readability"):
			unit_node.call("refresh_terrain_readability")
		return

	var next_waypoint: Vector2 = _coerce_vector2(path_world_points[0], target_position)
	var direction_to_waypoint: Vector2 = next_waypoint - current_position
	if direction_to_waypoint.is_zero_approx():
		cmd["path"] = path_world_points.duplicate(true)
		return

	var step_distance: float = MOVE_SPEED_PER_SECOND * move_speed_factor * _extract_surface_speed_factor(unit_node) * delta
	var distance_to_waypoint: float = direction_to_waypoint.length()
	var hex_metric: bool = _uses_hex_movement_metric(terrain_registry)
	if hex_metric:
		distance_to_waypoint = float(terrain_registry.call("get_movement_distance", current_position, next_waypoint))
	var desired_step_distance: float = minf(step_distance, distance_to_waypoint)
	var desired_velocity: Vector2 = direction_to_waypoint.normalized() * (desired_step_distance / maxf(delta, 0.0001))
	if hex_metric:
		desired_velocity = direction_to_waypoint * (desired_step_distance / distance_to_waypoint) / maxf(delta, 0.0001)
	var avoidance_speed: float = desired_velocity.length() if hex_metric else step_distance / maxf(delta, 0.0001)
	var safe_velocity: Vector2 = _resolve_local_avoidance_velocity(cmd, unit_node, current_position, desired_velocity, avoidance_speed, delta, terrain_registry)
	if safe_velocity.length_squared() <= 0.0001 \
		and bool(cmd.get("local_avoidance_deadlock", false)) \
		and _is_local_avoidance_transition_walkable(current_position, next_waypoint, terrain_registry):
		safe_velocity = desired_velocity
	var displacement: Vector2 = safe_velocity * delta
	if hex_metric:
		var physical_displacement: float = float(terrain_registry.call("get_movement_distance", current_position, current_position + displacement))
		if physical_displacement > desired_step_distance:
			displacement *= desired_step_distance / physical_displacement
	elif displacement.length() > desired_step_distance:
		displacement = displacement.normalized() * desired_step_distance
	current_position += displacement
	if current_position.distance_to(next_waypoint) <= 0.5:
		current_position = next_waypoint
		path_world_points.pop_front()

	_store_unit_facing_from_positions(unit_node, previous_position, current_position)
	unit_node.global_position = current_position
	_update_local_avoidance_agent_position(_extract_unit_id_for_path_recompute(unit_node), unit_node.global_position)
	cmd["path"] = path_world_points.duplicate(true)
	if unit_node.has_method("refresh_terrain_readability"):
		unit_node.call("refresh_terrain_readability")

	var resolved_target_position: Vector2 = _coerce_vector2(cmd.get("navigation_resolved_target_position", target_position), target_position)
	if bool(cmd.get("requeue_until_target", true)) and (not path_world_points.is_empty() or current_position.distance_to(resolved_target_position) > 0.5):
		enqueue_command(cmd)


func _store_unit_facing_from_positions(unit, from_position: Vector2, to_position: Vector2) -> void:
	if unit == null or not (unit is Node):
		return
	var direction: Vector2 = to_position - from_position
	if direction.length_squared() <= 0.0001:
		return
	(unit as Node).set_meta("facing_angle", direction.angle())


func _is_stale_tokenized_move_command(cmd: Dictionary, unit) -> bool:
	var command_token: String = String(cmd.get("command_token", "")).strip_edges()
	if command_token.is_empty():
		return false
	var unit_id: String = String(cmd.get("unit_id", "")).strip_edges()
	var latest_token: String = String(_latest_command_token_by_unit_id.get(unit_id, "")).strip_edges()
	if _latest_command_token_by_unit_id.has(unit_id) and latest_token != command_token:
		return true
	if unit == null or not unit.has_method("get_current_unit_command"):
		return false
	var current_command = unit.call("get_current_unit_command")
	if current_command == null:
		return false
	var current_token: String = ""
	if typeof(current_command) == TYPE_DICTIONARY:
		current_token = String(Dictionary(current_command).get("command_token", "")).strip_edges()
	elif current_command is Object:
		current_token = String(current_command.get("command_token")).strip_edges()
	if current_token == command_token:
		return false
	var committed_token: String = String(_committed_command_token_by_unit_id.get(unit_id, "")).strip_edges()
	return not _committed_command_token_by_unit_id.has(unit_id) or committed_token != current_token


func _discard_pending_move_commands_for_unit(unit_id: String) -> void:
	if is_hex_ground_runtime_active():_hex_movement_runtime.stage_stop(unit_id,"unit_not_fit")
	for index in range(command_queue.size() - 1, -1, -1):
		var pending_command: Dictionary = command_queue[index]
		if String(pending_command.get("unit_id", "")).strip_edges() != unit_id:
			continue
		if _extract_command_type(pending_command) not in ["move_to_position", "engage_area"]:
			continue
		command_queue.remove_at(index)
		_record_discarded_move_command(pending_command, "unit_not_fit", {"unit_id": unit_id})


func _record_discarded_move_command(cmd: Dictionary, reason: String, details: Dictionary = {}) -> void:
	var normalized_reason: String = reason.strip_edges().to_lower()
	if normalized_reason.is_empty():
		normalized_reason = "unknown"
	_discarded_move_command_count += 1
	_discarded_move_command_counts_by_reason[normalized_reason] = int(_discarded_move_command_counts_by_reason.get(normalized_reason, 0)) + 1
	var record: Dictionary = {
		"tick": tick_counter,
		"reason": normalized_reason,
		"command_type": String(cmd.get("command_type", cmd.get("type", ""))).strip_edges(),
		"unit_id": String(cmd.get("unit_id", "")).strip_edges(),
		"team_id": String(cmd.get("team_id", "")).strip_edges(),
		"source_command_type": String(cmd.get("source_command_type", cmd.get("origin_command_type", ""))).strip_edges(),
		"phase": int(cmd.get("phase", -1)),
		"command_token": String(cmd.get("command_token", "")).strip_edges(),
		"target_position": cmd.get("target_position", null),
		"requeue_until_target": bool(cmd.get("requeue_until_target", false)),
		"will_requeue": false,
	}
	for key in details.keys():
		record[key] = details[key]
	_last_discarded_move_command = record


func _extract_or_build_path_world_points(
	cmd: Dictionary,
	unit,
	current_position: Vector2,
	target_position: Vector2,
	terrain_registry
) -> Array:
	var existing_path: Array = []
	var raw_path: Variant = cmd.get("path", [])
	if raw_path is Array:
		existing_path = (raw_path as Array).duplicate(true)

	if _should_recompute_move_path(cmd, unit, existing_path, current_position, target_position, terrain_registry):
		existing_path.clear()
		cmd["path"] = []
		cmd.erase("navigation_resolved_target_position")

	if not existing_path.is_empty():
		cmd["navigation_resolved_target_position"] = _coerce_vector2(existing_path[-1], target_position)
		return existing_path

	if not _try_begin_navigation_path_request(cmd, unit, current_position, target_position):
		return []

	var path_world_points: Array = _build_path_world_points(current_position, target_position, terrain_registry, cmd, unit)
	if cmd.has("_regional_navigation_search"):
		_delay_navigation_path_request(cmd, unit, current_position, target_position, "regional_search_pending")
		return []
	cmd["path"] = path_world_points.duplicate(true)
	if not path_world_points.is_empty():
		cmd["navigation_resolved_target_position"] = _coerce_vector2(path_world_points[-1], target_position)
		cmd["navigation_path_terrain_revision"] = _get_terrain_registry_revision(terrain_registry)
	if terrain_move_debug_enabled:
		_record_terrain_move_debug(cmd, unit, current_position, target_position, terrain_registry, path_world_points)
	return path_world_points


func _should_recompute_move_path(
	cmd: Dictionary,
	unit,
	existing_path: Array,
	current_position: Vector2,
	target_position: Vector2,
	terrain_registry
) -> bool:
	if terrain_registry == null or unit == null:
		return false

	var unit_id: String = _extract_unit_id_for_path_recompute(unit)
	if unit_id.is_empty():
		return false

	if bool(cmd.get("local_avoidance_repath_requested", false)):
		cmd.erase("local_avoidance_repath_requested")
		cmd.erase("local_avoidance_deadlock")
		_contact_path_recompute_ready_at_msec.erase(unit_id)
		return true

	if cmd.has("navigation_path_terrain_revision") and int(cmd["navigation_path_terrain_revision"]) != _get_terrain_registry_revision(terrain_registry):
		return true

	if not bool(cmd.get("requeue_until_target", true)) or not _is_unit_in_contact(unit):
		_contact_path_recompute_ready_at_msec.erase(unit_id)
		return false

	if existing_path.is_empty():
		return false

	# An exact regional route already uses this command's fixed costs. The
	# explicit avoidance request and terrain revision checks above still apply.
	if _uses_regional_navigation(terrain_registry):
		return false

	var resolved_target_position: Vector2 = _coerce_vector2(cmd.get("navigation_resolved_target_position", target_position), target_position)
	var target_grid: Vector2i = terrain_registry.call("world_to_grid", resolved_target_position)
	var current_final_waypoint: Vector2 = _coerce_vector2(existing_path[-1], target_position)
	var current_final_grid: Vector2i = terrain_registry.call("world_to_grid", current_final_waypoint)
	if current_final_grid != target_grid:
		_contact_path_recompute_ready_at_msec[unit_id] = Time.get_ticks_msec() + CONTACT_PATH_RECOMPUTE_INTERVAL_MSEC
		return true

	var current_grid: Vector2i = terrain_registry.call("world_to_grid", current_position)
	if current_grid == target_grid:
		_contact_path_recompute_ready_at_msec.erase(unit_id)
		return false

	var now_msec: int = Time.get_ticks_msec()
	if int(_contact_path_recompute_ready_at_msec.get(unit_id, 0)) > now_msec:
		return false

	_contact_path_recompute_ready_at_msec[unit_id] = now_msec + CONTACT_PATH_RECOMPUTE_INTERVAL_MSEC
	return true


func _begin_navigation_budget_tick() -> void:
	_regional_navigation_expansions_this_tick = 0
	_prepare_regional_navigation_admissions()
	_navigation_new_path_queries_this_tick = 0
	_navigation_path_queries_this_tick = 0
	_navigation_delayed_this_tick = 0
	_navigation_fallback_queries_this_tick = 0
	_navigation_unreachable_queries_this_tick = 0
	_navigation_last_delay_reason = ""
	_navigation_last_tick_queries.clear()
	_navigation_last_path_metrics.clear()


func _finish_navigation_budget_tick() -> void:
	if _navigation_last_tick_queries.size() > navigation_debug_query_history_limit:
		_navigation_last_tick_queries = _navigation_last_tick_queries.slice(_navigation_last_tick_queries.size() - navigation_debug_query_history_limit)


func _try_begin_navigation_path_request(cmd: Dictionary, unit, current_position: Vector2, target_position: Vector2) -> bool:
	var max_queries: int = maxi(0, navigation_max_new_path_queries_per_tick)
	if navigation_budget_enabled and is_processing_tick and _navigation_new_path_queries_this_tick >= max_queries:
		_delay_navigation_path_request(cmd, unit, current_position, target_position, "budget_exhausted")
		return false
	if is_processing_tick and _uses_regional_navigation(_get_terrain_registry()):
		var unit_id := _extract_unit_id_for_path_recompute(unit)
		if not _regional_navigation_admissions.has(unit_id):
			_delay_navigation_path_request(cmd, unit, current_position, target_position, "regional_search_turn")
			return false
		_regional_navigation_last_service_tick[unit_id] = tick_counter

	_navigation_new_path_queries_this_tick += 1
	cmd.erase("navigation_pending_reason")
	cmd.erase("navigation_pending_since_tick")
	return true


func _prepare_regional_navigation_admissions() -> void:
	_regional_navigation_admissions.clear()
	if is_hex_ground_runtime_active():
		_regional_navigation_last_service_tick.clear()
		return
	var registry = _get_terrain_registry()
	if not _uses_regional_navigation(registry):
		_regional_navigation_last_service_tick.clear()
		return
	var candidates: Array[Dictionary] = []
	var next_history: Dictionary = {}
	var revision := _get_terrain_registry_revision(registry)
	for index in range(command_queue.size()):
		var command: Dictionary = command_queue[index]
		if _extract_command_type(command) not in ["move_to_position", "engage_area"]:
			continue
		if not Array(command.get("path", [])).is_empty() and not bool(command.get("local_avoidance_repath_requested", false)) and int(command.get("navigation_path_terrain_revision", -1)) == revision:
			continue
		var unit_id := String(command.get("unit_id", ""))
		var last_tick: int = _regional_navigation_last_service_tick.get(unit_id, -1)
		next_history[unit_id] = last_tick
		candidates.append({"unit_id": unit_id, "priority": _extract_priority(command), "last_tick": last_tick, "index": index})
	_regional_navigation_last_service_tick = next_history
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.priority != b.priority:
			return int(a.priority) > int(b.priority)
		if a.last_tick != b.last_tick:
			return int(a.last_tick) < int(b.last_tick)
		return int(a.index) < int(b.index)
	)
	var slots := REGIONAL_NAVIGATION_EXPANSIONS_PER_TICK / REGIONAL_NAVIGATION_EXPANSIONS_PER_SLICE
	if navigation_budget_enabled:
		slots = mini(slots, maxi(0, navigation_max_new_path_queries_per_tick))
	for candidate: Dictionary in candidates:
		if _regional_navigation_admissions.size() >= slots:
			break
		_regional_navigation_admissions[candidate.unit_id] = REGIONAL_NAVIGATION_EXPANSIONS_PER_SLICE
	# Reuse the existing total budget when fewer than four jobs are admitted.
	# Selection, priority and least-recent-service rotation stay unchanged.
	if not _regional_navigation_admissions.is_empty():
		var share: int = REGIONAL_NAVIGATION_EXPANSIONS_PER_TICK / _regional_navigation_admissions.size()
		for unit_id: String in _regional_navigation_admissions:
			_regional_navigation_admissions[unit_id] = share


func _delay_navigation_path_request(cmd: Dictionary, unit, current_position: Vector2, target_position: Vector2, reason: String) -> void:
	_navigation_delayed_this_tick += 1
	_navigation_last_delay_reason = reason
	var delayed_cmd: Dictionary = cmd.duplicate(true)
	delayed_cmd["path"] = []
	delayed_cmd["navigation_pending_reason"] = reason
	delayed_cmd["navigation_pending_since_tick"] = tick_counter
	delayed_cmd["navigation_delay_count"] = int(cmd.get("navigation_delay_count", 0)) + 1
	enqueue_command(delayed_cmd)

	var record: Dictionary = _make_navigation_record(cmd, unit, Vector2i.ZERO, Vector2i.ZERO, {}, 0, "delayed", reason, 0)
	record["current_position"] = current_position
	record["target_position"] = target_position
	record["delayed"] = true
	var pending_search: Variant = cmd.get("_regional_navigation_search")
	if pending_search != null:
		record["duration_usec"] = pending_search.last_slice_usec if reason == "regional_search_pending" else 0
		record["search_total_usec"] = pending_search.work_usec
		record["search_max_slice_usec"] = pending_search.max_slice_usec
		record["search_expanded_count"] = pending_search.expanded_count
	_append_navigation_debug_record(record)


func _record_navigation_path_query(
	cmd: Dictionary,
	unit,
	from_grid: Vector2i,
	to_grid: Vector2i,
	query_result: Dictionary,
	duration_usec: int,
	query_kind: String,
	reason: String,
	candidate_count: int
) -> void:
	_navigation_path_queries_this_tick += 1
	if query_kind == "fallback":
		_navigation_fallback_queries_this_tick += 1
	var record: Dictionary = _make_navigation_record(cmd, unit, from_grid, to_grid, query_result, duration_usec, query_kind, reason, candidate_count)
	if bool(record.get("unreachable", false)):
		_navigation_unreachable_queries_this_tick += 1
	_append_navigation_debug_record(record)


func _make_navigation_record(
	cmd: Dictionary,
	unit,
	from_grid: Vector2i,
	to_grid: Vector2i,
	query_result: Dictionary,
	duration_usec: int,
	query_kind: String,
	reason: String,
	candidate_count: int
) -> Dictionary:
	var path: Array = Array(query_result.get("path", []))
	var status: String = String(query_result.get("status", ""))
	var unit_id: String = _extract_unit_id_for_path_recompute(unit)
	if unit_id.is_empty():
		unit_id = String(cmd.get("unit_id", ""))
	var route_type: String = "none"
	if status in ["direct_a_star", "regional_nearest_reachable"]:
		route_type = "direct_a_star"
	elif status == HPA_PATHFINDER_SCRIPT.STATUS_HPA or status == HPA_PATHFINDER_SCRIPT.STATUS_SAME_COMPONENT:
		route_type = "hpa"
	elif query_kind == "delayed":
		route_type = "delayed"
	var unreachable: bool = path.is_empty() and (
		status == HPA_PATHFINDER_SCRIPT.STATUS_NO_ABSTRACT_ROUTE
		or status == HPA_PATHFINDER_SCRIPT.STATUS_NO_COMPONENT
		or status == HPA_PATHFINDER_SCRIPT.STATUS_LOCAL_PATH_FAILED
		or status == HPA_PATHFINDER_SCRIPT.STATUS_INVALID
	)
	unreachable = unreachable or status == "regional_nearest_reachable"
	var backend_snapshot: Dictionary = get_navigation_backend_debug_snapshot()
	return {
		"tick": tick_counter,
		"unit_id": unit_id,
		"command_type": String(cmd.get("command_type", cmd.get("type", ""))),
		"priority": _extract_priority(cmd),
		"query_kind": query_kind,
		"route_type": route_type,
		"status": status,
		"backend": String(backend_snapshot.get("last_backend", "none")),
		"backend_fallback_reason": String(backend_snapshot.get("fallback_reason", "")),
		"from_grid": from_grid,
		"to_grid": to_grid,
		"duration_usec": duration_usec,
		"search_elapsed_usec": int(query_result.get("search_elapsed_usec", duration_usec)),
		"search_max_slice_usec": int(query_result.get("search_max_slice_usec", duration_usec)),
		"path_grid_count": path.size(),
		"path_length_grid": int(query_result.get("path_length_grid", path.size())),
		"exposure_sum": float(query_result.get("exposure_sum", 0.0)),
		"cover_sum": float(query_result.get("cover_sum", 0.0)),
		"mean_exposure": float(query_result.get("mean_exposure", 0.0)),
		"mean_cover": float(query_result.get("mean_cover", 0.0)),
		"path_cost": float(query_result.get("path_cost", 0.0)),
		"candidate_count_estimate": candidate_count,
		"expanded_node_estimate": maxi(candidate_count, path.size()),
		"fallback_or_delay_reason": reason,
		"unreachable": unreachable,
	}


func _append_navigation_debug_record(record: Dictionary) -> void:
	if not navigation_debug_enabled:
		return
	_navigation_last_tick_queries.append(record)
	if _navigation_last_tick_queries.size() > navigation_debug_query_history_limit:
		_navigation_last_tick_queries.pop_front()
	var duration_usec: int = int(record.get("duration_usec", 0))
	if _navigation_most_expensive_query.is_empty() or duration_usec > int(_navigation_most_expensive_query.get("duration_usec", -1)):
		_navigation_most_expensive_query = record.duplicate(true)
	if String(record.get("query_kind", "")) != "delayed":
		_navigation_last_path_metrics = {
			"unit_id": String(record.get("unit_id", "")),
			"query_kind": String(record.get("query_kind", "")),
			"route_type": String(record.get("route_type", "")),
			"status": String(record.get("status", "")),
			"path_length_grid": int(record.get("path_length_grid", 0)),
			"exposure_sum": float(record.get("exposure_sum", 0.0)),
			"cover_sum": float(record.get("cover_sum", 0.0)),
			"mean_exposure": float(record.get("mean_exposure", 0.0)),
			"mean_cover": float(record.get("mean_cover", 0.0)),
			"path_cost": float(record.get("path_cost", 0.0)),
		}


func _count_pending_navigation_queries() -> int:
	var pending_count: int = 0
	for queued_command in command_queue:
		if typeof(queued_command) != TYPE_DICTIONARY:
			continue
		if not String(Dictionary(queued_command).get("navigation_pending_reason", "")).strip_edges().is_empty():
			pending_count += 1
	return pending_count


func _duplicate_dictionary_array(values: Array) -> Array:
	var result: Array = []
	for value in values:
		if typeof(value) == TYPE_DICTIONARY:
			result.append(Dictionary(value).duplicate(true))
	return result


func _prepare_local_avoidance_tick(force: bool = false) -> void:
	if not local_avoidance_enabled and not force:
		_local_avoidance_prepared_tick = -1
		return
	if _local_avoidance_prepared_tick == tick_counter:
		return
	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_all_units"):
		_local_avoidance_resolver.clear()
		_local_avoidance_prepared_tick = tick_counter
		return
	_local_avoidance_resolver.call(
		"build_from_units",
		_get_legacy_spacing_units(Array(unit_registry.call("get_all_units"))),
		local_avoidance_agent_radius,
		local_avoidance_spatial_cell_size
	)
	_local_avoidance_prepared_tick = tick_counter


func _enforce_unit_minimum_spacing() -> void:
	if not unit_minimum_spacing_enabled:
		return
	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_all_units"):
		return
	var units: Array = []
	for unit in Array(unit_registry.call("get_all_units")):
		if not (unit is Node2D):
			continue
		if is_hex_ground_runtime_active() and unit.has_method("get_unit_id") and _hex_ground_runtime.has_unit(String(unit.call("get_unit_id"))):continue
		if unit.has_method("get_unit_id") and String(unit.call("get_unit_id")).strip_edges().is_empty():
			continue
		units.append(unit)
	if units.size() < 2:
		_unit_minimum_spacing_debug_snapshot = {
			"tick": tick_counter,
			"enabled": true,
			"minimum_distance": unit_minimum_spacing_distance,
			"unit_count": units.size(),
			"moved_unit_ids": [],
			"minimum_distance_after": INF,
			"minimum_distance_measured": unit_minimum_spacing_debug_enabled,
			"solver_pair_check_count": 0,
			"diagnostic_pair_check_count": 0,
			"blocked_pair_count": 0,
			"downed_units_keep_space": true,
		}
		return
	var result: Dictionary = Dictionary(_local_avoidance_resolver.call(
		"resolve_minimum_spacing_positions",
		units,
		unit_minimum_spacing_distance,
		_get_terrain_registry(),
		unit_minimum_spacing_solver_iterations,
		unit_minimum_spacing_debug_enabled
	))
	var positions_by_unit_id: Dictionary = Dictionary(result.get("positions_by_unit_id", {}))
	var moved_unit_ids: Array = Array(result.get("moved_unit_ids", []))
	var moved_lookup: Dictionary = {}
	for unit_id_variant in moved_unit_ids:
		moved_lookup[String(unit_id_variant)] = true
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty() or not moved_lookup.has(unit_id):
			continue
		var next_position: Variant = positions_by_unit_id.get(unit_id, null)
		if typeof(next_position) != TYPE_VECTOR2:
			continue
		(unit as Node2D).global_position = Vector2(next_position)
		if unit.has_method("refresh_terrain_readability"):
			unit.call("refresh_terrain_readability")
		_update_local_avoidance_agent_position(unit_id, (unit as Node2D).global_position)
	_unit_minimum_spacing_debug_snapshot = {
		"tick": tick_counter,
		"enabled": true,
		"minimum_distance": float(result.get("minimum_distance", unit_minimum_spacing_distance)),
		"minimum_distance_after": float(result.get("minimum_distance_after", INF)),
		"minimum_distance_measured": bool(result.get("minimum_distance_measured", false)),
		"solver_pair_check_count": int(result.get("solver_pair_check_count", 0)),
		"diagnostic_pair_check_count": int(result.get("diagnostic_pair_check_count", 0)),
		"unit_count": units.size(),
		"moved_unit_ids": moved_unit_ids,
		"active_unit_ids": Array(result.get("active_unit_ids", [])),
		"resolved_pair_count": int(result.get("resolved_pair_count", 0)),
		"blocked_pair_count": int(result.get("blocked_pair_count", 0)),
		"blocked_pairs": Array(result.get("blocked_pairs", [])).duplicate(true),
		"downed_units_keep_space": true,
	}
	if unit_minimum_spacing_debug_enabled and int(_unit_minimum_spacing_debug_snapshot.get("blocked_pair_count", 0)) > 0:
		push_warning("SimulationRoot minimum spacing could not separate every active unit pair.")


func _get_legacy_spacing_units(units:Array) -> Array:
	if not is_hex_ground_runtime_active():return units
	var legacy:Array=[]
	for unit in units:
		if is_instance_valid(unit) and unit.has_method("get_unit_id") and _hex_ground_runtime.has_unit(String(unit.call("get_unit_id"))):continue
		legacy.append(unit)
	return legacy


func _is_local_avoidance_enabled_for_command(cmd: Dictionary) -> bool:
	if cmd.has("local_avoidance_enabled"):
		return bool(cmd.get("local_avoidance_enabled", false))
	return local_avoidance_enabled


func _resolve_local_avoidance_velocity(
	cmd: Dictionary,
	unit_node: Node2D,
	current_position: Vector2,
	desired_velocity: Vector2,
	max_speed: float,
	delta: float,
	terrain_registry
) -> Vector2:
	var command_avoidance_enabled: bool = _is_local_avoidance_enabled_for_command(cmd)
	if unit_node == null or not command_avoidance_enabled or desired_velocity.is_zero_approx():
		return desired_velocity
	_prepare_local_avoidance_tick(command_avoidance_enabled)
	var unit_id: String = _extract_unit_id_for_path_recompute(unit_node)
	var started_usec: int = Time.get_ticks_usec()
	var result: Dictionary = Dictionary(_local_avoidance_resolver.call(
		"solve_velocity",
		unit_id,
		current_position,
		desired_velocity,
		max_speed,
		local_avoidance_neighbor_radius,
		local_avoidance_max_neighbors
	))
	var safe_velocity: Vector2 = Vector2(result.get("safe_velocity", desired_velocity))
	safe_velocity = _preserve_local_avoidance_forward_progress(desired_velocity, safe_velocity, max_speed)
	var discarded_correction: bool = false
	var discard_reason: String = ""
	if terrain_registry != null:
		var candidate_position: Vector2 = current_position + safe_velocity * delta
		if not _is_local_avoidance_transition_walkable(current_position, candidate_position, terrain_registry):
			var desired_position: Vector2 = current_position + desired_velocity * delta
			discarded_correction = true
			discard_reason = "non_walkable_correction"
			if _is_local_avoidance_transition_walkable(current_position, desired_position, terrain_registry):
				safe_velocity = desired_velocity
			else:
				safe_velocity = Vector2.ZERO
				discard_reason = "non_walkable_desired"
	result["safe_velocity"] = safe_velocity
	result["correction_velocity"] = safe_velocity - desired_velocity
	result["discarded_correction"] = discarded_correction
	result["discard_reason"] = discard_reason
	result["duration_usec"] = Time.get_ticks_usec() - started_usec
	_record_local_avoidance_debug(cmd, unit_id, result, delta)
	return safe_velocity


func _preserve_local_avoidance_forward_progress(desired_velocity: Vector2, safe_velocity: Vector2, max_speed: float) -> Vector2:
	var desired_speed: float = desired_velocity.length()
	if desired_speed <= 0.001 or max_speed <= 0.001:
		return safe_velocity
	var desired_direction: Vector2 = desired_velocity / desired_speed
	var minimum_forward_speed: float = minf(desired_speed, max_speed) * LOCAL_AVOIDANCE_MIN_FORWARD_PROGRESS_FACTOR
	var current_forward_speed: float = safe_velocity.dot(desired_direction)
	if current_forward_speed >= minimum_forward_speed:
		return safe_velocity
	var lateral_velocity: Vector2 = safe_velocity - desired_direction * current_forward_speed
	var next_velocity: Vector2 = desired_direction * minimum_forward_speed + lateral_velocity
	if next_velocity.length() > max_speed:
		next_velocity = next_velocity.normalized() * max_speed
	return next_velocity


func _is_local_avoidance_transition_walkable(from_position: Vector2, to_position: Vector2, terrain_registry) -> bool:
	if not _is_local_avoidance_position_walkable(to_position, terrain_registry): return false
	if terrain_registry == null or not terrain_registry.has_method("get_tile_at_world"): return true
	var from_tile = terrain_registry.call("get_tile_at_world", from_position)
	var to_tile = terrain_registry.call("get_tile_at_world", to_position)
	var explicit_ramp_rules: bool = (from_tile != null and bool(from_tile.explicit_hex_ramps)) \
		or (to_tile != null and bool(to_tile.explicit_hex_ramps))
	if not explicit_ramp_rules: return true
	# Reuse the same bounded segment partition as minimum-spacing correction.
	# Every crossed edge is checked by TerrainPathfinder, including ramp flanks.
	return bool(_local_avoidance_resolver.call("_is_spacing_transition_walkable", from_position, to_position, terrain_registry))


func _is_local_avoidance_position_walkable(position: Vector2, terrain_registry) -> bool:
	if terrain_registry == null or not terrain_registry.has_method("world_to_grid") or not terrain_registry.has_method("is_walkable"):
		return true
	return bool(terrain_registry.call("is_walkable", terrain_registry.call("world_to_grid", position)))


func _update_local_avoidance_agent_position(unit_id: String, position: Vector2) -> void:
	if unit_id.strip_edges().is_empty():
		return
	if _local_avoidance_prepared_tick != tick_counter:
		return
	_local_avoidance_resolver.call("update_agent_position", unit_id, position)


func _record_local_avoidance_debug(cmd: Dictionary, unit_id: String, result: Dictionary, delta: float) -> void:
	var desired_velocity: Vector2 = Vector2(result.get("desired_velocity", Vector2.ZERO))
	var safe_velocity: Vector2 = Vector2(result.get("safe_velocity", desired_velocity))
	var desired_speed: float = desired_velocity.length()
	var safe_speed: float = safe_velocity.length()
	var stuck_seconds: float = float(_local_avoidance_stuck_seconds_by_unit_id.get(unit_id, 0.0))
	if desired_speed > local_avoidance_stuck_speed_threshold and safe_speed <= local_avoidance_stuck_speed_threshold:
		stuck_seconds += delta
	else:
		stuck_seconds = maxf(stuck_seconds - delta, 0.0)
	_local_avoidance_stuck_seconds_by_unit_id[unit_id] = stuck_seconds
	var deadlock_marked: bool = stuck_seconds >= local_avoidance_stuck_threshold_seconds
	if deadlock_marked:
		cmd["local_avoidance_deadlock"] = true
		cmd["local_avoidance_repath_requested"] = true
	if not local_avoidance_debug_enabled:
		return
	var neighbors: Array = Array(result.get("neighbors", []))
	var neighbor_ids: Array = []
	for neighbor_variant in neighbors:
		neighbor_ids.append(String(Dictionary(neighbor_variant).get("unit_id", "")))
	_local_avoidance_debug_by_unit_id[unit_id] = {
		"tick": tick_counter,
		"unit_id": unit_id,
		"neighbor_count": int(result.get("neighbor_count", 0)),
		"neighbor_ids": neighbor_ids,
		"collision_risk_count": int(result.get("collision_risk_count", 0)),
		"desired_velocity": desired_velocity,
		"avoidance_velocity": safe_velocity,
		"correction_velocity": Vector2(result.get("correction_velocity", Vector2.ZERO)),
		"stuck_time_seconds": stuck_seconds,
		"deadlock_marked": deadlock_marked,
		"discarded_correction": bool(result.get("discarded_correction", false)),
		"discard_reason": String(result.get("discard_reason", "")),
		"duration_usec": int(result.get("duration_usec", 0)),
		"command_local_avoidance_enabled": bool(cmd.get("local_avoidance_enabled", false)),
	}


func _extract_unit_id_for_path_recompute(unit) -> String:
	if unit == null or not unit.has_method("get_unit_id"):
		return ""

	return String(unit.call("get_unit_id"))


func _is_unit_in_contact(unit) -> bool:
	return unit != null and unit.has_method("is_in_contact") and bool(unit.call("is_in_contact"))


func _build_path_world_points(current_position: Vector2, target_position: Vector2, terrain_registry, cmd: Dictionary = {}, unit = null) -> Array:
	var path_world_points: Array = []
	if terrain_registry == null or _terrain_pathfinder == null:
		path_world_points.append(target_position)
		return path_world_points

	var from_grid: Vector2i = terrain_registry.call("world_to_grid", current_position)
	var target_resolution: Dictionary = _resolve_walkable_move_target(target_position, terrain_registry)
	var raw_replacement_grid: Variant = target_resolution.get("replacement_grid", terrain_registry.call("world_to_grid", target_position))
	var to_grid: Vector2i = raw_replacement_grid if typeof(raw_replacement_grid) == TYPE_VECTOR2I else terrain_registry.call("world_to_grid", target_position)
	var target_grid_was_walkable: bool = bool(target_resolution.get("target_walkable", true))
	var resolved_target_position: Vector2 = Vector2(target_resolution.get("replacement_position", target_position))
	if terrain_registry.has_method("is_walkable") and not bool(terrain_registry.call("is_walkable", from_grid)):
		var nearest_start_grid: Variant = terrain_registry.call("get_nearest_walkable_grid", current_position) if terrain_registry.has_method("get_nearest_walkable_grid") else null
		if typeof(nearest_start_grid) == TYPE_VECTOR2I:
			from_grid = nearest_start_grid

	var navigation_options: Dictionary = _build_navigation_cost_options(cmd, terrain_registry)
	if _uses_regional_navigation(terrain_registry):
		return _build_regional_path_world_points(cmd, unit, terrain_registry, from_grid, to_grid, resolved_target_position, navigation_options)
	var navigation_started_usec: int = Time.get_ticks_usec()
	var navigation_query: Dictionary = _find_navigation_grid_path(from_grid, to_grid, terrain_registry, navigation_options)
	var navigation_duration_usec: int = Time.get_ticks_usec() - navigation_started_usec
	var path_grid_points: Array = Array(navigation_query.get("path", []))
	var navigation_status: String = String(navigation_query.get("status", ""))
	_annotate_navigation_query_metrics(navigation_query, path_grid_points, terrain_registry, navigation_options)
	_record_navigation_path_query(cmd, unit, from_grid, to_grid, navigation_query, navigation_duration_usec, "primary", "", path_grid_points.size())
	path_grid_points = _simplify_grid_path_turns(path_grid_points)
	if path_grid_points.is_empty():
		if from_grid == to_grid:
			path_world_points.append(resolved_target_position)
			return path_world_points

		var reachable_grid: Variant = _find_hpa_reachable_walkable_grid(from_grid, to_grid, terrain_registry) if navigation_status == HPA_PATHFINDER_SCRIPT.STATUS_NO_ABSTRACT_ROUTE else _find_nearest_reachable_walkable_grid(from_grid, to_grid, terrain_registry)
		if typeof(reachable_grid) != TYPE_VECTOR2I:
			return path_world_points
		var fallback_started_usec: int = Time.get_ticks_usec()
		var fallback_query: Dictionary = _find_navigation_grid_path(from_grid, reachable_grid, terrain_registry, navigation_options)
		var fallback_duration_usec: int = Time.get_ticks_usec() - fallback_started_usec
		var fallback_path_grid_points: Array = Array(fallback_query.get("path", []))
		_annotate_navigation_query_metrics(fallback_query, fallback_path_grid_points, terrain_registry, navigation_options)
		_record_navigation_path_query(cmd, unit, from_grid, reachable_grid, fallback_query, fallback_duration_usec, "fallback", navigation_status, fallback_path_grid_points.size())
		fallback_path_grid_points = _simplify_grid_path_turns(fallback_path_grid_points)
		if fallback_path_grid_points.is_empty() and reachable_grid != from_grid:
			return path_world_points
		for fallback_index in range(1, fallback_path_grid_points.size()):
			path_world_points.append(terrain_registry.call("grid_to_world", fallback_path_grid_points[fallback_index]))
		if path_world_points.is_empty():
			path_world_points.append(terrain_registry.call("grid_to_world", reachable_grid))
		return path_world_points

	for index in range(1, path_grid_points.size()):
		path_world_points.append(terrain_registry.call("grid_to_world", path_grid_points[index]))

	if target_grid_was_walkable and (path_world_points.is_empty() or _coerce_vector2(path_world_points[-1], target_position).distance_to(target_position) > 0.5):
		path_world_points.append(target_position)

	return path_world_points


func _uses_regional_navigation(terrain_registry) -> bool:
	return (
		_uses_hex_movement_metric(terrain_registry)
		and terrain_registry.has_method("get_tile_count")
		and int(terrain_registry.call("get_tile_count")) >= REGIONAL_NAVIGATION_MIN_TILES
	)


func _build_regional_path_world_points(cmd: Dictionary, unit, terrain_registry, from_grid: Vector2i, to_grid: Vector2i, resolved_target: Vector2, options: Dictionary) -> Array:
	var revision := _get_terrain_registry_revision(terrain_registry)
	var search = cmd.get("_regional_navigation_search")
	if (
		search == null or search.source != from_grid or search.goal != to_grid
		or search.revision != revision or search.registry_id != terrain_registry.get_instance_id()
		or search.cost_options != options
	):
		search = create_regional_navigation_search(from_grid, to_grid, terrain_registry, options)
		cmd["_regional_navigation_search"] = search
	var limit := REGIONAL_NAVIGATION_EXPANSIONS_PER_SLICE
	if is_processing_tick:
		var unit_id := _extract_unit_id_for_path_recompute(unit)
		limit = int(_regional_navigation_admissions.get(unit_id, limit))
		limit = mini(limit, REGIONAL_NAVIGATION_EXPANSIONS_PER_TICK - _regional_navigation_expansions_this_tick)
	var started := Time.get_ticks_usec()
	_note_regional_navigation_backend(search)
	_regional_navigation_expansions_this_tick += search.advance(_terrain_pathfinder, terrain_registry, limit)
	search.last_slice_usec = Time.get_ticks_usec() - started
	search.work_usec += search.last_slice_usec
	search.max_slice_usec = maxi(search.max_slice_usec, search.last_slice_usec)
	if not search.finished:
		return []
	cmd.erase("_regional_navigation_search")
	cmd["_regional_navigation_route"] = true
	var reached: bool = not search.path.is_empty() and search.path[-1] == to_grid
	if navigation_debug_enabled:
		var result := {"path": search.path, "status": "direct_a_star" if reached else "regional_nearest_reachable"}
		_annotate_navigation_query_metrics(result, search.path, terrain_registry, options)
		result["search_elapsed_usec"] = Time.get_ticks_usec() - search.started_usec
		result["search_max_slice_usec"] = search.max_slice_usec
		_record_navigation_path_query(cmd, unit, from_grid, to_grid, result, search.work_usec, "primary", "", search.expanded_count)
	var simplified := _simplify_grid_path_turns(search.path)
	var world_path: Array = []
	for index in range(1, simplified.size()):
		world_path.append(terrain_registry.call("grid_to_world", simplified[index]))
	if reached and (world_path.is_empty() or Vector2(world_path[-1]).distance_to(resolved_target) > 0.5):
		world_path.append(resolved_target)
	return world_path


func _simplify_grid_path_turns(path_grid_points: Array) -> Array:
	if path_grid_points.size() <= 2:
		return path_grid_points.duplicate()
	var simplified: Array = [Vector2i(path_grid_points[0]), Vector2i(path_grid_points[1])]
	var previous_direction: Vector2i = _grid_step_direction(Vector2i(path_grid_points[0]), Vector2i(path_grid_points[1]))
	for index in range(2, path_grid_points.size()):
		var current_direction: Vector2i = _grid_step_direction(Vector2i(path_grid_points[index - 1]), Vector2i(path_grid_points[index]))
		if current_direction != previous_direction:
			simplified.append(Vector2i(path_grid_points[index - 1]))
		previous_direction = current_direction
	simplified.append(Vector2i(path_grid_points[-1]))
	return simplified


func _grid_step_direction(from_grid: Vector2i, to_grid: Vector2i) -> Vector2i:
	var delta: Vector2i = to_grid - from_grid
	var direction_x: int = 0
	var direction_y: int = 0
	if delta.x > 0:
		direction_x = 1
	elif delta.x < 0:
		direction_x = -1
	if delta.y > 0:
		direction_y = 1
	elif delta.y < 0:
		direction_y = -1
	return Vector2i(direction_x, direction_y)


func _build_navigation_cost_options(cmd: Dictionary, terrain_registry) -> Dictionary:
	var cover_aware_enabled: bool = navigation_cover_aware_enabled
	if cmd.has("navigation_cover_aware"):
		cover_aware_enabled = bool(cmd.get("navigation_cover_aware", false))
	elif cmd.has("cover_aware_navigation"):
		cover_aware_enabled = bool(cmd.get("cover_aware_navigation", false))

	var weights: Dictionary = _get_navigation_cost_weights_for_command(cmd)
	if cmd.has("navigation_exposure_weight"):
		weights["exposure_weight"] = maxf(float(cmd.get("navigation_exposure_weight", 0.0)), 0.0)
	if cmd.has("navigation_cover_weight"):
		weights["cover_weight"] = maxf(float(cmd.get("navigation_cover_weight", 0.0)), 0.0)

	var options: Dictionary = {
		"cover_aware_enabled": cover_aware_enabled,
		"exposure_weight": float(weights.get("exposure_weight", navigation_default_exposure_weight)),
		"cover_weight": float(weights.get("cover_weight", navigation_default_cover_weight)),
		"exposure_max_grid_distance": float(cmd.get("navigation_exposure_max_grid_distance", navigation_exposure_max_grid_distance)),
		"hazard_grids": _extract_navigation_hazard_grids(cmd, terrain_registry),
	}
	_append_navigation_corridor_options(options, cmd, terrain_registry)
	return options


func _get_navigation_cost_weights_for_command(cmd: Dictionary) -> Dictionary:
	var source_command_type: String = String(cmd.get("source_command_type", cmd.get("origin_command_type", ""))).strip_edges().to_lower()
	if source_command_type.is_empty():
		var command_type: String = String(cmd.get("command_type", cmd.get("type", ""))).strip_edges().to_lower()
		match command_type:
			"engage_area":
				source_command_type = "engage"
			"move_to_position":
				source_command_type = "move"
			_:
				source_command_type = command_type
	match source_command_type:
		"defend":
			return {"exposure_weight": 0.9, "cover_weight": 0.75}
		"take", "engage":
			return {"exposure_weight": 1.1, "cover_weight": 0.45}
		"flank":
			return {"exposure_weight": 1.2, "cover_weight": 0.3}
		"rush":
			return {"exposure_weight": 0.15, "cover_weight": 0.05}
		_:
			return {"exposure_weight": navigation_default_exposure_weight, "cover_weight": navigation_default_cover_weight}


func _extract_navigation_hazard_grids(cmd: Dictionary, terrain_registry) -> Array:
	var hazard_grids: Array = []
	for key in ["navigation_threat_grids", "threat_grids", "danger_grids"]:
		for grid_variant in Array(cmd.get(key, [])):
			_append_unique_navigation_hazard_grid(hazard_grids, Vector2i(grid_variant))
	if terrain_registry != null and terrain_registry.has_method("world_to_grid"):
		for key in ["navigation_threat_positions", "threat_positions", "danger_positions", "enemy_positions"]:
			for position_variant in Array(cmd.get(key, [])):
				if typeof(position_variant) != TYPE_VECTOR2:
					continue
				_append_unique_navigation_hazard_grid(hazard_grids, terrain_registry.call("world_to_grid", Vector2(position_variant)))
	hazard_grids.sort_custom(func(a, b) -> bool:
		var grid_a: Vector2i = Vector2i(a)
		var grid_b: Vector2i = Vector2i(b)
		if grid_a.x == grid_b.x:
			return grid_a.y < grid_b.y
		return grid_a.x < grid_b.x
	)
	return hazard_grids


func _append_unique_navigation_hazard_grid(hazard_grids: Array, grid_position: Vector2i) -> void:
	if not hazard_grids.has(grid_position):
		hazard_grids.append(grid_position)


func _append_navigation_corridor_options(options: Dictionary, cmd: Dictionary, terrain_registry) -> void:
	if terrain_registry == null or not terrain_registry.has_method("world_to_grid"):
		return
	if bool(cmd.get("navigation_corridor_enabled", false)):
		var start_position_variant: Variant = cmd.get("navigation_corridor_start_position", null)
		var end_position_variant: Variant = cmd.get("navigation_corridor_end_position", null)
		if typeof(start_position_variant) == TYPE_VECTOR2 and typeof(end_position_variant) == TYPE_VECTOR2:
			options["corridor_enabled"] = true
			options["corridor_from_grid"] = terrain_registry.call("world_to_grid", Vector2(start_position_variant))
			options["corridor_to_grid"] = terrain_registry.call("world_to_grid", Vector2(end_position_variant))
			options["corridor_half_width_grid"] = _world_distance_to_navigation_grid_distance(
				maxf(float(cmd.get("navigation_corridor_half_width_world", 0.0)), 0.0),
				terrain_registry
			)
			options["corridor_weight"] = maxf(float(cmd.get("navigation_corridor_weight", 0.0)), 0.0)
	if bool(cmd.get("navigation_lane_enabled", false)):
		options["lane_enabled"] = true
		var lane_sample_variant: Variant = cmd.get("navigation_lane_sample_position", null)
		if (
			bool(options.get("corridor_enabled", false))
			and typeof(lane_sample_variant) == TYPE_VECTOR2
			and options.has("corridor_from_grid")
			and options.has("corridor_to_grid")
		):
			options["lane_offset_grid"] = _signed_navigation_grid_line_distance(
				Vector2i(terrain_registry.call("world_to_grid", Vector2(lane_sample_variant))),
				Vector2i(options.get("corridor_from_grid", Vector2i.ZERO)),
				Vector2i(options.get("corridor_to_grid", Vector2i.ZERO))
			)
		else:
			options["lane_offset_grid"] = _world_distance_to_navigation_grid_distance(
				float(cmd.get("navigation_lane_offset_world", 0.0)),
				terrain_registry
			)
		options["lane_weight"] = maxf(float(cmd.get("navigation_lane_weight", 0.0)), 0.0)
	if cmd.has("navigation_blocker_clearance_weight"):
		options["blocker_clearance_weight"] = maxf(float(cmd.get("navigation_blocker_clearance_weight", 0.0)), 0.0)
	if cmd.has("navigation_blocker_clearance_radius"):
		options["blocker_clearance_radius"] = maxi(int(cmd.get("navigation_blocker_clearance_radius", 1)), 1)


func _world_distance_to_navigation_grid_distance(world_distance: float, terrain_registry) -> float:
	if is_zero_approx(world_distance):
		return 0.0
	if terrain_registry == null or not terrain_registry.has_method("grid_to_world"):
		return world_distance
	var origin_world: Vector2 = Vector2(terrain_registry.call("grid_to_world", Vector2i.ZERO))
	var x_world: Vector2 = Vector2(terrain_registry.call("grid_to_world", Vector2i.RIGHT))
	var y_world: Vector2 = Vector2(terrain_registry.call("grid_to_world", Vector2i.DOWN))
	var tile_world_distance: float = maxf((x_world - origin_world).length(), (y_world - origin_world).length())
	if tile_world_distance <= 0.001:
		return world_distance
	return world_distance / tile_world_distance


func _signed_navigation_grid_line_distance(grid_position: Vector2i, from_grid: Vector2i, to_grid: Vector2i) -> float:
	var from_value: Vector2 = Vector2(from_grid)
	var to_value: Vector2 = Vector2(to_grid)
	var point_value: Vector2 = Vector2(grid_position)
	var line: Vector2 = to_value - from_value
	var length: float = line.length()
	if length <= 0.001:
		return 0.0
	return line.cross(point_value - from_value) / length


func _annotate_navigation_query_metrics(query: Dictionary, path_grid_points: Array, terrain_registry, navigation_options: Dictionary) -> void:
	var path_metrics: Dictionary = Dictionary(_terrain_pathfinder.call("score_path", path_grid_points, terrain_registry, navigation_options))
	for key in path_metrics.keys():
		query[key] = path_metrics[key]


func _find_navigation_grid_path(from_grid: Vector2i, to_grid: Vector2i, terrain_registry, navigation_options: Dictionary = {}) -> Dictionary:
	var graph = _ensure_hpa_navigation_graph(terrain_registry)
	if graph != null and _hpa_pathfinder != null:
		var hpa_query: Dictionary
		if native_navigation_enabled:
			hpa_query = _native_navigation.find_path_with_status(from_grid, to_grid, terrain_registry, graph, navigation_options)
			_navigation_backend_debug.clear()
		else:
			hpa_query = Dictionary(_hpa_pathfinder.call("find_path_with_status", from_grid, to_grid, terrain_registry, graph, navigation_options))
			_set_gdscript_navigation_backend("native_navigation_disabled")
		var hpa_status: String = String(hpa_query.get("status", ""))
		if not Array(hpa_query.get("path", [])).is_empty():
			return hpa_query
		if hpa_status == HPA_PATHFINDER_SCRIPT.STATUS_NO_ABSTRACT_ROUTE or hpa_status == HPA_PATHFINDER_SCRIPT.STATUS_NO_COMPONENT:
			return hpa_query

	return {
		"path": _find_navigation_direct_path(from_grid, to_grid, terrain_registry, navigation_options),
		"status": "direct_a_star",
	}


func _find_navigation_direct_path(from_grid: Vector2i, to_grid: Vector2i, terrain_registry, navigation_options: Dictionary = {}) -> Array:
	if native_navigation_enabled:
		var path: Array = _native_navigation.find_path_with_options(from_grid, to_grid, terrain_registry, navigation_options)
		_navigation_backend_debug.clear()
		return path
	_set_gdscript_navigation_backend("native_navigation_disabled")
	return _terrain_pathfinder.find_path_with_options(from_grid, to_grid, terrain_registry, navigation_options)


func _ensure_hpa_navigation_graph(terrain_registry):
	if not is_instance_valid(terrain_registry) or not terrain_registry.has_method("get_all_tiles"):
		_clear_navigation_prepared_data()
		return null
	var tile_count: int = int(terrain_registry.call("get_tile_count")) if terrain_registry.has_method("get_tile_count") else Array(terrain_registry.call("get_all_tiles")).size()
	var registry_revision: int = _get_terrain_registry_revision(terrain_registry)
	if (
		_hpa_navigation_graph != null
		and _hpa_navigation_registry == terrain_registry
		and _hpa_navigation_tile_count == tile_count
		and _hpa_navigation_registry_revision == registry_revision
	):
		_hpa_navigation_cache_hit_count += 1
		return _hpa_navigation_graph
	var incremental_candidate: bool = (
		_hpa_navigation_graph != null
		and _hpa_navigation_registry == terrain_registry
		and _hpa_navigation_tile_count == tile_count
		and _hpa_navigation_graph.has_method("rebuild_dirty_clusters_from_registry")
	)
	var dirty_grids: Array = _get_terrain_registry_dirty_grids(terrain_registry) if incremental_candidate else []
	if not dirty_grids.is_empty():
		var incremental_built: bool = bool(_hpa_navigation_graph.call("rebuild_dirty_clusters_from_registry", terrain_registry, dirty_grids, HPA_NAVIGATION_CLUSTER_SIZE))
		_hpa_navigation_build_count += 1
		_hpa_navigation_last_build_stats = _get_hpa_graph_build_stats(_hpa_navigation_graph)
		_hpa_navigation_last_build_stats["registry_revision"] = registry_revision
		_hpa_navigation_last_build_stats["runtime_build_count"] = _hpa_navigation_build_count
		_hpa_navigation_last_build_stats["runtime_rebuild_mode"] = "incremental"
		if incremental_built:
			_hpa_navigation_registry_revision = registry_revision
			_clear_terrain_registry_dirty_grids(terrain_registry)
			return _hpa_navigation_graph
	_hpa_navigation_graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	var built: bool = bool(_hpa_navigation_graph.call("build_from_registry", terrain_registry, HPA_NAVIGATION_CLUSTER_SIZE))
	_hpa_navigation_build_count += 1
	_hpa_navigation_last_build_stats = _get_hpa_graph_build_stats(_hpa_navigation_graph)
	_hpa_navigation_last_build_stats["registry_revision"] = registry_revision
	_hpa_navigation_last_build_stats["runtime_build_count"] = _hpa_navigation_build_count
	_hpa_navigation_last_build_stats["runtime_rebuild_mode"] = "full"
	if not built:
		_hpa_navigation_graph = null
		_hpa_navigation_registry = null
		_hpa_navigation_tile_count = -1
		_hpa_navigation_registry_revision = -1
		return null
	_hpa_navigation_registry = terrain_registry
	_hpa_navigation_tile_count = tile_count
	_hpa_navigation_registry_revision = registry_revision
	_clear_terrain_registry_dirty_grids(terrain_registry)
	return _hpa_navigation_graph


func _get_terrain_registry_revision(terrain_registry) -> int:
	if terrain_registry != null and terrain_registry.has_method("get_revision"):
		return int(terrain_registry.call("get_revision"))
	return -1


func _get_terrain_registry_dirty_grids(terrain_registry) -> Array:
	if terrain_registry != null and terrain_registry.has_method("get_dirty_grid_positions"):
		return Array(terrain_registry.call("get_dirty_grid_positions"))
	return []


func _clear_terrain_registry_dirty_grids(terrain_registry) -> void:
	if terrain_registry != null and terrain_registry.has_method("clear_dirty_grid_positions"):
		terrain_registry.call("clear_dirty_grid_positions")


func _get_hpa_graph_build_stats(graph) -> Dictionary:
	if graph != null and graph.has_method("get_last_build_stats"):
		return Dictionary(graph.call("get_last_build_stats")).duplicate(true)
	return {}


func _resolve_walkable_move_target(target_position: Vector2, terrain_registry) -> Dictionary:
	if terrain_registry != null and terrain_registry.has_method("resolve_walkable_target"):
		return Dictionary(terrain_registry.call("resolve_walkable_target", target_position)).duplicate(true)
	var to_grid: Vector2i = terrain_registry.call("world_to_grid", target_position)
	var target_walkable: bool = bool(terrain_registry.call("is_walkable", to_grid)) if terrain_registry != null and terrain_registry.has_method("is_walkable") else true
	if target_walkable:
		return {
			"original_position": target_position,
			"original_grid": to_grid,
			"target_walkable": true,
			"replacement_grid": to_grid,
			"replacement_position": target_position,
			"blocked_grid": null,
			"blocked_position": null,
			"blocker_reason": "",
		}
	var nearest_target_grid: Variant = terrain_registry.call("get_nearest_walkable_grid", target_position) if terrain_registry != null and terrain_registry.has_method("get_nearest_walkable_grid") else to_grid
	return {
		"original_position": target_position,
		"original_grid": to_grid,
		"target_walkable": false,
		"replacement_grid": nearest_target_grid,
		"replacement_position": terrain_registry.call("grid_to_world", nearest_target_grid) if typeof(nearest_target_grid) == TYPE_VECTOR2I and terrain_registry.has_method("grid_to_world") else target_position,
		"blocked_grid": to_grid,
		"blocked_position": target_position,
		"blocker_reason": "target_not_walkable",
	}


func _find_hpa_reachable_walkable_grid(from_grid: Vector2i, desired_grid: Vector2i, terrain_registry) -> Variant:
	var graph = _ensure_hpa_navigation_graph(terrain_registry)
	if graph == null:
		return null
	var component_key: String = String(graph.call("get_component_key_for_grid", from_grid))
	if component_key.is_empty():
		return null
	var candidates: Array = Array(graph.call("get_component_tiles", component_key))
	candidates.sort_custom(func(a, b) -> bool:
		var grid_a: Vector2i = Vector2i(a)
		var grid_b: Vector2i = Vector2i(b)
		var distance_a: float = _grid_distance_score(grid_a, desired_grid)
		var distance_b: float = _grid_distance_score(grid_b, desired_grid)
		if absf(distance_a - distance_b) > 0.001:
			return distance_a < distance_b
		var source_distance_a: float = _grid_distance_score(grid_a, from_grid)
		var source_distance_b: float = _grid_distance_score(grid_b, from_grid)
		if absf(source_distance_a - source_distance_b) > 0.001:
			return source_distance_a < source_distance_b
		if grid_a.x == grid_b.x:
			return grid_a.y < grid_b.y
		return grid_a.x < grid_b.x
	)
	return null if candidates.is_empty() else Vector2i(candidates[0])


func _find_nearest_reachable_walkable_grid(from_grid: Vector2i, desired_grid: Vector2i, terrain_registry) -> Variant:
	if terrain_registry == null or not terrain_registry.has_method("get_all_tiles"):
		return null
	var candidates: Array = []
	for tile_data in Array(terrain_registry.call("get_all_tiles")):
		if tile_data == null or not bool(tile_data.walkable):
			continue
		candidates.append(tile_data)
	candidates.sort_custom(func(a, b) -> bool:
		var grid_a: Vector2i = Vector2i(a.grid_position)
		var grid_b: Vector2i = Vector2i(b.grid_position)
		var distance_a: float = _grid_distance_score(grid_a, desired_grid)
		var distance_b: float = _grid_distance_score(grid_b, desired_grid)
		if absf(distance_a - distance_b) > 0.001:
			return distance_a < distance_b
		var source_distance_a: float = _grid_distance_score(grid_a, from_grid)
		var source_distance_b: float = _grid_distance_score(grid_b, from_grid)
		if absf(source_distance_a - source_distance_b) > 0.001:
			return source_distance_a < source_distance_b
		if grid_a.x == grid_b.x:
			return grid_a.y < grid_b.y
		return grid_a.x < grid_b.x
	)
	for tile_data in candidates:
		var candidate_grid: Vector2i = Vector2i(tile_data.grid_position)
		if candidate_grid == from_grid:
			return candidate_grid
		if not _find_navigation_direct_path(from_grid, candidate_grid, terrain_registry).is_empty():
			return candidate_grid
	return null


func _grid_distance_score(a: Vector2i, b: Vector2i) -> float:
	return absf(float(a.x - b.x)) + absf(float(a.y - b.y))


func _record_terrain_move_debug(cmd: Dictionary, unit, current_position: Vector2, target_position: Vector2, terrain_registry, path_world_points: Array) -> void:
	var unit_id: String = _extract_unit_id_for_path_recompute(unit)
	if unit_id.is_empty() or terrain_registry == null:
		return
	var target_resolution: Dictionary = _resolve_walkable_move_target(target_position, terrain_registry)
	var replacement_position: Vector2 = Vector2(target_resolution.get("replacement_position", target_position))
	var final_position: Vector2 = _coerce_vector2(path_world_points[-1], replacement_position) if not path_world_points.is_empty() else current_position
	var original_grid: Vector2i = Vector2i(target_resolution.get("original_grid", terrain_registry.call("world_to_grid", target_position)))
	var replacement_grid: Variant = target_resolution.get("replacement_grid", null)
	var final_grid: Vector2i = terrain_registry.call("world_to_grid", final_position) if terrain_registry.has_method("world_to_grid") else Vector2i.ZERO
	var path_blocked: bool = not bool(target_resolution.get("target_walkable", true)) or (typeof(replacement_grid) == TYPE_VECTOR2I and final_grid != Vector2i(replacement_grid))
	var reason: String = String(target_resolution.get("blocker_reason", ""))
	if reason.is_empty() and path_blocked:
		reason = "no_reachable_path"
	_last_terrain_move_debug_by_unit_id[unit_id] = {
		"unit_id": unit_id,
		"command_type": String(cmd.get("command_type", "")),
		"original_target_position": target_position,
		"original_target_grid": original_grid,
		"target_walkable": bool(target_resolution.get("target_walkable", true)),
		"blocked_target_grid": target_resolution.get("blocked_grid", null),
		"blocked_target_position": target_resolution.get("blocked_position", null),
		"replacement_target_grid": replacement_grid,
		"replacement_target_position": replacement_position,
		"final_waypoint_position": final_position,
		"final_waypoint_grid": final_grid,
		"blocker_reason": reason,
		"path_waypoint_count": path_world_points.size(),
	}


func _apply_damage_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", ""))
	if unit_id.is_empty():
		push_warning("SimulationRoot damage effect expects a non-empty unit_id.")
		return

	var unit = _resolve_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a damage effect.")
		return

	if not unit.has_method("apply_damage"):
		push_warning("SimulationRoot damage effect expects a unit with apply_damage().")
		return

	var attacker_team_id: String = String(effect.get("attacker_team_id", ""))
	var attacker_unit_id: String = String(effect.get("attacker_unit_id", ""))
	var target_team_id: String = ""
	if unit.has_method("get_team_id"):
		target_team_id = String(unit.call("get_team_id"))

	var is_friendly_fire: bool = not attacker_team_id.is_empty() and not target_team_id.is_empty() and attacker_team_id == target_team_id
	var allow_friendly_fire: bool = bool(effect.get("allow_friendly_fire", true))
	if is_friendly_fire and not allow_friendly_fire:
		return

	var base_damage: int = _extract_int(effect.get("damage", 0))
	if base_damage <= 0:
		push_warning("SimulationRoot damage effect expects a positive damage value.")
		return

	var attacker_unit = _resolve_attacker_unit(attacker_unit_id)
	var attacker_profile:Dictionary=_get_damage_profile_snapshot(attacker_unit)
	var target_profile:Dictionary=attacker_profile if unit==attacker_unit else _get_damage_profile_snapshot(unit)
	var attacker_hit_modifier:float=float(attacker_profile.hit_modifier) if attacker_profile.has("hit_modifier") else _extract_unit_hit_modifier(attacker_unit)
	var target_evasion_modifier:float=float(target_profile.evasion_modifier) if target_profile.has("evasion_modifier") else _extract_unit_evasion_modifier(unit)
	var height_modifier:float=_extract_height_accuracy_modifier(attacker_unit,unit)
	var range_band_modifier:float=_extract_range_band_hit_modifier(effect,attacker_unit,unit)
	var attacker_ground:Dictionary=get_hex_unit_state(attacker_unit_id)
	var attacker_moving:bool=not attacker_ground.is_empty() and bool(attacker_ground.movement_state.moving)
	var moving_shot_factor:float=_get_moving_shot_accuracy_multiplier(attacker_unit,attacker_profile) if attacker_moving else 1.0
	var shot_state:Dictionary={"attacker_moving":attacker_moving,"moving_shot_accuracy_multiplier":moving_shot_factor}
	var target_cover_score: float = _extract_effective_cover_score(unit)
	if effect.has("target_cover_override"):
		target_cover_score = clampf(_extract_float(effect.get("target_cover_override", target_cover_score), target_cover_score), 0.0, 80.0)
	var attacker_attack_bonus: float = _extract_unit_attack_bonus(attacker_unit)
	var attacker_cover_score: float = _extract_unit_cover_score(attacker_unit)
	var target_cover_ratio: float = _normalize_cover_score_for_combat(target_cover_score)
	var attacker_cover_ratio: float = _normalize_cover_score_for_combat(attacker_cover_score)
	var hit_chance: float = _extract_float(effect.get("hit_chance", 1.0), 1.0)
	hit_chance *= maxf(float(attacker_profile.hit_chance_multiplier),0.0) if attacker_profile.has("hit_chance_multiplier") else _extract_unit_accuracy_multiplier(attacker_unit)
	hit_chance = clampf(
		hit_chance
		+ attacker_attack_bonus
		+ attacker_hit_modifier
		+ height_modifier
		+ range_band_modifier
		+ (attacker_cover_ratio * ATTACKER_COVER_HIT_BONUS_FACTOR)
		- target_evasion_modifier
		- (target_cover_ratio * TARGET_COVER_HIT_PENALTY_FACTOR),
		HIT_CHANCE_MIN,
		HIT_CHANCE_MAX
	)
	hit_chance=clampf(hit_chance*moving_shot_factor,HIT_CHANCE_MIN,HIT_CHANCE_MAX)
	var roll: float = _extract_damage_roll(effect)
	var damage_multiplier: float = _extract_float(effect.get("damage_multiplier", 1.0), 1.0)
	damage_multiplier = maxf(damage_multiplier + attacker_attack_bonus - (target_cover_ratio * TARGET_COVER_DAMAGE_PENALTY_FACTOR), DAMAGE_MULTIPLIER_MIN)
	damage_multiplier *= maxf(float(target_profile.damage_taken_multiplier),0.0) if target_profile.has("damage_taken_multiplier") else _extract_unit_damage_taken_multiplier(unit)
	var damage_model = DAMAGE_MODEL_SCRIPT.new()
	if not bool(damage_model.call("resolve_hit", hit_chance, roll)):
		_emit_damage_effect_resolution(_build_damage_effect_resolution(
			effect,
			unit,
			attacker_unit,
			false,
			hit_chance,
			roll,
			base_damage,
			0,
			damage_multiplier,
			attacker_attack_bonus,
			attacker_cover_score,
			attacker_cover_ratio,
			target_cover_score,
			target_cover_ratio,
			is_friendly_fire,
			shot_state
		))
		return

	var resolved_damage: int = int(damage_model.call("resolve_damage", base_damage, damage_multiplier))
	if resolved_damage <= 0:
		_emit_damage_effect_resolution(_build_damage_effect_resolution(
			effect,
			unit,
			attacker_unit,
			true,
			hit_chance,
			roll,
			base_damage,
			resolved_damage,
			damage_multiplier,
			attacker_attack_bonus,
			attacker_cover_score,
			attacker_cover_ratio,
			target_cover_score,
			target_cover_ratio,
			is_friendly_fire,
			shot_state
		))
		return

	var hit_context: Dictionary = {
		"effect_type": "damage",
		"unit_id": unit_id,
		"attacker_unit_id": attacker_unit_id,
		"attacker_team_id": attacker_team_id,
		"attacker_attack_bonus": attacker_attack_bonus,
		"attacker_profile_hit_modifier": attacker_hit_modifier,
		"target_profile_evasion_modifier": target_evasion_modifier,
		"height_accuracy_modifier": height_modifier,
		"attacker_moving":attacker_moving,
		"moving_shot_accuracy_multiplier":moving_shot_factor,
		"target_cover_score": target_cover_score,
		"target_cover_ratio": target_cover_ratio,
		"attacker_cover_score": attacker_cover_score,
		"attacker_cover_ratio": attacker_cover_ratio,
		"resolved_hit_chance": hit_chance,
		"roll": roll,
		"damage_multiplier": damage_multiplier,
		"friendly_fire": is_friendly_fire,
		"weapon_id": String(effect.get("weapon_id", "")),
		"fire_event_id": String(effect.get("fire_event_id", "")),
	}
	if bool(effect.get("is_flank", false)):
		hit_context["is_flank"] = true
		hit_context["flank_fireteam_id"] = String(effect.get("flank_fireteam_id", ""))
		hit_context["flank_source_angle"] = _extract_float(effect.get("flank_source_angle", 0.0), 0.0)
		hit_context["flank_direction_label"] = String(effect.get("flank_direction_label", "")).strip_edges().to_lower()
		hit_context["flank_morale_state"] = String(effect.get("flank_morale_state", "")).strip_edges().to_lower()
	unit.call("apply_damage", resolved_damage, hit_context)
	if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
		# Effects follow commands: cancel this tick's continuation before a heal/respawn can restore fitness.
		_discard_pending_move_commands_for_unit(unit_id)
	_emit_damage_effect_resolution(_build_damage_effect_resolution(
		effect,
		unit,
		attacker_unit,
		true,
		hit_chance,
		roll,
		base_damage,
		resolved_damage,
		damage_multiplier,
		attacker_attack_bonus,
		attacker_cover_score,
		attacker_cover_ratio,
		target_cover_score,
		target_cover_ratio,
		is_friendly_fire,
		shot_state
	))


func _build_damage_effect_resolution(
	effect: Dictionary,
	unit,
	attacker_unit,
	did_hit: bool,
	hit_chance: float,
	roll: float,
	base_damage: int,
	resolved_damage: int,
	damage_multiplier: float,
	attacker_attack_bonus: float,
	attacker_cover_score: float,
	attacker_cover_ratio: float,
	target_cover_score: float,
	target_cover_ratio: float,
	is_friendly_fire: bool,
	shot_state:Dictionary={}
) -> Dictionary:
	var target_health_points: int = -1
	var target_vital_state: String = ""
	if unit != null:
		if unit.has_method("get_health_points"):
			target_health_points = int(unit.call("get_health_points"))
		elif unit.has_method("get_health"):
			target_health_points = int(unit.call("get_health"))
		if unit.has_method("get_vital_state"):
			target_vital_state = String(unit.call("get_vital_state"))
	return {
		"effect_type": "damage",
		"unit_id": String(effect.get("unit_id", "")),
		"target_unit_id": String(effect.get("unit_id", "")),
		"attacker_unit_id": String(effect.get("attacker_unit_id", "")),
		"attacker_team_id": String(effect.get("attacker_team_id", "")),
		"weapon_id": String(effect.get("weapon_id", "")),
		"fire_event_id": String(effect.get("fire_event_id", "")),
		"hit": did_hit,
		"outcome": "hit" if did_hit else "miss",
		"hit_chance_resolved": hit_chance,
		"attacker_moving":bool(shot_state.get("attacker_moving",false)),
		"moving_shot_accuracy_multiplier":float(shot_state.get("moving_shot_accuracy_multiplier",1.0)),
		"roll": roll,
		"base_damage": base_damage,
		"damage_resolved": resolved_damage,
		"damage_multiplier_resolved": damage_multiplier,
		"attacker_attack_bonus": attacker_attack_bonus,
		"attacker_cover_score": attacker_cover_score,
		"attacker_cover_ratio": attacker_cover_ratio,
		"target_cover_score": target_cover_score,
		"target_cover_ratio": target_cover_ratio,
		"target_health_points": target_health_points,
		"target_vital_state": target_vital_state,
		"target_position": _get_unit_world_position_for_damage_resolution(unit),
		"attacker_position": _get_unit_world_position_for_damage_resolution(attacker_unit),
		"friendly_fire": is_friendly_fire,
	}


func _emit_damage_effect_resolution(result: Dictionary) -> void:
	var snapshot: Dictionary = result.duplicate(true)
	snapshot["read_only"] = true
	_last_damage_effect_resolution = snapshot
	damage_effect_resolved.emit(snapshot.duplicate(true))


func _extract_damage_roll(effect: Dictionary) -> float:
	if effect.has("roll_override"):
		return _extract_float(effect.get("roll_override", -1.0), -1.0)
	return get_next_combat_roll()


func _apply_heal_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", ""))
	if unit_id.is_empty():
		push_warning("SimulationRoot heal effect expects a non-empty unit_id.")
		return

	var unit = _resolve_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a heal effect.")
		return

	if not unit.has_method("apply_heal"):
		push_warning("SimulationRoot heal effect expects a unit with apply_heal().")
		return

	var heal_amount: int = _extract_int(effect.get("amount", 0))
	if heal_amount <= 0:
		push_warning("SimulationRoot heal effect expects a positive amount value.")
		return

	var healer_team_id: String = String(effect.get("healer_team_id", ""))
	if not healer_team_id.is_empty() and unit.has_method("get_team_id"):
		if healer_team_id != String(unit.call("get_team_id")):
			return

	var heal_context: Dictionary = {
		"effect_type": "heal",
		"unit_id": unit_id,
		"healer_unit_id": String(effect.get("healer_unit_id", "")),
		"healer_team_id": healer_team_id,
	}
	unit.call("apply_heal", heal_amount, heal_context)


func _apply_bleedout_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", ""))
	if unit_id.is_empty():
		push_warning("SimulationRoot bleedout effect expects a non-empty unit_id.")
		return

	var unit = _resolve_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a bleedout effect.")
		return

	if not unit.has_method("advance_bleedout"):
		push_warning("SimulationRoot bleedout effect expects a unit with advance_bleedout().")
		return

	unit.call("advance_bleedout")


func get_unit_registry():
	return _get_unit_registry()


func _get_unit_registry():
	if unit_registry_path.is_empty():
		return null

	return get_node_or_null(unit_registry_path)


func _get_terrain_registry():
	if terrain_registry_path.is_empty():
		return null

	return get_node_or_null(terrain_registry_path)


func _resolve_unit(unit_id: String):
	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_unit"):
		push_warning("SimulationRoot requires a direct UnitRegistry reference for unit lookups.")
		return null

	return unit_registry.call("get_unit", unit_id)


func _resolve_attacker_unit(attacker_unit_id: String):
	if attacker_unit_id.is_empty():
		return null

	return _resolve_known_unit(attacker_unit_id)


func _extract_unit_cover_score(unit) -> float:
	if unit == null or not unit.has_method("get_cover_score"):
		return 0.0

	return float(unit.call("get_cover_score"))


func _normalize_cover_score_for_combat(cover_score: float) -> float:
	return clampf(cover_score / 100.0, 0.0, 1.0)


func _extract_effective_cover_score(unit) -> float:
	var command_cover_score: float = _extract_unit_cover_score(unit)
	var terrain_cover_score: float = _extract_terrain_cover_score(unit)
	return clampf(command_cover_score + terrain_cover_score, 0.0, 80.0)


func _extract_terrain_cover_score(unit) -> float:
	if is_hex_ground_runtime_active():
		var state := _hex_ground_state_for_unit(unit)
		return float(_hex_ground_registry.call("get_cover_at",state.grid)) if not state.is_empty() else 0.0
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or unit == null or not (unit is Node2D) or not terrain_registry.has_method("get_cover_at_world"):
		return 0.0

	return float(terrain_registry.call("get_cover_at_world", (unit as Node2D).global_position))


func _get_unit_world_position_for_damage_resolution(unit) -> Vector2:
	if is_hex_ground_runtime_active():
		var state := _hex_ground_state_for_unit(unit)
		return Vector2(_hex_ground_registry.call("grid_to_world",state.grid)) if not state.is_empty() else Vector2.ZERO
	if unit is Node2D:
		return (unit as Node2D).global_position
	return Vector2.ZERO


func _hex_ground_state_for_unit(unit) -> Dictionary:
	if not is_instance_valid(unit) or not unit.has_method("get_unit_id"):
		return {}
	return get_hex_unit_state(String(unit.call("get_unit_id")))


func _extract_unit_attack_bonus(unit) -> float:
	if unit == null or not unit.has_method("get_attack_bonus"):
		return 0.0

	return float(unit.call("get_attack_bonus"))


## Distance zone modifier of the hit chance (WeaponData.RANGE_BAND_*). The distance is measured like the range check:
## Hex ground runtime = hex steps between the two grids, otherwise world distance / world units per tile.
## Weapon: the one named in the effect, else the attacker's active weapon; no weapon or no distance = 0.
func _extract_range_band_hit_modifier(effect: Dictionary, attacker_unit, target_unit) -> float:
	if attacker_unit == null or target_unit == null:
		return 0.0
	var weapon_id: String = String(effect.get("weapon_id", "")).strip_edges()
	if weapon_id.is_empty() and attacker_unit.has_method("get_active_weapon_id"):
		weapon_id = String(attacker_unit.call("get_active_weapon_id")).strip_edges()
	if weapon_id.is_empty():
		return 0.0
	var distance_tiles: float = -1.0
	if is_hex_ground_runtime_active():
		var source := _hex_ground_state_for_unit(attacker_unit)
		var destination := _hex_ground_state_for_unit(target_unit)
		if not source.is_empty() and not destination.is_empty():
			distance_tiles = float(HEX_GRID_SCRIPT.distance(source.grid, destination.grid))
	elif attacker_unit is Node2D and target_unit is Node2D:
		var units_per_tile: float = WEAPON_DATA_SCRIPT.get_world_units_per_tile(_get_terrain_registry())
		distance_tiles = (attacker_unit as Node2D).global_position.distance_to((target_unit as Node2D).global_position) / units_per_tile
	if distance_tiles < 0.0:
		return 0.0
	return WEAPON_DATA_SCRIPT.get_range_band_hit_modifier(weapon_id, distance_tiles)


func _extract_height_accuracy_modifier(attacker_unit, target_unit) -> float:
	if is_hex_ground_runtime_active():
		var source := _hex_ground_state_for_unit(attacker_unit)
		var destination := _hex_ground_state_for_unit(target_unit)
		if source.is_empty() or destination.is_empty():
			return 0.0
		var difference := clampf(float(int(source.stand_height_steps2)-int(destination.stand_height_steps2))*0.5,-2.0,2.0)
		return HEIGHT_ADVANTAGE_ACCURACY_BONUS*difference if difference>=0.0 else HEIGHT_DISADVANTAGE_ACCURACY_PENALTY*difference
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or attacker_unit == null or target_unit == null:
		return 0.0

	if not (attacker_unit is Node2D) or not (target_unit is Node2D):
		return 0.0

	var attacker_height: int = int(terrain_registry.call("get_height_at_world", (attacker_unit as Node2D).global_position))
	var target_height: int = int(terrain_registry.call("get_height_at_world", (target_unit as Node2D).global_position))
	# Additional terrain elevations extend geometry, not the existing accuracy budget.
	var height_difference: int = clampi(attacker_height - target_height, -2, 2)
	if height_difference > 0:
		return HEIGHT_ADVANTAGE_ACCURACY_BONUS * float(height_difference)

	if height_difference < 0:
		return -HEIGHT_DISADVANTAGE_ACCURACY_PENALTY * float(abs(height_difference))

	return 0.0


func _extract_surface_speed_factor(unit) -> float:
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or unit == null or not (unit is Node2D):
		return 1.0

	return float(terrain_registry.call("get_surface_speed_factor_at_world", (unit as Node2D).global_position))


func _extract_move_speed_factor(cmd: Dictionary, unit) -> float:
	var move_speed_factor: float = 1.0
	var raw_factor: Variant = cmd.get("move_speed_factor", null)
	if typeof(raw_factor) == TYPE_INT or typeof(raw_factor) == TYPE_FLOAT:
		move_speed_factor = maxf(float(raw_factor), 0.0)
	elif unit != null and unit.has_method("get_move_speed_factor"):
		move_speed_factor = maxf(float(unit.call("get_move_speed_factor")), 0.0)

	return move_speed_factor * _extract_unit_speed_multiplier(unit)


func _update_objective_capture() -> void:
	if not _is_valid_objective_status(_objective_status):
		return

	var capturing_team_ids: PackedStringArray = _get_objective_team_ids_in_radius(_objective_status)
	_objective_status.call("set_contested", capturing_team_ids.size() > 1)
	if capturing_team_ids.size() != 1:
		return

	var capturing_team_id: String = String(capturing_team_ids[0])
	if capturing_team_id.is_empty():
		return

	if String(_objective_status.owning_team_id) == capturing_team_id:
		_objective_status.capture_progress = 1.0
		_objective_status.capturing_team_id = capturing_team_id
		return

	if String(_objective_status.capturing_team_id) != capturing_team_id:
		_objective_status.capturing_team_id = capturing_team_id
		_objective_status.capture_progress = 0.0

	_objective_status.capture_progress = minf(float(_objective_status.capture_progress) + CAPTURE_PROGRESS_PER_TICK, 1.0)
	if float(_objective_status.capture_progress) < 1.0:
		return

	_objective_status.capture_progress = 1.0
	_objective_status.owning_team_id = capturing_team_id


func _get_objective_team_ids_in_radius(objective_status) -> PackedStringArray:
	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_all_units"):
		return []

	var team_ids: PackedStringArray = []
	var objective_position: Vector2 = objective_status.position
	var capture_radius: float = maxf(float(objective_status.capture_radius), 0.0)
	var hex_mode:bool=is_hex_ground_runtime_active()
	var objective_grid:Vector2i=_hex_ground_registry.call("world_to_grid",objective_position) if hex_mode else Vector2i.ZERO
	var hex_spacing:float=float(_hex_ground_registry.call("get_movement_distance",_hex_ground_registry.call("grid_to_world",Vector2i.ZERO),_hex_ground_registry.call("grid_to_world",Vector2i.RIGHT))) if hex_mode else 1.0
	for unit in unit_registry.call("get_all_units"):
		if unit == null or not (unit is Node2D):
			continue

		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
			continue

		if not unit.has_method("get_team_id"):
			continue

		var team_id: String = String(unit.call("get_team_id"))
		if team_id.is_empty() or team_ids.has(team_id):
			continue

		var distance:float=0.0
		if hex_mode:
			if not unit.has_method("get_unit_id"):continue
			var grid:Variant=_hex_ground_runtime.get_unit_grid(String(unit.call("get_unit_id")))
			if not grid is Vector2i:continue
			distance=float(HEX_GRID_SCRIPT.distance(grid,objective_grid))*hex_spacing
		else:distance=(unit as Node2D).global_position.distance_to(objective_position)
		if distance <= capture_radius:
			team_ids.append(team_id)

	return team_ids


func _is_valid_objective_status(objective_status) -> bool:
	return objective_status != null and objective_status is OBJECTIVE_STATUS_SCRIPT


func _extract_int(value: Variant) -> int:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return int(value)

	return 0


func _extract_float(value: Variant, fallback: float) -> float:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return float(value)

	return fallback


func _get_damage_profile_snapshot(unit) -> Dictionary:
	# Per-effect only: a later effect must see new skill/loadout/leadership values.
	# Explicit opt-in preserves existing individual-getter precedence elsewhere.
	if is_instance_valid(unit) and unit.has_method("get_damage_profile_snapshot"):
		var raw:Variant=unit.call("get_damage_profile_snapshot")
		if typeof(raw)==TYPE_DICTIONARY:return Dictionary(raw).duplicate(false)
	return {}


func _get_moving_shot_accuracy_multiplier(unit,profile:Dictionary) -> float:
	if profile.has("moving_shot_accuracy_multiplier"):
		return clampf(float(profile.moving_shot_accuracy_multiplier),0.0,1.0)
	var accuracy:=0.5
	var core:Dictionary={}
	if is_instance_valid(unit) and unit.has_method("get_character_profile_bundle"):
		core=Dictionary(Dictionary(unit.call("get_character_profile_bundle")).get("core_values",{}))
	if core.has("accuracy"):accuracy=float(core.accuracy)
	elif is_instance_valid(unit) and unit.has_method("get_accuracy_skill"):accuracy=float(unit.call("get_accuracy_skill"))
	return UNIT_PROFILE_MATH_SCRIPT.accuracy_to_moving_shot_multiplier(accuracy)


func _extract_unit_hit_modifier(unit) -> float:
	if unit == null:
		return 0.0
	if unit.has_method("get_combat_hit_modifier"):
		return float(unit.call("get_combat_hit_modifier"))

	var modifier: float = 0.0
	if unit.has_method("get_order_fidelity_hit_modifier"):
		modifier += float(unit.call("get_order_fidelity_hit_modifier"))
	if unit.has_method("get_autonomy_hit_modifier"):
		modifier += float(unit.call("get_autonomy_hit_modifier"))
	if unit.has_method("get_leadership_hit_modifier"):
		modifier += float(unit.call("get_leadership_hit_modifier"))
	return modifier


func _extract_unit_evasion_modifier(unit) -> float:
	if unit == null:
		return 0.0
	if unit.has_method("get_combat_evasion_modifier"):
		return float(unit.call("get_combat_evasion_modifier"))
	if not unit.has_method("get_signature_control_evasion_modifier"):
		return 0.0

	return float(unit.call("get_signature_control_evasion_modifier"))


func _extract_unit_accuracy_multiplier(unit) -> float:
	if unit == null:
		return 1.0
	if unit.has_method("get_combat_hit_chance_multiplier"):
		return maxf(float(unit.call("get_combat_hit_chance_multiplier")), 0.0)
	if not unit.has_method("get_accuracy_skill"):
		return 1.0

	return 0.5 + clampf(float(unit.call("get_accuracy_skill")), 0.0, 1.0)


func _extract_unit_speed_multiplier(unit) -> float:
	if unit == null:
		return 1.0
	if unit.has_method("get_combat_speed_multiplier"):
		return maxf(float(unit.call("get_combat_speed_multiplier")), 0.0)
	if not unit.has_method("get_speed_skill"):
		return 1.0

	var base_multiplier: float = 0.5 + clampf(float(unit.call("get_speed_skill")), 0.0, 1.0)
	if unit.has_method("get_initiative_speed_multiplier"):
		base_multiplier *= float(unit.call("get_initiative_speed_multiplier"))
	return base_multiplier


func _extract_unit_damage_taken_multiplier(unit) -> float:
	if unit == null:
		return 1.0
	if unit.has_method("get_combat_damage_taken_multiplier"):
		return maxf(float(unit.call("get_combat_damage_taken_multiplier")), 0.0)
	if not unit.has_method("get_toughness_skill"):
		return 1.0

	var toughness: float = clampf(float(unit.call("get_toughness_skill")), 0.0, 1.0)
	var damage_taken_multiplier: float = 1.0 - (toughness * 0.4)
	if unit.has_method("get_contact_stability_damage_taken_multiplier"):
		damage_taken_multiplier *= float(unit.call("get_contact_stability_damage_taken_multiplier"))
	return damage_taken_multiplier


func _apply_respawn_effect(effect: Dictionary) -> void:
	if is_hex_ground_runtime_required() or effect.has("_hex_respawn_ticket"):
		_apply_hex_respawn_effect(effect)
		return
	var unit_id: String = String(effect.get("unit_id", ""))
	if unit_id.is_empty():
		push_warning("SimulationRoot respawn effect expects a non-empty unit_id.")
		return

	var unit = _resolve_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a respawn effect.")
		return

	if not unit.has_method("respawn"):
		push_warning("SimulationRoot respawn effect expects a unit with respawn().")
		return

	var spawn_position: Variant = effect.get("spawn_position", null)
	if typeof(spawn_position) != TYPE_VECTOR2:
		push_warning("SimulationRoot respawn effect expects a Vector2 spawn_position.")
		return

	unit.call("respawn", spawn_position)


func _apply_dropship_embark_unit_effect(effect: Dictionary) -> void:
	if _hex_ground_enabled:
		if not is_hex_ground_runtime_active():
			_last_hex_lifecycle_resolution={"ok":false,"reason":"hex_ground_inactive"}
			return
		_last_hex_lifecycle_resolution=embark_hex_ground_actor_group(PackedStringArray([String(effect.get("unit_id",""))]))
		return
	var unit_id: String = String(effect.get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		push_warning("SimulationRoot dropship embark effect expects a non-empty unit_id.")
		return
	var unit = _resolve_known_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a dropship embark effect.")
		return
	unit.set_meta("dropship_embarked", true)
	_apply_dropship_position_and_visibility(unit, effect, false)


func _apply_dropship_deploy_unit_effect(effect: Dictionary) -> void:
	if _hex_ground_enabled:
		if not is_hex_ground_runtime_active():
			_last_hex_lifecycle_resolution={"ok":false,"reason":"hex_ground_inactive"}
			return
		_last_hex_lifecycle_resolution=_apply_hex_dropship_deploy_effect(effect)
		return
	var unit_id: String = String(effect.get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		push_warning("SimulationRoot dropship deploy effect expects a non-empty unit_id.")
		return
	var unit = _resolve_known_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a dropship deploy effect.")
		return
	unit.set_meta("dropship_embarked", false)
	_apply_dropship_runtime_activation(unit_id, unit, effect)
	_apply_dropship_position_and_visibility(unit, effect, true)
	var runtime_status: String = String(effect.get("runtime_status", "")).strip_edges()
	if not runtime_status.is_empty() and unit.has_method("set_runtime_status"):
		unit.call("set_runtime_status", runtime_status)
	if unit.has_method("refresh_terrain_readability"):
		unit.call("refresh_terrain_readability")


func _apply_air_asset_status_update_effect(effect: Dictionary) -> void:
	var status_snapshot: Dictionary = Dictionary(effect.get("status_snapshot", effect.get("air_asset_status", {}))).duplicate(true)
	if status_snapshot.is_empty():
		status_snapshot = {
			"asset_id": String(effect.get("asset_id", "")).strip_edges(),
			"asset_type": String(effect.get("asset_type", "")).strip_edges(),
			"state": String(effect.get("state", "")).strip_edges(),
		}
	var asset_id: String = String(status_snapshot.get("asset_id", effect.get("asset_id", ""))).strip_edges()
	if asset_id.is_empty():
		push_warning("SimulationRoot air asset status effect expects a non-empty asset_id.")
		return
	status_snapshot["asset_id"] = asset_id
	status_snapshot["asset_type"] = String(status_snapshot.get("asset_type", effect.get("asset_type", "dropship"))).strip_edges()
	status_snapshot["state"] = String(status_snapshot.get("state", effect.get("state", "intact"))).strip_edges()
	status_snapshot["last_event_id"] = String(status_snapshot.get("last_event_id", effect.get("event_id", ""))).strip_edges()
	status_snapshot["vfx_events"] = Array(effect.get("vfx_events", status_snapshot.get("vfx_events", []))).duplicate(true)
	status_snapshot["sfx_events"] = Array(effect.get("sfx_events", status_snapshot.get("sfx_events", []))).duplicate(true)
	status_snapshot["runtime_authority"] = "SimulationRoot"
	status_snapshot["applied_by"] = "SimulationRoot"
	status_snapshot["applied_tick"] = tick_counter
	status_snapshot["ui_sets_gameplay_truth"] = false
	_air_asset_status_by_id[asset_id] = status_snapshot


func _apply_dropship_position_and_visibility(unit, effect: Dictionary, default_visible: bool) -> void:
	if unit == null:
		return
	if effect.has("position") and unit is Node2D:
		var unit_node := unit as Node2D
		unit_node.global_position = _coerce_vector2(effect.get("position", unit_node.global_position), unit_node.global_position)
	if unit is CanvasItem:
		(unit as CanvasItem).visible = bool(effect.get("visible", default_visible))


func _apply_dropship_runtime_activation(unit_id: String, unit: Node, effect: Dictionary) -> void:
	if not bool(effect.get("runtime_active", false)):
		return
	var unit_registry = _get_unit_registry()
	if unit_registry != null and unit_registry.has_method("register_unit"):
		if not unit_registry.has_method("has_unit") or not bool(unit_registry.call("has_unit", unit_id)):
			unit_registry.call("register_unit", unit_id, unit)
	var runtime_leader = _resolve_optional_node_path(effect.get("runtime_leader_path", NodePath("")))
	if runtime_leader != null and runtime_leader.has_method("add_unit_member"):
		runtime_leader.call("add_unit_member", unit)
	var ftl_registry = _resolve_optional_node_path(effect.get("ftl_registry_path", NodePath("")))
	if ftl_registry == null or not ftl_registry.has_method("register_ftl"):
		return
	var team_id: String = String(effect.get("team_id", "")).strip_edges()
	if team_id.is_empty() and unit.has_method("get_team_id"):
		team_id = String(unit.call("get_team_id")).strip_edges()
	if not team_id.is_empty() and (not ftl_registry.has_method("has_ftl") or not bool(ftl_registry.call("has_ftl", team_id))):
		ftl_registry.call("register_ftl", team_id, runtime_leader)


func _resolve_optional_node_path(raw_path: Variant) -> Node:
	var node_path: NodePath = raw_path if raw_path is NodePath else NodePath(String(raw_path))
	if node_path.is_empty():
		return null
	return get_node_or_null(node_path)


func _apply_loadout_modifiers_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		push_warning("SimulationRoot loadout modifier effect expects a non-empty unit_id.")
		return
	var unit = _resolve_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a loadout modifier effect.")
		return
	if not unit.has_method("apply_loadout_modifiers"):
		push_warning("SimulationRoot loadout modifier effect expects a unit with apply_loadout_modifiers().")
		return
	var modifiers_dict: Dictionary = Dictionary(effect.get("modifiers", {})).duplicate(true)
	if modifiers_dict.is_empty():
		modifiers_dict = {
			"unit_id": unit_id,
			"armor_id": String(effect.get("armor_id", "medium")),
			"weapon_1_id": String(effect.get("weapon_1_id", "rifle")),
			"weapon_2_id": String(effect.get("weapon_2_id", "rifle")),
			"accuracy_mod": float(effect.get("accuracy_mod", 0.0)),
			"speed_mod": float(effect.get("speed_mod", 0.0)),
			"toughness_mod": float(effect.get("toughness_mod", 0.0)),
			"cover_mod": float(effect.get("cover_mod", 0.0)),
			"range_class": String(effect.get("range_class", "medium")),
		}
	unit.call("apply_loadout_modifiers", modifiers_dict)


func _apply_unit_combat_posture_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		push_warning("SimulationRoot combat posture effect expects a non-empty unit_id.")
		return
	var unit = _resolve_known_unit(unit_id)
	if unit == null or not (unit is Node):
		push_warning("SimulationRoot could not resolve the target unit for a combat posture effect.")
		return
	var unit_node: Node = unit as Node
	var facing_value: Variant = effect.get("facing_angle", null)
	if typeof(facing_value) == TYPE_FLOAT or typeof(facing_value) == TYPE_INT:
		var facing_angle: float = float(facing_value)
		unit_node.set_meta("facing_angle", facing_angle)
		unit_node.set_meta("map_facing_angle", facing_angle)
		if bool(effect.get("enemy_facing", false)):
			unit_node.set_meta("enemy_facing_angle", facing_angle)

	if not bool(effect.get("apply_posture", false)):
		return
	if not unit.has_method("get_runtime_status") or not unit.has_method("set_runtime_status"):
		push_warning("SimulationRoot combat posture effect expects a unit runtime status interface.")
		return
	var runtime_status = unit.call("get_runtime_status")
	if runtime_status == null or not runtime_status.has_method("get"):
		push_warning("SimulationRoot combat posture effect requires a readable runtime status.")
		return
	var movement_posture: String = String(effect.get("movement_posture", runtime_status.get("movement_posture"))).strip_edges().to_lower()
	var weapon_posture: String = String(effect.get("weapon_posture", runtime_status.get("weapon_posture"))).strip_edges().to_lower()
	var posture_policy_id: String = String(effect.get("posture_policy_id", runtime_status.get("posture_policy_id"))).strip_edges().to_lower()
	var move_speed_factor: float = float(effect.get("move_speed_factor", runtime_status.get("move_speed_factor")))
	unit.call(
		"set_runtime_status",
		String(runtime_status.get("status")),
		String(runtime_status.get("active_command_type")),
		int(runtime_status.get("priority")),
		String(runtime_status.get("fire_status")),
		String(runtime_status.get("source_command_type")),
		move_speed_factor,
		float(runtime_status.get("cover_score")),
		float(runtime_status.get("attack_bonus")),
		int(runtime_status.get("phase")),
		runtime_status.get("target_position"),
		movement_posture,
		weapon_posture,
		posture_policy_id,
		float(runtime_status.get("sight_range_factor")),
		float(runtime_status.get("aim_readiness_percent"))
	)
	if bool(effect.get("enemy_facing", false)):
		unit_node.set_meta("enemy_movement_posture", movement_posture)
		unit_node.set_meta("enemy_weapon_posture", weapon_posture)
		unit_node.set_meta("enemy_posture_policy_id", posture_policy_id)


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value

	if value is Vector2i:
		return Vector2(value.x, value.y)

	return fallback


var _location_resource_owner: Node
func configure_location_resources(owner: Node) -> void:
	_location_resource_owner=owner
func request_location_resource_command(operation: String, payload: Dictionary) -> Dictionary:
	if not is_instance_valid(_location_resource_owner): return {"ok":false,"reason":"resource_owner_missing"}
	return _location_resource_owner.call("apply_operation",operation,payload)

var _air_support_source: WeakRef
var _air_support_adapter: WeakRef
var _air_support_location_id := ""
var _air_support_sorties: Dictionary = {}
var _air_support_move_receipts: Dictionary = {}
var _air_support_fire_poll := 0.0
const AIR_GROUND_DISPERSION = preload("res://scripts/mission/air_support_dispersion.gd")
const AIR_GROUND_ADAPTER = preload("res://scripts/mission/air_support_ground_adapter.gd")
const SPACE_COMPONENTS = preload("res://scripts/mission/space_component_catalog.gd")

func _air_ground_registry() -> Node:
	return AIR_GROUND_ADAPTER.registry(is_hex_ground_runtime_active(), _hex_ground_registry, _get_terrain_registry())

func _air_ground_unit_grid(unit_id: String) -> Variant:
	if is_hex_ground_runtime_active(): return _hex_ground_runtime.get_unit_grid(unit_id)
	return AIR_GROUND_ADAPTER.unit_grid(_resolve_unit(unit_id), _air_ground_registry())

func _air_ground_occupant(grid: Vector2i) -> Dictionary:
	if is_hex_ground_runtime_active(): return {"ok":true, "unit_id":_hex_ground_runtime.get_occupant_at(grid)}
	return AIR_GROUND_ADAPTER.occupant(grid, _air_ground_registry(), _get_unit_registry())
const SPACE_COMPONENT_SYSTEMS = preload("res://scripts/tactical/space_component_systems.gd")
var _campaign_space_return_receipts: Dictionary = {}
var _campaign_space_entry_searches: Dictionary = {}
var _campaign_space_entry_origins: Dictionary = {}
var _piloted_air_ground_receipts: Dictionary = {}
var _air_ground_fire_receipts: Dictionary = {}
var _air_ground_order_receipts: Dictionary = {}
var _air_ground_rng_state := 1

func bind_air_support_source(source: Node, adapter: Node, location_id: String) -> Dictionary:
	# Internal read-through capability. The fleet/wing/equipment owners stay on
	# the campaign Root; the mission Root never creates another ship state.
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if not is_instance_valid(source) or source == self or not is_instance_valid(adapter) or location_id.strip_edges().is_empty(): return {"ok":false, "reason":"invalid_air_source"}
	if source.get("_departure_adapter") == null or source.get("_departure_adapter").get_ref() != adapter or adapter.get("_simulation") != source: return {"ok":false, "reason":"adapter_required"}
	var flow: Node = adapter.get("_flow")
	var mission := get_parent()
	if not is_instance_valid(flow) or not is_instance_valid(mission) or not flow.has_method("get_active_mission") or flow.call("get_active_mission") != mission or not flow.is_ancestor_of(mission) or String(mission.get_meta("location_id", "")) != location_id: return {"ok":false, "reason":"mission_context_changed"}
	if _air_support_source != null and (_air_support_source.get_ref() != source or _air_support_adapter == null or _air_support_adapter.get_ref() != adapter or _air_support_location_id != location_id): return {"ok":false, "reason":"air_source_already_bound"}
	_air_support_source = weakref(source)
	_air_support_adapter = weakref(adapter)
	_air_support_location_id = location_id
	return {"ok":true}

func _resolve_air_support_craft(craft_id: String) -> Dictionary:
	# References are for Root-internal use only; callers revalidate presence on
	# every operation and must not use this as proof of airborne status.
	if craft_id.strip_edges().is_empty() or _air_support_source == null or _air_support_adapter == null: return {"ok":false, "reason":"air_source_unavailable"}
	var source: Node = _air_support_source.get_ref()
	var adapter: Node = _air_support_adapter.get_ref()
	if not is_instance_valid(source) or not is_instance_valid(adapter) or source.get("_departure_adapter") == null or source.get("_departure_adapter").get_ref() != adapter or adapter.get("_simulation") != source: return {"ok":false, "reason":"air_source_changed"}
	var flow: Node = adapter.get("_flow")
	var mission := get_parent()
	if not is_instance_valid(flow) or not is_instance_valid(mission) or String(mission.get_meta("location_id", "")) != _air_support_location_id or not flow.is_ancestor_of(mission): return {"ok":false, "reason":"mission_context_changed"}
	var locations: Variant = flow.get("_craft_location_runtime")
	if typeof(locations) != TYPE_DICTIONARY or String(locations.get(craft_id, "")) != _air_support_location_id: return {"ok":false, "reason":"craft_not_at_location"}
	var fleet: RefCounted = source.get("_singleplayer_space_travel_owner")
	var equipment: RefCounted = source.get("_ship_equipment_owner")
	var wings: RefCounted = source.get("_space_wing_state")
	var combat: RefCounted = source.get("_space_combat_state")
	if fleet == null or equipment == null or wings == null or combat == null: return {"ok":false, "reason":"air_owner_unavailable"}
	var flight: RefCounted = fleet.get_flight_state(craft_id)
	var wing_id: String = wings.get_craft_wing(craft_id, "singleplayer")
	if flight == null or wing_id.is_empty() or equipment.get_snapshot(craft_id).is_empty(): return {"ok":false, "reason":"craft_not_ready"}
	return {"ok":true, "flight":flight, "fleet":fleet, "wings":wings, "combat":combat, "equipment":equipment, "wing_id":wing_id}

func is_air_support_craft_airborne(craft_id: String) -> bool:
	# Read the shared Flight; even a stale combat index must not make an
	# atmospheric aircraft available for boarding on the ground.
	var source: Node = _air_support_source.get_ref() if _air_support_source != null else null
	var fleet: RefCounted = source.get("_singleplayer_space_travel_owner") if is_instance_valid(source) else null
	var flight: RefCounted = fleet.get_flight_state(craft_id) if fleet != null else null
	if flight == null: return false
	var pose: Dictionary = flight.get_snapshot()
	return pose.get("coordinate_frame") == "local" and pose.get("motion_mode") == "tactical" and pose.get("space_area_id") == "atmosphere:" + _air_support_location_id

func get_air_support_world_pose(craft_id: String) -> Dictionary:
	var terrain: Node = _air_ground_registry()
	if not is_air_support_craft_airborne(craft_id) or terrain == null: return {}
	var source: Node = _air_support_source.get_ref()
	var flight: RefCounted = source.get("_singleplayer_space_travel_owner").get_flight_state(craft_id)
	var pose: Dictionary = flight.get_snapshot()
	var axial: Vector2 = SPACE_GRID.HEX.plane_to_axial(pose.position_plane)
	var origin: Vector2 = terrain.call("grid_to_world", Vector2i.ZERO)
	var q: Vector2 = Vector2(terrain.call("grid_to_world", Vector2i(1, 0))) - origin
	var r: Vector2 = Vector2(terrain.call("grid_to_world", Vector2i(0, 1))) - origin
	return {"position":origin + q * axial.x + r * axial.y, "heading_rad":pose.heading_rad}

func get_air_support_ground_target(grid: Vector2i) -> String:
	return String(_air_ground_occupant(grid).get("unit_id", ""))

func get_air_support_radar_contacts(craft_id: String) -> Dictionary:
	var binding: Dictionary = _resolve_air_support_craft(craft_id)
	if not binding.get("ok", false) or not is_air_support_craft_airborne(craft_id): return {"ok":false, "reason":"aircraft_not_flying"}
	var source: Node = _air_support_source.get_ref()
	if not is_instance_valid(source): return {"ok":false, "reason":"air_source_unavailable"}
	var result: Dictionary = source.get_space_radar_contacts(craft_id)
	if not result.get("ok", false): return result
	var terrain: Node = _air_ground_registry()
	if terrain == null: return {"ok":false, "reason":"ground_unavailable"}
	var origin: Vector2 = terrain.call("grid_to_world", Vector2i.ZERO)
	var q: Vector2 = Vector2(terrain.call("grid_to_world", Vector2i(1, 0))) - origin
	var r: Vector2 = Vector2(terrain.call("grid_to_world", Vector2i(0, 1))) - origin
	var projections: Array = []
	for contact_id: String in result.contacts:
		var target: RefCounted = binding.combat.get_actor(contact_id)
		if target == null: continue
		var pose: Dictionary = target.get_snapshot()
		if pose.get("space_area_id") != result.space_area_id: continue
		var axial: Vector2 = SPACE_GRID.HEX.plane_to_axial(pose.position_plane)
		projections.append({"craft_id":contact_id, "position":origin + q * axial.x + r * axial.y})
	result["projections"] = projections
	return result

func _resolve_air_support_pilot(craft_id: String) -> Dictionary:
	# The transport owner verifies actual boarding and pending deployment.
	var controller: Node = get_parent().get_node_or_null("TacticalController") if get_parent() != null else null
	if controller == null or not controller.has_method("get_campaign_air_support_pilot_guard"): return {"ok":false, "reason":"boarding_owner_unavailable"}
	var guard: Dictionary = controller.call("get_campaign_air_support_pilot_guard", craft_id)
	if not guard.get("ok", false): return guard
	var adapter: Node = _air_support_adapter.get_ref() if _air_support_adapter != null else null
	var flow: Node = adapter.get("_flow") if is_instance_valid(adapter) else null
	var pilots: Variant = flow.get("_assigned_aircraft_pilot_by_craft") if is_instance_valid(flow) else null
	var pilot_id := String(guard.get("pilot_unit_id", ""))
	if typeof(pilots) != TYPE_DICTIONARY or pilot_id.is_empty() or String(pilots.get(craft_id, "")) != pilot_id: return {"ok":false, "reason":"pilot_assignment_changed"}
	var pilot = _resolve_unit(pilot_id)
	if not is_instance_valid(pilot) or not bool(pilot.get_meta("dropship_embarked", false)) or not pilot.has_method("get_health") or int(pilot.call("get_health")) <= 0 or not pilot.has_method("get_team_id"): return {"ok":false, "reason":"pilot_not_aboard"}
	return {"ok":true, "pilot_id":pilot_id, "pilot":pilot}

func request_air_support_takeoff(craft_id: String) -> Dictionary:
	var terrain: Node = _air_ground_registry()
	if _should_skip_local_tick_processing() or terrain == null: return {"ok":false, "reason":"ground_unavailable"}
	if _air_support_location_id == "polisa": return {"ok":false, "reason":"no_planetary_atmosphere"}
	if is_processing_tick or craft_id.strip_edges().is_empty(): return {"ok":false, "reason":"invalid_context"}
	if _air_support_sorties.has(craft_id): return {"ok":false, "reason":"already_airborne"}
	var binding: Dictionary = _resolve_air_support_craft(craft_id)
	if not binding.get("ok", false): return binding
	var pilot: Dictionary = _resolve_air_support_pilot(craft_id)
	if not pilot.get("ok", false): return pilot
	var controller: Node = get_parent().get_node_or_null("TacticalController")
	if controller == null or not controller.has_method("_is_parked_campaign_dropship") or not controller.call("_is_parked_campaign_dropship", craft_id): return {"ok":false, "reason":"craft_not_landed"}
	var position: Variant = controller.call("_campaign_landed_craft_position", craft_id)
	if typeof(position) != TYPE_VECTOR2 or not position.is_finite(): return {"ok":false, "reason":"landing_position_unavailable"}
	var grid: Vector2i = terrain.call("world_to_grid", position)
	if terrain.call("get_tile_at_grid", grid) == null: return {"ok":false, "reason":"invalid_landing_site"}
	var source: Node = _air_support_source.get_ref()
	if not is_instance_valid(source) or source.get("is_processing_tick"): return {"ok":false, "reason":"simulation_busy"}
	var flight: RefCounted = binding.flight
	var old: Dictionary = flight.get_snapshot()
	var profile: Dictionary = binding.equipment.get_space_flight_profile(craft_id)
	var stats: Dictionary = binding.equipment.get_space_combat_stats(craft_id)
	if not profile.get("ok", false) or not stats.get("ok", false): return {"ok":false, "reason":"equipment_unavailable"}
	var existing: Dictionary = binding.combat.get_ship_systems(craft_id)
	if not existing.is_empty():
		var previous: Dictionary = existing.stats.duplicate(true); var current := stats.duplicate(true)
		previous.erase("equipment_revision"); current.erase("equipment_revision")
		if previous != current or float(existing.state.hull) <= 0.0: return {"ok":false, "reason":"systems_unavailable"}
	elif not SPACE_COMPONENT_SYSTEMS.initial(stats, float(stats.get("hull_capacity", 0.0))).get("ok", false): return {"ok":false, "reason":"systems_unavailable"}
	# A UI command is published between source ticks. Do not consume the next
	# tick in advance: the next real flight step must be strictly newer.
	var tick: int = maxi(int(source.get("tick_counter")), int(old.tick) + 1)
	var proposal := {"expected_revision":old.revision, "coordinate_frame":"local", "space_area_id":"atmosphere:" + _air_support_location_id, "position_plane":SPACE_GRID.HEX.axial_to_plane(Vector2(grid)), "velocity_plane":Vector2.ZERO, "heading_rad":0.0, "angular_velocity":0.0, "assist_mode":"coupled", "motion_mode":"tactical", "mass":profile.mass}
	var movement: Dictionary = flight.validate_surface_air_transition(proposal, tick)
	if not movement.get("ok", false): return movement
	var admission: Dictionary = binding.combat.validate_surface_air_admission(craft_id, flight, movement, profile.footprint_hexes)
	if not admission.get("ok", false): return admission
	for cell in admission.cells:
		if terrain.call("get_tile_at_grid", cell) == null: return {"ok":false, "reason":"map_edge"}
	# All publication tails are synchronous; the flight remains the fleet's
	# original object, and the controller derives parked state from that object.
	flight._publish_area_transition(movement)
	binding.combat._publish_surface_air_admission(admission)
	var systems: Dictionary = source._bind_owned_space_systems(craft_id)
	assert(systems.get("ok", false))
	_air_support_sorties[craft_id] = {"flight":flight, "source":weakref(source), "previous_pose":old, "landing_position":position, "landing_grid":grid, "was_inactive":admission.was_inactive}
	return {"ok":true, "craft_id":craft_id}

func request_air_support_landing(craft_id: String) -> Dictionary:
	if _should_skip_local_tick_processing() or _air_ground_registry() == null: return {"ok":false, "reason":"ground_unavailable"}
	if is_processing_tick or not _air_support_sorties.has(craft_id): return {"ok":false, "reason":"sortie_unavailable"}
	var sortie: Dictionary = _air_support_sorties[craft_id]
	var binding: Dictionary = _resolve_air_support_craft(craft_id)
	if not binding.get("ok", false): return binding
	var source: Node = sortie.source.get_ref()
	if not is_instance_valid(source) or source != _air_support_source.get_ref() or source.get("is_processing_tick") or binding.flight != sortie.flight: return {"ok":false, "reason":"sortie_context_changed"}
	var pilot: Dictionary = _resolve_air_support_pilot(craft_id)
	if not pilot.get("ok", false): return pilot
	var pose: Dictionary = binding.flight.get_snapshot()
	if not is_air_support_craft_airborne(craft_id) or pose.position_plane.distance_to(SPACE_GRID.HEX.axial_to_plane(Vector2(sortie.landing_grid))) > 0.15 or pose.velocity_plane.length() > 0.1: return {"ok":false, "reason":"not_at_landing_site"}
	if not is_hex_ground_runtime_active():
		var occupied_cells: Array[Vector2i] = binding.combat.preview_actor_cells(craft_id, {})
		if occupied_cells.is_empty(): return {"ok":false, "reason":"stale_aircraft_index"}
		for cell in occupied_cells:
			var ground: Dictionary = _air_ground_occupant(cell)
			if not ground.get("ok", false): return ground
			if not String(ground.unit_id).is_empty(): return {"ok":false, "reason":"ground_landing_occupied"}
	var controller: Node = get_parent().get_node_or_null("TacticalController")
	if controller == null or not controller.has_method("_ground_ship_touchdown_ready") or not controller.call("_ground_ship_touchdown_ready", craft_id, sortie.landing_position, false): return {"ok":false, "reason":"ground_landing_occupied"}
	var area_revision: int = binding.combat.get_area_revision(pose.space_area_id)
	var actor: Dictionary = binding.combat.validate_deactivation(craft_id, pose.revision, area_revision)
	if not actor.get("ok", false): return actor
	var old: Dictionary = sortie.previous_pose
	var proposal := {"expected_revision":pose.revision}
	for key in ["position_plane", "velocity_plane", "heading_rad", "angular_velocity", "assist_mode", "motion_mode", "mass", "space_area_id", "coordinate_frame"]: proposal[key] = old[key]
	var tick: int = maxi(int(source.get("tick_counter")) + 1, int(pose.tick) + 1)
	var movement: Dictionary = binding.flight.validate_surface_air_transition(proposal, tick)
	if not movement.get("ok", false): return movement
	binding.flight._publish_area_transition(movement)
	if sortie.was_inactive: binding.combat._publish_deactivation(actor)
	else: binding.combat._publish_local_departure(actor)
	_air_support_sorties.erase(craft_id)
	return {"ok":true, "craft_id":craft_id}

func request_air_support_move(command: Dictionary) -> Dictionary:
	if _should_skip_local_tick_processing() or _air_ground_registry() == null: return {"ok":false, "reason":"ground_unavailable"}
	if is_processing_tick or command.size() != 3 or typeof(command.get("craft_id")) != TYPE_STRING or typeof(command.get("target_hex")) != TYPE_VECTOR2I or typeof(command.get("request_id")) != TYPE_STRING or String(command.request_id).strip_edges().is_empty(): return {"ok":false, "reason":"invalid_command"}
	var id: String = command.craft_id
	var signature := SPACE_COMMAND_CONTRACT.request_signature(command)
	if _air_support_move_receipts.has(command.request_id):
		if _air_support_move_receipts[command.request_id] != signature: return {"ok":false, "reason":"request_id_conflict"}
		return {"ok":true, "replayed":true}
	if _air_support_move_receipts.size() >= 4096: return {"ok":false, "reason":"receipt_capacity"}
	if not _air_support_sorties.has(id): return {"ok":false, "reason":"sortie_unavailable"}
	var binding: Dictionary = _resolve_air_support_craft(id)
	if not binding.get("ok", false): return binding
	var pilot: Dictionary = _resolve_air_support_pilot(id)
	if not pilot.get("ok", false): return pilot
	var source: Node = _air_support_source.get_ref()
	if not is_instance_valid(source) or source.get("is_processing_tick") or _air_support_sorties[id].source.get_ref() != source or binding.flight != _air_support_sorties[id].flight or not is_air_support_craft_airborne(id): return {"ok":false, "reason":"sortie_context_changed"}
	var pose: Dictionary = binding.flight.get_snapshot()
	var target_plane: Vector2 = SPACE_GRID.HEX.axial_to_plane(Vector2(command.target_hex))
	var cells: Array[Vector2i] = binding.combat.preview_actor_cells(id, {"position_plane":target_plane})
	if cells.is_empty() or not _air_support_cells_on_map(cells): return {"ok":false, "reason":"invalid_target"}
	for occupant in binding.combat.query_cells(cells, pose.space_area_id):
		if occupant != id: return {"ok":false, "reason":"occupied"}
	for claimant in binding.combat.query_navigation_claims(cells, pose.space_area_id):
		if claimant != id: return {"ok":false, "reason":"navigation_claimed"}
	var profile: Dictionary = binding.equipment.get_space_flight_profile(id)
	if not profile.get("ok", false) or not is_equal_approx(float(profile.mass), float(pose.mass)): return {"ok":false, "reason":"flight_profile_changed"}
	var goal := {"target_plane":target_plane}
	var guidance: Dictionary = SPACE_GUIDANCE_RESOLVER.resolve(pose, goal, profile.hull, profile.power)
	if not guidance.get("ok", false): return guidance
	var claim: Dictionary = binding.combat.record_navigation_claim(id, pose.space_area_id, cells)
	if not claim.get("ok", false): return claim
	binding.combat.set_flight_control(id, {"goal":goal, "hull":profile.hull, "power":profile.power, "air_support_move":true, "mission_root":weakref(self), "equipment_snapshot":binding.equipment.get_snapshot(id), "area_id":pose.space_area_id})
	_air_support_move_receipts[command.request_id] = signature
	return {"ok":true, "replayed":false}

func _air_support_cells_on_map(cells: Array) -> bool:
	var terrain: Node = _air_ground_registry()
	if terrain == null: return false
	for cell in cells:
		if typeof(cell) != TYPE_VECTOR2I or terrain.call("get_tile_at_grid", cell) == null: return false
	return not cells.is_empty()

func _air_support_motion_context_valid(craft_id: String, source: Node, equipment_snapshot: Dictionary) -> bool:
	if _air_support_source == null or _air_support_source.get_ref() != source or not _air_support_sorties.has(craft_id) or not is_air_support_craft_airborne(craft_id): return false
	var binding: Dictionary = _resolve_air_support_craft(craft_id)
	return binding.get("ok", false) and binding.flight == _air_support_sorties[craft_id].flight and binding.equipment.get_snapshot(craft_id) == equipment_snapshot and _resolve_air_support_pilot(craft_id).get("ok", false)

func _advance_air_support_orders(delta: float) -> void:
	if _air_support_sorties.is_empty(): return
	_air_support_fire_poll -= maxf(delta, 0.0)
	if _air_support_fire_poll > 0.0: return
	_air_support_fire_poll = 0.2
	for craft_id in _air_support_sorties.keys():
		var binding: Dictionary = _resolve_air_support_craft(craft_id)
		if not binding.get("ok", false) or not is_air_support_craft_airborne(craft_id): continue
		var wing: Dictionary = binding.wings.get_snapshot().wings.get(binding.wing_id, {})
		var order: Dictionary = wing.get("order", {})
		if order.get("verb") != "attack_target" or order.get("fire_rule") != "free": continue
		var systems: Dictionary = binding.combat.get_ship_systems(craft_id)
		for weapon: Dictionary in systems.get("stats", {}).get("weapons", []):
			var slot := String(weapon.get("slot_id", ""))
			if slot.is_empty(): continue
			request_air_support_ground_fire({"craft_id":craft_id, "target_unit_id":String(order.get("target_id", "")), "weapon_slot":slot, "request_id":"auto-air:%s:%d:%s" % [craft_id, tick_counter, slot]})

func request_air_support_attack_order(command: Dictionary) -> Dictionary:
	# The target and wing are resolved from live mission owners, not the UI.
	if _should_skip_local_tick_processing() or _air_ground_registry() == null: return {"ok":false, "reason":"ground_unavailable"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if command.size() != 3: return {"ok":false, "reason":"invalid_command"}
	for key in ["craft_id", "target_unit_id", "request_id"]:
		if typeof(command.get(key)) != TYPE_STRING or String(command[key]).strip_edges().is_empty() or String(command[key]).length() > 128: return {"ok":false, "reason":"invalid_command"}
	var id: String = command.request_id
	if _air_ground_order_receipts.has(id):
		var prior: Dictionary = _air_ground_order_receipts[id]
		if prior.craft_id != command.craft_id or prior.target_unit_id != command.target_unit_id: return {"ok":false, "reason":"request_id_conflict"}
		var replay: Dictionary = prior.result.duplicate(true); replay["replayed"] = true; return replay
	if _air_ground_order_receipts.size() >= 4096: return {"ok":false, "reason":"receipt_capacity"}
	var binding: Dictionary = _resolve_air_support_craft(command.craft_id)
	if not binding.get("ok", false): return binding
	var pose: Dictionary = binding.flight.get_snapshot()
	if binding.combat.get_actor(command.craft_id) != binding.flight or pose.get("coordinate_frame") != "local" or pose.get("motion_mode") != "tactical" or pose.get("assist_mode") != "coupled" or pose.get("space_area_id") != "atmosphere:" + _air_support_location_id: return {"ok":false, "reason":"aircraft_not_flying"}
	var cells: Array[Vector2i] = binding.combat.preview_actor_cells(command.craft_id, {})
	if cells.is_empty() or not binding.combat.actor_cells_match(command.craft_id, pose.space_area_id, cells): return {"ok":false, "reason":"stale_aircraft_index"}
	var pilot_check: Dictionary = _resolve_air_support_pilot(command.craft_id)
	if not pilot_check.get("ok", false): return pilot_check
	var pilot = pilot_check.pilot
	var target = _resolve_unit(command.target_unit_id)
	if not is_instance_valid(target) or typeof(_air_ground_unit_grid(command.target_unit_id)) != TYPE_VECTOR2I or not target.has_method("get_health") or int(target.call("get_health")) <= 0 or not target.has_method("get_team_id"): return {"ok":false, "reason":"target_unavailable"}
	var team := String(pilot.call("get_team_id"))
	if team.is_empty() or String(target.call("get_team_id")) == team: return {"ok":false, "reason":"not_hostile"}
	var driver: Node = get_parent().get_node_or_null("CombatLoopDriver") if get_parent() != null else null
	if driver == null or not driver.has_method("get_multiplayer_visible_unit_ids") or not driver.call("get_multiplayer_visible_unit_ids", team).has(command.target_unit_id): return {"ok":false, "reason":"target_not_visible"}
	var revision: int = binding.wings.get_snapshot().revision
	var order := {"contract_category":"space_combat", "operation":"order_issue", "request_id":"air-ground-order:" + id, "expected_revision":revision, "payload":{"wing_ids":[binding.wing_id], "verb":"attack_target", "target_id":command.target_unit_id, "fire_rule":"free"}}
	var result: Dictionary = binding.wings.apply_command(order, {"authorized":true, "actor_id":"singleplayer", "phase":"tactical", "known_targets":[command.target_unit_id], "coordinate_frame":"local", "space_area_id":pose.space_area_id})
	if result.get("ok", false): _air_ground_order_receipts[id] = {"craft_id":command.craft_id, "target_unit_id":command.target_unit_id, "result":result.duplicate(true)}
	return result

func request_air_support_cease_fire(craft_id: String, request_id: String) -> Dictionary:
	if _should_skip_local_tick_processing() or is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	var binding: Dictionary = _resolve_air_support_craft(craft_id)
	if not binding.get("ok", false): return binding
	var snapshot: Dictionary = binding.wings.get_snapshot()
	var order: Dictionary = Dictionary(snapshot.wings.get(binding.wing_id, {})).get("order", {})
	if order.is_empty(): return {"ok":true, "already_stopped":true}
	if order.get("verb") != "attack_target": return {"ok":false, "reason":"no_attack_order"}
	var command := {"contract_category":"space_combat", "operation":"order_cancel", "request_id":request_id, "expected_revision":snapshot.revision, "payload":{"wing_id":binding.wing_id, "order_id":String(order.get("order_id", ""))}}
	return binding.wings.apply_command(command, {"authorized":true, "actor_id":"singleplayer", "phase":"tactical"})

func preview_air_support_ground_fire(command: Dictionary) -> Dictionary:
	# Read-only. Visibility and installed equipment come from live owners; the
	# UI supplies only identities, never pilot skill, position, or damage.
	if _should_skip_local_tick_processing() or _air_ground_registry() == null: return {"ok":false, "reason":"ground_unavailable"}
	if command.size() != 3: return {"ok":false, "reason":"invalid_command"}
	for key in ["craft_id", "target_unit_id", "weapon_slot"]:
		if typeof(command.get(key)) != TYPE_STRING or String(command[key]).strip_edges().is_empty(): return {"ok":false, "reason":"invalid_command"}
	var binding: Dictionary = _resolve_air_support_craft(command.craft_id)
	if not binding.get("ok", false): return binding
	var flight: RefCounted = binding.flight
	var pose: Dictionary = flight.get_snapshot()
	if binding.combat.get_actor(command.craft_id) != flight or pose.get("coordinate_frame") != "local" or pose.get("motion_mode") != "tactical" or pose.get("assist_mode") != "coupled" or pose.get("space_area_id") != "atmosphere:" + _air_support_location_id: return {"ok":false, "reason":"aircraft_not_flying"}
	var indexed_cells: Array[Vector2i] = binding.combat.preview_actor_cells(command.craft_id, {})
	if indexed_cells.is_empty() or not binding.combat.actor_cells_match(command.craft_id, pose.space_area_id, indexed_cells): return {"ok":false, "reason":"stale_aircraft_index"}
	var wing: Dictionary = binding.wings.get_snapshot().wings.get(binding.wing_id, {})
	var order: Dictionary = wing.get("order", {})
	if order.get("verb") != "attack_target" or order.get("target_id") != command.target_unit_id or order.get("fire_rule") != "free": return {"ok":false, "reason":"attack_order_required"}
	var pilot_check: Dictionary = _resolve_air_support_pilot(command.craft_id)
	if not pilot_check.get("ok", false): return pilot_check
	var pilot_id: String = pilot_check.pilot_id
	var pilot = pilot_check.pilot
	if not pilot.has_method("get_character_profile_bundle"): return {"ok":false, "reason":"pilot_skill_unavailable"}
	var target = _resolve_unit(command.target_unit_id)
	var target_grid: Variant = _air_ground_unit_grid(command.target_unit_id)
	if not is_instance_valid(target) or typeof(target_grid) != TYPE_VECTOR2I or not target.has_method("get_team_id") or not target.has_method("get_health") or int(target.call("get_health")) <= 0: return {"ok":false, "reason":"target_unavailable"}
	var team := String(pilot.call("get_team_id"))
	if team.is_empty() or String(target.call("get_team_id")) == team: return {"ok":false, "reason":"not_hostile"}
	var driver: Node = get_parent().get_node_or_null("CombatLoopDriver") if get_parent() != null else null
	if driver == null or not driver.has_method("get_multiplayer_visible_unit_ids") or not driver.call("get_multiplayer_visible_unit_ids", team).has(command.target_unit_id): return {"ok":false, "reason":"target_not_visible"}
	var systems: Dictionary = binding.combat.get_ship_systems(command.craft_id)
	var installed: Dictionary = binding.equipment.get_space_combat_stats(command.craft_id)
	if systems.is_empty() or not installed.get("ok", false) or float(systems.state.hull) <= 0.0: return {"ok":false, "reason":"systems_unavailable"}
	var previous: Dictionary = systems.stats.duplicate(true); var current := installed.duplicate(true)
	previous.erase("equipment_revision"); current.erase("equipment_revision")
	if previous != current: return {"ok":false, "reason":"systems_refit_required"}
	var weapon := {}
	for entry: Dictionary in systems.stats.weapons:
		if entry.get("slot_id") == command.weapon_slot: weapon = entry; break
	if weapon.is_empty() or float(systems.cooldowns.get(command.weapon_slot, 0.0)) > 0.0 or not SPACE_COMPONENT_SYSTEMS.consume_weapon(systems.stats, systems.state, 1.0).get("ok", false): return {"ok":false, "reason":"weapon_unavailable"}
	var delta: Vector2 = SPACE_GRID.HEX.axial_to_plane(Vector2(target_grid)) - pose.position_plane
	if delta.length_squared() <= 0.000001 or delta.length() > float(weapon.range): return {"ok":false, "reason":"out_of_range"}
	if absf(wrapf(delta.angle() - float(pose.heading_rad), -PI, PI)) > deg_to_rad(float(weapon.arc_degrees) * 0.5): return {"ok":false, "reason":"outside_fire_arc"}
	var skill_key := "dropship_piloting" if installed.get("model_id") == "cutlass" else ("fighter_piloting" if installed.get("model_id") == "buccaneer" else "")
	var profile: Variant = pilot.call("get_character_profile_bundle")
	if skill_key.is_empty() or typeof(profile) != TYPE_DICTIONARY or typeof(profile.get("platform_values")) != TYPE_DICTIONARY: return {"ok":false, "reason":"pilot_skill_unavailable"}
	var skill: Variant = profile.platform_values.get(skill_key)
	if typeof(skill) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(skill)) or float(skill) < 0.0 or float(skill) > 1.0: return {"ok":false, "reason":"pilot_skill_unavailable"}
	var spread: Dictionary = AIR_GROUND_DISPERSION.preview(target_grid, float(skill))
	return {"ok":true, "craft_id":command.craft_id, "target_unit_id":command.target_unit_id, "weapon_slot":command.weapon_slot, "pilot_id":pilot_id, "team_id":team, "aim_hex":target_grid, "radius":spread.radius}

func request_air_support_ground_fire(command: Dictionary) -> Dictionary:
	# A command contains identities only. All authority, visibility, weapon
	# values and seeded deviation are rebuilt from owners on the host.
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if command.size() != 4 or typeof(command.get("request_id")) != TYPE_STRING or String(command.request_id).strip_edges().is_empty() or String(command.request_id).length() > 128: return {"ok":false, "reason":"invalid_command"}
	var id: String = command.request_id
	var signature := var_to_str(command)
	if _air_ground_fire_receipts.has(id):
		var prior: Dictionary = _air_ground_fire_receipts[id]
		if prior.signature != signature: return {"ok":false, "reason":"request_id_conflict"}
		var replay: Dictionary = prior.result.duplicate(true); replay["replayed"] = true; return replay
	if _air_ground_fire_receipts.size() >= 4096: return {"ok":false, "reason":"receipt_capacity"}
	var request := command.duplicate(true); request.erase("request_id")
	var checked: Dictionary = preview_air_support_ground_fire(request)
	if not checked.get("ok", false): return checked
	var binding: Dictionary = _resolve_air_support_craft(checked.craft_id)
	if not binding.get("ok", false): return binding
	var systems: Dictionary = binding.combat.get_ship_systems(checked.craft_id)
	var weapon := {}
	for entry: Dictionary in systems.stats.weapons:
		if entry.slot_id == checked.weapon_slot: weapon = entry; break
	if weapon.is_empty() or typeof(weapon.get("damage")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(weapon.damage)) or float(weapon.damage) <= 0.0 or float(weapon.damage) != floorf(float(weapon.damage)): return {"ok":false, "reason":"weapon_unavailable"}
	var pilot = _resolve_unit(checked.pilot_id)
	var equipment: Dictionary = binding.equipment.get_snapshot(checked.craft_id)
	var key := "dropship_piloting" if equipment.get("model_id") == "cutlass" else "fighter_piloting"
	var skill: float = float(Dictionary(pilot.call("get_character_profile_bundle")).platform_values[key])
	var next_seed := (_air_ground_rng_state * 1103515245 + 12345) & 0x7fffffff
	var scatter: Dictionary = AIR_GROUND_DISPERSION.resolve(checked.aim_hex, skill, next_seed)
	if not scatter.get("ok", false): return scatter
	var impact_id := "air-fire-impact:" + id
	var weapon_id := "air-fire-weapon:" + id
	var ship_receipts: Dictionary = binding.combat.get("_ship_impact_receipts")
	if _air_ground_impact_receipts.has(impact_id) or ship_receipts.has(weapon_id): return {"ok":false, "reason":"event_id_conflict"}
	if _air_ground_impact_receipts.size() >= 4096 or ship_receipts.size() >= 4096: return {"ok":false, "reason":"receipt_capacity"}
	var lookup: Dictionary = _air_ground_occupant(scatter.impact_hex)
	if not lookup.get("ok", false): return lookup
	var occupant: String = lookup.unit_id
	if not occupant.is_empty():
		var target = _resolve_unit(occupant)
		if not is_instance_valid(target) or not target.has_method("apply_damage") or _air_ground_unit_grid(occupant) != scatter.impact_hex: return {"ok":false, "reason":"ground_actor_unavailable"}
	var ship_event := {"id":weapon_id, "shooter_id":checked.craft_id, "weapon_slot":checked.weapon_slot, "hit_craft_id":"", "damage":0.0}
	var spent: Dictionary = binding.combat._commit_ship_impact(ship_event)
	if not spent.get("ok", false): return spent
	var plane: Vector2 = binding.flight.get_snapshot().position_plane
	var axial: Vector2 = SPACE_GRID.HEX.plane_to_axial(plane)
	var terrain: Node = _air_ground_registry()
	var ground_origin: Vector2 = terrain.call("grid_to_world", Vector2i.ZERO)
	var q_axis: Vector2 = Vector2(terrain.call("grid_to_world", Vector2i(1, 0))) - ground_origin
	var r_axis: Vector2 = Vector2(terrain.call("grid_to_world", Vector2i(0, 1))) - ground_origin
	var visual := {"event_id":id, "craft_id":checked.craft_id, "weapon_slot":checked.weapon_slot, "origin_plane":plane, "impact_hex":scatter.impact_hex, "attacker_position":ground_origin + q_axis * axial.x + r_axis * axial.y, "target_position":terrain.call("grid_to_world", scatter.impact_hex), "aim_position":terrain.call("grid_to_world", checked.aim_hex), "tick":tick_counter}
	var result := {"ok":true, "replayed":false, "event":visual.duplicate(true)}
	# Store before ground damage emits signals so re-entry cannot shoot twice.
	_air_ground_fire_receipts[id] = {"signature":signature, "result":result.duplicate(true)}
	_air_ground_rng_state = next_seed
	var applied: Dictionary = _commit_air_ground_impact({"event_id":impact_id, "impact_hex":scatter.impact_hex, "pilot_id":checked.pilot_id, "team_id":checked.team_id, "damage":int(weapon.damage)})
	assert(applied.get("ok", false))
	air_support_ground_fired.emit(visual.duplicate(true))
	return result

func bind_campaign_space_combat(ids: Dictionary, authority_context: Dictionary) -> Dictionary:
	# Admission is a separate transaction; bind only existing authoritative
	# actors and the exact fleet flight, never client-provided health data.
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if authority_context.get("runtime_authorized") != true: return {"ok":false, "reason":"runtime_authority_required"}
	if _space_encounter_owner == null or _singleplayer_space_travel_owner == null or typeof(ids.get("player")) != TYPE_STRING: return {"ok":false, "reason":"encounter_unavailable"}
	if ids.get("hostile") != "hostile_cutlass" or ids.get("neutral") != "neutral_buccaneer": return {"ok":false, "reason":"invalid_encounter_actors"}
	if _singleplayer_space_travel_owner.get_flight_state(ids.player) != _space_combat_state.get_actor(ids.player): return {"ok":false, "reason":"not_owned"}
	return _space_encounter_owner.bind_combat_owner(_space_combat_state, ids)

func commit_campaign_space_return(adapter: Node, craft_id: String, request_id: String) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter or _singleplayer_space_travel_owner == null or _singleplayer_supply_owner == null or _space_encounter_owner == null: return {"ok":false, "reason":"adapter_required"}
	if _campaign_space_return_receipts.has(request_id):
		var receipt: Dictionary = _campaign_space_return_receipts[request_id]
		if receipt.craft_id != craft_id: return {"ok":false, "reason":"request_id_conflict"}
		if receipt.fleet != _singleplayer_space_travel_owner or receipt.supply != _singleplayer_supply_owner or receipt.supply_epoch != _singleplayer_supply_owner.get("_route_prepare_epoch") or receipt.encounter != _space_encounter_owner or receipt.flight != _singleplayer_space_travel_owner.get_flight_state(craft_id): return {"ok":false, "reason":"owner_changed"}
		var check: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(receipt.candidate, receipt.context)
		if not check.get("ok", false) or not check.get("replayed", false): return {"ok":false, "reason":"owner_changed"}
		var replay: Dictionary = receipt.result.duplicate(true); replay["replayed"] = true; return replay
	if _campaign_space_return_receipts.size() >= 1024: return {"ok":false, "reason":"receipt_capacity"}
	var encounter: Dictionary = _space_encounter_owner.get_snapshot()
	if request_id.strip_edges().is_empty() or encounter.get("craft_id") != craft_id or _space_encounter_owner.peek_completed_result().is_empty() or _space_encounter_owner.get("_combat_owner") != _space_combat_state: return {"ok":false, "reason":"encounter_not_complete"}
	if _space_encounter_owner.get("_combat_ids") != {"player":craft_id, "hostile":"hostile_cutlass", "neutral":"neutral_buccaneer"}: return {"ok":false, "reason":"encounter_actors_changed"}
	var tokens: Variant = adapter.get("_departure_token_by_craft")
	if typeof(tokens) != TYPE_DICTIONARY: return {"ok":false, "reason":"departure_unavailable"}
	var departure_id := String(tokens.get(craft_id, ""))
	var departure_receipt: Dictionary = _departure_group_receipts.get(departure_id, {})
	if departure_id.is_empty() or departure_receipt.get("craft_id") != craft_id or Dictionary(departure_receipt.get("result", {})).get("departure", {}).get("destination_location_id") != "distress_orbit": return {"ok":false, "reason":"departure_unavailable"}
	if departure_receipt.get("supply") != _singleplayer_supply_owner or departure_receipt.get("supply_epoch") != _singleplayer_supply_owner.get("_route_prepare_epoch") or departure_receipt.get("fleet") != _singleplayer_space_travel_owner or departure_receipt.get("flight") != _singleplayer_space_travel_owner.get_flight_state(craft_id): return {"ok":false, "reason":"departure_owner_changed"}
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if flight == null or _space_combat_state.get_actor(craft_id) != flight: return {"ok":false, "reason":"player_unavailable"}
	var pose: Dictionary = flight.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
	for id in ["hostile_cutlass", "neutral_buccaneer"]:
		var actor: RefCounted = _space_combat_state.get_actor(id)
		if actor == null or actor.get_snapshot().get("space_area_id") != pose.get("space_area_id"): return {"ok":false, "reason":"contact_unavailable"}
	var bound: Dictionary = _singleplayer_space_travel_owner.configure_space_area_transition_authority(self)
	if not bound.get("ok", false): return bound
	var payload := {"craft_id":craft_id, "location_id":"distress_orbit"}
	var context := {"request_id":request_id, "request_signature":JSON.stringify({"operation":"end_campaign_encounter", "payload":payload}, "", true), "operation":"end_campaign_encounter", "payload":payload, "source_area_id":String(pose.space_area_id), "target_area_id":String(pose.space_area_id), "expected_travel_revision":travel.revision, "expected_phase":"approach", "context_id":"encounter-return:" + request_id}
	bound = _singleplayer_space_travel_owner.bind_space_area_transition_context(context, self)
	if not bound.get("ok", false): return bound
	var candidate: Dictionary = _singleplayer_space_travel_owner.prepare_space_area_transition(craft_id, travel.revision, context.source_area_id, context.target_area_id, context)
	var validation: Dictionary = _singleplayer_space_travel_owner.validate_prepared_space_area_transition(candidate, context) if candidate.get("ok", false) else candidate
	if not validation.get("ok", false) or validation.get("replayed", false):
		_singleplayer_space_travel_owner.release_space_area_transition_context(context.context_id, self)
		return {"ok":false, "reason":String(validation.get("reason", "travel_validation_failed"))}
	if not _singleplayer_supply_owner.bind_route_fuel_preparation_authority(self):
		_singleplayer_space_travel_owner.release_space_area_transition_context(context.context_id, self)
		return {"ok":false, "reason":"supply_authority_unavailable"}
	var fuel_command := {"contract_category":"singleplayer_supply", "operation":"consume_route_fuel", "payload":{"craft_id":craft_id, "origin_location_id":"distress_orbit", "destination_location_id":"homebase"}, "request_id":"return:" + departure_id + ":fuel"}
	var fuel_candidate: Dictionary = _singleplayer_supply_owner.prepare_route_fuel(fuel_command, {"route_fuel_authority":self, "departure_authorized":true, "require_return_reserve":false})
	var fuel_validation: Dictionary = _singleplayer_supply_owner.validate_prepared_route_fuel(fuel_candidate, self) if fuel_candidate.get("ok", false) else fuel_candidate
	if not fuel_validation.get("ok", false) or fuel_validation.get("patch", {}).get("mode") != "apply":
		_singleplayer_space_travel_owner.release_space_area_transition_context(context.context_id, self)
		return {"ok":false, "reason":String(fuel_validation.get("reason", "fuel_validation_failed"))}
	# Validation above establishes that both contacts exist; no callbacks occur
	# before the authoritative travel state is published.
	_space_combat_state.remove_actor("hostile_cutlass")
	_space_combat_state.remove_actor("neutral_buccaneer")
	var fuel_result: Dictionary = _singleplayer_supply_owner._publish_prepared_route_fuel(fuel_candidate, fuel_validation)
	var result: Dictionary = _singleplayer_space_travel_owner._publish_prepared_space_area_transition(candidate, validation)
	var completed := {"ok":true, "replayed":false, "travel_result":result, "fuel_result":fuel_result}
	_campaign_space_return_receipts[request_id] = {"craft_id":craft_id, "fleet":_singleplayer_space_travel_owner, "supply":_singleplayer_supply_owner, "supply_epoch":_singleplayer_supply_owner.get("_route_prepare_epoch"), "encounter":_space_encounter_owner, "flight":flight, "candidate":candidate.duplicate(true), "context":context.duplicate(true), "result":completed.duplicate(true)}
	return completed

func advance_campaign_space_entry(adapter: Node, craft_id: String) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick: return {"ok":false, "reason":"simulation_busy"}
	if _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter or _space_encounter_owner == null or _singleplayer_space_travel_owner == null or _ship_equipment_owner == null: return {"ok":false, "reason":"entry_unavailable"}
	var encounter: Dictionary = _space_encounter_owner.get_snapshot()
	var travel: Dictionary = _singleplayer_space_travel_owner.get_craft_snapshot(craft_id)
	if encounter.get("phase") != "entering" or encounter.get("craft_id") != craft_id or travel.get("phase") != "approach" or travel.get("location_id") != "distress_orbit": return {"ok":false, "reason":"entry_context_changed"}
	var tokens: Variant = adapter.get("_departure_token_by_craft")
	if typeof(tokens) != TYPE_DICTIONARY: return {"ok":false, "reason":"departure_unavailable"}
	var departure: Dictionary = _departure_group_receipts.get(String(tokens.get(craft_id, "")), {})
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if flight == null or departure.get("craft_id") != craft_id or departure.get("flight") != flight or departure.get("fleet") != _singleplayer_space_travel_owner or Dictionary(departure.get("result", {})).get("departure", {}).get("destination_location_id") != "distress_orbit": return {"ok":false, "reason":"departure_unavailable"}
	var pilot: Dictionary = adapter.preview_space_warp_entry(craft_id)
	if not pilot.get("ok", false): return pilot
	if _space_combat_state.get_actor(craft_id) == flight:
		var retry: Dictionary = admit_campaign_space_contacts(craft_id, {"runtime_authorized":true})
		if retry.get("ok", false): _campaign_space_entry_origins.erase(craft_id)
		return retry
	if _space_combat_state.get_actor(craft_id) != null or _space_combat_state.get_inactive_actor(craft_id) != null: return {"ok":false, "reason":"actor_unavailable"}
	var pose: Dictionary = flight.get_snapshot()
	if pose.get("coordinate_frame") != "strategic" or not String(pose.get("space_area_id", "")).is_empty(): return {"ok":false, "reason":"strategic_flight_required"}
	var orbit: Dictionary = Dictionary(travel.get("orbits", {})).get(String(travel.get("orbit_id", "")), {})
	var body_id := String(orbit.get("body_id", ""))
	var profile: Dictionary = _ship_equipment_owner.get_space_flight_profile(craft_id)
	var stats: Dictionary = _ship_equipment_owner.get_space_combat_stats(craft_id)
	if not profile.get("ok", false) or not stats.get("ok", false) or not is_equal_approx(float(profile.mass), float(pose.mass)) or not SPACE_COMPONENT_SYSTEMS.initial(stats, float(stats.get("hull_capacity", 0.0))).get("ok", false): return {"ok":false, "reason":"equipment_unavailable"}
	var existing: Dictionary = _space_combat_state.get_ship_systems(craft_id)
	if not existing.is_empty():
		var prior: Dictionary = existing.stats.duplicate(true); var current := stats.duplicate(true)
		prior.erase("equipment_revision"); current.erase("equipment_revision")
		if prior != current: return {"ok":false, "reason":"systems_refit_required"}
	var state: Dictionary = _campaign_space_entry_searches.get(craft_id, {})
	if not state.is_empty() and (state.flight != flight or state.flight_revision != pose.revision or state.travel_revision != travel.revision or state.stats != stats or state.body_id != body_id):
		_campaign_space_entry_searches.erase(craft_id)
		return {"ok":false, "reason":"entry_context_changed"}
	if state.is_empty():
		var search = SPACE_ORBIT_ENTRY_SEARCH.new()
		var started: Dictionary = search.begin(body_id, [{"craft_id":craft_id, "flight":flight, "footprint_hexes":profile.footprint_hexes, "entry_heading":0.0}], _space_combat_state)
		if not started.get("ok", false): return started
		state = {"search":search, "flight":flight, "flight_revision":pose.revision, "travel_revision":travel.revision, "stats":stats.duplicate(true), "body_id":body_id, "footprint":profile.footprint_hexes.duplicate()}
		_campaign_space_entry_searches[craft_id] = state
	var found: Dictionary = state.search.advance(256)
	if not found.get("ok", false): _campaign_space_entry_searches.erase(craft_id); return found
	if found.status == "pending": return {"ok":true, "status":"pending"}
	var target := {"position_plane":found.allocations[craft_id].position_plane, "heading_rad":0.0, "velocity_plane":Vector2.ZERO, "angular_velocity":0.0}
	var tick := tick_counter + 1
	var geometry: Dictionary = SPACE_AREA_TRANSITION.preview(flight, pose.revision, body_id, target, state.footprint, _space_combat_state, tick)
	if not geometry.get("ok", false): _campaign_space_entry_searches.erase(craft_id); return geometry
	var wing: Dictionary = _space_wing_state.preview_flying_wings("singleplayer", [craft_id], pilot.owned_crafts, pilot.craft_pilots)
	if not wing.get("ok", false): _campaign_space_entry_searches.erase(craft_id); return wing
	var admission: Dictionary = _space_combat_state.validate_new_local_admission({"craft_id":craft_id, "faction_id":"player", "control_domain":"player", "footprint_hexes":state.footprint}, flight, geometry.proposal, tick)
	var movement: Dictionary = flight.validate_area_transition(geometry.proposal, tick)
	if not admission.get("ok", false) or not movement.get("ok", false): _campaign_space_entry_searches.erase(craft_id); return {"ok":false, "reason":"admission_invalid"}
	var committed: Dictionary = _space_wing_state.ensure_flying_wings("singleplayer", [craft_id], pilot.owned_crafts, pilot.craft_pilots, wing.expected_revision)
	if not committed.get("ok", false): _campaign_space_entry_searches.erase(craft_id); return committed
	_campaign_space_entry_origins[craft_id] = {"flight":flight, "position":pose.position_plane, "heading":pose.heading_rad}
	flight._publish_area_transition(movement)
	_space_combat_state._publish_new_local_admission(admission)
	var bound: Dictionary = _bind_owned_space_systems(craft_id)
	assert(bound.get("ok", false))
	_campaign_space_entry_searches.erase(craft_id)
	var admitted: Dictionary = admit_campaign_space_contacts(craft_id, {"runtime_authorized":true})
	if admitted.get("ok", false): _campaign_space_entry_origins.erase(craft_id)
	return admitted

func cancel_campaign_space_entry(adapter: Node, craft_id: String) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if is_processing_tick or _departure_adapter == null or not is_instance_valid(adapter) or _departure_adapter.get_ref() != adapter or _space_encounter_owner == null or _singleplayer_space_travel_owner == null: return {"ok":false, "reason":"entry_unavailable"}
	var encounter: Dictionary = _space_encounter_owner.get_snapshot()
	if encounter.get("phase") != "entering" or encounter.get("craft_id") != craft_id: return {"ok":false, "reason":"entry_context_changed"}
	var flight: RefCounted = _singleplayer_space_travel_owner.get_flight_state(craft_id)
	if flight == null: return {"ok":false, "reason":"player_unavailable"}
	var pose: Dictionary = flight.get_snapshot()
	if pose.get("coordinate_frame") == "local":
		var origin: Dictionary = _campaign_space_entry_origins.get(craft_id, {})
		if origin.get("flight") != flight or _space_combat_state.get_actor(craft_id) != flight: return {"ok":false, "reason":"entry_origin_changed"}
		var tick := tick_counter + 1
		var proposal := {"expected_revision":pose.revision, "coordinate_frame":"strategic", "space_area_id":"", "position_plane":origin.position, "heading_rad":origin.heading, "velocity_plane":Vector2.ZERO, "angular_velocity":0.0, "motion_mode":"travel"}
		var movement: Dictionary = flight.validate_area_transition(proposal, tick)
		var departure: Dictionary = _space_combat_state.validate_local_departure(craft_id, proposal, tick, _space_combat_state.get_area_revision(pose.space_area_id))
		if not movement.get("ok", false) or not departure.get("ok", false): return {"ok":false, "reason":"entry_cancel_invalid"}
		flight._publish_area_transition(movement)
		_space_combat_state._publish_local_departure(departure)
	elif pose.get("coordinate_frame") != "strategic" or _space_combat_state.get_actor(craft_id) != null: return {"ok":false, "reason":"entry_cancel_invalid"}
	_campaign_space_entry_searches.erase(craft_id)
	_campaign_space_entry_origins.erase(craft_id)
	return {"ok":true}

func admit_campaign_space_contacts(craft_id: String, authority_context: Dictionary) -> Dictionary:
	# Only a live owned player flight can anchor this encounter. The player
	# transition and the campaign start remain separate prerequisite actions.
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if authority_context.get("runtime_authorized") != true: return {"ok":false, "reason":"runtime_authority_required"}
	if _space_encounter_owner == null or _singleplayer_space_travel_owner == null: return {"ok":false, "reason":"encounter_unavailable"}
	var encounter: Dictionary = _space_encounter_owner.get_snapshot()
	if encounter.get("phase") not in ["combat", "entering"] or encounter.get("craft_id") != craft_id or _space_encounter_owner.get("_combat_owner") != null: return {"ok":false, "reason":"invalid_encounter"}
	var player: RefCounted = _space_combat_state.get_actor(craft_id)
	if player == null or _singleplayer_space_travel_owner.get_flight_state(craft_id) != player or _space_combat_state.get_ship_systems(craft_id).is_empty(): return {"ok":false, "reason":"player_unavailable"}
	var player_metadata: Dictionary = _space_combat_state.get_metadata(craft_id)
	if player_metadata.get("control_domain") != "player" or player_metadata.get("faction_id") == "hostile" or not is_instance_valid(_base_personnel_owner) or not _base_personnel_owner.is_pilot_aboard(craft_id): return {"ok":false, "reason":"player_unavailable"}
	for id in ["hostile_cutlass", "neutral_buccaneer"]:
		if _space_combat_state.get_actor(id) != null or _space_combat_state.get_inactive_actor(id) != null or not _space_combat_state.get_ship_systems(id).is_empty(): return {"ok":false, "reason":"contact_already_exists"}
	var pose: Dictionary = player.get_snapshot()
	if pose.get("coordinate_frame") != "local" or pose.get("motion_mode") != "tactical" or not String(pose.get("space_area_id", "")).begins_with("orbit_approach:"): return {"ok":false, "reason":"invalid_encounter_area"}
	var layout: Dictionary = ORBIT_LAYOUT.build(String(pose.space_area_id).trim_prefix("orbit_approach:").uri_decode())
	if not layout.get("ok", false) or layout.body_map_id != pose.space_area_id: return {"ok":false, "reason":"invalid_encounter_area"}
	var center: Vector2i = SPACE_GRID.HEX.round_axial(SPACE_GRID.HEX.plane_to_axial(pose.position_plane))
	var candidates: Array[Vector2i] = []
	for ring in range(3, 9):
		for q in range(-ring, ring + 1):
			for r in range(-ring, ring + 1):
				var cell := center + Vector2i(q, r)
				if SPACE_GRID.HEX.distance(center, cell) != ring or not SPACE_AREA_GRID.contains(cell, pose) or layout.body_cells.has(SPACE_GRID.to_offset(cell)): continue
				var query: Array[Vector2i] = [cell]
				if not _space_combat_state.query_cells(query, pose.space_area_id).is_empty() or not _space_combat_state.query_navigation_claims(query, pose.space_area_id).is_empty(): continue
				candidates.append(cell)
	if candidates.size() < 2: return {"ok":false, "reason":"no_encounter_space"}
	# Prefer a visible approach in front of the player; the repeater's real arc
	# still decides whether an individual shot can be fired.
	var forward := Vector2.from_angle(float(pose.heading_rad))
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da: Vector2 = SPACE_GRID.HEX.axial_to_plane(Vector2(a)) - pose.position_plane
		var db: Vector2 = SPACE_GRID.HEX.axial_to_plane(Vector2(b)) - pose.position_plane
		return da.normalized().dot(forward) > db.normalized().dot(forward))
	var prepared: Array[Dictionary] = []
	var specs := [{"id":"hostile_cutlass", "model":"cutlass", "domain":"enemy", "faction":"hostile"}, {"id":"neutral_buccaneer", "model":"buccaneer", "domain":"neutral", "faction":"neutral"}]
	for i in range(specs.size()):
		var spec: Dictionary = specs[i]
		var stats: Dictionary = SPACE_COMPONENTS.effective_stats(spec.model, SPACE_COMPONENTS.default_loadout(spec.model))
		if not stats.get("ok", false) or not SPACE_COMPONENT_SYSTEMS.initial(stats, float(stats.get("hull_capacity", 0.0))).get("ok", false): return {"ok":false, "reason":"invalid_ship_components"}
		var flight: RefCounted = SPACE_FLIGHT_STATE.new()
		if not flight.configure(spec.id, {"position_plane":Vector2.ZERO}).get("ok", false): return {"ok":false, "reason":"invalid_ship"}
		var target: Vector2 = SPACE_GRID.HEX.axial_to_plane(Vector2(candidates[i]))
		var proposal := {"expected_revision":0, "coordinate_frame":"local", "space_area_id":pose.space_area_id, "position_plane":target, "motion_mode":"tactical", "heading_rad":(pose.position_plane-target).angle(), "mass":stats.mass}
		var transition: Dictionary = flight.validate_area_transition(proposal, tick_counter + 1)
		var admission: Dictionary = _space_combat_state.validate_new_local_admission({"craft_id":spec.id, "faction_id":spec.faction, "control_domain":spec.domain, "footprint_hexes":[Vector2i.ZERO]}, flight, proposal, tick_counter + 1)
		if not transition.get("ok", false) or not admission.get("ok", false): return {"ok":false, "reason":"contact_admission_failed"}
		prepared.append({"flight":flight, "transition":transition, "admission":admission, "stats":stats, "id":spec.id})
	for entry: Dictionary in prepared:
		entry.flight._publish_area_transition(entry.transition)
		_space_combat_state._publish_new_local_admission(entry.admission)
		var installed: Dictionary = _space_combat_state.bind_ship_systems(entry.id, entry.stats, float(entry.stats.hull_capacity))
		assert(installed.get("ok", false))
	var binding: Dictionary = bind_campaign_space_combat({"player":craft_id, "hostile":"hostile_cutlass", "neutral":"neutral_buccaneer"}, authority_context)
	assert(binding.get("ok", false))
	return {"ok":true, "hostile":"hostile_cutlass", "neutral":"neutral_buccaneer"}

func request_campaign_space_engage(craft_id: String, authority_context: Dictionary) -> Dictionary:
	if _should_skip_local_tick_processing(): return {"ok":false, "reason":"not_authority"}
	if authority_context.get("runtime_authorized") != true: return {"ok":false, "reason":"runtime_authority_required"}
	if _space_encounter_owner == null or _space_encounter_owner.get("_combat_owner") != _space_combat_state: return {"ok":false, "reason":"encounter_not_bound"}
	var encounter: Dictionary = _space_encounter_owner.get_snapshot()
	if encounter.get("phase") != "combat" or encounter.get("craft_id") != craft_id: return {"ok":false, "reason":"invalid_encounter"}
	var player: RefCounted = _space_combat_state.get_actor(craft_id)
	var enemy: RefCounted = _space_combat_state.get_actor("hostile_cutlass")
	if player == null or enemy == null or _singleplayer_space_travel_owner == null or _singleplayer_space_travel_owner.get_flight_state(craft_id) != player or not is_instance_valid(_base_personnel_owner) or not _base_personnel_owner.is_pilot_aboard(craft_id): return {"ok":false, "reason":"player_unavailable"}
	var pose: Dictionary = player.get_snapshot(); var target: Dictionary = enemy.get_snapshot()
	if pose.space_area_id != target.space_area_id or pose.coordinate_frame != "local": return {"ok":false, "reason":"different_area"}
	var layout: Dictionary = ORBIT_LAYOUT.build(String(pose.space_area_id).trim_prefix("orbit_approach:").uri_decode())
	if not layout.get("ok", false) or layout.body_map_id != pose.space_area_id: return {"ok":false, "reason":"invalid_encounter_area"}
	var opaque: Array = []
	for cell in layout.body_cells: opaque.append(SPACE_GRID.from_offset(cell))
	var own_faction := String(_space_combat_state.get_metadata(craft_id).get("faction_id", ""))
	var enemy_faction := String(_space_combat_state.get_metadata("hostile_cutlass").get("faction_id", ""))
	var actors := {craft_id:{"id":craft_id, "position":pose.position_plane, "heading_rad":pose.heading_rad, "faction_id":own_faction, "area_id":pose.space_area_id, "sensor_range":12.0}, "hostile_cutlass":{"id":"hostile_cutlass", "position":target.position_plane, "heading_rad":target.heading_rad, "faction_id":enemy_faction, "area_id":target.space_area_id}}
	var contacts: Dictionary = SPACE_TARGETING.collect_contacts({"actors":actors, "opaque_cells":opaque}, own_faction)
	if not contacts.get("ok", false) or not contacts.contacts.has("hostile_cutlass"): return {"ok":false, "reason":"unknown_target"}
	var wing_id: String = _space_wing_state.get_craft_wing(craft_id, "singleplayer")
	if wing_id.is_empty(): return {"ok":false, "reason":"wing_required"}
	var rev: int = _space_wing_state.get_snapshot().revision
	var command := {"contract_category":"space_combat", "operation":"order_issue", "request_id":"campaign-attack:%s:%d" % [craft_id, rev], "expected_revision":rev, "payload":{"wing_ids":[wing_id], "verb":"attack_target", "target_id":"hostile_cutlass", "fire_rule":"free"}}
	return _space_wing_state.apply_command(command, {"authorized":true, "actor_id":"singleplayer", "phase":"tactical", "known_targets":contacts.contacts, "coordinate_frame":"local", "space_area_id":pose.space_area_id})

func advance_campaign_space_fire(authority_context: Dictionary) -> void:
	if _should_skip_local_tick_processing() or authority_context.get("runtime_authorized") != true or _space_encounter_owner == null or _space_encounter_owner.get("_combat_owner") != _space_combat_state: return
	var encounter: Dictionary = _space_encounter_owner.get_snapshot()
	if encounter.get("phase") != "combat" or encounter.get("engaging") != true: return
	var craft_id := String(encounter.get("craft_id", ""))
	var systems: Dictionary = _space_combat_state.get_ship_systems(craft_id)
	if systems.is_empty(): return
	for weapon: Dictionary in systems.stats.weapons:
		var slot := String(weapon.slot_id)
		if float(systems.cooldowns.get(slot, 0.0)) > 0.0: continue
		request_singleplayer_space_fire({"request_id":"campaign-shot:%s:%d:%s" % [craft_id, tick_counter, slot], "craft_id":craft_id, "target_id":"hostile_cutlass", "weapon_slot":slot}, {"runtime_authorized":true, "actor_id":"singleplayer"})
	_advance_campaign_hostile_fire(craft_id)

func _advance_campaign_hostile_fire(craft_id: String) -> void:
	# This is called only from the bound encounter tick, never from a UI payload.
	var hostile: RefCounted = _space_combat_state.get_actor("hostile_cutlass")
	var player: RefCounted = _space_combat_state.get_actor(craft_id)
	var source: Dictionary = _space_combat_state.get_ship_systems("hostile_cutlass")
	var target_systems: Dictionary = _space_combat_state.get_ship_systems(craft_id)
	if hostile == null or player == null or source.is_empty() or target_systems.is_empty() or float(source.state.hull) <= 0.0 or float(target_systems.state.hull) <= 0.0: return
	var a: Dictionary = hostile.get_snapshot(); var b: Dictionary = player.get_snapshot()
	if a.coordinate_frame != "local" or a.space_area_id != b.space_area_id: return
	var layout: Dictionary = ORBIT_LAYOUT.build(String(a.space_area_id).trim_prefix("orbit_approach:").uri_decode())
	if not layout.get("ok", false) or layout.body_map_id != a.space_area_id: return
	var opaque: Array = []
	for cell in layout.body_cells: opaque.append(SPACE_GRID.from_offset(cell))
	var hostile_faction := String(_space_combat_state.get_metadata("hostile_cutlass").get("faction_id", ""))
	var player_faction := String(_space_combat_state.get_metadata(craft_id).get("faction_id", ""))
	if hostile_faction.is_empty() or player_faction.is_empty() or hostile_faction == player_faction: return
	var shooter := {"id":"hostile_cutlass", "position":a.position_plane, "heading_rad":a.heading_rad, "faction_id":hostile_faction, "area_id":a.space_area_id, "sensor_range":12.0}
	var target := {"id":craft_id, "position":b.position_plane, "heading_rad":b.heading_rad, "faction_id":player_faction, "area_id":b.space_area_id}
	var contacts: Dictionary = SPACE_TARGETING.collect_contacts({"actors":{"hostile_cutlass":shooter, craft_id:target}, "opaque_cells":opaque}, hostile_faction)
	if not contacts.get("ok", false) or not contacts.contacts.has(craft_id): return
	var start := SPACE_GRID.HEX.round_axial(SPACE_GRID.HEX.plane_to_axial(a.position_plane))
	var end := SPACE_GRID.HEX.round_axial(SPACE_GRID.HEX.plane_to_axial(b.position_plane))
	var occupied := {}
	for cell: Vector2i in SPACE_GRID.HEX.line(start, end):
		if not SPACE_AREA_GRID.contains(cell, a): return
		var query: Array[Vector2i] = [cell]
		occupied[cell] = _space_combat_state.query_cells(query, a.space_area_id)
	var world := {"known_targets":contacts.contacts, "hostile_factions":[player_faction], "opaque_cells":opaque, "occupants_by_cell":occupied}
	for item: Dictionary in source.stats.weapons:
		if float(_space_combat_state.get_ship_systems(craft_id).state.hull) <= 0.0: break
		var slot := String(item.slot_id)
		if float(source.cooldowns.get(slot, 0.0)) > 0.0: continue
		var weapon: Dictionary = item.duplicate(true); weapon["accuracy"] = 1.0
		var event_id := "campaign-hostile:%d:%s" % [tick_counter, slot]
		var proposal: Dictionary = SPACE_WEAPON.resolve_shot(shooter, target, weapon, {"fire_rule":"free"}, world, event_id, _space_fire_rng)
		if not proposal.get("ok", false): continue
		var committed: Dictionary = _space_combat_state._commit_ship_impact(proposal.event)
		if committed.get("ok", false) and not committed.get("replayed", false): _space_fire_rng = int(proposal.rng_state)

func _commit_piloted_air_ground_impact(event: Dictionary) -> Dictionary:
	# Root-private tail. The future flight coordinator must validate that this
	# assigned pilot is aboard the aircraft and that aim/weapon/fire are legal.
	if _should_skip_local_tick_processing() or not is_hex_ground_runtime_active(): return {"ok":false, "reason":"ground_unavailable"}
	if event.size() != 7 or typeof(event.get("event_id")) != TYPE_STRING or String(event.event_id).strip_edges().is_empty() or typeof(event.get("craft_id")) != TYPE_STRING or String(event.craft_id).strip_edges().is_empty() or typeof(event.get("pilot_id")) != TYPE_STRING or String(event.pilot_id).strip_edges().is_empty() or typeof(event.get("team_id")) != TYPE_STRING or String(event.team_id).strip_edges().is_empty() or typeof(event.get("aim_hex")) != TYPE_VECTOR2I or typeof(event.get("seed")) != TYPE_INT or typeof(event.get("damage")) != TYPE_INT or int(event.damage) <= 0: return {"ok":false, "reason":"invalid_impact"}
	var id: String = event.event_id
	var signature := var_to_str(event)
	if _piloted_air_ground_receipts.has(id):
		var previous: Dictionary = _piloted_air_ground_receipts[id]
		if previous.signature != signature: return {"ok":false, "reason":"event_id_conflict"}
		var replay: Dictionary = previous.result.duplicate(true); replay["replayed"] = true; return replay
	if _piloted_air_ground_receipts.size() >= 4096: return {"ok":false, "reason":"receipt_capacity"}
	var equipment_owner: RefCounted = _ship_equipment_owner
	var shared := {}
	if _air_support_source != null:
		shared = _resolve_air_support_craft(event.craft_id)
		if not shared.get("ok", false): return shared
		equipment_owner = shared.equipment
	if equipment_owner == null: return {"ok":false, "reason":"equipment_unavailable"}
	var equipment: Dictionary = equipment_owner.get_snapshot(event.craft_id)
	var model := String(equipment.get("model_id", ""))
	var skill_key := "dropship_piloting" if model == "cutlass" else ("fighter_piloting" if model == "buccaneer" else "")
	if skill_key.is_empty(): return {"ok":false, "reason":"unsupported_aircraft"}
	var pilot = _resolve_unit(event.pilot_id)
	if not is_instance_valid(pilot) or not pilot.has_method("get_character_profile_bundle"): return {"ok":false, "reason":"pilot_profile_unavailable"}
	if not shared.is_empty():
		var adapter: Node = _air_support_adapter.get_ref()
		var flow: Node = adapter.get("_flow") if is_instance_valid(adapter) else null
		var pilots: Variant = flow.get("_assigned_aircraft_pilot_by_craft") if is_instance_valid(flow) else null
		if typeof(pilots) != TYPE_DICTIONARY or String(pilots.get(event.craft_id, "")) != event.pilot_id or not bool(pilot.get_meta("dropship_embarked", false)) or not pilot.has_method("get_health") or int(pilot.call("get_health")) <= 0: return {"ok":false, "reason":"pilot_not_aboard"}
	var profile: Variant = pilot.call("get_character_profile_bundle")
	if typeof(profile) != TYPE_DICTIONARY or typeof(profile.get("platform_values")) != TYPE_DICTIONARY: return {"ok":false, "reason":"pilot_profile_unavailable"}
	var skill: Variant = profile.platform_values.get(skill_key)
	if typeof(skill) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(skill)) or float(skill) < 0.0 or float(skill) > 1.0: return {"ok":false, "reason":"pilot_skill_unavailable"}
	var scattered: Dictionary = AIR_GROUND_DISPERSION.resolve(event.aim_hex, float(skill), event.seed)
	if not scattered.get("ok", false): return scattered
	var impact := {"event_id":"piloted:" + id, "impact_hex":scattered.impact_hex, "pilot_id":event.pilot_id, "team_id":event.team_id, "damage":event.damage}
	var result: Dictionary = _commit_air_ground_impact(impact)
	if not result.get("ok", false): return result
	result["aim_hex"] = event.aim_hex
	result["radius"] = scattered.radius
	_piloted_air_ground_receipts[id] = {"signature":signature, "result":result.duplicate(true)}
	return result

func _repair_ground_ship_at_service(craft_id:String)->Dictionary:
	if _should_skip_local_tick_processing() or _departure_adapter==null:return {"ok":false,"reason":"not_authority"}
	var adapter:Node=_departure_adapter.get_ref()
	if not is_instance_valid(adapter) or not adapter.has_method("get_ground_repair_context"):return {"ok":false,"reason":"adapter_required"}
	var service:Dictionary=adapter.call("get_ground_repair_context",craft_id)
	if service.get("ground_service_verified",false)!=true or not Array(service.get("services",[])).has("repair"):return {"ok":false,"reason":"repair_service_required"}
	var result:Dictionary
	if _space_combat_state.get_ship_systems(craft_id).is_empty():result={"ok":true,"message":"Lokaler Reparaturservice bereit; keine beschädigten Rumpfdaten","craft_id":craft_id}
	else:result=_space_combat_state.repair_ship_systems(craft_id)
	if result.get("ok",false):_repair_air_asset_status_at_service(craft_id,result)
	return result

## Same repair also restores the craft's AirAssetStatus (ground air defence damage)
## through the air_asset_status_update effect handler.
func _repair_air_asset_status_at_service(craft_id:String,result:Dictionary)->void:
	var prior:Dictionary=get_air_asset_status_snapshot(craft_id)
	if prior.is_empty() or (int(prior.get("integrity",100))>=int(prior.get("max_integrity",100)) and String(prior.get("state",""))=="intact"):return
	var repaired:Dictionary=AIR_DEFENSE_APPROACH_PLAN_SCRIPT.repaired_status_snapshot(prior,"ground_service_repair:%s:%d"%[craft_id,tick_counter])
	if repaired.is_empty():return
	_apply_air_asset_status_update_effect({"effect_type":"air_asset_status_update","status_snapshot":repaired,"event_id":String(repaired.get("last_event_id",""))})
	result["air_asset_integrity_before"]=int(prior.get("integrity",0))
	result["air_asset_integrity_after"]=int(repaired.get("integrity",100))
	if String(result.get("message","")).begins_with("Lokaler Reparaturservice bereit"):result["message"]="Rumpf am lokalen Servicepad repariert"
