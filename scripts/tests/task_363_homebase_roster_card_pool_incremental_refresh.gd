extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_363 Homebase Roster Card Pool Incremental Refresh ===")
	await _test_roster_pool_reuses_cards_on_selection_changes()
	await _test_reused_roster_card_refreshes_profile_text_and_badges()
	await _test_staged_pool_reuses_cards_and_keeps_open_signal()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_363: FAILED")
		quit(1)
	else:
		print("TASK_363: ALL PASSED")
		quit(0)


func _test_roster_pool_reuses_cards_on_selection_changes() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var roster: Array = _build_large_roster(60)
	screen.call("setup_roster", roster, PackedStringArray())
	await _wait_frames(2)

	var first_snapshot: Dictionary = Dictionary(screen.call("get_homebase_card_pool_snapshot"))
	var first_roster: Dictionary = Dictionary(first_snapshot.get("roster", {}))
	var unit_010_card := _find_card_by_unit_id(_roster_list(screen), "task363_unit_010")
	var unit_010_instance_id: int = unit_010_card.get_instance_id() if unit_010_card != null else 0
	_assert(int(first_roster.get("active_count", 0)) == 60, "Roster pool creates cards for the large roster")
	_assert(int(first_roster.get("last_created_count", 0)) == 60, "Initial roster render creates each visible card once")

	screen.call("set_selected_unit_ids", PackedStringArray(["task363_unit_000"]))
	await _wait_frames(2)
	var selection_snapshot: Dictionary = Dictionary(screen.call("get_homebase_card_pool_snapshot"))
	var selection_roster: Dictionary = Dictionary(selection_snapshot.get("roster", {}))
	var selection_staged: Dictionary = Dictionary(selection_snapshot.get("staged", {}))
	var reused_unit_010 := _find_card_by_unit_id(_roster_list(screen), "task363_unit_010")
	_assert(int(selection_roster.get("active_count", 0)) == 59, "Selecting one unit removes only that card from the roster pool")
	_assert(int(selection_roster.get("last_created_count", -1)) == 0, "Selection change does not recreate remaining roster cards")
	_assert(int(selection_roster.get("last_reused_count", 0)) == 59, "Selection change reuses remaining roster cards")
	_assert(int(selection_roster.get("last_retired_count", 0)) == 1, "Selection change retires the moved roster card")
	_assert(reused_unit_010 != null and reused_unit_010.get_instance_id() == unit_010_instance_id, "Unchanged roster card keeps its node instance")
	_assert(int(selection_staged.get("active_count", 0)) == 1 and int(selection_staged.get("last_created_count", 0)) == 1, "Staged pool creates the newly selected card")

	screen.call("set_selected_unit_ids", PackedStringArray(["task363_unit_000", "task363_unit_001"]))
	await _wait_frames(2)
	var second_selection_snapshot: Dictionary = Dictionary(screen.call("get_homebase_card_pool_snapshot"))
	var second_roster: Dictionary = Dictionary(second_selection_snapshot.get("roster", {}))
	var second_staged: Dictionary = Dictionary(second_selection_snapshot.get("staged", {}))
	_assert(int(second_roster.get("last_created_count", -1)) == 0 and int(second_roster.get("last_reused_count", 0)) == 58, "Adding another selected unit still reuses visible roster cards")
	_assert(int(second_staged.get("last_reused_count", 0)) == 1 and int(second_staged.get("last_created_count", 0)) == 1, "Staged pool reuses existing staged card and creates only the new one")

	screen.queue_free()
	await process_frame


func _test_reused_roster_card_refreshes_profile_text_and_badges() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var roster: Array = _build_large_roster(20)
	screen.call("setup_roster", roster, PackedStringArray())
	await _wait_frames(2)

	var unit_id := "task363_unit_010"
	var card := _find_card_by_unit_id(_roster_list(screen), unit_id)
	var instance_id: int = card.get_instance_id() if card != null else 0
	_assert(_card_name_text(card) == "Operator 010", "Initial roster card shows original profile name")

	var updated_roster: Array = roster.duplicate(true)
	for index in range(updated_roster.size()):
		var unit: Dictionary = Dictionary(updated_roster[index])
		if String(unit.get("unit_id", "")) != unit_id:
			continue
		unit["display_name"] = "Promoted Operator 010"
		unit["rank_badges"] = [{"badge_id": "badge_role_medic", "badge_key": "medic", "label": "Medic", "score": 0.92}]
		updated_roster[index] = unit
		break
	screen.call("setup_roster", updated_roster, PackedStringArray())
	await _wait_frames(2)

	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_card_pool_snapshot"))
	var roster_snapshot: Dictionary = Dictionary(snapshot.get("roster", {}))
	var refreshed_card := _find_card_by_unit_id(_roster_list(screen), unit_id)
	_assert(int(roster_snapshot.get("last_created_count", -1)) == 0 and int(roster_snapshot.get("last_reused_count", 0)) == 20, "Profile refresh reuses roster nodes")
	_assert(refreshed_card != null and refreshed_card.get_instance_id() == instance_id, "Profile refresh keeps the same card node")
	_assert(_card_name_text(refreshed_card) == "Promoted Operator 010", "Reused card refreshes display name")
	_assert(_badge_count(refreshed_card) > 0, "Reused card refreshes rank badge row")

	screen.queue_free()
	await process_frame


