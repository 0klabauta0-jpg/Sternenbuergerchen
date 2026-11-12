extends "res://scripts/tests/hex_runtime_selection_verifier.gd"
func _run() -> void:
 var rig: Dictionary = _selection_rig(PackedStringArray(["a"]))
 var actor = rig.actors.a
 if not actor.has_method("prepare_mission_vital_restore"):
  _check(false, "mission vital checkpoint hooks exist")
  rig.scene.free()
  _finish_checkpoint()
  return
 var before: Dictionary = actor._vital_status.to_dict()
 var incoming := {"state":"down", "health_points":0, "bleedout_ticks":42}
 var bad := incoming.duplicate()
 bad.health_points = -1
 _check(not actor.prepare_mission_vital_restore(rig.sim, bad).ok and actor._vital_status.to_dict() == before, "invalid health cannot mutate live actor")
 var prepared: Dictionary = actor.prepare_mission_vital_restore(rig.sim, incoming)
 _check(prepared.ok and actor._vital_status.to_dict() == before, "preparation leaves actor unchanged")
 if prepared.ok:
  var valid: Dictionary = actor.validate_mission_vital_restore(prepared.prepared)
  _check(valid.ok, "prepared identity validates")
  if valid.ok:
   actor._publish_mission_vital_restore(prepared.prepared, valid)
   _check(actor._vital_status.to_dict() == incoming, "model publication restores vital values")
   _check(actor.finalize_mission_vital_restore(prepared.prepared).ok, "visual projection finalizes after publication")
   var stale: Dictionary = actor.prepare_mission_vital_restore(rig.sim, incoming)
   actor._set_vital_status("fit", actor.max_health_points, 0)
   _check(stale.ok and not actor.validate_mission_vital_restore(stale.prepared).ok and actor.get_vital_state() == "fit", "stale prepared model cannot overwrite newer health")
 rig.scene.free()
 _finish_checkpoint()
func _finish_checkpoint() -> void:
 print("RESULTS: %d passed, %d failed" % [passed, failed])
 if failed == 0: print("MISSION_ACTOR_VITAL_CHECKPOINT_PASS")
 quit(0 if failed == 0 else 1)
