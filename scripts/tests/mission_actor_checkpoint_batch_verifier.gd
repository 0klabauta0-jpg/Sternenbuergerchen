extends "res://scripts/tests/hex_runtime_selection_verifier.gd"
var signal_count := 0
func on_vital(_v) -> void:
 signal_count += 1
func _run() -> void:
 var script = load("res://scripts/mission/mission_actor_checkpoint_batch.gd")
 if script == null:
  _check(false,"actor batch owner exists")
  done()
  return
 var rig: Dictionary = _selection_rig(PackedStringArray(["a","b"]))
 var batch = script.new()
 var a = rig.actors.a
 var b = rig.actors.b
 a._set_vital_status("down",0,5)
 b._set_vital_status("down",0,8)
 var saved: Dictionary = JSON.parse_string(JSON.stringify(batch.export_actors(rig.sim)))
 _check(saved.get("ok", false),"actual registered actors export")
 a._set_vital_status("fit",a.max_health_points,0)
 b._set_vital_status("fit",b.max_health_points,0)
 var positions := {"a":a.global_position,"b":b.global_position}
 var prepared: Dictionary = batch.prepare_restore(rig.sim,saved,positions)
 _check(prepared.get("ok",false),"batch prepares")
 if prepared.get("ok",false):
  b._set_vital_status("down",0,1)
  _check(not batch.commit_restore(prepared.prepared).get("ok",false) and a.get_vital_state() == "fit", "stale second actor cannot publish the first")
  b._set_vital_status("fit",b.max_health_points,0)
  prepared = batch.prepare_restore(rig.sim,saved,positions)
  _check(prepared.get("ok",false),"fresh batch prepares")
  if prepared.get("ok",false):
   a.vital_status_changed.connect(on_vital)
   b.vital_status_changed.connect(on_vital)
   if not batch.has_method("_publish_restore") or not batch.has_method("finalize_restore"):
    _check(false, "batch supports separate model publication and notification")
   else:
    var checked: Dictionary = batch.validate_restore(prepared.prepared)
    batch._publish_restore(prepared.prepared, checked)
    _check(signal_count == 0, "no actor signals before all models publish")
    _check(a.get_vital_state()=="down" and b.get_vital_state()=="down" and a._vital_status.bleedout_ticks==5 and b._vital_status.bleedout_ticks==8,"both actual health states restored")
    _check(batch.finalize_restore(prepared.prepared).get("ok",false) and signal_count == 2, "notifications occur after publication")
 rig.scene.free()
 done()
func done() -> void:
 print("RESULTS: %d passed, %d failed" % [passed,failed])
 if failed == 0: print("MISSION_ACTOR_BATCH_PASS")
 quit(0 if failed == 0 else 1)
