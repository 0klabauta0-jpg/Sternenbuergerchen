extends Control
## One-built view over HomebaseTestScreen. Only focus, controls and render caches.

const PORTRAITS: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const BASE_SCENE: PackedScene = preload("res://scenes/meta/explorable_homebase.tscn")
const INK := Color("08232e")
const PANEL := Color("102f3b")
const CREAM := Color("f4f2e9")
const MUTED := Color("a8c0ca")
const CYAN := Color("29e1e7")
const GOLD := Color("ffd348")
const REFRESH_SECONDS: float = 0.25

var _screen: WeakRef
var _built: bool = false
var _mode: String = "squad"
var _elapsed: float = 0.0
var _refresh_count: int = 0
var _row_create_count: int = 0
var _rows: Dictionary = {}
var _slots: Array[Dictionary] = []
var _nav: Dictionary = {}
var _columns: Dictionary = {}
var _selectors: Dictionary = {}
var _workspace: Control
var _roster_list: VBoxContainer
var _search: LineEdit
var _team_selector: OptionButton
var _team_title: Label
var _team_note: Label
var _focused_portrait: TextureRect
var _focused_name: Label
var _focused_role: Label
var _focused_status: Label
var _identity_row: BoxContainer
var _focused_details: Button
var _remove_member: Button
var _craft_selector: OptionButton
var _craft_image: TextureRect
var _pilot_selector: OptionButton
var _craft_status: Label
var _payload_label: Label
var _progress: ProgressBar
var _board: Button
var _unboard: Button
var _start: Button
var _mission_selector: OptionButton
var _mission_name: Label
var _feedback: Label
var _base: Control
var _focused_id: String = ""
var _craft_id: String = ""
var _fireteam_id: String = ""
var _option_signatures: Dictionary = {}


func configure(screen: Control) -> void:
	_screen = weakref(screen)
	if is_node_ready():
		refresh()


func _ready() -> void:
	name = "OperationsRoot"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	visibility_changed.connect(_visibility_changed)
	set_process(true)
	refresh()


func _process(delta: float) -> void:
	if not is_visible_in_tree() or _mode == "base":
		return
	_elapsed += delta
	if _elapsed >= REFRESH_SECONDS:
		_elapsed = 0.0
		refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _built:
		_layout_columns()


func _visibility_changed() -> void:
	set_process(is_visible_in_tree())
	if _base != null:
		_base.call("set_active", is_visible_in_tree() and _mode == "base")
	if is_visible_in_tree():
		refresh()


func _owner_screen() -> Control:
	return _screen.get_ref() as Control if _screen != null else null


func _act(operation: String, payload: Dictionary = {}) -> void:
	var screen: Control = _owner_screen()
	if screen == null:
		return
	var result: Dictionary = screen.call("request_operation", operation, payload)
	if _feedback != null:
		_feedback.text = String(result.get("message", ""))
	refresh()


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = INK
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	margin.add_child(outer)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 56
	outer.add_child(header)
	var title: Label = _label("STERNENBÜRGERCHEN  /  Heimatbasis", 27, CREAM)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var tools: Button = _button("Erweiterte Werkzeuge", false)
	header.add_child(tools)
	tools.pressed.connect(func(): _act("legacy"))
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	outer.add_child(body)
	var nav := VBoxContainer.new()
	nav.custom_minimum_size.x = 166
	nav.add_theme_constant_override("separation", 10)
	body.add_child(nav)
	for item in [{"id": "base", "label": "Basis erkunden"}, {"id": "personnel", "label": "Personal"}, {"id": "squad", "label": "Trupp &\nAusrüstung"}, {"id": "mission", "label": "Einsatz &\nAbflug"}]:
		var key: String = String(item.id)
		var button: Button = _button(String(item.label), false)
		button.name = "Navigate_" + key
		button.custom_minimum_size.y = 66
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nav.add_child(button)
		button.pressed.connect(func(): _act("navigate", {"mode": key}))
		_nav[key] = button
	var nav_spacer := Control.new()
	nav_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav.add_child(nav_spacer)
	var detail_button: Button = _button("Charakterdetails", false)
	nav.add_child(detail_button)
	detail_button.pressed.connect(func(): _act("details", {"unit_id": _focused_id}))
	_workspace = Control.new()
	_workspace.name = "Workspace"
	_workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_workspace)
	_workspace.resized.connect(_layout_columns)
	_build_roster()
	_build_squad()
	_build_equipment()
	_build_flightdeck()
	_base = BASE_SCENE.instantiate() as Control
	_base.name = "ExplorableBase"
	_workspace.add_child(_base)
	_base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_base.call("set_active", false)
	_base.connect("terminal_open_requested", _terminal_requested)
	_base.connect("exploration_exit_requested", func(): _act("navigate", {"mode": "squad"}))
	_feedback = _label("", 15, GOLD)
	_feedback.custom_minimum_size.y = 24
	outer.add_child(_feedback)
	_built = true
	_layout_columns()


