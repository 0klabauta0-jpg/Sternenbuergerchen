extends SceneTree
var held := false
func _init() -> void: call_deferred("_run")
func _reserve(craft: String) -> Dictionary:
	if held: return {"ok":false,"reason":"pad_busy"}
	held = true
	return {"ok":true,"pad_id":"pad_1","craft_id":craft}
func _validate(craft: String, pad: String) -> bool: return held and craft == "shuttle" and pad == "pad_1"
func _release(_craft: String, _pad: String) -> void: held = false
func _run() -> void:
	var script = load("res://scripts/core/polisa_shuttle_home_lifecycle.gd")
	if script == null: printerr("FAIL: lifecycle missing"); quit(1); return
	var owner = script.new()
	if not owner.configure(_reserve, _validate, _release).ok: printerr("FAIL: configure"); quit(1); return
	if not owner.begin("shuttle", "person").ok: printerr("FAIL: reserve"); quit(1); return
	if not owner.landing_receipt().is_empty(): printerr("FAIL: landed too soon"); quit(1); return
	owner.advance(3.0)
	if owner.get_snapshot().pad_visual.progress <= 0.0: printerr("FAIL: no inbound progress"); quit(1); return
	owner.advance(20.0)
	var receipt: Dictionary = owner.landing_receipt()
	if receipt.is_empty() or not owner.verify_landing("shuttle",receipt): printerr("FAIL: completed landing"); quit(1); return
	if owner.verify_landing("other",receipt): printerr("FAIL: wrong craft"); quit(1); return
	var exit_ticket: Dictionary = owner.prepare_passenger_exit("person")
	if exit_ticket.is_empty() or not owner.verify_passenger_exit("shuttle", "person", exit_ticket): printerr("FAIL: passenger transfer ticket"); quit(1); return
	if owner.verify_passenger_exit("shuttle", "other", exit_ticket): printerr("FAIL: passenger mismatch"); quit(1); return
	if not owner.begin_departure("shuttle").ok or not owner.departure_receipt().is_empty(): printerr("FAIL: departure started"); quit(1); return
	owner.advance(20.0)
	var departed: Dictionary = owner.departure_receipt()
	if departed.is_empty() or not owner.verify_departure("shuttle", departed): printerr("FAIL: completed departure"); quit(1); return
	owner.release()
	if held or owner.verify_landing("shuttle",receipt): printerr("FAIL: release invalidates receipt"); quit(1); return
	print("PASS: reserved timed home landing")
	quit(0)
