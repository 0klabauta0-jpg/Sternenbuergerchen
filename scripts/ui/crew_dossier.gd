extends Window
## Snapshot presentation only. Every inventory change goes through the host.
signal action_requested(action: String, payload: Dictionary)
const Catalog = preload("res://scripts/core/catalog.gd")
const Gear = preload("res://scripts/core/equipment_catalog.gd")
const Slot = preload("res://scripts/ui/equipment_slot.gd")
const Doll = preload("res://scripts/ui/crew_paperdoll.gd")
const Icons = preload("res://scripts/ui/hud_icons.gd")
const SLOT_NAMES: Dictionary = {"helmet":"HELM", "armor":"RÜSTUNG", "tool":"WERKZEUG", "attachment":"AUFSATZ", "backpack":"RUCKSACK"}
const CONTAINER_NAMES: Dictionary = {"inventory":"BASISLAGER", "cargo":"SCHIFFSFRACHT", "backpack":"RUCKSACK"}
var _state: Dictionary = {}
var _unit_id: String = "ida"
var _heading: Label
var _profile: Label
var _feedback: Label
var _amount: SpinBox
var _doll: SubViewportContainer
var _slots: Dictionary = {}
var _rows: Dictionary = {}
var _lists: Dictionary = {}
var _headers: Dictionary = {}
var _heal: Button
var _heal_target: OptionButton
var _refresh_pending: bool = false

func _ready() -> void:
	title = "Crew-Dossier"
	size = Vector2i(1120, 720)
	min_size = Vector2i(940, 620)
	visible = false
	close_requested.connect(close)
	window_input.connect(func(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE: close())
	var backdrop := PanelContainer.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101d27")
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	backdrop.add_theme_stylebox_override("panel", style)
	add_child(backdrop)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	backdrop.add_child(column)
	var bar := HBoxContainer.new()
	column.add_child(bar)
	_heading = Label.new()
	_heading.add_theme_font_size_override("font_size", 25)
	_heading.add_theme_color_override("font_color", Color("efab6f"))
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_heading)
	var dismiss := Button.new()
	dismiss.text = "Schließen ×"
	dismiss.pressed.connect(close)
	bar.add_child(dismiss)
	_profile = Label.new()
	column.add_child(_profile)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	column.add_child(body)
	var paper := VBoxContainer.new()
	paper.custom_minimum_size.x = 310
	body.add_child(paper)
	_doll = Doll.new()
	_doll.custom_minimum_size = Vector2(280, 280)
	_doll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	paper.add_child(_doll)
	var slot_grid := GridContainer.new()
	slot_grid.columns = 2
	paper.add_child(slot_grid)
	for slot: String in SLOT_NAMES:
		var button: Button = _make_target({"to":"equipment", "slot":slot})
		button.custom_minimum_size = Vector2(151, 57)
		button.add_theme_font_size_override("font_size", 13)
		slot_grid.add_child(button)
		_slots[slot] = button
	var stores := HBoxContainer.new()
	stores.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stores.add_theme_constant_override("separation", 10)
	body.add_child(stores)
	for container: String in CONTAINER_NAMES:
		var panel := VBoxContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.custom_minimum_size.x = 190
		stores.add_child(panel)
		var header := Label.new()
		header.add_theme_color_override("font_color", Color("86c5c2"))
		panel.add_child(header)
		_headers[container] = header
		var drop: Button = _make_target({"to":container})
		drop.text = "Hier ablegen ↓"
		drop.tooltip_text = "Basislager: Figur muss in 8 m Nähe sein." if container == "inventory" else "Fracht: Am Zugang in 8 m Nähe oder an Bord. Direktes Lager-Umladen nur am Heimatdock." if container == "cargo" else "Persönlicher Rucksack. Jeder Gegenstand belegt einen Platz."
		drop.custom_minimum_size.y = 44
		panel.add_child(drop)
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		panel.add_child(scroll)
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(list)
		_lists[container] = list
	var controls := HBoxContainer.new()
	column.add_child(controls)
	var amount_label := Label.new()
	amount_label.text = "Menge beim Ziehen"
	controls.add_child(amount_label)
	_amount = SpinBox.new()
	_amount.min_value = 1
	_amount.max_value = 99
	_amount.value = 1
	controls.add_child(_amount)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(spacer)
	_heal_target = OptionButton.new()
	controls.add_child(_heal_target)
	_heal = Button.new()
	_heal.text = "Medgun anwenden · 1 Ladung"
	_heal.pressed.connect(_request_heal)
	controls.add_child(_heal)
	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.custom_minimum_size.y = 44
	_feedback.text = "Gegenstand auf einen passenden Platz ziehen. Bestände ändern sich erst nach Bestätigung."
	column.add_child(_feedback)
	_refresh()

