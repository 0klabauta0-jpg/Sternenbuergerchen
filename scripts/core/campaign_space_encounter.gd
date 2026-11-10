extends RefCounted
## Bounded first orbital encounter, commanded only through SimulationRoot.
var _state: Dictionary = {}
func start_encounter(craft_id: String) -> Dictionary:
	if craft_id.is_empty(): return {"ok":false,"reason":"unknown_craft"}
	if not _state.is_empty() and String(_state.get("phase","")) not in ["aborted","defeat"]:
		return {"ok":false,"reason":"encounter_already_started"}
	_state={"phase":"combat","craft_id":craft_id,"player_hull":240.0,"cutlass_hull":180.0,"buccaneer_hull":150.0,"engaging":false,"seconds":0.0,"resolved":false,"revision":1,"enemy":"Cutlass","neutral":"Buccaneer"}
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
		if String(_state.phase) in ["victory","aborted"]: return {"ok":false,"reason":"encounter_closed"}
		_state.phase="aborted"
	else: return {"ok":false,"reason":"unknown_operation"}
	_state.revision+=1
	return {"ok":true,"snapshot":get_snapshot()}
func get_completed_result() -> Dictionary:
	if _state.is_empty() or bool(_state.resolved) or String(_state.phase) not in ["victory","defeat","aborted"]: return {}
	_state.resolved=true
	var victory:=String(_state.phase)=="victory"
	return {"result":String(_state.phase),"scenario_id":"buccaneer_rescue","craft_id":String(_state.craft_id),"mission_scenario_runtime_gates":{"all_gates_complete":victory,"completed_step_ids":["enemy_cutlass_destroyed","rescue_buccaneer"] if victory else []},"space_encounter":get_snapshot()}
