extends SceneTree
## Real native presenter and real card controls; only pure UI source inputs are
## fixtures. No mission actors, runtime commands, simulation or clocks are used.
const CARD = preload("res://scripts/meta/fob_fireteam_card.gd")
const THEME = preload("res://scripts/ui/tactical_ui_theme.gd")

class ControllerProbe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var roster: Array = ["fixture_member_a", "fixture_member_b", "fixture_member_c"]
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)
	func _get_fireteam_units(_fireteam_id: String, _include_hidden: bool = true) -> Array:
		return roster.duplicate()
	func _get_fireteam_display_label(_fireteam_id: String) -> String:
		return "FIXTURE ALPHA"

var passed := 0
var failed := 0
var notices := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var presenter := ControllerProbe.new()
	root.add_child(presenter)
	var host := Control.new()
	host.theme = THEME.get_theme()
	root.add_child(host)
	var card := CARD.new()
	host.add_child(card)
	card.setup_card("ft1", "FIXTURE ALPHA", false, false, "medium", "Fixture lead", "mission_mini")
	card.set_meta("mission_fireteam_lead_summary", "Fixture lead")
	var strip := HBoxContainer.new()
	strip.name = "FireteamMemberPortraitStrip"
	card.get_node("Margin/VBox").add_child(strip)
	for _index in range(2):
		var portrait := TextureRect.new()
		portrait.mouse_filter = Control.MOUSE_FILTER_STOP
		strip.add_child(portrait)
	var roster_before := presenter.roster.duplicate(true)
	var cases: Array[Dictionary] = [
		{"selected": false, "contacts": 0, "inactive": false, "counts": {}, "suppression": "ready", "expected": "Bereit"},
		{"selected": true, "contacts": 2, "inactive": false, "counts": {}, "suppression": "ready", "expected": "2 Feindkontakte"},
		{"selected": true, "contacts": 2, "inactive": true, "counts": {}, "suppression": "ready", "expected": "Nicht aktiv"},
		{"selected": false, "contacts": 0, "inactive": false, "counts": {"busy": 1}, "suppression": "ready", "expected": "Auftrag wird ausgeführt"},
		{"selected": false, "contacts": 0, "inactive": false, "counts": {"down": 1}, "suppression": "ready", "expected": "Verluste im Trupp"},
		{"selected": false, "contacts": 0, "inactive": false, "counts": {}, "suppression": "pinned", "expected": "Festgesetzt"},
	]
	present(presenter, card, cases[0])
	await settle()
	connect_notices(card)
	for spec in cases:
		var input_before := var_to_bytes(spec)
		present(presenter, card, spec)
		await settle()
		var expected := card_state(card)
		var stage := card.get_node("Margin/VBox/StageLabel") as Label
		var marker := card.get_node("Margin/VBox/HeaderRow/A5SelectionMarker") as Label
		check(stage.text == String(spec.expected) and marker.visible == bool(spec.selected), "Current status and selection project immediately: %s" % spec.expected)
		check(stage.get_theme_color("font_color") == (THEME.COLOR_WARNING if int(spec.contacts) > 0 else THEME.COLOR_TEXT), "Current contact warning has its final native color: %s" % spec.expected)
		notices = 0
		present(presenter, card, spec)
		await settle()
		print("R4_NATIVE_CARD_NOTICES ", JSON.stringify({"status": spec.expected, "count": notices}))
		check(notices == 0, "Identical native pass emits zero actual control theme notifications: %s" % spec.expected)
		check(card_state(card) == expected, "Identical native pass preserves complete actual card presentation: %s" % spec.expected)
		check(var_to_bytes(spec) == input_before, "Presenter leaves pure source snapshot unchanged: %s" % spec.expected)
	# The repair oracle checks the actual owned resources, not a remembered token.
	var spec: Dictionary = cases[1]
	present(presenter, card, spec)
	await settle()
	var pristine := card_state(card)
	var title := card.get_node("Margin/VBox/HeaderRow/TitleEdit") as LineEdit
	var margin := card.get_node("Margin") as MarginContainer
	var box := card.get_node("Margin/VBox") as VBoxContainer
	var marker := card.get_node("Margin/VBox/HeaderRow/A5SelectionMarker") as Label
	var stage := card.get_node("Margin/VBox/StageLabel") as Label
	card.add_theme_stylebox_override("panel", StyleBoxFlat.new())
	margin.add_theme_constant_override("margin_left", 991)
	margin.remove_theme_constant_override("margin_bottom")
	box.add_theme_constant_override("separation", 991)
	title.add_theme_font_size_override("font_size", 991)
	title.add_theme_color_override("font_uneditable_color", Color.MAGENTA)
	title.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	title.remove_theme_stylebox_override("read_only")
	marker.add_theme_color_override("font_color", Color.MAGENTA)
	marker.remove_theme_font_size_override("font_size")
	stage.add_theme_color_override("font_color", Color.MAGENTA)
	stage.remove_theme_font_size_override("font_size")
	present(presenter, card, spec)
	await settle()
	check(card_state(card) == pristine, "Real changed or removed owned overrides are restored even for identical source inputs")
	check(margin.has_theme_constant_override("margin_bottom") and title.has_theme_stylebox_override("read_only") and marker.has_theme_font_size_override("font_size") and stage.has_theme_font_size_override("font_size"), "Inherited equal values do not replace required owned overrides")
	check(presenter.roster == roster_before, "Native projection leaves roster source unchanged")
	host.free()
	presenter.free()
	await process_frame
	await process_frame
	print("R4_NATIVE_CARD_PROJECTION: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_NATIVE_CARD_PROJECTION_PASS")
	quit(1 if failed else 0)

