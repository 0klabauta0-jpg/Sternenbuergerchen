extends Control
## Presentation only: confirmed onboarding facts remain owned by the runtime.
const HELP_SERVICE = preload("res://scripts/ui/contextual_help_service.gd")
const HELP_POPUP = preload("res://scripts/ui/contextual_help_popup.gd")
const SETTINGS = preload("res://scripts/ui/game_settings_contract.gd")
const THEME = preload("res://scripts/ui/tactical_ui_theme.gd")
const HINT_ARROW = preload("res://scripts/ui/campaign_hint_arrow.gd")
const HINT_ARROWS = preload("res://scripts/meta/campaign_hint_arrows.gd")
const STEPS := {
	"base_ready":["campaign.boarding","Mondbasis vorbereiten: zwei Personen ausrüsten, Satellitenauftrag im Smart Mobile annehmen, Pilot und Trupp an Bord nehmen, abheben."],
	"satellite_uploaded":["campaign.return","Mission 1: Satellitenchip bergen, zum Schiff zurückbringen und wirklich heimfliegen. An der Basis unter Basis → Datenterminal den Chip hochladen."],
	"outpost_completed":["campaign.movement","Mission 2: Außenpostenauftrag annehmen, auf Karte B einen Gegner besiegen und die C-Benit-Kiste bergen."],
	"outpost_recruited":["campaign.trade","Den Handelsposten auf Karte B erreichen und ansprechen. Im Versorgungsfenster die neue Person aufnehmen; das Team wächst auf drei."],
	"crate_loaded":["campaign.use","C-Benit-Kiste am gesicherten Außenposten bergen und ins Schiff bringen."],
	"delivery_completed":["campaign.trade","Mission 3: Lieferauftrag annehmen, mit der Kiste zur Satellitenkarte zurückkehren und am dortigen Händler abgeben. Belohnung: Hand-Mining-Erwerbserlaubnis."],
	"outpost_chip_uploaded":["campaign.return","Mission 4: Auf Karte C zwei Gegner besiegen, Chip bergen, heimbringen und unter Basis → Datenterminal abgeben. Belohnung: Sturmgewehr-Erwerbserlaubnis."],
	"rescue_completed":["campaign.movement","Mission 5: Notruf annehmen und im Planetenorbit anfliegen. Feindliche Cutlass bekämpfen; neutrale Buccaneer retten."],
	"pilot_recruited":["campaign.use","Nach dem Sieg den Buccaneer-Piloten retten. Er schließt sich mit seinem Schiff an; das Team wächst auf vier."],
	"second_pad_built":["campaign.return","Zur Basis heimkehren: Kein freies Landepad für die Buccaneer. Unter Basis → Bauen das zweite Landepad für 100 Credits bauen."],
	"completed":["campaign.complete","Erstes Kampagnenkapitel abgeschlossen: vier Personen, zwei Schiffe und zwei Landepads. Orte bleiben besuchbar; sichere Basisstände können fortgesetzt werden."]
}
var _runtime: Node
var _flow: Node
var _service = HELP_SERVICE.new()
var _popup: Control
var _popup_host: ScrollContainer
var _strip: PanelContainer
var _guidance: Label
var _checkpoint_label: Label
var _title: Label
var _help_button: Button
var _hide_button: Button
var _dismiss_button: Button
var _hide_timer: Timer
var _detail_timer: Timer
var _hover_timer: Timer
var _signature: String = ""
var _help_id: String = ""
var _step_id: String = ""
var _hints_hidden: bool = false
var _guidance_dragging := false
var _guidance_moved := false
var _pinned: bool = false
var _seen: Dictionary = {}
var _render_count: int = 0
var _hint_arrow: Control
var _hint_arrows: RefCounted
## Facts and search root of the hint arrows, rebuilt by every refresh() (4 Hz from the flow); the rectangle of
## the target is followed in _process at most every hint_update_interval_msec (find_child is not free).
var _hint_facts: Dictionary = {}
var _hint_root: Node
var _hint_update_msec: int = -1000000
var _hint_facts_msec: int = -1000000
## True while no hint can ever open again (stage and satellite job, see "retire_when"): no facts, no operations snapshot.
var _hint_retired: bool = false
var _arrow_rect_seen: Rect2 = Rect2()
var hint_update_interval_msec: int = 50

