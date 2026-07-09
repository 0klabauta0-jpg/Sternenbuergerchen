class_name ReleaseFirstDecisionLoopTwoPlayerLoopRuntimeChoiceButtons
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_runtime_choice_buttons.v1"
const TASK_ID: String = "TASK_979"
const SOURCE_TASK_ID: String = "TASK_978"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_choice_hook.v1"
const HUD_WIRING_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_hud_wiring.v1"
const NEXT_TASK: String = "TASK_980 - Release First Decision Loop Two Player Loop Choice Confirm Smoke"
const REVIEW_TASK: String = "TASK_979 - Release First Decision Loop Two Player Loop Runtime Choice Buttons"
const PRESS_ACTION: String = "confirm_release_first_decision_loop_two_player_loop_choice_button"
const EXECUTE_ACTION: String = "execute_selected_fireteam_orders"
const COMMAND_GRID_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"
const BUTTON_SLOT_NAMES: Array[String] = ["CommandSlot08", "CommandSlot09", "CommandSlot10", "CommandSlot11"]


static func build_snapshot(source_choice_hook: Dictionary, source_hud_wiring: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_choice_hook, source_hud_wiring)
	var active: bool = blockers.is_empty()
	var specs: Array = _build_button_specs(Array(source_hud_wiring.get("hud_choice_chips", []))) if active else []
	var runtime_line: String = _build_runtime_line(specs) if active else ""
	var status: String = "runtime_choice_buttons_ready" if active else "blocked"
	var gate: String = "runtime_choice_buttons_ready" if active else "runtime_choice_buttons_blocked"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_choice_hook.get("schema", "")),
		"source_status": String(source_choice_hook.get("status", "")),
		"source_gate": String(source_choice_hook.get("gate", "")),
		"source_active": bool(source_choice_hook.get("active", false)),
		"active": active,
		"status": status,
		"gate": gate,
		"button_specs": specs,
		"button_count": specs.size(),
		"runtime_buttons_line": runtime_line,
		"press_action": "confirm_release_first_decision_loop_two_player_loop_choice_button",
		"execute_action": EXECUTE_ACTION,
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"recommended_next_task": NEXT_TASK if active else REVIEW_TASK,
		"recommended_direction": "run_choice_confirm_smoke" if active else "complete_choice_hook_source",
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
		blockers.append(_issue("source_schema_mismatch", "TASK_978-Source-Schema fehlt oder passt nicht."))
	if String(source_choice_hook.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_978."))
	if not bool(source_choice_hook.get("active", false)) or String(source_choice_hook.get("gate", "")) != "choice_hook_ready":
		blockers.append(_issue("source_not_ready", "TASK_978-Choice-Hook ist nicht bereit."))
	if String(source_hud_wiring.get("schema", "")) != HUD_WIRING_SCHEMA:
		blockers.append(_issue("hud_wiring_schema_mismatch", "TASK_977-HUD-Wiring-Source fehlt oder passt nicht."))
	if int(source_hud_wiring.get("hud_choice_chip_count", 0)) < 4:
		blockers.append(_issue("hud_choice_chips_missing", "TASK_977 liefert nicht alle Choice-Chips."))
	if not _snapshot_is_read_only(source_choice_hook) or not _snapshot_is_read_only(source_hud_wiring):
		blockers.append(_issue("source_not_read_only", "TASK_978/TASK_977-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_button_specs(choice_chips: Array) -> Array:
	var specs: Array = []
	var max_count: int = mini(choice_chips.size(), BUTTON_SLOT_NAMES.size())
	for i in range(max_count):
		var chip := Dictionary(choice_chips[i])
		var choice_id: String = String(chip.get("choice_id", ""))
		var token: String = String(chip.get("token", "")).strip_edges()
		if token.is_empty():
			token = choice_id.to_upper()
		var command_type: String = _command_type_for_choice_id(choice_id)
		specs.append({
			"choice_id": choice_id,
			"button_text": token,
			"button_label": String(chip.get("label", token)),
			"slot_name": BUTTON_SLOT_NAMES[i],
			"slot_path": "%s/%s" % [COMMAND_GRID_PATH, BUTTON_SLOT_NAMES[i]],
			"tooltip": "%s: %s vorbereiten, danach GO separat." % [token, command_type.capitalize()],
			"command_type": command_type,
			"command_hint": String(chip.get("command_hint", "")),
			"press_action": "confirm_release_first_decision_loop_two_player_loop_choice_button",
			"execute_action": EXECUTE_ACTION,
			"button_enabled": true,
			"separate_go_required": true,
			"auto_confirms": false,
			"auto_executes_go": false,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_movement": false,
		})
	return specs


static func _command_type_for_choice_id(choice_id: String) -> String:
	match choice_id:
		"secure_area":
			return "defend"
		"push_objective":
			return "move"
		"flank_pressure":
			return "flank"
		"reset_spacing":
			return "move"
		_:
			return "move"


static func _build_runtime_line(specs: Array) -> String:
	var tokens: PackedStringArray = PackedStringArray()
	for spec_variant in specs:
		var token: String = String(Dictionary(spec_variant).get("button_text", "")).strip_edges()
		if not token.is_empty():
			tokens.append(token)
	return "CHOICE BUTTONS %s | GO separat" % " / ".join(tokens)


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
