extends PanelContainer
## Compact read-only service view; transactions are committed by the bound owner.

const THEME: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")
const SHIP_VISUALS: GDScript = preload("res://scripts/terrain/frontier_ship_visuals.gd")
const SKIN=preload("res://scripts/ui/base_management_skin.gd")
const MENU_ICONS=preload("res://scripts/ui/menu_equipment_icons.gd")
const RESEARCH = preload("res://scripts/mission/campaign_research_catalog.gd")
const CREDIT_TEXT = preload("res://scripts/core/credit_text.gd")
const OFFER_ID := "medictool_supply"
const DEBOUNCE_SECONDS := 0.35

var _snapshot_provider: Callable
var _command_handler: Callable
var _selected_craft_id: String = ""
var _snapshot: Dictionary = {}
var _pending: Dictionary = {}
var _sequence: int = 0
## Sitzungskennzeichen: Zeit plus Zufallszahl, einmal je Programmlauf (wie _request_session im Adapter). Der Zaehler
## beginnt nach jedem Neustart wieder bei 1 und die Instanz-Id kann sich wiederholen; ohne Kennzeichen faende die
## Versorgung den GESPEICHERTEN Beleg mit gleicher Id und meldete den neuen Kauf als Wiederholung (nichts gebaut).
var _request_session: String = "%d-%d" % [int(Time.get_unix_time_from_system() * 1000.0), randi()]
var _built: bool = false
var _credits: Label
var _items: Label
var _craft_selector: OptionButton
var _fuel: Label
var _tool_buttons: Dictionary={}
var _buy: Button
var _amount: SpinBox
var _repair: Button
var _cargo_load: Button
var _cargo_unload: Button
var _refuel: Button
var _return: Button
var _feedback: Label
var _availability_feedback:=false

var _sell: Button
## Handel H2: Benit aus der Warenboerse. _market_buttons: Ware -> Kaufknopf; _sell_extra: weitere Verkaufsknoepfe (der erste Verkaufsknopf ist _sell).
var _market_buttons: Dictionary = {}
var _sell_extra: Array = []
const MARKET_ITEMS: Array = ["a_benit", "b_benit", "c_benit"]
const MARKET_SELL_ORDER: Array = ["b_benit", "c_benit", "a_benit"]
const MARKET_NAMES: Dictionary = {"a_benit": "A-Benit", "b_benit": "B-Benit", "c_benit": "C-Benit"}
var _campaign_buttons: Dictionary = {}
var _section: String = "all"
var _heading: Label
var _section_note: Label
var _eyebrow:Label
var _cards:GridContainer
var _ship_panel:PanelContainer
var _ship_image:TextureRect
var _modular_builder: Control

func configure(snapshot_provider: Callable, command_handler: Callable) -> void:
	_snapshot_provider = snapshot_provider
	_command_handler = command_handler
	if _modular_builder != null: _modular_builder.call("configure", command_handler)
	if is_node_ready():
		refresh()

func _ready() -> void:
	_build()
	set_process(false)
	refresh()

