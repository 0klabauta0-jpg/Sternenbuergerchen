extends VBoxContainer
## Shared reference inventory. IDs/selection are presentation state only.
signal operation_requested(operation: String, payload: Dictionary)
const SURFACE = preload("res://scripts/meta/operations_drag_surface.gd")
const ITEMS = preload("res://scripts/mission/inventory_transfer_contract.gd")
const SKIN=preload("res://scripts/ui/base_management_skin.gd")
const MENU_ICONS=preload("res://scripts/ui/menu_equipment_icons.gd")
const BADGES=preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const COPY=preload("res://scripts/meta/character_sheet_copy.gd")
const LABELS := {"armor_light":"Leichte Rüstung","armor_medium":"Mittlere Rüstung","armor_heavy":"Schwere Rüstung","rifle":"Sturmgewehr","smg":"Maschinenpistole","sniper":"Scharfschützengewehr","rail_gun":"Railgun","rocket_launcher":"Raketenwerfer","medictool":"Sanitätsgerät","ore":"Erz","salvage":"Bergungsgut","pistol":"Pistole","a_benit":"A-Benit","b_benit":"B-Benit","c_benit":"C-Benit","satellite_chip":"Satellitenchip","outpost_chip":"Außenpostenchip","c_benit_crate":"C-Benit-Kiste","mining_tool":"Hand-Mining-Tool","salvage_tool":"Bergungswerkzeug","none":"Leer"}
var _rest: CheckButton
var _signature := ""
var _unit_id := ""
var _craft_id := ""
var _selection: Dictionary = {}
var _slots: Control
var _body_preview:Control
var _body_frame:Panel
var _containers: HFlowContainer
var _selected: Label
var _amount: SpinBox
var _target: OptionButton
var _slot_target: OptionButton
var _transfer: Button
var _equip: Button
var _bodies: Dictionary = {}
var _rest_row:HBoxContainer
var _identity:Control
var _identity_portrait:TextureRect
var _identity_name:Label
var _main_role:Label
var _secondary_role:Label
var _condition:Label
var _badges:HFlowContainer
var _identity_signature:String=""
var _bag_preview:PanelContainer
var _bag_grid:GridContainer
var _bag_items:Dictionary={}
var _accessible:Array=[]

