class_name HexDetectionState
extends RefCounted

## One episode per ordered observer/target pair. No geometry, RNG or contact publication.
const MAX_TICK := 9223372036854775807
var _episodes: Dictionary = {}
var _latest_tick := -1


func observe_pair(observer_id: String, target_id: String, visible: bool,
		now_tick: int, delay_ticks: int) -> Dictionary:
	if observer_id.is_empty() or target_id.is_empty():
		return _invalid("invalid_unit_id")
	if now_tick < 0 or delay_ticks < 0 or now_tick > MAX_TICK - delay_ticks:
		return _invalid("invalid_timing")
	if now_tick < _latest_tick:
		return _invalid("stale_tick")
	_latest_tick = now_tick
	var targets: Dictionary = _episodes.get(observer_id, {})
	if not visible:
		var was_present: bool = targets.has(target_id)
		targets.erase(target_id)
		if targets.is_empty():
			_episodes.erase(observer_id)
		return {"ok":true,"episode_started":false,"ready_tick":-1,
			"detection_complete":false,"lost":was_present}
	var started: bool = not targets.has(target_id)
	if started:
		targets[target_id] = now_tick + delay_ticks
		_episodes[observer_id] = targets
	var ready_tick: int = targets[target_id]
	return {"ok":true,"episode_started":started,"ready_tick":ready_tick,
		"detection_complete":now_tick >= ready_tick,"lost":false}


func forget_unit(unit_id: String) -> void:
	_episodes.erase(unit_id)
	for observer_id in _episodes.keys():
		var targets: Dictionary = _episodes[observer_id]
		targets.erase(unit_id)
		if targets.is_empty():
			_episodes.erase(observer_id)


func read_pair(observer_id: String, target_id: String, now_tick: int) -> Dictionary:
	if now_tick < 0 or now_tick < _latest_tick:
		return {}
	var targets: Dictionary = _episodes.get(observer_id,{})
	if not targets.has(target_id):
		return {}
	var ready_tick: int = targets[target_id]
	return {"ready_tick":ready_tick,"detection_complete":now_tick>=ready_tick,
		"ticks_remaining":maxi(ready_tick-now_tick,0)}


func build_episode_snapshot(now_tick: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if now_tick < 0 or now_tick < _latest_tick:
		return result
	var observers: Array = _episodes.keys()
	observers.sort()
	for observer_id in observers:
		var targets: Array = Dictionary(_episodes[observer_id]).keys()
		targets.sort()
		for target_id in targets:
			var episode := read_pair(observer_id,target_id,now_tick)
			episode["key"] = JSON.stringify([observer_id,target_id])
			episode["attacker_unit_id"] = observer_id
			episode["target_unit_id"] = target_id
			result.append(episode)
	return result


func clear() -> void:
	_episodes.clear()
	_latest_tick = -1


func _invalid(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason,"episode_started":false,
		"ready_tick":-1,"detection_complete":false,"lost":false}
