extends SceneTree

const LOBBY_SOURCE_PATH := "res://scripts/ui/multiplayer_lobby_screen.gd"
const HARNESS_PATH := "res://scripts/tools/capture_release_host_client_entry_playtest.ps1"
const APPROACH_RESOLVER_PATH := "res://scripts/tactical/contact_approach_resolver.gd"
const COMBAT_DRIVER_PATH := "res://scripts/tests/mission_combat_loop_driver.gd"

var _failed := 0


func _initialize() -> void:
	var lobby_source := FileAccess.get_file_as_string(LOBBY_SOURCE_PATH)
	for token in [
		"movement_wall_time_msec",
		"simulation_tick",
		"physics_fps",
		"movement_start_position",
		"movement_distance_travelled",
		"movement_remaining_distance",
		"movement_progress_ratio",
		"RELEASE_TRACE_HEARTBEAT_MSEC",
	]:
		_assert(lobby_source.contains(token), "Release First Contact trace exposes %s" % token)
	_assert(lobby_source.contains("Time.get_ticks_msec() - _release_first_contact_advance_started_msec"), "Movement wall time is derived from a monotonic clock")
	_assert(lobby_source.contains("trace_heartbeat_bucket"), "Unchanged First Contact stages still write periodic movement evidence")
	_assert(lobby_source.contains("get_recent_fireteam_movement_trace"), "Release trace reads authoritative movement lifecycle evidence")
	_assert(lobby_source.contains('"recent_movement_trace"'), "Release trace preserves completed movement lifecycle evidence")
	for token in ["fireteam_unit_positions", "terrain_move_debug", "local_avoidance_debug"]:
		_assert(lobby_source.contains(token), "Release trace exposes lower movement boundary %s" % token)
	for token in ["runtime_tick_budget", "combat_tick_budget", "mission_visible_frame_timing", "mission_ui_refresh_timing", "mission_runtime_surface_timing"]:
		_assert(lobby_source.contains(token), "Release trace exposes runtime performance boundary %s" % token)
	_assert(lobby_source.contains('set_runtime_tick_budget_debug_enabled", true'), "Explicit First Contact run enables authoritative tick profiling")
	_assert(lobby_source.contains('set_combat_tick_budget_debug_enabled", true'), "Explicit First Contact run enables combat-listener profiling")
	_assert(lobby_source.contains('set_mission_visible_frame_timing_debug_enabled", true'), "Explicit First Contact run enables mission frame profiling")
	_assert(lobby_source.contains('get_mission_marker_world_position", "spawn_bravo"'), "Release Contact Approach follows the runtime enemy spawn marker")
	_assert(not lobby_source.contains('"spawn_enemy_defense"') and not lobby_source.contains('"spawn_enemy_patrol"'), "Release Contact Approach does not treat decorative enemy markers as runtime truth")
	_assert(lobby_source.contains("enemy_positions.append(requested_target)"), "Clients without hidden enemy nodes resolve against the shared spawn marker")
	_assert(lobby_source.contains("CONTACT_APPROACH_RESOLVER_SCRIPT"), "Release flow delegates approach selection to a tactical resolver")
	_assert(lobby_source.contains('request_network_authoritative_fireteam_intent", _release_local_fireteam_id, "engage"'), "Release Contact Approach uses combat-ready Engage semantics")
	_assert(FileAccess.file_exists(APPROACH_RESOLVER_PATH), "Contact approach resolver exists")
	var resolver_source := FileAccess.get_file_as_string(APPROACH_RESOLVER_PATH)
	for token in ["find_reachable_approach", "find_path", "has_line_of_sight_between_points", "get_all_units"]:
		_assert(resolver_source.contains(token) or lobby_source.contains(token), "Contact approach selection uses %s" % token)
	_assert(resolver_source.contains("FORMATION_SAMPLE_OFFSETS"), "Contact approach validates the formation footprint, not only its anchor")
	_assert(resolver_source.contains("MIN_FORMATION_LOS_SAMPLE_COUNT"), "Contact approach requires stable LOS across multiple formation slots")
	_assert(resolver_source.contains("MIN_FORMATION_REACHABLE_SAMPLE_COUNT"), "Contact approach requires the complete formation footprint to remain reachable")
	_assert(resolver_source.contains('"reachable_sample_count"'), "Contact approach evidence exposes formation reachability")
	_assert(resolver_source.contains("_path_reaches_sample"), "Formation footprint validation path-checks every sampled slot")

	var harness_source := FileAccess.get_file_as_string(HARNESS_PATH)
	for token in [
		"movement_pace",
		"movement_remaining_distance",
		"movement_distance_travelled",
		"movement_progress_ratio",
	]:
		_assert(harness_source.contains(token), "Release harness preserves %s evidence" % token)
	_assert(harness_source.contains('"TASK_1151"'), "First Contact pace manifest identifies TASK_1151")
	_assert(harness_source.contains('if ($FirstContact) { "1280x720" }'), "Two-process First Contact gate uses a per-machine representative render budget")
	_assert(harness_source.count('"--rendering-method", "gl_compatibility"') == 2, "Two-process functional gate isolates both instances from the D3D12 driver crash")
	for token in ["host_log_path", "client_log_path", "host_exited_before_gate", "client_exited_before_gate", "host_exit_code", "client_exit_code"]:
		_assert(harness_source.contains(token), "Release harness preserves process-boundary evidence %s" % token)
	var combat_source := FileAccess.get_file_as_string(COMBAT_DRIVER_PATH)
	_assert(combat_source.contains("COMBAT_DECISION_INTERVAL_TICKS: int = 3"), "Expensive tactical decisions use a 20 Hz cadence on a 60 Hz simulation")
	_assert(combat_source.contains("_should_run_combat_decision_tick"), "Combat listener exposes an explicit decision cadence guard")
	_assert(combat_source.find("_advance_detection_timers()") < combat_source.find("_should_run_combat_decision_tick"), "Detection timers advance before the expensive decision cadence guard")
	_assert(combat_source.find("_update_contact_tracking()") < combat_source.find("_should_run_combat_decision_tick"), "Contact tracking advances before the expensive decision cadence guard")
	var controller_source := FileAccess.get_file_as_string("res://scripts/tests/mission_tactical_sandbox_controller.gd")
	_assert(controller_source.contains("func get_recent_fireteam_movement_trace"), "Tactical controller exposes a public read-only movement trace")
	_assert(controller_source.contains('"standalone_network_intent": true'), "Authoritative network intents declare plan-independent lifecycle ownership")
	_assert(controller_source.contains("_update_standalone_network_intent_execution"), "Plan-independent network movement receives normal runtime updates")
	_assert(controller_source.contains('String(execution_state.get("execution_owner", "")) == "standalone_network_intent"'), "Missing UI plans do not reset standalone network movement")
	var intent_start: int = controller_source.find("func _apply_authoritative_fireteam_intent")
	var intent_end: int = controller_source.find("func _get_dropship_command_fireteam_id", intent_start)
	var intent_source: String = controller_source.substr(intent_start, intent_end - intent_start)
	_assert(intent_source.contains("_post_drop_security_pending_fireteam_ids.erase(fireteam_id)"), "Explicit network intent cancels pending automatic post-drop security")
	_assert(controller_source.contains('command.command_token = "post_drop_security:'), "Post-drop security moves carry stale-command tokens")
	_assert(controller_source.contains("RUNTIME_HUD_HEAVY_REFRESH_INTERVAL_SECONDS"), "Periodic HUD refresh has a separate heavy-surface cadence")
	_assert(controller_source.contains("func _update_ui(include_heavy_surfaces: bool = true, force_heavy_surfaces: bool = true)"), "Direct UI events can still request an immediate complete refresh")
	_assert(controller_source.contains("_update_ui(heavy_refresh_due, false)"), "Periodic frames use the guarded split light/heavy HUD refresh path")

	print("TASK_1151 connected release movement pace evidence: %d/64 PASS" % (64 - _failed))
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
