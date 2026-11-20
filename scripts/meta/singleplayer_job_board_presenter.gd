extends PanelContainer
## Cached presentation over the real Operations command bridge.
const SKIN=preload("res://scripts/ui/smart_mobile_theme.gd")
const DISPLAY=preload("res://scripts/mission/campaign_display_catalog.gd")
const JOBS=preload("res://scripts/mission/singleplayer_job_contract.gd")
const MENU_ICONS=preload("res://scripts/ui/menu_equipment_icons.gd")

var _screen: WeakRef
var _content: VBoxContainer
var _device: PanelContainer
var _actions: HFlowContainer
var _jobs: OptionButton
var _details: Label
var _accept: Button
var _show_map: Button
var _abandon: Button
var _job_id: String = ""
var _signature: String = ""
var _job_cards:VBoxContainer
var _body:GridContainer
var _card_buttons:Dictionary={}
var _visible_job_ids:PackedStringArray=PackedStringArray()
var _objectives:Label
var _detail_card:PanelContainer
var _details_expanded:bool=false
var _footer: PanelContainer
var _picture: TextureRect
var _illustration_column: VBoxContainer
var _dossier_heading: Label
var _summary: Label
var _job_list_rebuilds := 0
var _picture_key := ""
var _empty: Label

func configure(screen: Control) -> void:
	_screen = weakref(screen)
	name = "JobBoard"
	theme = SKIN.get_theme()
	add_theme_stylebox_override("panel", SKIN.box("shell"))
	var layout := VBoxContainer.new()
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 6)
	add_child(layout)
	var heading := Label.new()
	heading.text = "SMART MOBILE  /  AUFTRÄGE"
	heading.add_theme_font_override("font", SKIN.HEADING)
	heading.add_theme_font_size_override("font_size", 24)
	layout.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	layout.add_child(scroll)
	_device = PanelContainer.new()
	_device.name = "MobileDevice"
	_device.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_device.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_device.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	scroll.add_child(_device)
	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_device.add_child(_content)
	_body = GridContainer.new()
	_body.add_theme_constant_override("h_separation", 12)
	_content.add_child(_body)
	var selector := VBoxContainer.new()
	selector.custom_minimum_size.x = 230
	_body.add_child(selector)
	_jobs = OptionButton.new()
	_jobs.custom_minimum_size.y = 34
	_jobs.fit_to_longest_item = false
	selector.add_child(_jobs)
	_jobs.item_selected.connect(func(index: int): _job_id = String(_jobs.get_item_metadata(index)); _details_expanded = true; refresh())
	_job_cards = VBoxContainer.new()
	_job_cards.add_theme_constant_override("separation", 4)
	selector.add_child(_job_cards)
	_empty = Label.new()
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.custom_minimum_size.x = 230
	selector.add_child(_empty)
	_detail_card = PanelContainer.new()
	_detail_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(_detail_card)
	var dossier := VBoxContainer.new()
	dossier.add_theme_constant_override("separation", 6)
	_detail_card.add_child(dossier)
	_dossier_heading = Label.new()
	_dossier_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dossier_heading.add_theme_font_override("font", SKIN.HEADING)
	_dossier_heading.add_theme_font_size_override("font_size", 21)
	dossier.add_child(_dossier_heading)
	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.add_theme_font_size_override("font_size", 16)
	_summary.max_lines_visible = 3
	dossier.add_child(_summary)
	var briefing_columns := HBoxContainer.new()
	briefing_columns.name = "BriefingColumns"
	briefing_columns.add_theme_constant_override("separation", 12)
	dossier.add_child(briefing_columns)
	_illustration_column = VBoxContainer.new()
	_illustration_column.name = "IllustrationAndObjectives"
	_illustration_column.add_theme_constant_override("separation", 6)
	briefing_columns.add_child(_illustration_column)
	_picture = TextureRect.new()
	_picture.name = "MissionPanorama"
	_picture.custom_minimum_size = Vector2(180, 132)
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture.tooltip_text = "Gebietsillustration"
	_illustration_column.add_child(_picture)
	_details = Label.new()
	_details.name = "MissionFacts"
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.custom_minimum_size.x = 155
	_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	briefing_columns.add_child(_details)
	_objectives = Label.new()
	_objectives.name = "MissionObjectives"
	_objectives.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objectives.custom_minimum_size.x = 150
	_objectives.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_illustration_column.add_child(_objectives)
	_detail_card.resized.connect(_layout_dossier)
	_actions = HFlowContainer.new()
	_actions.name = "JobActions"
	_actions.add_theme_constant_override("h_separation", 8)
	_footer = PanelContainer.new()
	_footer.name = "JobActionFooter"
	_footer.add_theme_stylebox_override("panel", SKIN.box())
	layout.add_child(_footer)
	_footer.add_child(_actions)
	_accept = _button("AcceptJob", "Auftrag annehmen")
	SKIN.primary(_accept)
	_accept.pressed.connect(func(): _request("accept_job", {"job_id": _job_id}))
	_show_map = _button("ShowOnMap", "Auf Karte zeigen")
	_show_map.pressed.connect(_show_selected_on_map)
	_abandon = _button("AbandonJob", "Auftrag abbrechen")
	_abandon.pressed.connect(func(): _request("abandon_job", {"job_id": _job_id}))
	resized.connect(_layout_device)
	_layout_device()

