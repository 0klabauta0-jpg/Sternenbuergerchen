extends SceneTree

const LOBBY_SCENE := preload("res://scenes/ui/multiplayer_lobby.tscn")
const LOBBY_SCRIPT_PATH := "res://scripts/ui/multiplayer_lobby_screen.gd"
const PRODUCT_PLAYTEST_PATH := "res://scripts/tests/task_1119_connected_first_contact_three_peer_product_visual_playtest.gd"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1121 Connected First Contact Tactical World Readability ===")
	var lobby: Control = LOBBY_SCENE.instantiate()
	root.add_child(lobby)
	await process_frame
	await process_frame

	var panel: CanvasItem = lobby.get_node_or_null("Panel") as CanvasItem
	var background: CanvasItem = lobby.get_node_or_null("Background") as CanvasItem
	var shade: CanvasItem = lobby.get_node_or_null("BackgroundShade") as CanvasItem
	_assert(panel != null and background != null and shade != null, "Product lobby exposes panel, background and shade layers")
	_assert(panel.visible and background.visible and shade.visible, "Lobby chrome starts fully visible")

	lobby.call("_set_lobby_panel_visible", false)
	_assert(not panel.visible and not background.visible and not shade.visible, "Mission launch hides every full-screen lobby chrome layer")
	lobby.call("_set_lobby_panel_visible", true)
	_assert(panel.visible and background.visible and shade.visible, "Lobby return restores every chrome layer")

	var lobby_source := FileAccess.get_file_as_string(LOBBY_SCRIPT_PATH)
	_assert(lobby_source.contains("_background_rect.visible = visible") and lobby_source.contains("_background_shade.visible = visible"), "Lobby visibility contract explicitly owns background and shade")
	var playtest_source := FileAccess.get_file_as_string(PRODUCT_PLAYTEST_PATH)
	_assert(playtest_source.contains("(mission as Node2D).visible = is_target"), "Real-window capture couples world visibility to the requested peer")
	_assert(playtest_source.contains("primary_view.visible = is_target"), "Real-window capture couples Primary3D CanvasLayer visibility to the requested peer")
	_assert(not playtest_source.contains("(mission as Node2D).visible = index == 0"), "Real-window capture no longer mixes Host world with another peer HUD")

	lobby.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
