extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const MINI_CARD_HOST_PATH: String = "TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1062 Fireteam Card Delta Rendering ===")
	await _test_suppression_refresh_keeps_static_card_configuration()
	await _test_invalidated_reference_signature_reapplies_static_configuration()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_suppression_refresh_keeps_static_card_configuration() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(16)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var card_host := scene.get_node_or_null(MINI_CARD_HOST_PATH) as Control
	_assert(controller != null and card_host != null, "Mission fixture exposes controller and mini-card host")
	if controller == null or card_host == null:
		await _cleanup(scene)
		return
	_assert(controller.has_method("get_mission_fireteam_card_delta_rendering_snapshot"), "Controller exposes read-only Fireteam-card delta diagnostics")
	if not controller.has_method("get_mission_fireteam_card_delta_rendering_snapshot"):
		await _cleanup(scene)
		return

	var card := _first_mini_card(card_host)
	var fireteam_id: String = String(card.get_meta("fireteam_id", "")).strip_edges().to_lower() if card != null else ""
	_assert(not fireteam_id.is_empty(), "Fixture provides a named Fireteam mini-card")
	if fireteam_id.is_empty():
		await _cleanup(scene)
		return
	controller.set("_suppression_state_by_fireteam", {fireteam_id: _suppression_state(0.0)})
	controller.call("_refresh_fireteam_mini_cards")
	card = _first_mini_card(card_host)
	var title_edit := card.get_node_or_null("Margin/VBox/HeaderRow/TitleEdit") as LineEdit if card != null else null
	var leader_portrait := card.get_node_or_null("Margin/VBox/HeaderRow/LeaderPortraitRect") as TextureRect if card != null else null
	var before: Dictionary = Dictionary(controller.call("get_mission_fireteam_card_delta_rendering_snapshot"))
	_assert(card != null and title_edit != null and leader_portrait != null, "Mini-card has persistent static identity controls")
	if card == null or title_edit == null or leader_portrait == null:
		await _cleanup(scene)
		return
	var card_id: int = card.get_instance_id()
	var title_id: int = title_edit.get_instance_id()
	var leader_portrait_id: int = leader_portrait.get_instance_id()

	controller.set("_suppression_state_by_fireteam", {fireteam_id: _suppression_state(1.0)})
	controller.call("_refresh_fireteam_mini_cards")
	var after: Dictionary = Dictionary(controller.call("get_mission_fireteam_card_delta_rendering_snapshot"))
	var refreshed_card := _find_mini_card(card_host, fireteam_id)
	var suppression_bar := refreshed_card.find_child("MiniSuppressionBar", true, false) as ProgressBar if refreshed_card != null else null

	_assert(refreshed_card != null and refreshed_card.get_instance_id() == card_id, "Suppression refresh keeps the Fireteam card node")
	_assert(refreshed_card != null and refreshed_card.get_node_or_null("Margin/VBox/HeaderRow/TitleEdit") != null and refreshed_card.get_node("Margin/VBox/HeaderRow/TitleEdit").get_instance_id() == title_id, "Suppression refresh keeps the title identity control")
	_assert(refreshed_card != null and refreshed_card.get_node_or_null("Margin/VBox/HeaderRow/LeaderPortraitRect") != null and refreshed_card.get_node("Margin/VBox/HeaderRow/LeaderPortraitRect").get_instance_id() == leader_portrait_id, "Suppression refresh keeps the leader portrait control")
	_assert(suppression_bar != null and is_equal_approx(suppression_bar.value, 1.0), "Suppression refresh still updates the visible live bar")
	_assert(int(after.get("static_apply_count", -1)) == int(before.get("static_apply_count", -2)), "Pure live status does not reapply static card configuration")
	_assert(int(after.get("static_skip_count", 0)) > int(before.get("static_skip_count", 0)), "Pure live status records a static configuration skip")
	_assert(int(after.get("runtime_status_apply_count", 0)) > int(before.get("runtime_status_apply_count", 0)), "Pure live status still applies the runtime card delta")
	_assert(bool(after.get("read_only", false)), "Delta diagnostics remain read-only")
	_assert(not bool(after.get("ui_sets_gameplay_truth", true)), "Delta diagnostics do not own gameplay truth")
	await _cleanup(scene)


func _test_invalidated_reference_signature_reapplies_static_configuration() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(16)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var card_host := scene.get_node_or_null(MINI_CARD_HOST_PATH) as Control
	_assert(controller != null and card_host != null, "Reference-change fixture exposes controller and mini-card surface")
	if controller == null or card_host == null:
		await _cleanup(scene)
		return
	var card := _first_mini_card(card_host)
	var fireteam_id: String = String(card.get_meta("fireteam_id", "")).strip_edges().to_lower() if card != null else ""
	_assert(card != null and not fireteam_id.is_empty(), "Reference-change fixture resolves a Fireteam mini-card")
	if card == null or fireteam_id.is_empty():
		await _cleanup(scene)
		return
	var before: Dictionary = Dictionary(controller.call("get_mission_fireteam_card_delta_rendering_snapshot"))
	var current_signature: String = String(card.get_meta("mission_fireteam_mini_card_static_signature", ""))
	var changed_signature: String = String(controller.call("_build_fireteam_mini_card_static_signature", fireteam_id, null, "Lead changed | 5 members"))
	_assert(not current_signature.is_empty() and current_signature != changed_signature, "Reference-signature contract distinguishes a changed lead summary")
	card.set_meta("mission_fireteam_mini_card_static_signature", "outdated-reference")
	controller.set("_suppression_state_by_fireteam", {fireteam_id: _suppression_state(1.5)})
	controller.call("_refresh_fireteam_mini_cards")
	var after: Dictionary = Dictionary(controller.call("get_mission_fireteam_card_delta_rendering_snapshot"))
	var refreshed_card := _find_mini_card(card_host, fireteam_id)
	var title_edit := refreshed_card.get_node_or_null("Margin/VBox/HeaderRow/TitleEdit") as LineEdit if refreshed_card != null else null
	_assert(title_edit != null and not title_edit.text.is_empty(), "Static configuration restores the reference identity text")
	_assert(int(after.get("static_apply_count", 0)) > int(before.get("static_apply_count", 0)), "Invalidated reference signature reapplies static card configuration")
	await _cleanup(scene)


func _suppression_state(value: float) -> Dictionary:
	return {
		"value": value,
		"threshold": 2.0,
		"is_suppressed": false,
		"is_heavily_suppressed": false,
		"applied_level": 0,
		"hold_until_msec": 0,
	}


func _first_mini_card(card_host: Control) -> Control:
	if card_host == null:
		return null
	for child_variant in card_host.get_children():
		var child := child_variant as Control
		if child != null and not String(child.get_meta("fireteam_id", "")).strip_edges().is_empty():
			return child
	return null


func _find_mini_card(card_host: Control, fireteam_id: String) -> Control:
	if card_host == null:
		return null
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	for child_variant in card_host.get_children():
		var child := child_variant as Control
		if child != null and String(child.get_meta("fireteam_id", "")).strip_edges().to_lower() == normalized_fireteam_id:
			return child
	return null


func _cleanup(scene: Node) -> void:
	if is_instance_valid(scene):
		scene.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
