extends VBoxContainer
## Presentation only: the supply and base owners validate and perform construction.

var _command: Callable
var _type: OptionButton
var _x: SpinBox
var _y: SpinBox
var _rotation: OptionButton
var _room: OptionButton
var _slot: OptionButton
var _door_room: OptionButton
var _door_side: OptionButton
var _door_state: Label
var _status: Label
var _summary: Label
var _rooms_signature := ""
var _sequence := 0
var _snapshot: Dictionary = {}

func configure(command: Callable) -> void:
	_command = command

func _ready() -> void:
	name = "ModularBaseBuilder"
	var title := Label.new()
	title.text = "Räume und Gänge"
	title.add_theme_font_size_override("font_size", 20)
	add_child(title)
	var description := Label.new()
	description.text = "Erster Raum bei 0 / 0; weitere Räume direkt daneben. Ein Gang verbindet Räume. Lager: +100 Plätze."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description)
	_summary = Label.new(); _summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; add_child(_summary)
	_type = OptionButton.new()
	for option in [["Schlafraum · 300 Cr", "sleep"], ["Lagerraum · 300 Cr", "storage"], ["Gang · 100 Cr", "corridor"]]:
		_type.add_item(option[0]); _type.set_item_metadata(_type.item_count - 1, option[1])
	add_child(_type)
	var position_row := HBoxContainer.new()
	add_child(position_row)
	for axis in ["X", "Y"]:
		var axis_label := Label.new(); axis_label.text = axis; position_row.add_child(axis_label)
		var control := SpinBox.new(); control.min_value = -8; control.max_value = 8; control.step = 1; control.custom_minimum_size.x = 90; position_row.add_child(control)
		if axis == "X": _x = control
		else: _y = control
	_rotation = OptionButton.new()
	for angle in [0, 90, 180, 270]: _rotation.add_item("Drehung %d°" % angle)
	add_child(_rotation)
	var build := Button.new(); build.name = "BuildModularRoom"; build.text = "Raum oder Gang bauen"; add_child(build)
	build.pressed.connect(_build_room)
	var separator := HSeparator.new(); add_child(separator)
	var bed_title := Label.new(); bed_title.text = "Bett im Schlafraum · 100 Cr"; add_child(bed_title)
	_room = OptionButton.new(); _room.name = "ModularSleepRoom"; add_child(_room)
	_slot = OptionButton.new(); _slot.add_item("Bettplatz 1"); _slot.add_item("Bettplatz 2"); add_child(_slot)
	var bed := Button.new(); bed.name = "BuildRoomBed"; bed.text = "Bett aufstellen"; add_child(bed)
	bed.pressed.connect(_build_bed)
	add_child(HSeparator.new())
	var door_title := Label.new(); door_title.text = "Türen anpassen"; add_child(door_title)
	_door_room = OptionButton.new(); _door_room.name = "DoorRoom"; add_child(_door_room)
	_door_side = OptionButton.new()
	for side in ["Nordseite", "Ostseite", "Südseite", "Westseite"]: _door_side.add_item(side)
	_door_side.tooltip_text = "Die Seiten beziehen sich auf den Raum vor seiner Drehung."
	add_child(_door_side)
	_door_state = Label.new(); add_child(_door_state)
	_door_room.item_selected.connect(func(_index: int): _refresh_door_state())
	_door_side.item_selected.connect(func(_index: int): _refresh_door_state())
	var door_row := HBoxContainer.new(); add_child(door_row)
	var open_door := Button.new(); open_door.name = "OpenRoomDoor"; open_door.text = "Tür einbauen"; door_row.add_child(open_door)
	var close_door := Button.new(); close_door.name = "CloseRoomDoor"; close_door.text = "Tür ausbauen"; door_row.add_child(close_door)
	open_door.pressed.connect(func(): _set_door(true))
	close_door.pressed.connect(func(): _set_door(false))
	_status = Label.new(); _status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; add_child(_status)

func refresh(snapshot: Dictionary) -> void:
	_snapshot = snapshot
	if not is_node_ready(): return
	var modular: Dictionary = snapshot.get("supply", {}).get("modular_base", {})
	var rooms: Array = modular.get("rooms", [])
	var base_inventory: Dictionary = snapshot.get("supply", {}).get("inventory", {}).get("base:homebase", {})
	_summary.text = "Module: %d · Einzelbetten: %d · Lagerplätze: %d" % [rooms.size(), Array(modular.get("beds", [])).size(), int(base_inventory.get("capacity", 0))]
	var signature := JSON.stringify(rooms)
	if signature != _rooms_signature:
		var previous := String(_room.get_selected_metadata()) if _room.selected >= 0 else ""
		var previous_door := String(_door_room.get_selected_metadata()) if _door_room.selected >= 0 else ""
		_room.clear(); _room.add_item("Schlafraum auswählen"); _room.set_item_metadata(0, "")
		_door_room.clear(); _door_room.add_item("Raum auswählen"); _door_room.set_item_metadata(0, "")
		for room: Dictionary in rooms:
			_door_room.add_item("%s · %d / %d" % [String(room.get("id", "")), int(room.get("x", 0)), int(room.get("y", 0))])
			_door_room.set_item_metadata(_door_room.item_count - 1, String(room.get("id", "")))
			if String(room.get("id", "")) == previous_door: _door_room.select(_door_room.item_count - 1)
			if String(room.get("type", "")) != "sleep": continue
			_room.add_item("%s · %d / %d" % [String(room.get("id", "")), int(room.get("x", 0)), int(room.get("y", 0))])
			_room.set_item_metadata(_room.item_count - 1, String(room.get("id", "")))
			if String(room.get("id", "")) == previous: _room.select(_room.item_count - 1)
		_rooms_signature = signature
	_refresh_door_state()

func _refresh_door_state() -> void:
	if _door_room == null or _door_side == null or _door_state == null: return
	var selected := String(_door_room.get_selected_metadata()) if _door_room.selected >= 0 else ""
	_door_state.text = "Raum und Seite wählen."
	for room: Dictionary in _snapshot.get("supply", {}).get("modular_base", {}).get("rooms", []):
		if String(room.get("id", "")) != selected: continue
		var doors: Array = room.get("doors", [true, true, true, true])
		if doors.size() == 4: _door_state.text = "Türöffnung vorhanden" if bool(doors[_door_side.selected]) else "Wand geschlossen"
		break

func _submit(operation: String, payload: Dictionary) -> void:
	if not _command.is_valid(): return
	_sequence += 1
	payload["request_id"] = "modular-base:%d:%d" % [get_instance_id(), _sequence]
	var result: Dictionary = _command.call(operation, payload)
	_status.text = String(result.get("message", result.get("reason", "Auftrag bestätigt")))

func _build_room() -> void:
	_submit("campaign_build_room", {"type": String(_type.get_selected_metadata()), "x": int(_x.value), "y": int(_y.value), "rotation": _rotation.selected})

func _build_bed() -> void:
	var room_id := String(_room.get_selected_metadata())
	if room_id.is_empty():
		_status.text = "Bitte zuerst einen Schlafraum auswählen."
		return
	_submit("campaign_place_room_bed", {"room_id": room_id, "slot": _slot.selected})

func _set_door(open: bool) -> void:
	var room_id := String(_door_room.get_selected_metadata())
	if room_id.is_empty():
		_status.text = "Bitte zuerst einen Raum auswählen."
		return
	_submit("campaign_set_room_door", {"room_id": room_id, "side": _door_side.selected, "open": open})
