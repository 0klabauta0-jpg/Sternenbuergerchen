extends SceneTree
const EDITOR = preload("res://scripts/editor/map_editor.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var editor = EDITOR.new()
	var image := Image.create(4,4,false,Image.FORMAT_RGB8)
	image.fill(Color.RED)
	var texture: Texture2D = editor.call("_get_thumbnail_palette_preview_texture", ImageTexture.create_from_image(image), "rgb_fixture")
	var result := texture.get_image()
	var center := result.get_pixel(result.get_width()/2,result.get_height()/2)
	var passed := center.r > .9 and center.a > .9
	print("EDITOR_RGB_PREVIEW ", "PASS" if passed else "FAIL")
	editor.free()
	quit(0 if passed else 1)
