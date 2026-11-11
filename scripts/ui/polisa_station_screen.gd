extends Control
const SKIN = preload("res://scripts/ui/base_management_skin.gd")
const MENU_ICONS = preload("res://scripts/ui/menu_equipment_icons.gd")
## Read-only station projection. All purchases and equipment use runtime commands.
var _adapter: Node
var _snapshot: Dictionary = {}
var _page := "explore"
var _person := ""
var _signature := ""
var _content: VBoxContainer
var _status: Label
var _refuel_button: Button
var _fuel_label: Label
var _credits: Label
var _catalog: Dictionary = {}

func configure(adapter: Node) -> void:
	_adapter = adapter
	_catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/polisa_station.json"))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.position = Vector2(10, 76)
	panel.custom_minimum_size = Vector2(268, 0)
	SKIN.panel(panel, true)
	add_child(panel)
	var menu := VBoxContainer.new()
	panel.add_child(menu)
	_label(menu, "POLISA / Landestation")
	_credits = _label(menu, "")
	for category: Dictionary in _catalog.get("categories", []):
		_button(menu, String(category.name), _select_page.bind(String(category.id)))
	_fuel_label = _label(menu, "")
	_refuel_button = _button(menu, "Tanken", _request_refuel)
	_button(menu, "Rückflug vorbereiten", _request.bind("return_homebase", {}))
	_status = _label(menu, "")
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var shop := PanelContainer.new()
	shop.name = "Shop"
	shop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	SKIN.panel(shop)
	shop.offset_left = 298
	shop.offset_top = 76
	shop.offset_right = -16
	shop.offset_bottom = -110
	add_child(shop)
	var scroll := ScrollContainer.new()
	shop.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)

func refresh(snapshot: Dictionary) -> void:
	_snapshot = snapshot
	_credits.text = "%d Credits" % int(snapshot.get("credits", 0))
	var quote := refuel_quote(snapshot)
	_fuel_label.text = "Schiff: %s\nTank: %.2f / %.2f" % [String(snapshot.get("craft_name", snapshot.get("craft_id", "-"))), float(snapshot.get("fuel", 0.0)), float(snapshot.get("fuel_capacity", 0.0))]
	_refuel_button.text = "Tanken / +%.2f / %d Cr" % [float(quote.amount), int(quote.cost)] if quote.amount > 0.0 else String(quote.reason)
	_refuel_button.disabled = not quote.allowed
	_refuel_button.tooltip_text = String(quote.reason)
	var signature := JSON.stringify([_page, _person, snapshot])
	if signature == _signature: return
	_signature = signature
	get_node("Shop").visible = _page != "explore"
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	if _page == "explore": return
	_label(_content, "POLISA / " + _category_title(_page))
	if not snapshot.get("service_ready", false):
		_label(_content, "In Polisa landen, um die Station über dieses Menü zu nutzen.")
		return
	if _page == "ship_equipment":
		_label(_content, "Schiffswaffen und Komponenten sind noch nicht verfügbar. Kauf und Einbau folgen mit dem Ausbau der Schiffsausrüstung.")
		return
	if _page == "ships":
		_label(_content, "Lieferung zur Heimatbasis. Ein gebautes freies Heimatpad ist erforderlich.")
		_label(_content, "Ausstattung der gelieferten Schiffe an der Heimatbasis.")
		if snapshot.get("campaign_mode", false):
			_button(_content, "Heimatpad %d bauen / 200 Credits" % (int(snapshot.get("home_pad_count", 2)) + 1), _request.bind("station_build_home_pad", {}), int(snapshot.get("home_pad_count", 2)) >= 6)
	if _page in ["infantry", "armor"]:
		_label(_content, "Kauf ins gelandete Schiffslager. Ausrüstung für deine Personen auf der Station auswählen.")
		var people := OptionButton.new()
		_content.add_child(people)
		for person: Dictionary in snapshot.get("people", []):
			people.add_item(String(person.name))
			people.set_item_metadata(people.item_count - 1, String(person.unit_id))
			if _person.is_empty(): _person = String(person.unit_id)
			if _person == String(person.unit_id): people.select(people.item_count - 1)
		people.visible = people.item_count > 0
		if people.item_count == 0: _label(_content, "Zum Ausrüsten muss eine Person auf der Station sein.")
		people.item_selected.connect(func(index: int): _person = String(people.get_item_metadata(index)); _signature = ""; refresh(_snapshot))
	for offer_id: String in snapshot.get("offers", {}):
		var offer: Dictionary = snapshot.offers[offer_id]
		if String(offer.get("category", "")) != _page: continue
		var card := PanelContainer.new()
		SKIN.panel(card, true)
		_content.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(54, 54)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = MENU_ICONS.get_icon(String(offer.item_id))
		var armor_icon := "res://Assets/curated/ui/campaign_inventory/%s.svg" % String(offer.item_id)
		if String(offer.item_id).begins_with("armor_") and ResourceLoader.exists(armor_icon): icon.texture = load(armor_icon)
		icon.visible = icon.texture != null
		row.add_child(icon)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		var stock := int(Dictionary(snapshot.get("stock", {})).get(offer_id, 0))
		_label(details, String(offer.get("name", offer.item_id)).replace("Ruestung", "Rüstung"))
		_label(details, "%d Cr  ·  Bestand %d  ·  Schiffslager %d" % [int(offer.unit_price), stock, _cargo(String(offer.item_id))])
		var locked: bool = snapshot.get("require_blueprints", false) and not String(offer.get("required_blueprint", "")).is_empty() and not Array(snapshot.get("blueprints", [])).has(String(offer.required_blueprint))
		var ship := String(offer.get("kind", "")) == "ship"
		_button(row, "Bauplan fehlt" if locked else "Kaufen", _request.bind("station_buy_ship" if ship else "buy", {"offer_id":offer_id,"quantity":1}), locked or stock < 1 or int(snapshot.get("credits", 0)) < int(offer.unit_price) or (ship and String(snapshot.get("free_home_pad", "")).is_empty()))
		if _page in ["infantry", "armor"]:
			var item := String(offer.item_id)
			var slot := "armor" if item.begins_with("armor_") else ("backpack" if item == "backpack" else "weapon_1")
			_button(row, "Ausruesten", _request.bind("inventory_equip", {"unit_id":_person,"item_id":item,"slot":slot,"source_container_id":"craft:" + String(snapshot.get("craft_id", ""))}), not _can_equip(item))
	if _page == "commodities":
		_label(_content, "Ankauf aus dem gelandeten Schiffslager / je 1 Einheit")
		for item: String in snapshot.get("buy_orders", {}):
			var price := int(snapshot.buy_orders[item])
			_button(_content, "%s / Lager %d / 1 verkaufen fuer %d Cr" % [item, _cargo(item), price], _request.bind("sell", {"item_id":item,"quantity":1}), _cargo(item) < 1)

