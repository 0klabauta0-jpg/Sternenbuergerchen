extends PanelContainer
## Read-only system map. Requests never move ships or load missions locally.
const CANVAS = preload("res://scripts/ui/star_map_canvas.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
var _provider: Callable
var _commands: Callable
var _runtime: Dictionary = {}
var _elapsed := 0.0
var _built := false
var _canvas: Control
var _status: Label
var _selection: Label
var _locks: Label
var _boundary: Label
var _error: Label
var _progress: ProgressBar
var _abort: Button
var _approach: Button
var _land: Button
var _close: Button
var _sites: Dictionary = {}
var _sites_row: VBoxContainer
var _fleet_selector: OptionButton
var _visit_list: VBoxContainer
var _visit_buttons: Dictionary={}
var _details: PanelContainer
var _orbit_target_list: HFlowContainer
var _orbit_target_buttons: Array[Button] = []

func configure(snapshot_provider: Callable, command_handler: Callable) -> void:
	_provider = snapshot_provider
	_commands = command_handler
	if not _built:
		_build()
	refresh()

func _process(delta: float) -> void:
	if not _built or not is_visible_in_tree():
		return
	_elapsed += delta
	if _elapsed >= 0.1:
		_elapsed = 0.0
		refresh()

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
	column.add_child(_label("GLUT-SYSTEM  ·  256 × 256 HEXFELDER", 12, Color("789baa")))
	var body := HBoxContainer.new()
	body.name = "SystemAndDetails"
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var system_column := VBoxContainer.new()
	system_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	system_column.add_theme_constant_override("separation", 6)
	body.add_child(system_column)
	_canvas = CANVAS.new()
	_canvas.name = "SystemMap"
	_canvas.custom_minimum_size.x = 350
	_canvas.clip_contents = true
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.orbit_requested.connect(_jump)
	_canvas.location_selected.connect(_select)
	system_column.add_child(_canvas)
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
	_fleet_selector=OptionButton.new()
	_fleet_selector.name="FleetCraftSelector"
	information.add_child(_fleet_selector)
	_fleet_selector.item_selected.connect(func(index:int): _send("space_focus_craft",{"craft_id":String(_fleet_selector.get_item_metadata(index))}))
	_visit_list=VBoxContainer.new()
	_visit_list.name="LoadedLocations"
	information.add_child(_label("ZIEL & ANFLUG", 13, Color("70c8d0")))
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
	for button in [_abort, _approach, _land, _close] + _sites.values() + _orbit_target_buttons:
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
	if _orbit_target_buttons.is_empty():
		var orbits: Dictionary = _canvas.call("get_orbit_definitions")
		for orbit_id in ["planet_orbit", "glut_1a_orbit", "glut_1b_orbit", "moon_orbit"]:
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
			for marker: Dictionary in orbit.get("markers", []):
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
	var travel: Dictionary = _runtime.get("space_travel", {})
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
	for location: Dictionary in Array(_runtime.get("location_runtimes",[])):
		var id:=String(location.location_id)
		if not _visit_buttons.has(id):
			var button:=_button("ViewLocation_"+id,"Ort ansehen",func(): _send("focus_location",{"location_id":id}))
			_visit_list.add_child(button); _visit_buttons[id]=button
		var place_name: String=String(Dictionary(Dictionary(_runtime.get("campaign",{})).get("locations",{})).get(id,{}).get("name",id))
		(_visit_buttons[id] as Button).text="Ansehen: "+place_name
	if phase != previous_phase:
		_error.text = ""
	var orbit: String = String(travel.get("orbit_id", ""))
	_canvas.call("set_travel_snapshot", travel)
	_sync_orbit_targets(travel)
	var preparation: Dictionary = _runtime.get("map_preparation", {})
	_status.text = _phase_text(travel, preparation)
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
		marker_locations[id]={"name":String(location.get("name",id)),"available":not button.disabled,"selected":selected==id,"reason":reason,"region_position":location.get("region_position",[])}
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

func _phase_text(travel: Dictionary, preparation: Dictionary = {}) -> String:
	var phase := String(travel.get("phase", "grounded"))
	if phase == "orbit":
		if String(preparation.get("status", "")) == "failed": return "Ortskarte konnte nicht vorbereitet werden · Zurück im Orbit."
		if String(preparation.get("status", "")) == "cancelled": return "Anflug abgebrochen · Zurück im Orbit."
	match phase:
		"grounded": return "Mondbasis · Am Flightdeck abheben, um den Mondorbit zu erreichen."
		"quantum": return "Quantum-Sprung → %s · %d %% · Abbruch jederzeit möglich" % [_marker_name(travel, true), roundi(float(travel.get("progress", 0.0)) * 100)]
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
	refresh()

func get_ui_snapshot() -> Dictionary:
	return {"phase": String(Dictionary(_runtime.get("space_travel", {})).get("phase", "grounded")), "status": _status.text, "load_boundary": _boundary.text if _boundary.visible else "", "error": _error.text, "trade_reason": _lock_reason("trade_outpost"), "orbit_marker_count": _orbit_target_buttons.size()}
