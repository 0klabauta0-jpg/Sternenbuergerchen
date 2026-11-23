class_name MissionScenarioRuntimeGates
extends RefCounted

const VERTICAL_SLICE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_vertical_slice_contract.gd")

const STATUS_PENDING: String = "pending"
const STATUS_ACTIVE: String = "active"
const STATUS_BLOCKED: String = "blocked"
const STATUS_COMPLETE: String = "complete"

const OBJECTIVE_TYPE_AIR_DEFENSE_SHUTDOWN: String = "air_defense_shutdown"
const OBJECTIVE_TYPE_COMPUTER_HOLD: String = "computer_hold"
const OBJECTIVE_TYPE_CARGO_TOUCHDOWN_EXTRACT: String = "cargo_touchdown_extract"

var _slice: Dictionary = {}
var _steps: Array = []
var _completed_step_ids: Dictionary = {}
var _hold_started_msec_by_step_id: Dictionary = {}
var _last_snapshot: Dictionary = {}


func configure_from_slice(slice: Dictionary) -> void:
	_slice = VERTICAL_SLICE_CONTRACT_SCRIPT.call("normalize_slice", slice)
	_steps = Array(_slice.get("flow_steps", [])).duplicate(true)
	_completed_step_ids.clear()
	_hold_started_msec_by_step_id.clear()
	_last_snapshot = _build_empty_snapshot()


func configure_from_file(path: String) -> void:
	configure_from_slice(Dictionary(VERTICAL_SLICE_CONTRACT_SCRIPT.call("load_slice_from_file", path)))


func is_configured() -> bool:
	return not _steps.is_empty()


func reset_runtime_state() -> void:
	_completed_step_ids.clear()
	_hold_started_msec_by_step_id.clear()
	_last_snapshot = _build_empty_snapshot()


func update(context: Dictionary) -> Dictionary:
	if not is_configured():
		_last_snapshot = _build_empty_snapshot()
		return get_snapshot()

	var now_msec: int = maxi(int(context.get("now_msec", Time.get_ticks_msec())), 0)
	_apply_completed_step_overrides(context)

	var gate_entries: Array = []
	for step_variant in _steps:
		var step: Dictionary = Dictionary(step_variant)
		var gate: Dictionary = _evaluate_step(step, context, now_msec)
		if String(gate.get("status", "")) == STATUS_COMPLETE:
			_completed_step_ids[String(step.get("step_id", ""))] = true
		gate_entries.append(gate)

	_last_snapshot = {
		"configured": true,
		"runtime_authority": "MissionScenarioRuntimeGates",
		"ui_sets_gameplay_truth": false,
		"all_gates_complete": _are_all_gate_entries_complete(gate_entries),
		"completed_step_ids": _sorted_completed_step_ids(),
		"gates": gate_entries,
		"countdown": _build_primary_countdown(gate_entries),
	}
	return get_snapshot()


func get_snapshot() -> Dictionary:
	return _last_snapshot.duplicate(true)


func are_all_gates_complete() -> bool:
	return bool(_last_snapshot.get("all_gates_complete", false))


func build_countdown_source() -> Dictionary:
	return Dictionary(_last_snapshot.get("countdown", {})).duplicate(true)


func _evaluate_step(step: Dictionary, context: Dictionary, now_msec: int) -> Dictionary:
	var step_id: String = String(step.get("step_id", "")).strip_edges()
	var blocked_by: String = _get_blocking_requirement(step)
	if not blocked_by.is_empty():
		return _build_gate_entry(step, STATUS_BLOCKED, 0.0, 0.0, float(step.get("min_hold_seconds", 0.0)), blocked_by)

	var manual_state: String = _get_manual_step_state(context, step_id)
	if _state_satisfies_required_state(manual_state, String(step.get("required_state", ""))):
		return _build_gate_entry(step, STATUS_COMPLETE, 1.0, float(step.get("min_hold_seconds", 0.0)), float(step.get("min_hold_seconds", 0.0)), "")

	match String(step.get("objective_type", "")).strip_edges():
		OBJECTIVE_TYPE_AIR_DEFENSE_SHUTDOWN:
			return _evaluate_air_defense_step(step, context)
		OBJECTIVE_TYPE_COMPUTER_HOLD:
			return _evaluate_computer_hold_step(step, context, now_msec)
		OBJECTIVE_TYPE_CARGO_TOUCHDOWN_EXTRACT:
			return _evaluate_cargo_step(step, context)
		_:
			return _build_gate_entry(step, STATUS_PENDING, 0.0, 0.0, float(step.get("min_hold_seconds", 0.0)), "")


