extends PanelContainer
## Read-only system map. Requests never move ships or load missions locally.
const APP_THEME = preload("res://scripts/ui/smart_mobile_theme.gd")
const DISPLAY = preload("res://scripts/mission/campaign_display_catalog.gd")
const NAVIGATION = preload("res://scripts/ui/star_map_navigation_tree.gd")
const CANVAS = preload("res://scripts/ui/star_map_canvas.gd")
const ORBIT_CANVAS = preload("res://scripts/ui/orbit_area_canvas.gd")
const WING_PANEL = preload("res://scripts/ui/space_wing_panel.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const SERVICE_ROUTE_PROJECTION = preload("res://scripts/ui/polisa_service_route_projection.gd")
const TANKER_PANEL = preload("res://scripts/ui/emergency_tanker_panel.gd")
## Klick auf einen Orbitmarker merkt das Ziel nur vor (orbit_previewed); erst "Start" fliegt los und sendet orbit_requested.
signal orbit_previewed(orbit_id: String, marker_id: String)
signal orbit_requested(orbit_id: String, marker_id: String)
var _provider: Callable
var _commands: Callable
var _area_provider: Callable
var _orbit_canvas: Control
var _orbit_button: Button
var _system_button: Button
var _orbit_center: Button
var _pending_jump: Dictionary = {}
var _course_box: VBoxContainer
var _course_text: Label
var _course_start: Button
var _mode_row: HBoxContainer
var _mode_auto: Button
var _mode_manual: Button
var _course_start_ok := true
var _open_orbit_on_arrival := false
var _outbound_hint_key := ""
var _arrival_saw_quantum := false
var _arrival_attempts := 0
var _arrival_target: Dictionary = {}
var _station_dock: Button
var _orbit_craft_id := ""
var _orbit_visible := false
var _orbit_availability_signature := ""
var _move_sequence := 0
var _move_session := ""
var _runtime: Dictionary = {}
var _elapsed := 0.0
var _built := false
var _canvas: Control
var _status: Label
var _selection: Label
var _job_guidance: Label
var _fuel_help: Label
var _show_fuel_help := false
var _fuel_toggle: Button
var _fuel_pinned := false
var _tanker_panel: VBoxContainer
var _tanker_view_provider: Callable
var _boundary: Label
var _error: Label
var _progress: ProgressBar
var _abort: Button
var _approach: Button
var _land: Button
var _close: Button
var _view_homebase: Button
var _destination_ids: PackedStringArray = []
var _fleet_selector: OptionButton
var _wing_panel
var _visit_list: VBoxContainer
var _visit_buttons: Dictionary={}
var _details: PanelContainer
var _navigation: Tree
var _navigation_toggle: Button
var _map_column: VBoxContainer
var _destination_picture: TextureRect
var _picture_location := ""
var _destination_heading: Label

## tanker_view_provider (optional): rein lesender Zugang zur Auskunft des Nottankdienstes, Aufruf mit der Schiffskennung
## (craft_id) -> Dictionary. Ohne ihn (eingebettete Karte, Test-Stubs) bleibt das Tankerfeld verborgen und fragt nichts.
func configure(snapshot_provider: Callable, command_handler: Callable, area_provider: Callable = Callable(), tanker_view_provider: Callable = Callable()) -> void:
	_provider = snapshot_provider
	_commands = command_handler
	_area_provider = area_provider
	_tanker_view_provider = tanker_view_provider
	if not _built:
		_build()
	else:
		_wing_panel.configure(_provider, _commands)
	refresh()

func _process(delta: float) -> void:
	if not _built or not is_visible_in_tree():
		return
	_elapsed += delta
	if _elapsed >= 0.1:
		_elapsed = 0.0
		if _orbit_visible: _refresh_orbit_projection()
		else: refresh()

func cancel_modal_input() -> void:
	_show_fuel_help = false
	_update_fuel_help()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ALT and not event.echo:
		_show_fuel_help = event.pressed and is_visible_in_tree()
		_update_fuel_help()
	elif event is InputEventKey and event.pressed and not event.echo and not _pending_jump.is_empty() and is_visible_in_tree():
		# Vorgemerkter Kurs: Esc verwirft ihn, Enter startet ihn. Ein offenes Spielmenue behaelt beide Tasten.
		# Reihenfolge: der Autoload GlobalEscapeMenu nimmt Esc ebenfalls schon in _input (global_escape_menu.gd:138);
		# _input laeuft rueckwaerts durch den Baum, die Karte (spaeter im Baum als der Autoload) kommt also zuerst.
		if _game_menu_open():
			return
		if event.keycode == KEY_ESCAPE:
			_discard_preview()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER] and _enter_means_start():
			_start_pending()
			get_viewport().set_input_as_handled()

func _game_menu_open() -> bool:
	var tree := get_tree()
	var menu: Node = tree.root.get_node_or_null("GlobalEscapeMenu") if tree != null else null
	return menu != null and menu.has_method("is_overlay_open") and bool(menu.call("is_overlay_open"))

## Enter gilt nur dann als "Start", wenn kein anderes Bedienelement den Fokus hat (Textfeld, Baum, anderer Knopf).
func _enter_means_start() -> bool:
	var focus: Control = get_viewport().gui_get_focus_owner()
	if focus == null or focus == _course_start:
		return true
	return not (focus is LineEdit or focus is TextEdit or focus is Tree or focus is BaseButton)

