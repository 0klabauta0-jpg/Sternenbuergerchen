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
const PORTRAITS: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
## Feste Farbpalette fuer den Trupp-Streifen am rechten Rand der Passagierplaetze (je Trupp eine Farbe).
const TEAM_COLORS: Array[Color] = [Color("e8a33d"), Color("5fb0e8"), Color("c07ee8"), Color("7ee89a"), Color("e86f6f"), Color("e8e06f")]
## Platzaufteilung je Schiffsmodell: Turmschuetzenplaetze. Alle anderen Modelle: keiner. Passagiere = Kapazitaet - Pilot - Turmschuetze.
const GUNNER_SEATS := {"cutlass": 1}
const MAX_PASSENGERS := 12
signal pilot_dropped(unit_id: String)
signal fireteam_dropped(fireteam_id: String)
signal pilot_cleared
signal unboard_requested(fireteam_id: String)
## Einzelperson auf einen Platz gezogen: seat = "passenger" oder "gunner". Der Aufrufer entscheidet und meldet Ablehnungen ueber show_message.
signal person_dropped(unit_id: String, seat: String)
var pilot_validator: Callable = Callable()
## Callable(fireteam_id) -> String: leer = Trupp passt, sonst die Ablehnungsmeldung.
var fireteam_check: Callable = Callable()
var pilot_host: VBoxContainer
var _preview: TextureRect
var _name: Label
var _status: Label
var _pilot_slot: Label
var _pilot_card: Pulse
var _pilot_portrait: TextureRect
var _pilot_info: Label
var _pilot_hatch: Control
var _pilot_clear: Button
var _pilot_box: PanelContainer
var _troops: GridContainer
var _gunner_box: PanelContainer
var _gunner_label: Label
var _gunner_hatch: Control
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
	_pilot_box.set("drop_validator", func(payload: Dictionary) -> bool: return _pilot_payload_ok(payload))
	_pilot_box.connect("payload_dropped", func(payload: Dictionary): _handle_pilot_drop(payload))
	_pilot_box.tooltip_text = "Person hierher ziehen: wird Pilot dieses Schiffs"
	row.add_child(_pilot_box)
	_pilot_hatch = Hatch.new()
	_pilot_box.add_child(_pilot_hatch)
	var pilot_inner := VBoxContainer.new()
	pilot_inner.add_theme_constant_override("separation", 2)
	_pilot_box.add_child(pilot_inner)
	var pilot_line := HBoxContainer.new()
	pilot_inner.add_child(pilot_line)
	# Pilotkarte wie die Minikarte unter Personal: Portraet, Name, Rolle/Status. Pulsiert, solange der Pilot nicht an Bord ist.
	_pilot_card = Pulse.new()
	_pilot_card.name = "PilotCard"
	_pilot_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pilot_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pilot_card.add_theme_constant_override("separation", 8)
	pilot_line.add_child(_pilot_card)
	_pilot_portrait = _portrait(Vector2(40, 40))
	_pilot_portrait.name = "PilotPortrait"
	_pilot_portrait.visible = false
	_pilot_card.add_child(_pilot_portrait)
	var pilot_text := VBoxContainer.new()
	pilot_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pilot_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pilot_text.add_theme_constant_override("separation", 0)
	_pilot_card.add_child(pilot_text)
	_pilot_slot = _label("Pilot", 15, MUTED)
	_pilot_slot.name = "PilotName"
	_pilot_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pilot_text.add_child(_pilot_slot)
	_pilot_info = _compact_label("", 12, CYAN)
	_pilot_info.name = "PilotInfo"
	_pilot_info.visible = false
	pilot_text.add_child(_pilot_info)
	_pilot_clear = _clear_button("PilotClear", "Pilot entfernen")
	_pilot_clear.pressed.connect(func(): pilot_cleared.emit())
	pilot_line.add_child(_pilot_clear)
	pilot_host = VBoxContainer.new()
	pilot_host.name = "PilotHost"
	pilot_inner.add_child(pilot_host)
	_gunner_box = DRAG_SURFACE.new()
	_gunner_box.name = "GunnerSlot"
	_gunner_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Turmschuetzenplatz: belegbar (Person sitzt dort und zaehlt als an Bord); eine Schusslogik gibt es dazu noch nicht.
	_gunner_box.set("accepted_type", "homebase_unit_card")
	_gunner_box.set("drop_validator", func(payload: Dictionary) -> bool: return _person_payload_ok(payload))
	_gunner_box.connect("payload_dropped", func(payload: Dictionary): _handle_person_drop(payload, "gunner"))
	_gunner_box.tooltip_text = "Person hierher ziehen: sitzt als Turmschütze (noch ohne Schusslogik)"
	_gunner_box.add_theme_stylebox_override("panel", _box(Color("0f2630"), Color("3e6972")))
	_gunner_hatch = Hatch.new()
	_gunner_box.add_child(_gunner_hatch)
	_gunner_label = _label("Turmschütze", 15, MUTED)
	_gunner_label.name = "GunnerName"
	_gunner_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gunner_box.add_child(_gunner_label)
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
	var pilot_unit: Dictionary = Dictionary(craft.get("pilot_unit", {}))
	_pilot_portrait.visible = not pilot.is_empty() and not pilot_unit.is_empty()
	_set_portrait(_pilot_portrait, pilot_unit)
	var pilot_info: String = _info_line(pilot_unit)
	_pilot_info.text = pilot_info
	_pilot_info.visible = not pilot.is_empty() and not pilot_info.is_empty()
	# Zugewiesen, aber noch nicht an Bord: gedimmt und pulsierend; sonst Vollfarbe.
	_pilot_card.waiting = not pilot.is_empty() and not bool(craft.get("pilot_aboard", true))
	var layout: Dictionary = seat_layout(craft)
	_gunner_box.visible = int(layout.gunner) > 0
	_update_gunner(craft)
	var slots: int = int(layout.passengers)
	_passenger_slots = slots
	# Pilot und Turmschuetze stehen nur auf ihrem eigenen Platz, nie zusaetzlich auf einem Passagierplatz (auch wenn sie zum Trupp an Bord gehoeren).
	var seats: Array = _seat_entries(craft, String(craft.get("pilot_id", "")), String(craft.get("gunner_id", "")))
	var signature: String = "%d|%s" % [slots, JSON.stringify(seats)]
	if signature != _signature:
		_signature = signature
		for child in _troops.get_children():
			_troops.remove_child(child)
			child.queue_free()
		if slots == 0:
			var note := _label("Keine Passagierplätze", 14, MUTED)
			note.name = "TroopNote"
			note.autowrap_mode = TextServer.AUTOWRAP_OFF
			note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_troops.add_child(note)
		var team_order: Array = []
		for seat in seats:
			var seat_team: String = String(Dictionary(seat).team)
			if not seat_team.is_empty() and not team_order.has(seat_team):
				team_order.append(seat_team)
		for index in slots:
			var entry: Dictionary = Dictionary(seats[index]) if index < seats.size() else {}
			var color_index: int = team_order.find(String(entry.get("team", ""))) if not entry.is_empty() else -1
			_troops.add_child(_passenger_slot(index, entry, TEAM_COLORS[color_index % TEAM_COLORS.size()] if color_index >= 0 else Color(0, 0, 0, 0)))
	var items: Dictionary = Dictionary(cargo.get("items", {}))
	var lines: PackedStringArray = PackedStringArray()
	for item in items:
		lines.append("%s × %d" % [String(_labels.get(item, String(item).replace("_", " "))), int(items[item])])
	_cargo.text = "\n".join(lines) if not lines.is_empty() else "Leer"

