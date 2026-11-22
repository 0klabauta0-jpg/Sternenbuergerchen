extends CanvasLayer
## Speichern, erster Teil / 21.11. (S3): Kurze Rueckmeldungszeile am unteren Bildschirmrand ("Kampagne gespeichert.", "Speichern vorgemerkt: ...",
## Ablehnungssatz). Sie verschwindet nach einigen Sekunden von selbst und faengt keine Eingabe (alle Steuerelemente ignorieren die Maus,
## nichts nimmt den Fokus). Reine Anzeige: sie kennt weder Spielstand noch Speicherweg.
const SHOW_SECONDS := 4.5

var _panel: PanelContainer
var _label: Label
var _timer: Timer

func _ready() -> void:
	layer = 900 # ueber der Spielansicht, unter dem Escape-Menue (1000)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.name = "ToastPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.focus_mode = Control.FOCUS_NONE
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 28)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label = Label.new()
	_label.name = "ToastLabel"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.focus_mode = Control.FOCUS_NONE
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(520.0, 0.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 15)
	_panel.add_child(_label)
	add_child(_panel)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_hide_toast)
	add_child(_timer)
	_panel.hide()

## Zeigt den Satz und startet den Ablauf neu.
func show_text(text: String, seconds: float = -1.0) -> void:
	if _label == null: return
	_label.text = text
	_panel.show()
	# Lange Saetze (Grund plus Zeitpunkt, bis zu rund 190 Zeichen) bleiben laenger stehen als "Gespeichert.".
	var shown_for: float = seconds if seconds > 0.0 else maxf(SHOW_SECONDS, float(text.length()) * 0.05)
	_timer.start(maxf(0.5, shown_for))

func _hide_toast() -> void:
	if _panel != null: _panel.hide()

func is_showing() -> bool:
	return _panel != null and _panel.visible

func get_text() -> String:
	return _label.text if _label != null else ""

## Fuer Tests: wahr, wenn kein Steuerelement der Zeile Mausereignisse oder Fokus annimmt.
func fangt_keine_eingabe() -> bool:
	for control: Control in [_panel, _label]:
		if control == null or control.mouse_filter != Control.MOUSE_FILTER_IGNORE or control.focus_mode != Control.FOCUS_NONE:
			return false
	return true
