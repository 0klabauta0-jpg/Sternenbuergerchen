extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
const FLOW = preload("res://scenes/meta/meta_layer_test.tscn")
var failed := 0
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	START.request_start(self, "campaign", "new")
	var flow: Node = FLOW.instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Control = flow.get_node("HomebaseScreen")
	var craft: String = String(flow.get_meta("singleplayer_bootstrap_craft_id"))
	_check(screen.call("request_operation", "unboard", {"craft_id": craft, "fireteam_id": "ft1"}).get("ok", false), "Unboard campaign leader for preparation")
	_check(screen.call("request_operation", "add_fireteam", {}).get("ok", false), "Create a second preparation group")
	_check(screen.call("request_operation", "assign", {"unit_id": "campaign_leader", "fireteam_id": "ft2"}).get("ok", false), "Move leader into second real group")
	_check(screen.call("request_operation", "loadout", {"unit_id": "campaign_leader", "fireteam_id": "ft2", "key": "weapon_1", "value": "smg"}).get("ok", false), "Change actual campaign loadout")
	_check(screen.call("request_operation", "pilot", {"craft_id": craft, "unit_id": ""}).get("ok", false), "Pilot can be unassigned at home")
	var result: Dictionary = flow.get("_campaign_start").call("save_home_checkpoint", flow, flow.get("_singleplayer_runtime"))
	_check(result.get("ok", false), "Valid unfinished preparation saves without silently reverting")
	if not result.get("ok", false):
		print("SAVE_RESULT:", result)
		flow.queue_free()
		await process_frame
		quit(1)
		return
	flow.queue_free()
	await process_frame
	START.request_start(self, "campaign", "continue")
	flow = FLOW.instantiate()
	root.add_child(flow)
	await process_frame
	screen = flow.get_node("HomebaseScreen")
	_check(String(Dictionary(flow.get("_assigned_aircraft_pilot_by_craft")).get(craft, "")).is_empty(), "Continue preserves intentionally unassigned pilot")
	_check(PackedStringArray(flow.get("_homebase_staged_fireteam_ids")) == PackedStringArray(["ft2"]), "Continue preserves chosen second group")
	var loadouts: Dictionary = screen.get("_member_loadout_by_unit_id")
	_check(String(Dictionary(loadouts.get("campaign_leader", {})).get("weapon_1", "")) == "smg", "Continue preserves edited member equipment")
	_check(Array(flow.get("_all_team_units")).size() == 2, "Preparation resume never creates additional NPCs")
	flow.queue_free()
	await process_frame
	print("CAMPAIGN_PREPARATION failed=", failed)
	quit(1 if failed else 0)
func _check(value: bool, label: String) -> void:
	if not value:
		failed += 1
	print("PASS: " if value else "FAIL: ", label)
