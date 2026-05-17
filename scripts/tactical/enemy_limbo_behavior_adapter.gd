class_name EnemyLimboBehaviorAdapter
extends RefCounted

const ACTION_SEEK_COVER: String = "seek_cover"
const ACTION_CONTACT_HOLD: String = "contact_hold"
const ACTION_PATROL: String = "patrol"

const FLAG_SHOULD_SEEK_COVER: StringName = &"should_seek_cover"
const FLAG_HAS_CONTACT: StringName = &"has_contact"
const FLAG_HAS_PATROL: StringName = &"has_patrol"
const VAR_SELECTED_ACTION: StringName = &"selected_action"
const VAR_SEEK_COVER_ACTION: StringName = &"seek_cover_action"
const VAR_CONTACT_HOLD_ACTION: StringName = &"contact_hold_action"
const VAR_PATROL_ACTION: StringName = &"patrol_action"

const REASON_SEEK_COVER: String = "contact_visible_cover_needed"
const REASON_CONTACT_HOLD: String = "contact_visible_hold_fire_lane"
const REASON_PATROL: String = "no_contact_patrol_available"
const REASON_NO_BRANCH: String = "no_limbo_branch_available"

var _behavior_tree: BehaviorTree = null


class BlackboardFlagCondition:
	extends BTCondition

	@export var flag_var: StringName = &""

	func _init(next_flag_var: StringName = &"") -> void:
		flag_var = next_flag_var

	func _generate_name() -> String:
		return "Has %s" % String(flag_var)

	func _tick(_delta: float) -> Status:
		if blackboard == null:
			return FAILURE
		return SUCCESS if bool(blackboard.get_var(flag_var, false, false)) else FAILURE


class BlackboardCallableAction:
	extends BTAction

	const SELECTED_ACTION_VAR: StringName = &"selected_action"

	@export var action_id: String = ""
	@export var callable_var: StringName = &""

	func _init(next_action_id: String = "", next_callable_var: StringName = &"") -> void:
		action_id = next_action_id
		callable_var = next_callable_var

	func _generate_name() -> String:
		return "Do %s" % action_id

	func _tick(_delta: float) -> Status:
		if blackboard == null:
			return FAILURE
		var action_variant: Variant = blackboard.get_var(callable_var, Callable(), false)
		if typeof(action_variant) != TYPE_CALLABLE:
			return FAILURE
		var action: Callable = action_variant
		if not action.is_valid():
			return FAILURE
		if not bool(action.call()):
			return FAILURE
		blackboard.set_var(SELECTED_ACTION_VAR, action_id)
		return SUCCESS


func evaluate(enemy: Node, context: Dictionary, instance_owner: Node, delta: float = 0.0) -> Dictionary:
	if enemy == null:
		return _build_result(false, "", "missing_enemy")
	if instance_owner == null:
		return _build_result(false, "", "missing_instance_owner")

	var blackboard: Blackboard = Blackboard.new()
	_populate_blackboard(blackboard, context)
	var behavior_tree: BehaviorTree = _get_behavior_tree()
	var instance = behavior_tree.call("instantiate", enemy, blackboard, instance_owner, instance_owner)
	if instance == null or not instance.has_method("update"):
		return _build_result(false, "", "missing_bt_instance")

	var status: int = int(instance.call("update", delta))
	var selected_action: String = String(blackboard.get_var(VAR_SELECTED_ACTION, "", false))
	return {
		"handled": status == BTTask.SUCCESS and not selected_action.is_empty(),
		"selected_action": selected_action,
		"reason": _build_decision_reason(selected_action, context, status),
		"status": status,
		"status_text": _status_to_text(status),
		"source": "limboai_behavior_tree",
		"unit_id": String(context.get("unit_id", "")),
		"has_contact": bool(context.get("has_contact", false)),
		"has_patrol": bool(context.get("has_patrol", false)),
		"should_seek_cover": bool(context.get("should_seek_cover", false)),
		"cover_score": int(context.get("cover_score", 0)),
	}


