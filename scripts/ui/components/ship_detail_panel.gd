extends VBoxContainer
## Wiederverwendbarer Baustein: das gewaehlte Schiff mit Bild, Pilot-/Turmschuetzenplatz, Passagierplaetzen und Fracht.
## Der Pilot-Auswahlkasten wird vom Aufrufer in `pilot_host` gehaengt (Befehl `pilot` bleibt beim Aufrufer).
## Leere Plaetze sind grau schraffiert (Ablegefelder), belegte zeigen den Namen. Befehle sendet der Aufrufer ueber die Signale.
const INVENTORY_PANEL: GDScript = preload("res://scripts/ui/components/personnel_inventory_panel.gd")
const DRAG_SURFACE: GDScript = preload("res://scripts/meta/operations_drag_surface.gd")
const CYAN := Color("6fe3e8")
const CREAM := Color("f2ead0")
const MUTED := Color("93aab3")
const GOLD := Color("f2c94c")
## Platzaufteilung je Schiffsmodell: Turmschuetzenplaetze. Alle anderen Modelle: keiner. Passagiere = Kapazitaet - Pilot - Turmschuetze.
const GUNNER_SEATS := {"cutlass": 1}
const MAX_PASSENGERS := 12
signal pilot_dropped(unit_id: String)
signal fireteam_dropped(fireteam_id: String)
signal pilot_cleared
signal unboard_requested(fireteam_id: String)
var pilot_validator: Callable = Callable()
## Callable(fireteam_id) -> String: leer = Trupp passt, sonst die Ablehnungsmeldung.
var fireteam_check: Callable = Callable()
var pilot_host: VBoxContainer
var _preview: TextureRect
var _name: Label
var _status: Label
var _pilot_slot: Label
var _pilot_hatch: Control
var _pilot_clear: Button
var _pilot_box: PanelContainer
var _troops: GridContainer
var _gunner_box: PanelContainer
var _message: Label
var _cargo_title: Label
var _cargo: Label
var _labels: Dictionary = {}
var _signature: String = ""
var _passenger_slots: int = 0
var _craft_name: String = ""

## Sitzaufteilung aus dem Schnappschuss-Eintrag eines Schiffs: {gunner, passengers}.
static func seat_layout(craft: Dictionary) -> Dictionary:
	var capacity: int = maxi(int(craft.get("crew_capacity", 0)) - 1, 0)
	var gunner: int = mini(int(GUNNER_SEATS.get(String(craft.get("model_id", "")), 0)), capacity)
	return {"gunner": gunner, "passengers": clampi(capacity - gunner, 0, MAX_PASSENGERS)}

