extends "res://scripts/tests/campaign_pilot_ground_loop_test.gd"
## Actual outbound flight/landing, then deliberate authoritative casualty fixture.
## Exercises resolved defeat and objective victory with impossible extraction.

func _on_actual_landed(_controller: Node) -> void:
	pass

func _run() -> void:
	_configure_entry()
	for scenario: Dictionary in [
		{"all_down": true, "damaged_craft": false, "retry_button": "ReturnToHomebaseButton"},
		{"all_down": false, "damaged_craft": false, "retry_button": "ReturnToFOBButton"},
		{"all_down": true, "damaged_craft": true, "retry_button": "ReturnToHomebaseButton"},
	]:
		var all_down: bool = bool(scenario.all_down)
		print("CAMPAIGN_CASUALTY_CASE ", scenario)
		START.request_start(self, "campaign", "new")
		_flow = FLOW.instantiate()
		root.add_child(_flow)
		current_scene = _flow
		await process_frame
		_screen = _flow.get_node("HomebaseScreen")
		_runtime = _flow.get("_singleplayer_runtime")
		if not await _prepare_initial_base(): break
		_crew_ids = ["campaign_leader"]
		_pilot_id = "campaign_pilot"
		_check(_screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "Accept actual job")
		_check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), "Choose actual location")
		if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): break
		var checkpoint_bytes := FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH)
		_check(not checkpoint_bytes.is_empty(), "Last safe checkpoint exists before terminal casualty")
		var mission: Node = _flow.get("_active_mission")
		var controller: Node = mission.get_node("TacticalController")
		_check(String(_space().phase) == "surface" and String(_space().location_id) == "satellite_crash", "Casualty fixture follows actual moon launch, quantum and satellite approach")
		if bool(scenario.damaged_craft) and not await _damage_actual_craft(mission, controller):
			break
		controller.call("_get_campaign_sortie_unit", "campaign_leader").call("apply_damage", 10000)
		if all_down:
			controller.call("_get_campaign_sortie_unit", "campaign_pilot").call("apply_damage", 10000)
		var gate: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
		_check(String(gate.get("reason", "")) == ("pilot_unavailable" if all_down else "crew_unavailable"), "Real unavailable person blocks physical boarding")
		var supply_before: Dictionary = _supply().duplicate(true)
		mission.get_node("CombatLoopDriver").call("_resolve_combat", "defeat" if all_down else "victory", "enemy" if all_down else "player")
		await process_frame
		_check(_flow.get("_active_mission") == null, "Terminal casualty result releases combat instead of waiting forever")
		_check(Dictionary(_flow.get("_pending_campaign_mission_result")).is_empty(), "No impossible pending boarding retry")
		_check(String(_flow.get("_current_meta_view")) == "debrief", "Casualty debrief is visible")
		var result: Dictionary = _flow.get("_last_mission_result")
		_check(bool(result.get("campaign_checkpoint_retry_required", false)) and String(result.get("result", "")) == "defeat", "Impossible extraction requires explicit checkpoint retry and no success")
		_check(Array(result.get("team_states", [])).size() == 2 and not Dictionary(result.get("progression_summary", {})).is_empty(), "Both original casualties and existing medical progression reach debrief")
		_check(String(_campaign().jobs.satellite_recovery.status) == "failed", "Existing owner records failed job")
		_check(_supply() == supply_before, "No return fuel debit or completion reward")
		_check(Array(_flow.get("_pending_mission_craft_transfers")).is_empty() and String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(_craft_id, "")) == "mission", "No invented physical home arrival or return transfer")
		_check(String(_space().phase) == "surface", "Failed extraction does not manufacture an orbital departure")
		var forbidden_landing: Dictionary = _screen.call("request_operation", "space_land_homebase", {"craft_id": _craft_id})
		_check(not bool(forbidden_landing.get("ok", false)), "Stranded surface craft cannot invoke a moonbase landing")
		var away_save: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime)
		_check(not bool(away_save.get("ok", false)), "Casualty and repair metadata cannot authorize a home checkpoint")
		if bool(scenario.damaged_craft):
			_check(String(Dictionary(result.get("air_asset_recovery", {})).get("meta_state", "craft_available")) != "craft_available", "Real craft damage reaches existing recovery metadata")
		var campaign_before: Dictionary = _campaign().duplicate(true)
		_flow.call("_on_mission_combat_resolved", {"result": "defeat"})
		await create_timer(0.6).timeout
		_check(_campaign() == campaign_before and _supply() == supply_before, "Repeated result and service ticks cannot duplicate failure receipts or debit")
		if bool(scenario.damaged_craft):
			_flow.call("advance_air_asset_recovery_time", 10000.0)
			await process_frame
		_check(String(_craft(_flow.call("get_singleplayer_snapshot")).get("location_id", "")) != "homebase" and String(_space().phase) == "surface", "Recovery/service ticks cannot move the stranded craft home")
		var late_save: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime)
		_check(not bool(late_save.get("ok", false)), "Oversized repair time advance cannot create a safe home checkpoint away from base")
		_check(FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == checkpoint_bytes, "Terminal sortie never overwrites last safe checkpoint")
		if not result.get("campaign_checkpoint_retry_required", false):
			_flow.queue_free()
			await process_frame
			continue
		var button: Button = _flow.get_node("DebriefScreen/Panel/Margin/VBox/ButtonRow/" + String(scenario.retry_button))
		_check(button.text.contains("Checkpoint") and not button.disabled, "Visible primary action explicitly offers checkpoint continuation")
		button.pressed.emit()
		await process_frame
		await process_frame
		_flow = current_scene
		_check(_flow != null and String(_flow.get_meta("player_roster_source", "")) == "campaign_checkpoint" and _flow.get("_active_mission") == null, "Actual primary button reloads existing Continue checkpoint")
		_check(Array(_flow.get("_all_team_units")).size() == 2, "Checkpoint restart retains exactly two real people")
		_runtime = _flow.get("_singleplayer_runtime")
		_screen = _flow.get_node("HomebaseScreen")
		_check(String(_space().phase) == "grounded" and String(_craft(_flow.call("get_singleplayer_snapshot")).get("location_id", "")) == "homebase", "Explicit checkpoint rollback restores grounded state rather than completing the failed flight")
		_check(FileAccess.get_file_as_bytes(ROSTER.get_save_path()) == _skirmish_bytes, "Casualty and retry preserve Skirmish profile")
		_flow.queue_free()
		await process_frame
	print("CAMPAIGN_CASUALTY_RESULTS passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _damage_actual_craft(mission: Node, controller: Node) -> bool:
	var threat := {"asset_id": _craft_id, "weapon_id": "rocket_launcher", "attacker_unit_id": "casualty_fixture_at", "range_tiles": 6.0, "has_line_of_sight": true, "visible_in_fow": true, "altitude_layer": "low", "enemy_at_pressure": 0.8}
	threat["sequence"] = "casualty_warning"
	var warning: Dictionary = controller.call("apply_air_asset_threat", threat)
	if not _check(bool(warning.get("warning_required", false)), "Actual anti-armor fixture warns before damaging the landed craft"):
		return false
	threat.merge({"sequence": "casualty_hit", "warning_seen": true, "damage": 60, "allow_destroy": false}, true)
	var damaged: Dictionary = controller.call("apply_air_asset_threat", threat)
	if not _check(bool(damaged.get("hit_allowed", false)) and String(damaged.get("next_state", "")) == "damaged", "Existing damage resolver produces a damaged original craft"):
		return false
	return await _wait(func():
		var status: Dictionary = mission.get_node("SimulationRoot").call("get_air_asset_status_snapshot", _craft_id)
		return String(status.get("state", "")) == "damaged", 3000, "Craft damage commits through the actual mission SimulationRoot before crew loss")
