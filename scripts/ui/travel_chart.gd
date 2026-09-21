extends Window
## Named orbital destinations; selection is local, travel is an authoritative request.
signal command_requested(command: Dictionary)
const Catalog=preload("res://scripts/core/catalog.gd")
const Icons=preload("res://scripts/ui/hud_icons.gd")
const Regions=preload("res://scripts/core/regions.gd")
const Routes=preload("res://scripts/core/trade_routes.gd")
const DESTINATIONS={
 "base":{"title":"Rostgrenze","subtitle":"Heimatbasis","icon":"base","at":Vector2(8,270)},
 "rust":{"title":"Signal im Staub","subtitle":"Satellit · Erz · Wrack","icon":"satellite","at":Vector2(8,318)},
 "station":{"title":"Meridian","subtitle":"Orbitaler Freihafen","icon":"shuttle","at":Vector2(458,267)},
 "bunker_surface":{"title":"Karst · LEICHT","subtitle":"Flak + Wache · 1 unten","icon":"armor","at":Vector2(458,24)},
 "bunker_medium":{"title":"Kluft · MITTEL","subtitle":"3 oben · 2 unten","icon":"armor","at":Vector2(458,72)},
 "bunker_hard":{"title":"Bastion · SCHWER","subtitle":"5 oben · 4 unten","icon":"armor","at":Vector2(458,120)},
 "distribution_friendly":{"title":"Freihafen","subtitle":"Umschlag · freundlich","icon":"market","at":Vector2(458,315)},
 "distribution":{"title":"Knotenwerk","subtitle":"Umschlag · feindlich","icon":"target","at":Vector2(458,363)},
 "tradepost":{"title":"Staubmarkt","subtitle":"Handel · Erkundung","icon":"market","at":Vector2(8,366)}
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
	const CENTERS=[Vector2(212,300),Vector2(402,92),Vector2(481,258)]
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO,size),Color("07161f"))
		var rng:=RandomNumberGenerator.new();rng.seed=717
		for i in 430:
			var at:=Vector2(rng.randf_range(0,640),rng.randf_range(0,430))
			draw_circle(at,rng.randf_range(0.3,1.25),Color(0.7,0.83,0.91,rng.randf_range(0.15,0.8)))
		var star:=Vector2(292,201)
		for r in [85.0,145.0,207.0,280.0]:
			var orbit:=PackedVector2Array()
			for i in 121:orbit.append(star+Vector2(cos(i*TAU/120)*r,sin(i*TAU/120)*r*0.61))
			draw_polyline(orbit,Color(0.47,0.61,0.65,0.22),1,true)
		for i in 220:
			var a:=rng.randf_range(-0.7,1.4)
			var at:=star+Vector2(cos(a)*rng.randf_range(219,265),sin(a)*rng.randf_range(150,188))
			var poly:=PackedVector2Array()
			var radius:=rng.randf_range(1.5,5)
			for j in 5:poly.append(at+Vector2.from_angle(j*TAU/5)*radius*rng.randf_range(0.7,1.2))
			draw_colored_polygon(poly,Color("35636b").lightened(rng.randf_range(-0.25,0.18)))
		for r in range(85,30,-3):draw_circle(star,r,Color(1,0.43,0.09,0.016))
		_planet(star,32,Color("f7972e"),182,true)
		_planet(CENTERS[0],53,Color("b75e34"),921,false)
		_planet(CENTERS[1],37,Color("938673"),925,false)
		draw_string(ThemeDB.fallback_font,star+Vector2(-23,53),"ASCHE",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ffe1b1"))
		draw_string(ThemeDB.fallback_font,CENTERS[0]+Vector2(-46,75),"ROSTWELT",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ead9bd"))
		draw_string(ThemeDB.fallback_font,CENTERS[1]+Vector2(-45,-52),"KARSTMOND",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("ead9bd"))
		draw_string(ThemeDB.fallback_font,Vector2(391,236),"MERIDIAN-GÜRTEL",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("a9d4d2"))
		for id: String in DESTINATIONS:
			var button_at: Vector2=DESTINATIONS[id].at
			var center: Vector2=CENTERS[int(GROUPS[id])]
			var anchor:=button_at+Vector2(177 if button_at.x<100 else 0,21)
			var edge:=center+(anchor-center).normalized()*(56 if GROUPS[id]==0 else 40 if GROUPS[id]==1 else 9)
			var color:=Color("ffb158") if id==selected else Color("71929b")
			draw_line(edge,anchor,color,1,true);draw_circle(edge,4,color)
		var destination: Vector2=CENTERS[int(GROUPS.get(selected,0))]
		if GROUPS.get(selected,0)!=0:draw_dashed_line(CENTERS[0]+Vector2(55,-8),destination,Color("ffb158"),2,9,true)

	func _planet(at: Vector2,radius: float,color: Color,seed_value: int,star: bool) -> void:
		var rng:=RandomNumberGenerator.new();rng.seed=seed_value
		draw_circle(at,radius+1,color.lightened(0.25))
		draw_circle(at,radius,color.darkened(0.4))
		# Faceted surface with directional shading; fixed seed avoids visual flicker.
		for y in range(-int(radius),int(radius),3):
			for x in range(-int(radius),int(radius),3):
				var p:=Vector2(x,y)
				if p.length()>radius-2:continue
				var z:=sqrt(maxf(0,1-p.length_squared()/(radius*radius)))
				var light:=clampf(z*0.45-float(x)/radius*0.45-float(y)/radius*0.18,0.08,1)
				var shade:=color.darkened(0.72-light*0.7).lightened(rng.randf_range(-0.06,0.06))
				if star:shade=color.lightened(rng.randf_range(-0.28,0.22))
				draw_circle(at+p,2.2,shade)
		if not star:
			for i in 24:
				var p:=Vector2(rng.randf_range(-radius*0.8,radius*0.8),rng.randf_range(-radius*0.8,radius*0.8))
				var r:=rng.randf_range(1.5,radius*0.12)
				if p.length()+r>radius*0.88:continue
				draw_circle(at+p,r,color.darkened(0.38))
				draw_arc(at+p,r,0.8,3.5,12,color.lightened(0.12),1,true)

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
		style.set_corner_radius_all(8)
		_buttons[id].add_theme_stylebox_override("normal",style)
	if bool(_state.get("travel",{}).get("active",false)):hide()