func _init() -> void:
	name = "ShipDetail"
	add_theme_constant_override("separation", 8)
	_labels = INVENTORY_PANEL.get_script_constant_map().get("LABELS", {})
	_preview = TextureRect.new()
	_preview.name = "CraftPreview"
	_preview.custom_minimum_size = Vector2(0, 150)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_preview)
	_name = _label("Kein Schiff", 22, CREAM)
	_name.name = "CraftName"
	add_child(_name)
	_status = _label("", 15, GOLD)
	_status.name = "CraftStatus"
	add_child(_status)
	# Ein auf das Schiffsdetail gezogener Trupp geht wie bei der Schiffskarte an Bord.
	set_drag_forwarding(Callable(), _can_drop_fireteam, _drop_fireteam)
	var row := HBoxContainer.new()
	row.name = "SeatRow"
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	_pilot_box = DRAG_SURFACE.new()
	_pilot_box.name = "PilotSlot"
	_pilot_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pilot_box.set("accepted_type", "homebase_unit_card")
	_pilot_box.set("drop_validator", func(payload: Dictionary) -> bool: return pilot_validator.is_valid() and bool(pilot_validator.call(String(payload.get("unit_id", "")))))
	_pilot_box.connect("payload_dropped", func(payload: Dictionary): pilot_dropped.emit(String(payload.get("unit_id", ""))))
	_pilot_box.tooltip_text = "Person hierher ziehen: wird Pilot dieses Schiffs"
	row.add_child(_pilot_box)
	_pilot_hatch = Hatch.new()
	_pilot_box.add_child(_pilot_hatch)
	var pilot_inner := VBoxContainer.new()
	pilot_inner.add_theme_constant_override("separation", 2)
	_pilot_box.add_child(pilot_inner)
	var pilot_line := HBoxContainer.new()
	pilot_inner.add_child(pilot_line)
	_pilot_slot = _label("Pilot", 15, MUTED)
	_pilot_slot.name = "PilotName"
	_pilot_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pilot_line.add_child(_pilot_slot)
	_pilot_clear = _clear_button("PilotClear", "Pilot entfernen")
	_pilot_clear.pressed.connect(func(): pilot_cleared.emit())
	pilot_line.add_child(_pilot_clear)
	pilot_host = VBoxContainer.new()
	pilot_host.name = "PilotHost"
	pilot_inner.add_child(pilot_host)
	_gunner_box = DRAG_SURFACE.new()
	_gunner_box.name = "GunnerSlot"
	_gunner_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gunner_box.tooltip_text = "Turmschütze – noch nicht besetzbar"
	_gunner_box.add_theme_stylebox_override("panel", _box(Color("0b1a21"), Color("28404a")))
	_gunner_box.add_child(Hatch.new())
	var gunner_label := _label("Turmschütze", 15, Color("5f7680"))
	gunner_label.name = "GunnerName"
	_gunner_box.add_child(gunner_label)
	row.add_child(_gunner_box)
	add_child(_label("Passagierplätze", 14, MUTED))
	_troops = GridContainer.new()
	_troops.name = "TroopSlots"
	_troops.columns = 2
	_troops.add_theme_constant_override("h_separation", 6)
	_troops.add_theme_constant_override("v_separation", 4)
	add_child(_troops)
	_message = _label("", 14, GOLD)
	_message.name = "SeatMessage"
	_message.visible = false
	add_child(_message)
	_cargo_title = _label("Fracht", 14, MUTED)
	add_child(_cargo_title)
	var cargo_box := PanelContainer.new()
	cargo_box.name = "Cargo"
	cargo_box.add_theme_stylebox_override("panel", _box(Color("102f3b"), Color("3e6972")))
	add_child(cargo_box)
	_cargo = _label("Leer", 14, CREAM)
	cargo_box.add_child(_cargo)

func show_message(text: String) -> void:
	_message.text = text
	_message.visible = not text.is_empty()

## craft: Eintrag aus dem Operations-Schnappschuss (optional `seat_team_ids`: Trupp je belegtem Platz);
## cargo: Behaelter `craft:<id>` ({items:{id:n}, capacity}) oder leer.
func update_craft(craft: Dictionary, cargo: Dictionary) -> void:
	var path: String = String(craft.get("texture_path", ""))
	if String(_preview.get_meta("rendered_path", "__unset")) != path:
		_preview.texture = load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
		_preview.set_meta("rendered_path", path)
	_name.text = String(craft.get("name", "Kein Schiff"))
	if _name.text != _craft_name:
		_craft_name = _name.text
		show_message("")
	_status.text = String(craft.get("status", ""))
	var pilot: String = String(craft.get("pilot_name", ""))
	_pilot_slot.text = pilot if not pilot.is_empty() else "Pilot"
	_pilot_slot.add_theme_color_override("font_color", CREAM if not pilot.is_empty() else MUTED)
	_pilot_hatch.visible = pilot.is_empty()
	_pilot_clear.visible = not pilot.is_empty() and not bool(craft.get("busy", false))
	_pilot_box.add_theme_stylebox_override("panel", _box(Color("163743"), CYAN) if not pilot.is_empty() else _box(Color("0f2630"), Color("3e6972")))
	var layout: Dictionary = seat_layout(craft)
	_gunner_box.visible = int(layout.gunner) > 0
	var slots: int = int(layout.passengers)
	_passenger_slots = slots
	var names: Array = Array(craft.get("payload_names", []))
	var teams: Array = Array(craft.get("seat_team_ids", []))
	var signature: String = "%d|%s|%s" % [slots, JSON.stringify(names), JSON.stringify(teams)]
	if signature != _signature:
		_signature = signature
		for child in _troops.get_children():
			_troops.remove_child(child)
			child.queue_free()
		if slots == 0:
			var note := _label("Keine Passagierplätze", 14, MUTED)
			note.name = "TroopNote"
			_troops.add_child(note)
		for index in slots:
			_troops.add_child(_passenger_slot(index, String(names[index]) if index < names.size() else "", String(teams[index]) if index < teams.size() else ""))
	var items: Dictionary = Dictionary(cargo.get("items", {}))
	var lines: PackedStringArray = PackedStringArray()
	for item in items:
		lines.append("%s × %d" % [String(_labels.get(item, String(item).replace("_", " "))), int(items[item])])
	_cargo.text = "\n".join(lines) if not lines.is_empty() else "Leer"