func get_behavior_tree_snapshot() -> Dictionary:
	return {
		"source": "limboai_behavior_tree",
		"root": "BTSelector",
		"priority_order": PackedStringArray([
			ACTION_SEEK_COVER,
			ACTION_CONTACT_HOLD,
			ACTION_PATROL,
		]),
		"diagnostic_fields": PackedStringArray([
			"selected_action",
			"reason",
			"has_contact",
			"has_patrol",
			"should_seek_cover",
			"cover_score",
		]),
		"uses_limboai": ClassDB.class_exists("BehaviorTree") and ClassDB.class_exists("BTAction"),
	}


func _populate_blackboard(blackboard: Blackboard, context: Dictionary) -> void:
	blackboard.set_var(FLAG_SHOULD_SEEK_COVER, bool(context.get("should_seek_cover", false)))
	blackboard.set_var(FLAG_HAS_CONTACT, bool(context.get("has_contact", false)))
	blackboard.set_var(FLAG_HAS_PATROL, bool(context.get("has_patrol", false)))
	blackboard.set_var(VAR_SEEK_COVER_ACTION, context.get("seek_cover_action", Callable()))
	blackboard.set_var(VAR_CONTACT_HOLD_ACTION, context.get("contact_hold_action", Callable()))
	blackboard.set_var(VAR_PATROL_ACTION, context.get("patrol_action", Callable()))
	blackboard.set_var(VAR_SELECTED_ACTION, "")


func _get_behavior_tree() -> BehaviorTree:
	if _behavior_tree != null:
		return _behavior_tree

	var root: BTSelector = BTSelector.new()
	root.add_child(_build_sequence(FLAG_SHOULD_SEEK_COVER, ACTION_SEEK_COVER, VAR_SEEK_COVER_ACTION))
	root.add_child(_build_sequence(FLAG_HAS_CONTACT, ACTION_CONTACT_HOLD, VAR_CONTACT_HOLD_ACTION))
	root.add_child(_build_sequence(FLAG_HAS_PATROL, ACTION_PATROL, VAR_PATROL_ACTION))

	_behavior_tree = BehaviorTree.new()
	_behavior_tree.set_root_task(root)
	return _behavior_tree


func _build_sequence(flag_var: StringName, action_id: String, callable_var: StringName) -> BTSequence:
	var sequence: BTSequence = BTSequence.new()
	sequence.add_child(BlackboardFlagCondition.new(flag_var))
	sequence.add_child(BlackboardCallableAction.new(action_id, callable_var))
	return sequence


func _build_result(handled: bool, selected_action: String, reason: String) -> Dictionary:
	return {
		"handled": handled,
		"selected_action": selected_action,
		"status": BTTask.SUCCESS if handled else BTTask.FAILURE,
		"status_text": "success" if handled else "failure",
		"source": "limboai_behavior_tree",
		"reason": reason,
	}


func _build_decision_reason(selected_action: String, context: Dictionary, status: int) -> String:
	match selected_action:
		ACTION_SEEK_COVER:
			return REASON_SEEK_COVER
		ACTION_CONTACT_HOLD:
			return REASON_CONTACT_HOLD
		ACTION_PATROL:
			return REASON_PATROL
	if status == BTTask.FAILURE:
		if not bool(context.get("has_contact", false)) and not bool(context.get("has_patrol", false)):
			return "no_contact_no_patrol"
		if bool(context.get("has_contact", false)) and not bool(context.get("should_seek_cover", false)):
			return "contact_visible_action_failed"
	return REASON_NO_BRANCH


func _status_to_text(status: int) -> String:
	match status:
		BTTask.SUCCESS:
			return "success"
		BTTask.RUNNING:
			return "running"
		BTTask.FAILURE:
			return "failure"
		BTTask.FRESH:
			return "fresh"
		_:
			return "unknown"
