extends RefCounted
## Synchronous fixture convenience only; runtime should advance the search in bounded steps.
const SEARCH = preload("res://scripts/tactical/space_orbit_entry_search.gd")

static func allocate(body_id: String, requests: Array[Dictionary], occupancy: RefCounted) -> Dictionary:
	var search = SEARCH.new()
	var started: Dictionary = search.begin(body_id, requests, occupancy)
	if not started.get("ok", false): return started
	while true:
		var result: Dictionary = search.advance(SEARCH.MAX_CHECKS_PER_STEP)
		if not result.get("ok", false) or result.get("status") != "pending": return result
	return {"ok":false, "reason":"search_inactive"}
