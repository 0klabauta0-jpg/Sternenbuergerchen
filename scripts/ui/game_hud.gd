extends CanvasLayer
class_name RestartHUD

signal command_requested(command: Dictionary)
signal action_requested(action: String, payload: Dictionary)

const Icons=preload("res://scripts/ui/hud_icons.gd")

const INK := Color("101d27")
const PAPER := Color("eee8da")
const MUTED := Color("a3b3b8")
const AMBER := Color("efab6f")
const CYAN := Color("86c5c2")
const REGIONS := {"base": "HEIMAT / ROSTGRENZE", "rust": "ROSTGRENZE / SIGNAL 07", "station": "ORBIT / HANDELSSTATION"}

var selected_unit := "ida"
var selected_units: Array[String]=["ida"]
var _direct_mode := false
var selection_kind := "object"
var selection_id := ""
var _state: Dictionary = {}
var _root: Control
var _resources: Label
var _location: Label
var _network: Label
var _context_title: Label
var _context_text: RichTextLabel
var _context_actions: GridContainer
var _hint: Label
var _log: Label
var _toast: Label
var _pause: Button
var _control_toggle: Button
var _controls: Label
var _progress: ProgressBar
var _progress_text: Label
var _travel_panel: PanelContainer
var _travel_title: Label
var _travel_progress: ProgressBar
var _crew_buttons: Dictionary = {}
var _action_buttons: Dictionary = {}
var _last_region := ""
var _toast_seconds := 0.0
var _guest := false
var _worker: OptionButton
var _network_window: Window
var _address: LineEdit
var _context_panel: PanelContainer
var _objective: Label
var _objective_button: Button
var _objective_id := "contracts"
var _menu: PopupMenu
var _recipes: Dictionary={}
var _prices: Dictionary={}
var _activity: Label
var _credit_value: Label
var _ship_value: Label
var _cargo_value: Label
var _quick_actions: Dictionary={}
var _crew_caption: Label

func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var theme := Theme.new()
	theme.default_font_size = 14
	var font:=SystemFont.new()
	font.font_names=PackedStringArray(["Bahnschrift","Segoe UI"])
	theme.default_font=font
	theme.set_stylebox("panel","TooltipPanel",_style(Color("101b21"),1,CYAN))
	theme.set_color("font_color","TooltipLabel",PAPER)
	theme.set_font_size("font_size","TooltipLabel",14)
	theme.set_color("font_color", "Label", PAPER)
	theme.set_color("font_color", "Button", PAPER)
	theme.set_stylebox("normal", "Button", _style(Color("243640"), 5))
	theme.set_stylebox("hover", "Button", _style(Color("36545c"), 5))
	theme.set_stylebox("pressed", "Button", _style(Color("4b696b"), 5))
	theme.set_stylebox("disabled", "Button", _style(Color("172630"), 5))
	theme.set_color("font_disabled_color", "Button", Color("a6b0b5"))
	theme.set_stylebox("focus", "Button", _style(Color(0,0,0,0), 5, CYAN))
	for state: String in ["normal","hover","pressed","disabled"]:
		theme.get_stylebox(state,"Button").content_margin_top=7
		theme.get_stylebox(state,"Button").content_margin_bottom=7
	_root.theme = theme
	_build_top()
	_build_crew()
	_build_objective()
	_build_quick_actions()
	_build_context()
	_build_footer()
	_build_travel()
	_build_network()
	set_process(true)

func _style(color: Color, radius: int = 8, border: Color = Color("33464e")) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(1)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 7
	box.content_margin_bottom = 7
	return box

func _panel(anchor: int, offsets: Rect2) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(anchor)
	panel.offset_left = offsets.position.x
	panel.offset_top = offsets.position.y
	panel.offset_right = offsets.end.x
	panel.offset_bottom = offsets.end.y
	panel.add_theme_stylebox_override("panel", _style(Color(0.035,0.065,0.09,0.94)))
	_root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	return column

