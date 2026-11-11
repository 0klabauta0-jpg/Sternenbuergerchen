extends PanelContainer
## The panel edits a proposal. Purchases and roster changes use the runtime bridge.
const CATALOG = preload("res://scripts/meta/skirmish_points_catalog.gd")
const PORTRAITS = preload("res://scripts/meta/portrait_identity_catalog.gd")
const SKIN = preload("res://scripts/ui/base_management_skin.gd")

var _provider: Callable
var _command: Callable
var _elapsed := 0.0
var _economy: Dictionary = {}
var _recruits: Array = []
var _recruit_signature := ""
var _crew_signature := ""
var _points: Label
var _feedback: Label
var _candidate: OptionButton
var _portrait: TextureRect
var _identity: Label
var _role: OptionButton
var _experience: OptionButton
var _armor: OptionButton
var _weapon: OptionButton
var _buy_person: Button
var _crew: ItemList
var _dismiss: Button
var _equip: Button
var _purchases: Array[Dictionary] = []


func configure(provider: Callable, command: Callable) -> void:
	_provider = provider
	_command = command


func _ready() -> void:
	SKIN.panel(self)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	add_child(content)
	_points = _label("", 23)
	_points.name = "SkirmishPoints"
	content.add_child(_points)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 18)
	content.add_child(tabs)
	var personnel := _page(tabs, "Personal")
	_candidate = OptionButton.new()
	_candidate.name = "RecruitCandidate"
	_candidate.add_theme_font_size_override("font_size", 19)
	personnel.add_child(_candidate)
	_candidate.item_selected.connect(_select_candidate)
	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 12)
	personnel.add_child(identity_row)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(116, 164)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	identity_row.add_child(_portrait)
	_identity = _label("", 18)
	_identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_row.add_child(_identity)
	_role = _selector(personnel, "Rolle", CATALOG.ROLES)
	_experience = _selector(personnel, "Erfahrung", CATALOG.EXPERIENCE)
	_armor = _selector(personnel, "Rüstung", CATALOG.ARMOR)
	_weapon = _selector(personnel, "Waffe", CATALOG.WEAPONS)
	_buy_person = _button(personnel, "", _buy_recruit)
	_buy_person.name = "BuyRecruit"
	personnel.add_child(_label("Dein Personal", 20))
	_crew = ItemList.new()
	_crew.name = "PurchasedPersonnel"
	_crew.custom_minimum_size.y = 135
	_crew.add_theme_font_size_override("font_size", 18)
	personnel.add_child(_crew)
	_crew.item_selected.connect(func(_index: int): _update_actions())
	_equip = _button(personnel, "Ausrüsten", _open_equipment)
	_dismiss = _button(personnel, "", _dismiss_person)
	var build := _page(tabs, "Bauen")
	build.add_child(_label("Baue auf den markierten Flächen. Das Habitat enthält zwei Betten. Feldbetten ergänzen das Lager.", 18))
	for id: String in CATALOG.BUILDINGS:
		_purchase_button(build, "build", id, CATALOG.BUILDINGS[id])
	var ships := _page(tabs, "Schiffe")
	ships.add_child(_label("Jedes Schiff benötigt einen eigenen Landeplatz. Piloten weist du anschließend im Flugdeck zu.", 18))
	for id: String in CATALOG.SHIPS:
		_purchase_button(ships, "ship", id, CATALOG.SHIPS[id])
	var equipment := _page(tabs, "Lager")
	equipment.add_child(_label("Käufe kommen ins Basislager. Wähle unter Personal eine Person und öffne Ausrüsten.", 18))
	for id: String in CATALOG.EQUIPMENT:
		_purchase_button(equipment, "equipment", id, CATALOG.EQUIPMENT[id])
	_feedback = _label("", 17)
	_feedback.name = "PurchaseFeedback"
	content.add_child(_feedback)
	refresh()