func _build() -> void:
	if _built:
		return
	_built = true
	SKIN.panel(self)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(270,240)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)
	_eyebrow=_label("SC-06  /  TRANSPORT",14);SKIN.eyebrow(_eyebrow);content.add_child(_eyebrow)
	_heading = _label("Versorgung", 21)
	THEME.style_section_heading(_heading, 30)
	content.add_child(_heading)
	_section_note = _label("", 16)
	content.add_child(_section_note)
	_credits = _label("Kredite: —", 18)
	_credits.name = "SupplyCredits"
	content.add_child(_credits)
	SKIN.rule(content)
	_ship_panel=PanelContainer.new();_ship_panel.name="ShipServiceCard";SKIN.panel(_ship_panel,true);content.add_child(_ship_panel)
	var ship_row:=HBoxContainer.new();ship_row.add_theme_constant_override("separation",22);_ship_panel.add_child(ship_row)
	_ship_image=TextureRect.new();_ship_image.custom_minimum_size=Vector2(210,180);_ship_image.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;_ship_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;_ship_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;ship_row.add_child(_ship_image)
	var ship_content:=VBoxContainer.new();ship_content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;ship_content.add_theme_constant_override("separation",10);ship_row.add_child(ship_content)
	_items = _label("Bestand: —", 14)
	ship_content.add_child(_items)
	_craft_selector = OptionButton.new()
	_craft_selector.name = "ServiceCraftSelector"
	_craft_selector.custom_minimum_size.y = 38
	_craft_selector.fit_to_longest_item = false
	_craft_selector.add_theme_font_size_override("font_size", 15)
	ship_content.add_child(_craft_selector)
	_craft_selector.item_selected.connect(func(index: int): set_selected_craft(String(_craft_selector.get_item_metadata(index))))
	_fuel = _label("Treibstoff: —", 16)
	ship_content.add_child(_fuel)
	_buy = _button("Sanitätswerkzeug kaufen", "BuySupply")
	ship_content.add_child(_buy)
	_buy.pressed.connect(func(): _submit("buy"))
	for id in ["mining_tool_supply", "salvage_tool_supply", "backpack_supply"]:
		var tool:=_button("",id); ship_content.add_child(tool); _tool_buttons[id]=tool
		tool.pressed.connect(func(): _submit("buy",id))

	_sell = _button("Rohstoff aus Schiffsfracht verkaufen", "SellBenit")
	ship_content.add_child(_sell)
	_sell.pressed.connect(_submit_sell.bind(0))
	for extra_index in range(MARKET_ITEMS.size() - 1):
		var extra: Button = _button("Rohstoff verkaufen", "SellBenit%d" % (extra_index + 2))
		ship_content.add_child(extra)
		extra.pressed.connect(_submit_sell.bind(extra_index + 1))
		_sell_extra.append(extra)
	for market_item: String in MARKET_ITEMS:
		var market_button: Button = _button("%s kaufen" % MARKET_NAMES[market_item], "BuyMarket_" + market_item)
		ship_content.add_child(market_button)
		market_button.pressed.connect(_submit_market.bind(market_item))
		_market_buttons[market_item] = market_button
	var fuel_row := HBoxContainer.new()
	ship_content.add_child(fuel_row)
	var amount_label: Label = _label("Tankmenge", 14)
	amount_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount_label.custom_minimum_size.x = 80.0
	fuel_row.add_child(amount_label)
	_amount = SpinBox.new()
	_amount.name = "RefuelAmount"
	_amount.min_value = 1.0
	_amount.max_value = 100.0
	_amount.step = 1.0
	_amount.value = 10.0
	_amount.get_line_edit().add_theme_font_size_override("font_size", 15)
	_amount.custom_minimum_size.x = 110
	_amount.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	fuel_row.add_child(_amount)
	_amount.value_changed.connect(func(_value: float): refresh())
	_refuel = _button("Auftanken", "RefuelCraft")
	ship_content.add_child(_refuel);SKIN.button(_refuel,true)
	_refuel.pressed.connect(func(): _submit("refuel"))
	_repair=_button("Reparaturservice", "RepairCraft");ship_content.add_child(_repair)
	_repair.pressed.connect(func():_ground_request("repair",{}))
	_cargo_load=_button("Frachtaufzug → Schiff", "LoadGroundCargo");ship_content.add_child(_cargo_load)
	_cargo_unload=_button("Schiff → Frachtaufzug", "UnloadGroundCargo");ship_content.add_child(_cargo_unload)
	_cargo_load.pressed.connect(func():_ground_cargo_request(true))
	_cargo_unload.pressed.connect(func():_ground_cargo_request(false))
	_return = _button("Zur Heimatbasis", "ServiceReturnHomebase")
	ship_content.add_child(_return)
	ship_content.move_child(_craft_selector,0);ship_content.move_child(_fuel,1);ship_content.move_child(fuel_row,2);ship_content.move_child(_refuel,3)
	_return.pressed.connect(func(): _submit("return_homebase"))
	_modular_builder = load("res://scripts/ui/modular_base_builder.gd").new()
	content.add_child(_modular_builder)
	_modular_builder.call("configure", _command_handler)
	_cards=GridContainer.new();_cards.name="ServiceActionCards";_cards.add_theme_constant_override("h_separation",14);_cards.add_theme_constant_override("v_separation",14);content.add_child(_cards)
	var campaign_actions: Array = [
		["campaign_upload","Missionsdaten hochladen",{}],
		["campaign_recruit","Person am Handelsposten aufnehmen",{"kind":"outpost"}],
		["campaign_load_crate","Geborgene C-Benit-Kiste übernehmen",{}],
		["campaign_build_pad","Zweites Landepad bauen · 100 Cr",{}],
		["campaign_build_housing","Unterkunft mit zwei Betten bauen · 500 Cr",{}],
		["campaign_fabricate","Hand-Mining-Tool herstellen",{"blueprint_id":"mining_tool"}],
		["campaign_fabricate","Bergungswerkzeug herstellen",{"blueprint_id":"salvage_tool"}],
		["campaign_fabricate","Rucksack aus Bergungsgut herstellen",{"blueprint_id":"backpack_recycling"}],
		["campaign_fabricate","Sturmgewehr herstellen",{"blueprint_id":"assault_rifle"}],
		["campaign_fabricate","Leichte Rüstung herstellen",{"blueprint_id":"light_armor"}],
		["campaign_fabricate","Mittlere Rüstung herstellen",{"blueprint_id":"medium_armor"}],
		["campaign_fabricate","Schwere Rüstung herstellen",{"blueprint_id":"heavy_armor"}]]
	# Munition (M3): Namen aus ammo_rules.json, Stueckzahl aus dem Rezept ("Magazin leicht × 4").
	var ammo_names: Dictionary = Dictionary(load("res://scripts/core/ammo_rules.gd").load_rules().get("ammo_items", {}))
	for recipe_id: String in ["ammo_light", "ammo_rifle", "ammo_rail", "ammo_rocket"]:
		var ammo_recipe: Dictionary = load("res://scripts/core/singleplayer_supply_state.gd").get_campaign_recipe(recipe_id)
		if ammo_recipe.is_empty(): continue
		var ammo_count: int = load("res://scripts/core/singleplayer_supply_state.gd").recipe_output_count(ammo_recipe)
		var ammo_title: String = String(ammo_names.get(String(ammo_recipe.item), String(ammo_recipe.item)))
		campaign_actions.append(["campaign_fabricate", "%s × %d herstellen" % [ammo_title, ammo_count] if ammo_count > 1 else ammo_title + " herstellen", {"blueprint_id": recipe_id}])
	for id: String in RESEARCH.definitions().get("nodes", {}):
		var node: Dictionary = RESEARCH.definitions().nodes[id]
		campaign_actions.append(["campaign_research", node.title, {"research_id": id}])
	for action in campaign_actions:
		var key := String(action[0])+String(Dictionary(action[2]).get("blueprint_id",Dictionary(action[2]).get("research_id","")))
		var button := _button(String(action[1]),key)
		button.visible = false
		var card:=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;SKIN.panel(card,true);_cards.add_child(card)
		var body:=VBoxContainer.new();body.add_theme_constant_override("separation",8);card.add_child(body)
		var title_text:String=String(action[1]).trim_suffix(" herstellen")
		if String(action[0])=="campaign_upload":title_text="Missionsdaten"
		if String(action[0])=="campaign_build_pad":title_text="Zweites Landepad"
		var title_label:=_label(title_text,18)
		body.add_child(title_label)
		var icon:=TextureRect.new();icon.custom_minimum_size=Vector2(80,80);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;body.add_child(icon)
		var blueprint:String=String(Dictionary(action[2]).get("blueprint_id",""))
		var paths:Dictionary={"light_armor":"res://Assets/curated/ui/campaign_inventory/armor_light.svg","mining_tool":"res://Assets/curated/ui/campaign_inventory/benit.svg","assault_rifle":"res://Assets/used/npc/blaster_kit/previews/blaster-a.png"}
		var path:String=String(paths.get(blueprint,"res://Assets/curated/ui/campaign_inventory/chip.svg"))
		if String(action[0])=="campaign_build_pad":path="res://Assets/kenney_space-kit/Isometric/platform_center_SE.png"
		if String(action[0])=="campaign_build_housing":path="res://Assets/curated/kenney/space_station/previews_all/bed-single.png"
		if ResourceLoader.exists(path):icon.texture=load(path)
		var menu_item:String={"light_armor":"armor_light","medium_armor":"armor_medium","heavy_armor":"armor_heavy","mining_tool":"mining_tool","salvage_tool":"mining_tool","backpack_recycling":"backpack","assault_rifle":"rifle","ammo_light":"ammo_light","ammo_rifle":"ammo_rifle","ammo_rail":"ammo_rail","ammo_rocket":"ammo_rocket"}.get(blueprint,"satellite_chip")
		if String(action[0]) not in ["campaign_build_pad", "campaign_build_housing"]:icon.texture=MENU_ICONS.get_icon(menu_item)
		if not blueprint.is_empty():body.add_child(_label(get_blueprint_details(blueprint),14))
		if String(action[0]) == "campaign_research":
			var node: Dictionary = RESEARCH.definitions().nodes[String(action[2].research_id)]
			body.add_child(_label("Einmalige Entwicklung: %d Cr\n%s" % [int(node.cost), String(node.description)], 14))
		var state:=_label("",15);state.custom_minimum_size.y=42;body.add_child(state)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(button);SKIN.button(button,true)
		if String(action[0])=="campaign_fabricate":button.text="Herstellen"
		if String(action[0])=="campaign_research":button.text="Entwickeln"
		_campaign_buttons[key] = {"button":button,"operation":action[0],"payload":action[2],"card":card,"state_label":state,"title_label":title_label}
		button.pressed.connect(_submit_campaign.bind(key))
	_feedback = _label("", 14)
	_feedback.name = "ServiceFeedback"
	_feedback.custom_minimum_size.y = 32
	content.add_child(_feedback)
	resized.connect(_layout_cards)
	_layout_cards()

