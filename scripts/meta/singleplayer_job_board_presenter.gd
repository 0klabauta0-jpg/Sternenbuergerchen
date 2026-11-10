extends PanelContainer
## Cached presentation over the real Operations command bridge.
const SKIN=preload("res://scripts/ui/base_management_skin.gd")
const JOBS=preload("res://scripts/mission/singleplayer_job_contract.gd")

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

func configure(screen: Control) -> void:
	_screen = weakref(screen)
	name = "JobBoard"
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(scroll)
	var alignment := HBoxContainer.new()
	alignment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(alignment)
	_device = PanelContainer.new()
	_device.name = "MobileDevice"
	_device.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_device.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	SKIN.panel(_device)
	alignment.add_child(_device)
	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	_device.add_child(_content)
	var code:=Label.new();code.text="SM-01  /  EINSATZPLANUNG";SKIN.eyebrow(code);_content.add_child(code)
	var heading := Label.new()
	heading.text = "Smart Mobile"
	SKIN.label(heading,30)
	_content.add_child(heading)
	var subtitle:=Label.new();subtitle.text="Aufträge auswählen, Fortschritt verfolgen und den nächsten Einsatz vorbereiten.";SKIN.label(subtitle,16,true);_content.add_child(subtitle)
	SKIN.rule(_content)
	_body=GridContainer.new();_body.add_theme_constant_override("h_separation",18);_body.add_theme_constant_override("v_separation",14);_content.add_child(_body)
	var selector_column:=VBoxContainer.new();selector_column.custom_minimum_size.x=230;selector_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_body.add_child(selector_column)
	_jobs = OptionButton.new()
	_jobs.custom_minimum_size.y = 40
	_jobs.fit_to_longest_item = false
	selector_column.add_child(_jobs)
	_job_cards=VBoxContainer.new();_job_cards.add_theme_constant_override("separation",8);selector_column.add_child(_job_cards)
	_jobs.item_selected.connect(func(index: int): _job_id = String(_jobs.get_item_metadata(index)); refresh())
	_details = Label.new()
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var detail_card:=PanelContainer.new();detail_card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;SKIN.panel(detail_card,true);_body.add_child(detail_card)
	SKIN.label(_details,16);_details.custom_minimum_size=Vector2(250,180);detail_card.add_child(_details)
	SKIN.rule(_content)
	_actions = HFlowContainer.new()
	_actions.name = "JobActions"
	_actions.add_theme_constant_override("h_separation", 8)
	_actions.add_theme_constant_override("v_separation", 8)
	_content.add_child(_actions)
	_accept = _button("AcceptJob", "Auftrag annehmen")
	SKIN.button(_accept,true)
	_accept.pressed.connect(func(): _request("accept_job", {"job_id": _job_id}))
	_show_map = _button("ShowOnMap", "Auf Karte zeigen")
	_show_map.pressed.connect(_show_selected_on_map)
	_abandon = _button("AbandonJob", "Auftrag abbrechen")
	_abandon.pressed.connect(func(): _request("abandon_job", {"job_id": _job_id}))
	resized.connect(_layout_device)
	_layout_device()

func _layout_device() -> void:
	if _device != null:
		_device.custom_minimum_size.x = clampf(size.x-16, 280.0, 1040.0)
		if _body!=null:_body.columns=2 if size.x>=640 else 1
		if _job_cards!=null:_job_cards.visible=size.x>=640
		if _jobs!=null:_jobs.visible=size.x<640

func _button(node_name: String, text: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size.y = 40
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_actions.add_child(button)
	SKIN.button(button)
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
	var result: Dictionary = _request("select_destination", {"location_id": String(job.location_id), "job_id": _job_id})
	if result.get("ok", false):
		_request("navigate", {"mode": "map"})

func _snapshot() -> Dictionary:
	var screen: Control = _screen.get_ref()
	return Dictionary(screen.call("get_operations_snapshot").get("singleplayer", {}).get("campaign", {}))

func refresh() -> void:
	if _content == null:
		return
	var campaign: Dictionary = _snapshot()
	var jobs: Dictionary = campaign.get("jobs", {})
	var signature: String = JSON.stringify(jobs)
	if signature != _signature:
		_signature = signature
		_jobs.clear()
		for child:Node in _job_cards.get_children():_job_cards.remove_child(child);child.queue_free()
		_card_buttons.clear()
		_visible_job_ids.clear()
		for id in jobs:
			if bool(jobs[id].get("locked",false)):continue
			_visible_job_ids.append(String(id))
			_jobs.add_item(String(jobs[id].title))
			_jobs.set_item_metadata(_jobs.item_count - 1, id)
			var card:=Button.new();card.text=String(jobs[id].title);card.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;card.custom_minimum_size=Vector2(230,66);SKIN.button(card);_job_cards.add_child(card)
			card.alignment=HORIZONTAL_ALIGNMENT_LEFT;card.icon=load("res://Assets/curated/ui/campaign_inventory/chip.svg");card.expand_icon=true;card.add_theme_constant_override("icon_max_width",28)
			var target_id:String=String(id)
			card.pressed.connect(func():_job_id=target_id;refresh())
			_card_buttons[target_id]=card
		if not _visible_job_ids.has(_job_id):
			_job_id = String(_visible_job_ids[0]) if not _visible_job_ids.is_empty() else ""
	for index in range(_jobs.item_count):
		if String(_jobs.get_item_metadata(index)) == _job_id:
			_jobs.select(index)
	var job: Dictionary = jobs.get(_job_id, {})
	for id:String in _card_buttons:
		_card_buttons[id].modulate=Color.WHITE if id==_job_id else Color("b0c1c3")
	var status: String = String(job.get("status", "offered"))
	var locations: Dictionary = campaign.get("locations", {})
	var location: Dictionary = locations.get(String(job.get("location_id", "")), {})
	var labels := {"offered": "Angeboten", "accepted": "Angenommen", "active": "Im Einsatz", "completed": "Abgeschlossen", "failed": "Abgebrochen / fehlgeschlagen", "pending_upload":"Chip geborgen · zuhause hochladen"}
	_details.text = "Zielort: %s\nStatus: %s\nBelohnung: %d Kredite\n\n%s" % [String(location.get("name", "—")), "Vorherigen Auftrag abschließen" if bool(job.get("locked",false)) else String(labels.get(status, status)), int(Dictionary(job.get("reward", {})).get("credits", 0)),String(job.get("description","Annahme startet keinen Flug."))]
	var issuer:Dictionary=JOBS.get_issuer_for_job(_job_id)
	if not issuer.is_empty():_details.text="Auftraggeber: %s\n\n%s"%[String(issuer.display_name),_details.text]
	var screen: Control = _screen.get_ref()
	var campaign_mode := String(Dictionary(screen.call("get_operations_snapshot").get("singleplayer", {})).get("mode", "")) == "campaign"
	_accept.disabled = (status != "offered" and not (campaign_mode and status == "failed")) or job.is_empty() or (campaign_mode and bool(job.get("locked",false)))
	_accept.text = "Erneut annehmen" if campaign_mode and status == "failed" else "Auftrag annehmen"
	_show_map.disabled = not status in ["accepted", "active"]
	_abandon.disabled = not status in ["accepted", "active"]