func _test_staged_pool_reuses_cards_and_keeps_open_signal() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var roster: Array = _build_large_roster(16)
	screen.call("setup_roster", roster, PackedStringArray(["task363_unit_000", "task363_unit_001", "task363_unit_002"]))
	await _wait_frames(2)
	var staged_card := _find_card_by_unit_id(_staged_list(screen), "task363_unit_001")
	var staged_instance_id: int = staged_card.get_instance_id() if staged_card != null else 0
	var initial_snapshot: Dictionary = Dictionary(screen.call("get_homebase_card_pool_snapshot"))
	var initial_staged: Dictionary = Dictionary(initial_snapshot.get("staged", {}))
	_assert(int(initial_staged.get("active_count", 0)) == 3, "Staged pool creates selected team cards")

	screen.call("set_selected_unit_ids", PackedStringArray(["task363_unit_000", "task363_unit_001"]))
	await _wait_frames(2)
	var staged_snapshot: Dictionary = Dictionary(Dictionary(screen.call("get_homebase_card_pool_snapshot")).get("staged", {}))
	var reused_staged_card := _find_card_by_unit_id(_staged_list(screen), "task363_unit_001")
	_assert(int(staged_snapshot.get("last_reused_count", 0)) == 2 and int(staged_snapshot.get("last_created_count", -1)) == 0 and int(staged_snapshot.get("last_retired_count", 0)) == 1, "Staged pool reuses kept selected cards and retires removed cards")
	_assert(reused_staged_card != null and reused_staged_card.get_instance_id() == staged_instance_id, "Existing staged card keeps node instance")

	var double_click := InputEventMouseButton.new()
	double_click.button_index = MOUSE_BUTTON_LEFT
	double_click.pressed = true
	double_click.double_click = true
	reused_staged_card.call("_gui_input", double_click)
	await _wait_frames(2)
	var popup := screen.get_node_or_null("CharacterSheetPopup") as Control
	_assert(popup != null and popup.visible, "Reused staged card keeps double-click character popup signal")

	screen.queue_free()
	await process_frame


func _build_large_roster(count: int) -> Array:
	var units: Array = []
	for index in range(count):
		units.append(
			{
				"unit_id": "task363_unit_%03d" % index,
				"display_name": "Operator %03d" % index,
				"role_name": "Rifleman",
				"callsign": "T%03d" % index,
				"skill_values": {"accuracy": 0.5, "speed": 0.5, "leadership": 0.5, "toughness": 0.5},
				"rank_badges": [],
			}
		)
	return units


func _roster_list(screen: Control) -> VBoxContainer:
	return screen.get_node("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll/RosterList") as VBoxContainer


func _staged_list(screen: Control) -> VBoxContainer:
	return screen.get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel/DropMargin/DropVBox/SelectedTeamScroll/SelectedTeamList") as VBoxContainer


func _find_card_by_unit_id(container: Node, unit_id: String) -> Control:
	if container == null:
		return null
	for child in container.get_children():
		if not child.has_method("get_unit_id"):
			continue
		if String(child.call("get_unit_id")) == unit_id:
			return child as Control
	return null


func _card_name_text(card: Control) -> String:
	if card == null:
		return ""
	var label := card.get_node_or_null("Margin/HBox/TextVBox/NameRow/NameLabel") as Label
	return label.text if label != null else ""


func _badge_count(card: Control) -> int:
	if card == null:
		return 0
	var badge_row := card.get_node_or_null("Margin/HBox/TextVBox/NameRow/BadgeRow") as HBoxContainer
	return badge_row.get_child_count() if badge_row != null else 0


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
