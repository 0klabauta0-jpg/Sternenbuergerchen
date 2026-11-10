extends "res://scripts/tests/campaign_pilot_ground_loop_test.gd"
## Real two-sortie campaign; trader return uses the visible extraction button.
func _prepare_visit_return(mission: Node) -> bool:
	var controller: Node = mission.get_node("TacticalController")
	var map = MAP.load_from_file("res://maps/trade_outpost.json")
	var view: Node = mission.get_node("Primary3DView")
	var target: Vector2 = map.get_marker_position("ship_return")
	view.call("focus_world_position", target)
	controller.call("set_planning_enabled", false)
	_check(bool(controller.call("request_immediate_move_from_screen", view.call("world_to_screen_position", target))), "Plan off accepts real immediate move without GO")
	controller.call("set_planning_enabled", true)
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


func _landing_target(map) -> Vector2:
	var registry: Node = load("res://scripts/terrain/terrain_registry.gd").new()
	registry.configure_iso_grid(map.get_grid_origin(),64,32,map.get_grid_topology())
	for tile in map.get_tiles(): registry.register_tile(tile)
	var spawn: Vector2 = map.get_marker_position("spawn_alpha")
	for tile in map.get_tiles():
		if tile.world_position.distance_to(spawn) >= 256.0 and tile.world_position.distance_to(spawn) <= 512.0 and bool(load("res://scripts/mission/field_landing_contract.gd").validate(registry,tile.grid_position,[]).ok):
			var position: Vector2 = tile.world_position
			registry.free()
			return position
	registry.free()
	_check(false, "Authored map offers a safe free field landing away from spawn")
	return spawn
