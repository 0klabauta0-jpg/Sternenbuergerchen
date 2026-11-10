extends SceneTree
## Real menu/confirmation/scene lifecycle. Run only with a fresh private
## APPDATA path containing campaign_replace; no personal checkpoint is touched.

const MENU_PATH := "res://scenes/ui/main_menu.tscn"
const FLOW_PATH := "res://scenes/meta/meta_layer_test.tscn"
const STORE: GDScript = preload("res://scripts/meta/campaign_checkpoint_store.gd")
# SSR/SSAO use five mip levels of a half-size buffer: 32 -> 16 -> ... -> 1.
const MIN_SCREEN_EFFECT_AXIS := 32

var _passed := 0
var _failed := 0
var _stage := "startup"
var _pre_draw_count := 0
var _active_camera_samples := 0
var _screen_effect_samples := 0
var _unsafe_targets: Dictionary = {}
var _reported_targets: Dictionary = {}

func _init() -> void:
	RenderingServer.frame_pre_draw.connect(_on_frame_pre_draw)
	call_deferred("_run")

func _run() -> void:
	print("CAMPAIGN_REPLACE_BEGIN display=", DisplayServer.get_name(), " user_data=", OS.get_user_data_dir())
	var profile_path: String = OS.get_environment("APPDATA").replace("\\", "/").to_lower()
	if not _check(profile_path.contains("campaign_replace") and OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(profile_path + "/"), "Explicit private campaign_replace APPDATA owns all save writes"):
		await _finish()
		return
	if not _check(not FileAccess.file_exists(STORE.DEFAULT_PATH), "Fresh private profile starts without a campaign checkpoint"):
		await _finish()
		return
	root.size = Vector2i(1280, 720)
	if not await _open_menu("new_without_checkpoint"):
		await _finish()
		return
	var menu: Node = current_scene
	if not _press_campaign(menu):
		await _finish()
		return
	var start_dialog: ConfirmationDialog = menu.get("_campaign_dialog")
	_check(bool(menu.get("_campaign_continue_button").disabled), "First real campaign dialog disables Continue without a checkpoint")
	start_dialog.get_ok_button().pressed.emit()
	if not await _wait_scene(FLOW_PATH, "First real New Campaign OK reaches the campaign scene"):
		await _finish()
		return
	var flow: Node = current_scene
	await _settle_and_check_base(flow, "first_new")
	var screen: Control = flow.get_node("HomebaseScreen")
	var default_loadout: String = String(Dictionary(screen.get("_member_loadout_by_unit_id")).get("campaign_leader", {}).get("weapon_2", ""))
	var sentinel_loadout: String = "none" if default_loadout != "none" else "medictool"
	var changed: Dictionary = screen.call("request_operation", "loadout", {"unit_id": "campaign_leader", "key": "weapon_2", "value": sentinel_loadout})
	_check(bool(changed.get("ok", false)), "Existing equipment owner creates a distinct valid checkpoint fixture")
	var saved: Dictionary = flow.get("_campaign_start").call("save_home_checkpoint", flow, flow.get("_singleplayer_runtime"))
	if not _check(bool(saved.get("ok", false)) and bool(STORE.load_checkpoint().get("ok", false)), "First campaign writes a valid home checkpoint through its real owner"):
		print("CAMPAIGN_REPLACE_SAVE:", saved)
		await _finish()
		return
	var original_bytes: PackedByteArray = FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH)
	_check(not original_bytes.is_empty(), "Existing checkpoint fixture has concrete bytes to preserve")
	if not await _open_menu("replace_cancel"):
		await _finish()
		return
	menu = current_scene
	if not _press_campaign(menu):
		await _finish()
		return
	_check(not bool(menu.get("_campaign_continue_button").disabled), "Valid existing checkpoint enables the real Continue button")
	start_dialog = menu.get("_campaign_dialog")
	start_dialog.get_ok_button().pressed.emit()
	var replace_dialog: ConfirmationDialog = menu.get("_campaign_replace_dialog")
	_check(replace_dialog.visible and current_scene == menu, "Real New Campaign OK opens replacement confirmation without changing scene")
	replace_dialog.get_cancel_button().pressed.emit()
	await _frames(3)
	_check(not replace_dialog.visible and current_scene == menu, "Actual Cancel button closes replacement and retains the menu")
	_check(FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == original_bytes, "Cancel preserves the existing valid checkpoint byte for byte")
	if not _press_campaign(menu):
		await _finish()
		return
	start_dialog.get_ok_button().pressed.emit()
	_check(replace_dialog.visible, "New Campaign opens replacement confirmation again after Cancel")
	_stage = "replace_confirm_first_layout"
	replace_dialog.get_ok_button().pressed.emit()
	if not await _wait_scene(FLOW_PATH, "Actual Replace OK completes the real menu-to-campaign scene switch"):
		await _finish()
		return
	flow = current_scene
	await _settle_and_check_base(flow, "replaced")
	screen = flow.get_node("HomebaseScreen")
	var replaced_loadout: String = String(Dictionary(screen.get("_member_loadout_by_unit_id")).get("campaign_leader", {}).get("weapon_2", ""))
	_check(replaced_loadout == default_loadout and replaced_loadout != sentinel_loadout, "Confirmed replacement creates the fresh roster rather than restoring the old equipment")
	saved = flow.get("_campaign_start").call("save_home_checkpoint", flow, flow.get("_singleplayer_runtime"))
	_check(bool(saved.get("ok", false)) and bool(STORE.load_checkpoint().get("ok", false)), "Replacement allows a valid new grounded home checkpoint")
	_check(FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) != original_bytes, "Confirmed replacement replaces the distinct old checkpoint")
	await _exercise_view_switches(flow)
	if not await _open_menu("continue_replaced"):
		await _finish()
		return
	menu = current_scene
	if not _press_campaign(menu):
		await _finish()
		return
	var continue_button: Button = menu.get("_campaign_continue_button")
	_check(not continue_button.disabled, "The replacement checkpoint remains available to real Continue")
	_stage = "continue_first_layout"
	continue_button.pressed.emit()
	if await _wait_scene(FLOW_PATH, "Actual Continue button restores the replacement campaign"):
		flow = current_scene
		_check(String(flow.get_meta("player_roster_source", "")) == "campaign_checkpoint", "Continue uses checkpoint mode rather than a silent new campaign")
		await _settle_and_check_base(flow, "continued")
	await _finish()