func _ready() -> void:
	add_theme_constant_override("separation",10)
	var code:=Label.new();code.text="LA-04  /  AUSRÜSTUNG & FREIER BESTAND";SKIN.eyebrow(code);add_child(code)
	_rest_row=HBoxContainer.new();_rest_row.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;_rest_row.add_theme_constant_override("separation",4);add_child(_rest_row)
	_rest=CheckButton.new(); _rest.name="AutomaticRest"; _rest.text="";_rest.custom_minimum_size=Vector2(48,28); _rest_row.add_child(_rest)
	var rest_label:=Label.new();rest_label.text="Automatisch ruhen";SKIN.label(rest_label,15);rest_label.autowrap_mode=TextServer.AUTOWRAP_OFF;_rest_row.add_child(rest_label)
	_rest.tooltip_text="Bei Leerlauf an der Basis ein Bett aufsuchen. Ausschalten, um die Person stehen zu lassen."
	_rest.toggled.connect(func(enabled:bool): operation_requested.emit("base_auto_rest",{"unit_id":_unit_id,"enabled":enabled}))
	_slots=Control.new();_slots.name="EquipmentBody";_slots.custom_minimum_size=Vector2(360,460);add_child(_slots)
	_body_frame=Panel.new();_body_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;_body_frame.show_behind_parent=true;SKIN.panel(_body_frame,true);_slots.add_child(_body_frame)
	_body_preview=preload("res://scripts/ui/components/personnel_body_preview.gd").new();_slots.add_child(_body_preview)
	_build_identity()
	_bag_preview=SURFACE.new();_bag_preview.name="CarriedBackpack";SKIN.panel(_bag_preview,true);_slots.add_child(_bag_preview)
	var bag_body:=VBoxContainer.new();_bag_preview.add_child(bag_body)
	var bag_heading:=Label.new();bag_heading.text="Rucksack";SKIN.label(bag_heading,16);bag_body.add_child(bag_heading)
	var bag_scroll:=ScrollContainer.new();bag_scroll.custom_minimum_size.y=240;bag_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;bag_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;bag_body.add_child(bag_scroll)
	_bag_grid=GridContainer.new();_bag_grid.columns=2;bag_scroll.add_child(_bag_grid)
	_bag_preview.payload_dropped.connect(func(data:Dictionary):_move(String(data.get("source_container_id","")),String(data.get("item_id","")),"unit:"+_unit_id+":backpack",1))
	_slots.draw.connect(_draw_equipment_guides)
	_slots.resized.connect(_layout_body_slots)
	_containers=HFlowContainer.new(); add_child(_containers)
	_containers.add_theme_constant_override("h_separation",12)
	_selected=Label.new(); _selected.text="Gegenstand anklicken oder ziehen"; add_child(_selected)
	SKIN.label(_selected,15,true)
	_selected.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var row:=HFlowContainer.new(); add_child(row)
	_amount=SpinBox.new(); _amount.min_value=1; _amount.max_value=200; _amount.value=1; row.add_child(_amount)
	_target=OptionButton.new(); row.add_child(_target)
	_transfer=Button.new(); _transfer.text="Verschieben →"; row.add_child(_transfer)
	SKIN.button(_transfer)
	_transfer.pressed.connect(func(): _move(String(_selection.get("source_container_id","")),String(_selection.get("item_id","")),String(_target.get_item_metadata(_target.selected)),int(_amount.value)) if _target.selected>=0 else null)
	var equipment_row:=HFlowContainer.new(); add_child(equipment_row)
	_slot_target=OptionButton.new(); equipment_row.add_child(_slot_target)
	for spec in [["armor","Rüstung"],["weapon_1","Primär"],["weapon_2","Sekundär"]]:
		_slot_target.add_item(spec[1]); _slot_target.set_item_metadata(_slot_target.item_count-1,spec[0])
	_equip=Button.new(); _equip.text="Anlegen"; equipment_row.add_child(_equip)
	SKIN.button(_equip,true)
	_equip.pressed.connect(func(): _wear(_selection,String(_slot_target.get_item_metadata(_slot_target.selected))))

