extends SceneTree

const SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
var passed := 0
var failed := 0

func _init() -> void: call_deferred("run")

func run() -> void:
	print("=== TASK_1095 Connected Interaction Feedback Visual Polish ===")
	var scene := SCENE.instantiate(); root.add_child(scene); await process_frame
	var controller := scene.get_node("TacticalController")
	_assert(String(controller.call("_build_network_mission_interaction_display_token", "aa_shutdown_zone", "hold_zone")) == "AA", "AA token is compact")
	_assert(String(controller.call("_build_network_mission_interaction_display_token", "station_route_drill_door", "door")) == "DOOR", "Door token is compact")
	_assert(String(controller.call("_build_network_mission_interaction_display_token", "station_computer", "computer")) == "COM", "Computer token is compact")
	_assert(String(controller.call("_build_network_mission_interaction_display_token", "cargo_landing_hold", "hold_zone")) == "CARGO", "Cargo token is compact")
	controller.set("_network_mission_interaction_feedback", {"display_token":"COM"})
	controller.call("_apply_network_mission_interaction_result", {"accepted":true,"interaction_id":"station_computer","source_context":"mission_interaction_use_intent_command"})
	var ok := Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(String(ok.get("compact_line","")) == "COM HOST OK | LAEUFT" and String(ok.get("tone","")) == "success", "Accepted feedback is short and positive")
	controller.set("_network_mission_interaction_feedback", {"display_token":"DOOR"})
	controller.call("_apply_network_mission_interaction_result", {"accepted":false,"interaction_id":"station_route_drill_door","reason":"peer_team_mismatch","source_context":"mission_interaction_use_intent_command"})
	var blocked := Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(String(blocked.get("compact_line","")) == "DOOR BLOCKIERT | FALSCHES TEAM", "Wrong-team feedback is human readable")
	_assert(not String(blocked.get("compact_line","" )).contains("station_route_drill_door") and not String(blocked.get("compact_line","")).contains("peer_team_mismatch"), "Compact feedback hides technical identifiers")
	_assert(String(blocked.get("tone","")) == "blocked" and not String(blocked.get("detail_line","")).is_empty(), "Blocked feedback exposes tone and detail")
	scene.queue_free(); await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed]); quit(1 if failed else 0)

func _assert(ok: bool, text: String) -> void:
	if ok: passed += 1; print("PASS: %s" % text)
	else: failed += 1; push_error("FAIL: %s" % text)
