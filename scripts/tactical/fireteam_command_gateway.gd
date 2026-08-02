class_name FireteamCommandGateway
extends RefCounted

const COMMANDER_ORDER_INTENT_SCRIPT: GDScript = preload("res://scripts/mission/commander_order_intent.gd")
const COMMAND_SUBMISSION_RESULT_SCRIPT: GDScript = preload("res://scripts/mission/command_submission_result.gd")

var _simulation_root = null
var _planned_intents_by_id: Dictionary = {}
var _submission_results_by_plan_id: Dictionary = {}
var _expected_tokens_by_plan_id: Dictionary = {}
var _committed_tokens_by_plan_id: Dictionary = {}
var _plan_sequence: int = 0
var _next_planned_revision_by_peer_fireteam: Dictionary = {}
var _plan_namespace_by_peer: Dictionary = {}

static var _gateway_instance_sequence: int = 0


func configure(simulation_root) -> void:
	if _simulation_root != null and _simulation_root.has_signal("commander_intent_committed"):
		var previous_commit_callable := Callable(self, "_on_commander_intent_committed")
		if _simulation_root.is_connected("commander_intent_committed", previous_commit_callable):
			_simulation_root.disconnect("commander_intent_committed", previous_commit_callable)
	if _simulation_root != null and _simulation_root.has_signal("commander_intent_commit_received"):
		var previous_remote_commit_callable := Callable(self, "_on_commander_intent_committed")
		if _simulation_root.is_connected("commander_intent_commit_received", previous_remote_commit_callable):
			_simulation_root.disconnect("commander_intent_commit_received", previous_remote_commit_callable)
	_simulation_root = simulation_root
	if _simulation_root != null and _simulation_root.has_signal("commander_intent_committed"):
		var commit_callable := Callable(self, "_on_commander_intent_committed")
		if not _simulation_root.is_connected("commander_intent_committed", commit_callable):
			_simulation_root.connect("commander_intent_committed", commit_callable)
	if _simulation_root != null and _simulation_root.has_signal("commander_intent_commit_received"):
		var remote_commit_callable := Callable(self, "_on_commander_intent_committed")
		if not _simulation_root.is_connected("commander_intent_commit_received", remote_commit_callable):
			_simulation_root.connect("commander_intent_commit_received", remote_commit_callable)


func plan_intent(intent) -> RefCounted:
	if intent == null or not intent.has_method("to_dict"):
		return COMMAND_SUBMISSION_RESULT_SCRIPT.call("rejected", "", "invalid_commander_order_intent")
	var normalized = COMMANDER_ORDER_INTENT_SCRIPT.call("from_dict", Dictionary(intent.call("to_dict")))
	_plan_sequence += 1
	if String(normalized.plan_id).is_empty():
		normalized.plan_id = _build_peer_scoped_plan_id(int(normalized.source_peer_id))
	normalized.plan_revision = _resolve_authority_revision(normalized)
	if not bool(normalized.call("is_valid")):
		return COMMAND_SUBMISSION_RESULT_SCRIPT.call("rejected", String(normalized.plan_id), "invalid_commander_order_intent")
	_planned_intents_by_id[String(normalized.plan_id)] = Dictionary(normalized.call("to_dict")).duplicate(true)
	var planned_commands: Array = _build_fireteam_commands(normalized)
	var planned_fireteam_ids := PackedStringArray()
	var expected_command_tokens := PackedStringArray()
	for command_variant in planned_commands:
		var command: Dictionary = Dictionary(command_variant)
		var fireteam_id := String(command.get("fireteam_id", "")).strip_edges().to_lower()
		var command_token := String(command.get("command_token", "")).strip_edges()
		if not fireteam_id.is_empty():
			planned_fireteam_ids.append(fireteam_id)
		if not command_token.is_empty():
			expected_command_tokens.append(command_token)
	return COMMAND_SUBMISSION_RESULT_SCRIPT.call("from_dict", {
		"accepted": true,
		"plan_id": String(normalized.plan_id),
		"command_token": String(expected_command_tokens[0]) if not expected_command_tokens.is_empty() else "",
		"pending": false,
		"committed": false,
		"planned_fireteam_ids": planned_fireteam_ids,
		"expected_command_tokens": expected_command_tokens,
	})