func _label(text: String, size: int = 15, color: Color = PAPER) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, callback: Callable, parent: Node, height: float = 36) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = height
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _build_top() -> void:
	var top:=_panel(Control.PRESET_TOP_WIDE,Rect2(12,10,-24,44))
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",18)
	top.add_child(row)
	var brand:=_label("STERNENBÜRGERCHEN",14,PAPER)
	row.add_child(brand)
	_location=_label("ROSTGRENZE",12,MUTED)
	_location.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(_location)
	_credit_value=_metric(row,"credit","Credits")
	_ship_value=_metric(row,"shuttle","Zustand der Entersäbel")
	_cargo_value=_metric(row,"storage","Fracht / Kapazität")
	_pause=_icon_button("pause","Pause / Weiter [Leertaste]",func():_send("toggle_pause"),row)
	_control_toggle=_icon_button("crew","Der gewählten Figur folgen [V]",func():action_requested.emit("toggle_control",{}),row)
	_menu=PopupMenu.new()
	add_child(_menu)
	for entry: Array in [["Speichern · F5",1],["Laden · F9",2],["Koop-Verbindung",3],["Logbuch",4],["Bedienung",5],["Speichern und beenden",6]]: _menu.add_item(entry[0],entry[1])
	_menu.id_pressed.connect(_menu_action)
	_icon_button("menu","Menü · Speichern, Laden, Koop und Hilfe",func():_menu.popup(Rect2i(Vector2i(get_viewport().get_mouse_position()),Vector2i(240,0))),row)
	_resources=Label.new();_resources.hide();row.add_child(_resources)

func _build_crew() -> void:
	var column:=_panel(Control.PRESET_BOTTOM_LEFT,Rect2(12,-160,332,110))
	var header:=HBoxContainer.new()
	column.add_child(header)
	_crew_caption=_label("CREW / 01 GEWÄHLT",11,AMBER)
	_crew_caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(_crew_caption)
	_icon_button("target","Zur gewählten Figur",func():action_requested.emit("focus_unit",{"unit_id":selected_unit}),header,24)
	var cards:=HBoxContainer.new()
	cards.add_theme_constant_override("separation",6)
	column.add_child(cards)
	for id: String in ["ida","jaro"]:
		var button:=_button(id,func():choose_unit(id,false),cards,62)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		button.icon=load("res://assets/ui/crew_portrait.png")
		button.expand_icon=true
		button.add_theme_constant_override("icon_max_width",40)
		button.add_theme_font_size_override("font_size",12)
		_crew_buttons[id]=button
	_network=Label.new();_network.hide();column.add_child(_network)

func _build_context() -> void:
	var column:=_panel(Control.PRESET_BOTTOM_RIGHT,Rect2(-410,-350,398,300))
	_context_panel=column.get_parent()
	var heading:=HBoxContainer.new()
	column.add_child(heading)
	_context_title=_label("",16)
	_context_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_context_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(_context_title)
	_icon_button("close","Auswahl schließen [Esc]",dismiss_context,heading,24)
	_context_text=RichTextLabel.new()
	_context_text.bbcode_enabled=true
	_context_text.fit_content=true
	_context_text.scroll_active=false
	_context_text.add_theme_font_size_override("normal_font_size",13)
	column.add_child(_context_text)
	_worker=OptionButton.new()
	_worker.add_item("Ida · Technik 3",0)
	_worker.add_item("Jaro · Technik 1",1)
	_worker.item_selected.connect(func(index: int):choose_unit("ida" if index==0 else "jaro",false))
	column.add_child(_worker)
	_progress=ProgressBar.new()
	_progress.custom_minimum_size.y=10
	_progress.show_percentage=false
	_progress.add_theme_stylebox_override("fill",_style(CYAN,3,CYAN))
	column.add_child(_progress)
	_progress_text=_label("",12,CYAN)
	_progress_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_progress_text)
	_context_actions=GridContainer.new()
	_context_actions.columns=2
	_context_actions.add_theme_constant_override("separation",7)
	column.add_child(_context_actions)
	_hint=_label("",12,MUTED)
	_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_hint)
	_context_panel.hide()

func _build_footer() -> void:
	var column:=_panel(Control.PRESET_BOTTOM_WIDE,Rect2(12,-38,-24,26))
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",24)
	column.add_child(row)
	_activity=_label("",12,CYAN)
	row.add_child(_activity)
	_toast=_label("Auftragskonsole: Erste Bergung",12,PAPER)
	_toast.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_toast.clip_text=true
	row.add_child(_toast)
	_controls=Label.new();_controls.hide();column.add_child(_controls)
	_log=Label.new();_log.hide();column.add_child(_log)

