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
	if not _insertion_guard_checked:
		# The guard in mission_tactical_sandbox_controller.gd:1590 holds GO while the fireteam is not runtime-active or still pending (pending ids are keyed by the lower-case fireteam id, not by the campaign team id).
		# Observed on the first poll after the drop was requested (the wait predicate runs at once), i.e. while the insertion is still running; it must not wait until the leader is listed as deployed, because the guard is already released by then.
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
	# Stufe 2 der Einfuehrung verlangt outpost_completed + outpost_recruited + crate_loaded (campaign_onboarding_state.gd STAGE_FACTS), also den abgeschlossenen Auftrag outpost_recovery. Der zweite Ausflug ist ein Handelsbesuch ohne Auftrag (select_destination mit job_id ""), er schaltet die Einfuehrung deshalb nicht weiter: nach der ersten Rueckkehr Stufe 2, nach der zweiten weiterhin 2.
	_check(int(before.onboarding.stage_index) == mini(_return_number, 1) + 1, "Actual home arrival advances tutorial in order (a job-free trade visit does not advance it)")
	_check(Array(_flow.get("_all_team_units")).size() == 2, "True return keeps exactly two NPCs")
	# Der Heim-Speicherpunkt ist gesperrt, solange eine Ortsinstanz fokussiert ist (campaign_start_configuration.gd get_home_checkpoint_guard); nach dem Abflug wird sie freigegeben (wie campaign_retreat_reopen_at_home_verifier R6 es verlangt). Darauf wird gewartet, nicht darum herumgespeichert.
	if not await _wait(func(): return _flow.get("_active_mission") == null, 5000, "Visit location instance is released after the real return home"):
		print("CHECKPOINT_STATE: active_mission=", _flow.get("_active_mission"), " view=", _flow.get("_current_meta_view"), " return_number=", _return_number)
		return false
	# Explicit milestone save: force=true bypasses the 5 minute hex autosave interval (campaign_start_configuration.gd), otherwise the arrival autosave makes this a no-op and Continue loads the older file.
	var saved: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime, true)
	if not _check(bool(saved.get("ok", false)) and not bool(saved.get("throttled", false)), "Actual home milestone saves valid complete checkpoint"):
		print("CHECKPOINT_RESULT:", saved)
		print("CHECKPOINT_STATE: active_mission=", _flow.get("_active_mission"), " pending_transfers=", Array(_flow.get("_pending_mission_craft_transfers")).size(), " travel_phase=", _runtime.call("get_space_travel_snapshot").get("phase", "?"), " locations=", _flow.get("_aircraft_location_by_craft"), " stage_index=", before.onboarding.stage_index, " return_number=", _return_number)
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
	# Das Schiff steht dort, wo die Besatzung es gelandet hat (gewaehlte Landezone), nicht zwingend auf der Marke ship_return; die Rueckkehr zielt wie in _move_and_use auf den echten Landeplatz.
	if controller.has_method("_campaign_landed_craft_position"):
		ship = controller.call("_campaign_landed_craft_position", _craft_id)
	# Auf Hex-Karten zaehlt fuer das Einsteigen der Bodenzugang des Schiffs (get_campaign_ground_ship_access), nicht die Schiffsmitte: _campaign_unit_near_boarding_ship misst gegen ihn (Radius 128). Die Besatzung blieb sonst rund 220 Einheiten vor dem Schiff stehen.
	if controller.has_method("get_campaign_ground_ship_access"):
		var access: Dictionary = controller.call("get_campaign_ground_ship_access", _craft_id)
		if bool(access.get("ok", false)): ship = Vector2(access.position)
	controller.call("_create_waypoints_for_selected_fireteams", ship, true)
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), "Actual crew receives ship return walk"): return false
	if not await _wait(func():
		for id in ["campaign_leader", "campaign_pilot"]:
			var unit: Node2D = controller.call("_find_friendly_unit_by_id", id)
			if unit == null or unit.global_position.distance_to(ship) > 128.0: return false
		# 180 s wie in _move_and_use der Oberklasse: der echte Marsch ueber die Karte dauerte dort 48 s (headless, parallele Godot-Laeufe); 45 s war zu knapp.
		return true, 180000, "Actual crew returns to ship before boarding"):
		for id in ["campaign_leader", "campaign_pilot"]:
			var unit: Node2D = controller.call("_find_friendly_unit_by_id", id)
			print("SHIP_RETURN_STATE: ", id, " pos=", unit.global_position if unit != null else "-", " ship=", ship, " dist=", unit.global_position.distance_to(ship) if unit != null else -1.0, " vital=", unit.call("get_vital_state") if unit != null and unit.has_method("get_vital_state") else "-", " last_command=", controller.get("_last_command_text"))
		return false
	controller.call("request_campaign_crew_boarding", _craft_id)
	return await _wait(func(): return bool(controller.call("get_campaign_pilot_flight_guard", _craft_id).ok), 3000, "Actual pilot commits boarding before reverse flight")

func _configure_base_equipment() -> void:
	# Seit 21.11.2026 (Auftrag P1) startet die Kampagne ohne Waffen. Der erste Einsatz (Satellit, keine Gegner) und der
	# Handelsbesuch laufen bewusst mit dem unbewaffneten Truppfuehrer; hier wird nur belegt, dass er wirklich unbewaffnet ist.
	for id in ["campaign_leader", "campaign_pilot"]:
		var gear: Dictionary = _screen.call("_get_member_loadout", id)
		_check(String(gear.get("weapon_1", "")) == "none" and String(gear.get("weapon_2", "")) == "none", "Sortie runs with unarmed start gear on " + id)
