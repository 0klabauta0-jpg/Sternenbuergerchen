extends SceneTree

const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const NPC_COMPACT_CARD_SCRIPT: GDScript = preload("res://scripts/meta/npc_compact_card.gd")

var _passed: int = 0
var _failed: int = 0
var _opened_unit_id: String = ""


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_316 FOB Fireteam Staging Migration ===")
	await _test_fireteam_card_migrates_between_windows()
	await _test_npc_double_click_requests_character_sheet()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_fireteam_card_migrates_between_windows() -> void:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	screen.visible = true
	root.add_child(screen)
	await _wait_frames(4)

	screen.call("set_available_units", [
		{"unit_id": "unit_a", "display_name": "Anja", "role_name": "Lead"},
		{"unit_id": "unit_b", "display_name": "Milo", "role_name": "Medic"},
	])
	screen.call(
		"configure_transfer",
		PackedStringArray(["unit_a", "unit_b"]),
		PackedStringArray(["ft1", "ft1"]),
		[{"id": "ft1", "label": "FT1", "lead_unit_id": "unit_a"}]
	)
	await _wait_frames(4)
	_assert(_fireteam_list_contains(screen, "ft1"), "FT1 starts in #10 FIRETEAMS")
	_assert(_fireteam_card_stage_contains(screen, _fireteam_list_path(), "ft1", "Loadout:"), "#10 fireteam card always shows loadout")

	screen.call("_on_staging_fireteam_dropped", "ft1", "respawn")
	await _wait_frames(2)
	_assert(not _fireteam_list_contains(screen, "ft1"), "FT1 leaves #10 when moved to #12")
	_assert(_staging_card_contains(screen, _respawn_list_path(), "ft1"), "FT1 appears in #12 respawn")
	_assert(_fireteam_card_stage_contains(screen, _respawn_list_path(), "ft1", "Loadout:"), "#12 fireteam reference keeps loadout visible")
	_assert(_respawn_card_has_progress(screen), "#12 respawn card renders verorten progress rows")

	screen.call("_on_dropship_timer_timeout")
	await _wait_frames(2)
	_assert(_respawn_status_contains(screen, "locating"), "#12 status keeps progress state after timer tick")

	screen.call("_on_staging_fireteam_dropped", "ft1", "loadout")
	await _wait_frames(2)
	_assert(not _fireteam_list_contains(screen, "ft1"), "FT1 leaves #10 when moved to #13")
	_assert(_staging_card_contains(screen, _loadout_list_path(), "ft1"), "FT1 appears in #13 loadout")
	_assert(_staging_card_width_is_compact(screen, _loadout_list_path()), "#13 fireteam card stays compact")
	_assert(_loadout_reference_summary_is_hidden(screen), "#13 fireteam reference uses compact FOB loadout header")
	_assert(_loadout_member_rows_are_compact(screen), "#13 member loadout rows stay compact")
	_assert(_loadout_member_rows_have_badges_and_dropdowns(screen), "#13 member loadout rows show badges and loadout dropdowns")

	screen.call("set_transport_craft_state", [
		{
			"craft_id": "dropship_1",
			"display_name": "Dropship 1",
			"visible_in_fob": true,
			"is_boardable": true,
			"pilot_unit_id": "",
		},
	])
	screen.call("_on_staging_fireteam_dropped", "ft1", "dropship|dropship_1")
	await _wait_frames(2)
	var drop_state: Dictionary = Dictionary(screen.call("build_mission_drop_state"))
	_assert(not _fireteam_list_contains(screen, "ft1"), "FT1 leaves #10 when moved to #19")
	_assert(Array(drop_state.get("queued_fireteam_ids", [])).has("ft1"), "FT1 is queued in #19 transport card")

	screen.queue_free()
	await _wait_frames(2)


func _test_npc_double_click_requests_character_sheet() -> void:
	var card: Control = NPC_COMPACT_CARD_SCRIPT.new()
	root.add_child(card)
	card.call(
		"setup_from_profile",
		{"unit_id": "unit_a", "display_name": "Anja", "role_name": "Lead"},
		{"compact_mode": true, "source_context": "fob_fireteam"}
	)
	card.card_open_requested.connect(_on_card_open_requested)
	await process_frame

	var double_click := InputEventMouseButton.new()
	double_click.button_index = MOUSE_BUTTON_LEFT
	double_click.pressed = true
	double_click.double_click = true
	card.call("_gui_input", double_click)
	_assert(_opened_unit_id == "unit_a", "NPC card double-click requests character sheet")

	_opened_unit_id = ""
	card.call("set_visual_state", false, true)
	card.call("_gui_input", double_click)
	_assert(_opened_unit_id == "unit_a", "Disabled NPC card double-click still requests character sheet")

	card.queue_free()
	await process_frame


func _fireteam_list_contains(screen: Control, fireteam_id: String) -> bool:
	var list := screen.get_node_or_null(_fireteam_list_path()) as VBoxContainer
	return _container_has_fireteam_card(list, fireteam_id)


