extends SceneTree

const SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const MAX_INCREMENTAL_WIRE_BYTES_64: int = 8192
const MAX_INCREMENTAL_CHUNKS_64: int = 8
const MAX_SERIALIZATION_USEC: int = 50000

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1099 Connected Interaction Snapshot Payload Budget ===")
	var contract = SNAPSHOT_CONTRACT_SCRIPT.new()
	var baseline: Dictionary = _measure(contract, 0)
	var samples: Dictionary = {}
	for interaction_count in [1, 8, 32, 64]:
		var sample: Dictionary = _measure(contract, interaction_count)
		samples[interaction_count] = sample
		_assert(int(sample.get("mission_interaction_count", -1)) == interaction_count, "%d Interaction states are counted by serialization metrics" % interaction_count)
		_assert(int(sample.get("transport_raw_bytes", 0)) > 0, "%d Interaction states report transport raw bytes" % interaction_count)
		_assert(int(sample.get("transport_wire_bytes", 0)) > 0, "%d Interaction states report compressed wire bytes" % interaction_count)
		_assert(int(sample.get("transport_chunk_count", 0)) >= 1, "%d Interaction states report packet chunk count" % interaction_count)
		_assert(bool(sample.get("transport_compressed", false)) == bool(sample.get("expected_transport_compressed", true)), "%d Interaction states mirror the runtime conditional ZSTD fallback" % interaction_count)
		_assert(int(sample.get("transport_wire_bytes", 0)) == int(sample.get("expected_transport_wire_bytes", -1)), "%d Interaction states report the runtime-equivalent wire size" % interaction_count)
		_assert(int(sample.get("transport_measure_usec", MAX_SERIALIZATION_USEC + 1)) < MAX_SERIALIZATION_USEC, "%d Interaction state transport measurement stays below the broad 50 ms guard" % interaction_count)

	var largest: Dictionary = Dictionary(samples.get(64, {}))
	var incremental_wire_bytes: int = int(largest.get("transport_wire_bytes", 0)) - int(baseline.get("transport_wire_bytes", 0))
	var incremental_chunks: int = int(largest.get("transport_chunk_count", 0)) - int(baseline.get("transport_chunk_count", 0))
	print("TASK_1099 payload: baseline_wire=%d state64_wire=%d incremental=%d baseline_chunks=%d state64_chunks=%d measure=%dus" % [
		int(baseline.get("transport_wire_bytes", 0)),
		int(largest.get("transport_wire_bytes", 0)),
		incremental_wire_bytes,
		int(baseline.get("transport_chunk_count", 0)),
		int(largest.get("transport_chunk_count", 0)),
		int(largest.get("transport_measure_usec", 0)),
	])
	_assert(incremental_wire_bytes <= MAX_INCREMENTAL_WIRE_BYTES_64, "64 Interaction states add at most 8 KiB compressed wire payload")
	_assert(incremental_chunks <= MAX_INCREMENTAL_CHUNKS_64, "64 Interaction states add at most eight transport chunks")
	_assert(String(largest.get("asset_reference_policy", "")) == "ids_only_no_texture_paths_or_raw_payloads", "Interaction payload keeps the shared ID-only network policy")
	_assert(Array(largest.get("large_payload_offenders", PackedStringArray())).is_empty(), "Interaction payload introduces no raw path or asset offenders")
	_assert(bool(largest.get("read_only", false)), "Transport metrics explicitly remain read-only")
	_assert(not bool(largest.get("ui_sets_gameplay_truth", true)), "Transport metrics set no gameplay truth")
	_test_reverse_order_determinism(contract)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _measure(contract, interaction_count: int) -> Dictionary:
	var snapshot: Dictionary = Dictionary(contract.call("build_state_snapshot", {
		"tick": 1099,
		"mission_interactions": _build_interaction_snapshot(interaction_count),
	}))
	var metrics: Dictionary = Dictionary(contract.call("build_serialization_metrics", snapshot))
	var raw_bytes: PackedByteArray = var_to_bytes(snapshot)
	var compressed_bytes: PackedByteArray = raw_bytes.compress(FileAccess.COMPRESSION_ZSTD)
	var expected_compressed: bool = not compressed_bytes.is_empty() and compressed_bytes.size() < raw_bytes.size()
	metrics["expected_transport_compressed"] = expected_compressed
	metrics["expected_transport_wire_bytes"] = compressed_bytes.size() if expected_compressed else raw_bytes.size()
	return metrics


func _test_reverse_order_determinism(contract) -> void:
	var forward: Dictionary = Dictionary(contract.call("build_state_snapshot", {
		"tick": 1099,
		"mission_interactions": _build_interaction_snapshot(64),
	}))
	var reverse: Dictionary = Dictionary(contract.call("build_state_snapshot", {
		"tick": 1099,
		"mission_interactions": _build_interaction_snapshot(64, true),
	}))
	var forward_metrics: Dictionary = Dictionary(contract.call("build_serialization_metrics", forward))
	var reverse_metrics: Dictionary = Dictionary(contract.call("build_serialization_metrics", reverse))
	_assert(String(contract.call("build_canonical_payload_string", forward)) == String(contract.call("build_canonical_payload_string", reverse)), "Reverse Interaction input order normalizes to the same canonical payload")
	_assert(var_to_bytes(forward) == var_to_bytes(reverse), "Reverse Interaction input order normalizes to identical transport bytes")
	_assert(int(forward_metrics.get("transport_wire_bytes", -1)) == int(reverse_metrics.get("transport_wire_bytes", -2)), "Reverse Interaction input order keeps wire bytes stable")
	_assert(int(forward_metrics.get("transport_chunk_count", -1)) == int(reverse_metrics.get("transport_chunk_count", -2)), "Reverse Interaction input order keeps chunk count stable")


func _build_interaction_snapshot(interaction_count: int, reverse_order: bool = false) -> Dictionary:
	var states: Dictionary = {}
	var indices: Array = range(interaction_count)
	if reverse_order:
		indices.reverse()
	for index_variant in indices:
		var index: int = int(index_variant)
		var interaction_id: String = "station_%03d" % index
		states[interaction_id] = {
			"state": "holding" if index % 3 != 0 else "complete",
			"complete": index % 3 == 0,
			"hold_seconds": float(index % 12),
			"duration_seconds": 18.0,
			"progress": float(index % 18) / 18.0,
			"fireteam_id": "ft_%02d" % (index % 16),
			"team_id": "team_alpha" if index % 2 == 0 else "team_bravo",
			"step_id": "step_%03d" % index,
			"gate_id": "gate_%03d" % index,
			"interaction_type": ["air_defense", "door", "computer", "cargo"][index % 4],
			"command_type": "mission_interaction_use_intent_command",
			"updated_msec": 100000 + index,
		}
	return {"interaction_states": states}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
