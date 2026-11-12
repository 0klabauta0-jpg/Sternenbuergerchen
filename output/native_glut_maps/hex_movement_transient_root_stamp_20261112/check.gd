extends SceneTree
const SIM=preload("res://scripts/core/simulation_root.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const UNITS=preload("res://scripts/registries/unit_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
var passed:=0
var failed:=0
class Actor extends Node2D:
 var unit_id:="actual"
 var current_command:RefCounted
 var target_position:Vector2
 func get_unit_id()->String:return unit_id
 func get_team_id()->String:return "blue"
 func get_vital_state()->String:return "fit"
 func assign_unit_command(value):current_command=value
 func get_current_unit_command():return current_command
 func set_target_position(value):target_position=value
 func get_target_position()->Vector2:return target_position
 func get_move_speed_factor()->float:return 1.0
 func get_combat_speed_multiplier()->float:return 1.0
 func refresh_terrain_readability()->void:pass
 func get_health()->int:return 100
func check(ok:bool,label:String)->void:
 if ok:passed+=1
 else:failed+=1
 print("PASS " if ok else "FAIL ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var holder=Node.new();root.add_child(holder)
 var terrain=REGISTRY.new();terrain.name="Terrain";holder.add_child(terrain);terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
 for q in range(6):
  for r in range(2):terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[q,r],"grid_position":Vector2i(q,r)}))
 var units=UNITS.new();units.name="Units";holder.add_child(units)
 var sim=SIM.new();sim.unit_registry_path=NodePath("../Units");sim.terrain_registry_path=NodePath("../Terrain");holder.add_child(sim);sim.set_physics_process(false);sim.set_process(false)
 var map=MAP.create_empty("root-stamp",Vector2i(6,2),Vector2.ZERO,64,32,3,"hex_axial_v1");map.set_tactical_grid_rules("hex_tactical_v1");sim.configure_hex_ground_runtime(map,terrain)
 var actor=Actor.new();holder.add_child(actor);units.register_unit("actual",actor);sim.register_known_unit("actual",actor)
 var placements:Array[Dictionary]=[{"unit_id":"actual","grid":Vector2i.ZERO}];assert(sim.admit_hex_ground_units(placements).ok)
 var command:Dictionary={"type":"move_to_position","unit_id":"actual","team_id":"blue","target_position":terrain.grid_to_world(Vector2i(4,0))+Vector2(0.125,0.0625),"command_token":"root-source","move_speed_factor":1.0}
 sim.enqueue_command(command);sim._physics_process(0.1)
 var movement=sim._hex_movement_runtime
 var stored:Dictionary=movement._orders.actual.command
 check(stored.has("_hex_lifecycle") and sim._is_current_hex_payload(stored) and not command.has("_hex_lifecycle"),"Actual Root enqueue stamps real accepted movement without changing input")
 var stamp:Dictionary=stored._hex_lifecycle.duplicate(true)
 var state:Dictionary=movement.export_state()
 check(state.get("schema")=="hex_movement_v1","Actual Root-generated lifecycle command exports canonically")
 if failed:holder.free();finish();return
 var omitted:=true
 for field in state.accepted_intents[0].command_intent:
  if field.key=="_hex_lifecycle":omitted=false
 check(omitted and stored._hex_lifecycle==stamp,"Portable intent omits only validated transient marker without mutating live command")
 stored._hex_lifecycle.context+=1
 check(movement.export_state().get("reason")=="movement_save_stale_lifecycle","Stale actual Root stamp rejects instead of being silently discarded")
 stored._hex_lifecycle=stamp.duplicate(true);stored._hex_lifecycle.extra=true
 check(movement.export_state().get("reason")=="movement_save_invalid_lifecycle","Unknown lifecycle stamp keys reject strict shape")
 stored._hex_lifecycle=stamp.duplicate(true);stored._hex_lifecycle.actor=float(stamp.actor)
 check(movement.export_state().get("reason")=="movement_save_invalid_lifecycle","Portable numeric coercion cannot masquerade as live ObjectID")
 stored._hex_lifecycle=stamp.duplicate(true);stored._unknown_host_marker={"actor":actor.get_instance_id()}
 check(movement.export_state().get("reason")=="movement_save_unsupported_command_field","Unrecognized host marker remains rejected")
 stored.erase("_unknown_host_marker")
 var prepared:Dictionary=movement.prepare_restore_state(JSON.parse_string(JSON.stringify(state)));assert(prepared.ok)
 check(movement.publish_prepared_restore(prepared.prepared).get("ok",false) and not movement._orders.actual.command.has("_hex_lifecycle") and movement._orders.actual.source_command_id=="root-source","Restore keeps canonical intent unstamped and preserves true SourceID")
 command.command_token="next-source";sim.enqueue_command(command)
 var newest:Dictionary=sim.command_queue.back()
 check(newest.has("_hex_lifecycle") and newest._hex_lifecycle==sim._hex_payload_identity("actual") and sim._is_current_hex_payload(newest),"Later real Root enqueue creates fresh inprocess stamp itself")
 holder.free();finish()
func finish()->void:
 print("HEX_MOVEMENT_TRANSIENT_ROOT_STAMP passed=",passed," failed=",failed)
 quit(0 if failed==0 else 1)
