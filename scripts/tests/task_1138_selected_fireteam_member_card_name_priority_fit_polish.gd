extends SceneTree

const CARD_SCENE := preload("res://scenes/meta/components/npc_compact_card.tscn")
const PROFILE_SCRIPT := preload("res://scripts/meta/meta_unit_profile.gd")

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	var profile = PROFILE_SCRIPT.new({
		"unit_id": "task1138_operator",
		"display_name": "Alexandra Morgenstern",
		"role_id": "combat_medic",
		"role_name": "Bewegen | offensiv",
		"secondary_text": "Waffe gesenkt\nRennt",
		"weapon_1": "medictool",
		"weapon_2": "rifle",
	})
	var card = CARD_SCENE.instantiate()
	root.add_child(card)
	card.call("setup_from_profile", profile, {
		"source_context": "mission_selected_fireteam_member",
		"compact_mode": true,
		"drag_enabled": false,
		"show_badges": false,
		"show_lead_indicator": true,
		"fixed_size": true,
		"fixed_card_size": Vector2(176.0, 118.0),
		"compact_wrap_text": true,
		"compact_data_a_max_lines": 2,
		"compact_data_b_max_lines": 4,
		"compact_text_min_width": 94.0,
		"card_tooltip_override": "Alexandra Morgenstern\nTaktische Details",
	})
	await process_frame

	var badge_row := card.get_node_or_null("Margin/HBox/TextVBox/NameRow/BadgeRow") as HBoxContainer
	var name_label := card.get_node_or_null("Margin/HBox/TextVBox/NameRow/NameLabel") as Label
	var snapshot: Dictionary = Dictionary(card.call("get_card_userology_snapshot"))
	_check(card.custom_minimum_size == Vector2(176.0, 118.0), "Mission card uses the wider fixed geometry")
	_check(name_label != null and name_label.text == "Alexandra Morgenstern", "Full operator identity remains the card name")
	_check(badge_row != null and not badge_row.visible and badge_row.get_child_count() == 0, "Mission card does not spend header width on rank badges")
	_check(not bool(snapshot.get("show_badges", true)), "Readonly card snapshot exposes the context-specific badge policy")
	_check(card.tooltip_text.begins_with("Alexandra Morgenstern"), "Full operator name remains available in the card tooltip")
	_check(float(card.get_node("Margin/HBox/TextVBox").custom_minimum_size.x) >= 94.0, "Mission card reserves a wider text column")

	var default_card = CARD_SCENE.instantiate()
	root.add_child(default_card)
	default_card.call("setup_from_profile", profile, {"compact_mode": true, "drag_enabled": false})
	await process_frame
	var default_snapshot: Dictionary = Dictionary(default_card.call("get_card_userology_snapshot"))
	_check(bool(default_snapshot.get("show_badges", false)), "Other compact-card contexts keep the default badge policy")

	card.queue_free()
	default_card.queue_free()
	await process_frame
	if _failures.is_empty():
		print("TASK_1138 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
