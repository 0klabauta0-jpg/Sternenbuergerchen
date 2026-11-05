extends SceneTree
## Synthetic scheduling component check on the real mission scene/owners.
## Commands use public entry points; no actor, HP, skill, position or timer writes.
## Direct owner _process calls are not native cadence or physical movement proof.

const SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const CONTROLLER: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const BASE: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/"
const GRID: String = BASE + "CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"
const TEAM: String = BASE + "FireteamPanel"
const FEEDBACK_SOURCE: String = TEAM + "/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/CommandFeedbackLabel"
const TEAM_STATUS: String = TEAM + "/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamStatusLabel"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Continue 20261105 Command HUD Batch ===")
	root.size = Vector2i(1920, 1080)
	var scene: Node = SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(16):
		await process_frame
	var controller: Node = scene.get_node_or_null("TacticalController")
	var simulation: Node = scene.get_node_or_null("SimulationRoot")
	var go: Button = scene.get_node_or_null(GRID + "/GoCommandMatrixButton") as Button
	var compact_order: Label = scene.get_node_or_null("TacticalUI/A5TargetOrderPanel/Contents/Order") as Label
	var compact_feedback: Label = scene.get_node_or_null("TacticalUI/A5TargetOrderPanel/Contents/Feedback") as Label
	var details: PopupPanel = scene.get_node_or_null("TacticalUI/A5TeamDetailsPopup") as PopupPanel
	_check(controller != null and simulation != null and go != null and compact_order != null and compact_feedback != null and details != null, "Real mission fixture exposes command, simulation and A5 presentation owners")
	if controller == null or simulation == null or go == null or compact_order == null or compact_feedback == null or details == null:
		scene.queue_free()
		_finish()
		return
	var selected: PackedStringArray = PackedStringArray(controller.call("get_selected_fireteam_ids"))
	_check(not selected.is_empty(), "Real mission fixture has a normally initialized selected fireteam")
	if selected.is_empty():
		scene.queue_free()
		_finish()
		return
	var fireteam_id: String = selected[0]
	# Freeze only automatic scheduling of this UI/runtime owner. Its actual
	# _process method is called below; SimulationRoot still gets real physics ticks.
	controller.set_process(false)
	controller.call("_set_selected_fireteams", PackedStringArray([fireteam_id]), false)
	controller.call("_update_ui")
	_check(not bool(controller.get("preview_mode")) and bool(controller.call("_can_issue_local_commands")), "Fixture uses the existing authorized live-command path")
	_check(go.disabled, "GO is disabled before a plan is created")
	var publications: Array = []
	controller.connect("planning_state_changed", func(state: Dictionary) -> void:
		publications.append(state.duplicate(true))
	)
	var target_marker: Node2D = scene.get_node("TargetMarker") as Node2D
	var target: Vector2 = target_marker.global_position + Vector2(128.0, 0.0)
	var before: Dictionary = _guard(controller)
	var command_frame: int = Engine.get_process_frames()
	_check(bool(controller.call("issue_right_click_command_for_test", target, "move", false)), "Public Move accepts a real pending waypoint")
	var planned: Dictionary = _plan(controller, fireteam_id)
	_check(_has_waypoint(planned, "move", "pending"), "Move publishes its pending plan immediately")
	_check(publications.size() >= 1, "Move publishes planning-state feedback synchronously")
	_check(not go.disabled and _go_matches_owner(controller, go), "Move immediately enables GO according to the existing owner policy")
	_check(compact_order.text.contains("geplant") and compact_feedback.text == "Mit Plan ausführen starten", "Compact A5 immediately shows planned order and actionable GO feedback")
	_check(_heavy_calls(_guard(controller)) == _heavy_calls(before), "Move invokes no heavy runtime HUD surfaces synchronously")
	_check(_pending(controller), "Move leaves one command HUD refresh pending")
	_check(bool(controller.call("execute_selected_fireteam_orders")), "Public GO accepts the pending Move in the same frame")
	var active: Dictionary = _plan(controller, fireteam_id)
	_check(String(active.get("status", "")) == "active" and _has_waypoint(active, "move", "active"), "GO immediately activates the actual plan and waypoint")
	_check(_has_queued_move(simulation, controller, fireteam_id), "GO immediately enqueues real tokenized Move commands in SimulationRoot")
	_check(publications.size() >= 2 and Engine.get_process_frames() == command_frame, "Move and GO publish the latest plan within the same input frame")
	_check(_go_matches_owner(controller, go), "GO immediately preserves the existing active-order Continue policy")
	_check(compact_order.text.contains("Wird ausgeführt") and compact_feedback.text == "Ausführung läuft", "Compact A5 immediately shows the latest executing state after GO")
	var after_commands: Dictionary = _guard(controller)
	_check(_heavy_calls(after_commands) == _heavy_calls(before), "Move plus GO coalesces without synchronous heavy surface traversal")
	_check(_pending(controller), "The same-frame Move plus GO burst remains pending for one full refresh")

	# Let the queued command commit through the normal physics owner before
	# checking its read-only HUD representation. No actor state is patched.
	await physics_frame
	await process_frame
	var units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	_check(_all_units_have_move(units), "Real SimulationRoot physics commits the public GO commands")
	var before_flush: Dictionary = _guard(controller)
	controller.call("_process", float(CONTROLLER.CARD_REFRESH_INTERVAL_SECONDS) + 0.001)
	var flushed: Dictionary = _guard(controller)
	_check(_heavy_calls(flushed) == _heavy_calls(before_flush) + 1, "One actual owner process step flushes the coalesced HUD work exactly once")
	_check(int(flushed.get("craft_controls_apply_count", 0)) == int(before_flush.get("craft_controls_apply_count", 0)) + 1 and int(flushed.get("fireteam_card_group_apply_count", 0)) == int(before_flush.get("fireteam_card_group_apply_count", 0)) + 1, "The pending flush forces both craft and fireteam surface groups")
	_check(not _pending(controller), "The coalesced full refresh clears pending")
	_check(compact_order.text.contains("Wird ausgeführt") and compact_feedback.text == "Ausführung läuft", "The delayed full refresh retains the latest GO state")
	var status: Label = scene.get_node(TEAM_STATUS) as Label
	_check(not status.text.is_empty() and status.text == String(controller.call("_build_fireteam_status_text")) and int(flushed.get("selected_cards_apply_count", 0)) > int(before_flush.get("selected_cards_apply_count", 0)), "The flushed team status and member cards read the currently committed Move state")
	for _step in range(3):
		controller.call("_process", 0.2)
	var quiet: Dictionary = _guard(controller)
	_check(_heavy_calls(quiet) == _heavy_calls(flushed) and not _pending(controller), "Quiescent light process steps schedule no repeated command full refresh")
	controller.call("_process", float(CONTROLLER.RUNTIME_HUD_HEAVY_REFRESH_INTERVAL_SECONDS))
	var periodic: Dictionary = _guard(controller)
	_check(int(periodic.get("craft_controls_apply_count", 0)) == int(quiet.get("craft_controls_apply_count", 0)) and int(periodic.get("craft_controls_skip_count", 0)) == int(quiet.get("craft_controls_skip_count", 0)) + 1, "The ordinary periodic heavy pass uses its unchanged-state guard instead of forcing a rebuild")
	_check(not _pending(controller), "Quiescent periodic work does not restore command pending state")

	# Transport feedback can enter a guarded full pass before the cadence.
	_check(bool(controller.call("issue_right_click_command_for_test", target + Vector2(48.0, 0.0), "move", false)) and _pending(controller), "Interleaved transport case begins with pending command HUD work")
	var interleave_before: Dictionary = _guard(controller)
	controller.call("_update_ui", true, false)
	var interleave_after: Dictionary = _guard(controller)
	_check(not _pending(controller) and int(interleave_after.get("craft_controls_apply_count", 0)) == int(interleave_before.get("craft_controls_apply_count", 0)) + 1, "A guarded full transport pass consumes the command force request instead of losing it")
	controller.call("_process", float(CONTROLLER.CARD_REFRESH_INTERVAL_SECONDS) + 0.001)
	_check(int(_guard(controller).get("craft_controls_apply_count", 0)) == int(interleave_after.get("craft_controls_apply_count", 0)), "Cadence after an interleaved full pass does not force the same command twice")
	_test_details_are_current(scene, controller, simulation, fireteam_id, target + Vector2(64.0, 0.0))
	print("COMMAND_HUD_BATCH_FACTS " + JSON.stringify({"cadence_seconds": CONTROLLER.CARD_REFRESH_INTERVAL_SECONDS, "before": before, "after_commands": after_commands, "before_flush": before_flush, "flushed": flushed, "quiet": quiet, "periodic": periodic, "synthetic_owner_process": true, "actor_writes": false}))
	scene.queue_free()
	for _frame in range(2):
		await process_frame
	_finish()


