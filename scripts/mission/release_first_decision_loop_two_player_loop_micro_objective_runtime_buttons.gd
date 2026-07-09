class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveRuntimeButtons
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons.v1"
const TASK_ID: String = "TASK_993"
const SOURCE_TASK_ID: String = "TASK_992"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_choice_hook.v1"
const HUD_WIRING_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.v1"
const NEXT_TASK: String = "TASK_994 - Release First Decision Loop Two Player Loop Micro Objective Confirm Smoke"
const REVIEW_TASK: String = "TASK_993 - Release First Decision Loop Two Player Loop Micro Objective Runtime Buttons"
const PRESS_ACTION: String = "confirm_release_first_decision_loop_two_player_loop_micro_objective_button"
const EXECUTE_ACTION: String = "execute_selected_fireteam_orders"
const COMMAND_GRID_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"
const BUTTON_SLOT_NAMES: Array[String] = ["CommandSlot08", "CommandSlot09", "CommandSlot10"]


static func build_snapshot(source_choice_hook: Dictionary, source_hud_wiring: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_choice_hook, source_hud_wiring)
	var active: bool = blockers.is_empty()
	var specs: Array = _build_button_specs(Array(source_hud_wiring.get("hud_micro_objective_chips", []))) if active else []
	var runtime_line: String = _build_runtime_line(specs) if active else ""
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_choice_hook.get("schema", "")),
		"source_status": String(source_choice_hook.get("status", "")),
		"source_gate": String(source_choice_hook.get("gate", "")),
		"source_active": bool(source_choice_hook.get("active", false)),
		"active": active,
		"status": "micro_objective_runtime_buttons_ready" if active else "blocked",
		"gate": "micro_objective_runtime_buttons_ready" if active else "micro_objective_runtime_buttons_blocked",
		"micro_objective_button_specs": specs,
		"micro_objective_button_count": specs.size(),
		"runtime_buttons_line": runtime_line,
		"press_action": "confirm_release_first_decision_loop_two_player_loop_micro_objective_button",
		"execute_action": EXECUTE_ACTION,
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"recommended_next_task": NEXT_TASK if active else REVIEW_TASK,
		"recommended_direction": "run_micro_objective_confirm_smoke" if active else "complete_micro_objective_choice_hook_source",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


static func _build_blockers(source_choice_hook: Dictionary, source_hud_wiring: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_choice_hook.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_992-Source-Schema fehlt oder passt nicht."))
	if String(source_choice_hook.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_992."))
	if not bool(source_choice_hook.get("active", false)) or String(source_choice_hook.get("gate", "")) != "micro_objective_choice_hook_ready":
		blockers.append(_issue("source_not_ready", "TASK_992-Micro-Objective-Choice-Hook ist nicht bereit."))
	if String(source_hud_wiring.get("schema", "")) != HUD_WIRING_SCHEMA:
		blockers.append(_issue("hud_wiring_schema_mismatch", "TASK_991-HUD-Wiring-Source fehlt oder passt nicht."))
	if int(source_hud_wiring.get("hud_micro_objective_chip_count", 0)) < 3:
		blockers.append(_issue("hud_micro_objective_chips_missing", "TASK_991 liefert nicht alle Micro-Objective-Chips."))
	if not _snapshot_is_read_only(source_choice_hook) or not _snapshot_is_read_only(source_hud_wiring):
		blockers.append(_issue("source_not_read_only", "TASK_992/TASK_991-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_button_specs(chips: Array) -> Array:
	var specs: Array = []
	var max_count: int = mini(chips.size(), BUTTON_SLOT_NAMES.size())
	for i in range(max_count):
		var chip := Dictionary(chips[i])
		var objective_id: String = String(chip.get("objective_id", ""))
		var label: String = String(chip.get("label", "")).strip_edges()
		if label.is_empty():
			label = objective_id.to_upper()
		var command_type: String = String(chip.get("command_intent", "move"))
		specs.append({
			"micro_objective_id": objective_id,
			"button_text": label,
			"button_label": String(chip.get("player_line", label)),
			"slot_name": BUTTON_SLOT_NAMES[i],
			"slot_path": "%s/%s" % [COMMAND_GRID_PATH, BUTTON_SLOT_NAMES[i]],
			"tooltip": "%s: %s vorbereiten, danach GO separat." % [label, command_type.capitalize()],
			"command_type": command_type,
			"why_line": String(chip.get("why_line", "")),
			"press_action": "confirm_release_first_decision_loop_two_player_loop_micro_objective_button",
			"execute_action": EXECUTE_ACTION,
			"button_enabled": true,
			"separate_go_required": true,
			"auto_confirms": false,
			"auto_executes_go": false,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_movement": false,
			"sets_multiplayer_truth": false,
		})
	return specs


static func _build_runtime_line(specs: Array) -> String:
	var labels: PackedStringArray = PackedStringArray()
	for spec_variant in specs:
		var label: String = String(Dictionary(spec_variant).get("button_text", "")).strip_edges()
		if not label.is_empty():
			labels.append(label)
	return "MICRO OBJ BUTTONS %s | GO separat" % " / ".join(labels)


static func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_movement", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false))


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