func update_snapshot(inventory: Dictionary, unit: Dictionary, craft_id: String, accessible: Array, equipment_allowed: bool=true, actor:Node=null) -> void:
	_update_identity(unit)
	_accessible=accessible
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
		if child not in [_body_preview,_body_frame,_identity,_bag_preview]:
			_slots.remove_child(child);child.queue_free()
	for child in _containers.get_children():
		_containers.remove_child(child);child.queue_free()
	_target.clear(); _bodies.clear()
	var loadout: Dictionary=unit.get("loadout",{})
	_bag_items=Dictionary(Dictionary(inventory.get("unit:"+_unit_id+":backpack",{})).get("items",{}))
	_refresh_bag_preview()
	_body_preview.call("update_actor",actor,loadout)
	for spec in [["armor","Rüstung"],["weapon_1","Primär"],["weapon_2","Sekundär"]]:
		var key: String=spec[0]
		var item: String=ITEMS.item_from_slot(key,String(loadout.get(key,"none")))
		var slot: PanelContainer=SURFACE.new(); slot.name="InventorySlot_"+key
		slot.add_theme_stylebox_override("panel",SKIN.box(SKIN.CARD,4))
		slot.accepted_type="inventory_item" if equipment_allowed else ""; slot.custom_minimum_size=Vector2(130,66); _slots.add_child(slot)
		var slot_body:=HBoxContainer.new(); slot_body.mouse_filter=Control.MOUSE_FILTER_IGNORE; slot.add_child(slot_body)
		var icon:=TextureRect.new(); icon.texture=_item_icon(item); icon.custom_minimum_size=Vector2(72,72); icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.mouse_filter=Control.MOUSE_FILTER_IGNORE; slot_body.add_child(icon)
		var label:=Label.new(); label.text=spec[1]+"\n"+String(LABELS.get(item,item));label.custom_minimum_size.x=130;label.add_theme_font_size_override("font_size",16);label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; label.mouse_filter=Control.MOUSE_FILTER_IGNORE; slot_body.add_child(label)
		slot.payload_dropped.connect(func(data:Dictionary): _wear(data,key))
	_layout_body_slots()
	for spec in [["base:homebase","Basislager"],["craft:"+craft_id,"Schiffsfracht"],["unit:"+_unit_id+":backpack","Rucksack"]]:
		var id: String=spec[0]
		var data: Dictionary=inventory.get(id,{})
		var box: PanelContainer=SURFACE.new(); box.name="Inventory_"+id.validate_node_name(); box.accepted_type="inventory_item"; box.custom_minimum_size=Vector2(280 if id=="base:homebase" else 200,160); _containers.add_child(box)
		box.payload_dropped.connect(func(item:Dictionary): _move(String(item.get("source_container_id","")),String(item.get("item_id","")),id,1))
		var style:=StyleBoxFlat.new(); style.bg_color=Color("102f3b"); style.border_color=Color("3e6972"); style.set_border_width_all(1); style.content_margin_left=8; style.content_margin_right=8; style.content_margin_top=8; style.content_margin_bottom=8; box.add_theme_stylebox_override("panel",style)
		SKIN.panel(box,true)
		var body:=VBoxContainer.new(); box.add_child(body); _bodies[id]=body
		var header:=Label.new(); header.text="%s · %d/%d" % [spec[1],ITEMS.used(data.get("items",{})),int(data.get("capacity",0))]; body.add_child(header)
		if id=="base:homebase":header.text=header.text.replace("Basislager","Basislager · frei");header.tooltip_text="Freier Lagerbestand. Getragene Gegenstände stehen ausschließlich an der Person und werden hier nicht mitgezählt."
		SKIN.label(header,15)
		var allowed: bool=accessible.has(id)
		if not equipment_allowed and id!="unit:"+_unit_id+":backpack" and not allowed:box.hide()
		if not allowed:
			var locked:=Label.new(); locked.text="Hier nicht erreichbar"; body.add_child(locked)
		else:
			_target.add_item(spec[1]); _target.set_item_metadata(_target.item_count-1,id)
		var grid:=GridContainer.new(); grid.columns=2; body.add_child(grid)
		for item in Dictionary(data.get("items",{})):
			var source: PanelContainer=SURFACE.new(); source.drag_payload={"type":"inventory_item","source_container_id":id,"item_id":item,"label":String(LABELS.get(item,item))} if allowed else {}; grid.add_child(source)
			var button:=Button.new(); button.text="%s\n× %d" % [String(LABELS.get(item,item)).replace("Maschinenpistole","Maschinen-\npistole"),int(data.items[item])]; button.icon=_item_icon(String(item)); button.expand_icon=true; button.add_theme_constant_override("icon_max_width",42); button.custom_minimum_size=Vector2(126,78); button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; button.disabled=not allowed; source.add_child(button); source.forward_drag_from(button)
			SKIN.button(button);button.custom_minimum_size.y=78;button.add_theme_font_size_override("font_size",14);button.add_theme_constant_override("icon_max_width",32);button.text=button.text.replace(" Rüstung","\nRüstung")
			if id.begins_with("unit:"):
				button.name="BackpackItem_"+String(item)+"_List";button.text="";button.custom_minimum_size=Vector2(64,64);button.add_theme_constant_override("icon_max_width",52);button.tooltip_text="%s × %d"%[String(LABELS.get(item,item)),int(data.items[item])]
			button.pressed.connect(func(): _selection={"source_container_id":id,"item_id":item}; _selected.text=String(LABELS.get(item,item))+" · "+String(spec[1]))
		if Dictionary(data.get("items",{})).is_empty():
			var empty:=Label.new(); empty.text="Leer · Gegenstand hierher ziehen"; empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(empty)
	_transfer.disabled=accessible.is_empty(); _equip.disabled=accessible.is_empty() or not equipment_allowed
	_layout_body_slots()

