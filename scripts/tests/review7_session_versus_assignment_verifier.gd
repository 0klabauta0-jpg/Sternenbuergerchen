extends SceneTree

const ISOLATION_GUARD: GDScript = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SESSION_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not ISOLATION_GUARD.require_isolated_user_data():
		return
	call_deferred("_run_tests")


func _run_tests() -> void:
	for case in [{"host": "team_alpha", "client": "team_bravo"}, {"host": "team_bravo", "client": "team_alpha"}]:
		await _test_versus(case)
		await _test_coop(String(case["host"]))
	await _test_same_side_rejected()
	print("=== REVIEW7 SESSION VERSUS RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed == 0:
		print("REVIEW7_SESSION_VERSUS_ALL_PASSED")
	quit(1 if _failed > 0 else 0)


func _test_versus(case: Dictionary) -> void:
	var host: Node = _make_host()
	host.call("set_lobby_player_setup", {"team_play_mode": "versus", "team_slot": case["host"]})
	var assignments: Dictionary = Dictionary(host.call("build_session_assignments"))
	_assert(String(Dictionary(assignments.get("peer_teams", {})).get(1, "")) == String(case["host"]), "Versus preserves the selected host side %s" % case["host"])
	_assert(String(Dictionary(assignments.get("peer_teams", {})).get(2, "")) == String(case["client"]), "Versus assigns the client opposite host side %s" % case["host"])
	_assert(PackedStringArray(Dictionary(assignments.get("peer_fireteams", {})).get(1, [])) == PackedStringArray(["blue", "gold"]), "Versus preserves host Fireteam control")
	_assert(PackedStringArray(Dictionary(assignments.get("peer_fireteams", {})).get(2, [])) == PackedStringArray(["red"]), "Versus preserves client Fireteam control")
	host.call("set_peer_ready_for_test", 1, true)
	host.call("set_peer_ready_for_test", 2, true)
	_assert(bool(host.call("can_start_mission")), "Opposite ready sides allow versus mission start")
	host.queue_free()
	await process_frame


func _test_coop(side: String) -> void:
	var host: Node = _make_host()
	host.call("set_lobby_player_setup", {"team_play_mode": "coop", "team_slot": side})
	var assignments: Dictionary = Dictionary(host.call("build_session_assignments"))
	var teams: Dictionary = Dictionary(assignments.get("peer_teams", {}))
	_assert(String(teams.get(1, "")) == side and String(teams.get(2, "")) == side, "Coop keeps both peers on selected side %s" % side)
	var fireteams: Dictionary = Dictionary(assignments.get("peer_fireteams", {}))
	_assert(PackedStringArray(fireteams.get(1, [])) == PackedStringArray(["blue"]) and PackedStringArray(fireteams.get(2, [])) == PackedStringArray(["gold"]), "Coop keeps split non-overlapping Fireteams")
	host.call("set_peer_ready_for_test", 1, true)
	host.call("set_peer_ready_for_test", 2, true)
	_assert(bool(host.call("can_start_mission")), "Ready same-side coop session remains startable")
	host.call("set_lobby_player_setup", {"team_play_mode": "versus", "team_slot": side})
	teams = Dictionary(Dictionary(host.call("build_session_assignments")).get("peer_teams", {}))
	_assert(String(teams.get(1, "")) == side and String(teams.get(2, "")) != side, "Switching coop back to versus restores opposite client side")
	host.queue_free()
	await process_frame


func _test_same_side_rejected() -> void:
	var host: Node = _make_host()
	host.call("set_lobby_player_setup", {"team_play_mode": "versus", "team_slot": "team_alpha"})
	host.call("set_peer_ready_for_test", 1, true)
	host.call("set_peer_ready_for_test", 2, true)
	# Corrupt only the assignment boundary to exercise the start guard independently of rebalance.
	var peers: Dictionary = Dictionary(host.get("_peers_by_id")).duplicate(true)
	var peer_data: Dictionary = Dictionary(peers[2]).duplicate(true)
	peer_data["team_id"] = "team_alpha"
	peers[2] = peer_data
	host.set("_peers_by_id", peers)
	var starts: Array = []
	host.connect("mission_start_requested", func(assignments: Dictionary) -> void: starts.append(assignments))
	_assert(not bool(host.call("can_start_mission")), "Versus start guard rejects equal active peer sides")
	_assert(not bool(host.call("request_start_mission")) and starts.is_empty(), "Invalid same-side versus cannot emit a mission-start request")
	host.queue_free()
	await process_frame


func _make_host() -> Node:
	var host: Node = SESSION_SCRIPT.new()
	root.add_child(host)
	host.call("configure_host_state_for_test", [2])
	return host


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
