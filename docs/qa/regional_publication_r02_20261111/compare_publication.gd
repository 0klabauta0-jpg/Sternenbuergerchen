extends SceneTree
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const BEFORE=preload("res://output/native_glut_maps/regional_publication_r02/terrain_view_before.gd")
const AFTER=preload("res://output/native_glut_maps/regional_publication_r02/terrain_view_after.gd")
func _initialize():call_deferred("run")
func drain(view):
 while view.get("_fow_overlay_full_rebuild_pending"):view.call("_process_pending_fow_overlay_full_rebuild")
func run():
 var map=MAP.load_from_file("res://maps/trade_outpost.json")
 var views:Array=[];var plans:Array=[]
 for script in [BEFORE,AFTER]:
  var v=script.new();root.add_child(v);v.set_process(false);v.configure_from_map(map)
  v.set_fog_of_war_state({"mode":"known_terrain","team_id":"team_alpha","visibility_revision":1,"terrain_knowledge":{"visible_tile_ids":PackedStringArray(),"explored_tile_ids":PackedStringArray()}})
  drain(v)
  var full:Dictionary=v.get("_visual_streaming_active_chunks").duplicate();var smaller=full.duplicate();smaller.erase(smaller.keys()[-1])
  views.append(v);plans.append([smaller,full])
 var rows:Array=[]
 # Alternate A/B order so ordinary warm-up/drift does not always favor one arm.
 for pair in range(12):
  for arm in ([0,1] if pair%2==0 else [1,0]):
   var v=views[arm];var next:Dictionary=plans[arm][pair%2]
   var start:int=Time.get_ticks_usec();v.call("_publish_regional_chunks",next);var elapsed:int=Time.get_ticks_usec()-start
   rows.append({"arm":"before" if arm==0 else "after","pair":pair,"publish_usec":elapsed,"chunks":next.size(),"tiles":v.get("_fow_overlay_render_tile_ids").size()})
   drain(v)
 for v in views:v.free()
 FileAccess.open("res://output/native_glut_maps/regional_publication_r02/paired_cpu.json",FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info(),"renderer":"headless_dummy","map_sha256":FileAccess.get_sha256("res://maps/trade_outpost.json"),"workload":"actual publication between107/108 cached realB chunks, latest known terrain;12alternating pairs;overlay fills outside timed call","rows":rows},"  "))
 print("REGIONAL_PUBLISH_PAIRED ",JSON.stringify(rows));quit()
