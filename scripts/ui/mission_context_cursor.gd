extends CanvasLayer
## Hover projection only. Clicks submit existing local commands; hover never mutates gameplay.
const ACTIONS=preload("res://scripts/mission/world_context_action_contract.gd")
var _controller: Node
var _view: Node
var _hint: Label
var _target: Dictionary={}
var _elapsed := 0.0
var _owns_cursor := false
func _ready() -> void:
	_controller=get_parent()
	_view=_controller.get_node_or_null("../Primary3DView")
	layer=110
	_hint=Label.new(); _hint.name="WorldContextHint"; _hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_hint.add_theme_font_size_override("font_size",16)
	var style:=StyleBoxFlat.new(); style.bg_color=Color(.03,.09,.12,.94); style.content_margin_left=8; style.content_margin_right=8; style.content_margin_top=5; style.content_margin_bottom=5
	_hint.add_theme_stylebox_override("normal",style); add_child(_hint); _hint.hide()
func _process(delta: float) -> void:
	_elapsed+=delta
	if _elapsed<.1: return
	_elapsed=0.0
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
		if entry.get("complete",false) or not entry.get("has_marker_position",false): continue
		var blocked:=bool(entry.get("blocked",false))
		candidates.append({"id":String(entry.interaction_id),"kind":"interaction","label":ACTIONS.interaction_label(entry),"entry":entry,"blocked":blocked,"screen_position":_view.call("world_to_screen_position",entry.marker_position)})
	_target=ACTIONS.choose(pointer,candidates)
	if _target.is_empty(): _clear(); return {}
	var blocked:=bool(_target.get("blocked",false))
	_hint.text=String(_target.label)+(" · gesperrt" if blocked else " · Rechtsklick")
	if blocked: _hint.text+="\nAktion derzeit nicht verfügbar"
	elif _target.kind=="interaction" and not bool(_target.entry.get("can_use_now",false)): _hint.text+=" → hingehen, dann GO"
	elif _target.kind=="interaction": _hint.text+=" → dann GO"
	_hint.position=pointer+Vector2(18,22); _hint.show()
	Input.set_default_cursor_shape(Input.CURSOR_FORBIDDEN if blocked else Input.CURSOR_POINTING_HAND); _owns_cursor=true
	return _target.duplicate(true)
func activate_at(pointer: Vector2) -> Dictionary:
	var target:=refresh_at(pointer)
	if target.is_empty(): return {"handled":false}
	if target.get("blocked",false): return {"handled":true,"ok":false,"reason":"interaction_blocked"}
	if target.kind=="ship":
		_controller.call("select_mission_dropship_craft",String(target.id))
		var result: Dictionary=_controller.call("request_campaign_extraction",String(target.id))
		_hint.text=String(result.get("message","Einsteigen beauftragt")); return {"handled":true,"ok":bool(result.get("ok",false))}
	if bool(target.entry.get("can_use_now",false)):
		var result: Dictionary=_controller.call("create_selected_mission_interaction_use_intent",String(target.id))
		return {"handled":true,"ok":bool(result.get("accepted",false))}
	_controller.call("_create_waypoints_for_selected_fireteams",Vector2(target.entry.marker_position),true)
	return {"handled":true,"ok":true,"reason":"approach_intent"}
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed and not event.shift_pressed:
		if activate_at(event.position).get("handled",false): get_viewport().set_input_as_handled()
func _clear() -> void:
	if _hint!=null: _hint.hide()
	if _owns_cursor: Input.set_default_cursor_shape(Input.CURSOR_ARROW); _owns_cursor=false
func _exit_tree() -> void: _clear()
