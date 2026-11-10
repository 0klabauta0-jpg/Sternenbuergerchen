extends PanelContainer
## Compact read-only service view; transactions are committed by the bound owner.

const THEME: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")
const SHIP_VISUALS: GDScript = preload("res://scripts/terrain/frontier_ship_visuals.gd")
const OFFER_ID := "medictool_supply"
const DEBOUNCE_SECONDS := 0.35

var _snapshot_provider: Callable
var _command_handler: Callable
var _selected_craft_id: String = ""
var _snapshot: Dictionary = {}
var _pending: Dictionary = {}
var _sequence: int = 0
var _built: bool = false
var _credits: Label
var _items: Label
var _craft_selector: OptionButton
var _fuel: Label
var _buy: Button
var _amount: SpinBox
var _refuel: Button
var _return: Button
var _feedback: Label
var _sell: Button
var _campaign_buttons: Dictionary = {}

func configure(snapshot_provider: Callable, command_handler: Callable) -> void:
	_snapshot_provider = snapshot_provider
	_command_handler = command_handler
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
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102f3b")
	style.border_color = Color("29e1e7")
	style.set_border_width_all(1)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300,240)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	scroll.add_child(content)
	var heading: Label = _label("Versorgung", 21)
	THEME.style_section_heading(heading, 23)
	content.add_child(heading)
	_credits = _label("Kredite: —", 18)
	_credits.name = "SupplyCredits"
	content.add_child(_credits)
	_items = _label("Bestand: —", 14)
	content.add_child(_items)
	_craft_selector = OptionButton.new()
	_craft_selector.name = "ServiceCraftSelector"
	_craft_selector.custom_minimum_size.y = 38
	_craft_selector.fit_to_longest_item = false
	_craft_selector.add_theme_font_size_override("font_size", 15)
	content.add_child(_craft_selector)
	_craft_selector.item_selected.connect(func(index: int): set_selected_craft(String(_craft_selector.get_item_metadata(index))))
	_fuel = _label("Treibstoff: —", 16)
	content.add_child(_fuel)
	_buy = _button("Sanitätswerkzeug kaufen", "BuySupply")
	content.add_child(_buy)
	_buy.pressed.connect(func(): _submit("buy"))
	_sell = _button("Rohstoff aus Schiffsfracht verkaufen", "SellBenit")
	content.add_child(_sell)
	_sell.pressed.connect(_submit_sell)
	var fuel_row := HBoxContainer.new()
	content.add_child(fuel_row)
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
	content.add_child(_refuel)
	_refuel.pressed.connect(func(): _submit("refuel"))
	_return = _button("Zur Heimatbasis", "ServiceReturnHomebase")
	content.add_child(_return)
	_return.pressed.connect(func(): _submit("return_homebase"))
	for action in [
		["campaign_upload","Chip am Basisterminal hochladen",{}],
		["campaign_recruit","Person am Handelsposten aufnehmen",{"kind":"outpost"}],
		["campaign_load_crate","Geborgene C-Benit-Kiste übernehmen",{}],
		["campaign_build_pad","Zweites Landepad bauen · 100 Cr",{}],
		["campaign_fabricate","Hand-Mining-Tool herstellen",{"blueprint_id":"mining_tool"}],
		["campaign_fabricate","Sturmgewehr herstellen",{"blueprint_id":"assault_rifle"}],
		["campaign_fabricate","Leichte Rüstung herstellen",{"blueprint_id":"light_armor"}]]:
		var key := String(action[0])+String(Dictionary(action[2]).get("blueprint_id",""))
		var button := _button(String(action[1]),key)
		button.visible = false
		content.add_child(button)
		_campaign_buttons[key] = {"button":button,"operation":action[0],"payload":action[2]}
		button.pressed.connect(_submit_campaign.bind(key))
	_feedback = _label("", 14)
	_feedback.name = "ServiceFeedback"
	_feedback.custom_minimum_size.y = 32
	content.add_child(_feedback)

