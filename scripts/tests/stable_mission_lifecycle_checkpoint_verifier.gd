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
 # Gefechtstakt: neue Staende haben keinen gemeinsamen Schussplatz; alte Staende mit next_attack_tick laden weiter.
 var codec = load("res://scripts/mission/checkpoint_value_codec.gd")
 var payload: Dictionary = codec.decode_value(saved.payload).value
 _check(not payload.has("next_attack_tick"),"new state carries no shared fire slot")
 var legacy_payload: Dictionary = payload.duplicate(true)
 legacy_payload["next_attack_tick"] = 5
 var legacy: Dictionary = saved.duplicate(true)
 legacy.payload = codec.encode_value(legacy_payload).value
 _check(owner.prepare_restore(rig.sim,driver,legacy).get("ok",false),"old state with next_attack_tick still loads (value ignored)")
 legacy_payload["next_attack_tick"] = -3
 legacy.payload = codec.encode_value(legacy_payload).value
 _check(not owner.prepare_restore(rig.sim,driver,legacy).get("ok",false),"old state with an invalid next_attack_tick is still rejected")
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
  driver._combat_startup_grace_ticks += 1
  _check(prep.get("ok",false) and not owner.validate_restore(prep.prepared).get("ok",false), "changed driver state invalidates preparation")
  driver._combat_startup_grace_ticks -= 1
  prep = owner.prepare_restore(rig.sim,driver,saved)
  _check(prep.get("ok",false),"fresh lifecycle candidate prepares")
  if prep.get("ok",false):
   var checked: Dictionary = owner.validate_restore(prep.prepared)
   # FT-0b Regel 11: Unterdrueckung steht nicht im Speicherstand; der echte Wiederherstellweg leert sie.
   driver.get_suppression_tracker().set_state("enemy:probe", 3.0, 2)
   driver.get_suppression_tracker().set_state("own:a", 5.0, 3)
   if checked.get("ok",false): owner._publish_restore(prep.prepared)
   _check(driver.get_suppression_level("enemy:probe")==0 and driver.get_suppression_level("own:a")==0,"restore clears suppression of both sides")
   _check(checked.get("ok",false) and rig.sim.tick_counter==saved.tick and abs(driver._get_duration_seconds()-900.0)<0.2,"tick, RNG and elapsed clock publish")
 # Verbluten in Stufen: Wer liegt, sperrt das Speichern nicht; sein Ausfall-Tick steht im Stand und kommt beim Laden zurueck.
 var lying_id: String = String(rig.actors.a.get_unit_id())
 driver._down_state_started_tick_by_unit_id[lying_id] = driver._current_tick
 var lying_saved: Dictionary = owner.export_state(rig.sim,driver)
 _check(lying_saved.get("ok",false),"a lying person does not block the save")
 var lying_state: Dictionary = JSON.parse_string(JSON.stringify(lying_saved))
 driver._down_state_started_tick_by_unit_id.clear()
 var lying_prep: Dictionary = owner.prepare_restore(rig.sim,driver,lying_state)
 _check(lying_prep.get("ok",false),"the saved state with a lying person prepares")
 if lying_prep.get("ok",false) and owner.validate_restore(lying_prep.prepared).get("ok",false):
  owner._publish_restore(lying_prep.prepared)
  _check(driver._down_state_started_tick_by_unit_id.get(lying_id,-1) == int(lying_saved.tick),"restore brings the same fall tick back, the clock keeps running")
 else:
  _check(false,"the saved state with a lying person validates")
 # Ein Verbluten, das eingereiht aber noch nicht gewirkt hat, sperrt weiter (der Effekt steht noch in der Warteschlange).
 driver.campaign_casualty_rules_enabled = true
 driver._queued_bleedout_by_unit_id[lying_id] = true
 _check(owner.export_state(rig.sim,driver).get("reason","") == "mission_lifecycle_unsupported","a queued, not yet applied bleedout still blocks the save")
 # Hat es gewirkt (Kampagne, keine Rueckkehr), ist der Stand speicherbar; die Verblutete bleibt nach dem Laden verblutet.
 actor.apply_damage(1000, {})
 driver._on_unit_vital_status_changed(actor._vital_status, actor)
 actor.advance_bleedout()
 driver._on_unit_vital_status_changed(actor._vital_status, actor)
 _check(actor.get_vital_state() == "bleedout" and driver._queued_bleedout_by_unit_id.is_empty() and driver._down_state_started_tick_by_unit_id.is_empty(),"an applied bleedout (campaign, no return) frees the marker and the clock")
 var bled_saved: Dictionary = owner.export_state(rig.sim,driver)
 _check(bled_saved.get("ok",false),"a bled-out person does not block the save")
 var bled_state: Dictionary = {}
 var bled_flags: Dictionary = {}
 if bled_saved.get("ok",false):
  bled_state = JSON.parse_string(JSON.stringify(bled_saved))
  var bled_payload: Variant = codec.decode_value(bled_state.get("payload",{})).get("value",{})
  if bled_payload is Dictionary and bled_payload.get("casualty_flags",null) is Dictionary: bled_flags = bled_payload.casualty_flags
 _check(bled_flags.has("was_downed_unit_ids") and bled_flags.was_downed_unit_ids.has(lying_id) and not bled_flags.has("down_started_ticks"),"the saved state keeps the down marker, but no clock for the bled-out person")
 var bled_prep: Dictionary = owner.prepare_restore(rig.sim,driver,bled_state) if not bled_state.is_empty() else {}
 if bled_prep.get("ok",false) and owner.validate_restore(bled_prep.prepared).get("ok",false):
  owner._publish_restore(bled_prep.prepared)
  _check(actor.get_vital_state() == "bleedout" and driver._down_state_started_tick_by_unit_id.is_empty() and driver._queued_bleedout_by_unit_id.is_empty(),"after restore she is still bled out: no clock, no marker, not lying again")
 else:
  _check(false,"the saved state with a bled-out person loads")
 driver._queued_bleedout_by_unit_id.clear()
 rig.scene.free()
 done()
func done() -> void:
 print("RESULTS: %d passed, %d failed" % [passed,failed])
 if failed == 0: print("STABLE_MISSION_LIFECYCLE_CHECKPOINT_PASS")
 quit(0 if failed == 0 else 1)