func _passenger_slot(index: int, occupant: String, team_id: String) -> PanelContainer:
	var slot: PanelContainer = DRAG_SURFACE.new()
	slot.name = "TroopSlot_%d" % index
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.set("accepted_type", "fob_fireteam_card")
	slot.set("accept_any", true)
	slot.set("drop_validator", func(payload: Dictionary) -> bool: return _passenger_payload_ok(payload))
	slot.connect("payload_dropped", func(payload: Dictionary): _handle_drop(payload))
	var filled: bool = not occupant.is_empty()
	slot.tooltip_text = ("Besetzt: " + occupant) if filled else "Frei: Trupp (oder Person, dann mit Hinweis) hierher ziehen"
	slot.add_theme_stylebox_override("panel", _box(Color("163743"), CYAN) if filled else _box(Color("0f2630"), Color("3e6972")))
	var hatch := Hatch.new()
	hatch.visible = not filled
	slot.add_child(hatch)
	var line := HBoxContainer.new()
	slot.add_child(line)
	var text := _label(occupant if filled else "Passagier", 15, CREAM if filled else MUTED)
	text.name = "SeatName"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(text)
	if filled and not team_id.is_empty():
		var clear := _clear_button("SeatClear_%d" % index, "Ganzen Trupp absetzen")
		clear.visible = true
		clear.pressed.connect(func(): unboard_requested.emit(team_id))
		line.add_child(clear)
	return slot

func _passenger_payload_ok(payload: Dictionary) -> bool:
	match String(payload.get("type", "")):
		"fob_fireteam_card": return not String(payload.get("fireteam_id", "")).strip_edges().is_empty()
		"homebase_unit_card": return not String(payload.get("unit_id", "")).strip_edges().is_empty()
	return false

## Angenommenes Ablegen: passt es nicht, wird es mit sichtbarer Meldung verworfen; sonst geht der Befehl hinaus.
func _handle_drop(payload: Dictionary) -> void:
	if String(payload.get("type", "")) == "homebase_unit_card":
		show_message("Einzelpersonen bitte als Trupp einsteigen lassen.")
		return
	var id: String = String(payload.get("fireteam_id", "")).strip_edges()
	var problem: String = String(fireteam_check.call(id)) if fireteam_check.is_valid() else "Boarding gerade nicht verfügbar."
	if not problem.is_empty():
		show_message(problem)
		return
	show_message("")
	fireteam_dropped.emit(id)

func _can_drop_fireteam(_at: Vector2, data: Variant) -> bool:
	return _passenger_slots > 0 and typeof(data) == TYPE_DICTIONARY and _passenger_payload_ok(Dictionary(data))

func _drop_fireteam(at: Vector2, data: Variant) -> void:
	if _can_drop_fireteam(at, data):
		_handle_drop(Dictionary(data))

func _clear_button(node_name: String, tip: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = "✕"
	button.flat = true
	button.tooltip_text = tip
	button.custom_minimum_size = Vector2(28, 28)
	button.visible = false
	return button

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _box(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

## Dezente graue Schraffur fuer leere Ablegefelder (diagonale Linien, keine Bilddatei).
class Hatch extends Control:
	func _init() -> void:
		name = "Hatch"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true
	func _draw() -> void:
		var height: float = size.y
		var x: float = -height
		while x < size.x:
			draw_line(Vector2(x, height), Vector2(x + height, 0.0), Color(0.62, 0.7, 0.74, 0.16), 1.0)
			x += 8.0
