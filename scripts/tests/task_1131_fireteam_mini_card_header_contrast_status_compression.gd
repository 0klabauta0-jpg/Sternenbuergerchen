extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1131 Fireteam Mini-Card Header Contrast and Status Compression ===")
	root.size = Vector2i(1920, 1080)
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(16):
		await process_frame
	var host := mission.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox") as VBoxContainer
	var cards := _cards_by_fireteam(host)
	_assert(cards.has("blue") and cards.has("gold"), "Local mission exposes BLUE and GOLD mini-cards")
	_assert(_cards_have_contrast_header(cards), "Mission mini-card titles use the explicit high-contrast header style")
	_assert(_cards_keep_header_controls_separate(cards), "Status badges and stance controls no longer compete with the Fireteam title")
	_assert(_cards_do_not_duplicate_member_status_row(cards), "Member health snapshot remains available without a redundant visible chip row")
	_assert(_cards_fit_fireteam_scroll(cards, host), "Both Fireteam cards fit completely inside the left overview viewport")
	_assert(_cards_show_primary_status_first(cards), "First visible status line exposes execution, contact and health in player language")
	_assert(_cards_show_compact_identity_second(cards), "Second visible line keeps lead and operator count without waypoint noise")
	_assert(_cards_keep_full_detail_tooltip(cards), "Compressed cards retain movement, position and suppression detail in the tooltip")
	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _cards_by_fireteam(host: VBoxContainer) -> Dictionary:
	var result: Dictionary = {}
	if host == null:
		return result
	for child in host.get_children():
		var fireteam_id := String(child.get_meta("fireteam_id", "")).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			result[fireteam_id] = child
	return result


func _cards_have_contrast_header(cards: Dictionary) -> bool:
	for card_variant in cards.values():
		var card := card_variant as Control
		var title := card.get_node_or_null("Margin/VBox/HeaderRow/TitleEdit") as LineEdit if card != null else null
		if title == null or not bool(title.get_meta("mission_mini_high_contrast_header", false)):
			return false
		var font_color := title.get_theme_color("font_color")
		if font_color.get_luminance() < 0.75 or title.get_theme_font_size("font_size") < 12:
			return false
	return not cards.is_empty()


func _cards_show_primary_status_first(cards: Dictionary) -> bool:
	for card_variant in cards.values():
		var card := card_variant as Control
		var stage := card.get_node_or_null("Margin/VBox/StageLabel") as Label if card != null else null
		if stage == null or stage.text.split(" | ").size() != 3 or not stage.text.contains("KONTAKT") or not stage.text.contains("FIT "):
			return false
	return not cards.is_empty()


func _cards_fit_fireteam_scroll(cards: Dictionary, host: VBoxContainer) -> bool:
	var scroll := host.get_parent() as ScrollContainer if host != null else null
	if scroll == null:
		return false
	var viewport_rect := scroll.get_global_rect()
	for card_variant in cards.values():
		var card := card_variant as Control
		if card == null or not viewport_rect.encloses(card.get_global_rect()):
			print("TASK_1131 geometry viewport=%s card=%s" % [str(viewport_rect), str(card.get_global_rect()) if card != null else "null"])
			return false
	return not cards.is_empty()


func _cards_do_not_duplicate_member_status_row(cards: Dictionary) -> bool:
	for card_variant in cards.values():
		var card := card_variant as Control
		var row := card.find_child("FireteamMemberStatusRow", true, false) as Control if card != null else null
		if row == null or row.visible or row.custom_minimum_size.y > 0.0:
			return false
		if Dictionary(row.call("get_row_snapshot")).is_empty():
			return false
	return not cards.is_empty()


func _cards_keep_header_controls_separate(cards: Dictionary) -> bool:
	for card_variant in cards.values():
		var card := card_variant as Control
		var header := card.get_node_or_null("Margin/VBox/HeaderRow") as HBoxContainer if card != null else null
		var status_row := card.get_node_or_null("Margin/VBox/HeaderStatusRow") as HBoxContainer if card != null else null
		if header == null or status_row == null:
			return false
		for node_name in ["ContactBadge", "MoraleBadge", "CoordinationBadge", "StanceToggle"]:
			if header.get_node_or_null(node_name) != null or status_row.get_node_or_null(node_name) == null:
				return false
	return not cards.is_empty()


func _cards_show_compact_identity_second(cards: Dictionary) -> bool:
	for card_variant in cards.values():
		var card := card_variant as Control
		var member := card.get_node_or_null("Margin/VBox/MemberLabel") as Label if card != null else null
		if member == null or not member.text.begins_with("Lead ") or not member.text.contains(" Ops"):
			return false
		if member.text.contains("\n") or member.text.contains("Wegpunkte"):
			return false
	return not cards.is_empty()


func _cards_keep_full_detail_tooltip(cards: Dictionary) -> bool:
	for card_variant in cards.values():
		var card := card_variant as Control
		var stage := card.get_node_or_null("Margin/VBox/StageLabel") as Label if card != null else null
		if stage == null or not stage.tooltip_text.contains("Suppression:") or not stage.tooltip_text.contains("Move:") or not stage.tooltip_text.contains("Position:"):
			return false
	return not cards.is_empty()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
