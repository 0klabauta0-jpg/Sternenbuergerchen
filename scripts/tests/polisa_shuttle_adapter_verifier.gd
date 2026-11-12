extends SceneTree

class MockShuttle extends RefCounted:
	var elapsed := 0.0
	func advance(delta: float) -> Dictionary:
		elapsed += delta
		return {"ok":true}
	func get_snapshot() -> Dictionary:
		return {"craft_id":"station-shuttle", "phase":"to_home", "checkpoint_safe":false, "route":{"phase":"quantum", "position":[1.0,2.0]}}

class MockFleet extends RefCounted:
	func get_snapshot(_id: String = "") -> Dictionary:
		return {"craft_id":"own", "phase":"orbit", "routes":{"own":{"phase":"orbit"}}}

class MockFlow extends Node:
	var _last_mission_result := {}
	var _selected_mission_id := ""

class MockBase extends Node:
	func get_shuttle_person_status(_id: String) -> Dictionary: return {"ok":true,"has_bed":false,"has_task":false}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var adapter = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new()
	if not adapter.has_method("_service_shuttle_snapshot"):
		printerr("FAIL: Shuttle adapter snapshot missing")
		quit(1)
		return
	var service := MockShuttle.new()
	adapter._polisa_shuttle = service
	adapter.advance_space_travel(1.5)
	assert(service.elapsed == 1.5)
	assert(adapter._service_shuttle_snapshot().craft_id == "station-shuttle")
	assert(not adapter.get_world_checkpoint_guard().ok)
	var flow := MockFlow.new()
	adapter._flow = flow
	adapter._travel = MockFleet.new()
	var snapshot: Dictionary = adapter.get_space_travel_snapshot()
	assert(snapshot.service_shuttle.craft_id == "station-shuttle")
	assert(not snapshot.routes.has("station-shuttle"), "Service ship must not become an owned fleet route")
	flow.free()
	adapter.free()
	adapter = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new()
	var flow2 := MockFlow.new()
	var base := MockBase.new()
	adapter._flow = flow2
	adapter._base_personnel = base
	if not adapter.has_method("_configure_polisa_shuttle"):
		printerr("FAIL: shuttle dispatcher bootstrap missing")
		base.free(); flow2.free(); adapter.free(); quit(1); return
	var configured: Dictionary = adapter._configure_polisa_shuttle()
	assert(configured.ok and adapter._polisa_shuttle != null and adapter._polisa_shuttle_dispatcher != null)
	base.free(); flow2.free(); adapter.free()
	print("PASS: simulation tick, route snapshot and checkpoint guard")
	quit(0)
