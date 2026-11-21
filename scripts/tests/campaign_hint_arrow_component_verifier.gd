extends SceneTree
## Baustein "Hinweispfeil": Platzierung, Eingabe-Durchlass, Textumbruch. Kein Spielstart, keine Einstellungen.

const ARROW_SCRIPT: GDScript = preload("res://scripts/ui/campaign_hint_arrow.gd")
const SIZES: Array[Vector2] = [Vector2(1280.0, 720.0), Vector2(1920.0, 1080.0)]
const MARGIN: float = 16.0

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("FAIL " + message)


func _run() -> void:
	var arrow: Control = ARROW_SCRIPT.new()
	arrow.set("pulse_enabled", false)
	root.add_child(arrow)
	await process_frame
	_check(not arrow.call("is_showing"), "Neu: nichts gezeigt")
	_check(Rect2(arrow.call("get_arrow_rect")).size == Vector2.ZERO, "Neu: leeres Pfeilrechteck")
	for view: Vector2 in SIZES:
		arrow.set("view_size_override", view)
		var targets: Dictionary = {
			"mitte": Rect2(view * 0.5 - Vector2(60.0, 20.0), Vector2(120.0, 40.0)),
			"linker Rand": Rect2(0.0, 200.0, 80.0, 60.0),
			"rechts unten": Rect2(view.x - 80.0, view.y - 70.0, 60.0, 50.0),
			"sehr breit": Rect2(40.0, 300.0, view.x - 80.0, 60.0),
		}
		for case_name: String in targets:
			var target: Rect2 = targets[case_name]
			var tag: String = "%s %dx%d" % [case_name, int(view.x), int(view.y)]
			arrow.call("show_at", target, "Hier per Drag and Drop ausrüsten")
			var rect: Rect2 = arrow.call("get_arrow_rect")
			_check(bool(arrow.call("is_showing")), "Zeigt: " + tag)
			_check(rect.size.x > 0.0 and rect.size.y > 0.0, "Rechteck nicht leer: " + tag)
			var inner: Rect2 = Rect2(Vector2(MARGIN, MARGIN), view - Vector2(MARGIN * 2.0, MARGIN * 2.0))
			_check(inner.encloses(rect), "16 px Rand im Fenster: %s %s" % [tag, str(rect)])
			_check(not rect.intersects(target), "Ziel bleibt frei: %s %s vs %s" % [tag, str(rect), str(target)])
			var layout: Dictionary = arrow.call("get_layout_snapshot")
			_check(bool(layout.get("has_box", false)), "Kasten vorhanden: " + tag)
	# Abschalten
	arrow.call("hide_arrow")
	_check(not arrow.call("is_showing"), "hide_arrow: nicht mehr gezeigt")
	_check(not arrow.visible, "hide_arrow: unsichtbar")
	_check(Rect2(arrow.call("get_arrow_rect")).size == Vector2.ZERO, "hide_arrow: leeres Rechteck")
	# Eingabe durchlassen
	arrow.call("show_at", Rect2(600.0, 300.0, 100.0, 40.0), "Kurz")
	var all_ignore: bool = true
	var no_focus: bool = true
	var nodes: Array[Node] = [arrow]
	nodes.append_array(arrow.find_children("*", "Control", true, false))
	for node: Node in nodes:
		var control: Control = node as Control
		if control == null:
			continue
		if control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			all_ignore = false
			print("mouse_filter nicht IGNORE bei " + str(control.name))
		if control.focus_mode != Control.FOCUS_NONE:
			no_focus = false
			print("focus_mode nicht NONE bei " + str(control.name))
	_check(all_ignore, "Alle Knoten MOUSE_FILTER_IGNORE")
	_check(no_focus, "Alle Knoten FOCUS_NONE")
	_check(nodes.size() >= 2, "Textknoten vorhanden")
	_check(not paused, "Baum nicht pausiert")
	# Textumbruch
	arrow.set("view_size_override", Vector2(1920.0, 1080.0))
	var label: Label = arrow.find_child("HintText", true, false) as Label
	_check(label != null, "Textknoten HintText gefunden")
	if label != null:
		var font: Font = label.get_theme_font("font")
		var line_height: float = font.get_height(ARROW_SCRIPT.FONT_SIZE)
		arrow.call("show_at", Rect2(900.0, 500.0, 100.0, 40.0), "Kurz")
		var short_height: float = label.size.y
		_check(short_height < line_height * 1.6, "Kurzer Text: eine Zeile (%f)" % short_height)
		arrow.call("show_at", Rect2(900.0, 500.0, 100.0, 40.0), "Dieser Hinweistext ist absichtlich viel zu lang fuer eine einzige Zeile und muss deshalb umbrechen")
		_check(label.size.x <= 220.0, "Langer Text: hoechstens 220 px breit (%f)" % label.size.x)
		_check(label.size.y >= line_height * 1.8, "Langer Text bricht um (%f)" % label.size.y)
		_check(label.autowrap_mode != TextServer.AUTOWRAP_OFF, "Label bricht um")
		var rect_long: Rect2 = arrow.call("get_arrow_rect")
		_check(Rect2(MARGIN, MARGIN, 1920.0 - 2.0 * MARGIN, 1080.0 - 2.0 * MARGIN).encloses(rect_long), "Langer Text bleibt im Fenster")
	# Fenster zu klein fuer Kasten: Pfeil ohne Kasten, trotzdem im Fenster
	arrow.set("view_size_override", Vector2(300.0, 200.0))
	arrow.call("show_at", Rect2(100.0, 80.0, 100.0, 40.0), "Dieser Hinweistext ist absichtlich viel zu lang fuer eine einzige Zeile")
	var tiny: Dictionary = arrow.call("get_layout_snapshot")
	_check(not bool(tiny.get("has_box", true)), "Enges Fenster: Pfeil ohne Kasten")
	arrow.call("hide_arrow")
	arrow.free()
	print("CAMPAIGN_HINT_ARROW_COMPONENT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
