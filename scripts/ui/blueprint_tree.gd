extends Window
## Snapshot-only research graph; work is performed by the authoritative core.
signal command_requested(command:Dictionary)
const Catalog=preload("res://scripts/core/catalog.gd")
const POSITIONS={"upgrade_solar_three":Vector2(500,720),"research_fusion":Vector2(260,720),"build_fusion_small":Vector2(20,860),"research_fusion_large":Vector2(260,860),"build_fusion_large":Vector2(500,860),"build_solar":Vector2(20,440),"research_energy":Vector2(260,440),"upgrade_solar":Vector2(500,440),"research_communications":Vector2(260,580),"upgrade_sender":Vector2(500,580),"mission":Vector2(20,25),"cutter":Vector2(260,25),"upgrade_workbench":Vector2(20,160),"research_materials":Vector2(260,160),"refine_alloy":Vector2(500,160),"research_medicine":Vector2(260,300),"med_charge_efficient":Vector2(500,300)}
const EDGES=[["upgrade_solar","upgrade_solar_three"],["upgrade_solar_three","research_fusion"],["research_fusion","build_fusion_small"],["research_fusion","research_fusion_large"],["research_fusion_large","build_fusion_large"],["mission","research_energy"],["research_energy","upgrade_solar"],["research_energy","research_communications"],["research_communications","upgrade_sender"],["mission","cutter"],["upgrade_workbench","cutter"],["upgrade_workbench","research_materials"],["research_materials","refine_alloy"],["research_materials","research_medicine"],["research_medicine","med_charge_efficient"]]
class Links extends Control:
	func _draw() -> void:
		for edge in EDGES:
			var a:Vector2=POSITIONS[edge[0]]+Vector2(100,45);var b:Vector2=POSITIONS[edge[1]]+Vector2(100,45)
			draw_line(a,b,Color("477a83"),2,true)
var _state:Dictionary={}
var _buttons:Dictionary={}
var _details:RichTextLabel
var _worker:OptionButton
var _start:Button
var _selected:="research_materials"
var _shop:OptionButton
var _buy:Button
var _power:Label
var _sender:Button
var _body:RichTextLabel
func _ready() -> void:
	title="Baupläne & Forschung";size=Vector2i(1100,750);min_size=size;close_requested.connect(hide)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,22)
	add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",14);margin.add_child(column)
	var heading:=Label.new();heading.text="BAUPLÄNE / FORSCHUNG";heading.add_theme_font_size_override("font_size",26);column.add_child(heading)
	_power=Label.new();column.add_child(_power)
	_sender=Button.new();_sender.pressed.connect(func():command_requested.emit({"type":"toggle_sender"}));column.add_child(_sender)
	var market:=HBoxContainer.new();column.add_child(market)
	_shop=OptionButton.new();_shop.size_flags_horizontal=Control.SIZE_EXPAND_FILL;market.add_child(_shop)
	var offers:Dictionary=preload("res://scripts/core/base_infrastructure.gd").offers()
	for id:String in offers:
		_shop.add_item("%s · %d Cr"%[offers[id].label,offers[id].price]);_shop.set_item_metadata(_shop.item_count-1,id)
	_shop.item_selected.connect(func(_index:int):present(_state))
	_buy=Button.new();_buy.text="Kaufen & an Basis liefern";market.add_child(_buy)
	_buy.pressed.connect(func():command_requested.emit({"type":"buy_power","offer":_shop.get_item_metadata(_shop.selected)}))
	var row:=HBoxContainer.new();column.add_child(row)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(740,410);row.add_child(scroll)
	var graph:=Links.new();graph.custom_minimum_size=Vector2(730,960);scroll.add_child(graph)
	for id:String in POSITIONS:
		var button:=Button.new();button.position=POSITIONS[id];button.size=Vector2(210,90);button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(func():_selected=id;present(_state));graph.add_child(button);_buttons[id]=button
	var panel:=VBoxContainer.new();panel.custom_minimum_size.x=295;row.add_child(panel)
	_details=RichTextLabel.new();_details.bbcode_enabled=true;_details.custom_minimum_size=Vector2(290,300);panel.add_child(_details)
	_worker=OptionButton.new();_worker.add_item("Ida · Technik 3");_worker.add_item("Jaro · Technik 1");panel.add_child(_worker)
	_start=Button.new();_start.text="An der Werkbank starten";_start.custom_minimum_size.y=50;panel.add_child(_start)
	_start.pressed.connect(func():command_requested.emit({"type":"assign_work","unit_id":"ida" if _worker.selected==0 else "jaro","recipe_id":_selected}))
	_body=RichTextLabel.new();_body.bbcode_enabled=true;_body.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(_body)
	hide()
