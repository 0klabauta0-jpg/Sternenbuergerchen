extends SceneTree
class MockFlow extends Node:
	var _aircraft_location_by_craft := {"own":"starmap","other":"homebase"}
	var pending := false
	func _find_pending_mission_craft_transfer(_id: String) -> Dictionary: return {"busy":true} if pending else {}
class MockFleet extends RefCounted:
	func get_snapshot(id: String = "") -> Dictionary: return {"routes":{id:{"phase":"orbit"}}}
	func is_quantum_active() -> bool: return false
class MockDispatcher extends RefCounted:
	var phase := "idle"
	var advances := 0
	var cancel_pending := false
	func get_snapshot() -> Dictionary: return {"phase":phase,"source_craft_id":"own","craft_id":"shuttle"}
	func request_departure(_id: String) -> Dictionary: phase="pilot_pending"; return {"ok":true,"handled":true,"pending":true}
	func advance(_delta: float) -> void:
		advances += 1
		if phase == "cancelling": phase = "cancelled"
	func ack_cancelled() -> Dictionary: phase="idle"; return {"ok":true}
	func cancel_before_transfer() -> Dictionary:
		if cancel_pending: phase="cancelling"; return {"ok":true,"pending":true}
		phase="idle"; return {"ok":true}
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var adapter = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new()
	if not adapter.has_method("_reserve_service_home_pad"): printerr("FAIL: pad reservation missing"); adapter.free(); quit(1); return
	adapter._pad_by_craft = {"own":"homebase_pad_01"}
	var claim: Dictionary = adapter._reserve_service_home_pad("shuttle")
	if not claim.ok or claim.pad_id != "homebase_pad_02": printerr("FAIL: claim"); adapter.free(); quit(1); return
	if not adapter._validate_service_home_pad("shuttle", "homebase_pad_02"): printerr("FAIL: validation"); adapter.free(); quit(1); return
	if not adapter._polisa_free_home_pad().is_empty(): printerr("FAIL: player cannot take reserved pad"); adapter.free(); quit(1); return
	if adapter._reserve_service_home_pad("other").ok: printerr("FAIL: duplicate reservation"); adapter.free(); quit(1); return
	adapter._release_service_home_pad("other", "homebase_pad_02")
	if not adapter._validate_service_home_pad("shuttle", "homebase_pad_02"): printerr("FAIL: wrong release"); adapter.free(); quit(1); return
	adapter._release_service_home_pad("shuttle", "homebase_pad_02")
	if adapter._validate_service_home_pad("shuttle", "homebase_pad_02"): printerr("FAIL: release"); adapter.free(); quit(1); return
	var flow := MockFlow.new()
	adapter._flow = flow
	adapter._travel = MockFleet.new()
	adapter._pad_by_craft = {"own":"homebase_pad_01","other":"homebase_pad_02"}
	var borrowed: Dictionary = adapter._reserve_service_home_pad("shuttle")
	if not borrowed.ok or borrowed.pad_id != "homebase_pad_01": printerr("FAIL: empty away-craft pad should be borrowable"); flow.free(); adapter.free(); quit(1); return
	if not adapter._service_pad_blocks_craft("own"): printerr("FAIL: owner landing must wait"); flow.free(); adapter.free(); quit(1); return
	adapter._release_service_home_pad("shuttle", "homebase_pad_01")
	adapter._polisa_shuttle_dispatcher = MockDispatcher.new()
	adapter.request_polisa_service_departure("own")
	if not adapter._validate_service_home_pad("shuttle", "homebase_pad_01"): printerr("FAIL: reserve before player can return"); flow.free(); adapter.free(); quit(1); return
	if adapter.get_world_checkpoint_guard().get("ok", true): printerr("FAIL: pending service must block checkpoint"); flow.free(); adapter.free(); quit(1); return
	if not adapter._reserve_service_home_pad("shuttle").ok: printerr("FAIL: same owner must reuse pad reservation"); flow.free(); adapter.free(); quit(1); return
	adapter._release_service_home_pad("shuttle", "homebase_pad_01")
	flow.pending = true
	adapter.advance_space_travel(1.0)
	if adapter._polisa_shuttle_dispatcher.advances != 0: printerr("FAIL: dispatcher must wait for pad before moving shuttle"); flow.free(); adapter.free(); quit(1); return
	flow.pending = false
	adapter.advance_space_travel(1.0)
	if adapter._polisa_shuttle_dispatcher.advances != 1 or not adapter._validate_service_home_pad("shuttle", "homebase_pad_01"): printerr("FAIL: dispatcher must resume after pad becomes available"); flow.free(); adapter.free(); quit(1); return
	adapter._polisa_shuttle_dispatcher.cancel_pending = true
	if not adapter.cancel_polisa_service_departure("own").ok or not adapter._validate_service_home_pad("shuttle", "homebase_pad_01"): printerr("FAIL: pending cancel must retain reservation"); flow.free(); adapter.free(); quit(1); return
	adapter.advance_space_travel(1.0)
	if adapter._polisa_shuttle_dispatcher.phase != "idle" or adapter._validate_service_home_pad("shuttle", "homebase_pad_01"): printerr("FAIL: completed async cancel releases reservation"); flow.free(); adapter.free(); quit(1); return
	flow.free()
	adapter.free()
	print("PASS: service pad reservation excludes player allocation")
	quit(0)
