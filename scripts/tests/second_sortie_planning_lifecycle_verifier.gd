extends SceneTree

## Lifecycle regression: the live first sortie receives a seeded terminal
## result at the combat-to-Meta boundary. This fixture does not play combat.
const ISOLATION_GUARD := preload("res://scripts/tests/review2_isolated_user_guard.gd")
const AIR_ASSET_STATUS := preload("res://scripts/mission/air_asset_status.gd")
const MAIN_MENU := preload("res://scenes/ui/main_menu.tscn")
const META_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const START_PATH := "Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton"
const MISSION_NAV_PATH := "Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/MissionNavButton"
const AIRCRAFT_STATUS_PATH := "Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftStatusLabel"
const RETURN_PATH := "Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton"
const OLD_LZ := Vector2(-320.0, 576.0)
const LATE_LZ := Vector2(91.0, 987.0)

var _passed := 0
var _failed := 0


func _initialize() -> void:
	if not ISOLATION_GUARD.require_isolated_user_data():
		quit(2)
		return
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var menu: Node = MAIN_MENU.instantiate()
	root.add_child(menu)
	current_scene = menu
	await _frames(5)
	if not _press(menu, "MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton", "The normal Singleplayer button is enabled"):
		await _finish()
		return
	for _index in range(120):
		if current_scene != null and current_scene.scene_file_path == META_SCENE_PATH:
			break
		await process_frame
	var flow: Node = current_scene
	if not _check(flow != null and flow.scene_file_path == META_SCENE_PATH, "The normal menu opens the Meta flow"):
		await _finish()
		return
	await _frames(8)
	var homebase: Node = flow.get_node("HomebaseScreen")
	if not _press(homebase, START_PATH, "Homebase starts the first live sortie"):
		await _finish()
		return
	await _frames(8)
	var first: Node = flow.call("get_active_mission")
	if not _check(first != null, "First launch creates an active mission"):
		await _finish()
		return
	var first_instance_id: int = first.get_instance_id()
	var first_started: int = int(flow.get("_active_mission_started_at_msec"))
	var controller: Node = first.get_node("TacticalController")
	var first_plan: Dictionary = controller.call("get_planning_state")
	var craft_id: String = String(first_plan.get("mission_drop_craft_id", ""))
	var payload := PackedStringArray(first_plan.get("embarked_unit_ids", []))
	if not _check(not craft_id.is_empty() and not payload.is_empty(), "First sortie starts with the real staged craft and crew"):
		await _finish()
		return

	var options := OS.get_cmdline_user_args()
	var damaged_end: bool = options.has("--damaged-end")
	var end_during_outbound: bool = damaged_end or options.has("--early-end")
	_advance_craft_transfer(flow, craft_id, "to_mission")
	var completed_plan: Dictionary = _seed_prior_sortie_return(controller, craft_id, payload, end_during_outbound)
	var before_result: Dictionary = {}
	if end_during_outbound:
		var locations_at_end: Dictionary = flow.get("_aircraft_location_by_craft")
		if not _check(String(locations_at_end.get(craft_id, "")) == "mission" and _find_transfer(flow, craft_id).is_empty(), "The craft is still on the map with no pending return"):
			await _finish()
			return
		if damaged_end:
			controller.set("_air_asset_status", AIR_ASSET_STATUS.from_dict({
				"asset_id": craft_id,
				"asset_type": "dropship",
				"state": "damaged",
				"integrity": 45,
			}))
	else:
		flow.call("_on_homebase_transport_timer_timeout")
		before_result = _find_transfer(flow, craft_id)
		if not _check(String(before_result.get("phase", "")) == "to_homebase" and float(before_result.get("elapsed_seconds", 0.0)) > 0.0, "Fixture starts a genuine RTB transfer with elapsed time"):
			await _finish()
			return
		if options.has("--replay-return"):
			_advance_craft_transfer(flow, craft_id, "to_homebase")
			_check(_find_transfer(flow, craft_id).is_empty(), "Initial RTB reaches its destination")
			controller.emit_signal("planning_state_changed", completed_plan)
			var locations_after_replay: Dictionary = flow.get("_aircraft_location_by_craft")
			_check(_find_transfer(flow, craft_id).is_empty() and String(locations_after_replay.get(craft_id, "")) == "homebase", "Replaying an arrived craft's return cannot restart RTB")
			await _finish()
			return

	var combat: Node = first.get_node("CombatLoopDriver")
	var friendly_team: String = String(combat.get("friendly_team_id"))
	combat.emit_signal("combat_resolved", {
		"result": "victory",
		"mission_outcome": "won",
		"winning_team_id": friendly_team,
		"friendly_team_id": friendly_team,
		"win_condition_type": "objective_capture",
		"objective_captured": true,
		"duration_seconds": 12.0,
	})
	var debrief: Control = flow.get_node("DebriefScreen")
	var result: Dictionary = debrief.call("get_mission_result")
	_check(debrief.visible and String(result.get("result", "")) == "victory", "Meta routes the combat result to the real Debrief")
	_check(flow.call("get_active_mission") == null and int(flow.get("_active_mission_started_at_msec")) == 0, "Completion releases mission one and ends its timer")
	if end_during_outbound:
		var recovery: Dictionary = flow.call("get_air_asset_recovery_snapshot")
		var transfer: Dictionary = _find_transfer(flow, craft_id)
		if damaged_end:
			var craft_recovery: Dictionary = recovery.get(craft_id, {})
			_check(String(craft_recovery.get("meta_state", "")) == "damaged_repairing" and transfer.is_empty(), "Repair recovery takes priority over the normal return transfer")
		else:
			_check(String(transfer.get("phase", "")) == "to_homebase" and String(transfer.get("payload_source", "")) == "homebase_direct", "Completion during map exit hands the healthy craft to a normal RTB transfer")
			_check(not recovery.has(craft_id), "A healthy craft enters no repair or replacement recovery")
		await _finish()
		return
	_check(_find_transfer(flow, craft_id) == before_result, "Mission completion keeps the existing RTB transfer and its elapsed time")

	# The old controller still exists in this same frame after queue_free().
	# Its final callback must be unable to change the Meta planning model.
	var plan_before_late: Dictionary = Dictionary(flow.get("_mission_planning_state")).duplicate(true)
	controller.emit_signal("planning_state_changed", {
		"has_lz_position": true,
		"lz_position": LATE_LZ,
		"mission_drop_source": "homebase_direct",
		"mission_drop_cards": [{"craft_id": craft_id, "state": "to_homebase"}],
	})
	_check(Dictionary(flow.get("_mission_planning_state")) == plan_before_late, "A late callback from the released mission cannot rewrite planning")
	_check(_find_transfer(flow, craft_id) == before_result, "A repeated old return does not restart the pending transfer")

	if not _press(debrief, RETURN_PATH, "The real Debrief button returns to Homebase"):
		await _finish()
		return
	var returned: Dictionary = flow.call("get_debrief_return_homebase_handoff_snapshot")
	_check(homebase.visible and not debrief.visible and bool(returned.get("mission_result_preserved", false)), "Homebase is visible and the previous result is still available")
	var start_button := homebase.get_node_or_null(START_PATH) as Button
	_check(start_button != null and start_button.is_visible_in_tree() and start_button.disabled and String(_find_transfer(flow, craft_id).get("phase", "")) == "to_homebase", "Homebase Start stays disabled while the only craft is returning")
	var aircraft_status := homebase.get_node(AIRCRAFT_STATUS_PATH) as Label
	_check(aircraft_status.is_visible_in_tree() and aircraft_status.text.contains("Rückflug"), "The flightdeck explains that the Cutlass is returning")
	var mission_nav := homebase.get_node(MISSION_NAV_PATH) as Button
	_check(mission_nav.is_visible_in_tree() and mission_nav.disabled, "Mission navigation cannot bypass the post-Debrief launch gate")
	mission_nav.pressed.emit()
	_check(flow.call("get_active_mission") == null and homebase.is_visible_in_tree(), "The navigation callback cannot open an unprepared second sortie")
	_advance_craft_transfer(flow, craft_id, "to_homebase")
	_check(_find_transfer(flow, craft_id).is_empty(), "The regular transport timer completes the existing RTB")
	var locations: Dictionary = flow.get("_aircraft_location_by_craft")
	_check(String(locations.get(craft_id, "")) == "homebase", "The completed return parks the same craft at Homebase")
	await _frames(8)
	if not _press(homebase, START_PATH, "Homebase starts a second sortie with the returned craft"):
		await _finish()
		return
	await _frames(8)
	var second: Node = flow.call("get_active_mission")
	if not _check(second != null and second.get_instance_id() != first_instance_id, "A new active mission owns the second sortie"):
		await _finish()
		return

	var next_controller: Node = second.get_node("TacticalController")
	var next_plan: Dictionary = next_controller.call("get_planning_state")
	_check(int(flow.get("_active_mission_started_at_msec")) > first_started, "The second sortie has a fresh timer")
	_check(String(next_plan.get("mission_drop_craft_id", "")) == craft_id and PackedStringArray(next_plan.get("embarked_unit_ids", [])) == payload, "The second sortie reuses the returned craft with the newly staged crew")
	_check(String(next_plan.get("mission_drop_state", "")) == "to_mission", "The second sortie starts a fresh outbound transfer to the mission")
	_check(_is_fresh_insertion_plan(next_plan, craft_id), "The new flight contains no previous LZ, drop request or deployed crew")
	_advance_craft_transfer(flow, craft_id, "to_mission")
	await _frames(2)
	next_plan = next_controller.call("get_planning_state")
	_check(String(next_plan.get("mission_drop_state", "")) == "waiting", "The second transport reaches normal waiting after transit")
	_check(_is_fresh_insertion_plan(next_plan, craft_id), "Arrival still needs a fresh LZ and Drop command")
	await _finish()


