extends SceneTree
## Actual transport fanout; controlled DTO/sight inputs isolate publisher work.
const SIM=preload("res://scripts/core/simulation_root.gd")
const UNITS=preload("res://scripts/registries/unit_registry.gd")
const ISOLATION=preload("res://scripts/tests/review2_isolated_user_guard.gd")
var passed:=0
var failed:=0

class ProbeRoot extends SIM:
	var pack_calls:Array=[]
	var envelopes:Array=[]
	var reliable:Array=[]
	var chunks:Dictionary={}
	var fixture_state:Dictionary={}
	var fixture_vitals:Array=[]
	func _build_raw_multiplayer_tick_state()->Dictionary:
		var state:Dictionary=fixture_state.duplicate(true)
		state.tick=tick_counter
		return state
	func _build_vital_state_updates()->Array:return fixture_vitals.duplicate(true)
	func _get_multiplayer_visibility_context(_raw:Dictionary,team:String)->Dictionary:
		return {"reference_provenance":"host_raw","own_unit_ids":["own_"+team],"visible_unit_ids":[],"fireteam_team_ids":{"blue_ft":"blue","red_ft":"red"},"craft_team_ids":{},"asset_team_ids":{}}
	func _broadcast_tick_state_chunks(state:Dictionary,recipients:PackedInt32Array)->void:
		pack_calls.append({"team":state.get("recipient_team",""),"peers":Array(recipients),"state":state.duplicate(true)})
		super._broadcast_tick_state_chunks(state,recipients)
	@rpc("authority","unreliable")
	func _receive_tick_state_chunk(tick:int,index:int,count:int,raw_size:int,compressed:bool,chunk:PackedByteArray,context:Dictionary={})->void:
		if accepts_multiplayer_runtime_context(context):
			if not chunks.has(tick):chunks[tick]={}
			chunks[tick][index]=chunk
			if chunks[tick].size()==count:
				var bytes:=PackedByteArray()
				for i in range(count):bytes.append_array(chunks[tick][i])
				var raw:PackedByteArray=bytes.decompress(raw_size,FileAccess.COMPRESSION_ZSTD) if compressed else bytes
				envelopes.append(bytes_to_var(raw))
				chunks.erase(tick)
		super._receive_tick_state_chunk(tick,index,count,raw_size,compressed,chunk,context)
	@rpc("authority","reliable")
	func _receive_vital_state_updates(updates:Array,context:Dictionary={},team:String="")->void:
		reliable.append({"updates":updates.duplicate(true),"context":context.duplicate(true),"team":team})
		super._receive_vital_state_updates(updates,context,team)

func _init()->void:
	if ISOLATION.require_isolated_user_data():call_deferred("run")
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failed+=1
	print("PASS " if ok else "FAIL ",label)
func pump()->void:await create_timer(0.15).timeout
func fixture(api:SceneMultiplayer,label:String)->Dictionary:
	var scope:=Node.new();scope.name=label;root.add_child(scope)
	set_multiplayer(api,scope.get_path())
	var registry:=UNITS.new();registry.name="UnitRegistry";scope.add_child(registry)
	var sim:=ProbeRoot.new();sim.name="SimulationRoot";sim.is_server_authoritative=true;sim.unit_registry_path=NodePath("../UnitRegistry");scope.add_child(sim)
	sim.set_physics_process(false);sim.set_process(false)
	return {"scope":scope,"sim":sim,"api":api}
func only_team(envelope:Dictionary,team:String)->bool:
	var units:Array=envelope.get("snapshot",{}).get("units",[])
	var intents:Array=envelope.get("snapshot",{}).get("commander_intents",[])
	return envelope.get("recipient_team")==team and units.size()==1 and units[0].unit_id=="own_"+team and intents.size()==1 and intents[0].team_id==team
func reliable_ok(sim:ProbeRoot,team:String)->bool:
	if sim.reliable.is_empty():return false
	var record:Dictionary=sim.reliable.back()
	return record.team==team and record.updates.size()==1 and record.updates[0].unit_id=="own_"+team and record.updates[0].health== (81 if team=="blue" else 62)
