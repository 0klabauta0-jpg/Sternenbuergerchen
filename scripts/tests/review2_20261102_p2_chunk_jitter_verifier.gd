extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SIMULATION = preload("res://scripts/core/simulation_root.gd")
const CONTRACT = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const REGISTRY = preload("res://scripts/registries/unit_registry.gd")
var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	_test_delayed_chunks()
	_test_stale_duplicates_and_payload_tick()
	await _test_pending_lifetime_and_capacity()
	print("REVIEW2_CHUNK_JITTER_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_delayed_chunks() -> void:
	var scene := Node.new()
	root.add_child(scene)
	var registry = REGISTRY.new()
	registry.name = "Units"
	scene.add_child(registry)
	var control = _simulation(scene)
	var delayed = _simulation(scene)
	var packets: Dictionary = {}
	for tick in range(100, 164):
		var packet: Dictionary = _packet(tick, 64)
		packets[tick] = packet
		for index in range(packet.chunks.size()):
			_deliver(control, tick, index, packet)
		_deliver(delayed, tick, 0, packet)
		if tick >= 104:
			var earlier: Dictionary = packets[tick - 4]
			for index in range(1, earlier.chunks.size()):
				_deliver(delayed, tick - 4, index, earlier)
	var control_debug: Dictionary = control.get_multiplayer_snapshot_debug_snapshot()
	var delayed_debug: Dictionary = delayed.get_multiplayer_snapshot_debug_snapshot()
	print("CHUNK_DELIVERY chunks=%d control_applied=%d delayed_applied=%d complete_delayed_ticks=60" % [packets[100].chunks.size(), control_debug.apply_count, delayed_debug.apply_count])
	_check(packets[100].chunks.size() > 1, "Fixture uses real compressed packetized 64-unit snapshots")
	_check(control_debug.apply_count == 64, "Complete immediate delivery applies every control snapshot")
	_check(delayed_debug.apply_count == 60 and delayed_debug.last_applied_tick == 159, "All 60 fully delivered delayed snapshots converge with four ticks of chunk jitter")
	var final_packet: Dictionary = packets[163]
	for index in range(final_packet.chunks.size() - 1, -1, -1):
		_deliver(delayed, 163, index, final_packet)
	_check(delayed.get_multiplayer_snapshot_debug_snapshot().last_applied_tick == 163, "Latest reversed chunks converge after skipped intermediate snapshots")
	_check(delayed.get_snapshot_transport_debug_snapshot().pending_tick_count == 0, "Latest completion removes obsolete partial snapshots")
	_check(delayed.command_queue.is_empty() and delayed.effects_queue.is_empty(), "Reassembly remains a command/effect-free viewer path")
	scene.free()


func _test_stale_duplicates_and_payload_tick() -> void:
	var scene := Node.new()
	root.add_child(scene)
	var registry = REGISTRY.new()
	registry.name = "Units"
	scene.add_child(registry)
	var simulation = _simulation(scene)
	var packet: Dictionary = _packet(100, 64)
	_deliver(simulation, 100, 0, packet)
	_deliver(simulation, 100, 0, packet)
	for index in range(packet.chunks.size() - 1, 0, -1):
		_deliver(simulation, 100, index, packet)
	_check(simulation.get_multiplayer_snapshot_debug_snapshot().apply_count == 1, "Duplicate chunk cannot complete or apply a snapshot twice")
	_deliver(simulation, 99, 0, _packet(99, 64))
	_check(simulation.get_snapshot_transport_debug_snapshot().pending_tick_count == 0, "Stale partial chunk never creates a new buffer")
	var wrong_tick: Dictionary = _packet(102, 64)
	for index in range(wrong_tick.chunks.size()):
		_deliver(simulation, 101, index, wrong_tick)
	_check(simulation.get_multiplayer_snapshot_debug_snapshot().last_applied_tick == 100, "Decoded snapshot tick must agree with chunk header")
	_check(simulation.get_snapshot_transport_debug_snapshot().reassembly_failure_count == 1, "Inconsistent complete payload is counted explicitly")
	_check(simulation.command_queue.is_empty() and simulation.effects_queue.is_empty(), "Stale and inconsistent packets create no gameplay work")
	scene.free()


func _test_pending_lifetime_and_capacity() -> void:
	var scene := Node.new()
	root.add_child(scene)
	var registry = REGISTRY.new()
	registry.name = "Units"
	scene.add_child(registry)
	var simulation = _simulation(scene)
	for tick in range(200):
		_deliver(simulation, tick, 0, _packet(tick, 64))
	_check(simulation.get_snapshot_transport_debug_snapshot().pending_tick_count <= 32, "Unfinished snapshot storm has a bounded pending count")
	var pending: Dictionary = simulation.get("_incoming_snapshot_chunks_by_tick")
	for tick in pending:
		pending[tick]["first_received_msec"] = Time.get_ticks_msec() - 10000
	await process_frame
	await process_frame
	_check(simulation.get_snapshot_transport_debug_snapshot().pending_tick_count == 0, "Expired incomplete buffers retire even without a newer applied tick")
	_check(simulation.get_multiplayer_snapshot_debug_snapshot().apply_count == 0, "Incomplete storm never applies partial state")
	scene.free()


func _simulation(parent: Node):
	var simulation = SIMULATION.new()
	simulation.unit_registry_path = NodePath("../Units")
	parent.add_child(simulation)
	simulation.set_physics_process(false)
	return simulation


func _packet(tick: int, unit_count: int) -> Dictionary:
	var units: Array = []
	for index in range(unit_count):
		units.append({"unit_id": "unit_%03d" % index, "team_id": "team_alpha", "fireteam_id": "blue", "position": Vector2(sin(float(index)) * 1000.0 + tick, cos(float(index)) * 1000.0), "facing_angle": float(index) * 0.12345, "visible": true, "vital_state": "fit", "health": 100 - index, "bleedout_ticks": 0, "vital_tick": tick})
	var snapshot: Dictionary = CONTRACT.new().build_state_snapshot({"tick": tick, "units": units})
	var raw: PackedByteArray = var_to_bytes(snapshot)
	var compressed: PackedByteArray = raw.compress(FileAccess.COMPRESSION_ZSTD)
	var use_compression: bool = compressed.size() > 0 and compressed.size() < raw.size()
	var wire: PackedByteArray = compressed if use_compression else raw
	var chunks: Array = []
	for index in range(ceili(float(wire.size()) / 1000.0)):
		chunks.append(wire.slice(index * 1000, mini((index + 1) * 1000, wire.size())))
	return {"chunks": chunks, "raw_size": raw.size(), "compressed": use_compression}


func _deliver(simulation: Node, tick: int, index: int, packet: Dictionary) -> void:
	simulation.call("_receive_tick_state_chunk", tick, index, packet.chunks.size(), packet.raw_size, packet.compressed, packet.chunks[index])


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		print("FAIL: " + message)
