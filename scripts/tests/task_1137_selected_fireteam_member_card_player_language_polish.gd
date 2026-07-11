extends SceneTree

const CONTROLLER_SCRIPT := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const CARD_SCENE := preload("res://scenes/meta/components/npc_compact_card.tscn")
const PROFILE_SCRIPT := preload("res://scripts/meta/meta_unit_profile.gd")

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	var controller = CONTROLLER_SCRIPT.new()
	_check_equal(controller.call("_format_unit_command_label", "move"), "Bewegen", "Move wird spielsprachlich formatiert")
	_check_equal(controller.call("_format_unit_command_label", "engage"), "Angreifen", "Engage wird spielsprachlich formatiert")
	_check_equal(controller.call("_format_unit_command_label", "take"), "Nehmen", "Take wird spielsprachlich formatiert")
	_check_equal(controller.call("_format_unit_command_label", "defend"), "Verteidigen", "Defend wird spielsprachlich formatiert")
	_check_equal(controller.call("_format_unit_command_label", "idle"), "Wartet", "Idle wird spielsprachlich formatiert")
	_check_equal(controller.call("_format_unit_weapon_posture_text", "aimed"), "Waffe im Anschlag", "Aimed wird spielsprachlich formatiert")
	_check_equal(controller.call("_format_unit_weapon_posture_text", "lowered"), "Waffe gesenkt", "Lowered wird spielsprachlich formatiert")
	_check_equal(controller.call("_format_unit_movement_posture_text", "travel"), "Marschiert", "Travel wird spielsprachlich formatiert")
	_check_equal(controller.call("_format_unit_movement_posture_text", "run"), "Rennt", "Run wird spielsprachlich formatiert")
	_check_equal(controller.call("_format_unit_movement_posture_text", "idle"), "Steht", "Idle-Bewegung wird spielsprachlich formatiert")

	var profile = PROFILE_SCRIPT.new({
		"unit_id": "task1137_unit",
		"display_name": "Mira Test",
		"role_name": "Bewegen | Feuer frei | offensiv",
		"secondary_text": "Waffe im Anschlag | Rennt",
	})
	var card = CARD_SCENE.instantiate()
	root.add_child(card)
	card.call("setup_from_profile", profile, {
		"compact_mode": true,
		"drag_enabled": false,
		"card_tooltip_override": "Technik\nSkills: A:0.7 S:0.5",
	})
	await process_frame
	_check_equal(card.tooltip_text, "Technik\nSkills: A:0.7 S:0.5", "Technische Werte bleiben im Karten-Tooltip erhalten")
	_check(not String(card.get_node("Margin/HBox/TextVBox/DataBLabel").text).contains("A:"), "Sichtbare Detailzeile enthaelt keine rohen Skillwerte")
	_check(bool(card.call("get_profile_reference_contract_snapshot").get("has_card_tooltip_override", false)), "Readonly-Contract meldet den Tooltip")
	card.queue_free()
	controller.free()
	await process_frame

	if _failures.is_empty():
		print("TASK_1137 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _check_equal(actual, expected, message: String) -> void:
	_check(actual == expected, "%s (actual=%s expected=%s)" % [message, str(actual), str(expected)])
