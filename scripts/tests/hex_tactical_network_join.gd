extends RefCounted
## AP8 owner join. Transport capture is explicit, not an ENet/peer acceptance test.
const SIM = preload("res://scripts/core/simulation_root.gd")
const REGISTRY = preload("res://scripts/registries/unit_registry.gd")
const SESSION = preload("res://scripts/multiplayer/multiplayer_session.gd")
const VITAL = preload("res://scripts/npc/unit_vital_status.gd")
const DRIVER = preload("res://scripts/tests/mission_combat_loop_driver.gd")

class CapturedWire extends MultiplayerAPIExtension:
	var local_id: int = 1
	var sender_id: int = 0
	var peers := PackedInt32Array([2,3])
	var peer: MultiplayerPeer = OfflineMultiplayerPeer.new()
	var sent: Array = []
	func _get_unique_id() -> int: return local_id
	func _get_remote_sender_id() -> int: return sender_id
	func _get_peer_ids() -> PackedInt32Array: return peers.duplicate()
	func _get_multiplayer_peer() -> MultiplayerPeer: return peer
	func _set_multiplayer_peer(value: MultiplayerPeer) -> void: peer=value
	func _poll() -> Error: return OK
	func _object_configuration_add(_object: Object,_configuration: Variant) -> Error: return OK
	func _object_configuration_remove(_object: Object,_configuration: Variant) -> Error: return OK
	func _rpc(recipient: int,_object: Object,method: StringName,args: Array) -> Error:
		sent.append({"peer":recipient,"method":String(method),"args":args.duplicate(true)})
		return OK

class ReplicaActor extends Node2D:
	var unit_id: String = ""
	var team_id: String = ""
	var vital = VITAL.new()
	var vital_apply_count: int = 0
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return team_id
	func get_vital_status() -> RefCounted: return vital
	func apply_remote_vital_update(update: Dictionary) -> void:
		vital.state=String(update.get("vital_state",vital.state))
		vital.health_points=int(update.get("health",vital.health_points))
		vital.bleedout_ticks=int(update.get("bleedout_ticks",vital.bleedout_ticks))
		vital_apply_count+=1

class ReplicaDriver extends DRIVER:
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

var passed: int = 0
var failed: int = 0

func _check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1
	print("PASS " if value else "FAIL ","AP8_NET ",label)

func _messages(wire: CapturedWire,method: String,peer_id: int) -> Array:
	var found: Array=[]
	for message: Dictionary in wire.sent:
		if message.method==method and message.peer==peer_id: found.append(message.duplicate(true))
	return found

func _decoded(chunks: Array) -> Dictionary:
	if chunks.is_empty(): return {}
	var ordered: Dictionary={}
	var first: Array=chunks[0].args
	for message: Dictionary in chunks:
		var args: Array=message.args
		if args.size()!=7 or args[0]!=first[0] or args[2]!=first[2] or args[3]!=first[3] or args[4]!=first[4] or args[6]!=first[6]: return {}
		ordered[args[1]]=args[5]
	if ordered.size()!=int(first[2]): return {}
	var bytes := PackedByteArray()
	for index in range(int(first[2])):
		if not ordered.has(index): return {}
		bytes.append_array(ordered[index])
	var raw: PackedByteArray=bytes.decompress(int(first[3]),FileAccess.COMPRESSION_ZSTD) if first[4] else bytes
	var value: Variant=bytes_to_var(raw)
	return value if value is Dictionary else {}

func _deliver_chunks(client: Node,wire: CapturedWire,chunks: Array) -> void:
	wire.sender_id=1
	for index in range(chunks.size()-1,-1,-1): client.callv("_receive_tick_state_chunk",chunks[index].args)
	wire.sender_id=0

func _portable(value: Variant) -> bool:
	if value is Dictionary:
		for key in value:
			if key in ["_hex_lifecycle","passage_commitments","active_segments","committed_corridor_grants","_orders","_admission_by_id"]: return false
			if not _portable(value[key]): return false
	elif value is Array:
		for item in value:
			if not _portable(item): return false
	return true

