extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const CAUTIOUS_CAPTURE := "res://tmp/task_1136_stance_cautious.png"
const OFFENSIVE_CAPTURE := "res://tmp/task_1136_stance_offensive.png"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1136 Live Tactical Stance Effect Playtest and Feedback ===")
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)
	var controller := scene.get_node_or_null("TacticalController")
	var feedback_label := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/CommandFeedbackLabel") as Label
	var stance_summary := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/TacticalStancePanel/MarginContainer/VBoxContainer/SummaryLabel") as Label
	_assert(controller != null and feedback_label != null and stance_summary != null, "Drill exposes controller and both real stance feedback surfaces")
	if controller != null and feedback_label != null and stance_summary != null:
		await _run_live_stance_playtest(controller, feedback_label, stance_summary)
	scene.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _run_live_stance_playtest(controller: Node, feedback_label: Label, stance_summary: Label) -> void:
	var units: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	var leader = controller.call("_resolve_fireteam_leader_for_behavior", "drill")
	_assert(units.size() == 4 and leader is Node2D, "Drill exposes a complete moving Fireteam")
	if units.size() != 4 or not (leader is Node2D):
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var target_position: Vector2 = (leader as Node2D).global_position + Vector2(320.0, -96.0)
	var profile = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.new()
	profile.fireteam_id = "drill"
	profile.advance_style = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH
	profile.tactical_stance = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL
	profile.order_fidelity = 1.0
	profile.execution_cohesion = 0.65
	profile.metadata = {"origin_command_type": "move", "rough_target_position": target_position}
	controller.call("_set_active_behavior_profile", "drill", profile)
	var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
	waypoint.waypoint_id = "wp_task1136_live"
	waypoint.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE
	waypoint.target_position = target_position
	_assert(bool(controller.call("_issue_waypoint_for_fireteam", "drill", waypoint, 1, profile)), "Live playtest starts a real Move execution")
	await _wait_frames(3)

	_assert(bool(controller.call("set_fireteams_tactical_stance", PackedStringArray(["drill"]), "cautious")), "VORS applies during the running Move")
	await _wait_frames(3)
	var cautious_runtime: Dictionary = Dictionary((leader as Node).call("get_runtime_status").to_dict())
	var cautious_text := feedback_label.text
	_assert(cautious_text.contains("VORSICHTIG LIVE") and cautious_text.contains("langsam"), "Real HUD confirms cautious live tempo")
	_assert(cautious_text.contains("volle Sicht") and cautious_text.contains("Waffe im Anschlag"), "Real HUD explains cautious sight and weapon posture")
	_assert(stance_summary.text == "VORS LIVE | langsam | Sicht voll | Anschlag", "Visible stance panel mirrors compact cautious effects")
	_assert(stance_summary.max_lines_visible == 1 and stance_summary.get_global_rect().size.y >= 14.0 and stance_summary.get_minimum_size().x <= stance_summary.get_global_rect().size.x, "Visible cautious feedback reserves one fitting line")
	_assert(String(cautious_runtime.get("movement_posture", "")) == "engage" and String(cautious_runtime.get("weapon_posture", "")) == "aimed", "Cautious runtime simultaneously uses engage/aimed")
	if OS.get_environment("STERNEN_TASK1136_CAPTURE") == "1":
		await _capture(CAUTIOUS_CAPTURE, "Cautious FullHD capture is written")

	_assert(bool(controller.call("set_fireteams_tactical_stance", PackedStringArray(["drill"]), "aggressive")), "OFF applies during the same running Move")
	await _wait_frames(3)
	var offensive_runtime: Dictionary = Dictionary((leader as Node).call("get_runtime_status").to_dict())
	var offensive_text := feedback_label.text
	_assert(offensive_text.contains("OFFENSIV LIVE") and offensive_text.contains("schnell"), "Real HUD confirms offensive live tempo")
	_assert(offensive_text.contains("kurze Sicht") and offensive_text.contains("Waffe gesenkt"), "Real HUD explains offensive sight and weapon posture")
	_assert(stance_summary.text == "OFF LIVE | schnell | Sicht kurz | gesenkt", "Visible stance panel mirrors compact offensive effects")
	_assert(stance_summary.get_minimum_size().x <= stance_summary.get_global_rect().size.x, "Visible offensive feedback fits without truncation")
	_assert(String(offensive_runtime.get("movement_posture", "")) == "run" and String(offensive_runtime.get("weapon_posture", "")) == "lowered", "Offensive runtime simultaneously uses run/lowered")
	_assert(float(cautious_runtime.get("move_speed_factor", 0.0)) < float(offensive_runtime.get("move_speed_factor", 0.0)), "Live runtime makes OFF faster than VORS")
	_assert(float(cautious_runtime.get("sight_range_factor", 0.0)) > float(offensive_runtime.get("sight_range_factor", 0.0)), "Live runtime gives VORS more sight than OFF")
	if OS.get_environment("STERNEN_TASK1136_CAPTURE") == "1":
		await _capture(OFFENSIVE_CAPTURE, "Offensive FullHD capture is written")


func _capture(path: String, message: String) -> void:
	RenderingServer.force_draw(true)
	await process_frame
	var image: Image = root.get_texture().get_image()
	var error := image.save_png(path) if image != null else ERR_CANT_CREATE
	_assert(image != null and image.get_size() == Vector2i(1920, 1080) and error == OK, message)


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
