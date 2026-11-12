extends VBoxContainer
## Displays projections only; caller validates and owns every purchase.
signal hire_requested(offer_id: String)
const SHEET = preload("res://scripts/meta/character_sheet_view.gd")
const PROFILE = preload("res://scripts/meta/meta_unit_profile.gd")
var _offers: Array = []
var _selected: Dictionary = {}
var _detail_id := ""
var _credits := 0
var _beds := 0
var _roster := 0
var _can_hire := false
var _cards: HFlowContainer
var _warning: Label
var _comparison: HBoxContainer

func show_offers(offers: Array, credits: int, beds: int, roster: int, can_hire: bool) -> void:
	_offers = offers.duplicate(true)
	_credits = credits
	_beds = beds
	_roster = roster
	_can_hire = can_hire
	var valid := {}
	for offer: Dictionary in _offers: valid[String(offer.get("id", ""))] = true
	for id in _selected.keys():
		if not valid.has(id): _selected.erase(id)
	if not valid.has(_detail_id): _detail_id = ""
	_render()

func set_compared(id: String, enabled: bool) -> void:
	if not _has_offer(id): return
	if enabled: _selected[id] = true
	else: _selected.erase(id)
	_render()

func get_card_count() -> int:
	return _cards.get_child_count() if is_instance_valid(_cards) else 0

func get_comparison_count() -> int:
	return _selected.size()

func get_bed_warning() -> String:
	return _warning.text if is_instance_valid(_warning) else ""

func _has_offer(id: String) -> bool:
	for offer: Dictionary in _offers:
		if String(offer.get("id", "")) == id: return true
	return false

func _render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_warning = Label.new()
	_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_warning.text = "Achtung: Für diese Person gibt es noch kein Bett in der Heimatbasis." if _roster + 1 > _beds else ""
	add_child(_warning)
	if not _can_hire:
		var unavailable := Label.new()
		unavailable.text = "Anwerbung derzeit nicht verfügbar."
		add_child(unavailable)
	_cards = HFlowContainer.new()
	_cards.add_theme_constant_override("h_separation", 12)
	add_child(_cards)
	for offer: Dictionary in _offers: _add_card(offer)
	if not _detail_id.is_empty():
		for offer: Dictionary in _offers:
			if String(offer.get("id", "")) == _detail_id:
				_add_sheet(self, offer, "Charakterbogen")
	if not _selected.is_empty():
		var title := Label.new()
		title.text = "Vergleich"
		add_child(title)
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size.y = 450
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		add_child(scroll)
		_comparison = HBoxContainer.new()
		scroll.add_child(_comparison)
		for offer: Dictionary in _offers:
			if _selected.has(String(offer.get("id", ""))): _add_sheet(_comparison, offer, "")

func _add_card(offer: Dictionary) -> void:
	var id := String(offer.get("id", ""))
	var profile: Dictionary = offer.get("profile", {})
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 210
	_cards.add_child(panel)
	var body := VBoxContainer.new()
	panel.add_child(body)
	var portrait_path := String(profile.get("portrait_path", ""))
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(96, 96)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture = load(portrait_path)
		body.add_child(portrait)
	var label := Label.new()
	var skill: Dictionary = profile.get("skill_values", {})
	var platform: Dictionary = profile.get("platform_values", {})
	label.text = "%s\n%s · %s\nTreffer %.2f · Führung %.2f\nFliegen %.2f\n%d Credits" % [String(profile.get("display_name", id)), String(offer.get("role", "")), String(offer.get("experience", "")), float(skill.get("accuracy", 0.0)), float(skill.get("leadership", 0.0)), float(platform.get("dropship_piloting", 0.0)), int(offer.get("price", 0))]
	body.add_child(label)
	var details := Button.new()
	details.text = "Charakterbogen"
	details.pressed.connect(func(): _detail_id = id; _render())
	body.add_child(details)
	var compare := CheckBox.new()
	compare.text = "Vergleichen"
	compare.button_pressed = _selected.has(id)
	compare.toggled.connect(func(enabled: bool): set_compared(id, enabled))
	body.add_child(compare)
	var buy := Button.new()
	buy.text = "Anwerben"
	buy.disabled = not _can_hire or int(offer.get("price", 0)) > _credits
	buy.pressed.connect(func(): hire_requested.emit(id))
	body.add_child(buy)

func _add_sheet(parent: Node, offer: Dictionary, heading: String) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 440
	parent.add_child(column)
	var title := Label.new()
	title.text = heading + (" · " if not heading.is_empty() else "") + String(Dictionary(offer.get("profile", {})).get("display_name", ""))
	column.add_child(title)
	var host := VBoxContainer.new()
	column.add_child(host)
	SHEET.render(host, PROFILE.from_dict(Dictionary(offer.get("profile", {}))), {"editable_metrics":false, "compact_read_only":true, "compact_sheet_width":400})
