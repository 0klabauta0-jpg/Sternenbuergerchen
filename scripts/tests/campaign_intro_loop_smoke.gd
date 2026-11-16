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
	if not _insertion_guard_checked and Dictionary(controller.get("_deployed_unit_ids")).has("campaign_leader"):
		# The guard in mission_tactical_sandbox_controller.gd:1590 holds GO while the fireteam is not runtime-active or still pending (pending ids are keyed by the lower-case fireteam id, not by the campaign team id).
		# The pending dictionaries are already empty when the leader shows up in _deployed_unit_ids, so the transient is the runtime-active flag.
		controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
		var held := false
		for fireteam_id in controller.get("_selected_fireteam_ids"):
			var key := String(fireteam_id).strip_edges().to_lower()
			held = held or not bool(controller.call("_is_fireteam_runtime_active", key)) or Dictionary(controller.get("_runtime_activation_pending_fireteam_ids")).has(key) or Dictionary(controller.get("_post_drop_security_pending_fireteam_ids")).has(key)
		if held:
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
	var presence_before: Dictionary = {}
	for person: Dictionary in Array(Dictionary(before.get("base_personnel", {})).get("units", [])):
		presence_before[String(person.unit_id)] = [String(person.status), String(person.craft_id)]
	_check(int(before.onboarding.stage_index) == _return_number + 1, "Actual home arrival advances tutorial in order")
	_check(Array(_flow.get("_all_team_units")).size() == 2, "True return keeps exactly two NPCs")
	# Explicit milestone save: force=true bypasses the 5 minute hex autosave interval (campaign_start_configuration.gd), otherwise the arrival autosave makes this a no-op and Continue loads the older file.
	var saved: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime, true)
	if not _check(bool(saved.get("ok", false)) and not bool(saved.get("throttled", false)), "Actual home milestone saves valid complete checkpoint"):
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
	_check(String(after.space_travel.phase) == "grounded" and String(_craft(after).location_id) == "homebase", "Continue after orbital landing restores a grounded original craft")
	var people: Array = _runtime.call("get_base_personnel_runtime").call("get_snapshot").get("units", [])
	_check(people.size() == 2 and people.all(func(person: Dictionary): return person.unit_id in ["campaign_leader", "campaign_pilot"]), "Continue restores the same two authoritative base people")
	var presence_after: Dictionary = {}
	for person: Dictionary in people:
		presence_after[String(person.unit_id)] = [String(person.status), String(person.craft_id)]
	_check(presence_after == presence_before, "Continue preserves actual presence and original craft for both people")
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
	if _base_crew_ready():
		return _check(true, "Both actual base people and transport payload already agree on boarding")
	var boarding: Dictionary = _screen.call("request_operation", "base_board", {"craft_id": _craft_id, "fireteam_id": _team_id, "whole_fireteam": true})
	if not _check(bool(boarding.get("ok", false)), "Both base people receive real boarding walk"):
		print("BASE_BOARD_RESULT:", boarding)
		return false
	return await _wait(_base_crew_ready, 60000, "Both real people arrive, embark and complete the existing transport payload before launch")

func _base_crew_ready() -> bool:
	var personnel: Node = _runtime.call("get_base_personnel_runtime")
	if personnel == null or not bool(personnel.call("is_pilot_aboard", _craft_id)):
		return false
	var people: Array = personnel.call("get_snapshot").get("units", [])
	return people.size() == 2 and people.all(func(person: Dictionary): return String(person.status) == "aboard" and String(person.craft_id) == _craft_id) and bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", _craft_id))

func _prepare_sortie_base() -> bool:
	return await _board_actual_base_crew()

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