func _build() -> void:
	_built = true
	name = "StarMapScreen"
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = APP_THEME.get_theme()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("070d15")
	style.border_color = Color("243c4b")
	style.set_border_width_all(1)
	add_theme_stylebox_override("panel", style)
	var scroll := ScrollContainer.new()
	scroll.name = "MapScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "Content"
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := _label("KURSBUCH  /  STERNKARTE", 24)
	title.add_theme_font_override("font", APP_THEME.HEADING)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	_navigation_toggle = _button("ToggleSystemTree", "Systembaum", func(): pass)
	_navigation_toggle.toggle_mode = true
	_navigation_toggle.toggled.connect(func(_pressed: bool): _layout_details())
	heading.add_child(_navigation_toggle)
	_close = _button("CloseStarMap", "Abflug zur Sternkarte vorbereiten", _open_operations)
	heading.add_child(_close)
	_view_homebase = _button("ViewHomebase", "Basis ansehen", func(): _send("open_location_view", {"location_id":"homebase"}))
	heading.add_child(_view_homebase)
	var system_caption := _label("SYSTEM: " + DISPLAY.SYSTEM_NAME, 16, APP_THEME.MUTED)
	system_caption.name = "SystemCaption"
	system_caption.tooltip_text = "Baum: Orte ansehen oder Ziel wählen. Kartenmarker: Kurs ansehen, dann Start. Doppelklick zoomt auf Körper oder Ort."
	column.add_child(system_caption)
	var body := HBoxContainer.new()
	body.name = "SystemAndDetails"
	body.add_theme_constant_override("separation", 8)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	_navigation = NAVIGATION.new()
	_navigation.custom_minimum_size = Vector2(216, 300)
	_navigation.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_navigation.body_focused.connect(_focus_body)
	_navigation.location_requested.connect(_select)
	_navigation.location_inspection_requested.connect(func(id: String): _send("inspect_location", {"location_id":id}))
	_navigation.orbit_inspection_requested.connect(func(body_id: String, orbit_id: String): _send("inspect_orbit", {"body_id":body_id, "orbit_id":orbit_id}))
	body.add_child(_navigation)
	var system_column := VBoxContainer.new()
	_map_column = system_column
	system_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	system_column.add_theme_constant_override("separation", 6)
	body.add_child(system_column)
	var map_views := HBoxContainer.new()
	map_views.name = "SpaceMapViews"
	system_column.add_child(map_views)
	_system_button = _button("SystemView", "System", _show_system_view)
	map_views.add_child(_system_button)
	_orbit_button = _button("OrbitView", "Orbit ansehen", _show_orbit_view)
	_orbit_button.disabled = true
	_orbit_button.tooltip_text = "Schiff explizit auswählen; benötigt einen aktiven lokalen Orbitbereich."
	map_views.add_child(_orbit_button)
	_orbit_center = _button("OrbitRecenter", "Schiff zentrieren", func(): _orbit_canvas.call("recenter_selected"))
	_orbit_center.hide()
	map_views.add_child(_orbit_center)
	_station_dock = _button("BeginStationDock", "Polisa andocken", _begin_station_dock)
	_station_dock.hide()
	_station_dock.disabled = true
	_station_dock.tooltip_text = "Dockauftrag senden; Gate, Besatzung und Besuch werden vom Spiel geprueft."
	map_views.add_child(_station_dock)
	visibility_changed.connect(_refresh_station_dock_button)
	# Wieder sichtbar: sofort den Stand lesen (nicht erst nach dem naechsten 0,1-s-Takt), damit z. B. die Ankunft nicht verpasst wird.
	visibility_changed.connect(func(): if is_visible_in_tree(): refresh())
	_move_session = "%d:%d" % [get_instance_id(),Time.get_ticks_usec()]
	_canvas = CANVAS.new()
	_canvas.name = "SystemMap"
	_canvas.custom_minimum_size.x = 350
	_canvas.clip_contents = true
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.orbit_previewed.connect(_preview_jump)
	_canvas.preview_cleared.connect(_discard_preview)
	_canvas.location_selected.connect(_select)
	_canvas.body_selected.connect(func(id: String): _navigation.focus_body(id))
	_canvas.craft_selected.connect(_on_map_craft_selected)
	_canvas.crafts_box_selected.connect(func(ids: Array, additive: bool): _wing_panel.select_for_crafts(ids, additive))
	system_column.add_child(_canvas)
	_orbit_canvas = ORBIT_CANVAS.new()
	_orbit_canvas.name = "LocalOrbitMap"
	_orbit_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_orbit_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_orbit_canvas.move_requested.connect(_on_orbit_move_requested)
	system_column.add_child(_orbit_canvas)
	_orbit_canvas.hide()
	_details = PanelContainer.new()
	_details.name = "DetailsPanel"
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color("0c1721")
	detail_style.border_color = Color("284754")
	detail_style.set_border_width_all(1)
	_details.add_theme_stylebox_override("panel", detail_style)
	body.add_child(_details)
	# Navigation left, native map centre, destination readout right.
	var detail_scroll := ScrollContainer.new()
	detail_scroll.name = "DetailsScroll"
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_details.add_child(detail_scroll)
	var inset := MarginContainer.new()
	inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "top", "right", "bottom"]:
		inset.add_theme_constant_override("margin_" + side, 8)
	detail_scroll.add_child(inset)
	var information := VBoxContainer.new()
	information.name = "DestinationInformation"
	information.add_theme_constant_override("separation", 6)
	inset.add_child(information)
	_fleet_selector=OptionButton.new()
	_fleet_selector.name="FleetCraftSelector"
	information.add_child(_fleet_selector)
	_fleet_selector.item_selected.connect(_on_fleet_craft_selected)
	_visit_list=VBoxContainer.new()
	_visit_list.name="LoadedLocations"
	_destination_heading = _label("ZIEL & ANFLUG", 21, Color("b4dae8"))
	_destination_heading.add_theme_font_override("font", APP_THEME.HEADING)
	information.add_child(_destination_heading)
	_destination_picture = TextureRect.new()
	_destination_picture.name = "DestinationPanorama"
	_destination_picture.custom_minimum_size.y = 124
	_destination_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_destination_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_destination_picture.tooltip_text = "Gebietsillustration"
	information.add_child(_destination_picture)
	_job_guidance = _label("", 14, Color("f2ca86"))
	_job_guidance.name = "AcceptedJobGuidance"
	information.add_child(_job_guidance)
	_fuel_toggle = _button("FuelReachabilityToggle", "Treibstoff & Reichweite", func(): pass)
	_fuel_toggle.toggle_mode = true
	_fuel_toggle.tooltip_text = "Treibstoff je Etappe anzeigen: Abheben, Sprung, Anflug und Ortsabflug buchen je ihren Anteil. Alt halten zeigt dieselbe Information vorübergehend."
	_fuel_toggle.toggled.connect(func(pressed: bool):
		_fuel_pinned = pressed
		_update_fuel_help())
	information.add_child(_fuel_toggle)
	_fuel_help = _label("", 13, Color("f2ca86"))
	_fuel_help.name = "FuelReachability"
	_fuel_help.hide()
	information.add_child(_fuel_help)
	# Nottankdienst (T3): erscheint nur bei Treibstoffproblem oder offenem Auftrag; liest und bestellt ueber den Befehlsweg.
	_tanker_panel = TANKER_PANEL.new()
	information.add_child(_tanker_panel)
	_tanker_panel.configure(Callable(self, "_tanker_view"), func(operation: String, payload: Dictionary) -> Variant: return _commands.call(operation, payload) if _commands.is_valid() else {}, 13)
	_status = _label("", 15)
	_status.tooltip_text = "Am Flugdeck abheben, dann den Zielorbit wählen. Ein Zielort wird erst mit Anflug starten betreten."
	_status.name = "TravelStatus"
	information.add_child(_status)
	_build_course_box(information)
	_abort = _button("AbortQuantum", "Sprung abbrechen", _cancel_current_travel)
	_abort.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	information.add_child(_abort)
	_progress = ProgressBar.new()
	_progress.name = "QuantumProgress"
	_progress.custom_minimum_size.y = 8
	_progress.show_percentage = false
	information.add_child(_progress)

	_selection = _label("", 14, Color("b5c9d3"))
	_selection.name = "SelectedDestination"
	information.add_child(_selection)
	var actions := VBoxContainer.new()
	information.add_child(actions)
	_approach = _button("BeginApproach", "Anflug starten", _begin_approach)
	_approach.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(_approach)
	_land = _button("LandHomebase", "An Mondbasis landen", func(): _send("space_land_homebase", {"craft_id": _craft_id()}))
	_land.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(_land)
	_boundary = _label("Ortskarte wird geladen.", 14, Color("f2ca86"))
	_boundary.name = "LoadBoundary"
	information.add_child(_boundary)
	_error = _label("", 14, Color("ffb1a5"))
	_error.name = "CommandError"
	information.add_child(_error)
	information.add_child(_visit_list)
	_wing_panel = WING_PANEL.new()
	information.add_child(_wing_panel)
	# Wing tools remain available below the destination actions.
	_wing_panel.wing_focus_requested.connect(_on_map_craft_selected)
	_wing_panel.configure(_provider, _commands)
	_style_buttons()
	resized.connect(_layout_details)
	_layout_details()

