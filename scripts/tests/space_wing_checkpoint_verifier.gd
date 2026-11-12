extends SceneTree
const WING = preload("res://scripts/core/space_wing_state.gd")
func _initialize() -> void:
 var source = WING.new()
 assert(source.ensure_flying_wings("player", ["ship1", "ship2"], ["ship1", "ship2"], {"ship1":"pilot1", "ship2":"pilot2"}).ok)
 if not source.has_method("export_checkpoint_state") or not source.has_method("prepare_checkpoint_restore"):
  printerr("missing wing checkpoint APIs")
  quit(1)
  return
 var snapshot: Dictionary = JSON.parse_string(JSON.stringify(source.export_checkpoint_state()))
 var target = WING.new()
 var before: Dictionary = target.get_snapshot()
 var malformed := snapshot.duplicate(true)
 var codec = load("res://scripts/mission/checkpoint_value_codec.gd")
 var payload: Dictionary = codec.decode_value(malformed.payload).value
 payload.wings["solo:ship1"].craft_ids.append("ship2")
 malformed.payload = codec.encode_value(payload).value
 assert(not target.prepare_checkpoint_restore(malformed, "player", ["ship1", "ship2"]).ok)
 assert(target.get_snapshot() == before)
 assert(not target.prepare_checkpoint_restore(snapshot, "stranger", ["ship1", "ship2"]).ok)
 var result: Dictionary = target.prepare_checkpoint_restore(snapshot, "player", ["ship1", "ship2"])
 assert(result.ok and target.get_snapshot() == before)
 if not target.has_method("validate_checkpoint_restore"):
  printerr("validation API absent")
  quit(1)
  return
 assert(target.validate_checkpoint_restore(result.prepared).ok)
 assert(target.commit_checkpoint_restore(result.prepared).ok)
 assert(target.get_snapshot() == source.get_snapshot())
 assert(not target.commit_checkpoint_restore(result.prepared).ok)
 var stale: Dictionary = target.prepare_checkpoint_restore(snapshot, "player", ["ship1", "ship2", "ship3"])
 assert(stale.ok)
 assert(target.ensure_flying_wings("player", ["ship3"], ["ship1", "ship2", "ship3"], {"ship1":"pilot1", "ship2":"pilot2", "ship3":"pilot3"}).ok)
 var changed: Dictionary = target.get_snapshot()
 assert(not target.commit_checkpoint_restore(stale.prepared).ok)
 assert(target.get_snapshot() == changed)
 source._wings["solo:ship1"]["order"] = {"destination":Vector2(1, 2)}
 var with_order: Dictionary = JSON.parse_string(JSON.stringify(source.export_checkpoint_state()))
 var order_target = WING.new()
 var order_prep: Dictionary = order_target.prepare_checkpoint_restore(with_order, "player", ["ship1", "ship2"])
 assert(order_prep.ok and order_target.commit_checkpoint_restore(order_prep.prepared).ok)
 assert(order_target.get_snapshot() == source.get_snapshot())
 print("SPACE_WING_CHECKPOINT_PASS")
 quit(0)