func _layout_cards()->void:
	if _cards==null:return
	_cards.columns=(3 if size.x>=720 else (2 if size.x>=500 else 1)) if _section=="workshop" else 1
	_ship_image.visible=size.x>=650 and _ship_image.texture!=null

func refresh(snapshot: Dictionary = {}) -> void:
	if not _built:
		return
	var incoming: Dictionary = snapshot
	if incoming.is_empty() and _snapshot_provider.is_valid():
		incoming = _snapshot_provider.call()
	_snapshot = Dictionary(incoming.get("singleplayer", incoming)).duplicate(true)
	var supply: Dictionary = Dictionary(_snapshot.get("supply", {}))
	_release_acknowledged(int(supply.get("revision", -1)))
	var view: Dictionary = _snapshot.get("location_view", {})
	var place := String(view.get("location_id", ""))
	var crafts: Array = Array(_snapshot.get("crafts", [])).filter(func(craft: Dictionary): return not place.is_empty() and String(craft.get("location_id", "")) == place)
	_selected_craft_id = String(view.get("craft_id", ""))
	var ids: Array[String] = []
	for craft: Dictionary in crafts:
		ids.append(String(craft.get("craft_id", craft.get("id", ""))))
	if not ids.has(_selected_craft_id):
		_selected_craft_id = ""
	var labels: Array[String] = []
	for craft: Dictionary in crafts:
		labels.append(SHIP_VISUALS.get_ui_display_name(craft))
	var signature: String = JSON.stringify([ids, labels])
	if String(_craft_selector.get_meta("craft_signature", "")) != signature:
		_craft_selector.clear()
		_craft_selector.add_item("Serviceschiff auswählen")
		_craft_selector.set_item_metadata(0, "")
		for index in range(ids.size()):
			_craft_selector.add_item(labels[index])
			_craft_selector.set_item_metadata(_craft_selector.item_count - 1, ids[index])
		_craft_selector.set_meta("craft_signature", signature)
	if ids.has(_selected_craft_id):
		_craft_selector.select(ids.find(_selected_craft_id) + 1)
	else:
		_craft_selector.select(0)
	_craft_selector.disabled = ids.is_empty() or not _pending.is_empty()
	_refresh_campaign_actions(supply)
	_credits.text = "Kredite: " + CREDIT_TEXT.format(int(supply.get("credits", 0))) if not supply.is_empty() else "Kredite: —"
	var quantities: Dictionary = Dictionary(supply.get("item_quantities", {}))
	_items.text = "Sanitätswerkzeug: %d" % int(quantities.get("medictool", 0)) if not supply.is_empty() else "Bestand: —"
	var fuel_values: Dictionary = Dictionary(supply.get("fuel_by_craft_id", {}))
	var has_fuel: bool = fuel_values.has(_selected_craft_id)
	var fuel: float = float(fuel_values.get(_selected_craft_id, 0.0))
	var capacity: float = float(supply.get("fuel_capacity", 0.0))
	_fuel.text = "Treibstoff: %s / %s" % [str(fuel), str(capacity)] if has_fuel else "Treibstoff: Schiff nicht registriert"
	var contexts: Dictionary = Dictionary(_snapshot.get("service_contexts_by_craft_id", {}))
	var context: Dictionary = Dictionary(contexts.get(_selected_craft_id, {}))
	var location: String = String(context.get("location_id", ""))
	var available: bool = not context.is_empty() and not bool(context.get("craft_busy", true)) and _command_handler.is_valid()
	var local_service:bool=location!="trade_outpost" or bool(context.get("ground_service_verified",false))
	_repair.disabled=not available or not bool(context.get("ground_service_verified",false)) or not Array(context.get("services",[])).has("repair")
	_repair.tooltip_text="Reparatur läuft nur am freigegebenen lokalen Servicepad"
	var lift:=String(context.get("cargo_lift_container_id",""))
	_cargo_load.visible=location=="trade_outpost";_cargo_unload.visible=_cargo_load.visible
	_cargo_load.disabled=not available or lift.is_empty() or not local_service or not Array(context.get("services",[])).has("cargo")
	_cargo_unload.disabled=_cargo_load.disabled
	var unavailable_reason: String = "Versorgung erst nach Landung am passenden Versorgungsort"
	if _selected_craft_id.is_empty():
		unavailable_reason = "Serviceschiff auswählen"
	elif not _command_handler.is_valid():
		unavailable_reason = "Versorgung noch nicht verbunden"
	# Handel (Nachbesserung W2): An der Absturzstelle gilt der Handel nur, wenn das gelandete Schiff nah am Haendler steht; sonst sagt der Text, was zu tun ist.
	var trade_reason: String = unavailable_reason
	if location == "satellite_crash" and available and not Array(context.get("services", [])).has("trade"):
		trade_reason = "Schiff in Sichtweite des Händlers landen, aber nicht direkt neben ihm – Handel erst dort"
	var offer: Dictionary = Dictionary(Dictionary(supply.get("offers", {})).get(OFFER_ID, {}))
	var price: int = int(offer.get("unit_price", 0))
	var stock: int = int(Dictionary(supply.get("stock_by_offer_id", {})).get(OFFER_ID, 0))
	_buy.text = "Sanitätswerkzeug · %d Cr · %d verfügbar" % [price, stock]
	var buy_reason: String = ""
	if not available or not local_service or not Array(context.get("services",[])).has("trade"):
		buy_reason = unavailable_reason
	elif offer.is_empty() or not Array(offer.get("location_ids", [])).has(location):
		buy_reason = "Kauf nur am Handelsaußenposten"
	elif stock <= 0:
		buy_reason = "Angebot ausverkauft"
	elif int(supply.get("credits", 0)) < price:
		buy_reason = "Kredite reichen für den Kauf nicht"
	_buy.disabled = not buy_reason.is_empty() or _pending.has("buy")
	_buy.tooltip_text = buy_reason if not buy_reason.is_empty() else "Ein Sanitätswerkzeug kaufen"
	for id in _tool_buttons:
		var tool_offer: Dictionary=Dictionary(supply.get("offers",{})).get(id,{})
		var tool_stock:=int(Dictionary(supply.get("stock_by_offer_id",{})).get(id,0))
		var tool_price:=int(tool_offer.get("unit_price",0))
		var button: Button=_tool_buttons[id]
		button.text="%s · %d Cr · %d verfügbar" % [tool_offer.get("name",id),tool_price,tool_stock]
		button.disabled=not available or not local_service or not Array(context.get("services",[])).has("trade") or not Array(tool_offer.get("location_ids",[])).has(location) or tool_stock<1 or int(supply.get("credits",0))<tool_price or _pending.has("buy")
		if id == "mining_tool_supply" and String(_snapshot.get("mode","")) == "campaign" and not Array(supply.get("blueprints",[])).has("mining_tool"): button.disabled = true
		button.tooltip_text = ("Kauf wird im lokalen Frachtaufzug bereitgestellt" if not lift.is_empty() else "Kauf wird in dieses Schiff geliefert") if not button.disabled else "Schiff muss am Handelsservice sein. Credits und Bestand erforderlich."
		if id == "backpack_supply" and not button.disabled:
			button.tooltip_text = "Wird im Frachtaufzug bereitgestellt; anschließend ins Schiff laden." if not lift.is_empty() else "Wird in die Schiffsfracht geliefert. An der Heimatbasis anlegen."

	var cargo: Dictionary = Dictionary(Dictionary(supply.get("inventory",{})).get("craft:"+_selected_craft_id,{})).get("items",{}).duplicate()
	var stored:Dictionary=Dictionary(Dictionary(supply.get("inventory",{})).get(lift,{})).get("items",{})
	for item in stored:cargo[item]=int(cargo.get(item,0))+int(stored[item])
	# Handel H2: Verkaufsknoepfe und Kaufknoepfe der Warenboerse kommen aus den Daten (supply.market), nichts steht fest im Text.
	var market_here: Dictionary = Dictionary(Dictionary(supply.get("market", {})).get(location, {}))
	var trade_ready: bool = available and local_service and Array(context.get("services",[])).has("trade")
	var bought_items: Array = []
	for sell_item: String in MARKET_SELL_ORDER:
		if _market_buy_price(supply, location, sell_item) > 0: bought_items.append(sell_item)
	var sell_buttons: Array = [_sell] + _sell_extra
	for slot in range(sell_buttons.size()):
		var sell_button: Button = sell_buttons[slot]
		var slot_item: String = String(bought_items[slot]) if slot < bought_items.size() else ""
		sell_button.set_meta("item", slot_item)
		sell_button.visible = not slot_item.is_empty() and location in ["satellite_crash","trade_outpost"]
		if slot_item.is_empty(): continue
		var sell_price: int = _market_buy_price(supply, location, slot_item)
		sell_button.text = "1 × %s verkaufen · %d Cr" % [MARKET_NAMES.get(slot_item, slot_item), sell_price]
		sell_button.disabled = not trade_ready or int(cargo.get(slot_item,0)) < 1
		sell_button.tooltip_text = "Verkauf aus lokaler Schiffsfracht oder dem Frachtaufzug" if not sell_button.disabled else ("Keine %s im Schiff oder Frachtaufzug" % MARKET_NAMES.get(slot_item, slot_item) if trade_ready else trade_reason)
	for market_item: String in MARKET_ITEMS:
		var market_button: Button = _market_buttons[market_item]
		var market_entry: Dictionary = Dictionary(market_here.get(market_item, {}))
		market_button.visible = market_entry.has("sell_price") and location in ["satellite_crash","trade_outpost"]
		if not market_button.visible: continue
		var market_price: int = int(market_entry.sell_price)
		var market_stock: int = int(market_entry.get("stock", 0))
		market_button.text = "%s · %d Cr · %d verfügbar" % [MARKET_NAMES.get(market_item, market_item), market_price, market_stock]
		var market_reason: String = ""
		if not trade_ready: market_reason = trade_reason
		elif market_stock <= 0: market_reason = "Ausverkauft – füllt sich nach der Heimlandung wieder auf"
		elif int(supply.get("credits", 0)) < market_price: market_reason = "Kredite reichen für den Kauf nicht"
		market_button.disabled = not market_reason.is_empty() or _pending.has("buy")
		market_button.tooltip_text = market_reason if not market_reason.is_empty() else ("Wird im Frachtaufzug bereitgestellt; anschließend ins Schiff laden." if not lift.is_empty() else "Wird in die Schiffsfracht geliefert.")
	var amount: float = _amount.value
	var cost: float = amount * float(supply.get("fuel_price_per_unit", 0.0))
	_refuel.text = "+%s Treibstoff · %s Cr" % [str(amount), str(cost)]
	var fuel_reason: String = ""
	if not available or not local_service or not Array(context.get("services",[])).has("refuel"):
		fuel_reason = unavailable_reason
	elif not location in ["homebase", "trade_outpost", "satellite_crash"]:
		fuel_reason = "An diesem Ort gibt es keine Tankstelle"
	elif not has_fuel:
		fuel_reason = "Schiff hat keinen registrierten Treibstofftank"
	elif amount > capacity - fuel:
		fuel_reason = "Nur %s Treibstoff bis zum vollen Tank möglich" % str(maxf(capacity - fuel, 0.0))
	elif cost > float(supply.get("credits", 0)):
		fuel_reason = "Kredite reichen für diese Tankmenge nicht"
	_refuel.disabled = not fuel_reason.is_empty() or _pending.has("refuel")
	_refuel.tooltip_text = fuel_reason if not fuel_reason.is_empty() else "Bestätigten Schiffstank auffüllen"
	_amount.editable = not _pending.has("refuel")
	var craft: Dictionary = {}
	for entry: Dictionary in crafts:
		if String(entry.get("craft_id", entry.get("id", ""))) == _selected_craft_id:
			craft = entry
	_return.visible = not craft.is_empty() and String(craft.get("location_id", "homebase")) != "homebase"
	var space: Dictionary = _snapshot.get("space_travel", {})
	_return.text = "Zum Ortsorbit abheben" if String(space.get("phase", "")) == "surface" and String(space.get("craft_id", "")) == _selected_craft_id else "Zur Heimatbasis"
	_return.disabled = bool(craft.get("busy", true)) or not available or _pending.has("return_homebase")
	_return.tooltip_text = "Rückflug erst nach bestätigter Landung am Versorgungsort" if _return.disabled else "Rückflug für dieses Schiff anfordern"
	if not available:
		_feedback.text = unavailable_reason; _availability_feedback=true
	elif not buy_reason.is_empty() and not fuel_reason.is_empty():
		_feedback.text = buy_reason + " · " + fuel_reason; _availability_feedback=true
	elif _availability_feedback:
		_feedback.text = "Versorgung bereit"; _availability_feedback=false

	_apply_section()