func _evaluate_air_defense_step(step: Dictionary, context: Dictionary) -> Dictionary:
	var step_id: String = String(step.get("step_id", "")).strip_edges()
	if bool(_completed_step_ids.get(step_id, false)):
		return _build_gate_entry(step, STATUS_COMPLETE, 1.0, 0.0, 0.0, "")
	var enemy_group_id: String = String(step.get("enemy_group_id", "")).strip_edges()
	var group_fit_counts: Dictionary = Dictionary(context.get("enemy_group_fit_counts", {}))
	# Zusatz: enemy_group_ids (Liste) - erledigt erst, wenn JEDE genannte Gruppe bekannt und ohne kampffaehige Wache ist.
	# Ohne die Liste gilt unveraendert nur enemy_group_id.
	var group_ids: Array = []
	for list_variant in Array(step.get("enemy_group_ids", [])):
		var list_id: String = String(list_variant).strip_edges()
		if not list_id.is_empty() and not group_ids.has(list_id):
			group_ids.append(list_id)
	if not group_ids.is_empty():
		if not enemy_group_id.is_empty() and not group_ids.has(enemy_group_id):
			group_ids.append(enemy_group_id)
		var all_down: bool = true
		for group_id in group_ids:
			if not group_fit_counts.has(group_id) or int(group_fit_counts.get(group_id, 0)) > 0:
				all_down = false
		if all_down:
			return _build_gate_entry(step, STATUS_COMPLETE, 1.0, 0.0, 0.0, "")
	elif not enemy_group_id.is_empty() and group_fit_counts.has(enemy_group_id):
		if int(group_fit_counts.get(enemy_group_id, 0)) <= 0:
			return _build_gate_entry(step, STATUS_COMPLETE, 1.0, 0.0, 0.0, "")
	return _build_gate_entry(step, STATUS_ACTIVE, 0.0, 0.0, 0.0, "")


func _evaluate_computer_hold_step(step: Dictionary, context: Dictionary, now_msec: int) -> Dictionary:
	var step_id: String = String(step.get("step_id", "")).strip_edges()
	var hold_seconds: float = maxf(float(step.get("min_hold_seconds", 0.0)), 0.0)
	if bool(_completed_step_ids.get(step_id, false)):
		return _build_gate_entry(step, STATUS_COMPLETE, 1.0, hold_seconds, hold_seconds, "")

	var objective_status = context.get("objective_status", null)
	var required_team_id: String = String(step.get("operator_team_id", context.get("friendly_team_id", ""))).strip_edges()
	var owner_id: String = _get_objective_owner_id(objective_status)
	var is_held_by_required_team: bool = not required_team_id.is_empty() and owner_id == required_team_id
	if not is_held_by_required_team:
		_hold_started_msec_by_step_id.erase(step_id)
		return _build_gate_entry(step, STATUS_PENDING, 0.0, 0.0, hold_seconds, "")

	if not _hold_started_msec_by_step_id.has(step_id):
		_hold_started_msec_by_step_id[step_id] = now_msec
	var hold_elapsed: float = maxf(float(now_msec - int(_hold_started_msec_by_step_id.get(step_id, now_msec))) / 1000.0, 0.0)
	var progress: float = 1.0 if hold_seconds <= 0.0 else clampf(hold_elapsed / hold_seconds, 0.0, 1.0)
	if progress >= 1.0:
		return _build_gate_entry(step, STATUS_COMPLETE, 1.0, hold_seconds, hold_seconds, "")
	return _build_gate_entry(step, STATUS_ACTIVE, progress, hold_elapsed, hold_seconds, "")


func _evaluate_cargo_step(step: Dictionary, context: Dictionary) -> Dictionary:
	var step_id: String = String(step.get("step_id", "")).strip_edges()
	if bool(_completed_step_ids.get(step_id, false)):
		var hold_seconds: float = maxf(float(step.get("min_hold_seconds", 0.0)), 0.0)
		return _build_gate_entry(step, STATUS_COMPLETE, 1.0, hold_seconds, hold_seconds, "")

	var cargo_state: String = String(context.get("cargo_state", "")).strip_edges().to_lower()
	if ["cargo_departed", "departed", "extracted", "complete"].has(cargo_state):
		var complete_hold: float = maxf(float(step.get("min_hold_seconds", 0.0)), 0.0)
		return _build_gate_entry(step, STATUS_COMPLETE, 1.0, complete_hold, complete_hold, "")

	var cargo_hold_seconds: float = maxf(float(context.get("cargo_hold_seconds", 0.0)), 0.0)
	var required_hold_seconds: float = maxf(float(step.get("min_hold_seconds", 0.0)), 0.0)
	var progress: float = 0.0 if required_hold_seconds <= 0.0 else clampf(cargo_hold_seconds / required_hold_seconds, 0.0, 1.0)
	var status: String = STATUS_ACTIVE if cargo_state == "landed" or cargo_state == "touchdown" or cargo_hold_seconds > 0.0 else STATUS_PENDING
	return _build_gate_entry(step, status, progress, cargo_hold_seconds, required_hold_seconds, "")


