extends CanvasLayer
## Read-only hover and mission feedback. Clicks submit existing local commands.
const ACTIONS=preload("res://scripts/mission/world_context_action_contract.gd")
var _controller: Node
var _view: Node
var _hint: Label
var _target: Dictionary={}
var _elapsed := 0.0
var _owns_cursor := false
var _objective_panel: PanelContainer
var _objective_text: Label
var _objective_progress: ProgressBar
var _objective_action: Button
func _ready() -> void:
	_controller=get_parent()
	_view=_controller.get_node_or_null("../Primary3DView")
	layer=110
	_hint=Label.new(); _hint.name="WorldContextHint"; _hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_hint.add_theme_font_size_override("font_size",16)
	var style:=StyleBoxFlat.new(); style.bg_color=Color(.03,.09,.12,.94); style.content_margin_left=8; style.content_margin_right=8; style.content_margin_top=5; style.content_margin_bottom=5;style.border_color=Color(.15,.65,.7);style.set_border_width_all(1);style.set_corner_radius_all(4)
	_hint.add_theme_stylebox_override("normal",style); add_child(_hint); _hint.hide()
	_objective_panel=PanelContainer.new(); _objective_panel.name="SatelliteDataFeedback"
	_objective_panel.add_theme_stylebox_override("panel",style)
	add_child(_objective_panel)
	var column:=VBoxContainer.new();_objective_panel.add_child(column)
	_objective_text=Label.new();_objective_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_objective_text.custom_minimum_size.x=330;_objective_text.add_theme_font_size_override("font_size",18);column.add_child(_objective_text)
	_objective_progress=ProgressBar.new();_objective_progress.custom_minimum_size.y=12;_objective_progress.show_percentage=false;column.add_child(_objective_progress)
	_objective_action=Button.new();_objective_action.text="Daten sichern vorbereiten";_objective_action.custom_minimum_size.y=34;column.add_child(_objective_action)
	_objective_action.pressed.connect(func(): queue_interaction("satellite_data"))
	_objective_panel.hide()
func _process(delta: float) -> void:
	_elapsed+=delta
	if _elapsed<.1: return
	_elapsed=0.0
	update_objective_feedback()
	refresh_at(get_viewport().get_mouse_position())
func refresh_at(pointer: Vector2) -> Dictionary:
	_target={}
	if not is_instance_valid(_view): _view=_controller.get_node_or_null("../Primary3DView")
	if not bool(_controller.get("_tactical_ui_visible")) or _view==null or not _controller.call("_can_edit_planning") or _controller.get("preview_mode") or _controller.get("_selected_fireteam_ids").is_empty() or _controller.get("_is_lz_placement_armed") or _controller.get("_is_target_placement_armed") or _controller.call("_is_pointer_over_control",pointer):
		_clear(); return {}
	var candidates: Array=[]
	for card: Dictionary in _controller.call("_get_mission_dropship_card_entries"):
		var id:=String(card.get("craft_id",""))
		if not _controller.call("_is_parked_campaign_dropship",id): continue
		var position: Vector2=_controller.call("_campaign_landed_craft_position",id)
		if position.is_finite(): candidates.append({"id":id,"kind":"ship","label":"Einsteigen","screen_position":_view.call("world_to_screen_position",position)})
	var snapshot: Dictionary=_controller.call("get_mission_interaction_runtime_use_state_snapshot")
	for entry: Dictionary in Array(snapshot.get("interactions",[])):
		if not entry.get("has_marker_position",false): continue
		var blocked:=bool(entry.get("blocked",false))
		candidates.append({"id":String(entry.interaction_id),"kind":"interaction","label":ACTIONS.interaction_label(entry),"entry":entry,"blocked":blocked,"complete":bool(entry.get("complete",false)),"screen_position":_view.call("world_to_screen_position",entry.marker_position)})
	_target=ACTIONS.choose(pointer,candidates)
	if _target.is_empty(): _clear(); return {}
	var blocked:=bool(_target.get("blocked",false))
	_hint.text=String(_target.label)+(" · gesperrt" if blocked else " · Rechtsklick")
	if bool(_target.get("complete",false)): _hint.text="Daten gesichert · zur Basis zurückbringen" if String(_target.id)=="satellite_data" else "Aktion abgeschlossen"
	elif blocked: _hint.text+="\nAktion derzeit nicht verfügbar"
	elif _target.kind=="interaction" and not bool(_target.entry.get("can_use_now",false)): _hint.text+=" → Annäherung & Sichern, dann GO"
	elif _target.kind=="interaction": _hint.text+=" → dann GO"
	_hint.position=pointer+Vector2(18,22); _hint.show()
	Input.set_default_cursor_shape(Input.CURSOR_FORBIDDEN if blocked else Input.CURSOR_POINTING_HAND); _owns_cursor=true
	return _target.duplicate(true)
