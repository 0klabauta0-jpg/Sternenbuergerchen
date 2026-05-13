extends SceneTree

const MEMBER_STATUS_ROW_SCRIPT: GDScript = preload("res://scripts/ui/fireteam_member_status_row.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_370 Fireteam Member Health Status Row ===")
	await _test_direct_row_statuses_and_refresh()
	await _test_mission_member_row_updates_after_health_change()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_direct_row_statuses_and_refresh() -> void:
	var row: Control = MEMBER_STATUS_ROW_SCRIPT.new()
	root.add_child(row)
	await _wait_frames(2)
	row.call("set_member_snapshot", {
		"fireteam_id": "blue",
		"members": [
			_member("alpha", "fit"),
			_member("bravo", "wounded"),
			_member("charlie", "down"),
			_member("delta", "suppressed"),
		],
	})
	await _wait_frames(2)
	var snapshot: Dictionary = Dictionary(row.call("get_row_snapshot"))
	var counts: Dictionary = Dictionary(snapshot.get("counts", {}))
	_assert(int(snapshot.get("member_count", 0)) == 4, "Four-person fireteam exposes four member chips")
	_assert(int(snapshot.get("visible_chip_count", 0)) == 4, "Four-person row keeps exactly four visible chips")
	_assert(int(counts.get("fit", 0)) == 1 and int(counts.get("wounded", 0)) == 1 and int(counts.get("down", 0)) == 1 and int(counts.get("suppressed", 0)) == 1, "Fit, wounded, down and suppressed states are distinct")
	_assert(row.custom_minimum_size == MEMBER_STATUS_ROW_SCRIPT.DEFAULT_SIZE, "Row reports fixed compact dimensions")
	row.call("set_member_snapshot", {"fireteam_id": "blue", "members": [_member("delta", "busy")]})
	await _wait_frames(2)
	var refreshed: Dictionary = Dictionary(row.call("get_row_snapshot"))
	var refreshed_counts: Dictionary = Dictionary(refreshed.get("counts", {}))
	_assert(int(refreshed_counts.get("suppressed", 0)) == 0 and int(refreshed_counts.get("busy", 0)) == 1, "Status refresh replaces stale chip counts")
	row.call("set_member_snapshot", {"fireteam_id": "blue", "members": [_member("delta", "down")]})
	await _wait_frames(2)
	var down_refreshed: Dictionary = Dictionary(row.call("get_row_snapshot"))
	_assert(int(Dictionary(down_refreshed.get("counts", {})).get("down", 0)) == 1, "Status refresh can switch a chip to downed")
	row.call("set_member_snapshot", {"fireteam_id": "empty", "members": []})
	await _wait_frames(2)
	var empty_snapshot: Dictionary = Dictionary(row.call("get_row_snapshot"))
	_assert(String(empty_snapshot.get("display_state", "")) == "neutral" and int(empty_snapshot.get("visible_chip_count", 0)) == 4, "Empty member data renders neutral slots")
	row.queue_free()
	await _wait_frames(2)


func _test_mission_member_row_updates_after_health_change() -> void:
	root.size = Vector2i(1920, 1080)
	var scene = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var card_list: Node = scene.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox")
	_assert(controller != null and card_list != null, "Mission scene exposes controller and fireteam mini cards")
	if controller == null or card_list == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_update_ui")
	await _wait_frames(8)
	var row: Control = _find_blue_member_row(card_list)
	_assert(row != null, "Blue mini card embeds member status row")
	var initial_snapshot: Dictionary = Dictionary(row.call("get_row_snapshot")) if row != null else {}
	var blue_units: Array = _find_fireteam_units(controller, "blue")
	var expected_member_count: int = blue_units.size()
	_assert(expected_member_count > 0 and int(initial_snapshot.get("member_count", 0)) == expected_member_count, "Mission blue row mirrors current fireteam member count")
	_assert(int(Dictionary(initial_snapshot.get("counts", {})).get("fit", 0)) >= 1, "Mission row starts with at least one fit member")

	if not blue_units.is_empty():
		if blue_units[0].has_method("apply_damage"):
			blue_units[0].call("apply_damage", 25, {"source": "task_370_wound_probe"})
	controller.call("_update_ui")
	await _wait_frames(8)
	row = _find_blue_member_row(card_list)
	var changed_snapshot: Dictionary = Dictionary(row.call("get_row_snapshot")) if row != null else {}
	var changed_counts: Dictionary = Dictionary(changed_snapshot.get("counts", {}))
	_assert(int(changed_counts.get("wounded", 0)) >= 1, "Mission row reflects wounded member after damage")
	_assert(int(changed_snapshot.get("visible_chip_count", 0)) == clampi(maxi(expected_member_count, 4), 4, 6), "Mission row keeps stable chip slots after status changes")
	_assert(_mini_cards_stay_compact(card_list), "Member status row keeps mini cards compact")
	var public_rows: Array = Array(controller.call("get_fireteam_member_status_row_snapshot"))
	_assert(_has_public_member_row(public_rows, "blue", expected_member_count), "Controller exposes public member-row snapshot")
	scene.queue_free()
	await _wait_frames(2)


func _member(unit_id: String, status: String) -> Dictionary:
	return {
		"unit_id": unit_id,
		"display_name": unit_id.capitalize(),
		"status": status,
		"read_only": true,
	}


func _find_blue_member_row(card_list: Node) -> Control:
	if card_list == null:
		return null
	return card_list.get_node_or_null("FireteamMiniCard_Blue/FireteamMemberStatusRow") as Control


func _find_fireteam_units(controller: Node, fireteam_id: String) -> Array:
	var result: Array = []
	for unit in Array(controller.call("_get_all_friendly_units", true)):
		if unit == null or not unit.has_method("get_fireteam_id"):
			continue
		if String(unit.call("get_fireteam_id")).strip_edges().to_lower() == fireteam_id.strip_edges().to_lower():
			result.append(unit)
	return result


func _has_public_member_row(rows: Array, fireteam_id: String, expected_member_count: int) -> bool:
	for row_variant in rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = Dictionary(row_variant)
		if String(row.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id.strip_edges().to_lower():
			return int(row.get("member_count", 0)) == expected_member_count and Array(row.get("members", [])).size() == expected_member_count
	return false


func _mini_cards_stay_compact(card_list: Node) -> bool:
	for child in card_list.get_children():
		var control := child as Control
		if control == null or not control.visible:
			continue
		if control.size.y > 96.0:
			return false
	return true


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
