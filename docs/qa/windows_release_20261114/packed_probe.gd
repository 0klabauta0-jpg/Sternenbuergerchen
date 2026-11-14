extends SceneTree
var passed := 0
func _initialize() -> void:
 call_deferred("probe")
func check(value: bool, label: String) -> void:
 if value: passed += 1
 else: push_error("PACKED_RELEASE_SMOKE failed: " + label)
func probe() -> void:
 if not OS.get_user_data_dir().replace("\\", "/").begins_with(OS.get_environment("APPDATA").replace("\\", "/")):
  push_error("Private APPDATA ignored"); quit(2); return
 print("PACKED_RELEASE_USER_DIR " + OS.get_user_data_dir())
 check(FileAccess.file_exists("res://data/export_runtime_package_contract.json"), "packed runtime data")
 var scene = load("res://scenes/ui/main_menu.tscn") as PackedScene
 check(scene != null, "packed main scene")
 var menu = scene.instantiate() if scene else null
 if menu: root.add_child(menu)
 await process_frame
 check(menu != null and menu.is_node_ready(), "main menu ready")
 check(menu != null and menu.get_child_count() > 0, "populated main menu")
 if menu: menu.queue_free()
 await process_frame
 print("PACKED_RELEASE_SMOKE passed=%d failed=%d" % [passed,4-passed])
 quit(0 if passed == 4 else 1)
