extends "res://scripts/tests/hex_base_boarding_verifier.gd"

class Shuttle extends RefCounted:
	func get_snapshot() -> Dictionary: return {"phase":"return_boarding_required","person_id":"base_person","craft_id":"service"}
class Home extends RefCounted:
	var valid := true
	func get_snapshot() -> Dictionary: return {"phase":"landed","craft_id":"service","landing_pad_id":"pad"}
	func landing_receipt() -> Dictionary: return {"craft_id":"service","pad_id":"pad"} if valid else {}
class ShuttleScope extends Scope:
	var _polisa_shuttle_home = Home.new()

func _finish()->void:
	var rig:Dictionary=_boarding_rig()
	rig.scene.set_script(ShuttleScope)
	rig.scene._polisa_shuttle=Shuttle.new()
	var base:Node=rig.base
	if not base.has_method("request_polisa_shuttle_return_board"):
		_check(false,"returning recruit has real home boarding")
	else:
		var wrong:Dictionary=base.request_polisa_shuttle_return_board("base_person","service",Vector2i(1,0),"board-1")
		_check(not wrong.get("ok",false),"wrong pad rejected")
		var accepted:Dictionary=base.request_polisa_shuttle_return_board("base_person","service",Vector2i(2,0),"board-1")
		_check(accepted.get("ok",false) and base.get_polisa_shuttle_return_board_receipt("base_person","service","board-1").is_empty(),"walking does not fabricate boarding receipt")
		var replay:Dictionary=base.request_polisa_shuttle_return_board("base_person","service",Vector2i(2,0),"board-1")
		_check(replay.get("ok",false) and replay.get("pending",false),"repeated boarding request does not restart walk")
		base.apply_operation("base_cancel", {"unit_id":"base_person"})
		_check(base.get_polisa_shuttle_return_board_receipt("base_person","service","board-1").is_empty(),"cancelled walk cannot fabricate receipt")
		var restarted:Dictionary=base.request_polisa_shuttle_return_board("base_person","service",Vector2i(2,0),"board-1")
		_check(restarted.get("ok",false),"cancelled boarding walk can be safely retried")
		for i in range(80): rig.sim._physics_process(0.1)
		var receipt:Dictionary=base.get_polisa_shuttle_return_board_receipt("base_person","service","board-1")
		_check(not receipt.is_empty() and base.verify_polisa_shuttle_return_board_receipt(receipt) and rig.sim.get_hex_unit_state("base_person").is_empty() and not base.get_actor("base_person").visible,"only reached and physically released person has valid boarding receipt")
		var saved: Dictionary=base.export_state()
		_check(saved.units.base_person.status=="station" and saved.units.base_person.location_id=="polisa","remote station status is encoded explicitly")
		var boarded_replay:Dictionary=base.request_polisa_shuttle_return_board("base_person","service",Vector2i(2,0),"board-1")
		_check(boarded_replay.get("ok",false) and not boarded_replay.get("pending",true) and boarded_replay.get("replayed",false),"completed boarding request replays without another movement")
		var altered:=receipt.duplicate(true); altered.unit_id="other"
		_check(not base.verify_polisa_shuttle_return_board_receipt(altered),"altered boarding receipt rejected")
		rig.scene._polisa_shuttle_home.valid=false
		_check(not base.verify_polisa_shuttle_return_board_receipt(receipt),"lost pad binding invalidates boarding receipt")
	rig.scene.free()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("POLISA_HOME_RETURN_BOARD_PASS")
	quit(0 if failed==0 else 1)
