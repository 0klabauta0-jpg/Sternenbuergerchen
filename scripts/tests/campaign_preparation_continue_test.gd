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
	var personnel: Node = screen.call("get_base_personnel_runtime")
	var initial_people: Array = personnel.call("get_snapshot").get("units", [])
	_check(initial_people.size() == 2 and initial_people.all(func(person: Dictionary): return String(person.status) == "outside"), "Both actual base people begin outside")
	# People now deliberately start outside; preparation must not depend on
	# the retired automatic boarding bootstrap.
	var unboard: Dictionary = screen.call("request_operation", "unboard", {"craft_id": craft, "fireteam_id": "ft1"})
	_check(not bool(unboard.get("ok", false)) and String(unboard.get("reason", "")) == "not_aboard", "New campaign begins outside without automatic boarding")
	_check(screen.call("request_operation", "add_fireteam", {}).get("ok", false), "Create a second preparation group")
	_check(screen.call("request_operation", "assign", {"unit_id": "campaign_leader", "fireteam_id": "ft2"}).get("ok", false), "Move leader into second real group")
	var adapter: Node = flow.get("_singleplayer_runtime")
	# Seit 21.11.2026 (Auftrag P1) liegt keine leichte Ruestung im Startlager; die Vorbereitung wird mit dem Sanitaetsgeraet
	# (Waffe 2: laesst sich ueber die Oberflaeche auch wieder zurueckgeben) geprueft statt mit Ruestung.
	var stock_before: int = int(adapter.get_snapshot().supply.inventory["base:homebase"].items.get("medictool", 0))
	var starting_loadout: Dictionary = screen.call("_get_member_loadout", "campaign_leader")
	_check(String(starting_loadout.get("armor", "")) == "suit" and String(starting_loadout.get("weapon_1", "")) == "none" and String(starting_loadout.get("weapon_2", "")) == "none", "New campaign begins in undersuit without weapons: " + str(starting_loadout))
	_check(stock_before == 1, "Main campaign starts with one stored medic tool")
	_check(screen.call("request_operation", "loadout", {"unit_id": "campaign_leader", "fireteam_id": "ft2", "key": "weapon_2", "value": "medictool"}).get("ok", false), "Equip the owned medic tool")
	_check(int(adapter.get_snapshot().supply.inventory["base:homebase"].items.get("medictool", 0)) == stock_before - 1, "Equipped medic tool leaves base inventory")
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
	_check(String(Dictionary(loadouts.get("campaign_leader", {})).get("weapon_2", "")) == "medictool", "Continue preserves edited member equipment")
	var unequip: Dictionary = screen.call("request_operation", "loadout", {"unit_id":"campaign_leader", "fireteam_id":"ft2", "key":"weapon_2", "value":"none"})
	_check(unequip.get("ok", false), "Restored person can remove the medic tool: " + str(unequip))
	_check(int(flow.get("_singleplayer_runtime").get_snapshot().supply.inventory["base:homebase"].items.get("medictool", 0)) == stock_before, "Removed medic tool returns to base inventory")
	_check(Array(flow.get("_all_team_units")).size() == 2, "Preparation resume never creates additional NPCs")
	var restored_runtime: Node = flow.get("_singleplayer_runtime")
	var restored: Dictionary = restored_runtime.call("get_snapshot")
	_check(String(restored.space_travel.phase) == "grounded", "Preparation checkpoint resumes before any orbital departure")
	var restored_people: Array = restored_runtime.call("get_base_personnel_runtime").call("get_snapshot").get("units", [])
	_check(restored_people.size() == 2 and restored_people.all(func(person: Dictionary): return String(person.status) == "outside"), "Continue preserves real outside presence without automatic boarding")
	flow.queue_free()
	await process_frame
	print("CAMPAIGN_PREPARATION failed=", failed)
	quit(1 if failed else 0)
func _check(value: bool, label: String) -> void:
	if not value:
		failed += 1
	print("PASS: " if value else "FAIL: ", label)
