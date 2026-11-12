extends SceneTree
const DRIVER = preload("res://scripts/tests/mission_combat_loop_driver.gd")
class QuietDriver extends DRIVER:
 func _ready() -> void: set_process(false); set_physics_process(false)
func _initialize() -> void:
 var driver = QuietDriver.new()
 root.add_child(driver)
 if not driver.has_method("restore_checkpoint_elapsed_time"):
  printerr("mission clock restore unavailable")
  driver.free(); quit(1); return
 driver.mission_time_limit_seconds = 1200.0
 var result: Dictionary = driver.restore_checkpoint_elapsed_time(900000)
 assert(result.ok)
 assert(abs(driver._get_duration_seconds() - 900.0) < 0.2)
 assert(abs(driver.get_remaining_time_limit_seconds() - 300.0) < 0.2)
 assert(not driver.restore_checkpoint_elapsed_time(-1).ok)
 driver.free()
 print("MISSION_CHECKPOINT_CLOCK_PASS")
 quit(0)
