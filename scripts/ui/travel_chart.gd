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
var _variants:OptionButton
var _variant_family:=""
var _buttons: Dictionary={}
var _title: Label
var _detail: Label
var _route: Button
var _preview:TextureRect
var _ship_info:Label
var _worlds:HBoxContainer
var _planet_buttons:Dictionary={}
var _map: Control

class RouteDiagram extends Control:
	var selected: String="rust"
	var show_starts:=false
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
		if show_starts:
			for spec:Array in [["ice",Vector2(95,108),28.0,"FROSTMARK"],["basalt",Vector2(249,54),22.0,"SCHLACKE"],["mineral",Vector2(361,358),27.0,"GRÜNSCHIEFER"]]:
				var at:Vector2=spec[1];var radius:float=spec[2]
				draw_texture_rect(preload("res://scripts/ui/celestial_art.gd").texture(spec[0]),Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),false)
				draw_string(ThemeDB.fallback_font,at+Vector2(-40,radius+17),spec[3],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("dfdbc9"))
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

	func _planet(at: Vector2,radius: float,_color: Color,seed_value: int,star: bool) -> void:
		var body: String="star" if star else "rust" if seed_value==921 else "moon"
		var texture: Texture2D=preload("res://scripts/ui/celestial_art.gd").texture(body)
		draw_texture_rect(texture,Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),false)

func _ready() -> void:
	title="Systemkarte · Asche"
	size=Vector2i(1100,780)
	min_size=Vector2i(1100,780)
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
	_preview=TextureRect.new();_preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;_preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;_preview.custom_minimum_size=Vector2(284,132);info.add_child(_preview)
	_title=_label("",26,Color("efab6f"));info.add_child(_title)
	_variants=OptionButton.new();info.add_child(_variants)
	_variants.item_selected.connect(func(_index:int):_refresh())
	_detail=_label("",14)
	_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size=Vector2(280,150)
	info.add_child(_detail)
	_route=Button.new()
	_route.text="Anflug beginnen"
	_route.custom_minimum_size.y=46
	_route.pressed.connect(func():command_requested.emit({"type":"travel_site" if _state.has("campaign") and _variants.visible else "travel","destination":str(_variants.get_item_metadata(_variants.selected)) if _variants.visible else _selected}))
	info.add_child(_route)
	var back:=Button.new()
	back.text="Zurück zum Schiff"
	back.custom_minimum_size.y=38
	back.pressed.connect(hide)
	info.add_child(back)
	_worlds=HBoxContainer.new();_worlds.add_theme_constant_override("separation",12);column.add_child(_worlds)
	for planet:String in preload("res://scripts/core/team_campaign.gd").PLANETS:
		var button:=Button.new();button.text=preload("res://scripts/core/team_campaign.gd").PLANETS[planet]
		button.icon=preload("res://scripts/ui/celestial_art.gd").texture(planet)
		button.expand_icon=true;button.add_theme_constant_override("icon_max_width",38)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.custom_minimum_size.y=52
		button.tooltip_text="Aus dem Orbit zum Erkundungsgebiet dieses Planeten reisen."
		button.pressed.connect(func():command_requested.emit({"type":"travel_planet","planet":planet}))
		_worlds.add_child(button);_planet_buttons[planet]=button
	_ship_info=_label("",17,Color("f1d6ab"));column.add_child(_ship_info)
	var summary:="HANDELSRING · Bruttomarge pro Stück\n"
	for leg: Dictionary in Routes.routes():
		summary+="%s → %s: %s %d → %d (+%d Cr)   " % [DESTINATIONS[leg.from].title,DESTINATIONS[leg.to].title,Catalog.item_name(leg.item),leg.buy,leg.sell,leg.margin]
	summary+="\nStartkapital und Fracht nötig; Schäden mindern den Gewinn."
	var routes_label:=_label(summary,14,Color("afd3c0"))
	routes_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_ship_info.tooltip_text=summary
	routes_label.queue_free()
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
	popup_centered(size)