func _build_gate_entry(step: Dictionary, status: String, progress: float, hold_elapsed_seconds: float, hold_required_seconds: float, blocked_by_step_id: String) -> Dictionary:
	return {
		"step_id": String(step.get("step_id", "")).strip_edges(),
		"objective_type": String(step.get("objective_type", "")).strip_edges(),
		"target_marker_id": String(step.get("target_marker_id", "")).strip_edges(),
		"required_state": String(step.get("required_state", "")).strip_edges(),
		"status": status,
		"complete": status == STATUS_COMPLETE,
		"progress": clampf(progress, 0.0, 1.0),
		"hold_elapsed_seconds": maxf(hold_elapsed_seconds, 0.0),
		"hold_required_seconds": maxf(hold_required_seconds, 0.0),
		"blocked_by_step_id": blocked_by_step_id.strip_edges(),
		"enemy_group_id": String(step.get("enemy_group_id", "")).strip_edges(),
		"operator_team_id": String(step.get("operator_team_id", "")).strip_edges(),
		"requires_step_id": String(step.get("requires_step_id", "")).strip_edges(),
	}


func _apply_completed_step_overrides(context: Dictionary) -> void:
	for step_id_variant in Array(context.get("completed_step_ids", [])):
		var step_id: String = String(step_id_variant).strip_edges()
		if not step_id.is_empty():
			_completed_step_ids[step_id] = true
	var step_states: Dictionary = Dictionary(context.get("step_states", {}))
	for step_id_variant in step_states.keys():
		var step_id: String = String(step_id_variant).strip_edges()
		var state: String = String(step_states.get(step_id_variant, "")).strip_edges()
		var step: Dictionary = _get_step_by_id(step_id)
		if not step.is_empty() and _state_satisfies_required_state(state, String(step.get("required_state", ""))):
			_completed_step_ids[step_id] = true


func _get_blocking_requirement(step: Dictionary) -> String:
	var required_step_id: String = String(step.get("requires_step_id", "")).strip_edges()
	if required_step_id.is_empty():
		return ""
	return "" if bool(_completed_step_ids.get(required_step_id, false)) else required_step_id


func _get_step_by_id(step_id: String) -> Dictionary:
	var normalized_step_id: String = step_id.strip_edges()
	for step_variant in _steps:
		var step: Dictionary = Dictionary(step_variant)
		if String(step.get("step_id", "")).strip_edges() == normalized_step_id:
			return step
	return {}


func _get_manual_step_state(context: Dictionary, step_id: String) -> String:
	var step_states: Dictionary = Dictionary(context.get("step_states", {}))
	return String(step_states.get(step_id, "")).strip_edges()


func _state_satisfies_required_state(state: String, required_state: String) -> bool:
	var normalized_state: String = state.strip_edges().to_lower()
	var normalized_required: String = required_state.strip_edges().to_lower()
	if normalized_state.is_empty():
		return false
	return normalized_state == normalized_required or normalized_state == STATUS_COMPLETE or normalized_state == "completed"


func _get_objective_owner_id(objective_status) -> String:
	if objective_status == null:
		return ""
	if typeof(objective_status) == TYPE_DICTIONARY:
		return String(Dictionary(objective_status).get("owning_team_id", "")).strip_edges()
	if objective_status.get("owning_team_id") != null:
		return String(objective_status.get("owning_team_id")).strip_edges()
	return ""


func _are_all_gate_entries_complete(gate_entries: Array) -> bool:
	if gate_entries.is_empty():
		return false
	for gate_variant in gate_entries:
		if not bool(Dictionary(gate_variant).get("complete", false)):
			return false
	return true


func _build_primary_countdown(gate_entries: Array) -> Dictionary:
	for gate_variant in gate_entries:
		var gate: Dictionary = Dictionary(gate_variant)
		if String(gate.get("objective_type", "")) != OBJECTIVE_TYPE_COMPUTER_HOLD:
			continue
		var status: String = String(gate.get("status", ""))
		if status != STATUS_ACTIVE and status != STATUS_PENDING:
			continue
		var required_seconds: float = maxf(float(gate.get("hold_required_seconds", 0.0)), 0.0)
		if required_seconds <= 0.0:
			continue
		var elapsed_seconds: float = maxf(float(gate.get("hold_elapsed_seconds", 0.0)), 0.0)
		return {
			"countdown_seconds": maxf(required_seconds - elapsed_seconds, 0.0),
			"countdown_total_seconds": required_seconds,
			"timer_state": "active" if status == STATUS_ACTIVE else "paused",
			"timer_source": "scenario_computer_hold",
			"timer_label": "COM",
		}
	return {}


func _sorted_completed_step_ids() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for step_id_variant in _completed_step_ids.keys():
		result.append(String(step_id_variant))
	result.sort()
	return result


func _build_empty_snapshot() -> Dictionary:
	return {
		"configured": false,
		"runtime_authority": "MissionScenarioRuntimeGates",
		"ui_sets_gameplay_truth": false,
		"all_gates_complete": false,
		"completed_step_ids": PackedStringArray(),
		"gates": [],
		"countdown": {},
	}
