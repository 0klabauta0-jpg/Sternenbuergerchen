extends "res://scripts/tests/review_completion_maps_capture.gd"
func run() -> void:
 output=OS.get_environment("SB_REVIEW_COMPLETION_CAPTURE_DIR")
 if output.is_empty() or OS.get_environment("SB_REVIEW2_USER_DIR").is_empty() or DisplayServer.get_name()=="headless": quit(2); return
 check(OS.get_user_data_dir().replace("\\","/")==OS.get_environment("SB_REVIEW2_USER_DIR").replace("\\","/"),"private profile")
 DirAccess.make_dir_recursive_absolute(output)
 root.size=Vector2i(1280,720);root.content_scale_size=root.size
 for id:String in ["Ground_Mission02_128x128","station_outpost_64x64","Ground_Mission01_32x32","trade_outpost","frontier_workyard_24x20"]:
  var terrain=MAP.load_from_file("res://maps/"+id+".json")
  var view=VIEW.new();root.add_child(view)
  view.configure_from_map(terrain,terrain.get_marker_position("objective_point"),26.0)
  view.set_authoring_markers_visible(false)
  await settle_map(view)
  await capture(id,{"source":"maps/"+id+".json","sha256":FileAccess.get_sha256("res://maps/"+id+".json"),"camera_size":26.0,"render":view.get_render_snapshot()})
  if id=="trade_outpost":
   view.focus_world_position(terrain.get_marker_position("trade_service"));view.set("_camera_size",22.0);view._update_camera_transform()
   await settle_map(view);await capture("trade_outpost_service_core",{"actual_map":id,"camera_size":22.0})
   view.focus_world_position(terrain.get_tile_at_grid(Vector2i(36,-3)).world_position);view._update_camera_transform()
   await settle_map(view);await capture("trade_outpost_local_hill",{"actual_map":id,"focus_grid":[36,-3],"camera_size":22.0})
  if id=="Ground_Mission01_32x32":
   view.focus_world_position(terrain.get_tile_at_grid(Vector2i(17,47)).world_position);view.set("_camera_size",22.0);view._update_camera_transform()
   await settle_map(view);await capture("gm01_landing_mesa",{"actual_map":id,"focus_grid":[17,47],"camera_size":22.0})
  view.queue_free();await frames()
 print("MAP_SERVICES_CAPTURE passed=%d failed=%d"%[passed,failed])
 quit(0 if failed==0 else 1)