func _host_session(session: Node) -> void:
	session.set("_local_is_host",true)
	session.set("_connection_state","hosting")
	session.set("max_players",1)
	session.set("_team_play_mode","coop")
	session.set("_peers_by_id",{1:{"peer_id":1,"ready":true,"team_id":"blue","role_id":"host"}})

## Checkpoint joins inside the caller's actual in-flight passage, BEFORE this
## network lifecycle sequence. This helper owns no save/restore coordination.
func run(tree: SceneTree,host: Node,driver: Node,actors: Dictionary) -> Dictionary:
	var host_scope: Node=host.get_parent()
	var host_wire := CapturedWire.new()
	tree.set_multiplayer(host_wire,host_scope.get_path())
	host.is_server_authoritative=true
	host.set_peer_team_assignments({1:"blue",2:"blue",3:"red"})
	host.set_peer_role_assignments({1:"host",2:"commander",3:"commander"})
	host.set_peer_fireteam_assignments({1:["blue_ft"],2:["blue_ft"],3:["red_ft"]})
	# Real facing producer, real tick, real current-sight getter. No sight-ID stub.
	for id in ["follower","leader"]: host.queue_hex_facing_intent(id,3,"net_hidden_"+id,"security_assignment")
	host._physics_process(0.1)
	driver._current_tick=host.tick_counter
	var sight: PackedStringArray=driver.get_multiplayer_visible_unit_ids("blue")
	_check(not sight.has("target"),"actual rear-facing host geometry hides target before publication")
	var session = SESSION.new()
	session.name="NetworkJoinSession"
	host_scope.add_child(session)
	_host_session(session)
	session.set_host_map_manifest({"map_id":"hex_tactical_slice","map_name":"AP8 fixture","map_hash":"a".repeat(64),"map_size_bytes":100})
	var started: bool=session.request_start_mission()
	var context: Dictionary=session.get_multiplayer_runtime_context()
	var bound: Dictionary=host.bind_multiplayer_runtime_context(context,"blue")
	_check(started and bound.get("ok",false) and context.get("runtime_token","").length()==32,"actual Session start mints context and actual Root binds it")
	var changed: Dictionary=context.duplicate(true)
	changed.runtime_token="f".repeat(32) if context.get("runtime_token")!="f".repeat(32) else "e".repeat(32)
	_check(not host.bind_multiplayer_runtime_context(changed,"blue").get("ok",true) and host.get_multiplayer_runtime_context()==context,"active Root rejects another lifetime without rebinding")

	var client_scope := Node.new()
	client_scope.name="AP8NetworkReplica"
	tree.root.add_child(client_scope)
	var client_wire := CapturedWire.new()
	client_wire.local_id=2
	client_wire.peers=PackedInt32Array([1])
	tree.set_multiplayer(client_wire,client_scope.get_path())
	var registry = REGISTRY.new()
	registry.name="UnitRegistry"
	client_scope.add_child(registry)
	var client = SIM.new()
	client.name="SimulationRoot"
	client.unit_registry_path=NodePath("../UnitRegistry")
	client_scope.add_child(client)
	client.set_physics_process(false)
	client.is_server_authoritative=true
	var replicas: Dictionary={}
	for id in ["follower","leader","target","registry_foreign","known_foreign"]:
		var actor := ReplicaActor.new()
		actor.unit_id=id
		actor.team_id="blue" if id in ["follower","leader"] else "red"
		client_scope.add_child(actor)
		if id!="known_foreign": registry.register_unit(id,actor)
		if id!="registry_foreign": client.register_known_unit(id,actor)
		replicas[id]=actor
	var client_bound: Dictionary=client.bind_multiplayer_runtime_context(context,"blue")
	_check(client_bound.get("ok",false) and replicas.follower.visible and not replicas.target.visible and not replicas.registry_foreign.visible and not replicas.known_foreign.visible,"initial real Root visual gate covers foreign Registry-only and Known-only actors")
	replicas.known_foreign.show()
	_check(not replicas.known_foreign.visible,"later foreign visual activation cannot escape the bound visibility gate")
	var applied: Array=[]
	client.multiplayer_snapshot_applied.connect(func(snapshot: Dictionary):applied.append(snapshot.duplicate(true)))
	host.set_multiplayer_snapshot_context({"commander_intents":[{"command_id":"hidden_target","team_id":"blue","fireteam_id":"blue_ft","target_unit_id":"target","target_position":actors.target.global_position},{"command_id":"free_area","team_id":"blue","fireteam_id":"blue_ft","target_position":Vector2(900,400)}]})
	host_wire.sent.clear()
	host._broadcast_tick_state()
	var first_chunks: Array=_messages(host_wire,"_receive_tick_state_chunk",2)
	var first_projection: Dictionary=_decoded(first_chunks)
	var red_projection: Dictionary=_decoded(_messages(host_wire,"_receive_tick_state_chunk",3))
	var first_snapshot: Dictionary=first_projection.get("snapshot",{})
	var ids: Array=[]
	for unit: Dictionary in first_snapshot.get("units",[]): ids.append(unit.unit_id)
	_check(first_projection.get("projection_scope")=="full_recipient_state" and first_projection.get("runtime_context")==context and first_projection.get("recipient_team")=="blue" and not ids.has("target") and ids.has("follower") and red_projection.get("recipient_team")=="red","actual host publisher produces recipient-specific compressed full scopes")
	var intents: Dictionary={}
	for intent: Dictionary in first_snapshot.get("commander_intents",[]): intents[intent.command_id]=intent
	_check(intents.has("hidden_target") and not intents.hidden_target.has("target_position") and intents.has("free_area") and intents.free_area.get("target_position")==Vector2(900,400) and _portable(first_projection),"raw endpoint proof survives until filter; free own areas remain and private host promises never enter the wire")
	var vitals: Array=_messages(host_wire,"_receive_vital_state_updates",2)
	for message: Dictionary in vitals: client.callv("_receive_vital_state_updates",message.args)
	_check(not vitals.is_empty() and replicas.follower.vital_apply_count==1 and replicas.target.vital_apply_count==0,"actual reliable publisher and receiver apply only proven recipient vitals")
	_deliver_chunks(client,client_wire,first_chunks)
	_check(applied.size()==1 and not replicas.target.visible and not replicas.registry_foreign.visible and client.get_snapshot_transport_debug_snapshot().reassembled_snapshot_count==1,"actual reverse-order chunk receiver emits one fullscope and preserves foreign absence")

	host_wire.sent.clear()
	for id in ["follower","leader"]: host.queue_hex_facing_intent(id,0,"net_visible_"+id,"security_assignment")
	host._physics_process(0.1)
	driver._current_tick=host.tick_counter
	var visible_chunks: Array=_messages(host_wire,"_receive_tick_state_chunk",2)
	var visible_projection: Dictionary=_decoded(visible_chunks)
	_deliver_chunks(client,client_wire,visible_chunks)
	var public_enemy: Dictionary={}
	for unit: Dictionary in visible_projection.get("snapshot",{}).get("units",[]):
		if unit.unit_id=="target": public_enemy=unit
	_check(driver.get_multiplayer_visible_unit_ids("blue").has("target") and replicas.target.visible and not public_enemy.is_empty() and not public_enemy.has("fireteam_id") and not public_enemy.has("target_position"),"actual Root facing admits a visible display-only enemy through host publisher and receiver")
	host_wire.sent.clear()
	for id in ["follower","leader"]: host.queue_hex_facing_intent(id,3,"net_hidden_again_"+id,"security_assignment")
	host._physics_process(0.1)
	driver._current_tick=host.tick_counter
	_deliver_chunks(client,client_wire,_messages(host_wire,"_receive_tick_state_chunk",2))
	_check(not replicas.target.visible and applied.size()==3,"next actual fullscope removes a formerly visible enemy")

	var apply_count: int=applied.size()
	var reject_chunks: Array=first_chunks.duplicate(true)
	for message: Dictionary in reject_chunks: message.args[6]=changed.duplicate(true)
	_deliver_chunks(client,client_wire,reject_chunks)
	client._receive_vital_state_updates([{"unit_id":"follower","health":1,"vital_tick":host.tick_counter+100}],changed,"blue")
	var legacy: Dictionary=client.apply_multiplayer_snapshot({"tick":host.tick_counter+100,"units":[{"unit_id":"target","visible":true}]})
	_check(applied.size()==apply_count and client.get_snapshot_transport_debug_snapshot().pending_tick_count==0 and replicas.follower.vital.health_points==100 and not legacy.get("accepted",true),"foreign-token chunks/vitals and contextless legacy state reject before recipient mutation")
	var received_results: Array=[]
	client.network_command_result_received.connect(func(value: Dictionary):received_results.append(value.duplicate(true)))
	client._receive_network_command_result({"accepted":true},changed)
	client._receive_network_command_result({"accepted":true},context)
	_check(received_results.size()==1,"command result callbacks require the current lifetime")

	var command: Dictionary={"command_type":"hold_position","unit_id":"follower","team_id":"blue","fireteam_id":"blue_ft"}
	client.submit_multiplayer_command(command)
	var commands: Array=_messages(client_wire,"request_command",1)
	var accepted_before: int=host.get_network_command_contract_snapshot().accepted_count
	host_wire.sender_id=2
	host.request_command(command,changed)
	if not commands.is_empty(): host.callv("request_command",commands.back().args)
	host_wire.sender_id=0
	_check(commands.size()==1 and commands[0].args[1]==context and host.get_network_command_contract_snapshot().accepted_count==accepted_before+1,"real client submit and authority request boundary accept only the current-context owned command")
	var unblocked: Array=[]
	session.mission_rejoin_peer_block_changed.connect(func(id: int,blocked: bool):unblocked.append([id,blocked]))
	session.set("_reconnect_tokens_by_peer_id",{2:"fixture_reconnect"})
	host_wire.sender_id=2
	session.notify_mission_runtime_ready(changed)
	session.notify_mission_runtime_ready(context)
	host_wire.sender_id=0
	_check(unblocked==[[2,false]],"actual READY receiver unblocks only the current lifetime")

	var replica_driver := ReplicaDriver.new()
	replica_driver.name="CombatLoopDriver"
	replica_driver.simulation_root_path=NodePath("../SimulationRoot")
	client_scope.add_child(replica_driver)
	replica_driver.set("_runs_local_authority",false)
	replica_driver._receive_mission_result({"result":"victory"},changed)
	replica_driver._receive_remote_event("old unit event","follower",Color.WHITE,1.0,"old",changed)
	_check(not replica_driver.get("_combat_finished"),"direct Driver result and unit-event paths reject a foreign lifetime")

	client.clear_multiplayer_runtime_context()
	host.clear_multiplayer_runtime_context()
	host_wire.sent.clear()
	host._broadcast_tick_state()
	driver._broadcast_remote_event("must not become legacy","target")
	_deliver_chunks(client,client_wire,visible_chunks)
	client._receive_tick_state({"tick":host.tick_counter+200,"units":[{"unit_id":"target","visible":true}]})
	_check(not host.accepts_multiplayer_runtime_context({}) and not client.accepts_multiplayer_runtime_context({}) and host_wire.sent.is_empty() and applied.size()==apply_count and not replicas.target.visible,"clear closes outgoing and incoming paths without reopening legacy wire mode")
	session.complete_mission()
	_host_session(session)
	var restarted: bool=session.request_start_mission()
	var next_context: Dictionary=session.get_multiplayer_runtime_context()
	var next_bound: Dictionary=host.bind_multiplayer_runtime_context(next_context,"blue")
	var next_client: Dictionary=client.bind_multiplayer_runtime_context(next_context,"blue")
	_deliver_chunks(client,client_wire,visible_chunks)
	_check(restarted and next_context!=context and next_bound.get("ok",false) and next_client.get("ok",false) and not host.accepts_multiplayer_runtime_context(context) and applied.size()==apply_count,"real second Session start rebinds new lifetime and old same-roster messages stay rejected")

	client_scope.free()
	return {"ok":failed==0,"passed":passed,"failed":failed,"host_publication":failed==0,"receiver":failed==0,"runtime_lifetime":failed==0,"root_checkpoint":false,"real_peer":false,"transport":"controlled_multiplayer_api_extension","native_acceptance":false}
