extends SceneTree
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
func cmd(owner, op: String, payload: Dictionary, id: String, trusted: bool = false) -> Dictionary:
 return owner.apply_command({"contract_category":"singleplayer_space_travel", "operation":op, "payload":payload, "request_id":id}, {"runtime_authorized":trusted})
func _initialize() -> void:
 var source = FLEET.new()
 assert(source.configure().ok)
 source.register_craft("a")
 source.register_craft("b")
 assert(cmd(source,"launch_to_orbit",{"craft_id":"a"},"launch",true).ok)
 assert(cmd(source,"start_quantum",{"craft_id":"a","target_orbit_id":"planet_orbit"},"jump").ok)
 if not source.has_method("export_checkpoint_state"):
  printerr("fleet checkpoint API absent")
  quit(1)
  return
 var context := {"request_id":"completed", "request_signature":"sig", "operation":"launch_to_orbit", "source_area_id":"", "target_area_id":"", "context_id":"old", "expected_phase":"grounded", "expected_travel_revision":0, "payload":{"craft_id":"a"}}
 var binding := JSON.stringify(context, "", true)
 source._space_area_bindings["completed"] = binding
 source._space_area_receipts["completed"] = {"context_binding":binding,"result":{"ok":true},"travel_owner_instance_id":source._owners.a.get_instance_id(),"travel_owner_epoch":source._owners.a._space_area_epoch}
 var saved: Dictionary = JSON.parse_string(JSON.stringify(source.export_checkpoint_state()))
 var target = FLEET.new()
 assert(target.configure().ok)
 var before: Dictionary = target.get_snapshot()
 assert(not target.prepare_checkpoint_restore(saved,["a"]).ok)
 assert(target.get_snapshot() == before)
 var prepared: Dictionary = target.prepare_checkpoint_restore(saved,["a","b"])
 assert(prepared.ok and target.get_snapshot() == before)
 var rebuilt = prepared.candidate
 var authority = RefCounted.new()
 assert(rebuilt.configure_space_area_transition_authority(authority).ok)
 assert(rebuilt._check_bound_space_area_context(context).ok)
 assert(rebuilt._space_area_receipt_owner_valid(rebuilt._space_area_receipts.completed,"a"))
 assert(rebuilt.get_snapshot().focused_craft_id == source.get_snapshot().focused_craft_id)
 assert(rebuilt.get_craft_snapshot("a").phase == "quantum")
 assert(rebuilt.get_craft_snapshot("b").phase == "grounded")
 assert(cmd(rebuilt,"launch_to_orbit",{"craft_id":"a"},"launch",true).get("replayed",false))
 print("SPACE_FLEET_CHECKPOINT_PASS")
 quit(0)
