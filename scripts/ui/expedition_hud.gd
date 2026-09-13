extends CanvasLayer
## Contextual flight controls. All actions go through the shared command gateway.
signal command_requested(command: Dictionary)
signal action_requested(action: String, payload: Dictionary)

const Icons = preload("res://scripts/ui/hud_icons.gd")
var _panel: PanelContainer
var _heading: Label
var _detail: Label
var _actions: GridContainer
var _contacts: VBoxContainer
var _buttons: Dictionary = {}
var _contact_buttons: Dictionary = {}
var _last_layout := ""
var _state: Dictionary = {}
var _guest := false

func _ready() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(80,78)
	_panel.custom_minimum_size = Vector2(294,0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035,0.065,0.09,0.96)
	style.border_color = Color("45676d")
	style.set_border_width_all(1)
	style.set_content_margin_all(13)
	_panel.add_theme_stylebox_override("panel",style)
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	_panel.add_child(column)
	_heading = _label("",15,Color("efab6f"))
	column.add_child(_heading)
	_detail = _label("",13,Color("e1e6e4"))
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size.x = 268
	column.add_child(_detail)
	_actions = GridContainer.new()
	_actions.columns = 2
	_actions.add_theme_constant_override("h_separation",6)
	_actions.add_theme_constant_override("v_separation",6)
	column.add_child(_actions)
	_contacts = VBoxContainer.new()
	_contacts.add_theme_constant_override("separation",5)
	column.add_child(_contacts)
	_panel.hide()

func _label(text: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size",size)
	result.add_theme_color_override("font_color",color)
	return result

func _action(id: String, title: String, icon: String, callback: Callable, parent: Node = null) -> Button:
	var button := Button.new()
	button.text = title
	button.icon = Icons.texture(icon)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width",20)
	button.add_theme_font_size_override("font_size",13)
	button.custom_minimum_size = Vector2(130,38)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	(parent if parent != null else _actions).add_child(button)
	_buttons[id] = button
	return button

func _send(kind: String, payload: Dictionary = {}) -> void:
	var command := payload.duplicate(true)
	command["type"] = kind
	command_requested.emit(command)

func present(state: Dictionary, guest: bool) -> void:
	_state = state
	_guest = guest
	if not is_instance_valid(_panel) or state.is_empty(): return
	var region: String = str(state.region)
	_panel.visible = region in ["rust","space"] and not bool(state.travel.active)
	if not _panel.visible: return
	var airborne: bool = str(state.ship.get("mode","landed")) == "flying"
	var discovery: Dictionary = state.get("discovery",{})
	var contacts: Array = discovery.get("signals",[])
	var layout: String = region+str(airborne)+str(contacts.size())
	if layout != _last_layout:
		_last_layout = layout
		for container: Node in [_actions,_contacts]:
			for child: Node in container.get_children():
				container.remove_child(child)
				child.queue_free()
		_buttons.clear()
		_contact_buttons.clear()
		_action("focus_ship","Schiff zeigen","target",func():action_requested.emit("focus_object",{"object_id":"shuttle"}))
		if region == "space":
			_action("fire_turret","Turm: Angriff","target",func():_send("fire_turret",{"target_id":"pirate"}))
			_action("stop_fire","Feuer einstellen","pause",func():_send("fire_turret",{"target_id":""}))
			_action("flee","Rückzug","shuttle",func():_send("flee"))
		elif airborne:
			_action("radar_scan","Radarimpuls","target",func():_send("radar_scan"))
			_action("land","Hier landen","load",func():_send("land"))
			for contact: Dictionary in contacts:
				var id: String = str(contact.id)
				var coords: Array = contact.position.duplicate()
				# The same stand-off for every anonymous contact keeps the landing clear.
				coords[1] = float(coords[1])+18.0
				var button := _action("contact_"+id,"Unbekanntes Signal","target",func():_send("ship_move",{"position":coords}),_contacts)
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_contact_buttons[id] = button
		else:
			_action("launch","Suchflug starten","shuttle",func():_send("launch"))
	if region == "space":
		var encounter: Dictionary = state.get("encounter",{})
		var enemy: Dictionary = encounter.get("enemy",{})
		_heading.text = "RAUMKONTAKT / FREIBEUTER"
		_detail.text = "Entersäbel %d %%   ·   Gegner %d / %d\nIda: Pilotin   ·   Jaro: Geschützturm\nRechtsklick: Ausweichziel auf der Ebene." % [int(state.ship.condition),int(enemy.get("hull",0)),int(enemy.get("max_hull",1))]
		var gunner: Dictionary = state.crew.get("jaro",{})
		var owns_gunner: bool = _guest or int(gunner.get("owner",1)) == 1
		_buttons.fire_turret.disabled = not owns_gunner or str(encounter.get("turret_target","")) == "pirate"
		_buttons.stop_fire.disabled = not owns_gunner or str(encounter.get("turret_target","")) == ""
		_buttons.fire_turret.tooltip_text = "Jaro nimmt das Ziel automatisch unter Feuer, sobald es in Reichweite ist." if owns_gunner else "Der Gast führt Jaro am Geschützturm."
		_buttons.flee.disabled = guest or float(encounter.get("escape_remaining",0)) > 0
		if float(encounter.get("escape_remaining",0)) > 0:
			_detail.text += "\nRückzug: %.1f s" % float(encounter.escape_remaining)
		elif str(encounter.get("turret_target","")) == "pirate": _detail.text += "\nTurm verfolgt das Ziel."
	else:
		_heading.text = "SUCHGEBIET / ROSTGRENZE"
		var found: bool = bool(discovery.get("satellite_found",false))
		_detail.text = "Satellit identifiziert. In der Nähe landen und eine Person zur Bergung schicken." if found else "Der Satellit liegt irgendwo in diesem Gebiet. Suchflug starten, Radarimpuls senden und unbekannte Kontakte anfliegen."
		if airborne:
			_detail.text += "\nRechtsklick: Flugziel. Kein Höhenflug."
			_buttons.radar_scan.disabled = guest
			_buttons.land.disabled = guest
			for contact: Dictionary in contacts:
				if not _contact_buttons.has(str(contact.id)): continue
				var button: Button = _contact_buttons[str(contact.id)]
				button.text = str(contact.get("label","Unbekanntes Signal"))+"  →"
				button.tooltip_text = "Kontakt anfliegen; erst die Nähe zeigt, was hier liegt."
				button.disabled = guest
		else:
			_buttons.launch.disabled = guest or bool(state.work.active) or bool(state.salvage.active)
		if guest: _detail.text += "\nDer Host fliegt und scannt. Du führst Jaro am Boden."

func inspect_target(id: String) -> bool:
	if id == "pirate":
		return true
	return id.begins_with("signal_")