func _refresh() -> void:
	if _state.is_empty():return
	_worlds.visible=_state.has("campaign")
	for planet:String in _planet_buttons:
		_planet_buttons[planet].disabled=_state.get("region","")!="orbit" or _state.get("travel",{}).get("active",false)
	_map.selected=_selected;_map.show_starts=_state.has("campaign");_map.queue_redraw()
	if _variant_family!=_selected:
		_variant_family=_selected;_variants.clear()
		_variants.visible=_selected not in ["base","station"]
		if _variants.visible:
			for i in 4:
				var id:String=_selected+("_v%d"%(i+1) if i>0 else "")
				_variants.add_item(Regions.LABELS[id]+" · "+["Rostwelt","Frostmark","Schlacke","Grünschiefer"][i]);_variants.set_item_metadata(i,id)
	var data: Dictionary=DESTINATIONS[_selected]
	var preview_id:String="distribution_friendly" if _selected=="distribution" else "bunker_surface" if Regions.bunker(_selected) else _selected
	var preview_path:String="res://assets/original/previews/%s.jpg"%preview_id
	if ResourceLoader.exists(preview_path):_preview.texture=load(preview_path)
	var aboard:=0
	for unit:Dictionary in _state.crew.values():
		if unit.assignment=="aboard":aboard+=1
	var cargo:=0
	for amount:Variant in _state.cargo.values():cargo+=int(amount)
	_ship_info.text="%s  ·  Crew %d / %d an Bord  ·  Fracht %d / %d"%[_state.ship.name,aboard,_state.crew.size(),cargo,_state.ship.capacity]
	var destination:String=str(_variants.get_item_metadata(_variants.selected)) if _variants.visible else _selected
	_title.text=Regions.LABELS.get(destination,str(data.title))
	_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var width:=int(Catalog.bounds(_selected)*2)
	_detail.text=str(data.subtitle)+"\n\nGebiet: %d × %d m\n" % [width,width]
	_detail.text+="Risiko unterwegs: %d %%\n" % int(Catalog.travel_risk(_selected))
	for route: Dictionary in Routes.routes():
		if route.to==_selected:_detail.text+="Handel: %s %d Cr · aus %s (%d Cr).\n" % [Catalog.item_name(route.item),route.sell,DESTINATIONS[route.from].title,route.buy]
	if Regions.bunker(_selected):_detail.text+="Untergeschoss %d × %d m · Aufzug.\n" % [int(Catalog.bounds(Regions.elevator_target(_selected))*2),int(Catalog.bounds(Regions.elevator_target(_selected))*2)]
	_detail.text+="\nAnkunft am Kartenrand · selbst landen."
	var ready: bool=str(_state.get("region",""))=="orbit" and not bool(_state.get("travel",{}).get("active",false))
	var access_error:String=preload("res://scripts/core/base_infrastructure.gd").site_access(_state,destination)
	if not access_error.is_empty():_detail.text+="\n"+access_error
	_route.disabled=not ready or not access_error.is_empty()
	var action_style:=StyleBoxFlat.new();action_style.bg_color=Color("ed9d48");action_style.set_corner_radius_all(8);_route.add_theme_stylebox_override("normal",action_style);_route.add_theme_color_override("font_color",Color("17232b"))
	if not ready:_detail.text+="\nZuerst in den Orbit aufsteigen."
	for id: String in _buttons:
		var style:=StyleBoxFlat.new()
		style.bg_color=Color("355a5c") if id==_selected else Color("1b303a")
		style.border_color=Color("efab6f") if id==_selected else Color("46606a")
		style.set_border_width_all(2 if id==_selected else 1)
		style.set_corner_radius_all(8)
		_buttons[id].add_theme_stylebox_override("normal",style)
	if bool(_state.get("travel",{}).get("active",false)):hide()
