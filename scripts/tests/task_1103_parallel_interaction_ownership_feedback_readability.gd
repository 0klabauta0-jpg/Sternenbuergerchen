extends SceneTree

const SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1103 Parallel Interaction Ownership Feedback Readability ===")
	var scene: Node = SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	var controller: Node = scene.get_node("TacticalController")
	var command_feedback_label := controller.get_node_or_null(controller.get("command_feedback_label_path")) as Label
	var label_minimum_before: Vector2 = command_feedback_label.custom_minimum_size if command_feedback_label != null else Vector2.ZERO

	controller.set("_network_mission_interaction_feedback", {"display_token": "COM", "fireteam_id": "gold"})
	controller.call("_apply_network_mission_interaction_result", {
		"accepted": false,
		"interaction_id": "parallel_terminal_alpha",
		"fireteam_id": "gold",
		"reason": "interaction_reserved_by_other_fireteam",
		"source_context": "mission_interaction_use_intent_command",
	})
	var blocked: Dictionary = Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(String(blocked.get("compact_line", "")) == "COM GOLD BLOCKIERT | ANDERES FIRETEAM AKTIV", "Reservation reject names requesting Fireteam and human reason")
	_assert(not String(blocked.get("compact_line", "")).contains("parallel_terminal") and not String(blocked.get("compact_line", "")).contains("interaction_reserved"), "Reservation feedback hides technical identifiers")
	_assert(String(blocked.get("fireteam_id", "")) == "gold" and String(blocked.get("reason_label", "")) == "ANDERES FIRETEAM AKTIV", "Feedback snapshot keeps read-only requesting Fireteam context")

	var single_snapshot := {
		"source_tick": 10,
		"interaction_states": {
			"station_computer": {"state": "operating", "complete": false, "progress": 0.42, "hold_seconds": 8.0, "duration_seconds": 18.0, "interaction_type": "computer", "fireteam_id": "blue"},
		},
	}
	_assert(bool(controller.call("_apply_network_mission_interaction_progress_surface", single_snapshot)), "Single owned Interaction updates progress surface")
	var single: Dictionary = Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(String(single.get("compact_line", "")) == "COM 42% | 8/18s BLUE", "Single Interaction line names owning Fireteam")
	_assert(String(single.get("owner_fireteam_id", "")) == "blue" and int(single.get("parallel_owner_count", 0)) == 1, "Single progress snapshot exposes owner diagnostics")

	var parallel_snapshot := {
		"source_tick": 11,
		"interaction_states": {
			"station_computer": {"state": "operating", "complete": false, "progress": 0.42, "hold_seconds": 8.0, "duration_seconds": 18.0, "interaction_type": "computer", "fireteam_id": "blue"},
			"cargo_landing_hold": {"state": "holding", "complete": false, "progress": 0.58, "hold_seconds": 7.0, "duration_seconds": 12.0, "interaction_type": "hold_zone", "fireteam_id": "gold"},
		},
	}
	_assert(bool(controller.call("_apply_network_mission_interaction_progress_surface", parallel_snapshot)), "Parallel owned Interactions update one compact surface")
	var parallel: Dictionary = Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(String(parallel.get("compact_line", "")) == "COM 42% BLUE | CARGO 58% GOLD", "Parallel line names both Interaction owners")
	_assert(String(parallel.get("compact_line", "")).length() <= 72 and int(parallel.get("parallel_owner_count", 0)) == 2, "Parallel ownership line respects compact budget")
	_assert(command_feedback_label != null and command_feedback_label.text.contains("LAST COM 42% BLUE | CARGO 58% GOLD"), "Existing LAST HUD line renders parallel ownership summary")
	_assert(command_feedback_label != null and command_feedback_label.custom_minimum_size == label_minimum_before, "Ownership refresh keeps HUD label dimensions stable")
	_assert(not bool(controller.call("_apply_network_mission_interaction_progress_surface", parallel_snapshot)), "Identical parallel snapshot is deduplicated")

	var ownership_change: Dictionary = parallel_snapshot.duplicate(true)
	ownership_change["source_tick"] = 12
	var changed_states: Dictionary = Dictionary(ownership_change.get("interaction_states", {})).duplicate(true)
	var changed_computer: Dictionary = Dictionary(changed_states.get("station_computer", {})).duplicate(true)
	changed_computer["fireteam_id"] = "silver"
	changed_states["station_computer"] = changed_computer
	ownership_change["interaction_states"] = changed_states
	_assert(bool(controller.call("_apply_network_mission_interaction_progress_surface", ownership_change)), "Owner change invalidates progress fingerprint")
	var changed: Dictionary = Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(String(changed.get("compact_line", "")).contains("SILVER"), "Updated owner becomes visible without progress change")
	var neutral_parallel := {
		"source_tick": 13,
		"interaction_states": {
			"station_computer": {"state": "operating", "complete": false, "progress": 0.42, "hold_seconds": 8.0, "duration_seconds": 18.0, "interaction_type": "computer", "fireteam_id": "silver"},
			"parallel_aux": {"state": "operating", "complete": false, "progress": 0.58, "hold_seconds": 7.0, "duration_seconds": 12.0, "interaction_type": "terminal", "fireteam_id": "gold"},
		},
	}
	_assert(bool(controller.call("_apply_network_mission_interaction_progress_surface", neutral_parallel)), "Neutral second Interaction token updates summary")
	var token_change: Dictionary = neutral_parallel.duplicate(true)
	token_change["source_tick"] = 14
	var token_states: Dictionary = Dictionary(token_change.get("interaction_states", {})).duplicate(true)
	var token_aux: Dictionary = Dictionary(token_states.get("parallel_aux", {})).duplicate(true)
	token_aux["interaction_type"] = "door"
	token_states["parallel_aux"] = token_aux
	token_change["interaction_states"] = token_states
	_assert(bool(controller.call("_apply_network_mission_interaction_progress_surface", token_change)), "Visible second token change invalidates progress fingerprint")
	_assert(String(Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot")).get("compact_line", "")).contains("DOOR 58% GOLD"), "Changed second token reaches existing HUD line")
	_assert(not bool(changed.get("ui_sets_gameplay_truth", true)), "Ownership feedback remains read-only UI")

	scene.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
