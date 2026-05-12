extends SceneTree

const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const REPORT_PATH := "res://docs/reports/drop_light_layout_profiles_compact_resolution.md"
const TASK_PATH := "res://docs/tasks/TASK_334_drop_light_layout_profiles_compact_resolution.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_334 Drop Light Layout Profiles Compact Resolution ===")
	_test_profile_contract()
	_test_fullhd_layout_pixel_stability()
	_test_compact_layout_contract()
	await _test_homebase_compact_profile_application()
	await _test_fob_compact_profile_application()
	await _test_mission_compact_profile_application()
	_test_docs_and_report()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_profile_contract() -> void:
	var full_hd: String = String(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("PROFILE_FULL_HD"))
	var compact: String = String(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("PROFILE_COMPACT_720"))
	_assert(full_hd == "full_hd", "Contract exposes the unchanged full_hd profile id")
	_assert(compact == "compact_720", "Contract exposes a compact 720p profile id")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_default_profile_id") == full_hd, "Default profile remains full_hd")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_profile_for_viewport", Vector2i(1920, 1080)) == full_hd, "1920x1080 resolves to full_hd")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_profile_for_viewport", Vector2i(1280, 720)) == compact, "1280x720 resolves to compact_720")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_profile_viewport", full_hd) == Vector2i(1920, 1080), "full_hd viewport stays 1920x1080")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_profile_viewport", compact) == Vector2i(1280, 720), "compact_720 viewport is 1280x720")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_action_button_size", full_hd) == Vector2i(48, 48), "full_hd action buttons stay 48px square")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_action_button_size", compact) == Vector2i(40, 40), "compact action buttons stay large enough to hit")


func _test_fullhd_layout_pixel_stability() -> void:
	_assert(_layout_matches_expected(
		DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_fob_layout"),
		{
			"viewport": Rect2i(Vector2i.ZERO, Vector2i(1920, 1080)),
			"topbar": Rect2i(0, 0, 1920, 72),
			"unassigned_pool": Rect2i(24, 80, 240, 736),
			"fireteams": Rect2i(280, 80, 304, 736),
			"loadout": Rect2i(600, 80, 352, 736),
			"flightdeck": Rect2i(968, 80, 928, 736),
			"boarding_status": Rect2i(24, 832, 448, 224),
			"actions": Rect2i(488, 832, 464, 224),
			"flightdeck_stage": Rect2i(992, 128, 880, 560),
			"ship_slots": Rect2i(992, 704, 880, 240),
		}
	), "FOB full_hd layout is pixel-stable")
	_assert(_layout_matches_expected(
		DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_homebase_layout"),
		{
			"viewport": Rect2i(Vector2i.ZERO, Vector2i(1920, 1080)),
			"topbar": Rect2i(0, 0, 1920, 64),
			"mission_brief": Rect2i(24, 80, 1872, 112),
			"roster": Rect2i(24, 200, 520, 856),
			"transfer_team": Rect2i(560, 200, 424, 856),
			"flightdeck": Rect2i(1000, 200, 520, 856),
			"character_sheet": Rect2i(1536, 200, 360, 856),
		}
	), "Homebase full_hd layout is pixel-stable")
	_assert(_layout_matches_expected(
		DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_mission_hud_layout"),
		{
			"viewport": Rect2i(Vector2i.ZERO, Vector2i(1920, 1080)),
			"mission_identity": Rect2i(24, 24, 360, 80),
			"top_nav": Rect2i(720, 24, 480, 56),
			"fireteam_mini": Rect2i(24, 128, 280, 360),
			"bottom_dock": Rect2i(0, 800, 1920, 280),
			"command_matrix": Rect2i(24, 808, 304, 248),
			"selected_fireteam": Rect2i(344, 808, 1192, 248),
			"mission_control": Rect2i(1552, 808, 344, 248),
		}
	), "Mission HUD full_hd layout is pixel-stable")


