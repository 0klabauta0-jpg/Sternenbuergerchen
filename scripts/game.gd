extends Node3D

const SimulationScript = preload("res://scripts/core/simulation_root.gd")
const WorldScript = preload("res://scripts/world/world_view.gd")
const HudScript = preload("res://scripts/ui/game_hud.gd")
const SessionScript = preload("res://scripts/network/session_gateway.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const ExpeditionScript = preload("res://scripts/ui/expedition_hud.gd")
const SAVE_PATH := "user://campaign.json"

var simulation: Node
var world: Node3D
var hud: CanvasLayer
var session: Node
var expedition: CanvasLayer
var save_path: String = SAVE_PATH
var load_on_start: bool = true
var simulation_seed: int = -1
var _auto_save_allowed := true
var _counter := 0
var _ui_elapsed := 0.0
var _capture_path := ""
var _capture_time := -1.0
var _capture_quit := false
var _direct_mode := false

func _ready() -> void:
	DisplayServer.window_set_title("Sternenbürgerchen · Rostgrenze · Neustart")
	simulation = SimulationScript.new(simulation_seed)
	simulation.name="Simulation"
	add_child(simulation)
	var startup_message := ""
	if load_on_start and FileAccess.file_exists(save_path):
		var restored: Dictionary=simulation.load_game(save_path)
		startup_message="Karriere fortgesetzt." if restored.get("ok",false) else str(restored.get("reason","Spielstand nicht lesbar."))
		_auto_save_allowed=bool(restored.get("ok",false))
	session=SessionScript.new()
	session.name="Session"
	add_child(session)
	session.setup(simulation)
	world=WorldScript.new()
	world.name="World"
	add_child(world)
	hud=HudScript.new()
	hud.name="HUD"
	add_child(hud)
	world.object_selected.connect(_on_object_selected)
	world.ground_clicked.connect(_on_ground_clicked)
	world.units_selected.connect(_on_units_selected)
	hud.command_requested.connect(send_command)
	hud.action_requested.connect(_on_action)
	expedition=ExpeditionScript.new()
	expedition.name="ExpeditionHUD"
	add_child(expedition)
	expedition.command_requested.connect(send_command)
	expedition.action_requested.connect(_on_action)
	simulation.notice.connect(hud.notify)
	session.connection_changed.connect(func(message: String): hud.notify(message))
	session.command_result.connect(func(result: Dictionary):
		if not result.get("ok",false): hud.notify(str(result.get("reason","Befehl abgelehnt"))))
	get_tree().auto_accept_quit=false
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="): _capture_path=argument.trim_prefix("--capture="); _capture_time=3.0
		if argument=="--capture-quit": _capture_quit=true
		if argument.begins_with("--join="): session.join_host(argument.trim_prefix("--join="))
		if argument=="--host": session.start_host()
	_refresh()
	if not startup_message.is_empty(): hud.notify(startup_message)

func send_command(command: Dictionary) -> Dictionary:
	_counter+=1
	var payload: Dictionary=command.duplicate(true)
	payload["request_id"]="ui-%s-%s-%s" % [OS.get_process_id(),Time.get_ticks_usec(),_counter]
	var result: Dictionary=session.dispatch(payload)
	if result.get("pending",false): hud.notify("Befehl wird beim Host geprüft …")
	if not result.get("ok",false): hud.notify(str(result.get("reason","Befehl abgelehnt")))
	_refresh()
	return result

func _on_object_selected(kind: String,id: String) -> void:
	if is_instance_valid(expedition) and expedition.inspect_target(id):
		hud.dismiss_context()
		if world.has_method("set_selection"): world.set_selection(kind,id)
		return
	hud.select_object(kind,id)
	if world.has_method("set_selection"): world.set_selection(kind,id)
	_refresh()

func _on_ground_clicked(position: Vector2) -> void:
	var state: Dictionary=session.current_snapshot()
	if str(state.get("ship",{}).get("mode","landed"))=="flying":
		send_command({"type":"ship_move","position":[position.x,position.y]})
		return
	var selection: Array[String]=[]
	if _direct_mode: selection.append(str(hud.selected_unit))
	else: selection.assign(hud.selected_units)
	var ids: Array[String]=_owned_units(selection)
	for index: int in range(ids.size()):
		var offset: float=(float(index)-float(ids.size()-1)*0.5)*1.4
		send_command({"type":"move","unit_id":ids[index],"position":[position.x+offset,position.y]})
	if ids.is_empty(): hud.notify("Diese Crew gehört dem anderen Commander.")

func _owned_units(ids: Array[String]) -> Array[String]:
	var result: Array[String]=[]
	var crew: Dictionary=session.current_snapshot().get("crew",{})
	for id: String in ids:
		if crew.has(id) and ((session.is_guest() and id=="jaro") or (not session.is_guest() and int(crew[id].owner)==1)):
			result.append(id)
	return result

func _on_units_selected(ids: Array[String]) -> void:
	var owned: Array[String]=_owned_units(ids)
	if owned.is_empty(): return
	hud.select_units(owned)
	_refresh()

func _on_action(action: String,payload: Dictionary) -> void:
	match action:
		"save":
			if session.is_guest(): hud.notify("Der Host speichert die gemeinsame Karriere."); return
			var result: Dictionary=simulation.save_game(save_path)
			if result.get("ok",false): _auto_save_allowed=true
			hud.notify("Karriere gespeichert." if result.get("ok",false) else str(result.get("reason","Speichern fehlgeschlagen")))
		"load":
			if session.is_guest(): hud.notify("Der Host lädt die gemeinsame Karriere."); return
			var result: Dictionary=simulation.load_game(save_path)
			if result.get("ok",false): _auto_save_allowed=true
			hud.notify("Karriere geladen." if result.get("ok",false) else str(result.get("reason","Kein Spielstand vorhanden")))
			_refresh()
		"focus_unit":
			var unit_id: String=str(payload.get("unit_id","ida"))
			world.focus_unit(unit_id)
			world.set_selection("unit",unit_id)
		"selection_changed":
			world.set_selected_units(hud.selected_units)
			world.set_control_mode(_direct_mode,hud.selected_unit)
		"toggle_control":
			if not _direct_mode and _owned_units([hud.selected_unit]).is_empty():
				hud.notify("Diese Figur gehört dem anderen Commander. Wähle deine eigene Crew.")
				return
			_direct_mode=not _direct_mode
			hud.set_direct_mode(_direct_mode)
			world.set_control_mode(_direct_mode,hud.selected_unit)
			if _direct_mode: world.focus_unit(hud.selected_unit)
			hud.notify("Einzelansicht: Rechtsklick setzt das Laufziel. Kamera folgt "+hud.selected_unit.capitalize()+"." if _direct_mode else "Crewansicht: Rahmen ziehen und Rechtsklick für den Gruppenauftrag.")
		"focus_object": world.focus_object(str(payload.get("object_id","shuttle")))
		"inspect_object":
			var id: String=str(payload.get("object_id","contracts"))
			_on_object_selected("object",id)
			world.focus_object(id)
		"dismiss_selection": world.set_selection("object","")
		"host":
			var error: Error=session.start_host()
			if error!=OK: hud.notify("Sitzung konnte nicht geöffnet werden: "+error_string(error))
		"join":
			var error: Error=session.join_host(str(payload.get("address","127.0.0.1")))
			if error!=OK: hud.notify("Beitritt fehlgeschlagen: "+error_string(error))
		"disconnect": session.disconnect_session()
		"quit": _quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_SPACE: send_command({"type":"toggle_pause"}); get_viewport().set_input_as_handled()
		KEY_F5: _on_action("save",{}); get_viewport().set_input_as_handled()
		KEY_F9: _on_action("load",{}); get_viewport().set_input_as_handled()
		KEY_1: hud.choose_unit("ida",false)
		KEY_2: hud.choose_unit("jaro",false)
		KEY_V: _on_action("toggle_control",{}); get_viewport().set_input_as_handled()
		KEY_ESCAPE: hud.dismiss_context()

func _process(delta: float) -> void:
	if not is_instance_valid(session) or not is_instance_valid(world) or not is_instance_valid(hud): return
	world.present(session.current_snapshot())
	_ui_elapsed+=delta
	if _ui_elapsed>=0.12:
		_ui_elapsed=0.0
		_refresh()
	if _capture_time>0:
		_capture_time-=delta
		if _capture_time<=0: _capture()

func _refresh() -> void:
	if not is_instance_valid(hud): return
	hud.set_connection(session.status_text(),session.is_guest())
	hud.present(session.current_snapshot())
	hud.set_recipe_details(Catalog.recipes(),Catalog.prices())
	if is_instance_valid(expedition): expedition.present(session.current_snapshot(),session.is_guest())

func _capture() -> void:
	await RenderingServer.frame_post_draw
	var image: Image=get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_capture_path.get_base_dir())
	var error: Error=image.save_png(_capture_path)
	print("GAME_CAPTURE ",_capture_path," result=",error)
	if _capture_quit: get_tree().quit(0 if error==OK else 1)

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST: _quit()

func _quit() -> void:
	if is_instance_valid(session) and not session.is_guest() and _auto_save_allowed:
		var result: Dictionary=simulation.save_game(save_path)
		if not result.get("ok",false):
			hud.notify("Beenden abgebrochen: "+str(result.get("reason","Speichern fehlgeschlagen.")))
			return
	get_tree().quit()
