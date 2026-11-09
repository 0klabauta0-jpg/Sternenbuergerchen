extends PanelContainer
## Read-only system map. Requests never move ships or load missions locally.
const CANVAS = preload("res://scripts/ui/star_map_canvas.gd")
const LOCATION_IDS := ["satellite_crash", "trade_outpost"]
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
var _details: PanelContainer

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
	column.add_child(_label("MONDBASIS  /  MONDORBIT  /  PLANETENORBIT  /  ORTSANFLUG", 12, Color("789baa")))
	var body := HBoxContainer.new()
	body.name = "SystemAndDetails"
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	_canvas = CANVAS.new()
	_canvas.name = "SystemMap"
	_canvas.custom_minimum_size.x = 350
	_canvas.clip_contents = true
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.orbit_requested.connect(_jump)
	body.add_child(_canvas)
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
	information.add_child(_label("ZIEL & ANFLUG", 13, Color("70c8d0")))
	_status = _label("", 15)
	_status.name = "TravelStatus"
	information.add_child(_status)
	_abort = _button("AbortQuantum", "Sprung abbrechen", func(): _send("space_abort_quantum", {"craft_id": _craft_id()}))
	_abort.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	information.add_child(_abort)
	_progress = ProgressBar.new()
	_progress.name = "QuantumProgress"
	_progress.custom_minimum_size.y = 8
	_progress.show_percentage = false
	information.add_child(_progress)
	information.add_child(_label("ORTE AM PLANETEN", 11, Color("789baa")))
	var sites_row := VBoxContainer.new()
	sites_row.add_theme_constant_override("separation", 10)
	information.add_child(sites_row)
	for id in LOCATION_IDS:
		var button := _button("SatelliteDestination" if id == "satellite_crash" else "TradeDestination", "", _select.bind(id))
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.custom_minimum_size.y = 34
		button.add_theme_font_size_override("font_size", 13)
		sites_row.add_child(button)
		_sites[id] = button
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
	for button in [_abort, _approach, _land, _close, _sites.satellite_crash, _sites.trade_outpost, _canvas.get("_moon"), _canvas.get("_planet")]:
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

func refresh(snapshot: Dictionary = {}) -> void:
	if not _built:
		return
	var previous_phase: String = String(Dictionary(_runtime.get("space_travel", {})).get("phase", ""))
	_runtime = snapshot.duplicate(true) if not snapshot.is_empty() else (Dictionary(_provider.call()) if _provider.is_valid() else {})
	var travel: Dictionary = _runtime.get("space_travel", {})
	var phase: String = String(travel.get("phase", "grounded"))
	if phase != previous_phase:
		_error.text = ""
	var orbit: String = String(travel.get("orbit_id", ""))
	_canvas.call("set_travel_snapshot", travel)
	_status.text = _phase_text(travel)
	_abort.visible = phase == "quantum"
	_progress.visible = phase in ["quantum", "stopped"]
	_progress.value = clampf(float(travel.get("progress", 0.0)) * 100.0, 0, 100)
	_close.visible = phase in ["grounded", "orbit", "quantum", "stopped"]
	_close.text = "Abflug zur Sternkarte vorbereiten" if phase == "grounded" else "Trupp & Ausrüstung"
	var campaign: Dictionary = _runtime.get("campaign", {})
	var locations: Dictionary = campaign.get("locations", {})
	var selected: String = String(campaign.get("selected_location_id", ""))
	var at_planet := phase == "orbit" and orbit == "planet_orbit"
	var reasons: PackedStringArray = []
	for id in LOCATION_IDS:
		var button: Button = _sites[id]
		var location: Dictionary = locations.get(id, {})
		button.text = ("◆  " if selected == id else "◇  ") + String(location.get("name", "Satelliten-Absturzstelle" if id == "satellite_crash" else "Handelsposten"))
		var reason := _lock_reason(id)
		button.disabled = not at_planet or not reason.is_empty()
		button.tooltip_text = reason if not reason.is_empty() else ("Zielort auswaehlen. Erst der Anflug laedt die Karte." if at_planet else "Zielorte werden im Planetenorbit waehlbar.")
		if not reason.is_empty():
			reasons.append(String(location.get("name", id)) + ": " + reason)
	_locks.text = "\n".join(reasons)
	_locks.visible = not reasons.is_empty()
	var selected_location: Dictionary = locations.get(selected, {})
	var job: Dictionary = Dictionary(campaign.get("jobs", {})).get(String(campaign.get("selected_job_id", "")), {})
	_selection.text = "Ziel: %s  ·  Auftrag: %s" % [String(selected_location.get("name", "Noch keinen Zielort ausgewaehlt")), String(job.get("title", "Ortsbesuch"))] if selected in LOCATION_IDS else "Handelsposten und Satellitenzone liegen am Planeten. Zielwahl im Planetenorbit."
	_approach.visible = at_planet and selected in LOCATION_IDS
	_approach.disabled = not _lock_reason(selected).is_empty() or not at_planet
	_approach.text = "Anflug starten"
	_land.visible = phase == "orbit" and orbit == "moon_orbit"
	_boundary.visible = _approach.visible or phase == "approach"
	_error.visible = not _error.text.is_empty()