func _build_travel() -> void:
	_travel_panel = PanelContainer.new()
	_travel_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_travel_panel.position = Vector2(-260,-76)
	_travel_panel.size = Vector2(520,152)
	_travel_panel.add_theme_stylebox_override("panel",_style(INK))
	_root.add_child(_travel_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	_travel_panel.add_child(column)
	column.add_child(_label("ENTERSÄBEL / REISE", 12, AMBER))
	_travel_title = _label("Anflug",22)
	column.add_child(_travel_title)
	_travel_progress = ProgressBar.new()
	_travel_progress.custom_minimum_size.y=14
	column.add_child(_travel_progress)
	_travel_panel.hide()

func _build_network() -> void:
	_network_window = Window.new()
	_network_window.title = "Koop · dieselbe Crew, zwei Commander"
	_network_window.unresizable = true
	_network_window.transient = true
	_network_window.close_requested.connect(_network_window.hide)
	add_child(_network_window)
	_network_window.hide()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,20)
	_network_window.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)
	column.add_child(_label("Host führt Ida. Gast führt Jaro.",16))
	column.add_child(_label("Reise, Handel und gemeinsame Pause beim Host.",12,MUTED))
	_address = LineEdit.new()
	_address.text="127.0.0.1"
	_address.placeholder_text="IP-Adresse des Hosts"
	column.add_child(_address)
	_button("Sitzung öffnen",func(): action_requested.emit("host",{}); _network_window.hide(),column)
	_button("Beitreten",func(): action_requested.emit("join",{"address":_address.text.strip_edges()}); _network_window.hide(),column)
	_button("Verbindung schließen",func(): action_requested.emit("disconnect",{}); _network_window.hide(),column)

func choose_unit(id: String, focus: bool) -> void:
	selected_unit=id
	selected_units=[id]
	_worker.select(0 if id == "ida" else 1)
	action_requested.emit("selection_changed",{})
	if focus:
		selection_kind="unit"
		selection_id=id
		_rebuild_actions()
		action_requested.emit("focus_unit",{"unit_id":id})
	_update_context()
	if not _recipes.is_empty(): set_recipe_details(_recipes,_prices)

func select_object(kind: String, id: String) -> void:
	selection_kind=kind
	selection_id=id
	if kind == "unit":
		selected_unit=id
		selected_units=[id]
		_worker.select(0 if id == "ida" else 1)
		action_requested.emit("selection_changed",{})
	_rebuild_actions()
	_update_context()

func select_units(ids: Array[String]) -> void:
	if ids.is_empty(): return
	selected_units=ids.duplicate()
	selected_unit=ids[0]
	selection_kind="unit"
	selection_id=selected_unit
	_worker.select(0 if selected_unit=="ida" else 1)
	action_requested.emit("selection_changed",{})
	_rebuild_actions()
	_update_context()

func set_direct_mode(enabled: bool) -> void:
	_direct_mode=enabled
	_control_toggle.tooltip_text="Freie Crewansicht [V]" if enabled else "Der gewählten Figur folgen [V]"
	_control_toggle.icon=Icons.texture("target" if enabled else "crew")
	_update_context()

func set_connection(text: String, guest: bool) -> void:
	_network.text=text
	if guest and not _guest: choose_unit("jaro",false)
	_guest=guest
	_pause.disabled=guest
	_pause.tooltip_text="Der Host steuert die gemeinsame Pause." if guest else "Leertaste: Pause / Weiter"

func present(state: Dictionary) -> void:
	_state=state
	if state.is_empty(): return
	var region: String=state.get("region","base")
	if region != _last_region:
		_last_region=region
		selection_kind="object"
		selection_id=""
		_rebuild_actions()
	_location.text=REGIONS.get(region,region.to_upper())
	var cargo: Dictionary=state.get("cargo",{})
	var cargo_used: int=0
	for value: Variant in cargo.values(): cargo_used += int(value)
	_resources.text="%s Credits    ·    Shuttle %d %%    ·    Fracht %d / %d" % [str(state.get("credits",0)),int(state.get("ship",{}).get("condition",0)),cargo_used,int(state.get("ship",{}).get("capacity",0))]
	_pause.icon=Icons.texture("play" if state.get("paused",false) else "pause")
	_credit_value.text=str(state.credits)
	_ship_value.text=str(int(state.ship.condition))+"%"
	_cargo_value.text=str(cargo_used)+" / "+str(state.ship.capacity)
	_crew_caption.text="CREW / "+str(selected_units.size())+" GEWÄHLT"
	_crew_caption.tooltip_text=_network.text
	for id: String in _crew_buttons:
		var unit: Dictionary=state.get("crew",{}).get(id,{})
		var assignment: String=unit.get("assignment","idle")
		var work_label: String={"idle":"Bereit", "work":"Werkstatt", "salvage":"Bergung", "boarding":"Zum Shuttle", "moving":"Unterwegs"}.get(assignment,assignment)
		var button: Button=_crew_buttons[id]
		var owns: bool=_owns(id)
		var owner_label: String="DU" if owns else "HOST" if _guest else "GAST"
		button.text=("● " if id in selected_units else "○ ")+str(unit.get("name",id))+"  "+owner_label+"\n"+work_label
		button.add_theme_stylebox_override("normal",_style(Color("304d53") if id in selected_units else Color("243640"),5,CYAN if id in selected_units else Color("33464e")))
	var entries: Array=state.get("log",[])
	var recent: PackedStringArray=[]
	for i: int in range(maxi(0,entries.size()-3),entries.size()): recent.append(str(entries[i]))
	_log.text="\n".join(recent)
	var travel: Dictionary=state.get("travel",{})
	_travel_panel.visible=travel.get("active",false)
	if _travel_panel.visible:
		var destination: String=travel.get("to","base")
		_travel_title.text=("Crew steigt ein" if travel.get("phase","")=="boarding" else "Unterwegs nach "+REGIONS.get(destination,destination))
		_travel_progress.value=_fraction(travel)
	_update_objective()
	_update_context()

