extends SceneTree
## Rendert eine Ruestung in vier Ansichten (vorne, hinten, seite, oben) plus Spielmassstab.
## Braucht ein (virtuelles) Fenster, nicht --headless.
## Aufruf: g.sh <wt> 300 --script res://scripts/tests/ruestung_ansichten_capture.gd -- <armor_id> <ausgabeordner> [front_yaw_grad]
## Echter Einheiten-Proxy (TerrainMap3DView._create_unit_proxy), Idle-Animation bei 0,2 s, ortho Kamera,
## Hintergrund 0,8 grau, Umgebungslicht plus schwaches Richtungslicht, kein Schatten. Siehe
## docs/tasks/RUESTUNG_SCHWER_VERGLEICH_2026_11_15.md Abschnitt 2.
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const WINDOW := Vector2i(640, 960)
const FIGURE_FILL := 0.85
var _camera: Camera3D
var _figure: Node3D
func _initialize() -> void:
	call_deferred("run")
func _collect_bounds(node: Node, boxes: Array) -> void:
	if node is MeshInstance3D and node.mesh != null and (node as Node3D).is_visible_in_tree():
		boxes.append(node.global_transform * node.get_aabb())
	for child: Node in node.get_children():
		_collect_bounds(child, boxes)
func _set_extras_visible(show_weapon: bool) -> void:
	for node: Node in _figure.find_children("BlasterVisual_*", "Node3D", true, false):
		(node as Node3D).visible = show_weapon
	for child: Node in _figure.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh is CylinderMesh:
			(child as MeshInstance3D).visible = false
func _shot(path: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("CAPTURED ", path)
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var armor_id: String = args[0] if args.size() > 0 else "heavy"
	var out: String = args[1] if args.size() > 1 else "/tmp/ansichten"
	var front_yaw: float = float(args[2]) if args.size() > 2 else 90.0
	DirAccess.make_dir_recursive_absolute(out)
	root.size = WINDOW
	root.content_scale_size = WINDOW
	root.transparent_bg = false
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.8, 0.8, 0.8)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	light.light_energy = 0.35
	light.shadow_enabled = false
	root.add_child(light)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.near = 0.05
	_camera.far = 200.0
	root.add_child(_camera)
	_camera.current = true
	var resolver: Node = VIEW.new()
	var actor: Node = load("res://scripts/npc/test_unit.gd").new()
	actor.unit_id = "ansicht_0"
	actor.team_id = "team_alpha"
	actor.armor_id = armor_id
	actor.portrait_path = load("res://scripts/meta/portrait_identity_catalog.gd").resolve_path("char_portrait_001")
	root.add_child(actor)
	_figure = resolver.call("_create_unit_proxy", actor)
	root.add_child(_figure)
	var idle := _figure.find_child("UnitVisualAnimationPlayer", true, false) as AnimationPlayer
	if idle != null and idle.has_animation("idle"):
		idle.play("idle")
		idle.advance(0.2)
		idle.pause()
	_figure.rotation_degrees.y = front_yaw
	_set_extras_visible(false)
	for i in 6: await process_frame
	var boxes: Array = []
	_collect_bounds(_figure, boxes)
	var bounds: AABB = boxes[0]
	for box: AABB in boxes:
		bounds = bounds.merge(box)
	var center := bounds.get_center()
	var height := bounds.size.y
	print("BOUNDS ", bounds)
	_camera.size = height / FIGURE_FILL
	var dist := 40.0
	# vorne: Kamera auf +Z, Figur blickt nach +Z (front_yaw)
	_camera.position = center + Vector3(0, 0, dist)
	_camera.look_at(center, Vector3.UP)
	await _shot(out + "/vorne.png")
	_figure.rotation_degrees.y = front_yaw + 180.0
	await _shot(out + "/hinten.png")
	_figure.rotation_degrees.y = front_yaw + 270.0 # blickt nach -X = links im Bild
	await _shot(out + "/seite.png")
	_figure.rotation_degrees.y = front_yaw
	_camera.position = center + Vector3(0, dist, 0)
	_camera.look_at(center, Vector3(0, 0, -1))
	_camera.size = maxf(bounds.size.x, bounds.size.z) / FIGURE_FILL * 1.2
	await _shot(out + "/oben.png")
	# Spielmassstab: Yaw 45 / Pitch 40, Figur etwa 70 px hoch, mit Waffe. Die Figur blickt zur Kamera-Diagonale.
	_set_extras_visible(true)
	_figure.rotation_degrees.y = front_yaw
	var yaw := deg_to_rad(45.0)
	var pitch := deg_to_rad(40.0)
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	_camera.position = center + dir * dist
	_camera.look_at(center, Vector3.UP)
	_camera.size = height * WINDOW.y / 70.0
	await _shot(out + "/spielmassstab.png")
	quit(0)
