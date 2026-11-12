extends "res://scripts/tests/hex_runtime_selection_verifier.gd"
func _run() -> void:
 var rig: Dictionary = _selection_rig(PackedStringArray(["a"]))
 var actor = rig.actors.a
 if not actor.has_method("export_mission_actor_checkpoint"):
  _check(false, "actor checkpoint hooks exist")
  rig.scene.free()
  done()
  return
 actor._set_vital_status("down", 0, 9)
 var saved: Dictionary = JSON.parse_string(JSON.stringify(actor.export_mission_actor_checkpoint()))
 actor._set_vital_status("fit", actor.max_health_points, 0)
 var before: Dictionary = actor._vital_status.to_dict()
 var bad: Dictionary = saved.duplicate(true)
 bad.unit_id = "different"
 _check(not actor.prepare_mission_actor_restore(rig.sim,bad,actor.global_position).ok and actor._vital_status.to_dict() == before, "foreign identity rejected without health mutation")
 _check(not actor.prepare_mission_actor_restore(rig.sim,saved,actor.global_position + Vector2(1, 0)).ok, "ground position mismatch is rejected")
 var prepared: Dictionary = actor.prepare_mission_actor_restore(rig.sim,saved,actor.global_position)
 _check(prepared.ok and actor._vital_status.to_dict() == before, "actor restore is prepared without publication")
 if prepared.ok:
  var checked: Dictionary = actor.validate_mission_actor_restore(prepared.prepared)
  _check(checked.ok, "actor preparations validate")
  if checked.ok:
   actor._publish_mission_actor_restore(prepared.prepared,checked)
   _check(actor.get_vital_state() == "down" and actor._vital_status.bleedout_ticks == 9, "actual actor health restored")
   _check(actor.finalize_mission_actor_restore(prepared.prepared).ok, "final actor projection succeeds")
   actor._set_vital_status("fit", actor.max_health_points, 0)
   var command = load("res://scripts/npc/unit_command.gd").new()
   command.command_type = "hold_position"
   command.unit_id = actor.unit_id
   command.team_id = actor.team_id
   command.source_task_type = "post_drop_360_security"
   _check(actor.assign_unit_command(command), "actual unit accepts saved command")
   var active: Dictionary = JSON.parse_string(JSON.stringify(actor.export_mission_actor_checkpoint()))
   var codec = load("res://scripts/mission/checkpoint_value_codec.gd")
   var broken := active.duplicate(true)
   var broken_data: Dictionary = codec.decode_value(broken.payload).value
   broken_data.vital = {"state":"down", "health_points":0, "bleedout_ticks":1}
   broken.payload = codec.encode_value(broken_data).value
   _check(not actor.prepare_mission_actor_restore(rig.sim,broken,actor.global_position).ok, "downed actor cannot restore a live command")
   actor._current_unit_command = null
   actor.remove_meta("post_drop_security_active")
   var active_prep: Dictionary = actor.prepare_mission_actor_restore(rig.sim,active,actor.global_position)
   _check(active_prep.ok, "active command prepares")
   if active_prep.ok:
    var active_check: Dictionary = actor.validate_mission_actor_restore(active_prep.prepared)
    _check(active_check.ok, "active command validates")
    if active_check.ok:
     actor._publish_mission_actor_restore(active_prep.prepared,active_check)
     _check(actor.finalize_mission_actor_restore(active_prep.prepared).ok and actor.get_current_unit_command() != null and actor.get_meta("post_drop_security_active",false), "active command and security behavior restored")
 rig.scene.free()
 done()
func done() -> void:
 print("RESULTS: %d passed, %d failed" % [passed, failed])
 if failed == 0: print("MISSION_ACTOR_CHECKPOINT_PASS")
 quit(0 if failed == 0 else 1)