func _rebuild_actions() -> void:
	if not is_instance_valid(_context_actions): return
	for child: Node in _context_actions.get_children():
		_context_actions.remove_child(child)
		child.queue_free()
	_action_buttons.clear()
	_context_actions.columns=3 if selection_id in ["market","workbench"] else 1 if selection_id=="storage" else 2
	_worker.visible=selection_id in ["workbench","satellite"]
	match selection_id:
		"contracts":
			_add_command("accept_contract","Auftrag annehmen","accept_contract")
			_add_command("claim_contract","Bergung abgeben","claim_contract")
		"workbench":
			_add_command("toolkit","Werkzeugkit herstellen","assign_work",{"recipe_id":"toolkit"},true)
			_add_command("repair","Shuttle reparieren","assign_work",{"recipe_id":"repair"},true)
			_add_command("cutter","Präzisionsschneider herstellen","assign_work",{"recipe_id":"cutter"},true)
			_add_command("cancel_work","Abbrechen","cancel_work")
		"satellite":
			_icon_button("target","Absturzstelle zeigen",func():action_requested.emit("focus_object",{"object_id":"satellite"}),_context_actions)
			_add_command("salvage","Hingehen und bergen","salvage",{},true)
			_add_command("cancel_salvage","Bergung abbrechen","cancel_salvage")
		"shuttle":
			_icon_button("target","Shuttle zeigen",func():action_requested.emit("focus_object",{"object_id":"shuttle"}),_context_actions)
			_add_command("rust","Zur Absturzstelle","travel",{"destination":"rust"})
			_add_command("base","Heimfliegen","travel",{"destination":"base"})
			_add_command("station","Zur Handelsstation","travel",{"destination":"station"})
		"market":
			for item: String in ["scrap","parts"]:
				var label: String="Metall" if item=="scrap" else "Bauteil"
				_add_command("buy_"+item,label+" kaufen (+1)","trade",{"side":"buy","item":item,"amount":1})
				_add_command("sell_"+item,label+" verkaufen (−1)","trade",{"side":"sell","item":item,"amount":1})
			_add_command("sell_toolkit","Werkzeugkit verkaufen","trade",{"side":"sell","item":"toolkit","amount":1})
			_add_command("sell_cutter","Schneider verkaufen","trade",{"side":"sell","item":"cutter","amount":1})
		"storage":
			_hint.text="Güter aus dem Shuttle werden zu Hause ins Lager übernommen."
			for item: String in ["scrap","parts","toolkit","cutter"]:
				var row:=HBoxContainer.new()
				_context_actions.add_child(row)
				_add_command("load_"+item,_item_name(item),"transfer",{"item":item,"amount":1,"direction":"load"},false,row)
				_add_command("unload_"+item,"Ausladen","transfer",{"item":item,"amount":1,"direction":"unload"},false,row)

func _add_command(key: String,label: String,type: String,data: Dictionary={},with_unit: bool=false,parent: Node=null) -> void:
	var captions: Dictionary={"accept_contract":"Annehmen","claim_contract":"Abgeben","toolkit":"Werkzeugkit","repair":"Reparieren","cutter":"Schneider","cancel_work":"Abbrechen","salvage":"Bergen","cancel_salvage":"Abbrechen","rust":"Signal 07","base":"Heimat","station":"Markt"}
	var button:=_button(captions.get(key,label),func():
		var payload: Dictionary=data.duplicate(true)
		if with_unit: payload["unit_id"]=selected_unit
		_send(type,payload),_context_actions if parent==null else parent,48)
	button.icon=Icons.texture(_action_icon(key))
	button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",22)
	button.add_theme_font_size_override("font_size",12)
	button.tooltip_text=label
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.x=112 if parent==null else 165
	_action_buttons[key]=button

