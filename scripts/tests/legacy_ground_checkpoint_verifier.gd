extends "res://scripts/tests/hex_runtime_selection_verifier.gd"
func _run() -> void:
 var script = load("res://scripts/mission/legacy_ground_checkpoint.gd")
 if script == null:
  _check(false,"legacy ground checkpoint exists")
  done()
  return
 var rig: Dictionary = _selection_rig(PackedStringArray(["a","b"]))
 rig.map.set_tactical_grid_rules("")
 rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
 var owner = script.new()
 var a = rig.actors.a
 var b = rig.actors.b
 var expected_a: Vector2 = a.global_position
 var expected_b: Vector2 = b.global_position
 var saved: Dictionary = JSON.parse_string(JSON.stringify(owner.export_positions(rig.sim,rig.terrain,["a","b"])))
 _check(saved.get("ok",false),"actual legacy positions exported")
 a.global_position = rig.terrain.grid_to_world(Vector2i(2,0))
 b.global_position = rig.terrain.grid_to_world(Vector2i(3,0))
 var current_a: Vector2 = a.global_position
 var bad: Dictionary = saved.duplicate(true)
 bad.map_fingerprint = "invalid"
 _check(not owner.prepare_restore(rig.sim,rig.terrain,bad,["a","b"]).get("ok",false) and a.global_position == current_a,"different map fingerprint rejected")
 var codec = load("res://scripts/mission/checkpoint_value_codec.gd")
 bad = saved.duplicate(true)
 var bad_positions: Dictionary = codec.decode_value(bad.positions).value
 bad_positions.b = bad_positions.a
 bad.positions = codec.encode_value(bad_positions).value
 _check(not owner.prepare_restore(rig.sim,rig.terrain,bad,["a","b"]).get("ok",false),"overlapping positions rejected")
 var prep: Dictionary = owner.prepare_restore(rig.sim,rig.terrain,saved,["a","b"])
 _check(prep.get("ok",false),"valid positions prepare without mutation")
 if prep.get("ok",false):
  b.global_position += Vector2(1,0)
  _check(not owner.commit_restore(prep.prepared).get("ok",false) and a.global_position == current_a,"changed second actor prevents all position changes")
  b.global_position -= Vector2(1,0)
  prep = owner.prepare_restore(rig.sim,rig.terrain,saved,["a","b"])
  _check(prep.get("ok",false) and owner.commit_restore(prep.prepared).get("ok",false),"fresh legacy positions commit")
  _check(a.global_position.distance_to(expected_a)<0.01 and b.global_position.distance_to(expected_b)<0.01,"both positions restored")
 rig.scene.free()
 done()
func done() -> void:
 print("RESULTS: %d passed, %d failed" % [passed,failed])
 if failed == 0: print("LEGACY_GROUND_CHECKPOINT_PASS")
 quit(0 if failed == 0 else 1)
