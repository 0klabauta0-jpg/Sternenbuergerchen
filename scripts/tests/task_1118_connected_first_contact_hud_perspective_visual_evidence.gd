extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const BLUE_PNG := "res://tmp/task_1118_connected_first_contact_blue.png"
const GOLD_PNG := "res://tmp/task_1118_connected_first_contact_gold.png"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1118 Connected First Contact HUD Perspective and Visual Evidence ===")
	root.size = Vector2i(1920, 1080)
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	await process_frame
	var controller: Node = mission.get_node("TacticalController")
	var driver: Node = mission.get_node("CombatLoopDriver")
	var simulation: Node = mission.get_node("SimulationRoot")
	var strategic_status: Control = mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel")
	var phase_controls: Control = mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel")
	_assert(strategic_status.get_index() < phase_controls.get_index(), "Mission Control keeps current combat status above scrollable phase controls")
	simulation.process_mode = Node.PROCESS_MODE_DISABLED
	driver.set("_runs_local_authority", false)
	var commands_before: int = Array(simulation.get("command_queue")).size()
	var effects_before: int = Array(simulation.get("effects_queue")).size()
	var snapshot: Dictionary = _combat_snapshot()
	var capture_perspective: String = OS.get_environment("STERNENBUERGERCHEN_TASK1118_CAPTURE_PERSPECTIVE").strip_edges().to_lower()
	driver.set("_remote_contact_snapshot", Array(snapshot.get("contacts", [])).duplicate(true))
	driver.set("_recent_fire_events", Array(snapshot.get("fire_events", [])).duplicate(true))
	controller.call("apply_authoritative_fire_rule_snapshot", snapshot.get("tactical_rules", []))

	var perspective_order: Array = ["gold", "blue"] if capture_perspective == "gold" else ["blue", "gold"]
	var perspective_results: Dictionary = {}
	for fireteam_id_variant in perspective_order:
		var fireteam_id: String = String(fireteam_id_variant)
		perspective_results[fireteam_id] = await _exercise_perspective(controller, mission, strategic_status, fireteam_id, capture_perspective)
	var blue: Dictionary = Dictionary(perspective_results.get("blue", {}))
	var gold: Dictionary = Dictionary(perspective_results.get("gold", {}))
	_assert(not String(blue.get("perspective_signature", "")).is_empty() and String(blue.get("perspective_signature", "")) != String(gold.get("perspective_signature", "")), "Blue and Gold expose different stable perspective signatures")
	_assert(Array(simulation.get("command_queue")).size() == commands_before and Array(simulation.get("effects_queue")).size() == effects_before, "Perspective switching creates no Gameplay commands or effects")
	if DisplayServer.get_name().strip_edges().to_lower() != "headless" and capture_perspective in ["blue", "gold"]:
		var expected_path: String = BLUE_PNG if capture_perspective == "blue" else GOLD_PNG
		_assert(FileAccess.file_exists(expected_path), "%s FullHD evidence PNG is written in its own renderer process" % capture_perspective.capitalize())

	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _exercise_perspective(controller: Node, mission: Node, strategic_status: Control, fireteam_id: String, capture_perspective: String) -> Dictionary:
	var expected: Dictionary = {
		"blue": {"event_id": "task1118:blue:fire", "roe": "FW", "outcome": "HIT", "png": BLUE_PNG},
		"gold": {"event_id": "task1118:gold:fire", "roe": "RF", "outcome": "MISS", "png": GOLD_PNG},
	}.get(fireteam_id, {})
	controller.call("_set_selected_fireteams", PackedStringArray([fireteam_id]), false)
	controller.call("_update_ui")
	await process_frame
	var perspective: Dictionary = Dictionary(controller.call("get_connected_first_contact_hud_perspective_snapshot")) if controller.has_method("get_connected_first_contact_hud_perspective_snapshot") else {}
	var label: String = fireteam_id.capitalize()
	_assert(String(perspective.get("fire_event_id", "")) == String(expected.get("event_id", "")), "%s reads its relevant First-Fire event" % label)
	_assert(String(perspective.get("primary_line", "")).begins_with("%s | CONTACT FIRE" % fireteam_id.to_upper()), "%s primary line starts with contact ownership" % label)
	_assert(_line_is_complete(String(perspective.get("primary_line", "")), String(expected.get("roe", "")), String(expected.get("outcome", ""))), "%s line exposes ROE, outcome and NEXT" % label)
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(feedback.get("selected_fireteam_status_label_text", "")).contains(String(perspective.get("primary_line", ""))) and String(feedback.get("mission_control_status_text", "")).contains(String(perspective.get("primary_line", ""))), "%s perspective is rendered in Selected Fireteam and Mission Control" % label)
	var strategic_panel: Control = mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel")
	var strategic_rect: Rect2 = strategic_status.get_global_rect()
	_assert(strategic_status.is_visible_in_tree() and String((strategic_status as Label).text).contains(String(perspective.get("primary_line", ""))) and strategic_rect.intersects(strategic_panel.get_global_rect()) and strategic_rect.size.y >= 32.0, "%s Mission Control status has readable visible height" % label)
	if DisplayServer.get_name().strip_edges().to_lower() != "headless" and capture_perspective == fireteam_id:
		await _save_viewport(String(expected.get("png", "")))
	return perspective


