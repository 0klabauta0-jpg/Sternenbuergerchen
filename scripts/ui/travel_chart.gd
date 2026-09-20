extends Window
## Named orbital destinations; selection is local, travel is an authoritative request.
signal command_requested(command: Dictionary)
const Catalog=preload("res://scripts/core/catalog.gd")
const Icons=preload("res://scripts/ui/hud_icons.gd")
const Regions=preload("res://scripts/core/regions.gd")
const Routes=preload("res://scripts/core/trade_routes.gd")
const DESTINATIONS={
 "base":{"title":"Rostgrenze","subtitle":"Heimatbasis","icon":"base","at":Vector2(45,145)},
 "rust":{"title":"Signal im Staub","subtitle":"Satellit · Erz · Wrack","icon":"satellite","at":Vector2(45,193)},
 "station":{"title":"Meridian","subtitle":"Orbitaler Freihafen","icon":"shuttle","at":Vector2(455,125)},
 "bunker_surface":{"title":"Karst · LEICHT","subtitle":"Flak + Wache · 1 unten","icon":"armor","at":Vector2(250,267)},
 "bunker_medium":{"title":"Kluft · MITTEL","subtitle":"3 oben · 2 unten","icon":"armor","at":Vector2(250,315)},
 "bunker_hard":{"title":"Bastion · SCHWER","subtitle":"5 oben · 4 unten","icon":"armor","at":Vector2(250,363)},
 "distribution_friendly":{"title":"Freihafen","subtitle":"Umschlag · freundlich","icon":"market","at":Vector2(455,173)},
 "distribution":{"title":"Knotenwerk","subtitle":"Umschlag · feindlich","icon":"target","at":Vector2(455,221)},
 "tradepost":{"title":"Staubmarkt","subtitle":"Handel · Erkundung","icon":"market","at":Vector2(45,241)}
}
var _state: Dictionary={}
var _selected := "rust"
var _buttons: Dictionary={}
var _title: Label
var _detail: Label
var _route: Button
var _map: Control

class RouteDiagram extends Control:
	var selected: String="rust"
	const GROUPS={"base":0,"rust":0,"tradepost":0,"bunker_surface":1,"bunker_medium":1,"bunker_hard":1,"station":2,"distribution_friendly":2,"distribution":2}
	const CENTERS=[Vector2(128,99),Vector2(332,220),Vector2(538,78)]
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO,size),Color("09131e"))
		for i in 125:draw_circle(Vector2(fposmod(i*137.29,640),fposmod(i*73.63,430)),1.0 if i%3 else 1.6,Color(0.6,0.77,0.85,0.2+float(i%4)*0.1))
		var star:=Vector2(68,364)
		for r in [160.0,290.0,420.0,535.0]:
			draw_arc(star,r,-PI*0.7,PI*0.1,90,Color(0.36,0.48,0.56,0.24),1,true)
		for r in range(60,24,-4):draw_circle(star,r,Color(0.93,0.37,0.13,0.035))
		draw_circle(star,24,Color("f3974d"));draw_circle(star-Vector2(7,5),14,Color("ffda8d"))
		draw_arc(star,32,-2.8,0.3,36,Color("ffb66d"),3,true)
		draw_line(star+Vector2(20,-14),star+Vector2(51,-35),Color("d66c4b"),3,true)
		draw_string(ThemeDB.fallback_font,Vector2(30,410),"ASCHE · Flackerstern",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("edb38c"))
		var names: Array=["ROSTWELT","KARSTMOND","MERIDIAN-GÜRTEL"]
		var colors: Array=[Color("bd7951"),Color("858f96"),Color("4d9299")]
		for i in 3:
			var at: Vector2=CENTERS[i]
			draw_circle(at,27 if i<2 else 32,colors[i]);draw_circle(at+Vector2(11,4),21,colors[i].darkened(0.45))
			draw_arc(at,34,0,TAU,60,colors[i].lightened(0.15),1,true)
			draw_string(ThemeDB.fallback_font,at+Vector2(-70,-43),names[i],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("c0d1d9"))
			if i==2:draw_arc(at,40,-0.4,PI+0.4,60,Color("7aa5a7"),3,true)
		var selected_at: Vector2=CENTERS[int(GROUPS.get(selected,0))]
		draw_arc(selected_at,39,0,TAU,60,Color("f0b176"),2,true)
		draw_dashed_line(star,selected_at,Color(0.8,0.65,0.43,0.6),1,5,true)

func _ready() -> void:
	title="Systemkarte · Asche"
	size=Vector2i(1040,680)
	min_size=Vector2i(1040,680)
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
	column.add_child(_label("Asche-System",23,Color("efab6f")))
	column.add_child(_label("Planeten und Stationen · Ort wählen, Anflug bestätigen · Jede Landezone wird einzeln geladen",14))
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",23)
	column.add_child(row)
	_map=RouteDiagram.new()
	_map.clip_contents=true
	_map.custom_minimum_size=Vector2(640,430)
	row.add_child(_map)
	for id: String in DESTINATIONS:
		var data: Dictionary=DESTINATIONS[id]
		var button:=Button.new()
		button.text=str(data.title)
		button.icon=Icons.texture(str(data.icon))
		button.tooltip_text=str(data.subtitle)
		button.expand_icon=true
		button.add_theme_constant_override("icon_max_width",22)
		button.add_theme_font_size_override("font_size",12)
		button.position=data.at
		button.size=Vector2(177,43)
		button.pressed.connect(func():_selected=id;_refresh())
		_map.add_child(button)
		_buttons[id]=button
	var info:=VBoxContainer.new()
	info.custom_minimum_size.x=284
	info.add_theme_constant_override("separation",12)
	row.add_child(info)
	_title=_label("",23,Color("efab6f"));info.add_child(_title)
	_detail=_label("",15)
	_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size=Vector2(280,285)
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
	var summary:="HANDELSRING · Bruttomarge pro Stück\n"
	for leg: Dictionary in Routes.routes():
		summary+="%s → %s: %s %d → %d (+%d Cr)   " % [DESTINATIONS[leg.from].title,DESTINATIONS[leg.to].title,Catalog.item_name(leg.item),leg.buy,leg.sell,leg.margin]
	summary+="\nStartkapital und Fracht nötig; Schäden mindern den Gewinn."
	var routes_label:=_label(summary,14,Color("afd3c0"))
	routes_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(routes_label)
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
	popup_centered(Vector2i(1040,680))

func _refresh() -> void:
	if _state.is_empty():return
	_map.selected=_selected;_map.queue_redraw()
	var data: Dictionary=DESTINATIONS[_selected]
	_title.text=str(data.title)
	var width:=int(Catalog.bounds(_selected)*2)
	_detail.text=str(data.subtitle)+"\n\nGebiet: %d × %d m\n\n" % [width,width]
	_detail.text+="Risiko unterwegs: %d %%\n\n" % int(Catalog.travel_risk(_selected))
	for route: Dictionary in Routes.routes():
		if route.to==_selected:_detail.text+="Verkauf: %s für %d Cr. Einkauf in %s: %d Cr.\n\n" % [Catalog.item_name(route.item),route.sell,DESTINATIONS[route.from].title,route.buy]
	if Regions.bunker(_selected):_detail.text+="Untergrund: %d × %d m, per Aufzug separat geladen.\n\n" % [int(Catalog.bounds(Regions.elevator_target(_selected))*2),int(Catalog.bounds(Regions.elevator_target(_selected))*2)]
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
