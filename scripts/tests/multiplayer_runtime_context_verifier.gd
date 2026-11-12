extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SESSION = preload("res://scripts/multiplayer/multiplayer_session.gd")

class TestSession extends "res://scripts/multiplayer/multiplayer_session.gd":
	var sent: Array = []
	func _send_start_assignments(peer_id: int = 0) -> void:
		sent.append({"peer": peer_id, "assignments": _last_start_assignments.duplicate(true)})

var passed: int = 0
var failed: int = 0

func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print(("PASS " if ok else "FAIL ") + label)

func host_ready(host: Node) -> void:
	host.set("_local_is_host", true)
	host.set("_connection_state", "hosting")
	host.set("max_players", 1)
	host.set("_team_play_mode", "coop")
	host.set("_peers_by_id", {1: {"peer_id": 1, "ready": true, "team_id": "team_alpha", "role_id": "host"}})

func run() -> void:
	var host = TestSession.new()
	var client = TestSession.new()
	root.add_child(host)
	root.add_child(client)
	if not host.has_method("get_multiplayer_runtime_context"):
		check(false, "runtime context API exists")
		finish(host, client)
		return
	host_ready(host)
	check(host.call("get_multiplayer_runtime_context").is_empty() and not host.build_session_assignments().has("multiplayer_runtime_context"), "getter and assignments never mint before start")
	var manifest: Dictionary = {"map_id": "tiny", "map_name": "Tiny", "map_hash": "a".repeat(64), "map_size_bytes": 100, "scenario_hash": "b".repeat(64)}
	host.set_host_map_manifest(manifest)
	client.set_host_map_manifest(manifest)
	check(host.request_start_mission(), "actual successful host start")
	var first: Dictionary = host.call("get_multiplayer_runtime_context")
	check(first.get("schema") == "multiplayer.runtime_context.v1" and first.get("runtime_token", "").length() == 32 and first.get("map_id") == "tiny" and first.get("scenario_hash") == "b".repeat(64) and first.size() == 5, "exact identity DTO without paths")
	var wire: Dictionary = host.build_session_assignments()
	check(wire.get("multiplayer_runtime_context") == first and host.sent.size() == 1, "actual start assignment carries context")
	first["map_id"] = "tampered"
	check(host.call("get_multiplayer_runtime_context").get("map_id") == "tiny", "getter detached")
	wire["multiplayer_runtime_context"]["map_id"] = "tampered"
	check(host.build_session_assignments()["multiplayer_runtime_context"]["map_id"] == "tiny", "assignment detached")
	wire = host.build_session_assignments()
	client._receive_start_mission(wire)
	check(client.get("_mission_started") and client.call("get_multiplayer_runtime_context") == host.call("get_multiplayer_runtime_context"), "actual reliable receive adopts same context")
	var token: String = host.call("get_multiplayer_runtime_context")["runtime_token"]
	host._send_start_assignments(9)
	check(host.sent[1]["assignments"]["multiplayer_runtime_context"]["runtime_token"] == token and host.call("get_multiplayer_runtime_context")["runtime_token"] == token, "rejoin assignment and pure reads preserve token")
	check_active_snapshot_receive(manifest, wire)
	client.complete_mission()
	var starts: Array = []
	client.mission_start_requested.connect(func(a: Dictionary): starts.append(a))
	for key in ["schema", "map_hash", "scenario_hash", "runtime_token"]:
		var bad: Dictionary = wire.duplicate(true)
		bad["multiplayer_runtime_context"][key] = "unknown"
		client._receive_start_mission(bad)
		check(not client.get("_mission_started") and starts.is_empty() and client.call("get_multiplayer_runtime_context").is_empty(), "reject invalid present " + key + " before activation")
	var extra: Dictionary = wire.duplicate(true)
	extra["multiplayer_runtime_context"]["source_path"] = "res://somewhere"
	client._receive_start_mission(extra)
	check(not client.get("_mission_started"), "reject unknown context fields")
	var snapshot: Dictionary = host.get_session_snapshot()
	snapshot["assignments"]["multiplayer_runtime_context"]["schema"] = "unknown"
	client._apply_authority_snapshot(snapshot)
	check(not client.get("_mission_started"), "snapshot cannot preactivate invalid present context")
	host.complete_mission()
	check(host.call("get_multiplayer_runtime_context").is_empty(), "completion retires runtime")
	host_ready(host)
	check(host.request_start_mission() and host.call("get_multiplayer_runtime_context")["runtime_token"] != token, "next actual start new token")
	host._reset_session_state(false)
	check(host.call("get_multiplayer_runtime_context").is_empty(), "reset clears context")
	client._reset_session_state(false)
	client._receive_start_mission({"peer_teams": {1: "team_alpha"}})
	check(client.get("_mission_started") and client.call("get_multiplayer_runtime_context").is_empty(), "missing context preserves legacy receive")
	client.complete_mission()
	client._receive_start_mission(wire)
	check(not client.get("_mission_started"), "present context without accepted manifest rejected")
	for value in [{}, null, "unknown"]:
		client._receive_start_mission({"multiplayer_runtime_context": value})
		check(not client.get("_mission_started"), "explicit empty or malformed context rejects")
	host_ready(host)
	check(host.request_start_mission() and host.call("get_multiplayer_runtime_context").is_empty() and not host.build_session_assignments().has("multiplayer_runtime_context"), "no manifest legacy host still starts without invented identity")
	finish(host, client)

