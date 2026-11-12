extends SceneTree
class Service extends RefCounted:
	func get_snapshot() -> Dictionary: return {"phase":"home_disembark_required","person_id":"person","craft_id":"service"}
class Home extends RefCounted:
	func get_snapshot() -> Dictionary: return {"phase":"landed"}
	func prepare_passenger_exit(_id: String) -> Dictionary: return {"proof":true}
class Base extends Node:
	var attempts := 0
	func get_snapshot() -> Dictionary: return {"layout":{"avatar_spawn_grid":[0,0]}}
	func admit_polisa_shuttle_home(_id: String,_proof: Dictionary,_grid: Vector2i) -> Dictionary: attempts+=1; return {"ok":false,"reason":"no_arrival_space"}
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var adapter = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new()
	var base := Base.new()
	adapter._base_personnel = base; adapter._polisa_shuttle = Service.new(); adapter._polisa_shuttle_home = Home.new()
	for i in range(10): adapter._advance_polisa_shuttle_home(0.1)
	if base.attempts > 3 or base.attempts < 1: printerr("FAIL: blocked arrival retries must be throttled"); base.free(); adapter.free(); quit(1); return
	base.free(); adapter.free()
	print("PASS: blocked home admission is throttled")
	quit(0)
