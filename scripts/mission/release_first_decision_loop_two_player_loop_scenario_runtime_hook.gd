class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioRuntimeHook
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_runtime_hook.v1"
const TASK_ID: String = "TASK_1013"
const SOURCE_TASK_ID: String = "TASK_1012"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_stitch.v1"
const REVIEW_TASK: String = "TASK_1013 - Release First Decision Loop Two Player Loop Scenario Runtime Hook"
const STITCH_TASK: String = "TASK_1012 - Release First Decision Loop Two Player Loop Scenario Stitch"
const NEXT_TASK: String = "TASK_1014 - Release First Decision Loop Two Player Loop Scenario Runtime Smoke"


static func build_snapshot(source_stitch: Dictionary, runtime_context: Dictionary = {}) -> Dictionary:
	var source_blockers: Array = _build_source_blockers(source_stitch)
	var runtime_steps: Array = _build_runtime_steps(Array(source_stitch.get("scenario_beats", [])))
	var runtime_choices: Array = _build_runtime_choices(source_stitch)
	var resolved_step_id: String = _resolve_current_step_id(runtime_steps, runtime_context)
	var selected_role_id: String = _resolve_role_id(Array(source_stitch.get("two_player_roles", [])), runtime_context)
	var selected_choice_id: String = _resolve_choice_id(runtime_choices, runtime_context)
	var selected_step: Dictionary = _find_by_id(runtime_steps, "step_id", resolved_step_id)
	var selected_role: Dictionary = _find_by_id(Array(source_stitch.get("two_player_roles", [])), "role_id", selected_role_id)
	var selected_choice: Dictionary = _find_by_id(runtime_choices, "choice_id", selected_choice_id)
	var runtime_blockers: Array = []
	if source_blockers.is_empty():
		runtime_blockers = _build_runtime_blockers(selected_step, selected_role, selected_choice, runtime_context)

	var blockers: Array = source_blockers + runtime_blockers
	var active: bool = blockers.is_empty()
	var status: String = "runtime_hook_ready" if active else "needs_runtime_hook_review"
	var gate: String = "runtime_hook_ready" if active else "runtime_hook_review"
	if _source_identity_blocked(source_stitch):
		status = "blocked"
		gate = "blocked"

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_stitch.get("schema", "")),
		"source_status": String(source_stitch.get("status", "")),
		"source_gate": String(source_stitch.get("gate", "")),
		"source_scenario_id": String(source_stitch.get("scenario_id", "")),
		"source_scenario_title": String(source_stitch.get("scenario_title", "")),
		"active": active,
		"runtime_hook_ready": active,
		"status": status,
		"gate": gate,
		"scenario_runtime_steps": runtime_steps,
		"scenario_runtime_step_count": runtime_steps.size(),
		"current_step_id": resolved_step_id if active or selected_step.is_empty() else String(selected_step.get("step_id", "")),
		"current_step": selected_step,
		"selected_role_id": selected_role_id,
		"selected_role": selected_role,
		"runtime_choices": runtime_choices,
		"selected_runtime_choice_id": selected_choice_id,
		"selected_runtime_choice": selected_choice,
		"mission_control_runtime_line": _build_mission_control_line(source_stitch, selected_step, selected_choice, active),
		"selected_fireteam_runtime_line": _build_selected_fireteam_line(selected_role, selected_step, active),
		"command_matrix_runtime_hooks": _build_command_matrix_hooks(selected_choice, active),
		"requires_existing_go_path": true,
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"recommended_next_task": NEXT_TASK if active else (STITCH_TASK if not source_blockers.is_empty() else REVIEW_TASK),
		"recommended_direction": "run_scenario_runtime_smoke" if active else "fix_scenario_runtime_hook",
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