func refresh(snapshot: Dictionary = {}) -> void:
	if not _built:
		return
	var incoming: Dictionary = snapshot
	if incoming.is_empty() and _snapshot_provider.is_valid():
		incoming = _snapshot_provider.call()
	_snapshot = Dictionary(incoming.get("singleplayer", incoming)).duplicate(true)
	var supply: Dictionary = Dictionary(_snapshot.get("supply", {}))
	_refresh_campaign_actions(supply)
	_release_acknowledged(int(supply.get("revision", -1)))
	var crafts: Array = Array(_snapshot.get("crafts", []))
	var ids: Array[String] = []
	for craft: Dictionary in crafts:
		ids.append(String(craft.get("craft_id", craft.get("id", ""))))
	if not ids.has(_selected_craft_id):
		_selected_craft_id = ids[0] if not ids.is_empty() else ""
	var labels: Array[String] = []
	for craft: Dictionary in crafts:
		labels.append(SHIP_VISUALS.get_ui_display_name(craft))
	var signature: String = JSON.stringify([ids, labels])
	if String(_craft_selector.get_meta("craft_signature", "")) != signature:
		_craft_selector.clear()
		for index in range(ids.size()):
			_craft_selector.add_item(labels[index])
			_craft_selector.set_item_metadata(_craft_selector.item_count - 1, ids[index])
		_craft_selector.set_meta("craft_signature", signature)
	if ids.has(_selected_craft_id):
		_craft_selector.select(ids.find(_selected_craft_id))
	_craft_selector.disabled = ids.is_empty() or not _pending.is_empty()
	_credits.text = "Kredite: %d" % int(supply.get("credits", 0)) if not supply.is_empty() else "Kredite: —"
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
	var unavailable_reason: String = "Versorgung erst nach Landung am passenden Versorgungsort"
	if _selected_craft_id.is_empty():
		unavailable_reason = "Kein reales Schiff verfügbar"
	elif not _command_handler.is_valid():
		unavailable_reason = "Versorgung noch nicht verbunden"
	var offer: Dictionary = Dictionary(Dictionary(supply.get("offers", {})).get(OFFER_ID, {}))
	var price: int = int(offer.get("unit_price", 0))
	var stock: int = int(Dictionary(supply.get("stock_by_offer_id", {})).get(OFFER_ID, 0))
	_buy.text = "Sanitätswerkzeug · %d Cr · %d verfügbar" % [price, stock]
	var buy_reason: String = ""
	if not available:
		buy_reason = unavailable_reason
	elif offer.is_empty() or not Array(offer.get("location_ids", [])).has(location):
		buy_reason = "Kauf nur am Handelsaußenposten"
	elif stock <= 0:
		buy_reason = "Angebot ausverkauft"
	elif int(supply.get("credits", 0)) < price:
		buy_reason = "Kredite reichen für den Kauf nicht"
	_buy.disabled = not buy_reason.is_empty() or _pending.has("buy")
	_buy.tooltip_text = buy_reason if not buy_reason.is_empty() else "Ein Sanitätswerkzeug kaufen"
	var purchased_item := "c_benit" if location == "satellite_crash" else "b_benit"
	var cargo: Dictionary = Dictionary(Dictionary(supply.get("inventory",{})).get("craft:"+_selected_craft_id,{})).get("items",{})
	_sell.visible = location in ["satellite_crash","trade_outpost"]
	_sell.text = "1 × %s verkaufen · 15 Cr" % ("C-Benit" if purchased_item == "c_benit" else "B-Benit")
	_sell.disabled = not available or int(cargo.get(purchased_item,0)) < 1
	_sell.tooltip_text = "Dieser Händler kauft nur diesen Rohstoff aus der Schiffsfracht"
	var amount: float = _amount.value
	var cost: float = amount * float(supply.get("fuel_price_per_unit", 0.0))
	_refuel.text = "+%s Treibstoff · %s Cr" % [str(amount), str(cost)]
	var fuel_reason: String = ""
	if not available:
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
	_return.text = "Zum Planetenorbit abheben" if String(space.get("phase", "")) == "surface" and String(space.get("craft_id", "")) == _selected_craft_id else "Zur Heimatbasis"
	_return.disabled = bool(craft.get("busy", true)) or not available or _pending.has("return_homebase")
	_return.tooltip_text = "Rückflug erst nach bestätigter Landung am Versorgungsort" if _return.disabled else "Rückflug für dieses Schiff anfordern"
	if not available:
		_feedback.text = unavailable_reason
	elif not buy_reason.is_empty() and not fuel_reason.is_empty():
		_feedback.text = buy_reason + " · " + fuel_reason
	elif _feedback.text == unavailable_reason:
		_feedback.text = "Versorgung bereit"

func set_selected_craft(craft_id: String) -> bool:
	if not _pending.is_empty():
		return false
	for craft: Dictionary in Array(_snapshot.get("crafts", [])):
		if String(craft.get("craft_id", craft.get("id", ""))) == craft_id:
			_selected_craft_id = craft_id
			_feedback.text = ""
			refresh()
			return true
	return false