func _column(key: String, heading: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = key.capitalize() + "Column"
	panel.add_theme_stylebox_override("panel", _style(PANEL, Color("2b5361")))
	_workspace.add_child(panel)
	_columns[key] = panel
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)
	content.add_child(_label(heading, 23, CREAM))
	return content


func _scroll(parent: Control) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	return list


func _build_roster() -> void:
	var content: VBoxContainer = _column("roster", "Personal")
	_search = LineEdit.new()
	_search.placeholder_text = "Name suchen"
	_search.custom_minimum_size.y = 40
	content.add_child(_search)
	_search.text_changed.connect(func(_value: String): _filter_rows())
	_roster_list = _scroll(content)


func _build_squad() -> void:
	var content: VBoxContainer = _column("squad", "Trupp")
	_team_selector = _option(content, "TeamSelector")
	_team_selector.item_selected.connect(func(index: int): _act("focus_fireteam", {"fireteam_id": String(_team_selector.get_item_metadata(index))}))
	_team_title = _label("0 / 4", 18, GOLD)
	content.add_child(_team_title)
	var list: VBoxContainer = _scroll(content)
	for index in range(4):
		var slot: Dictionary = _person_row(list, "slot_%d" % index, false)
		_slots.append(slot)
		var focus: Button = slot.focus
		focus.pressed.connect(_slot_pressed.bind(index))
	_team_note = _label("Personal auswählen und zuweisen.", 15, MUTED)
	content.add_child(_team_note)
	var row := HBoxContainer.new()
	content.add_child(row)
	var add: Button = _button("Neuer Trupp", false)
	row.add_child(add)
	add.pressed.connect(func(): _act("add_fireteam"))


func _build_equipment() -> void:
	var content: VBoxContainer = _column("equipment", "Ausrüstung")
	var list: VBoxContainer = _scroll(content)
	_identity_row = BoxContainer.new()
	_identity_row.vertical = true
	_identity_row.add_theme_constant_override("separation", 18)
	list.add_child(_identity_row)
	_focused_portrait = _portrait(Vector2(176, 176))
	_focused_portrait.name = "FocusedPortrait"
	_focused_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_focused_portrait.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_focused_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_identity_row.add_child(_focused_portrait)
	var identity_text := VBoxContainer.new()
	identity_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_text.add_theme_constant_override("separation", 12)
	_identity_row.add_child(identity_text)
	_focused_name = _label("Mitglied auswählen", 24, CREAM)
	identity_text.add_child(_focused_name)
	_focused_role = _label("", 17, MUTED)
	identity_text.add_child(_focused_role)
	_focused_status = _label("", 15, GOLD)
	identity_text.add_child(_focused_status)
	for spec in [{"id": "armor", "label": "Rüstung"}, {"id": "weapon_1", "label": "Primärwaffe"}, {"id": "weapon_2", "label": "Sekundärwaffe"}]:
		var key: String = String(spec.id)
		list.add_child(_label(String(spec.label), 16, MUTED))
		var selector: OptionButton = _option(list, key.capitalize() + "Selector")
		selector.item_selected.connect(func(index: int): _act("loadout", {"unit_id": _focused_id, "key": key, "value": String(selector.get_item_metadata(index))}))
		_selectors[key] = selector
	_remove_member = _button("Aus Trupp entfernen", false)
	list.add_child(_remove_member)
	_remove_member.pressed.connect(func(): _act("remove", {"unit_id": _focused_id}))
	_focused_details = _button("Charakter ansehen", false)
	list.add_child(_focused_details)
	_focused_details.pressed.connect(func(): _act("details", {"unit_id": _focused_id}))