func set_section(section: String) -> void:
	_section = section if section in ["all","build","workshop","data","ship"] else "all"
	refresh()

func _apply_section() -> void:
	var ship := _section in ["all", "ship"]
	_ship_panel.visible=ship
	_eyebrow.text={"all":"SC-06  /  VERSORGUNG","ship":"SC-06  /  TRANSPORT","build":"BAU-02  /  INFRASTRUKTUR","workshop":"WB-03  /  FERTIGUNG","data":"DT-05  /  INFORMATION"}.get(_section,"")
	_heading.text = {"all":"Versorgung", "build":"Basis · Bauen", "workshop":"Werkstatt · Entwicklung & Fertigung", "data":"Datenterminal · Hochladen", "ship":"Schiff · Versorgung"}.get(_section,"Versorgung")
	_section_note.text = {"all":"", "build":"Baue Räume und Gänge aneinander; Betten werden einzeln im Schlafraum aufgestellt.", "workshop":"Baupläne durch Aufträge freischalten, Schutztechnik einmal entwickeln und anschließend jedes Stück separat fertigen. Fertige Ausrüstung liegt im Basislager.", "data":"Geborgene Missionsdaten nach der Landung hier hochladen. Erst dadurch wird der Auftrag abgeschlossen.", "ship":"Schiff auswählen und Treibstoff ergänzen. Besatzung und Fracht im Flugdeck verwalten."}.get(_section, "")
	_section_note.visible = not _section_note.text.is_empty()
	if _modular_builder != null:
		_modular_builder.visible = _section == "build" and String(_snapshot.get("mode", "")) == "campaign"
		if _modular_builder.visible: _modular_builder.call("refresh", _snapshot)
	for control in [_craft_selector,_fuel,_buy,_sell,_repair,_cargo_load,_cargo_unload,_amount.get_parent(),_refuel,_return]+_tool_buttons.values():
		control.visible = ship
	var trade_context:Dictionary=Dictionary(_snapshot.get("service_contexts_by_craft_id",{})).get(_selected_craft_id,{})
	var trading:bool=String(trade_context.get("location_id","")) in ["trade_outpost","satellite_crash"]
	_cargo_load.visible=ship and String(trade_context.get("location_id",""))=="trade_outpost"
	_cargo_unload.visible=_cargo_load.visible
	for control in [_buy,_sell]+_tool_buttons.values():control.visible=ship and trading
	# Handel H2: die Knoepfe der Warenboerse zeigt refresh() je nach Daten; hier werden sie nur ausgeblendet, wenn kein Handelsort offen ist.
	for control in _sell_extra+_market_buttons.values():
		if not (ship and trading): control.visible = false
	_tool_buttons["backpack_supply"].visible = ship and String(trade_context.get("location_id", "")) == "trade_outpost" and String(_snapshot.get("mode", "")) == "campaign"
	_items.visible = ship and trading
	_refuel.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	_refuel.custom_minimum_size.x=180
	_return.visible = false
	if ship:
		for craft:Dictionary in _snapshot.get("crafts",[]):
			if String(craft.get("craft_id","")) == _selected_craft_id:
				_return.visible = String(craft.get("location_id","homebase")) != "homebase"

	for action:Dictionary in _campaign_buttons.values():
		var button:Button=action.button
		if _section == "all": continue
		var wanted:bool=(_section=="build" and String(action.operation) in ["campaign_build_pad", "campaign_build_housing"]) or (_section=="workshop" and (String(action.operation)=="campaign_fabricate" or (String(action.operation)=="campaign_research" and String(_snapshot.get("mode",""))=="campaign"))) or (_section=="data" and String(action.operation)=="campaign_upload")
		if not wanted:
			button.hide()
			continue
		var available:bool=button.visible
		button.show()
		if not available:
			button.disabled=true
			button.tooltip_text={"build":"Nach der Pilotenrettung verfügbar; bereits gebaute Pads bleiben erhalten.","workshop":"Passende Erwerbserlaubnis zuerst in den Kampagnenaufträgen freischalten.","data":"Keine geborgenen Missionsdaten zum Hochladen vorhanden."}.get(_section,"")
	if _section == "data":
		var has_data:bool=false
		for job:Dictionary in _snapshot.get("campaign",{}).get("jobs",{}).values():
			has_data=has_data or String(job.get("status",""))=="pending_upload"
		var upload_blocker:String=String(_snapshot.get("home_services",{}).get("upload_blocker",""))
		has_data=has_data or not Array(_snapshot.get("home_services",{}).get("upload_job_ids",[])).is_empty() or not upload_blocker.is_empty()
		if not has_data:
			_section_note.text="Keine geborgenen Missionsdaten vorhanden. Erst am Einsatzort sichern, zum Schiff zurückbringen und heimkehren."
			var jobs:Dictionary=_snapshot.get("campaign",{}).get("jobs",{})
			for id:String in ["satellite_recovery","outpost_chip_recovery"]:
				var job:Dictionary=jobs.get(id,{})
				if String(job.get("status",""))=="failed":
					_section_note.text="Auftrag fehlgeschlagen: %s. Kein freigegebener Upload vorhanden. Im Smart Mobile den Auftrag erneut annehmen und die Daten am Einsatzort bergen; anschließend zum Schiff zurückbringen und heimkehren."%String(job.get("title",id))
					break
				if String(job.get("status",""))=="completed":
					_section_note.text="%s: Daten bereits hochgeladen und Belohnung erhalten. Keine weiteren Missionsdaten zum Hochladen vorhanden."%String(job.get("title",id))
		elif _campaign_buttons.campaign_upload.button.disabled:
			_section_note.text=upload_blocker if not upload_blocker.is_empty() else "Missionsdaten geborgen. Zuerst wieder an der Heimatbasis landen."
		else:
			_section_note.text="Missionsdaten vorhanden. Mit dem Button unten hochladen."
	_feedback.visible = ship or (not _availability_feedback and _feedback.text != "Versorgung bereit")
	for action:Dictionary in _campaign_buttons.values():
		action.card.visible=action.button.visible
		var free_recipe:bool=String(action.operation)=="campaign_fabricate" and load("res://scripts/core/singleplayer_supply_state.gd").is_free_recipe(String(action.payload.blueprint_id))
		action.state_label.text=String(action.button.tooltip_text) if action.button.disabled else (("Ohne Erwerbserlaubnis verfügbar" if free_recipe else "Erwerbserlaubnis freigeschaltet") if String(action.operation)=="campaign_fabricate" else "Aktion verfügbar")
		if action.button.disabled and action.state_label.text.is_empty():action.state_label.text="Derzeit nicht verfügbar"
		if String(action.operation)=="campaign_fabricate" and action.button.disabled:action.state_label.text="Gesperrt · Erwerbserlaubnis fehlt" if not (free_recipe or Array(_snapshot.get("supply",{}).get("blueprints",[])).has(String(action.payload.blueprint_id))) else String(action.button.tooltip_text)
		if String(action.operation)=="campaign_build_housing":
			var offer:Dictionary=_snapshot.get("housing_offer",{})
			var built_beds:int=int(_snapshot.get("supply", {}).get("campaign_beds", 2))
			if bool(offer.get("container",false)):
				var supply_script:GDScript=load("res://scripts/core/singleplayer_supply_state.gd")
				var title:String="Wohncontainer mit vier Betten – %d Cr" % int(supply_script.CONTAINER_HOUSING_COST)
				action.title_label.text="Wohncontainer mit vier Betten"
				action.button.text=title
				# Vorhandene Alt-Gebaeude haben nur zwei Betten; nur die freien Stellplaetze bringen je vier dazu.
				var placed:Array=Array(_snapshot.get("supply", {}).get("campaign_housing_beds", [])).slice(0,int(offer.get("sites",0)))
				var max_beds:int=2+int(supply_script.CONTAINER_HOUSING_BEDS)*maxi(0,int(offer.get("sites",0))-placed.size())
				for placed_beds in placed:max_beds+=int(placed_beds)
				action.state_label.text="Gebaut: %d / %d Betten" % [built_beds,max_beds]
				var blocker:String=_housing_container_blocker(offer)
				if action.button.disabled and not blocker.is_empty():
					action.state_label.text+="\n"+blocker
					action.button.tooltip_text=blocker
			else:
				action.state_label.text="Gebaut: %d / 20 Betten" % built_beds
	for craft:Dictionary in _snapshot.get("crafts",[]):
		if String(craft.get("craft_id",""))==_selected_craft_id:_ship_image.texture=SHIP_VISUALS.get_ui_preview_texture(craft)
	_layout_cards()

