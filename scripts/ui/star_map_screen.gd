extends PanelContainer
## Read-only system map. Requests never move ships or load missions locally.
const CANVAS = preload("res://scripts/ui/star_map_canvas.gd")
const ORBIT_CANVAS = preload("res://scripts/ui/orbit_area_canvas.gd")
const WING_PANEL = preload("res://scripts/ui/space_wing_panel.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const SERVICE_ROUTE_PROJECTION = preload("res://scripts/ui/polisa_service_route_projection.gd")
var _provider: Callable
var _commands: Callable
var _area_provider: Callable
var _orbit_canvas: Control
var _orbit_button: Button
var _system_button: Button
var _orbit_center: Button
var _orbit_auto: Button
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
var _locks: Label
var _boundary: Label
var _error: Label
var _progress: ProgressBar
var _abort: Button
var _approach: Button
var _land: Button
var _close: Button
var _view_homebase: Button
var _sites: Dictionary = {}
var _sites_row: VBoxContainer
var _fleet_selector: OptionButton
var _wing_panel
var _visit_list: VBoxContainer
var _visit_buttons: Dictionary={}
var _details: PanelContainer
var _orbit_target_list: HFlowContainer
var _orbit_target_buttons: Array[Button] = []
var _orbit_target_signature := ""

func configure(snapshot_provider: Callable, command_handler: Callable, area_provider: Callable = Callable()) -> void:
	_provider = snapshot_provider
	_commands = command_handler
	_area_provider = area_provider
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

func _build() -> void:
	_built = true
	name = "StarMapScreen"
	mouse_filter = Control.MOUSE_FILTER_STOP
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
		margin.add_theme_constant_override("margin_" + side, 16)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "Content"
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := _label("STERNKARTE", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	_close = _button("CloseStarMap", "Abflug zur Sternkarte vorbereiten", _open_operations)
	heading.add_child(_close)
	_view_homebase = _button("ViewHomebase", "Basis ansehen", func(): _send("open_location_view", {"location_id":"homebase"}))
	heading.add_child(_view_homebase)
	column.add_child(_label("BÖRNER-SYSTEM  ·  256 × 256 HEXFELDER", 12, Color("789baa")))
	var body := HBoxContainer.new()
	body.name = "SystemAndDetails"
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var system_column := VBoxContainer.new()
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
	_orbit_auto = _button("OrbitAutomatic", "Durchflug: an", _toggle_orbit_automatic)
	_orbit_auto.tooltip_text = "Automatischen Orbitdurchflug für dieses Schiff ein- oder ausschalten."
	map_views.add_child(_orbit_auto)
	_station_dock = _button("BeginStationDock", "Polisa andocken", _begin_station_dock)
	_station_dock.hide()
	_station_dock.disabled = true
	_station_dock.tooltip_text = "Dockauftrag senden; Gate, Besatzung und Besuch werden vom Spiel geprueft."
	map_views.add_child(_station_dock)
	visibility_changed.connect(_refresh_station_dock_button)
	_move_session = "%d:%d" % [get_instance_id(),Time.get_ticks_usec()]
	_canvas = CANVAS.new()
	_canvas.name = "SystemMap"
	_canvas.custom_minimum_size.x = 350
	_canvas.clip_contents = true
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.orbit_requested.connect(_jump)
	_canvas.location_selected.connect(_select)
	_canvas.craft_selected.connect(_on_map_craft_selected)
	system_column.add_child(_canvas)
	_orbit_canvas = ORBIT_CANVAS.new()
	_orbit_canvas.name = "LocalOrbitMap"
	_orbit_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_orbit_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_orbit_canvas.move_requested.connect(_on_orbit_move_requested)
	system_column.add_child(_orbit_canvas)
	_orbit_canvas.hide()
	system_column.add_child(_label("ORBITMARKER", 11, Color("789baa")))
	_orbit_target_list = HFlowContainer.new()
	_orbit_target_list.name = "OrbitTargetList"
	_orbit_target_list.add_theme_constant_override("h_separation", 16)
	_orbit_target_list.add_theme_constant_override("v_separation", 4)
	system_column.add_child(_orbit_target_list)
	_details = PanelContainer.new()
	_details.name = "DetailsPanel"
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color("0c1721")
	detail_style.border_color = Color("284754")
	detail_style.set_border_width_all(1)
	_details.add_theme_stylebox_override("panel", detail_style)
	body.add_child(_details)
	body.move_child(_details, 0)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.name = "DetailsScroll"
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_details.add_child(detail_scroll)
	var inset := MarginContainer.new()
	inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "top", "right", "bottom"]:
		inset.add_theme_constant_override("margin_" + side, 12)
	detail_scroll.add_child(inset)
	var information := VBoxContainer.new()
	information.name = "DestinationInformation"
	information.add_theme_constant_override("separation", 10)
	inset.add_child(information)
	_close.reparent(information)
	_view_homebase.reparent(information)
	_fleet_selector=OptionButton.new()
	_fleet_selector.name="FleetCraftSelector"
	information.add_child(_fleet_selector)
	_fleet_selector.item_selected.connect(_on_fleet_craft_selected)
	_visit_list=VBoxContainer.new()
	_visit_list.name="LoadedLocations"
	information.add_child(_label("ZIEL & ANFLUG", 13, Color("70c8d0")))
	_job_guidance = _label("", 14, Color("f2ca86"))
	_job_guidance.name = "AcceptedJobGuidance"
	information.add_child(_job_guidance)
	_status = _label("", 15)
	_status.name = "TravelStatus"
	information.add_child(_status)
	_abort = _button("AbortQuantum", "Sprung abbrechen", _cancel_current_travel)
	_abort.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	information.add_child(_abort)
	_progress = ProgressBar.new()
	_progress.name = "QuantumProgress"
	_progress.custom_minimum_size.y = 8
	_progress.show_percentage = false
	information.add_child(_progress)
	information.add_child(_label("ZIELORTE", 11, Color("789baa")))
	_sites_row = VBoxContainer.new()
	_sites_row.name = "DestinationRows"
	_sites_row.add_theme_constant_override("separation", 10)
	information.add_child(_sites_row)
	_locks = _label("", 13, Color("f2ca86"))
	_locks.name = "LocationLocks"
	information.add_child(_locks)
	_selection = _label("", 14, Color("b5c9d3"))
	_selection.name = "SelectedDestination"
	information.add_child(_selection)
	var actions := VBoxContainer.new()
	information.add_child(actions)
	_approach = _button("BeginApproach", "Anflug starten", _begin_approach)
	_approach.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	actions.add_child(_approach)
	_land = _button("LandHomebase", "An Mondbasis landen", func(): _send("space_land_homebase", {"craft_id": _craft_id()}))
	_land.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	actions.add_child(_land)
	_boundary = _label("Du verlässt die Sternkarte. Die Ortskarte wird geladen.", 14, Color("f2ca86"))
	_boundary.name = "LoadBoundary"
	information.add_child(_boundary)
	_error = _label("", 14, Color("ffb1a5"))
	_error.name = "CommandError"
	information.add_child(_error)
	information.add_child(_visit_list)
	_wing_panel = WING_PANEL.new()
	information.add_child(_wing_panel)
	information.move_child(_wing_panel, 3)
	_wing_panel.wing_focus_requested.connect(_on_map_craft_selected)
	_wing_panel.configure(_provider, _commands)
	_style_buttons()
	resized.connect(_layout_details)
	_layout_details()

func _layout_details() -> void:
	if _details != null:
		_details.custom_minimum_size.x = clampf(size.x * 0.24, 244, 300)

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
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(action)
	return button

func _style_buttons() -> void:
	for button in [_abort, _approach, _land, _close, _view_homebase, _system_button, _orbit_button, _orbit_center, _orbit_auto, _station_dock] + _sites.values() + _orbit_target_buttons:
		if button == null:
			continue
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("16313b") if state in ["hover", "pressed", "focus"] else Color("0a1b26")
			style.border_color = Color("efb16a") if state == "focus" else Color("35606c")
			style.set_border_width_all(2 if state == "focus" else 1)
			style.set_corner_radius_all(2)
			style.content_margin_left = 10
			style.content_margin_right = 10
			button.add_theme_stylebox_override(state, style)
		button.add_theme_color_override("font_color", Color("e5f0f3"))
		button.add_theme_color_override("font_disabled_color", Color("85929f"))

func _sync_orbit_targets(travel: Dictionary) -> void:
	var orbits: Dictionary = _canvas.call("get_orbit_definitions")
	var signature := var_to_str(orbits)
	if signature != _orbit_target_signature:
		_orbit_target_signature = signature
		for child in _orbit_target_list.get_children():
			_orbit_target_list.remove_child(child)
			child.queue_free()
		_orbit_target_buttons.clear()
		# Body source order preserves V2's existing four rows, then adds others.
		var ordered: Array = []
		var bodies: Dictionary = travel.get("bodies",{})
		for body_id in bodies:
			if body_id == "sun": continue
			for orbit_id in orbits:
				if orbits[orbit_id].get("body_id") == body_id: ordered.append(orbit_id)
		for orbit_id in orbits:
			if not ordered.has(orbit_id): ordered.append(orbit_id)
		for orbit_id in ordered:
			var orbit: Dictionary = orbits.get(orbit_id, {})
			if orbit.is_empty():
				continue
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 5)
			_orbit_target_list.add_child(row)
			var body_name := String(orbit.get("name", "")).get_slice(" · ", 0)
			var label := _label(body_name, 14)
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			for marker: Dictionary in Array(orbit.get("markers", [])).slice(0, 1):
				var id := String(marker.id)
				var number := id.get_slice("_", 1)
				var button := _button("OrbitMarker_%s_%s" % [orbit_id, id], number, _jump.bind(orbit_id, id))
				button.custom_minimum_size = Vector2(36, 29)
				button.set_meta("orbit_id", orbit_id)
				button.set_meta("marker_id", id)
				button.set_meta("marker_label", "%s · Orbitmarker %s" % [body_name, number])
				row.add_child(button)
				_orbit_target_buttons.append(button)
		_style_buttons()
	for button in _orbit_target_buttons:
		var orbit_id := String(button.get_meta("orbit_id"))
		var marker_id := String(button.get_meta("marker_id"))
		var current := orbit_id == String(travel.get("orbit_id", "")) and marker_id == String(travel.get("orbit_marker_id", GRID.ORBIT_MARKER_IDS[0]))
		button.disabled = not GRID.can_jump_to_marker(travel, orbit_id, marker_id)
		button.tooltip_text = String(button.get_meta("marker_label")) + (" · Aktueller Standort" if current else "")
		button.add_theme_color_override("font_disabled_color", Color("f2c47c") if current else Color("85929f"))

