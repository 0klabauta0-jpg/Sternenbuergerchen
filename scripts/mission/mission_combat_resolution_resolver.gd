class_name MissionCombatResolutionResolver
extends RefCounted

const WIN_CONDITION_OBJECTIVE_CAPTURE: String = "objective_capture"
const WIN_CONDITION_OBJECTIVE_DEFENSE: String = "objective_defense"

const AUTHORITY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_authority_contract.gd")


func build_resolution_decision(context: Dictionary) -> Dictionary:
	if bool(context.get("combat_finished", false)):
		return {}

	var duration_seconds: float = maxf(float(context.get("duration_seconds", 0.0)), 0.0)
	var time_limit_seconds: float = maxf(float(context.get("mission_time_limit_seconds", 0.0)), 0.0)
	if time_limit_seconds > 0.0 and duration_seconds >= time_limit_seconds:
		return _build_decision("defeat", String(context.get("enemy_team_id", "")).strip_edges(), "time_limit")

	if bool(context.get("victory_condition_met", false)):
		return _build_decision("victory", String(context.get("friendly_team_id", "")).strip_edges())

	if int(context.get("friendly_fit_count", 0)) > 0:
		return {}

	if not bool(context.get("has_seen_active_friendly_units", false)):
		return {}

	if bool(context.get("has_pending_friendly_insertions", false)):
		return {}

	return _build_decision("defeat", String(context.get("enemy_team_id", "")).strip_edges())


func is_victory_condition_met(
	win_condition: String,
	objective_captured_by_friendly: bool,
	objective_defense_elapsed_seconds: float,
	objective_defense_hold_seconds: float,
	enemy_team_eliminated: bool
) -> bool:
	match win_condition.strip_edges():
		WIN_CONDITION_OBJECTIVE_CAPTURE:
			return objective_captured_by_friendly
		WIN_CONDITION_OBJECTIVE_DEFENSE:
			return objective_captured_by_friendly and maxf(objective_defense_elapsed_seconds, 0.0) >= maxf(objective_defense_hold_seconds, 0.0)
		_:
			return enemy_team_eliminated


func build_objective_countdown_source(
	win_condition: String,
	objective_defense_hold_seconds: float,
	objective_defense_elapsed_seconds: float,
	objective_captured_by_friendly: bool,
	mission_time_limit_seconds: float,
	remaining_time_limit_seconds: float
) -> Dictionary:
	if win_condition.strip_edges() == WIN_CONDITION_OBJECTIVE_DEFENSE and objective_defense_hold_seconds > 0.0:
		var hold_elapsed_seconds: float = maxf(objective_defense_elapsed_seconds, 0.0)
		var hold_remaining_seconds: float = maxf(objective_defense_hold_seconds - hold_elapsed_seconds, 0.0)
		return {
			"countdown_seconds": hold_remaining_seconds,
			"countdown_total_seconds": objective_defense_hold_seconds,
			"timer_state": "expired" if objective_captured_by_friendly and hold_remaining_seconds <= 0.0 else ("active" if objective_captured_by_friendly else "paused"),
			"timer_source": "objective_defense_hold",
			"timer_label": "HOLD",
		}
	if mission_time_limit_seconds > 0.0:
		var remaining_seconds: float = float(remaining_time_limit_seconds)
		if remaining_seconds < 0.0:
			return {
				"countdown_seconds": mission_time_limit_seconds,
				"countdown_total_seconds": mission_time_limit_seconds,
				"timer_state": "paused",
				"timer_source": "mission_time_limit",
				"timer_label": "TIME",
			}
		return {
			"countdown_seconds": remaining_seconds,
			"countdown_total_seconds": mission_time_limit_seconds,
			"timer_state": "expired" if remaining_seconds <= 0.0 else "active",
			"timer_source": "mission_time_limit",
			"timer_label": "TIME",
		}
	return {}


func build_mission_result(context: Dictionary) -> Dictionary:
	var mission_result: Dictionary = Dictionary(
		AUTHORITY_CONTRACT_SCRIPT.call(
			"build_mission_result",
			String(context.get("result", "")).strip_edges(),
			String(context.get("winning_team_id", "")).strip_edges(),
			String(context.get("friendly_team_id", "")).strip_edges(),
			String(context.get("win_condition_type", "")).strip_edges(),
			bool(context.get("objective_captured", false)),
			maxf(float(context.get("duration_seconds", 0.0)), 0.0),
			Array(context.get("team_states", [])).duplicate(true)
		)
	)
	mission_result["fireteam_tactical_debrief"] = Array(context.get("fireteam_tactical_debrief", [])).duplicate(true)
	return mission_result


func _build_decision(result: String, winning_team_id: String, result_condition_override: String = "") -> Dictionary:
	return {
		"resolved": true,
		"result": result.strip_edges().to_lower(),
		"winning_team_id": winning_team_id.strip_edges(),
		"result_condition_override": result_condition_override.strip_edges(),
	}