func _combat_snapshot() -> Dictionary:
	return {
		"tick": 1118,
		"contacts": [
			_contact("blue", "enemy_delta", Vector2(420.0, 260.0)),
			_contact("gold", "enemy_echo", Vector2(820.0, 460.0)),
		],
		"fire_events": [
			_fire_event("task1118:blue:fire", "blue", "unit_alpha", "enemy_delta", "hit"),
			_fire_event("task1118:gold:fire", "gold", "unit_echo", "enemy_echo", "miss"),
		],
		"tactical_rules": [
			{"fireteam_id": "blue", "team_id": "team_alpha", "fire_rule": "free", "revision": 2},
			{"fireteam_id": "gold", "team_id": "team_alpha", "fire_rule": "return", "revision": 2},
		],
		"dropship": {},
		"mission_interactions": {},
	}


func _contact(fireteam_id: String, unit_id: String, position: Vector2) -> Dictionary:
	return {"fireteam_id": fireteam_id, "unit_id": unit_id, "team_id": "team_bravo", "enemy_type": "rifleman", "last_known_position": position, "detection_state": "confirmed", "report_state": "current", "confidence": 0.92, "report_text": "1 contact, rifleman, now", "read_only": true, "ui_sets_gameplay_truth": false}


func _fire_event(event_id: String, fireteam_id: String, attacker_id: String, target_id: String, outcome: String) -> Dictionary:
	return {"event_id": event_id, "event_type": "weapon_fire", "attacker_unit_id": attacker_id, "attacker_fireteam_id": fireteam_id, "attacker_team_id": "team_alpha", "target_unit_id": target_id, "target_team_id": "team_bravo", "weapon_id": "assault_rifle", "combat_outcome": outcome, "result": outcome, "read_only": true, "ui_sets_gameplay_truth": false}


func _line_is_complete(line: String, roe: String, outcome: String) -> bool:
	return line.contains("ROE %s" % roe) and line.contains(outcome) and line.contains("NEXT")


func _save_viewport(path: String) -> void:
	var capture_size: Vector2i = root.size
	root.size = Vector2i(capture_size.x - 1, capture_size.y)
	await process_frame
	root.size = capture_size
	for _frame in range(8):
		await process_frame
	RenderingServer.force_draw(true)
	await process_frame
	var image: Image = root.get_texture().get_image()
	var error: Error = image.save_png(path) if image != null else ERR_CANT_CREATE
	_assert(image != null and image.get_width() == 1920 and image.get_height() == 1080 and error == OK, "%s is a valid FullHD viewport capture" % path.get_file())


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
