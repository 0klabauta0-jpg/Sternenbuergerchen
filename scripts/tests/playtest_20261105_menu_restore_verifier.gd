extends SceneTree
const MENU = preload("res://scenes/ui/main_menu.tscn")
const CATALOG = preload("res://scripts/assets/background_image_catalog.gd")
const IMAGE := "res://Assets/curated/main_menu/sternenbuerger_main_menu_bg.jpeg"
const IMAGE_SHA := "8702c2e3989b8e537656bf3824c734e2474ba797f7744b574aad8390299a5563"
var passed := 0
var failed := 0
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var menu = MENU.instantiate()
 var entry: Dictionary = CATALOG.get_entry("main_menu_shell")
 check(String(menu.call("get_background_path")) == IMAGE, "Real main-menu API restores the user-selected original artwork")
 check(String(entry.get("origin", "")) == "task_199_curated_project_asset", "Original provenance is distinguished from the newer native capture")
 check(FileAccess.get_sha256(IMAGE) == IMAGE_SHA, "Original title artwork bytes are unchanged")
 check(String(entry.get("sha256", "")) == IMAGE_SHA, "Active catalog pins the exact original image")
 var texture = ResourceLoader.load(IMAGE) as Texture2D
 check(texture != null and texture.get_width() == 1376 and texture.get_height() == 768, "Original image remains loadable at its real dimensions")
 var routes: Dictionary = menu.call("get_route_snapshot")
 check(String(routes.get("singleplayer", "")) == "res://scenes/meta/meta_layer_test.tscn", "Singleplayer retains the real authoritative Meta route")
 check(menu.get_node_or_null("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton") is Button, "Real Singleplayer callback/control remains")
 menu.free()
 print("MENU_RESTORE_RESULT %d passed, %d failed" % [passed, failed])
 if failed == 0: print("PLAYTEST_MENU_RESTORE_ALL_PASS")
 quit(1 if failed else 0)
func check(ok: bool, message: String) -> void:
 if ok:
  passed += 1
  print("PASS: ", message)
 else:
  failed += 1
  push_error("FAIL: " + message)