func _exit_tree() -> void:
	# The arrow is a sibling of this card (not a child), so it must be released with it.
	if _hint_arrow != null and is_instance_valid(_hint_arrow):
		if _hint_arrow.get_parent() == null:
			_hint_arrow.free()
		else:
			_hint_arrow.queue_free()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_service.load_catalog()
	_service.set_help_mode(String(SETTINGS.load_settings().get("contextual_help_mode", "compact")))
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()

func configure(runtime: Node, flow: Node) -> void:
	_runtime = runtime
	_flow = flow
	_signature = ""
	refresh()

func _build_ui() -> void:
	_strip = PanelContainer.new()
	_strip.name = "CampaignGuidance"
	THEME.style_card(_strip)
	add_child(_strip)
	var rows := VBoxContainer.new()
	_strip.add_child(rows)
	var actions := HBoxContainer.new()
	rows.add_child(actions)
	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(_title)
	_title.mouse_filter=Control.MOUSE_FILTER_STOP
	_title.mouse_default_cursor_shape=Control.CURSOR_DRAG
	_title.tooltip_text="Titel ziehen, um die Kampagnenhilfe zu verschieben"
	_title.gui_input.connect(_drag_guidance)
	_help_button = Button.new()
	_help_button.name = "CampaignHelpButton"
	_help_button.text = "?"
	_help_button.custom_minimum_size = Vector2(32, 28)
	_help_button.tooltip_text = "Kampagnenhilfe erneut oeffnen"
	_help_button.pressed.connect(reopen_help)
	actions.add_child(_help_button)
	_hide_button = Button.new()
	_hide_button.text = "Hinweise aus"
	_hide_button.pressed.connect(hide_hints)
	actions.add_child(_hide_button)
	_dismiss_button = Button.new()
	_dismiss_button.text = "Hinweis schliessen"
	_dismiss_button.pressed.connect(_dismiss_popup)
	actions.add_child(_dismiss_button)
	_guidance = Label.new()
	_guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_guidance.add_theme_font_size_override("font_size", 13)
	rows.add_child(_guidance)
	_checkpoint_label = Label.new()
	_checkpoint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_checkpoint_label.add_theme_font_size_override("font_size", 11)
	rows.add_child(_checkpoint_label)
	_popup_host = ScrollContainer.new()
	_popup_host.name = "CampaignHelpScroll"
	_popup_host.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_popup_host.hide()
	add_child(_popup_host)
	_popup = HELP_POPUP.new()
	_popup.name = "CampaignContextHelp"
	_popup_host.add_child(_popup)
	_hover_timer = Timer.new()
	_hover_timer.one_shot = true
	_hover_timer.wait_time = HELP_SERVICE.DEFAULT_COMPACT_DELAY_SECONDS
	_hover_timer.timeout.connect(_show_compact_help)
	add_child(_hover_timer)
	_hide_timer = Timer.new()
	_hide_timer.one_shot = true
	_hide_timer.wait_time = 0.15
	_hide_timer.timeout.connect(_dismiss_popup)
	add_child(_hide_timer)
	_detail_timer = Timer.new()
	_detail_timer.one_shot = true
	_detail_timer.wait_time = HELP_SERVICE.DEFAULT_DETAIL_DELAY_SECONDS
	_detail_timer.timeout.connect(_show_expanded_help)
	add_child(_detail_timer)
	for control in [_help_button, _guidance]:
		control.mouse_entered.connect(_begin_hover)
		control.mouse_exited.connect(_end_hover)
		control.focus_entered.connect(_begin_hover)
		control.focus_exited.connect(_end_hover)
	_guidance.mouse_filter = Control.MOUSE_FILTER_PASS
	_guidance.focus_mode = Control.FOCUS_ALL
	_hint_arrow = HINT_ARROW.new()
	_hint_arrow.name = "CampaignHintArrow"
	_hint_arrows = HINT_ARROWS.new()
	_hint_arrows.call("attach_arrow", _hint_arrow)

