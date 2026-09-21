extends Window
## Snapshot-only research graph; work is performed by the authoritative core.
signal command_requested(command:Dictionary)
const Catalog=preload("res://scripts/core/catalog.gd")
const POSITIONS={"mission":Vector2(20,25),"cutter":Vector2(260,25),"upgrade_workbench":Vector2(20,160),"research_materials":Vector2(260,160),"refine_alloy":Vector2(500,160),"research_medicine":Vector2(260,300),"med_charge_efficient":Vector2(500,300)}
const EDGES=[["mission","cutter"],["upgrade_workbench","cutter"],["upgrade_workbench","research_materials"],["research_materials","refine_alloy"],["research_materials","research_medicine"],["research_medicine","med_charge_efficient"]]
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
var _body:RichTextLabel
func _ready() -> void:
	title="Baupläne & Forschung";size=Vector2i(1100,750);min_size=size;close_requested.connect(hide)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,22)
	add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",14);margin.add_child(column)
	var heading:=Label.new();heading.text="BAUPLÄNE / FORSCHUNG";heading.add_theme_font_size_override("font_size",26);column.add_child(heading)
	var row:=HBoxContainer.new();column.add_child(row)
	var graph:=Links.new();graph.custom_minimum_size=Vector2(730,410);row.add_child(graph)
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
		if state.work.active:text+="\nWerkbank belegt: %d s verbleiben."%int(ceil(state.work.remaining))
		_details.text=text
		_start.disabled=not _selected in unlocked or state.region!="base" or state.work.active or int(state.base.workbench_tier)<int(recipe.tier) or (recipe.has("unlocks") and recipe.unlocks[0] in unlocked)
	var lines:Array[String]=["[b]Weitere verfügbare Baupläne[/b]"]
	for id:String in recipes:
		if POSITIONS.has(id):continue
		lines.append("%s · Werkbank %d · Technik %d · %s"%[recipes[id].label,recipes[id].get("tier",1),recipes[id].min_skill,"vorhanden" if id in unlocked else "fehlt"])
	lines.append("\nForschung nutzt zunächst die Werkbank II. Eigene Forschungsräume sind ein späterer Basisausbau.")
	_body.text="\n".join(lines)