func _layout_device() -> void:
	if _device == null: return
	_device.custom_minimum_size.x = maxf(size.x - 20, 280)
	_body.columns = 2 if size.x >= 640 and _details_expanded else 1
	_job_cards.visible = size.x >= 640 or not _details_expanded
	_jobs.visible = size.x < 640 and _details_expanded
	_layout_dossier()

func _layout_dossier() -> void:
	if _illustration_column == null: return
	_illustration_column.custom_minimum_size.x = clampf((_detail_card.size.x - 32.0) * 0.5, 180.0, 300.0)

func _button(node_name: String, text: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size.y = 34
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_actions.add_child(button)
	return button

func _request(operation: String, payload: Dictionary) -> Dictionary:
	var screen: Control = _screen.get_ref()
	var result: Dictionary = screen.call("request_operation", operation, payload)
	refresh()
	return result

func _show_selected_on_map() -> void:
	var campaign: Dictionary = _snapshot()
	var job: Dictionary = Dictionary(campaign.get("jobs", {}).get(_job_id, {}))
	if job.is_empty():
		return
	var result: Dictionary = _request("select_destination", {"location_id": String(job.location_id), "job_id": _job_id if String(job.get("status", "")) in ["accepted", "active"] else ""})
	if result.get("ok", false):
		_request("navigate", {"mode": "map"})

func _snapshot() -> Dictionary:
	var screen: Control = _screen.get_ref()
	return Dictionary(screen.call("get_operations_snapshot").get("singleplayer", {}).get("campaign", {}))

func refresh() -> void:
	if _content == null:
		return
	var screen: Control = _screen.get_ref()
	var singleplayer: Dictionary = screen.call("get_operations_snapshot").get("singleplayer", {})
	var campaign: Dictionary = singleplayer.get("campaign", {})
	var jobs: Dictionary = campaign.get("jobs", {})
	var availability: Dictionary = campaign.get("job_availability", {})
	var signature: String = JSON.stringify([jobs, availability])
	if signature != _signature:
		_signature = signature
		_job_list_rebuilds += 1
		var focused_job := ""
		for id: String in _card_buttons:
			if _card_buttons[id].has_focus(): focused_job = id; break
		_jobs.clear()
		for child:Node in _job_cards.get_children():_job_cards.remove_child(child);child.queue_free()
		_card_buttons.clear()
		_visible_job_ids.clear()
		for id in jobs:
			if not bool(Dictionary(availability.get(id, {})).get("visible", false)): continue
			_visible_job_ids.append(String(id))
			_jobs.add_item(String(jobs[id].title))
			_jobs.set_item_metadata(_jobs.item_count - 1, id)
			var card:=Button.new();card.text=String(jobs[id].title);card.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;card.custom_minimum_size=Vector2(230,52);_job_cards.add_child(card)
			card.alignment=HORIZONTAL_ALIGNMENT_LEFT;card.icon=MENU_ICONS.get_icon("satellite_chip");card.expand_icon=true;card.add_theme_constant_override("icon_max_width",30)
			var target_id:String=String(id)
			card.pressed.connect(_toggle_job_details.bind(target_id))
			_card_buttons[target_id]=card
		if not _visible_job_ids.has(_job_id):
			_job_id = String(_visible_job_ids[0]) if not _visible_job_ids.is_empty() else ""
		if _card_buttons.has(focused_job): _card_buttons[focused_job].call_deferred("grab_focus")
	_empty.visible = _visible_job_ids.is_empty()
	_empty.text = "Zurzeit keine verfügbaren Aufträge."
	if _empty.visible:
		_details_expanded = false
		for id: String in jobs:
			if String(jobs[id].get("status", "")) == "failed":
				_empty.text += "\n" + String(Dictionary(availability.get(id, {})).get("message", ""))
				break
	for index in range(_jobs.item_count):
		if String(_jobs.get_item_metadata(index)) == _job_id:
			_jobs.select(index)
	var job: Dictionary = jobs.get(_job_id, {})
	for id:String in _card_buttons:
		_card_buttons[id].modulate=Color.WHITE if id==_job_id else Color("b0c1c3")
		_card_buttons[id].text=("▾  " if id==_job_id and _details_expanded else "▸  ")+String(jobs[id].title) + "\n" + _lock_text(availability, id, _status_text(jobs[id]))
	var status: String = String(job.get("status", "offered"))
	var locations: Dictionary = campaign.get("locations", {})
	var location_id := String(job.get("location_id", ""))
	var location: Dictionary = locations.get(location_id, {})
	var picture_key := _job_id + "|" + location_id
	if picture_key != _picture_key:
		_picture_key = picture_key
		_picture.texture = SKIN.job_picture(_job_id, location_id)
		# Preserve the entire dish and broken solar panels within the compact band.
		_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if _job_id == "satellite_recovery" else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_dossier_heading.text = String(job.get("title", "Aufträge"))
	_summary.text = String(job.get("description", ""))
	_summary.tooltip_text = _summary.text
	_summary.visible = not _summary.text.is_empty() and not _summary.text.contains("Bestätigten Fortschritt im Auftrag verfolgen.")
	_details.text = "Zielort: %s\nStatus: %s\nBelohnung: %d Kredite" % [DISPLAY.location_name(location_id, location), "Vorherigen Auftrag abschließen" if bool(job.get("locked",false)) else _lock_text(availability, _job_id, _status_text(job)), int(Dictionary(job.get("reward", {})).get("credits", 0))]
	var issuer:Dictionary=JOBS.get_issuer_for_job(_job_id)
	if not issuer.is_empty():_details.text="Auftraggeber: %s\n\n%s"%[String(issuer.display_name),_details.text]
	var briefing:Dictionary=JOBS.get_briefing(_job_id,campaign,singleplayer.get("space_travel",{}))
	var body_name:String=String(briefing.get("body_name",""))
	if not body_name.is_empty():
		_details.text="Himmelskörper: %s (%s)\nEinsatzgebiet: %s\nStatus: %s\nBelohnung: %d Kredite"%[body_name,String(briefing.get("body_kind","")),String(briefing.get("site_label",location.get("name","—"))),_lock_text(availability,_job_id,_status_text(job)),int(Dictionary(job.get("reward",{})).get("credits",0))]
		if not issuer.is_empty():_details.text+="\nAuftraggeber: "+String(issuer.display_name)
	var objectives:PackedStringArray=PackedStringArray()
	for objective:String in briefing.get("objectives",[]):objectives.append("• "+objective)
	_objectives.text="ZIELE\n" + "\n".join(objectives) if not objectives.is_empty() else ""
	var campaign_mode := String(singleplayer.get("mode", "")) == "campaign"
	_accept.disabled = not bool(Dictionary(availability.get(_job_id, {})).get("can_accept", false))
	_accept.tooltip_text = String(Dictionary(availability.get(_job_id, {})).get("message", ""))
	_accept.text = "Erneut annehmen" if campaign_mode and status == "failed" else "Auftrag annehmen"
	_show_map.disabled = not status in ["accepted", "active", "completed"]
	_show_map.text = "Ort erneut besuchen" if status == "completed" else "Auf Karte zeigen"
	_abandon.disabled = not status in ["accepted", "active"]
	_detail_card.visible=_details_expanded;_objectives.visible=_details_expanded;_actions.visible=_details_expanded
	_footer.visible = _details_expanded
	_layout_device()

## Gesperrt gelisteter Auftrag (Vorgaenger fertig, Vorbedingung fehlt): statt des Statustexts steht der
## Grund der Sperre im Wortlaut des Kampagnenstands. Sonst unveraenderter Statustext.
func _lock_text(availability: Dictionary, id: String, status_text: String) -> String:
	var entry: Dictionary = availability.get(id, {})
	if bool(entry.get("locked", false)) and not String(entry.get("message", "")).is_empty():
		return "Gesperrt: " + String(entry.message)
	return status_text

## Statuszeile eines Auftrags. Nach einem Rueckzug bleibt der Auftrag offen; die Anzeige liest nur
## retreat_count und reopen_at_home aus dem Kampagnenstand. Ohne Rueckzug der heutige Statustext.
func _status_text(job: Dictionary) -> String:
	var status := String(job.get("status", "offered"))
	var text := String(DISPLAY.STATUS.get(status, status))
	var retreats := int(job.get("retreat_count", 0))
	if retreats > 0 and status == "failed" and bool(job.get("reopen_at_home", false)):
		return "Rückzug · wird an der Basis wieder geöffnet"
	if retreats > 0 and status in ["offered", "accepted"]:
		return "Offen · 1 Rückzug" if retreats == 1 else "Offen · %d Rückzüge" % retreats
	return text

func _toggle_job_details(id:String)->void:
	_details_expanded=not _details_expanded if id==_job_id else true
	_job_id=id
	refresh()
