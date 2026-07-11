extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1130 Fireteam Mini-Card Identity and Typography Polish ===")
	root.size = Vector2i(1920, 1080)
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(12):
		await process_frame
	var host := mission.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox") as VBoxContainer
	var cards: Dictionary = _cards_by_fireteam(host)
	_assert(cards.has("blue") and cards.has("gold"), "Local mission exposes BLUE and GOLD mini-cards")
	_assert(_card_title(Dictionary(cards).get("blue", null)) == "BLUE" and _card_title(Dictionary(cards).get("gold", null)) == "GOLD", "Mini-card titles retain known Fireteam identities")
	_assert(_cards_do_not_show_unknown_review_badge(cards), "Inactive local review session does not render FT ? on mini-cards")
	_assert(_cards_meet_font_floor(cards, "Margin/VBox/HeaderRow/TitleEdit", 12), "Mini-card Fireteam titles use at least 12 px")
	_assert(_cards_meet_font_floor(cards, "Margin/VBox/StageLabel", 10), "Mini-card secondary status uses at least 10 px")
	_assert(_cards_meet_font_floor(cards, "Margin/VBox/MemberLabel", 10), "Mini-card primary status uses at least 10 px")
	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _cards_by_fireteam(host: VBoxContainer) -> Dictionary:
	var result: Dictionary = {}
	if host == null:
		return result
	for child in host.get_children():
		var fireteam_id: String = String(child.get_meta("fireteam_id", "")).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			result[fireteam_id] = child
	return result


func _card_title(card_variant) -> String:
	var card := card_variant as Control
	var title := card.get_node_or_null("Margin/VBox/HeaderRow/TitleEdit") as LineEdit if card != null else null
	return title.text.strip_edges() if title != null else ""


func _cards_do_not_show_unknown_review_badge(cards: Dictionary) -> bool:
	for card_variant in cards.values():
		var card := card_variant as Control
		if card == null:
			return false
		for path in ["Margin/VBox/StageLabel", "Margin/VBox/MemberLabel"]:
			var label := card.get_node_or_null(path) as Label
			if label != null and label.text.contains("FT ?"):
				return false
	return not cards.is_empty()


func _cards_meet_font_floor(cards: Dictionary, path: String, minimum_size: int) -> bool:
	for card_variant in cards.values():
		var card := card_variant as Control
		var control := card.get_node_or_null(path) as Control if card != null else null
		if control == null or control.get_theme_font_size("font_size") < minimum_size:
			return false
	return not cards.is_empty()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