func _seed_prior_sortie_return(controller: Node, craft_id: String, payload: PackedStringArray, end_during_outbound: bool) -> Dictionary:
	var plan: Dictionary = controller.call("get_planning_state")
	var cards: Array = Array(plan.get("mission_drop_cards", [])).duplicate(true)
	var state: String = "outbound" if end_during_outbound else "to_homebase"
	for card_variant in cards:
		var card: Dictionary = card_variant
		if String(card.get("craft_id", "")) != craft_id:
			continue
		card["state"] = state
		card["passenger_count"] = 0
		card["embarked_unit_ids"] = []
		card["has_lz_position"] = true
		card["lz_position"] = OLD_LZ
		card["approach_angle"] = "SE"
	plan["mission_drop_cards"] = cards
	plan["mission_drop_state"] = state
	plan["mission_drop_return_requested"] = not end_during_outbound
	plan["mission_drop_passenger_count"] = 0
	plan["embarked_unit_ids"] = []
	plan["has_lz_position"] = true
	plan["lz_position"] = OLD_LZ
	plan["approach_angle"] = "SE"
	plan["deployed_unit_ids"] = Array(payload)
	controller.emit_signal("planning_state_changed", plan)
	return plan


func _find_transfer(flow: Node, craft_id: String) -> Dictionary:
	for transfer_variant in Array(flow.get("_pending_mission_craft_transfers")):
		var transfer: Dictionary = transfer_variant
		if String(transfer.get("craft_id", "")) == craft_id:
			return transfer.duplicate(true)
	return {}