## Parallele Listen des Schnappschusses zu Plaetzen zusammengefuehrt: {id, name, team, unit, aboard}.
## Eintraege der Pilotperson entfallen (sie steht nur im Pilotplatz); ohne `payload_unit_ids` ist kein Abgleich moeglich.
func _seat_entries(craft: Dictionary, pilot_id: String, gunner_id: String = "") -> Array:
	var names: Array = Array(craft.get("payload_names", []))
	var ids: Array = Array(craft.get("payload_unit_ids", []))
	var teams: Array = Array(craft.get("seat_team_ids", []))
	var units: Array = Array(craft.get("seat_units", []))
	var aboard: Array = Array(craft.get("payload_aboard", []))
	var entries: Array = []
	for index in names.size():
		var id: String = String(ids[index]) if index < ids.size() else ""
		if (not pilot_id.is_empty() and id == pilot_id) or (not gunner_id.is_empty() and id == gunner_id):
			continue
		entries.append({"id": id, "name": String(names[index]), "team": String(teams[index]) if index < teams.size() else "",
			"unit": Dictionary(units[index]) if index < units.size() and typeof(units[index]) == TYPE_DICTIONARY else {},
			"aboard": bool(aboard[index]) if index < aboard.size() else true})
	return entries

func _passenger_slot(index: int, entry: Dictionary, team_color: Color) -> PanelContainer:
	var slot: PanelContainer = DRAG_SURFACE.new()
	slot.name = "TroopSlot_%d" % index
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.set("accepted_type", "fob_fireteam_card")
	slot.set("accept_any", true)
	slot.set("drop_validator", func(payload: Dictionary) -> bool: return _passenger_payload_ok(payload))
	slot.connect("payload_dropped", func(payload: Dictionary): _handle_drop(payload))
	var occupant: String = String(entry.get("name", ""))
	var unit_id: String = String(entry.get("id", ""))
	var team_id: String = String(entry.get("team", ""))
	var unit: Dictionary = Dictionary(entry.get("unit", {}))
	var filled: bool = not occupant.is_empty()
	slot.tooltip_text = ("Besetzt: %s · auf den Pilotplatz ziehen, um Pilot zu werden" % occupant) if filled else "Frei: ganzen Trupp oder eine einzelne Person hierher ziehen"
	slot.add_theme_stylebox_override("panel", _box(Color("163743"), CYAN) if filled else _box(Color("0f2630"), Color("3e6972")))
	if filled and not unit_id.is_empty():
		# Belegter Platz ist ziehbar wie eine Person in der Personal-Spalte (z. B. auf den Pilotplatz).
		slot.set("drag_payload", {"type": "homebase_unit_card", "unit_id": unit_id, "label": occupant, "source_context": "seat"})
	var hatch := Hatch.new()
	hatch.visible = not filled
	slot.add_child(hatch)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 4)
	slot.add_child(line)
	var card := Pulse.new()
	card.name = "SeatCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_constant_override("separation", 6)
	line.add_child(card)
	if filled and not unit.is_empty():
		var portrait: TextureRect = _portrait(Vector2(32, 32))
		portrait.name = "SeatPortrait"
		_set_portrait(portrait, unit)
		card.add_child(portrait)
	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 0)
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(text_box)
	var text := _compact_label(occupant if filled else "Passagier", 14, CREAM if filled else MUTED)
	text.name = "SeatName"
	text_box.add_child(text)
	var status_text: String = String(unit.get("status", ""))
	if filled and not unit.is_empty() and status_text.is_empty():
		status_text = "An Bord" if bool(entry.aboard) else "Nicht an Bord"
	if filled and not status_text.is_empty():
		var status := _compact_label(status_text, 11, CYAN)
		status.name = "SeatStatus"
		text_box.add_child(status)
	card.waiting = filled and not bool(entry.get("aboard", true))
	if filled and not team_id.is_empty():
		var clear := _clear_button("SeatClear_%d" % index, "Ganzen Trupp absetzen")
		clear.visible = true
		clear.pressed.connect(func(): unboard_requested.emit(team_id))
		line.add_child(clear)
	if filled and team_color.a > 0.0:
		var stripe := ColorRect.new()
		stripe.name = "TeamStripe"
		stripe.color = team_color
		stripe.custom_minimum_size = Vector2(5, 0)
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stripe.tooltip_text = "Gleicher Streifen = gleicher Trupp"
		slot.set_meta("team_id", team_id)
		slot.set_meta("team_color", team_color)
		line.add_child(stripe)
	return slot

