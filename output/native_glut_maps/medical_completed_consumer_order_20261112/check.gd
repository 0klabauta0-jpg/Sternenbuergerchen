extends "res://scripts/tests/hex_respawn_verifier.gd"

class ConsumerDriver extends "res://scripts/tests/mission_combat_loop_driver.gd":
	var broadcast_events:Array=[]
	func _ready()->void:
		set_process(false)
		set_physics_process(false)
	func _update_event_label()->void:pass
	func _update_status_label(_state:String)->void:pass
	func _broadcast_remote_event(event_text:String,_id:String="",_color:Color=Color.WHITE,_seconds:float=1.0,_unit_text:String="")->void:
		broadcast_events.append(event_text)

func _initialize()->void:call_deferred("consumer_repro")
func _run()->void:pass # Inherited fixture constructor must not launch its suites.
func consumer_repro()->void:
	var r:Dictionary=_medical_rig()
	var driver=ConsumerDriver.new()
	r.scene.add_child(driver)
	var order:Array=[]
	var proof:Dictionary={"medical":false,"linger_before":false,"linger_after":false}
	r.actors.a.vital_status_changed.connect(Callable(driver,"_on_unit_vital_status_changed").bind(r.actors.a))
	r.actors.a.apply_damage(1000)
	assert(r.manager.request_respawn("a","blue"))
	var ticket:String=r.manager._pending_respawns.a.hex_ticket
	# Earlier subscriber performs real damage; Driver's actual callback runs second.
	r.manager.unit_respawn_completed.connect(func(id:String):
		order.append("first_subscriber")
		proof.medical=r.sim.get_hex_respawn_receipt(ticket).status=="committed" and r.actors.a.get_vital_state()=="fit" and r.sim.get_hex_unit_state(id).grid==Vector2i(2,0)
		r.actors.a.apply_damage(1000,{"source_unit_id":"actual_subscriber"})
		proof.linger_before=driver._down_state_started_msec_by_unit_id.has(id))
	r.manager.unit_respawn_completed.connect(func(id:String):
		order.append("driver")
		driver._on_unit_respawn_completed(id)
		proof.linger_after=driver._down_state_started_msec_by_unit_id.has(id))
	r.manager._physics_process(30.0)
	r.sim._physics_process(0.1)
	var reproduced:bool=proof.medical and proof.linger_before and not proof.linger_after and r.actors.a.get_vital_state()=="down" and driver._last_event_text=="a RESPAWN READY" and order==["first_subscriber","driver"]
	print("MEDICAL_COMPLETED_CONSUMER_ORDER ",JSON.stringify({"reproduced":reproduced,"proof":proof,"order":order,"vital":r.actors.a.get_vital_state(),"event":driver._last_event_text,"broadcasts":driver.broadcast_events}))
	r.scene.free()
	if reproduced:print("MEDICAL_COMPLETED_CONSUMER_RED_REPRODUCED")
	quit(0 if reproduced else 1)
