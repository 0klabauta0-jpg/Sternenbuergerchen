extends VBoxContainer
## Two visible containers, quantities and drop intent; the host owns every transfer.
signal command_requested(command: Dictionary)
signal feedback(message: String)
const Catalog=preload("res://scripts/core/catalog.gd")
const Icons=preload("res://scripts/ui/hud_icons.gd")
const Slot=preload("res://scripts/ui/equipment_slot.gd")
var footer: VBoxContainer
var _state: Dictionary={}
var _lists: Dictionary={}
var _rows: Dictionary={}
var _headers: Dictionary={}
var _amount: SpinBox
var _claim: Button
var _cancel:Button
var _status: Label
func _ready() -> void:
	var top:=HBoxContainer.new();add_child(top)
	var label:=Label.new();label.text="Menge pro Verladung";label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(label)
	_amount=SpinBox.new();_amount.min_value=1;_amount.max_value=10000000;_amount.value=1;_amount.custom_minimum_size.x=95;top.add_child(_amount)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);add_child(row)
	for container: String in ["inventory","cargo"]:
		var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.custom_minimum_size.x=166;row.add_child(column)
		var header:=_slot(container);header.text="Basislager" if container=="inventory" else "Schiffsfracht";header.icon=Icons.texture("storage" if container=="inventory" else "shuttle");column.add_child(header);_headers[container]=header
		var list:=VBoxContainer.new();column.add_child(list);_lists[container]=list
	_status=Label.new();_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_status.add_theme_font_size_override("font_size",13);footer.add_child(_status)
	_cancel=Button.new();_cancel.text="Verladung abbrechen · Kisten bleiben liegen";_cancel.pressed.connect(func():command_requested.emit({"type":"cancel_hauling"}));footer.add_child(_cancel)
	_claim=Button.new();_claim.text="Blackbox abgeben · +260 Cr + Bauplan";_claim.custom_minimum_size.y=40;_claim.pressed.connect(func():command_requested.emit({"type":"claim_contract"}));footer.add_child(_claim)
func _slot(container: String) -> Button:
	var button:=Slot.new();button.target={"to":container};button.accept=_reject;button.amount=func():return int(_amount.value)
	button.dropped.connect(_drop);button.rejected.connect(func(reason: String):feedback.emit(reason))
	button.add_theme_font_size_override("font_size",13)
	return button
func present(state: Dictionary) -> void:
	_state=state
	for container: String in ["inventory","cargo"]:
		var items: Dictionary=state.get(container,{})
		var used:=0
		for quantity: Variant in items.values():used+=int(quantity)
		_headers[container].text=("Basislager\nHier ausladen" if container=="inventory" else "Schiffsfracht\n%d / %d Plätze" % [used,int(state.ship.capacity)])
		for item: String in Catalog.ITEMS:
			var key:=container+":"+item;var quantity:=int(items.get(item,0))
			if quantity<=0:
				if _rows.has(key):_rows[key].hide()
				continue
			if not _rows.has(key):
				var button:=_slot(container);_lists[container].add_child(button);_rows[key]=button
				button.pressed.connect(func():_drop({"from":container,"item":item,"amount":mini(int(_amount.value),int(_state[container].get(item,0)))},{"to":"cargo" if container=="inventory" else "inventory"}))
			var button: Button=_rows[key];button.show();button.text=Catalog.item_name(item)+"\n%d Stück · %d Plätze" % [quantity,quantity]
			button.icon=Icons.texture(item if Icons.SHAPES.has(item) else "storage")
			button.source={"from":container,"item":item,"available":quantity}
			button.tooltip_text="Ziehen auf "+("Schiffsfracht" if container=="inventory" else "Basislager")+" oder klicken. 1 Stück = 1 Frachtplatz."
	_claim.visible=state.contract.status=="recovered"
	_claim.disabled=int(state.inventory.blackbox)<1 or state.region!="base" or state.paused
	_status.text="Ware auf den anderen Behälter ziehen. Klick beauftragt NPCs mit der gewählten Menge."
	if state.contract.status=="recovered":_status.text="Blackbox im Lager. Jetzt Belohnung abholen." if int(state.inventory.blackbox)>0 else "Blackbox aus dem Schiff ins Basislager ziehen. Danach hier abgeben."
	if state.contract.status=="claimed":_status.text="Auftrag bezahlt: 260 Credits + Schneider-Bauplan."
	_cancel.visible=not state.get("hauling",{"jobs":[]}).jobs.is_empty()
	if _cancel.visible:_status.text=preload("res://scripts/core/cargo_hauling.gd").summary(state)
	var unavailable:=_access_error()
	if not unavailable.is_empty():_status.text=unavailable+"\n"+_status.text
func _access_error() -> String:
	if _state.get("paused",false):return "Pause aufheben, um zu verladen."
	if _state.get("region","")!="base":return "Ausladen im Basislager: zur Rostgrenze zurückkehren."
	var ship: Dictionary=_state.ship;var dock: Array=Catalog.landmarks("base").shuttle
	if ship.mode!="landed" or Vector2(ship.position[0],ship.position[1]).distance_to(Vector2(dock[0],dock[1]))>20:return "Am markierten Heimatdock landen, dann hier ausladen."
	return ""
func _reject(data: Dictionary,target: Dictionary) -> String:
	if not data.get("from","") in ["inventory","cargo"] or not target.get("to","") in ["inventory","cargo"] or data.get("from")==target.get("to"):return "Auf den anderen Behälter ziehen."
	if not Catalog.ITEMS.has(data.get("item","")):return "Unbekannte Ware."
	return _access_error()
func _drop(data: Dictionary,target: Dictionary) -> void:
	var reason:=_reject(data,target)
	if not reason.is_empty():feedback.emit(reason);return
	command_requested.emit({"type":"transfer","item":data.item,"amount":data.amount,"direction":"load" if target.to=="cargo" else "unload"})