## Pilotplatz: Personen aus dem Auswahlkasten (`pilot_validator`) oder von einem Passagierplatz (wird bei Nichteignung gemeldet statt still verworfen).
func _pilot_payload_ok(payload: Dictionary) -> bool:
	var id: String = String(payload.get("unit_id", "")).strip_edges()
	if id.is_empty():
		return false
	if String(payload.get("source_context", "")) == "seat":
		return true
	return pilot_validator.is_valid() and bool(pilot_validator.call(id))

func _handle_pilot_drop(payload: Dictionary) -> void:
	var id: String = String(payload.get("unit_id", "")).strip_edges()
	if id.is_empty():
		return
	if pilot_validator.is_valid() and bool(pilot_validator.call(id)):
		show_message("")
		pilot_dropped.emit(id)
		return
	var who: String = String(payload.get("label", "")).strip_edges()
	show_message("%s kann nicht Pilot werden." % (who if not who.is_empty() else "Diese Person"))

func _info_line(unit: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for key in ["role", "status"]:
		var value: String = String(unit.get(key, ""))
		if not value.is_empty():
			parts.append(value)
	return " · ".join(parts)

func _set_portrait(rect: TextureRect, unit: Dictionary) -> void:
	var path: String = PORTRAITS.resolve_path(String(unit.get("portrait_id", "")), String(unit.get("portrait_path", ""))) if not unit.is_empty() else ""
	if String(rect.get_meta("rendered_path", "__unset")) == path:
		return
	rect.texture = load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	rect.set_meta("rendered_path", path)

func _portrait(minimum: Vector2) -> TextureRect:
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = minimum
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return portrait

## Einzeilige, abgeschnittene Beschriftung (kein Umbruch, zwingt die Spalte nicht auf).
func _compact_label(value: String, size: int, color: Color) -> Label:
	var label := _label(value, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size.x = 0
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _passenger_payload_ok(payload: Dictionary) -> bool:
	match String(payload.get("type", "")):
		"fob_fireteam_card": return not String(payload.get("fireteam_id", "")).strip_edges().is_empty()
		"homebase_unit_card": return not String(payload.get("unit_id", "")).strip_edges().is_empty()
	return false

## Angenommenes Ablegen: passt es nicht, wird es mit sichtbarer Meldung verworfen; sonst geht der Befehl hinaus.
func _handle_drop(payload: Dictionary) -> void:
	if String(payload.get("type", "")) == "homebase_unit_card":
		_handle_person_drop(payload, "passenger")
		return
	var id: String = String(payload.get("fireteam_id", "")).strip_edges()
	var problem: String = String(fireteam_check.call(id)) if fireteam_check.is_valid() else "Einsteigen ist gerade nicht möglich."
	if not problem.is_empty():
		show_message(problem)
		return
	show_message("")
	fireteam_dropped.emit(id)

func _person_payload_ok(payload: Dictionary) -> bool:
	return not String(payload.get("unit_id", "")).strip_edges().is_empty()

## Einzelperson auf Passagier- oder Turmschuetzenplatz: der Befehl geht an den Aufrufer, der Ablehnungen ueber show_message meldet.
func _handle_person_drop(payload: Dictionary, seat: String) -> void:
	var id: String = String(payload.get("unit_id", "")).strip_edges()
	if id.is_empty():
		return
	show_message("")
	person_dropped.emit(id, seat)

## Turmschuetzenplatz: Name der besetzenden Person (Schnappschuss `gunner_id` in `payload_unit_ids`), sonst grau schraffiert.
func _update_gunner(craft: Dictionary) -> void:
	var gunner_id: String = String(craft.get("gunner_id", ""))
	var ids: Array = Array(craft.get("payload_unit_ids", []))
	var names: Array = Array(craft.get("payload_names", []))
	var index: int = ids.find(gunner_id) if not gunner_id.is_empty() else -1
	var occupant: String = String(names[index]) if index >= 0 and index < names.size() else ""
	var filled: bool = not occupant.is_empty()
	_gunner_label.text = occupant if filled else "Turmschütze"
	_gunner_label.add_theme_color_override("font_color", CREAM if filled else MUTED)
	_gunner_hatch.visible = not filled
	_gunner_box.add_theme_stylebox_override("panel", _box(Color("163743"), CYAN) if filled else _box(Color("0f2630"), Color("3e6972")))
	var aboard: Array = Array(craft.get("payload_aboard", []))
	var is_aboard: bool = bool(aboard[index]) if index >= 0 and index < aboard.size() else true
	_gunner_box.tooltip_text = ("Turmschütze: %s · %s · auf einen Passagierplatz ziehen, um ihn dorthin zu setzen (noch ohne Schusslogik)" % [occupant, "an Bord" if is_aboard else "geht gerade an Bord"]) if filled else "Person hierher ziehen: sitzt als Turmschütze (noch ohne Schusslogik)"
	# Belegter Platz ist ziehbar wie ein Passagierplatz (z. B. auf den Pilotplatz).
	_gunner_box.set("drag_payload", {"type": "homebase_unit_card", "unit_id": gunner_id, "label": occupant, "source_context": "seat"} if filled else {})

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

## Karteninhalt eines Platzes. `waiting` = zugewiesen, aber noch nicht an Bord: ausgegraut und sanft pulsierend
## (Deckkraft WAIT_ALPHA_LOW <-> WAIT_ALPHA_HIGH, rund 1 s je Zyklus). Sonst Vollfarbe ohne Blinken.
class Pulse extends HBoxContainer:
	const LOW := 0.35
	const HIGH := 0.7
	var waiting: bool = false:
		set(value):
			var changed: bool = value != waiting
			waiting = value
			set_meta("waiting", value)
			if changed or (value and _tween == null and is_inside_tree()):
				_apply()
	var _tween: Tween
	func _enter_tree() -> void:
		_apply()
	func _exit_tree() -> void:
		_stop()
	func _stop() -> void:
		if _tween != null:
			_tween.kill()
			_tween = null
	func _apply() -> void:
		_stop()
		if not waiting:
			modulate.a = 1.0
			return
		modulate.a = LOW
		if is_inside_tree():
			_tween = create_tween().set_loops()
			_tween.tween_property(self, "modulate:a", HIGH, 0.5).set_trans(Tween.TRANS_SINE)
			_tween.tween_property(self, "modulate:a", LOW, 0.5).set_trans(Tween.TRANS_SINE)

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