func _test_compact_layout_contract() -> void:
	var compact: String = String(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("PROFILE_COMPACT_720"))
	for screen_id in [
		DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("SCREEN_HOMEBASE"),
		DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("SCREEN_FOB"),
		DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("SCREEN_MISSION_HUD"),
	]:
		var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_layout", String(screen_id), compact)
		_assert((layout.get("viewport") as Rect2i).size == Vector2i(1280, 720), "%s compact layout declares 1280x720 viewport" % screen_id)
		_assert(_all_rects_inside_profile(layout, compact), "%s compact layout stays inside the compact viewport" % screen_id)
		_assert(_all_rects_on_base_grid(layout), "%s compact layout stays on the base grid" % screen_id)
	_assert(_rect_minimum(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_fob_layout", compact), "actions", Vector2i(320, 160)), "FOB compact action area keeps sensible hit-room")
	_assert(_rect_minimum(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_homebase_layout", compact), "mission_brief", Vector2i(960, 72)), "Homebase compact mission brief keeps readable width")
	_assert(_rect_minimum(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_mission_hud_layout", compact), "command_matrix", Vector2i(248, 168)), "Mission compact command matrix keeps five-column room")


func _test_homebase_compact_profile_application() -> void:
	var compact: String = String(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("PROFILE_COMPACT_720"))
	var target_viewport := Vector2i(1280, 720)
	root.size = target_viewport
	var screen := HOMEBASE_TEST_SCENE.instantiate() as Control
	root.add_child(screen)
	await _wait_frames(4)
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_homebase_layout", compact)
	_assert(String(screen.get_meta("drop_light_layout_profile", "")) == compact, "Homebase root records compact profile")
	_assert(screen.custom_minimum_size == Vector2(1280.0, 720.0), "Homebase compact workspace uses 1280x720 minimum")
	_assert(_node_rect_matches_actual(screen.get_node("DropLightTopbar") as Control, layout.get("topbar")), "Homebase topbar applies compact rect")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/MissionPanel") as Control, layout.get("mission_brief")), "Homebase mission brief applies compact rect")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/ContentRow/RosterPanel") as Control, layout.get("roster")), "Homebase roster applies compact rect")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/ContentRow/InfoPanel") as Control, layout.get("character_sheet")), "Homebase character sheet applies compact rect")
	_assert(_button_reachable(screen, "Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton", target_viewport), "Homebase start mission button remains reachable at 1280x720")
	_assert(_button_reachable(screen, "Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamHeaderRow/ConfirmButton", target_viewport), "Homebase confirm button remains reachable at 1280x720")
	_assert(_scroll_container_is_usable(screen, "Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll"), "Homebase compact character sheet keeps internal scroll")
	screen.queue_free()
	await _wait_frames(2)


func _test_fob_compact_profile_application() -> void:
	var compact: String = String(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("PROFILE_COMPACT_720"))
	var target_viewport := Vector2i(1280, 720)
	root.size = target_viewport
	var screen := FOB_TEST_SCENE.instantiate() as Control
	screen.visible = true
	root.add_child(screen)
	await _wait_frames(4)
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_fob_layout", compact)
	_assert(String(screen.get_meta("drop_light_layout_profile", "")) == compact, "FOB root records compact profile")
	_assert(screen.custom_minimum_size == Vector2(1280.0, 720.0), "FOB compact workspace uses 1280x720 minimum")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/ContentRow/AvailablePanel") as Control, layout.get("unassigned_pool")), "FOB NPC pool applies compact rect")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/ContentRow/FireteamPanel") as Control, layout.get("fireteams")), "FOB fireteams apply compact rect")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/DropLightBottomRow/ActionsPanel") as Control, layout.get("actions")), "FOB actions panel applies compact rect")
	_assert(_button_reachable(screen, "Panel/Margin/VBox/DropLightBottomRow/ActionsPanel/Margin/VBox/ActionGrid/BoardButton", target_viewport), "FOB Board button remains reachable at 1280x720")
	_assert(_button_reachable(screen, "Panel/Margin/VBox/DropLightBottomRow/ActionsPanel/Margin/VBox/ActionGrid/SendButton", target_viewport), "FOB Send button remains reachable at 1280x720")
	_assert(_scroll_container_is_usable(screen, "Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutMemberScroll"), "FOB compact loadout keeps internal scroll")
	screen.queue_free()
	await _wait_frames(2)


