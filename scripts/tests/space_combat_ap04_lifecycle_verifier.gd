extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
class FlowStub extends Node:
	var _assigned_aircraft_pilot_by_craft := {"a":"pilot_a","b":"pilot_b"}
	var _homebase_aircraft_definitions := [{"craft_id":"a"},{"craft_id":"b"}]

func _initialize() -> void:
	var failed := 0
	var flow := FlowStub.new()
	var fleet = FLEET.new()
	fleet.configure()
	fleet.register_craft("a")
	fleet.register_craft("b")
	var sim = ROOT.new()
	sim.configure_singleplayer_owners(null, null, null, fleet)
	var adapter = ADAPTER.new()
	adapter.set("_flow", flow)
	adapter.set("_travel", fleet)
	adapter.set("_simulation", sim)
	var commands: Array[Dictionary] = [
		{"contract_category":"space_combat","operation":"wing_create","request_id":"1","expected_revision":0,"payload":{"wing_id":"w"}},
		{"contract_category":"space_combat","operation":"wing_assign","request_id":"2","expected_revision":1,"payload":{"wing_id":"w","craft_id":"a"}},
		{"contract_category":"space_combat","operation":"wing_assign","request_id":"3","expected_revision":2,"payload":{"wing_id":"w","craft_id":"b"}}
	]
	for command in commands:
		if not adapter.request_operation("space_wing_command", {"command":command}).get("ok", false): failed += 1
	var before: Dictionary = sim.get_space_wing_snapshot()
	flow._assigned_aircraft_pilot_by_craft.b = "pilot_a"
	if adapter.sync_space_wings().get("reason") != "pilot_already_assigned": failed += 1
	if sim.get_space_wing_snapshot() != before: failed += 1
	flow._assigned_aircraft_pilot_by_craft.erase("a")
	flow._assigned_aircraft_pilot_by_craft.b = "pilot_b"
	if not adapter.sync_space_wings().get("changed", false): failed += 1
	var wing: Dictionary = sim.get_space_wing_snapshot().wings.w
	if wing.leader_craft_id != "b" or wing.craft_ids != ["a","b"]: failed += 1
	flow._assigned_aircraft_pilot_by_craft.erase("b")
	adapter.sync_space_wings()
	wing = sim.get_space_wing_snapshot().wings.w
	if wing.active or not String(wing.leader_craft_id).is_empty() or wing.craft_ids.size() != 2: failed += 1
	var choose := {"contract_category":"space_combat","operation":"wing_leader_set","request_id":"choose","expected_revision":sim.get_space_wing_snapshot().revision,"payload":{"wing_id":"w","leader_craft_id":"a"}}
	if adapter.request_operation("space_wing_command", {"command":choose}).get("reason") != "pilot_missing": failed += 1
	flow._homebase_aircraft_definitions = [{"craft_id":"b"}]
	adapter.sync_space_wings()
	if sim.get_space_wing_snapshot().wings.w.craft_ids != ["b"]: failed += 1
	flow._homebase_aircraft_definitions = []
	adapter.sync_space_wings()
	if sim.get_space_wing_snapshot().wings.has("w"): failed += 1
	if sim.reconcile_space_wings([], {}, {}).get("reason") != "runtime_authority_required": failed += 1
	adapter.free()
	sim.free()
	flow.free()
	print("SPACE_COMBAT_AP04_LIFECYCLE passed=", 12 - failed, " failed=", failed)
	quit(1 if failed else 0)
