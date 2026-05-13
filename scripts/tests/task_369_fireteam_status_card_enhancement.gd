extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_369 Fireteam Status Card Enhancement ===")
	await _test_fireteam_status_snapshots_and_card_lines()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_fireteam_status_snapshots_and_card_lines() -> void:
	root.size = Vector2i(1920, 1080)
	var scene = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var card_list: Node = scene.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox")
	_assert(controller != null and combat_driver != null and card_list != null, "Mission scene exposes controller, combat driver and fireteam card list")
	if controller == null or combat_driver == null or card_list == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["blue", "gold"]), Vector2(880.0, 860.0), Vector2(1040.0, 980.0), "take")
	_position_fireteam_units(controller, "blue", Vector2(640.0, 640.0))
	_position_fireteam_units(controller, "gold", Vector2(1760.0, 1760.0))
	_force_contact_for_fireteam(controller, combat_driver, "blue")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_update_ui")
	await _wait_frames(8)

	var snapshots: Array = Array(controller.call("get_fireteam_status_card_snapshot"))
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var blue_snapshot: Dictionary = _find_snapshot(snapshots, "blue")
	var gold_snapshot: Dictionary = _find_snapshot(snapshots, "gold")
	_assert(snapshots.size() >= 2, "Controller exposes status-card snapshots for at least two fireteams")
	_assert(int(feedback.get("fireteam_status_card_count", 0)) == snapshots.size(), "Command feedback mirrors status-card snapshot count")
	_assert(_snapshot_has_required_status_fields(blue_snapshot), "Blue status snapshot carries execution, readiness, contact and health")
	_assert(_snapshot_has_required_status_fields(gold_snapshot), "Gold status snapshot carries execution, readiness, contact and health")
	_assert(bool(blue_snapshot.get("selected", false)) and not bool(gold_snapshot.get("selected", true)), "Selected fireteam state stays explicit per card")
	_assert(_status_snapshots_are_distinct(blue_snapshot, gold_snapshot), "Verifier sees different contact or readiness states across fireteams")

	var blue_card := card_list.get_node_or_null("FireteamMiniCard_Blue") as Control
	_assert(blue_card != null, "Blue mini card exists")
	if blue_card != null:
		var primary_label := blue_card.get_node_or_null("Margin/VBox/MemberLabel") as Label
		var secondary_label := blue_card.get_node_or_null("Margin/VBox/StageLabel") as Label
		var stored_snapshot: Dictionary = Dictionary(blue_card.get_meta("mission_fireteam_status_card_snapshot", {}))
		_assert(primary_label != null and _line_contains_status_tokens(primary_label.text), "Card primary line shows execution, readiness, contact and health tokens")
		_assert(secondary_label != null and secondary_label.text.find("MV ") >= 0 and secondary_label.text.find("POS ") >= 0, "Card secondary line shows movement and position")
		_assert(not stored_snapshot.is_empty() and String(stored_snapshot.get("fireteam_id", "")) == "blue", "Card stores read-only status snapshot metadata")
		_assert(bool(blue_card.get_meta("mission_fireteam_status_selected", false)), "Card metadata keeps selected marker")
		_assert(_mini_cards_stay_compact(card_list), "Status enhancement keeps mini cards compact")
	scene.queue_free()
	await _wait_frames(2)


func _force_contact_for_fireteam(controller: Node, combat_driver: Node, fireteam_id: String) -> void:
	var friendly = _find_friendly_fireteam_unit(controller, fireteam_id)
	var enemy = _find_first_enemy_unit(controller)
	if not (friendly is Node2D) or not (enemy is Node2D):
		return
	(enemy as Node2D).visible = true
	(enemy as Node2D).global_position = (friendly as Node2D).global_position + Vector2(42.0, 0.0)
	combat_driver.call("_update_contact_tracking")
	if combat_driver.has_method("_advance_detection_timers"):
		combat_driver.call("_advance_detection_timers")
	combat_driver.call("_update_contact_tracking")
	if controller.has_method("refresh_contact_overlay"):
		controller.call("refresh_contact_overlay")


func _position_fireteam_units(controller: Node, fireteam_id: String, anchor_position: Vector2) -> void:
	var index: int = 0
	for unit in Array(controller.call("_get_all_friendly_units", true)):
		if unit == null or not unit.has_method("get_fireteam_id") or not (unit is Node2D):
			continue
		if String(unit.call("get_fireteam_id")).strip_edges().to_lower() != fireteam_id.strip_edges().to_lower():
			continue
		(unit as Node2D).visible = true
		(unit as Node2D).global_position = anchor_position + Vector2(float(index) * 18.0, 0.0)
		index += 1


func _find_friendly_fireteam_unit(controller: Node, fireteam_id: String):
	for unit in Array(controller.call("_get_all_friendly_units", true)):
		if unit == null or not unit.has_method("get_fireteam_id"):
			continue
		if String(unit.call("get_fireteam_id")).strip_edges().to_lower() == fireteam_id.strip_edges().to_lower():
			return unit
	return null


func _find_first_enemy_unit(controller: Node):
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	return enemies[0] if not enemies.is_empty() else null


func _find_snapshot(snapshots: Array, fireteam_id: String) -> Dictionary:
	for snapshot_variant in snapshots:
		if typeof(snapshot_variant) != TYPE_DICTIONARY:
			continue
		var snapshot: Dictionary = Dictionary(snapshot_variant)
		if String(snapshot.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id.strip_edges().to_lower():
			return snapshot
	return {}


func _snapshot_has_required_status_fields(snapshot: Dictionary) -> bool:
	if snapshot.is_empty():
		return false
	if String(snapshot.get("execution_text", "")).strip_edges().is_empty():
		return false
	if String(snapshot.get("readiness_label", "")).strip_edges().is_empty():
		return false
	if not snapshot.has("contact_count") or not snapshot.has("health"):
		return false
	var health: Dictionary = Dictionary(snapshot.get("health", {}))
	return health.has("fit_count") and health.has("total_count") and String(snapshot.get("primary_text", "")).find("HP ") >= 0


func _status_snapshots_are_distinct(first: Dictionary, second: Dictionary) -> bool:
	if first.is_empty() or second.is_empty():
		return false
	if int(first.get("contact_count", 0)) != int(second.get("contact_count", 0)):
		return true
	return String(first.get("readiness_state", "")) != String(second.get("readiness_state", ""))


func _line_contains_status_tokens(text: String) -> bool:
	return text.find("EX ") >= 0 and text.find("RDY ") >= 0 and text.find("C") >= 0 and text.find("HP ") >= 0


func _mini_cards_stay_compact(card_list: Node) -> bool:
	for child in card_list.get_children():
		var control := child as Control
		if control == null or not control.visible:
			continue
		if control.size.y > 92.0:
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