func check_active_snapshot_receive(manifest: Dictionary, wire: Dictionary) -> void:
	for changed_manifest in ["same", "different", "mismatch", "empty_completion"]:
		var active = TestSession.new()
		root.add_child(active)
		active.set_host_map_manifest(manifest)
		active._receive_start_mission(wire)
		var assignments_seen: Array = []
		var snapshots_seen: Array = []
		active.mission_assignments_changed.connect(func(a: Dictionary): assignments_seen.append(a.duplicate(true)))
		active.session_snapshot_changed.connect(func(s: Dictionary): snapshots_seen.append(s.duplicate(true)))
		var before: Dictionary = active.get_session_snapshot()
		var received_before: bool = active.get("_has_received_host_map_manifest")
		var rejected: Dictionary = {"mission_started": true, "assignments": wire.duplicate(true), "map_manifest": manifest.duplicate(true)}
		rejected["assignments"]["multiplayer_runtime_context"]["schema"] = "unknown"
		if changed_manifest in ["different", "mismatch"]:
			rejected["map_manifest"]["map_id"] = "different"
			rejected["map_manifest"]["map_hash"] = "c".repeat(64)
			if changed_manifest == "mismatch":
				rejected["assignments"]["multiplayer_runtime_context"] = wire["multiplayer_runtime_context"].duplicate(true)
		elif changed_manifest == "empty_completion":
			rejected["map_manifest"] = {}
			rejected["mission_started"] = false
			rejected["assignments"]["multiplayer_runtime_context"] = {}
		active._receive_session_snapshot(rejected)
		check(assignments_seen.is_empty() and snapshots_seen.is_empty() and active.get_session_snapshot() == before and active.get("_has_received_host_map_manifest") == received_before, "actual active receive rejects atomically including signals, manifest, token and assignments; changed_manifest=" + str(changed_manifest))
		active.free()
	var accepted = TestSession.new()
	root.add_child(accepted)
	accepted.set_host_map_manifest(manifest)
	accepted._receive_start_mission(wire)
	var observed: Array = []
	accepted.mission_assignments_changed.connect(func(a: Dictionary): observed.append(a.duplicate(true)))
	accepted._receive_session_snapshot({"mission_started": true, "assignments": wire.duplicate(true)})
	check(observed.size() == 1 and observed[0] == wire and accepted.get_multiplayer_runtime_context() == wire["multiplayer_runtime_context"], "actual active valid receive still publishes accepted assignment")
	var next_wire: Dictionary = wire.duplicate(true)
	next_wire["multiplayer_runtime_context"]["runtime_token"] = "d".repeat(32)
	accepted._receive_session_snapshot({"mission_started": true, "assignments": next_wire})
	check(observed.size() == 2 and observed[1] == next_wire and accepted.get_multiplayer_runtime_context().is_empty(), "different valid snapshot token forwards assignments but never binds runtime")
	accepted._receive_start_mission(next_wire)
	check(accepted.get_multiplayer_runtime_context() == next_wire["multiplayer_runtime_context"], "only reliable start accepts the new runtime context")
	accepted.free()

func finish(host: Node, client: Node) -> void:
	host.free()
	client.free()
	print("MULTIPLAYER_RUNTIME_CONTEXT passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
