extends Control
## Career selection only. Gameplay lives in the subsequently loaded Game scene.
const SAVE_PATH := "user://campaign.json"
const Icons = preload("res://scripts/ui/hud_icons.gd")
var _card: VBoxContainer
var _home: VBoxContainer
var _network: VBoxContainer
var _address: LineEdit
var _notice: Label
var _continue: Button
var _starting := false
var _team_mode: CheckButton

func _ready() -> void:
	DisplayServer.window_set_title("Sternenbürgerchen · Rostgrenze")
	get_tree().auto_accept_quit = true
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/curated/main-menu/background.jpeg")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0,0.40,0.75,1.0])
	gradient.colors = PackedColorArray([Color(0.025,0.045,0.06,0.97),Color(0.025,0.045,0.06,0.86),Color(0.025,0.045,0.06,0.18),Color(0.025,0.045,0.06,0.05)])
	var wash := GradientTexture2D.new()
	wash.gradient = gradient
	var shade := TextureRect.new()
	shade.texture = wash
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Bahnschrift","Segoe UI"])
	theme.default_font = font
	theme.default_font_size = 16
	theme.set_color("font_color","Label",Color("eee8da"))
	self.theme = theme
	_card = VBoxContainer.new()
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	_card.position = Vector2(82,-315)
	_card.custom_minimum_size = Vector2(390,0)
	_card.add_theme_constant_override("separation",18)
	add_child(_card)
	_label(_card,"ROSTGRENZE  /  EINE KLEINE CREW",13,Color("efab6f"))
	_label(_card,"Sternen\nbürgerchen",52,Color("f1ede3"))
	var lead := _label(_card,"Zwei Freunde. Ein eigenes Schiff.\nWas ihr daraus macht, liegt bei euch.",17,Color("bdc9c8"))
	lead.custom_minimum_size.y = 72
	_home = VBoxContainer.new()
	_home.add_theme_constant_override("separation",9)
	_card.add_child(_home)
	_continue = _button(_home,"Karriere fortsetzen" if FileAccess.file_exists(SAVE_PATH) else "Neue Karriere","play",func():_launch("", "", true))
	if FileAccess.file_exists(SAVE_PATH): _button(_home,"Neu beginnen","crew",_confirm_new)
	_button(_home,"Mehrspieler · Koop / Team gegen Team","network",func():_home.hide();_network.show();_notice.text="Internet: Einladungslink austauschen.\nIm selben Netzwerk funktioniert weiterhin LAN.")
	_button(_home,"Beenden","close",func():get_tree().quit())
	_network = VBoxContainer.new()
	_network.add_theme_constant_override("separation",9)
	_card.add_child(_network)
	_team_mode=CheckButton.new()
	_team_mode.text="Team-Partie · 2 Teams mit je bis zu 8 Spielern"
	_team_mode.tooltip_text="Gemeinsame Crew je Team, eigene Karriere je Gegner. Ohne Haken: gemeinsame Koop-Karriere."
	_network.add_child(_team_mode)
	_button(_network,"Internet-Sitzung öffnen","network",func():_launch("internet_host"))
	_address = LineEdit.new()
	_address.secret = true
	_address.placeholder_text = "Einladungslink oder LAN-Adresse einfügen"
	_address.custom_minimum_size.y = 44
	_address.add_theme_font_size_override("font_size",13)
	_network.add_child(_address)
	_button(_network,"Einladung beitreten","play",func():
		var address := _address.text.strip_edges()
		if address.is_empty(): _notice.text="Füge zuerst den Einladungslink deines Freundes ein.";return
		_launch("internet_join" if address.begins_with("wss://") else "lan_join",address))
	_button(_network,"LAN-Sitzung öffnen","network",func():_launch("lan_host"))
	_button(_network,"Zurück","back",func():_network.hide();_home.show();_notice.text="")
	_network.hide()
	_notice = _label(_card,"",13,Color("efab6f"))
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.custom_minimum_size = Vector2(390,52)
	var footer := _label(self,"COMMANDER-STEUERUNG   ·   RECHTSKLICK: ZIEL   ·   ECHTZEIT MIT PAUSE",12,Color("b8c5c6"))
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.offset_left = 82
	footer.offset_top = -36
	footer.offset_bottom = -18
	_continue.grab_focus()
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--host": _launch.call_deferred("lan_host")
		if arg.begins_with("--join="): _launch.call_deferred("lan_join",arg.trim_prefix("--join="))
		if arg.begins_with("--capture="): _capture.call_deferred(arg.trim_prefix("--capture="),"--capture-quit" in OS.get_cmdline_user_args())

func _label(parent: Node, text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
	return label

func _button(parent: Node, title: String, icon: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.icon = Icons.texture(icon)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width",22)
	button.add_theme_constant_override("h_separation",14)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(390,46)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08,0.14,0.17,0.87) if state == "normal" else Color(0.16,0.28,0.30,0.97)
		style.border_color = Color("51666b") if state == "normal" else Color("e3aa76")
		style.set_border_width_all(1)
		style.content_margin_left = 16
		style.content_margin_right = 16
		button.add_theme_stylebox_override(state,style)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _confirm_new() -> void:
	var confirm := ConfirmationDialog.new()
	confirm.title = "Neue Karriere"
	confirm.dialog_text = "Eine neue Karriere ersetzt beim nächsten Speichern den bisherigen Spielstand."
	confirm.ok_button_text = "Neu beginnen"
	confirm.cancel_button_text = "Zurück"
	add_child(confirm)
	confirm.confirmed.connect(func():_launch("","",false))
	confirm.canceled.connect(confirm.queue_free)
	confirm.popup_centered(Vector2i(490,160))

func _launch(mode: String = "", address: String = "", restore: bool = true) -> void:
	if _starting: return
	_starting = true
	var game:Node = load("res://scenes/game.tscn").instantiate()
	game.team_mode = is_instance_valid(_team_mode) and _team_mode.button_pressed and mode.ends_with("host")
	game.load_on_start = restore
	game.startup_network_mode = mode
	game.startup_network_address = address
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	queue_free()

func _capture(path: String, close: bool) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var result := get_viewport().get_texture().get_image().save_png(path)
	print("MENU_CAPTURE result=",result)
	if close: get_tree().quit(0 if result==OK else 1)