static func get_blueprint_details(blueprint_id:String)->String:
	var recipe:Dictionary=load("res://scripts/core/singleplayer_supply_state.gd").get_campaign_recipe(blueprint_id)
	if recipe.is_empty():return ""
	var lines:PackedStringArray=PackedStringArray()
	if String(recipe.item)=="rifle":
		var weapons=load("res://scripts/core/weapon_data.gd")
		lines.append("Basisschaden: %d"%weapons.get_damage_per_hit("rifle"))
		lines.append("Reichweite: %d Felder"%weapons.get_effective_tile_range("rifle"))
	elif String(recipe.item)=="mining_tool":lines.append("Werkzeug zum Abbau\nmarkierter Vorkommen")
	elif String(recipe.item)=="salvage_tool":lines.append("Werkzeug zur Bergung\nmarkierter Wracks")
	elif String(recipe.item)=="backpack":lines.append("Rucksack für %d Inventarplätze" % int(load("res://scripts/mission/inventory_transfer_contract.gd").BACKPACK_CAPACITY))
	elif String(recipe.item) in ["armor_light", "armor_medium", "armor_heavy"]:
		lines.append("Rüstungsklasse: " + {"armor_light":"Leicht", "armor_medium":"Mittel", "armor_heavy":"Schwer"}[String(recipe.item)])
	var count:int=load("res://scripts/core/singleplayer_supply_state.gd").recipe_output_count(recipe)
	if count>1:lines.append("Ergebnis: %d × %s" % [count, String(Dictionary(load("res://scripts/core/ammo_rules.gd").load_rules().get("ammo_items", {})).get(String(recipe.item), String(recipe.item)))])
	lines.append("Herstellung: %d Cr"%int(recipe.cost))
	for item: String in recipe.get("inputs", {}):
		lines.append("Material: %d × %s aus dem Basislager" % [int(recipe.inputs[item]), RESEARCH.item_label(item)])
	return "\n".join(lines)

