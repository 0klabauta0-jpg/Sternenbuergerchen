extends "res://scripts/tests/hex_admission_slots_verifier.gd"

const PHASE_PATH="res://scripts/mission/hex_ground_deployment_adapter.gd"

func _finish()->void:
	if failed==0:
		_test_group_admission()
		_test_admission_ramps()
		_test_active_edge_admission()
		_test_phased_deployment()
		_test_staged_actor_and_terrain()
		_test_stale_lifecycle_queue()
		_test_actual_despawn()
		_test_stale_registry_entry()
		_test_pending_group_cleanup()
		_test_registry_only_actor()
	_check(ResourceLoader.exists(PHASE_PATH),"existing unload sequence can use a Root-confirmed phase bridge")
	if failed==0:_test_phase_bridge()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_DEPLOYMENT_PHASE_PASS")
	quit(0 if failed==0 else 1)

func _test_phase_bridge()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)])
	var actors:Array=[]
	for id in ["first","second"]:
		var actor:Node2D=_add_admission_actor(rig,id)
		actor.set_meta("dropship_embarked",true)
		actor.visible=false
		actors.append(actor)
	var sequence:Dictionary={"units":actors,"unit_index":0}
	var bridge=load(PHASE_PATH).new()
	var queued:Dictionary=bridge.advance_phase(rig.sim,sequence,Vector2.ZERO)
	_check(queued.phase=="queued" and sequence.unit_index==0 and rig.sim.get_hex_ground_planning_snapshot().units_by_id.is_empty(),"enqueueing unload never publishes deployment before Root commit")
	var count:int=rig.sim.effects_queue.size()
	var waiting:Dictionary=bridge.advance_phase(rig.sim,sequence,Vector2.ZERO)
	_check(waiting.phase=="waiting" and rig.sim.effects_queue.size()==count,"render polling never duplicates a pending unload effect")
	rig.sim._physics_process(0.1)
	var admission_id:String=String(sequence.hex_admission.admission_id)
	rig.sim.enqueue_command(_command("first",rig.terrain.grid_to_world(Vector2i(0,1))))
	for i in range(16):rig.sim._physics_process(0.1)
	_check(rig.sim.get_hex_unit_state("first").grid==Vector2i(0,1),"fixture person can move away before controller reads its unload completion")
	var committed:Dictionary=bridge.advance_phase(rig.sim,sequence,Vector2.ZERO)
	_check(committed.phase=="committed" and committed.unit_id=="first" and committed.admission_id==admission_id and sequence.unit_index==0,"commit receipt survives movement without letting bridge own sequence progress")
	sequence.unit_index=1
	var next:Dictionary=bridge.advance_phase(rig.sim,sequence,Vector2.ZERO)
	_check(next.phase=="queued" and rig.sim.get_hex_unit_state("second").is_empty(),"next unload phase retains its independently reserved slot")
	rig.sim._physics_process(0.1)
	var second:Dictionary=bridge.advance_phase(rig.sim,sequence,Vector2.ZERO)
	_check(second.phase=="committed" and second.unit_id=="second" and rig.sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.is_empty(),"last real effect confirms completion after ticket slots are fully consumed")
	sequence.unit_index=2
	_check(bridge.advance_phase(rig.sim,sequence,Vector2.ZERO).phase=="complete","existing sequence owner determines end of unloading")
	rig.scene.free()