func _phase_text(travel: Dictionary) -> String:
	match String(travel.get("phase", "grounded")):
		"grounded": return "Mondbasis · Am Flightdeck abheben, um den Mondorbit zu erreichen."
		"quantum": return "Quantum-Sprung → %s · %d %% · Abbruch jederzeit moeglich" % [_orbit_name(String(travel.get("target_orbit_id", ""))), roundi(float(travel.get("progress", 0.0)) * 100)]
		"stopped": return "Sprung abgebrochen · Position gehalten. Ziel anklicken, um erneut zu springen."
		"orbit": return "%s erreicht · %s" % [_orbit_name(String(travel.get("orbit_id", ""))), "Zielort waehlen und Anflug starten." if String(travel.get("orbit_id", "")) == "planet_orbit" else "Planet anklicken oder an der Mondbasis landen."]
		"approach": return "Anflug · Sternkarte wird verlassen. Ortskarte wird geladen …"
		"surface": return "Am Zielort · Nach dem Abheben kehrst du in den Planetenorbit zurueck."
	return "Sternkarte wird vorbereitet …"

func _open_operations() -> void:
	var phase: String = String(Dictionary(_runtime.get("space_travel", {})).get("phase", "grounded"))
	_send("space_prepare_launch" if phase == "grounded" else "space_open_operations")

func _orbit_name(id: String) -> String:
	return "Mondorbit" if id == "moon_orbit" else "Planetenorbit"

func _lock_reason(location_id: String) -> String:
	if String(_runtime.get("mode", "")) != "campaign":
		return ""
	var stage: int = int(Dictionary(_runtime.get("onboarding", {})).get("stage_index", 3))
	if stage < 2 and location_id == "trade_outpost":
		return "Erst Satellit bergen und zur Mondbasis heimkehren."
	if stage == 2 and location_id == "satellite_crash":
		return "Jetzt Versorgung am Handelsposten sichern."
	return ""

func _craft_id() -> String:
	var runtime: Dictionary = _provider.call() if _provider.is_valid() else _runtime
	return String(Dictionary(runtime.get("space_travel", {})).get("craft_id", ""))

func _jump(orbit_id: String) -> void:
	_send("space_start_quantum", {"craft_id": _craft_id(), "target_orbit_id": orbit_id})

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
	return {"phase": String(Dictionary(_runtime.get("space_travel", {})).get("phase", "grounded")), "status": _status.text, "load_boundary": _boundary.text if _boundary.visible else "", "error": _error.text, "trade_reason": _lock_reason("trade_outpost"), "body_count": 2}
