extends PanelContainer
## Independent regional location view; never a renamed tactical mission map.

var _screen: WeakRef
var _content: VBoxContainer
var _map: Control
var _status: Label
var _buttons: Dictionary = {}

func configure(screen: Control) -> void:
	_screen = weakref(screen)
	name = "RegionMap"
	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.add_theme_constant_override("separation", 12)
	add_child(_content)
	var title := Label.new()
	title.text = "REGION  /  Zielort wählen"
	title.add_theme_font_size_override("font_size", 28)
	_content.add_child(title)
	_map = Control.new()
	_map.name = "Locations"
	_map.custom_minimum_size = Vector2(0, 300)
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(_map)
	_map.resized.connect(_position_buttons)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(_status)
	var next := Button.new()
	next.text = "Weiter zu Einsatz & Abflug"
	next.custom_minimum_size.y = 48
	_content.add_child(next)
	next.pressed.connect(func(): _screen.get_ref().call("request_operation", "navigate", {"mode": "mission"}))
	refresh()

func refresh() -> void:
	var campaign: Dictionary = _screen.get_ref().call("get_operations_snapshot").get("singleplayer", {}).get("campaign", {})
	var locations: Dictionary = campaign.get("locations", {})
	for id in locations:
		var location: Dictionary = locations[id]
		if not _buttons.has(id):
			var button := Button.new()
			button.name = id
			button.custom_minimum_size = Vector2(200, 60)
			button.size = Vector2(200, 60)
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_map.add_child(button)
			button.pressed.connect(_select.bind(String(id)))
			button.set_meta("region_position", location.region_position)
			_buttons[id] = button
		var button: Button = _buttons[id]
		button.text = ("◆ " if String(campaign.get("selected_location_id", "")) == id else "◇ ") + String(location.name)
	_position_buttons()
	var selected: Dictionary = locations.get(String(campaign.get("selected_location_id", "")), {})
	var job: Dictionary = Dictionary(campaign.get("jobs", {})).get(String(campaign.get("selected_job_id", "")), {})
	_status.text = "Ziel: %s\nAuftrag: %s\nDie Zielwahl startet keinen Flug. Handel ist ohne Kampfauftrag erreichbar." % [String(selected.get("name", "—")), String(job.get("title", "Ortsbesuch"))]

func _select(location_id: String) -> void:
	var screen: Control = _screen.get_ref()
	var campaign: Dictionary = screen.call("get_operations_snapshot").get("singleplayer", {}).get("campaign", {})
	var job_id: String = ""
	var selected_job: String = String(campaign.get("selected_job_id", ""))
	var job: Dictionary = Dictionary(campaign.get("jobs", {})).get(selected_job, {})
	if String(job.get("location_id", "")) == location_id and String(job.get("status", "")) in ["accepted", "active"]:
		job_id = selected_job
	screen.call("request_operation", "select_destination", {"location_id": location_id, "job_id": job_id})
	refresh()

func _position_buttons() -> void:
	if _map == null:
		return
	for button in _buttons.values():
		var point: Array = Array(button.get_meta("region_position", [0.5, 0.5]))
		button.position = Vector2(float(point[0]) * maxf(_map.size.x - 220, 0), float(point[1]) * maxf(_map.size.y - 80, 0))