func _send(type: String, payload: Dictionary={}) -> void:
	var command: Dictionary=payload.duplicate(true)
	command["type"]=type
	command_requested.emit(command)

func _update_context() -> void:
	if _state.is_empty() or not is_instance_valid(_context_title): return
	_context_panel.visible=not selection_id.is_empty()
	if selection_id.is_empty(): return
	var inventory: Dictionary=_state.inventory
	var cargo: Dictionary=_state.cargo
	var contract: Dictionary=_state.contract
	var work: Dictionary=_state.work
	var salvage: Dictionary=_state.salvage
	var actor: Dictionary=_state.crew.get(selected_unit,{})
	_progress.visible=false
	_progress_text.text=""
	_hint.text=""
	var busy: bool=work.active
	_worker.disabled=busy if selection_id=="workbench" else bool(salvage.active)
	if not _worker.disabled: _worker.select(0 if selected_unit=="ida" else 1)
	for index: int in range(2):
		_worker.set_item_disabled(index,not _owns("ida" if index==0 else "jaro"))
	var height: float={"workbench":320,"market":265,"storage":330,"shuttle":290,"satellite":305,"contracts":250}.get(selection_id,205)
	_context_panel.offset_top=-height-50
	_context_panel.offset_bottom=-50
	match selection_id:
		"contracts":
			_context_title.text="Ein Signal im Staub"
			_context_text.text="Ein abgestürzter Satellit sendet noch. Bringe seine Blackbox nach Hause.\n\n[b]260 Credits + Bauplan: Schneider[/b]"
			_disable("accept_contract",contract.status!="available" or _guest)
			_disable("claim_contract",int(inventory.blackbox)<1 or contract.status=="claimed" or _guest)
			_hint.text="Der Host koordiniert die Aufträge." if _guest else "Abgeben, sobald die Blackbox im Basislager liegt."
		"workbench":
			_context_title.text="Werkbank"
			_context_text.text="Verfügbar im Lager: [b]%d Metall · %d Bauteile[/b]\nArbeiter für den nächsten Auftrag:" % [int(inventory.scrap),int(inventory.parts)]
			if busy:
				var worker: Dictionary=_state.crew[work.unit_id]
				_worker.select(0 if work.unit_id=="ida" else 1)
				_context_text.text="[b]%s · %s[/b]\nReserviert: %s" % [_recipe_name(work.recipe_id),worker.name,_items(work.reserved)]
				_show_progress(work,"Werkbank")
			_disable("cancel_work",not busy or (busy and not _owns(work.unit_id)))

		"satellite":
			_context_title.text="Abgestürzter Satellit"
			_context_text.text="[b]Bestand: %d Metall[/b]\nBlackbox an Bord: %d\n\nDie gewählte Person läuft zum Wrack und beginnt dort mit der Bergung." % [int(_state.wreck_remaining),int(cargo.blackbox)]
			var blocked: String=""
			if not _owns(selected_unit): blocked="Diese Figur gehört dem anderen Commander."
			elif actor.assignment!="idle": blocked="Die gewählte Person ist bereits im Einsatz."
			elif _state.wreck_remaining<=0: blocked="Wrack vollständig geborgen."
			_disable("salvage",salvage.active or not blocked.is_empty())
			_disable("cancel_salvage",not salvage.active or (salvage.active and not _owns(salvage.unit_id)))
			_hint.text=blocked
			if salvage.active: _show_progress(salvage,"Bergung")
		"shuttle":
			_context_title.text="Entersäbel"
			_context_text.text="[b]Zustand %d %% · Fracht %d / %d[/b]\nAn Bord: %s\n\nDie Crew sammelt sich vor dem Abflug am Schiff." % [int(_state.ship.condition),_cargo_used(),int(_state.ship.capacity),_items(cargo)]
			var blocked: String="Der Host entscheidet über die gemeinsame Reise." if _guest else "Laufende Arbeit zuerst beenden oder abbrechen." if work.active or salvage.active else ""
			for key: String in ["base","rust","station"]:
				_disable(key,_state.region==key or _state.travel.active or not blocked.is_empty() or (key=="rust" and contract.status=="available"))
			_hint.text=blocked if not blocked.is_empty() else "Für die Absturzstelle zuerst den Auftrag annehmen." if contract.status=="available" else "Reiseziel wählen."
		"market":
			_context_title.text="Stationsmarkt"
			_context_text.text="[b]%d Credits · Fracht %d / %d[/b]\nAn Bord: %s" % [int(_state.credits),_cargo_used(),int(_state.ship.capacity),_items(cargo)]
			_hint.text="Handel übernimmt der Host." if _guest else "Einkäufe kommen ins Shuttle. Zu Hause wird automatisch ausgeladen."

		"storage":
			_context_title.text="Basislager"
			_context_text.text="[b]Im Lager[/b]  "+_items(inventory)+"\n\n[b]Im Shuttle[/b]  "+_items(cargo)
			_hint.text="Je Klick ein Gut. Ausladen macht eine Verladung rückgängig."
			for item: String in ["scrap","parts","toolkit","cutter"]:
				_disable("load_"+item,_guest or int(inventory[item])<=0 or _cargo_used()>=int(_state.ship.capacity) or _state.travel.active)
				_disable("unload_"+item,_guest or int(cargo[item])<=0 or _state.travel.active)
		"bed_ida","bed_jaro":
			_context_title.text="Ein Platz für "+("Ida" if selection_id=="bed_ida" else "Jaro")
			_context_text.text="Fest reserviertes Bett.\n\nZwei Freunde, zwei Schlafplätze. Mehr Crew braucht später weiteren Wohnraum."
		_:
			_context_title.text="Gruppe · "+str(selected_units.size()) if selected_units.size()>1 and not _direct_mode else str(actor.get("name",selected_unit))
			_context_text.text="[b]Rechtsklick setzt das Laufziel.[/b]\n"+("Die Kamera folgt "+str(actor.get("name",selected_unit))+"." if _direct_mode else "Ein Rahmen wählt mehrere Personen.")+"\n\nTechnik "+str(actor.get("skill",0))+" · "+("Deine Figur" if _owns(selected_unit) else "Anderer Commander")
			_hint.text="Arbeitsplatz anklicken, dann eine Person zuweisen."

