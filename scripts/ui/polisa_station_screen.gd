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
var _craft_picker: OptionButton
var _credits: Label
var _catalog: Dictionary = {}
var _armor_images: Dictionary = {}

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
	_craft_picker = OptionButton.new()
	menu.add_child(_craft_picker)
	_craft_picker.item_selected.connect(func(index: int):
		var craft_id := String(_craft_picker.get_item_metadata(index))
		var result: Dictionary = _adapter.call("request_operation", "select_location_view_craft", {"location_id":"polisa", "craft_id":craft_id})
		_status.text = String(result.get("message", "Schiff ausgewählt" if result.get("ok", false) else "Auswahl nicht verfügbar"))
		refresh(_adapter.call("get_polisa_snapshot")))
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
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)

func refresh(snapshot: Dictionary) -> void:
	_snapshot = snapshot
	_craft_picker.clear()
	_craft_picker.add_item("Serviceschiff auswählen")
	_craft_picker.set_item_metadata(0, "")
	for craft: Dictionary in snapshot.get("local_crafts", []):
		_craft_picker.add_item(String(craft.get("name", craft.craft_id)))
		_craft_picker.set_item_metadata(_craft_picker.item_count - 1, String(craft.craft_id))
		if String(craft.craft_id) == String(snapshot.get("craft_id", "")): _craft_picker.select(_craft_picker.item_count - 1)
	_craft_picker.disabled = _craft_picker.item_count < 2
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
		_label(_content, "Serviceschiff auswählen" if snapshot.get("selection_required", false) else "In Polisa landen, um die Station über dieses Menü zu nutzen.")
		return
	if _page == "ship_equipment":
		_label(_content, "Schiffswaffen und Komponenten sind noch nicht verfügbar. Kauf und Einbau folgen mit dem Ausbau der Schiffsausrüstung.")
		return
	_label(_content, "Schiffslager: %s / %d Einheiten" % [String(snapshot.get("craft_name", snapshot.get("craft_id", "-"))), _cargo_total()])
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
	var products := HFlowContainer.new()
	products.name = "Products"
	products.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	products.add_theme_constant_override("h_separation", 12)
	products.add_theme_constant_override("v_separation", 12)
	_content.add_child(products)
	for offer_id: String in snapshot.get("offers", {}):
		var offer: Dictionary = snapshot.offers[offer_id]
		if String(offer.get("category", "")) != _page: continue
		var card := PanelContainer.new()
		card.name = "Product_" + offer_id
		card.custom_minimum_size.x = 236
		card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		SKIN.panel(card, true)
		products.add_child(card)
		var details := VBoxContainer.new()
		details.custom_minimum_size.x = 216
		details.add_theme_constant_override("separation", 8)
		card.add_child(details)
		var icon := TextureRect.new()
		var item := String(offer.item_id)
		var armor_image := _armor_illustration(item)
		icon.custom_minimum_size = Vector2(0, 236 if armor_image != null else 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = armor_image if armor_image != null else MENU_ICONS.get_icon(item)
		icon.tooltip_text = "Rüstung / 2D-Illustration" if armor_image != null else ""
		icon.visible = icon.texture != null
		details.add_child(icon)
		var stock := int(Dictionary(snapshot.get("stock", {})).get(offer_id, 0))
		var title := _label(details, String(offer.get("name", offer.item_id)).replace("Ruestung", "Rüstung"))
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		SKIN.label(title, 18)
		_label(details, "%d Cr" % int(offer.unit_price))
		_label(details, "Bestand %d / Schiffslager %d" % [stock, _cargo(item)])
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 8)
		details.add_child(actions)
		var locked: bool = snapshot.get("require_blueprints", false) and not String(offer.get("required_blueprint", "")).is_empty() and not Array(snapshot.get("blueprints", [])).has(String(offer.required_blueprint))
		var ship := String(offer.get("kind", "")) == "ship"
		var buy := _button(actions, "Bauplan fehlt" if locked else "Kaufen", _request.bind("station_buy_ship" if ship else "buy", {"craft_id":String(snapshot.get("craft_id", "")),"offer_id":offer_id,"quantity":1}), locked or stock < 1 or int(snapshot.get("credits", 0)) < int(offer.unit_price) or (ship and String(snapshot.get("free_home_pad", "")).is_empty()))
		buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if _page in ["infantry", "armor"]:
			var slot := "armor" if item.begins_with("armor_") else ("backpack" if item == "backpack" else "weapon_1")
			var equip := _button(actions, "Ausrüsten", _request.bind("inventory_equip", {"craft_id":String(snapshot.get("craft_id", "")),"unit_id":_person,"item_id":item,"slot":slot,"source_container_id":"craft:" + String(snapshot.get("craft_id", ""))}), not _can_equip(item))
			equip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _page == "commodities":
		_label(_content, "Ankauf aus dem gelandeten Schiffslager / je 1 Einheit")
		for item: String in snapshot.get("buy_orders", {}):
			var price := int(snapshot.buy_orders[item])
			_button(_content, "%s / Lager %d / 1 verkaufen fuer %d Cr" % [item, _cargo(item), price], _request.bind("sell", {"craft_id":String(_snapshot.get("craft_id", "")),"item_id":item,"quantity":1}), _cargo(item) < 1)

