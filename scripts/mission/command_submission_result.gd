class_name CommandSubmissionResult
extends RefCounted

var accepted: bool = false
var reason: String = ""
var plan_id: String = ""
var command_token: String = ""
var pending: bool = false
var committed: bool = false
var fireteam_results: Array = []


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		accepted = bool(data.get("accepted", false))
		reason = String(data.get("reason", "")).strip_edges()
		plan_id = String(data.get("plan_id", "")).strip_edges()
		command_token = String(data.get("command_token", "")).strip_edges()
		pending = bool(data.get("pending", false))
		committed = bool(data.get("committed", false))
		fireteam_results = Array(data.get("fireteam_results", [])).duplicate(true)
	_normalize()


static func from_dict(data: Dictionary) -> CommandSubmissionResult:
	var script_ref: GDScript = load("res://scripts/mission/command_submission_result.gd")
	return script_ref.new(data)


static func accepted_pending(next_plan_id: String, next_command_token: String, next_fireteam_results: Array = []) -> CommandSubmissionResult:
	return from_dict({
		"accepted": true,
		"plan_id": next_plan_id,
		"command_token": next_command_token,
		"pending": true,
		"committed": false,
		"fireteam_results": next_fireteam_results,
	})


static func accepted_committed(next_plan_id: String, next_command_token: String, next_fireteam_results: Array = []) -> CommandSubmissionResult:
	return from_dict({
		"accepted": true,
		"plan_id": next_plan_id,
		"command_token": next_command_token,
		"pending": false,
		"committed": true,
		"fireteam_results": next_fireteam_results,
	})


static func rejected(next_plan_id: String, next_reason: String, next_command_token: String = "", next_fireteam_results: Array = []) -> CommandSubmissionResult:
	return from_dict({
		"accepted": false,
		"reason": next_reason,
		"plan_id": next_plan_id,
		"command_token": next_command_token,
		"pending": false,
		"committed": false,
		"fireteam_results": next_fireteam_results,
	})


func to_dict() -> Dictionary:
	return {
		"accepted": accepted,
		"reason": reason,
		"plan_id": plan_id,
		"command_token": command_token,
		"pending": pending,
		"committed": committed,
		"fireteam_results": fireteam_results.duplicate(true),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _normalize() -> void:
	if not accepted:
		pending = false
		committed = false
	elif committed:
		pending = false