func _open_menu(stage_name: String) -> bool:
	_stage = stage_name
	if not _check(change_scene_to_file(MENU_PATH) == OK, "Real SceneTree routes to the main menu for " + stage_name):
		return false
	return await _wait_scene(MENU_PATH, "Main menu is SceneTree.current_scene for " + stage_name)

func _press_campaign(menu: Node) -> bool:
	var button: Button = menu.find_child("CampaignButton", true, false)
	if not _check(button != null and button.is_visible_in_tree() and not button.disabled, "Actual current-scene Campaign button is usable"):
		return false
	button.pressed.emit()
	var dialog: ConfirmationDialog = menu.get("_campaign_dialog")
	return _check(dialog.visible and not dialog.get_ok_button().disabled, "Actual Campaign button presents the New Campaign dialog")

func _wait_scene(path: String, label: String) -> bool:
	var deadline: int = Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:
		if current_scene != null and current_scene.scene_file_path == path and current_scene.is_node_ready():
			return _check(true, label)
		await process_frame
	return _check(false, "TIMEOUT " + label)

func _settle_and_check_base(flow: Node, stage_name: String) -> void:
	_stage = stage_name + "_settling"
	var presenter: Node=flow.get_node("HomebaseScreen").get("_operations_presenter")
	var base_button: Button=presenter.find_child("Navigate_base",true,false)
	base_button.pressed.emit()
	await _frames(12)
	_check(flow == current_scene and bool(flow.call("is_campaign_start")), stage_name + " is the actual live campaign scene")
	var units: Array = flow.get("_all_team_units")
	var runtime: Node = flow.get("_singleplayer_runtime")
	var people: Array = runtime.call("get_base_personnel_runtime").call("get_snapshot").get("units", [])
	_check(units.size() == 2 and people.size() == 2 and people.all(func(person: Dictionary): return String(person.unit_id) in ["campaign_leader", "campaign_pilot"]), stage_name + " contains exactly the original two authoritative campaign people")
	_check(String(Dictionary(runtime.call("get_snapshot").get("space_travel", {})).get("phase", "")) == "grounded", stage_name + " begins at the grounded campaign base")
	_check_base_target_sizes(flow, stage_name)

func _exercise_view_switches(flow: Node) -> void:
	var presenter: Control = flow.get_node("HomebaseScreen").get("_operations_presenter")
	for mode: String in ["base", "squad", "mission", "personnel", "base", "squad"]:
		_stage = "switch_" + mode
		var nav: Button = presenter.find_child("Navigate_" + mode, true, false)
		if not _check(nav != null and nav.is_visible_in_tree() and not nav.disabled, "Actual navigation button is usable for " + mode):
			continue
		nav.pressed.emit()
		await _frames(12)
		_check(String(presenter.get("_mode")) == mode, "Actual navigation selects " + mode)
		if mode == "base" or (mode in ["squad","mission"] and presenter.get("_base").is_visible_in_tree()):
			_check_base_target_sizes(flow, "settled_" + mode)