func activate_at(pointer: Vector2) -> Dictionary:
	var target:=refresh_at(pointer)
	if target.is_empty(): return {"handled":false}
	if target.get("complete",false): return {"handled":true,"ok":true,"reason":"already_complete"}
	if target.get("blocked",false): return {"handled":true,"ok":false,"reason":"interaction_blocked"}
	if target.kind=="ship":
		_controller.call("select_mission_dropship_craft",String(target.id))
		var result: Dictionary=_controller.call("request_campaign_extraction",String(target.id))
		_hint.text=String(result.get("message","Einsteigen beauftragt")); return {"handled":true,"ok":bool(result.get("ok",false))}
	return queue_interaction(String(target.id))

func queue_interaction(id: String) -> Dictionary:
	var result:Dictionary=_controller.call("create_selected_mission_interaction_use_intent",id,true)
	if result.get("accepted",false) and not bool(_controller.get("_planning_enabled")):
		_controller.call("execute_selected_fireteam_orders")
	update_objective_feedback()
	return {"handled":true,"ok":bool(result.get("accepted",false)),"reason":String(result.get("blocked_reason",""))}

func update_objective_feedback() -> void:
	if _objective_panel==null:return
	_objective_panel.hide()
	if not bool(_controller.get("_tactical_ui_visible")) or bool(_controller.get("_character_overlay_open")):return
	var satellite:Dictionary={}
	for entry:Dictionary in _controller.call("get_mission_interaction_runtime_use_state_snapshot").get("interactions",[]):
		if String(entry.get("interaction_id",""))=="satellite_data":satellite=entry;break
	if satellite.is_empty():return
	_objective_panel.show()
	_objective_panel.position=Vector2(maxf((get_viewport().get_visible_rect().size.x-350)*.5,8),128)
	_objective_panel.size.x=350
	var complete:bool=bool(satellite.get("complete",false)) or String(satellite.get("runtime_use_status",""))=="complete"
	var progress:float=float(satellite.get("progress",0))
	var status:=String(satellite.get("runtime_use_status",""))
	var selected_active:bool=false
	for id in _controller.get("_selected_fireteam_ids"):
		selected_active=selected_active or bool(_controller.call("_is_fireteam_runtime_active",String(id)))
	_objective_progress.value=progress*100
	_objective_progress.visible=not complete
	_objective_action.visible=not complete
	_objective_action.disabled=_controller.get("_selected_fireteam_ids").is_empty() or bool(satellite.get("blocked",false)) or status=="in_progress" or not selected_active or not bool(_controller.call("_can_issue_local_commands"))
	if complete:
		_objective_text.text="✓ Daten gesichert\nZum Schiff und zur Heimatbasis zurückkehren. Basis → Datenterminal."
	elif status=="in_progress":
		_objective_text.text="Daten werden gesichert · %d %%\nTrupp in Reichweite lassen."%roundi(progress*100)
	elif not selected_active:
		_objective_text.text="Satellitendaten bergen\nTrupp landen lassen und auswählen."
	elif status=="interrupted":
		_objective_text.text="Datenaufnahme unterbrochen\nTrupp in Reichweite bringen und erneut vorbereiten."
	elif bool(satellite.get("blocked",false)):
		_objective_text.text="Datenaufnahme gesperrt\nVorherigen Auftragsschritt abschließen."
	else:
		var intent:Dictionary=_controller.get("_last_mission_interaction_use_intent_snapshot")
		var waypoint:Variant=_controller.call("_get_waypoint_from_ref",intent) if intent.get("accepted",false) else null
		if waypoint!=null and String(intent.get("interaction_id",""))=="satellite_data" and String(waypoint.status) in ["pending","active"]:
			_objective_text.text="Datenaufnahme vorbereitet · GO drücken." if String(waypoint.status)=="pending" else "Trupp nähert sich / Datenaufnahme läuft."
		else:
			_objective_text.text="Satellitendaten bergen\nVom begehbaren Nachbarfeld bedienen. Nicht auf das Wrack laufen."

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed and not event.shift_pressed:
		if activate_at(event.position).get("handled",false): get_viewport().set_input_as_handled()
func _clear() -> void:
	if _objective_panel!=null and not bool(_controller.get("_tactical_ui_visible")):_objective_panel.hide()
	if _hint!=null: _hint.hide()
	if _owns_cursor: Input.set_default_cursor_shape(Input.CURSOR_ARROW); _owns_cursor=false
func _exit_tree() -> void: _clear()