func set_selected_craft(craft_id: String) -> bool:
	if not _pending.is_empty():
		return false
	if craft_id.is_empty() and _command_handler.is_valid():
		var cleared: Dictionary = _command_handler.call("select_location_view_craft", {"location_id":String(Dictionary(_snapshot.get("location_view", {})).get("location_id", "")), "craft_id":""})
		refresh()
		return bool(cleared.get("ok", false))
	for craft: Dictionary in Array(_snapshot.get("crafts", [])):
		if String(craft.get("craft_id", craft.get("id", ""))) == craft_id:
			var place := String(Dictionary(_snapshot.get("location_view", {})).get("location_id", ""))
			if String(craft.get("location_id", "")) != place or place.is_empty() or not _command_handler.is_valid(): return false
			var result: Dictionary = _command_handler.call("select_location_view_craft", {"location_id":place, "craft_id":craft_id})
			if not bool(result.get("ok", false)): return false
			_feedback.text = ""
			refresh()
			return true
	return false

## Leer = Kauf moeglich, sonst der Grund als Text fuer den Spieler.
func _housing_container_blocker(offer: Dictionary) -> String:
	var supply: Dictionary = _snapshot.get("supply", {})
	var supply_script: GDScript = load("res://scripts/core/singleplayer_supply_state.gd")
	if int(supply.get("campaign_housing", 0)) >= int(offer.get("sites", 0)): return "Kein freier Stellplatz für einen weiteren Wohncontainer"
	if int(supply.get("credits", 0)) < int(supply_script.CONTAINER_HOUSING_COST): return "Ein Wohncontainer kostet %d Credits" % int(supply_script.CONTAINER_HOUSING_COST)
	return ""