func _sync_sites(locations: Dictionary) -> void:
	var changed := false
	for id in _sites.keys():
		if not locations.has(id) or String(id) == "homebase":
			_sites[id].queue_free()
			_sites.erase(id)
			changed = true
	for key in locations:
		var id := String(key)
		if id == "homebase" or _sites.has(id): continue
		var names := {"satellite_crash":"SatelliteDestination","trade_outpost":"TradeDestination","fortified_outpost":"FortifiedDestination","distress_orbit":"DistressDestination"}
		var button := _button(String(names.get(id,"Destination_" + id.validate_node_name())),"",_select.bind(id))
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.custom_minimum_size = Vector2(220,34)
		button.add_theme_font_size_override("font_size", 13)
		button.clip_text = true
		_sites_row.add_child(button)
		_sites[id] = button
		changed = true
	if changed: _style_buttons()

func refresh(snapshot: Dictionary = {}) -> void:
	if not _built:
		return
	var previous_phase: String = String(Dictionary(_runtime.get("space_travel", {})).get("phase", ""))
	_runtime = snapshot.duplicate(true) if not snapshot.is_empty() else (Dictionary(_provider.call()) if _provider.is_valid() else {})
	_wing_panel.refresh(_runtime)
	var travel: Dictionary = _runtime.get("space_travel", {})
	_orbit_auto.text = "Durchflug: an" if travel.get("orbit_transit_automatic", true) else "Durchflug: aus"
	_orbit_auto.visible = bool(travel.get("orbit_transit_available", false))
	_orbit_auto.disabled = String(travel.get("craft_id", "")).is_empty() or not _orbit_auto.visible
	var phase: String = String(travel.get("phase", "grounded"))
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
		var place_name: String=String(Dictionary(Dictionary(_runtime.get("campaign",{})).get("locations",{})).get(id,{}).get("name",id))
		(_visit_buttons[id] as Button).text="Ansehen: "+place_name
	if phase != previous_phase:
		_error.text = ""
	var orbit: String = String(travel.get("orbit_id", ""))
	var map_travel: Dictionary = SERVICE_ROUTE_PROJECTION.merge(travel, Dictionary(travel.get("service_shuttle", {})))
	_canvas.call("set_travel_snapshot", map_travel)
	_sync_orbit_targets(travel)
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
	_close.text = "Abflug zur Sternkarte vorbereiten" if phase == "grounded" else "Trupp & Ausrüstung"
	var campaign: Dictionary = _runtime.get("campaign", {})
	var locations: Dictionary = campaign.get("locations", {})
	_sync_sites(locations)
	var selected: String = String(campaign.get("selected_location_id", ""))
	var location_orbits: Dictionary = travel.get("location_orbits", {})
	var accepted_locations := {}
	var guidance: PackedStringArray = []
	for job_data: Dictionary in Dictionary(campaign.get("jobs", {})).values():
		if String(job_data.get("status", "")) not in ["accepted", "active"]: continue
		var job_location := String(job_data.get("location_id", ""))
		if job_location.is_empty(): continue
		accepted_locations[job_location] = true
		var job_orbit := String(location_orbits.get(job_location, ""))
		var job_body := String(Dictionary(Dictionary(travel.get("orbits", {})).get(job_orbit, {})).get("body_id", ""))
		var body_name := String(Dictionary(Dictionary(travel.get("bodies", {})).get(job_body, {})).get("name", job_orbit))
		guidance.append("Auftrag: %s\nZiel: %s · Orbit %s" % [String(job_data.get("title", "Auftrag")), String(Dictionary(locations.get(job_location, {})).get("name", job_location)), body_name])
	_job_guidance.text = "\n".join(guidance)
	_job_guidance.visible = not guidance.is_empty()
	var marker_locations: Dictionary={}
	var reasons: PackedStringArray = []
	for id in _sites:
		var button: Button = _sites[id]
		var location: Dictionary = locations.get(id, {})
		button.text = ("◆  " if selected == id else "◇  ") + String(location.get("name", "Satelliten-Absturzstelle" if id == "satellite_crash" else "Handelsposten"))
		var reason := _lock_reason(id)
		var required_orbit := String(location_orbits.get(id, "planet_orbit" if location_orbits.is_empty() else ""))
		var at_site_orbit: bool = phase == "orbit" and not required_orbit.is_empty() and orbit == required_orbit
		button.disabled = not at_site_orbit or not reason.is_empty()
		marker_locations[id]={"name":String(location.get("name",id)),"available":not button.disabled,"selected":selected==id,"accepted_job":accepted_locations.has(id),"reason":reason,"region_position":location.get("region_position",[])}
		button.tooltip_text = reason if not reason.is_empty() else ("Zielort auswaehlen. Erst der Anflug laedt die Karte." if at_site_orbit else "Erst den Orbit dieses Zielorts erreichen.")
		if not reason.is_empty():
			reasons.append(String(location.get("name", id)) + ": " + reason)
	_canvas.call("set_location_snapshot",marker_locations)
	_locks.text = "\n".join(reasons)
	_locks.visible = not reasons.is_empty()
	var selected_location: Dictionary = locations.get(selected, {})
	var job: Dictionary = Dictionary(campaign.get("jobs", {})).get(String(campaign.get("selected_job_id", "")), {})
	_selection.text = "Ziel: %s  ·  Auftrag: %s" % [String(selected_location.get("name", "Noch keinen Zielort ausgewaehlt")), String(job.get("title", "Ortsbesuch"))] if _sites.has(selected) else "Zielort im zugehörigen Orbit auswählen."
	var selected_orbit := String(location_orbits.get(selected, "planet_orbit" if location_orbits.is_empty() else ""))
	var at_selected_orbit := phase == "orbit" and not selected_orbit.is_empty() and orbit == selected_orbit
	_approach.visible = at_selected_orbit and _sites.has(selected)
	_approach.disabled = not _lock_reason(selected).is_empty() or not at_selected_orbit
	_approach.text = "Anflug starten"
	_land.visible = phase == "orbit" and orbit == "moon_orbit"
	_boundary.visible = _approach.visible or phase == "approach"
	_error.visible = not _error.text.is_empty()

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
	return {"name":String(body.get("name",body_id)),"color":Color.from_string(String(body.get("color","866349")),Color("866349"))}