static func refuel_quote(snapshot: Dictionary) -> Dictionary:
	var capacity := float(snapshot.get("fuel_capacity", 0.0))
	var fuel := float(snapshot.get("fuel", 0.0))
	var price := float(snapshot.get("fuel_price_per_unit", 0.0))
	var amount := minf(10.0, maxf(0.0, capacity - fuel))
	var cost := int(ceil(amount * price))
	var reason := ""
	if not bool(snapshot.get("service_ready", false)): reason = "Serviceschiff auswählen" if snapshot.get("selection_required", false) else "Zuerst in Polisa landen"
	elif not bool(snapshot.get("fuel_registered", false)) or String(snapshot.get("craft_id", "")).is_empty(): reason = "Kein registriertes Schiff am Tankservice"
	elif capacity <= 0.0 or price <= 0.0: reason = "Tankservice nicht verfuegbar"
	elif amount <= 0.0: reason = "Tank voll"
	elif int(snapshot.get("credits", 0)) < cost: reason = "Credits reichen nicht"
	return {"amount":amount,"cost":cost,"allowed":reason.is_empty(),"reason":reason}

func _armor_illustration(item: String) -> Texture2D:
	if item not in ["armor_light", "armor_medium", "armor_heavy"]: return null
	if _armor_images.has(item): return _armor_images[item]
	var path := "res://Assets/curated/ui/polisa_armor/%s_turnaround.png" % item.trim_prefix("armor_")
	if not ResourceLoader.exists(path): return null
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path)
	# Original target sheets remain intact. Display only the complete front figure,
	# including helmet/boots, without neighbouring views or turnaround labels.
	atlas.region = Rect2(55, 20, 395, 790)
	atlas.filter_clip = true
	_armor_images[item] = atlas
	return atlas

func _cargo_total() -> int:
	var items: Dictionary = Dictionary(Dictionary(_snapshot.get("inventory", {})).get("craft:" + String(_snapshot.get("craft_id", "")), {})).get("items", {})
	var total := 0
	for quantity: Variant in items.values(): total += int(quantity)
	return total

func _request_refuel() -> void:
	# Re-read the projection at click time; the Supply owner still validates/commits.
	if not is_instance_valid(_adapter) or not _adapter.has_method("get_polisa_snapshot") or not _adapter.has_method("request_operation"):
		_status.text = "Tankservice nicht verfuegbar"
		_refuel_button.disabled = true
		return
	var expected_craft := String(_snapshot.get("craft_id", ""))
	var projection: Variant = _adapter.call("get_polisa_snapshot")
	if not projection is Dictionary:
		_status.text = "Tankservice nicht verfuegbar"
		_refuel_button.disabled = true
		return
	var current: Dictionary = projection
	refresh(current)
	if String(current.get("craft_id", "")) != expected_craft:
		_status.text = "Schiffsauswahl geändert; Tankmenge erneut prüfen"
		return
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
	if not data.has("craft_id"): data["craft_id"] = String(_snapshot.get("craft_id", ""))
	data["service_location_id"] = "polisa"
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
