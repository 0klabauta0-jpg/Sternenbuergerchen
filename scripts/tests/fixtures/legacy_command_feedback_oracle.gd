extends "res://scripts/tests/mission_tactical_sandbox_controller.gd"
## Frozen pre-extraction debug/report builder; test-only executable oracle.
## Source method body is copied verbatim, only its method name differs.
## Body SHA256: c5951c28435512013e235d674b4ed237a1e338969a1ccb4860924b80107b515a

func get_pre_extraction_feedback_snapshot() -> Dictionary:
	var cover_effectiveness_readout: Dictionary = get_cover_effectiveness_readout_snapshot()
	var combat_hud_density: Dictionary = _build_mission_combat_hud_density_snapshot()
	var selected_fireteam_status_label_text: String = _build_fireteam_status_text()
	var mission_control_status_text: String = _build_strategic_status_text()
	combat_hud_density = _build_mission_combat_hud_density_snapshot()
	var contact_fire_primary_line: String = _build_release_fire_exchange_contact_fire_primary_hud_line(combat_hud_density)
	if contact_fire_primary_line.is_empty():
		selected_fireteam_status_label_text = _bind_release_fire_exchange_real_window_primary_hud_text(
			_get_label_text(FIRETEAM_STATUS_LABEL_PATH),
			combat_hud_density,
			selected_fireteam_status_label_text
		)
		mission_control_status_text = _bind_release_fire_exchange_real_window_primary_hud_text(
			_get_label_text(STRATEGIC_STATUS_LABEL_PATH),
			combat_hud_density,
			mission_control_status_text
		)
	var frontier_probe_one_screen: Dictionary = _build_frontier_probe_one_screen_playability_readout()
	var order_preview_threat_overlay_f6_hud: Dictionary = get_order_preview_threat_overlay_f6_hud_snapshot()
	var decision_overlay_real_f6_visual_review: Dictionary = get_decision_overlay_real_f6_visual_review_snapshot(order_preview_threat_overlay_f6_hud)
	var decision_overlay_f6_visual_polish: Dictionary = get_decision_overlay_f6_visual_polish_snapshot(decision_overlay_real_f6_visual_review)
	var first_decision_micro_scenario_polish: Dictionary = get_first_decision_micro_scenario_polish_snapshot({}, order_preview_threat_overlay_f6_hud, decision_overlay_f6_visual_polish)
	var frontier_probe_next_interaction: Dictionary = _build_frontier_probe_playfeel_next_interaction_snapshot()
	var frontier_probe_debrief_handoff: Dictionary = _build_frontier_probe_debrief_handoff_feel_snapshot()
	var mission_interaction_use_feedback: Dictionary = get_mission_interaction_use_feedback_snapshot()
	var mission_interaction_progress_readability: Dictionary = _build_mission_interaction_progress_readability_snapshot(mission_interaction_use_feedback)
	var mission_interaction_use_intent: Dictionary = get_mission_interaction_use_intent_snapshot()
	var mission_interaction_door_use_breach_hook: Dictionary = get_mission_interaction_door_use_breach_command_hook_snapshot()
	var mission_interaction_door_multiplayer_authority: Dictionary = get_mission_interaction_door_multiplayer_authority_snapshot()
	var mission_interaction_door_authority_ui_feedback: Dictionary = build_mission_interaction_door_authority_ui_feedback()
	var mission_interaction_multiplayer_door_feedback_capture: Dictionary = get_mission_interaction_multiplayer_door_feedback_capture_snapshot()
	var mission_interaction_objective_gate: Dictionary = get_mission_interaction_objective_gate_snapshot()
	var mission_interaction_visual_state: Dictionary = Dictionary(MISSION_INTERACTION_VISUAL_STATE_SCRIPT.call(
		"build_snapshot",
		get_mission_interaction_runtime_use_state_snapshot(),
		mission_interaction_objective_gate
	)).duplicate(true)
	var mission_interaction_object_reaction: Dictionary = Dictionary(MISSION_INTERACTION_OBJECT_REACTION_SCRIPT.call(
		"build_snapshot",
		mission_interaction_visual_state
	)).duplicate(true)
	var station_route_run_readout: Dictionary = _build_station_route_run_readout_snapshot(mission_interaction_objective_gate, mission_interaction_object_reaction)
	var station_scenario_route_cue_polish: Dictionary = _build_station_scenario_route_cue_polish_snapshot(
		station_route_run_readout,
		mission_interaction_objective_gate,
		mission_interaction_use_feedback,
		mission_interaction_progress_readability
	)
	var mission_hud_interaction_density: Dictionary = _build_mission_hud_interaction_density_snapshot(
		station_route_run_readout,
		station_scenario_route_cue_polish,
		mission_interaction_progress_readability
	)
	var fire_rule_consequence_readability: Dictionary = Dictionary(mission_hud_interaction_density.get("fire_rule_consequence", {})).duplicate(true)
	var station_scenario_identity_body: Dictionary = build_station_scenario_identity_body_snapshot(station_route_run_readout, [], station_scenario_route_cue_polish)
	var station_scenario_debrief_handoff_cue: Dictionary = _build_station_scenario_debrief_handoff_cue_snapshot(
		station_route_run_readout,
		station_scenario_route_cue_polish,
		station_scenario_identity_body,
		mission_hud_interaction_density
	)
	var mission_team_chip_snapshot: Dictionary = get_mission_team_chip_snapshot()
	var tactical_event_log_entries: Array = get_tactical_event_log_snapshot()
	var release_firefight_decision: Dictionary = _build_release_candidate_firefight_decision_line_snapshot()
	var release_firefight_event_log_display: Dictionary = _build_release_firefight_event_log_display_snapshot(
		tactical_event_log_entries,
		release_firefight_decision,
		combat_hud_density
	)
	var release_first_decision_next_playable_loop: Dictionary = get_release_first_decision_next_playable_loop_snapshot(
		{},
		first_decision_micro_scenario_polish,
		release_firefight_decision
	)
	var release_first_decision_next_loop_line: String = String(release_first_decision_next_playable_loop.get("visible_loop_line", release_first_decision_next_playable_loop.get("primary_line", "")))
	var release_first_decision_loop_two_playtest: Dictionary = get_release_first_decision_loop_two_playtest_snapshot(
		release_first_decision_next_playable_loop,
		selected_fireteam_status_label_text,
		mission_control_status_text,
		{
			"release_first_decision_next_loop_line": release_first_decision_next_loop_line,
			"release_first_decision_next_loop_status": String(release_first_decision_next_playable_loop.get("status", "")),
		}
	)
	var release_first_decision_loop_two_polish: Dictionary = get_release_first_decision_loop_two_polish_snapshot(
		release_first_decision_next_playable_loop,
		release_first_decision_loop_two_playtest
	)
	var release_first_decision_loop_two_execution_hook: Dictionary = get_release_first_decision_loop_two_execution_hook_snapshot(
		release_first_decision_loop_two_polish,
		String(release_first_decision_loop_two_polish.get("recommended_choice_id", "hold_angle"))
	)
	var release_first_decision_loop_two_go_smoke: Dictionary = get_release_first_decision_loop_two_go_smoke_snapshot(
		release_first_decision_loop_two_execution_hook,
		{}
	)
	var release_first_decision_loop_two_runtime_button: Dictionary = get_release_first_decision_loop_two_runtime_button_snapshot(
		release_first_decision_loop_two_go_smoke,
		release_first_decision_loop_two_execution_hook
	)
	var release_first_decision_loop_two_visual_polish: Dictionary = get_release_first_decision_loop_two_visual_polish_snapshot(
		{},
		release_first_decision_loop_two_runtime_button
	)
	var release_first_decision_loop_two_playability_smoke: Dictionary = get_release_first_decision_loop_two_playability_smoke_snapshot(
		release_first_decision_loop_two_visual_polish,
		{}
	)
	var release_first_decision_loop_two_player_loop_extension: Dictionary = get_release_first_decision_loop_two_player_loop_extension_snapshot()
	var release_first_decision_loop_two_player_loop_hud_wiring: Dictionary = get_release_first_decision_loop_two_player_loop_hud_wiring_snapshot(
		release_first_decision_loop_two_player_loop_extension,
		{
			"selected_fireteam_status_text": selected_fireteam_status_label_text,
			"mission_control_status_text": mission_control_status_text,
			"command_feedback_text": _get_label_text(command_feedback_label_path),
		}
	)
	var release_first_decision_loop_two_player_loop_choice_hook: Dictionary = get_release_first_decision_loop_two_player_loop_choice_hook_snapshot(
		release_first_decision_loop_two_player_loop_hud_wiring,
		""
	)
	var release_first_decision_loop_two_player_loop_runtime_choice_buttons: Dictionary = get_release_first_decision_loop_two_player_loop_runtime_choice_buttons_snapshot(
		release_first_decision_loop_two_player_loop_choice_hook,
		release_first_decision_loop_two_player_loop_hud_wiring
	)
	var release_first_decision_loop_two_player_loop_choice_confirm_smoke: Dictionary = get_release_first_decision_loop_two_player_loop_choice_confirm_smoke_snapshot(
		release_first_decision_loop_two_player_loop_runtime_choice_buttons,
		release_first_decision_loop_two_player_loop_choice_hook,
		{}
	)
	var release_first_decision_loop_two_player_loop_visual_polish: Dictionary = get_release_first_decision_loop_two_player_loop_visual_polish_snapshot(
		{},
		release_first_decision_loop_two_player_loop_runtime_choice_buttons
	)
	var release_first_decision_loop_two_player_loop_acceptance_slice: Dictionary = get_release_first_decision_loop_two_player_loop_acceptance_slice_snapshot(
		release_first_decision_loop_two_player_loop_visual_polish,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_outcome_slice: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_outcome_slice_snapshot(
		release_first_decision_loop_two_player_loop_acceptance_slice,
		{}
	)
	var release_first_decision_loop_two_player_loop_outcome_real_window_capture: Dictionary = get_release_first_decision_loop_two_player_loop_outcome_real_window_capture_snapshot(
		release_first_decision_loop_two_player_loop_scenario_outcome_slice,
		{}
	)
	var release_first_decision_loop_two_player_loop_outcome_visual_polish: Dictionary = get_release_first_decision_loop_two_player_loop_outcome_visual_polish_snapshot(
		{},
		release_first_decision_loop_two_player_loop_outcome_real_window_capture
	)
	var release_first_decision_loop_two_player_loop_outcome_playability_slice: Dictionary = get_release_first_decision_loop_two_player_loop_outcome_playability_slice_snapshot(
		release_first_decision_loop_two_player_loop_outcome_visual_polish,
		{}
	)
	var release_first_decision_loop_two_player_loop_next_micro_objective: Dictionary = get_release_first_decision_loop_two_player_loop_next_micro_objective_snapshot(
		release_first_decision_loop_two_player_loop_outcome_playability_slice,
		{}
	)
	var release_first_decision_loop_two_player_loop_micro_objective_hud_wiring: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_snapshot(
		release_first_decision_loop_two_player_loop_next_micro_objective,
		{}
	)
	var release_first_decision_loop_two_player_loop_micro_objective_choice_hook: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_choice_hook_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_hud_wiring,
		""
	)
	var release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_choice_hook,
		release_first_decision_loop_two_player_loop_micro_objective_hud_wiring
	)
	var release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons,
		release_first_decision_loop_two_player_loop_micro_objective_choice_hook,
		{}
	)
	var release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke,
		{}
	)
	var release_first_decision_loop_two_player_loop_micro_objective_outcome_slice: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_outcome_slice_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice,
		{}
	)
	var release_first_decision_loop_two_player_loop_micro_objective_real_window_capture: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_real_window_capture_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_outcome_slice,
		{}
	)
	var release_first_decision_loop_two_player_loop_micro_objective_visual_polish: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_visual_polish_snapshot(
		{},
		release_first_decision_loop_two_player_loop_micro_objective_real_window_capture
	)
	var release_first_decision_loop_two_player_loop_micro_objective_playability_slice: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_playability_slice_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_visual_polish,
		{}
	)
	var release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_playability_slice,
		{}
	)
	var release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke,
		{}
	)
	var release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice
	)
	var release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish,
		{}
	)
	var release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture,
		{}
	)
	var release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings
	)
	var release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish,
		{}
	)
	var release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice,
		{}
	)
	var release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest,
		{}
	)
	var release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings
	)
	var release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice: Dictionary = get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_stitch: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_stitch_snapshot(
		release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_runtime_hook: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_runtime_hook_snapshot(
		release_first_decision_loop_two_player_loop_scenario_stitch,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_runtime_smoke: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_runtime_smoke_snapshot(
		release_first_decision_loop_two_player_loop_scenario_runtime_hook,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_player_feel_findings: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_player_feel_findings_snapshot(
		release_first_decision_loop_two_player_loop_scenario_runtime_smoke,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_player_feel_polish: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_player_feel_polish_snapshot(
		release_first_decision_loop_two_player_loop_scenario_player_feel_findings
	)
	var release_first_decision_loop_two_player_loop_scenario_playability_slice: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_playability_slice_snapshot(
		release_first_decision_loop_two_player_loop_scenario_player_feel_polish,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_real_window_capture: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_real_window_capture_snapshot(
		release_first_decision_loop_two_player_loop_scenario_playability_slice,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_visual_findings: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_visual_findings_snapshot(
		release_first_decision_loop_two_player_loop_scenario_real_window_capture,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_acceptance_slice: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_acceptance_slice_snapshot(
		release_first_decision_loop_two_player_loop_scenario_visual_findings,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_integrated_playtest: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_integrated_playtest_snapshot(
		release_first_decision_loop_two_player_loop_scenario_acceptance_slice,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings_snapshot(
		release_first_decision_loop_two_player_loop_scenario_integrated_playtest,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice_snapshot(
		release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest_snapshot(
		release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance_snapshot(
		release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_ship_readiness_review: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_ship_readiness_review_snapshot(
		release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke_snapshot(
		release_first_decision_loop_two_player_loop_scenario_ship_readiness_review,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_delivery_review: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_delivery_review_snapshot(
		release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_handoff_packet: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_handoff_packet_snapshot(
		release_first_decision_loop_two_player_loop_scenario_delivery_review,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_tester_run: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_tester_run_snapshot(
		release_first_decision_loop_two_player_loop_scenario_handoff_packet,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance_snapshot(
		release_first_decision_loop_two_player_loop_scenario_tester_run,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan_snapshot(
		release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook_snapshot(
		release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke_snapshot(
		release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings_snapshot(
		release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish_snapshot(
		release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings
	)
	var release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice_snapshot(
		release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture_snapshot(
		release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings_snapshot(
		release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish_snapshot(
		release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings
	)
	var release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice_snapshot(
		release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish,
		{}
	)
	var release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest: Dictionary = get_release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_snapshot(
		release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice,
		{}
	)
	var tactical_event_log_display_entries: Array = Array(release_firefight_event_log_display.get("entries", []))
	var command_feedback_snapshot: Dictionary = {
		"selected_fireteam_ids": Array(_selected_fireteam_ids),
		"selected_fireteam_label": _get_fireteam_name(),
		"selected_tile": _build_selected_tile_snapshot(),
		"phase_name": _get_phase_name(),
		"target_text": _build_target_text(),
		"selected_order_text": _build_selected_waypoint_info_text(),
		"selected_multi_fireteam_plan_text": _build_selected_multi_fireteam_plan_info_text(),
		"mission_control_plan_text": _build_mission_control_multi_fireteam_plan_text(),
		"selected_status_text": _build_fireteam_status_text(),
		"selected_decision_text": _build_selected_decision_status_text(),
		"selected_decision_context": _build_selected_decision_context_snapshot(),
		"last_command_text": _last_command_text,
		"command_feedback_text": _get_label_text(command_feedback_label_path),
		"selected_fireteam_status_label_text": selected_fireteam_status_label_text,
		"mission_control_status_text": mission_control_status_text,
		"mission_identity_header_text": _get_label_text(MISSION_IDENTITY_HEADER_LABEL_PATH),
		"mission_identity_body_text": _get_label_text(MISSION_IDENTITY_BODY_LABEL_PATH),
		"station_scenario_identity_body": station_scenario_identity_body,
		"station_scenario_identity_body_line": String(station_scenario_identity_body.get("text", "")),
		"station_scenario_identity_body_route_visible": bool(station_scenario_identity_body.get("active", false)),
		"station_scenario_identity_body_cue_visible": bool(station_scenario_identity_body.get("cue_visible", false)),
		"station_scenario_identity_body_display_route_line": String(station_scenario_identity_body.get("display_route_line", "")),
		"station_scenario_identity_body_future_blocker_hidden_in_display": bool(station_scenario_identity_body.get("future_blocker_hidden_in_display", false)),
		"mission_team_chip_text": _get_label_text(MISSION_TEAM_CHIP_LABEL_PATH),
		"mission_team_chip": mission_team_chip_snapshot,
		"mission_team_chip_tooltip_text": _get_label_tooltip_text(MISSION_TEAM_CHIP_LABEL_PATH),
		"authority_visual": Dictionary(mission_team_chip_snapshot.get("authority_visual", {})).duplicate(true),
		"authority_visual_text": String(mission_team_chip_snapshot.get("authority_compact_text", "")),
		"authority_visual_visible": bool(mission_team_chip_snapshot.get("authority_visible", false)),
		"authority_visual_tooltip_text": String(mission_team_chip_snapshot.get("authority_tooltip_text", "")),
		"authority_feedback_line": String(Dictionary(mission_team_chip_snapshot.get("authority_visual", {})).get("feedback_line", "")),
		"authority_feedback_detail": String(Dictionary(mission_team_chip_snapshot.get("authority_visual", {})).get("feedback_detail", "")),
		"authority_visible_feedback_text": String(mission_team_chip_snapshot.get("authority_visible_feedback_text", Dictionary(mission_team_chip_snapshot.get("authority_visual", {})).get("visible_feedback_text", ""))),
		"authority_visible_action_text": String(mission_team_chip_snapshot.get("authority_visible_action_text", Dictionary(mission_team_chip_snapshot.get("authority_visual", {})).get("visible_action_text", ""))),
		"authority_next_action_text": String(mission_team_chip_snapshot.get("authority_next_action_text", Dictionary(mission_team_chip_snapshot.get("authority_visual", {})).get("next_action_text", ""))),
		"authority_next_action_detail": String(mission_team_chip_snapshot.get("authority_next_action_detail", Dictionary(mission_team_chip_snapshot.get("authority_visual", {})).get("next_action_detail", ""))),
		"review_session_badge": Dictionary(mission_team_chip_snapshot.get("review_session", {})).duplicate(true),
		"review_session_badge_text": String(mission_team_chip_snapshot.get("review_session_badge_text", "")),
		"review_session_badge_visible": bool(mission_team_chip_snapshot.get("review_session_badge_visible", false)),
		"review_session_badge_style_id": String(mission_team_chip_snapshot.get("review_session_badge_style_id", REVIEW_SESSION_BADGE_STYLE_ID)),
		"command_buttons": _build_command_control_snapshot(),
		"command_hierarchy": get_command_hierarchy_snapshot(),
		"planned_waypoint_count": _count_selected_phase_waypoints(),
		"planned_area_order_count": _count_selected_area_orders(),
		"multi_fireteam_plan_count": _serialize_multi_fireteam_plans().size(),
		"visualized_waypoint_count": get_visualized_waypoints_snapshot().size(),
		"visualized_area_order_count": get_visualized_area_orders_snapshot().size(),
		"waypoint_intent_preview_count": get_waypoint_intent_preview_snapshot().size(),
		"waypoint_intent_preview": get_waypoint_intent_preview_snapshot(),
		"waypoint_intent_preview_contract": get_waypoint_intent_preview_contract_snapshot(),
		"fire_sector_overlay": get_fire_sector_overlay_snapshot(),
		"los_debug_overlay": get_los_debug_overlay_snapshot(),
		"contact_density_heatmap": get_contact_density_heatmap_snapshot(),
		"contact_decision_diagnostics": get_contact_decision_diagnostics_snapshot(),
		"contact_decision_diagnostics_text": _build_mission_control_contact_diagnostics_text(),
		"combat_hud_density": combat_hud_density,
		"combat_hud_compact_line": String(combat_hud_density.get("compact_line", "")),
		"mission_hud_interaction_density": mission_hud_interaction_density,
		"mission_hud_interaction_line": String(mission_hud_interaction_density.get("mission_control_line", "")),
		"fire_rule_consequence_readability": fire_rule_consequence_readability,
		"fire_rule_consequence_line": String(fire_rule_consequence_readability.get("consequence_line", "")),
		"fire_rule_consequence_state": String(fire_rule_consequence_readability.get("consequence_state", "")),
		"frontier_probe_one_screen_playability": frontier_probe_one_screen,
		"frontier_probe_one_screen_line": String(frontier_probe_one_screen.get("one_screen_line", "")),
		"order_preview_threat_overlay_f6_hud": order_preview_threat_overlay_f6_hud,
		"order_preview_threat_overlay_choice_line": String(order_preview_threat_overlay_f6_hud.get("mission_control_choice_line", "")),
		"order_preview_threat_overlay_choice_cards": Array(order_preview_threat_overlay_f6_hud.get("visible_choice_cards", [])),
		"order_preview_threat_overlay_selected_fireteam_line": String(order_preview_threat_overlay_f6_hud.get("selected_fireteam_choice_line", "")),
		"order_preview_threat_overlay_gate": String(order_preview_threat_overlay_f6_hud.get("gate", "")),
		"decision_overlay_real_f6_visual_review": decision_overlay_real_f6_visual_review,
		"decision_overlay_real_f6_visual_review_gate": String(decision_overlay_real_f6_visual_review.get("gate", "")),
		"decision_overlay_real_f6_visual_review_status": String(decision_overlay_real_f6_visual_review.get("status", "")),
		"decision_overlay_f6_visual_polish": decision_overlay_f6_visual_polish,
		"decision_overlay_f6_visual_polish_gate": String(decision_overlay_f6_visual_polish.get("gate", "")),
		"decision_overlay_f6_visual_polish_status": String(decision_overlay_f6_visual_polish.get("status", "")),
		"first_decision_micro_scenario_polish": first_decision_micro_scenario_polish,
		"first_decision_micro_scenario_line": String(first_decision_micro_scenario_polish.get("primary_cue_line", "")),
		"first_decision_micro_scenario_gate": String(first_decision_micro_scenario_polish.get("gate", "")),
		"release_first_decision_next_playable_loop": release_first_decision_next_playable_loop,
		"release_first_decision_next_loop_line": release_first_decision_next_loop_line,
		"release_first_decision_next_loop_status": String(release_first_decision_next_playable_loop.get("status", "")),
		"release_first_decision_loop_two_playtest": release_first_decision_loop_two_playtest,
		"release_first_decision_loop_two_gate": String(release_first_decision_loop_two_playtest.get("gate", "")),
		"release_first_decision_loop_two_status": String(release_first_decision_loop_two_playtest.get("status", "")),
		"release_first_decision_loop_two_polish": release_first_decision_loop_two_polish,
		"release_first_decision_loop_two_polish_line": String(release_first_decision_loop_two_polish.get("compact_line", "")),
		"release_first_decision_loop_two_polish_gate": String(release_first_decision_loop_two_polish.get("gate", "")),
		"release_first_decision_loop_two_polish_status": String(release_first_decision_loop_two_polish.get("status", "")),
		"release_first_decision_loop_two_execution_hook": release_first_decision_loop_two_execution_hook,
		"release_first_decision_loop_two_execution_line": String(release_first_decision_loop_two_execution_hook.get("execution_line", "")),
		"release_first_decision_loop_two_execution_gate": String(release_first_decision_loop_two_execution_hook.get("gate", "")),
		"release_first_decision_loop_two_execution_status": String(release_first_decision_loop_two_execution_hook.get("status", "")),
		"release_first_decision_loop_two_go_smoke": release_first_decision_loop_two_go_smoke,
		"release_first_decision_loop_two_go_smoke_line": String(release_first_decision_loop_two_go_smoke.get("smoke_line", "")),
		"release_first_decision_loop_two_go_smoke_gate": String(release_first_decision_loop_two_go_smoke.get("gate", "")),
		"release_first_decision_loop_two_go_smoke_status": String(release_first_decision_loop_two_go_smoke.get("status", "")),
		"release_first_decision_loop_two_runtime_button": release_first_decision_loop_two_runtime_button,
		"release_first_decision_loop_two_runtime_button_line": String(release_first_decision_loop_two_runtime_button.get("runtime_line", "")),
		"release_first_decision_loop_two_runtime_button_gate": String(release_first_decision_loop_two_runtime_button.get("gate", "")),
		"release_first_decision_loop_two_runtime_button_status": String(release_first_decision_loop_two_runtime_button.get("status", "")),
		"release_first_decision_loop_two_visual_polish": release_first_decision_loop_two_visual_polish,
		"release_first_decision_loop_two_visual_polish_line": String(release_first_decision_loop_two_visual_polish.get("hud_line", "")),
		"release_first_decision_loop_two_visual_polish_status": String(release_first_decision_loop_two_visual_polish.get("status", "")),
		"release_first_decision_loop_two_playability_smoke": release_first_decision_loop_two_playability_smoke,
		"release_first_decision_loop_two_playability_smoke_line": String(release_first_decision_loop_two_playability_smoke.get("smoke_line", "")),
		"release_first_decision_loop_two_playability_smoke_status": String(release_first_decision_loop_two_playability_smoke.get("status", "")),
		"release_first_decision_loop_two_player_loop_extension": release_first_decision_loop_two_player_loop_extension,
		"release_first_decision_loop_two_player_loop_extension_line": String(release_first_decision_loop_two_player_loop_extension.get("visible_loop_line", release_first_decision_loop_two_player_loop_extension.get("primary_line", ""))),
		"release_first_decision_loop_two_player_loop_extension_status": String(release_first_decision_loop_two_player_loop_extension.get("status", "")),
		"release_first_decision_loop_two_player_loop_hud_wiring": release_first_decision_loop_two_player_loop_hud_wiring,
		"release_first_decision_loop_two_player_loop_hud_wiring_line": String(release_first_decision_loop_two_player_loop_hud_wiring.get("command_feedback_line", "")),
		"release_first_decision_loop_two_player_loop_hud_wiring_status": String(release_first_decision_loop_two_player_loop_hud_wiring.get("status", "")),
		"release_first_decision_loop_two_player_loop_hud_choice_chips": Array(release_first_decision_loop_two_player_loop_hud_wiring.get("hud_choice_chips", [])),
		"release_first_decision_loop_two_player_loop_choice_hook": release_first_decision_loop_two_player_loop_choice_hook,
		"release_first_decision_loop_two_player_loop_choice_hook_line": String(release_first_decision_loop_two_player_loop_choice_hook.get("choice_hook_line", "")),
		"release_first_decision_loop_two_player_loop_choice_hook_status": String(release_first_decision_loop_two_player_loop_choice_hook.get("status", "")),
		"release_first_decision_loop_two_player_loop_choice_hook_command_draft": Dictionary(release_first_decision_loop_two_player_loop_choice_hook.get("command_draft", {})).duplicate(true),
		"release_first_decision_loop_two_player_loop_runtime_choice_buttons": release_first_decision_loop_two_player_loop_runtime_choice_buttons,
		"release_first_decision_loop_two_player_loop_runtime_choice_buttons_line": String(release_first_decision_loop_two_player_loop_runtime_choice_buttons.get("runtime_buttons_line", "")),
		"release_first_decision_loop_two_player_loop_runtime_choice_buttons_status": String(release_first_decision_loop_two_player_loop_runtime_choice_buttons.get("status", "")),
		"release_first_decision_loop_two_player_loop_runtime_choice_button_specs": Array(release_first_decision_loop_two_player_loop_runtime_choice_buttons.get("button_specs", [])),
		"release_first_decision_loop_two_player_loop_choice_confirm_smoke": release_first_decision_loop_two_player_loop_choice_confirm_smoke,
		"release_first_decision_loop_two_player_loop_choice_confirm_smoke_line": String(release_first_decision_loop_two_player_loop_choice_confirm_smoke.get("smoke_line", "")),
		"release_first_decision_loop_two_player_loop_choice_confirm_smoke_status": String(release_first_decision_loop_two_player_loop_choice_confirm_smoke.get("status", "")),
		"release_first_decision_loop_two_player_loop_visual_polish": release_first_decision_loop_two_player_loop_visual_polish,
		"release_first_decision_loop_two_player_loop_visual_polish_line": String(release_first_decision_loop_two_player_loop_visual_polish.get("choice_group_line", "")),
		"release_first_decision_loop_two_player_loop_visual_polish_status": String(release_first_decision_loop_two_player_loop_visual_polish.get("status", "")),
		"release_first_decision_loop_two_player_loop_visual_polish_button_specs": Array(release_first_decision_loop_two_player_loop_visual_polish.get("button_visual_specs", [])),
		"release_first_decision_loop_two_player_loop_acceptance_slice": release_first_decision_loop_two_player_loop_acceptance_slice,
		"release_first_decision_loop_two_player_loop_acceptance_slice_line": String(release_first_decision_loop_two_player_loop_acceptance_slice.get("acceptance_line", "")),
		"release_first_decision_loop_two_player_loop_acceptance_slice_status": String(release_first_decision_loop_two_player_loop_acceptance_slice.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_outcome_slice": release_first_decision_loop_two_player_loop_scenario_outcome_slice,
		"release_first_decision_loop_two_player_loop_scenario_outcome_line": String(release_first_decision_loop_two_player_loop_scenario_outcome_slice.get("outcome_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_outcome_status": String(release_first_decision_loop_two_player_loop_scenario_outcome_slice.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_outcome_next_step_line": String(release_first_decision_loop_two_player_loop_scenario_outcome_slice.get("next_step_line", "")),
		"release_first_decision_loop_two_player_loop_outcome_real_window_capture": release_first_decision_loop_two_player_loop_outcome_real_window_capture,
		"release_first_decision_loop_two_player_loop_outcome_real_window_capture_status": String(release_first_decision_loop_two_player_loop_outcome_real_window_capture.get("status", "")),
		"release_first_decision_loop_two_player_loop_outcome_real_window_capture_gate": String(release_first_decision_loop_two_player_loop_outcome_real_window_capture.get("gate", "")),
		"release_first_decision_loop_two_player_loop_outcome_visual_polish": release_first_decision_loop_two_player_loop_outcome_visual_polish,
		"release_first_decision_loop_two_player_loop_outcome_visual_polish_line": String(release_first_decision_loop_two_player_loop_outcome_visual_polish.get("outcome_polish_line", "")),
		"release_first_decision_loop_two_player_loop_outcome_visual_polish_status": String(release_first_decision_loop_two_player_loop_outcome_visual_polish.get("status", "")),
		"release_first_decision_loop_two_player_loop_outcome_visual_polish_surface_specs": Array(release_first_decision_loop_two_player_loop_outcome_visual_polish.get("outcome_surface_specs", [])),
		"release_first_decision_loop_two_player_loop_outcome_playability_slice": release_first_decision_loop_two_player_loop_outcome_playability_slice,
		"release_first_decision_loop_two_player_loop_outcome_playability_slice_line": String(release_first_decision_loop_two_player_loop_outcome_playability_slice.get("outcome_playability_line", "")),
		"release_first_decision_loop_two_player_loop_outcome_playability_slice_status": String(release_first_decision_loop_two_player_loop_outcome_playability_slice.get("status", "")),
		"release_first_decision_loop_two_player_loop_outcome_playability_slice_gate": String(release_first_decision_loop_two_player_loop_outcome_playability_slice.get("gate", "")),
		"release_first_decision_loop_two_player_loop_next_micro_objective": release_first_decision_loop_two_player_loop_next_micro_objective,
		"release_first_decision_loop_two_player_loop_next_micro_objective_line": String(release_first_decision_loop_two_player_loop_next_micro_objective.get("next_micro_objective_line", "")),
		"release_first_decision_loop_two_player_loop_next_micro_objective_status": String(release_first_decision_loop_two_player_loop_next_micro_objective.get("status", "")),
		"release_first_decision_loop_two_player_loop_next_micro_objective_cards": Array(release_first_decision_loop_two_player_loop_next_micro_objective.get("micro_objective_cards", [])),
		"release_first_decision_loop_two_player_loop_micro_objective_hud_wiring": release_first_decision_loop_two_player_loop_micro_objective_hud_wiring,
		"release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_line": String(release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.get("command_feedback_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_status": String(release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_chips": Array(release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.get("hud_micro_objective_chips", [])),
		"release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_selected_fireteam_line": String(release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.get("selected_fireteam_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_mission_control_line": String(release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.get("mission_control_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_choice_hook": release_first_decision_loop_two_player_loop_micro_objective_choice_hook,
		"release_first_decision_loop_two_player_loop_micro_objective_choice_hook_line": String(release_first_decision_loop_two_player_loop_micro_objective_choice_hook.get("micro_objective_choice_hook_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_choice_hook_status": String(release_first_decision_loop_two_player_loop_micro_objective_choice_hook.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_choice_hook_command_draft": Dictionary(release_first_decision_loop_two_player_loop_micro_objective_choice_hook.get("micro_objective_command_draft", {})).duplicate(true),
		"release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons": release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons,
		"release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons_line": String(release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons.get("runtime_buttons_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons_status": String(release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_runtime_button_specs": Array(release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons.get("micro_objective_button_specs", [])),
		"release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke": release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke,
		"release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke_line": String(release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke.get("micro_objective_confirm_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke_status": String(release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke_gate": String(release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke.get("gate", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice": release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice,
		"release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice_line": String(release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice.get("acceptance_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice_status": String(release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice_gate": String(release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice.get("gate", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_outcome_slice": release_first_decision_loop_two_player_loop_micro_objective_outcome_slice,
		"release_first_decision_loop_two_player_loop_micro_objective_outcome_slice_line": String(release_first_decision_loop_two_player_loop_micro_objective_outcome_slice.get("outcome_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_outcome_slice_status": String(release_first_decision_loop_two_player_loop_micro_objective_outcome_slice.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_outcome_slice_gate": String(release_first_decision_loop_two_player_loop_micro_objective_outcome_slice.get("gate", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_outcome_next_step_line": String(release_first_decision_loop_two_player_loop_micro_objective_outcome_slice.get("next_step_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_real_window_capture": release_first_decision_loop_two_player_loop_micro_objective_real_window_capture,
		"release_first_decision_loop_two_player_loop_micro_objective_real_window_capture_status": String(release_first_decision_loop_two_player_loop_micro_objective_real_window_capture.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_real_window_capture_gate": String(release_first_decision_loop_two_player_loop_micro_objective_real_window_capture.get("gate", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_real_window_capture_window_screenshot_path": String(release_first_decision_loop_two_player_loop_micro_objective_real_window_capture.get("window_screenshot_path", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_visual_polish": release_first_decision_loop_two_player_loop_micro_objective_visual_polish,
		"release_first_decision_loop_two_player_loop_micro_objective_visual_polish_line": String(release_first_decision_loop_two_player_loop_micro_objective_visual_polish.get("micro_objective_polish_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_visual_polish_status": String(release_first_decision_loop_two_player_loop_micro_objective_visual_polish.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_visual_polish_surface_specs": Array(release_first_decision_loop_two_player_loop_micro_objective_visual_polish.get("micro_objective_surface_specs", [])),
		"release_first_decision_loop_two_player_loop_micro_objective_playability_slice": release_first_decision_loop_two_player_loop_micro_objective_playability_slice,
		"release_first_decision_loop_two_player_loop_micro_objective_playability_slice_line": String(release_first_decision_loop_two_player_loop_micro_objective_playability_slice.get("micro_objective_playability_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_playability_slice_status": String(release_first_decision_loop_two_player_loop_micro_objective_playability_slice.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_playability_slice_gate": String(release_first_decision_loop_two_player_loop_micro_objective_playability_slice.get("gate", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke": release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke,
		"release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke_line": String(release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke.get("round_trip_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke_status": String(release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke_gate": String(release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke.get("gate", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice": release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice,
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice_line": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice.get("round_loop_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice_status": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice_gate": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice.get("gate", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish": release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish,
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish_line": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish.get("mission_control_runtime_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish_status": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish_surface_specs": Array(release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish.get("round_loop_runtime_surface_specs", [])),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture": release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture,
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture_status": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture_gate": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture.get("gate", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture_window_screenshot_path": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture.get("window_screenshot_path", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings": release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings,
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings_status": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings_issue_count": int(release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings.get("issue_count", 0)),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish": release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish,
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish_line": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish.get("round_loop_polish_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish_status": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish_surface_specs": Array(release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish.get("round_loop_surface_specs", [])),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice": release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice,
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice_line": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice.get("round_loop_playability_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice_status": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice_gate": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice.get("gate", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest": release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest,
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest_line": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest.get("integrated_playtest_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest_status": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest_gate": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest.get("gate", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings": release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings,
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings_status": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings.get("status", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings_issue_count": int(release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings.get("issue_count", 0)),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings_summary_line": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings.get("player_feel_summary_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish": release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish,
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish_line": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish.get("player_feel_polish_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_surface_specs": Array(release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish.get("player_feel_surface_specs", [])).duplicate(true),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice": release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice,
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice_line": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice.get("round_loop_acceptance_line", "")),
		"release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice_status": String(release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_stitch": release_first_decision_loop_two_player_loop_scenario_stitch,
		"release_first_decision_loop_two_player_loop_scenario_stitch_line": String(release_first_decision_loop_two_player_loop_scenario_stitch.get("scenario_stitch_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_stitch_status": String(release_first_decision_loop_two_player_loop_scenario_stitch.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_runtime_hook": release_first_decision_loop_two_player_loop_scenario_runtime_hook,
		"release_first_decision_loop_two_player_loop_scenario_runtime_hook_line": String(release_first_decision_loop_two_player_loop_scenario_runtime_hook.get("mission_control_runtime_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_runtime_hook_status": String(release_first_decision_loop_two_player_loop_scenario_runtime_hook.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_runtime_smoke": release_first_decision_loop_two_player_loop_scenario_runtime_smoke,
		"release_first_decision_loop_two_player_loop_scenario_runtime_smoke_line": String(release_first_decision_loop_two_player_loop_scenario_runtime_smoke.get("smoke_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_runtime_smoke_status": String(release_first_decision_loop_two_player_loop_scenario_runtime_smoke.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_player_feel_findings": release_first_decision_loop_two_player_loop_scenario_player_feel_findings,
		"release_first_decision_loop_two_player_loop_scenario_player_feel_findings_status": String(release_first_decision_loop_two_player_loop_scenario_player_feel_findings.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_player_feel_findings_issue_count": int(release_first_decision_loop_two_player_loop_scenario_player_feel_findings.get("issue_count", 0)),
		"release_first_decision_loop_two_player_loop_scenario_player_feel_findings_summary_line": String(release_first_decision_loop_two_player_loop_scenario_player_feel_findings.get("scenario_player_feel_summary_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_player_feel_polish": release_first_decision_loop_two_player_loop_scenario_player_feel_polish,
		"release_first_decision_loop_two_player_loop_scenario_player_feel_polish_line": String(release_first_decision_loop_two_player_loop_scenario_player_feel_polish.get("scenario_player_feel_polish_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_player_feel_surface_specs": Array(release_first_decision_loop_two_player_loop_scenario_player_feel_polish.get("scenario_player_feel_surface_specs", [])).duplicate(true),
		"release_first_decision_loop_two_player_loop_scenario_player_feel_polish_status": String(release_first_decision_loop_two_player_loop_scenario_player_feel_polish.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_playability_slice": release_first_decision_loop_two_player_loop_scenario_playability_slice,
		"release_first_decision_loop_two_player_loop_scenario_playability_slice_line": String(release_first_decision_loop_two_player_loop_scenario_playability_slice.get("scenario_playability_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_playability_slice_status": String(release_first_decision_loop_two_player_loop_scenario_playability_slice.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_playability_slice_gate": String(release_first_decision_loop_two_player_loop_scenario_playability_slice.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_real_window_capture": release_first_decision_loop_two_player_loop_scenario_real_window_capture,
		"release_first_decision_loop_two_player_loop_scenario_real_window_capture_status": String(release_first_decision_loop_two_player_loop_scenario_real_window_capture.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_real_window_capture_gate": String(release_first_decision_loop_two_player_loop_scenario_real_window_capture.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_real_window_capture_window_screenshot_path": String(release_first_decision_loop_two_player_loop_scenario_real_window_capture.get("window_screenshot_path", "")),
		"release_first_decision_loop_two_player_loop_scenario_visual_findings": release_first_decision_loop_two_player_loop_scenario_visual_findings,
		"release_first_decision_loop_two_player_loop_scenario_visual_findings_status": String(release_first_decision_loop_two_player_loop_scenario_visual_findings.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_visual_findings_issue_count": int(release_first_decision_loop_two_player_loop_scenario_visual_findings.get("issue_count", 0)),
		"release_first_decision_loop_two_player_loop_scenario_acceptance_slice": release_first_decision_loop_two_player_loop_scenario_acceptance_slice,
		"release_first_decision_loop_two_player_loop_scenario_acceptance_slice_line": String(release_first_decision_loop_two_player_loop_scenario_acceptance_slice.get("scenario_acceptance_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_acceptance_slice_status": String(release_first_decision_loop_two_player_loop_scenario_acceptance_slice.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_integrated_playtest": release_first_decision_loop_two_player_loop_scenario_integrated_playtest,
		"release_first_decision_loop_two_player_loop_scenario_integrated_playtest_line": String(release_first_decision_loop_two_player_loop_scenario_integrated_playtest.get("integrated_playtest_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_integrated_playtest_status": String(release_first_decision_loop_two_player_loop_scenario_integrated_playtest.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_integrated_playtest_gate": String(release_first_decision_loop_two_player_loop_scenario_integrated_playtest.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings": release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings,
		"release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings_status": String(release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings_issue_count": int(release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings.get("issue_count", 0)),
		"release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings_summary_line": String(release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings.get("scenario_integrated_player_feel_summary_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice": release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice,
		"release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice_line": String(release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice.get("small_game_acceptance_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice_status": String(release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice_gate": String(release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest": release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest,
		"release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest_line": String(release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest.get("release_candidate_playtest_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest_status": String(release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest_gate": String(release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance": release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance,
		"release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance_line": String(release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance.get("release_candidate_acceptance_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance_status": String(release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance_gate": String(release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_ship_readiness_review": release_first_decision_loop_two_player_loop_scenario_ship_readiness_review,
		"release_first_decision_loop_two_player_loop_scenario_ship_readiness_review_line": String(release_first_decision_loop_two_player_loop_scenario_ship_readiness_review.get("ship_readiness_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_ship_readiness_review_status": String(release_first_decision_loop_two_player_loop_scenario_ship_readiness_review.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_ship_readiness_review_gate": String(release_first_decision_loop_two_player_loop_scenario_ship_readiness_review.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke": release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke,
		"release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke_line": String(release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke.get("visible_ship_smoke_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke_status": String(release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke_gate": String(release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_delivery_review": release_first_decision_loop_two_player_loop_scenario_delivery_review,
		"release_first_decision_loop_two_player_loop_scenario_delivery_review_line": String(release_first_decision_loop_two_player_loop_scenario_delivery_review.get("delivery_review_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_delivery_review_status": String(release_first_decision_loop_two_player_loop_scenario_delivery_review.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_delivery_review_gate": String(release_first_decision_loop_two_player_loop_scenario_delivery_review.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_handoff_packet": release_first_decision_loop_two_player_loop_scenario_handoff_packet,
		"release_first_decision_loop_two_player_loop_scenario_handoff_packet_line": String(release_first_decision_loop_two_player_loop_scenario_handoff_packet.get("handoff_packet_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_handoff_packet_status": String(release_first_decision_loop_two_player_loop_scenario_handoff_packet.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_handoff_packet_gate": String(release_first_decision_loop_two_player_loop_scenario_handoff_packet.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_tester_run": release_first_decision_loop_two_player_loop_scenario_tester_run,
		"release_first_decision_loop_two_player_loop_scenario_tester_run_line": String(release_first_decision_loop_two_player_loop_scenario_tester_run.get("tester_run_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_tester_run_status": String(release_first_decision_loop_two_player_loop_scenario_tester_run.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_tester_run_gate": String(release_first_decision_loop_two_player_loop_scenario_tester_run.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance": release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance,
		"release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance_line": String(release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.get("acceptance_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance_status": String(release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance_gate": String(release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan": release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan,
		"release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan_line": String(release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.get("next_slice_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan_status": String(release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan_gate": String(release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook": release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook,
		"release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook_line": String(release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.get("first_contact_runtime_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook_status": String(release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook_gate": String(release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke": release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke,
		"release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke_line": String(release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke.get("first_contact_runtime_smoke_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke_status": String(release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke_gate": String(release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings": release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings,
		"release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings_status": String(release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings_issue_count": int(release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings.get("issue_count", 0)),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings_summary_line": String(release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings.get("first_contact_player_feel_summary_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish": release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish,
		"release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish_line": String(release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish.get("first_contact_player_feel_polish_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_surface_specs": Array(release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish.get("first_contact_player_feel_surface_specs", [])).duplicate(true),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish_status": String(release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice": release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice,
		"release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice_line": String(release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice.get("first_contact_playability_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice_status": String(release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice_gate": String(release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture": release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture,
		"release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture_status": String(release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture_gate": String(release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture_window_screenshot_path": String(release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.get("window_screenshot_path", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings": release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings,
		"release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings_status": String(release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings_issue_count": int(release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings.get("issue_count", 0)),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings_summary_line": String(release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings.get("first_contact_visual_findings_summary_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish": release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish,
		"release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish_line": String(release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish.get("first_contact_visual_polish_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_visual_surface_specs": Array(release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish.get("first_contact_visual_surface_specs", [])).duplicate(true),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish_status": String(release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice": release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice,
		"release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice_line": String(release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice.get("first_contact_acceptance_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice_status": String(release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice_gate": String(release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice.get("gate", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest": release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest,
		"release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_line": String(release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest.get("integrated_playtest_line", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_status": String(release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest.get("status", "")),
		"release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_gate": String(release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest.get("gate", "")),
		"frontier_probe_playfeel_next_interaction": frontier_probe_next_interaction,
		"frontier_probe_next_interaction_line": String(frontier_probe_next_interaction.get("next_interaction_line", "")),
		"frontier_probe_debrief_handoff_feel": frontier_probe_debrief_handoff,
		"frontier_probe_debrief_handoff_line": String(frontier_probe_debrief_handoff.get("handoff_line", "")),
		"station_scenario_debrief_handoff_cue": station_scenario_debrief_handoff_cue,
		"station_scenario_debrief_handoff_line": String(station_scenario_debrief_handoff_cue.get("handoff_line", "")),
		"station_scenario_debrief_handoff_ready": bool(station_scenario_debrief_handoff_cue.get("handoff_ready", false)),
		"mission_interaction_use_feedback": mission_interaction_use_feedback,
		"mission_interaction_use_feedback_line": String(mission_interaction_use_feedback.get("feedback_line", "")),
		"mission_interaction_use_feedback_action": String(mission_interaction_use_feedback.get("action_label", "")),
		"mission_interaction_progress_readability": mission_interaction_progress_readability,
		"mission_interaction_progress_line": String(mission_interaction_progress_readability.get("display_line", "")),
		"mission_interaction_progress_line_within_limit": bool(mission_interaction_progress_readability.get("line_within_limit", false)),
		"mission_interaction_use_intent": mission_interaction_use_intent,
		"mission_interaction_use_intent_accepted": bool(mission_interaction_use_intent.get("accepted", false)),
		"mission_interaction_use_intent_command_type": String(mission_interaction_use_intent.get("command_type", "")),
		"mission_interaction_door_use_breach_command_hook": mission_interaction_door_use_breach_hook,
		"mission_interaction_door_use_breach_command_hook_accepted": bool(mission_interaction_door_use_breach_hook.get("accepted", false)),
		"mission_interaction_door_use_breach_command_hook_line": String(mission_interaction_door_use_breach_hook.get("last_command_text", "")),
		"mission_interaction_door_multiplayer_authority": mission_interaction_door_multiplayer_authority,
		"mission_interaction_door_multiplayer_authority_gate": String(mission_interaction_door_multiplayer_authority.get("gate", "")),
		"mission_interaction_door_multiplayer_authority_summary": String(mission_interaction_door_multiplayer_authority.get("summary", "")),
		"mission_interaction_door_authority_ui_feedback": mission_interaction_door_authority_ui_feedback,
		"mission_interaction_door_authority_ui_status": String(mission_interaction_door_authority_ui_feedback.get("status", "")),
		"mission_interaction_door_authority_ui_line": String(mission_interaction_door_authority_ui_feedback.get("summary_line", "")),
		"mission_interaction_door_authority_ui_compact_line": String(mission_interaction_door_authority_ui_feedback.get("compact_line", "")),
		"mission_interaction_door_authority_visible_line": _build_visible_door_authority_command_line(),
		"mission_interaction_door_authority_ui_player_hint": String(mission_interaction_door_authority_ui_feedback.get("player_hint", "")),
		"mission_interaction_door_authority_ui_next_action": String(mission_interaction_door_authority_ui_feedback.get("next_action", "")),
		"mission_interaction_door_authority_ui_severity": String(mission_interaction_door_authority_ui_feedback.get("severity", "")),
		"mission_interaction_door_authority_ui_reject_reason_label": String(mission_interaction_door_authority_ui_feedback.get("reject_reason_label", "")),
		"mission_interaction_door_authority_ui_tooltip": String(mission_interaction_door_authority_ui_feedback.get("tooltip_text", "")),
		"mission_interaction_multiplayer_door_feedback_capture": mission_interaction_multiplayer_door_feedback_capture,
		"mission_interaction_multiplayer_door_feedback_capture_gate": String(mission_interaction_multiplayer_door_feedback_capture.get("gate", "")),
		"mission_interaction_multiplayer_door_feedback_capture_summary": String(mission_interaction_multiplayer_door_feedback_capture.get("summary", "")),
		"mission_interaction_objective_gate": mission_interaction_objective_gate,
		"mission_interaction_objective_next_line": String(mission_interaction_objective_gate.get("next_line", "")),
		"mission_interaction_objective_next_step_id": String(mission_interaction_objective_gate.get("next_step_id", "")),
		"mission_interaction_visual_state": mission_interaction_visual_state,
		"mission_interaction_visual_state_count": int(mission_interaction_visual_state.get("visual_state_count", 0)),
		"mission_interaction_visual_state_summary": String(mission_interaction_visual_state.get("summary", "")),
		"mission_interaction_object_reaction": mission_interaction_object_reaction,
		"mission_interaction_object_reaction_count": int(mission_interaction_object_reaction.get("object_reaction_count", 0)),
		"mission_interaction_object_reaction_summary": String(mission_interaction_object_reaction.get("summary", "")),
		"station_route_run_readout": station_route_run_readout,
		"station_route_run_line": String(station_route_run_readout.get("compact_line", "")),
		"station_route_run_next_token": String(station_route_run_readout.get("next_token", "")),
		"station_route_run_line_within_limit": bool(station_route_run_readout.get("line_within_limit", false)),
		"station_scenario_route_cue_polish": station_scenario_route_cue_polish,
		"station_scenario_route_cue_line": String(station_scenario_route_cue_polish.get("cue_line", "")),
		"station_scenario_route_cue_detail": String(station_scenario_route_cue_polish.get("detail_line", "")),
		"station_scenario_route_cue_next_token": String(station_scenario_route_cue_polish.get("next_token", "")),
		"station_scenario_route_cue_line_within_limit": bool(station_scenario_route_cue_polish.get("line_within_limit", false)),
		"cover_effectiveness_readout": cover_effectiveness_readout,
		"cover_effectiveness_text": String(cover_effectiveness_readout.get("readout_text", "")),
		"enemy_limbo_behavior": get_enemy_limbo_behavior_snapshot(),
		"fireteam_orientation_count": get_fireteam_orientation_snapshot().size(),
		"fireteam_orientations": get_fireteam_orientation_snapshot(),
		"active_area_defense": get_active_area_defense_snapshot(),
		"active_area_attack": get_active_area_attack_snapshot(),
		"fireteamleader_feedback_bubbles_enabled": fireteamleader_feedback_bubbles_enabled,
		"fireteamleader_feedback_bubble_count": get_fireteamleader_feedback_bubble_snapshot().size(),
		"fireteamleader_feedback_bubbles": get_fireteamleader_feedback_bubble_snapshot(),
		"tactical_communication_event_count": get_tactical_communication_event_snapshot().size(),
		"tactical_communication_events": get_tactical_communication_event_snapshot(),
		"tactical_event_log_count": tactical_event_log_display_entries.size(),
		"tactical_event_log_raw_count": tactical_event_log_entries.size(),
		"tactical_event_log": tactical_event_log_display_entries,
		"release_firefight_event_log_display": release_firefight_event_log_display,
		"release_firefight_event_log_fallback_active": bool(release_firefight_event_log_display.get("fallback_active", false)),
		"release_firefight_event_log_style_id": String(release_firefight_event_log_display.get("style_id", "")),
		"tactical_event_log_contract": get_tactical_event_log_contract_snapshot(),
		"ftl_readiness_count": get_ftl_readiness_snapshot().size(),
		"ftl_readiness": get_ftl_readiness_snapshot(),
		"ftl_readiness_contract": get_ftl_readiness_contract_snapshot(),
		"fireteam_status_card_count": get_fireteam_status_card_snapshot().size(),
		"fireteam_status_cards": get_fireteam_status_card_snapshot(),
		"fireteam_member_status_row_count": get_fireteam_member_status_row_snapshot().size(),
		"fireteam_member_status_rows": get_fireteam_member_status_row_snapshot(),
		"tactical_breakout_count": get_tactical_breakout_snapshot().size(),
		"tactical_breakouts": get_tactical_breakout_snapshot(),
		"fireteam_coordination_count": get_fireteam_coordination_snapshot().size(),
		"fireteam_coordination": get_fireteam_coordination_snapshot(),
		"air_asset_status": get_air_asset_status_snapshot(),
		"air_asset_threat_count": get_air_asset_threat_snapshot().size(),
		"air_asset_threats": get_air_asset_threat_snapshot(),
		"selected_tactical_communication_text": _build_selected_tactical_communication_text(),
		"mission_control_tactical_communication_text": _build_mission_control_tactical_communication_text(),
		"npc_thought_bubble_count": get_npc_thought_bubble_snapshot().size(),
		"npc_thought_bubbles": get_npc_thought_bubble_snapshot(),
	}
	return _build_release_first_exchange_real_window_hud_source_synced_feedback_snapshot(command_feedback_snapshot)