func _build_flightdeck() -> void:
	var content: VBoxContainer = _column("flight", "Einsatz & Abflug")
	var list: VBoxContainer = _scroll(content)
	_mission_name = _label("Einsatz auswählen", 20, CREAM)
	list.add_child(_mission_name)
	_mission_selector = _option(list, "MissionSelector")
	_mission_selector.item_selected.connect(func(index: int): _act("mission", {"mission_id": String(_mission_selector.get_item_metadata(index))}))
	_craft_selector = _option(list, "CraftSelector")
	_craft_selector.item_selected.connect(func(index: int): _act("craft", {"craft_id": String(_craft_selector.get_item_metadata(index))}))
	_craft_image = _portrait(Vector2(120, 150))
	_craft_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	list.add_child(_craft_image)
	list.add_child(_label("Pilot", 16, MUTED))
	_pilot_selector = _option(list, "PilotSelector")
	_pilot_selector.item_selected.connect(func(index: int): _act("pilot", {"unit_id": String(_pilot_selector.get_item_metadata(index)), "craft_id": _craft_id}))
	_craft_status = _label("Kein Schiff verfügbar", 19, GOLD)
	list.add_child(_craft_status)
	_payload_label = _label("", 16, CREAM)
	list.add_child(_payload_label)
	_progress = ProgressBar.new()
	_progress.custom_minimum_size.y = 18
	_progress.show_percentage = false
	list.add_child(_progress)
	_board = _button("Boarding starten", false)
	_board.custom_minimum_size.y = 52
	list.add_child(_board)
	_board.pressed.connect(func(): _act("board", {"fireteam_id": _fireteam_id, "craft_id": _craft_id}))
	_unboard = _button("Trupp zurückholen", false)
	list.add_child(_unboard)
	_unboard.pressed.connect(func(): _act("unboard", {"fireteam_id": _fireteam_id, "craft_id": _craft_id}))
	_start = _button("Einsatz starten  ›", true)
	_start.name = "StartMission"
	_start.custom_minimum_size.y = 64
	list.add_child(_start)
	_start.pressed.connect(func(): _act("start", {"craft_id": _craft_id}))


func _person_row(parent: Control, id: String, with_assign: bool) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = "Person_" + id.validate_node_name()
	panel.custom_minimum_size.y = 112
	panel.add_theme_stylebox_override("panel", _style(Color("163743"), Color("28515e")))
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	panel.add_child(row)
	var portrait: TextureRect = _portrait(Vector2(96, 96))
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.custom_minimum_size.x = 100.0
	text.add_theme_constant_override("separation", 3)
	row.add_child(text)
	var focus := Button.new()
	focus.flat = true
	focus.alignment = HORIZONTAL_ALIGNMENT_LEFT
	focus.add_theme_font_size_override("font_size", 19)
	focus.custom_minimum_size.y = 31
	focus.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	focus.clip_text = true
	text.add_child(focus)
	var role: Label = _label("", 15, MUTED)
	role.autowrap_mode = TextServer.AUTOWRAP_OFF
	role.clip_text = true
	role.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.add_child(role)
	var status: Label = _label("", 14, CYAN)
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	status.clip_text = true
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.add_child(status)
	var action: Button
	if with_assign:
		action = _button("+", false)
		action.custom_minimum_size = Vector2(40, 42)
		action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(action)
	return {"root": panel, "portrait": portrait, "focus": focus, "role": role, "status": status, "assign": action, "unit_id": ""}