func get_planned_intent(plan_id: String):
	var normalized_plan_id: String = plan_id.strip_edges()
	if normalized_plan_id.is_empty() or not _planned_intents_by_id.has(normalized_plan_id):
		return null
	return COMMANDER_ORDER_INTENT_SCRIPT.call("from_dict", Dictionary(_planned_intents_by_id[normalized_plan_id]).duplicate(true))


func submit_go(plan_id: String) -> RefCounted:
	var normalized_plan_id: String = plan_id.strip_edges()
	if normalized_plan_id.is_empty() or not _planned_intents_by_id.has(normalized_plan_id):
		return COMMAND_SUBMISSION_RESULT_SCRIPT.call("rejected", normalized_plan_id, "unknown_plan")
	if _submission_results_by_plan_id.has(normalized_plan_id):
		return COMMAND_SUBMISSION_RESULT_SCRIPT.call("rejected", normalized_plan_id, "plan_already_submitted")
	if _simulation_root == null or not _simulation_root.has_method("submit_commander_order_intent_for_peer"):
		return COMMAND_SUBMISSION_RESULT_SCRIPT.call("rejected", normalized_plan_id, "simulation_root_unavailable")

	var intent = get_planned_intent(normalized_plan_id)
	if intent == null or not bool(intent.call("is_valid")):
		return COMMAND_SUBMISSION_RESULT_SCRIPT.call("rejected", normalized_plan_id, "invalid_commander_order_intent")
	var commands: Array = _build_fireteam_commands(intent)
	if commands.is_empty():
		return COMMAND_SUBMISSION_RESULT_SCRIPT.call("rejected", normalized_plan_id, "commander_order_has_no_fireteams")

	var fireteam_results: Array = []
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant).duplicate(true)
		if _simulation_root.has_method("preflight_commander_order_intent_for_peer"):
			var preflight: Dictionary = Dictionary(_simulation_root.call("preflight_commander_order_intent_for_peer", command, int(intent.source_peer_id)))
			if not bool(preflight.get("accepted", false)):
				fireteam_results.append(_fireteam_result(command, false, false, false, String(preflight.get("reason", "commander_order_rejected"))))
				return COMMAND_SUBMISSION_RESULT_SCRIPT.call("rejected", normalized_plan_id, String(preflight.get("reason", "commander_order_rejected")), String(command.get("command_token", "")), fireteam_results)

	var expected_tokens: PackedStringArray = PackedStringArray()
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant).duplicate(true)
		var submission: Dictionary = Dictionary(_simulation_root.call("submit_commander_order_intent_for_peer", command, int(intent.source_peer_id)))
		var command_token: String = String(command.get("command_token", "")).strip_edges()
		if not bool(submission.get("accepted", false)):
			fireteam_results.append(_fireteam_result(command, false, false, false, String(submission.get("reason", "commander_order_rejected"))))
			return COMMAND_SUBMISSION_RESULT_SCRIPT.call("rejected", normalized_plan_id, String(submission.get("reason", "commander_order_rejected")), command_token, fireteam_results)
		expected_tokens.append(command_token)
		fireteam_results.append(_fireteam_result(command, true, true, false, ""))

	var result = COMMAND_SUBMISSION_RESULT_SCRIPT.call("accepted_pending", normalized_plan_id, String(expected_tokens[0]) if not expected_tokens.is_empty() else "", fireteam_results)
	_submission_results_by_plan_id[normalized_plan_id] = Dictionary(result.call("to_dict")).duplicate(true)
	_expected_tokens_by_plan_id[normalized_plan_id] = PackedStringArray(expected_tokens)
	_committed_tokens_by_plan_id[normalized_plan_id] = {}
	return result


