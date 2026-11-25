extends Node
## Nur Darstellung: zeichnet je Schiffstyp einmal das vorhandene Modell von oben (orthografisch, transparent) in eine
## Textur und merkt sie sich. Kopflos (kein Bildschirmbild) oder bei fehlendem Modell gibt es keine Textur; die
## Orbit-Karte zeichnet dann das alte Zeichen.
const SHIP_VISUALS = preload("res://scripts/terrain/frontier_ship_visuals.gd")
const TEXTURE_SIZE := 256
## Sichtbare Kantenlaenge der Aufnahme in Modelleinheiten (Meter laut Katalog-Maessen); die Nase zeigt im Bild nach oben.
const ORTHO_SIZE := 20.0
## Ein Hexfeld entspricht der Laenge des laengeren der beiden kleinen Schiffe (Entermesser/Cutlass, 16 m).
const HEX_LENGTH_UNITS := 16.0
const MODEL_ASSETS := {"cutlass": "cutlass_01", "buccaneer": "buccaneer_01"}
signal sprite_ready(model_id: String)
static var _textures: Dictionary = {}
static var _failed: Dictionary = {}
var _pending: Dictionary = {}

## Laenge des Modells in Metern (Modelleinheiten) aus dem Katalog; 0, wenn der Typ unbekannt ist.
static func length_units(model_id: String) -> float:
	if not MODEL_ASSETS.has(model_id): return 0.0
	var size: Variant = SHIP_VISUALS.get_ship(String(MODEL_ASSETS[model_id])).get("bounds_size")
	return float(size[2]) if size is Array and size.size() == 3 else 0.0

## Felder in der Laenge, auf ganze Felder gerundet, mindestens 1; 0 = Typ unbekannt.
static func fields_for(model_id: String) -> int:
	var length := length_units(model_id)
	return 0 if length <= 0.0 else maxi(1, roundi(length / HEX_LENGTH_UNITS))

func get_sprite(model_id: String) -> Texture2D:
	if _textures.has(model_id): return _textures[model_id]
	if not _failed.has(model_id) and not _pending.has(model_id) and MODEL_ASSETS.has(model_id): _render(model_id)
	return null

func _render(model_id: String) -> void:
	if DisplayServer.get_name() == "headless" or not is_inside_tree(): _failed[model_id] = true; return
	var path := String(SHIP_VISUALS.get_ship(String(MODEL_ASSETS[model_id])).get("model_path", ""))
	if path.is_empty() or not ResourceLoader.exists(path): _failed[model_id] = true; return
	var scene := load(path) as PackedScene
	if scene == null: _failed[model_id] = true; return
	_pending[model_id] = true
	var viewport := SubViewport.new()
	viewport.size = Vector2i(TEXTURE_SIZE, TEXTURE_SIZE)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = ORTHO_SIZE
	viewport.add_child(camera)
	camera.look_at_from_position(Vector3(0, 30, 0), Vector3.ZERO, Vector3(0, 0, 1))
	var light := DirectionalLight3D.new()
	light.light_energy = 1.2
	viewport.add_child(light)
	light.look_at_from_position(Vector3(4, 20, -6), Vector3.ZERO, Vector3.UP)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.8, 0.85, 0.9)
	environment.ambient_light_energy = 0.8
	camera.environment = environment
	var model := scene.instantiate() as Node3D
	if model == null: viewport.free(); _pending.erase(model_id); _failed[model_id] = true; return
	viewport.add_child(model)
	# Modellmitte auf den Bildmittelpunkt (Grundflaeche laut Katalog).
	var bounds: Variant = SHIP_VISUALS.get_ship(String(MODEL_ASSETS[model_id]))
	var bmin: Variant = bounds.get("bounds_min"); var bsize: Variant = bounds.get("bounds_size")
	if bmin is Array and bsize is Array and bmin.size() == 3 and bsize.size() == 3:
		model.position = -Vector3(float(bmin[0]) + float(bsize[0]) * 0.5, 0.0, float(bmin[2]) + float(bsize[2]) * 0.5)
	add_child(viewport)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	_pending.erase(model_id)
	if image == null or image.is_empty(): _failed[model_id] = true; return
	_textures[model_id] = ImageTexture.create_from_image(image)
	sprite_ready.emit(model_id)
