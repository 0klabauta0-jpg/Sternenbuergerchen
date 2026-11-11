extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")

class FlowStub extends Node:
	var _assigned_aircraft_pilot_by_craft := {"a":"pilot_a"}

func _initialize() -> void:
	var failed := 0
	var flow := FlowStub.new()
	var fleet = FLEET.new()
	fleet.configure()
	fleet.register_craft("a")
	var sim = ROOT.new()
	sim.configure_singleplayer_owners(null, null, null, fleet)
	var adapter = ADAPTER.new()
	adapter.set("_flow", flow)
	adapter.set("_travel", fleet)
	adapter.set("_simulation", sim)
	var create := {"contract_category":"space_combat", "operation":"wing_create", "request_id":"create", "expected_revision":0, "payload":{"wing_id":"w"}}
	if not adapter.request_operation("space_wing_command", {"command":create}).get("ok", false): failed += 1
	var assign := {"contract_category":"space_combat", "operation":"wing_assign", "request_id":"assign", "expected_revision":1, "payload":{"wing_id":"w", "craft_id":"a"}}
	if not adapter.request_operation("space_wing_command", {"command":assign}).get("ok", false): failed += 1
	if sim.get_space_wing_snapshot().wings.w.craft_ids != ["a"]: failed += 1
	var foreign := assign.duplicate(true)
	foreign.request_id = "foreign"
	foreign.expected_revision = 2
	foreign.payload.craft_id = "other"
	if adapter.request_operation("space_wing_command", {"command":foreign, "owned_crafts":["other"]}).get("reason") != "unknown_craft": failed += 1
	fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"launch_to_orbit", "payload":{"craft_id":"a"}, "request_id":"l"}, {"runtime_authorized":true})
	fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"start_quantum", "payload":{"craft_id":"a", "target_orbit_id":"planet_orbit"}, "request_id":"j"})
	if not adapter.request_operation("space_wing_command", {"command":assign}).get("replayed", false): failed += 1
	var altered := assign.duplicate(true)
	altered.payload.craft_id = "other"
	if adapter.request_operation("space_wing_command", {"command":altered}).get("reason") != "request_id_conflict": failed += 1
	altered.payload["bad"] = {3:"bad"}
	if adapter.request_operation("space_wing_command", {"command":altered}).get("reason") != "invalid_payload": failed += 1
	var remove := {"contract_category":"space_combat", "operation":"wing_remove", "request_id":"remove", "expected_revision":2, "payload":{"wing_id":"w", "craft_id":"a"}}
	if adapter.request_operation("space_wing_command", {"command":remove}).get("reason") != "craft_busy": failed += 1
	if sim.get_space_wing_snapshot().wings.w.craft_ids != ["a"]: failed += 1
	adapter.free()
	sim.free()
	flow.free()
	print("SPACE_COMBAT_AP04_ADAPTER passed=", 9 - failed, " failed=", failed)
	quit(1 if failed else 0)