func _show_orbit_view() -> void:
	_refresh_orbit_projection()
	if _orbit_button.disabled: return
	_orbit_visible = true
	_canvas.hide()
	_orbit_target_list.hide()
	_orbit_canvas.show()
	_orbit_center.show()
	_refresh_station_dock_button()
	_elapsed = 0.0

func _show_system_view() -> void:
	_orbit_visible = false
	_canvas.show()
	_orbit_target_list.show()
	_orbit_canvas.hide()
	_orbit_center.hide()
	_refresh_station_dock_button()
	_elapsed = 0.0

func _on_orbit_move_requested(craft_id: String, target_hex: Vector2i) -> void:
	if not _orbit_visible or craft_id.is_empty() or craft_id != _orbit_craft_id or String(_orbit_canvas.call("get_selected_craft_id")) != craft_id: return
	_move_sequence += 1
	_send("space_move",{"craft_id":craft_id,"target_hex":target_hex,"request_id":"orbit-ui:%s:%d" % [_move_session,_move_sequence]})

func _toggle_orbit_automatic() -> void:
	var travel: Dictionary = _runtime.get("space_travel", {})
	var craft_id := String(travel.get("craft_id", ""))
	if craft_id.is_empty(): return
	_send("space_set_orbit_automatic", {"craft_id":craft_id, "enabled":not bool(travel.get("orbit_transit_automatic", true))})

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
		"grounded": return "Mondbasis · Am Flightdeck abheben, um den Mondorbit zu erreichen."
		"quantum": return "Warp-Sprung → %s · %d %% · Abbruch jederzeit möglich" % [_marker_name(travel, true), roundi(float(travel.get("progress", 0.0)) * 100)]
		"stopped": return "Sprung abgebrochen · Position gehalten. Ziel anklicken, um erneut zu springen."
		"orbit": return "%s erreicht · %s" % [_marker_name(travel), "Zielort wählen und Anflug starten." if String(travel.get("orbit_id", "")) != "moon_orbit" else "Zielorbit wählen oder an der Mondbasis landen."]
		"approach":
			match String(preparation.get("status", "loading_data")):
				"preparing_resources": return "Ortskarte wird vorbereitet · %d %%" % roundi(clampf(float(preparation.get("progress", 0.0)), 0.0, 1.0) * 100.0)
				"ready": return "Ortskarte bereit · Einsatz wird geöffnet …"
			return "Anflug · Ortskarte wird geladen …"
		"surface": return "Am Zielort · Nach dem Abheben kehrst du in den zugehörigen Orbit zurück."
	return "Sternkarte wird vorbereitet …"

