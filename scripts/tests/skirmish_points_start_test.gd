extends SceneTree

const CATALOG = preload("res://scripts/meta/skirmish_points_catalog.gd")
const START = preload("res://scripts/meta/game_start_contract.gd")
const SETUP = preload("res://scripts/meta/skirmish_start_configuration.gd")
const ROSTER = preload("res://scripts/meta/player_roster_store.gd")

var _checks := 0
var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var pilot := {"role": "pilot", "experience": "junior", "armor": "light", "weapon": "pistol"}
	var medic := {"role": "medic", "experience": "trained", "armor": "heavy", "weapon": "rifle"}
	var draft := {"budget": 1000, "ships": ["cutlass"], "people": [pilot, medic]}
	var purchase := CATALOG.evaluate(draft)
	_check(purchase.ok and purchase.spent == 650 and purchase.remaining == 350, "Catalog prices all purchases including medical equipment")
	var over_budget := draft.duplicate(true)
	over_budget.ships.append_array(["buccaneer", "buccaneer"])
	_check(not CATALOG.evaluate(over_budget).ok and CATALOG.evaluate(over_budget).remaining < 0, "Over budget blocked")
	var tampered := draft.duplicate(true)
	tampered.people[1].weapon = "invalid"
	_check(not CATALOG.evaluate(tampered).ok, "Unknown gear blocked")
	_check(not CATALOG.evaluate({"budget": 1500, "ships": ["cutlass"], "people": [medic]}).ok, "Pilot required")
	_check(not START.request_start(self, "campaign", "new", "", draft).ok, "Cannot attach draft to campaign")
	var configuration: Dictionary = SETUP.new().build_points_start(draft)
	_check(configuration.ok and configuration.roster.size() == 2 and configuration.crafts.size() == 1, "Build exactly the purchase")
	_check(configuration.roster[0].skill_values.accuracy == 0.55 and configuration.roster[1].dropship_piloting == 0.4, "Experience reaches the profile")
	var profile = load("res://scripts/meta/meta_unit_profile_builder.gd").build_from_identity_config(configuration.roster[0])
	_check(is_equal_approx(profile.skill_values.accuracy, 0.55) and profile.trait_ids.is_empty(),
		"Paid experience remains exact in effective profile")
	_check(load("res://scripts/meta/character_sheet_formatter.gd").get_experience_label(profile) == "Entspricht Vorlage: Mittelerfahren",
		"Character sheet discloses exact template equivalence without inventing provenance")
	var menu: Node = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var button = menu.find_child("SkirmishPointsStart", true, false)
	_check(button != null, "Main menu exposes points entry")
	if button != null:
		button.pressed.emit()
		var dialog: AcceptDialog = menu.get("_skirmish_points_dialog")
		_check(dialog != null and dialog.visible, "Main menu opens the draft")
		_check(dialog.find_child("StartBudget1000", true, false) != null and dialog.find_child("StartBudget1500", true, false) != null, "UI offers both base budgets")
		dialog.hide()
	menu.queue_free()
	await process_frame
	var team_path := ROSTER.get_save_path()
	var before := FileAccess.get_file_as_bytes(team_path) if FileAccess.file_exists(team_path) else PackedByteArray()
	_check(START.request_start(self, "skirmish", "new", "", draft).ok, "Start contract accepts purchase")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var loadout: Dictionary = flow.get_node("HomebaseScreen").call("_get_member_loadout", "skirmish_points_01")
	_check(loadout.get("armor") == "heavy" and loadout.get("weapon_1") == "rifle" and loadout.get("weapon_2") == "medictool", "Homebase owns purchased equipment")
	_check(flow.get("_all_team_units").size() == 2 and flow.get("_homebase_aircraft_definitions").size() == 1, "Actual flow owns the purchased roster and fleet")
	_check(flow.get_meta("skirmish_preset_id", "") == "points" and not flow.call("is_campaign_start"), "Fresh Skirmish with independent roster")
	var after := FileAccess.get_file_as_bytes(team_path) if FileAccess.file_exists(team_path) else PackedByteArray()
	_check(before == after, "Saved team bytes preserved")
	flow.queue_free()
	await process_frame
	print("Skirmish points: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