func _process(_delta: float) -> void:
	# Between two refresh() calls (the flow ticks at 4 Hz) only the target rectangle moves, e.g. while a side
	# window slides in. Follow it with the cached facts, at most every hint_update_interval_msec.
	if _hint_facts.is_empty() or _hint_arrows == null or not is_instance_valid(_hint_arrow):
		return
	var now: int = Time.get_ticks_msec()
	if now - _hint_update_msec < hint_update_interval_msec:
		return
	_hint_update_msec = now
	_apply_hint_arrows()

func _update_hint_arrows() -> void:
	# Runs before the early returns of refresh(): the arrows must outlive the hidden card.
	if _hint_arrows == null or not is_instance_valid(_hint_arrow):
		return
	# Empty list: no snapshot, no facts, nothing to do. Loads the list only once.
	if not bool(_hint_arrows.call("has_hints")):
		return
	if _hint_arrow.get_parent() == null and get_parent() != null:
		get_parent().add_child(_hint_arrow)
	# The 50 ms lock also holds for this path (own stamp: the follow-up in _process must not starve the 4 Hz rebuild).
	var now: int = Time.get_ticks_msec()
	if now - _hint_facts_msec < hint_update_interval_msec:
		return
	_hint_facts_msec = now
	_hint_update_msec = now
	_build_hint_facts()
	if _hint_retired:
		_hint_arrow.call("hide_arrow")
		if _arrow_rect_seen != Rect2():
			_arrow_rect_seen = Rect2()
			if _strip != null:
				_layout()
		return
	_apply_hint_arrows()

func _apply_hint_arrows() -> void:
	var search_root: Node = _hint_root if is_instance_valid(_hint_root) else null
	_hint_arrows.call("refresh", search_root, _hint_facts)
	# The arrow counts as a protected area for the card (see _launch_action_rects): re-place the card when it moved.
	var arrow_rect: Rect2 = Rect2()
	if bool(_hint_arrow.call("is_showing")):
		arrow_rect = _hint_arrow.call("get_arrow_rect")
	if arrow_rect != _arrow_rect_seen:
		_arrow_rect_seen = arrow_rect
		if _strip != null:
			_layout()

func _build_hint_facts() -> void:
	_hint_root = null
	_hint_facts = {}
	_hint_retired = false
	var snapshot: Dictionary = {}
	if is_instance_valid(_runtime) and _runtime.has_method("get_snapshot"):
		snapshot = _runtime.get_snapshot()
	if String(snapshot.get("mode", "")) != "campaign":
		return
	var onboarding: Dictionary = snapshot.get("onboarding", {}) if snapshot.get("onboarding") is Dictionary else {}
	# Light check first (stage + runtime snapshot only): once nothing can open again, stop here.
	if bool(_hint_arrows.call("is_retired", {"stage": int(onboarding.get("stage_index", 0)), "runtime": snapshot})):
		_hint_retired = true
		return
	var homebase: Node = _flow.get_node_or_null("HomebaseScreen") if is_instance_valid(_flow) else null
	var operations_mode: String = _variant_text(homebase.get("_operations_mode")) if homebase != null else ""
	var meta_view: String = _variant_text(_flow.get("_current_meta_view")) if is_instance_valid(_flow) else ""
	var views: Array = []
	for view_name: String in [operations_mode, meta_view]:
		if not view_name.is_empty():
			views.append(view_name)
	var facts: Dictionary = {}
	var onboarding_facts: Variant = onboarding.get("facts", {})
	if onboarding_facts is Dictionary:
		facts = (onboarding_facts as Dictionary).duplicate()
	facts["stage"] = int(onboarding.get("stage_index", 0))
	facts["step"] = String(onboarding.get("next_step_id", ""))
	facts["view"] = operations_mode if not operations_mode.is_empty() else meta_view
	facts["views"] = views
	facts["in_mission"] = is_instance_valid(_flow) and is_instance_valid(_flow.get("_active_mission"))
	# Read-only snapshots for the state words of the hint list (the arrows never write).
	facts["runtime"] = snapshot
	if homebase != null and homebase.has_method("get_operations_snapshot"):
		facts["operations"] = homebase.call("get_operations_snapshot", false)
	_hint_facts = facts
	# Search root = the flow: the ship service card (MissionServices) lives next to the homebase screen, not below it.
	_hint_root = _flow if is_instance_valid(_flow) else homebase