func present(state: Dictionary, unit_id: String = "") -> void:
	_state = state.duplicate(true)
	if not unit_id.is_empty(): _unit_id = unit_id
	if not is_node_ready(): return
	if gui_is_dragging():
		_refresh_pending = true
	else:
		_refresh()

func _process(_delta: float) -> void:
	if _refresh_pending and not gui_is_dragging():
		_refresh_pending = false
		_refresh()

func open_for(unit_id: String) -> void:
	_unit_id = unit_id
	if not is_node_ready(): return
	_refresh()
	popup_centered(size)

func close() -> void:
	hide()

func present_result(result: Dictionary) -> void:
	if not visible or _feedback == null: return
	if result.get("pending", false):
		_feedback.text = "Warte auf Host …"
		_feedback.add_theme_color_override("font_color", Color("efab6f"))
		return
	_feedback.text = "Bestätigt." if result.get("ok", false) else str(result.get("reason", "Aktion abgelehnt."))
	_feedback.add_theme_color_override("font_color", Color("86c5c2") if result.get("ok", false) else Color("f0ab86"))

func _make_target(target: Dictionary) -> Button:
	var button: Button = Slot.new()
	button.target = target
	button.accept = _rejection
	button.amount = func() -> int: return int(_amount.value) if _amount != null else 1
	button.dropped.connect(_drop)
	button.rejected.connect(func(reason: String) -> void: _feedback.text = reason)
	return button

func _items(container: String) -> Dictionary:
	if container == "backpack": return _crew().get("backpack", {}).get("items", {})
	return _state.get(container, {})

func _crew() -> Dictionary:
	return _state.get("crew", {}).get(_unit_id, {})

func _name(item: String) -> String:
	return "Standardhelm" if item == "basic_helmet" else Catalog.item_name(item)

