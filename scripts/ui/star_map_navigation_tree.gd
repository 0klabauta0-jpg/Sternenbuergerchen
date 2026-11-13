extends Tree
## Navigation and expansion only. Commands and selected IDs remain with owners.
const DISPLAY = preload("res://scripts/mission/campaign_display_catalog.gd")
const INSPECT: Texture2D = preload("res://Assets/curated/smart_mobile_icons/inspect.svg")
const ORBIT_MAP: Texture2D = preload("res://Assets/curated/smart_mobile_icons/orbit_map.svg")
signal body_focused(body_id: String)
signal location_requested(location_id: String)
signal location_inspection_requested(location_id: String)
signal orbit_inspection_requested(body_id: String, orbit_id: String)
var _items: Dictionary = {}
var _signature := ""
var _projected_selection := ""
var _syncing := false
var rebuild_count := 0
var orbit_marker_count := 0

func _ready() -> void:
	name = "SystemNavigationTree"
	hide_root = false
	allow_reselect = true
	focus_mode = Control.FOCUS_ALL
	select_mode = Tree.SELECT_ROW
	item_selected.connect(_on_selected)
	item_mouse_selected.connect(_on_mouse_selected)
	button_clicked.connect(_on_inspect_button)
	item_activated.connect(_inspect_selected)

func _on_mouse_selected(_position: Vector2, button: int) -> void:
	if _syncing or button != MOUSE_BUTTON_LEFT: return
	var item := get_selected()
	if item == null or Dictionary(item.get_metadata(0)).get("kind") == "location": return
	# Only a row click reveals children. Native keyboard/fold-arrow changes also
	# emit item_selected; expanding there would immediately undo every collapse.
	_syncing = true
	item.collapsed = false
	_syncing = false

func refresh(campaign: Dictionary, travel: Dictionary) -> void:
	var bodies: Dictionary = travel.get("bodies", {})
	var locations: Dictionary = campaign.get("locations", {})
	var available: Dictionary = campaign.get("location_availability", {})
	var topology: Array = []
	for id: String in bodies:
		topology.append([id, bodies[id].get("parent_id", ""), DISPLAY.body_name(id, bodies[id])])
	var visible_locations := {}
	for id: String in locations:
		var orbit_id := String(Dictionary(travel.get("location_orbits", {})).get(id, ""))
		var body_id := String(Dictionary(Dictionary(travel.get("orbits", {})).get(orbit_id, {})).get("body_id", ""))
		for key: String in bodies:
			if String(bodies[key].get("surface_location_id", "")) == id: body_id = key; break
		visible_locations[id] = {"body_id":body_id, "orbit_id":orbit_id}
		topology.append(["location:" + id, body_id, DISPLAY.location_name(id, locations[id])])
	var orbits: Dictionary = travel.get("orbits", {})
	for id: String in orbits:
		var markers: Array = []
		for marker: Dictionary in Array(orbits[id].get("markers", [])): markers.append(String(marker.get("id", "")))
		topology.append(["orbit:" + id, String(orbits[id].get("body_id", "")), markers])
	var signature := JSON.stringify(topology)
	_syncing = true
	if signature != _signature:
		_signature = signature
		var collapsed := {}
		var focused := get_selected()
		var focus_key := ""
		if focused != null:
			var data: Dictionary = focused.get_metadata(0)
			focus_key = ("location:" if data.get("kind") == "location" else "body:") + String(data.get("id", ""))
		for key: String in _items: collapsed[key] = _items[key].collapsed
		clear()
		_items.clear()
		orbit_marker_count = 0
		rebuild_count += 1
		var system := create_item()
		system.set_text(0, DISPLAY.SYSTEM_NAME + "  /  SYSTEM")
		system.set_metadata(0, {"kind":"system", "id":"sun"})
		_items["body:sun"] = system
		for id: String in bodies: _create_body(id, bodies, system, 0)
		for orbit_id: String in orbits:
			var orbit: Dictionary = orbits[orbit_id]
			var body_id := String(orbit.get("body_id", ""))
			if not _items.has("body:" + body_id): continue
			var body_item: TreeItem = _items["body:" + body_id]
			var metadata: Dictionary = body_item.get_metadata(0)
			var inspections: Array = metadata.get("inspections", [])
			if not inspections.is_empty(): continue
			var caption := DISPLAY.body_name(body_id, bodies.get(body_id, {})) + " · OM ansehen · keine Reise"
			body_item.add_button(0, ORBIT_MAP, 0, false, caption, caption)
			inspections.append({"body_id":body_id, "orbit_id":orbit_id})
			orbit_marker_count += 1
			metadata["inspections"] = inspections
			body_item.set_metadata(0, metadata)
		for id: String in visible_locations:
			var parent: TreeItem = _items.get("body:" + String(visible_locations[id].body_id), system)
			var item := create_item(parent)
			item.set_text(0, DISPLAY.location_name(id, locations[id]))
			item.set_metadata(0, {"kind":"location", "id":id})
			var caption := DISPLAY.location_name(id, locations[id]) + " ansehen · nur bekannte Bereiche · keine Reise"
			item.add_button(0, INSPECT, 0, false, caption, caption)
			_items["location:" + id] = item
		for key: String in collapsed:
			if _items.has(key): _items[key].collapsed = bool(collapsed[key])
		if _items.has(focus_key): _items[focus_key].select(0)
	var phase := String(travel.get("phase", "grounded"))
	for id: String in visible_locations:
		var item: TreeItem = _items["location:" + id]
		var available_here: Dictionary = available.get(id, {})
		var can_select: bool = bool(available_here.get("ok", false)) and (phase == "grounded" or (phase == "orbit" and String(travel.get("orbit_id", "")) == String(visible_locations[id].orbit_id)))
		var metadata: Dictionary = item.get_metadata(0)
		metadata["can_select_destination"] = can_select
		item.set_metadata(0, metadata)
		# Every location is keyboard-inspectable; only the owner permits a route.
		item.set_selectable(0, true)
		item.set_custom_color(0, Color("e0edf0") if can_select else Color("829ca6"))
		var reason := String(available_here.get("message", "Zuerst den zugehörigen Orbit erreichen"))
		item.set_tooltip_text(0, DISPLAY.location_name(id, locations[id]) + (" · Ziel wählen, ohne abzufliegen" if can_select else " · Nur ansehen: " + reason) + " · Auge / Enter: Ansicht")
	var selected := String(campaign.get("selected_location_id", ""))
	var current: TreeItem = get_selected()
	if current == null or selected != _projected_selection:
		_projected_selection = selected
		if _items.has("location:" + selected):
			var item: TreeItem = _items["location:" + selected]
			var parent := item.get_parent()
			while parent != null: parent.collapsed = false; parent = parent.get_parent()
			item.select(0)
		else: deselect_all()
	_syncing = false