## Read access for tests and later hint content: the arrow node and its controller.
func get_hint_arrow() -> Control:
	return _hint_arrow

func get_hint_arrows() -> RefCounted:
	return _hint_arrows

func _variant_text(value: Variant) -> String:
	return "" if value == null else String(value)

func refresh() -> void:
	_update_hint_arrows()
	if is_instance_valid(_flow) and String(_flow.get("_current_meta_view")) == "inspection":
		visible = false
		return
	if not is_instance_valid(_runtime) or not _runtime.has_method("get_snapshot") or _strip == null:
		visible = false
		return
	var snapshot: Dictionary = _runtime.get_snapshot()
	if String(snapshot.get("mode", "")) != "campaign":
		visible = false
		return
	if is_instance_valid(_flow) and _flow.has_method("is_context_overlay_obscured") and _flow.is_context_overlay_obscured():
		visible = false
		return
	var homebase: Node = _flow.get_node_or_null("HomebaseScreen") if is_instance_valid(_flow) else null
	var detail_popup: Control = homebase.get_node_or_null("CharacterSheetPopup") if homebase != null else null
	var operations:Node=homebase.get("_operations_presenter") if homebase!=null else null
	var flyout_open:bool=operations!=null and operations.has_method("is_workspace_flyout_open") and bool(operations.call("is_workspace_flyout_open"))
	var mission:Node=_flow.get("_active_mission") if is_instance_valid(_flow) else null
	var mission_details:Control=mission.get_node_or_null("TacticalUI/CharacterOverlay") if is_instance_valid(mission) else null
	if flyout_open or (mission_details!=null and mission_details.is_visible_in_tree()) or (detail_popup != null and detail_popup.is_visible_in_tree()) or (homebase != null and String(homebase.get("_operations_mode")) in ["services","jobs"]) or (is_instance_valid(_flow) and String(_flow.get("_current_meta_view")) == "star_map"):
		# These views already carry their own instructions. Keep the global
		# floating guidance clear of identity, map headings and close actions.
		visible = false
		return
	visible = true
	var onboarding: Dictionary = snapshot.get("onboarding", {})
	var checkpoint: Dictionary = _flow.get_meta("campaign_checkpoint_result", {}) if is_instance_valid(_flow) else {}
	var checkpoint_guard: Dictionary=Dictionary(_runtime.call("get_snapshot").get("checkpoint_guard",{}))
	var active_save: Dictionary = _flow.get_meta("campaign_active_checkpoint_result", {}) if is_instance_valid(_flow) else {}
	var in_mission := is_instance_valid(mission)
	var signature := JSON.stringify({"view_mode":String(homebase.get("_operations_mode")) if homebase != null else "", "in_mission":in_mission,"active_save":active_save,"checkpoint_guard":checkpoint_guard,"onboarding": onboarding, "checkpoint_ok": checkpoint.get("ok", true), "has_checkpoint": not checkpoint.is_empty()})
	if signature == _signature:
		return
	_signature = signature
	_render_count += 1
	_step_id = String(onboarding.get("next_step_id", "base_ready"))
	var step: Array = STEPS.get(_step_id, ["campaign.job", "Aktuellen Auftrag und den Sperrgrund im Operationsfenster pruefen. Ein abgebrochener Ausflug kann erneut begonnen werden."])
	_help_id = String(step[0])
	_title.text = "Kampagne: Kapitel abgeschlossen" if bool(onboarding.get("completed",false)) else "Kampagne: Schritt %d / %d" % [int(onboarding.get("stage_index",0))+1,int(onboarding.get("stage_count",7))]
	_guidance.text = String(step[1])
	_checkpoint_label.text = "Speichert an Basis-Meilensteinen." if checkpoint.is_empty() else ("Basisstand gespeichert." if bool(checkpoint.get("ok", false)) else "Speichern fehlgeschlagen. Der letzte Basisstand bleibt erhalten.")
	if not bool(checkpoint_guard.get("ok",true)): _checkpoint_label.text=String(checkpoint_guard.get("message","Speichern wartet auf die Rueckkehr aller Schiffe"))
	if in_mission:
		_checkpoint_label.text = "Stabilen Einsatz über Escape → Kampagne speichern sichern."
		if not active_save.is_empty():
			_checkpoint_label.text = "Einsatzstand gespeichert; Fortsetzen nimmt diesen Einsatz wieder auf." if active_save.get("ok", false) else "Einsatz noch nicht speicherbar; der letzte gespeicherte Stand bleibt erhalten."
	_service.register_control(_guidance, _help_id)
	_service.register_control(_help_button, _help_id)
	_guidance.visible = not _hints_hidden
	_layout()
	if not _hints_hidden and not _seen.has(_help_id):
		_seen[_help_id] = true
		_show_compact_help()

