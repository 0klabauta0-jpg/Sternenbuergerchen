extends SceneTree
func _initialize() -> void:
 for i in range(45,49):
  var texture: Texture2D = load("res://Assets/curated/portraits/frontier_20261105/portraits/char_portrait_%03d.tres" % i)
  if texture == null or texture.get_width() != 627 or not texture is AtlasTexture or texture.atlas == null or texture.atlas.get_width() <= 0:
   printerr("native asset texture failed ", i)
   quit(1)
   return
 var tile = load("res://scripts/terrain/terrain_tile_data.gd").new()
 var importer = load("res://scripts/editor/map_builder_scene_importer.gd").new()
 var warnings: Array[String] = []
 importer.call("_apply_authoring_overrides",tile,{"height_level":7},"",{},warnings)
 if tile.height_level != 7:
  printerr("native importer clipped authored H7")
  quit(1)
  return
 print("NATIVE_JOIN_IMPORTED_RESOURCES_PASS portraits=4 height=7")
 quit(0)