func _create_body(id: String, bodies: Dictionary, system: TreeItem, depth: int) -> TreeItem:
	if _items.has("body:" + id): return _items["body:" + id]
	if not bodies.has(id) or depth > bodies.size(): return system
	var body: Dictionary = bodies[id]
	var parent := _create_body(String(body.get("parent_id", "sun")), bodies, system, depth + 1)
	var item := create_item(parent)
	item.set_text(0, DISPLAY.body_name(id, body))
	item.set_metadata(0, {"kind":"body", "id":id})
	item.set_tooltip_text(0, "Fokussieren und Orte aufklappen · Enter: Orbit ansehen · keine Reise")
	_items["body:" + id] = item
	return item

func focus_body(id: String) -> void:
	if not _items.has("body:" + id): return
	_syncing = true
	var item: TreeItem = _items["body:" + id]
	item.collapsed = false
	var parent := item.get_parent()
	while parent != null: parent.collapsed = false; parent = parent.get_parent()
	item.select(0)
	scroll_to_item(item)
	_syncing = false

func _on_selected() -> void:
	if _syncing: return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and get_button_id_at_position(get_local_mouse_position()) >= 0: return
	var item := get_selected()
	if item == null: return
	var data: Dictionary = item.get_metadata(0)
	if data.get("kind") == "location":
		if bool(data.get("can_select_destination", false)): location_requested.emit(String(data.id))
	else:
		body_focused.emit(String(data.id))

func _on_inspect_button(item: TreeItem, _column: int, id: int, mouse_button: int) -> void:
	if mouse_button != MOUSE_BUTTON_LEFT or item == null: return
	var data: Dictionary = item.get_metadata(0)
	if data.get("kind") == "location":
		location_inspection_requested.emit(String(data.id))
		return
	var inspections: Array = data.get("inspections", [])
	if id < 0 or id >= inspections.size(): return
	var inspection: Dictionary = inspections[id]
	orbit_inspection_requested.emit(String(inspection.body_id), String(inspection.orbit_id))

func _inspect_selected() -> void:
	_on_inspect_button(get_selected(), 0, 0, MOUSE_BUTTON_LEFT)
