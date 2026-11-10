extends VBoxContainer
## Shared reference inventory. IDs/selection are presentation state only.
signal operation_requested(operation: String, payload: Dictionary)
const SURFACE = preload("res://scripts/meta/operations_drag_surface.gd")
const ITEMS = preload("res://scripts/mission/inventory_transfer_contract.gd")
const LABELS := {"armor_light":"Leichte Rüstung","armor_medium":"Mittlere Rüstung","armor_heavy":"Schwere Rüstung","rifle":"Sturmgewehr","smg":"Maschinenpistole","sniper":"Scharfschützengewehr","rail_gun":"Railgun","rocket_launcher":"Raketenwerfer","medictool":"Sanitätsgerät","ore":"Erz","salvage":"Bergungsgut","pistol":"Pistole","a_benit":"A-Benit","b_benit":"B-Benit","c_benit":"C-Benit","satellite_chip":"Satellitenchip","outpost_chip":"Außenpostenchip","c_benit_crate":"C-Benit-Kiste","mining_tool":"Hand-Mining-Tool","salvage_tool":"Bergungswerkzeug","none":"Leer"}
var _rest: CheckButton
var _signature := ""
var _unit_id := ""
var _craft_id := ""
var _selection: Dictionary = {}
var _slots: Control
var _body_preview:Control
var _containers: HFlowContainer
var _selected: Label
var _amount: SpinBox
var _target: OptionButton
var _slot_target: OptionButton
var _transfer: Button
var _equip: Button
var _bodies: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation",10)
	_rest=CheckButton.new(); _rest.name="AutomaticRest"; _rest.text="Automatisch ruhen"; add_child(_rest)
	_rest.tooltip_text="Bei Leerlauf an der Basis ein Bett aufsuchen. Ausschalten, um die Person stehen zu lassen."
	_rest.toggled.connect(func(enabled:bool): operation_requested.emit("base_auto_rest",{"unit_id":_unit_id,"enabled":enabled}))
	_slots=Control.new();_slots.name="EquipmentBody";_slots.custom_minimum_size=Vector2(340,310);add_child(_slots)
	_body_preview=preload("res://scripts/ui/components/personnel_body_preview.gd").new();_slots.add_child(_body_preview)
	_slots.resized.connect(_layout_body_slots)
	_containers=HFlowContainer.new(); add_child(_containers)
	_containers.add_theme_constant_override("h_separation",12)
	_selected=Label.new(); _selected.text="Gegenstand anklicken oder ziehen"; add_child(_selected)
	_selected.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var row:=HFlowContainer.new(); add_child(row)
	_amount=SpinBox.new(); _amount.min_value=1; _amount.max_value=200; _amount.value=1; row.add_child(_amount)
	_target=OptionButton.new(); row.add_child(_target)
	_transfer=Button.new(); _transfer.text="Verschieben →"; row.add_child(_transfer)
	_transfer.pressed.connect(func(): _move(String(_selection.get("source_container_id","")),String(_selection.get("item_id","")),String(_target.get_item_metadata(_target.selected)),int(_amount.value)) if _target.selected>=0 else null)
	var equipment_row:=HFlowContainer.new(); add_child(equipment_row)
	_slot_target=OptionButton.new(); equipment_row.add_child(_slot_target)
	for spec in [["armor","Rüstung"],["weapon_1","Primär"],["weapon_2","Sekundär"]]:
		_slot_target.add_item(spec[1]); _slot_target.set_item_metadata(_slot_target.item_count-1,spec[0])
	_equip=Button.new(); _equip.text="Anlegen"; equipment_row.add_child(_equip)
	_equip.pressed.connect(func(): _wear(_selection,String(_slot_target.get_item_metadata(_slot_target.selected))))