static func _build_source_blockers(source_stitch: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_stitch.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1012-Source-Schema fehlt oder passt nicht."))
	if String(source_stitch.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1012."))
	if String(source_stitch.get("status", "")) != "scenario_stitch_ready" or not bool(source_stitch.get("scenario_stitch_ready", false)):
		blockers.append(_issue("source_not_ready", "TASK_1012-Szenario-Stitch ist nicht bereit."))
	if Array(source_stitch.get("scenario_beats", [])).size() < 5:
		blockers.append(_issue("source_beats_missing", "TASK_1012 liefert zu wenige Szenario-Beats."))
	if Array(source_stitch.get("two_player_roles", [])).size() != 2:
		blockers.append(_issue("source_roles_missing", "TASK_1012 liefert nicht genau zwei Spielerrollen."))
	if String(source_stitch.get("mission_objective_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_objective_missing", "TASK_1012-Mission-Objective fehlt."))
	if not _snapshot_is_read_only(source_stitch):
		blockers.append(_issue("source_not_read_only", "TASK_1012-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_runtime_blockers(selected_step: Dictionary, selected_role: Dictionary, selected_choice: Dictionary, runtime_context: Dictionary) -> Array:
	var blockers: Array = []
	if selected_step.is_empty():
		blockers.append(_issue("current_step_missing", "Ausgewaehlter Runtime-Schritt fehlt: %s." % String(runtime_context.get("current_step_id", ""))))
	if selected_role.is_empty():
		blockers.append(_issue("selected_role_missing", "Ausgewaehlte Spielerrolle fehlt."))
	if selected_choice.is_empty():
		blockers.append(_issue("selected_runtime_choice_missing", "Ausgewaehlte Runtime-Choice fehlt: %s." % String(runtime_context.get("selected_runtime_choice_id", ""))))
	if bool(runtime_context.get("ui_sets_gameplay_truth", false)):
		blockers.append(_issue("context_sets_gameplay_truth", "Runtime-Kontext darf keine Gameplay-Wahrheit setzen."))
	if bool(runtime_context.get("creates_command", false)):
		blockers.append(_issue("context_creates_command", "Runtime-Kontext darf keinen Command erzeugen."))
	if bool(runtime_context.get("auto_executes_go", false)):
		blockers.append(_issue("context_auto_executes_go", "Runtime-Kontext darf GO nicht automatisch ausfuehren."))
	return blockers


static func _build_runtime_steps(beats: Array) -> Array:
	var steps: Array = []
	var index: int = 0
	for beat_variant in beats:
		if typeof(beat_variant) != TYPE_DICTIONARY:
			continue
		var beat: Dictionary = Dictionary(beat_variant)
		var step_id: String = String(beat.get("beat_id", "")).strip_edges()
		if step_id.is_empty():
			step_id = "step_%d" % index
		steps.append({
			"step_id": step_id,
			"index": index,
			"label": _label_for_step(step_id),
			"text": String(beat.get("text", "")),
			"runtime_state": "pending" if index > 0 else "active",
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
		index += 1
	return steps


static func _build_runtime_choices(source_stitch: Dictionary) -> Array:
	var objective: String = String(source_stitch.get("mission_objective_line", "Relais sichern"))
	return [
		{
			"choice_id": "secure_relay",
			"label": "SICHERN",
			"command_type": "defend",
			"objective_line": objective,
			"requires_confirm": true,
			"requires_go": true,
			"read_only": true,
		},
		{
			"choice_id": "press_contact",
			"label": "DRUECKEN",
			"command_type": "move",
			"objective_line": objective,
			"requires_confirm": true,
			"requires_go": true,
			"read_only": true,
		},
		{
			"choice_id": "regroup_fireteam",
			"label": "SAMMELN",
			"command_type": "move",
			"objective_line": objective,
			"requires_confirm": true,
			"requires_go": true,
			"read_only": true,
		},
	]


static func _resolve_current_step_id(steps: Array, context: Dictionary) -> String:
	var requested: String = String(context.get("current_step_id", "")).strip_edges()
	if not requested.is_empty():
		return requested
	if steps.is_empty():
		return ""
	return String(Dictionary(steps[0]).get("step_id", ""))


static func _resolve_role_id(roles: Array, context: Dictionary) -> String:
	var requested: String = String(context.get("selected_role_id", "")).strip_edges()
	if not requested.is_empty():
		return requested
	if roles.is_empty():
		return ""
	return String(Dictionary(roles[0]).get("role_id", ""))


static func _resolve_choice_id(choices: Array, context: Dictionary) -> String:
	var requested: String = String(context.get("selected_runtime_choice_id", "")).strip_edges()
	if not requested.is_empty():
		return requested
	if choices.is_empty():
		return ""
	return String(Dictionary(choices[0]).get("choice_id", ""))


static func _find_by_id(entries: Array, key: String, value: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get(key, "")) == value:
			return entry.duplicate(true)
	return {}


static func _build_mission_control_line(source_stitch: Dictionary, selected_step: Dictionary, selected_choice: Dictionary, active: bool) -> String:
	var title: String = String(source_stitch.get("scenario_title", "FOB Relay Probe"))
	var objective: String = String(source_stitch.get("mission_objective_line", "Relais sichern"))
	var step_label: String = String(selected_step.get("label", "CHECK"))
	var choice_label: String = String(selected_choice.get("label", "NEXT"))
	var state: String = "READY" if active else "CHECK"
	return "FOB %s | %s | %s -> NEXT %s | GO separat" % [title, step_label, objective, choice_label] if state == "READY" else "FOB %s | Runtime Hook pruefen | NEXT offen | GO separat" % title


static func _build_selected_fireteam_line(selected_role: Dictionary, selected_step: Dictionary, active: bool) -> String:
	var role_text: String = String(selected_role.get("text", "Alpha liest NEXT"))
	var role_name: String = "Bravo" if String(selected_role.get("role_id", "")).contains("bravo") else "Alpha"
	var step_label: String = String(selected_step.get("label", "CHECK"))
	return "%s | %s | %s | Confirm vor GO" % [role_name, step_label, role_text] if active else "%s | Runtime Hook pruefen | Confirm vor GO" % role_name


static func _build_command_matrix_hooks(selected_choice: Dictionary, active: bool) -> Array:
	var choice_id: String = String(selected_choice.get("choice_id", ""))
	var choice_label: String = String(selected_choice.get("label", ""))
	return [
		{
			"hook_id": "next",
			"label": "NEXT",
			"action": "select_next_scenario_step",
			"enabled": active,
			"read_only": true,
		},
		{
			"hook_id": "confirm",
			"label": "CONFIRM",
			"action": "_issue_command",
			"choice_id": choice_id,
			"choice_label": choice_label,
			"enabled": active,
			"creates_command": false,
			"read_only": true,
		},
		{
			"hook_id": "go",
			"label": "GO",
			"action": "execute_selected_fireteam_orders",
			"enabled": active,
			"auto_executes": false,
			"read_only": true,
		},
	]


static func _label_for_step(step_id: String) -> String:
	match step_id:
		"entry":
			return "ENTRY"
		"first_contact":
			return "CONTACT"
		"decision":
			return "DECIDE"
		"feedback":
			return "FEEDBACK"
		"exit":
			return "EXIT"
		_:
			return step_id.to_upper()


static func _source_identity_blocked(source_stitch: Dictionary) -> bool:
	return String(source_stitch.get("schema", "")) != SOURCE_SCHEMA or String(source_stitch.get("task_id", "")) != SOURCE_TASK_ID


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
