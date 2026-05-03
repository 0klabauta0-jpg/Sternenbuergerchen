extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")
const STATUS_BADGE_SCRIPT: GDScript = preload("res://scripts/ui/components/status_badge.gd")
const TACTICAL_CARD_SCRIPT: GDScript = preload("res://scripts/ui/components/tactical_card.gd")
const UNIT_ROSTER_ROW_SCRIPT: GDScript = preload("res://scripts/ui/components/unit_roster_row.gd")
const COMMAND_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/components/command_button.gd")
const PROGRESS_LINE_SCRIPT: GDScript = preload("res://scripts/ui/components/progress_line.gd")
const UI_TOOLTIP_ICON_HELPER_SCRIPT: GDScript = preload("res://scripts/ui/components/ui_tooltip_icon_helper.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_164 UI Theme Component Verifier ===")
	await _test_theme_tokens_and_curated_assets()
	await _test_component_data_display_contracts()
	await _test_selected_fireteam_slice_uses_component_basis()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_theme_tokens_and_curated_assets() -> void:
	var success_color: Color = TACTICAL_UI_THEME_SCRIPT.call("status_color", "success")
	var danger_color: Color = TACTICAL_UI_THEME_SCRIPT.call("status_color", "danger")
	var neutral_color: Color = TACTICAL_UI_THEME_SCRIPT.call("status_color", "unknown")
	_assert(success_color != neutral_color and danger_color != neutral_color, "Theme exposes distinct status colors")

	var curated_paths: Dictionary = Dictionary(UI_TOOLTIP_ICON_HELPER_SCRIPT.call("get_curated_icon_paths"))
	_assert(curated_paths.size() >= 6, "Tooltip/Icon helper exposes a small curated asset manifest")
	var all_paths_exist: bool = true
	for path_variant in curated_paths.values():
		all_paths_exist = all_paths_exist and ResourceLoader.exists(String(path_variant))
	_assert(all_paths_exist, "Curated Kenney UI asset paths exist in the repo")
	_assert(UI_TOOLTIP_ICON_HELPER_SCRIPT.call("load_icon", "check") != null, "Tooltip/Icon helper loads a curated Kenney icon")


func _test_component_data_display_contracts() -> void:
	var status_badge := STATUS_BADGE_SCRIPT.new() as Label
	root.add_child(status_badge)
	await process_frame
	status_badge.call("set_badge", "Ready", "success")
	_assert(status_badge.text == "READY", "StatusBadge displays snapshot text as a compact badge")

	var tactical_card := TACTICAL_CARD_SCRIPT.new() as PanelContainer
	root.add_child(tactical_card)
	await process_frame
	tactical_card.call("apply_card_style", true)
	_assert(bool(tactical_card.get("selected")), "TacticalCard tracks only local display selection")

	var roster_row := UNIT_ROSTER_ROW_SCRIPT.new() as HBoxContainer
	root.add_child(roster_row)
	await process_frame
	roster_row.call(
		"set_unit_snapshot",
		{
			"display_name": "Alpha One",
			"role": "Lead",
			"status": "Ready",
			"status_key": "success",
		}
	)
	var name_label := roster_row.get_node_or_null("NameLabel") as Label
	var role_label := roster_row.get_node_or_null("RoleLabel") as Label
	var row_badge := roster_row.get_node_or_null("StatusBadge") as Label
	_assert(name_label != null and name_label.text == "Alpha One" and role_label != null and role_label.text == "Lead" and row_badge != null and row_badge.text == "READY", "UnitRosterRow renders unit snapshot fields without owning gameplay state")

	var command_button := COMMAND_BUTTON_SCRIPT.new() as Button
	root.add_child(command_button)
	await process_frame
	command_button.call("configure", "Go", "go_phase", "Execute the current phase.", "command")
	_assert(command_button.text == "Go" and String(command_button.get("command_id")) == "go_phase", "CommandButton keeps command identity as display metadata")

	var progress_line := PROGRESS_LINE_SCRIPT.new() as VBoxContainer
	root.add_child(progress_line)
	await process_frame
	progress_line.call("set_progress", "SUPP", 0.5, 1.0, "warning")
	var progress_bar := progress_line.get_node_or_null("ProgressBar") as ProgressBar
	_assert(progress_bar != null and is_equal_approx(progress_bar.value, 0.5), "ProgressLine displays bounded progress data")

	for node in [status_badge, tactical_card, roster_row, command_button, progress_line]:
		root.remove_child(node)
		node.queue_free()
	await process_frame


func _test_selected_fireteam_slice_uses_component_basis() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission test scene exposes the tactical controller")
	if controller == null:
		scene.queue_free()
		await process_frame
		return

	var panel := controller.call("_ensure_fireteam_status_panel") as Control
	controller.call("_refresh_fireteam_status_panel")
	await process_frame
	var status_badge := panel.get_node_or_null("MarginContainer/HBoxContainer/SelectionStateBadge") as Control if panel != null else null
	var suppression_label := panel.get_node_or_null("MarginContainer/HBoxContainer/SuppressionLabel") as Label if panel != null else null
	var progress_line := panel.get_node_or_null("MarginContainer/HBoxContainer/SuppressionProgressLine") as Control if panel != null else null
	var return_button := panel.get_node_or_null("MarginContainer/HBoxContainer/ReturnToPlanButton") as Button if panel != null else null

	_assert(panel != null and panel.get_script() == TACTICAL_CARD_SCRIPT, "Selected Fireteam status slice uses TacticalCard")
	_assert(status_badge != null and status_badge.get_script() == STATUS_BADGE_SCRIPT, "Selected Fireteam status slice uses StatusBadge")
	_assert(progress_line != null and progress_line.get_script() == PROGRESS_LINE_SCRIPT, "Selected Fireteam status slice uses ProgressLine")
	_assert(return_button != null and return_button.get_script() == COMMAND_BUTTON_SCRIPT, "Selected Fireteam status slice uses CommandButton")
	_assert(suppression_label != null and not suppression_label.text.is_empty(), "Selected Fireteam status slice keeps the old readable status summary")

	scene.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
