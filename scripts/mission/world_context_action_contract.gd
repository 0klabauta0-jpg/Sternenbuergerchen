extends RefCounted
## Read-only semantic projection; commands and gates stay with existing owners.
static func interaction_label(entry: Dictionary) -> String:
	var id := String(entry.get("interaction_id",""))
	var name := String(entry.get("display_name",""))
	if id == "ship_return": return "Einsteigen / Rückflug"
	if id.contains("satellite") or id.contains("chip"): return "Daten sichern"
	if id.contains("crate") or id.contains("loot"): return "Einsammeln"
	if String(entry.get("asset_hint","")).begins_with("resource_"):
		return "Bergen" if String(entry.asset_hint).ends_with("wreck") else "Abbauen"
	return name if not name.is_empty() else "Benutzen"

static func choose(pointer: Vector2, candidates: Array, radius: float=48.0) -> Dictionary:
	var best: Dictionary={}
	var distance := radius
	for candidate: Dictionary in candidates:
		if typeof(candidate.get("screen_position")) != TYPE_VECTOR2: continue
		var d: float=pointer.distance_to(candidate.screen_position)
		if d > distance: continue
		if not best.is_empty() and is_equal_approx(d,distance) and String(candidate.get("id","")) > String(best.get("id","")): continue
		best=candidate.duplicate(true); distance=d
	return best
