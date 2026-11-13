extends VBoxContainer
## Selection and feedback only; membership belongs to the simulation owner.
signal wing_focus_requested(craft_id: String)
var _provider: Callable
var _commands: Callable
var _snapshot: Dictionary = {}
var _signature := ""
var _sequence := 0
var _session := ""
var _wings: OptionButton
var _crafts: OptionButton
var _name_edit: LineEdit
var _feedback: Label
var _members: Label
var _cards: VBoxContainer
var _management: VBoxContainer
var _selected_wings: Dictionary = {}
var _expanded_wings: Dictionary = {}
var _drag_start := Vector2.ZERO
var _drag_end := Vector2.ZERO
var _drag_wing := ""
var _drag_additive := false
var _drag_active := false

func configure(snapshot_provider: Callable, command_handler: Callable) -> void:
	_provider = snapshot_provider
	_commands = command_handler
	_session = "%d-%d" % [get_instance_id(), Time.get_ticks_usec()]
	if _wings == null: _build()
	refresh(_read())

func _build() -> void:
	name = "SpaceWingPanel"
	var heading := Label.new()
	heading.text = "ROTTEN"
	add_child(heading)
	_cards = VBoxContainer.new()
	_cards.name = "WingCards"
	add_child(_cards)
	var manage := Button.new()
	manage.text = "Rotten verwalten ▸"
	add_child(manage)
	_management = VBoxContainer.new()
	_management.name = "WingManagement"
	_management.hide()
	add_child(_management)
	manage.pressed.connect(func():
		_management.visible = not _management.visible
		manage.text = "Rotten verwalten ▾" if _management.visible else "Rotten verwalten ▸")
	_wings = OptionButton.new()
	_wings.name = "WingSelector"
	_management.add_child(_wings)
	_wings.item_selected.connect(func(_index: int): _show_members())
	_members = Label.new()
	_members.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_management.add_child(_members)
	_crafts = OptionButton.new()
	_crafts.name = "WingCraftSelector"
	_management.add_child(_crafts)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Rottenname"
	_management.add_child(_name_edit)
	_add_button("Neue Rotte", _create)
	_add_button("Umbenennen", _rename)
	_add_button("Schiff zuordnen", func(): _selected_action("wing_assign"))
	_add_button("Schiff entfernen", func(): _selected_action("wing_remove"))
	_add_button("Als Führung festlegen", func(): _selected_action("wing_leader_set"))
	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_management.add_child(_feedback)
	var notice := Label.new()
	notice.text = "Rotten werden noch nicht im Spielstand gespeichert."
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_management.add_child(notice)

