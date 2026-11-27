extends VBoxContainer
## Selection and feedback only; membership belongs to the simulation owner.
## Schiffe sind Karten: Ziehen und Ablegen auf eine Schiffsgruppe ordnet zu, auf "Ohne Gruppe" nimmt aus der Gruppe,
## auf "Neue Schiffsgruppe" legt eine an. Alles laeuft ueber dieselben Befehle wie zuvor (wing_create, wing_assign, wing_remove ...).
signal wing_focus_requested(craft_id: String)
const NEW_WING := "<new>"
const FREE_SHIPS := ""
const DRAG_KIND := "space_craft"
const MAX_MEMBERS := 6
var _provider: Callable
var _commands: Callable
var _snapshot: Dictionary = {}
var _signature := ""
var _sequence := 0
var _session := ""
var _name_edit: LineEdit
var _feedback: Label
var _cards: VBoxContainer
var _free_cards: VBoxContainer
var _management: VBoxContainer
var _selected_wings: Dictionary = {}
var _selected_craft := ""
var _expanded_wings: Dictionary = {}
var _drag_start := Vector2.ZERO
var _drag_end := Vector2.ZERO
var _drag_wing := ""
var _drag_additive := false
var _drag_active := false
var _heading: Button
var _body: VBoxContainer
var _open_override = null
var _ship_count := 0

## Anzeige: Ein-Schiff-Gruppen heissen wie ihr Schiff, die technische Kennung ("solo:...") wird nie gezeigt.
func _wing_label(id, wing: Dictionary, names: Dictionary) -> String:
	var wing_name := String(wing.get("name", id))
	if not wing_name.begins_with("solo:"):
		return wing_name
	var craft_ids: Array = Array(wing.get("craft_ids", []))
	var craft_name := String(names.get(String(craft_ids[0]), "")) if not craft_ids.is_empty() else ""
	if craft_name.is_empty() or craft_name.begins_with("solo:"): return "Einzelschiff"
	return craft_name

func _craft_names() -> Dictionary:
	var names := {}
	for craft: Dictionary in Array(_snapshot.get("crafts", [])):
		names[String(craft.get("craft_id", ""))] = String(craft.get("display_name", craft.get("craft_id", "")))
	return names

func _wings_dict() -> Dictionary:
	return Dictionary(Dictionary(_snapshot.get("space_wings", {})).get("wings", {}))

func _wing_of(craft_id: String) -> String:
	var wings := _wings_dict()
	for id in wings:
		if craft_id in Array(Dictionary(wings[id]).get("craft_ids", [])): return String(id)
	return ""

## Mit mehreren Schiffen sind die Gruppen anfangs aufgeklappt (die Schiffskarten sind dann zu sehen); ein Klick auf den Reiter schaltet um.
func _is_expanded(id) -> bool:
	return bool(_expanded_wings.get(id, _ship_count > 1))

func _apply_open_state() -> void:
	if _body == null: return
	var open: bool = bool(_open_override) if _open_override != null else _ship_count > 1
	_body.visible = open
	_heading.text = "SCHIFFSGRUPPEN " + ("▾" if open else "▸")

func configure(snapshot_provider: Callable, command_handler: Callable) -> void:
	_provider = snapshot_provider
	_commands = command_handler
	_session = "%d-%d" % [get_instance_id(), Time.get_ticks_usec()]
	if _cards == null: _build()
	refresh(_read())

