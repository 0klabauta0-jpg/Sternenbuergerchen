extends SceneTree
class Shuttle extends RefCounted:
	var phase := "return_boarding_required"
	var returned := false
	var fail_first := false
	func get_snapshot() -> Dictionary: return {"phase":phase,"person_id":"person","craft_id":"service"}
	func begin_return(receipt: Dictionary) -> Dictionary:
		if fail_first:
			phase = "home_departure_pending"
			return {"ok":false,"reason":"temporary_failure"}
		returned = receipt.has("boarding") and receipt.has("departure")
		return {"ok":returned}
class Home extends RefCounted:
	var phase := "landed"
	var released := false
	func get_snapshot() -> Dictionary: return {"phase":phase,"landing_pad_id":"pad"}
	func begin_departure(_id: String) -> Dictionary: phase="departing"; return {"ok":true}
	func advance(_delta: float) -> Dictionary:
		if phase == "departing": phase="departed"
		return {"ok":true}
	func departure_receipt() -> Dictionary: return {"proof":true} if phase == "departed" else {}
	func release() -> void: released=true
class Base extends Node:
	var ready_to_board := false
	var requests := 0
	func get_snapshot() -> Dictionary: return {"layout":{"landing_pads":[{"id":"pad","interaction_grid":[1,2]}]}}
	func request_polisa_shuttle_return_board(_unit: String, _craft: String, _grid: Vector2i, _id: String) -> Dictionary: requests+=1; return {"ok":true}
	func get_polisa_shuttle_return_board_receipt(_unit: String, _craft: String, _id: String) -> Dictionary: return {"proof":true} if ready_to_board else {}
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var adapter = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new()
	var service := Shuttle.new(); var home := Home.new(); var base := Base.new()
	adapter._polisa_shuttle = service; adapter._polisa_shuttle_home = home; adapter._base_personnel = base
	adapter._advance_polisa_shuttle_home(1.0)
	if base.requests != 1 or home.phase != "landed" or service.returned: printerr("FAIL: must wait for real boarding"); base.free(); adapter.free(); quit(1); return
	base.ready_to_board = true
	adapter._advance_polisa_shuttle_home(1.0)
	if not service.returned or not home.released: printerr("FAIL: return after boarding and departure"); base.free(); adapter.free(); quit(1); return
	var retry_service := Shuttle.new(); var retry_home := Home.new(); retry_service.fail_first = true
	adapter._polisa_shuttle = retry_service; adapter._polisa_shuttle_home = retry_home
	adapter._advance_polisa_shuttle_home(1.0)
	if retry_home.released or retry_service.phase != "home_departure_pending": printerr("FAIL: pending retry retains pad"); base.free(); adapter.free(); quit(1); return
	retry_service.phase = "to_station"
	adapter._advance_polisa_shuttle_home(1.0)
	if not retry_home.released: printerr("FAIL: successful retry releases pad"); base.free(); adapter.free(); quit(1); return
	base.free(); adapter.free()
	print("PASS: home return waits for boarding and departure")
	quit(0)
