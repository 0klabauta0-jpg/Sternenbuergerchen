extends SceneTree
var present := false
var cancellation_allowed := false
func _init() -> void: call_deferred("_run")
func _quote(id: String) -> Dictionary:
	return {"ok":true,"offer_id":id,"unit_id":"polisa_recruit_b","price":250,"profile":{"unit_id":"polisa_recruit_b","display_name":"B"}}
func _verify(unit_id: String, reserve_id: String) -> Dictionary:
	return {"ok":present and unit_id == "polisa_recruit_b" and reserve_id == "reserve-b"}
func _can_cancel(_unit_id: String, _reserve_id: String) -> Dictionary:
	return {"ok":cancellation_allowed}
func _run() -> void:
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	var contract = load("res://scripts/mission/singleplayer_supply_command_contract.gd")
	supply.configure()
	supply._credits = 1000
	var context := {"location_id":"polisa","station_service_verified":true,"recruit_quote":Callable(self,"_quote"),"recruit_verify":Callable(self,"_verify"),"recruit_cancel_verify":Callable(self,"_can_cancel")}
	var reserve: Dictionary = contract.build_command("station_recruit_reserve", {"offer_id":"offer-b"}, "reserve-b")
	if reserve.is_empty(): _fail("reserve command"); return
	var result: Dictionary = supply.apply_command(reserve, context)
	if not result.get("ok",false) or result.get("state") != "pending" or supply.get_supply_snapshot().credits != 750: _fail("reservation"); return
	if not supply.has_pending_recruitments(): _fail("pending not reported"); return
	var finish: Dictionary = contract.build_command("station_recruit_finalize", {"reservation_id":"reserve-b"}, "final-b")
	if supply.apply_command(finish,context).get("ok",false): _fail("finalized without real actor"); return
	var saved: Dictionary = supply.export_state()
	var restored = load("res://scripts/core/singleplayer_supply_state.gd").new()
	if not restored.restore_state(saved).get("ok",false): _fail("restore pending"); return
	if restored.get_recruit_reservation("reserve-b").get("profile",{}).get("display_name") != "B": _fail("restore candidate profile"); return
	present = true
	result = restored.apply_command(finish,context)
	if not result.get("ok",false) or result.get("unit_id") != "polisa_recruit_b" or restored.get_supply_snapshot().credits != 750: _fail("finalize"); return
	if restored.has_pending_recruitments(): _fail("completed reservation still pending"); return
	if not restored.apply_command(finish,context).get("replayed",false): _fail("idempotent finalize"); return
	var another = load("res://scripts/core/singleplayer_supply_state.gd").new()
	if not another.restore_state(saved).get("ok",false): _fail("restore cancellation fixture"); return
	var cancel: Dictionary = contract.build_command("station_recruit_cancel", {"reservation_id":"reserve-b"}, "cancel-b")
	if cancel.is_empty(): _fail("cancel command"); return
	if another.apply_command(cancel,context).get("ok",false) or another.get_supply_snapshot().credits != 750: _fail("cancel before proof"); return
	cancellation_allowed = true
	if not another.apply_command(cancel,context).get("ok",false) or another.get_supply_snapshot().credits != 1000: _fail("verified cancellation refund"); return
	if not another.apply_command(cancel,context).get("replayed",false) or another.get_supply_snapshot().credits != 1000: _fail("idempotent refund"); return
	if another.apply_command(finish,context).get("ok",false): _fail("cancelled reservation cannot finalize"); return
	print("PASS: reserved credits survive restore and require real admission")
	quit(0)
func _fail(message: String) -> void:
	printerr("FAIL: " + message)
	quit(1)
