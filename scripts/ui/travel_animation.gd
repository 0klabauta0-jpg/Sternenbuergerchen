extends Control
## Snapshot-driven transition. Pausing freezes the animation along with travel.
const Regions=preload("res://scripts/core/regions.gd")
var travel: Dictionary={}
var paused:=false
var _label: Label
func _ready() -> void:
	custom_minimum_size=Vector2(660,330)
	clip_contents=true
	mouse_filter=Control.MOUSE_FILTER_STOP
	_label=Label.new();_label.position=Vector2(28,22);_label.add_theme_font_size_override("font_size",20);add_child(_label)
func present(state: Dictionary) -> void:
	travel=state.get("travel",{});paused=state.get("paused",false)
	visible=travel.get("active",false)
	if not visible:return
	var dest:=str(travel.get("to","orbit"))
	_label.text=("Aufstieg in den Orbit" if dest=="orbit" else "Anflug · "+str(Regions.LABELS.get(dest,dest)))+(" · Pause" if paused else "")
	queue_redraw()
func _draw() -> void:
	draw_style_box(_frame(),Rect2(Vector2.ZERO,size))
	var progress:=clampf(1.0-float(travel.get("remaining",0))/maxf(0.01,float(travel.get("total",1))),0,1)
	var ascend: bool=travel.get("to","")=="orbit"
	for i in range(90):
		var star:=Vector2(fposmod(i*173.7-progress*100,650)+5,fposmod(i*79.3,220)+60)
		draw_circle(star,1 if i%4 else 1.6,Color(0.65,0.79,0.86,0.3+0.15*(i%4)))
	var planet:=Vector2(130,330+progress*130) if ascend else Vector2(560,230)
	var radius:=150.0 if ascend else lerpf(50,140,progress)
	draw_circle(planet,radius+7,Color(0.37,0.61,0.69,0.22))
	draw_circle(planet,radius,Color("855848"))
	draw_circle(planet+Vector2(radius*0.35,0),radius*0.8,Color("4d3940"))
	draw_arc(planet,radius,-PI,-PI/4,50,Color("d7a274"),3,true)
	var ship:=Vector2(170,240).lerp(Vector2(435,135) if ascend else Vector2(430,210),smoothstep(0,1,progress))
	var hull:=PackedVector2Array([ship+Vector2(28,0),ship+Vector2(8,-10),ship+Vector2(-14,-10),ship+Vector2(-22,-24),ship+Vector2(-30,-24),ship+Vector2(-25,-6),ship+Vector2(-18,0),ship+Vector2(-25,6),ship+Vector2(-30,24),ship+Vector2(-22,24),ship+Vector2(-14,10),ship+Vector2(8,10)])
	draw_colored_polygon(hull,Color("dbe4df"))
	draw_line(ship-Vector2(23,17),ship-Vector2(60,17),Color("77ccdf"),3,true)
	draw_line(ship-Vector2(23,-17),ship-Vector2(60,-17),Color("77ccdf"),3,true)
	draw_circle(ship+Vector2(6,0),4,Color("688994"))
	draw_string(ThemeDB.fallback_font,Vector2(28,300),"ORBIT ERREICHEN" if ascend else "PLANETARES ZIEL · " + str(Regions.LABELS.get(travel.get("to",""),"")),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("b3c5cc"))
func _frame() -> StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color("0a121e");style.border_color=Color("526875");style.set_border_width_all(1);return style