func _refresh_campaign_actions(supply: Dictionary) -> void:
	var campaign: Dictionary = _snapshot.get("campaign",{})
	var jobs: Dictionary = campaign.get("jobs",{})
	var progress: Dictionary = campaign.get("progress",{})
	var home_services: Dictionary = _snapshot.get("home_services", {})
	var home := bool(home_services.get("workshop_available", false))
	var local_uploads: Array = home_services.get("upload_job_ids", [])
	var context: Dictionary = Dictionary(_snapshot.get("service_contexts_by_craft_id", {})).get(_selected_craft_id, {})
	var job_craft := String(Dictionary(jobs.get("outpost_recovery", {})).get("craft_id", ""))
	# LC2h H5: Ist das Auftragsschiff verloren (Verlustbeleg), genuegt "ein Schiff" der Flotte am richtigen Ort.
	var job_craft_lost: bool = not job_craft.is_empty() and Array(home_services.get("lost_craft_ids", [])).has(job_craft)
	var is_job_craft: bool = _selected_craft_id == job_craft or (job_craft_lost and not _selected_craft_id.is_empty())
	var at_outpost := String(context.get("location_id", "")) == "trade_outpost" and not _selected_craft_id.is_empty() and is_job_craft
	var has_chip := false
	for job: Dictionary in jobs.values(): has_chip = has_chip or String(job.get("status","")) == "pending_upload"
	has_chip = has_chip or not local_uploads.is_empty() or not String(home_services.get("upload_blocker", "")).is_empty()
	for key in _campaign_buttons:
		var action: Dictionary = _campaign_buttons[key]
		var button: Button = action.button
		var show := String(_snapshot.get("mode","")) == "campaign"
		var enabled := home
		match String(action.operation):
			"campaign_upload":
				show = has_chip
				enabled = not local_uploads.is_empty()
			"campaign_recruit":
				show = show and String(Dictionary(jobs.get("outpost_recovery",{})).get("status","")) in ["active","completed"] and not bool(progress.get("recruited_outpost",false))
				enabled = at_outpost
			"campaign_load_crate":
				show = show and String(Dictionary(jobs.get("outpost_recovery",{})).get("status","")) == "completed" and not bool(progress.get("crate_loaded",false))
				enabled = at_outpost or (String(context.get("location_id", "")) == "homebase" and is_job_craft)
			"campaign_build_pad":
				show = show and bool(progress.get("recruited_pilot",false)) and not bool(progress.get("second_pad_built",false))
				enabled = bool(home_services.get("all_at_home", false))
			"campaign_build_housing":
				var housing_offer:Dictionary=_snapshot.get("housing_offer",{})
				if bool(housing_offer.get("container",false)):
					enabled = _housing_container_blocker(housing_offer).is_empty()
				else:
					enabled = int(supply.get("credits", 0)) >= 500 and int(supply.get("campaign_housing", 0)) < 9
			"campaign_fabricate":
				show = Array(supply.get("blueprints",[])).has(String(action.payload.blueprint_id)) or load("res://scripts/core/singleplayer_supply_state.gd").is_free_recipe(String(action.payload.blueprint_id))
				var quote: Dictionary = supply.get("research", {}).get("fabrication", {}).get(String(action.payload.blueprint_id), {})
				enabled = home and bool(quote.get("ok", false))
			"campaign_research":
				var research: Dictionary = supply.get("research", {}).get("nodes", {}).get(String(action.payload.research_id), {})
				enabled = home and bool(research.get("available", false))
		button.visible = show
		button.disabled = not enabled or not _command_handler.is_valid()
		button.tooltip_text = "Lokaler Zugang oder Voraussetzung fehlt" if not enabled else ""
		if String(action.operation) == "campaign_research" and home:
			button.tooltip_text = String(supply.get("research", {}).get("nodes", {}).get(String(action.payload.research_id), {}).get("message", "Entwicklung derzeit nicht verfügbar"))
		if String(action.operation) == "campaign_fabricate" and home:
			button.tooltip_text = String(supply.get("research", {}).get("fabrication", {}).get(String(action.payload.blueprint_id), {}).get("message", "Herstellung derzeit nicht möglich")) if not enabled else ""

func _submit_campaign(key: String) -> void:
	var action: Dictionary = _campaign_buttons.get(key,{})
	if action.is_empty() or action.button.disabled or not _command_handler.is_valid(): return
	var payload: Dictionary = Dictionary(action.payload).duplicate(true)
	payload["craft_id"] = _selected_craft_id
	_sequence += 1
	payload["request_id"] = "campaign-service:%d:%s:%d" % [get_instance_id(),_request_session,_sequence]
	var result: Dictionary = _command_handler.call(String(action.operation),payload)
	_feedback.text = String(result.get("message",result.get("reason","Aktion bestätigt")))
	refresh()

## Handel H2: Ankaufspreis des Haendlers am Ort aus den Daten (Warenboerse vor den Handelsdaten); 0 = kauft nicht. Gleiche Regel wie der Versorgungszustand.
func _market_buy_price(supply: Dictionary, location: String, item: String) -> int:
	var entry: Dictionary = Dictionary(Dictionary(Dictionary(supply.get("market", {})).get(location, {})).get(item, {}))
	if entry.has("sell_price"): return 0
	if entry.has("buy_price"): return int(entry.buy_price)
	return int(Dictionary(Dictionary(supply.get("commodity_buy_orders", {})).get(location, {})).get(item, 0))