func _slot_pressed(index: int) -> void:
	var id: String = String(_slots[index].get("unit_id", ""))
	if not id.is_empty():
		_act("focus_unit", {"unit_id": id})


func refresh() -> void:
	var screen: Control = _owner_screen()
	if screen == null or not _built or not is_visible_in_tree():
		return
	var snapshot: Dictionary = screen.call("get_operations_snapshot")
	_refresh_count += 1
	var mode: String = String(snapshot.get("mode", "squad"))
	var changed_mode: bool = mode != _mode
	_mode = mode
	var focused: Dictionary = Dictionary(snapshot.get("focused_unit", {}))
	_focused_id = String(focused.get("id", ""))
	_fireteam_id = String(snapshot.get("focused_fireteam_id", ""))
	if changed_mode or _refresh_count == 1:
		for key in _nav:
			var button: Button = _nav[key]
			button.add_theme_stylebox_override("normal", _style(Color("15505d") if key == _mode else PANEL, CYAN if key == _mode else Color("2b5361")))
	_update_roster(Array(snapshot.get("roster", [])))
	var team: Dictionary = Dictionary(snapshot.get("focused_fireteam", {}))
	_update_team(team, Array(snapshot.get("fireteams", [])))
	_update_equipment(focused, Dictionary(snapshot.get("loadout_options", {})))
	_update_flight(Dictionary(snapshot.get("selected_craft", {})), snapshot)
	if changed_mode:
		_layout_columns()
		_base.call("set_active", _mode == "base" and is_visible_in_tree())


func _update_roster(roster: Array) -> void:
	var live: Dictionary = {}
	for unit_variant in roster:
		var unit: Dictionary = Dictionary(unit_variant)
		var id: String = String(unit.get("id", ""))
		if id.is_empty():
			continue
		live[id] = true
		if not _rows.has(id):
			var row: Dictionary = _person_row(_roster_list, id, true)
			_rows[id] = row
			_row_create_count += 1
			var focus: Button = row.focus
			focus.pressed.connect(func(): _act("focus_unit", {"unit_id": id}))
			var assign: Button = row.assign
			assign.pressed.connect(func(): _act("assign", {"unit_id": id}))
		var item: Dictionary = Dictionary(_rows[id])
		_fill_person(item, unit)
		var action: Button = item.assign
		action.disabled = not bool(unit.get("can_assign", false))
		action.text = "✓" if String(unit.get("fireteam_id", "")) == _fireteam_id else "+"
		action.tooltip_text = "Diesem Trupp zuweisen" if not action.disabled else String(unit.get("status", ""))
	for key in _rows.keys():
		if not live.has(key):
			Dictionary(_rows[key]).root.queue_free()
			_rows.erase(key)
	_filter_rows()


func _filter_rows() -> void:
	var query: String = _search.text.strip_edges().to_lower()
	for item_variant in _rows.values():
		var item: Dictionary = Dictionary(item_variant)
		var root_control: Control = item.root
		var focus: Button = item.focus
		root_control.visible = query.is_empty() or focus.text.to_lower().contains(query)


