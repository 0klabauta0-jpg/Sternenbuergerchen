extends Control
## A view of existing knowledge only. No command, area or travel owner.
const APP_THEME = preload("res://scripts/ui/smart_mobile_theme.gd")
const ORBIT_CANVAS = preload("res://scripts/ui/orbit_area_canvas.gd")
signal back_requested
var _provider: Callable
var _projection: Dictionary = {}
var _heading: Label
var _knowledge: Label
var _orbit: Control
var _elapsed := 0.0

func _ready() -> void:
	name = "RemoteInspection"
	theme = APP_THEME.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stack := VBoxContainer.new()
	add_child(stack)
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.offset_left = 16
	stack.offset_right = -16
	stack.offset_top = 12
	stack.offset_bottom = -12
	var bar := HBoxContainer.new()
	stack.add_child(bar)
	var back := Button.new()
	back.name = "BackToStarMap"
	back.text = "‹ Sternkarte"
	back.custom_minimum_size = Vector2(140, 38)
	back.pressed.connect(func(): back_requested.emit())
	bar.add_child(back)
	_heading = Label.new()
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_heading.add_theme_font_size_override("font_size", 22)
	bar.add_child(_heading)
	_knowledge = Label.new()
	_knowledge.name = "KnowledgeStatus"
	_knowledge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_knowledge.text = "Keine Sichtdaten · Das Gebiet ist nicht aufgeklärt."
	stack.add_child(_knowledge)
	_orbit = ORBIT_CANVAS.new()
	_orbit.name = "KnownOrbit"
	_orbit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(_orbit)
	_orbit.hide()

func configure(provider: Callable) -> void:
	_provider = provider
	refresh()
	set_process(Dictionary(_projection.get("target", {})).get("kind") == "orbit")

func refresh() -> void:
	if not _provider.is_valid() or not is_instance_valid(_heading): return
	var next: Dictionary = _provider.call()
	if next == _projection: return
	_projection = next.duplicate(true)
	_heading.text = String(next.get("title", "Ortsansicht"))
	var area: Dictionary = next.get("area", {})
	var known := bool(area.get("ok", false))
	_knowledge.text = "Aktuelle Sicht eigener Schiffe · Nur Ansicht" if known else "Keine Sichtdaten · Das Gebiet ist nicht aufgeklärt."
	_orbit.visible = known
	# Empty selection and no move signal handler: this screen never sends orders.
	_orbit.call("set_projection", area if known else {}, "", next.get("body_visual", {}))

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_elapsed += delta
	if _elapsed >= 0.2:
		_elapsed = 0.0
		refresh()

func get_inspection_snapshot() -> Dictionary:
	return {"target":_projection.get("target", {}).duplicate(true),
		"title":_heading.text if is_instance_valid(_heading) else "",
		"blackout":not bool(Dictionary(_projection.get("area", {})).get("ok", false)),
		"visible":is_visible_in_tree()}
