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
	var ids: PackedStringArray = setup.get("selected_team_unit_ids")
	_check(ids == PackedStringArray(["campaign_leader", "campaign_pilot"]), "Mission instantiates both real campaign IDs exactly once")
	var configs: Array = setup.get("selected_team_unit_configs")
	_check(configs.size() == 2 and String(Dictionary(configs.back()).get("unit_id", "")) == "campaign_pilot", "Pilot retains authoritative roster profile")
	_check(Array(flow.get("_all_team_units")).size() == 2, "No third roster person is generated")
	var controller: Node = mission.get_node("TacticalController")
	_check(controller.has_method("get_campaign_pilot_flight_guard"), "Flight guard is implemented at actual mission transport owner")
	mission.queue_free()
	flow.queue_free()
	await process_frame
	print("CAMPAIGN_PILOT_GROUND_HANDOFF failed=", failed)
	quit(1 if failed else 0)
func _check(value: bool, label: String) -> void:
	if not value: failed += 1
	print("PASS: " if value else "FAIL: ", label)
