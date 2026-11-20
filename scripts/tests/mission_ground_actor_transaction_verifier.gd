extends "res://scripts/tests/hex_runtime_selection_verifier.gd"
## Joint ground/actor restore transaction on the Hex runtime. Checkpoints in the
## pre-Hex format (legacy_ground_positions.v1) are rejected since 20.11.2026.
func _run() -> void:
 var ACTORS = load("res://scripts/mission/mission_actor_checkpoint_batch.gd")
 var transaction_script = load("res://scripts/mission/mission_ground_actor_transaction.gd")
 var rig: Dictionary = _selection_rig(PackedStringArray(["a","b"]))
 var sim = rig.sim
 var a = rig.actors.a
 var b = rig.actors.b
 var actors = ACTORS.new()
 var exported: Dictionary = sim.export_hex_checkpoint_state()
 print("HEX_EXPORT ", exported.get("reason","ok"))
 _check(exported.get("ok",false),"hex ground state exports from the real Root")
 var saved_actors: Dictionary = JSON.parse_string(JSON.stringify(actors.export_actors(sim)))
 _check(saved_actors.get("ok",false),"actor batch exports")
 var saved_ground: Dictionary = JSON.parse_string(JSON.stringify({"ok":true,"schema":"hex_mission_ground.v1","checkpoint":exported.get("state",{})}))
 var transaction = transaction_script.new()
 var prepared: Dictionary = transaction.prepare_restore(rig.sim,rig.terrain,saved_ground,saved_actors,["a","b"],{})
 print("HEX_PREPARE ", prepared.get("reason","ok"))
 _check(prepared.get("ok",false),"current Hex checkpoint is accepted")
 if prepared.get("ok",false):
  _check(transaction.validate_restore(prepared.prepared).get("ok",false),"prepared Hex checkpoint validates against the owners")
  transaction._publish_restore(prepared.prepared)
  _check(transaction.finalize_restore(prepared.prepared).get("ok",false),"published Hex checkpoint finalizes")
 var legacy := {"ok":true,"schema":"legacy_ground_positions.v1","frame":{},"map_fingerprint":"","overrides":{},"positions":{}}
 var rejected: Dictionary = transaction_script.new().prepare_restore(rig.sim,rig.terrain,legacy,saved_actors,["a","b"],{})
 _check(not rejected.get("ok",true) and rejected.get("reason") == "unsupported_ground_schema","legacy ground checkpoint is rejected with unsupported_ground_schema (got " + str(rejected.get("reason")) + ")")
 # Derselbe heute gueltige Hex-Stand, nur das ground-Schema im Speicher auf das alte Format gesetzt.
 var format_only: Dictionary = saved_ground.duplicate(true)
 format_only.schema = "legacy_ground_positions.v1"
 var format_rejected: Dictionary = transaction_script.new().prepare_restore(rig.sim,rig.terrain,format_only,saved_actors,["a","b"],{})
 _check(not format_rejected.get("ok",true) and format_rejected.get("reason") == "unsupported_ground_schema","nur das Schema weicht ab: Grund genau unsupported_ground_schema (got " + str(format_rejected.get("reason")) + ")")
 var no_schema: Dictionary = transaction_script.new().prepare_restore(rig.sim,rig.terrain,{},saved_actors,["a","b"],{})
 _check(not no_schema.get("ok",true) and no_schema.get("reason") == "unsupported_ground_schema","ground ohne Schema (leer): Grund genau unsupported_ground_schema (got " + str(no_schema.get("reason")) + ")")
 var unchanged: Dictionary = transaction_script.new().prepare_restore(rig.sim,rig.terrain,saved_ground,saved_actors,["a","b"],{})
 _check(unchanged.get("ok",false) == true,"derselbe Stand mit hex_mission_ground.v1 wird angenommen (ok == true)")
 _check(a.global_position.is_finite() and b.global_position.is_finite() and not sim.get_hex_unit_state("a").is_empty() and not sim.get_hex_unit_state("b").is_empty(),"rejection leaves both actors on the Hex ground")
 rig.scene.free()
 done()
func done() -> void:
 print("RESULTS: %d passed, %d failed" % [passed,failed])
 if failed == 0: print("MISSION_GROUND_ACTOR_TRANSACTION_PASS")
 quit(0 if failed == 0 else 1)