func packing_samples(sim:ProbeRoot)->void:
	if sim.pack_calls.is_empty():return
	# Measure only real Variant serialization/ZSTD, repeated exactly as often as
	# the productive publisher invoked the packer for this three-peer team.
	var state:Dictionary=sim.pack_calls[0].state.duplicate(true)
	state.snapshot.units=[]
	state.snapshot.vital_updates=[]
	state.snapshot.commander_intents=[]
	for i in range(96):
		state.snapshot.units.append({"unit_id":"blue_"+str(i),"team_id":"blue","fireteam_id":"blue_ft_"+str(i/4),"position":Vector2(i*17,i*31),"health":100-i%41,"vital_state":"fit","bleedout_ticks":0,"vital_tick":1,"facing_angle":float(i)*0.12,"active_weapon_id":"rifle","target_position":Vector2(i*19,i*37),"movement_posture":"normal"})
		state.snapshot.vital_updates.append({"unit_id":"blue_"+str(i),"health":100-i%41,"vital_tick":1})
		if i%4==0:state.snapshot.commander_intents.append({"command_id":"move_"+str(i),"team_id":"blue","fireteam_id":"blue_ft_"+str(i/4),"target_position":Vector2(i*19,i*37)})
	var samples:Array[int]=[]
	var raw_size:=0
	var wire_size:=0
	for sample in range(35):
		var started:int=Time.get_ticks_usec()
		for call in range(sim.pack_calls.size()):
			var raw:PackedByteArray=var_to_bytes(state)
			var compressed:PackedByteArray=raw.compress(FileAccess.COMPRESSION_ZSTD)
			raw_size=raw.size();wire_size=compressed.size()
		var elapsed:int=Time.get_ticks_usec()-started
		if sample>=5:samples.append(elapsed)
	print("PERF_SAMPLE ",JSON.stringify({"metric":"same_team_3peers_96units_packing_cpu","unit":"usec","samples":samples,"units":96,"peers":3,"pack_calls":sim.pack_calls.size(),"raw_bytes":raw_size,"compressed_bytes":wire_size,"renderer":"headless","scope":"var_to_bytes_plus_ZSTD_without_RPC"}))
func diagnostic(host:Dictionary,clients:Array,label:String)->void:
	var receipt_counts:Array=[]
	for client in clients:receipt_counts.append({"peer":client.api.get_unique_id(),"envelopes":client.sim.envelopes.size(),"reliable":client.sim.reliable.size(),"last_reliable":client.sim.reliable.back() if not client.sim.reliable.is_empty() else {}})
	var packs:Array=[]
	for call:Dictionary in host.sim.pack_calls:packs.append({"team":call.team,"peers":call.peers})
	print("FANOUT_DIAGNOSTIC ",label," packs=",packs," receipts=",receipt_counts)
