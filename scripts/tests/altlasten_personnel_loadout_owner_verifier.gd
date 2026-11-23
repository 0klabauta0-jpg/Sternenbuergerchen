extends SceneTree

var passed := 0
var failed := 0
var _screen: Node
var _commit_observations: Array = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
	print("PASS: " if condition else "FAIL: ", label)


func _observe_commit(command: Dictionary, result: Dictionary) -> void:
	if String(command.get("operation", "")) != "inventory_equip" or not bool(result.get("ok", false)) or bool(result.get("replayed", false)):
		return
	var id: String = String(command.payload.unit_id)
	_commit_observations.append(_screen.call("_get_member_loadout", id) == result.loadout)


func _run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	_screen = flow.get_node("HomebaseScreen")
	var runtime: Node = flow.get("_singleplayer_runtime")
	var simulation: Node = runtime.get("_simulation")
	_check(simulation.has_method("get_personnel_loadout_state"), "SimulationRoot exposes the single personnel loadout owner")
	var before: Dictionary = _screen.call("_get_member_loadout", "campaign_leader")
	var view: Dictionary = _screen.get("_member_loadout_by_unit_id")
	view["campaign_leader"]["weapon_1"] = "rail_gun"
	_check(_screen.call("_get_member_loadout", "campaign_leader") == before, "Compatibility loadout snapshots cannot mutate equipped gear")
	# Restore the pre-test value on the old implementation so the signal check
	# independently reproduces the inventory commit ordering bug.
	_screen.call("_set_homebase_member_loadout_value", "campaign_leader", "weapon_1", String(before.weapon_1))
	simulation.singleplayer_command_committed.connect(_observe_commit)
	var equip := {"unit_id": "campaign_pilot", "source_container_id": "base:homebase", "slot": "weapon_1", "item_id": "medictool", "request_id": "loadout-first"}
	var result: Dictionary = _screen.call("request_operation", "inventory_equip", equip)
	_check(bool(result.get("ok", false)), "Unassigned outside pilot equips finite inventory through the normal request")
	_check(not _commit_observations.is_empty() and bool(_commit_observations[0]), "Committed signal observes both inventory and equipped loadout already committed")
	equip["item_id"] = "pistol"  # das Basislager enthaelt kein "rifle" mehr (nur pistol, ammo_light, ammo_rifle)
	equip["request_id"] = "loadout-second"
	_check(bool(_screen.call("request_operation", "inventory_equip", equip).get("ok", false)), "A second equipment swap succeeds")
	var state: Dictionary = runtime.call("get_snapshot")
	var second_loadout: Dictionary = _screen.call("_get_member_loadout", "campaign_pilot")
	equip["item_id"] = "medictool"
	equip["request_id"] = "loadout-first"
	var replay: Dictionary = _screen.call("request_operation", "inventory_equip", equip)
	_check(bool(replay.get("replayed", false)) and _screen.call("_get_member_loadout", "campaign_pilot") == second_loadout, "Replaying the first receipt cannot restore stale equipment")
	_check(runtime.call("get_snapshot").supply == state.supply, "Equipment replay leaves inventory unchanged")
	_check(_commit_observations.all(func(value: bool): return value), "Every successful new equipment signal sees committed personnel state")
	if simulation.has_method("get_personnel_loadout_state"):
		var owner: RefCounted = simulation.call("get_personnel_loadout_state")
		var snapshot: Dictionary = owner.call("get_snapshot")
		snapshot["campaign_pilot"]["weapon_1"] = "sniper"
		_check(_screen.call("_get_member_loadout", "campaign_pilot") == second_loadout, "Core owner snapshots are isolated from their consumers")
		_screen.hide()
		flow.call("_refresh_homebase_screen")
		_check(_screen.call("_get_member_loadout", "campaign_pilot") == second_loadout, "Unassigned pilot equipment survives hidden presentation refresh")
		var definitions: Array = _screen.call("_get_fireteam_definitions_snapshot")
		for definition: Dictionary in definitions:
			if Dictionary(definition.get("member_loadouts", {})).has("campaign_leader"):
				definition.member_loadouts.campaign_leader.weapon_1 = "sniper"
		_check(_screen.call("_get_member_loadout", "campaign_leader") == before, "Fireteam export is a projection and cannot change canonical equipment")
		definitions = _screen.call("_get_fireteam_definitions_snapshot")
		for definition: Dictionary in definitions:
			if Dictionary(definition.get("member_loadouts", {})).has("campaign_leader"):
				definition.member_loadouts.campaign_leader.weapon_1 = "sniper"
		_screen.call("set_fireteam_context", _screen.call("get_selected_fireteam_ids"), definitions)
		_check(String(_screen.call("_get_member_loadout", "campaign_leader").weapon_1) == "sniper", "Explicit compatibility context imports an intentional equipment change")
		flow.call("_refresh_homebase_screen")
		_check(String(_screen.call("_get_member_loadout", "campaign_leader").weapon_1) == "sniper", "An ordinary FOB presentation refresh cannot overwrite equipped gear")
	flow.queue_free()
	await process_frame
	print("PERSONNEL_LOADOUT_OWNER passed=", passed, " failed=", failed)
	quit(1 if failed else 0)