func _fill_person(row: Dictionary, unit: Dictionary) -> void:
	var portrait: TextureRect = row.portrait
	var wide: bool = _workspace.size.x > 2200.0
	var portrait_edge: float = 112.0 if wide else 96.0
	portrait.custom_minimum_size = Vector2(portrait_edge, portrait_edge)
	_set_portrait(portrait, unit)
	var focus: Button = row.focus
	focus.add_theme_font_size_override("font_size", 23 if wide else 19)
	focus.text = String(unit.get("name", "Freier Platz"))
	focus.tooltip_text = focus.text
	focus.disabled = unit.is_empty()
	var role: Label = row.role
	role.add_theme_font_size_override("font_size", 17 if wide else 15)
	role.text = String(unit.get("role", "Personal auswählen"))
	role.tooltip_text = role.text
	var status: Label = row.status
	status.add_theme_font_size_override("font_size", 16 if wide else 14)
	status.text = String(unit.get("status", ""))
	status.tooltip_text = status.text
	var panel: PanelContainer = row.root
	panel.custom_minimum_size.y = 128.0 if wide else 112.0
	var selected: bool = not unit.is_empty() and String(unit.get("id", "")) == _focused_id
	if not panel.has_meta("operations_selected") or bool(panel.get_meta("operations_selected")) != selected:
		panel.add_theme_stylebox_override("panel", _style(Color("173d49"), GOLD if selected else Color("28515e")))
		panel.set_meta("operations_selected", selected)


func _update_team(team: Dictionary, teams: Array) -> void:
	_set_options(_team_selector, teams, _fireteam_id)
	var members: Array = Array(team.get("members", []))
	_team_title.text = "%d / 4 Mitglieder" % members.size()
	for index in range(4):
		var unit: Dictionary = Dictionary(members[index]) if index < members.size() else {}
		_slots[index]["unit_id"] = String(unit.get("id", ""))
		_fill_person(_slots[index], unit)
	_team_note.text = "Trupp an Bord · zum Bearbeiten zurückholen" if bool(team.get("busy", false)) else "Personal auswählen und zuweisen."
	if members.size() > 4:
		_team_note.text = "%d weitere Mitglieder in den Charakterdetails/Werkzeugen." % (members.size() - 4)


func _update_equipment(unit: Dictionary, options: Dictionary) -> void:
	_set_portrait(_focused_portrait, unit)
	_focused_name.text = String(unit.get("name", "Mitglied auswählen"))
	_focused_role.text = String(unit.get("role", ""))
	_focused_status.text = String(unit.get("status", ""))
	var loadout: Dictionary = Dictionary(unit.get("loadout", {}))
	for key in _selectors:
		var selector: OptionButton = _selectors[key]
		_set_options(selector, Array(options.get(key, [])), String(loadout.get(key, "")))
		selector.disabled = not bool(unit.get("can_edit", false))
	_remove_member.disabled = not bool(unit.get("can_remove", false))
	_focused_details.disabled = unit.is_empty()


func _update_flight(craft: Dictionary, snapshot: Dictionary) -> void:
	_craft_id = String(craft.get("id", ""))
	_set_options(_craft_selector, Array(snapshot.get("crafts", [])), _craft_id)
	_set_options(_mission_selector, Array(snapshot.get("missions", [])), String(snapshot.get("mission_id", "")))
	_mission_name.text = String(snapshot.get("mission_name", "Einsatz"))
	_set_options(_pilot_selector, Array(craft.get("pilot_options", [])), String(craft.get("pilot_id", "")))
	_pilot_selector.disabled = bool(craft.get("busy", false)) or craft.is_empty()
	_set_texture(_craft_image, String(craft.get("texture_path", "")))
	_craft_status.text = String(craft.get("status", "Kein Schiff verfügbar"))
	_payload_label.text = "%d Kräfte an Bord / im Boarding" % int(craft.get("passenger_count", 0))
	_progress.value = float(craft.get("progress", 0.0))
	_board.disabled = not bool(craft.get("can_board", false))
	_unboard.disabled = not bool(craft.get("can_unboard", false))
	_unboard.visible = bool(craft.get("has_payload", false))
	_start.disabled = not bool(craft.get("can_start", false))
	_start.tooltip_text = String(craft.get("next_step", ""))


func _set_portrait(rect: TextureRect, unit: Dictionary) -> void:
	var path: String = PORTRAITS.resolve_path(String(unit.get("portrait_id", "")), String(unit.get("portrait_path", ""))) if not unit.is_empty() else ""
	_set_texture(rect, path)


