extends Control
const SKIN = preload("res://scripts/ui/base_management_skin.gd")
const MENU_ICONS = preload("res://scripts/ui/menu_equipment_icons.gd")
const CARGO_LIFT_FEEDBACK = preload("res://scripts/ui/polisa_cargo_lift_feedback.gd")
const CAMPAIGN_HELP = preload("res://scripts/ui/campaign_context_help.gd")
const RECRUIT_VIEW = preload("res://scripts/ui/polisa_recruitment_view.gd")
## Read-only station projection. All purchases and equipment use runtime commands.
var _adapter: Node
var _snapshot: Dictionary = {}
var _page := "explore"
var _delivery_mode := "homebase"
var _crew_source := ""
var _crew_pilot := ""
var _crew_take_team := true
var _person := ""
var _signature := ""
var _content: VBoxContainer
var _status: Label
var _refuel_button: Button
var _cancel_shuttle: Button
var _fuel_label: Label
var _craft_picker: OptionButton
var _credits: Label
var _catalog: Dictionary = {}
var _armor_images: Dictionary = {}
var _cargo_lift: Control
var _campaign_help: Control
var _cargo_source := "station:polisa:lift"
var _cargo_target := ""

func configure(adapter: Node) -> void:
	_adapter = adapter
	_catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/polisa_station.json"))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_campaign_help = CAMPAIGN_HELP.new()
	_campaign_help.name = "CampaignContextHelp"
	_campaign_help.z_index = 100
	add_child(_campaign_help)
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
		var category_button := _button(menu, String(category.name), _select_page.bind(String(category.id)))
		_campaign_help.call("bind_target", category_button, _campaign_help.call("category_help_id", String(category.id)))
	_button(menu, "Frachttransfer", _select_page.bind("cargo_transfer"))
	_fuel_label = _label(menu, "")
	_refuel_button = _button(menu, "Tanken", _request_refuel)
	_campaign_help.call("bind_target", _refuel_button, "polisa.fuel")
	_button(menu, "Rückflug vorbereiten", _request.bind("return_homebase", {}))
	_cancel_shuttle = _button(menu, "Shuttlefahrt abbrechen", _request.bind("station_shuttle_cancel", {}))
	_status = _label(menu, "")
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cargo_lift = CARGO_LIFT_FEEDBACK.new()
	menu.add_child(_cargo_lift)
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
	var dispatch: Dictionary = snapshot.get("service_dispatch", {})
	_cancel_shuttle.visible = String(dispatch.get("phase", "")) in ["pilot_pending", "walk_pending", "approaching"] and String(dispatch.get("source_craft_id", "")) == String(snapshot.get("craft_id", ""))
	_connect_globe()
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
	var signature := JSON.stringify([_page, _person, _delivery_mode, _crew_source, _crew_pilot, _crew_take_team, snapshot])
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
	if _page == "recruitment":
		_show_recruitment()
		return
	if _page == "cargo_transfer":
		_show_cargo_transfer(snapshot)
		return
	if _page == "ship_equipment":
		_show_warp_equipment(snapshot)
		return
	_label(_content, "Schiffslager: %s / %d Einheiten" % [String(snapshot.get("craft_name", snapshot.get("craft_id", "-"))), _cargo_total()])
	if _page == "ships":
		_label(_content, "Ein freies Heimatpad wird reserviert.")
		var delivery := OptionButton.new()
		delivery.add_item("Zur Heimatbasis liefern")
		delivery.add_item("Hier auf Polisa übernehmen (unbemannt)")
		delivery.set_item_disabled(1, not bool(snapshot.get("local_pickup_available", false)))
		delivery.select(1 if _delivery_mode == "local" else 0)
		_content.add_child(delivery)
		delivery.item_selected.connect(func(index: int): _delivery_mode = "local" if index == 1 else "homebase"; _signature = ""; refresh(_snapshot))
		if _delivery_mode == "local": _label(_content, "Unbemannt · Pilot und Besatzung noch zuweisen")
		if not snapshot.get("local_pickup_available", false): _label(_content, String(snapshot.get("local_pickup_reason", "Lokale Ausgabe noch nicht verfügbar")))
		if snapshot.get("campaign_mode", false):
			_button(_content, "Heimatpad %d bauen / 200 Credits" % (int(snapshot.get("home_pad_count", 2)) + 1), _request.bind("station_build_home_pad", {}), int(snapshot.get("home_pad_count", 2)) >= 6)
	if _page == "ships": _show_crew_handoff(snapshot)
	if _page in ["infantry", "armor"]:
		_label(_content, "Kaufziel: gelandetes Schiffslager")
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
		var buy_payload := {"craft_id":String(snapshot.get("craft_id", "")),"offer_id":offer_id,"quantity":1}
		if ship: buy_payload["delivery_mode"] = _delivery_mode
		var buy := _button(actions, "Bauplan fehlt" if locked else ("Auf Polisa übernehmen" if ship and _delivery_mode == "local" else "Kaufen"), _request.bind("station_buy_ship" if ship else "buy", buy_payload), locked or stock < 1 or int(snapshot.get("credits", 0)) < int(offer.unit_price) or (ship and (String(snapshot.get("free_home_pad", "")).is_empty() or (_delivery_mode == "local" and not bool(snapshot.get("local_pickup_available", false))))))
		buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if _page in ["infantry", "armor"]:
			var slot := "armor" if item.begins_with("armor_") else ("backpack" if item == "backpack" else "weapon_1")
			var equip := _button(actions, "Ausrüsten", _request.bind("inventory_equip", {"craft_id":String(snapshot.get("craft_id", "")),"unit_id":_person,"item_id":item,"slot":slot,"source_container_id":"craft:" + String(snapshot.get("craft_id", ""))}), not _can_equip(item))
			equip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _page == "commodities":
		_label(_content, "Verkauf aus dem Schiffslager · je 1")
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