func _build() -> void:
	name = "SpaceWingPanel"
	# Ueberschrift ist zugleich der Knopf zum Ein- und Ausklappen; mit nur einem Schiff ist der Block anfangs eingeklappt.
	_heading = Button.new()
	_heading.name = "WingHeading"
	_heading.flat = true
	_heading.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_heading.pressed.connect(func():
		_open_override = not _body.visible
		_apply_open_state())
	add_child(_heading)
	_body = VBoxContainer.new()
	_body.name = "WingBody"
	add_child(_body)
	_cards = VBoxContainer.new()
	_cards.name = "WingCards"
	_body.add_child(_cards)
	# Ablageflaeche "Neue Schiffsgruppe": ein Schiff hierher ziehen legt eine eigene Gruppe an.
	var new_zone := _zone("WingNewZone", "＋ Neue Schiffsgruppe: Schiff hierher ziehen", NEW_WING)
	_body.add_child(new_zone)
	# Ablageflaeche "Ohne Gruppe": zeigt Schiffe ohne Gruppe; ein Schiff hierher ziehen nimmt es aus seiner Gruppe.
	var free_zone := _zone("WingFreeZone", "Ohne Gruppe (hierher ziehen: aus der Gruppe nehmen)", FREE_SHIPS)
	_body.add_child(free_zone)
	_free_cards = VBoxContainer.new()
	_free_cards.name = "WingFreeShips"
	free_zone.get_child(0).add_child(_free_cards)
	var manage := Button.new()
	manage.text = "Schiffsgruppen verwalten ▸"
	_body.add_child(manage)
	_management = VBoxContainer.new()
	_management.name = "WingManagement"
	_management.hide()
	_body.add_child(_management)
	_apply_open_state()
	manage.pressed.connect(func():
		_management.visible = not _management.visible
		manage.text = "Schiffsgruppen verwalten ▾" if _management.visible else "Schiffsgruppen verwalten ▸")
	var hint := Label.new()
	hint.text = "Schiffe per Ziehen und Ablegen zwischen den Karten bewegen. Reiter anklicken: Gruppe wählen; Schiffskarte anklicken: Schiff wählen."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_management.add_child(hint)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Name der Schiffsgruppe"
	_management.add_child(_name_edit)
	_add_button("Neue Schiffsgruppe", _create)
	_add_button("Umbenennen (gewählte Gruppe)", _rename)
	_add_button("Als Führung festlegen (gewähltes Schiff)", _set_leader)
	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_management.add_child(_feedback)
	var notice := Label.new()
	notice.text = "Schiffsgruppen werden noch nicht im Spielstand gespeichert."
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_management.add_child(notice)

func _add_button(label: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(action)
	_management.add_child(button)

## Ablageflaeche mit Titel; das erste Kind ist ein VBoxContainer, in den weitere Karten kommen koennen.
func _zone(node_name: String, title: String, target: String) -> PanelContainer:
	var zone := PanelContainer.new()
	zone.name = node_name
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.11, 0.15, 0.7)
	style.border_color = Color("284754")
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	zone.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	zone.add_child(box)
	var caption := Label.new()
	caption.text = title
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_theme_font_size_override("font_size", 12)
	box.add_child(caption)
	_make_drop_target(zone, target)
	_make_drop_target(box, target)
	return zone

func refresh(snapshot: Dictionary) -> void:
	_snapshot = snapshot
	var craft_labels: Array = []
	for craft: Dictionary in Array(snapshot.get("crafts", [])):
		craft_labels.append([craft.get("craft_id", ""), craft.get("display_name", craft.get("craft_id", ""))])
	var signature := var_to_str([snapshot.get("space_wings", {}), craft_labels])
	if signature == _signature: return
	_signature = signature
	var ships := Array(snapshot.get("crafts", [])).size()
	if (ships > 1) != (_ship_count > 1): _open_override = null
	_ship_count = ships
	_apply_open_state()
	var wings := _wings_dict()
	for id in _selected_wings.keys():
		if not wings.has(id): _selected_wings.erase(id)
	for id in _expanded_wings.keys():
		if not wings.has(id): _expanded_wings.erase(id)
	if not _selected_craft.is_empty() and _wing_of(_selected_craft).is_empty() and not _craft_names().has(_selected_craft): _selected_craft = ""
	_rebuild_cards()

func selected_wing_ids() -> Array:
	var ids := _selected_wings.keys()
	ids.sort()
	return ids

func select_for_craft(craft_id: String) -> void:
	var wings := _wings_dict()
	_selected_wings.clear()
	for id in wings:
		if craft_id in Array(Dictionary(wings[id]).get("craft_ids", [])):
			_selected_wings[id] = true
			break
	_selected_craft = craft_id
	_rebuild_cards()

func select_for_crafts(craft_ids: Array, additive: bool = false) -> void:
	var wings := _wings_dict()
	if not additive: _selected_wings.clear()
	for id in wings:
		for craft_id in Array(Dictionary(wings[id]).get("craft_ids", [])):
			if craft_id in craft_ids:
				_selected_wings[id] = true
				break
	if _selected_wings.size() == 1:
		var id: String = String(_selected_wings.keys()[0])
		var leader := String(Dictionary(wings[id]).get("leader_craft_id", ""))
		if not leader.is_empty(): wing_focus_requested.emit(leader)
	_rebuild_cards()

