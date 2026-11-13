extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const CONTEXT := preload("res://scripts/tests/review_interaction_fixture_context.gd")
const PORT := 19472
var passed := 0
var failed := 0

func _init() -> void: call_deferred("run")

func run() -> void:
	print("=== TASK_1094 Connected Client GO Interaction RPC Handoff ===")
	var hp := ENetMultiplayerPeer.new(); var cp := ENetMultiplayerPeer.new()
	_assert(hp.create_server(PORT, 2) == OK and cp.create_client("127.0.0.1", PORT) == OK, "ENet pair starts")
	var ha := MultiplayerAPI.create_default_interface(); var ca := MultiplayerAPI.create_default_interface()
	ha.multiplayer_peer = hp; ca.multiplayer_peer = cp
	for _i in range(120): ha.poll(); ca.poll(); await process_frame
	var hr := Node.new(); var cr := Node.new(); root.add_child(hr); root.add_child(cr)
	set_multiplayer(ha, hr.get_path()); set_multiplayer(ca, cr.get_path())
	var hs := MISSION_SCENE.instantiate(); var cs := MISSION_SCENE.instantiate(); hs.name="Mission"; cs.name="Mission"
	for scene in [hs, cs]:
		scene.get_node("SimulationRoot").set("is_server_authoritative", true)
		scene.get_node("MissionSetup").set("defer_friendly_runtime_activation", false)
		scene.get_node("CombatLoopDriver").call("set_combat_startup_grace_ticks", 100000)
	hr.add_child(hs); cr.add_child(cs)
	for _i in range(12): ha.poll(); ca.poll(); await process_frame
	var hsim := hs.get_node("SimulationRoot"); var csim := cs.get_node("SimulationRoot"); var cc := cs.get_node("TacticalController")
	var fireteam := String(PackedStringArray(cc.call("_get_available_fireteam_ids"))[0]); var peer_id := ca.get_unique_id()
	for sim in [hsim, csim]:
		sim.set("is_server_authoritative", true); sim.call("set_peer_team_assignments", {1:"team_alpha",peer_id:"team_alpha"}); sim.call("set_peer_role",1,"host"); sim.call("set_peer_role",peer_id,"commander"); sim.call("set_peer_fireteam_assignments",{peer_id:[fireteam]})
	_assert(CONTEXT.bind_pair(hs, cs, "task1094_go"), "Both real Hex scenes bind the verified map session")
	for _i in range(12): ha.poll(); ca.poll(); await process_frame
	cc.call("_set_selected_fireteams", PackedStringArray([fireteam]), false)
	var terrain = hs.get_node("MissionSetup").get("_loaded_terrain_map_data")
	_assert(terrain != null and terrain.has_marker("objective_point"), "GO target is an authored Host map marker")
	var target: Vector2 = terrain.get_marker_position("objective_point")
	var slice := {"flow_steps":[{"step_id":"disable_air_defense", "objective_type":"air_defense_shutdown", "target_marker_id":"objective_point", "required_state":"aa_disabled", "min_hold_seconds":0.0}], "interaction_points":[{"interaction_id":"aa_shutdown_zone", "interaction_type":"hold_zone", "marker_id":"objective_point", "required_order":"take", "required_team":"team_alpha", "duration_seconds":0.0, "radius_world":160.0, "step_id":"disable_air_defense", "gate_id":"disable_air_defense", "required_state":"aa_disabled"}]}
	for scene in [hs, cs]:
		_assert(scene.get_node("CombatLoopDriver").call("configure_scenario_runtime_gates", slice), "Real interaction owner receives authored AA binding")
	cc.set("_last_mission_interaction_use_intent_snapshot", {"accepted":true,"requires_go":true,"interaction_id":"aa_shutdown_zone","interaction_type":"hold_zone","fireteam_id":fireteam,"command_type":"take","required_order":"take","duration_seconds":0.0,"step_id":"disable_air_defense","gate_id":"disable_air_defense","required_state":"aa_disabled","target_position":target,"phase":0})
	var before := int(Dictionary(hsim.call("get_network_command_contract_snapshot")).get("accepted_count",0))
	_assert(bool(cc.call("execute_selected_fireteam_orders")), "Connected client GO sends Interaction request")
	_assert(not bool(cc.call("execute_selected_fireteam_orders")), "Second GO is blocked while Host response is pending")
	for _i in range(24): ha.poll(); ca.poll(); await process_frame
	var after := int(Dictionary(hsim.call("get_network_command_contract_snapshot")).get("accepted_count",0))
	var feedback := Dictionary(cc.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(after == before + 1, "Host receives exactly one GO request")
	_assert(String(feedback.get("status","")) == "accepted", "Client receives Host OK feedback")
	_assert(Array(csim.get("command_queue")).is_empty(), "Client GO enqueues no local command")
	cp.close(); hp.close(); hr.queue_free(); cr.queue_free(); await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed]); quit(1 if failed else 0)

func _assert(ok: bool, text: String) -> void:
	if ok: passed += 1; print("PASS: %s" % text)
	else: failed += 1; push_error("FAIL: %s" % text)