func set_recipe_details(recipes: Dictionary,prices: Dictionary) -> void:
	_recipes=recipes
	_prices=prices
	if _state.is_empty(): return
	if selection_id=="workbench":
		for id: String in ["toolkit","repair","cutter"]:
			var recipe: Dictionary=recipes[id]
			var reason: String=_recipe_blocked(id,recipe)
			var button: Button=_action_buttons[id]
			var caption: String={"toolkit":"Werkzeugkit","repair":"Reparieren","cutter":"Schneider"}[id]
			var short_reason: String="Belegt" if _state.work.active else "Bauplan fehlt" if not id in _state.blueprints else "Technik "+str(recipe.min_skill) if int(_state.crew[selected_unit].skill)<int(recipe.min_skill) else "Gesperrt"
			button.text=caption+"\n"+(str(int(recipe.duration))+" s" if reason.is_empty() else short_reason)
			button.add_theme_font_size_override("font_size",12)
			button.tooltip_text=str(recipe.label)+"\nKosten: "+_items(recipe.materials)+" · Technik "+str(recipe.min_skill)+("\n"+reason if not reason.is_empty() else "\nAuftrag mit "+str(_state.crew[selected_unit].name)+" starten")
			button.disabled=not reason.is_empty()
			if not _state.work.active:
				var actor: Dictionary=_state.crew[selected_unit]
				_hint.text=str(actor.name)+" · Technik "+str(actor.skill)+" | Kit: 2 Metall + 1 Bauteil | Reparatur: 2 + 1\nSchneider: 3 Metall + 2 Bauteile · Bauplan aus der Bergung"
				if int(actor.skill)<2: _hint.text=str(actor.name)+": Technik 2 benötigt. Wähle Ida für diese Aufträge."
	elif selection_id=="market":
		for key: String in _action_buttons:
			var side: String=key.get_slice("_",0)
			var item: String=key.trim_prefix(side+"_")
			var amount: int=int(prices[item][side])
			_action_buttons[key].text=_item_name(item)+"\n"+("−" if side=="buy" else "+")+str(amount)+" Cr"
			var blocked: bool=_guest or _state.travel.active
			if side=="buy": blocked=blocked or int(_state.credits)<amount or _cargo_used()>=int(_state.ship.capacity)
			else: blocked=blocked or int(_state.cargo[item])<=0
			_action_buttons[key].disabled=blocked
			_action_buttons[key].tooltip_text="Der Host handelt." if _guest else "Kein Bestand an Bord." if side=="sell" and int(_state.cargo[item])<=0 else "Nicht genug Credits oder Frachtraum." if blocked else "Eine Einheit handeln"

func _items(items: Dictionary) -> String:
	var parts: PackedStringArray=[]
	for id: String in items:
		if int(items[id])>0: parts.append("%d %s" % [int(items[id]),_item_name(id)])
	return " · ".join(parts) if not parts.is_empty() else "leer"

