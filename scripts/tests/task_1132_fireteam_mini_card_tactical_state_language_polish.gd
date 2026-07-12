extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1132 Fireteam Mini-Card Tactical State Language Polish ===")
	root.size = Vector2i(1920, 1080)
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(16):
		await process_frame
	var controller := mission.get_node_or_null("TacticalController")
	var blue_card := mission.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox/FireteamMiniCard_Blue") as Control
	_assert(controller != null and blue_card != null, "Mission exposes controller and BLUE mini-card")
	if controller != null and blue_card != null:
		_test_neutral_visible_language(blue_card)
		_test_active_snapshot_language(controller)
		_test_execution_risk_language(controller)
		_test_readiness_footer_truth(blue_card)
	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_neutral_visible_language(card: Control) -> void:
	var status := card.get_node_or_null("Margin/VBox/StageLabel") as Label
	var text := status.text.strip_edges() if status != null else ""
	_assert(text.begins_with("WARTET | "), "Neutral Fireteam state starts with WARTET")
	_assert(text.contains("KEIN KONTAKT"), "Neutral Fireteam state explains that no contact exists")
	_assert(text.contains("FIT "), "Neutral Fireteam state names fit operators")
	_assert(not text.contains("EX ") and not text.contains("C0") and not text.contains("HP "), "Visible state contains no legacy diagnosis abbreviations")


func _test_active_snapshot_language(controller: Node) -> void:
	var units: Array = Array(controller.call("_get_fireteam_units", "blue", true))
	var snapshot: Dictionary = Dictionary(controller.call("_build_fireteam_status_card_entry", "blue", units, {
		"execution_label": "STEADY",
		"order_fidelity": 0.82,
	}, {
		"state": "confirmed",
		"count": 2,
	}))
	var visible_text := String(snapshot.get("primary_text", ""))
	_assert(visible_text.begins_with("STABIL 82% | "), "Active execution translates STEADY and preserves useful fidelity")
	_assert(visible_text.contains("2 KONTAKTE BEST."), "Confirmed contacts name the contact domain without a diagnostic C-prefix")
	_assert(String(snapshot.get("execution_text", "")).contains("STEADY"), "Technical execution detail remains in the snapshot")
	_assert(String(snapshot.get("tooltip_text", "")).contains("Execution:"), "Tooltip retains technical execution diagnostics")


func _test_readiness_footer_truth(card: Control) -> void:
	var footer := card.find_child("ReadinessFooterLabel", true, false) as Label
	_assert(footer != null and not footer.visible, "Unavailable readiness is hidden instead of displaying RDY N/A")
	_assert(footer != null and String(footer.get_meta("mission_fireteam_readiness_state", "")) == "unavailable", "Hidden readiness footer preserves its truthful state metadata")


func _test_execution_risk_language(controller: Node) -> void:
	_assert(String(controller.call("_format_fireteam_visible_execution_text", {"execution_label": "LOW DISC", "order_fidelity": 0.4})).begins_with("FEUERDISZ. "), "Low fire discipline has a compact player label")
	_assert(String(controller.call("_format_fireteam_visible_execution_text", {"execution_label": "SCATTER", "order_fidelity": 0.4})).begins_with("VERSTREUT "), "Low cohesion has a compact player label")
	_assert(String(controller.call("_format_fireteam_visible_execution_text", {"execution_label": "DELAY", "order_fidelity": 0.4})).begins_with("VERZUG "), "Reaction delay has a compact player label")
	var unknown_text := String(controller.call("_format_fireteam_visible_execution_text", {"execution_label": "A VERY LONG MODDED EXECUTION LABEL", "order_fidelity": 0.4}))
	_assert(unknown_text == "AKTIV 40%", "Unknown execution labels stay bounded while raw diagnostics remain elsewhere")


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