func hide_hints() -> void:
	_hints_hidden = true
	if _hint_arrows != null: _hint_arrows.call("set_enabled", false)
	_guidance.hide()
	_hide_button.hide()
	_dismiss_popup()
	_layout()

func reopen_help() -> void:
	_hints_hidden = false
	if _hint_arrows != null: _hint_arrows.call("set_enabled", true)
	_guidance.show()
	_hide_button.show()
	_show_help(true)

func set_help_mode(mode: String) -> void:
	_service.set_help_mode(mode)
	if _hint_arrows != null: _hint_arrows.call("set_help_mode", mode)
	if mode == "off" and _popup != null:
		_dismiss_popup()

func _begin_hover() -> void:
	_hide_timer.stop()
	_hover_timer.start()
	if _service.get_help_mode() == "expanded":
		_detail_timer.start()

func _end_hover() -> void:
	_hover_timer.stop()
	_detail_timer.stop()
	if not _pinned:
		_hide_timer.start()

func _show_expanded_help() -> void:
	if _service.get_help_mode() == "expanded":
		_show_help(true)

func _show_compact_help() -> void:
	_show_help(false)

func _show_help(pinned: bool) -> void:
	if not visible or _hints_hidden or _help_id.is_empty():
		return
	var payload: Dictionary = _service.request_help(_help_id, HELP_SERVICE.DEFAULT_COMPACT_DELAY_SECONDS, pinned)
	if String(payload.get("level", "none")) == "none":
		_dismiss_popup()
		return
	_pinned = pinned
	_popup.show_help(payload, _strip.get_global_rect(), get_viewport_rect().size, pinned)
	_popup.position = Vector2.ZERO
	_popup_host.show()
	_dismiss_button.show()
	_layout()
	_fit_popup_content()
	call_deferred("_fit_popup_content")

func _dismiss_popup() -> void:
	_pinned = false
	_hover_timer.stop()
	_hide_timer.stop()
	_detail_timer.stop()
	_popup.hide_help()
	_popup_host.hide()
	_dismiss_button.hide()

func _layout() -> void:
	if _strip == null:
		return
	if not _guidance_moved: _strip.position = Vector2(210, 88)
	_strip.size.x = 300 if _hints_hidden else maxf(300, minf(560, get_viewport_rect().size.x - 640))
	if _hints_hidden and not _guidance_moved: _strip.position=Vector2(maxf(210,get_viewport_rect().size.x-500),8)
	_guidance.custom_minimum_size.x = maxf(260, _strip.size.x - 24)
	_strip.reset_size()
	if not _guidance_moved:
		_strip.position = _free_guidance_position(_launch_action_rects())
	if _popup_host.visible:
		_place_popup_host()


func _free_guidance_position(protected: Array[Rect2]) -> Vector2:
	# Playtest L04: the hint card must never sit on an action and swallow part of its clicks.
	var view: Vector2 = get_viewport_rect().size
	var card: Vector2 = _strip.size
	var right: float = maxf(210.0, view.x - card.x - 16.0)
	var candidates: Array[Vector2] = [_strip.position, Vector2(right, 88.0), Vector2(right, 8.0), Vector2(210.0, 8.0)]
	for protected_rect: Rect2 in protected:
		candidates.append(Vector2(right, protected_rect.end.y + 12.0))
	var best: Vector2 = _strip.position
	var best_overlap: float = INF
	for candidate: Vector2 in candidates:
		var rect := Rect2(candidate, card)
		var overlap: float = 0.0
		for protected_rect: Rect2 in protected:
			overlap += rect.intersection(protected_rect).get_area()
		if overlap < best_overlap:
			best_overlap = overlap
			best = candidate
		if overlap <= 0.0:
			break
	return best


