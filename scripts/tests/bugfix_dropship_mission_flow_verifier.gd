extends SceneTree

const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Dropship Mission Bugfix Verifier ===")
	await _test_fob_refresh_preserves_boarded_units()
	await _test_mission_start_requires_boarded_team()
	await _test_meta_mission_uses_deferred_drop_state()
	await _test_combat_loop_waits_for_pending_insertions()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_fob_refresh_preserves_boarded_units() -> void:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta"])
	var selected_fireteam_ids := PackedStringArray(["blue", "blue", "blue"])
	var fireteam_definitions := [
		{
			"id": "blue",
			"label": "BLUE",
			"lead_unit_id": "unit_alpha",
			"respawn_enabled": false,
			"loadout": "medium",
		}
	]
	screen.call("set_available_units", UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster"))
	screen.call(
		"set_transport_craft_state",
		[
			{
				"craft_id": "dropship_test",
				"display_name": "Dropship Test",
				"visible_in_fob": true,
				"is_boardable": true,
			}
		]
	)
	screen.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	screen.call("_queue_fireteam_for_dropship", "blue", "dropship_test")
	screen.set("_dropship_phase", "boarded")
	screen.set("_boarded_unit_ids", selected_unit_ids)
	screen.set("_boarded_fireteam_ids", PackedStringArray(["blue"]))

	var drop_state_before_refresh: Dictionary = Dictionary(screen.call("build_mission_drop_state"))
	screen.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	var drop_state_after_refresh: Dictionary = Dictionary(screen.call("build_mission_drop_state"))
	_assert(String(screen.get("_dropship_phase")) == "boarded", "FOB keeps boarded phase after a same-state refresh")
	_assert(Array(drop_state_before_refresh.get("embarked_unit_ids", [])).size() == 3, "FOB boards all queued members before the refresh check")
	_assert(Array(drop_state_after_refresh.get("embarked_unit_ids", [])).size() == 3, "FOB refresh no longer wipes boarded unit progress")
	screen.queue_free()
	await process_frame


func _test_meta_mission_uses_deferred_drop_state() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	var mission_setup: Node = scene.get_node("MissionSetup")
	mission_setup.set("defer_friendly_runtime_activation", true)
	var tactical_controller: Node = scene.get_node("TacticalController")
	tactical_controller.call(
		"set_planning_state",
		{
			"has_lz_position": true,
			"lz_position": Vector2(320.0, 180.0),
			"selected_fireteam": "BLUE",
			"selected_fireteams": ["blue"],
			"embarked_unit_ids": ["unit_alpha", "unit_bravo", "unit_delta"],
			"deployed_unit_ids": [],
		}
	)
	root.add_child(scene)
	for _frame in range(8):
		await process_frame

	var unit_registry: Node = scene.get_node("UnitRegistry")
	var blue_drop_units: Array = Array(tactical_controller.call("_get_units_for_drop_operation"))
	var blue_units: Array = Array(tactical_controller.call("_get_fireteam_units", "blue", true))
	var gold_units: Array = Array(tactical_controller.call("_get_fireteam_units", "gold", true))
	var all_blue_hidden: bool = true
	for unit in blue_units:
		if unit is CanvasItem and (unit as CanvasItem).visible:
			all_blue_hidden = false
			break
	var all_gold_hidden: bool = true
	for unit in gold_units:
		if unit is CanvasItem and (unit as CanvasItem).visible:
			all_gold_hidden = false
			break

	tactical_controller.call("_on_call_dropship_pressed")

	_assert(unit_registry.has_method("has_unit") and not bool(unit_registry.call("has_unit", "unit_alpha")), "Deferred mission start keeps embarked units out of UnitRegistry")
	_assert(all_blue_hidden, "Embarked blue units stay hidden before the dropship is called")
	_assert(all_gold_hidden, "Non-dropped friendly units stay hidden on the mission map")
	_assert(blue_drop_units.size() == 3, "Drop operation prefers the already embarked fireteam members")
	_assert(String(tactical_controller.get("_drop_sequence_phase")) == "inbound", "Calling the dropship starts the live inbound sequence for embarked units")
	scene.queue_free()
	await process_frame


func _test_mission_start_requires_boarded_team() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	var fob_screen: Control = scene.get_node("FOBScreen")
	var start_button := scene.get_node("FOBScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/StartMissionButton") as Button
	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta"])
	var selected_fireteam_ids := PackedStringArray(["blue", "blue", "blue"])
	var fireteam_definitions := [
		{
			"id": "blue",
			"label": "BLUE",
			"lead_unit_id": "unit_alpha",
			"respawn_enabled": false,
			"loadout": "medium",
		}
	]
	fob_screen.call("set_available_units", UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster"))
	fob_screen.call(
		"set_transport_craft_state",
		[
			{
				"craft_id": "dropship_test",
				"display_name": "Dropship Test",
				"visible_in_fob": true,
				"is_boardable": true,
			}
		]
	)
	fob_screen.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	fob_screen.call("_queue_fireteam_for_dropship", "blue", "dropship_test")
	fob_screen.call("_refresh_ui_state")

	_assert(start_button != null and start_button.disabled, "FOB start button stays locked until the selected operators are boarded")
	fob_screen.call("request_mission_start")
	for _frame in range(2):
		await process_frame
	_assert(scene.call("get_active_mission") == null, "FOB mission start does not launch a mission before boarding is complete")

	fob_screen.set("_dropship_phase", "boarded")
	fob_screen.set("_boarded_unit_ids", selected_unit_ids)
	fob_screen.set("_boarded_fireteam_ids", PackedStringArray(["blue"]))
	fob_screen.call("_refresh_ui_state")
	_assert(start_button != null and not start_button.disabled, "FOB start button unlocks once the selected operators are fully boarded")
	fob_screen.call("request_mission_start")
	for _frame in range(4):
		await process_frame
	_assert(scene.call("get_active_mission") != null, "FOB mission start launches once a boarded team is available")
	scene.queue_free()
	await process_frame


func _test_combat_loop_waits_for_pending_insertions() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	var mission_setup: Node = scene.get_node("MissionSetup")
	mission_setup.set("defer_friendly_runtime_activation", true)
	var tactical_controller: Node = scene.get_node("TacticalController")
	var combat_driver: Node = scene.get_node("CombatLoopDriver")
	tactical_controller.call(
		"set_planning_state",
		{
			"has_lz_position": true,
			"lz_position": Vector2(320.0, 180.0),
			"selected_fireteam": "BLUE",
			"selected_fireteams": ["blue"],
			"embarked_unit_ids": ["unit_alpha", "unit_bravo", "unit_delta"],
			"deployed_unit_ids": [],
		}
	)
	root.add_child(scene)
	for _frame in range(24):
		await process_frame

	var mission_result: Dictionary = Dictionary(combat_driver.call("get_mission_result"))
	_assert(mission_result.is_empty(), "Combat loop does not resolve defeat while friendly insertions are still pending")
	scene.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
