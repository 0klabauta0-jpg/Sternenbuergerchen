extends Window
## Explicit invitation copying; access keys never appear in status labels.
signal action_requested(action: String, payload: Dictionary)
var _mode: OptionButton
var _address: LineEdit
var _status: Label
var _help: Label
var _host: Button
var _copy: Button
var _invitation := ""

func _ready() -> void:
	title = "Koop · zwei Commander, eine Crew"
	unresizable = true
	transient = true
	size = Vector2i(560,440)
	close_requested.connect(hide)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,22)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",12)
	margin.add_child(box)
	_mode = OptionButton.new()
	_mode.add_item("Internet · mit Einladungslink")
	_mode.add_item("LAN · im selben Netzwerk")
	_mode.item_selected.connect(func(_id:int):_update_mode())
	box.add_child(_mode)
	_help = Label.new()
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help.custom_minimum_size = Vector2(510,55)
	box.add_child(_help)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	box.add_child(row)
	_host = _button(row,"Internet-Sitzung öffnen",func():action_requested.emit("internet_host" if _mode.selected==0 else "host",{}))
	_copy = _button(row,"Einladung kopieren",func():
		if not _invitation.is_empty(): DisplayServer.clipboard_set(_invitation);_status.text="Einladung kopiert. Schicke sie deinem Freund persönlich.")
	_copy.disabled = true
	_address = LineEdit.new()
	_address.custom_minimum_size.y = 38
	box.add_child(_address)
	_button(box,"Beitreten",func():
		var address := _address.text.strip_edges()
		if address.is_empty(): _status.text="Zuerst eine Einladung oder Adresse einfügen.";return
		action_requested.emit("internet_join" if _mode.selected==0 else "join",{"address":address}))
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(510,66)
	box.add_child(_status)
	_button(box,"Verbindung schließen",func():action_requested.emit("disconnect",{}))
	_update_mode()
	hide()

func _button(parent:Node,text:String,callback:Callable)->Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 38
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _update_mode()->void:
	var internet := _mode.selected==0
	_host.text = "Internet-Sitzung öffnen" if internet else "LAN-Sitzung öffnen"
	_copy.visible = internet
	_address.placeholder_text = "Einladungslink des Hosts einfügen" if internet else "LAN-Adresse, z. B. 192.168.1.42"
	_address.secret = internet
	_help.text = "Host öffnen → Einladung kopieren → Freund fügt sie ein.\nDer Host muss das Spiel geöffnet lassen." if internet else "Host führt Ida, Gast Jaro. Im selben Netzwerk genügt die lokale IP-Adresse des Hosts."

func present(status:String,invitation:String)->void:
	if not is_instance_valid(_status):return
	_invitation = invitation
	_copy.disabled = invitation.is_empty()
	if _status.text.begins_with("Einladung kopiert") and not invitation.is_empty():return
	_status.text = status

func open(internet:bool=true)->void:
	_mode.select(0 if internet else 1)
	_update_mode()
	popup_centered(Vector2i(560,440))