func _open_operations() -> void:
	var phase: String = String(Dictionary(_runtime.get("space_travel", {})).get("phase", "grounded"))
	_send("space_prepare_launch" if phase == "grounded" else "space_open_operations")

func _orbit_name(id: String) -> String:
	var travel: Dictionary = _runtime.get("space_travel", {})
	var definition: Dictionary = Dictionary(travel.get("orbits", {})).get(id, {})
	return String(definition.get("name", "Mondorbit" if id == "moon_orbit" else "Planetenorbit"))

func _marker_name(travel: Dictionary, target: bool = false) -> String:
	var orbit_id := String(travel.get("target_orbit_id" if target else "orbit_id", ""))
	var marker_id := String(travel.get("target_orbit_marker_id" if target else "orbit_marker_id", GRID.ORBIT_MARKER_IDS[0]))
	return "%s · Marker %s" % [_orbit_name(orbit_id), marker_id.get_slice("_", 1)]

func _lock_reason(location_id: String) -> String:
	if String(_runtime.get("mode", "")) != "campaign":
		return ""
	var campaign: Dictionary = _runtime.get("campaign", {})
	if bool(Dictionary(Dictionary(campaign.get("locations", {})).get(location_id, {})).get("free_visit", false)): return ""
	var jobs: Dictionary = campaign.get("jobs", {})
	for job: Dictionary in jobs.values():
		if String(job.get("location_id", "")) != location_id: continue
		var prior := String(job.get("prerequisite_job_id", ""))
		var locked: bool = bool(job.get("locked", not prior.is_empty() and String(Dictionary(jobs.get(prior,{})).get("status", "")) != "completed"))
		if not locked: return ""
	return "Zuerst den vorherigen Kampagnenauftrag abschließen und Chips zuhause hochladen."

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

func _send(operation: String, payload: Dictionary = {}) -> void:
	if not _commands.is_valid():
		return
	var result: Variant = _commands.call(operation, payload)
	_error.text = String(Dictionary(result).get("message", "Aktion wurde abgelehnt.")) if result is Dictionary and not bool(result.get("ok", false)) else ""
	if operation in ["space_move", "space_begin_station_dock"]:
		_refresh_orbit_projection()
		_error.visible = not _error.text.is_empty()
	else: refresh()

func get_ui_snapshot() -> Dictionary:
	return {"phase": String(Dictionary(_runtime.get("space_travel", {})).get("phase", "grounded")), "status": _status.text, "load_boundary": _boundary.text if _boundary.visible else "", "error": _error.text, "trade_reason": _lock_reason("trade_outpost"), "orbit_marker_count": _orbit_target_buttons.size()}
