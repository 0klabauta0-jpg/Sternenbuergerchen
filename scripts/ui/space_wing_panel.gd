extends VBoxContainer
## Selection and feedback only; membership belongs to the simulation owner.
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
	_wings = OptionButton.new()
	_wings.name = "WingSelector"
	add_child(_wings)
	_wings.item_selected.connect(func(_index: int): _show_members())
	_members = Label.new()
	_members.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_members)
	_crafts = OptionButton.new()
	_crafts.name = "WingCraftSelector"
	add_child(_crafts)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Rottenname"
	add_child(_name_edit)
	_add_button("Neue Rotte", _create)
	_add_button("Umbenennen", _rename)
	_add_button("Schiff zuordnen", func(): _selected_action("wing_assign"))
	_add_button("Schiff entfernen", func(): _selected_action("wing_remove"))
	_add_button("Als Führung festlegen", func(): _selected_action("wing_leader_set"))
	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_feedback)
	var notice := Label.new()
	notice.text = "Rotten werden noch nicht im Spielstand gespeichert."
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(notice)

func _add_button(label: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(action)
	add_child(button)

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
