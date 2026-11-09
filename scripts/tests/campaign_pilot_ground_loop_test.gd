extends "res://scripts/tests/playtest_20261109_singleplayer_loop_smoke.gd"
## Reuses the real two-sortie driver; no fabricated wins or onboarding facts.
const START = preload("res://scripts/meta/game_start_contract.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const ROSTER = preload("res://scripts/meta/player_roster_store.gd")
var _skirmish_bytes: PackedByteArray
var _return_number := 0
var _insertion_guard_checked := false
var _ground_checked := false

func _configure_entry() -> void:
	ROSTER.ensure_roster("campaign-profile-isolation")
	_skirmish_bytes = FileAccess.get_file_as_bytes(ROSTER.get_save_path())
	_check(FileAccess.file_exists(ROSTER.get_save_path()) and not _skirmish_bytes.is_empty(), "Existing menu-built Skirmish team fixture is nonempty")
	START.request_start(self, "campaign", "new")

func _expected_crew_count() -> int:
	return 1

func _all_crew_deployed(controller: Node) -> bool:
	if not _insertion_guard_checked and Dictionary(controller.get("_deployed_unit_ids")).has("campaign_leader") and Dictionary(controller.get("_runtime_activation_pending_fireteam_ids")).has(_team_id):
		controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
		var accepted: bool = controller.call("execute_selected_fireteam_orders")
		_check(not accepted and String(controller.get("_last_command_text")).begins_with("WAIT FOR INSERTION"), "GO is held until actual deploy effects and automatic insertion security finish")
		_insertion_guard_checked = true
	var pilot: Node = controller.call("_find_friendly_unit_by_id", "campaign_pilot")
	if not Dictionary(controller.get("_deployed_unit_ids")).has("campaign_pilot") or pilot == null or bool(pilot.get_meta("dropship_embarked", true)):
		return false
	return super._all_crew_deployed(controller)

func _wait_homebase() -> bool:
	var ready: bool = await _wait(func():
		var current: Dictionary = _flow.call("get_singleplayer_snapshot")
		var craft: Dictionary = _craft(current)
		return String(craft.get("location_id", "")) == "homebase" and not bool(craft.get("busy", true)), 35000, "Actual reverse transit restores original craft to homebase")
	if not ready:
		_dump("homebase_return")
		return false
	_return_number += 1
	_flow.call("_show_homebase")
	_runtime.call("observe_campaign_progress")
	var before: Dictionary = _flow.call("get_singleplayer_snapshot")
	_check(int(before.onboarding.stage_index) == _return_number + 1, "Actual home arrival advances tutorial in order")
	_check(Array(_flow.get("_all_team_units")).size() == 2, "True return keeps exactly two NPCs")
	var saved: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime)
	if not _check(bool(saved.get("ok", false)), "Actual home milestone saves valid complete checkpoint"):
		print("CHECKPOINT_RESULT:", saved)
		return false
	var loaded: Dictionary = STORE.load_checkpoint()
	_check(bool(loaded.get("ok", false)), "Saved campaign checkpoint loads after real trip")
	_flow.queue_free()
	await process_frame
	START.request_start(self, "campaign", "continue")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	var after: Dictionary = _flow.call("get_singleplayer_snapshot")
	_check(int(after.onboarding.stage_index) == int(before.onboarding.stage_index), "Continue preserves completed tutorial milestone")
	_check(int(after.supply.credits) == int(before.supply.credits) and after.supply.fuel_by_craft_id == before.supply.fuel_by_craft_id and after.supply.item_quantities == before.supply.item_quantities, "Continue preserves credits, craft fuel and purchased inventory")
	_check(_identity(_screen.call("get_operations_snapshot")) == _identity_before, "Continue preserves original two NPC identities")
	_check(FileAccess.get_file_as_bytes(ROSTER.get_save_path()) == _skirmish_bytes, "Campaign progress and continue preserve Skirmish profile bytes")
	return true

func _finish() -> void:
	if _failed == 0:
		_check(_insertion_guard_checked, "Actual transient insertion guard was exercised")
	_check(FileAccess.get_file_as_bytes(ROSTER.get_save_path()) == _skirmish_bytes, "Campaign never writes the menu-built Skirmish team")
	print("CAMPAIGN_INTRO_LOOP returns=%d" % _return_number)
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame
	print("SINGLEPLAYER_LOOP_RESULTS passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _prepare_initial_base() -> bool:
	var operations: Dictionary = _screen.call("get_operations_snapshot")
	var craft: Dictionary = operations.get("selected_craft", {})
	_craft_id = String(craft.get("id", ""))
	for team: Dictionary in Array(operations.get("fireteams", [])):
		if not Array(team.get("members", [])).is_empty():
			_team_id = String(team.id)
			break
	_configure_base_equipment()
	return await _board_actual_base_crew()

func _board_actual_base_crew() -> bool:
	var boarding: Dictionary = _screen.call("request_operation", "base_board", {"craft_id": _craft_id, "fireteam_id": _team_id, "whole_fireteam": true})
	if not _check(bool(boarding.get("ok", false)), "Both base people receive real boarding walk"):
		print("BASE_BOARD_RESULT:", boarding)
		return false
	var personnel: Node = _runtime.call("get_base_personnel_runtime")
	return await _wait(func(): return bool(personnel.call("is_pilot_aboard", _craft_id)), 60000, "Base pilot reaches actual craft before launch")

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