func _add_button(label: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(action)
	_management.add_child(button)

func refresh(snapshot: Dictionary) -> void:
	_snapshot = snapshot
	var craft_labels: Array = []
	for craft: Dictionary in Array(snapshot.get("crafts", [])):
		craft_labels.append([craft.get("craft_id", ""), craft.get("display_name", craft.get("craft_id", ""))])
	var signature := var_to_str([snapshot.get("space_wings", {}), craft_labels])
	if signature == _signature: return
	_signature = signature
	var selected_wing := _selected(_wings)
	var selected_craft := _selected(_crafts)
	_wings.clear()
	var wings: Dictionary = Dictionary(snapshot.get("space_wings", {})).get("wings", {})
	for id in _selected_wings.keys():
		if not wings.has(id): _selected_wings.erase(id)
	for id in _expanded_wings.keys():
		if not wings.has(id): _expanded_wings.erase(id)
	_rebuild_cards()
	var ids: Array = wings.keys()
	ids.sort()
	for id in ids:
		var wing: Dictionary = wings[id]
		_wings.add_item("%s (%d/6)" % [wing.get("name", id), Array(wing.get("craft_ids", [])).size()])
		_wings.set_item_metadata(_wings.item_count - 1, id)
		if id == selected_wing: _wings.select(_wings.item_count - 1)
	_crafts.clear()
	for craft: Dictionary in Array(snapshot.get("crafts", [])):
		var id := String(craft.get("craft_id", ""))
		if id.is_empty(): continue
		_crafts.add_item(String(craft.get("display_name", id)))
		_crafts.set_item_metadata(_crafts.item_count - 1, id)
		if id == selected_craft: _crafts.select(_crafts.item_count - 1)
	_show_members()

func selected_wing_ids() -> Array:
	var ids := _selected_wings.keys()
	ids.sort()
	return ids

func select_for_craft(craft_id: String) -> void:
	var wings: Dictionary = Dictionary(_snapshot.get("space_wings", {})).get("wings", {})
	_selected_wings.clear()
	for id in wings:
		if craft_id in Array(Dictionary(wings[id]).get("craft_ids", [])):
			_selected_wings[id] = true
			break
	_rebuild_cards()

func select_for_crafts(craft_ids: Array, additive: bool = false) -> void:
	var wings: Dictionary = Dictionary(_snapshot.get("space_wings", {})).get("wings", {})
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
	var wings: Dictionary = Dictionary(_snapshot.get("space_wings", {})).get("wings", {})
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
		accept_event()

func cancel_modal_input() -> void:
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
		if _drag_start.distance_to(_drag_end) < 6.0:
			_expanded_wings[_drag_wing] = not bool(_expanded_wings.get(_drag_wing, false))
			select_wing(_drag_wing, _drag_additive)
		else:
			var box := Rect2(_drag_start, _drag_end - _drag_start).abs()
			if not _drag_additive: _selected_wings.clear()
			for card in _cards.get_children():
				var button: Control = card.get_child(0)
				if box.intersects(button.get_global_rect()): _selected_wings[String(button.get_meta("wing_id"))] = true
			if _selected_wings.size() == 1:
				var id: String = String(_selected_wings.keys()[0])
				var wing: Dictionary = Dictionary(Dictionary(_snapshot.get("space_wings", {})).get("wings", {})).get(id, {})
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
	var wings: Dictionary = Dictionary(_snapshot.get("space_wings", {})).get("wings", {})
	var ids := wings.keys()
	ids.sort()
	var names := {}
	for craft: Dictionary in Array(_snapshot.get("crafts", [])):
		names[String(craft.get("craft_id", ""))] = String(craft.get("display_name", craft.get("craft_id", "")))
	for id in ids:
		var wing: Dictionary = wings[id]
		var card := VBoxContainer.new()
		_cards.add_child(card)
		var button := Button.new()
		button.name = "WingTab_" + String(id).validate_node_name()
		button.set_meta("wing_id", id)
		button.text = ("◆ " if _selected_wings.has(id) else "◇ ") + String(wing.get("name", id)) + (" ▾" if _expanded_wings.has(id) and _expanded_wings[id] else " ▸")
		button.tooltip_text = "Klicken: auswählen und öffnen · Strg: Auswahl ergänzen"
		button.gui_input.connect(_card_input.bind(String(id)))
		card.add_child(button)
		if bool(_expanded_wings.get(id, false)):
			var details := Label.new()
			details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var members: PackedStringArray = []
			for craft_id in Array(wing.get("craft_ids", [])):
				members.append(("◆ " if craft_id == wing.get("leader_craft_id", "") else "• ") + String(names.get(craft_id, craft_id)))
			details.text = "\n".join(members) if not members.is_empty() else "Keine Schiffe zugeordnet"
			card.add_child(details)

func _show_members() -> void:
	var wings: Dictionary = Dictionary(_snapshot.get("space_wings", {})).get("wings", {})
	var wing: Dictionary = wings.get(_selected(_wings), {})
	if wing.is_empty():
		_members.text = "Noch keine Rotte ausgewählt."
		return
	var names: Dictionary = {}
	for craft: Dictionary in Array(_snapshot.get("crafts", [])):
		names[String(craft.get("craft_id", ""))] = String(craft.get("display_name", craft.get("craft_id", "")))
	var lines: PackedStringArray = []
	for id in Array(wing.get("craft_ids", [])):
		lines.append(("◆ " if id == wing.get("leader_craft_id", "") else "• ") + String(names.get(id, id)))
	_members.text = "\n".join(lines) if not lines.is_empty() else "Noch keine Schiffe zugeordnet."

func submit(operation: String, payload: Dictionary) -> Dictionary:
	if not _commands.is_valid(): return {"ok":false, "reason":"runtime_unavailable"}
	_sequence += 1
	var command := {"contract_category":"space_combat", "operation":operation, "payload":payload,
		"request_id":"wing-ui:%s:%d" % [_session, _sequence],
		"expected_revision":int(Dictionary(_snapshot.get("space_wings", {})).get("revision", 0))}
	var result: Dictionary = _commands.call("space_wing_command", {"command":command})
	var reasons := {"craft_already_assigned":"Schiff gehört bereits zu einer Rotte.", "wing_full":"Diese Rotte hat bereits sechs Schiffe.", "pilot_missing":"Dem Schiff ist kein Pilot zugeordnet.", "not_member":"Dieses Schiff gehört nicht zu der ausgewählten Rotte.", "stale_revision":"Der Bestand wurde geändert. Bitte erneut versuchen."}
	_feedback.text = "" if result.get("ok", false) else String(result.get("message", reasons.get(result.get("reason", ""), result.get("reason", "Aktion abgelehnt"))))
	refresh(_read())
	return result

func get_feedback() -> String:
	return _feedback.text

func _read() -> Dictionary:
	return Dictionary(_provider.call()) if _provider.is_valid() else {}

func _selected(control: OptionButton) -> String:
	return String(control.get_item_metadata(control.selected)) if control != null and control.selected >= 0 else ""

func _create() -> void:
	var id := "wing-%s-%d" % [_session, _sequence + 1]
	var result := submit("wing_create", {"wing_id":id})
	if result.get("ok", false) and not _name_edit.text.strip_edges().is_empty():
		submit("wing_rename", {"wing_id":id, "name":_name_edit.text})

func _rename() -> void:
	var id := _selected(_wings)
	if id.is_empty() or _name_edit.text.strip_edges().is_empty():
		_feedback.text = "Rotte und Namen auswählen."
		return
	submit("wing_rename", {"wing_id":id, "name":_name_edit.text})

func _selected_action(operation: String) -> void:
	var wing := _selected(_wings)
	var craft := _selected(_crafts)
	if wing.is_empty() or craft.is_empty():
		_feedback.text = "Rotte und Schiff auswählen."
		return
	var payload := {"wing_id":wing}
	payload["leader_craft_id" if operation == "wing_leader_set" else "craft_id"] = craft
	submit(operation, payload)
