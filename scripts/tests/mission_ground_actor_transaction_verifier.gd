extends "res://scripts/tests/hex_runtime_selection_verifier.gd"
func _run() -> void:
 var GROUND = load("res://scripts/mission/legacy_ground_checkpoint.gd")
 var ACTORS = load("res://scripts/mission/mission_actor_checkpoint_batch.gd")
 var rig: Dictionary = _selection_rig(PackedStringArray(["a","b"]))
 rig.map.set_tactical_grid_rules("")
 rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
 var ground = GROUND.new()
 var actors = ACTORS.new()
 var a = rig.actors.a
 var b = rig.actors.b
 a._set_vital_status("down",0,7)
 var saved_ground: Dictionary = JSON.parse_string(JSON.stringify(ground.export_positions(rig.sim,rig.terrain,["a","b"])))
 var saved_actors: Dictionary = JSON.parse_string(JSON.stringify(actors.export_actors(rig.sim)))
 var original_position: Vector2 = a.global_position
 a._set_vital_status("fit",a.max_health_points,0)
 a.global_position = rig.terrain.grid_to_world(Vector2i(2,0))
 b.global_position = rig.terrain.grid_to_world(Vector2i(3,0))
 var g: Dictionary = ground.prepare_restore(rig.sim,rig.terrain,saved_ground,["a","b"])
 _check(g.get("ok",false),"actual ground model prepared")
 if not g.get("ok",false): rig.scene.free(); done(); return
 var p: Dictionary = actors.prepare_restore(rig.sim,saved_actors,g.positions)
 _check(p.get("ok",false),"actor positions agree with prepared ground")
 if p.get("ok",false):
  var ground_check: Dictionary = ground.validate_restore(g.prepared)
  var actor_check: Dictionary = actors.validate_restore(p.prepared)
  _check(ground_check.ok and actor_check.ok,"both participants validate before publication")
  if ground_check.ok and actor_check.ok:
   ground._publish_restore(g.prepared)
   actors._publish_restore(p.prepared,actor_check)
   _check(a.global_position.distance_to(original_position)<0.01 and a.get_vital_state()=="down", "position and health commit together")
   _check(actors.finalize_restore(p.prepared).ok,"projection finalizes after both models")
 rig.scene.free()
 done()
func done() -> void:
 print("RESULTS: %d passed, %d failed" % [passed,failed])
 if failed == 0: print("MISSION_GROUND_ACTOR_TRANSACTION_PASS")
 quit(0 if failed == 0 else 1)