func _check_base_target_sizes(flow: Node, label: String) -> void:
	var base: Control = flow.get_node("HomebaseScreen").get("_operations_presenter").get("_base")
	var host: SubViewportContainer = base.get("_host")
	var outer: SubViewport = base.get("_viewport")
	var view: CanvasLayer = base.get("_view")
	var inner: SubViewport = view.get_node("ViewportContainer/SubViewport") if view != null else null
	print("CAMPAIGN_REPLACE_BASE_TARGET ", label, " host=", host.size, " outer=", outer.size, " visible=", outer.get_visible_rect().size, " inner=", inner.size if inner != null else Vector2i.ZERO, " mode=", inner.render_target_update_mode if inner != null else -1)
	_check(base.is_visible_in_tree() and host.size.x >= MIN_SCREEN_EFFECT_AXIS and host.size.y >= MIN_SCREEN_EFFECT_AXIS, label + " has a real visible base or pad-preview area")
	_check(inner != null and inner.get_camera_3d() != null, label + " retains the real terrain camera")
	if inner == null:
		return
	var expected: Vector2i = Vector2i(outer.get_visible_rect().size.round())
	_check(inner.size.x >= MIN_SCREEN_EFFECT_AXIS and inner.size.y >= MIN_SCREEN_EFFECT_AXIS, label + " never settles on a tiny 16x16 render target")
	_check(absi(inner.size.x - expected.x) <= 1 and absi(inner.size.y - expected.y) <= 1, label + " inner terrain render target follows the settled outer visible area")

func _frames(count: int) -> void:
	for frame: int in count:
		await process_frame
		# Dummy/headless renderers may omit frame_pre_draw; retain state evidence.
		_sample_render_targets("process_frame")

func _on_frame_pre_draw() -> void:
	_pre_draw_count += 1
	_sample_render_targets("frame_pre_draw")

func _sample_render_targets(source: String) -> void:
	for node: Node in root.find_children("*", "SubViewport", true, false):
		var viewport: SubViewport = node as SubViewport
		var camera: Camera3D = viewport.get_camera_3d()
		if camera == null or viewport.disable_3d or viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED:
			continue
		_active_camera_samples += 1
		var environment: Environment = camera.environment
		if environment == null and viewport.world_3d != null:
			environment = viewport.world_3d.environment
		# The dummy renderer does not register World3D.environment. Read the
		# authored resource as well; do not change or disable its screen effects.
		if environment == null:
			for environment_node: Node in viewport.find_children("*", "WorldEnvironment", true, false):
				environment = (environment_node as WorldEnvironment).environment
				if environment != null:
					break
		var effects: bool = environment != null and (environment.ssao_enabled or environment.ssr_enabled)
		if effects:
			_screen_effect_samples += 1
		var unsafe: bool = effects and (viewport.size.x < MIN_SCREEN_EFFECT_AXIS or viewport.size.y < MIN_SCREEN_EFFECT_AXIS)
		var row: Dictionary = {"stage": _stage, "source": source, "path": String(viewport.get_path()), "size": viewport.size, "update_mode": viewport.render_target_update_mode, "ssao": environment.ssao_enabled if environment != null else false, "ssr": environment.ssr_enabled if environment != null else false}
		var signature: String = str([_stage, row.path, row.size, row.update_mode, row.ssao, row.ssr])
		if not _reported_targets.has(signature):
			_reported_targets[signature] = true
			print("CAMPAIGN_REPLACE_RENDER_TARGET:", var_to_str(row))
		if unsafe and not _unsafe_targets.has(signature):
			_unsafe_targets[signature] = row
			_check(false, "Active SSR/SSAO render target requires both axes >=32 before drawing: " + signature)

func _check(value: bool, label: String) -> bool:
	if value:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		printerr("FAIL: ", label)
	return value

func _finish() -> void:
	_check(_active_camera_samples > 0, "Render sampling exercised actual active 3D camera targets")
	_check(_screen_effect_samples > 0, "Render sampling retained the shipped SSR/SSAO configuration")
	if DisplayServer.get_name() != "headless":
		_check(_pre_draw_count > 0, "Native rendering was sampled at RenderingServer.frame_pre_draw")
	print("CAMPAIGN_REPLACE_RENDER_SAMPLES pre_draw=", _pre_draw_count, " active_camera=", _active_camera_samples, " screen_effects=", _screen_effect_samples, " unsafe=", _unsafe_targets.size())
	RenderingServer.frame_pre_draw.disconnect(_on_frame_pre_draw)
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	await process_frame
	print("CAMPAIGN_REPLACE_RESULTS passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