func _refresh() -> void:
	var crew: Dictionary = _crew()
	_heading.text = str(crew.get("name", _unit_id)) + " / CREW-DOSSIER"
	var skills: Dictionary = crew.get("skills", {})
	_profile.text = "Gesundheit %s / 100     Pilot %s · Geschütz %s · Technik %s" % [crew.get("health", "–"), skills.get("pilot", "–"), skills.get("gunnery", "–"), skills.get("tech", "–")]
	var equipment: Dictionary = crew.get("equipment", {})
	_doll.present(equipment)
	for slot: String in _slots:
		var button: Button = _slots[slot]
		var item: String = str(equipment.get(slot, ""))
		button.text = SLOT_NAMES[slot] + "\n" + (_name(item) if not item.is_empty() else "Frei")
		button.icon = Icons.texture(slot if slot in ["armor", "helmet"] else "toolkit" if slot == "tool" else "storage")
		button.source = {"from":"equipment", "slot":slot, "item":item, "available":1, "unit_id":_unit_id} if not item.is_empty() and item != "basic_helmet" else {}
		button.tooltip_text = "Standardhelm ist nicht handelbar." if item == "basic_helmet" else button.text
	for container: String in CONTAINER_NAMES:
		var items: Dictionary = _items(container)
		var used: int = 0
		for count: Variant in items.values(): used += int(count)
		var capacity: String = "ohne Mengenlimit" if container == "inventory" else "%s / %s Plätze" % [used, crew.get("backpack", {}).get("capacity", 0) if container == "backpack" else _state.get("ship", {}).get("capacity", 0)]
		_headers[container].text = CONTAINER_NAMES[container] + "\n" + capacity
		for item: String in Catalog.ITEMS:
			var key: String = container + ":" + item
			var quantity: int = int(items.get(item, 0))
			if quantity <= 0:
				if _rows.has(key): _rows[key].hide()
				continue
			if not _rows.has(key):
				var row: Button = _make_target({"to":container})
				_lists[container].add_child(row)
				_rows[key] = row
			var button: Button = _rows[key]
			button.show()
			button.text = _name(item) + "\n× " + str(quantity)
			button.source = {"from":container, "item":item, "available":quantity, "unit_id":_unit_id}
			button.tooltip_text = "Ziehen: " + _name(item)
	var target_id: String = str(_heal_target.get_item_metadata(_heal_target.selected)) if _heal_target.selected >= 0 else ""
	_heal_target.clear()
	for id: String in _state.get("crew", {}):
		_heal_target.add_item(str(_state.crew[id].name))
		_heal_target.set_item_metadata(_heal_target.item_count - 1, id)
		if id == target_id: _heal_target.select(_heal_target.item_count - 1)
	_heal.disabled = equipment.get("tool", "") != "medgun" or int(_items("backpack").get("med_charge", 0)) < 1 or float(crew.get("health", 0)) <= 0 or crew.get("assignment", "") != "idle" or _state.get("ship", {}).get("mode", "") != "landed"
	_heal.tooltip_text = "Freie, gesunde Figur an Land mit angelegter Medgun. Ziel innerhalb 6 m und in freier Sicht: +35 Gesundheit oder Wiederbelebung mit 35 Gesundheit. Verbraucht 1 Ladung aus dem eigenen Rucksack."

func _rejection(data: Dictionary, target: Dictionary) -> String:
	if data.get("unit_id") != _unit_id: return "Bitte das Dossier dieser Figur öffnen."
	if _state.get("paused", false): return "Das Spiel ist pausiert."
	var from: String = str(data.get("from", ""))
	var to: String = str(target.get("to", ""))
	if from == to: return "Gegenstand liegt bereits hier."
	if to == "equipment":
		if Gear.slot_for(str(data.get("item", ""))) != target.get("slot"): return "Dieser Gegenstand passt nicht in den Platz."
		if target.get("slot") == "attachment" and _crew().get("equipment", {}).get("tool") != "multitool": return "Zuerst ein Multi-Tool ausrüsten."
	elif not to in CONTAINER_NAMES: return "Kein Ablageziel."
	if to == "backpack" and int(_crew().get("backpack", {}).get("capacity", 0)) == 0: return "Zuerst einen Rucksack kaufen oder fertigen und ausrüsten."
	if from != "equipment" and to != "equipment" and from != "backpack" and to != "backpack" and _state.get("region") != "base": return "Direktes Umladen zwischen Lager und Fracht ist nur am Heimatdock möglich."
	return ""

func _drop(data: Dictionary, target: Dictionary) -> void:
	var reason: String = _rejection(data, target)
	if not reason.is_empty():
		_feedback.text = reason
		return
	var payload: Dictionary = {"unit_id":_unit_id}
	var action: String
	if target.to == "equipment":
		action = "equip_item"
		payload.merge({"slot":target.slot, "item":data.item, "source":data.from})
	elif data.from == "equipment":
		action = "unequip_item"
		payload.merge({"slot":data.slot, "destination":target.to})
	elif data.from != "backpack" and target.to != "backpack":
		action = "transfer"
		payload = {"item":data.item, "amount":data.amount, "direction":"load" if target.to == "cargo" else "unload"}
	else:
		action = "backpack_transfer"
		payload.merge({"item":data.item, "amount":data.amount, "source":data.from, "destination":target.to})
	_feedback.text = "Anfrage gesendet …"
	action_requested.emit(action, payload)

func _request_heal() -> void:
	if _heal_target.selected < 0: return
	action_requested.emit("use_medgun", {"unit_id":_unit_id, "target_id":_heal_target.get_item_metadata(_heal_target.selected)})