func _test_details_are_current(scene: Node, controller: Node, simulation: Node, fireteam_id: String, target: Vector2) -> void:
	var details: PopupPanel = scene.get_node("TacticalUI/A5TeamDetailsPopup") as PopupPanel
	var button: Button = scene.get_node(TEAM + "/A5DetailsButton") as Button
	var text: Label = details.get_node("Margin/Box/Scroll/Text") as Label
	var feedback: Label = scene.get_node(FEEDBACK_SOURCE) as Label
	var status: Label = scene.get_node(TEAM_STATUS) as Label
	_check(bool(controller.call("issue_right_click_command_for_test", target, "move", false)) and _pending(controller), "Separate details case starts with a new pending command refresh")
	var plan_before: String = JSON.stringify(controller.call("get_order_plans_snapshot"))
	var queue_before: String = JSON.stringify(simulation.get("command_queue"))
	var before_open: Dictionary = _guard(controller)
	button.pressed.emit()
	var after_open: Dictionary = _guard(controller)
	_check(details.visible and not text.text.is_empty(), "The original Details callback opens the actual team popup")
	_check(_heavy_calls(after_open) == _heavy_calls(before_open) + 1 and not _pending(controller), "Opening details flushes pending full sources once before display")
	_check(not feedback.text.is_empty() and text.text.contains(feedback.text) and text.text.contains(status.text), "Newly opened details contain the complete current feedback and team status sources")
	_check(JSON.stringify(controller.call("get_order_plans_snapshot")) == plan_before and JSON.stringify(simulation.get("command_queue")) == queue_before, "Opening current details creates or changes no gameplay plan or command")
	var old_text: String = text.text
	var before_change: Dictionary = _guard(controller)
	_check(bool(controller.call("issue_right_click_command_for_test", target + Vector2(32.0, 0.0), "take", false)), "Public Take changes planning while details remain open")
	_check(_has_waypoint(_plan(controller, fireteam_id), "take", "pending"), "The open-details action retains a real pending Take waypoint")
	_check(_pending(controller) and _heavy_calls(_guard(controller)) == _heavy_calls(before_change), "Open details preserve command batching for subsequent input")
	_check(text.text != old_text and text.text.contains("WAYPOINT TAKE") and text.text.contains(feedback.text), "Already open details immediately replace stale command text with the latest Take feedback")
	details.hide()