func _advance_craft_transfer(flow: Node, craft_id: String, phase: String) -> void:
	# Seed the final second of this fixture's wait, then let the real timer
	# own completion, craft location and the Homebase/mission refresh.
	var transfers: Array = Array(flow.get("_pending_mission_craft_transfers")).duplicate(true)
	for transfer_variant in transfers:
		var transfer: Dictionary = transfer_variant
		if String(transfer.get("craft_id", "")) != craft_id or String(transfer.get("phase", "")) != phase:
			continue
		transfer["elapsed_seconds"] = maxf(float(transfer.get("duration_seconds", 0.0)) - 1.0, 0.0)
		flow.set("_pending_mission_craft_transfers", transfers)
		flow.call("_on_homebase_transport_timer_timeout")
		return


func _is_fresh_insertion_plan(plan: Dictionary, craft_id: String) -> bool:
	if bool(plan.get("has_lz_position", true)) or bool(plan.get("drop_ship_requested", true)):
		return false
	if not Array(plan.get("deployed_unit_ids", [])).is_empty() or not Dictionary(plan.get("deployed_unit_positions", {})).is_empty():
		return false
	for card_variant in Array(plan.get("mission_drop_cards", [])):
		var card: Dictionary = card_variant
		if String(card.get("craft_id", "")) == craft_id:
			return not bool(card.get("has_lz_position", false)) and not bool(card.get("drop_ship_requested", false))
	return false


func _press(parent: Node, path: String, label: String) -> bool:
	var button := parent.get_node_or_null(path) as Button
	if not _check(button != null and button.is_visible_in_tree() and not button.disabled, label):
		return false
	button.pressed.emit()
	return true


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, label: String) -> bool:
	if condition:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		push_error("FAIL: " + label)
	return condition


func _finish() -> void:
	if current_scene != null:
		current_scene.queue_free()
		await _frames(3)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