func get_submission_result(plan_id: String) -> RefCounted:
	var normalized_plan_id: String = plan_id.strip_edges()
	if normalized_plan_id.is_empty() or not _submission_results_by_plan_id.has(normalized_plan_id):
		return COMMAND_SUBMISSION_RESULT_SCRIPT.call("rejected", normalized_plan_id, "submission_not_found")
	return COMMAND_SUBMISSION_RESULT_SCRIPT.call("from_dict", Dictionary(_submission_results_by_plan_id[normalized_plan_id]).duplicate(true))


func resolve_network_result(result: Dictionary) -> void:
	var plan_id: String = String(result.get("plan_id", "")).strip_edges()
	if plan_id.is_empty() or not _submission_results_by_plan_id.has(plan_id):
		return
	if bool(result.get("accepted", false)):
		if bool(result.get("committed", false)):
			_mark_command_token_committed(plan_id, String(result.get("command_token", "")).strip_edges())
		return
	var current: Dictionary = Dictionary(_submission_results_by_plan_id[plan_id]).duplicate(true)
	var token: String = String(result.get("command_token", "")).strip_edges()
	var fireteam_results: Array = Array(current.get("fireteam_results", [])).duplicate(true)
	for index in range(fireteam_results.size()):
		var fireteam_result: Dictionary = Dictionary(fireteam_results[index]).duplicate(true)
		if token.is_empty() or String(fireteam_result.get("command_token", "")).strip_edges() == token:
			fireteam_result["accepted"] = false
			fireteam_result["pending"] = false
			fireteam_result["committed"] = false
			fireteam_result["reason"] = String(result.get("reason", "commander_order_rejected")).strip_edges()
			fireteam_results[index] = fireteam_result
	current["accepted"] = false
	current["pending"] = false
	current["committed"] = false
	current["reason"] = String(result.get("reason", "commander_order_rejected")).strip_edges()
	current["fireteam_results"] = fireteam_results
	_submission_results_by_plan_id[plan_id] = current


