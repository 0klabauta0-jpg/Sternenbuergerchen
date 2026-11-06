extends SceneTree
## UI presentation fixture, not a physical playthrough or timing benchmark.
const SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const HUD: GDScript = preload("res://scripts/ui/mission_a5_hud_layout.gd")
const ICONS: GDScript = preload("res://scripts/ui/native_ui_icons.gd")
const THEME: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")
const LAYOUT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const BASE := "TacticalUI/BottomDock/BottomMargin/BottomRow/"
const GRID := BASE + "CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/"
const NEW_IDS := {"TargetButton": "order_target", "ClearTargetButton": "order_clear", "DeleteOrderButton": "order_delete", "SortCommandMatrixButton": "order_sort", "GoCommandMatrixButton": "order_go"}
var _passed := 0
var _failed := 0


func _initialize() -> void:
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_FULLSCREEN
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	call_deferred("_run")


func _run() -> void:
	var old_icons: Dictionary = {}
	for id in ["move", "take", "defend", "flank", "dropship", "loadout"]:
		old_icons[id] = ICONS.get_icon(id)
	for name in NEW_IDS:
		var icon: Texture2D = ICONS.get_icon(NEW_IDS[name])
		_check(icon != null and icon.get_width() >= 32 and icon.get_height() >= 32 and icon.get_width() <= 256 and icon.get_height() <= 256, "%s has a real bounded glyph texture" % name)
		_check(icon != null and icon == ICONS.get_icon(NEW_IDS[name]), "%s reuses its original cached glyph" % name)
	_check(ICONS.get_icon("unrecognized_r3_icon") == null, "Unknown IDs keep the existing null contract")
	for id in old_icons:
		_check(old_icons[id] != null and old_icons[id] == ICONS.get_icon(id), "Existing %s identity remains unchanged" % id)
	var scene := SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(14):
		await process_frame
	var owner: Node = scene.get_node("TacticalController")
	var simulation: Node = scene.get_node("SimulationRoot")
	owner.set_process(false)
	var identities: Dictionary = {}
	var callbacks: Dictionary = {}
	for name in Array(HUD.FIRST) + Array(HUD.SECOND):
		var button := scene.get_node(GRID + name) as Button
		identities[name] = button.get_instance_id()
		callbacks[name] = button.get_signal_connection_list("pressed")
	for viewport_size in [Vector2i(3440, 1440), Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.content_scale_size = viewport_size
		root.size = viewport_size
		await process_frame
		await process_frame
		var before := _owner_signature(owner, simulation)
		owner.call("_apply_native_a5_hud_layout")
		print("R3_VIEWPORT requested=", viewport_size, " actual=", owner.get_viewport().get_visible_rect().size)
		_check(Vector2i(owner.get_viewport().get_visible_rect().size) == viewport_size, "%s verifies the actual logical viewport" % viewport_size)
		# Reproduce an existing generic skin refresh without changing geometry.
		for name in Array(HUD.FIRST) + Array(HUD.SECOND):
			THEME.style_action_tile(scene.get_node(GRID + name) as Button)
		owner.call("_apply_native_a5_hud_layout")
		var metrics: Dictionary = LAYOUT.get_mission_hud_layout(viewport_size)
		for name in Array(HUD.FIRST) + Array(HUD.SECOND):
			var button := scene.get_node(GRID + name) as Button
			print("R3_ACTION_RECT ", viewport_size, " ", name, " size=", button.size, " min=", button.get_combined_minimum_size(), " custom=", button.custom_minimum_size, " edge=", metrics.action_edge)
			_check(button.visible and button.icon != null, "%s %s has its visible final icon" % [viewport_size, name])
			_check(button.get_instance_id() == identities[name] and button.get_signal_connection_list("pressed") == callbacks[name], "%s %s preserves original node and callback" % [viewport_size, name])
			_check(button.size.x <= float(metrics.action_edge) + 0.5 and button.size.y <= float(metrics.action_edge) + 0.5, "%s %s stays inside its square slot" % [viewport_size, name])
			if NEW_IDS.has(name):
				_check(button.icon == ICONS.get_icon(NEW_IDS[name]), "%s %s uses the explicit native glyph owner" % [viewport_size, name])
		var team := scene.get_node(BASE + "FireteamPanel") as Control
		var title := team.get_node("A5TeamIdentity") as Label
		_check(bool(team.get_meta("native_a5_quiet_frame", false)), "%s uses the quiet native frame without a short legacy header divider" % viewport_size)
		_check(title.visible and not title.text.is_empty(), "%s retains the current selected-team identity" % viewport_size)
		_check(_owner_signature(owner, simulation) == before, "%s pure icon/frame formatting leaves real owners unchanged" % viewport_size)
		if DisplayServer.get_name() != "headless":
			_check(root.mode == Window.MODE_FULLSCREEN and DisplayServer.window_get_size() == DisplayServer.screen_get_size(), "Native fixture remains actual fullscreen")
			await RenderingServer.frame_post_draw
			for argument in OS.get_cmdline_user_args():
				if argument.begins_with("--evidence-output="):
					var path := argument.trim_prefix("--evidence-output=").get_basename() + "_%dx%d.png" % [viewport_size.x, viewport_size.y]
					_check(not FileAccess.file_exists(path), "Native fixture PNG target is new")
					_check(root.get_texture().get_image().save_png(path) == OK, "Native fixture screenshot saved")
	scene.queue_free()
	for _frame in range(2):
		await process_frame
	print("REFERENCE_POLISH_R3_MISSION_UI: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("REFERENCE_POLISH_R3_MISSION_UI_VERIFY_PASS")
	quit(1 if _failed else 0)


func _owner_signature(owner: Node, simulation: Node) -> String:
	return JSON.stringify({"commands": simulation.get("command_queue"), "effects": simulation.get("effects_queue"), "plans": owner.call("get_order_plans_snapshot"), "areas": owner.call("get_area_orders_snapshot"), "selected": owner.call("get_selected_fireteam_ids"), "roe": simulation.call("get_authoritative_fire_rule_snapshot")})


func _check(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", message)
	else:
		_failed += 1
		print("FAIL: ", message)