func _layout_body_slots()->void:
	if _body_preview==null:return
	var width:float=maxf(_slots.size.x,360)
	var wide:bool=width>=700
	var left:float=280 if wide else 190
	var show_bag:bool=width>=760
	var height:float=464 if wide else 512
	_slots.custom_minimum_size.y=height
	_body_frame.size=Vector2(width,height)
	var body_width:float=minf(300,width-left-(180 if show_bag else 20))
	var body_size:=Vector2(maxf(body_width,140),450)
	_body_preview.custom_minimum_size=body_size;_body_preview.position=Vector2(left,4);_body_preview.size=body_size
	_identity.position=Vector2(12,10);_identity.size=Vector2(left-20,190 if wide else 236)
	_identity_portrait.position=Vector2.ZERO;_identity_portrait.size=Vector2(90,104) if wide else Vector2(64,74)
	var text_x:float=100 if wide else 0
	_identity_name.position=Vector2(text_x,0 if wide else 76);_identity_name.size=Vector2(left-24-text_x,28)
	_main_role.position=Vector2(text_x,36 if wide else 104);_main_role.size=Vector2(left-24-text_x,36)
	_secondary_role.position=Vector2(0,108 if wide else 142);_secondary_role.size=Vector2(left-24,24)
	_condition.position=Vector2(0,130 if wide else 166);_condition.size=Vector2(left-24,20 if wide else 28)
	_badges.position=Vector2(0,152 if wide else 198);_badges.size=Vector2(left-24,34)
	_bag_preview.visible=show_bag
	_bag_preview.position=Vector2(width-172,148);_bag_preview.size=Vector2(164,300)
	var bag_body:Node=_bodies.get("unit:"+_unit_id+":backpack")
	if bag_body!=null:(bag_body.get_parent() as Control).visible=not show_bag
	for key:String in ["armor","weapon_1","weapon_2"]:
		var slot:=_slots.get_node_or_null("InventorySlot_"+key) as Control
		if slot==null:continue
		var slot_width:float=left-24
		slot.custom_minimum_size=Vector2(slot_width,80);slot.size=Vector2(slot_width,80)
		slot.position=Vector2(12,(204 if wide else 252)+84*["armor","weapon_1","weapon_2"].find(key))
		var icon:TextureRect=slot.get_child(0).get_child(0)
		icon.custom_minimum_size=Vector2(72,72) if wide else Vector2(48,48)
		var label:Label=slot.get_child(0).get_child(1)
		label.custom_minimum_size.x=130 if wide else 100;label.add_theme_font_size_override("font_size",16 if wide else 14)
	_slots.queue_redraw()

func _build_identity()->void:
	_identity=Control.new();_identity.name="SharedPersonnelIdentity";_slots.add_child(_identity)
	_identity_portrait=TextureRect.new();_identity_portrait.name="IdentityPortrait";_identity_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;_identity_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;_identity.add_child(_identity_portrait)
	_identity_name=_identity_label("IdentityName",22)
	_main_role=_identity_label("PrimaryRole",15)
	_secondary_role=_identity_label("SecondaryRole",14)
	_secondary_role.max_lines_visible=1;_secondary_role.clip_text=true;_secondary_role.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	_condition=_identity_label("PersonnelCondition",14)
	_badges=HFlowContainer.new();_badges.name="PersonnelBadges";_badges.add_theme_constant_override("h_separation",6);_identity.add_child(_badges)

func _identity_label(node_name:String,font_size:int)->Label:
	var label:=Label.new();label.name=node_name;SKIN.label(label,font_size);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;_identity.add_child(label);return label

func _update_identity(unit:Dictionary)->void:
	var signature:String=JSON.stringify([unit.get("name",""),unit.get("role",""),unit.get("secondary_role",""),unit.get("condition",""),unit.get("status",""),unit.get("portrait_id",""),unit.get("portrait_path",""),unit.get("badges",[])])
	if signature==_identity_signature:return
	_identity_signature=signature
	_identity_portrait.texture=load("res://scripts/meta/portrait_identity_catalog.gd").load_texture(String(unit.get("portrait_id","")),String(unit.get("portrait_path","")))
	_identity_name.text=String(unit.get("name",""));_main_role.text="Hauptrolle: "+COPY.text(String(unit.get("role","")))
	var secondary:String=String(unit.get("secondary_role",""));_secondary_role.text="Nebenrolle: "+COPY.text(secondary if not secondary.is_empty() else "—")
	_condition.text=COPY.text(String(unit.get("status",unit.get("condition",""))))
	for child:Node in _badges.get_children():_badges.remove_child(child);child.queue_free()
	for badge:Dictionary in unit.get("badges",[]):
		var label:=Label.new();label.text=String(badge.get("label",""));SKIN.label(label,14);label.autowrap_mode=TextServer.AUTOWRAP_OFF;label.mouse_filter=Control.MOUSE_FILTER_STOP;BADGES.apply_badge_help_metadata(label,badge);label.tooltip_text=BADGES.format_badge_tooltip(badge);_badges.add_child(label)
	var condition:String=COPY.text(String(unit.get("condition","")))
	if not condition.is_empty() and condition!=_condition.text:
		var readiness:=Label.new();readiness.name="ReadinessStatus";readiness.text=condition;SKIN.label(readiness,14);readiness.autowrap_mode=TextServer.AUTOWRAP_OFF;readiness.add_theme_color_override("font_color",SKIN.CYAN);_badges.add_child(readiness)

