extends VBoxContainer
## Shared reference inventory. IDs/selection are presentation state only.
signal operation_requested(operation: String, payload: Dictionary)
const SURFACE = preload("res://scripts/meta/operations_drag_surface.gd")
const ITEMS = preload("res://scripts/mission/inventory_transfer_contract.gd")
const SKIN=preload("res://scripts/ui/base_management_skin.gd")
const MENU_ICONS=preload("res://scripts/ui/menu_equipment_icons.gd")
const BADGES=preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const COPY=preload("res://scripts/meta/character_sheet_copy.gd")
const PORTRAITS=preload("res://scripts/meta/portrait_identity_catalog.gd")
const PORTRAIT_SIZE := Vector2(112, 140)
const MODEL_HEIGHT := 500.0
# PC density, user decision 14.11.2026 (home base P6): body slots and storage tiles.
const SLOT_HEIGHT := 60.0
const SLOT_WIDTH_WIDE := 240.0
const SLOT_WIDTH_NARROW := 216.0
const SLOT_ICON := Vector2(48, 48)
const STORAGE_TILE_SIZE := Vector2(110, 64)
const STORAGE_TILE_ICON := 28
const STORAGE_TILE_PADDING := Vector2(6, 4)
const LABELS := {"suit":"Anzug","armor_light":"Leichte Rüstung","armor_medium":"Mittlere Rüstung","armor_heavy":"Schwere Rüstung","rifle":"Sturmgewehr","smg":"Maschinenpistole","sniper":"Scharfschützengewehr","rail_gun":"Railgun","rocket_launcher":"Raketenwerfer","medictool":"Sanitätsgerät","ore":"Erz","salvage":"Bergungsgut","pistol":"Pistole","a_benit":"A-Benit","b_benit":"B-Benit","c_benit":"C-Benit","satellite_chip":"Satellitenchip","outpost_chip":"Außenpostenchip","c_benit_crate":"C-Benit-Kiste","mining_tool":"Hand-Mining-Tool","salvage_tool":"Bergungswerkzeug","backpack":"Rucksack","ammo_light":"Magazin leicht","ammo_rifle":"Magazin Gewehr","ammo_rail":"Schienenladung","ammo_rocket":"Rakete","none":"Leer"}
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
var _remove_backpack: Button
var _remove_armor: Button
var _bodies: Dictionary = {}
var _rest_row:HBoxContainer
var _identity:HBoxContainer
var _identity_portrait:TextureRect
var _identity_name:Label
var _main_role:Label
var _secondary_role:Label
var _condition:Label
var _readiness:Label
var _badges:HBoxContainer
var _identity_signature:String=""
var _bag_preview:PanelContainer
var _bag_grid:GridContainer
var _bag_heading: Label
var _personal_storage: Dictionary = {}
var _accessible:Array=[]

static func get_preferred_character_column_width(viewport_width: float) -> float:
	if viewport_width >= 1500:
		return 850
	return clampf(viewport_width * 0.52, 360, 660)

