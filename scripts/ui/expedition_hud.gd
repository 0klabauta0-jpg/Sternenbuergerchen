extends CanvasLayer
## Local flight, orbital chart and contacts have distinct actions.
signal command_requested(command: Dictionary)
signal action_requested(action: String, payload: Dictionary)
const Regions=preload("res://scripts/core/regions.gd")
const Icons=preload("res://scripts/ui/hud_icons.gd")
var _panel: PanelContainer
var _heading: Label
var _detail: Label
var _actions: GridContainer
var _contacts: VBoxContainer
var _buttons: Dictionary={}
var _contact_buttons: Dictionary={}
var _last_layout := ""
var _state: Dictionary={}
var _guest:=false

func _ready() -> void:
	_panel=PanelContainer.new()
	_panel.position=Vector2(80,78)
	_panel.custom_minimum_size=Vector2(300,0)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.035,0.065,0.09,0.96)
	style.border_color=Color("45676d")
	style.set_border_width_all(1)
	style.set_content_margin_all(13)
	_panel.add_theme_stylebox_override("panel",style)
	add_child(_panel)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	_panel.add_child(column)
	_heading=_label("",15,Color("efab6f"));column.add_child(_heading)
	_detail=_label("",13,Color("e1e6e4"))
	_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size.x=272
	column.add_child(_detail)
	_actions=GridContainer.new();_actions.columns=2
	_actions.add_theme_constant_override("h_separation",6)
	_actions.add_theme_constant_override("v_separation",6)
	column.add_child(_actions)
	_contacts=VBoxContainer.new();_contacts.add_theme_constant_override("separation",5)
	column.add_child(_contacts)
	_panel.hide()

func _label(text: String,pixels: int,color: Color) -> Label:
	var label:=Label.new();label.text=text
	label.add_theme_font_size_override("font_size",pixels)
	label.add_theme_color_override("font_color",color)
	return label

func _action(id: String,title: String,icon: String,callback: Callable,parent: Node=null) -> Button:
	var button:=Button.new();button.text=title
	button.icon=Icons.texture(icon);button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",20)
	button.add_theme_font_size_override("font_size",13)
	button.custom_minimum_size=Vector2(132,38)
	button.focus_mode=Control.FOCUS_NONE
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	(parent if parent!=null else _actions).add_child(button)
	_buttons[id]=button
	return button

func _send(type: String,data: Dictionary={}) -> void:
	var command:=data.duplicate(true);command.type=type
	command_requested.emit(command)

func present(state: Dictionary,guest: bool) -> void:
	_state=state;_guest=guest
	if not is_instance_valid(_panel) or state.is_empty():return
	var region: String=str(state.region)
	var airborne: bool=str(state.ship.get("mode","landed"))=="flying"
	_panel.visible=(airborne or region in ["space","orbit"]) and not bool(state.travel.active)
	if not _panel.visible:return
	var contacts: Array=state.get("discovery",{}).get("signals",[]) if region=="rust" else []
	var layout:=region+str(airborne)+str(contacts.size())
	if layout!=_last_layout:
		_last_layout=layout
		for container: Node in [_actions,_contacts]:
			for child: Node in container.get_children():container.remove_child(child);child.queue_free()
		_buttons.clear();_contact_buttons.clear()
		_action("focus_ship","Schiff zeigen","target",func():action_requested.emit("focus_object",{"object_id":"shuttle"}))
		if region=="space":
			_action("fire_turret","Turm: Angriff","target",func():_send("fire_turret",{"target_id":"pirate"}))
			_action("stop_fire","Feuer einstellen","pause",func():_send("fire_turret",{"target_id":""}))
			_action("flee","Rückzug","shuttle",func():_send("flee"))
		elif region=="orbit":
			_action("travel_chart","Reisekarte","orbit",func():action_requested.emit("travel_chart",{}))
		else:
			_action("land","Hier landen","load",func():_send("land"))
			_action("enter_orbit","In den Orbit","orbit",func():_send("enter_orbit"))
			_action("travel_chart","Reiseübersicht","contracts",func():action_requested.emit("travel_chart",{}))
			if region=="rust":
				_action("radar_scan","Radarimpuls","target",func():_send("radar_scan"))
				for contact: Dictionary in contacts:
					var id: String=str(contact.id)
					var point: Array=contact.position
					var button:=_action(id,"Unbekannter Kontakt","target",func():_send("ship_move",{"position":point.duplicate()}),_contacts)
					button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
					_contact_buttons[id]=button
	var roles: Dictionary=state.ship.get("roles",{})
	var pilot: String=str(state.crew.get(str(roles.get("pilot","")),{}).get("name","unbesetzt"))
	var gunner: String=str(state.crew.get(str(roles.get("gunner","")),{}).get("name","unbesetzt"))
	if region=="space":
		_heading.text="RAUMKONTAKT / FREIBEUTER"
		var encounter: Dictionary=state.get("encounter",{})
		var enemy: Dictionary=encounter.get("enemy",{})
		_detail.text="%s: %d %% · Gegner: %d / %d\nPilot: %s · Turm: %s\nRechtsklick: Ausweichziel." % [str(state.ship.get("name","Entersäbel")),int(state.ship.condition),int(enemy.get("hull",0)),int(enemy.get("max_hull",1)),pilot,gunner]
		_buttons.fire_turret.disabled=gunner=="unbesetzt" or str(state.ship.get("model",""))=="vulture" or str(encounter.get("turret_target",""))=="pirate"
		_buttons.stop_fire.disabled=str(encounter.get("turret_target",""))==""
		var escaping: bool=float(encounter.get("escape_remaining",0))>0.0
		_buttons.flee.disabled=escaping
		if escaping:_detail.text+="\nRückzug: %.1f s" % float(encounter.get("escape_remaining",0))
	elif region=="orbit":
		_heading.text="ORBIT / ROSTWELT"
		_detail.text="Pilot: %s · %s\nWähle auf der Reisekarte einen benannten Ort. Die Crew bleibt während des Anflugs an Bord." % [pilot,str(state.ship.get("name","Entersäbel"))]
	else:
		_heading.text="LOKALER FLUG / "+str(state.ship.get("name","Entersäbel")).to_upper()
		_detail.text="Pilot: %s\nRechtsklick: hierhin fliegen.\nLandung und Aussteigen sind getrennte Befehle." % pilot
		if region=="rust":
			_detail.text+="\nRadar zeigt unbekannte Signale; Nähe identifiziert den Fund."
			for contact: Dictionary in contacts:
				var id: String=str(contact.id)
				if _contact_buttons.has(id):_contact_buttons[id].text=str(contact.get("label","Unbekanntes Signal"))+" →"
		if Regions.archetype(region)=="bunker_surface":_detail.text+="\nFlak voraus: außerhalb ihrer Reichweite landen."

func inspect_target(id: String) -> bool:
	return id=="pirate" or id.begins_with("signal_")