func select_wing(id: String, additive: bool = false) -> void:
	var wings := _wings_dict()
	if not wings.has(id): return
	if not additive: _selected_wings.clear()
	if additive and _selected_wings.has(id): _selected_wings.erase(id)
	else: _selected_wings[id] = true
	if _selected_wings.size() == 1:
		var remaining: String = String(_selected_wings.keys()[0])
		var leader := String(Dictionary(wings[remaining]).get("leader_craft_id", ""))
		if not leader.is_empty(): wing_focus_requested.emit(leader)
	_rebuild_cards()

func _card_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_drag_start = event.global_position
		_drag_end = _drag_start
		_drag_wing = id
		_drag_additive = event.ctrl_pressed
		_drag_active = true
		_show_tab_pressed(id, true)
		accept_event()

## Der Druck wird hier verbraucht, der Knopf zeichnet ihn deshalb nicht selbst: Druckzustand von Hand zeigen und wieder loesen.
func _show_tab_pressed(id: String, pressed: bool) -> void:
	if _cards == null: return
	for card in _cards.get_children():
		var button := card.get_child(0) as Button
		if button == null or String(button.get_meta("wing_id", "")) != id: continue
		if pressed:
			button.add_theme_stylebox_override("normal", button.get_theme_stylebox("pressed"))
			button.add_theme_stylebox_override("hover", button.get_theme_stylebox("pressed"))
		else:
			button.remove_theme_stylebox_override("normal")
			button.remove_theme_stylebox_override("hover")

func cancel_modal_input() -> void:
	_show_tab_pressed(_drag_wing, false)
	_drag_active = false
	_drag_wing = ""
	_drag_start = Vector2.ZERO
	_drag_end = Vector2.ZERO
	_drag_additive = false
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not _drag_active: return
	if not is_visible_in_tree():
		_drag_active = false
		queue_redraw()
		return
	if event is InputEventMouseMotion:
		_drag_end = event.global_position
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_drag_end = event.global_position
		_drag_active = false
		_show_tab_pressed(_drag_wing, false)
		if _drag_start.distance_to(_drag_end) < 6.0:
			_expanded_wings[_drag_wing] = not _is_expanded(_drag_wing)
			select_wing(_drag_wing, _drag_additive)
		else:
			var box := Rect2(_drag_start, _drag_end - _drag_start).abs()
			if not _drag_additive: _selected_wings.clear()
			for card in _cards.get_children():
				var button: Control = card.get_child(0)
				if box.intersects(button.get_global_rect()): _selected_wings[String(button.get_meta("wing_id"))] = true
			if _selected_wings.size() == 1:
				var id: String = String(_selected_wings.keys()[0])
				var wing: Dictionary = Dictionary(_wings_dict().get(id, {}))
				var leader := String(wing.get("leader_craft_id", ""))
				if not leader.is_empty(): wing_focus_requested.emit(leader)
			_rebuild_cards()
		queue_redraw()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	if _drag_active and _drag_start.distance_to(_drag_end) >= 6.0:
		var box := Rect2(_drag_start - global_position, _drag_end - _drag_start).abs()
		draw_rect(box, Color(0.3, 0.85, 0.95, 0.18), true)
		draw_rect(box, Color("77dce9"), false, 1.0)

func _rebuild_cards() -> void:
	if _cards == null: return
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for child in _free_cards.get_children():
		_free_cards.remove_child(child)
		child.queue_free()
	var wings := _wings_dict()
	var ids := wings.keys()
	ids.sort()
	var names := _craft_names()
	var assigned := {}
	for id in ids:
		var wing: Dictionary = wings[id]
		for craft_id in Array(wing.get("craft_ids", [])): assigned[String(craft_id)] = true
		var card := VBoxContainer.new()
		card.name = "WingCard_" + String(id).validate_node_name()
		_cards.add_child(card)
		var button := Button.new()
		button.name = "WingTab_" + String(id).validate_node_name()
		button.set_meta("wing_id", id)
		button.text = ("◆ " if _selected_wings.has(id) else "◇ ") + _wing_label(id, wing, names) + (" ▾" if _is_expanded(id) else " ▸")
		button.tooltip_text = "Klicken: auswählen und öffnen · Strg: Auswahl ergänzen · Schiffe hierher ziehen: zuordnen"
		button.gui_input.connect(_card_input.bind(String(id)))
		card.add_child(button)
		_make_drop_target(button, String(id))
		_make_drop_target(card, String(id))
		if _is_expanded(id):
			var members := VBoxContainer.new()
			members.name = "WingMembers_" + String(id).validate_node_name()
			card.add_child(members)
			_make_drop_target(members, String(id))
			var craft_ids: Array = Array(wing.get("craft_ids", []))
			for craft_id in craft_ids:
				members.add_child(_ship_card(String(craft_id), String(id), String(wing.get("leader_craft_id", "")) == String(craft_id), names))
			if craft_ids.is_empty():
				var empty := Label.new()
				empty.text = "Keine Schiffe zugeordnet"
				empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
				members.add_child(empty)
	for craft: Dictionary in Array(_snapshot.get("crafts", [])):
		var craft_id := String(craft.get("craft_id", ""))
		if craft_id.is_empty() or assigned.has(craft_id) or bool(craft.get("service_only", false)): continue
		_free_cards.add_child(_ship_card(craft_id, FREE_SHIPS, false, names))

