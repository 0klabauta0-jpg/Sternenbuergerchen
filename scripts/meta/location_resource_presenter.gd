extends PanelContainer
## Discovered-site UI only; movement and extraction stay with their runtime owners.
var _owner: Node
var _choices: OptionButton
var _status: Label
var _use: Button
var _move: Button
var _details: VBoxContainer
var _toggle: Button
var _timer := 0.0
var _signature := ""
var _site_id := ""

func configure(owner: Node) -> void:
	_owner=owner
	custom_minimum_size=Vector2(280,0)
	position=Vector2(16,160)
	size=Vector2(280,0)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var content:=VBoxContainer.new()
	add_child(content)
	_toggle=Button.new()
	_toggle.text="Rohstoffe"
	content.add_child(_toggle)
	_details=VBoxContainer.new()
	content.add_child(_details)
	_toggle.pressed.connect(func(): _details.visible=not _details.visible)
	_choices=OptionButton.new()
	_choices.fit_to_longest_item=false
	_details.add_child(_choices)
	_choices.item_selected.connect(func(index: int): _site_id=String(_choices.get_item_metadata(index)); _refresh())
	_status=Label.new()
	_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size=Vector2(260,50)
	_details.add_child(_status)
	var buttons:=HBoxContainer.new()
	_details.add_child(buttons)
	_move=Button.new()
	_move.text="Trupp hinführen"
	buttons.add_child(_move)
	_move.pressed.connect(func(): _show_result(_owner.call("request_move_to",_site_id)))
	_use=Button.new()
	_use.text="Abbauen / Bergen"
	buttons.add_child(_use)
	_use.pressed.connect(func(): _show_result(_owner.call("request_use",_site_id)))
	_refresh()

func _process(delta: float) -> void:
	_timer+=delta
	if _timer<.25: return
	_timer=0.0
	_refresh()

func _refresh() -> void:
	if not is_instance_valid(_owner): hide(); return
	var snapshot: Dictionary=_owner.call("get_snapshot")
	var sites: Array=snapshot.get("sites",[])
	visible=not sites.is_empty()
	if not visible: return
	_toggle.text="Rohstoffe · %d entdeckt" % sites.size()
	var signature:=JSON.stringify(sites)
	if signature!=_signature:
		_signature=signature
		_choices.clear()
		for entry: Dictionary in sites:
			_choices.add_item(String(entry.name)+( " · erschöpft" if int(entry.remaining)==0 else ""))
			_choices.set_item_metadata(_choices.item_count-1,String(entry.site_id))
		var found:=false
		for index in range(_choices.item_count):
			if String(_choices.get_item_metadata(index))==_site_id: _choices.select(index); found=true
		if not found:
			_choices.select(0)
			_site_id=String(_choices.get_item_metadata(0))
	var selected: Dictionary={}
	for site: Dictionary in sites:
		if String(site.site_id)==_site_id: selected=site; break
	var active: Dictionary=snapshot.get("active_use",{})
	_use.disabled=selected.is_empty() or int(selected.get("remaining",0))==0 or not active.is_empty()
	_move.disabled=not active.is_empty()
	if not active.is_empty():
		_status.text="Bergung läuft: %.1f s\nPerson muss am Vorkommen bleiben." % float(active.get("elapsed",0.0))
	elif not String(snapshot.get("message","")).is_empty():
		_status.text=String(snapshot.message)
	else:
		_status.text="Trupp auswählen und zum Vorkommen führen. Zum Bergen passendes Werkzeug im Rucksack mitnehmen."

func _show_result(result: Dictionary) -> void:
	_status.text=String(result.get("message","Aktion ausgeführt" if result.get("ok",false) else "Aktion hier nicht möglich"))
