extends Control
## Base presentation. Real personnel state and actions remain with runtime owners.

signal terminal_open_requested(id: String)
signal world_selection_changed(kind: String, id: String)
signal exploration_exit_requested

const MAP_PATH: String = "res://maps/homebase_frontier_exploration.json"
const CAMPAIGN_MAP_PATH: String = "res://maps/campaign_intro_base.json"
var _map_path: String = MAP_PATH
const MAP_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const UNITS_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const SIM_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const AVATAR_SCRIPT: GDScript = preload("res://scripts/meta/homebase_commander_avatar.gd")
const FLIGHT_VISUAL_SCRIPT: GDScript = preload("res://scripts/terrain/mission_flight_visual.gd")
const HEX_SCRIPT: GDScript = preload("res://scripts/terrain/hex_grid.gd")
const PAD_SCRIPT: GDScript = preload("res://scripts/terrain/frontier_outpost_pad.gd")
const SHIP_VISUALS: GDScript = preload("res://scripts/terrain/frontier_ship_visuals.gd")
const INTERACTION_RADIUS: float = 1.8
const BASE_NAV: GDScript = preload("res://scripts/meta/base_interior_navigation.gd")

var _personnel_owner: WeakRef
var _personnel_command: Callable
var _selected_person_id: String = ""
var _person_visuals: Dictionary = {}
var _person_panel: VBoxContainer
var _person_selector: OptionButton
var _person_state: Label
var _person_feedback: Label
var _person_buttons: Dictionary = {}
var _personnel_ui_elapsed: float = 0.0
var _navigation_data
var _navigation_graph: RefCounted


func _personnel_runtime() -> Node:
	return _personnel_owner.get_ref() if _personnel_owner != null else null


func configure_personnel_runtime(owner: Node, command: Callable) -> void:
	_personnel_command = command
	if owner == _personnel_runtime():
		return
	var previous: Node = _personnel_runtime()
	if previous != null and previous.is_connected("terminal_ready", _personnel_terminal_ready):
		previous.disconnect("terminal_ready", _personnel_terminal_ready)
	_personnel_owner = weakref(owner) if owner != null else null
	if owner != null:
		owner.connect("terminal_ready", _personnel_terminal_ready)


func _personnel_terminal_ready(unit_id: String, terminal_id: String) -> void:
	# Arrival is an authoritative runtime event, even if another view is open.
	_select_person(unit_id)
	terminal_open_requested.emit(terminal_id)


func _personnel_action(operation: String, payload: Dictionary = {}) -> Dictionary:
	if not _personnel_command.is_valid() or _selected_person_id.is_empty():
		return {"ok": false, "reason": "no_person", "message": "Zuerst eine Person auswählen"}
	var data: Dictionary = payload.duplicate(true)
	data["unit_id"] = _selected_person_id
	if not data.has("craft_id") and not _transport_projection.is_empty():
		data["craft_id"] = String(_transport_projection[0].get("craft_id", ""))
	var result: Dictionary = _personnel_command.call(operation, data)
	if _person_feedback != null:
		_person_feedback.text = String(result.get("message", ""))
	return result


func _build_personnel_visuals(stage: Node3D) -> void:
	for person: Dictionary in _personnel_runtime().call("get_snapshot").get("units", []):
		var id: String = String(person.unit_id)
		if _person_visuals.has(id):continue
		var visual: Node3D = _load_visual(Dictionary(_layout.get("avatar_visual", {})))
		if visual == null:
			continue
		visual.name = "RosterPerson_" + id.validate_node_name()
		visual.set_meta("unit_id", id)
		stage.add_child(visual)
		var players: Array[Node] = visual.find_children("*", "AnimationPlayer", true, false)
		var player: AnimationPlayer = players[0] as AnimationPlayer if not players.is_empty() else null
		var idle: String = ""
		var walk: String = ""
		if player != null:
			for clip in player.get_animation_list():
				if String(clip).to_lower().ends_with("idle"):
					idle = String(clip)
				if String(clip).to_lower().ends_with("walk"):
					walk = String(clip)
			if not idle.is_empty():
				player.play(idle)
		var label := Label3D.new()
		label.text = String(person.get("name", person.get("display_name", id)))
		label.font_size = 30
		label.pixel_size = 0.003
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position.y = 0.85
		var marker := Node3D.new()
		stage.add_child(marker)
		marker.add_child(label)
		_person_visuals[id] = {"model": visual, "marker": marker, "label": label, "player": player, "idle": idle, "walk": walk, "previous": Vector2.INF, "moving": false}
	if _person_visuals.has(_selected_person_id):
		_model = _person_visuals[_selected_person_id].model


func _select_person(id: String) -> bool:
	var owner: Node = _personnel_runtime()
	if owner == null or owner.call("get_actor", id) == null:
		return false
	_selected_person_id = id
	_selected_world_craft_id = ""
	world_selection_changed.emit("person",id)
	_manual_camera = false
	_avatar = owner.call("get_actor", id)
	if _person_visuals.has(id):
		_model = _person_visuals[id].model
	if _personnel_command.is_valid():
		_personnel_command.call("focus_unit", {"unit_id": id})
	_update_personnel_controls()
	return true


func _select_person_at(point: Vector2) -> bool:
	for key in _screen_world_labels:
		var label: Label=_screen_world_labels[key]
		if String(key).begins_with("person:") and label.visible and Rect2(label.position,label.size).has_point(point): return _select_person(String(key).trim_prefix("person:"))
	var nearest: String = ""
	var distance: float = 30.0
	for id: String in _person_visuals:
		var entry: Dictionary = _person_visuals[id]
		if not (entry.model as Node3D).visible:
			continue
		var actor: Node2D = _personnel_runtime().call("get_actor", id)
		var screen: Vector2 = _view.call("world_to_screen_position", actor.position)
		var candidate: float = screen.distance_to(point)
		if candidate < distance:
			nearest = id
			distance = candidate
	return _select_person(nearest) if not nearest.is_empty() else false


func _build_personnel_controls() -> void:
	_person_panel = VBoxContainer.new()
	_person_panel.name = "BasePersonnelActions"
	add_child(_person_panel)
	_person_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_person_panel.offset_left = 24.0
	_person_panel.offset_right = 424.0
	_person_panel.offset_top = -298.0
	_person_panel.offset_bottom = -24.0
	_person_selector = OptionButton.new()
	_person_selector.tooltip_text = "Person auswählen – auch Besatzung an Bord"
	_person_selector.item_selected.connect(func(index: int): _select_person(String(_person_selector.get_item_metadata(index))))
	_person_panel.add_child(_person_selector)
	var name_row:=HBoxContainer.new(); _person_panel.add_child(name_row)
	var name_input:=LineEdit.new(); name_input.name="RenamePerson"; name_input.placeholder_text="Neuer Name"; name_input.max_length=48; name_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL; name_row.add_child(name_input)
	var rename:=Button.new(); rename.text="Umbenennen"; name_row.add_child(rename)
	rename.pressed.connect(func(): _personnel_action("base_rename",{"display_name":name_input.text}); name_input.clear())
	_person_state = Label.new()
	_person_panel.add_child(_person_state)
	var rest := CheckButton.new()
	rest.name = "AutomaticRest"
	rest.text = "Automatisch ruhen"
	rest.tooltip_text = "Bei Leerlauf zu einem freien Bett gehen. Aus: nach manuellen Befehlen stehen bleiben."
	rest.toggled.connect(func(enabled: bool): _personnel_action("base_auto_rest", {"enabled":enabled}))
	_person_panel.add_child(rest)
	_person_buttons["auto_rest"] = rest
	var actions := GridContainer.new()
	actions.columns = 3
	_person_panel.add_child(actions)
	for spec: Array in [["base_board", "Einsteigen"], ["base_unboard", "Aussteigen"], ["equipment", "Ausrüsten"], ["base_sleep", "Schlafen"], ["base_wake", "Aufwecken"], ["details", "Details"], ["pilot", "Pilot übernehmen"], ["base_cancel", "Abbrechen"]]:
		var operation: String = String(spec[0])
		var button := Button.new()
		button.text = String(spec[1])
		var tips: Dictionary = {"base_board":"Zum Schiff gehen und bestaetigt einsteigen. Truppmitglieder verwenden den bestehenden Trupp-Payload.", "base_unboard":"Das verfuegbare Schiff verlassen. Die Pilotenplatzzuweisung bleibt erhalten.", "equipment":"Vorhandene Personalausruestung fuer diese Person oeffnen.", "base_sleep":"Ein freies Bett reservieren und zu Fuss aufsuchen. Fuehrt keine Sofortheilung aus.", "base_wake":"Aufwecken und Bett freigeben.", "details":"Das vorhandene Charakterblatt dieser Person oeffnen.", "pilot":"Dieser Person den Pilotenplatz zuweisen. Eine Truppperson zuerst im Truppmenue freigeben.", "base_cancel":"Den laufenden Basisweg abbrechen und die Bettreservierung freigeben."}
		button.tooltip_text = String(tips.get(operation, ""))
		button.custom_minimum_size = Vector2(128, 36)
		button.pressed.connect(func():
			if operation == "equipment":
				_personnel_action("focus_unit")
				_personnel_action("navigate", {"mode": "personnel"})
			else:
				_personnel_action(operation))
		actions.add_child(button)
		_person_buttons[operation] = button
	_person_feedback = Label.new()
	_person_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_person_feedback.custom_minimum_size.x = 390
	_person_panel.add_child(_person_feedback)
	_hint.text = "NPC anklicken · Rechtsklick Ziel · E Konsole"
	_update_personnel_controls()


