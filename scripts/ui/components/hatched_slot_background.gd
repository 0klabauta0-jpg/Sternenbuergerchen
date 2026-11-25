extends Control
## Dezente graue Schraffur fuer leere Ablegefelder (diagonale Linien, keine Bilddatei).
## Gleiche Zeichnung wie die Klasse Hatch im Schiffsdetail; faengt keine Mausereignisse ab.
const SPACING := 8.0
const LINE_COLOR := Color(0.62, 0.7, 0.74, 0.16)
## Ausgegraute Schriftfarbe fuer die Aufschrift eines leeren Fachs.
const MUTED_TEXT := Color(0.62, 0.68, 0.72, 0.7)

func _init() -> void:
	name = "Hatch"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	var height: float = size.y
	var x: float = -height
	while x < size.x:
		draw_line(Vector2(x, height), Vector2(x + height, 0.0), LINE_COLOR, 1.0)
		x += SPACING
