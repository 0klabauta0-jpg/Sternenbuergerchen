extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"
const REAL_ACTOR = preload("res://scripts/npc/test_unit.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const LIFECYCLE = preload("res://scripts/mission/stable_mission_lifecycle_checkpoint.gd")
const FIRETEAM_MOVE = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const DEPLOY = preload("res://scripts/mission/hex_ground_deployment_adapter.gd")
const TRANSPORT = preload("res://scripts/mission/transport_checkpoint.gd")
func _run() -> void:
	if not GUARD.require_isolated_user_data(): return
	_test_actual_security_command()
	await process_frame
	print("REVIEW_COMPLETION_COMMAND_SAVE passed=%d failed=%d" % [passed,failed])
	quit(1 if failed else 0)

func _test_actual_security_command() -> void:
	var rig := _admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0)])
	rig.sim.set_physics_process(false)
	var actor := REAL_ACTOR.new()
	actor.unit_id = "security_unit"
	actor.team_id = "blue"
	rig.scene.add_child(actor)
	rig.units.register_unit(actor.unit_id,actor)
	rig.sim.register_known_unit(actor.unit_id,actor)
	_check(rig.sim.admit_hex_ground_actor_group(PackedStringArray([actor.unit_id]),Vector2i.ZERO).get("ok",false),"actual post-drop actor has canonical Ground presence")
	var command = COMMAND.new()
	command.command_type = "move_to_position"
	command.priority = 13
	command.unit_id = actor.unit_id
	command.team_id = "blue"
	command.target_position = rig.terrain.grid_to_world(Vector2i(2,0))
	command.move_speed_factor = 0.68
	command.source_command_type = "hold_position"
	command.source_task_type = "post_drop_360_security"
	command.command_token = "post_drop_security:ft1:1:security_unit"
	command.phase = 1
	var payload: Dictionary = command.to_dict()
	payload.merge({"requeue_until_target":true,"security_mode":"360","security_radius_tiles":4,"facing_angle":0.81203121185303})
	var behavior: Dictionary = FIRETEAM_MOVE.get_behavior_stance_modifiers("take","normal")
	FIRETEAM_MOVE.new()._append_behavior_modifier_fields(payload,behavior)
	rig.sim.enqueue_command(payload)
	rig.sim._physics_process(0.1)
	var lifecycle := LIFECYCLE.new()
	_check(not lifecycle._command_is_stable(rig.sim,actor,actor.get_current_unit_command()),"in-flight security movement is not a stable lifecycle command")
	var exported: Dictionary = rig.sim.export_hex_checkpoint_state()
	_check(exported.get("ok",false),"actual accepted post-drop command exports all explicit producer fields: "+str(exported.get("reason","")))
	var accepted: Dictionary = rig.sim._hex_movement_runtime._orders[actor.unit_id].command
	_check(not accepted.has("behavior_command_type") and not accepted.has("take_doctrine_id") and accepted.move_speed_factor==0.68 and accepted.contact_initiative_seconds==payload.contact_initiative_seconds and accepted.engagement_range_policy==payload.engagement_range_policy,"actual behavior producer retains effective command semantics without duplicate diagnostic fields")
	if not exported.get("ok",false):
		rig.scene.free(); return
	var saved: Dictionary = JSON.parse_string(JSON.stringify(exported.state,"",true,true))
	for invalid in [["security_mode","invented"],["security_radius_tiles",-1],["security_radius_tiles",257],["security_radius_tiles",1.25],["facing_angle",TAU*3.0],["facing_angle","bad"]]:
		var corrupted: Dictionary = saved.duplicate(true)
		for field in corrupted.movement.accepted_intents[0].command_intent:
			if field.key==invalid[0]: field.value=invalid[1]
		var before: Dictionary = rig.sim.get_hex_ground_planning_snapshot()
		_check(not rig.sim.prepare_hex_checkpoint_restore(corrupted).get("ok",true) and rig.sim.get_hex_ground_planning_snapshot()==before,"invalid security enum/type/range rejects without owner writes")
	var restored: Dictionary = rig.sim.restore_hex_checkpoint_state(saved)
	_check(restored.get("ok",false),"actual Root restores the live security movement")
	if restored.get("ok",false):
		var restored_command: Dictionary = rig.sim._hex_movement_runtime._orders[actor.unit_id].command
		_check(restored_command.security_mode=="360" and restored_command.security_radius_tiles==4 and restored_command.facing_angle==payload.facing_angle and restored_command.source_task_type==payload.source_task_type,"restored intent retains security semantics and the original source task")
		for step in range(90): rig.sim._physics_process(0.1)
		_check(rig.sim.has_hex_position_arrived(actor.unit_id,command.target_position,command.command_token),"restored real security command completes through Root movement")
		_check(lifecycle._command_is_stable(rig.sim,actor,actor.get_current_unit_command()),"completed actual security movement is stable without erasing its command or stance")
		var stale = COMMAND.from_dict(payload)
		stale.command_token = "unrelated-token"
		_check(not lifecycle._command_is_stable(rig.sim,actor,stale),"matching position with another command token is not sufficient arrival proof")
		_check(rig.sim.embark_hex_ground_actor_group(PackedStringArray([actor.unit_id])).get("ok",false),"actual deployed actor embarks through Root")
		var sequence := {"units":[actor],"unit_index":0,"phase":"complete"}
		var queued: Dictionary = DEPLOY.new().advance_phase(rig.sim,sequence,Vector2.ZERO)
		_check(queued.phase=="queued" and not TRANSPORT.pack_sequence(sequence).get("ok",true),"uncommitted real admission keeps transport save blocked")
		rig.sim._physics_process(0.1)
		var deployed: Dictionary = DEPLOY.new().advance_phase(rig.sim,sequence,Vector2.ZERO)
		_check(deployed.phase=="committed" and not sequence.has("hex_admission") and TRANSPORT.pack_sequence(sequence).get("ok",false),"final actual Root admission releases only completed sequence receipt and permits stable transport save")
	rig.scene.free()