func _layout_details() -> void:
	if _details != null:
		_details.custom_minimum_size.x = clampf(size.x * 0.23, 260, 320)
	if _navigation != null:
		_navigation.custom_minimum_size.x = clampf(size.x * 0.18, 210, 276)
		var narrow := size.x < 1000
		_navigation_toggle.visible = narrow
		_navigation.visible = not narrow or _navigation_toggle.button_pressed
		_map_column.visible = not narrow or not _navigation_toggle.button_pressed

func _label(text: String, font_size: int, color: Color = Color("e1ecf0")) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _button(node_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size.y = 34
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(action)
	return button

func _style_buttons() -> void:
	# Theme resources are cached once, including repeated projection refreshes.
	APP_THEME.primary(_approach)

func _focus_body(body_id: String) -> void:
	_canvas.call("focus_body", body_id)

func _sync_locations(locations: Dictionary) -> void:
	_destination_ids.clear()
	for id: String in locations:
		if id != "homebase": _destination_ids.append(id)

func refresh(snapshot: Dictionary = {}) -> void:
	if not _built:
		return
	var previous_phase: String = String(Dictionary(_runtime.get("space_travel", {})).get("phase", ""))
	_runtime = snapshot.duplicate(true) if not snapshot.is_empty() else (Dictionary(_provider.call()) if _provider.is_valid() else {})
	_wing_panel.refresh(_runtime)
	var travel: Dictionary = _runtime.get("space_travel", {})
	var phase: String = String(travel.get("phase", "grounded"))
	_update_course(travel, phase)
	var fleet_signature:=JSON.stringify(_runtime.get("crafts",[]))
	if String(_fleet_selector.get_meta("fleet_signature",""))!=fleet_signature:
		_fleet_selector.clear()
		for craft: Dictionary in Array(_runtime.get("crafts",[])):
			_fleet_selector.add_item(String(craft.get("display_name",craft.get("craft_id","Schiff"))))
			_fleet_selector.set_item_metadata(_fleet_selector.item_count-1,String(craft.get("craft_id","")))
		_fleet_selector.set_meta("fleet_signature",fleet_signature)
	for index in range(_fleet_selector.item_count):
		if String(_fleet_selector.get_item_metadata(index))==String(travel.get("craft_id","")): _fleet_selector.select(index)
	var route: Dictionary = Dictionary(travel.get("routes",{})).get(_orbit_craft_id,{})
	var availability_signature := str([_orbit_craft_id,route.get("phase",""),route.get("revision",-1)])
	if availability_signature != _orbit_availability_signature:
		_orbit_availability_signature = availability_signature
		_refresh_orbit_projection()
	var loaded_ids := {}
	for location: Dictionary in Array(_runtime.get("location_runtimes",[])): loaded_ids[String(location.location_id)] = true
	for id: String in _visit_buttons.keys():
		if not loaded_ids.has(id):
			_visit_buttons[id].queue_free()
			_visit_buttons.erase(id)
	for location: Dictionary in Array(_runtime.get("location_runtimes",[])):
		var id:=String(location.location_id)
		if not _visit_buttons.has(id):
			var button:=_button("ViewLocation_"+id,"Ort ansehen",func(): _send("open_location_view",{"location_id":id}))
			_visit_list.add_child(button); _visit_buttons[id]=button
		var place_name: String=DISPLAY.location_name(id, Dictionary(Dictionary(_runtime.get("campaign",{})).get("locations",{})).get(id,{}))
		(_visit_buttons[id] as Button).text="Ansehen: "+place_name
	if phase != previous_phase:
		_error.text = ""
	var orbit: String = String(travel.get("orbit_id", ""))
	var map_travel: Dictionary = SERVICE_ROUTE_PROJECTION.merge(travel, Dictionary(travel.get("service_shuttle", {})))
	_canvas.call("set_travel_snapshot", map_travel)
	var preparation: Dictionary = _runtime.get("map_preparation", {})
	_status.text = _phase_text(travel, preparation)
	var service_status: String = SERVICE_ROUTE_PROJECTION.describe(Dictionary(travel.get("service_shuttle", {})), Dictionary(travel.get("service_shuttle_home", {})), Dictionary(travel.get("service_shuttle_dispatch", {})))
	if not service_status.is_empty(): _status.text += "\n" + service_status
	_abort.visible = phase == "quantum" or (phase == "approach" and bool(preparation.get("cancel_available", false)))
	_abort.text = "Anflug abbrechen" if phase == "approach" else "Sprung abbrechen"
	var preparing := phase == "approach" and String(preparation.get("status", "")) in ["preparing_resources", "ready"]
	_progress.visible = phase in ["quantum", "stopped"] or preparing
	_progress.value = clampf(float(preparation.get("progress", 0.0) if preparing else travel.get("progress", 0.0)) * 100.0, 0, 100)
	if phase == "orbit" and String(preparation.get("status", "")) == "failed":
		_error.text = String(preparation.get("error", "Ortskarte konnte nicht vorbereitet werden."))
	elif phase == "orbit" and String(preparation.get("status", "")) == "cancelled":
		_error.text = ""
	_close.visible = phase in ["grounded", "orbit", "quantum", "stopped"]
	_close.text = "Abflug vorbereiten" if phase == "grounded" else "Trupp"
	var campaign: Dictionary = _runtime.get("campaign", {})
	_update_fuel_help()
	var locations: Dictionary = campaign.get("locations", {})
	_sync_locations(locations)
	_navigation.refresh(campaign, travel)
	var selected: String = String(campaign.get("selected_location_id", ""))
	var location_orbits: Dictionary = travel.get("location_orbits", {})
	var accepted_locations := {}
	var guidance: PackedStringArray = []
	var job_availability: Dictionary = campaign.get("job_availability", {})
	for id: String in Dictionary(campaign.get("jobs", {})):
		var job_data: Dictionary = campaign.jobs[id]
		var job_location := String(job_data.get("location_id", ""))
		var status := String(job_data.get("status", ""))
		if status in ["accepted", "active"]: accepted_locations[job_location] = true
		if job_location != selected or not bool(Dictionary(job_availability.get(id, {})).get("visible", false)): continue
		var job_orbit := String(location_orbits.get(job_location, ""))
		var job_body := String(Dictionary(Dictionary(travel.get("orbits", {})).get(job_orbit, {})).get("body_id", ""))
		var body_name := DISPLAY.body_name(job_body, Dictionary(travel.get("bodies", {})).get(job_body, {}))
		var job_state := Dictionary(job_availability.get(id, {}))
		var state_text := ("Gesperrt: " + String(job_state.get("message", ""))) if bool(job_state.get("shown_as_locked", false)) else String(DISPLAY.STATUS.get(status, status))
		guidance.append("%s\n%s · %s\nBelohnung: %d Kredite" % [String(job_data.get("title", "Auftrag")), body_name, state_text, int(Dictionary(job_data.get("reward", {})).get("credits", 0))])
	_job_guidance.text = "\n".join(guidance)
	_job_guidance.visible = not guidance.is_empty()
	var marker_locations: Dictionary={}
	for id in _destination_ids:
		var location: Dictionary = locations.get(id, {})
		var reason := _lock_reason(id)
		var required_orbit := String(location_orbits.get(id, "planet_orbit" if location_orbits.is_empty() else ""))
		var at_site_orbit: bool = phase == "orbit" and not required_orbit.is_empty() and orbit == required_orbit
		var selectable: bool = (phase == "grounded" or at_site_orbit) and reason.is_empty()
		if reason.is_empty(): marker_locations[id]={"name":DISPLAY.location_name(id, location),"available":selectable,"selected":selected==id,"accepted_job":accepted_locations.has(id),"reason":reason,"region_position":location.get("region_position",[])}
	_canvas.call("set_location_snapshot",marker_locations)
	var selected_location: Dictionary = locations.get(selected, {})
	_destination_heading.text = DISPLAY.location_name(selected, selected_location)
	if selected != _picture_location:
		_picture_location = selected
		_destination_picture.texture = APP_THEME.location_picture(selected)
		_destination_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if selected == "satellite_crash" else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var job: Dictionary = Dictionary(campaign.get("jobs", {})).get(String(campaign.get("selected_job_id", "")), {})
	_selection.text = String(job.get("title", "Ortsbesuch")) if _destination_ids.has(selected) else ""
	var selected_orbit := String(location_orbits.get(selected, "planet_orbit" if location_orbits.is_empty() else ""))
	var at_selected_orbit := phase == "orbit" and not selected_orbit.is_empty() and orbit == selected_orbit
	_approach.visible = at_selected_orbit and _destination_ids.has(selected)
	_approach.disabled = not _lock_reason(selected).is_empty() or not at_selected_orbit
	_approach.text = "Anflug starten"
	_land.visible = phase == "orbit" and orbit == "moon_orbit"
	_boundary.visible = _approach.visible or phase == "approach"
	_error.visible = not _error.text.is_empty()

func _update_fuel_help() -> void:
	if _fuel_help == null: return
	var travel: Dictionary = _runtime.get("space_travel", {})
	var reach: Dictionary = travel.get("fuel_reachability", {})
	var campaign: Dictionary = _runtime.get("campaign", {})
	var locations: Dictionary = campaign.get("locations", {})
	var availability: Dictionary = campaign.get("location_availability", {})
	# Regel 8 / Auftrag 21.11.: erreichbar = die nächste Etappe ist bezahlbar; zusätzlich: reicht der Treibstoff für den ganzen Hinweg?
	var lines: PackedStringArray = ["TREIBSTOFF · nächste Etappe und ganzer Hinweg"]
	for id in reach:
		if not bool(Dictionary(availability.get(id, {})).get("ok", false)): continue
		var outcome: Dictionary = reach[id]
		var name := DISPLAY.location_name(id, locations.get(id, {}))
		var next_ok := bool(outcome.get("ok", false))
		var detail := ""
		if not next_ok:
			detail = " · " + String(outcome.get("message", "Nicht verfügbar"))
		elif not bool(outcome.get("route_ok", true)):
			detail = " · nächste Etappe möglich, der ganze Hinweg braucht %d (vorhanden %d)" % [int(ceil(float(outcome.get("needed_total", 0.0)))), int(floor(float(outcome.get("available", 0.0))))]
		else:
			detail = " · ganzer Hinweg gedeckt"
		lines.append(("✓ " if next_ok else "✕ ") + name + detail)
	if lines.size() == 1: lines.append("Keine Routendaten für verfügbare Ziele.")
	_fuel_help.text = "\n".join(lines)
	_fuel_help.visible = (_show_fuel_help or _fuel_pinned) and is_visible_in_tree()

## Auskunft des Nottankdienstes fuer das Schiff, das die Karte gerade zeigt (im Orbitbild das gewaehlte). Nur lesend.
func _tanker_view() -> Dictionary:
	if not _tanker_view_provider.is_valid(): return {}
	var craft_id: String = _orbit_craft_id if _orbit_visible and not _orbit_craft_id.is_empty() else String(Dictionary(_runtime.get("space_travel", {})).get("craft_id", ""))
	if craft_id.is_empty(): return {}
	var result: Variant = _tanker_view_provider.call(craft_id)
	return result if result is Dictionary else {}

func _on_fleet_craft_selected(index: int) -> void:
	_orbit_craft_id = String(_fleet_selector.get_item_metadata(index))
	_orbit_availability_signature = ""
	_send("space_focus_craft", {"craft_id":_orbit_craft_id})

func _on_map_craft_selected(craft_id: String) -> void:
	_canvas.call("set_selected_ship", craft_id)
	if _wing_panel != null: _wing_panel.select_for_craft(craft_id)
	var leader := craft_id
	for wing: Dictionary in Dictionary(Dictionary(_runtime.get("space_wings", {})).get("wings", {})).values():
		if craft_id in Array(wing.get("craft_ids", [])):
			var wing_leader := String(wing.get("leader_craft_id", ""))
			if not wing_leader.is_empty(): leader = wing_leader
			break
	_orbit_craft_id = leader
	_orbit_availability_signature = ""
	_send("space_focus_craft", {"craft_id":leader})

func _refresh_orbit_projection() -> void:
	var projection: Dictionary = {}
	if not _orbit_craft_id.is_empty() and _area_provider.is_valid():
		var result: Variant = _area_provider.call(_orbit_craft_id)
		if result is Dictionary: projection = result
	_orbit_canvas.call("set_projection",projection,_orbit_craft_id,_orbit_body_visual(projection))
	var available: bool = not _orbit_craft_id.is_empty() and String(_orbit_canvas.call("get_selected_craft_id")) == _orbit_craft_id
	_orbit_button.disabled = not available
	_orbit_button.tooltip_text = "Lokalen Orbit ansehen" if available else "Schiff explizit auswählen; benötigt einen aktiven lokalen Orbitbereich."
	if _orbit_visible and not available: _show_system_view()
	_refresh_station_dock_button()

func _refresh_station_dock_button() -> void:
	if not is_instance_valid(_station_dock) or not is_instance_valid(_orbit_canvas): return
	var projection: Dictionary = _orbit_canvas.call("get_projection")
	var targets: Variant = projection.get("dock_targets")
	var expected := {"target_id":"polisa_station_dock","revision":"polisa_glut2_dock_v1"}
	var available: bool = is_visible_in_tree() and _orbit_visible and _commands.is_valid() and _area_provider.is_valid() and not _orbit_craft_id.is_empty() and String(_orbit_canvas.call("get_selected_craft_id")) == _orbit_craft_id and projection.get("ok") == true and projection.get("space_area_id") == "orbit_approach:glut_2" and targets is Array and targets.size() == 1 and targets[0] is Dictionary and targets[0] == expected
	_station_dock.visible = available
	_station_dock.disabled = not available

func _begin_station_dock() -> void:
	# Re-read the provider at click time; a displayed target is never a permit.
	_refresh_orbit_projection()
	if _station_dock.disabled or not _station_dock.is_visible_in_tree(): return
	_move_sequence += 1
	_send("space_begin_station_dock", {"craft_id":_orbit_craft_id,"location_id":"polisa","target_id":"polisa_station_dock","layout_revision":"polisa_glut2_dock_v1","request_id":"station-dock-ui:%s:%d" % [_move_session,_move_sequence]})

func _orbit_body_visual(projection: Dictionary) -> Dictionary:
	var area_id := String(projection.get("space_area_id",""))
	if not area_id.begins_with("orbit_approach:"): return {}
	var body_id := area_id.trim_prefix("orbit_approach:").uri_decode()
	var body: Dictionary = Dictionary(Dictionary(_runtime.get("space_travel",{})).get("bodies",{})).get(body_id,{})
	return {"name":DISPLAY.body_name(body_id, body),"color":Color.from_string(String(body.get("color","866349")),Color("866349"))}

func _show_orbit_view() -> void:
	_refresh_orbit_projection()
	if _orbit_button.disabled: return
	_orbit_visible = true
	_canvas.hide()
	_orbit_canvas.show()
	_orbit_center.show()
	_refresh_station_dock_button()
	_elapsed = 0.0

func _show_system_view() -> void:
	_orbit_visible = false
	_canvas.show()
	_orbit_canvas.hide()
	_orbit_center.hide()
	_refresh_station_dock_button()
	_elapsed = 0.0

func _on_orbit_move_requested(craft_id: String, target_hex: Vector2i) -> void:
	if not _orbit_visible or craft_id.is_empty() or craft_id != _orbit_craft_id or String(_orbit_canvas.call("get_selected_craft_id")) != craft_id: return
	_move_sequence += 1
	_send("space_move",{"craft_id":craft_id,"target_hex":target_hex,"request_id":"orbit-ui:%s:%d" % [_move_session,_move_sequence]})

## Block "KURS": vorgemerktes Ziel mit Etappen und Treibstoff, Wahl des Durchflugs, Knopf "Start".
func _build_course_box(parent: VBoxContainer) -> void:
	_course_box = VBoxContainer.new()
	_course_box.name = "CoursePanel"
	_course_box.add_theme_constant_override("separation", 6)
	parent.add_child(_course_box)
	var heading := _label("KURS", 16, Color("b4dae8"))
	heading.add_theme_font_override("font", APP_THEME.HEADING)
	_course_box.add_child(heading)
	_course_text = _label("", 14, Color("f2ca86"))
	_course_text.name = "CourseText"
	_course_box.add_child(_course_text)
	_mode_row = HBoxContainer.new()
	_mode_row.name = "OrbitModeRow"
	_mode_row.add_theme_constant_override("separation", 4)
	_course_box.add_child(_mode_row)
	var caption := _label("Durchflug:", 14, APP_THEME.MUTED)
	_mode_row.add_child(caption)
	var group := ButtonGroup.new()
	_mode_auto = _button("OrbitModeAutomatic", "Automatik", func(): _set_orbit_mode(true))
	_mode_manual = _button("OrbitModeManual", "Selbst fliegen", func(): _set_orbit_mode(false))
	_mode_auto.tooltip_text = "Der Durchflug zum Planeten oder ins All läuft von selbst."
	_mode_manual.tooltip_text = "Bei der Ankunft öffnet sich die Orbit-Ansicht; ein Klick schickt das Schiff dorthin."
	for button: Button in [_mode_auto, _mode_manual]:
		button.toggle_mode = true
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_stretch_ratio = 1.0
		button.custom_minimum_size.x = 0
		_mode_row.add_child(button)
	_mode_auto.button_pressed = true
	_course_start = _button("StartCourse", "Start", _start_pending)
	_course_start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_course_start.tooltip_text = "Kurs fliegen (Enter). Esc oder Rechtsklick auf freie Fläche verwirft das Ziel."
	_course_box.add_child(_course_start)
	_course_box.hide()

func _preview_jump(orbit_id: String, marker_id: String) -> void:
	var travel: Dictionary = _runtime.get("space_travel", {})
	if not GRID.can_jump_to_marker(travel, orbit_id, marker_id): return
	_pending_jump = {"orbit_id": orbit_id, "marker_id": marker_id, "craft_id": String(travel.get("craft_id", "")), "wings": _selected_wings()}
	orbit_previewed.emit(orbit_id, marker_id)
	_update_course(travel, String(travel.get("phase", "grounded")))

func _discard_preview() -> void:
	if _pending_jump.is_empty(): return
	_pending_jump = {}
	if _canvas != null: _canvas.call("clear_preview_course")
	_update_course(_runtime.get("space_travel", {}), String(Dictionary(_runtime.get("space_travel", {})).get("phase", "grounded")))

## "Start": der alte Weg (_jump) mit dem vorgemerkten Ziel. Gesperrt, wenn der Treibstoff nicht reicht.
func _start_pending() -> void:
	if _pending_jump.is_empty() or not _course_start_ok: return
	var orbit_id := String(_pending_jump.orbit_id)
	var marker_id := String(_pending_jump.marker_id)
	var pending := _pending_jump.duplicate()
	_error.text = ""
	orbit_requested.emit(orbit_id, marker_id)
	_jump(orbit_id, marker_id)
	var travel: Dictionary = _runtime.get("space_travel", {})
	if not _error.text.is_empty():
		# Abgelehnt: Ziel und Kurslinie bleiben stehen, der Grund steht im Fehlerfeld.
		_pending_jump = pending
		_open_orbit_on_arrival = false
		_error.visible = true
		_update_course(travel, String(travel.get("phase", "grounded")))
		return
	_pending_jump = {}
	_canvas.call("clear_preview_course")
	if not bool(travel.get("orbit_transit_automatic", true)):
		_open_orbit_on_arrival = true
		_arrival_saw_quantum = false
		_arrival_attempts = 0
		_arrival_target = {"orbit_id": orbit_id, "marker_id": marker_id}
		if _orbit_craft_id.is_empty():
			_orbit_craft_id = String(travel.get("craft_id", ""))
			_orbit_availability_signature = ""
	else:
		_open_orbit_on_arrival = false
	_update_course(travel, String(travel.get("phase", "grounded")))

func _selected_wings() -> Array:
	return _wing_panel.selected_wing_ids() if _wing_panel != null else []

func _set_orbit_mode(automatic: bool) -> void:
	var travel: Dictionary = _runtime.get("space_travel", {})
	var craft_id := String(travel.get("craft_id", ""))
	if craft_id.is_empty() or automatic == bool(travel.get("orbit_transit_automatic", true)): return
	_send("space_set_orbit_automatic", {"craft_id": craft_id, "enabled": automatic})

## Fuer das Ziel: Treibstoff aus der Erreichbarkeit des zugehoerigen Ortes (so weit die Daten reichen). {text, ok}
func _course_fuel(travel: Dictionary, orbit_id: String) -> Dictionary:
	var location_orbits: Dictionary = travel.get("location_orbits", {})
	var selected := String(Dictionary(_runtime.get("campaign", {})).get("selected_location_id", ""))
	var location_id := ""
	var ids: Array = []
	for id in location_orbits:
		if String(location_orbits[id]) == orbit_id: ids.append(String(id))
	ids.sort()
	if String(location_orbits.get(selected, "")) == orbit_id:
		location_id = selected
	elif not ids.is_empty():
		location_id = String(ids[0])
	var reach: Dictionary = Dictionary(travel.get("fuel_reachability", {}))
	if location_id.is_empty() or not reach.has(location_id):
		return {"text": "Treibstoff: keine Angabe für dieses Ziel", "ok": true}
	var outcome: Dictionary = reach[location_id]
	# Hat der Koerper mehrere Orte, sagt der Text, fuer welchen die Zahl gilt.
	var label := "Treibstoff"
	if ids.size() > 1:
		var locations: Dictionary = Dictionary(Dictionary(_runtime.get("campaign", {})).get("locations", {}))
		label = "Treibstoff für " + DISPLAY.location_name(location_id, locations.get(location_id, {}))
	if not bool(outcome.get("ok", false)):
		var why := String(outcome.get("message", "Zu wenig Treibstoff"))
		return {"text": label + ": reicht nicht · " + why, "ok": false}
	if not bool(outcome.get("route_ok", true)):
		return {"text": label + ": reicht für die nächste Etappe · ganzer Hinweg braucht %d (vorhanden %d)" % [int(ceil(float(outcome.get("needed_total", 0.0)))), int(floor(float(outcome.get("available", 0.0))))], "ok": true,
			"warning": "Reicht nur bis zum Orbit – dort tanken oder den Nottankdienst rufen."}
	return {"text": label + ": reicht · ganzer Hinweg gedeckt", "ok": true}

func _update_course(travel: Dictionary, phase: String) -> void:
	if _course_box == null: return
	# Ein vorgemerktes Ziel gilt nur, solange der Sprung wirklich noch moeglich ist.
	if not _pending_jump.is_empty() and (phase not in ["orbit", "stopped"] or not GRID.can_jump_to_marker(travel, String(_pending_jump.orbit_id), String(_pending_jump.marker_id))):
		_pending_jump = {}
	# Anderes Schiff oder andere Schiffsgruppe gewaehlt: das Ziel galt fuer die alte Wahl und wird verworfen.
	if not _pending_jump.is_empty() and (String(_pending_jump.get("craft_id", "")) != String(travel.get("craft_id", "")) or _pending_jump.get("wings", []) != _selected_wings()):
		_pending_jump = {}
	var automatic := bool(travel.get("orbit_transit_automatic", true))
	var available := bool(travel.get("orbit_transit_available", false))
	var has_craft := not String(travel.get("craft_id", "")).is_empty()
	_mode_row.visible = available
	_mode_auto.set_pressed_no_signal(automatic)
	_mode_manual.set_pressed_no_signal(not automatic)
	_mode_auto.disabled = not has_craft
	_mode_manual.disabled = not has_craft
	var pending := not _pending_jump.is_empty()
	_course_box.visible = pending or available
	_course_text.visible = pending
	_course_start.visible = pending
	if pending:
		var orbit_id := String(_pending_jump.orbit_id)
		var marker_id := String(_pending_jump.marker_id)
		var destination := Vector2.ZERO
		var found := false
		for marker: Dictionary in Array(Dictionary(Dictionary(travel.get("orbits", {})).get(orbit_id, {})).get("markers", [])):
			if String(marker.get("id", "")) == marker_id:
				destination = GRID.normalized(GRID.cell_from_record(marker))
				found = true
		var origin := GRID.pair(travel.get("position", []))
		if found: _canvas.call("set_preview_course", origin, destination)
		var cells := int(_canvas.call("get_preview_cell_count"))
		var fuel := _course_fuel(travel, orbit_id)
		_course_start_ok = bool(fuel.ok) and found
		var lines := PackedStringArray(["Ziel: %s · Marker %s" % [_orbit_name(orbit_id), marker_id.get_slice("_", 1)]])
		lines.append("Etappe: Quantensprung" + (" · %d Felder" % maxi(cells - 1, 1) if cells > 0 else ""))
		lines.append(String(fuel.text))
		if fuel.has("warning"): lines.append(String(fuel.warning))
		if not _course_start_ok: lines.append("Start gesperrt.")
		_course_text.text = "\n".join(lines)
		_course_start.disabled = not _course_start_ok
	else:
		_canvas.call("clear_preview_course")
		_course_start_ok = true
	_update_arrival(phase)

## "Selbst fliegen": Kommt das Schiff an, oeffnet sich die Orbit-Ansicht von selbst (wenn der lokale Orbit schon bereitsteht).
func _update_arrival(phase: String) -> void:
	# Abflug vom Boden im Handflug: Das Schiff startet am oberen Planetenrand; einmal je Abflug sagen, wie es weitergeht.
	var travel: Dictionary = _runtime.get("space_travel", {})
	var transit: Dictionary = Dictionary(travel.get("orbit_transit", {}))
	if phase == "orbit" and not bool(travel.get("orbit_transit_automatic", true)) and transit.get("direction") == "outbound" and transit.get("status") == "manual":
		var hint_key := String(travel.get("craft_id", "")) + ":" + String(transit.get("location_id", ""))
		if hint_key != _outbound_hint_key:
			_outbound_hint_key = hint_key
			_error.text = "Abgehoben. Fliege auf der Orbit-Karte nach unten ins Weltall, dann kannst du über die Sternkarte weiterfliegen – oder stelle oben auf „Automatisch“."
			_error.add_theme_color_override("font_color", Color("c4d7de"))
	elif phase != "orbit":
		_outbound_hint_key = ""
	if not _open_orbit_on_arrival: return
	# War die Karte waehrend des Sprungs verdeckt, wurde "quantum" nie gesehen: dann zaehlt, dass das Schiff am Ziel steht.
	var at_target := not _arrival_target.is_empty() and String(_runtime.get("space_travel", {}).get("orbit_id", "")) == String(_arrival_target.orbit_id) and String(_runtime.get("space_travel", {}).get("orbit_marker_id", "")) == String(_arrival_target.marker_id)
	if phase == "quantum":
		_arrival_saw_quantum = true
	elif phase == "orbit" and (_arrival_saw_quantum or at_target):
		_arrival_attempts += 1
		if _arrival_attempts == 1:
			# Einmal je Ankunft im Handflug: Der Spieler soll nicht ratlos im Orbit stehen.
			_error.text = "Im Orbit angekommen. Öffne „Orbit ansehen“ und klicke auf den Planeten oben – oder stelle oben auf „Automatisch“."
			_error.add_theme_color_override("font_color", Color("c4d7de"))
		_show_orbit_view()
		if _orbit_visible or _arrival_attempts > 40: _open_orbit_on_arrival = false
	elif phase in ["grounded", "surface", "approach"]:
		_open_orbit_on_arrival = false

func get_course_snapshot() -> Dictionary:
	var travel: Dictionary = _runtime.get("space_travel", {})
	return {"pending": _pending_jump.duplicate(), "text": _course_text.text if not _pending_jump.is_empty() else "", "start_disabled": _course_start.disabled,
		"line_points": Array(_canvas.call("get_preview_course")).size() if _canvas != null else 0,
		"mode": "automatic" if bool(travel.get("orbit_transit_automatic", true)) else "manual", "orbit_view_open": _orbit_visible}

func _phase_text(travel: Dictionary, preparation: Dictionary = {}) -> String:
	var phase := String(travel.get("phase", "grounded"))
	if phase == "orbit":
		var transit: Dictionary = travel.get("orbit_transit", {})
		if transit.get("status") == "flying":
			return "Orbitdurchflug → " + ("Planet" if transit.get("direction") == "inbound" else "Weltraum / System")
		if transit.get("status") == "manual" and not String(transit.get("reason", "")).is_empty():
			return "Orbitdurchflug angehalten · manuelle Steuerung verfügbar"
		if String(preparation.get("status", "")) == "failed": return "Ortskarte konnte nicht vorbereitet werden · Zurück im Orbit."
		if String(preparation.get("status", "")) == "cancelled": return "Anflug abgebrochen · Zurück im Orbit."
	match phase:
		"grounded":
			var location_id := String(travel.get("location_id", "homebase"))
			return DISPLAY.location_name(location_id, Dictionary(Dictionary(_runtime.get("campaign", {})).get("locations", {})).get(location_id, {})) + " · Gelandet"
		"quantum": return "Warp-Sprung → %s · %d %%" % [_marker_name(travel, true), roundi(float(travel.get("progress", 0.0)) * 100)]
		"stopped": return "Sprung abgebrochen · Position gehalten"
		"orbit": return "%s erreicht" % _marker_name(travel)
		"approach":
			match String(preparation.get("status", "loading_data")):
				"preparing_resources": return "Ortskarte wird vorbereitet · %d %%" % roundi(clampf(float(preparation.get("progress", 0.0)), 0.0, 1.0) * 100.0)
				"ready": return "Ortskarte bereit · Einsatz wird geöffnet …"
			return "Anflug · Ortskarte wird geladen …"
		"surface": return "Am Zielort"
	return "Sternkarte wird vorbereitet …"

func _open_operations() -> void:
	var phase: String = String(Dictionary(_runtime.get("space_travel", {})).get("phase", "grounded"))
	_send("space_prepare_launch" if phase == "grounded" else "space_open_operations")

func _orbit_name(id: String) -> String:
	var travel: Dictionary = _runtime.get("space_travel", {})
	return DISPLAY.orbit_name(id, travel)

func _marker_name(travel: Dictionary, target: bool = false) -> String:
	var orbit_id := String(travel.get("target_orbit_id" if target else "orbit_id", ""))
	var marker_id := String(travel.get("target_orbit_marker_id" if target else "orbit_marker_id", GRID.ORBIT_MARKER_IDS[0]))
	return "%s · Marker %s" % [_orbit_name(orbit_id), marker_id.get_slice("_", 1)]

func _lock_reason(location_id: String) -> String:
	var campaign: Dictionary = _runtime.get("campaign", {})
	var availability: Dictionary = Dictionary(campaign.get("location_availability", {})).get(location_id, {})
	return "" if bool(availability.get("ok", false)) else String(availability.get("message", "Ziel zurzeit nicht verfügbar"))

func _craft_id() -> String:
	var runtime: Dictionary = _provider.call() if _provider.is_valid() else _runtime
	return String(Dictionary(runtime.get("space_travel", {})).get("craft_id", ""))

func _jump(orbit_id: String, marker_id: String) -> void:
	var selected: Array = _wing_panel.selected_wing_ids() if _wing_panel != null else []
	if not selected.is_empty() and _commands.is_valid():
		var wings: Dictionary = Dictionary(_runtime.get("space_wings", {})).get("wings", {})
		var sent := {}
		var failures: PackedStringArray = []
		for wing_id in selected:
			for id in Array(Dictionary(wings.get(wing_id, {})).get("craft_ids", [])):
				var craft_id := String(id)
				if craft_id.is_empty() or sent.has(craft_id): continue
				sent[craft_id] = true
				var result: Variant = _commands.call("space_start_quantum", {"craft_id":craft_id, "target_orbit_id":orbit_id, "target_orbit_marker_id":marker_id})
				if not result is Dictionary or not bool(result.get("ok", false)):
					failures.append(craft_id + ": " + (String(result.get("message", "Sprung abgelehnt")) if result is Dictionary else "Sprung abgelehnt"))
		refresh()
		_error.text = "\n".join(failures) if not failures.is_empty() else ("Keine Schiffe in der Auswahl." if sent.is_empty() else "")
		_error.visible = not _error.text.is_empty()
		return
	_send("space_start_quantum", {"craft_id": _craft_id(), "target_orbit_id": orbit_id, "target_orbit_marker_id": marker_id})

func _select(location_id: String) -> void:
	var runtime: Dictionary = _provider.call() if _provider.is_valid() else _runtime
	var campaign: Dictionary = runtime.get("campaign", {})
	var selected_job: String = String(campaign.get("selected_job_id", ""))
	var jobs: Dictionary = campaign.get("jobs", {})
	var job: Dictionary = jobs.get(selected_job, {})
	var job_id := ""
	if String(job.get("location_id", "")) == location_id and String(job.get("status", "")) in ["accepted", "active"]:
		job_id = selected_job
	if job_id.is_empty():
		for id in jobs:
			var accepted: Dictionary = jobs[id]
			if String(accepted.get("location_id", "")) == location_id and String(accepted.get("status", "")) == "accepted":
				job_id = String(id)
				break
	_send("select_destination", {"location_id": location_id, "job_id": job_id})

func _cancel_current_travel() -> void:
	var phase := String(Dictionary(_runtime.get("space_travel", {})).get("phase", ""))
	if phase == "approach":
		if bool(Dictionary(_runtime.get("map_preparation", {})).get("cancel_available", false)):
			_send("space_cancel_approach", {"craft_id": _craft_id()})
	else:
		_send("space_abort_quantum", {"craft_id": _craft_id()})

func _begin_approach() -> void:
	var runtime: Dictionary = _provider.call() if _provider.is_valid() else _runtime
	_send("space_begin_approach", {"craft_id": _craft_id(), "location_id": String(Dictionary(runtime.get("campaign", {})).get("selected_location_id", ""))})
	# Selbst fliegen: nach "Anflug starten" gleich die Orbit-Ansicht zeigen, statt ueber den Durchflug zu warten.
	if _error.text.is_empty() and not bool(Dictionary(_runtime.get("space_travel", {})).get("orbit_transit_automatic", true)) and not _orbit_craft_id.is_empty():
		_show_orbit_view()

func _send(operation: String, payload: Dictionary = {}) -> void:
	if not _commands.is_valid():
		return
	var result: Variant = _commands.call(operation, payload)
	_error.remove_theme_color_override("font_color")
	_error.text = String(Dictionary(result).get("message", "Aktion wurde abgelehnt.")) if result is Dictionary and not bool(result.get("ok", false)) else ""
	if operation in ["space_move", "space_begin_station_dock"]:
		_refresh_orbit_projection()
		_error.visible = not _error.text.is_empty()
	else: refresh()

func get_ui_snapshot() -> Dictionary:
	return {"phase": String(Dictionary(_runtime.get("space_travel", {})).get("phase", "grounded")), "status": _status.text, "load_boundary": _boundary.text if _boundary.visible else "", "error": _error.text, "trade_reason": _lock_reason("trade_outpost"), "orbit_marker_count": _navigation.orbit_marker_count, "navigation_rebuilds": _navigation.rebuild_count}
