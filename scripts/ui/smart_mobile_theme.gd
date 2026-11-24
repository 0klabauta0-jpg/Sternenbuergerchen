extends RefCounted
## Small cached app theme; does not alter the surrounding game or personnel UI.
const BODY: FontFile = preload("res://Assets/curated/smart_mobile_fonts/Rajdhani-Medium.ttf")
const HEADING: FontFile = preload("res://Assets/curated/smart_mobile_fonts/Rajdhani-SemiBold.ttf")
const INK := Color("08151e")
const PANEL := Color("10242d")
const TEXT := Color("e0edf0")
const MUTED := Color("9fbac5")
const AMBER := Color("edbb6c")
const PRIMARY_FILL := Color("b6833f")
const BACKGROUNDS = preload("res://scripts/assets/background_image_catalog.gd")
static var _pictures: Dictionary = {}
static var _theme: Theme
static var _styles: Dictionary = {}

static func box(id: String = "panel") -> StyleBoxFlat:
	if _styles.has(id): return _styles[id]
	var style := StyleBoxFlat.new()
	style.bg_color = INK if id == "shell" else PANEL
	style.border_color = Color("31525f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(1)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	if id == "hover": style.bg_color = Color("1b3944")
	if id == "pressed": style.bg_color = Color("294650"); style.border_color = AMBER
	if id == "focus": style.bg_color = Color.TRANSPARENT; style.border_color = AMBER; style.set_border_width_all(2)
	if id == "primary": style.bg_color = PRIMARY_FILL; style.border_color = AMBER
	# Hauptknopf: dieselbe Farbe in allen Zustaenden (hover heller, pressed dunkler, disabled entsaettigt), nie das graublaue Standardfeld.
	if id == "primary_hover": style.bg_color = PRIMARY_FILL.lightened(0.14); style.border_color = AMBER.lightened(0.2)
	if id == "primary_pressed": style.bg_color = PRIMARY_FILL.darkened(0.22); style.border_color = AMBER
	if id == "primary_disabled": style.bg_color = Color.from_hsv(PRIMARY_FILL.h, PRIMARY_FILL.s * 0.4, PRIMARY_FILL.v * 0.7); style.border_color = Color.from_hsv(AMBER.h, AMBER.s * 0.35, AMBER.v * 0.6)
	if id == "primary_focus": style.bg_color = Color.TRANSPARENT; style.border_color = Color("fff0c0"); style.set_border_width_all(2)
	_styles[id] = style
	return style

static func get_theme() -> Theme:
	if _theme != null: return _theme
	_theme = Theme.new()
	_theme.default_font = BODY
	_theme.default_font_size = 17
	_theme.set_color("font_color", "Label", TEXT)
	for type in ["Button", "OptionButton"]:
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			_theme.set_stylebox(state, type, box(state))
		_theme.set_color("font_color", type, TEXT)
		_theme.set_color("font_disabled_color", type, Color("788e98"))
	_theme.set_stylebox("panel", "PanelContainer", box())
	_theme.set_stylebox("panel", "Tree", box("shell"))
	_theme.set_stylebox("selected", "Tree", box("pressed"))
	_theme.set_stylebox("selected_focus", "Tree", box("pressed"))
	_theme.set_stylebox("focus", "Tree", box("focus"))
	_theme.set_color("font_color", "Tree", TEXT)
	_theme.set_color("font_selected_color", "Tree", Color.WHITE)
	_theme.set_constant("v_separation", "Tree", 8)
	_theme.set_constant("h_separation", "Tree", 5)
	return _theme

static func primary(button: Button) -> void:
	button.add_theme_stylebox_override("normal", box("primary"))
	for state in ["hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, box("primary_" + state))
	button.add_theme_stylebox_override("hover_pressed", box("primary_pressed"))
	button.add_theme_color_override("font_color", INK)
	for font_state in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(font_state, INK)
	button.add_theme_color_override("font_disabled_color", Color("4a4130"))
	button.add_theme_font_override("font", HEADING)

static func location_picture(location_id: String) -> Texture2D:
	if location_id == "satellite_crash": return _picture("mission_satellite_recovery")
	return _picture(_default_location_picture_id(location_id))

static func job_picture(job_id: String, location_id: String) -> Texture2D:
	# A shared/custom destination must not give another job the satellite art.
	return _picture("mission_satellite_recovery" if job_id == "satellite_recovery" else _default_location_picture_id(location_id))

static func _default_location_picture_id(location_id: String) -> String:
	var background_id := "mission_select_desert_outpost"
	if location_id == "homebase" or location_id == "polisa": background_id = "multiplayer_lobby_hangar"
	elif location_id == "distress_orbit": background_id = "loading_asteroid_flight"
	return background_id

static func _picture(background_id: String) -> Texture2D:
	if not _pictures.has(background_id): _pictures[background_id] = BACKGROUNDS.load_texture(background_id)
	return _pictures[background_id] as Texture2D
