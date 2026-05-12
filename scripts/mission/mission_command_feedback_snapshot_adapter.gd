extends RefCounted

const SNAPSHOT_KEYS: PackedStringArray = [
	"selected_fireteam_ids",
	"selected_fireteam_label",
	"selected_tile",
	"phase_name",
	"target_text",
	"selected_order_text",
	"selected_multi_fireteam_plan_text",
	"mission_control_plan_text",
	"selected_status_text",
	"last_command_text",
	"command_feedback_text",
	"selected_fireteam_status_label_text",
	"mission_control_status_text",
	"command_buttons",
	"command_hierarchy",
	"command_clarity",
	"planned_waypoint_count",
	"planned_area_order_count",
	"multi_fireteam_plan_count",
	"visualized_waypoint_count",
	"visualized_area_order_count",
	"active_area_defense",
	"active_area_attack",
	"fireteamleader_feedback_bubbles_enabled",
	"fireteamleader_feedback_bubbles",
	"tactical_communication_events",
	"tactical_breakouts",
	"fireteam_coordination",
	"air_asset_status",
	"air_asset_threats",
	"selected_tactical_communication_text",
	"mission_control_tactical_communication_text",
	"npc_thought_bubbles",
]


func build_snapshot(context: Dictionary) -> Dictionary:
	var snapshot: Dictionary = {}
	for key in SNAPSHOT_KEYS:
		snapshot[key] = _duplicate_snapshot_value(context.get(key, _default_value_for_key(key)))

	_apply_count(snapshot, "fireteamleader_feedback_bubble_count", "fireteamleader_feedback_bubbles")
	_apply_count(snapshot, "tactical_communication_event_count", "tactical_communication_events")
	_apply_count(snapshot, "tactical_breakout_count", "tactical_breakouts")
	_apply_count(snapshot, "fireteam_coordination_count", "fireteam_coordination")
	_apply_count(snapshot, "air_asset_threat_count", "air_asset_threats")
	_apply_count(snapshot, "npc_thought_bubble_count", "npc_thought_bubbles")
	return snapshot


func _apply_count(snapshot: Dictionary, count_key: String, array_key: String) -> void:
	snapshot[count_key] = Array(snapshot.get(array_key, [])).size()


func _duplicate_snapshot_value(value: Variant) -> Variant:
	if value is Dictionary:
		return Dictionary(value).duplicate(true)
	if value is Array:
		return Array(value).duplicate(true)
	if value is PackedStringArray:
		return Array(value)
	return value


func _default_value_for_key(key: String) -> Variant:
	if key.ends_with("_count") or key in [
		"planned_waypoint_count",
		"planned_area_order_count",
		"multi_fireteam_plan_count",
		"visualized_waypoint_count",
		"visualized_area_order_count",
	]:
		return 0
	if key.ends_with("_enabled"):
		return false
	if key in [
		"selected_fireteam_ids",
		"active_area_defense",
		"active_area_attack",
		"fireteamleader_feedback_bubbles",
		"tactical_communication_events",
		"tactical_breakouts",
		"fireteam_coordination",
		"air_asset_threats",
		"npc_thought_bubbles",
	]:
		return []
	if key in [
		"selected_tile",
		"command_buttons",
		"command_hierarchy",
		"command_clarity",
		"air_asset_status",
	]:
		return {}
	return ""
