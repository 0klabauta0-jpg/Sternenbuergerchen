extends "res://scripts/tests/campaign_pilot_ground_loop_test.gd"
## Pilot swap from the ship map during a sortie, then real home landing: the home checkpoint must save,
## continue, and keep the new pilot while the displaced pilot belongs to the craft's payload team.
## Argument "noswap" runs the control path without the swap (state must be what it always was).
## The inherited loop saves and continues at the first home arrival; this file adds the swap-specific proof
## and stops there (the later sorties of the parent are covered by their own tests).

const NEW_PILOT := "campaign_leader"
const OLD_PILOT := "campaign_pilot"
var _swap := true

func _configure_entry() -> void:
	_swap = not OS.get_cmdline_user_args().has("noswap")
	super._configure_entry()

func _on_actual_landed(controller: Node) -> void:
	if _swap:
		super._on_actual_landed(controller)

func _wait_homebase() -> bool:
	var inherited_ok: bool = await super._wait_homebase()
	if is_instance_valid(_flow) and _homebase_craft_ready():
		_verify_after_home(inherited_ok)
	return false # ends the inherited loop after the first home arrival; _finish prints the result

func _homebase_craft_ready() -> bool:
	return String(_craft(_flow.call("get_singleplayer_snapshot")).get("location_id", "")) == "homebase"

func _state() -> Dictionary:
	var personnel: Node = _runtime.call("get_base_personnel_runtime")
	var people: Dictionary = {}
	for person: Dictionary in Array(personnel.call("get_snapshot").get("units", [])):
		people[String(person.unit_id)] = [String(person.status), String(person.craft_id), String(person.get("fireteam_id", ""))]
	var teams: Dictionary = {}
	for team: Dictionary in Array(_screen.call("get_operations_snapshot").get("fireteams", [])):
		var ids: Array = []
		for member: Dictionary in Array(team.get("members", [])):
			ids.append(String(member.get("id", "")))
		teams[String(team.get("id", ""))] = ids
	return {
		"pilot": String(Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")).get(_craft_id, "")),
		"screen_pilot": String(_screen.call("_get_assigned_pilot_id", _craft_id)),
		"teams": teams,
		"payload_teams": Array(_screen.call("_get_homebase_direct_payload_fireteam_ids_for_craft_raw", _craft_id)),
		"staged": Array(_flow.get("_homebase_staged_unit_ids")),
		"staged_teams": Array(_flow.get("_homebase_staged_fireteam_ids")),
		"people": people,
	}

func _in_a_payload_team(state: Dictionary, id: String) -> bool:
	for team_id in Array(state.get("payload_teams", [])):
		if Array(Dictionary(state.get("teams", {})).get(String(team_id), [])).has(id):
			return true
	return false

func _verify_after_home(inherited_ok: bool) -> void:
	var state: Dictionary = _state()
	print("PILOT_SWAP_STATE swap=", _swap, " ", var_to_str(state))
	var expected_pilot := NEW_PILOT if _swap else OLD_PILOT
	var other := OLD_PILOT if _swap else NEW_PILOT
	_check(state.pilot == expected_pilot and state.screen_pilot == expected_pilot, "Home landing keeps the pilot the player chose")
	for id: String in [OLD_PILOT, NEW_PILOT]:
		_check(String(Dictionary(state.people).get(id, ["", ""])[0]) == "aboard" and String(Dictionary(state.people).get(id, ["", ""])[1]) == _craft_id, "Real person is aboard the landed craft: " + id)
	_check(state.pilot == expected_pilot, "Control or swap: pilot matches")
	_check(_in_a_payload_team(state, other), "Every aboard person is pilot or in a payload team of the craft: " + other)
	if not _swap:
		# Control: unchanged from before the fix (the pilot is not a team member, the leader is).
		_check(not _in_a_payload_team(state, OLD_PILOT) and _in_a_payload_team(state, NEW_PILOT), "Without swap the old shape stays: only the leader is in the payload team")
	var saved: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime, true)
	if not _check(bool(saved.get("ok", false)) and not bool(saved.get("throttled", false)), "Home checkpoint saves after the pilot swap"):
		print("PILOT_SWAP_SAVE_RESULT:", saved)
	var manual: Dictionary = _flow.call("request_campaign_save")
	if not _check(bool(manual.get("ok", false)), "Manual campaign save succeeds at home after the swap"):
		print("PILOT_SWAP_MANUAL_RESULT:", manual)
	if not inherited_ok:
		return
	# The inherited loop has already saved, rebuilt the Flow and continued: this is the loaded state.
	var selected: Dictionary = _screen.call("request_operation", "select_destination", {"location_id": "trade_outpost", "job_id": "", "request_id": "swap:destination"})
	_check(bool(selected.get("ok", false)), "Continued game selects the next destination")
	var guard: Dictionary = _runtime.call("authorize_departure", _craft_id)
	_check(bool(guard.get("ok", false)), "Continued game can depart again with the chosen pilot")
	if not bool(guard.get("ok", false)):
		print("PILOT_SWAP_DEPARTURE_RESULT:", guard)

func _finish() -> void:
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame
	print("CAMPAIGN_PILOT_SWAP_HOME_SAVE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
