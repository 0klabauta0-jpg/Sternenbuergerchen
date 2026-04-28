class_name CommandToFTLTaskTranslator
extends RefCounted

const COMMANDER_COMMAND_SCRIPT: GDScript = preload("res://scripts/command/commander_command.gd")
const FTL_TASK_SCRIPT: GDScript = preload("res://scripts/ftl/ftl_task.gd")


func translate(command) -> RefCounted:
	if command == null or not command.has_method("is_valid") or not bool(command.call("is_valid")):
		return null

	var task_type: String = _map_command_type(String(command.get("command_type")))
	if task_type.is_empty():
		return null

	var task = FTL_TASK_SCRIPT.new()
	task.task_type = task_type
	task.priority = command.priority
	task.unit_id = command.unit_id
	task.team_id = command.team_id
	task.target_position = command.target_position
	task.target_floor_index = int(command.get("target_floor_index"))
	task.source_command_type = command.command_type
	task.phase = command.phase

	if not bool(task.call("is_valid")):
		return null

	return task


func translate_from_dict(data: Dictionary) -> RefCounted:
	var command = COMMANDER_COMMAND_SCRIPT.call("from_dict", data)
	return translate(command)


func _map_command_type(command_type: String) -> String:
	match command_type:
		"move":
			return "move_to_area"
		"engage":
			return "engage_in_area"
		# V1 rule: "take" maps straight to an area-engagement task without deeper decomposition yet.
		"take":
			return "engage_in_area"
		"defend":
			return "hold_position"
		# V1 rule: "flank" stays a repositioning task until later tactical split logic exists.
		"flank":
			return "move_to_area"
		_:
			return ""