## Schiffskarte: Klick waehlt das Schiff, Ziehen nimmt es mit. wing_id ist die Gruppe, in der es steht ("" = ohne Gruppe).
func _ship_card(craft_id: String, wing_id: String, leader: bool, names: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "ShipCard_" + craft_id.validate_node_name()
	card.set_meta("craft_id", craft_id)
	card.custom_minimum_size = Vector2(0, 30)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.tooltip_text = "Klicken: Schiff wählen · Ziehen: in eine andere Schiffsgruppe legen"
	var chosen := craft_id == _selected_craft
	var style := StyleBoxFlat.new()
	style.bg_color = Color("163244") if chosen else Color("0f2230")
	style.border_color = Color("f2c47c") if chosen else Color("2f5566")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	card.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = ("◆ " if leader else "• ") + String(names.get(craft_id, craft_id))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card.add_child(label)
	card.gui_input.connect(_ship_card_input.bind(craft_id))
	card.set_drag_forwarding(_ship_drag.bind(card, craft_id, wing_id), _can_drop_craft, _drop_craft.bind(wing_id))
	return card

func _ship_card_input(event: InputEvent, craft_id: String) -> void:
	# Ein Klick (ohne Ziehen) waehlt das Schiff; nach einem Zug kommt hier keine Loslassen-Meldung an.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_selected_craft = craft_id
		wing_focus_requested.emit(craft_id)
		call_deferred("_rebuild_cards")

func _ship_drag(_at_position: Vector2, card: Control, craft_id: String, wing_id: String) -> Variant:
	if craft_id.is_empty(): return null
	var preview := PanelContainer.new()
	var label := Label.new()
	label.text = String(_craft_names().get(craft_id, craft_id))
	preview.add_child(label)
	card.set_drag_preview(preview)
	return {"kind": DRAG_KIND, "craft_id": craft_id, "wing_id": wing_id}

func _make_drop_target(control: Control, target: String) -> void:
	control.set_drag_forwarding(Callable(), _can_drop_craft, _drop_craft.bind(target))

func _can_drop_craft(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and String(data.get("kind", "")) == DRAG_KIND and not String(data.get("craft_id", "")).is_empty()

func _drop_craft(_at_position: Vector2, data: Variant, target: String) -> void:
	if not _can_drop_craft(_at_position, data): return
	move_craft(String(data.get("craft_id", "")), String(data.get("wing_id", "")), target)

## Schiff zwischen Gruppen bewegen: aus der alten Gruppe nehmen (wing_remove), dann in die neue legen (wing_assign); fuer eine neue
## Gruppe vorher wing_create. Scheitert ein Schritt, steht der Grund im Rueckmeldefeld und das Schiff kommt in seine alte Gruppe zurueck.
func move_craft(craft_id: String, from_wing: String, target: String) -> Dictionary:
	if craft_id.is_empty() or from_wing == target: return {"ok": true, "unchanged": true}
	var wings := _wings_dict()
	if target != NEW_WING and target != FREE_SHIPS:
		var members: Array = Array(Dictionary(wings.get(target, {})).get("craft_ids", []))
		if not wings.has(target): return _say("Diese Schiffsgruppe gibt es nicht mehr.")
		if members.size() >= MAX_MEMBERS: return _say("Diese Schiffsgruppe hat bereits sechs Schiffe.")
	var from_name := String(Dictionary(wings.get(from_wing, {})).get("name", from_wing))
	if not from_wing.is_empty():
		var removed := submit("wing_remove", {"wing_id": from_wing, "craft_id": craft_id})
		if not removed.get("ok", false): return removed
	if target == FREE_SHIPS:
		_selected_craft = craft_id
		_rebuild_cards()
		return {"ok": true}
	var wing_id := target
	if target == NEW_WING:
		wing_id = "wing-%s-%d" % [_session, _sequence + 1]
		var created := submit("wing_create", {"wing_id": wing_id})
		if not created.get("ok", false):
			var message := _feedback.text
			_restore_membership(craft_id, from_wing, from_name)
			_feedback.text = message
			return created
	var assigned := submit("wing_assign", {"wing_id": wing_id, "craft_id": craft_id})
	if not assigned.get("ok", false):
		var message := _feedback.text
		_restore_membership(craft_id, from_wing, from_name)
		_feedback.text = message + (" Das Schiff bleibt in seiner Gruppe." if not from_wing.is_empty() else "")
		return assigned
	if target == NEW_WING: _selected_wings = {wing_id: true}
	_selected_craft = craft_id
	_rebuild_cards()
	return assigned

func _restore_membership(craft_id: String, from_wing: String, from_name: String) -> void:
	if from_wing.is_empty(): return
	if not _wings_dict().has(from_wing):
		if not submit("wing_create", {"wing_id": from_wing}).get("ok", false): return
		if not from_name.is_empty() and from_name != from_wing: submit("wing_rename", {"wing_id": from_wing, "name": from_name})
	submit("wing_assign", {"wing_id": from_wing, "craft_id": craft_id})

func _say(text: String) -> Dictionary:
	if _feedback != null: _feedback.text = text
	return {"ok": false, "message": text}

func submit(operation: String, payload: Dictionary) -> Dictionary:
	if not _commands.is_valid(): return {"ok":false, "reason":"runtime_unavailable"}
	_sequence += 1
	var command := {"contract_category":"space_combat", "operation":operation, "payload":payload,
		"request_id":"wing-ui:%s:%d" % [_session, _sequence],
		"expected_revision":int(Dictionary(_snapshot.get("space_wings", {})).get("revision", 0))}
	var result: Dictionary = _commands.call("space_wing_command", {"command":command})
	var reasons := {"craft_already_assigned":"Schiff gehört bereits zu einer Schiffsgruppe.", "wing_full":"Diese Schiffsgruppe hat bereits sechs Schiffe.", "pilot_missing":"Dem Schiff ist kein Pilot zugeordnet.", "not_member":"Dieses Schiff gehört nicht zu der ausgewählten Schiffsgruppe.", "stale_revision":"Der Bestand wurde geändert. Bitte erneut versuchen.", "craft_flying":"Das Schiff fliegt gerade und kann nicht umgeordnet werden."}
	_feedback.text = "" if result.get("ok", false) else String(result.get("message", reasons.get(result.get("reason", ""), result.get("reason", "Aktion abgelehnt"))))
	refresh(_read())
	return result

func get_feedback() -> String:
	return _feedback.text

func _read() -> Dictionary:
	return Dictionary(_provider.call()) if _provider.is_valid() else {}

func _single_selected_wing() -> String:
	return String(_selected_wings.keys()[0]) if _selected_wings.size() == 1 else ""

func _create() -> void:
	var id := "wing-%s-%d" % [_session, _sequence + 1]
	var result := submit("wing_create", {"wing_id":id})
	if result.get("ok", false):
		_selected_wings = {id: true}
		if not _name_edit.text.strip_edges().is_empty(): submit("wing_rename", {"wing_id":id, "name":_name_edit.text})
		_rebuild_cards()

func _rename() -> void:
	var id := _single_selected_wing()
	if id.is_empty() or _name_edit.text.strip_edges().is_empty():
		_feedback.text = "Eine Schiffsgruppe wählen und einen Namen eintragen."
		return
	submit("wing_rename", {"wing_id":id, "name":_name_edit.text})

func _set_leader() -> void:
	var wing := _wing_of(_selected_craft) if not _selected_craft.is_empty() else ""
	if wing.is_empty():
		_feedback.text = "Ein Schiff in einer Schiffsgruppe wählen (Schiffskarte anklicken)."
		return
	submit("wing_leader_set", {"wing_id":wing, "leader_craft_id":_selected_craft})
