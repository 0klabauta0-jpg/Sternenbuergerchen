extends PanelContainer
## Cached presentation over the real Operations command bridge.

var _screen: WeakRef
var _content: VBoxContainer
var _jobs: OptionButton
var _details: Label
var _accept: Button
var _show_map: Button
var _abandon: Button
var _job_id: String = ""
var _signature: String = ""

func configure(screen: Control) -> void:
	_screen = weakref(screen)
	name = "JobBoard"
	var scroll := ScrollContainer.new()
	add_child(scroll)
	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 16)
	scroll.add_child(_content)
	var heading := Label.new()
	heading.text = "SMART MOBILE  /  Aufträge"
	heading.add_theme_font_size_override("font_size", 28)
	_content.add_child(heading)
	_jobs = OptionButton.new()
	_jobs.custom_minimum_size.y = 46
	_content.add_child(_jobs)
	_jobs.item_selected.connect(func(index: int): _job_id = String(_jobs.get_item_metadata(index)); refresh())
	_details = Label.new()
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.custom_minimum_size.y = 130
	_content.add_child(_details)
	_accept = _button("AcceptJob", "Auftrag annehmen")
	_accept.pressed.connect(func(): _request("accept_job", {"job_id": _job_id}))
	_show_map = _button("ShowOnMap", "Auf Karte zeigen")
	_show_map.pressed.connect(_show_selected_on_map)
	_abandon = _button("AbandonJob", "Auftrag abbrechen")
	_abandon.pressed.connect(func(): _request("abandon_job", {"job_id": _job_id}))

func _button(node_name: String, text: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size.y = 46
	_content.add_child(button)
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
		for id in jobs:
			_jobs.add_item(String(jobs[id].title))
			_jobs.set_item_metadata(_jobs.item_count - 1, id)
		if not jobs.has(_job_id):
			_job_id = String(jobs.keys()[0]) if not jobs.is_empty() else ""
	for index in range(_jobs.item_count):
		if String(_jobs.get_item_metadata(index)) == _job_id:
			_jobs.select(index)
	var job: Dictionary = jobs.get(_job_id, {})
	var status: String = String(job.get("status", "offered"))
	var locations: Dictionary = campaign.get("locations", {})
	var location: Dictionary = locations.get(String(job.get("location_id", "")), {})
	var labels := {"offered": "Angeboten", "accepted": "Angenommen", "active": "Im Einsatz", "completed": "Abgeschlossen", "failed": "Abgebrochen / fehlgeschlagen"}
	_details.text = "%s\nZielort: %s\nStatus: %s\nBelohnung: %d Credits\n\nDaten sichern, anschließend zum Schiff zurückkehren. Annahme startet keinen Flug." % [String(job.get("title", "Keine Aufträge")), String(location.get("name", "—")), String(labels.get(status, status)), int(Dictionary(job.get("reward", {})).get("credits", 0))]
	_accept.disabled = status != "offered" or job.is_empty()
	_show_map.disabled = not status in ["accepted", "active"]
	_abandon.disabled = not status in ["accepted", "active"]
