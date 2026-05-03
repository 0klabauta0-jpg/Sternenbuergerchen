extends SceneTree

const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const FOB_SCREEN_SCRIPT: GDScript = preload("res://scripts/meta/fob_screen.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const SMG_PREVIEW_PATH := "res://Assets/used/npc/blaster_kit/previews/blaster-a.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_176 FOB Loadout Weapon Preview Selector Verifier ===")
	_test_preview_asset_contract()
	_test_weapon_selector_contract()
	await _test_fob_loadout_row_shows_smg_preview()
	await _test_medictool_keeps_empty_preview()
	_test_no_absolute_local_asset_paths_in_runtime_files()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_176: FAILED")
		quit(1)
	else:
		print("TASK_176: ALL PASSED")
		quit(0)


func _test_preview_asset_contract() -> void:
	_assert(ResourceLoader.exists(SMG_PREVIEW_PATH), "SMG preview asset exists inside the project")
	var texture := load(SMG_PREVIEW_PATH) as Texture2D
	_assert(texture != null, "SMG preview asset loads as Texture2D")
	_assert(SMG_PREVIEW_PATH.begins_with("res://Assets/used/"), "SMG preview uses a project res:// asset path")


func _test_weapon_selector_contract() -> void:
	var fob_screen = FOB_SCREEN_SCRIPT.new()
	var option_button := OptionButton.new()
	fob_screen.call("_populate_weapon_option_button", option_button, "medictool")
	_assert(option_button.item_count == 2, "FOB weapon selector only offers SMG and Medictool")
	_assert(option_button.get_item_text(0) == "SMG", "FOB weapon selector labels blaster-a as SMG")
	_assert(option_button.get_item_text(1) == "Medictool", "FOB weapon selector keeps Medictool")
	_assert(option_button.get_selected_id() == 1, "FOB weapon selector can preselect Medictool")
	_assert(String(fob_screen.call("_weapon_id_from_index", 0)) == "smg", "FOB selector index 0 writes smg")
	_assert(String(fob_screen.call("_weapon_id_from_index", 1)) == "medictool", "FOB selector index 1 writes medictool")
	_assert(String(fob_screen.call("_get_weapon_preview_path", "smg")) == SMG_PREVIEW_PATH, "SMG maps to blaster-a preview")
	_assert(String(fob_screen.call("_get_weapon_preview_path", "medictool")).is_empty(), "Medictool does not receive a false blaster preview")
	option_button.queue_free()
	fob_screen.queue_free()


func _test_fob_loadout_row_shows_smg_preview() -> void:
	var screen: Control = _build_staged_fob_screen()
	var member_list := _get_loadout_member_list(screen)
	var weapon_1_preview := _find_node_by_name(member_list, "Weapon1Preview") as TextureRect
	var weapon_1_select := _find_node_by_name(member_list, "Weapon1Select") as OptionButton

	_assert(weapon_1_select != null and weapon_1_select.item_count == 2, "#13 loadout row uses the reduced weapon selector")
	_assert(weapon_1_preview != null and weapon_1_preview.visible, "#13 loadout row shows an SMG preview image")
	_assert(weapon_1_preview != null and String(weapon_1_preview.get_meta("weapon_preview_path", "")) == SMG_PREVIEW_PATH, "#13 SMG preview points at blaster-a.png")
	_assert(weapon_1_preview != null and weapon_1_preview.texture != null, "#13 SMG preview has a loaded texture")

	screen.queue_free()
	await process_frame


func _test_medictool_keeps_empty_preview() -> void:
	var screen: Control = _build_staged_fob_screen()
	screen.call("_set_member_loadout", "ft1", "unit_alpha", "", "medictool", "")
	await process_frame

	var member_list := _get_loadout_member_list(screen)
	var weapon_1_preview := _find_node_by_name(member_list, "Weapon1Preview") as TextureRect
	var weapon_1_select := _find_node_by_name(member_list, "Weapon1Select") as OptionButton

	_assert(weapon_1_select != null and weapon_1_select.get_selected_id() == 1, "#13 can select Medictool in slot 1")
	_assert(weapon_1_preview != null and not weapon_1_preview.visible, "Medictool slot hides the Blaster preview")
	_assert(weapon_1_preview != null and String(weapon_1_preview.get_meta("weapon_preview_path", "")).is_empty(), "Medictool slot keeps an empty preview path")

	screen.queue_free()
	await process_frame


func _test_no_absolute_local_asset_paths_in_runtime_files() -> void:
	for file_path in [
		"res://scripts/meta/fob_screen.gd",
		"res://data/npc_unit_visual_mapping.json",
	]:
		var text: String = _read_text_file(file_path)
		_assert(not text.contains("C:\\Users\\"), "%s does not reference local user asset paths" % file_path)


func _build_staged_fob_screen() -> Control:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(screen)
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("set_available_units", roster)
	screen.call(
		"configure_transfer",
		PackedStringArray(["unit_alpha", "unit_bravo"]),
		PackedStringArray(["ft1", "ft1"]),
		[]
	)
	screen.call("_on_staging_fireteam_dropped", "ft1", "loadout")
	return screen


func _get_loadout_member_list(screen: Node) -> VBoxContainer:
	return screen.get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutMemberScroll/LoadoutMemberList") as VBoxContainer


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node == null:
		return null
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _read_text_file(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