func _fireteam_card_stage_contains(screen: Control, path: String, fireteam_id: String, expected_text: String) -> bool:
	var card := _find_fireteam_card(screen.get_node_or_null(path) as VBoxContainer, fireteam_id)
	if card == null:
		return false
	var stage_label := card.get_node_or_null("Margin/VBox/StageLabel") as Label
	return stage_label != null and stage_label.visible and stage_label.text.contains(expected_text)


func _staging_card_contains(screen: Control, path: String, fireteam_id: String) -> bool:
	return _container_has_fireteam_card(screen.get_node_or_null(path) as VBoxContainer, fireteam_id)


func _staging_card_width_is_compact(screen: Control, path: String) -> bool:
	var container := screen.get_node_or_null(path) as VBoxContainer
	if container == null or container.get_child_count() == 0:
		return false
	var card := container.get_child(0) as Control
	return card != null and card.custom_minimum_size.x <= 280.0


func _respawn_card_has_progress(screen: Control) -> bool:
	var container := screen.get_node_or_null(_respawn_list_path()) as VBoxContainer
	if container == null or container.get_child_count() == 0:
		return false
	var card = container.get_child(0)
	if not card.has_method("get_member_host"):
		return false
	var member_host := card.call("get_member_host") as VBoxContainer
	return member_host != null and member_host.get_child_count() >= 2 and String((member_host.get_child(0) as Label).text).begins_with("Verorten:")


func _respawn_status_contains(screen: Control, needle: String) -> bool:
	var label := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel/RespawnMargin/RespawnVBox/RespawnStatusLabel") as Label
	return label != null and label.text.to_lower().contains(needle)


func _loadout_member_rows_are_compact(screen: Control) -> bool:
	var container := screen.get_node_or_null(_loadout_member_list_path()) as VBoxContainer
	if container == null or container.get_child_count() == 0:
		return false
	for child in container.get_children():
		var control := child as Control
		if control == null:
			continue
		if not bool(control.get_meta("compact_loadout_member_row", false)):
			return false
		if control.custom_minimum_size.y > 72.0:
			return false
	return true


func _loadout_reference_summary_is_hidden(screen: Control) -> bool:
	var container := screen.get_node_or_null(_loadout_list_path()) as VBoxContainer
	if container == null or container.get_child_count() == 0:
		return false
	var card := container.get_child(0) as Control
	if card == null:
		return false
	var stage_label := card.get_node_or_null("Margin/VBox/StageLabel") as Label
	var member_label := card.get_node_or_null("Margin/VBox/MemberLabel") as Label
	return stage_label != null and stage_label.text.begins_with("FOB |") and stage_label.text.contains("Loadout:") and member_label != null and not member_label.visible


func _loadout_member_rows_have_badges_and_dropdowns(screen: Control) -> bool:
	var container := screen.get_node_or_null(_loadout_member_list_path()) as VBoxContainer
	if container == null:
		return false
	var found_dropdown_row := false
	var found_badges := false
	for child in container.get_children():
		var control := child as Control
		if control == null or not bool(control.get_meta("compact_loadout_member_row", false)):
			continue
		found_dropdown_row = found_dropdown_row or _count_compact_loadout_dropdowns(control) == 3
		var badge_count: int = _count_nodes_with_prefix(control, "RankBadge_")
		found_badges = found_badges or (badge_count > 0 and badge_count <= 2)
	return found_dropdown_row and found_badges


func _count_compact_loadout_dropdowns(node: Node) -> int:
	var count := 0
	if node is OptionButton and bool((node as OptionButton).get_meta("compact_loadout_dropdown", false)):
		count += 1
	for child in node.get_children():
		count += _count_compact_loadout_dropdowns(child)
	return count


func _count_nodes_with_prefix(node: Node, prefix: String) -> int:
	var count := 0
	if String(node.name).begins_with(prefix):
		count += 1
	for child in node.get_children():
		count += _count_nodes_with_prefix(child, prefix)
	return count


func _container_has_fireteam_card(container: VBoxContainer, fireteam_id: String) -> bool:
	return _find_fireteam_card(container, fireteam_id) != null


func _find_fireteam_card(container: VBoxContainer, fireteam_id: String) -> Control:
	if container == null:
		return null
	for child in container.get_children():
		if child.has_method("get_fireteam_id") and String(child.call("get_fireteam_id")) == fireteam_id:
			return child as Control
	return null


func _fireteam_list_path() -> String:
	return "Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll/FireteamList"


func _respawn_list_path() -> String:
	return "Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel/RespawnMargin/RespawnVBox/RespawnFireteamList"


func _loadout_list_path() -> String:
	return "Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutFireteamList"


func _loadout_member_list_path() -> String:
	return "Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutMemberScroll/LoadoutMemberList"


func _on_card_open_requested(unit_id: String, _profile, _source_context: String) -> void:
	_opened_unit_id = unit_id


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