func _refresh_campaign_actions(supply: Dictionary) -> void:
	var campaign: Dictionary = _snapshot.get("campaign",{})
	var jobs: Dictionary = campaign.get("jobs",{})
	var progress: Dictionary = campaign.get("progress",{})
	var home := true
	for craft: Dictionary in Array(_snapshot.get("crafts",[])):
		home = home and String(craft.get("location_id","")) in ["homebase","waiting_pad"] and not bool(craft.get("busy",false))
	var has_chip := false
	for job: Dictionary in jobs.values(): has_chip = has_chip or String(job.get("status","")) == "pending_upload"
	for key in _campaign_buttons:
		var action: Dictionary = _campaign_buttons[key]
		var button: Button = action.button
		var show := String(_snapshot.get("mode","")) == "campaign"
		var enabled := home
		match String(action.operation):
			"campaign_upload": show = has_chip
			"campaign_recruit":
				show = show and String(Dictionary(jobs.get("outpost_recovery",{})).get("status","")) in ["active","completed"] and not bool(progress.get("recruited_outpost",false))
				enabled = not Dictionary(_snapshot.get("service_contexts_by_craft_id",{})).is_empty()
			"campaign_load_crate": show = show and String(Dictionary(jobs.get("outpost_recovery",{})).get("status","")) == "completed" and not bool(progress.get("crate_loaded",false))
			"campaign_build_pad": show = show and bool(progress.get("recruited_pilot",false)) and not bool(progress.get("second_pad_built",false))
			"campaign_fabricate":
				show = Array(supply.get("blueprints",[])).has(String(action.payload.blueprint_id))
		button.visible = show
		button.disabled = not enabled or not _command_handler.is_valid()
		button.tooltip_text = "Zur Basis zurückkehren" if not enabled else ""

func _submit_campaign(key: String) -> void:
	var action: Dictionary = _campaign_buttons.get(key,{})
	if action.is_empty() or action.button.disabled or not _command_handler.is_valid(): return
	var payload: Dictionary = Dictionary(action.payload).duplicate(true)
	payload["craft_id"] = _selected_craft_id
	_sequence += 1
	payload["request_id"] = "campaign-service:%d:%d" % [get_instance_id(),_sequence]
	var result: Dictionary = _command_handler.call(String(action.operation),payload)
	_feedback.text = String(result.get("message",result.get("reason","Aktion bestätigt")))
	refresh()

func _submit_sell() -> void:
	if _sell.disabled or not _command_handler.is_valid(): return
	var context: Dictionary = Dictionary(_snapshot.get("service_contexts_by_craft_id",{})).get(_selected_craft_id,{})
	var item := "c_benit" if String(context.get("location_id","")) == "satellite_crash" else "b_benit"
	_sequence += 1
	var result: Dictionary = _command_handler.call("sell",{"craft_id":_selected_craft_id,"item_id":item,"quantity":1,"request_id":"services-sell:%d:%d" % [get_instance_id(),_sequence]})
	_feedback.text = String(result.get("message",result.get("reason","Verkauf bestätigt")))
	refresh()

func _submit(operation: String) -> void:
	if _pending.has(operation):
		return
	var button: Button = _buy if operation == "buy" else (_refuel if operation == "refuel" else _return)
	if button.disabled or not _command_handler.is_valid():
		_feedback.text = button.tooltip_text
		return
	_sequence += 1
	var request_id: String = "services:%d:%d" % [get_instance_id(), _sequence]
	var payload: Dictionary = {"craft_id": _selected_craft_id, "request_id": request_id}
	if operation == "buy":
		payload["offer_id"] = OFFER_ID
		payload["quantity"] = 1
	elif operation == "refuel":
		payload["amount"] = _amount.value
	var pending: Dictionary = {"request_id": request_id, "payload": payload.duplicate(true), "revision": int(Dictionary(_snapshot.get("supply", {})).get("revision", -1)), "elapsed": false}
	_pending[operation] = pending
	button.disabled = true
	var result: Dictionary = _command_handler.call(operation, payload)
	pending["result"] = result.duplicate(true)
	_feedback.text = String(result.get("message", result.get("reason", "Anfrage gesendet")))
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
	return label

func _button(value: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = value
	button.custom_minimum_size.y = 42
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_size_override("font_size", 15)
	return button