func _item_name(id: String) -> String:
	return {"scrap":"Metall","parts":"Bauteile","toolkit":"Werkzeugkit","cutter":"Schneider","blackbox":"Blackbox"}.get(id,id)

func _disable(key: String, value: bool) -> void:
	if _action_buttons.has(key): _action_buttons[key].disabled=value

func _show_progress(job: Dictionary,label: String) -> void:
	_progress.visible=true
	_progress.value=_fraction(job)
	var stage: String="Läuft zum Arbeitsplatz" if job.get("phase","")=="walking" else "%0.1f s verbleiben" % float(job.get("remaining",0))
	_progress_text.text=label+" · "+("PAUSIERT · "+stage if _state.paused else stage)

func _fraction(job: Dictionary) -> float:
	return clampf(100.0*(1.0-float(job.get("remaining",0))/maxf(0.001,float(job.get("total",1)))),0,100)

func notify(message: String) -> void:
	_toast.text=message
	_toast_seconds=8.0

func _process(delta: float) -> void:
	if _toast_seconds>0:
		_toast_seconds-=delta
		if _toast_seconds<=0: _toast.text="F5: Speichern · F9: Laden · Menü: Logbuch und Hilfe"

func _show_help() -> void:
	var dialog:=AcceptDialog.new()
	dialog.title="So beginnt die erste Reise"
	dialog.dialog_text="Auftragskonsole → Auftrag annehmen → Shuttle → Absturzstelle.\nAm Satelliten eine Person zuweisen, bergen, heimfliegen und abgeben.\nWerkbank: Arbeiter wählen, Kosten prüfen, Auftrag starten.\n\nLinksklick: Figur oder Objekt wählen\nRahmen ziehen: mehrere Figuren wählen\nRechtsklick: Laufziel für die Auswahl\nWASD / Pfeile / mittlere Maus: Kamera\nV: Einzelansicht mit Kamerafolge / freie Crewansicht\n1 / 2: Crew wählen · Home: Überblick · Rad: Zoom\nLeertaste: Pause · F5: Speichern · F9: Laden\n\nKoop: Host führt Ida und die gemeinsame Reise; Gast führt Jaro."
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(660,420))

func _build_objective() -> void:
	var column:=_panel(Control.PRESET_TOP_RIGHT,Rect2(-330,68,318,60))
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	column.add_child(row)
	_objective_button=_icon_button("contracts","Auftrag zeigen",func():action_requested.emit("inspect_object",{"object_id":_objective_id}),row,34)
	_objective=_label("",13,PAPER)
	_objective.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	row.add_child(_objective)

func _update_objective() -> void:
	for id: String in _quick_actions:
		_quick_actions[id].visible=id=="shuttle" or (_state.region=="base" and id in ["contracts","workbench","storage"]) or (_state.region=="station" and id=="market")
	var status: String=_state.contract.status
	_objective_id="contracts"
	var text: String="Erster Auftrag · 260 Credits + Bauplan"
	var action: String="Auftragskonsole zeigen"
	if _state.region=="station":
		text="Handelsstation · Güter liegen im Shuttle";action="Markt öffnen";_objective_id="market"
	elif _state.region=="rust":
		text="Blackbox geborgen · Zurück nach Hause" if status=="recovered" else "Signal 07 · Blackbox bergen"
		action="Shuttle zeigen" if status=="recovered" else "Absturzstelle zeigen"
		_objective_id="shuttle" if status=="recovered" else "satellite"
	elif status=="active":
		text="Auftrag angenommen · Zur Absturzstelle";action="Shuttle öffnen";_objective_id="shuttle"
	elif status=="recovered": text="Zurück daheim · Bergung abgeben";action="Auftrag abgeben"
	elif status=="claimed": text="Bauplan erhalten · Schneider herstellen";action="Werkbank öffnen";_objective_id="workbench"
	_objective.text=text
	_objective_button.tooltip_text=action
	_objective_button.icon=Icons.texture(_objective_id)
	var name: String=str(_state.crew[selected_unit].name)
	_activity.text="Kamera folgt "+name+" · Rechtsklick: Laufziel · WASD: Kamera" if _direct_mode else str(selected_units.size())+" gewählt · RMT Laufziel · WASD Kamera"
	for job: Dictionary in [_state.work,_state.salvage]:
		if job.active:
			_activity.text=str(_state.crew[job.unit_id].name)+" · "+(_recipe_name(job.recipe_id) if job.has("recipe_id") else "Bergung")+" · "+("pausiert" if _state.paused else "auf dem Weg" if job.get("phase","")=="walking" else "in Arbeit")
	_controls.text="Linksklick: wählen  ·  Rechtsklick: Laufziel  ·  WASD: Kamera  ·  V: Ansicht  ·  Leertaste: Pause"

