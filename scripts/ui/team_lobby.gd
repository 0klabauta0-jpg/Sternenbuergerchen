extends Window
## Membership and home assignments are host commands, never local simulation edits.
signal command_requested(command:Dictionary)
var _body:VBoxContainer
var _signature:=""
func _ready() -> void:
	title="Team-Lobby · Gemeinsam gegen das andere Team"
	size=Vector2i(800,680);min_size=size
	close_requested.connect(hide)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	_body=VBoxContainer.new();_body.add_theme_constant_override("separation",12);margin.add_child(_body)
	hide()
func _label(text:String,parent:Node) -> void:
	var label:=Label.new();label.text=text;parent.add_child(label)
func present(state:Dictionary,host:bool) -> void:
	if not is_node_ready():return
	var campaign:Dictionary=state.get("campaign",{})
	var signature:=JSON.stringify(campaign)+str(host)
	if signature==_signature:return
	_signature=signature
	for child in _body.get_children():_body.remove_child(child);child.queue_free()
	if campaign.is_empty():
		_label("Gemeinsame Koop-Karriere",_body)
		_label("Für Team gegen Team im Hauptmenü eine Team-Partie öffnen.",_body)
		return
	_label("ZWEI TEAMS · BIS ZU ACHT COMMANDER JE TEAM",_body)
	_label("Du spielst in Team %d. Alle im Team führen dieselbe Crew und Flotte."%[int(campaign.team)+1],_body)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size.y=360;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;_body.add_child(scroll)
	var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",32);columns.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(columns)
	for team in 2:
		var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(column)
		var count:=0
		for peer in campaign.members:
			if int(campaign.members[peer])==team:count+=1
		_label("TEAM %d · %d / 8"%[team+1,count],column)
		var home:=OptionButton.new()
		var worlds:Array=campaign.planets.keys()
		for world in worlds:home.add_item(str(campaign.planets[world]))
		home.select(worlds.find(campaign.homes[team]));home.disabled=not host or campaign.started
		home.item_selected.connect(func(index:int):command_requested.emit({"type":"select_home","team":team,"planet":worlds[index]}))
		column.add_child(home)
		var ai:=CheckButton.new();ai.text="KI · Basiswirtschaft";ai.button_pressed=campaign.get("ai",[false,false])[team];ai.disabled=not host or not campaign.lobby_open
		ai.tooltip_text="Erste KI: nimmt Auftrag an, repariert und fertigt mit vorhandenen Materialien. Keine selbstständigen Expeditionen."
		ai.toggled.connect(func(enabled:bool):command_requested.emit({"type":"set_team_ai","team":team,"enabled":enabled}))
		column.add_child(ai)
		for peer in campaign.members:
			if int(campaign.members[peer])!=team:continue
			var button:=Button.new();button.custom_minimum_size.y=36
			button.text=("Host" if int(peer)==1 else "Commander %s"%peer)+("   → Team %d"%[2-team] if host else "")
			button.disabled=not host or not campaign.lobby_open
			button.pressed.connect(func():command_requested.emit({"type":"assign_team","peer_id":int(peer),"team":1-team}))
			column.add_child(button)
	var detail:="In der offenen Lobby pausiert die Partie. Der Host verteilt die verbundenen Spieler.\nGegnerische Teams beginnen auf unterschiedlichen Heimatwelten."
	_label(detail,_body)
	var button:=Button.new();button.custom_minimum_size.y=46
	button.text="Partie starten / fortsetzen" if campaign.lobby_open else "Lobby für Beitritte öffnen · Partie pausieren"
	button.disabled=not host
	button.pressed.connect(func():command_requested.emit({"type":"start_match" if campaign.lobby_open else "open_lobby"}))
	_body.add_child(button)
	_label("Verbindungen und Einladung: System → Koop-Verbindung",_body)
