extends "res://scripts/tests/campaign_five_actual_sorties_verifier.gd"
## Diagnostic continuation: requires a real checkpoint from the first sortie/full verifier.
func _run() -> void:
	var existing:Dictionary=STORE.load_checkpoint()
	if not bool(existing.get("ok",false)) or int(Dictionary(existing.get("payload",{})).get("onboarding",{}).get("stage_index",0))<2:
		printerr("Run campaign_chapter_one_sortie_verifier or the full five-sortie verifier first.")
		quit(1);return
	Engine.time_scale=4.0
	START.request_start(self,"campaign","continue")
	_flow=FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen=_flow.get_node("HomebaseScreen"); _runtime=_flow.get("_singleplayer_runtime")
	var op:Dictionary=_screen.call("get_operations_snapshot")
	_craft_id=String(op.selected_craft.id); _pilot_id=String(op.selected_craft.pilot_id); _team_id="ft1"; _crew_ids=["campaign_leader"]
	await _remaining_missions()
	await _finish()
func _dump(stage:String) -> void:
	if is_instance_valid(_flow) and _flow.get("_active_mission")!=null:
		var mission:Node=_flow.get("_active_mission")
		var registry:Node=mission.get_node("UnitRegistry")
		for unit in registry.call("get_all_units"):
			if unit is Node:
				print("LIVE_UNIT ",unit.name," ",unit.global_position," vital=",unit.call("get_vital_state") if unit.has_method("get_vital_state") else "unknown"," hp=",unit.call("get_health") if unit.has_method("get_health") else -1," weapon=",unit.call("get_active_weapon_id") if unit.has_method("get_active_weapon_id") else "unknown")
		print("FIT_COUNTS ",mission.get_node("CombatLoopDriver").call("_build_enemy_group_fit_counts"))
		print("FIRE_RULES ",mission.get_node("TacticalController").call("get_fireteam_fire_rule_snapshot"))
		print("SCENARIO_GATES ",mission.get_node("CombatLoopDriver").call("get_mission_scenario_runtime_gate_snapshot"))
		print("USE_STATE ",mission.get_node("TacticalController").call("get_mission_interaction_runtime_use_state_snapshot"))
	super._dump(stage)