func _show_cargo_transfer(snapshot:Dictionary)->void:
	var craft:=String(snapshot.get("craft_id",""))
	if _cargo_target.is_empty():_cargo_target="craft:"+craft
	var containers:Array=[{"id":"station:polisa:lift","name":"Frachtaufzug"}]
	for item:Dictionary in snapshot.get("local_crafts",[]):
		containers.append({"id":"craft:"+String(item.craft_id),"name":String(item.get("name",item.craft_id))})
	var inventory:Dictionary=snapshot.get("inventory",{})
	for key in ["source","target"]:
		var selector:=OptionButton.new()
		_content.add_child(_label_control("Von" if key=="source" else "Nach"))
		_content.add_child(selector)
		var chosen:=_cargo_source if key=="source" else _cargo_target
		for item:Dictionary in containers:
			var stored:Dictionary=inventory.get(item.id,{})
			selector.add_item("%s (%d/%d)"%[item.name,_container_count(stored),int(stored.get("capacity",0))])
			selector.set_item_metadata(selector.item_count-1,item.id)
			if item.id==chosen:selector.select(selector.item_count-1)
		selector.item_selected.connect(func(index:int):
			if key=="source":_cargo_source=String(selector.get_item_metadata(index))
			else:_cargo_target=String(selector.get_item_metadata(index)))
	var job:Dictionary=snapshot.get("cargo_transfer",{})
	var phase:=String(job.get("phase","idle"))
	var phases:Dictionary={"idle":"Bereit","active":"Transport läuft","blocked":"Angehalten","complete":"Abgeschlossen","cancelled":"Abgebrochen"}
	_label(_content,"%s · %d / %d"%[String(phases.get(phase,phase)),int(job.get("completed",0)),int(job.get("total",0))])
	if phase=="blocked":
		var reasons:Dictionary={"container_full":"Ziel ist voll","insufficient_items":"Ware an der Quelle fehlt","cargo_ship_unavailable":"Schiff ist nicht mehr auf der Station","cargo_context_unavailable":"Transportweg nicht verfügbar"}
		_label(_content,"Grund: "+String(reasons.get(String(job.get("reason","")),"Transportweg oder Ware nicht mehr verfügbar")))
	_button(_content,"Alles automatisch transportieren",func():_request("cargo_transfer_all",{"source_container_id":_cargo_source,"destination_container_id":_cargo_target}),phase in ["active","blocked"])
	_button(_content,"Frachtauftrag abbrechen",func():_request("cargo_transfer_cancel",{}),phase not in ["active","blocked"])

func _label_control(value:String)->Label:
	var label:=Label.new();label.text=value;SKIN.label(label,15);return label

func _container_count(container:Dictionary)->int:
	var total:=0
	for amount in Dictionary(container.get("items",{})).values():total+=int(amount)
	return total