func _test_mission_compact_profile_application() -> void:
	var compact: String = String(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("PROFILE_COMPACT_720"))
	var target_viewport := Vector2i(1280, 720)
	root.size = target_viewport
	var mission := MISSION_TEST_SCENE.instantiate()
	root.add_child(mission)
	await _wait_frames(8)
	var tactical_ui := mission.get_node_or_null("TacticalUI") as CanvasLayer
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_mission_hud_layout", compact)
	_assert(tactical_ui != null and String(tactical_ui.get_meta("drop_light_layout_profile", "")) == compact, "Mission HUD records compact profile")
	_assert(_node_rect_matches_actual(mission.get_node("TacticalUI/MissionIdentityPanel") as Control, layout.get("mission_identity")), "Mission identity applies compact rect")
	_assert(_node_rect_matches_actual(mission.get_node("TacticalUI/TopNavPanel") as Control, layout.get("top_nav")), "Mission nav applies compact rect")
	_assert(_node_rect_matches_actual(mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel") as Control, layout.get("command_matrix")), "Mission command matrix applies compact rect")
	_assert(_node_rect_matches_actual(mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel") as Control, layout.get("mission_control")), "Mission control applies compact rect")
	_assert(_button_reachable(mission, "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/MoveButton", target_viewport), "Mission Move button remains reachable at 1280x720")
	_assert(_button_reachable(mission, "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoCommandMatrixButton", target_viewport), "Mission GO button remains reachable at 1280x720")
	_assert(_button_reachable(mission, "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton", target_viewport), "Mission dropship button remains reachable at 1280x720")
	_assert(_scroll_container_is_usable(mission, "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll"), "Mission compact command matrix keeps internal scroll")
	mission.queue_free()
	await _wait_frames(2)


func _test_docs_and_report() -> void:
	_assert(FileAccess.file_exists(REPORT_PATH), "TASK_334 compact layout report exists")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_334 task document exists")
	var report: String = _read_text(REPORT_PATH)
	for required_text in ["Summary", "Automated Coverage", "Manual Sightcheck", "Risks"]:
		_assert(report.contains(required_text), "TASK_334 report covers %s" % required_text)
	var task_doc: String = _read_text(TASK_PATH)
	_assert(task_doc.contains("## Status: IMPLEMENTIERT"), "TASK_334 task status is updated")
	_assert(not task_doc.contains("- [ ]"), "TASK_334 task checklist has no unchecked acceptance or local check item")


func _layout_matches_expected(layout: Dictionary, expected: Dictionary) -> bool:
	for key in expected.keys():
		if not layout.has(key):
			return false
		if layout.get(key) != expected.get(key):
			return false
	return true


func _all_rects_inside_profile(layout: Dictionary, profile_id: String) -> bool:
	for value in layout.values():
		if typeof(value) != TYPE_RECT2I:
			continue
		if not bool(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("is_rect_inside_viewport", value, profile_id)):
			return false
	return true


func _all_rects_on_base_grid(layout: Dictionary) -> bool:
	for value in layout.values():
		if typeof(value) != TYPE_RECT2I:
			continue
		if not bool(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("is_rect_on_base_grid", value)):
			return false
	return true


func _rect_minimum(layout: Dictionary, key: String, minimum_size: Vector2i) -> bool:
	if not layout.has(key) or typeof(layout.get(key)) != TYPE_RECT2I:
		return false
	var rect: Rect2i = layout.get(key)
	return rect.size.x >= minimum_size.x and rect.size.y >= minimum_size.y


func _node_rect_matches_actual(control: Control, rect_variant: Variant) -> bool:
	if control == null or typeof(rect_variant) != TYPE_RECT2I:
		return false
	var rect: Rect2i = rect_variant
	var matches: bool = _approximately_equal(control.global_position.x, float(rect.position.x)) \
		and _approximately_equal(control.global_position.y, float(rect.position.y)) \
		and _approximately_equal(control.size.x, float(rect.size.x)) \
		and _approximately_equal(control.size.y, float(rect.size.y))
	if not matches:
		print("  RECT MISMATCH: %s actual=(%s,%s %sx%s) expected=(%s,%s %sx%s)" % [
			control.get_path(),
			control.global_position.x,
			control.global_position.y,
			control.size.x,
			control.size.y,
			rect.position.x,
			rect.position.y,
			rect.size.x,
			rect.size.y,
		])
	return matches


func _button_reachable(root_node: Node, path: String, viewport_size: Vector2i) -> bool:
	var button := root_node.get_node_or_null(path) as Button
	if button == null or not (button.visible and button.is_visible_in_tree()):
		return false
	if button.size.x < 32.0 or button.size.y < 32.0:
		return false
	return Rect2(Vector2.ZERO, Vector2(float(viewport_size.x), float(viewport_size.y))).grow(1.0).encloses(Rect2(button.global_position, button.size))


func _scroll_container_is_usable(root_node: Node, path: String) -> bool:
	var scroll := root_node.get_node_or_null(path) as ScrollContainer
	if scroll == null or not (scroll.visible and scroll.is_visible_in_tree()):
		return false
	return scroll.size.x > 0.0 and scroll.size.y > 0.0 and scroll.get_child_count() > 0


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _approximately_equal(a: float, b: float) -> bool:
	return absf(a - b) <= 0.5


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
