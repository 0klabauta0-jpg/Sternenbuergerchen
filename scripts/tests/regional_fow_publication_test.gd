extends SceneTree
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
class Probe extends "res://scripts/terrain/terrain_map_3d_view.gd":
 var surface_queries:int=0
 func _get_fow_surface_overlay_transform(tile_data)->Transform3D:
  surface_queries+=1
  return super._get_fow_surface_overlay_transform(tile_data)
var passed:=0
var failed:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String)->void:
 print("PASS: " if ok else "FAIL: ",label)
 if ok:passed+=1
 else:failed+=1
func capture(view:Node)->Dictionary:
 return {"tiles":view.get("_fow_overlay_render_tiles").duplicate(),"ids":view.get("_fow_overlay_render_tile_ids").duplicate(),"lookup":view.get("_fow_overlay_tile_by_id").duplicate(),"min":view.get("_fow_overlay_safety_min"),"max":view.get("_fow_overlay_safety_max"),"blackout_y":view.get("_fow_overlay_cached_blackout_y")}
func run():
 var view=Probe.new();root.add_child(view);view.set_process(false)
 if not view.has_method("_cache_fow_overlay_regional_chunks"):
  check(false,"Regional publication reuses per-chunk metadata")
  view.free();print("REGIONAL_FOW_PUBLICATION %d passed, %d failed"%[passed,failed]);quit(1);return
 var map=MAP.load_from_file("res://maps/trade_outpost.json")
 view.configure_from_map(map)
 var chunks:Dictionary=view.get("_visual_streaming_active_chunks").duplicate()
 var tiles:Array=[]
 for chunk in chunks:tiles.append_array(view.get("_regional_tiles_by_chunk")[chunk])
 check(chunks.size()>1 and tiles.size()>512,"Real512x256B subset spans multiple chunks and overlay slices")
 var cache:Dictionary=view.get("_regional_fow_render_cache")
 check(cache.size()==view.get("_regional_chunk_nodes").size(),"Every resident chunk has its matching static metadata")
 view.surface_queries=0
 view.call("_cache_fow_overlay_regional_chunks",chunks)
 var reused:Dictionary=capture(view)
 check(view.surface_queries==0,"Warm publication performs zero per-tile surface geometry queries")
 view.call("_cache_fow_overlay_render_tiles",tiles)
 var oracle:Dictionary=capture(view)
 check(view.surface_queries==tiles.size(),"Uncached independent publication still visits every source tile")
 check(reused==oracle,"Cached publication exactly matches full ordered IDs, lookups, safety bounds and blackout height")
 var id:String=reused.ids[0]
 view.set_fog_of_war_state({"mode":"unexplored_blackout","team_id":"team_alpha","visibility_revision":1,"terrain_knowledge":{"visible_tile_ids":PackedStringArray([id]),"explored_tile_ids":PackedStringArray()}})
 check(is_instance_valid(view.get("_fow_overlay_safety_cover")),"Unexplored publication retains protective blackout until overlay completes")
 view.set_fog_of_war_state({"mode":"unexplored_blackout","team_id":"team_alpha","visibility_revision":2,"terrain_knowledge":{"visible_tile_ids":PackedStringArray(),"explored_tile_ids":PackedStringArray([id])}})
 for index in range(32):
  if not view.get("_fow_overlay_full_rebuild_pending"):break
  view.call("_process_pending_fow_overlay_full_rebuild")
 check(not view.get("_fow_overlay_full_rebuild_pending") and String(view.get("_fow_overlay_tile_states_by_id").get(id,""))=="explored","Latest FoW knowledge wins while cached geometry overlay is prepared")
 check(int(view.get("_fow_overlay_visibility_revision"))==2,"Current visibility revision remains authoritative")
 var chunk:Vector2i=chunks.keys()[0]
 view.call("_remove_regional_chunk",chunk)
 check(not view.get("_regional_fow_render_cache").has(chunk),"Retiring chunk also releases metadata")
 var tile=view.get("_regional_tiles_by_chunk")[chunk][0]
 var old_height:int=tile.height_level;tile.height_level=50
 view.surface_queries=0;view.call("_build_regional_chunk",chunk)
 check(view.surface_queries>0,"Recreated chunk rebuilds metadata from current source geometry")
 view.call("_cache_fow_overlay_regional_chunks",chunks)
 check(float(view.get("_fow_overlay_cached_blackout_y"))>float(oracle.blackout_y),"Recreated chunk publishes changed height instead of stale cached blackout")
 tile.height_level=old_height
 var replacement=MAP.create_empty("publication_replacement",Vector2i(4,4),Vector2.ZERO)
 view.configure_from_map(replacement)
 check(view.get("_regional_fow_render_cache").is_empty(),"Map replacement clears every old regional metadata entry")
 check(view.get("_fow_overlay_render_tile_ids").size()==16,"Map replacement uses only replacement terrain")
 view.free()
 print("REGIONAL_FOW_PUBLICATION %d passed, %d failed"%[passed,failed]);quit(0 if failed==0 else 1)
