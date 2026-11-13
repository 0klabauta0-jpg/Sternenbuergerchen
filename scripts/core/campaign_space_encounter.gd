extends RefCounted
## Bounded first orbital encounter, commanded only through SimulationRoot.
var _state: Dictionary = {}
var _combat_owner: RefCounted
var _combat_ids: Dictionary = {}

func bind_combat_owner(owner: RefCounted, ids: Dictionary) -> Dictionary:
	# Called by SimulationRoot after it has admitted the actual encounter ships.
	# No health or faction values are accepted from the UI.
	if _state.is_empty() or _state.phase not in ["combat", "entering"] or _combat_owner != null or owner == null or not ids.has_all(["player", "hostile", "neutral"]): return {"ok":false, "reason":"invalid_encounter"}
	if String(ids.player) != String(_state.craft_id) or ids.values().size() != 3 or ids.player == ids.hostile or ids.player == ids.neutral or ids.hostile == ids.neutral: return {"ok":false, "reason":"invalid_encounter_actors"}
	var area := ""
	for role in ["player", "hostile", "neutral"]:
		var id := String(ids[role])
		var actor: RefCounted = owner.get_actor(id)
		var metadata: Dictionary = owner.get_metadata(id)
		var systems: Dictionary = owner.get_ship_systems(id)
		if actor == null or systems.is_empty() or metadata.get("control_domain") != ("enemy" if role == "hostile" else role): return {"ok":false, "reason":"encounter_actor_unavailable"}
		var pose: Dictionary = actor.get_snapshot()
		if pose.get("coordinate_frame") != "local" or pose.get("motion_mode") != "tactical" or String(pose.get("space_area_id", "")).is_empty(): return {"ok":false, "reason":"invalid_encounter_area"}
		if area.is_empty(): area = String(pose.space_area_id)
		elif area != String(pose.space_area_id): return {"ok":false, "reason":"different_area"}
	if owner.get_metadata(String(ids.player)).get("faction_id") == owner.get_metadata(String(ids.hostile)).get("faction_id"): return {"ok":false, "reason":"invalid_factions"}
	_combat_owner = owner
	_combat_ids = ids.duplicate(true)
	_state.phase = "combat"
	return {"ok":true}
func start_encounter(craft_id: String, prepare_combat: bool = false) -> Dictionary:
	if craft_id.is_empty(): return {"ok":false,"reason":"unknown_craft"}
	if not _state.is_empty() and String(_state.get("phase","")) not in ["aborted","defeat"]:
		return {"ok":false,"reason":"encounter_already_started"}
	_combat_owner = null
	_combat_ids.clear()
	_state={"phase":"combat","craft_id":craft_id,"player_hull":240.0,"cutlass_hull":180.0,"buccaneer_hull":150.0,"engaging":false,"seconds":0.0,"resolved":false,"revision":1,"enemy":"Cutlass","neutral":"Buccaneer"}
	if prepare_combat: _state.phase = "entering"
	return {"ok":true}
func get_snapshot() -> Dictionary:
	return _state.duplicate(true)
func apply_command(command: Dictionary, context: Dictionary={}) -> Dictionary:
	if String(command.get("contract_category",""))!="campaign_space" or _state.is_empty(): return {"ok":false,"reason":"no_encounter"}
	var op:=String(command.get("operation",""))
	if op=="engage":
		if String(_state.phase)!="combat" or String(Dictionary(command.get("payload",{})).get("target_id","cutlass"))!="cutlass": return {"ok":false,"reason":"invalid_hostile_target"}
		_state.engaging=true
	elif op=="advance":
		if not bool(context.get("runtime_authorized",false)): return {"ok":false,"reason":"untrusted_tick"}
		var dt: Variant=Dictionary(command.get("payload",{})).get("delta_seconds",0)
		if typeof(dt) not in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(dt)) or float(dt)<=0 or float(dt)>1: return {"ok":false,"reason":"invalid_delta"}
		if String(_state.phase)!="combat": return {"ok":true,"changed":false}
		if _combat_owner != null:
			return _advance_bound_combat(float(dt))
		_state.seconds+=float(dt)
		# Continuous deterministic damage; the neutral is never a player target.
		_state.cutlass_hull=maxf(0,float(_state.cutlass_hull)-(26.0 if _state.engaging else 3.0)*float(dt))
		if _state.engaging: _state.player_hull=maxf(0,float(_state.player_hull)-7.0*float(dt))
		_state.buccaneer_hull=maxf(0,float(_state.buccaneer_hull)-(3.0 if _state.engaging else 9.0)*float(dt))
		if float(_state.buccaneer_hull)<=0 or float(_state.player_hull)<=0: _state.phase="defeat"
		elif float(_state.cutlass_hull)<=0: _state.phase="rescue_ready"
	elif op=="rescue":
		if String(_state.phase)!="rescue_ready": return {"ok":false,"reason":"enemy_still_active"}
		_state.phase="victory"
	elif op=="retreat":
		if String(_state.phase) in ["victory","defeat","aborted"]: return {"ok":false,"reason":"encounter_closed"}
		_state.phase="aborted"
	else: return {"ok":false,"reason":"unknown_operation"}
	_state.revision+=1
	return {"ok":true,"snapshot":get_snapshot()}

func _advance_bound_combat(delta: float) -> Dictionary:
	var values := {}
	var area := ""
	for role in ["player", "hostile", "neutral"]:
		var id := String(_combat_ids[role])
		var actor: RefCounted = _combat_owner.get_actor(id)
		var systems: Dictionary = _combat_owner.get_ship_systems(id)
		if actor == null or systems.is_empty() or not systems.get("state", {}).has("hull"): return {"ok":false, "reason":"encounter_actor_unavailable"}
		var pose: Dictionary = actor.get_snapshot()
		if pose.get("coordinate_frame") != "local" or pose.get("motion_mode") != "tactical" or String(pose.get("space_area_id", "")).is_empty(): return {"ok":false, "reason":"invalid_encounter_area"}
		if area.is_empty(): area = String(pose.space_area_id)
		elif area != String(pose.space_area_id): return {"ok":false, "reason":"different_area"}
		values[role] = float(systems.state.hull)
	_state.seconds += delta
	_state.player_hull = values.player
	_state.cutlass_hull = values.hostile
	_state.buccaneer_hull = values.neutral
	if values.player <= 0.0 or values.neutral <= 0.0: _state.phase = "defeat"
	elif values.hostile <= 0.0: _state.phase = "rescue_ready"
	_state.revision += 1
	return {"ok":true, "snapshot":get_snapshot()}
func peek_completed_result() -> Dictionary:
	if _state.is_empty() or bool(_state.resolved) or String(_state.phase) not in ["victory","defeat","aborted"]: return {}
	var victory:=String(_state.phase)=="victory"
	return {"result":String(_state.phase),"scenario_id":"buccaneer_rescue","craft_id":String(_state.craft_id),"mission_scenario_runtime_gates":{"all_gates_complete":victory,"completed_step_ids":["enemy_cutlass_destroyed","rescue_buccaneer"] if victory else []},"space_encounter":get_snapshot()}

func get_completed_result() -> Dictionary:
	var result := peek_completed_result()
	if result.is_empty(): return {}
	_state.resolved = true
	result.space_encounter = get_snapshot()
	return result
