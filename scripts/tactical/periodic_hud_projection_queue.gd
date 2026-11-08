extends RefCounted
## Presentation scheduling metadata only. No nodes, callbacks or owner sources.
const KEYS: PackedStringArray = ["primary_secondary", "craft", "world_status", "cards"]

var _pending_keys: Array[String] = []
var _pending: Dictionary = {}
var _active_ticket: Dictionary = {}
var _generation: int = 0
var _ticket_sequence: int = 0
var _requested_counts: Dictionary = {}
var _completed_counts: Dictionary = {}
var _coalesced_counts: Dictionary = {}
var _work_counts: Dictionary = {}
var _max_pending_age_msec: int = 0
var _max_pending_keys: int = 0


func _init() -> void:
	for key in KEYS:
		_requested_counts[key] = 0
		_completed_counts[key] = 0
		_coalesced_counts[key] = 0
		_work_counts[key] = 0


func request(force_refresh: bool, now_msec: int) -> void:
	if _pending_keys.is_empty() and _active_ticket.is_empty():
		_generation += 1
	_observe_age(now_msec)
	for key in KEYS:
		_requested_counts[key] = int(_requested_counts[key]) + 1
		if _pending.has(key):
			var existing: Dictionary = _pending[key]
			existing["force"] = bool(existing["force"]) or force_refresh
			_coalesced_counts[key] = int(_coalesced_counts[key]) + 1
		else:
			_pending_keys.append(key)
			_pending[key] = {"key": key, "force": force_refresh, "generation": _generation, "enqueued_msec": now_msec}
	_max_pending_keys = maxi(_max_pending_keys, _pending_keys.size())


func take(now_msec: int) -> Dictionary:
	if _pending_keys.is_empty() or not _active_ticket.is_empty():
		return {}
	_observe_age(now_msec)
	var key: String = _pending_keys.pop_front()
	var ticket: Dictionary = Dictionary(_pending[key]).duplicate()
	_pending.erase(key)
	_ticket_sequence += 1
	ticket["ticket_id"] = _ticket_sequence
	_active_ticket = ticket.duplicate()
	_work_counts[key] = int(_work_counts[key]) + 1
	return ticket


func complete(ticket: Dictionary, now_msec: int) -> bool:
	if _active_ticket.is_empty() or int(_active_ticket["ticket_id"]) != int(ticket.get("ticket_id", -1)):
		return false
	_max_pending_age_msec = maxi(_max_pending_age_msec, maxi(0, now_msec - int(_active_ticket["enqueued_msec"])))
	_active_ticket.clear()
	if int(ticket.get("generation", -1)) != _generation:
		return false
	var key: String = String(ticket["key"])
	_completed_counts[key] = int(_completed_counts[key]) + 1
	# The ticket was removed before execution. A reentrant request may already
	# have added the same key again; completing this ticket never erases it.
	return true


func cancel() -> void:
	_generation += 1
	_pending_keys.clear()
	_pending.clear()
	_active_ticket.clear()


func has_pending() -> bool:
	return not _pending_keys.is_empty()


func has_inflight() -> bool:
	return not _active_ticket.is_empty()


func get_generation() -> int:
	return _generation


func requires_force_refresh() -> bool:
	for job in _pending.values():
		if bool(Dictionary(job)["force"]):
			return true
	return bool(_active_ticket.get("force", false))


func _observe_age(now_msec: int) -> void:
	for job in _pending.values():
		_max_pending_age_msec = maxi(_max_pending_age_msec, maxi(0, now_msec - int(Dictionary(job)["enqueued_msec"])))
	if not _active_ticket.is_empty():
		_max_pending_age_msec = maxi(_max_pending_age_msec, maxi(0, now_msec - int(_active_ticket["enqueued_msec"])))


func get_debug_snapshot(now_msec: int) -> Dictionary:
	_observe_age(now_msec)
	return {
		"pending_keys": _pending_keys.duplicate(),
		"generation": _generation,
		"requested_counts": _requested_counts.duplicate(),
		"completed_counts": _completed_counts.duplicate(),
		"coalesced_counts": _coalesced_counts.duplicate(),
		"work_counts": _work_counts.duplicate(),
		"max_pending_age_msec": _max_pending_age_msec,
		"max_pending_keys": _max_pending_keys,
		"inflight_key": String(_active_ticket.get("key", "")),
		"read_only": true,
		"retains_owner_sources": false,
	}
