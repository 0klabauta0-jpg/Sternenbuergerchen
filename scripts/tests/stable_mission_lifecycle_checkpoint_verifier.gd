extends "res://scripts/tests/hex_runtime_selection_verifier.gd"
const DRIVER = preload("res://scripts/tests/mission_combat_loop_driver.gd")
class QuietDriver extends DRIVER:
 func _ready() -> void: set_process(false); set_physics_process(false)
class StillMovement extends RefCounted:
 func get_state_snapshot() -> Array: return []
class QuietController extends Node:
 var _order_plans_by_key := {}
 var _area_orders_by_id := {}
 var _fireteam_movement_controller = StillMovement.new()
func _run() -> void:
 var script = load("res://scripts/mission/stable_mission_lifecycle_checkpoint.gd")
 if script == null: _check(false,"stable lifecycle helper exists"); done(); return
 var rig: Dictionary = _selection_rig(PackedStringArray(["a"]))
 rig.map.set_tactical_grid_rules("")
 rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
 var driver = QuietDriver.new()
 rig.scene.add_child(driver)
 driver.friendly_team_id = "blue"
 driver._current_tick = rig.sim.tick_counter
 driver._mission_started_at_msec = maxi(Time.get_ticks_msec(),1)
 driver._checkpoint_elapsed_offset_msec = 900000
 var owner = script.new()
 var saved: Dictionary = JSON.parse_string(JSON.stringify(owner.export_state(rig.sim,driver)))
 _check(saved.get("ok",false),"stable legacy lifecycle captures")
 var controller := QuietController.new()
 controller.name = "TacticalController"
 rig.scene.add_child(controller)
 _check(owner.export_state(rig.sim,driver).get("ok",false),"empty planned orders remain savable")
 controller._order_plans_by_key["ft1|phase"] = {"waypoints":[Vector2(40,20)]}
 _check(owner.export_state(rig.sim,driver).get("reason","")=="mission_planned_orders_unsupported","planned movement cannot be silently omitted")
 _check(not owner.prepare_restore(rig.sim,driver,saved).get("ok",false),"restore rejects a target with planned movement")
 controller._order_plans_by_key.clear()
 controller._area_orders_by_id["area"] = {"command":"defend"}
 _check(owner.export_state(rig.sim,driver).get("reason","")=="mission_planned_orders_unsupported","planned area order cannot be silently omitted")
 controller._area_orders_by_id.clear()
 var actor = rig.actors.a
 var moving = load("res://scripts/npc/unit_command.gd").new()
 moving.command_type = "move_to_position"
 moving.unit_id = actor.unit_id
 moving.team_id = actor.team_id
 moving.target_position = Vector2(200,0)
 actor._current_unit_command = moving
 _check(not owner.export_state(rig.sim,driver).get("ok",false),"active movement cannot be silently omitted")
 actor._current_unit_command = null
 rig.sim.tick_counter += 4
 driver._current_tick = rig.sim.tick_counter
 var before: int = rig.sim.tick_counter
 var prep: Dictionary = owner.prepare_restore(rig.sim,driver,saved)
 _check(prep.get("ok",false) and rig.sim.tick_counter == before,"lifecycle restore prepares without mutation")
 if prep.get("ok",false):
  rig.sim.tick_counter += 1
  _check(not owner.validate_restore(prep.prepared).get("ok",false),"changed source clock is rejected")
  driver._current_tick = rig.sim.tick_counter
  prep = owner.prepare_restore(rig.sim,driver,saved)
  driver._next_attack_tick += 1
  _check(prep.get("ok",false) and not owner.validate_restore(prep.prepared).get("ok",false), "changed driver state invalidates preparation")
  driver._next_attack_tick -= 1
  prep = owner.prepare_restore(rig.sim,driver,saved)
  _check(prep.get("ok",false),"fresh lifecycle candidate prepares")
  if prep.get("ok",false):
   var checked: Dictionary = owner.validate_restore(prep.prepared)
   if checked.get("ok",false): owner._publish_restore(prep.prepared)
   _check(checked.get("ok",false) and rig.sim.tick_counter==saved.tick and abs(driver._get_duration_seconds()-900.0)<0.2,"tick, RNG and elapsed clock publish")
 rig.scene.free()
 done()
func done() -> void:
 print("RESULTS: %d passed, %d failed" % [passed,failed])
 if failed == 0: print("STABLE_MISSION_LIFECYCLE_CHECKPOINT_PASS")
 quit(0 if failed == 0 else 1)
