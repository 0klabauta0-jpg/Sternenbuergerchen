extends SceneTree
## Real menu controls, isolated scene bookmark and live physics; no OS input.
var passed := 0
var failed := 0
const SLOT := "user://game_review_20261112_scene_bookmark.cfg"

class TickProbe extends Node:
	var ticks := 0
	func _physics_process(_delta: float) -> void:
		ticks += 1

class BookmarkMenu extends "res://scripts/ui/main_menu_screen.gd":
	func _ready() -> void:
		pass

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		printerr("FAIL: ", label)

func run() -> void:
	var shell: Node = root.get_node("GlobalEscapeMenu")
	shell.call("set_test_mode", true)
	shell.call("set_save_path_for_tests", SLOT)
	var scene := Node.new()
	scene.scene_file_path = "res://scenes/meta/meta_layer_test.tscn"
	root.add_child(scene)
	current_scene = scene
	var probe := TickProbe.new()
	scene.add_child(probe)
	shell.call("open_menu")
	var save: Button = shell.get("_save_button")
	var load_button: Button = shell.get("_load_button")
	check(save.text == "Szenenstart merken", "ESC does not advertise a state save")
	check(save.tooltip_text.contains("Fortschritt"), "ESC explains that progress is not saved")
	check(load_button.text == "Gemerkte Szene neu starten", "ESC explicitly announces a restart")
	check(not paused, "Opening ESC keeps real-time simulation unpaused")
	var before := probe.ticks
	for index in 4:
		await physics_frame
	check(probe.ticks > before, "Physics continues while ESC is open")
	shell.call("_on_save_pressed")
	var slot: Dictionary = shell.call("get_save_slot_snapshot")
	check(slot.get("save_kind") == "scene_path_v1", "Bookmark format remains compatible")
	check(slot.get("scene_path") == scene.scene_file_path, "Bookmark records the actual scene path")
	check(String(shell.get("_status_label").text).contains("Fortschritt"), "Save feedback discloses progress limitation")
	var result: Dictionary = shell.call("load_mission_slot", false)
	check(bool(result.get("ok", false)) and current_scene == scene, "Read-only load validation does not replace the current scene")
	shell.call("open_settings")
	check(not paused and bool(shell.call("is_settings_visible")), "Settings also preserve the no-pause contract")
	shell.call("close_menu")
	check(not paused, "Closing menu does not change simulation pause state")
	# Build only the real menu's slot row; avoid _ready and player profile writes.
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	menu.set_script(BookmarkMenu)
	root.add_child(menu)
	menu.call("_ensure_mission_save_load_buttons")
	var menu_save: Button = menu.get("_mission_save_button")
	var menu_load: Button = menu.get("_mission_load_button")
	check(menu_save.text == save.text and menu_load.text == load_button.text, "Main menu and ESC use consistent scene-bookmark wording")
	current_scene = menu
	menu.call("_refresh_mission_save_load_buttons")
	check(menu_save.disabled, "Main menu cannot bookmark itself as an active mission")
	current_scene = scene
	menu.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SLOT))
	scene.queue_free()
	await process_frame
	print("GAME_REVIEW_SHELL passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
