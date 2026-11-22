extends CanvasLayer
## Abschnitt P (22.11.2026): Pleite-Bildschirm der Kampagne. Vollbild-Ueberlagerung ueber Basis, Sternkarte und Orbit; faengt alle Mausklicks,
## nimmt Escape an und zeigt drei Knoepfe. Reine Anzeige: sie kennt weder Spielstand noch Speicherweg. Was die Knoepfe tun (Spielstand laden,
## neue Kampagne, Hauptmenue), entscheidet der Besitzer (meta_layer_flow) ueber das Signal action_requested ("load", "new", "main_menu").
## Gebaut wie das Spielmenue (global_escape_menu.gd): Shade plus zentrierte Tafel, Knoepfe mit demselben Mindestmass. Die Ebene liegt ueber dem
## Spielmenue (1000) und der Rueckmeldungszeile (900); die Szene laeuft auch bei angehaltener Zeit weiter (PROCESS_MODE_ALWAYS).
signal action_requested(action: String)

const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")
const TITLE_TEXT := "Pleite"
const MESSAGE_TEXT := "Die Schulden haben den Kreditrahmen erreicht, und kein Schiff kann mehr starten."
const NEW_CAMPAIGN_HINT := "Der vorhandene Kampagnenstand wird durch eine neue Kampagne ersetzt. Noch einmal drücken, um zu bestätigen."

var _debt_label: Label
var _hint_label: Label
var _load_button: Button
var _new_button: Button
var _menu_button: Button
var _new_armed := false

func _ready() -> void:
	name = "CampaignBankruptcyScreen"
	layer = 1100
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.name = "BankruptRoot"
	TACTICAL_UI_THEME_SCRIPT.apply_screen(root)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.014, 0.018, 0.88)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(shade)
	var panel := PanelContainer.new()
	panel.name = "BankruptPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -270.0
	panel.offset_right = 270.0
	panel.offset_top = -230.0
	panel.offset_bottom = 230.0
	root.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.name = "BankruptBox"
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var title := Label.new()
	title.name = "BankruptTitle"
	title.text = TITLE_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)
	var message := Label.new()
	message.name = "BankruptMessage"
	message.text = MESSAGE_TEXT
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 15)
	box.add_child(message)
	_debt_label = Label.new()
	_debt_label.name = "BankruptDebt"
	_debt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_debt_label.add_theme_font_size_override("font_size", 17)
	box.add_child(_debt_label)
	_hint_label = Label.new()
	_hint_label.name = "BankruptHint"
	_hint_label.text = NEW_CAMPAIGN_HINT
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.visible = false
	box.add_child(_hint_label)
	_load_button = _add_button(box, "BankruptLoad", "Spielstand laden", "load")
	_new_button = _add_button(box, "BankruptNewCampaign", "Neue Kampagne", "new")
	_menu_button = _add_button(box, "BankruptMainMenu", "Zum Hauptmenü", "main_menu")
	_load_button.grab_focus.call_deferred()

## Zeile mit dem Schuldenstand (fertiger Text, gebaut ueber credit_text.gd).
func set_debt_text(text: String) -> void:
	if _debt_label != null: _debt_label.text = text

## Sperrt die drei Knoepfe (waehrend des Szenenwechsels) oder gibt sie wieder frei.
func set_buttons_disabled(disabled: bool) -> void:
	for button: Button in [_load_button, _new_button, _menu_button]:
		if button != null: button.disabled = disabled

## Neue Kampagne ersetzt den vorhandenen Stand: der erste Druck zeigt nur den Hinweis, der zweite loest aus.
func is_new_campaign_armed() -> bool:
	return _new_armed

func _add_button(parent: Control, button_name: String, text: String, action: String) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.custom_minimum_size = Vector2(320.0, 46.0)
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("global_button_sfx_force", true)
	parent.add_child(button)
	button.pressed.connect(_on_pressed.bind(action))
	return button

func _on_pressed(action: String) -> void:
	if action == "new" and not _new_armed:
		_new_armed = true
		_hint_label.visible = true
		return
	action_requested.emit(action)

## Escape darf das Spielmenue nicht hinter dem Bildschirm oeffnen; alles andere laeuft wie sonst (Fokus, Eingabetaste).
func _input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and key_event.keycode == KEY_ESCAPE:
		var viewport := get_viewport()
		if viewport != null: viewport.set_input_as_handled()
