extends Control
## One-built view over HomebaseTestScreen. Only focus, controls and render caches.

const PORTRAITS: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const BASE_SCENE: PackedScene = preload("res://scenes/meta/explorable_homebase.tscn")
const THEME: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")
const DRAG_SURFACE: GDScript = preload("res://scripts/meta/operations_drag_surface.gd")
const BADGES: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const INK := Color("08232e")
const PANEL := Color("102f3b")
const CREAM := Color("f4f2e9")
const MUTED := Color("a8c0ca")
const CYAN := Color("29e1e7")
const GOLD := Color("ffd348")
const REFRESH_SECONDS: float = 0.25
const EQUIPMENT_LABELS: Dictionary = {"light": "Leicht", "medium": "Mittel", "heavy": "Schwer", "rifle": "Sturmgewehr", "smg": "Maschinenpistole", "sniper": "Scharfschützengewehr", "rail_gun": "Railgun", "rocket_launcher": "Raketenwerfer", "medictool": "Sanitätsgerät", "none": "Keine"}
const SHIP_BACKDROP_SCRIPT: GDScript = preload("res://scripts/meta/ship_context_backdrop.gd")

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
var _sort_selector: OptionButton
var _roster_return_target: PanelContainer
var _team_drag_source: PanelContainer
var _craft_drop_target: PanelContainer
var _squad_craft_image: TextureRect
var _squad_craft_selector: OptionButton
var _squad_craft_caption: Label
var _inventory_panel: VBoxContainer
var _equipment_slots: Dictionary = {}
var _equipment_palette: VBoxContainer
var _equipment_palette_toggle: Button
var _equipment_palette_flow: HFlowContainer
var _equipment_palette_tabs: Dictionary = {}
var _equipment_palette_chips: Dictionary = {}
var _equipment_palette_options: Dictionary = {}
var _equipment_palette_key: String = "armor"
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
var _launch_reason: Label
var _mission_selector: OptionButton
var _mission_name: Label
var _feedback: Label
var _base: Control
var _focused_id: String = ""
var _craft_id: String = ""
var _fireteam_id: String = ""
var _option_signatures: Dictionary = {}
var _reference_stage: PanelContainer
var _stage_content: Control
var _stage_name: Label
var _stage_caption: Label
var _ship_backdrop: Control
var _ship_preview_context: Dictionary = {}
var _preview_layout_rect := Rect2()
var _workflow: HBoxContainer
var _workflow_labels: Dictionary = {}
var _job_board: Control
var _region_map: Control
var _services_view: Control


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
	THEME.style_section_heading(title, 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back: Button = _button("‹ Zur Truppansicht", false)
	back.name = "OperationsBack"
	header.add_child(back)
	back.pressed.connect(func(): _act("navigate", {"mode": "squad"}))
	_workflow = HBoxContainer.new()
	_workflow.name = "PreparationSequence"
	_workflow.add_theme_constant_override("separation", 24)
	outer.add_child(_workflow)
	for entry in [{"id": "personnel", "label": "01  PERSONAL"}, {"id": "squad", "label": "02  TRUPP & AUSRÜSTUNG"}, {"id": "mission", "label": "03  EINSATZ & ABFLUG"}]:
		var step: Label = _label(String(entry.label), 16, MUTED)
		THEME.style_section_heading(step, 18)
		step.autowrap_mode = TextServer.AUTOWRAP_OFF
		_workflow.add_child(step)
		_workflow_labels[String(entry.id)] = step
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	outer.add_child(body)
	var nav := VBoxContainer.new()
	nav.custom_minimum_size.x = 166
	nav.add_theme_constant_override("separation", 8)
	body.add_child(nav)
	for item in [{"id": "base", "label": "Basis erkunden"}, {"id": "personnel", "label": "Personal"}, {"id": "squad", "label": "Trupp &\nAusrüstung"}, {"id": "map", "label": "Sternkarte"}, {"id": "mission", "label": "Einsatz &\nAbflug"}, {"id": "jobs", "label": "Smart Mobile"}]:
		var key: String = String(item.id)
		var button: Button = _button(String(item.label), false)
		button.name = "Navigate_" + key
		button.custom_minimum_size.y = 46
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nav.add_child(button)
		button.pressed.connect(func(): _act("navigate", {"mode": key}))
		button.disabled = key in ["jobs", "map"]
		if button.disabled:
			button.tooltip_text = "Noch nicht verfügbar"
		_nav[key] = button
	var nav_spacer := Control.new()
	nav_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav.add_child(nav_spacer)
	var detail_button: Button = _button("Charakterdetails", false)
	var refuel := _button("Tankservice", false)
	refuel.name = "OpenBaseServices"
	nav.add_child(refuel)
	refuel.pressed.connect(func(): _act("navigate", {"mode": "services"}))
	nav.add_child(detail_button)
	detail_button.pressed.connect(func(): _act("details", {"unit_id": _focused_id}))
	nav.move_child(_nav.jobs,nav.get_child_count()-1)
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
	_job_board = load("res://scripts/meta/singleplayer_job_board_presenter.gd").new()
	_workspace.add_child(_job_board)
	_job_board.call("configure", _owner_screen() if _owner_screen() != null else get_parent())
	_job_board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_job_board.hide()
	_region_map = load("res://scripts/meta/singleplayer_region_map_presenter.gd").new()
	_workspace.add_child(_region_map)
	_region_map.call("configure", _owner_screen() if _owner_screen() != null else get_parent())
	_region_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_region_map.hide()
	_services_view = load("res://scripts/meta/singleplayer_services_presenter.gd").new()
	_services_view.name = "BaseServices"
	_workspace.add_child(_services_view)
	_services_view.call("configure", _singleplayer_snapshot, _singleplayer_request)
	_services_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_services_view.hide()
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
	var title: Label = _label(heading, 23, CREAM)
	THEME.style_section_heading(title, 26)
	content.add_child(title)
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
	_sort_selector = _option(content, "PersonnelSort")
	_sort_selector.item_selected.connect(func(index: int): _act("sort_roster", {"sort_mode": String(_sort_selector.get_item_metadata(index))}))
	_roster_return_target = DRAG_SURFACE.new()
	_roster_return_target.name = "ReturnPersonToRoster"
	_roster_return_target.set("accepted_type", "homebase_unit_card")
	_roster_return_target.custom_minimum_size.y = 34
	_roster_return_target.tooltip_text = "Truppmitglied hierher ziehen, um es aus dem Trupp zu lösen"
	_roster_return_target.add_theme_stylebox_override("panel", _style(PANEL, CYAN))
	content.add_child(_roster_return_target)
	_roster_return_target.add_child(_label("‹ Person zurück ins Personal", 14, CYAN))
	_roster_return_target.connect("payload_dropped", func(data: Dictionary): _act("remove", {"unit_id": String(data.unit_id)}))
	_roster_list = _scroll(content)


func _build_squad() -> void:
	var content: VBoxContainer = _column("squad", "Trupp")
	_team_selector = _option(content, "TeamSelector")
	_team_selector.item_selected.connect(func(index: int): _act("focus_fireteam", {"fireteam_id": String(_team_selector.get_item_metadata(index))}))
	_team_drag_source = DRAG_SURFACE.new()
	_team_drag_source.name = "DragFocusedFireteam"
	_team_drag_source.set("accepted_type", "homebase_unit_card")
	_team_drag_source.tooltip_text = "Person hier zuweisen · Trupp von hier ins Schiff ziehen"
	_team_drag_source.add_theme_stylebox_override("panel", _style(PANEL, CYAN))
	content.add_child(_team_drag_source)
	_team_title = _label("0 / 4", 16, GOLD)
	_team_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team_drag_source.add_child(_team_title)
	_team_drag_source.connect("payload_dropped", func(data: Dictionary): _act("assign", {"unit_id": String(data.unit_id), "fireteam_id": _fireteam_id}))
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
	_squad_craft_selector=_option(content,"SquadCraftSelector")
	_squad_craft_selector.item_selected.connect(func(index:int): _act("craft",{"craft_id":String(_squad_craft_selector.get_item_metadata(index))}))
	_squad_craft_image=_portrait(Vector2(180,110))
	_squad_craft_image.name="SquadCraftPreview"
	_squad_craft_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(_squad_craft_image)
	_squad_craft_caption=_label("",14,MUTED)
	content.add_child(_squad_craft_caption)


func _build_equipment() -> void:
	var content: VBoxContainer = _column("equipment", "Ausrüstung · Fokus")
	var list: VBoxContainer = _scroll(content)
	_identity_row = BoxContainer.new()
	_identity_row.vertical = false
	_identity_row.add_theme_constant_override("separation", 16)
	list.add_child(_identity_row)
	_focused_portrait = _portrait(Vector2(176, 176))
	_focused_portrait.name = "FocusedPortrait"
	_focused_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_focused_portrait.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_focused_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_identity_row.add_child(_focused_portrait)
	var identity_text := VBoxContainer.new()
	identity_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_text.add_theme_constant_override("separation", 10)
	_identity_row.add_child(identity_text)
	_focused_name = _label("Mitglied auswählen", 24, CREAM)
	THEME.style_section_heading(_focused_name, 28)
	_focused_name.max_lines_visible = 2
	_focused_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	identity_text.add_child(_focused_name)
	_focused_role = _label("", 17, MUTED)
	identity_text.add_child(_focused_role)
	_focused_status = _label("", 15, GOLD)
	identity_text.add_child(_focused_status)
	for spec in [{"id": "armor", "label": "Rüstung"}, {"id": "weapon_1", "label": "Primär"}, {"id": "weapon_2", "label": "Sekundär"}]:
		var key: String = String(spec.id)
		var slot: PanelContainer = DRAG_SURFACE.new()
		slot.name = "EquipmentSlot_" + key
		slot.set("accepted_type", "homebase_loadout_item")
		slot.set("equipment_key", key)
		slot.tooltip_text = "Ausrüstung wählen oder passendes Ausrüstungsteil hierher ziehen"
		slot.add_theme_stylebox_override("panel", _style(PANEL, CYAN))
		list.add_child(slot)
		_equipment_slots[key] = slot
		slot.connect("payload_dropped", func(data: Dictionary): _act("loadout", {"unit_id": _focused_id, "key": key, "value": String(data.get("item_id", ""))}))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		slot.add_child(row)
		var field: Label = _label(String(spec.label), 16, MUTED)
		field.custom_minimum_size.x = 76
		field.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(field)
		var selector: OptionButton = _option(row, key.capitalize() + "Selector")
		selector.item_selected.connect(func(index: int): _act("loadout", {"unit_id": _focused_id, "key": key, "value": String(selector.get_item_metadata(index))}))
		slot.call("forward_drag_from", selector)
		_selectors[key] = selector
	_build_equipment_palette(list)
	_inventory_panel=load("res://scripts/ui/components/personnel_inventory_panel.gd").new()
	_inventory_panel.name="PersonnelInventory"
	list.add_child(_inventory_panel)
	_inventory_panel.operation_requested.connect(_act)
	_remove_member = _button("Aus Trupp entfernen", false)
	list.add_child(_remove_member)
	_remove_member.pressed.connect(func(): _act("remove", {"unit_id": _focused_id}))
	_focused_details = _button("Charakter ansehen", false)
	list.add_child(_focused_details)
	_focused_details.pressed.connect(func(): _act("details", {"unit_id": _focused_id}))


func _build_equipment_palette(parent: Control) -> void:
	_equipment_palette_toggle = _button("Ausrüstung ziehen ▸", false)
	_equipment_palette_toggle.name = "EquipmentPaletteToggle"
	_equipment_palette_toggle.custom_minimum_size.y = 36
	_equipment_palette_toggle.tooltip_text = "Ausrüstungsoptionen zum Ziehen öffnen"
	parent.add_child(_equipment_palette_toggle)
	_equipment_palette = VBoxContainer.new()
	_equipment_palette.name = "EquipmentPalette"
	_equipment_palette.visible = false
	parent.add_child(_equipment_palette)
	_equipment_palette_toggle.pressed.connect(func():
		_equipment_palette.visible = not _equipment_palette.visible
		_equipment_palette_toggle.text = "Ausrüstung ziehen ▾" if _equipment_palette.visible else "Ausrüstung ziehen ▸"
		_update_equipment_palette())
	var tabs := HBoxContainer.new()
	_equipment_palette.add_child(tabs)
	for spec: Dictionary in [{"id": "armor", "label": "Rüstung"}, {"id": "weapon_1", "label": "Primär"}, {"id": "weapon_2", "label": "Sekundär"}]:
		var key: String = String(spec.id)
		var button: Button = _button(String(spec.label), false)
		button.custom_minimum_size.y = 32
		button.add_theme_font_size_override("font_size", 14)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(button)
		_equipment_palette_tabs[key] = button
		button.pressed.connect(func():
			_equipment_palette_key = key
			_update_equipment_palette())
	_equipment_palette_flow = HFlowContainer.new()
	_equipment_palette_flow.name = "EquipmentChoices"
	_equipment_palette_flow.add_theme_constant_override("h_separation", 6)
	_equipment_palette_flow.add_theme_constant_override("v_separation", 6)
	_equipment_palette.add_child(_equipment_palette_flow)
	_equipment_palette.add_child(_label("Auf einen passenden Ausrüstungsslot ziehen.", 13, MUTED))


func _update_equipment_palette() -> void:
	if _equipment_palette == null or not _equipment_palette.visible:
		return
	for key in _equipment_palette_tabs:
		(_equipment_palette_tabs[key] as Button).disabled = String(key) == _equipment_palette_key
	var live: Dictionary = {}
	for option: Dictionary in Array(_equipment_palette_options.get(_equipment_palette_key, [])):
		var item_id: String = String(option.get("id", ""))
		if item_id.is_empty():
			continue
		var cache_key: String = _equipment_palette_key + ":" + item_id
		var label: String = String(EQUIPMENT_LABELS.get(item_id, option.get("label", item_id)))
		live[cache_key] = true
		if not _equipment_palette_chips.has(cache_key):
			var chip: PanelContainer = DRAG_SURFACE.new()
			chip.name = "EquipmentChoice_" + _equipment_palette_key + "_" + item_id.validate_node_name()
			chip.custom_minimum_size = Vector2(86, 34)
			chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			chip.add_theme_stylebox_override("panel", _style(Color("17424c"), CYAN))
			_equipment_palette_flow.add_child(chip)
			var caption: Label = _label(label, 14, CREAM)
			caption.autowrap_mode = TextServer.AUTOWRAP_OFF
			caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chip.add_child(caption)
			_equipment_palette_chips[cache_key] = chip
		var source: PanelContainer = _equipment_palette_chips[cache_key]
		source.tooltip_text = label + " auf den passenden Slot ziehen"
		source.set("drag_payload", {"type": "homebase_loadout_item", "key": _equipment_palette_key, "item_id": item_id, "label": label})
	for key in _equipment_palette_chips:
		(_equipment_palette_chips[key] as Control).visible = live.has(key)


func _build_flightdeck() -> void:
	var content: VBoxContainer = _column("flight", "Flugdeck · Einsatz & Abflug")
	var groups := HBoxContainer.new()
	groups.name = "FlightdeckGroups"
	groups.add_theme_constant_override("separation", 16)
	groups.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(groups)
	var mission: VBoxContainer = _flight_group(groups, "Selection")
	var pilot: VBoxContainer = _flight_group(groups, "Readiness")
	var actions: VBoxContainer = _flight_group(groups, "Actions")
	_mission_name = _label("Einsatz", 20, CREAM)
	mission.add_child(_mission_name)
	_mission_selector = _option(mission, "MissionSelector")
	_mission_selector.item_selected.connect(func(index: int): _act("mission", {"mission_id": String(_mission_selector.get_item_metadata(index))}))
	mission.add_child(_label("Schiff", 16, MUTED))
	_craft_drop_target = DRAG_SURFACE.new()
	_craft_drop_target.name = "CraftFireteamDropTarget"
	_craft_drop_target.set("accepted_type", "fob_fireteam_card")
	_craft_drop_target.tooltip_text = "Kompletten Trupp hierher auf das ausgewählte Schiff ziehen"
	mission.add_child(_craft_drop_target)
	_craft_drop_target.connect("payload_dropped", func(data: Dictionary): _act("board", {"fireteam_id": String(data.get("fireteam_id", "")), "craft_id": _craft_id}))
	_craft_selector = _option(_craft_drop_target, "CraftSelector")
	_craft_drop_target.call("forward_drag_from", _craft_selector)
	_craft_selector.item_selected.connect(func(index: int): _act("craft", {"craft_id": String(_craft_selector.get_item_metadata(index))}))
	pilot.add_child(_label("Pilot", 16, MUTED))
	_pilot_selector = _option(pilot, "PilotSelector")
	_pilot_selector.item_selected.connect(func(index: int): _act("pilot", {"unit_id": String(_pilot_selector.get_item_metadata(index)), "craft_id": _craft_id}))
	_craft_status = _label("Kein Schiff verfügbar", 19, THEME.status_color("neutral"))
	pilot.add_child(_craft_status)
	_payload_label = _label("", 16, CREAM)
	pilot.add_child(_payload_label)
	_progress = ProgressBar.new()
	_progress.custom_minimum_size.y = 18
	_progress.show_percentage = false
	pilot.add_child(_progress)
	_board = _button("Boarding starten", false)
	_board.custom_minimum_size.y = 44
	actions.add_child(_board)
	_board.pressed.connect(func(): _act("board", {"fireteam_id": _fireteam_id, "craft_id": _craft_id}))
	_unboard = _button("Trupp zurückholen", false)
	actions.add_child(_unboard)
	_unboard.pressed.connect(func(): _act("unboard", {"fireteam_id": _fireteam_id, "craft_id": _craft_id}))
	_start = _button("Einsatz starten  ›", true)
	_start.name = "StartMission"
	_start.custom_minimum_size.y = 48
	actions.add_child(_start)
	_start.pressed.connect(func(): _act("start", {"craft_id": _craft_id}))
	_launch_reason = _label("Abflugbereitschaft wird geprüft …", 13, GOLD)
	_launch_reason.name = "LaunchReadiness"
	_launch_reason.custom_minimum_size.y = 32
	actions.add_child(_launch_reason)
	_build_reference_stage()


func _flight_group(parent: Control, id: String) -> VBoxContainer:
	var group := VBoxContainer.new()
	group.name = id
	group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group.add_theme_constant_override("separation", 6)
	parent.add_child(group)
	return group


func _build_reference_stage() -> void:
	_reference_stage = PanelContainer.new()
	_reference_stage.name = "ReferenceBaseStage"
	_reference_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reference_stage.clip_contents = true
	_reference_stage.add_theme_stylebox_override("panel", _style(Color("0a2935"), Color("2e7b8a")))
	_reference_stage.set_meta("visual_only", true)
	_reference_stage.set_meta("source_resource", "res://scripts/meta/ship_context_backdrop.gd")
	_reference_stage.set_meta("image_status", "runtime_snapshot_projection")
	_workspace.add_child(_reference_stage)
	_stage_content = Control.new()
	_stage_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reference_stage.add_child(_stage_content)
	_ship_backdrop = SHIP_BACKDROP_SCRIPT.new()
	_ship_backdrop.name = "ShipContextBackdrop"
	_stage_content.add_child(_ship_backdrop)
	_ship_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage_name = _label("Heimatbasis", 28, CREAM)
	_stage_name.name = "SelectedCraftName"
	THEME.style_section_heading(_stage_name, 30)
	_stage_content.add_child(_stage_name)
	_craft_image = _portrait(Vector2.ZERO)
	_craft_image.name = "SelectedCraftPreview"
	_craft_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stage_content.add_child(_craft_image)
	_stage_caption = _label("Schiffsposition wird gelesen …", 15, CREAM)
	_stage_caption.name = "StageCaption"
	_stage_content.add_child(_stage_caption)
	_reference_stage.resized.connect(_layout_reference_stage)
	_stage_content.resized.connect(_layout_reference_stage)


func _layout_reference_stage() -> void:
	if _stage_content == null or _craft_image == null:
		return
	var area: Vector2 = _stage_content.size
	_stage_name.position = Vector2(16, 12)
	_stage_name.size = Vector2(maxf(area.x - 32, 0), 42)
	var preview_width: float = minf(maxf(area.x - 48, 0), 320.0)
	var preview_height: float = maxf(minf(area.y * 0.55, area.y - 92), 0.0)
	_craft_image.position = Vector2((area.x - preview_width) * 0.5, 58 + maxf((area.y - 84 - preview_height) * 0.5, 0.0))
	_craft_image.size = Vector2(preview_width, preview_height)
	_stage_caption.position = Vector2(16, maxf(area.y - 48, 0))
	_stage_caption.size = Vector2(maxf(area.x - 32, 0), 42)


func _person_row(parent: Control, id: String, with_assign: bool) -> Dictionary:
	var panel: PanelContainer = DRAG_SURFACE.new()
	panel.name = "Person_" + id.validate_node_name()
	panel.custom_minimum_size.y = 112
	panel.add_theme_stylebox_override("panel", _style(Color("163743"), Color("28515e")))
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_theme_constant_override("separation", 9)
	panel.add_child(row)
	var portrait: TextureRect = _portrait(Vector2(96, 96))
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_PASS
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
	panel.call("forward_drag_from", focus)
	focus.gui_input.connect(func(event: InputEvent): _person_input(event, panel))
	panel.gui_input.connect(func(event: InputEvent): _person_input(event, panel, true))
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
	var badge := TextureRect.new()
	badge.custom_minimum_size = Vector2(20, 20)
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(badge)
	var action: Button
	if with_assign:
		action = _button("+", false)
		action.custom_minimum_size = Vector2(40, 42)
		action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(action)
	if not with_assign:
		panel.set("accepted_type", "homebase_unit_card")
		panel.connect("payload_dropped", func(data: Dictionary): _act("assign", {"unit_id": String(data.unit_id), "fireteam_id": _fireteam_id}))
	return {"root": panel, "portrait": portrait, "focus": focus, "role": role, "status": status, "badge": badge, "assign": action, "unit_id": ""}


func _person_input(event: InputEvent, panel: PanelContainer, allow_single: bool = false) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var id: String = String(Dictionary(panel.get("drag_payload")).get("unit_id", ""))
		if not id.is_empty() and event.double_click:
			_act("details", {"unit_id": id})
			panel.accept_event()
		elif not id.is_empty() and allow_single:
			_act("focus_unit", {"unit_id": id})


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
	var campaign_ready: bool = not Dictionary(snapshot.get("singleplayer", {})).is_empty()
	for key in ["jobs", "map"]:
		_nav[key].disabled = not campaign_ready
		_nav[key].tooltip_text = "" if campaign_ready else "Noch nicht verfügbar"
	if _job_board != null:
		_job_board.visible = _mode == "jobs"
		if _job_board.visible:
			_job_board.call("refresh")
	if _region_map != null:
		_region_map.visible = _mode == "map"
		if _region_map.visible:
			_region_map.call("refresh")
	if _services_view != null:
		_services_view.visible = _mode == "services"
		if _services_view.visible:
			_services_view.call("refresh", snapshot.get("singleplayer", {}))
	var focused: Dictionary = Dictionary(snapshot.get("focused_unit", {}))
	_focused_id = String(focused.get("id", ""))
	_fireteam_id = String(snapshot.get("focused_fireteam_id", ""))
	if changed_mode or _refresh_count == 1:
		for key in _nav:
			var button: Button = _nav[key]
			button.add_theme_stylebox_override("normal", _style(Color("15505d") if key == _mode else PANEL, CYAN if key == _mode else Color("2b5361")))
		for key in _workflow_labels:
			(_workflow_labels[key] as Label).add_theme_color_override("font_color", GOLD if key == _mode else MUTED)
		_workflow.visible = _mode != "base"
	_set_options(_sort_selector, Array(snapshot.get("roster_sort_options", [])), String(snapshot.get("roster_sort_mode", "name_asc")))
	_update_roster(Array(snapshot.get("roster", [])))
	var team: Dictionary = Dictionary(snapshot.get("focused_fireteam", {}))
	_update_team(team, Array(snapshot.get("fireteams", [])))
	_update_equipment(focused, Dictionary(snapshot.get("loadout_options", {})))
	var singleplayer: Dictionary=snapshot.get("singleplayer",{})
	var inventory: Dictionary=Dictionary(singleplayer.get("supply",{})).get("inventory",{})
	_inventory_panel.visible=not inventory.is_empty()
	for slot in _equipment_slots.values(): slot.visible=inventory.is_empty()
	_equipment_palette_toggle.visible=inventory.is_empty()
	if not inventory.is_empty():
		_equipment_palette.visible=false
		var view: Dictionary = screen.call("get_personnel_inventory_view", _focused_id, snapshot)
		_inventory_panel.update_snapshot(view.inventory, view.unit, view.craft_id, view.accessible, view.equipment_allowed)
		_inventory_panel.update_rest_snapshot(view.person)
	if bool(screen.get("_character_sheet_open")):
		screen.call("_update_character_inventory", snapshot)
	_update_flight(Dictionary(snapshot.get("selected_craft", {})), snapshot)
	if changed_mode:
		_layout_columns()
	_update_base_surface(snapshot)


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
		if (item.root as Control).get_index() != live.size() - 1:
			_roster_list.move_child(item.root, live.size() - 1)
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
	var panel: PanelContainer = row.root
	var wide: bool = _workspace.size.x > 2200.0
	var compact_slot: bool = row.assign == null and size.x < 1600.0
	var portrait_edge: float = 52.0 if row.assign != null else (64.0 if compact_slot else 72.0)
	var style_signature: String = "%s:%s" % [wide, compact_slot]
	if String(panel.get_meta("operations_row_style", "")) != style_signature:
		portrait.custom_minimum_size = Vector2(portrait_edge, portrait_edge)
		(row.focus as Button).add_theme_font_size_override("font_size", 17 if compact_slot else (23 if wide else 19))
		(row.role as Label).add_theme_font_size_override("font_size", 14 if compact_slot else (17 if wide else 15))
		(row.status as Label).add_theme_font_size_override("font_size", 13 if compact_slot else (16 if wide else 14))
		panel.set_meta("operations_row_style", style_signature)
	portrait.visible = not unit.is_empty()
	_set_portrait(portrait, unit)
	var focus: Button = row.focus
	focus.text = String(unit.get("name", "Freier Platz"))
	focus.tooltip_text = focus.text
	focus.disabled = unit.is_empty()
	var role: Label = row.role
	role.text = String(unit.get("role", "Personal zuweisen"))
	role.tooltip_text = role.text
	var status: Label = row.status
	var loadout: Dictionary = Dictionary(unit.get("loadout", {}))
	status.text = "%s · %s / %s" % [String(unit.get("status", "")), String(EQUIPMENT_LABELS.get(String(loadout.get("armor","")),"")), String(EQUIPMENT_LABELS.get(String(loadout.get("weapon_1","")),""))] if not unit.is_empty() else ""
	status.tooltip_text = status.text
	panel.tooltip_text = "%s · %s" % [String(unit.get("name", "Freier Platz")), status.text]
	panel.custom_minimum_size.y = 58.0 if unit.is_empty() else 80.0
	panel.set("drag_payload", {"type": "homebase_unit_card", "unit_id": String(unit.get("id", "")), "source_context": "operations", "label": String(unit.get("name", ""))} if not unit.is_empty() else {})
	var badges: Array = Array(unit.get("badges", []))
	var badge: TextureRect = row.badge
	badge.visible = not badges.is_empty()
	if not badges.is_empty():
		var badge_data: Dictionary = Dictionary(badges[0])
		_set_texture(badge, BADGES.get_badge_asset_path(String(badge_data.get("badge_id", ""))))
		badge.tooltip_text = BADGES.format_badge_tooltip(badge_data)
	var selected: bool = not unit.is_empty() and String(unit.get("id", "")) == _focused_id
	if not panel.has_meta("operations_selected") or bool(panel.get_meta("operations_selected")) != selected:
		panel.add_theme_stylebox_override("panel", _style(Color("173d49"), GOLD if selected else Color("28515e")))
		panel.set_meta("operations_selected", selected)


func _update_team(team: Dictionary, teams: Array) -> void:
	_set_options(_team_selector, teams, _fireteam_id)
	var members: Array = Array(team.get("members", []))
	_team_title.text = "%d / 4 Mitglieder" % members.size()
	_team_drag_source.set("drag_payload", {"type": "fob_fireteam_card", "fireteam_id": _fireteam_id, "label": String(team.get("label", _fireteam_id))} if not team.is_empty() else {})
	for index in range(4):
		var unit: Dictionary = Dictionary(members[index]) if index < members.size() else {}
		_slots[index]["unit_id"] = String(unit.get("id", ""))
		_fill_person(_slots[index], unit)
	_team_note.text = "Trupp an Bord · zum Bearbeiten zurückholen" if bool(team.get("busy", false)) else "Person auf einen Platz ziehen · Trupp ins Schiff ziehen."
	if members.size() > 4:
		_team_note.text = "%d weitere Mitglieder in den Charakterdetails/Werkzeugen." % (members.size() - 4)


func _update_equipment(unit: Dictionary, options: Dictionary) -> void:
	_equipment_palette_options = options.duplicate(true)
	_set_portrait(_focused_portrait, unit)
	_focused_name.text = String(unit.get("name", "Mitglied auswählen"))
	_focused_role.text = String(unit.get("role", ""))
	_focused_status.text = String(unit.get("status", ""))
	var loadout: Dictionary = Dictionary(unit.get("loadout", {}))
	for key in _selectors:
		var selector: OptionButton = _selectors[key]
		_set_options(selector, Array(options.get(key, [])), String(loadout.get(key, "")))
		selector.disabled = not bool(unit.get("can_edit", false))
		(_equipment_slots[key] as PanelContainer).set("drag_payload", {"type": "homebase_loadout_item", "key": key, "item_id": String(loadout.get(key, "")), "label": "%s: %s" % [key, String(loadout.get(key, ""))]} if not unit.is_empty() else {})
	_remove_member.disabled = not bool(unit.get("can_remove", false))
	_focused_details.disabled = unit.is_empty()
	_update_equipment_palette()


func _update_flight(craft: Dictionary, snapshot: Dictionary) -> void:
	_craft_id = String(craft.get("id", ""))
	_set_options(_craft_selector, Array(snapshot.get("crafts", [])), _craft_id)
	_set_options(_squad_craft_selector,Array(snapshot.get("crafts",[])),_craft_id)
	_set_texture(_squad_craft_image,String(craft.get("texture_path","")))
	_squad_craft_caption.text="%s · Pilot: %s\n%d Kräfte · %s" % [String(craft.get("name","")),String(craft.get("pilot_name","Nicht zugewiesen")),int(craft.get("passenger_count",0)),String(craft.get("status",""))]
	_set_options(_mission_selector, Array(snapshot.get("missions", [])), String(snapshot.get("mission_id", "")))
	_set_options(_pilot_selector, Array(craft.get("pilot_options", [])), String(craft.get("pilot_id", "")))
	_pilot_selector.disabled = bool(craft.get("busy", false)) or craft.is_empty()
	_set_texture(_craft_image, String(craft.get("texture_path", "")))
	_stage_name.text = String(craft.get("name", "Heimatbasis"))
	_craft_status.text = String(craft.get("status", "Kein Schiff verfügbar"))
	var status_color: Color = THEME.status_color(_craft_status_key(craft))
	if _craft_status.get_theme_color("font_color") != status_color:
		_craft_status.add_theme_color_override("font_color", status_color)
	_payload_label.text = "%d Kräfte an Bord / im Boarding" % int(craft.get("passenger_count", 0))
	_progress.value = float(craft.get("progress", 0.0))
	_board.disabled = not bool(craft.get("can_board", false))
	_unboard.disabled = not bool(craft.get("can_unboard", false))
	_unboard.visible = bool(craft.get("has_payload", false))
	_start.disabled = not bool(craft.get("can_start", false))
	_start.tooltip_text = String(craft.get("next_step", ""))
	var space_route: bool = bool(Dictionary(Dictionary(snapshot.get("singleplayer", {})).get("space_travel", {})).get("enabled", false))
	var launch_message: String = String(craft.get("next_step", "Schiff vorbereiten"))
	if space_route:
		var readiness: Dictionary = Dictionary(Dictionary(snapshot.get("singleplayer", {})).get("space_launch_readiness_by_craft_id", {})).get(_craft_id, {})
		_start.disabled = _start.disabled or not bool(readiness.get("ok", false))
		if not bool(readiness.get("ok", false)):
			launch_message = String(readiness.get("message", "Abflugbereitschaft wird geprüft …"))
		elif not _start.disabled:
			launch_message = "Bereit zum Abheben in den Mondorbit."
	_launch_reason.text = launch_message
	_launch_reason.add_theme_color_override("font_color", GOLD if _start.disabled else CYAN)
	_start.tooltip_text = launch_message
	_start.text = "Abheben · Mondorbit  ›" if space_route else "Einsatz starten  ›"
	# A location catalogue also exists in ordinary Skirmish. Only the active
	# orbital-route projection changes its selector and launch requirements.
	_mission_selector.visible = not space_route
	_mission_name.text = "Mondbasis → Mondorbit\nZielort nach dem Quantum-Sprung im Planetenorbit wählen." if space_route else "Einsatz"


func get_launch_action_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for control in [_start, _board, _unboard, _launch_reason]+_nav.values():
		if control != null and control.is_visible_in_tree():
			result.append(control.get_global_rect())
	return result


static func _craft_status_key(craft: Dictionary) -> String:
	# Presentation only: use the existing snapshot gates, never localized text.
	if craft.is_empty():
		return "neutral"
	if bool(craft.get("busy", false)):
		return "transit"
	if String(craft.get("pilot_id", "")).is_empty():
		return "blocked"
	if bool(craft.get("can_start", false)):
		return "ready"
	if bool(craft.get("has_payload", false)) and float(craft.get("progress", 0.0)) < 100.0:
		return "transit"
	return "pending"


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
	for option_variant in options:
		var option: Dictionary = Dictionary(option_variant)
		var id: String = String(option.get("id", ""))
		var label: String = String(option.get("label", option.get("name", "")))
		if _selectors.values().has(selector):
			label = String(EQUIPMENT_LABELS.get(id, label))
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
	var gap: float = 12.0
	var narrow: bool = available.x < 1450.0 and size.x < 1600.0
	var rects: Dictionary = {}
	var scene_rect := Rect2()
	if _mode == "personnel":
		var roster_width: float = clampf(available.x * 0.25, 280.0, 380.0)
		var equipment_width: float = available.x - roster_width - gap
		rects["roster"] = Rect2(0, 0, roster_width, available.y)
		rects["equipment"] = Rect2(roster_width + gap, 0, equipment_width, available.y)
	elif _mode in ["base", "jobs", "map", "services"]:
		pass
	elif _mode == "squad":
		var roster_width: float = clampf(available.x*0.18,280.0,320.0)
		var squad_width: float = clampf(available.x*0.20,250.0,320.0)
		rects["roster"] = Rect2(0,0,roster_width,available.y)
		rects["squad"] = Rect2(roster_width+gap,0,squad_width,available.y)
		var right_x: float=roster_width+squad_width+gap*2
		rects["equipment"] = Rect2(right_x,0,maxf(available.x-right_x,280.0),available.y)
	else:
		var start_x: float = 0.0
		if _mode != "mission":
			var roster_width: float = clampf(available.x * 0.20, 304.0, 560.0)
			rects["roster"] = Rect2(start_x, 0, roster_width, available.y)
			start_x += roster_width + gap
		var squad_width: float = clampf(available.x * (0.25 if narrow else 0.18), 260.0 if narrow else 280.0, 480.0)
		rects["squad"] = Rect2(start_x, 0, squad_width, available.y)
		start_x += squad_width + gap
		var right_width: float = maxf(available.x - start_x, 0.0)
		var footer_height: float = minf(248.0, available.y)
		var top_height: float = maxf(available.y - footer_height - gap, 0.0)
		var equipment_width: float = clampf(right_width * 0.43, 300.0, 620.0)
		rects["equipment"] = Rect2(start_x, 0, equipment_width, top_height)
		scene_rect = Rect2(start_x + equipment_width + gap, 0, maxf(right_width - equipment_width - gap, 0.0), top_height)
		rects["flight"] = Rect2(start_x, top_height + gap, right_width, footer_height)
	for key in _columns:
		var panel: Control = _columns[key]
		panel.visible = rects.has(key)
		if panel.visible:
			var rect: Rect2 = rects[key]
			panel.position = rect.position
			panel.size = rect.size
	_preview_layout_rect = scene_rect
	if _reference_stage != null:
		_reference_stage.visible = scene_rect.size.x > 0 and scene_rect.size.y > 0
		_reference_stage.position = scene_rect.position
		_reference_stage.size = scene_rect.size
		_layout_reference_stage()
	_layout_base_surface()
	if _identity_row != null:
		var equipment_panel: Control = _columns.equipment
		_identity_row.vertical = equipment_panel.size.x < 310.0
		var portrait_edge: float = 224.0 if available.x > 2200.0 else (112.0 if narrow else 176.0)
		_focused_portrait.custom_minimum_size = Vector2(portrait_edge, portrait_edge)
		var identity_size: int = 30 if available.x > 2200.0 else (23 if narrow else 26)
		if _focused_name.get_theme_font_size("font_size") != identity_size:
			_focused_name.add_theme_font_size_override("font_size", identity_size)


func _terminal_requested(id: String) -> void:
	var target: String = "personnel" if id == "personnel" else ("squad" if id == "team" else ("jobs" if id == "jobs" else ("services" if id == "refuel" else "mission")))
	_act("navigate", {"mode": target})


func _singleplayer_snapshot() -> Dictionary:
	var screen: Control = _owner_screen()
	return Dictionary(screen.call("get_operations_snapshot").get("singleplayer", {})) if screen != null else {}


func _singleplayer_request(operation: String, payload: Dictionary = {}) -> Dictionary:
	var screen: Control = _owner_screen()
	return screen.call("request_operation", operation, payload) if screen != null else {"ok": false}


func _update_base_surface(snapshot: Dictionary) -> void:
	if _base == null:
		return
	var screen: Control = _owner_screen()
	if screen != null and screen.has_method("get_base_personnel_runtime"):
		_base.call("configure_personnel_runtime", screen.call("get_base_personnel_runtime"), Callable(screen, "request_operation"))
	var runtime: Dictionary = snapshot.get("singleplayer", {})
	if runtime.is_empty():
		_base.call("set_active", _mode == "base" and is_visible_in_tree())
		return
	_base.call("set_transport_snapshot", runtime)
	_ship_preview_context = _project_ship_context(runtime)
	var caption: String = String(_ship_preview_context.get("caption", ""))
	_stage_caption.text = caption
	_ship_backdrop.call("set_context", _ship_preview_context)
	_craft_image.visible = String(_ship_preview_context.get("kind", "")) == "space"
	_layout_base_surface()


func _layout_base_surface() -> void:
	if _base == null or _reference_stage == null:
		return
	# PanelContainer clamps an empty rectangle to its 16x12 style minimum.
	# Only the actual computed workspace rectangle authorizes a 3D preview.
	var has_preview: bool = _mode in ["squad", "mission"] and _preview_layout_rect.size.x >= 32.0 and _preview_layout_rect.size.y >= 32.0 and is_visible_in_tree()
	if _mode == "base" and is_visible_in_tree():
		_reference_stage.hide()
		_base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_base.call("set_active", true)
	elif has_preview and String(_ship_preview_context.get("kind", "")) == "base_pad":
		_base.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_base.position = _preview_layout_rect.position
		_base.size = _preview_layout_rect.size
		_reference_stage.hide()
		_base.call("set_pad_preview", true, _craft_id)
	else:
		_base.call("set_active", false)
		_reference_stage.visible = has_preview


func _project_ship_context(runtime: Dictionary) -> Dictionary:
	var craft: Dictionary = {}
	for entry in Array(runtime.get("crafts", [])):
		if String(entry.get("craft_id", "")) == _craft_id:
			craft = entry
			break
	var travel: Dictionary = runtime.get("space_travel", {})
	var phase: String = String(travel.get("phase", "grounded"))
	if String(travel.get("craft_id", "")) == _craft_id and phase in ["orbit", "quantum", "stopped", "approach"]:
		var context: Dictionary = travel.duplicate(true)
		context["kind"] = "space"
		var orbit: String = String(travel.get("orbit_id", ""))
		match phase:
			"orbit": context["caption"] = "Im Weltraum · " + ("Mondorbit" if orbit == "moon_orbit" else "Planetenorbit")
			"quantum": context["caption"] = "Quantum-Sprung → %s · %d %%" % ["Mondorbit" if String(travel.get("target_orbit_id", "")) == "moon_orbit" else "Planetenorbit", roundi(float(travel.get("progress", 0.0)) * 100)]
			"stopped": context["caption"] = "Im Weltraum · Sprung abgebrochen, Position gehalten"
			"approach": context["caption"] = "Ortsanflug · Planetenorbit wird verlassen"
		return context
	if not Dictionary(craft.get("pad_visual",{})).is_empty():
		return {"kind":"base_pad","phase":String(craft.pad_visual.phase),"craft_id":_craft_id,"landing_pad_id":String(craft.get("landing_pad_id","")),"caption":"Mondbasis · An-/Abflug am tatsächlichen Landepad"}
	if not craft.is_empty() and bool(craft.get("visible_on_pad", false)) and String(craft.get("location_id", "")) == "homebase":
		return {"kind": "base_pad", "phase": "grounded", "craft_id": _craft_id, "landing_pad_id": String(craft.get("landing_pad_id", "")), "caption": "Mondbasis · Schiff auf seinem Landepad"}
	var location_id: String = String(craft.get("location_id", ""))
	var location: Dictionary = Dictionary(Dictionary(runtime.get("campaign", {})).get("locations", {})).get(location_id, {})
	return {"kind": "location", "phase": phase if String(travel.get("craft_id", "")) == _craft_id else "", "craft_id": _craft_id, "caption": "Schiff am Zielort · " + String(location.get("name", "Position wird bestaetigt"))}


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
		"reference_stage_visible": _reference_stage != null and _reference_stage.is_visible_in_tree(),
		"reference_stage_rect": _reference_stage.get_global_rect() if _reference_stage != null else Rect2(),
		"reference_stage_source": "res://scripts/meta/ship_context_backdrop.gd",
		"reference_stage_kind": String(_ship_preview_context.get("kind", "unavailable")),
		"ship_preview_phase": String(_ship_preview_context.get("phase", "")),
		"ship_preview_caption": _stage_caption.text,
		"ship_preview_visible": (_base.is_visible_in_tree() and _mode != "base") or _reference_stage.is_visible_in_tree(),
		"ship_preview_rect": _base.get_global_rect() if _base.is_visible_in_tree() and _mode != "base" else _reference_stage.get_global_rect(),
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
