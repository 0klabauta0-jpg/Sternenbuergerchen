extends Control
## Read-only schematic space background behind the existing selected ship visual.
var _context: Dictionary = {}

func set_context(context: Dictionary) -> void:
	if context == _context:
		return
	_context = context.duplicate(true)
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("07131f"))
	if String(_context.get("kind", "")) != "space":
		return
	for i in range(74):
		var point := Vector2(fposmod(float(i * 137 + 23), 881.0) / 881.0 * size.x, fposmod(float(i * 229 + 71), 673.0) / 673.0 * size.y)
		draw_circle(point, 0.8 if i % 4 else 1.5, Color(0.65, 0.82, 0.91, 0.25 if i % 3 else 0.65))
	var phase: String = String(_context.get("phase", ""))
	var orbit: String = String(_context.get("orbit_id", ""))
	if orbit == "moon_orbit" or phase in ["quantum", "stopped"]:
		var center := Vector2(size.x * 0.13, size.y * 0.72)
		var radius := minf(size.x, size.y) * 0.22
		draw_circle(center, radius, Color("778c9a"))
		draw_circle(center + Vector2(-0.25, -0.3) * radius, radius * 0.2, Color("556e7c"))
		draw_circle(center + Vector2(0.35, 0.15) * radius, radius * 0.13, Color("617a88"))
		draw_arc(center, radius * 1.25, PI, TAU, 40, Color(0.48, 0.81, 0.87, 0.35), 1, true)
	if orbit == "planet_orbit" or phase in ["quantum", "stopped", "approach"]:
		var center := Vector2(size.x * 0.90, size.y * 0.78)
		var radius := minf(size.x, size.y) * 0.33
		draw_circle(center, radius * 1.08, Color(0.15, 0.55, 0.72, 0.15))
		draw_circle(center, radius, Color("2e7785"))
		draw_arc(center + Vector2(-0.1, -0.2) * radius, radius * 0.65, 1.0, 3.9, 32, Color("729887"), maxf(radius * 0.24, 1), true)
	if phase == "quantum":
		var direction := -1.0 if String(_context.get("target_orbit_id", "")) == "moon_orbit" else 1.0
		for i in range(7):
			var point := Vector2(size.x * (0.24 + float(i % 3) * 0.13), size.y * (0.20 + float(i) * 0.09))
			draw_line(point, point + Vector2(-direction * 34, direction * 5), Color(0.35, 0.85, 1.0, 0.35), 2, true)
