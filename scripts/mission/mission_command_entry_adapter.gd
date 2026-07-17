class_name MissionCommandEntryAdapter
extends RefCounted

const COMMANDER_ORDER_INTENT_SCRIPT: GDScript = preload("res://scripts/mission/commander_order_intent.gd")
const COMMAND_SUBMISSION_RESULT_SCRIPT: GDScript = preload("res://scripts/mission/command_submission_result.gd")

var _gateway = null


func configure(gateway) -> void:
	_gateway = gateway


func plan_from_button(command_type: String, selected_fireteam_ids: PackedStringArray, target_position: Variant, phase: int, source_peer_id: int, team_id: String = "", target_area_id: String = "", metadata: Dictionary = {}) -> RefCounted:
	return plan_from_entry("button", command_type, selected_fireteam_ids, target_position, phase, source_peer_id, team_id, target_area_id, metadata)


func plan_from_hotkey(command_type: String, selected_fireteam_ids: PackedStringArray, target_position: Variant, phase: int, source_peer_id: int, team_id: String = "", target_area_id: String = "", metadata: Dictionary = {}) -> RefCounted:
	return plan_from_entry("hotkey", command_type, selected_fireteam_ids, target_position, phase, source_peer_id, team_id, target_area_id, metadata)


func plan_from_rmb(command_type: String, selected_fireteam_ids: PackedStringArray, target_position: Variant, phase: int, source_peer_id: int, team_id: String = "", target_area_id: String = "", metadata: Dictionary = {}) -> RefCounted:
	return plan_from_entry("rmb", command_type, selected_fireteam_ids, target_position, phase, source_peer_id, team_id, target_area_id, metadata)


func plan_from_entry(entry_source: String, command_type: String, selected_fireteam_ids: PackedStringArray, target_position: Variant, phase: int, source_peer_id: int, team_id: String = "", target_area_id: String = "", metadata: Dictionary = {}) -> RefCounted:
	if _gateway == null or not _gateway.has_method("plan_intent"):
		return COMMAND_SUBMISSION_RESULT_SCRIPT.call("rejected", "", "command_gateway_unavailable")
	var intent = COMMANDER_ORDER_INTENT_SCRIPT.new({
		"command_type": command_type,
		"selected_fireteam_ids": selected_fireteam_ids,
		"target_position": target_position,
		"phase": phase,
		"source_peer_id": source_peer_id,
		"entry_source": entry_source,
		"team_id": team_id,
		"target_area_id": target_area_id,
		"metadata": metadata.duplicate(true),
	})
	return _gateway.call("plan_intent", intent)


func submit_go(plan_id: String) -> RefCounted:
	if _gateway == null or not _gateway.has_method("submit_go"):
		return COMMAND_SUBMISSION_RESULT_SCRIPT.call("rejected", plan_id.strip_edges(), "command_gateway_unavailable")
	return _gateway.call("submit_go", plan_id)