func _update_personnel_controls() -> void:
	if _person_panel == null or _personnel_runtime() == null:
		return
	_person_panel.visible = _active and not _pad_preview and not _selected_person_id.is_empty()
	var units: Array = _personnel_runtime().call("get_snapshot").get("units", [])
	if _person_selector.item_count != units.size():
		_person_selector.clear()
		for person: Dictionary in units:
			_person_selector.add_item(String(person.get("name", person.get("display_name", person.unit_id))))
			_person_selector.set_item_metadata(_person_selector.item_count - 1, String(person.unit_id))
	for index in units.size():
		var person: Dictionary = units[index]
		_person_selector.set_item_text(index,String(person.get("name",person.get("display_name",person.unit_id))))
		if String(person.unit_id) != _selected_person_id:
			continue
		_person_selector.select(index)
		var status: String = String(person.get("status", "outside"))
		var labels: Dictionary = {"outside": "In der Basis", "moving": "Unterwegs", "sleeping": "Schläft", "aboard": "An Bord", "boarding": "Geht zum Schiff", "away": "Im Einsatz"}
		_person_state.text = String(labels.get(status, status))
		(_person_buttons.base_board as Button).disabled = status in ["aboard", "away"]
		(_person_buttons.auto_rest as CheckButton).set_pressed_no_signal(bool(person.get("auto_rest_enabled",true)))
		(_person_buttons.base_unboard as Button).disabled = status != "aboard"
		(_person_buttons.base_wake as Button).disabled = status != "sleeping"
		(_person_buttons.base_sleep as Button).disabled = status in ["aboard", "sleeping", "away"]


func _update_personnel_visuals() -> void:
	var units: Array = _personnel_runtime().call("get_snapshot").get("units", [])
	if _authored_stage!=null and units.size()>_person_visuals.size():_build_personnel_visuals(_authored_stage)
	for person: Dictionary in units:
		var id: String = String(person.unit_id)
		if not _person_visuals.has(id):
			continue
		var entry: Dictionary = _person_visuals[id]
		entry["display_name"]=String(person.get("name",person.get("display_name",id)))
		(entry.label as Label3D).text="" if _screen_labels_host!=null else String(entry.display_name)
		var model: Node3D = entry.model
		var actor: Node2D = _personnel_runtime().call("get_actor", id)
		var status: String = String(person.get("status", "outside"))
		model.visible = status not in ["aboard", "away"] and not _pad_preview
		(entry.marker as Node3D).visible = model.visible
		var plane: Vector3 = _view.call("_world_to_3d_position", actor.position, 0.0)
		var position_3d: Vector3 = plane + Vector3.UP * BASE_NAV.standing_y(plane)
		var sleeping_rotation: float = model.rotation.y
		if status == "sleeping":
			for bed: Dictionary in _layout.get("beds", []):
				if String(bed.id) == String(person.get("bed_id", "")) and bed.has("sleep_plane"):
					position_3d = _plane_position(bed.sleep_plane) + Vector3.UP * float(bed.get("sleep_y", 0.4))
					sleeping_rotation = float(bed.get("rotation_y", 0.0))
		var previous: Vector2 = entry.previous
		var moving: bool = previous.is_finite() and actor.position.distance_squared_to(previous) > 0.00001
		var displacement: Vector3 = position_3d - model.position
		model.position = position_3d
		model.rotation.z = PI * 0.5 if status == "sleeping" else 0.0
		if status == "sleeping":
			model.rotation.y = sleeping_rotation
		if moving:
			model.rotation.y = atan2(displacement.x, displacement.z)
			if id == _selected_person_id and not _manual_camera:
				_view.call("focus_world_position", actor.position)
		(entry.marker as Node3D).position = position_3d
		(entry.label as Label3D).modulate = Color("ffe08b") if id == _selected_person_id else Color("eaf2df")
		if moving != bool(entry.moving) and entry.player != null:
			var clip: String = String(entry.walk if moving else entry.idle)
			if not clip.is_empty():
				(entry.player as AnimationPlayer).play(clip, 0.15)
		entry.moving = moving
		entry.previous = actor.position
	_view.call("_request_viewport_redraw")

var _active: bool = false
var _initialized: bool = false
var _host: SubViewportContainer
var _viewport: SubViewport
var _runtime: Node
var _view: CanvasLayer
var _terrain: Node
var _units: Node
var _sim: Node
var _avatar: Node2D
var _model: Node3D
var _player: AnimationPlayer
var _idle_clip: String = ""
var _walk_clip: String = ""
var _walking: bool = false
var _previous_position: Vector2 = Vector2.ZERO
var _terminals: Array[Dictionary] = []
var _terminal_labels: Dictionary = {}
var _layout: Dictionary = {}
var _asset_sources: Array[Dictionary] = []
var _structure_visual_nodes: Dictionary = {}
var _structure_visual_records: Dictionary = {}
var _refuel_service_available: bool = false
var _map_bounds: Rect2
var _map_data
var _hint: Label
var _interact: Button
var _nearby_terminal: String = ""
var _keys: Dictionary = {}
var _keyboard_move: bool = false
var _move_cadence: float = 0.0
var _movement_command_count: int = 0
var _command_sequence: int = 0
var _drone_model: Node3D
var _drone_helper: Node3D
var _cutaway_wall_visual_count: int = 0
var _authored_stage: Node3D
var _transport_projection: Array = []
var _transport_signature: String = ""
var _craft_visuals: Dictionary = {}
var _focused_craft_id: String = ""
var _camera_dragging := false
var _camera_drag_last := Vector2.ZERO
var _manual_camera := false
var _context_elapsed := 0.0
var _world_context_hint: Label
var _base_owns_cursor := false
var _selected_world_craft_id := ""
var _screen_world_labels: Dictionary = {}
var _screen_labels_host: Control
const CONTEXT_ACTIONS = preload("res://scripts/mission/world_context_action_contract.gd")
var _pad_preview: bool = false
var _preview_surface_size: Vector2 = Vector2.ZERO
var _preview_pad_id: String = ""


