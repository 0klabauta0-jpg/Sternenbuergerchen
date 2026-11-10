extends "res://scripts/tests/campaign_pilot_ground_loop_test.gd"
## Real two-sortie campaign; trader return uses the visible extraction button.
func _prepare_visit_return(mission: Node) -> bool:
	var controller: Node = mission.get_node("TacticalController")
	var ids := PackedStringArray(["campaign_leader", "campaign_pilot"])
	var before := {}
	for id in ids:
		before[id] = (controller.call("_find_friendly_unit_by_id", id) as Node2D).global_position
	controller.call("_refresh_mission_dropship_panel")
	var board := mission.get_node("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Actions/board") as Button
	if not _check(board.visible and not board.disabled, "Normal landed card exposes an enabled extraction button"):
		return false
	board.pressed.emit()
	for id in ids:
		_check((controller.call("_find_friendly_unit_by_id", id) as Node2D).global_position == before[id], "Extraction does not teleport " + id)
	if not await _wait(func(): return bool(controller.call("get_campaign_pilot_flight_guard", _craft_id).get("ok", false)), 60000, "Visible extraction walks both real people and commits boarding"):
		return false
	var embarked: Array = controller.call("get_planning_state").get("embarked_unit_ids", [])
	_check(embarked.size() == 2 and embarked.has(ids[0]) and embarked.has(ids[1]), "Visible extraction retains both people exactly once")
	controller.call("_refresh_mission_dropship_panel")
	var depart := mission.get_node("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Actions/return") as Button
	_check(depart.visible and not depart.disabled, "Explicit takeoff enables only after boarding commits")
	return true
