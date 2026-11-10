extends RefCounted
## Visual vocabulary derived from management_concept_01; no gameplay state.
const INK:=Color("09232e")
const CARD:=Color("133640")
const EDGE:=Color("3c626b")
const CREAM:=Color("f1ebdc")
const MUTED:=Color("aac0c2")
const AMBER:=Color("efc376")
const CYAN:=Color("67c9c5")

static func box(color:Color=INK,inset:int=18)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=color;style.border_color=EDGE
	style.set_border_width_all(1);style.set_corner_radius_all(7);style.set_content_margin_all(inset)
	return style

static func panel(control:Control,inset:bool=false)->void:
	control.add_theme_stylebox_override("panel",box(CARD if inset else INK,14 if inset else 22))

static func label(control:Label,font_size:int=16,muted:bool=false)->void:
	control.add_theme_color_override("font_color",MUTED if muted else CREAM)
	control.add_theme_font_size_override("font_size",font_size)
	control.add_theme_constant_override("line_spacing",4)
	control.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

static func eyebrow(control:Label)->void:
	label(control,14);control.add_theme_color_override("font_color",AMBER)

static func button(control:Button,primary:bool=false)->void:
	var normal:=box(AMBER if primary else CARD,10)
	normal.border_color=AMBER if primary else EDGE
	control.add_theme_stylebox_override("normal",normal)
	var hover:=normal.duplicate();hover.bg_color=Color("f9d699") if primary else Color("204b55");hover.border_color=CYAN
	control.add_theme_stylebox_override("hover",hover)
	var pressed:=normal.duplicate();pressed.bg_color=Color("d5a75d") if primary else Color("0b2933")
	control.add_theme_stylebox_override("pressed",pressed)
	control.add_theme_stylebox_override("disabled",box(Color("16313a"),10))
	control.add_theme_color_override("font_color",INK if primary else CREAM)
	control.add_theme_color_override("font_hover_color",INK if primary else CREAM)
	control.add_theme_color_override("font_pressed_color",INK if primary else CREAM)
	control.add_theme_color_override("font_disabled_color",Color("81979b"))
	control.add_theme_font_size_override("font_size",16)
	control.custom_minimum_size.y=42

static func rule(host:Control)->void:
	var separator:=HSeparator.new();separator.add_theme_color_override("separator",EDGE);host.add_child(separator)