func set_pad_preview(active: bool, craft_id: String = "", pad_id: String = "") -> void:
	_clear_base_context()
	if _screen_labels_host!=null: _screen_labels_host.visible=not active
	if not active:
		set_active(false)
		return
	var changed_pad := pad_id != _preview_pad_id
	_preview_pad_id = pad_id
	if _pad_preview and _active and _initialized:
		if changed_pad or _focused_craft_id != craft_id:
			_focus_preview_pad(craft_id)
		if size != _preview_surface_size:
			_preview_surface_size = size
			_view.call("_resize_subviewport")
			_view.call("_request_viewport_redraw")
			_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
		return
	set_active(true)
	_pad_preview = true
	if _screen_labels_host!=null: _screen_labels_host.hide()
	_clear_base_context()
	_preview_surface_size = size
	_clear_keyboard_input()
	if _personnel_runtime() == null:
		_sim.call("clear_queues")
		_sim.set_physics_process(false)
	_runtime.process_mode = Node.PROCESS_MODE_DISABLED
	if _model != null:
		_model.visible = false
	_update_personnel_controls()
	for entry: Dictionary in _person_visuals.values():
		(entry.model as Node3D).hide()
		(entry.marker as Node3D).hide()
	_host.release_focus()
	_host.focus_mode = Control.FOCUS_NONE
	_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_node("ExplorationHelp").visible = false
	get_node("ExitExploration").visible = false
	if _drone_helper != null:
		_drone_helper.call("set_operating_visual", false)
	set_process(true)
	set_physics_process(false)
	set_process_unhandled_key_input(false)
	_focus_preview_pad(craft_id)
	_view.call("_request_viewport_redraw")
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE


func set_transport_snapshot(snapshot: Dictionary) -> void:
	if not _initialized:
		_map_path = CAMPAIGN_MAP_PATH if String(snapshot.get("mode", "")) == "campaign" else MAP_PATH
	# Presentation cache only. Actual membership, pad occupancy and phase arrive
	# from the runtime adapter; this scene never creates or moves a real craft.
	_refuel_service_available = not Dictionary(snapshot.get("supply", {})).is_empty()
	for terminal in _terminals:
		if String(terminal.get("id", "")) == "refuel":
			terminal["enabled"] = _refuel_service_available
	var crafts: Array = Array(snapshot.get("crafts", [])).duplicate(true)
	var signature: String = JSON.stringify(crafts, "", true)
	if signature == _transport_signature:
		return
	_transport_signature = signature
	_transport_projection = crafts
	if _initialized:
		_update_craft_projection()


func focus_craft_pad(craft_id: String) -> bool:
	if not _initialized or not _craft_visuals.has(craft_id):
		return false
	var entry: Dictionary = _craft_visuals[craft_id]
	var pad: Dictionary = _pad_definition(String(entry.landing_pad_id))
	if pad.is_empty():
		return false
	_focused_craft_id = craft_id
	if _pad_preview: _view.set("_camera_size",8.5)
	_view.call("focus_world_position", _world_at_grid(pad.grid))
	_view.call("_request_viewport_redraw")
	if _pad_preview:
		_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	return true


func _focus_preview_pad(craft_id: String) -> void:
	if _preview_pad_id.is_empty():
		focus_craft_pad(craft_id)
		return
	var pad := _pad_definition(_preview_pad_id)
	if pad.is_empty(): return
	_focused_craft_id = craft_id
	_view.set("_camera_size", 8.5)
	_view.call("focus_world_position", _world_at_grid(pad.grid))
	_view.call("_request_viewport_redraw")


func _pad_definition(pad_id: String) -> Dictionary:
	for pad in Array(_layout.get("landing_pads", [])):
		if String(pad.get("id", "")) == pad_id:
			return Dictionary(pad)
	return {}