func dismiss_context() -> void:
	selection_kind="object";selection_id=""
	_context_panel.hide()
	action_requested.emit("dismiss_selection",{})

func _owns(id: String) -> bool:
	if not _state.get("crew",{}).has(id): return false
	return id=="jaro" if _guest else int(_state.crew[id].owner)==1

func _cargo_used() -> int:
	var amount:=0
	for value: Variant in _state.get("cargo",{}).values(): amount+=int(value)
	return amount

func _recipe_name(id: String) -> String:
	return str(_recipes.get(id,{}).get("label",{"toolkit":"Werkzeugkit","repair":"Shuttle reparieren","cutter":"Schneider"}.get(id,id)))

func _recipe_blocked(id: String,recipe: Dictionary) -> String:
	var actor: Dictionary=_state.crew[selected_unit]
	if _state.work.active: return "Werkbank belegt · laufender Auftrag"
	if not _owns(selected_unit): return "Person gehört dem anderen Commander"
	if actor.assignment!="idle": return str(actor.name)+" ist bereits im Einsatz"
	if not id in _state.blueprints: return "Bauplan fehlt · zuerst die Blackbox bergen"
	if int(actor.skill)<int(recipe.min_skill): return "Technik %d nötig · %s hat %d" % [int(recipe.min_skill),str(actor.name),int(actor.skill)]
	for item: String in recipe.materials:
		var missing: int=int(recipe.materials[item])-int(_state.inventory[item])
		if missing>0: return "Es fehlen %d %s" % [missing,_item_name(item)]
	if id=="repair" and _state.ship.condition>=100: return "Shuttle ist vollständig repariert"
	return ""

func _menu_action(id: int) -> void:
	match id:
		1: action_requested.emit("save",{})
		2: action_requested.emit("load",{})
		3: _network_window.popup_centered(Vector2i(460,290))
		4:
			var dialog:=AcceptDialog.new()
			dialog.title="Logbuch"
			dialog.dialog_text="\n".join(PackedStringArray(_state.get("log",[])))
			add_child(dialog)
			dialog.confirmed.connect(dialog.queue_free)
			dialog.canceled.connect(dialog.queue_free)
			dialog.popup_centered(Vector2i(750,600))
		5: _show_help()
		6: action_requested.emit("quit",{})

func _metric(parent: Node,icon: String,hint: String) -> Label:
	var row:=HBoxContainer.new()
	row.tooltip_text=hint
	parent.add_child(row)
	var symbol:=TextureRect.new()
	symbol.texture=Icons.texture(icon)
	symbol.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	symbol.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	symbol.custom_minimum_size=Vector2(18,18)
	row.add_child(symbol)
	var value:=_label("0",14,PAPER)
	row.add_child(value)
	return value

func _icon_button(icon: String,hint: String,callback: Callable,parent: Node,dimension: int=30) -> Button:
	var button:=_button("",callback,parent,dimension)
	for state: String in ["normal","hover","pressed","disabled"]:
		var style: StyleBoxFlat=button.get_theme_stylebox(state).duplicate()
		style.content_margin_left=4;style.content_margin_right=4
		style.content_margin_top=4;style.content_margin_bottom=4
		button.add_theme_stylebox_override(state,style)
	button.custom_minimum_size=Vector2(dimension,dimension)
	button.icon=Icons.texture(icon)
	button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",18)
	button.tooltip_text=hint
	return button

func _action_icon(key: String) -> String:
	if key.begins_with("buy_") or key.begins_with("load_"): return "load"
	if key.begins_with("sell_") or key.begins_with("unload_"): return "unload"
	return {"accept_contract":"contracts","claim_contract":"check","cancel_work":"close","cancel_salvage":"close","salvage":"satellite","rust":"satellite","station":"market"}.get(key,key)

func _build_quick_actions() -> void:
	var column:=_panel(Control.PRESET_TOP_LEFT,Rect2(12,68,46,205))
	for id: String in ["contracts","workbench","storage","shuttle","market"]:
		var label: String={"contracts":"Auftragskonsole","workbench":"Werkbank","storage":"Lager","shuttle":"Entersäbel · Shuttle","market":"Stationsmarkt"}[id]
		_quick_actions[id]=_icon_button(id,label,func():action_requested.emit("inspect_object",{"object_id":id}),column,30)