func update_snapshot(inventory: Dictionary, unit: Dictionary, craft_id: String, accessible: Array, equipment_allowed: bool=true, actor:Node=null) -> void:
	var next_id := String(unit.get("id",""))
	var selected_source := String(_selection.get("source_container_id",""))
	var selected_item := String(_selection.get("item_id",""))
	var selected_stock: Dictionary = Dictionary(Dictionary(inventory.get(selected_source,{})).get("items",{}))
	if next_id != _unit_id or not accessible.has(selected_source) or int(selected_stock.get(selected_item,0)) <= 0:
		_selection.clear()
		if _selected != null: _selected.text = "Gegenstand anklicken oder ziehen"
	_unit_id=next_id; _craft_id=craft_id
	var signature:=JSON.stringify([inventory,unit.get("loadout",{}),_unit_id,craft_id,accessible,equipment_allowed,actor.get_instance_id() if actor!=null else 0])
	if signature==_signature: return
	_signature=signature
	for child in _slots.get_children():
		if child!=_body_preview:
			_slots.remove_child(child);child.queue_free()
	for child in _containers.get_children():
		_containers.remove_child(child);child.queue_free()
	_target.clear(); _bodies.clear()
	var loadout: Dictionary=unit.get("loadout",{})
	_body_preview.call("update_actor",actor,loadout)
	for spec in [["armor","Rüstung"],["weapon_1","Primär"],["weapon_2","Sekundär"]]:
		var key: String=spec[0]
		var item: String=ITEMS.item_from_slot(key,String(loadout.get(key,"none")))
		var slot: PanelContainer=SURFACE.new(); slot.name="InventorySlot_"+key
		slot.accepted_type="inventory_item"; slot.custom_minimum_size=Vector2(130,66); _slots.add_child(slot)
		var slot_body:=HBoxContainer.new(); slot_body.mouse_filter=Control.MOUSE_FILTER_IGNORE; slot.add_child(slot_body)
		var icon:=TextureRect.new(); icon.texture=_item_icon(item); icon.custom_minimum_size=Vector2(48,60); icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.mouse_filter=Control.MOUSE_FILTER_IGNORE; slot_body.add_child(icon)
		var label:=Label.new(); label.text=spec[1]+"\n"+String(LABELS.get(item,item));label.custom_minimum_size.x=76;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; label.mouse_filter=Control.MOUSE_FILTER_IGNORE; slot_body.add_child(label)
		slot.payload_dropped.connect(func(data:Dictionary): _wear(data,key))
	_layout_body_slots()
	for spec in [["base:homebase","Basislager"],["craft:"+craft_id,"Schiffsfracht"],["unit:"+_unit_id+":backpack","Rucksack"]]:
		var id: String=spec[0]
		var data: Dictionary=inventory.get(id,{})
		var box: PanelContainer=SURFACE.new(); box.name="Inventory_"+id.validate_node_name(); box.accepted_type="inventory_item"; box.custom_minimum_size=Vector2(280 if id=="base:homebase" else 200,160); _containers.add_child(box)
		box.payload_dropped.connect(func(item:Dictionary): _move(String(item.get("source_container_id","")),String(item.get("item_id","")),id,1))
		var style:=StyleBoxFlat.new(); style.bg_color=Color("102f3b"); style.border_color=Color("3e6972"); style.set_border_width_all(1); style.content_margin_left=8; style.content_margin_right=8; style.content_margin_top=8; style.content_margin_bottom=8; box.add_theme_stylebox_override("panel",style)
		var body:=VBoxContainer.new(); box.add_child(body); _bodies[id]=body
		var header:=Label.new(); header.text="%s · %d/%d" % [spec[1],ITEMS.used(data.get("items",{})),int(data.get("capacity",0))]; body.add_child(header)
		if id=="base:homebase":header.text=header.text.replace("Basislager","Basislager · frei");header.tooltip_text="Freier Lagerbestand. Getragene Gegenstände stehen ausschließlich an der Person und werden hier nicht mitgezählt."
		var allowed: bool=accessible.has(id)
		if not allowed:
			var locked:=Label.new(); locked.text="Hier nicht erreichbar"; body.add_child(locked)
		else:
			_target.add_item(spec[1]); _target.set_item_metadata(_target.item_count-1,id)
		var grid:=GridContainer.new(); grid.columns=2; body.add_child(grid)
		for item in Dictionary(data.get("items",{})):
			var source: PanelContainer=SURFACE.new(); source.drag_payload={"type":"inventory_item","source_container_id":id,"item_id":item,"label":String(LABELS.get(item,item))} if allowed else {}; grid.add_child(source)
			var button:=Button.new(); button.text="%s\n× %d" % [String(LABELS.get(item,item)).replace("Maschinenpistole","Maschinen-\npistole"),int(data.items[item])]; button.icon=_item_icon(String(item)); button.expand_icon=true; button.add_theme_constant_override("icon_max_width",42); button.custom_minimum_size=Vector2(126,78); button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; button.disabled=not allowed; source.add_child(button); source.forward_drag_from(button)
			button.pressed.connect(func(): _selection={"source_container_id":id,"item_id":item}; _selected.text=String(LABELS.get(item,item))+" · "+String(spec[1]))
		if Dictionary(data.get("items",{})).is_empty():
			var empty:=Label.new(); empty.text="Leer · Gegenstand hierher ziehen"; empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(empty)
	_transfer.disabled=accessible.is_empty(); _equip.disabled=accessible.is_empty() or not equipment_allowed

func _layout_body_slots()->void:
	if _body_preview==null:return
	var width:float=maxf(_slots.size.x,340)
	_body_preview.position=Vector2((width-180)/2,0);_body_preview.size=Vector2(180,300)
	for key:String in ["armor","weapon_1","weapon_2"]:
		var slot:=_slots.get_node_or_null("InventorySlot_"+key) as Control
		if slot==null:continue
		slot.size=Vector2(130,66)
		slot.position=Vector2((width-slot.size.x)/2,80) if key=="armor" else Vector2(0 if key=="weapon_1" else width-slot.size.x,186)

func update_rest_snapshot(person: Dictionary) -> void:
	_rest.visible=not person.is_empty()
	_rest.set_pressed_no_signal(bool(person.get("auto_rest_enabled",true)))

func _move(source: String, item: String, target: String, amount: int) -> void:
	operation_requested.emit("inventory_transfer",{"unit_id":_unit_id,"craft_id":_craft_id,"source_container_id":source,"destination_container_id":target,"item_id":item,"amount":amount})
func _wear(data: Dictionary, slot: String) -> void:
	operation_requested.emit("inventory_equip",{"unit_id":_unit_id,"craft_id":_craft_id,"source_container_id":String(data.get("source_container_id","")),"item_id":String(data.get("item_id","")),"slot":slot})


func _item_icon(item: String) -> Texture2D:
	if item in ["armor_light","armor_medium","armor_heavy"]: return load("res://Assets/curated/ui/campaign_inventory/"+item+".svg")
	if item.ends_with("_benit"): return load("res://Assets/curated/ui/campaign_inventory/benit.svg")
	if item.ends_with("_chip") or item.ends_with("_crate"): return load("res://Assets/curated/ui/campaign_inventory/chip.svg")
	var weapons=load("res://scripts/core/weapon_data.gd")
	var entry: Dictionary=Dictionary(weapons.WEAPON_CATALOG.get(item,{}))
	var path:=String(entry.get("preview_path",""))
	return load(path) if not path.is_empty() and ResourceLoader.exists(path) else null
