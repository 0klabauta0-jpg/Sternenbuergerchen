extends RefCounted
## Opt-in diagnostic receipts only. No scene/runtime references or gameplay state.
const RETAINED_FRAMES := 8
var _frames: Dictionary = {}

func clear() -> void:
	_frames.clear()

func record_sample(process_frame: int, sample_usec: int, scopes_usec: Dictionary = {}, tick: int = -1) -> void:
	if not _frames.has(process_frame):
		_frames[process_frame] = _empty_frame(process_frame)
		while _frames.size() > RETAINED_FRAMES:
			_frames.erase(_frames.keys()[0])
	var frame: Dictionary = _frames[process_frame]
	frame.has_sample = true
	frame.sample_count += 1
	frame.sum_usec += sample_usec
	frame.max_usec = maxi(int(frame.max_usec), sample_usec)
	if tick >= 0:
		if int(frame.first_tick) < 0: frame.first_tick = tick
		frame.last_tick = tick
	for key in scopes_usec:
		var elapsed := int(scopes_usec[key])
		frame.scopes_sum_usec[key] = int(frame.scopes_sum_usec.get(key, 0)) + elapsed
		frame.scopes_max_usec[key] = maxi(int(frame.scopes_max_usec.get(key, 0)), elapsed)

func get_snapshot(process_frame: int) -> Dictionary:
	return Dictionary(_frames.get(process_frame, _empty_frame(process_frame))).duplicate(true)

func _empty_frame(process_frame: int) -> Dictionary:
	return {"process_frame":process_frame,"has_sample":false,"sample_count":0,
		"sum_usec":0,"max_usec":0,"first_tick":-1,"last_tick":-1,
		"scopes_sum_usec":{},"scopes_max_usec":{}}
