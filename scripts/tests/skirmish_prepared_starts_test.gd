extends SceneTree

class MenuProbe:
	extends "res://scripts/ui/main_menu_screen.gd"
	var routed := ""
	func _change_scene(path: String) -> void:
		routed = path

var checks := 0
var failures := 0
func _init() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	var script = load("res://scripts/meta/skirmish_start_configuration.gd")
	if script == null:
		check(false, "Prepared Skirmish configuration exists")
		quit(1)
		return
	var config = script.new()
	for id in ["early", "mid", "late"]:
		var result: Dictionary = config.build_start(id)
		check(result.get("ok", false), "Authored preset builds: " + id)
		if not result.get("ok", false): continue
		var expected: int = {"early":8,"mid":20,"late":30}[id]
		check(result.roster.size() == expected, "Exact roster capacity: " + id)
		check(result.infrastructure.beds >= expected, "Every person has a bed: " + id)
		check(result.infrastructure.pads >= result.crafts.size(), "Every craft has a pad: " + id)
		check(result.staged_teams.size() == result.staged_units.size(), "Every ground operator has a parallel team assignment")
		for team_id in result.staged_teams: check(not String(team_id).is_empty(), "Ground team assignment is explicit")
		var ids := {}
		for unit: Dictionary in result.roster:
			check(not ids.has(unit.unit_id), "Stable unique identities")
			ids[unit.unit_id] = true
			var loadout: Dictionary = result.member_loadouts[unit.unit_id]
			check(loadout.weapon_1 == "rifle" and loadout.armor in ["medium","heavy"], "Real assault rifle and armor loadout")
		for craft: Dictionary in result.crafts:
			check(ids.has(result.pilots[craft.craft_id]), "Every craft has a real roster pilot")
		var again: Dictionary = config.build_start(id)
		check(result == again, "Deterministic restart without saved-team mutation: " + id)
	var early: Dictionary = config.build_start("early")
	check(early.crafts.size() == 3 and early.crafts[0].model_id == "cutlass", "Early has one Cutlass and two fighters")
	check(early.crafts[1].model_id == "buccaneer" and early.crafts[2].model_id == "buccaneer", "Both Early fighters are Buccaneer")
	check(not config.build_start("unknown").get("ok", true), "Unknown preset rejected")
	var contract = load("res://scripts/meta/game_start_contract.gd")
	check(contract.request_start(self, "skirmish", "new", "early").ok, "Preset start command accepted")
	check(contract.consume_start(self).get("preset_id") == "early", "Preset survives one-shot route")
	check(not contract.consume_start(self).has("preset_id"), "Preset metadata consumed once")
	check(not contract.request_start(self, "campaign", "new", "early").ok, "Campaign cannot inherit Skirmish preset")
	check(not contract.request_start(self, "skirmish", "new", "unknown").ok, "Invalid preset cannot route")
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	menu.set_script(MenuProbe)
	menu.set("_start_roster_profile_id", "skirmish_prepared_test")
	menu.set("_start_roster_save_path", "user://profiles/skirmish_prepared_test/roster_v1.json")
	root.add_child(menu)
	await process_frame
	var roster_path := "user://profiles/skirmish_prepared_test/roster_v1.json"
	var before := FileAccess.get_file_as_bytes(roster_path)
	menu.get_node("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton").pressed.emit()
	check(menu.get("_skirmish_dialog").visible, "Skirmish button opens explicit start selection")
	for id in ["early", "mid", "late"]:
		menu.routed = ""
		menu.find_child("SkirmishPreset_" + id, true, false).pressed.emit()
		check(menu.routed.ends_with("meta_layer_test.tscn"), "Real preset button routes: " + id)
		check(contract.consume_start(self).get("preset_id") == id, "Real button passes authored ID: " + id)
	check(FileAccess.get_file_as_bytes(roster_path) == before, "Selection preserves saved roster bytes")
	menu.find_child("SkirmishOwnTeam", true, false).pressed.emit()
	check(not contract.consume_start(self).has("preset_id"), "Own-team start remains available")
	menu.free()
	print("Prepared Skirmish: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