func _launch_action_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = _operations_action_rects().duplicate()
	# The hint arrow is protected like the launch actions: the card must not cover it.
	if is_instance_valid(_hint_arrow) and bool(_hint_arrow.call("is_showing")):
		var arrow_rect: Rect2 = _hint_arrow.call("get_arrow_rect")
		if arrow_rect.size.x > 0.0 and arrow_rect.size.y > 0.0:
			rects.append(arrow_rect)
	return rects


func _operations_action_rects() -> Array[Rect2]:
	if not is_instance_valid(_flow):
		return []
	var screen: Control = _flow.get_node_or_null("HomebaseScreen")
	if screen == null:
		return []
	var operations: Control = screen.get("_operations_presenter")
	var rects: Array[Rect2] = []
	if operations != null and operations.has_method("get_launch_action_rects"):
		rects.append_array(operations.call("get_launch_action_rects"))
	# Meldung 25.11.: Hinweiskarte und Hilfefenster deckten Knoepfe im Inhalt ab (Personal-Sortierung, Namen, Schiffswahl) und
	# fingen dort die Maus ab. Alle sichtbaren, freigegebenen Knoepfe der Heimatbasis gelten deshalb als geschuetzt.
	_append_button_rects(screen, rects)
	return rects


func _append_button_rects(node: Node, rects: Array[Rect2]) -> void:
	for child: Node in node.get_children():
		if child is BaseButton:
			var button: BaseButton = child
			if button.is_visible_in_tree() and not button.disabled:
				var rect: Rect2 = button.get_global_rect()
				var parent: Node = button.get_parent()
				while parent != null and rect.has_area():
					if parent is Control and (parent as Control).clip_contents:
						rect = rect.intersection((parent as Control).get_global_rect())
					parent = parent.get_parent()
				if rect.has_area():
					rects.append(rect)
		_append_button_rects(child, rects)


func _fit_popup_content() -> void:
	if not _popup.visible:
		return
	var frame: Control = _popup.get_node("HelpFrame")
	var content_height: float = maxf(_popup.size.y, frame.get_combined_minimum_size().y)
	_popup.custom_minimum_size = Vector2(_popup.size.x, content_height)
	_popup.position = Vector2.ZERO
	_place_popup_host()


func _place_popup_host() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var content_width: float = _popup.custom_minimum_size.x + _popup_host.get_v_scroll_bar().get_combined_minimum_size().x + 2
	var height: float = minf(_popup.custom_minimum_size.y, viewport_size.y * 0.45)
	var preferred_y: float = _strip.get_global_rect().end.y + 8
	height = minf(height, maxf(viewport_size.y - preferred_y - 16, 96))
	var window_size := Vector2(minf(content_width, viewport_size.x - 32), height)
	var forbidden: Array[Rect2] = _launch_action_rects()
	var candidates := [Vector2(_strip.position.x, preferred_y), Vector2(viewport_size.x - window_size.x - 16, preferred_y), Vector2(_strip.position.x, viewport_size.y - height - 16)]
	for point in candidates:
		var candidate := Rect2(point, window_size)
		if not Rect2(Vector2.ZERO, viewport_size).encloses(candidate):
			continue
		var blocked := false
		for protected in forbidden:
			if candidate.intersects(protected):
				blocked = true
				break
		if not blocked:
			_popup_host.position = point
			_popup_host.size = window_size
			return
	# A cramped view keeps the help in the left reading column with scrolling.
	_popup_host.position = Vector2(16, preferred_y)
	_popup_host.size = window_size

func get_presentation_snapshot() -> Dictionary:
	return {"step_id": _step_id, "help_id": _help_id, "guidance": _guidance.text if _guidance != null else "", "hints_hidden": _hints_hidden, "popup_visible": _popup.visible if _popup != null else false, "render_count": _render_count, "help_mode": _service.get_help_mode()}

func _drag_guidance(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		_guidance_dragging=event.pressed
	elif event is InputEventMouseMotion and _guidance_dragging:
		_guidance_moved=true
		var limit: Vector2=get_viewport_rect().size-_strip.size-Vector2(8,8)
		_strip.position=(_strip.position+event.relative).clamp(Vector2(8,8),limit.max(Vector2(8,8)))
		if _popup_host.visible: _place_popup_host()