func _page(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	return content


func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _selector(parent: Control, caption: String, entries: Dictionary) -> OptionButton:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := _label(caption, 18)
	label.custom_minimum_size.x = 110
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(label)
	var options := OptionButton.new()
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_theme_font_size_override("font_size", 18)
	for id in entries:
		options.add_item(entries[id].label)
		options.set_item_metadata(options.item_count - 1, id)
	row.add_child(options)
	options.item_selected.connect(func(_index: int): _update_actions())
	return options


func _purchase_button(parent: Control, operation: String, id: String, entry: Dictionary) -> void:
	var button := _button(parent, "%s · %d P" % [entry.label, int(entry.cost)],
		func(): _request("skirmish_" + operation, {"item_id": id}))
	button.name = "Purchase_" + id
	_purchases.append({"button": button, "cost": int(entry.cost), "operation": operation, "item_id": id})


func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_elapsed += delta
	if _elapsed >= 0.3:
		_elapsed = 0.0
		refresh()


func refresh() -> void:
	if not is_node_ready() or not _provider.is_valid(): return
	var snapshot: Dictionary = _provider.call()
	_economy = snapshot.get("skirmish_economy", {})
	if _economy.is_empty(): return
	_points.text = "%d / %d Punkte frei" % [int(_economy.remaining), int(_economy.budget)]
	_recruits = _economy.get("recruits", [])
	var signature := String(_economy.next_person_id)
	if signature != _recruit_signature:
		_recruit_signature = signature
		_candidate.clear()
		for entry: Dictionary in _recruits:
			_candidate.add_item(String(entry.profile.display_name))
		_select_candidate(0)
	var people: Array = snapshot.get("base_personnel", {}).get("units", [])
	signature = JSON.stringify(people.map(func(person: Dictionary): return [person.unit_id, person.name]))
	if signature != _crew_signature:
		_crew_signature = signature
		var selected := _selected_person()
		_crew.clear()
		for person: Dictionary in people:
			_crew.add_item(String(person.name))
			var index := _crew.item_count - 1
			_crew.set_item_metadata(index, String(person.unit_id))
			if String(person.unit_id) == selected: _crew.select(index)
	_update_actions()


func _select_candidate(index: int) -> void:
	if index < 0 or index >= _recruits.size(): return
	_candidate.select(index)
	var entry: Dictionary = _recruits[index]
	var profile: Dictionary = entry.profile
	_portrait.texture = PORTRAITS.load_texture(String(profile.portrait_id), String(profile.portrait_path))
	_identity.text = String(profile.display_name)
	for pair: Array in [[_role, "role"], [_experience, "experience"], [_armor, "armor"], [_weapon, "weapon"]]:
		var selector: OptionButton = pair[0]
		for item_index in range(selector.item_count):
			if selector.get_item_metadata(item_index) == entry.configuration[pair[1]]:
				selector.select(item_index)
	_update_actions()


func _configuration() -> Dictionary:
	return {"role": _role.get_item_metadata(_role.selected), "experience": _experience.get_item_metadata(_experience.selected),
		"armor": _armor.get_item_metadata(_armor.selected), "weapon": _weapon.get_item_metadata(_weapon.selected),
		"candidate_index": _candidate.selected}


func _selected_person() -> String:
	var indices := _crew.get_selected_items() if _crew != null else PackedInt32Array()
	return String(_crew.get_item_metadata(indices[0])) if not indices.is_empty() else ""


func _update_actions() -> void:
	if _economy.is_empty() or _role == null: return
	var price := CATALOG.get_person_cost(_configuration())
	_buy_person.text = "Rekrutieren · %d P inkl. Ausrüstung" % price
	_buy_person.disabled = price < 0 or price > int(_economy.remaining)
	var id := _selected_person()
	var refund := int(_economy.person_refunds.get(id, 0))
	_dismiss.text = "Entlassen · %d P zurück" % refund
	_dismiss.tooltip_text = "Personalpreis zurück. Getragene und mitgeführte Ausrüstung wird ins Basislager übernommen."
	_dismiss.disabled = refund == 0
	_equip.disabled = id.is_empty()
	for entry: Dictionary in _purchases:
		var disabled: bool = entry.cost > int(_economy.remaining)
		if entry.operation == "build":
			var key := "pads" if entry.item_id == "pad" else String(entry.item_id)
			disabled = disabled or int(_economy.infrastructure.get(key, 0)) >= int(CATALOG.BUILDINGS[entry.item_id].limit)
		entry.button.disabled = disabled


func _request(operation: String, payload: Dictionary) -> void:
	if not _command.is_valid(): return
	var result: Dictionary = _command.call(operation, payload)
	_feedback.text = String(result.get("message", result.get("reason", "")))
	refresh()


func _buy_recruit() -> void:
	_request("skirmish_person", _configuration())


func _dismiss_person() -> void:
	_request("skirmish_dismiss", {"unit_id": _selected_person()})


func _open_equipment() -> void:
	_command.call("focus_unit", {"unit_id": _selected_person()})
	_command.call("navigate", {"mode": "squad"})