func present(presenter: Node, card: Control, spec: Dictionary) -> void:
	# The normal caller publishes these fresh pure status/tooltip inputs before
	# the native endpass. Reset them here too, avoiding an artificial direct-only
	# tooltip accumulation fixture that does not occur in the real call chain.
	card.tooltip_text = "Fixture legacy tooltip"
	card.set_meta("mission_fireteam_status_card_snapshot", {"contact_count": int(spec.contacts), "suppression_state": String(spec.suppression), "member_status": {"counts": Dictionary(spec.counts).duplicate(true)}, "readiness_state": "high", "tooltip_text": "Fixture current status"})
	presenter.call("_apply_native_a5_fireteam_card", card, "ft1", ["fixture_member_a", "fixture_member_b"], bool(spec.selected), bool(spec.inactive))

func settle() -> void:
	await process_frame
	await process_frame

func connect_notices(node: Node) -> void:
	if node is Control:
		(node as Control).theme_changed.connect(note_notice)
	for child in node.get_children():
		connect_notices(child)

func note_notice() -> void:
	notices += 1

func card_state(card: Control) -> Dictionary:
	var result: Dictionary = {}
	capture(card, card, result)
	return result

func capture(card: Control, node: Node, result: Dictionary) -> void:
	if node is Control:
		var item := node as Control
		var facts: Dictionary = {"identity": item, "visible": item.visible, "position": item.position, "size": item.size, "minimum": item.custom_minimum_size, "h_flags": item.size_flags_horizontal, "tooltip": item.tooltip_text, "metadata": {}, "gui_input": item.gui_input.get_connections()}
		for key in item.get_meta_list():
			facts.metadata[key] = item.get_meta(key)
		if item is Label or item is LineEdit:
			facts.text = item.get("text")
			facts.font = item.get_theme_font("font")
			facts.font_size = item.get_theme_font_size("font_size")
			facts.owns_font_size = item.has_theme_font_size_override("font_size")
			facts.color = item.get_theme_color("font_color")
			facts.owns_color = item.has_theme_color_override("font_color")
		if item is LineEdit:
			facts.uneditable_color = item.get_theme_color("font_uneditable_color")
			facts.normal = item.get_theme_stylebox("normal")
			facts.read_only = item.get_theme_stylebox("read_only")
			facts.owns_read_only = item.has_theme_stylebox_override("read_only")
			facts.submit_callbacks = (item as LineEdit).text_submitted.get_connections()
			facts.blur_callbacks = (item as LineEdit).focus_exited.get_connections()
		if item is PanelContainer:
			facts.panel = item.get_theme_stylebox("panel")
			facts.owns_panel = item.has_theme_stylebox_override("panel")
		if item is MarginContainer:
			for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
				facts[side] = item.get_theme_constant(side)
				facts["owns_" + side] = item.has_theme_constant_override(side)
		if item is BoxContainer:
			facts.separation = item.get_theme_constant("separation")
		if item is TextureRect:
			facts.texture = (item as TextureRect).texture
		if item.has_signal("card_pressed"):
			facts.card_callbacks = item.get_signal_connection_list("card_pressed")
		result[String(card.get_path_to(item))] = facts.duplicate(true)
	for child in node.get_children():
		capture(card, child, result)

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("PASS: " if ok else "FAIL: ", message)
