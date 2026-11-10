extends SubViewportContainer
## Read-only model projection using the same visual resolver as the tactical map.
const VISUALS = preload("res://scripts/terrain/terrain_map_3d_view.gd")
var _view:SubViewport
var _scene:Node3D
var _camera:Camera3D
var _model:Node3D
var _signature:String=""

func _ready()->void:
	name="PersonnelBodyPreview"
	custom_minimum_size=Vector2(90,150)
	stretch=true
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	_view=SubViewport.new();_view.size=Vector2i(320,480);_view.own_world_3d=true;_view.transparent_bg=true
	_view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	add_child(_view)
	_scene=Node3D.new();_view.add_child(_scene)
	_camera=Camera3D.new();_camera.projection=Camera3D.PROJECTION_ORTHOGONAL;_scene.add_child(_camera)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-25,0);light.light_energy=1.4;_scene.add_child(light)
	var environment:=WorldEnvironment.new();var settings:=Environment.new()
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color.WHITE;settings.ambient_light_energy=.7
	environment.environment=settings;_scene.add_child(environment)
	resized.connect(_render_once)
	visibility_changed.connect(_render_once)

func update_actor(actor:Node,loadout:Dictionary)->void:
	var signature:=str(actor.get_instance_id() if actor!=null else 0)+JSON.stringify(loadout)
	if signature==_signature:return
	_signature=signature
	if is_instance_valid(_model):_model.free()
	if actor==null:return
	var resolver:Node=VISUALS.new()
	_model=resolver.call("_create_unit_proxy",actor)
	resolver.free()
	_scene.add_child(_model)
	_model.process_mode=Node.PROCESS_MODE_DISABLED
	_model.rotation_degrees.y=90
	var idle:=_model.find_child("UnitVisualAnimationPlayer",true,false) as AnimationPlayer
	if idle!=null and idle.has_animation("idle"):
		idle.play("idle");idle.advance(0);idle.pause()
		set_meta("preview_idle_pose",true)
	var boxes:Array[AABB]=[]
	_collect_bounds(_model,boxes)
	if boxes.is_empty():return
	var bounds:AABB=boxes[0]
	for box:AABB in boxes:bounds=bounds.merge(box)
	var center:=bounds.get_center()
	_camera.position=center+Vector3(0,bounds.size.y*.06,maxf(bounds.size.y*2,2))
	_camera.look_at(center)
	_camera.size=maxf(bounds.size.y*1.16,bounds.size.x*1.8)
	set_meta("preview_unit_id",String(actor.call("get_unit_id")))
	set_meta("preview_uses_existing_model",bool(_model.get_meta("uses_kenney_model",false)))
	_render_once()

func _collect_bounds(node:Node,boxes:Array[AABB])->void:
	if node is MeshInstance3D and node.mesh!=null:
		boxes.append(node.global_transform*node.get_aabb())
	for child:Node in node.get_children():_collect_bounds(child,boxes)

func _render_once()->void:
	if _view!=null and is_visible_in_tree():_view.render_target_update_mode=SubViewport.UPDATE_ONCE
