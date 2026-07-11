extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_431_fireteam_aim_pose_and_card_ui_hotfix.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_431 Fireteam Aim Pose And Card UI Hotfix ===")
	await _test_aim_pose_uses_static_hold_sample()
	await _test_fireteam_mini_card_reuse_and_cleanup()
	await _test_single_feedback_bubble_and_wp_erase_button()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_aim_pose_uses_static_hold_sample() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_431_aim_pose_map", Vector2i(4, 4), Vector2.ZERO, 64.0, 32.0, 2)
	var terrain_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(terrain_view)
	terrain_view.call("configure_from_map", map_data)
	var unit: Node2D = _make_unit("task431_unit", Vector2(64.0, 64.0))
	root.add_child(unit)
	unit.call("set_runtime_status", "assigned", "move_to_position", 10, "fire_at_will", "task_431", 1.0, 0.0, 0.0, -1, unit.global_position, "engage", "aimed", "debug_aimed")
	terrain_view.call("set_unit_nodes", [unit])
	await _wait_frames(8)

	var proxy := _find_proxy_node_by_unit_id(terrain_view, "task431_unit") as Node3D
	var player := _find_unit_visual_animation_player(proxy)
	_assert(proxy != null and player != null, "Runtime proxy owns a visual AnimationPlayer")
	if player != null:
		var shoot_animation: Animation = player.get_animation("shoot") if player.has_animation("shoot") else null
		var walk_shoot: Animation = player.get_animation("walkShoot") if player.has_animation("walkShoot") else null
		_assert(shoot_animation != null and float(shoot_animation.get_meta("unit_weapon_upper_body_pose_sample_time", 0.0)) > 0.0, "Aim pose samples a non-zero Shoot hold key")
		_assert(walk_shoot != null and bool(walk_shoot.get_meta("unit_animation_pose_static_hold", false)), "walkShoot bakes a static upper-body hold pose")
		_assert(_has_static_hold_rotation_track(walk_shoot), "Baked walkShoot upper-body track keeps the same raised-pose rotation")
	var snapshot: Dictionary = Dictionary(terrain_view.call("get_render_snapshot"))
	var proxy_state: Dictionary = Dictionary(Dictionary(snapshot.get("unit_proxy_state_by_id", {})).get("task431_unit", {}))
	_assert(bool(proxy_state.get("unit_weapon_upper_body_pose_active", false)), "Aimed runtime posture activates upper-body pose")
	terrain_view.queue_free()
	unit.queue_free()
	await _wait_frames(2)


func _test_fireteam_mini_card_reuse_and_cleanup() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Drill scene exposes TacticalController")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_refresh_fireteam_mini_cards")
	var card_list := scene.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox")
	var first_card: Control = null
	if card_list != null:
		first_card = card_list.get_node_or_null("FireteamMiniCard_Drill") as Control
	var first_stance_button: Button = null
	if first_card != null:
		first_stance_button = first_card.find_child("StanceCButton", true, false) as Button
	controller.call("_refresh_fireteam_mini_cards")
	var second_card: Control = null
	if card_list != null:
		second_card = card_list.get_node_or_null("FireteamMiniCard_Drill") as Control
	var second_stance_button: Button = null
	if second_card != null:
		second_stance_button = second_card.find_child("StanceCButton", true, false) as Button
	_assert(first_card != null and first_card == second_card, "Mini-card is reused across refreshes")
	_assert(first_stance_button != null and first_stance_button == second_stance_button, "Mini-card stance segments keep their instances across refreshes")
	_assert(first_card != null and first_card.find_child("FTLReadinessGauge", true, false) == null, "Mini-card no longer shows the round FTL readiness gauge")
	var stage_label := first_card.get_node_or_null("Margin/VBox/StageLabel") as Label if first_card != null else null
	var member_label := first_card.get_node_or_null("Margin/VBox/MemberLabel") as Label if first_card != null else null
	var card_text: String = "%s %s" % [stage_label.text if stage_label != null else "", member_label.text if member_label != null else ""]
	_assert(not card_text.contains("LD MEDIUM"), "Mini-card status removes loadout-medium text")
	var readiness_footer: Label = null
	var portrait_strip: HBoxContainer = null
	if first_card != null:
		readiness_footer = first_card.find_child("ReadinessFooterLabel", true, false) as Label
		portrait_strip = first_card.find_child("FireteamMemberPortraitStrip", true, false) as HBoxContainer
	var readiness_state: String = String(readiness_footer.get_meta("mission_fireteam_readiness_state", "")) if readiness_footer != null else ""
	var truthful_readiness: bool = readiness_footer != null \
		and ((readiness_state == "unavailable" and not readiness_footer.visible and readiness_footer.text.is_empty()) \
		or (readiness_state != "unavailable" and readiness_footer.visible and not readiness_footer.text.is_empty()))
	_assert(truthful_readiness, "Readiness footer shows only available player-readable state")
	_assert(portrait_strip != null and portrait_strip.get_child_count() >= 4, "Mini-card shows member portraits at the bottom")
	scene.queue_free()
	await _wait_frames(2)


