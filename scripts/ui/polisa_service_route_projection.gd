extends RefCounted
## Read-only map projection; never mutates the player's FleetTravel state.

static func describe(shuttle: Dictionary, home: Dictionary = {}, dispatcher: Dictionary = {}) -> String:
	if shuttle.get("phase") == "home_landing_required" and home.get("phase") == "inbound": return "Stationsshuttle: landet an der Heimatbasis"
	if dispatcher.get("waiting_for_pad") == true: return "Stationsshuttle: wartet auf einen freien Landeplatz"
	if shuttle.get("phase", "idle") == "idle" and dispatcher.get("phase") in ["pilot_pending", "walk_pending", "approaching", "taking_off", "next_recruit_pending"]: return "Stationsshuttle: wird auf Polisa vorbereitet"
	var labels := {"to_home":"unterwegs zur Heimatbasis", "home_landing_required":"wartet auf einen freien Landeplatz", "home_disembark_required":"bereitet den Ausstieg vor", "home_waiting":"Personal wartet an der Basis", "return_boarding_required":"Personal kehrt zum Shuttle zurück", "to_station":"unterwegs nach Polisa", "station_landing_required":"bereitet die Stationslandung vor", "station_disembark_required":"Personal steigt auf Polisa aus"}
	var label := String(labels.get(String(shuttle.get("phase", "")), ""))
	return "Stationsshuttle: " + label if not label.is_empty() else ""

static func merge(player_travel: Dictionary, shuttle: Dictionary) -> Dictionary:
	var result := player_travel.duplicate(true)
	var id := String(shuttle.get("craft_id", ""))
	var route: Variant = shuttle.get("route", {})
	var routes: Dictionary = result.get("routes", {})
	if not result.has("routes") and not String(result.get("craft_id", "")).is_empty():
		routes[String(result.craft_id)] = player_travel.duplicate(true)
	if id.is_empty() or routes.has(id) or typeof(route) != TYPE_DICTIONARY or not route.has("phase"):
		return result
	routes[id] = route.duplicate(true)
	result["routes"] = routes
	return result
