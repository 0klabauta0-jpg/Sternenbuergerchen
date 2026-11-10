extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Same real orbit/two-sortie/checkpoint loop, with a changed actual pilot.
var _ground_checked := false

func _prepare_visit_return(mission: Node) -> bool:
	var controller: Node = mission.get_node("TacticalController")
	var refused: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
	_check(not bool(refused.ok) and String(refused.get("reason", "")) in ["pilot_not_at_ship", "crew_not_at_ship"], "Trader use cannot teleport remote pilot onto craft")
	var map = MAP.load_from_file("res://maps/trade_outpost.json")
	var ship: Vector2 = map.get_marker_position("ship_return")
	controller.call("_create_waypoints_for_selected_fireteams", ship, true)
	_check(bool(controller.call("execute_selected_fireteam_orders")), "Both real people receive return walk")
	if not await _wait(func():
		for id: String in ["campaign_leader", "campaign_pilot"]:
			var unit: Node2D = controller.call("_find_friendly_unit_by_id", id)
			if unit == null or unit.global_position.distance_to(ship) > 128.0: return false
		return true, 45000, "Both people physically reach craft before boarding"):
		return false
	var boarded: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
	_check(not bool(boarded.ok) and String(boarded.get("reason", "")) == "pilot_boarding_pending", "Boarding queues actual SimulationRoot effects")
	_check(not bool(controller.call("get_campaign_pilot_flight_guard", _craft_id).ok), "Queued boarding is not already presence")
	if not await _wait(func(): return bool(controller.call("get_campaign_pilot_flight_guard", _craft_id).ok), 3000, "Flight opens only after real pilot embark commit"):
		return false
	var payload: Array = controller.call("get_planning_state").get("embarked_unit_ids", [])
	_check(payload.size() == 2 and payload.has("campaign_pilot") and payload.has("campaign_leader"), "Return payload has both IDs once")
	return true

func _configure_base_equipment() -> void:
	var gear: Dictionary = _screen.call("request_operation", "loadout", {"unit_id":"campaign_pilot", "key":"weapon_1", "value":"medictool"})
	_check(bool(gear.get("ok", false)), "Outside real pilot equips through existing operation owner")

func _on_actual_landed(controller: Node) -> void:
	var pilot: Node = controller.call("_find_friendly_unit_by_id", "campaign_pilot")
	_check(String(pilot.call("get_weapon_1_id")) == "medictool", "Pilot gear crosses actual deployment boundary")
	if not _ground_checked:
		_ground_checked = true
		_check(pilot != null and not bool(pilot.get_meta("dropship_embarked", true)), "Real pilot is deployed by SimulationRoot")
		_check(String(pilot.call("get_fireteam_id")) == _team_id, "Pilot follows same existing tactical team without new permanent team")
		var guard: Dictionary = controller.call("get_campaign_pilot_flight_guard", _craft_id)
		_check(not bool(guard.ok) and String(guard.reason) == "pilot_not_aboard", "Actual pilot on ground blocks flight even while assigned")
		var fuel_before: Dictionary = _supply()
		var refused: Dictionary = _runtime.call("authorize_return", _craft_id)
		_check(not bool(refused.ok) and _supply() == fuel_before, "Pilot absence rejects return without consuming fuel")
		var other: Dictionary = controller.call("assign_campaign_pilot", _craft_id, "campaign_leader")
		_check(bool(other.ok) and String(Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")).get(_craft_id, "")) == "campaign_leader", "Any actual NPC can take pilot post through shared assignment")
		_check(not bool(controller.call("get_campaign_pilot_flight_guard", _craft_id).ok), "Reassignment does not invent presence at pilot post")
		_check(not bool(controller.call("assign_campaign_pilot", _craft_id, "invisible_replacement").ok), "Unknown replacement is rejected")
		_pilot_id = "campaign_leader"