## Handel H2: Kauf eines Stuecks aus der Warenboerse am aktuellen Ort (Befehl buy, Angebotskennung market:<Ort>:<Ware>).
func _submit_market(item: String) -> void:
	var button: Button = _market_buttons.get(item)
	if button == null or not _command_handler.is_valid(): return
	if button.disabled:
		_feedback.text = button.tooltip_text
		return
	var context: Dictionary = Dictionary(_snapshot.get("service_contexts_by_craft_id",{})).get(_selected_craft_id,{})
	var location_id := String(context.get("location_id", ""))
	_sequence += 1
	var request_id: String = "services-market:%d:%d" % [get_instance_id(), _sequence]
	var payload: Dictionary = {"craft_id": _selected_craft_id, "request_id": request_id, "service_location_id": location_id, "offer_id": "market:%s:%s" % [location_id, item], "quantity": 1}
	var result: Dictionary = _command_handler.call("buy", payload)
	_feedback.text = String(result.get("message", result.get("reason", "Kauf bestätigt")))
	refresh()

func _submit_sell(slot: int = 0) -> void:
	var sell_button: Button = _sell if slot <= 0 else _sell_extra[slot - 1]
	if sell_button.disabled or not _command_handler.is_valid(): return
	var context: Dictionary = Dictionary(_snapshot.get("service_contexts_by_craft_id",{})).get(_selected_craft_id,{})
	var item := String(sell_button.get_meta("item", ""))
	if item.is_empty(): return
	_sequence += 1
	var cargo:Dictionary=Dictionary(Dictionary(_snapshot.get("supply",{})).get("inventory",{})).get("craft:"+_selected_craft_id,{}).get("items",{})
	var source:="craft:"+_selected_craft_id if int(cargo.get(item,0))>0 else String(context.get("cargo_lift_container_id",""))
	var result: Dictionary = _command_handler.call("sell",{"source_container_id":source,"service_location_id":String(context.get("location_id", "")),"craft_id":_selected_craft_id,"item_id":item,"quantity":1,"request_id":"services-sell:%d:%d" % [get_instance_id(),_sequence]})
	_feedback.text = String(result.get("message",result.get("reason","Verkauf bestätigt")))
	refresh()

func _submit(operation: String, offer_id: String=OFFER_ID) -> void:
	if _pending.has(operation):
		return
	var button: Button = (_buy if offer_id==OFFER_ID else _tool_buttons[offer_id]) if operation == "buy" else (_refuel if operation == "refuel" else _return)
	if button.disabled or not _command_handler.is_valid():
		_feedback.text = button.tooltip_text
		return
	_sequence += 1
	var request_id: String = "services:%d:%d" % [get_instance_id(), _sequence]
	var payload: Dictionary = {"craft_id": _selected_craft_id, "request_id": request_id, "service_location_id":String(Dictionary(Dictionary(_snapshot.get("service_contexts_by_craft_id", {})).get(_selected_craft_id, {})).get("location_id", ""))}
	if operation == "buy":
		payload["offer_id"] = offer_id
		payload["quantity"] = 1
	elif operation == "refuel":
		payload["amount"] = _amount.value
	var pending: Dictionary = {"request_id": request_id, "payload": payload.duplicate(true), "revision": int(Dictionary(_snapshot.get("supply", {})).get("revision", -1)), "elapsed": false}
	_pending[operation] = pending
	button.disabled = true
	var result: Dictionary = _command_handler.call(operation, payload)
	pending["result"] = result.duplicate(true)
	_feedback.text = String(result.get("message", result.get("reason", "Anfrage gesendet")))
	_availability_feedback=false
	refresh()
	get_tree().create_timer(DEBOUNCE_SECONDS).timeout.connect(_acknowledgement_delay_elapsed.bind(operation, request_id), CONNECT_ONE_SHOT)

func _acknowledgement_delay_elapsed(operation: String, request_id: String) -> void:
	if _pending.has(operation) and String(_pending[operation].request_id) == request_id:
		_pending[operation]["elapsed"] = true
		refresh()

func _release_acknowledged(revision: int) -> void:
	for operation: String in _pending.keys():
		var pending: Dictionary = _pending[operation]
		if not bool(pending.elapsed):
			continue
		var result: Dictionary = Dictionary(pending.get("result", {}))
		if not bool(result.get("ok", false)) or bool(result.get("replayed", false)) or revision > int(pending.revision) or operation == "return_homebase":
			_pending.erase(operation)

func get_presentation_snapshot() -> Dictionary:
	return {"selected_craft_id": _selected_craft_id, "pending_request_count": _pending.size(), "feedback": _feedback.text if _feedback != null else "", "ui_sets_gameplay_truth": false}

func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f4f2e9"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SKIN.label(label,font_size)
	return label

func _button(value: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = value
	button.custom_minimum_size.y = 42
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 15)
	SKIN.button(button)
	return button

func fit_to_viewport() -> void:
	# Wrapped labels can transiently report thousands of pixels before their
	# first layout. Refit after text updates instead of retaining that height.
	var viewport:=get_viewport_rect()
	size=Vector2(330,0)
	position=Vector2(maxf(viewport.size.x-size.x-20,16),196)

func _ground_request(operation:String, payload:Dictionary)->void:
	if not _command_handler.is_valid():return
	_sequence+=1
	var context:Dictionary=Dictionary(_snapshot.get("service_contexts_by_craft_id",{})).get(_selected_craft_id,{})
	payload.merge({"craft_id":_selected_craft_id,"service_location_id":String(context.get("location_id","")),"request_id":"ground-service:%d:%d"%[get_instance_id(),_sequence]},true)
	var result:Dictionary=_command_handler.call(operation,payload)
	_feedback.text=String(result.get("message",result.get("reason","")))
	refresh()

func _ground_cargo_request(load_ship:bool)->void:
	var context:Dictionary=Dictionary(_snapshot.get("service_contexts_by_craft_id",{})).get(_selected_craft_id,{})
	var lift:=String(context.get("cargo_lift_container_id",""))
	_ground_request("cargo_transfer_all",{"source_container_id":lift if load_ship else "craft:"+_selected_craft_id,"destination_container_id":"craft:"+_selected_craft_id if load_ship else lift})