func _ready() -> void:
	add_theme_constant_override("separation",10)
	_slots=Control.new();_slots.name="EquipmentBody";_slots.custom_minimum_size=Vector2(360,508);add_child(_slots)
	_body_frame=Panel.new();_body_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;_body_frame.show_behind_parent=true;SKIN.panel(_body_frame,true);_slots.add_child(_body_frame)
	_body_preview=preload("res://scripts/ui/components/personnel_body_preview.gd").new();_slots.add_child(_body_preview)
	_build_identity()
	_bag_preview=SURFACE.new();_bag_preview.name="CarriedBackpack";SKIN.panel(_bag_preview,true);_slots.add_child(_bag_preview)
	var bag_body:=VBoxContainer.new();_bag_preview.add_child(bag_body)
	_bag_heading = Label.new()
	_bag_heading.name = "CarriedStorageHeading"
	SKIN.label(_bag_heading, 15)
	bag_body.add_child(_bag_heading)
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
	for spec in [["armor","Rüstung"],["weapon_1","Primär"],["weapon_2","Sekundär"],["backpack","Rucksack"]]:
		_slot_target.add_item(spec[1]); _slot_target.set_item_metadata(_slot_target.item_count-1,spec[0])
	_equip=Button.new(); _equip.text="Anlegen"; equipment_row.add_child(_equip)
	SKIN.button(_equip,true)
	_equip.pressed.connect(func(): _wear(_selection,String(_slot_target.get_item_metadata(_slot_target.selected))))
	var help := preload("res://scripts/ui/campaign_context_help.gd").new()
	help.top_level = true
	_slots.add_child(help)
	help.bind_target(_equip, "campaign.equip")
	help.bind_target(_transfer, "campaign.transfer")
	_remove_backpack = Button.new()
	_remove_backpack.name = "UnequipBackpack"
	_remove_backpack.text = "Rucksack ablegen"
	_remove_backpack.tooltip_text = "Leeren Rucksack in den ausgewählten Container legen."
	_remove_backpack.hide()
	SKIN.button(_remove_backpack)
	equipment_row.add_child(_remove_backpack)
	_remove_backpack.pressed.connect(func():
		if _target.selected >= 0:
			_wear({"source_container_id": _target.get_item_metadata(_target.selected), "item_id": "none"}, "backpack"))
	_remove_armor = Button.new()
	_remove_armor.name = "UnequipArmor"
	_remove_armor.text = "Rüstung ablegen"
	_remove_armor.tooltip_text = "Rüstung in den ausgewählten Container legen; der Anzug bleibt getragen."
	_remove_armor.hide()
	SKIN.button(_remove_armor)
	equipment_row.add_child(_remove_armor)
	_remove_armor.pressed.connect(func():
		if _target.selected >= 0:
			_wear({"source_container_id": _target.get_item_metadata(_target.selected), "item_id": "suit"}, "armor"))

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
	var signature:=JSON.stringify([inventory,unit.get("loadout",{}),unit.get("portrait_id",""),unit.get("portrait_path",""),_unit_id,craft_id,accessible,equipment_allowed,actor.get_instance_id() if actor!=null else 0])
	if signature==_signature: return
	_signature=signature
	for child in _slots.get_children():
		if child not in [_body_preview,_body_frame,_identity,_bag_preview]:
			_slots.remove_child(child);child.queue_free()
	for child in _containers.get_children():
		_containers.remove_child(child);child.queue_free()
	_target.clear(); _bodies.clear()
	var loadout: Dictionary=unit.get("loadout",{})
	var personal_id := "unit:" + _unit_id + ":backpack"
	_personal_storage = inventory.get(personal_id, {})
	var has_armor_slot := _personal_storage.has("armor_chip_capacity")
	var backpack_option := _slot_target.item_count - 1
	_slot_target.set_item_disabled(backpack_option, not has_armor_slot or not equipment_allowed)
	if _slot_target.selected == backpack_option and _slot_target.is_item_disabled(backpack_option):
		_slot_target.select(0)
	_remove_backpack.visible = has_armor_slot and equipment_allowed and int(_personal_storage.capacity) > 0
	_remove_backpack.disabled = not accessible.has(personal_id)
	_refresh_bag_preview()
	_body_preview.call("update_actor",actor,loadout,unit)
	for spec in [["armor","Rüstung"],["weapon_1","Primär"],["weapon_2","Sekundär"]]:
		var key: String=spec[0]
		var item: String=ITEMS.item_from_slot(key,String(loadout.get(key,"none")))
		var slot: PanelContainer=SURFACE.new(); slot.name="InventorySlot_"+key
		slot.add_theme_stylebox_override("panel",SKIN.box(SKIN.CARD,4))
		slot.accepted_type="inventory_item" if equipment_allowed else ""; slot.custom_minimum_size=Vector2(130,SLOT_HEIGHT); _slots.add_child(slot)
		var slot_body:=HBoxContainer.new(); slot_body.mouse_filter=Control.MOUSE_FILTER_IGNORE; slot.add_child(slot_body)
		var icon:=TextureRect.new(); icon.texture=_item_icon(item); icon.custom_minimum_size=SLOT_ICON; icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.mouse_filter=Control.MOUSE_FILTER_IGNORE; slot_body.add_child(icon)
		var label:=Label.new(); label.text=spec[1]+"\n"+String(LABELS.get(item,item));label.custom_minimum_size.x=130;label.add_theme_font_size_override("font_size",16);label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; label.mouse_filter=Control.MOUSE_FILTER_IGNORE; slot_body.add_child(label)
		slot.payload_dropped.connect(func(data:Dictionary): _wear(data,key))
	_layout_body_slots()
	var personal_label := "Persönlicher Stauraum" if has_armor_slot else "Rucksack"
	for spec in [["base:homebase","Basislager"],["craft:"+craft_id,"Schiffsfracht"],[personal_id, personal_label]]:
		var id: String=spec[0]
		var data: Dictionary=inventory.get(id,{})
		var box: PanelContainer=SURFACE.new(); box.name="Inventory_"+id.validate_node_name(); box.accepted_type="inventory_item"; box.custom_minimum_size=Vector2(280 if id=="base:homebase" else 200,160); _containers.add_child(box)
		box.payload_dropped.connect(func(item:Dictionary): _move(String(item.get("source_container_id","")),String(item.get("item_id","")),id,1))
		var style:=StyleBoxFlat.new(); style.bg_color=Color("102f3b"); style.border_color=Color("3e6972"); style.set_border_width_all(1); style.content_margin_left=8; style.content_margin_right=8; style.content_margin_top=8; style.content_margin_bottom=8; box.add_theme_stylebox_override("panel",style)
		SKIN.panel(box,true)
		var body:=VBoxContainer.new(); box.add_child(body); _bodies[id]=body
		var header := Label.new()
		header.text = _carried_storage_title(data) if id == personal_id else "%s · %d/%d" % [spec[1], ITEMS.used(data.get("items", {})), int(data.get("capacity", 0))]
		body.add_child(header)
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
			var button:=Button.new(); button.text="%s\n× %d" % [String(LABELS.get(item,item)).replace("Maschinenpistole","Maschinen-\npistole"),int(data.items[item])]; button.icon=_item_icon(String(item)); button.expand_icon=true; button.add_theme_constant_override("icon_max_width",42); button.custom_minimum_size=STORAGE_TILE_SIZE; button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; button.disabled=not allowed; source.add_child(button); source.forward_drag_from(button)
			SKIN.button(button);button.custom_minimum_size.y=STORAGE_TILE_SIZE.y;button.add_theme_font_size_override("font_size",14);button.add_theme_constant_override("icon_max_width",STORAGE_TILE_ICON);button.text=button.text.replace(" Rüstung","\nRüstung")
			if not id.begins_with("unit:"): _compact_tile(button)
			if id.begins_with("unit:"):
				button.name="BackpackItem_"+String(item)+"_List";button.text="" if button.icon != null else String(LABELS.get(item,item));button.custom_minimum_size=Vector2(64,64);button.add_theme_constant_override("icon_max_width",52);button.tooltip_text="%s × %d"%[String(LABELS.get(item,item)),int(data.items[item])]
			button.pressed.connect(func(): _selection={"source_container_id":id,"item_id":item}; _selected.text=String(LABELS.get(item,item))+" · "+String(spec[1]))
		if Dictionary(data.get("items",{})).is_empty():
			var empty:=Label.new(); empty.text="Leer · Gegenstand hierher ziehen"; empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(empty)
	_transfer.disabled=accessible.is_empty(); _equip.disabled=accessible.is_empty() or not equipment_allowed
	_remove_armor.visible = equipment_allowed and String(loadout.get("armor", "suit")) != "suit"
	_remove_armor.disabled = accessible.is_empty()
	_layout_body_slots()

