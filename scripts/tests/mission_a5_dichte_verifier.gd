extends SceneTree

const LAYOUT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# [Viewport, inset, band, card_width, portrait_height, team_height, transport_width, objective_width, identity_h, log_h, control_h, body, heading]
	var specs: Array = [
		[Vector2i(1280, 720), 8, 128, 280, 80, 128, 280, 392, 56, 104, 160, 14, 20],
		[Vector2i(1920, 1080), 8, 152, 312, 88, 136, 312, 440, 64, 120, 176, 16, 23],
		[Vector2i(3440, 1440), 12, 180, 376, 96, 144, 376, 504, 72, 152, 200, 18, 26],
	]
	for spec in specs:
		_check_table(spec)
	print("MISSION_A5_DICHTE: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check_table(spec: Array) -> void:
	var vp: Vector2i = spec[0]
	var layout: Dictionary = LAYOUT.get_mission_hud_layout(vp)
	var tag: String = str(vp)
	_expect(int(layout.action_inset) == int(spec[1]), "%s: inset" % tag)
	_expect((layout.bottom_dock as Rect2i).size.y == int(spec[2]), "%s: band_height" % tag)
	_expect(int(layout.card_width) == int(spec[3]), "%s: card_width" % tag)
	_expect(int(layout.portrait_height) == int(spec[4]), "%s: portrait_height" % tag)
	_expect((layout.selected_fireteam as Rect2i).size.y == int(spec[5]), "%s: team_height" % tag)
	_expect((layout.selected_fireteam as Rect2i).size.y == int(layout.portrait_height) + 48, "%s: team_height == portrait + 48" % tag)
	_expect((layout.mission_control as Rect2i).size.x == int(spec[6]), "%s: transport_width" % tag)
	_expect((layout.event_log as Rect2i).size.x == int(spec[6]), "%s: event_log width" % tag)
	_expect((layout.mission_identity as Rect2i).size.x == int(spec[7]), "%s: objective_width" % tag)
	_expect((layout.mission_identity as Rect2i).size.y == int(spec[8]), "%s: identity height" % tag)
	_expect((layout.event_log as Rect2i).size.y == int(spec[9]), "%s: event_log height" % tag)
	_expect((layout.mission_control as Rect2i).size.y == int(spec[10]), "%s: mission_control height" % tag)
	_expect(int(layout.body_font_size) == int(spec[11]), "%s: body_font_size" % tag)
	_expect(int(layout.heading_font_size) == int(spec[12]), "%s: heading_font_size" % tag)
	_expect((layout.event_log as Rect2i).end.y == (layout.bottom_dock as Rect2i).position.y - 12, "%s: event_log 12 above band" % tag)
	_expect(layout.has("team_parameters"), "%s: team_parameters present" % tag)
	if layout.has("team_parameters"):
		var params: Rect2i = layout.team_parameters
		var dock: Rect2i = layout.bottom_dock
		_expect(dock.encloses(params) and params.end.x <= vp.x, "%s: team_parameters inside bottom_dock" % tag)
		_expect(not params.intersects(layout.target_order), "%s: team_parameters misses target_order" % tag)
		_expect(params.size.x == 528, "%s: team_parameters width 528" % tag)


func _expect(value: bool, label: String) -> void:
	if value:
		_passed += 1
		print("PASS: " + label)
	else:
		_failed += 1
		push_error("FAIL: " + label)