func _refresh_bag_preview()->void:
	for child:Node in _bag_grid.get_children():_bag_grid.remove_child(child);child.queue_free()
	var id:String="unit:"+_unit_id+":backpack"
	var allowed:bool=_accessible.has(id)
	_bag_preview.accepted_type="inventory_item" if allowed else ""
	for item:String in _bag_items:
		var source:PanelContainer=SURFACE.new();source.drag_payload={"type":"inventory_item","source_container_id":id,"item_id":item,"label":String(LABELS.get(item,item))} if allowed else {};_bag_grid.add_child(source)
		var button:=Button.new();button.name="BackpackItem_"+item;button.icon=_item_icon(item);button.expand_icon=true;button.custom_minimum_size=Vector2(62,64);button.add_theme_constant_override("icon_max_width",52);button.tooltip_text="%s × %d"%[String(LABELS.get(item,item)),int(_bag_items[item])];source.add_child(button);source.forward_drag_from(button)
		button.pressed.connect(func():_selection={"source_container_id":id,"item_id":item};_selected.text=String(LABELS.get(item,item)))
	if _bag_items.is_empty():
		var empty:=Label.new();empty.text="Leer";SKIN.label(empty,14,true);empty.autowrap_mode=TextServer.AUTOWRAP_OFF;_bag_grid.add_child(empty)

func _draw_equipment_guides()->void:
	if _body_preview==null:return
	var target:Vector2=_body_preview.position+_body_preview.size*Vector2(.5,.44)
	for key:String in ["armor","weapon_1","weapon_2"]:
		var slot:=_slots.get_node_or_null("InventorySlot_"+key) as Control
		if slot==null:continue
		var end:Vector2=target if key=="armor" else target+Vector2(-30 if key=="weapon_1" else 30,100)
		_slots.draw_line(slot.position+Vector2(slot.size.x+3,slot.size.y*.5),end,Color(.4,.78,.77,.6),1,true)
		_slots.draw_circle(end,2,Color(.4,.78,.77,.8))

func update_rest_snapshot(person: Dictionary) -> void:
	_rest_row.visible=not person.is_empty()
	_rest.set_pressed_no_signal(bool(person.get("auto_rest_enabled",true)))

func _move(source: String, item: String, target: String, amount: int) -> void:
	operation_requested.emit("inventory_transfer",{"unit_id":_unit_id,"craft_id":_craft_id,"source_container_id":source,"destination_container_id":target,"item_id":item,"amount":amount})
func _wear(data: Dictionary, slot: String) -> void:
	operation_requested.emit("inventory_equip",{"unit_id":_unit_id,"craft_id":_craft_id,"source_container_id":String(data.get("source_container_id","")),"item_id":String(data.get("item_id","")),"slot":slot})


func _item_icon(item: String) -> Texture2D:
	var illustrated:=MENU_ICONS.get_icon(item)
	if illustrated!=null:return illustrated
	if item in ["armor_light","armor_medium","armor_heavy"]: return load("res://Assets/curated/ui/campaign_inventory/"+item+".svg")
	if item.ends_with("_benit"): return load("res://Assets/curated/ui/campaign_inventory/benit.svg")
	if item.ends_with("_chip") or item.ends_with("_crate"): return load("res://Assets/curated/ui/campaign_inventory/chip.svg")
	var weapons=load("res://scripts/core/weapon_data.gd")
	var entry: Dictionary=Dictionary(weapons.WEAPON_CATALOG.get(item,{}))
	var path:=String(entry.get("preview_path",""))
	return load(path) if not path.is_empty() and ResourceLoader.exists(path) else null
