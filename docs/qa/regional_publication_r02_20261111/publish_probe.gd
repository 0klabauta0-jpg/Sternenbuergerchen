extends SceneTree
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
class Probe extends "res://scripts/terrain/terrain_map_3d_view.gd":
 var spans:Dictionary={}
 func _cache_fow_overlay_render_tiles(tiles:Array)->void:
  var t=Time.get_ticks_usec();super._cache_fow_overlay_render_tiles(tiles);spans["cache_usec"]=Time.get_ticks_usec()-t
 func _rebuild_fog_of_war_visuals()->void:
  var t=Time.get_ticks_usec();super._rebuild_fog_of_war_visuals();spans["rebuild_usec"]=Time.get_ticks_usec()-t
 func _create_fow_overlay_multimesh()->void:
  var t=Time.get_ticks_usec();super._create_fow_overlay_multimesh();spans["create_mesh_usec"]=Time.get_ticks_usec()-t
func _initialize():call_deferred("run")
func run():
 var map=MAP.load_from_file("res://maps/trade_outpost.json")
 var view=Probe.new();root.add_child(view);await process_frame;view.set_process(false)
 view.configure_from_map(map)
 view.set_fog_of_war_state({"mode":"known_terrain","team_id":"team_alpha","terrain_knowledge":{"visible_tile_ids":PackedStringArray(),"explored_tile_ids":PackedStringArray()},"visibility_revision":1})
 var rows:Array=[]
 var chunks:Dictionary=view.get("_visual_streaming_active_chunks")
 var tiles:Array=[]
 for chunk in chunks:tiles.append_array(view.get("_regional_tiles_by_chunk")[chunk])
 for index in range(5):
  view.spans.clear();view._cache_fow_overlay_render_tiles(tiles);view._rebuild_fog_of_war_visuals()
  var row=view.spans.duplicate();row["tile_count"]=tiles.size();row["chunk_count"]=chunks.size();rows.append(row)
 print("REGIONAL_PUBLISH_DIAG ",JSON.stringify(rows))
 FileAccess.open("res://output/native_glut_maps/regional_publication_r02/baseline_diagnostic.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
 view.free();quit()
