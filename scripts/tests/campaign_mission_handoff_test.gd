extends SceneTree
var failed := 0
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var mission: Node = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	flow.call("_configure_mission_instance", mission, PackedStringArray(["campaign_leader"]), PackedStringArray(["ft1"]), false)
	root.add_child(mission)
	await process_frame
	await process_frame
	var setup: Node = mission.get_node("MissionSetup")
	var driver: Node = mission.get_node("CombatLoopDriver")
	_check(setup.get("_mission_scenario") != null, "Campaign handoff loads actual scenario resource")
	_check(not Dictionary(driver.call("get_mission_scenario_runtime_gate_snapshot")).is_empty(), "Campaign mission has real scenario gates")
	var configs: Array = setup.get("selected_team_unit_configs")
	var config: Dictionary = {}
	for unit: Dictionary in configs:
		if String(unit.get("unit_id", "")) == "campaign_leader":
			config = unit
	_check(String(config.get("display_name", "")) == "Anja Voss", "Actual campaign leader profile crosses mission boundary")
	print("HANDOFF_DIAGNOSTIC:", var_to_str({"setup_ready": setup.get("_is_initialized"), "scenario_path": setup.get("scenario_file_path"), "configs": configs, "gates": driver.call("get_mission_scenario_runtime_gate_snapshot")}))
	mission.queue_free()
	flow.queue_free()
	await process_frame
	print("CAMPAIGN_HANDOFF failed=", failed)
	quit(1 if failed else 0)
func _check(value: bool, label: String) -> void:
	if not value:
		failed += 1
	print("PASS: " if value else "FAIL: ", label)
