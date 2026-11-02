extends SceneTree
const PREVIEW = preload("res://scenes/tests/frontier_art_preview.tscn")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var preview = PREVIEW.instantiate()
 root.add_child(preview)
 var view = preview.get("_view")
 view.call("_request_viewport_redraw",true,60000)
 for id in ["ground_detail","landscape","closed_hall","closed_habitat","geology_detail"]:
  preview.call("_camera_view",{"closed_hall":"workshop","closed_habitat":"cutaway"}.get(id,id))
  view.call("_request_viewport_redraw",true,60000)
  for i in range(15):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://output/grafik_20261101/pass06_probe_%s.png"%id)
 preview.free()
 await process_frame
 quit()
