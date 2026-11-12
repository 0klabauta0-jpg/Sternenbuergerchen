extends SceneTree
const COMBAT = preload("res://scripts/core/space_combat_state.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const CATALOG = preload("res://scripts/mission/space_component_catalog.gd")
func owner():
 var result = COMBAT.new()
 var stats = CATALOG.effective_stats("buccaneer", CATALOG.default_loadout("buccaneer"))
 for spec in [["a",Vector2i.ZERO], ["b",Vector2i(4,0)]]:
  var f = FLIGHT.new()
  assert(f.configure(spec[0], {"position_plane":HEX.axial_to_plane(Vector2(spec[1])), "motion_mode":"tactical"}).ok)
  assert(result.admit_actor({"craft_id":spec[0], "start_hex":spec[1], "faction_id":"blue", "control_domain":"player", "footprint_hexes":[Vector2i.ZERO]}, f).ok)
  assert(result.bind_ship_systems(spec[0], stats, 50.0).ok)
 return result
func _initialize() -> void:
 var source = owner()
 if not source.has_method("export_systems_checkpoint"):
  printerr("systems checkpoint unavailable")
  quit(1)
  return
 var weapon: Dictionary = source.get_ship_systems("a").stats.weapons[0]
 var shot := {"id":"shot_1", "shooter_id":"a", "hit_craft_id":"b", "weapon_slot":weapon.slot_id, "damage":weapon.damage}
 assert(source._commit_ship_impact(shot).ok)
 var saved: Dictionary = JSON.parse_string(JSON.stringify(source.export_systems_checkpoint()))
 var target = owner()
 var original: Dictionary = target.get_ship_systems("a")
 var codec = load("res://scripts/mission/checkpoint_value_codec.gd")
 var bad := saved.duplicate(true)
 var data: Dictionary = codec.decode_value(bad.payload).value
 data.systems.a.state.hull = -1
 bad.payload = codec.encode_value(data).value
 assert(not target.prepare_systems_checkpoint_restore(bad).ok)
 assert(target.get_ship_systems("a") == original)
 bad = saved.duplicate(true)
 data = codec.decode_value(bad.payload).value
 data.systems.a.state.hull_capacity = 999.0
 bad.payload = codec.encode_value(data).value
 assert(not target.prepare_systems_checkpoint_restore(bad).ok)
 assert(target.get_ship_systems("a") == original)
 var prepared: Dictionary = target.prepare_systems_checkpoint_restore(saved)
 assert(prepared.ok and target.get_ship_systems("a") == original)
 if not target.has_method("validate_systems_checkpoint_restore"):
  printerr("systems validation API absent")
  quit(1)
  return
 assert(target.validate_systems_checkpoint_restore(prepared.prepared).ok)
 assert(target.commit_systems_checkpoint_restore(prepared.prepared).ok)
 assert(target.get_ship_systems("a").state == source.get_ship_systems("a").state)
 assert(target.get_ship_systems("b").state == source.get_ship_systems("b").state)
 var before_replay: Dictionary = target.get_ship_systems("b")
 assert(target._commit_ship_impact(shot).get("replayed", false))
 assert(target.get_ship_systems("b") == before_replay)
 assert(not target.commit_systems_checkpoint_restore(prepared.prepared).ok)
 print("SPACE_SYSTEMS_CHECKPOINT_PASS")
 quit(0)
