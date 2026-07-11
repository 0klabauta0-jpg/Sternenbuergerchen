extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const OUTPUT_PNG_PATH := "res://tmp/task_1114_dropship_pending_card_visual_polish.png"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1114 Connected Dropship Pending Card Visual Polish ===")
	root.size = Vector2i(1920, 1080)
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	await process_frame
	var controller: Node = mission.get_node("TacticalController")
	var state: Dictionary = Dictionary(controller.call("get_planning_state"))
	state["mission_drop_craft_id"] = "dropship_blue"
	state["selected_fireteams"] = ["blue"]
	state["mission_drop_cards"] = [
		_card("dropship_blue", "blue"),
		_card("dropship_gold", "gold"),
	]
	controller.call("set_planning_state", state)
	controller.set("_pending_network_dropship_commands_by_craft", {
		"dropship_blue": {
			"command_id": "task1114:blue:set_lz",
			"command_type": "set_lz",
			"phase": "request_sent",
			"remaining_seconds": 8.0,
			"payload": {"lz_position": Vector2(400.0, 200.0)},
			"compact_line": "LZ DROPSHIP BLUE -> HOST",
		}
	})
	controller.call("_update_ui")
	await process_frame

	var blue_pending: Dictionary = Dictionary(controller.call("get_mission_dropship_card_ui_snapshot", "dropship_blue"))
	var gold_idle: Dictionary = Dictionary(controller.call("get_mission_dropship_card_ui_snapshot", "dropship_gold"))
	_assert(String(blue_pending.get("feedback_text", "")).contains("HOST"), "Blue card shows its Pending host roundtrip")
	_assert(String(blue_pending.get("feedback_tone", "")) == "pending", "Blue Pending uses explicit pending tone")
	_assert(not String(blue_pending.get("feedback_color", "")).is_empty(), "Blue Pending exposes stable theme color")
	_assert(_all_commands_disabled(blue_pending), "Blue Pending disables Blue command buttons")
	_assert(not _all_commands_disabled(gold_idle), "Gold command buttons remain independently available")
	_assert(String(gold_idle.get("feedback_tone", "")) != "pending", "Gold card does not inherit Blue Pending tone")

	controller.call("_apply_network_dropship_command_result", {
		"accepted": false,
		"command_type": "set_lz",
		"craft_id": "dropship_blue",
		"command_id": "task1114:blue:set_lz",
		"reason": "fireteam_not_assigned_to_peer",
	})
	await process_frame
	var blue_blocked: Dictionary = Dictionary(controller.call("get_mission_dropship_card_ui_snapshot", "dropship_blue"))
	_assert(String(blue_blocked.get("feedback_text", "")).contains("BLOCKIERT"), "Reject stays on the affected craft card")
	_assert(String(blue_blocked.get("feedback_tone", "")) == "blocked", "Reject uses blocked tone")
	_assert(not _all_commands_disabled(blue_blocked), "Reject releases Blue command buttons")

	controller.set("_pending_network_dropship_commands_by_craft", {
		"dropship_blue": {
			"command_id": "task1114:blue:success",
			"command_type": "set_lz",
			"phase": "accepted_waiting_snapshot",
			"remaining_seconds": 8.0,
			"payload": {"lz_position": Vector2(400.0, 200.0)},
			"compact_line": "LZ DROPSHIP BLUE HOST OK",
		}
	})
	var snapshot: Dictionary = Dictionary(controller.call("get_planning_state"))
	snapshot["mission_drop_cards"] = [
		_card("dropship_blue", "blue").merged({"has_lz_position": true, "lz_position": Vector2(400.0, 200.0)}, true),
		_card("dropship_gold", "gold"),
	]
	controller.call("apply_authoritative_mission_dropship_snapshot", snapshot)
	await process_frame
	var blue_success: Dictionary = Dictionary(controller.call("get_mission_dropship_card_ui_snapshot", "dropship_blue"))
	_assert(String(blue_success.get("feedback_text", "")).contains("HOST OK"), "Matching snapshot leaves short craft-specific success feedback")
	_assert(String(blue_success.get("feedback_tone", "")) == "success", "Matching snapshot uses success tone")
	_assert(int(Dictionary(controller.call("get_network_dropship_pending_debug_snapshot")).get("pending_count", -1)) == 0, "Success feedback does not keep gameplay request Pending")
	if DisplayServer.get_name().strip_edges().to_lower() != "headless":
		for _frame in range(8):
			await process_frame
		var image: Image = root.get_texture().get_image()
		var save_error: Error = image.save_png(OUTPUT_PNG_PATH) if image != null else ERR_CANT_CREATE
		_assert(image != null and image.get_width() == 1920 and image.get_height() == 1080, "Real-window evidence uses FullHD viewport")
		_assert(save_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "Real-window Dropship card evidence PNG is written")

	controller.call("_advance_network_dropship_pending", 20.0)
	await process_frame
	var blue_expired: Dictionary = Dictionary(controller.call("get_mission_dropship_card_ui_snapshot", "dropship_blue"))
	_assert(String(blue_expired.get("feedback_tone", "")) != "success", "Transient success feedback expires without changing craft state")

	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _card(craft_id: String, fireteam_id: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"display_name": craft_id.replace("_", " ").capitalize(),
		"state": "waiting",
		"progress": 0.0,
		"passenger_count": 1,
		"embarked_unit_ids": ["%s_unit" % fireteam_id],
		"boarded_fireteam_ids": [fireteam_id],
		"has_lz_position": false,
		"approach_angle": "NW",
	}


func _all_commands_disabled(snapshot: Dictionary) -> bool:
	var commands: Dictionary = Dictionary(snapshot.get("commands", {}))
	if commands.is_empty():
		return false
	for command_variant in commands.values():
		if not bool(Dictionary(command_variant).get("disabled", false)):
			return false
	return true


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
