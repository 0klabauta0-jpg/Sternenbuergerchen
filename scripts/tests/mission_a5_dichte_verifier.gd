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
	for spec in specs:
		await _check_live(spec[0])
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


const BASE: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/"
const TEAM: String = BASE + "FireteamPanel"
const STANCE: String = TEAM + "/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/TacticalStancePanel"


func _near(a: Rect2, b: Rect2i, label: String) -> void:
	var r := Rect2(b)
	_expect(absf(a.position.x - r.position.x) <= 1.0 and absf(a.position.y - r.position.y) <= 1.0 and absf(a.size.x - r.size.x) <= 1.0 and absf(a.size.y - r.size.y) <= 1.0, "%s (ist %s, soll %s)" % [label, str(a), str(r)])


func _check_live(vp: Vector2i) -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = vp
	var layout: Dictionary = LAYOUT.get_mission_hud_layout(vp)
	var tag: String = str(vp)
	var mission: Node = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	var setup: Node = mission.get_node("MissionSetup")
	setup.set("defer_friendly_runtime_activation", false)
	setup.set("selected_team_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]))
	setup.set("selected_team_fireteam_ids", PackedStringArray(["ft1", "ft1", "ft2", "ft3"]))
	root.add_child(mission)
	for _i in range(24):
		await process_frame
	var controller: Node = mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["ft1"]), false)
	controller.call("_update_ui")
	for _i in range(12):
		await process_frame
	var dock := mission.get_node("TacticalUI/BottomDock") as Control
	var target := mission.get_node("TacticalUI/A5TargetOrderPanel") as Control
	_near((mission.get_node(TEAM) as Control).get_global_rect(), layout.selected_fireteam, "%s: FireteamPanel == selected_fireteam" % tag)
	var params := Rect2(layout.team_parameters).grow(1.0)
	for node_path in [STANCE, TEAM + "/A5FireRuleSelector", TEAM + "/A5TeamBoard", TEAM + "/A5BoardStatus", TEAM + "/A5TeamSummary"]:
		var node := mission.get_node_or_null(node_path) as Control
		_expect(node != null, "%s: %s vorhanden" % [tag, node_path.get_file()])
		if node == null:
			continue
		var rect: Rect2 = node.get_global_rect()
		_expect(params.encloses(rect), "%s: %s liegt in team_parameters (%s)" % [tag, node_path.get_file(), str(rect)])
		_expect(dock.get_global_rect().grow(1.0).encloses(rect), "%s: %s liegt im BottomDock" % [tag, node_path.get_file()])
		_expect(not rect.intersects(target.get_global_rect()), "%s: %s schneidet A5TargetOrderPanel nicht" % [tag, node_path.get_file()])
	var stance_rect: Rect2 = (mission.get_node(STANCE) as Control).get_global_rect()
	var selector_rect: Rect2 = (mission.get_node(TEAM + "/A5FireRuleSelector") as Control).get_global_rect()
	var heading_rect: Rect2 = (mission.get_node(TEAM + "/A5FireRuleHeading") as Control).get_global_rect()
	_expect(not stance_rect.intersects(selector_rect) and not stance_rect.intersects(heading_rect), "%s: Haltungsrahmen %s schneidet Feuerregel-Zeile nicht (%s, %s)" % [tag, str(stance_rect), str(heading_rect), str(selector_rect)])
	_expect(dock.get_global_rect().grow(1.0).encloses(selector_rect), "%s: A5FireRuleSelector liegt im BottomDock" % tag)
	var portraits := mission.get_node(TEAM + "/A5TeamPortraits") as Control
	_expect(portraits.get_child_count() > 0, "%s: Portraits vorhanden" % tag)
	for child in portraits.get_children():
		_expect(absf((child as Control).size.y - float(layout.portrait_height)) <= 1.0, "%s: Portrait Hoehe %s == %d" % [tag, str((child as Control).size.y), int(layout.portrait_height)])
	var event_log := mission.get_node("TacticalUI/TacticalEventLogPanel") as Control
	var identity := mission.get_node("TacticalUI/MissionIdentityPanel") as Control
	var ship := mission.get_node("TacticalUI/MissionDropshipPanel") as Control
	_near(event_log.get_global_rect(), layout.event_log, "%s: TacticalEventLogPanel == event_log" % tag)
	_near(identity.get_global_rect(), layout.mission_identity, "%s: MissionIdentityPanel == mission_identity" % tag)
	var ship_rect: Rect2 = ship.get_global_rect()
	_expect(absf(ship_rect.size.x - float((layout.mission_control as Rect2i).size.x)) <= 1.0, "%s: Dropship Breite %s" % [tag, str(ship_rect.size.x)])
	if vp == Vector2i(1920, 1080):
		_expect(ship_rect.size.y <= 196.0, "%s: Dropship Hoehe %s <= 196" % [tag, str(ship_rect.size.y)])
	_expect(ship_rect.end.x <= float(vp.x - _edge(vp)) + 1.0, "%s: Dropship rechter Rand %s" % [tag, str(ship_rect.end.x)])
	_expect(not ship_rect.intersects(event_log.get_global_rect()), "%s: Dropship schneidet Protokoll nicht" % tag)
	_expect(not ship_rect.intersects(identity.get_global_rect()), "%s: Dropship schneidet Identity nicht" % tag)
	var dial := mission.get_node("TacticalUI/MissionDropshipPanel/CompactCard/Contents/ApproachRow/ApproachDial") as Control
	_expect(dial.custom_minimum_size == Vector2(96, 56), "%s: ApproachDial 96x56" % tag)
	mission.queue_free()
	for _i in range(4):
		await process_frame


func _edge(vp: Vector2i) -> int:
	return 24 if vp.y >= 1260 else 16


func _expect(value: bool, label: String) -> void:
	if value:
		_passed += 1
		print("PASS: " + label)
	else:
		_failed += 1
		push_error("FAIL: " + label)
