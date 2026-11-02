extends SceneTree
const PREVIEW = preload("res://scenes/tests/frontier_art_preview.tscn")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var preview = PREVIEW.instantiate()
 root.add_child(preview)
 preview.set_process(false)
 preview.get("_view").set_process(false)
 preview.get("_view").get_node("ViewportContainer/SubViewport").render_target_update_mode=SubViewport.UPDATE_ALWAYS
 preview.get("_sim").set_physics_process(false)
 for entry in preview.get("_crew"):
  if entry["player"]:entry["player"].pause()
 preview.call("_camera_view","outpost")
 var paint: MeshInstance3D = preview.get("_worklife").get_node("DustBanksAndCompactedApproaches")
 for enabled in [false,true]:
  paint.visible=enabled
  preview.get("_view").call("_request_viewport_redraw",true,60000)
  for i in range(12):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://output/grafik_20261101/contact_probe_%s.png"%str(enabled))
 quit()