func run()->void:
	var server:=ENetMultiplayerPeer.new()
	check(server.create_server(0,3)==OK,"real ENet server created")
	if failed:quit(1);return
	var host_api:=SceneMultiplayer.new();host_api.multiplayer_peer=server
	var host:Dictionary=fixture(host_api,"Host")
	var clients:Array=[]
	var peers:Array=[]
	for i in range(3):
		var peer:=ENetMultiplayerPeer.new()
		check(peer.create_client("127.0.0.1",server.host.get_local_port())==OK,"real ENet client created "+str(i))
		peers.append(peer)
		var api:=SceneMultiplayer.new();api.multiplayer_peer=peer
		clients.append(fixture(api,"Client"+str(i)))
	var deadline:int=Time.get_ticks_msec()+5000
	while host_api.get_peers().size()!=3 and Time.get_ticks_msec()<deadline:await pump()
	check(host_api.get_peers().size()==3,"three actual remote peers complete handshake")
	if host_api.get_peers().size()!=3:
		for peer in peers:peer.close()
		server.close()
		for client in clients:client.scope.free()
		host.scope.free();quit(1);return
	var context:Dictionary={"schema":"multiplayer.runtime_context.v1","runtime_token":"ef".repeat(16),"map_id":"fanout","map_hash":"a".repeat(64)}
	host.sim.bind_multiplayer_runtime_context(context,"blue")
	var ids:Array=[]
	for client in clients:
		var id:int=client.api.get_unique_id();ids.append(id)
		host.sim.set_peer_team(id,"blue")
		client.sim.bind_multiplayer_runtime_context(context,"blue")
	host.sim.fixture_state={"schema_version":1,"snapshot_type":"state","transfer_mode":"unreliable","units":[],"vital_updates":[],"commander_intents":[]}
	for team in ["blue","red"]:
		var unit:Dictionary={"unit_id":"own_"+team,"team_id":team,"fireteam_id":team+"_ft","position":Vector2(1,2),"health":81 if team=="blue" else 62}
		host.sim.fixture_state.units.append(unit)
		var vital:Dictionary={"unit_id":unit.unit_id,"health":unit.health}
		host.sim.fixture_state.vital_updates.append(vital)
		host.sim.fixture_vitals.append(vital)
		host.sim.fixture_state.commander_intents.append({"command_id":"intent_"+team,"team_id":team,"fireteam_id":team+"_ft","target_position":Vector2(9,9)})
	host.sim.tick_counter=1
	host.sim._broadcast_tick_state()
	await pump()
	diagnostic(host,clients,"same_team")
	check(host.sim.pack_calls.size()==1 and host.sim.pack_calls[0].peers.size()==3,"same team three peers invoke actual packer once")
	var same:=true
	for client in clients:same=same and client.sim.envelopes.size()==1 and only_team(client.sim.envelopes.back(),"blue") and reliable_ok(client.sim,"blue")
	check(same,"same-team peers receive own-only projection and unchanged reliable vitals")
	packing_samples(host.sim)
	host.sim.pack_calls.clear()
	host.sim.set_peer_team(ids[2],"red")
	clients[2].sim.bind_multiplayer_runtime_context(context,"red")
	host.sim.tick_counter=2
	host.sim._broadcast_tick_state()
	await pump()
	diagnostic(host,clients,"two_teams")
	var groups:Dictionary={}
	for call:Dictionary in host.sim.pack_calls:groups[call.team]=call.peers
	check(host.sim.pack_calls.size()==2 and groups.get("blue",[]).size()==2 and groups.get("red",[])==[ids[2]],"two teams pack separately with current recipient groups")
	var separate:=true
	for i in range(3):
		var team:String="red" if i==2 else "blue"
		separate=separate and clients[i].sim.envelopes.size()==2 and only_team(clients[i].sim.envelopes.back(),team) and reliable_ok(clients[i].sim,team)
	check(separate,"two-team actual envelopes and reliable vitals conceal other team")
	host.sim.pack_calls.clear()
	host.sim.set_snapshot_peer_blocked(ids[1],true)
	var blocked_chunks:int=clients[1].sim.envelopes.size()
	var blocked_vitals:int=clients[1].sim.reliable.size()
	host.sim.tick_counter=3
	host.sim._broadcast_tick_state()
	await pump()
	diagnostic(host,clients,"blocked")
	var blocked_absent:=true
	for call:Dictionary in host.sim.pack_calls:blocked_absent=blocked_absent and not call.peers.has(ids[1])
	check(host.sim.pack_calls.size()==2 and blocked_absent and clients[1].sim.envelopes.size()==blocked_chunks and clients[1].sim.reliable.size()==blocked_vitals,"blocked peer receives neither packed snapshot nor reliable vitals")
	check(clients[0].sim.envelopes.size()==3 and clients[2].sim.envelopes.size()==3 and reliable_ok(clients[0].sim,"blue") and reliable_ok(clients[2].sim,"red"),"unblocked peers keep snapshot and reliable delivery")
	for peer in peers:peer.close()
	server.close()
	for client in clients:client.scope.free()
	host.scope.free()
	await process_frame
	print("PERFORMANCE_SNAPSHOT_FANOUT checks=%d failures=%d"%[passed+failed,failed])
	if failed==0:print("PERFORMANCE_SNAPSHOT_FANOUT_PASS")
	quit(0 if failed==0 else 1)