func _request(operation: String, payload: Dictionary) -> void:
	var data := payload.duplicate(true)
	if not data.has("craft_id"): data["craft_id"] = String(_snapshot.get("craft_id", ""))
	data["service_location_id"] = "polisa"
	var result: Dictionary = _adapter.call("request_operation", operation, data)
	_status.text = String(result.get("message", "Vorgang abgeschlossen" if result.get("ok", false) else result.get("reason", "Nicht verfuegbar")))
	if operation == "buy" and result.get("ok", false) and result.get("container_id") == "station:polisa:lift":
		_status.text = "Ware liegt im Frachtaufzug. Unter Frachttransfer zum Schiff transportieren."
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
	if id == "cargo_transfer": return "Frachttransfer"
	if id == "recruitment": return "Personal anwerben"
	for category: Dictionary in _catalog.get("categories", []):
		if String(category.id) == id: return String(category.name)
	return id

func _connect_globe() -> void:
	if not is_instance_valid(_adapter) or not _adapter.has_method("get_polisa_globe_controller"): return
	var controller: Node = _adapter.call("get_polisa_globe_controller")
	if controller == null or not controller.has_signal("polisa_globe_requested"): return
	var handler := Callable(self, "_on_globe_requested")
	if not controller.is_connected("polisa_globe_requested", handler): controller.connect("polisa_globe_requested", handler)

func _on_globe_requested(interaction: Dictionary) -> void:
	if not interaction.get("ok", false):
		_status.text = "Eine eigene Person muss am Globus stehen."
		return
	var result: Dictionary = _adapter.call("request_operation", "station_recruit_open", {"craft_id":String(_snapshot.get("craft_id", "")),"unit_id":String(interaction.get("unit_id", ""))})
	if not result.get("ok", false):
		_status.text = String(result.get("message", "Anwerbung nicht verfügbar"))
		return
	_page = "recruitment"
	_signature = ""
	refresh(_adapter.call("get_polisa_snapshot"))

func _show_recruitment() -> void:
	if not _adapter.has_method("get_polisa_recruitment_snapshot"): return
	var data: Dictionary = _adapter.call("get_polisa_recruitment_snapshot")
	if not data.get("capacity_available", false): _label(_content, "Bettenkapazität der Heimatbasis nicht verfügbar.")
	var view: VBoxContainer = RECRUIT_VIEW.new()
	_content.add_child(view)
	view.call("show_offers", Array(data.get("offers", [])), int(data.get("credits", 0)), int(data.get("beds", 0)), int(data.get("roster_size", 0)), bool(data.get("capacity_available", false)) and not bool(data.get("pending", false)))
	view.connect("hire_requested", _hire_recruit.bind(String(data.get("recruiter_id", ""))))

func _hire_recruit(offer_id: String, recruiter_id: String) -> void:
	_request("station_recruit_hire", {"offer_id":offer_id,"recruiter_id":recruiter_id})


func _show_warp_equipment(snapshot: Dictionary) -> void:
	var catalog = load("res://scripts/mission/ship_equipment_catalog.gd")
	var equipment: Dictionary = snapshot.get("equipment", {})
	var installed := String(Dictionary(equipment.get("slots", {})).get("quantum_drive", ""))
	_label(_content, "Warp-Antrieb / Qualität D → C → B → A")
	if installed.is_empty():
		_label(_content, "Für dieses Schiff ist noch kein austauschbarer Warp-Antrieb verfügbar.")
		return
	var drive: Dictionary = catalog.item(installed)
	_label(_content, "Eingebaut: %s / Klasse %s" % [String(drive.get("name", installed)), String(drive.get("quality", ""))])
	_label(_content, "Warp-Reisezeit: %.0f %% der Standardzeit" % (catalog.multiplier(installed)*100.0))
	var offer: Dictionary = snapshot.get("offers", {}).get("polisa_warp_hemera", {})
	if not offer.is_empty():
		_button(_content, "Hemera / Klasse A / 160 Cr kaufen · Bestand %d" % int(snapshot.get("stock", {}).get("polisa_warp_hemera", 0)), _request.bind("buy", {"craft_id":String(snapshot.get("craft_id", "")), "offer_id":"polisa_warp_hemera", "quantity":1}), int(snapshot.get("credits", 0)) < 160 or int(snapshot.get("stock", {}).get("polisa_warp_hemera", 0)) < 1)
	_label(_content, "Einbau separat · alter Antrieb zurück ins Schiffslager")
	for item_id: String in catalog.ITEMS:
		var item: Dictionary = catalog.item(item_id)
		var quantity := _cargo(item_id)
		_button(_content, "%s / Klasse %s einbauen · Schiffslager %d" % [String(item.name), String(item.quality), quantity], _request.bind("station_install_ship_component", {"craft_id":String(snapshot.get("craft_id", "")), "slot_id":"quantum_drive", "item_id":item_id, "source_container_id":"craft:"+String(snapshot.get("craft_id", "")), "expected_equipment_revision":int(equipment.get("revision", 0))}), quantity < 1 or installed == item_id)


