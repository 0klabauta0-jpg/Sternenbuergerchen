extends VBoxContainer
## Wiederverwendbarer Baustein: das gewaehlte Schiff mit Bild, Pilotplatz, Truppplaetzen und Fracht.
## Reine Anzeige. Der Pilot-Auswahlkasten wird vom Aufrufer in `pilot_host` gehaengt (Befehl `pilot` bleibt beim Aufrufer).
const INVENTORY_PANEL: GDScript = preload("res://scripts/ui/components/personnel_inventory_panel.gd")
const CYAN := Color("6fe3e8")
const CREAM := Color("f2ead0")
const MUTED := Color("93aab3")
const GOLD := Color("f2c94c")
var pilot_host: VBoxContainer
var _preview: TextureRect
var _name: Label
var _status: Label
var _pilot_slot: Label
var _troops: VBoxContainer
var _cargo_title: Label
var _cargo: Label
var _labels: Dictionary = {}
var _signature: String = ""

func _init() -> void:
	name = "ShipDetail"
	add_theme_constant_override("separation", 8)
	_labels = INVENTORY_PANEL.get_script_constant_map().get("LABELS", {})
	_preview = TextureRect.new()
	_preview.name = "CraftPreview"
	_preview.custom_minimum_size = Vector2(0, 150)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_preview)
	_name = _label("Kein Schiff", 22, CREAM)
	_name.name = "CraftName"
	add_child(_name)
	_status = _label("", 15, GOLD)
	_status.name = "CraftStatus"
	add_child(_status)
	add_child(_label("Pilotplatz", 14, MUTED))
	var pilot_box := PanelContainer.new()
	pilot_box.name = "PilotSlot"
	pilot_box.add_theme_stylebox_override("panel", _box(Color("163743"), CYAN))
	add_child(pilot_box)
	var pilot_inner := VBoxContainer.new()
	pilot_inner.add_theme_constant_override("separation", 4)
	pilot_box.add_child(pilot_inner)
	_pilot_slot = _label("Nicht zugewiesen", 16, CREAM)
	_pilot_slot.name = "PilotName"
	pilot_inner.add_child(_pilot_slot)
	pilot_host = VBoxContainer.new()
	pilot_host.name = "PilotHost"
	pilot_inner.add_child(pilot_host)
	add_child(_label("Truppplätze", 14, MUTED))
	_troops = VBoxContainer.new()
	_troops.name = "TroopSlots"
	_troops.add_theme_constant_override("separation", 4)
	add_child(_troops)
	_cargo_title = _label("Fracht", 14, MUTED)
	add_child(_cargo_title)
	var cargo_box := PanelContainer.new()
	cargo_box.name = "Cargo"
	cargo_box.add_theme_stylebox_override("panel", _box(Color("102f3b"), Color("3e6972")))
	add_child(cargo_box)
	_cargo = _label("Leer", 14, CREAM)
	cargo_box.add_child(_cargo)

## craft: Eintrag aus dem Operations-Schnappschuss; cargo: Behaelter `craft:<id>` ({items:{id:n}, capacity}) oder leer.
func update_craft(craft: Dictionary, cargo: Dictionary) -> void:
	var path: String = String(craft.get("texture_path", ""))
	if String(_preview.get_meta("rendered_path", "__unset")) != path:
		_preview.texture = load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
		_preview.set_meta("rendered_path", path)
	_name.text = String(craft.get("name", "Kein Schiff"))
	_status.text = String(craft.get("status", ""))
	var pilot: String = String(craft.get("pilot_name", ""))
	_pilot_slot.text = pilot if not pilot.is_empty() else "Nicht zugewiesen"
	var slots: int = clampi(int(craft.get("crew_capacity", 0)) - 1, 0, 4)
	var names: Array = Array(craft.get("payload_names", []))
	var signature: String = "%d|%s" % [slots, JSON.stringify(names)]
	if signature != _signature:
		_signature = signature
		for child in _troops.get_children():
			_troops.remove_child(child)
			child.queue_free()
		if slots == 0:
			var note := _label("Kein Platz für einen Trupp", 14, MUTED)
			note.name = "TroopNote"
			_troops.add_child(note)
		for index in slots:
			var slot := PanelContainer.new()
			slot.name = "TroopSlot_%d" % index
			slot.add_theme_stylebox_override("panel", _box(Color("163743"), Color("28515e")))
			var text := _label(String(names[index]) if index < names.size() else "Frei", 15, CREAM if index < names.size() else MUTED)
			slot.add_child(text)
			_troops.add_child(slot)
	var items: Dictionary = Dictionary(cargo.get("items", {}))
	var lines: PackedStringArray = PackedStringArray()
	for item in items:
		lines.append("%s × %d" % [String(_labels.get(item, String(item).replace("_", " "))), int(items[item])])
	_cargo.text = "\n".join(lines) if not lines.is_empty() else "Leer"

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _box(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
