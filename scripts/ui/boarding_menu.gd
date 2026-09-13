extends PopupMenu
## Explicit seat requests. Reservation and walking happen only in the core.
signal command_requested(command: Dictionary)
signal action_requested(action: String, payload: Dictionary)
const ROLE_NAMES := {"pilot":"Pilot", "gunner":"Turmschütze", "passenger":"Passagier"}
var _requests: Dictionary = {}

func _ready() -> void:
	id_pressed.connect(_choose)

func open_for(state: Dictionary, ids: Array[String], screen: Vector2) -> void:
	clear()
	_requests.clear()
	var ship: Dictionary = state.get("ship",{})
	var seats: Dictionary = ship.get("seats",{})
	var index := 0
	add_separator("BESATZUNG / " + str(ship.get("name","Entersäbel")))
	for id in ids:
		var unit: Dictionary = state.get("crew",{}).get(id,{})
		if unit.is_empty(): continue
		var name: String = str(unit.get("name",id))
		var task: String = str(unit.get("assignment","idle"))
		if task=="aboard":
			add_item(name+" · Aussteigen",index)
			set_item_disabled(get_item_count()-1,str(ship.get("mode","landed"))!="landed")
			_requests[index]={"type":"disembark","unit_id":id};index+=1
		elif task=="boarding":
			add_item(name+" · Einsteigen abbrechen",index)
			_requests[index]={"type":"cancel_board","unit_id":id};index+=1
		else:
			for role: String in ROLE_NAMES:
				var occupied := not str(seats.get(role,"")).is_empty() if role!="passenger" else not str(seats.get("passenger_1","")).is_empty() and not str(seats.get("passenger_2","")).is_empty()
				var disabled := occupied or task!="idle" or str(ship.get("mode","landed"))!="landed" or float(unit.get("health",100))<=0
				if role=="gunner" and str(ship.get("model",""))=="vulture": disabled=true
				add_item(name+" · Als "+str(ROLE_NAMES[role])+" einsteigen"+(" (belegt)" if occupied else ""),index)
				set_item_disabled(get_item_count()-1,disabled)
				_requests[index]={"type":"board","unit_id":id,"role":role};index+=1
		add_separator()
	if not ids.is_empty():
		add_item("Einsteigen · Plätze nach Fähigkeiten",index)
		_requests[index]={"type":"board_selected","ids":ids.duplicate()};index+=1
	add_item("Besatzung und Schiff anzeigen",index)
	_requests[index]={"type":"inspect_object","object_id":"shuttle"}
	var viewport: Viewport=get_parent().get_viewport()
	position=Vector2i(screen if is_embedded() else viewport.get_screen_transform()*screen)
	popup()

func _choose(id: int) -> void:
	if not _requests.has(id): return
	var request: Dictionary = _requests[id].duplicate(true)
	var type: String = request.type
	if type in ["board_selected","inspect_object"]:
		request.erase("type")
		action_requested.emit(type,request)
	else: command_requested.emit(request)
