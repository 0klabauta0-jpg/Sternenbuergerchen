extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const PLATFORM_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/platform_large_NW.png"
const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"
const CARGO_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_cargoA_NE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_179 Homebase Drop Light Fixed FullHD Layout Verifier ===")
	await _test_homebase_fixed_window_positions()
	await _test_homebase_flightdeck_read_only_visual_stage()
	_test_no_absolute_user_paths_in_runtime_files()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_179: FAILED")
		quit(1)
	else:
		print("TASK_179: ALL PASSED")
		quit(0)


func _test_homebase_fixed_window_positions() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_homebase_layout")
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	_assert(screen.custom_minimum_size == Vector2(float(target_viewport.x), float(target_viewport.y)), "Homebase root fixes the FullHD workspace size")
	_assert(bool(screen.get_meta("drop_light_fixed_fullhd_layout", false)), "Homebase root is marked as a drop_light fixed layout")
	_assert(_node_rect_matches_actual(screen.get_node("DropLightTopbar") as Control, layout.get("topbar")), "Homebase topbar uses the fixed contract position and size")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/MissionPanel") as Control, layout.get("mission_brief")), "#01 mission brief uses the fixed contract position and size")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/ContentRow/RosterPanel") as Control, layout.get("roster")), "#02 roster uses the fixed contract position and size")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/ContentRow/TeamPanel") as Control, layout.get("transfer_team")), "#03 transfer team uses the fixed contract position and size")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control, layout.get("flightdeck")), "#05 flightdeck uses the fixed contract position and size")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/ContentRow/InfoPanel") as Control, layout.get("character_sheet")), "#07 character sheet uses the fixed contract position and size")

	var info_panel := screen.get_node("Panel/Margin/VBox/ContentRow/InfoPanel") as Control
	_assert(info_panel.visible, "Homebase character sheet is visible as a fixed window")
	_assert(screen.get_node("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll") is ScrollContainer, "Roster keeps long content in a targeted scroll area")
	_assert(screen.get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel/DropMargin/DropVBox/SelectedTeamScroll") is ScrollContainer, "Transfer team keeps staged content in a targeted scroll area")
	_assert(screen.get_node("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll") is ScrollContainer, "Character sheet keeps long content in a targeted scroll area")

	screen.queue_free()
	await process_frame


func _test_homebase_flightdeck_read_only_visual_stage() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.call("setup_roster", UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster"))
	screen.call(
		"set_transport_state",
		[
			{
				"craft_id": "dropship_alpha",
				"craft_type": "dropship",
				"display_name": "Dropship",
				"texture_path": DROPSHIP_TEXTURE_PATH,
				"supports_cargo": false,
				"cargo_options": [],
			},
			{
				"craft_id": "cargo_alpha",
				"craft_type": "craft_cargoB",
				"display_name": "Frachter",
				"texture_path": CARGO_TEXTURE_PATH,
				"supports_cargo": true,
				"cargo_options": [
					{"cargo_id": "", "display_name": "No Cargo"},
					{"cargo_id": "rover", "display_name": "Rover"},
				],
			},
		],
		{"dropship_alpha": "unit_alpha", "cargo_alpha": "unit_bravo"},
		[],
		[
			{
				"craft_id": "cargo_alpha",
				"pilot_unit_id": "unit_bravo",
				"duration_seconds": 12.0,
				"elapsed_seconds": 4.0,
			},
		],
		{"dropship_alpha": "homebase", "cargo_alpha": "transit"},
		{"cargo_alpha": "rover"},
		{"cargo_alpha": "rover"},
		[]
	)
	await process_frame
	await process_frame

	var stage_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DropLightFlightdeckStage") as PanelContainer
	var pad_stage := stage_panel.get_node("Margin/PadStage") as Control
	_assert(stage_panel != null and bool(stage_panel.get_meta("drop_light_read_only_visual_stage", false)), "Homebase flightdeck has a read-only visual stage")
	_assert(stage_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE and pad_stage.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Flightdeck visual stage does not take input away from existing controls")
	_assert(_contains_texture_path(pad_stage, PLATFORM_TEXTURE_PATH), "Flightdeck stage renders the project platform asset")
	_assert(_contains_texture_path(pad_stage, DROPSHIP_TEXTURE_PATH), "Flightdeck stage renders the project dropship asset")
	_assert(_contains_texture_path(pad_stage, CARGO_TEXTURE_PATH), "Flightdeck stage renders the project cargo craft asset")
	_assert(not _contains_button(pad_stage), "Flightdeck visual stage introduces no unbound action buttons")
	_assert(_contains_texture_path(screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/ShipCardsScroll/ShipCardsList"), DROPSHIP_TEXTURE_PATH), "Homebase shipcards keep using project aircraft assets")

	screen.queue_free()
	await process_frame


func _test_no_absolute_user_paths_in_runtime_files() -> void:
	for file_path in [
		"res://scripts/meta/homebase_screen.gd",
		"res://scripts/meta/meta_layer_flow.gd",
		"res://scripts/meta/drop_light_layout_contract.gd",
	]:
		var text := _read_text_file(file_path)
		_assert(not text.contains("C:" + "\\" + "Users" + "\\") and not text.contains("C:" + "/" + "Users" + "/"), "%s contains no absolute user asset path" % file_path)
	for asset_path in [PLATFORM_TEXTURE_PATH, DROPSHIP_TEXTURE_PATH, CARGO_TEXTURE_PATH]:
		_assert(ResourceLoader.exists(asset_path), "%s exists inside the project" % asset_path)


func _node_rect_matches_actual(control: Control, rect_variant: Variant) -> bool:
	if control == null or typeof(rect_variant) != TYPE_RECT2I:
		return false
	var rect: Rect2i = rect_variant
	var matches := _approximately_equal(control.global_position.x, float(rect.position.x)) \
		and _approximately_equal(control.global_position.y, float(rect.position.y)) \
		and _approximately_equal(control.size.x, float(rect.size.x)) \
		and _approximately_equal(control.size.y, float(rect.size.y))
	if not matches:
		print("  RECT MISMATCH %s actual pos=%s size=%s expected pos=%s size=%s" % [
			control.name,
			control.global_position,
			control.size,
			rect.position,
			rect.size,
		])
	return matches


func _approximately_equal(a: float, b: float) -> bool:
	return absf(a - b) <= 0.5


func _contains_texture_path(root_node: Node, expected_path: String) -> bool:
	for node in _collect_nodes(root_node):
		var texture_rect := node as TextureRect
		if texture_rect == null or texture_rect.texture == null:
			continue
		if texture_rect.texture.resource_path == expected_path:
			return true
	return false


func _contains_button(root_node: Node) -> bool:
	for node in _collect_nodes(root_node):
		if node is Button:
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
