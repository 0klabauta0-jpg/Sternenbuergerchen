extends Control
## Presentation only: confirmed onboarding facts remain owned by the runtime.
const HELP_SERVICE = preload("res://scripts/ui/contextual_help_service.gd")
const HELP_POPUP = preload("res://scripts/ui/contextual_help_popup.gd")
const SETTINGS = preload("res://scripts/ui/game_settings_contract.gd")
const THEME = preload("res://scripts/ui/tactical_ui_theme.gd")
const STEPS := {
	"base_ready": ["campaign.boarding", "Mondbasis vorbereiten: Pilot und Leader kennenlernen, Trupp/Ausruestung pruefen. Satellitenauftrag annehmen, Boarding abschliessen und zum Mondorbit abheben."],
	"satellite_completed": ["campaign.movement", "Auf der Sternkarte den Planeten anklicken. Im Planetenorbit Satelliten-Absturzstelle waehlen und Anflug starten. Landen, Leader absetzen, Bewegung/GO und Satelliten-Use ausfuehren; danach zum Schiff zurueck."],
	"satellite_home": ["campaign.return", "Bergung bestaetigt: Leader und Pilot fuer den Heimflug bereitstellen und zur Heimatbasis zurueckkehren. Erst die Heimkehr schaltet den Versorgungsauftrag frei."],
	"trade_departed": ["campaign.trade", "Versorgung sichern: Pilot/Leader an Bord nehmen, zum Mondorbit abheben und zum Planeten springen. Im Planetenorbit Handelsposten waehlen und den Anflug starten."],
	"trade_used": ["campaign.use", "Am Handelsposten landen, Leader absetzen und zum Haendler bewegen. Use oeffnet den echten Handel."],
	"bought": ["campaign.trade", "Beim Haendler einen passenden verfuegbaren Gegenstand kaufen. Ein bestaetigter Kauf zaehlt; das Oeffnen des Handels allein reicht nicht."],
	"refueled": ["campaign.trade", "Treibstoff beim Haendler nachfuellen. Die erfolgreiche Tankaktion wird bestaetigt; bei fehlenden Mitteln den sichtbaren Sperrgrund pruefen."],
	"trade_home": ["campaign.return", "Kauf und Tanken sind bestaetigt. Zum Schiff zurueckkehren, einsteigen und zur Heimatbasis fliegen, um die Einfuehrung abzuschliessen."],
	"completed": ["campaign.complete", "Einfuehrung abgeschlossen. Die vorhandenen Orte bleiben frei besuchbar. Dein Stand wird an sicheren Basis-Meilensteinen gespeichert."]
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
var _pinned: bool = false
var _seen: Dictionary = {}
var _render_count: int = 0

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

func refresh() -> void:
	if not is_instance_valid(_runtime) or not _runtime.has_method("get_snapshot") or _strip == null:
		visible = false
		return
	var snapshot: Dictionary = _runtime.get_snapshot()
	if String(snapshot.get("mode", "")) != "campaign":
		visible = false
		return
	visible = true
	var onboarding: Dictionary = snapshot.get("onboarding", {})
	var checkpoint: Dictionary = _flow.get_meta("campaign_checkpoint_result", {}) if is_instance_valid(_flow) else {}
	var signature := JSON.stringify({"onboarding": onboarding, "checkpoint_ok": checkpoint.get("ok", true), "has_checkpoint": not checkpoint.is_empty()})
	if signature == _signature:
		return
	_signature = signature
	_render_count += 1
	_step_id = String(onboarding.get("next_step_id", "base_ready"))
	var step: Array = STEPS.get(_step_id, ["campaign.job", "Aktuellen Auftrag und den Sperrgrund im Operationsfenster pruefen. Ein abgebrochener Ausflug kann erneut begonnen werden."])
	_help_id = String(step[0])
	_title.text = "Kampagne: Einfuehrung abgeschlossen" if int(onboarding.get("stage_index", 0)) >= 3 else "Kampagne: Etappe %d / 3" % (int(onboarding.get("stage_index", 0)) + 1)
	_guidance.text = String(step[1])
	_checkpoint_label.text = "Speichert an Basis-Meilensteinen." if checkpoint.is_empty() else ("Basisstand gespeichert." if bool(checkpoint.get("ok", false)) else "Speichern fehlgeschlagen. Der letzte Basisstand bleibt erhalten.")
	_service.register_control(_guidance, _help_id)
	_service.register_control(_help_button, _help_id)
	_guidance.visible = not _hints_hidden
	_layout()
	if not _hints_hidden and not _seen.has(_help_id):
		_seen[_help_id] = true
		_show_compact_help()

func hide_hints() -> void:
	_hints_hidden = true
	_guidance.hide()
	_hide_button.hide()
	_dismiss_popup()
	_layout()

func reopen_help() -> void:
	_hints_hidden = false
	_guidance.show()
	_hide_button.show()
	_show_help(true)

func set_help_mode(mode: String) -> void:
	_service.set_help_mode(mode)
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
	_strip.position = Vector2(260, 8)
	_strip.size.x = maxf(300, minf(560, get_viewport_rect().size.x - 640))
	_guidance.custom_minimum_size.x = maxf(260, _strip.size.x - 24)
	_strip.reset_size()
	for protected in _launch_action_rects():
		if _strip.get_global_rect().intersects(protected):
			_strip.position = Vector2(16, 8)
			break
	if _popup_host.visible:
		_place_popup_host()


func _launch_action_rects() -> Array[Rect2]:
	if not is_instance_valid(_flow):
		return []
	var screen: Control = _flow.get_node_or_null("HomebaseScreen")
	if screen == null:
		return []
	var operations: Control = screen.get("_operations_presenter")
	return operations.call("get_launch_action_rects") if operations != null and operations.has_method("get_launch_action_rects") else []


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
	var candidates := [Vector2(16, preferred_y), Vector2(16, 16), Vector2(viewport_size.x - window_size.x - 16, preferred_y), Vector2(16, viewport_size.y - height - 16)]
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
