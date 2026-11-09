extends "res://scripts/tests/campaign_pilot_ground_loop_test.gd"
## Actual outbound flight/landing, then deliberate authoritative casualty fixture.
## Exercises resolved defeat and objective victory with impossible extraction.

func _on_actual_landed(_controller: Node) -> void:
	pass

func _run() -> void:
	_configure_entry()
	for all_down: bool in [true, false]:
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
		var campaign_before: Dictionary = _campaign().duplicate(true)
		_flow.call("_on_mission_combat_resolved", {"result": "defeat"})
		await create_timer(0.6).timeout
		_check(_campaign() == campaign_before and _supply() == supply_before, "Repeated result and service ticks cannot duplicate failure receipts or debit")
		_check(FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == checkpoint_bytes, "Terminal sortie never overwrites last safe checkpoint")
		if not result.get("campaign_checkpoint_retry_required", false):
			_flow.queue_free()
			await process_frame
			continue
		var button: Button = _flow.get_node("DebriefScreen/Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton")
		_check(button.text.contains("Checkpoint") and not button.disabled, "Visible primary action explicitly offers checkpoint continuation")
		button.pressed.emit()
		await process_frame
		await process_frame
		_flow = current_scene
		_check(_flow != null and String(_flow.get_meta("player_roster_source", "")) == "campaign_checkpoint" and _flow.get("_active_mission") == null, "Actual primary button reloads existing Continue checkpoint")
		_check(Array(_flow.get("_all_team_units")).size() == 2, "Checkpoint restart retains exactly two real people")
		_check(FileAccess.get_file_as_bytes(ROSTER.get_save_path()) == _skirmish_bytes, "Casualty and retry preserve Skirmish profile")
		_flow.queue_free()
		await process_frame
	print("CAMPAIGN_CASUALTY_RESULTS passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