func _test_single_feedback_bubble_and_wp_erase_button() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)
	var controller := scene.get_node_or_null("TacticalController")
	var command_grid := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid") as GridContainer
	_assert(controller != null and command_grid != null, "Drill scene exposes controller and command grid")
	if controller == null or command_grid == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	var wp_button := command_grid.get_node_or_null("WaypointEraseButton") as Button
	_assert(wp_button != null and wp_button.text == "WP-" and String(wp_button.get_meta("command_matrix_slot_id", "")) == "16.20", "Command matrix slot 16.20 is WP erase")
	_assert(wp_button != null and is_equal_approx(wp_button.custom_minimum_size.x, wp_button.custom_minimum_size.y), "WP erase button stays square")

	controller.call("_store_fireteamleader_feedback_bubble", {"fireteam_id": "drill", "feedback_action": "move", "text": "Move West", "duration_seconds": 4.0})
	controller.call("_store_fireteamleader_feedback_bubble", {"fireteam_id": "drill", "feedback_action": "take", "text": "Take Objective", "duration_seconds": 4.0})
	var bubbles: Array = Array(controller.call("get_fireteamleader_feedback_bubble_snapshot"))
	var latest: Dictionary = Dictionary(bubbles[0]) if bubbles.size() == 1 else {}
	_assert(bubbles.size() == 1 and String(latest.get("feedback_action", "")) == "take", "New FTL bubble replaces the previous bubble")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("TASK_431 - Fireteam Aim Pose And Card UI Hotfix"), "TASK_431 task file exists")
	_assert(status_text.contains("TASK_431 - Fireteam Aim Pose And Card UI Hotfix"), "Implementation status documents TASK_431")
	_assert(roadmap_text.contains("TASK_431 - Fireteam Aim Pose And Card UI Hotfix"), "Roadmap lists TASK_431")


func _make_unit(unit_id: String, position_value: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = "blue"
	unit.weapon_1_id = "rifle"
	unit.weapon_2_id = "rifle"
	unit.global_position = position_value
	unit._ready()
	return unit


func _has_static_hold_rotation_track(animation: Animation) -> bool:
	if animation == null:
		return false
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) != Animation.TYPE_ROTATION_3D:
			continue
		if animation.track_get_key_count(track_index) != 2:
			continue
		var first_value: Variant = animation.track_get_key_value(track_index, 0)
		var second_value: Variant = animation.track_get_key_value(track_index, 1)
		if typeof(first_value) != TYPE_QUATERNION or typeof(second_value) != TYPE_QUATERNION:
			continue
		var first_rotation := Quaternion(first_value)
		var second_rotation := Quaternion(second_value)
		if absf(absf(first_rotation.dot(second_rotation)) - 1.0) < 0.001:
			return true
	return false


func _find_proxy_node_by_unit_id(node: Node, unit_id: String) -> Node:
	if node == null:
		return null
	if String(node.get_meta("unit_id", "")) == unit_id:
		return node
	for child in node.get_children():
		var found: Node = _find_proxy_node_by_unit_id(child, unit_id)
		if found != null:
			return found
	return null


func _find_unit_visual_animation_player(node: Node) -> AnimationPlayer:
	if node == null:
		return null
	if node is AnimationPlayer and String(node.name) == "UnitVisualAnimationPlayer":
		return node as AnimationPlayer
	for child in node.get_children():
		var found: AnimationPlayer = _find_unit_visual_animation_player(child)
		if found != null:
			return found
	return null


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