func _set_texture(rect: TextureRect, path: String) -> void:
	if String(rect.get_meta("rendered_path", "__unset")) == path:
		return
	rect.texture = load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	rect.set_meta("rendered_path", path)


func _set_options(selector: OptionButton, options: Array, selected: String) -> void:
	var stable_options: Array = []
	var equipment_labels: Dictionary = {"light": "Leicht", "medium": "Mittel", "heavy": "Schwer", "rifle": "Sturmgewehr", "smg": "Maschinenpistole", "sniper": "Scharfschützengewehr", "rail_gun": "Railgun", "rocket_launcher": "Raketenwerfer", "medictool": "Sanitätsgerät", "none": "Keine"}
	for option_variant in options:
		var option: Dictionary = Dictionary(option_variant)
		var id: String = String(option.get("id", ""))
		var label: String = String(option.get("label", option.get("name", "")))
		if _selectors.values().has(selector):
			label = String(equipment_labels.get(id, label))
		stable_options.append({"id": id, "label": label})
	var signature: String = JSON.stringify(stable_options)
	if String(_option_signatures.get(selector.get_instance_id(), "")) != signature:
		selector.clear()
		for option_variant in stable_options:
			var option: Dictionary = Dictionary(option_variant)
			selector.add_item(String(option.get("label", option.get("name", ""))))
			selector.set_item_metadata(selector.item_count - 1, String(option.get("id", "")))
		_option_signatures[selector.get_instance_id()] = signature
	for index in range(selector.item_count):
		if String(selector.get_item_metadata(index)) == selected:
			selector.select(index)
			break


func _layout_columns() -> void:
	if _workspace == null or _columns.size() != 4:
		return
	var available: Vector2 = _workspace.size
	var keys: Array = ["roster", "squad", "equipment", "flight"]
	var weights: Array = [0.24, 0.23, 0.26, 0.27]
	if _mode == "personnel":
		keys = ["roster", "equipment"]
		weights = [0.58, 0.42]
	elif _mode == "mission":
		keys = ["squad", "equipment", "flight"]
		weights = [0.28, 0.30, 0.42]
	elif _mode == "base":
		keys = []
		weights = []
	elif available.x < 1450.0 and size.x < 1600.0:
		# Boarding stays on its existing navigation page when four columns
		# would squeeze a portrait, readable name and assignment into a sliver.
		keys = ["roster", "squad", "equipment"]
		weights = [0.32, 0.30, 0.38]
	# Keep the reference-like grouping readable on ultrawide displays rather
	# than stretching short controls and portraits across empty 800px columns.
	var design_width: float = minf(available.x, 2400.0)
	var x: float = maxf((available.x - design_width) * 0.5, 0.0)
	var usable: float = maxf(design_width - maxf(keys.size() - 1, 0) * 12.0, 0.0)
	for key in _columns:
		var panel: Control = _columns[key]
		panel.visible = keys.has(key)
	for index in range(keys.size()):
		var panel: Control = _columns[keys[index]]
		var width: float = usable * float(weights[index])
		var maximum_height: float = 850.0 if keys[index] in ["squad", "equipment"] else (1060.0 if keys[index] == "flight" else available.y)
		panel.position = Vector2(x, 0)
		panel.size = Vector2(width, minf(available.y, maximum_height))
		x += width + 12
	if _identity_row != null:
		var equipment_panel: Control = _columns.equipment
		_identity_row.vertical = equipment_panel.size.x < 450.0
		var portrait_edge: float = 224.0 if available.x > 2200.0 else 176.0
		_focused_portrait.custom_minimum_size = Vector2(portrait_edge, portrait_edge)
		_focused_name.add_theme_font_size_override("font_size", 30 if available.x > 2200.0 else 24)
		_craft_image.custom_minimum_size.y = clampf(available.y * 0.28, 180.0, 360.0)
	if _base != null:
		_base.visible = _mode == "base"