func _guard(controller: Node) -> Dictionary:
	return Dictionary(controller.call("get_mission_hud_runtime_surface_guard_snapshot"))


func _heavy_calls(snapshot: Dictionary) -> int:
	# Every runtime-surface traversal takes exactly one craft apply/skip branch.
	return int(snapshot.get("craft_controls_apply_count", 0)) + int(snapshot.get("craft_controls_skip_count", 0))


func _pending(controller: Node) -> bool:
	# get() also lets original source execute the assertions and report RED.
	var pending: Variant = controller.get("_runtime_hud_command_refresh_pending")
	return pending is bool and pending


func _go_matches_owner(controller: Node, go: Button) -> bool:
	var expected_disabled: bool = bool(controller.get("preview_mode")) or not bool(controller.call("_can_issue_local_commands")) or not bool(controller.call("_has_selected_fireteam_orders_to_execute"))
	return go.disabled == expected_disabled


func _plan(controller: Node, fireteam_id: String) -> Dictionary:
	for entry in Array(controller.call("get_order_plans_snapshot")):
		var plan: Dictionary = Dictionary(entry)
		if String(plan.get("fireteam_id", "")) == fireteam_id:
			return plan
	return {}


func _has_waypoint(plan: Dictionary, command_type: String, status: String) -> bool:
	for entry in Array(plan.get("waypoints", [])):
		var waypoint: Dictionary = Dictionary(entry)
		if String(waypoint.get("command_type", "")) == command_type and String(waypoint.get("status", "")) == status:
			return true
	return false


func _has_queued_move(simulation: Node, controller: Node, fireteam_id: String) -> bool:
	var ids: PackedStringArray = PackedStringArray()
	for unit in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		ids.append(String(unit.call("get_unit_id")))
	for entry in Array(simulation.get("command_queue")):
		var command: Dictionary = Dictionary(entry)
		if ids.has(String(command.get("unit_id", ""))) and String(command.get("command_type", "")) == "move_to_position" and String(command.get("source_command_type", "")) == "move" and not String(command.get("command_token", "")).is_empty():
			return true
	return false


func _all_units_have_move(units: Array) -> bool:
	if units.is_empty():
		return false
	for unit in units:
		var command = unit.call("get_current_unit_command")
		if command == null or String(command.get("source_command_type")) != "move":
			return false
	return true


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: " + label)
	else:
		_failed += 1
		push_error("FAIL: " + label)


func _finish() -> void:
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	print("COMMAND_HUD_BATCH_ALL_PASS" if _failed == 0 else "COMMAND_HUD_BATCH_FAILED")
	quit(0 if _failed == 0 else 1)
