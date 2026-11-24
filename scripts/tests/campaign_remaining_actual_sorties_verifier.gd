extends "res://scripts/tests/campaign_five_actual_sorties_verifier.gd"
## ACHTUNG - KEIN EIGENSTAENDIGER TEST: Dieses Skript setzt den Pruefpunkt (Checkpoint) fort, den campaign_five_actual_sorties_verifier
## (oder campaign_chapter_one_sortie_verifier) im SELBEN Benutzerprofil hinterlassen hat. Es ist nur sinnvoll, wenn es DIREKT NACH
## campaign_five_actual_sorties_verifier im selben Profil laeuft. Allein oder mit frischem Wegwerfprofil (z. B. ueber nachlauf.ps1) findet es
## keinen Pruefpunkt, prueft NICHTS und endet mit der Zeile "campaign_remaining_actual_sorties_verifier SKIPPED: Vorbedingung fehlt"
## (kein Fehlschlag, aber auch kein bestandener Lauf). Eine Lauf-Zusammenfassung ohne "passed=" ist hier kein Erfolg.
func _run() -> void:
	var existing:Dictionary=STORE.load_checkpoint()
	# Enge Vorbedingung: genau der Stand, den campaign_five_actual_sorties_verifier nach seinem ersten Meilenstein-Pruefpunkt (save_home_checkpoint
	# nach "upload completes first mission") hinterlaesst: satellite_recovery abgeschlossen, die drei Restauftraege vorhanden aber NICHT abgeschlossen.
	# Der Stand von campaign_dead_end_probe_verifier (outpost_recovery bereits abgeschlossen) loest den Test deshalb NICHT aus.
	var skip_reason:="no_checkpoint"
	if bool(existing.get("ok",false)):
		var jobs:Dictionary=Dictionary(Dictionary(Dictionary(existing.get("payload",{})).get("campaign",{})).get("jobs",{}))
		var open_ok:=true
		for job_id in ["outpost_recovery","benit_delivery","outpost_chip_recovery"]:
			open_ok=open_ok and jobs.has(job_id) and String(Dictionary(jobs[job_id]).get("status",""))!="completed"
		if jobs.has("satellite_recovery") and String(Dictionary(jobs["satellite_recovery"]).get("status",""))=="completed" and open_ok: skip_reason=""
		else: skip_reason="state_not_left_by_five_actual_sorties"
	if not skip_reason.is_empty():
		print("campaign_remaining_actual_sorties_verifier SKIPPED: Vorbedingung fehlt (%s) - der Pruefpunkt im Profil ist nicht der Stand nach dem ersten Meilenstein von campaign_five_actual_sorties_verifier; es wurde NICHTS geprueft. Zuerst campaign_five_actual_sorties_verifier im selben Profil laufen lassen." % skip_reason)
		print("CAMPAIGN_REMAINING_ACTUAL_SORTIES SKIPPED reason=%s" % skip_reason)
		quit(0);return
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
				print("LIVE_UNIT ",unit.call("get_unit_id") if unit.has_method("get_unit_id") else unit.name," ",unit.name," ",unit.global_position," vital=",unit.call("get_vital_state") if unit.has_method("get_vital_state") else "unknown"," hp=",unit.call("get_health") if unit.has_method("get_health") else -1," weapon=",unit.call("get_active_weapon_id") if unit.has_method("get_active_weapon_id") else "unknown")
		print("MOVE_DEBUG ",mission.get_node("SimulationRoot").get("_last_terrain_move_debug_by_unit_id"))
		print("MOVE_DISCARDED ",mission.get_node("SimulationRoot").get("_last_discarded_move_command"))
		print("FIT_COUNTS ",mission.get_node("CombatLoopDriver").call("_build_enemy_group_fit_counts"))
		print("FIRE_RULES ",mission.get_node("TacticalController").call("get_fireteam_fire_rule_snapshot"))
		print("SCENARIO_GATES ",mission.get_node("CombatLoopDriver").call("get_mission_scenario_runtime_gate_snapshot"))
		print("USE_STATE ",mission.get_node("TacticalController").call("get_mission_interaction_runtime_use_state_snapshot"))
	super._dump(stage)