func _update_craft_projection() -> void:
	if _authored_stage == null:
		return
	_sync_capacity_visuals(_authored_stage)
	var present: Dictionary = {}
	var occupied_pads: Dictionary = {}
	for craft in _transport_projection:
		var craft_id: String = String(craft.get("craft_id", ""))
		var pad_id: String = String(craft.get("landing_pad_id", ""))
		var pad: Dictionary = _pad_definition(pad_id)
		if craft_id.is_empty() or pad.is_empty() or (Dictionary(craft.get("pad_visual",{})).is_empty() and (not bool(craft.get("visible_on_pad", false)) or String(craft.get("location_id", "")) != "homebase")) or occupied_pads.has(pad_id):
			continue
		present[craft_id] = true
		occupied_pads[pad_id] = craft_id
		var identity: Dictionary = SHIP_VISUALS.get_ui_identity(craft)
		var model_path: String = String(identity.get("model_path", ""))
		if _craft_visuals.has(craft_id):
			var previous: Dictionary = _craft_visuals[craft_id]
			if String(previous.model_path) == model_path and String(previous.landing_pad_id) == pad_id:
				_apply_pad_flight_display(previous,craft)
				continue
			(previous.node as Node3D).queue_free()
		var owner := Node3D.new()
		owner.name = "ActualCraft_" + craft_id.validate_node_name()
		owner.set_meta("craft_id", craft_id)
		owner.set_meta("landing_pad_id", pad_id)
		owner.position = _plane_position(pad.plane)
		_authored_stage.add_child(owner)
		if not model_path.is_empty() and ResourceLoader.exists(model_path):
			var model: Node3D = _load_visual({"id": craft_id, "path": model_path, "scale": float(identity.get("scale", 1.0)), "source_status": "real craft projected at assigned runtime pad"})
			if model != null:
				owner.add_child(model)
				model.rotation_degrees.y = float(identity.get("root_rotation_y_degrees", 0.0))
				if String(identity.get("asset_id",""))=="cutlass_01" or String(identity.get("model_id","")).contains("cutlass") or model_path.to_lower().contains("cutlass"):
					var exhaust: Node3D=FLIGHT_VISUAL_SCRIPT.new(); exhaust.name="ReadOnlyFlightVisual"; model.add_child(exhaust); exhaust.configure_cutlass_ref03()
		var label := Label3D.new()
		label.text = SHIP_VISUALS.get_ui_display_name(craft) + " · " + craft_id
		label.font_size = 38
		label.pixel_size = 0.005
		label.position = Vector3(0.0, 1.65, 0.0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		owner.add_child(label)
		_craft_visuals[craft_id] = {"node": owner, "landing_pad_id": pad_id, "model_path": model_path}
		_apply_pad_flight_display(_craft_visuals[craft_id],craft)
	for craft_id in _craft_visuals.keys():
		if not present.has(craft_id):
			(_craft_visuals[craft_id].node as Node3D).queue_free()
			_craft_visuals.erase(craft_id)
	if not _craft_visuals.has(_focused_craft_id):
		_focused_craft_id = ""
	_view.call("_request_viewport_redraw")
	if _pad_preview:
		_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_host = SubViewportContainer.new()
	_host.name = "BaseWorldViewport"
	_host.stretch = true
	_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_host.focus_mode = Control.FOCUS_ALL
	add_child(_host)
	_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.gui_input.connect(_on_world_gui_input)
	_host.focus_exited.connect(_clear_keyboard_input)
	_viewport = SubViewport.new()
	_viewport.name = "BaseWorld"
	_viewport.own_world_3d = true
	_viewport.world_2d = World2D.new()
	_viewport.gui_disable_input = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_host.add_child(_viewport)
	_build_overlay()
	visibility_changed.connect(_on_visibility_changed)
	set_active(_active)


func set_active(active: bool) -> void:
	var was_preview: bool = _pad_preview
	_pad_preview = false
	_active = active
	if not is_node_ready():
		return
	visible = active
	if _screen_labels_host!=null: _screen_labels_host.visible=active
	if active and not _initialized:
		_initialize_runtime()
	if active and was_preview and _view != null:
		_view.set("_camera_size", 26.0)
		_view.call("focus_world_position", _world_at_grid([68,52]))
	if _runtime != null:
		_runtime.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		if _personnel_runtime() == null:
			_sim.set_physics_process(active)
		if _model != null:
			_model.visible = true
	_host.focus_mode = Control.FOCUS_ALL
	_host.mouse_filter = Control.MOUSE_FILTER_STOP
	get_node("ExplorationHelp").visible = true
	get_node("ExitExploration").visible = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	if _drone_helper != null:
		_drone_helper.call("set_operating_visual", active)
	if not active:
		_camera_dragging = false
		_clear_base_context()
		_clear_keyboard_input()
		if _sim != null and _personnel_runtime() == null:
			_sim.call("clear_queues")
	set_process(active)
	set_physics_process(active)
	set_process_unhandled_key_input(active)
	if active:
		_host.grab_focus()
		_update_nearby_terminal()


func _on_visibility_changed() -> void:
	if _active and not is_visible_in_tree():
		set_active(false)


func _initialize_runtime() -> void:
	_layout = BASE_NAV.layout(_map_path)
	_map_data = MAP_SCRIPT.load_from_file(_map_path)
	var personnel: Node = _personnel_runtime()
	if personnel != null: _layout = Dictionary(personnel.call("get_snapshot").get("layout",_layout)).duplicate(true)
	# The campaign owner already loaded its fine movement map. The view only
	# needs coarse render extents and borrows that owner's registry below.
	_navigation_data = BASE_NAV.load_map(_map_path) if personnel == null else _map_data
	_runtime = Node.new()
	_runtime.name = "HomebaseRuntime"
	_viewport.add_child(_runtime)
	if personnel != null:
		_terrain = personnel.call("get_terrain_registry")
		_units = personnel.call("get_unit_registry")
		_sim = personnel.call("get_simulation_root")
	else:
		_terrain = TERRAIN_SCRIPT.new()
		_terrain.name = "TerrainRegistry"
		_runtime.add_child(_terrain)
		var tile_size: Dictionary = _navigation_data.get_tile_size()
		_terrain.call("configure_iso_grid", _navigation_data.get_grid_origin(), tile_size["half_width"], tile_size["half_height"], _navigation_data.get_grid_topology())
	var first: bool = true
	for tile in _navigation_data.get_tiles():
		if personnel == null:
			_terrain.call("register_tile", tile)
		if first:
			_map_bounds = Rect2(tile.world_position, Vector2.ZERO)
			first = false
		else:
			_map_bounds = _map_bounds.expand(tile.world_position)
	if personnel == null:
		_navigation_graph = BASE_NAV.new()
		_navigation_graph.call("configure_graph", _terrain)
		_units = UNITS_SCRIPT.new()
		_units.name = "UnitRegistry"
		_runtime.add_child(_units)
		_sim = SIM_SCRIPT.new()
		_sim.name = "SimulationRoot"
		_sim.set("unit_registry_path", NodePath("../UnitRegistry"))
		_sim.set("terrain_registry_path", NodePath("../TerrainRegistry"))
		_runtime.add_child(_sim)
		_avatar = AVATAR_SCRIPT.new()
		_avatar.name = "CommanderAvatar"
		_runtime.add_child(_avatar)
		_avatar.position = _world_at_grid(_layout.get("avatar_spawn_grid", [7, 11]))
		_units.call("register_unit", AVATAR_SCRIPT.UNIT_ID, _avatar)
		_sim.call("register_known_unit", AVATAR_SCRIPT.UNIT_ID, _avatar)
	else:
		var people: Array = personnel.call("get_snapshot").get("units", [])
		if not people.is_empty():
			_selected_person_id = String(people[0].unit_id)
			_avatar = personnel.call("get_actor", _selected_person_id)
	_view = VIEW_SCRIPT.new()
	_view.name = "Primary3DView"
	_runtime.add_child(_view)
	_view.call("set_frontier_art_enabled", true)
	_view.call("set_hex_grid_visible", false)
	_view.call("set_authoring_markers_visible",false)
	_view.call("configure_from_map", _map_data)
	_view.set("_camera_size", 16.0)
	_view.set("_camera_yaw_degrees", 24.0)
	_view.set("_camera_pitch_degrees", VIEW_SCRIPT.DEFAULT_CAMERA_PITCH_DEGREES)
	_view.call("focus_world_position", _avatar.position)
	var world: Node3D = _view.get_node("ViewportContainer/SubViewport/WorldRoot") as Node3D
	var stage := Node3D.new()
	_authored_stage = stage
	stage.name = "HomebaseAuthoredVisuals"
	world.add_child(stage)
	for asset_variant in Array(_layout.get("assets", [])):
		var asset: Dictionary = Dictionary(asset_variant)
		# Historical authored prop remains in source data for traceability, but
		# only real craft definitions may instantiate a ship on an occupied pad.
		if String(asset.get("id", "")) == "cutlass_01":
			continue
		var visual: Node3D = _load_visual(asset)
		if visual != null:
			stage.add_child(visual)
			visual.position = _plane_position(asset.get("plane", [0.0, 0.0]))
			if String(asset.get("id", "")) in ["habitat_cutaway_01", "freihafen_hall_01"]:
				# Furnished cutaway sources are the user's base target. Navigation
				# remains in MapData; source meshes are never replaced or rewritten.
				var id: String = String(asset.id)
				_structure_visual_nodes[id] = visual
				_structure_visual_records[id] = {"source_path": String(asset.path), "actual_sha256": String(_asset_sources.back().get("actual_sha256", "")), "route": String(asset.get("visual_route", "original_furnished_cutaway_glb")), "original_path": String(asset.get("original_path", asset.path))}
	_build_landing_pads(stage)
	_sync_capacity_visuals(stage)
	# Natural authored geology replaces the former decorative block fence.
	var avatar_visual: Dictionary = Dictionary(_layout.get("avatar_visual", {}))
	_model = _load_visual(avatar_visual) if personnel == null else null
	if _model != null:
		_model.name = "CommanderVisual"
		stage.add_child(_model)
		var players: Array[Node] = _model.find_children("*", "AnimationPlayer", true, false)
		_player = players[0] as AnimationPlayer if not players.is_empty() else null
		if _player != null:
			for clip in _player.get_animation_list():
				if String(clip).to_lower().ends_with("idle"):
					_idle_clip = String(clip)
				if String(clip).to_lower().ends_with("walk"):
					_walk_clip = String(clip)
			if not _idle_clip.is_empty():
				_player.play(_idle_clip)
	_build_terminals(stage)
	_build_service_drone(stage)
	# These stored blockers are the footprints of the authored scene above.
	# Register its visual ownership so generic missing-asset boxes do not draw
	# through the real buildings and parked ship. Navigation facts stay intact.
	var footprint_visuals: Dictionary = {}
	for tile in _map_data.get_tiles():
		if not bool(tile.walkable) and String(tile.object_type_id).is_empty():
			footprint_visuals[Vector2i(tile.grid_position)] = stage
	_view.call("set_external_terrain_object_visuals", footprint_visuals)
	_previous_position = _avatar.position
	_initialized = true
	if personnel != null:
		_build_personnel_visuals(stage)
		_build_personnel_controls()
	_update_craft_projection()
	_update_avatar_visual()


func _load_visual(source: Dictionary) -> Node3D:
	var path: String = String(source.get("path", ""))
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return null
	var visual: Node3D = scene.instantiate() as Node3D
	visual.scale = Vector3.ONE * float(source.get("scale", 1.0))
	var fact: Dictionary = source.duplicate(true)
	fact["actual_sha256"] = FileAccess.get_sha256(path)
	_asset_sources.append(fact)
	return visual


func _world_at_grid(raw_grid: Variant) -> Vector2:
	var grid: Array = Array(raw_grid)
	return _terrain.call("grid_to_world", Vector2i(int(grid[0]), int(grid[1])))


func _visual_bounds(visual: Node3D) -> AABB:
	var bounds := AABB()
	var first: bool = true
	for node in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var current: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = current if first else bounds.merge(current)
		first = false
	return bounds


func _plane_position(raw_plane: Variant) -> Vector3:
	var plane: Array = Array(raw_plane)
	return Vector3(float(plane[0]), 0.0, float(plane[1]))


func request_walk_to(world_position: Vector2) -> bool:
	if _pad_preview or not _active or not _initialized or not is_visible_in_tree():
		return false
	if _personnel_runtime() != null:
		var result: Dictionary = _personnel_action("base_move", {"target_position": world_position})
		if bool(result.get("ok", false)):
			_movement_command_count += 1
		return bool(result.get("ok", false))
	var grid: Vector2i = _terrain.call("world_to_grid", world_position)
	if not bool(_terrain.call("is_walkable", grid)):
		return false
	var target: Vector2 = _terrain.call("grid_to_world", grid)
	var path: Array = _navigation_graph.call("find_world_path", _avatar.position, target)
	if path.is_empty():
		return false
	_command_sequence += 1
	_sim.call("enqueue_command", {
		"type": "move_to_position", "unit_id": AVATAR_SCRIPT.UNIT_ID,
		"target_position": target, "path": path,
		"navigation_path_terrain_revision": _terrain.call("get_revision"),
		"command_token": "homebase_walk_%d" % _command_sequence,
		"requeue_until_target": true,
	})
	_movement_command_count += 1
	return true


func request_terminal(id: String) -> bool:
	if _pad_preview or not _active or not _initialized or not is_visible_in_tree():
		return false
	if _personnel_runtime() != null:
		return bool(_personnel_action("base_terminal", {"terminal_id": id}).get("ok", false))
	for terminal in _terminals:
		if String(terminal["id"]) == id and bool(terminal.get("enabled", true)) and _terminal_distance(terminal) <= INTERACTION_RADIUS:
			_stop_avatar()
			terminal_open_requested.emit(id)
			return true
	return false


func _stop_avatar() -> void:
	if _sim == null:
		return
	if _personnel_runtime() != null:
		_personnel_action("base_cancel")
		return
	_command_sequence += 1
	_sim.call("enqueue_command", {"type": "hold_position", "unit_id": AVATAR_SCRIPT.UNIT_ID, "command_token": "homebase_hold_%d" % _command_sequence})


func _on_world_gui_input(event: InputEvent) -> void:
	if not _active or not _initialized:
		return
	if event is InputEventMouseButton and event.pressed:
		_host.grab_focus()
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_camera_dragging = true
			_camera_drag_last = _host.get_global_transform_with_canvas() * event.position
			_manual_camera = true
			_host.accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			var context := get_base_world_context(event.position)
			if not context.is_empty():
				activate_base_world_context(event.position)
				_host.accept_event()
				return
			var local: Vector2 = event.position * Vector2(_viewport.size) / _host.size.max(Vector2.ONE)
			var target: Variant = _view.call("screen_to_world_plane_position", local)
			if typeof(target) == TYPE_VECTOR2:
				var plane: Vector3 = _view.call("_world_to_3d_position", Vector2(target), 0.0)
				target = _view.call("screen_to_world_plane_position", local, BASE_NAV.standing_y(plane))
				request_walk_to(Vector2(target))
			_host.accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_manual_camera = true
			_view.call("zoom_camera_at_screen_position", 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0, event.position * Vector2(_viewport.size) / _host.size.max(Vector2.ONE))
			_host.accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if _select_person_at(event.position):
				if event.double_click: _personnel_action("details")
				_host.accept_event()
				return
			var context := get_base_world_context(event.position)
			if not context.is_empty() and context.kind=="ship":
				select_world_craft(String(context.id))
				_host.accept_event()
				return
			clear_world_selection()
			_host.accept_event()
			return


func _unhandled_key_input(event: InputEvent) -> void:
	if not _active or not _initialized or not _host.has_focus() or not event is InputEventKey:
		return
	var key: Key = event.physical_keycode
	if key in [KEY_W, KEY_A, KEY_S, KEY_D]:
		_keys[key] = event.pressed
		get_viewport().set_input_as_handled()
	elif event.pressed and not event.echo and key == KEY_E:
		request_terminal(_nearby_terminal)
		get_viewport().set_input_as_handled()
	elif event.pressed and not event.echo and key == KEY_ESCAPE:
		exploration_exit_requested.emit()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not _active or not _initialized:
		return
	var direction := Vector2(float(bool(_keys.get(KEY_D, false))) - float(bool(_keys.get(KEY_A, false))), float(bool(_keys.get(KEY_S, false))) - float(bool(_keys.get(KEY_W, false))))
	if direction.is_zero_approx() or not _host.has_focus():
		if _keyboard_move:
			_stop_avatar()
		_keyboard_move = false
		_move_cadence = 0.0
		return
	_keyboard_move = true
	_move_cadence -= delta
	if _move_cadence > 0.0:
		return
	_move_cadence = 0.16
	var yaw: float = deg_to_rad(float(_view.call("get_camera_yaw_degrees")))
	var plane_direction: Vector2 = Vector2(cos(yaw), -sin(yaw)) * direction.normalized().x + Vector2(sin(yaw), cos(yaw)) * direction.normalized().y
	var origin_3d: Vector3 = _view.call("_world_to_3d_position", _avatar.position, 0.0)
	var target: Vector2 = _view.call("_position_3d_to_world", origin_3d + Vector3(plane_direction.x, 0.0, plane_direction.y) * 1.4)
	request_walk_to(target)


func _clear_keyboard_input() -> void:
	_keys.clear()
	# The campaign owner keeps accepted movement running while its view is
	# hidden. Clearing local input must not emit a gameplay cancel command.
	if _keyboard_move and _personnel_runtime() == null:
		_stop_avatar()
	_keyboard_move = false


func _process(delta: float) -> void:
	if not _active or not _initialized: return
	_advance_pad_flight_effects(delta)
	if _pad_preview: return
	_context_elapsed += delta
	if _context_elapsed >= .1:
		_context_elapsed = 0.0
		_refresh_base_context()
		_refresh_screen_world_labels()
	_update_avatar_visual()
	_personnel_ui_elapsed -= delta
	if _personnel_runtime() != null and _personnel_ui_elapsed <= 0.0:
		_personnel_ui_elapsed = 0.2
		_update_personnel_controls()
	_update_nearby_terminal()
	if _drone_helper != null and bool(_drone_helper.call("advance_visual", delta)):
		_view.call("_request_viewport_redraw")


func _update_avatar_visual() -> void:
	if _personnel_runtime() != null:
		_update_personnel_visuals()
		return
	if _model == null:
		return
	var position_3d: Vector3 = _view.call("_world_to_surface_3d_position", _avatar.position, 0.006)
	var displacement: Vector3 = position_3d - _model.position
	var moving: bool = _avatar.position.distance_squared_to(_previous_position) > 0.00001
	_model.position = position_3d
	if moving:
		_focused_craft_id = ""
		_model.rotation.y = atan2(displacement.x, displacement.z)
		if not _manual_camera: _view.call("focus_world_position", _avatar.position)
	if moving != _walking and _player != null:
		var clip: String = _walk_clip if moving else _idle_clip
		if not clip.is_empty():
			_player.play(clip, 0.15)
	_walking = moving
	_previous_position = _avatar.position
	_view.call("_request_viewport_redraw")


func _build_terminals(stage: Node3D) -> void:
	for raw_terminal in Array(_layout.get("terminals", [])):
		var terminal: Dictionary = Dictionary(raw_terminal).duplicate(true)
		if String(terminal.get("id", "")) == "flightdeck": terminal["title"] = "Flugdeck"
		if String(terminal.get("id", "")) == "refuel":
			terminal["enabled"] = _refuel_service_available
		terminal["world_position"] = _world_at_grid(terminal["grid"])
		_terminals.append(terminal)
		var position_3d: Vector3 = _view.call("_world_to_surface_3d_position", terminal["world_position"], 0.0)
		# The furnished rooms already have desks and monitors. Mark their usable
		# approach points instead of intersecting them with extra console boxes.
		var label := Label3D.new()
		label.text = String(terminal["title"])
		label.font_size = 32
		label.pixel_size = 0.004
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color("eaf2df")
		label.position = position_3d + Vector3(0.0, 0.95, 0.0)
		stage.add_child(label)
		_terminal_labels[String(terminal["id"])] = label


func _build_authored_interiors(stage: Node3D) -> void:
	# Read authoring facts only: this builder never mutates a terrain tile.
	for raw_room in Array(_layout.get("interiors", [])):
		var room: Dictionary = Dictionary(raw_room)
		var owner := Node3D.new()
		owner.name = "Cutaway_" + String(room["id"])
		owner.set_meta("visual_status", String(room.get("visual_status", "candidate")))
		stage.add_child(owner)
		for raw_floor in Array(room.get("floor_grids", [])):
			var point: Vector3 = _view.call("_world_to_3d_position", _world_at_grid(raw_floor), 0.0)
			_hex_column(owner, point, 0.025, Color("777f72"), -0.025)
		for raw_wall in Array(room.get("wall_grids", [])):
			var point: Vector3 = _view.call("_world_to_3d_position", _world_at_grid(raw_wall), 0.0)
			_hex_column(owner, point, 1.35, Color("cfc8ae"), 0.0)
			_hex_column(owner, point, 0.10, Color("376b75"), 1.35)
			_cutaway_wall_visual_count += 1
		var door: Vector3 = _view.call("_world_to_3d_position", _world_at_grid(room["door_grid"]), 0.0)
		_box(owner, Vector3(1.12, 0.16, 0.18), door + Vector3(0.0, 1.53, 0.0), Color("376b75"))
		for side in [-1.0, 1.0]:
			_box(owner, Vector3(0.10, 1.52, 0.18), door + Vector3(side * 0.54, 0.76, 0.0), Color("376b75"))


func _hex_column(parent: Node3D, point: Vector3, height: float, color: Color, bottom: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.radial_segments = 6
	mesh.rings = 1
	mesh.top_radius = 0.58
	mesh.bottom_radius = 0.58
	mesh.height = height
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	visual.material_override = material
	visual.position = point + Vector3(0.0, bottom + height * 0.5, 0.0)
	parent.add_child(visual)


func _build_landing_pads(stage: Node3D) -> void:
	for raw_pad in Array(_layout.get("landing_pads", [])):
		var pad: Dictionary = Dictionary(raw_pad)
		var visual: Node3D = PAD_SCRIPT.new()
		visual.name = String(pad["id"])
		visual.set_meta("landing_pad_id", String(pad["id"]))
		stage.add_child(visual)
		var center: Array = Array(pad["plane"])
		var pad_size: Array = Array(pad["size"])
		visual.call("build", Vector2(float(center[0]), float(center[1])), Vector2(float(pad_size[0]), float(pad_size[1])), String(pad["designation"]) if bool(pad.get("built",true)) else "BAUPLATZ · PAD 02")
		if not bool(pad.get("built",true)): visual.scale.y=0.15
		# Deck top coincides with authored ground height; no hidden visual step.
		visual.position.y = float(pad.get("surface_y", 0.0)) - PAD_SCRIPT.DECK_HEIGHT


func _build_boundary_rocks(stage: Node3D) -> void:
	var size_value: Vector2i = _map_data.get_grid_size()
	for tile in _map_data.get_tiles():
		var grid: Vector2i = tile.grid_position
		if grid.x != 0 and grid.y != 0 and grid.x != size_value.x - 1 and grid.y != size_value.y - 1:
			continue
		var point: Vector3 = _view.call("_world_to_3d_position", tile.world_position, 0.0)
		_hex_column(stage, point, 0.45 + float(posmod(grid.x + grid.y, 3)) * 0.15, Color("777c6b"), 0.0)


func _terminal_distance(terminal: Dictionary) -> float:
	var avatar_plane: Vector3 = _view.call("_world_to_3d_position", _avatar.position, 0.0)
	var terminal_plane: Vector3 = _view.call("_world_to_3d_position", terminal["world_position"], 0.0)
	return avatar_plane.distance_to(terminal_plane)


func _update_nearby_terminal() -> void:
	var nearest: String = ""
	var title: String = ""
	var distance_value: float = INTERACTION_RADIUS
	for terminal in _terminals:
		var distance_candidate: float = _terminal_distance(terminal)
		if bool(terminal.get("enabled", true)) and distance_candidate <= distance_value:
			distance_value = distance_candidate
			nearest = String(terminal["id"])
			title = String(terminal["title"])
	if nearest == _nearby_terminal:
		return
	_nearby_terminal = nearest
	_interact.disabled = nearest.is_empty()
	_interact.text = "E · " + title if not nearest.is_empty() else "Konsole aufsuchen"
	for id in _terminal_labels:
		(_terminal_labels[id] as Label3D).modulate = Color("ffe08b") if String(id) == nearest else Color("eaf2df")


func _build_service_drone(stage: Node3D) -> void:
	var drone_owner := Node3D.new()
	drone_owner.name = "AuthoredServiceDrone"
	drone_owner.position = _plane_position(Dictionary(_layout.get("service_drone", {})).get("plane", [17.1, 10.7]))
	stage.add_child(drone_owner)
	_drone_model = Node3D.new()
	_drone_model.name = "ServiceDroneVisual"
	_drone_model.position.y = 0.85
	drone_owner.add_child(_drone_model)
	_box(_drone_model, Vector3(0.38, 0.15, 0.28), Vector3.ZERO, Color("cbd4c5"))
	_box(_drone_model, Vector3(0.18, 0.05, 0.22), Vector3(0.0, 0.10, 0.0), Color("326a69"))
	_box(_drone_model, Vector3(0.09, 0.06, 0.025), Vector3(0.0, 0.0, 0.15), Color("2ac6c7"))
	_drone_helper = FLIGHT_VISUAL_SCRIPT.new()
	_drone_helper.name = "ReadOnlyDroneMotion"
	drone_owner.add_child(_drone_helper)
	var nozzles: Array[Vector3] = [Vector3(0.0, 0.76, 0.0)]
	_drone_helper.call("configure_service_drone", _drone_model, nozzles)
	_drone_helper.call("set_operating_visual", true)


func _box(parent: Node3D, size_value: Vector3, position_value: Vector3, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	visual.material_override = material
	visual.position = position_value
	parent.add_child(visual)
	return visual


func _build_overlay() -> void:
	var panel := VBoxContainer.new()
	panel.name = "ExplorationHelp"
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -420.0
	panel.offset_top = -118.0
	panel.offset_right = -24.0
	panel.offset_bottom = -22.0
	_interact = Button.new()
	_interact.name = "InteractTerminal"
	_interact.text = "Konsole aufsuchen"
	_interact.disabled = true
	_interact.custom_minimum_size.y = 40.0
	_interact.pressed.connect(func(): request_terminal(_nearby_terminal))
	panel.add_child(_interact)
	_hint = Label.new()
	_hint.text = "WASD gehen · Rechtsklick Ziel · E Konsole"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(_hint)
	var exit := Button.new()
	exit.name = "ExitExploration"
	exit.text = "Übersicht  ·  Esc"
	exit.pressed.connect(func(): exploration_exit_requested.emit())
	add_child(exit)
	exit.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	exit.offset_left = -196.0
	exit.offset_top = 20.0
	exit.offset_right = -24.0
	exit.offset_bottom = 64.0


func get_exploration_snapshot() -> Dictionary:
	var projected_crafts: Array = []
	for craft_id in _craft_visuals:
		var entry: Dictionary = _craft_visuals[craft_id]
		projected_crafts.append({"craft_id": String(craft_id), "landing_pad_id": String(entry.landing_pad_id), "model_path": String(entry.model_path), "visual_instance_id": (entry.node as Node3D).get_instance_id()})
	var result: Dictionary = {
		"initialized": _initialized, "active": _active,
		"preview_mode": _pad_preview,
		"map_path": _map_path, "movement_owner": "SimulationRoot",
		"owns_roster": false, "owns_transport": false, "owns_inventory": false,
		"ephemeral_commander": _personnel_runtime() == null, "read_only": true,
		"selected_person_id": _selected_person_id,
		"personnel": _personnel_runtime().call("get_snapshot") if _personnel_runtime() != null else {},
		"tree_paused": get_tree().paused if is_inside_tree() else false,
		"projected_crafts": projected_crafts, "focused_craft_id": _focused_craft_id,
	}
	if not _initialized:
		return result
	result.merge({
		"map_grid_size": _map_data.get_grid_size(), "map_bounds": _map_bounds,
		"avatar_position": _avatar.position, "avatar_instance_id": _avatar.get_instance_id(),
		"registered_unit_count": Array(_units.call("get_all_units")).size(),
		"simulation_ticks": int(_sim.get("tick_counter")),
		"movement_command_count": _movement_command_count,
		"terminals": _terminals.duplicate(true), "nearby_terminal": _nearby_terminal,
		"interiors": Array(_layout.get("interiors", [])).duplicate(true),
		"landing_pads": Array(_layout.get("landing_pads", [])).duplicate(true),
		"expansion_areas": Array(_layout.get("expansion_areas", [])).duplicate(true),
		"cutaway_wall_visual_count": _cutaway_wall_visual_count,
		"structure_visuals": _get_structure_visual_snapshot(),
		"initial_walk_target": _world_at_grid(_layout.get("initial_walk_target_grid", [9, 11])),
		"blocked_test_position": _world_at_grid(_layout.get("blocked_test_grid", [11, 9])), "distant_terminal_id": "flightdeck",
		"asset_sources": _asset_sources.duplicate(true),
		"service_drone": {"decorative": true, "runtime_unit": false, "model_local_position": _drone_model.position, "model_local_rotation": _drone_model.rotation, "exhaust": _drone_helper.call("get_visual_snapshot")},
		"viewport_size": _viewport.size, "world_focus": _host.has_focus(),
	}, true)
	return result


func _get_structure_visual_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for id in _structure_visual_nodes:
		var visual: Node3D = _structure_visual_nodes[id]
		if is_instance_valid(visual):
			var record: Dictionary = Dictionary(_structure_visual_records[id]).duplicate(true)
			record["visible"] = visual.visible
			result[id] = record
	return result


var _capacity_visual_count: int = -1
func _sync_capacity_visuals(stage: Node3D) -> void:
	var personnel: Node = _personnel_runtime()
	if personnel == null: return
	var layout: Dictionary = personnel.call("get_snapshot").get("layout",{})
	var count := Array(layout.get("beds",[])).size()*100+Array(layout.get("landing_pads",[])).size()
	if Array(layout.get("landing_pads",[])).size()>1 and bool(layout.landing_pads[1].get("built",true)):count+=10000
	if count==_capacity_visual_count:return
	_capacity_visual_count=count
	_layout=layout.duplicate(true)
	for bed: Dictionary in Array(layout.get("beds",[])):
		if String(bed.get("visual_kind",""))!="field_bunk" or stage.has_node(String(bed.id)):continue
		var owner:=Node3D.new(); owner.name=String(bed.id); stage.add_child(owner)
		var plane: Array=bed.get("sleep_plane",bed.get("rest_plane",[0,0]))
		owner.position=Vector3(float(plane[0]),0,float(plane[1]))
		var mesh:=BoxMesh.new(); mesh.size=Vector3(0.65,0.22,1.8)
		var cot:=MeshInstance3D.new(); cot.mesh=mesh; cot.position.y=0.3; owner.add_child(cot)
		var material:=StandardMaterial3D.new(); material.albedo_color=Color(0.25,0.37,0.32); cot.material_override=material
		var pillow:=MeshInstance3D.new(); var pillow_mesh:=BoxMesh.new(); pillow_mesh.size=Vector3(0.56,0.12,0.34); pillow.mesh=pillow_mesh; pillow.position=Vector3(0,0.47,-0.65); owner.add_child(pillow)
	for pad: Dictionary in Array(layout.get("landing_pads",[])):
		if stage.has_node(String(pad.id)):
			stage.get_node(String(pad.id)).scale.y=1.0 if bool(pad.get("built",true)) else 0.15
			var designation: Node=stage.get_node(String(pad.id)).get_node_or_null("PadDesignation")
			if designation!=null:designation.text=String(pad.designation) if bool(pad.get("built",true)) else "BAUPLATZ · PAD 02"
			continue
		var visual: Node3D=PAD_SCRIPT.new(); visual.name=String(pad.id); stage.add_child(visual)
		visual.set_meta("landing_pad_id",String(pad.id))
		visual.call("build",Vector2(float(pad.plane[0]),float(pad.plane[1])),Vector2(float(pad.size[0]),float(pad.size[1])),String(pad.designation))
		visual.position.y=float(pad.get("surface_y",0))-PAD_SCRIPT.DECK_HEIGHT

func _input(event: InputEvent) -> void:
	if not _active or _pad_preview or not is_visible_in_tree(): _camera_dragging=false; return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_MIDDLE and not event.pressed:
		_camera_dragging=false
	elif event is InputEventMouseMotion and _camera_dragging:
		var transform := _host.get_global_transform_with_canvas().affine_inverse()
		var scale := Vector2(_viewport.size)/_host.size.max(Vector2.ONE)
		_view.call("pan_camera_between_screen_positions",(transform*_camera_drag_last)*scale,(transform*event.position)*scale)
		_camera_drag_last=event.position
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_EXIT_TREE]:
		_camera_dragging=false
		_clear_base_context()

func get_base_world_context(point: Vector2) -> Dictionary:
	if not _active or _pad_preview or _personnel_runtime()==null: return {}
	var scale := _host.size.max(Vector2.ONE)/Vector2(_viewport.size).max(Vector2.ONE)
	for key in _screen_world_labels:
		var label: Label=_screen_world_labels[key]
		if not label.visible or not Rect2(label.position,label.size).has_point(point): continue
		if String(key).begins_with("ship:"): return {"id":String(key).trim_prefix("ship:"),"kind":"ship","label":"Einsteigen"}
	var candidates: Array=[]
	for id in _craft_visuals:
		var entry: Dictionary=_craft_visuals[id]
		var pad: Dictionary=_pad_definition(String(entry.landing_pad_id))
		if pad.is_empty(): continue
		candidates.append({"id":id,"kind":"ship","label":"Einsteigen","screen_position":Vector2(_view.call("world_to_screen_position",_world_at_grid(pad.grid)))*scale})
	for terminal: Dictionary in _terminals:
		candidates.append({"id":terminal.id,"kind":"terminal","label":String(terminal.get("title","Benutzen")),"blocked":not bool(terminal.get("enabled",true)),"screen_position":Vector2(_view.call("world_to_screen_position",terminal.world_position))*scale})
	return CONTEXT_ACTIONS.choose(point,candidates)

func activate_base_world_context(point: Vector2) -> Dictionary:
	var action:=get_base_world_context(point)
	if action.is_empty(): return {"ok":false,"reason":"no_target"}
	if action.get("blocked",false): return {"ok":false,"reason":"unavailable"}
	if action.kind=="ship" and _selected_person_id.is_empty(): return {"ok":false,"message":"Zuerst eine Person auswählen"}
	if action.kind=="ship": return _personnel_action("base_board",{"craft_id":String(action.id)})
	return {"ok":request_terminal(String(action.id))}

func _refresh_base_context() -> void:
	if _world_context_hint==null:
		_world_context_hint=Label.new(); _world_context_hint.name="BaseWorldContextHint"; _world_context_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
		_world_context_hint.add_theme_font_size_override("font_size",16); add_child(_world_context_hint)
	var point := _host.get_local_mouse_position()
	var action:=get_base_world_context(point) if Rect2(Vector2.ZERO,_host.size).has_point(point) and get_viewport().gui_get_hovered_control()==_host and not _camera_dragging else {}
	if action.is_empty(): _clear_base_context(); return
	_world_context_hint.text="Schiffdetails · Linksklick" if action.kind=="ship" and _selected_person_id.is_empty() else String(action.label)+(" · nicht verfügbar" if action.get("blocked",false) else " · Rechtsklick")
	_world_context_hint.position=get_local_mouse_position()+Vector2(18,22); _world_context_hint.show()
	Input.set_default_cursor_shape(Input.CURSOR_FORBIDDEN if action.get("blocked",false) else Input.CURSOR_POINTING_HAND); _base_owns_cursor=true

func _clear_base_context() -> void:
	if _world_context_hint!=null: _world_context_hint.hide()
	if _base_owns_cursor: Input.set_default_cursor_shape(Input.CURSOR_ARROW); _base_owns_cursor=false

func get_selected_world_craft_id() -> String:
	return _selected_world_craft_id

func select_world_craft(craft_id: String) -> bool:
	if not _craft_visuals.has(craft_id): return false
	_selected_world_craft_id=craft_id
	_selected_person_id=""
	world_selection_changed.emit("ship",craft_id)
	_update_personnel_controls()
	return true

func clear_world_selection() -> void:
	_selected_person_id=""
	_selected_world_craft_id=""
	world_selection_changed.emit("","")
	_update_personnel_controls()

func _refresh_screen_world_labels() -> void:
	if _screen_labels_host==null:
		_screen_labels_host=Control.new(); _screen_labels_host.name="ScreenWorldLabels"; _screen_labels_host.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(_screen_labels_host)
	var entries: Array=[]
	var removed_world_text := false
	var overview_labels := float(_view.call("get_camera_size"))>32.0
	for id in _person_visuals:
		var actor: Node2D=_personnel_runtime().call("get_actor",id)
		var entry: Dictionary=_person_visuals[id]
		removed_world_text = (entry.label as Label3D).visible or removed_world_text
		(entry.label as Label3D).hide()
		if actor!=null and (entry.model as Node3D).visible and (not overview_labels or id==_selected_person_id):
			entries.append({"id":"person:"+id,"text":String(entry.get("display_name",(entry.label as Label3D).text)),"position":actor.position})
	for id in _terminal_labels:
		removed_world_text = (_terminal_labels[id] as Label3D).visible or removed_world_text
		(_terminal_labels[id] as Label3D).text=""
		(_terminal_labels[id] as Label3D).hide()
	for terminal: Dictionary in _terminals:
		if overview_labels and String(terminal.id) not in ["personnel","team","flightdeck"]: continue
		entries.append({"id":"terminal:"+String(terminal.id),"text":String(terminal.title),"position":terminal.world_position})
	for id in _craft_visuals:
		var craft: Dictionary=_craft_visuals[id]
		for child in (craft.node as Node3D).get_children():
			if child is Label3D:
				removed_world_text=child.visible or removed_world_text
				child.text=""
				child.hide()
		if overview_labels and id!=_selected_world_craft_id: continue
		entries.append({"id":"ship:"+id,"text":SHIP_VISUALS.get_ui_display_name(_find_projected_craft(id)),"position":_world_at_grid(_pad_definition(String(craft.landing_pad_id)).grid)})
	var shown: Dictionary={}
	var occupied: Array[Rect2]=[]
	var scale := _host.size.max(Vector2.ONE)/Vector2(_viewport.size).max(Vector2.ONE)
	for entry: Dictionary in entries:
		var point: Vector2=Vector2(_view.call("world_to_screen_position",entry.position))*scale+_host.position
		if not Rect2(_host.position,_host.size).has_point(point): continue
		var label: Label=_screen_world_labels.get(entry.id)
		if label==null:
			label=Label.new(); label.name="WorldLabel_"+String(entry.id).validate_node_name(); label.mouse_filter=Control.MOUSE_FILTER_IGNORE
			label.add_theme_font_size_override("font_size",16); label.add_theme_color_override("font_shadow_color",Color.BLACK); label.add_theme_constant_override("shadow_outline_size",3)
			_screen_labels_host.add_child(label); _screen_world_labels[entry.id]=label
		label.text=String(entry.text); label.reset_size(); label.size=label.get_combined_minimum_size()
		var rect:=Rect2(point-Vector2(label.size.x*.5,label.size.y+10),label.size)
		for attempt in range(mini(entries.size()+1,48)):
			if not occupied.any(func(other:Rect2):return other.grow(3).intersects(rect)): break
			rect.position.y-=maxf(label.size.y+6,22.0)
		label.position=rect.position; label.show(); shown[entry.id]=true; occupied.append(rect)
	for id in _screen_world_labels:
		if not shown.has(id): (_screen_world_labels[id] as Label).hide()

	if removed_world_text:
		_view.call("_request_viewport_redraw")
		_viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE

func _find_projected_craft(id: String) -> Dictionary:
	for craft: Dictionary in _transport_projection:
		if String(craft.get("craft_id",""))==id: return craft
	return {}

func _apply_pad_flight_display(entry: Dictionary, craft: Dictionary) -> void:
	var node: Node3D=entry.node
	var pad: Dictionary=_pad_definition(String(entry.landing_pad_id))
	var anchor:=_plane_position(pad.plane)
	var motion: Dictionary=craft.get("pad_visual",{})
	var phase:=String(motion.get("phase","landed"))
	node.position=anchor; node.rotation=Vector3.ZERO
	var thrust:=0.0
	if not motion.is_empty():
		var sample: Dictionary=FLIGHT_VISUAL_SCRIPT.sample_maneuver(phase,float(motion.progress))
		var departure:=phase=="departing"
		var offset:=float(sample.route_fraction) if departure else 1.0-float(sample.route_fraction)
		var identity: Dictionary=SHIP_VISUALS.get_ui_identity(craft)
		var forward:=Vector3(0,0,1).rotated(Vector3.UP,deg_to_rad(float(identity.get("root_rotation_y_degrees",0.0))))
		node.position=anchor+forward*(8.0*offset*(1.0 if departure else -1.0))+Vector3.UP*float(sample.clearance)
		node.basis=Basis(Vector3.UP.cross(forward).normalized(),-deg_to_rad(float(sample.pitch_degrees)))
		thrust=float(sample.thrust_fraction)
	for child in node.get_children():
		if not child is Node3D: continue
		var helper: Node=child.get_node_or_null("ReadOnlyFlightVisual")
		if helper!=null: helper.call("set_flight_response",phase,thrust)

func _advance_pad_flight_effects(delta: float) -> void:
	var changed:=false
	for entry: Dictionary in _craft_visuals.values():
		for child in (entry.node as Node3D).get_children():
			var helper: Node=child.get_node_or_null("ReadOnlyFlightVisual")
			if helper!=null: changed=bool(helper.call("advance_visual",delta)) or changed
	if changed:
		_view.call("_request_viewport_redraw")
		_viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
