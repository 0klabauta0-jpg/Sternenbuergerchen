extends SceneTree
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
func command(owner, operation: String, payload: Dictionary, id: String, trusted: bool = false) -> Dictionary:
 return owner.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":id}, {"runtime_authorized":trusted})
func close_snapshot(a: Dictionary, b: Dictionary) -> bool:
 for key in a:
  if typeof(a[key]) == TYPE_FLOAT and typeof(b[key]) == TYPE_FLOAT:
   if not is_equal_approx(a[key], b[key]): return false
  elif a[key] != b[key]: return false
 return true
func _initialize() -> void:
 var source = TRAVEL.new()
 assert(source.configure("ship").ok)
 assert(command(source,"launch_to_orbit",{"craft_id":"ship"},"launch",true).ok)
 assert(command(source,"start_quantum",{"craft_id":"ship","target_orbit_id":"planet_orbit"},"jump").ok)
 assert(command(source,"advance",{"delta_seconds":1.0},"tick1",true).ok)
 if not source.has_method("export_checkpoint_state"):
  printerr("missing travel checkpoint API")
  quit(1)
  return
 var saved: Dictionary = JSON.parse_string(JSON.stringify(source.export_checkpoint_state()))
 var target = TRAVEL.new()
 assert(target.configure("ship").ok)
 var before: Dictionary = target.get_snapshot()
 var bad: Dictionary = saved.duplicate(true)
 bad.craft_id = "other"
 assert(not target.prepare_checkpoint_restore(bad).ok)
 var tampered: Dictionary = saved.duplicate(true)
 var codec = load("res://scripts/mission/checkpoint_value_codec.gd")
 var payload: Dictionary = codec.decode_value(tampered.travel).value
 payload.progress = 0.9
 tampered.travel = codec.encode_value(payload).value
 assert(not target.prepare_checkpoint_restore(tampered).ok)
 assert(target.get_snapshot() == before)
 var prepared: Dictionary = target.prepare_checkpoint_restore(saved)
 assert(prepared.ok and target.get_snapshot() == before)
 if not target.has_method("validate_checkpoint_restore"):
  printerr("validation API absent")
  quit(1)
  return
 assert(target.validate_checkpoint_restore(prepared.prepared).ok)
 assert(target.commit_checkpoint_restore(prepared.prepared).ok)
 assert(close_snapshot(target.get_snapshot(), source.get_snapshot()))
 assert(command(target,"advance",{"delta_seconds":1.0},"tick1",true).get("replayed", false))
 assert(command(source,"advance",{"delta_seconds":2.0},"tick2",true).ok)
 assert(command(target,"advance",{"delta_seconds":2.0},"tick2",true).ok)
 assert(close_snapshot(target.get_snapshot(), source.get_snapshot()))
 print("SPACE_TRAVEL_CHECKPOINT_PASS")
 quit(0)
