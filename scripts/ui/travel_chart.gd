extends Window
## Named orbital destinations; selection is local, travel is an authoritative request.
signal command_requested(command: Dictionary)
const Catalog=preload("res://scripts/core/catalog.gd")
const Icons=preload("res://scripts/ui/hud_icons.gd")
const DESTINATIONS := {
	"base":{"title":"Rostgrenze","subtitle":"Heimatbasis","icon":"base","at":Vector2(62,52)},
	"rust":{"title":"Signal im Staub","subtitle":"Satellit · Erz · Wrack","icon":"satellite","at":Vector2(286,52)},
	"bunker_surface":{"title":"Wachtposten","subtitle":"Flak · Bunker · Aufzug","icon":"armor","at":Vector2(62,195)},
	"distribution":{"title":"Knotenwerk","subtitle":"Verteilzentrum","icon":"storage","at":Vector2(286,195)},
	"tradepost":{"title":"Staubmarkt","subtitle":"Handel · Erkundung","icon":"market","at":Vector2(62,338)},
	"station":{"title":"Meridian","subtitle":"Orbitaler Freihafen","icon":"shuttle","at":Vector2(286,338)}
}
var _state: Dictionary={}
var _selected := "rust"
var _buttons: Dictionary={}
var _title: Label
var _detail: Label
var _route: Button
var _map: Control

class RouteDiagram extends Control:
	func _draw() -> void:
		var ink := Color("263c46")
		for x in range(24,530,40): draw_line(Vector2(x,0),Vector2(x,474),Color(0.3,0.5,0.55,0.09))
		for y in range(0,474,40): draw_line(Vector2(0,y),Vector2(530,y),Color(0.3,0.5,0.55,0.09))
		draw_arc(Vector2(265,240),175,0,TAU,72,ink,2.0,true)
		draw_line(Vector2(265,90),Vector2(265,390),Color("526b72"),1.5,true)
		for y in [92,235,378]:
			draw_line(Vector2(142,y),Vector2(374,y),ink,2.0,true)
			draw_circle(Vector2(265,y),5.0,Color("c58c65"))

func _ready() -> void:
	title="Reisekarte · Rostwelt und Orbit"
	size=Vector2i(920,620)
	min_size=Vector2i(850,590)
	transient=true
	unresizable=true
	close_requested.connect(hide)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",15)
	margin.add_child(column)
	column.add_child(_label("ROSTWELT / REISEKARTE",23,Color("efab6f")))
	column.add_child(_label("Einsteigen  →  Abheben  →  Orbit  →  Ziel anfliegen  →  Landen",14))
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",23)
	column.add_child(row)
	_map=RouteDiagram.new()
	_map.custom_minimum_size=Vector2(520,465)
	row.add_child(_map)
	for id: String in DESTINATIONS:
		var data: Dictionary=DESTINATIONS[id]
		var button:=Button.new()
		button.text=str(data.title)+"\n"+str(data.subtitle)
		button.icon=Icons.texture(str(data.icon))
		button.expand_icon=true
		button.add_theme_constant_override("icon_max_width",22)
		button.add_theme_font_size_override("font_size",14)
		button.position=data.at
		button.size=Vector2(192,79)
		button.pressed.connect(func():_selected=id;_refresh())
		_map.add_child(button)
		_buttons[id]=button
	var info:=VBoxContainer.new()
	info.custom_minimum_size.x=284
	info.add_theme_constant_override("separation",18)
	row.add_child(info)
	_title=_label("",23,Color("efab6f"));info.add_child(_title)
	_detail=_label("",15)
	_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size=Vector2(284,295)
	info.add_child(_detail)
	_route=Button.new()
	_route.text="Anflug beginnen"
	_route.custom_minimum_size.y=46
	_route.pressed.connect(func():command_requested.emit({"type":"travel","destination":_selected}))
	info.add_child(_route)
	var back:=Button.new()
	back.text="Zurück zum Schiff"
	back.custom_minimum_size.y=38
	back.pressed.connect(hide)
	info.add_child(back)
	hide()

func _label(text: String, pixels: int, color: Color=Color("e0e8e5")) -> Label:
	var label:=Label.new();label.text=text
	label.add_theme_font_size_override("font_size",pixels)
	label.add_theme_color_override("font_color",color)
	return label

func present(state: Dictionary) -> void:
	_state=state
	if is_node_ready():_refresh()

func open_chart(state: Dictionary) -> void:
	present(state)
	popup_centered(Vector2i(920,620))

func _refresh() -> void:
	if _state.is_empty():return
	var data: Dictionary=DESTINATIONS[_selected]
	_title.text=str(data.title)
	var width:=int(Catalog.bounds(_selected)*2)
	_detail.text=str(data.subtitle)+"\n\nGebiet: %d × %d m\n\n" % [width,width]
	_detail.text+="Risiko unterwegs: %d %%\n\n" % int(Catalog.travel_risk(_selected))
	_detail.text+="Ankunft: schwebend am Rand des Zielgebiets. Danach selbst anfliegen, landen und aussteigen."
	var ready: bool=str(_state.get("region",""))=="orbit" and not bool(_state.get("travel",{}).get("active",false))
	_route.disabled=not ready
	if not ready:_detail.text+="\n\nVor dem Ortswechsel erst in den Orbit aufsteigen."
	for id: String in _buttons:
		var style:=StyleBoxFlat.new()
		style.bg_color=Color("355a5c") if id==_selected else Color("1b303a")
		style.border_color=Color("efab6f") if id==_selected else Color("46606a")
		style.set_border_width_all(2 if id==_selected else 1)
		_buttons[id].add_theme_stylebox_override("normal",style)
	if bool(_state.get("travel",{}).get("active",false)):hide()
