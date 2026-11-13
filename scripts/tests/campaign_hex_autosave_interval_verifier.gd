extends SceneTree
const START = preload("res://scripts/meta/campaign_start_configuration.gd")
var failed := 0
var passed := 0

class FakeSimulation extends Node:
	var required := true
	var revision := 1
	func is_hex_ground_runtime_required() -> bool: return required
	func get_hex_ground_context_revision() -> int: return revision

class FakeRuntime extends Node:
	var _simulation: Node
	var guard := {"ok": true}
	var exports := 0
	var travel := {"phase":"grounded"}
	func get_world_checkpoint_guard() -> Dictionary: return guard
	func get_space_travel_snapshot() -> Dictionary: return travel
	func export_campaign_checkpoint() -> Dictionary:
		exports += 1
		return {} # Deliberate unsuccessful save; checks export timing without touching user data.

class FakeFlow extends Node:
	var _active_mission = null
	var _pending_mission_craft_transfers: Array = []
	var _pending_homebase_team_transfers: Array = []
	var _pending_homebase_pilot_transfers: Array = []
	var _pending_homebase_cargo_loads: Array = []
	var _homebase_aircraft_definitions := [{"craft_id":"probe"}]
	var _aircraft_location_by_craft := {"probe":"homebase"}

func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value: failed += 1
	else: passed += 1

func run() -> void:
	var start = START.new()
	check(start.HEX_AUTOSAVE_INTERVAL_MSEC == 300000, "interval is exactly five minutes")
	start._hex_export_scope = "scope"; start._hex_export_msec = 1000
	check(start._hex_save_throttled("scope", 300999, false), "one millisecond before boundary is throttled")
	check(not start._hex_save_throttled("scope", 301000, false), "exact boundary is allowed")
	check(not start._hex_save_throttled("scope", 1001, true), "force bypasses interval")
	check(not start._hex_save_throttled("other", 1001, false), "new scope saves immediately")
	var flow := FakeFlow.new(); root.add_child(flow)
	var sim := FakeSimulation.new(); root.add_child(sim)
	var runtime := FakeRuntime.new(); runtime._simulation = sim; root.add_child(runtime)
	start = START.new()
	var first: Dictionary = start.save_home_checkpoint(flow, runtime)
	check(first.get("reason") == "runtime_unavailable" and runtime.exports == 1, "first call attempts export")
	var next: Dictionary = start.save_home_checkpoint(flow, runtime)
	check(not next.get("ok",true) and next.get("retry_pending",false) and runtime.exports == 1 and start._hex_export_scope.is_empty(), "failed export has a short bounded retry and never claims a saved checkpoint")
	var forced: Dictionary = start.save_home_checkpoint(flow, runtime, true)
	check(forced.get("reason") == "runtime_unavailable" and runtime.exports == 2, "forced save bypasses interval")
	runtime.guard = {"ok":false,"reason":"pending_cargo"}
	check(start.save_home_checkpoint(flow, runtime, true).get("reason") == "pending_cargo" and runtime.exports == 2, "force does not bypass owner guard")
	runtime.guard = {"ok":true}
	for pending in ["_pending_homebase_team_transfers", "_pending_homebase_pilot_transfers", "_pending_homebase_cargo_loads"]:
		flow.get(pending).append({})
		check(start.save_home_checkpoint(flow, runtime, true).get("reason") == "preparation_in_progress" and runtime.exports == 2, "force does not bypass " + pending)
		flow.get(pending).clear()
	flow._pending_mission_craft_transfers.append({})
	check(start.save_home_checkpoint(flow, runtime, true).get("reason") == "away_from_checkpoint" and runtime.exports == 2, "force does not bypass pending mission transfer")
	flow._pending_mission_craft_transfers.clear()
	flow._active_mission = Node.new()
	check(start.save_home_checkpoint(flow, runtime, true).get("reason") == "away_from_checkpoint" and runtime.exports == 2, "force does not bypass active mission")
	flow._active_mission.free(); flow._active_mission = null
	runtime.travel = {"phase":"quantum"}
	check(start.save_home_checkpoint(flow, runtime, true).get("reason") == "away_from_checkpoint" and runtime.exports == 2, "force does not bypass active travel")
	runtime.travel = {"phase":"grounded"}
	flow._aircraft_location_by_craft.probe = "polisa"
	check(start.save_home_checkpoint(flow, runtime, true).get("reason") == "away_from_checkpoint" and runtime.exports == 2, "force does not bypass remote craft")
	flow._aircraft_location_by_craft.probe = "homebase"
	start._hex_failed_msec = Time.get_ticks_msec() - start.HEX_AUTOSAVE_RETRY_MSEC
	var retried: Dictionary = start.save_home_checkpoint(flow,runtime)
	check(retried.get("reason")=="runtime_unavailable" and not retried.get("retry_pending",false) and runtime.exports==3,"failed initialization retries at the short boundary without waiting five minutes")
	runtime.free(); sim.free(); flow.free()
	if failed == 0: print("CAMPAIGN_HEX_AUTOSAVE_INTERVAL_PASS")
	print("CAMPAIGN_HEX_AUTOSAVE_INTERVAL passed=%d failed=%d" % [passed,failed])
	quit(0 if failed == 0 else 1)
