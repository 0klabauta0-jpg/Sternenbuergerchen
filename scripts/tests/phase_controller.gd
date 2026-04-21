class_name PhaseController
extends Node

const PHASE_STATE_SCRIPT: GDScript = preload("res://scripts/command/phase_state.gd")
const PREMISSION_PHASE_INDEX: int = 0
const FIRST_INTERACTIVE_PHASE_INDEX: int = 1
const MINIMUM_PHASE_COUNT: int = 2

var _phase_states: Array = []
var _active_phase_index: int = PREMISSION_PHASE_INDEX
var _selected_phase_index: int = FIRST_INTERACTIVE_PHASE_INDEX
var _tick_counter: int = 0


func _ready() -> void:
	_ensure_default_state()


func reset_to_defaults() -> void:
	_phase_states.clear()
	_active_phase_index = PREMISSION_PHASE_INDEX
	_selected_phase_index = FIRST_INTERACTIVE_PHASE_INDEX
	_tick_counter = 0
	ensure_phase_count(MINIMUM_PHASE_COUNT)
	_sync_phase_states()


func load_from_planning_state(planning_state: Dictionary, max_plan_phase: int = -1, legacy_mode: bool = false) -> void:
	reset_to_defaults()

	if planning_state.has("phase_states"):
		_phase_states.clear()
		for phase_variant in Array(planning_state.get("phase_states", [])):
			if typeof(phase_variant) != TYPE_DICTIONARY:
				continue
			var phase_state = PHASE_STATE_SCRIPT.call("from_dict", Dictionary(phase_variant))
			if phase_state == null or not phase_state.is_valid():
				continue
			ensure_phase_count(int(phase_state.phase_index) + 1)
			_phase_states[int(phase_state.phase_index)] = phase_state
	elif planning_state.has("phase_count"):
		ensure_phase_count(int(planning_state.get("phase_count", MINIMUM_PHASE_COUNT)))

	if max_plan_phase >= 0:
		ensure_phase_count(maxi(max_plan_phase + 1, MINIMUM_PHASE_COUNT))

	if planning_state.has("active_phase_index"):
		_active_phase_index = maxi(int(planning_state.get("active_phase_index", PREMISSION_PHASE_INDEX)), PREMISSION_PHASE_INDEX)

	if planning_state.has("selected_phase_index"):
		_selected_phase_index = maxi(int(planning_state.get("selected_phase_index", FIRST_INTERACTIVE_PHASE_INDEX)), FIRST_INTERACTIVE_PHASE_INDEX)
	elif legacy_mode and planning_state.has("selected_phase"):
		_selected_phase_index = _parse_legacy_selected_phase(String(planning_state.get("selected_phase", "")))

	_active_phase_index = mini(_active_phase_index, max(FIRST_INTERACTIVE_PHASE_INDEX, _phase_states.size() - 1))
	_selected_phase_index = clampi(_selected_phase_index, FIRST_INTERACTIVE_PHASE_INDEX, max(FIRST_INTERACTIVE_PHASE_INDEX, _phase_states.size() - 1))
	_sync_phase_states()


func ensure_phase_count(required_count: int) -> void:
	var target_count: int = maxi(required_count, MINIMUM_PHASE_COUNT)
	while _phase_states.size() < target_count:
		_phase_states.append(_make_phase_state(_phase_states.size()))


func add_phase() -> int:
	ensure_phase_count(_phase_states.size() + 1)
	_sync_phase_states()
	return _phase_states.size() - 1


func cycle_selected_phase(delta: int) -> int:
	var interactive_count: int = maxi(_phase_states.size() - 1, 1)
	if interactive_count <= 1:
		return set_selected_phase_index(FIRST_INTERACTIVE_PHASE_INDEX)
	var wrapped_index: int = wrapi((_selected_phase_index - FIRST_INTERACTIVE_PHASE_INDEX) + delta, 0, interactive_count)
	return set_selected_phase_index(wrapped_index + FIRST_INTERACTIVE_PHASE_INDEX)


