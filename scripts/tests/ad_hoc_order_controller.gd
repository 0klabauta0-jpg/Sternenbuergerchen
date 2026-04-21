class_name AdHocOrderController
extends RefCounted

const AD_HOC_ORDER_SCRIPT: GDScript = preload("res://scripts/command/ad_hoc_order.gd")

var _sequence: int = 0
var _active_orders_by_fireteam: Dictionary = {}
var _resume_state_by_fireteam: Dictionary = {}


func issue_order(fireteam_id: String, order_type: String, target_position: Variant, source_phase: int, can_issue_now: bool, resume_state: Dictionary = {}, metadata: Dictionary = {}) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() or not can_issue_now:
		return {}
	if not AD_HOC_ORDER_SCRIPT.call("is_allowed_order_type", order_type):
		return {}
	var order = AD_HOC_ORDER_SCRIPT.new()
	_sequence += 1
	order.order_id = "adhoc_%04d" % _sequence
	order.fireteam_id = normalized_fireteam_id
	order.order_type = order_type
	order.status = AD_HOC_ORDER_SCRIPT.STATUS_ACTIVE
	order.source_phase = source_phase
	if target_position != null:
		order.target_position = target_position
	order.resume_plan_after = true
	order.metadata = Dictionary(metadata).duplicate(true)
	if not order.is_valid():
		return {}
	_active_orders_by_fireteam[normalized_fireteam_id] = order
	_resume_state_by_fireteam[normalized_fireteam_id] = Dictionary(resume_state).duplicate(true)
	return order.to_dict()


func has_active_order(fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return false
	return _active_orders_by_fireteam.has(normalized_fireteam_id)


func get_active_order(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() or not _active_orders_by_fireteam.has(normalized_fireteam_id):
		return {}
	var order = _active_orders_by_fireteam[normalized_fireteam_id]
	return order.to_dict() if order != null and order.has_method("to_dict") else {}


func get_active_orders_snapshot() -> Array:
	var result: Array = []
	var fireteam_ids: Array = _active_orders_by_fireteam.keys()
	fireteam_ids.sort()
	for fireteam_id in fireteam_ids:
		result.append(get_active_order(String(fireteam_id)))
	return result


func complete_order(fireteam_id: String, reason: String = "completed") -> Dictionary:
	return _finalize_order(fireteam_id, AD_HOC_ORDER_SCRIPT.STATUS_COMPLETED, reason)


func cancel_order(fireteam_id: String, reason: String = "cancelled") -> Dictionary:
	return _finalize_order(fireteam_id, AD_HOC_ORDER_SCRIPT.STATUS_CANCELLED, reason)


func get_resume_state(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() or not _resume_state_by_fireteam.has(normalized_fireteam_id):
		return {}
	return Dictionary(_resume_state_by_fireteam.get(normalized_fireteam_id, {})).duplicate(true)


func should_hold_until_last_man(fireteam_id: String) -> bool:
	var order_dict: Dictionary = get_active_order(fireteam_id)
	if order_dict.is_empty():
		return false
	return String(order_dict.get("order_type", "")) == AD_HOC_ORDER_SCRIPT.ORDER_TYPE_HOLD_TILL_LAST_MAN


func _finalize_order(fireteam_id: String, next_status: String, reason: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() or not _active_orders_by_fireteam.has(normalized_fireteam_id):
		return {}
	var order = _active_orders_by_fireteam[normalized_fireteam_id]
	if order == null:
		_active_orders_by_fireteam.erase(normalized_fireteam_id)
		_resume_state_by_fireteam.erase(normalized_fireteam_id)
		return {}
	order.status = next_status
	var metadata: Dictionary = Dictionary(order.metadata).duplicate(true)
	metadata["resolved_reason"] = reason
	order.metadata = metadata
	var result: Dictionary = order.to_dict()
	_active_orders_by_fireteam.erase(normalized_fireteam_id)
	_resume_state_by_fireteam.erase(normalized_fireteam_id)
	return result