static func refuel_quote(snapshot: Dictionary) -> Dictionary:
	var capacity := float(snapshot.get("fuel_capacity", 0.0))
	var fuel := float(snapshot.get("fuel", 0.0))
	var price := float(snapshot.get("fuel_price_per_unit", 0.0))
	var amount := minf(10.0, maxf(0.0, capacity - fuel))
	var cost := int(ceil(amount * price))
	var reason := ""
	if not bool(snapshot.get("service_ready", false)): reason = "Zuerst in Polisa landen"
	elif not bool(snapshot.get("fuel_registered", false)) or String(snapshot.get("craft_id", "")).is_empty(): reason = "Kein registriertes Schiff am Tankservice"
	elif capacity <= 0.0 or price <= 0.0: reason = "Tankservice nicht verfuegbar"
	elif amount <= 0.0: reason = "Tank voll"
	elif int(snapshot.get("credits", 0)) < cost: reason = "Credits reichen nicht"
	return {"amount":amount,"cost":cost,"allowed":reason.is_empty(),"reason":reason}

func _request_refuel() -> void:
	# Re-read the projection at click time; the Supply owner still validates/commits.
	if not is_instance_valid(_adapter) or not _adapter.has_method("get_polisa_snapshot") or not _adapter.has_method("request_operation"):
		_status.text = "Tankservice nicht verfuegbar"
		_refuel_button.disabled = true
		return
	var projection: Variant = _adapter.call("get_polisa_snapshot")
	if not projection is Dictionary:
		_status.text = "Tankservice nicht verfuegbar"
		_refuel_button.disabled = true
		return
	var current: Dictionary = projection
	refresh(current)
	var quote := refuel_quote(current)
	if not quote.allowed:
		_status.text = String(quote.reason)
		return
	_request("refuel", {"amount":float(quote.amount)})

func _cargo(item: String) -> int:
	return int(Dictionary(Dictionary(_snapshot.get("inventory", {})).get("craft:" + String(_snapshot.get("craft_id", "")), {})).get("items", {}).get(item, 0))

func _can_equip(item: String) -> bool:
	for person: Dictionary in _snapshot.get("people", []):
		if person.unit_id == _person: return bool(person.equipment_allowed) and _cargo(item) > 0
	return false

func _select_page(page: String) -> void:
	_page = page
	_signature = ""
	refresh(_snapshot)

func _request(operation: String, payload: Dictionary) -> void:
	var data := payload.duplicate(true)
	data["craft_id"] = String(_snapshot.get("craft_id", ""))
	var result: Dictionary = _adapter.call("request_operation", operation, data)
	_status.text = String(result.get("message", "Vorgang abgeschlossen" if result.get("ok", false) else result.get("reason", "Nicht verfuegbar")))
	_signature = ""
	refresh(_adapter.call("get_polisa_snapshot"))

func _label(parent: Node, value: String) -> Label:
	var label := Label.new()
	label.text = value
	SKIN.label(label, 15)
	parent.add_child(label)
	return label

func _button(parent: Node, value: String, action: Callable, disabled := false) -> Button:
	var button := Button.new()
	button.text = value
	SKIN.button(button)
	button.disabled = disabled
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _category_title(id: String) -> String:
	for category: Dictionary in _catalog.get("categories", []):
		if String(category.id) == id: return String(category.name)
	return id