func _build_fireteam_commands(intent) -> Array:
	var commands: Array = []
	for fireteam_variant in PackedStringArray(intent.selected_fireteam_ids):
		var fireteam_id: String = String(fireteam_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		var command_token: String = "n003:%s:p%d:%s" % [String(intent.plan_id), int(intent.source_peer_id), fireteam_id]
		var metadata: Dictionary = Dictionary(intent.metadata).duplicate(true)
		metadata["n003_plan_id"] = String(intent.plan_id)
		metadata["n003_entry_source"] = String(intent.entry_source)
		commands.append({
			"contract_category": "commander_intent",
			"source_context": "mission_n003_fireteam_go",
			"command_id": "%s:%s" % [String(intent.plan_id), fireteam_id],
			"command_token": command_token,
			"plan_id": String(intent.plan_id),
			"plan_revision": int(intent.plan_revision),
			"verb": String(intent.command_type),
			"command_type": String(intent.command_type),
			"fireteam_id": fireteam_id,
			"selected_fireteam_ids": PackedStringArray(intent.selected_fireteam_ids),
			"coordinated_fireteam_ids": PackedStringArray(intent.selected_fireteam_ids),
			"team_id": String(intent.team_id),
			"target_position": intent.target_position,
			"target_area_id": String(intent.target_area_id),
			"phase": int(intent.phase),
			"source_peer_id": int(intent.source_peer_id),
			"entry_source": String(intent.entry_source),
			"metadata": metadata,
		})
	return commands


func _fireteam_result(command: Dictionary, accepted: bool, pending: bool, committed: bool, reason: String) -> Dictionary:
	return {
		"fireteam_id": String(command.get("fireteam_id", "")).strip_edges().to_lower(),
		"command_token": String(command.get("command_token", "")).strip_edges(),
		"accepted": accepted,
		"pending": pending,
		"committed": committed,
		"reason": reason.strip_edges(),
	}


func _on_commander_intent_committed(command: Dictionary) -> void:
	if String(command.get("source_context", "")).strip_edges() != "mission_n003_fireteam_go":
		return
	var plan_id: String = String(command.get("plan_id", "")).strip_edges()
	var command_token: String = String(command.get("command_token", "")).strip_edges()
	if plan_id.is_empty() or command_token.is_empty() or not _submission_results_by_plan_id.has(plan_id):
		return
	_mark_command_token_committed(plan_id, command_token)


func _mark_command_token_committed(plan_id: String, command_token: String) -> void:
	if plan_id.is_empty() or command_token.is_empty() or not _submission_results_by_plan_id.has(plan_id):
		return
	var expected_tokens: PackedStringArray = PackedStringArray(_expected_tokens_by_plan_id.get(plan_id, PackedStringArray()))
	if not expected_tokens.has(command_token):
		return
	var committed_tokens: Dictionary = Dictionary(_committed_tokens_by_plan_id.get(plan_id, {}))
	committed_tokens[command_token] = true
	_committed_tokens_by_plan_id[plan_id] = committed_tokens
	var current: Dictionary = Dictionary(_submission_results_by_plan_id[plan_id]).duplicate(true)
	var fireteam_results: Array = Array(current.get("fireteam_results", [])).duplicate(true)
	for index in range(fireteam_results.size()):
		var fireteam_result: Dictionary = Dictionary(fireteam_results[index]).duplicate(true)
		if String(fireteam_result.get("command_token", "")).strip_edges() == command_token:
			fireteam_result["pending"] = false
			fireteam_result["committed"] = true
			fireteam_results[index] = fireteam_result
	var all_committed: bool = true
	for expected_token in expected_tokens:
		if not committed_tokens.has(String(expected_token)):
			all_committed = false
			break
	current["pending"] = not all_committed
	current["committed"] = all_committed
	current["fireteam_results"] = fireteam_results
	_submission_results_by_plan_id[plan_id] = current


func _build_peer_scoped_plan_id(source_peer_id: int) -> String:
	var peer_id: int = source_peer_id if source_peer_id > 0 else 1
	var plan_namespace: String = String(_plan_namespace_by_peer.get(peer_id, "")).strip_edges()
	if plan_namespace.is_empty():
		_gateway_instance_sequence += 1
		var wall_clock_msec: int = maxi(int(Time.get_unix_time_from_system() * 1000.0), 1)
		plan_namespace = "p%d_s%d_i%d" % [peer_id, wall_clock_msec, _gateway_instance_sequence]
		_plan_namespace_by_peer[peer_id] = plan_namespace
	return "n003_%s_plan_%d" % [plan_namespace, _plan_sequence]


func _resolve_authority_revision(intent) -> int:
	var source_peer_id: int = int(intent.source_peer_id) if int(intent.source_peer_id) > 0 else 1
	var requested_revision: int = maxi(int(intent.plan_revision), 0)
	var next_revision: int = 1
	for fireteam_variant in PackedStringArray(intent.selected_fireteam_ids):
		var fireteam_id: String = String(fireteam_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		var revision_key: String = "%d:%s" % [source_peer_id, fireteam_id]
		var authority_next: int = 1
		if _simulation_root != null and _simulation_root.has_method("get_next_commander_order_revision_for_peer_fireteam"):
			authority_next = maxi(int(_simulation_root.call("get_next_commander_order_revision_for_peer_fireteam", source_peer_id, fireteam_id)), 1)
		var planned_next: int = maxi(int(_next_planned_revision_by_peer_fireteam.get(revision_key, 1)), 1)
		next_revision = maxi(maxi(next_revision, authority_next), planned_next)
	var resolved_revision: int = maxi(next_revision, requested_revision)
	for fireteam_variant in PackedStringArray(intent.selected_fireteam_ids):
		var fireteam_id: String = String(fireteam_variant).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			_next_planned_revision_by_peer_fireteam["%d:%s" % [source_peer_id, fireteam_id]] = resolved_revision + 1
	return resolved_revision