func open_tree(state:Dictionary) -> void:present(state);popup_centered(size)
func present(state:Dictionary) -> void:
	_state=state
	if state.is_empty() or not is_node_ready():return
	for i in 2:
		var unit:Dictionary=state.crew["ida" if i==0 else "jaro"]
		_worker.set_item_text(i,str(unit.name)+" · Technik "+str(unit.skill))
	var budget:Dictionary=preload("res://scripts/core/base_infrastructure.gd").budget(state,str(state.work.recipe_id) if state.work.active else "")
	_power.text="ENERGIE  %d erzeugt · %d Grundlast · %d Arbeit · %d Reserve%s"%[budget.supply,budget.idle,budget.work,budget.remaining," · ARBEIT WARTET AUF STROM" if not budget.powered else ""]
	_sender.text="Sendestation ausschalten (Notzugriff bleibt)" if state.base.get("infrastructure",{}).get("sender_enabled",true) else "Sendestation einschalten"
	_sender.disabled=state.region!="base"
	var available_stock:int=int(state.market_stock.station.items.get("power:"+str(_shop.get_item_metadata(_shop.selected)),0))
	_buy.disabled=state.region!="base" or available_stock<=0
	_buy.text="Liefern · %d vorrätig"%available_stock
	_buy.tooltip_text="Gemeinsamer Lieferantenbestand. Nachschub in %d s."%int(ceil(state.market_stock.station.remaining))
	var unlocked:Array=state.get("blueprints",[]);var recipes:Dictionary=Catalog.recipes()
	for id:String in _buttons:
		var label:String="Blackbox bergen\n260 Cr + Schneider" if id=="mission" else str(recipes[id].label).replace("Forschung · ","")
		var done:bool=state.contract.status=="claimed" if id=="mission" else int(state.base.workbench_tier)>=2 if id=="upgrade_workbench" else recipes[id].has("unlocks") and recipes[id].unlocks[0] in unlocked
		var available:bool=id in unlocked
		_buttons[id].text=("✓ " if done else "")+label+("\nBauplan vorhanden" if available and not done else "")
		var style:=StyleBoxFlat.new();style.bg_color=Color("12333d") if available or done else Color("14232e");style.border_color=Color("ffb35c") if id==_selected else Color("52bcb2") if done else Color("385563");style.set_border_width_all(2);style.set_corner_radius_all(10)
		_buttons[id].add_theme_stylebox_override("normal",style)
	_start.visible=_selected!="mission";_worker.visible=_start.visible
	if _selected=="mission":_details.text="Bergungsauftrag annehmen, Satellit finden, Blackbox ins Basislager bringen und dort abgeben.\n\nStatus: "+str(state.contract.status)
	else:
		var recipe:Dictionary=recipes[_selected]
		var text:String="[b]"+str(recipe.label)+"[/b]\n\nWerkbank %d · Technik %d\nDauer: %d s\n\n"%[recipe.tier,recipe.min_skill,recipe.duration]
		for item:String in recipe.materials:text+="%s: %d / %d\n"%[Catalog.item_name(item),int(state.inventory.get(item,0)),recipe.materials[item]]
		if recipe.has("unlocks"):
			text+="\nSchaltet frei:\n"
			for id:String in recipe.unlocks:text+=str(recipes[id].label)+"\n"
		var prerequisite:String=preload("res://scripts/core/base_infrastructure.gd").available(state,_selected)
		if _selected=="upgrade_sender":text+="\nErschließt die fernen Orte auf Schlacke und Grünschiefer dauerhaft. Grundlast steigt auf 8.\n"
		if not prerequisite.is_empty():text+="\n"+prerequisite+"\n"
		var power:Dictionary=preload("res://scripts/core/base_infrastructure.gd").budget(state,_selected)
		text+="\nLeistungsbedarf bei Arbeit: %d / %d\n"%[power.idle+power.work,power.supply]
		if not power.powered:text+="Arbeit wartet, bis genug Strom verfügbar ist.\n"
		if state.work.active:text+="\nWerkbank belegt: %d s verbleiben."%int(ceil(state.work.remaining))
		_details.text=text
		_start.disabled=not prerequisite.is_empty() or not _selected in unlocked or state.region!="base" or state.work.active or int(state.base.workbench_tier)<int(recipe.tier) or (recipe.has("unlocks") and recipe.unlocks[0] in unlocked)
	var lines:Array[String]=["[b]Weitere verfügbare Baupläne[/b]"]
	for id:String in recipes:
		if POSITIONS.has(id):continue
		lines.append("%s · Werkbank %d · Technik %d · %s"%[recipes[id].label,recipes[id].get("tier",1),recipes[id].min_skill,"vorhanden" if id in unlocked else "fehlt"])
	lines.append("\nForschung nutzt zunächst die Werkbank II. Eigene Forschungsräume sind ein späterer Basisausbau.")
	_body.text="\n".join(lines)