func _compact_tile(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		if style == null: continue
		style.content_margin_left = STORAGE_TILE_PADDING.x; style.content_margin_right = STORAGE_TILE_PADDING.x
		style.content_margin_top = STORAGE_TILE_PADDING.y; style.content_margin_bottom = STORAGE_TILE_PADDING.y
		button.add_theme_stylebox_override(state, style)

func _layout_body_slots() -> void:
	if _identity == null or _bag_preview == null:
		return
	var width := maxf(_slots.size.x, 360)
	var wide := width >= 700
	var stacked := width < 500
	var left := 190.0 if stacked else 314.0
	var show_bag := width >= 820
	_identity.position = Vector2(12, 10)
	var header_width := width - 24 if stacked else minf(width - 24, 455.0)
	_identity.size = Vector2(header_width, 0)
	var slots_top := _identity.position.y + _identity.size.y + 12
	var model_top := slots_top if stacked else maxf(4.0, _identity.size.y - 92.0)
	var model_space := width - left - (180 if show_bag else 12)
	var body_size := Vector2(minf(model_space, 370), MODEL_HEIGHT)
	_body_preview.custom_minimum_size = body_size
	_body_preview.position = Vector2(left + (model_space - body_size.x) * 0.5, model_top)
	_body_preview.size = body_size
	_bag_preview.visible = show_bag
	_bag_preview.position = Vector2(width - 172, 148)
	_bag_preview.size = Vector2(164, 300)
	var bag_body:Node=_bodies.get("unit:"+_unit_id+":backpack")
	if bag_body!=null:(bag_body.get_parent() as Control).visible=not show_bag
	var slot_y := slots_top
	for key:String in ["armor","weapon_1","weapon_2"]:
		var slot:=_slots.get_node_or_null("InventorySlot_"+key) as Control
		if slot==null:continue
		var icon:TextureRect=slot.get_child(0).get_child(0)
		icon.custom_minimum_size=SLOT_ICON
		var label:Label=slot.get_child(0).get_child(1)
		label.custom_minimum_size.x=130 if wide else 100;label.add_theme_font_size_override("font_size",16 if wide else 14)
		var slot_width := minf(left - 24, SLOT_WIDTH_WIDE if wide else SLOT_WIDTH_NARROW)
		slot.custom_minimum_size = Vector2(slot_width, SLOT_HEIGHT)
		slot.size = slot.custom_minimum_size
		slot.position = Vector2(12, slot_y)
		slot_y += slot.size.y + 4
	var height := maxf(model_top + MODEL_HEIGHT + 4, slot_y + 6)
	_slots.custom_minimum_size.y = height
	_body_frame.size = Vector2(width, height)
	_slots.queue_redraw()

func _build_identity() -> void:
	_identity = HBoxContainer.new()
	_identity.name = "SharedPersonnelIdentity"
	_identity.add_theme_constant_override("separation", 12)
	_slots.add_child(_identity)
	_identity.minimum_size_changed.connect(_layout_body_slots, CONNECT_DEFERRED)

	_identity_portrait = TextureRect.new()
	_identity_portrait.name = "IdentityPortrait"
	PORTRAITS.apply_texture_rect_contract(_identity_portrait, "character_sheet")
	_identity_portrait.custom_minimum_size = PORTRAIT_SIZE
	_identity_portrait.set_meta("portrait_target_size", PORTRAIT_SIZE)
	_identity_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_identity.add_child(_identity_portrait)

	var facts := VBoxContainer.new()
	facts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	facts.add_theme_constant_override("separation", 3)
	_identity.add_child(facts)
	var name_line := HFlowContainer.new()
	name_line.name = "PersonnelNameLine"
	name_line.add_theme_constant_override("h_separation", 14)
	facts.add_child(name_line)
	_identity_name = _identity_label(name_line, "IdentityName", 22)
	_identity_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	_identity_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_rest_row=HBoxContainer.new();_rest_row.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;_rest_row.add_theme_constant_override("separation",4);name_line.add_child(_rest_row)
	_rest=CheckButton.new(); _rest.name="AutomaticRest"; _rest.text="";_rest.custom_minimum_size=Vector2(48,28); _rest_row.add_child(_rest)
	var rest_label:=Label.new();rest_label.text="Automatisch ruhen";SKIN.label(rest_label,15);rest_label.autowrap_mode=TextServer.AUTOWRAP_OFF;_rest_row.add_child(rest_label)
	_rest.tooltip_text="Bei Leerlauf an der Basis ein Bett aufsuchen. Ausschalten, um die Person stehen zu lassen."
	_rest.toggled.connect(func(enabled:bool): operation_requested.emit("base_auto_rest",{"unit_id":_unit_id,"enabled":enabled}))
	_main_role = _identity_label(facts, "PrimaryRole", 15)
	_secondary_role = _identity_label(facts, "SecondaryRole", 15)
	var status_line := HFlowContainer.new()
	status_line.add_theme_constant_override("h_separation", 10)
	facts.add_child(status_line)
	_condition = _identity_label(status_line, "PersonnelCondition", 15)
	_condition.autowrap_mode = TextServer.AUTOWRAP_OFF
	_condition.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_badges = HBoxContainer.new()
	_badges.name = "PersonnelBadges"
	_badges.add_theme_constant_override("separation", 5)
	status_line.add_child(_badges)
	_readiness = _identity_label(facts, "ReadinessStatus", 14)
	_readiness.add_theme_color_override("font_color", SKIN.CYAN)

func _identity_label(facts: Container, node_name: String, font_size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	SKIN.label(label, font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	facts.add_child(label)
	return label

func _update_identity(unit: Dictionary) -> void:
	var main := COPY.text(String(unit.get("primary_role", unit.get("role", ""))))
	var secondary := COPY.text(String(unit.get("secondary_role", "")))
	var condition := COPY.text(String(unit.get("condition", "")))
	var status := COPY.text(String(unit.get("status", condition)))
	var signature := JSON.stringify([unit.get("name", ""), main, secondary, condition, status,
		unit.get("portrait_id", ""), unit.get("portrait_path", ""), unit.get("badges", [])])
	if signature == _identity_signature:
		return
	_identity_signature = signature
	_identity_portrait.texture = PORTRAITS.load_texture(String(unit.get("portrait_id", "")), String(unit.get("portrait_path", "")))
	_identity_name.text = String(unit.get("name", ""))
	_main_role.text = "Hauptrolle: " + (main if not main.is_empty() else "—")
	_secondary_role.text = "Nebenrolle: " + (secondary if not secondary.is_empty() else "—")
	_condition.text = "Status: " + status
	_condition.visible = not status.is_empty()
	_readiness.text = "Bereitschaft: " + condition
	_readiness.visible = not condition.is_empty() and condition != status
	for child in _badges.get_children():
		_badges.remove_child(child)
		child.queue_free()
	for badge: Dictionary in unit.get("badges", []):
		var path := String(badge.get("path", ""))
		var texture := load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
		var indicator: Control
		if texture != null:
			var icon := TextureRect.new()
			icon.name = "RankBadge_" + String(badge.get("badge_key", badge.get("badge_id", "")))
			icon.texture = texture
			icon.custom_minimum_size = Vector2(23, 23)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			indicator = icon
		else:
			var label := Label.new()
			label.text = String(badge.get("label", ""))
			SKIN.label(label, 14)
			indicator = label
		indicator.mouse_filter = Control.MOUSE_FILTER_PASS
		indicator.tooltip_text = BADGES.format_badge_tooltip(badge)
		BADGES.apply_badge_help_metadata(indicator, badge)
		_badges.add_child(indicator)
	_badges.visible = _badges.get_child_count() > 0


func _carried_storage_title(data: Dictionary) -> String:
	var capacity := int(data.get("capacity", 0))
	var backpack := "Rucksack · %d/%d" % [ITEMS.backpack_slots_used(data), capacity]
	if not data.has("armor_chip_capacity"):
		return backpack
	var suit_capacity := int(data.armor_chip_capacity)
	var suit_used := ITEMS.compartment_used(data)
	return "Rüstungsfach (%d/%d)\n%s" % [suit_used, suit_capacity, backpack if capacity > 0 else "Kein Rucksack"]

func _refresh_bag_preview()->void:
	_bag_heading.text = _carried_storage_title(_personal_storage)
	var carried_items: Dictionary = _personal_storage.get("items", {})
	for child:Node in _bag_grid.get_children():_bag_grid.remove_child(child);child.queue_free()
	var id:String="unit:"+_unit_id+":backpack"
	var allowed:bool=_accessible.has(id)
	_bag_preview.accepted_type="inventory_item" if allowed else ""
	for item:String in carried_items:
		var source:PanelContainer=SURFACE.new();source.drag_payload={"type":"inventory_item","source_container_id":id,"item_id":item,"label":String(LABELS.get(item,item))} if allowed else {};_bag_grid.add_child(source)
		var button:=Button.new();button.name="BackpackItem_"+item;button.icon=_item_icon(item);button.expand_icon=true;button.custom_minimum_size=Vector2(62,64);button.add_theme_constant_override("icon_max_width",52);button.tooltip_text="%s × %d"%[String(LABELS.get(item,item)),int(carried_items[item])];source.add_child(button)
		if button.icon == null:
			button.text = String(LABELS.get(item, item))
		source.forward_drag_from(button)
		button.pressed.connect(func():_selection={"source_container_id":id,"item_id":item};_selected.text=String(LABELS.get(item,item)))
	if carried_items.is_empty():
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