func _terminal_requested(id: String) -> void:
	var target: String = "personnel" if id == "personnel" else ("squad" if id == "team" else "mission")
	_act("navigate", {"mode": target})


func get_presentation_snapshot() -> Dictionary:
	var rects: Dictionary = {}
	for key in _columns:
		var column: Control = _columns[key]
		rects[key] = {"rect": Rect2(column.global_position, column.size), "visible": column.is_visible_in_tree()}
	var minimum_name_width: float = INF
	var minimum_row_width: float = INF
	var minimum_portrait_width: float = INF
	var minimum_assign_width: float = INF
	var single_line_roles: bool = true
	for row_variant in _rows.values():
		var row: Dictionary = Dictionary(row_variant)
		var row_root: Control = row.root
		if not row_root.is_visible_in_tree():
			continue
		var focus: Button = row.focus
		var portrait: TextureRect = row.portrait
		var assign: Button = row.assign
		var role: Label = row.role
		var status: Label = row.status
		minimum_name_width = minf(minimum_name_width, focus.size.x)
		minimum_row_width = minf(minimum_row_width, row_root.size.x)
		minimum_portrait_width = minf(minimum_portrait_width, portrait.size.x)
		minimum_assign_width = minf(minimum_assign_width, assign.size.x)
		single_line_roles = single_line_roles and role.autowrap_mode == TextServer.AUTOWRAP_OFF and status.autowrap_mode == TextServer.AUTOWRAP_OFF
	var mission_navigation: Button = _nav.mission
	return {"presenter": "homebase_operations_20261105", "refresh_count": _refresh_count,
		"row_create_count": _row_create_count, "cached_row_count": _rows.size(),
		"team_slot_count": _slots.size(), "loadout_selector_count": _selectors.size(),
		"mode": _mode, "columns": rects, "visible": is_visible_in_tree(),
		"base_active": _mode == "base" and is_visible_in_tree(), "poll_seconds": REFRESH_SECONDS,
		"focused_portrait_rect": Rect2(_focused_portrait.global_position, _focused_portrait.size),
		"focused_portrait_stretch_mode": _focused_portrait.stretch_mode,
		"workspace_size": _workspace.size,
		"roster_minimum_name_width": minimum_name_width if is_finite(minimum_name_width) else 0.0,
		"roster_minimum_row_width": minimum_row_width if is_finite(minimum_row_width) else 0.0,
		"roster_minimum_portrait_width": minimum_portrait_width if is_finite(minimum_portrait_width) else 0.0,
		"roster_minimum_assign_width": minimum_assign_width if is_finite(minimum_assign_width) else 0.0,
		"roster_role_status_single_line": single_line_roles,
		"mission_navigation_visible": mission_navigation.is_visible_in_tree(),
		"mission_navigation_rect": Rect2(mission_navigation.global_position, mission_navigation.size),
		"ship_preview_path": String(_craft_image.get_meta("rendered_path", "")),
		"base": _base.call("get_exploration_snapshot") if _base != null else {}}


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _portrait(minimum: Vector2) -> TextureRect:
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = minimum
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return portrait


func _option(parent: Control, node_name: String) -> OptionButton:
	var option := OptionButton.new()
	option.name = node_name
	option.custom_minimum_size.y = 42
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.fit_to_longest_item = false
	option.add_theme_font_size_override("font_size", 17)
	parent.add_child(option)
	return option


func _button(value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 40
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_stylebox_override("normal", _style(GOLD if primary else PANEL, GOLD if primary else CYAN))
	button.add_theme_stylebox_override("hover", _style(Color("ffe785") if primary else Color("1d5361"), CYAN))
	button.add_theme_stylebox_override("pressed", _style(Color("dfb62d") if primary else Color("0c5864"), GOLD))
	button.add_theme_color_override("font_color", INK if primary else CREAM)
	return button


func _style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
