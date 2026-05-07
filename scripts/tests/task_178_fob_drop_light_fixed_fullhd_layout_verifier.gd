extends SceneTree

const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"
const SHUTTLE_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederA_NE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_178 FOB Drop Light Fixed FullHD Layout Verifier ===")
	await _test_fob_scene_uses_fixed_fullhd_layout_contract()
	await _test_flightdeck_renders_project_craft_assets()
	_test_runtime_files_keep_project_asset_paths()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_178: FAILED")
		quit(1)
	else:
		print("TASK_178: ALL PASSED")
		quit(0)


func _test_fob_scene_uses_fixed_fullhd_layout_contract() -> void:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_fob_layout")
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	_assert(screen.custom_minimum_size == Vector2(float(target_viewport.x), float(target_viewport.y)), "FOB root fixes the FullHD workspace size")
	_assert(bool(screen.get_meta("drop_light_fixed_fullhd_layout", false)), "FOB root is marked as a drop_light fixed layout")

	var fireteam_panel := screen.get_node("Panel/Margin/VBox/ContentRow/FireteamPanel") as Control
	var loadout_panel := screen.get_node("Panel/Margin/VBox/ContentRow/StagingPanel") as Control
	var flightdeck_panel := screen.get_node("Panel/Margin/VBox/ContentRow/DropshipPanel") as Control
	_assert(_node_rect_matches_contract(fireteam_panel, layout.get("fireteams")), "#10 FIRETEAMS uses the fixed contract rectangle")
	_assert(_node_rect_matches_contract(loadout_panel, layout.get("loadout")), "#13 LOADOUT uses the fixed contract rectangle")
	_assert(_node_rect_matches_contract(flightdeck_panel, layout.get("flightdeck")), "#14 FLIGHTDECK uses the fixed contract rectangle")
	_assert(flightdeck_panel.custom_minimum_size.x > loadout_panel.custom_minimum_size.x, "#14 FLIGHTDECK is wider than #13 LOADOUT")

	var available_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AvailablePanel") as Control
	_assert(available_panel != null and not available_panel.visible, "#09 available operators is not part of the fixed FOB runtime layout")

	var dropship_label := screen.get_node("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipHeaderRow/DropshipHeaderLabel") as Label
	var loadout_label := screen.get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutHeaderRow/LoadoutHeaderLabel") as Label
	_assert(dropship_label != null and dropship_label.text == "#14 FLIGHTDECK", "FOB right panel is labeled #14 FLIGHTDECK")
	_assert(loadout_label != null and loadout_label.text == "#13 LOADOUT", "FOB middle panel is labeled #13 LOADOUT")

	var bottom_row := screen.get_node_or_null("Panel/Margin/VBox/DropLightBottomRow") as HBoxContainer
	_assert(bottom_row != null and bool(bottom_row.get_meta("drop_light_fixed_fullhd_layout", false)), "FOB adds a fixed bottom row for boarding status and actions")
	_assert(_node_rect_matches_contract(bottom_row.get_node("BoardingStatusPanel") as Control, layout.get("boarding_status")), "Boarding status sits in its fixed bottom contract window")
	_assert(_node_rect_matches_contract(bottom_row.get_node("ActionsPanel") as Control, layout.get("actions")), "Actions sit in their fixed bottom contract window")
	_assert(_all_buttons_square(bottom_row.get_node("ActionsPanel/Margin/VBox/ActionGrid") as GridContainer), "Bottom action buttons are square")

	screen.queue_free()
	await process_frame


func _test_flightdeck_renders_project_craft_assets() -> void:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.call("set_transport_craft_state", [
		{
			"craft_id": "dropship_alpha",
			"display_name": "Dropship",
			"visible_in_fob": true,
			"is_boardable": true,
			"texture_path": DROPSHIP_TEXTURE_PATH,
			"pilot_display_name": "Anja",
		},
		{
			"craft_id": "shuttle_beta",
			"display_name": "Shuttle",
			"visible_in_fob": true,
			"is_boardable": true,
			"texture_path": SHUTTLE_TEXTURE_PATH,
			"pilot_display_name": "Talia",
		},
	])
	await process_frame

	var queue_list := screen.get_node("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipQueueScroll/DropshipQueueList") as VBoxContainer
	_assert(queue_list != null and queue_list.get_child_count() >= 2, "#14 FLIGHTDECK renders visible transport craft cards")
	_assert(_contains_texture_path(queue_list, DROPSHIP_TEXTURE_PATH), "Flightdeck uses the project dropship asset")
	_assert(_contains_texture_path(queue_list, SHUTTLE_TEXTURE_PATH), "Flightdeck uses the project shuttle asset")
	_assert(_transport_card_buttons_are_square(queue_list), "Transport craft card actions are square")

	screen.queue_free()
	await process_frame


func _test_runtime_files_keep_project_asset_paths() -> void:
	for file_path in [
		"res://scripts/meta/fob_screen.gd",
		"res://scripts/meta/transport_craft_card_ui.gd",
		"res://scripts/meta/drop_light_layout_contract.gd",
	]:
		var text := _read_text_file(file_path)
		_assert(not text.contains("C:" + "\\" + "Users" + "\\") and not text.contains("C:" + "/" + "Users" + "/"), "%s contains no absolute user asset path" % file_path)
	_assert(ResourceLoader.exists(DROPSHIP_TEXTURE_PATH), "Dropship asset exists under res://Assets")
	_assert(ResourceLoader.exists(SHUTTLE_TEXTURE_PATH), "Shuttle asset exists under res://Assets")


func _node_rect_matches_contract(control: Control, rect_variant: Variant) -> bool:
	if control == null or typeof(rect_variant) != TYPE_RECT2I:
		return false
	var rect: Rect2i = rect_variant
	return control.custom_minimum_size == Vector2(float(rect.size.x), float(rect.size.y)) \
		and control.get_meta("drop_light_rect", Rect2i()) == rect


func _all_buttons_square(container: Node) -> bool:
	if container == null:
		return false
	for child in container.get_children():
		var button := child as Button
		if button == null:
			continue
		if button.custom_minimum_size.x <= 0.0 or button.custom_minimum_size.x != button.custom_minimum_size.y:
			return false
		if not bool(button.get_meta("drop_light_square_action_button", false)):
			return false
	return true


func _transport_card_buttons_are_square(root_node: Node) -> bool:
	var found_button := false
	for node in _collect_nodes(root_node):
		var button := node as Button
		if button == null or not button.name.ends_with("ActionButton"):
			continue
		found_button = true
		if button.custom_minimum_size.x <= 0.0 or button.custom_minimum_size.x != button.custom_minimum_size.y:
			return false
	return found_button


func _contains_texture_path(root_node: Node, expected_path: String) -> bool:
	for node in _collect_nodes(root_node):
		var texture_rect := node as TextureRect
		if texture_rect == null or texture_rect.texture == null:
			continue
		if texture_rect.texture.resource_path == expected_path:
			return true
	return false


func _collect_nodes(root_node: Node) -> Array:
	var nodes: Array = []
	if root_node == null:
		return nodes
	nodes.append(root_node)
	for child in root_node.get_children():
		nodes.append_array(_collect_nodes(child))
	return nodes


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
