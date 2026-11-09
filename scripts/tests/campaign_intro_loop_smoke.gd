extends "res://scripts/tests/playtest_20261109_singleplayer_loop_smoke.gd"
## Reuses the real two-sortie driver; no fabricated wins or onboarding facts.
const START = preload("res://scripts/meta/game_start_contract.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const ROSTER = preload("res://scripts/meta/player_roster_store.gd")
var _skirmish_bytes: PackedByteArray
var _return_number := 0
var _insertion_guard_checked := false

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
	if not await super._wait_homebase():
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
	await super._finish()

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
	if bool(controller.call("get_campaign_pilot_flight_guard", _craft_id).ok): return true
	var map = MAP.load_from_file("res://maps/trade_outpost.json")
	var ship: Vector2 = map.get_marker_position("ship_return")
	controller.call("_create_waypoints_for_selected_fireteams", ship, true)
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), "Actual crew receives ship return walk"): return false
	if not await _wait(func():
		for id in ["campaign_leader", "campaign_pilot"]:
			var unit: Node2D = controller.call("_find_friendly_unit_by_id", id)
			if unit == null or unit.global_position.distance_to(ship) > 128.0: return false
		return true, 45000, "Actual crew returns to ship before boarding"): return false
	controller.call("request_campaign_crew_boarding", _craft_id)
	return await _wait(func(): return bool(controller.call("get_campaign_pilot_flight_guard", _craft_id).ok), 3000, "Actual pilot commits boarding before reverse flight")

func _configure_base_equipment() -> void:
	pass