func set_selected_phase_index(index: int) -> int:
	_selected_phase_index = clampi(index, FIRST_INTERACTIVE_PHASE_INDEX, max(FIRST_INTERACTIVE_PHASE_INDEX, _phase_states.size() - 1))
	_sync_phase_states()
	return _selected_phase_index


func advance_to_next_phase() -> int:
	if _active_phase_index >= _phase_states.size() - 1:
		return -1
	_active_phase_index += 1
	_tick_counter += 1
	_sync_phase_states()
	return _active_phase_index


func get_active_phase_index() -> int:
	return _active_phase_index


func get_selected_phase_index() -> int:
	return _selected_phase_index


func get_phase_count() -> int:
	return _phase_states.size()


func get_selected_phase_name() -> String:
	return _get_phase_display_name(_selected_phase_index)


func get_active_phase_name() -> String:
	return _get_phase_display_name(_active_phase_index)


func get_phase_list_text() -> String:
	var labels: PackedStringArray = []
	for phase_index in range(_phase_states.size()):
		labels.append(_get_phase_display_name(phase_index))
	return " | ".join(labels)


func get_phase_states_snapshot() -> Array:
	var result: Array = []
	for phase_state in _phase_states:
		if phase_state == null:
			continue
		result.append(phase_state.to_dict())
	return result


func build_planning_state_fragment() -> Dictionary:
	return {
		"selected_phase": get_selected_phase_name(),
		"selected_phase_index": _selected_phase_index,
		"active_phase_index": _active_phase_index,
		"phase_count": _phase_states.size(),
		"phase_states": get_phase_states_snapshot(),
	}


func _ensure_default_state() -> void:
	if _phase_states.is_empty():
		reset_to_defaults()


func _make_phase_state(phase_index: int):
	var phase_state = PHASE_STATE_SCRIPT.new()
	phase_state.phase_index = phase_index
	phase_state.display_name = _get_phase_display_name(phase_index)
	phase_state.is_editable = phase_index >= FIRST_INTERACTIVE_PHASE_INDEX
	phase_state.metadata = {"is_premission": phase_index == PREMISSION_PHASE_INDEX}
	return phase_state


func _sync_phase_states() -> void:
	_ensure_default_state()
	for phase_index in range(_phase_states.size()):
		var phase_state = _phase_states[phase_index]
		if phase_state == null:
			phase_state = _make_phase_state(phase_index)
			_phase_states[phase_index] = phase_state
		phase_state.phase_index = phase_index
		phase_state.display_name = _get_phase_display_name(phase_index)
		phase_state.is_editable = phase_index >= FIRST_INTERACTIVE_PHASE_INDEX
		phase_state.metadata["is_premission"] = phase_index == PREMISSION_PHASE_INDEX
		if phase_index == _active_phase_index:
			phase_state.status = PHASE_STATE_SCRIPT.STATUS_ACTIVE
			if phase_state.started_tick < 0:
				phase_state.started_tick = _tick_counter
			phase_state.completed_tick = -1
		elif phase_index < _active_phase_index:
			phase_state.status = PHASE_STATE_SCRIPT.STATUS_COMPLETED
			if phase_state.started_tick < 0:
				phase_state.started_tick = phase_index
			phase_state.completed_tick = maxi(phase_state.completed_tick, _tick_counter)
		else:
			phase_state.status = PHASE_STATE_SCRIPT.STATUS_PENDING
			phase_state.completed_tick = -1


func _get_phase_display_name(phase_index: int) -> String:
	if phase_index == PREMISSION_PHASE_INDEX:
		return "P0 PRE"
	return "P%d" % phase_index


func _parse_legacy_selected_phase(phase_name: String) -> int:
	var normalized_name: String = phase_name.strip_edges().to_upper()
	match normalized_name:
		"APPROACH":
			return 1
		"ASSAULT":
			return 2
		"HOLD":
			return 3
		_:
			if normalized_name.begins_with("P"):
				return maxi(int(normalized_name.substr(1)), FIRST_INTERACTIVE_PHASE_INDEX)
	return FIRST_INTERACTIVE_PHASE_INDEX