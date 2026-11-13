extends PanelContainer
## Read-only combat projection; inputs go to the campaign runtime adapter.
var _runtime: Node
var _status: Label
var _attack: Button
var _rescue: Button
var _retreat: Button
var _clock:=0.0
var _visuals: Array[Node3D]=[]
func configure(runtime: Node) -> void:
	_runtime=runtime
	position=Vector2(24,120); custom_minimum_size=Vector2(460,340)
	var box:=VBoxContainer.new(); add_child(box)
	var heading:=Label.new(); heading.text="Notruf im Orbit"; box.add_child(heading)
	_status=Label.new(); _status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; _status.custom_minimum_size=Vector2(450,90); box.add_child(_status)
	var container:=SubViewportContainer.new(); container.custom_minimum_size=Vector2(450,170); container.stretch=true; box.add_child(container)
	var viewport:=SubViewport.new(); viewport.size=Vector2i(450,170); viewport.own_world_3d=true; viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE; container.add_child(viewport)
	var scene:=Node3D.new(); viewport.add_child(scene)
	var camera:=Camera3D.new(); camera.position=Vector3(0,20,30); camera.look_at_from_position(camera.position,Vector3.ZERO); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=45; scene.add_child(camera)
	var light:=DirectionalLight3D.new(); light.rotation_degrees=Vector3(-45,-30,0); light.light_energy=2; scene.add_child(light)
	for index in range(2):
		var ship:=Node3D.new(); scene.add_child(ship); ship.position.x=-12 if index==0 else 12
		var path:="res://Assets/curated/frontier_illustrated_20261101/ships_pass04_r02/"+("cutlass_01.glb" if index==0 else "buccaneer_01.glb")
		var packed=load(path)
		if packed is PackedScene: ship.add_child(packed.instantiate())
		_visuals.append(ship)
	_attack=_button(box,"Feindliche Cutlass angreifen","campaign_space_engage")
	_rescue=_button(box,"Buccaneer bergen / Pilot kontaktieren","campaign_space_rescue")
	_retreat=_button(box,"Gefecht abbrechen","campaign_space_retreat")
	refresh()
func _button(box:Node,text:String,operation:String) -> Button:
	var button:=Button.new(); button.text=text; button.custom_minimum_size.y=36
	button.pressed.connect(func(): _runtime.call("request_operation",operation,{}); refresh())
	box.add_child(button); return button
func _process(delta:float) -> void:
	_clock+=delta
	if _clock<0.15:return
	_clock=0; refresh()
func refresh() -> void:
	if not is_instance_valid(_runtime):
		hide()
		return
	var state:Dictionary=_runtime.call("get_space_encounter_snapshot")
	visible=not state.is_empty() and not bool(state.get("resolved", false))
	if not visible:return
	if String(state.get("phase", "")) in ["aborted", "defeat", "victory"]:
		_status.text = "Begegnung beendet · Rückkehr in den Orbit läuft"
		_status.tooltip_text = "Eine verzögerte Rückkehr wird automatisch erneut versucht."
		_attack.disabled = true; _rescue.disabled = true; _retreat.disabled = true
		return
	if state.phase == "entering":
		var feedback: Dictionary = _runtime.call("get_campaign_entry_feedback") if _runtime.has_method("get_campaign_entry_feedback") else {}
		_status.text = "Kampfbereich wird vorbereitet" if feedback.is_empty() or feedback.get("ok", false) else "Kampfbereich noch nicht bereit · Abbruch möglich"
		_status.tooltip_text = ""
		_attack.disabled = true; _rescue.disabled = true; _retreat.disabled = false
		return
	_status.text="Cutlass · FEINDLICH · Hülle %d\nBuccaneer · NEUTRAL · Hülle %d\nEigenes Schiff · Hülle %d\n%s" % [int(state.cutlass_hull),int(state.buccaneer_hull),int(state.player_hull),"Feind zerstört. Pilot kontaktieren." if state.phase=="rescue_ready" else "Feuergefecht läuft." if state.engaging else "Die Buccaneer braucht Hilfe!"]
	_attack.disabled=state.phase!="combat" or bool(state.engaging)
	_rescue.disabled=state.phase!="rescue_ready"
	_retreat.disabled=false
	for index in _visuals.size():
		_visuals[index].position.z=sin(float(state.seconds)*0.5+index*2)*2