func _show_crew_handoff(snapshot: Dictionary) -> void:
	var handoff: Dictionary = snapshot.get("crew_handoff", {})
	_label(_content, "Besatzung für %s" % String(snapshot.get("craft_name", "ausgewähltes Schiff")))
	for resident: Dictionary in snapshot.get("station_residents", []):
		var unit_id := String(resident.get("unit_id", ""))
		var claim := _button(_content, "%s für dieses Schiff übernehmen" % String(resident.get("name", unit_id)), _request.bind("station_claim_resident", {"craft_id":String(snapshot.get("craft_id", "")),"unit_id":unit_id}))
		claim.name = "ClaimResident_" + unit_id
	_button(_content, "Besatzung einsteigen lassen", _request.bind("station_board_crew", {"craft_id":String(snapshot.get("craft_id", ""))}))
	_label(_content, "Zielschiff oben auswählen")
	var sources: Array = handoff.get("sources", [])
	if sources.is_empty():
		_label(_content, String(handoff.get("message", "Keine andere lokale Besatzung verfügbar.")))
		return
	var source_choice := OptionButton.new()
	source_choice.add_item("Quellschiff auswählen")
	source_choice.set_item_metadata(0, "")
	_content.add_child(source_choice)
	var selected := {}
	for source: Dictionary in sources:
		source_choice.add_item(String(source.get("name", source.get("id", ""))))
		source_choice.set_item_metadata(source_choice.item_count-1, String(source.get("id", "")))
		if String(source.get("id", "")) == _crew_source:
			selected = source
			source_choice.select(source_choice.item_count-1)
	source_choice.item_selected.connect(func(index: int): _crew_source = String(source_choice.get_item_metadata(index)); _crew_pilot = ""; _signature = ""; refresh(_snapshot))
	if selected.is_empty(): return
	_button(_content, "Personen des Quellschiffs absetzen", _request.bind("station_deploy_crew", {"craft_id":_crew_source}))
	_label(_content, "Nach der Übergabe noch zum Zielschiff gehen und einsteigen.")
	var pilot_choice := OptionButton.new()
	pilot_choice.add_item("Piloten auswählen")
	pilot_choice.set_item_metadata(0, "")
	_content.add_child(pilot_choice)
	var pilot_present := false
	for person: Dictionary in selected.get("people", []):
		pilot_choice.add_item(String(person.get("name", person.get("unit_id", ""))))
		pilot_choice.set_item_metadata(pilot_choice.item_count-1, String(person.get("unit_id", "")))
		if String(person.get("unit_id", "")) == _crew_pilot:
			pilot_choice.select(pilot_choice.item_count-1)
			pilot_present = true
	pilot_choice.item_selected.connect(func(index: int): _crew_pilot = String(pilot_choice.get_item_metadata(index)); _signature = ""; refresh(_snapshot))
	var team := CheckBox.new()
	team.text = "Ganze Besatzung mitnehmen"
	team.button_pressed = _crew_take_team
	_content.add_child(team)
	team.toggled.connect(func(enabled: bool): _crew_take_team = enabled; _signature = ""; refresh(_snapshot))
	var units: Array = Array(selected.get("unit_ids", [])).duplicate() if _crew_take_team else [_crew_pilot]
	_button(_content, "Besatzung übernehmen", _request.bind("station_handoff_crew", {"craft_id":String(snapshot.get("craft_id", "")),"source_craft_id":_crew_source,"target_craft_id":String(snapshot.get("craft_id", "")),"unit_ids":units,"pilot_id":_crew_pilot}), not pilot_present or _crew_pilot.is_empty())
