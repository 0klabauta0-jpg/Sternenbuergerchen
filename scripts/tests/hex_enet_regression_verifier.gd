extends SceneTree
## Two actual loopback ENet peers in separate SceneMultiplayer branches.
const SIM=preload("res://scripts/core/simulation_root.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN=preload("res://scripts/terrain/terrain_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const UNITS=preload("res://scripts/registries/unit_registry.gd")
const DRIVER=preload("res://scripts/tests/mission_combat_loop_driver.gd")
const CACHE=preload("res://scripts/mission/combat_visibility_cache.gd")
const VITAL=preload("res://scripts/npc/unit_vital_status.gd")
const ISOLATION=preload("res://scripts/tests/review2_isolated_user_guard.gd")
var passed:=0
var failed:=0
var snapshots:Array=[]
var results:Array=[]
var resolutions:Array=[]

class ObservedRoot extends SIM:
	var received_envelopes:Array=[]
	var wire_chunks:Dictionary={}
	@rpc("authority","unreliable")
	func _receive_tick_state_chunk(tick:int,index:int,count:int,raw_size:int,compressed:bool,chunk:PackedByteArray,runtime_context:Dictionary={}) -> void:
		# Observe actual RPC bytes before product validation/normalization; never
		# replace delivery, sender identity, projection or the receiver itself.
		if accepts_multiplayer_runtime_context(runtime_context):
			if not wire_chunks.has(tick):wire_chunks[tick]={}
			wire_chunks[tick][index]=chunk
			if wire_chunks[tick].size()==count:
				var bytes:=PackedByteArray()
				for i in range(count):bytes.append_array(wire_chunks[tick][i])
				var raw:PackedByteArray=bytes.decompress(raw_size,FileAccess.COMPRESSION_ZSTD) if compressed else bytes
				received_envelopes.append(bytes_to_var(raw))
				wire_chunks.erase(tick)
		super._receive_tick_state_chunk(tick,index,count,raw_size,compressed,chunk,runtime_context)

class NPC extends Node2D:
	var unit_id:String
	var team_id:String="blue"
	var current_command:RefCounted
	var target_position:=Vector2.ZERO
	var vital=VITAL.new()
	var damage_count:=0
	var remote_count:=0
	func get_unit_id()->String:return unit_id
	func get_team_id()->String:return team_id
	func get_fireteam_id()->String:return "blue_ft" if team_id=="blue" else "red_ft"
	func get_vital_state()->String:return vital.state
	func get_vital_status()->RefCounted:return vital
	func get_health()->int:return vital.health_points
	func get_awareness()->float:return 0.8
	func get_current_unit_command():return current_command
	func assign_unit_command(value):current_command=value
	func set_target_position(value):target_position=value
	func get_target_position()->Vector2:return target_position
	func get_move_speed_factor()->float:return 1.0
	func get_combat_speed_multiplier()->float:return 1.0
	func refresh_terrain_readability()->void:pass
	func apply_damage(amount:int,_context:Dictionary={})->bool:
		damage_count+=1
		vital.health_points=maxi(0,vital.health_points-amount)
		return true
	func apply_remote_vital_update(update:Dictionary)->void:
		remote_count+=1
		vital.health_points=int(update.get("health",vital.health_points))
		vital.state=String(update.get("vital_state",vital.state))
		vital.bleedout_ticks=int(update.get("bleedout_ticks",vital.bleedout_ticks))
	func apply_remote_snapshot(snapshot:Dictionary)->void:
		visible=bool(snapshot.get("visible",visible))
		if snapshot.get("position") is Vector2:global_position=snapshot.position
		apply_remote_vital_update(snapshot)

class QuietDriver extends DRIVER:
	func _ready()->void:
		set_process(false)
		set_physics_process(false)

func _init()->void:
	if ISOLATION.require_isolated_user_data():call_deferred("_run")
func _check(value:bool,label:String)->void:
	if value:passed+=1
	else:failed+=1
	print("PASS " if value else "FAIL ",label)
func _pump(seconds:float=0.12)->void:
	await create_timer(seconds).timeout
func _fixture(label:String,api:SceneMultiplayer,authority:bool)->Dictionary:
	var scope:=Node.new()
	scope.name=label
	root.add_child(scope)
	set_multiplayer(api,scope.get_path())
	var terrain=TERRAIN.new()
	terrain.name="TerrainRegistry"
	scope.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for x in range(6):terrain.register_tile(TILE.new({"tile_id":str(x),"grid_position":Vector2i(x,0),"explicit_hex_ramps":true}))
	var registry=UNITS.new()
	registry.name="UnitRegistry"
	scope.add_child(registry)
	var sim=ObservedRoot.new()
	sim.name="SimulationRoot"
	sim.unit_registry_path=NodePath("../UnitRegistry")
	sim.terrain_registry_path=NodePath("../TerrainRegistry")
	sim.is_server_authoritative=true
	scope.add_child(sim)
	sim.set_physics_process(false)
	sim.set_process(false)
	var map=MAP.create_empty("hex_enet_regression",Vector2i(6,1),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	map._extension_metadata["terrain_height_rules"]="explicit_hex_ramps_v1"
	if authority:_check(sim.configure_hex_ground_runtime(map,terrain).get("ok",false),"host opts in through actual Ground version gate")
	var cache=CACHE.new()
	cache.name="VisibilityCache"
	scope.add_child(cache)
	var driver:=QuietDriver.new()
	driver.name="CombatLoopDriver"
	driver.friendly_team_id="blue"
	driver.simulation_root_path=NodePath("../SimulationRoot")
	driver.terrain_registry_path=NodePath("../TerrainRegistry")
	driver.combat_visibility_cache_path=NodePath("../VisibilityCache")
	scope.add_child(driver)
	driver.set("_runs_local_authority",authority)
	var actors:Dictionary={}
	for id in ["own","enemy"]:
		var actor:=NPC.new()
		actor.name=id
		actor.unit_id=id
		actor.team_id="blue" if id=="own" else "red"
		actor.position=terrain.grid_to_world(Vector2i(0 if id=="own" else 4,0))
		scope.add_child(actor)
		registry.register_unit(id,actor)
		sim.register_known_unit(id,actor)
		actors[id]=actor
	driver.friendly_unit_paths.assign([NodePath("../own")])
	driver.enemy_unit_paths.assign([NodePath("../enemy")])
	if authority:
		var placements:Array[Dictionary]=[{"unit_id":"own","grid":Vector2i.ZERO,"facing_dir":3},{"unit_id":"enemy","grid":Vector2i(4,0),"facing_dir":3}]
		_check(sim.admit_hex_ground_units(placements).get("ok",false),"two real actors have exclusive host Ground cells")
	return {"scope":scope,"sim":sim,"driver":driver,"terrain":terrain,"actors":actors}

func _private_free(value:Variant)->bool:
	if value is Dictionary:
		for key in value:
			if key in ["rng_state","passage_commitments","active_segments","committed_corridor_grants","occupant_by_grid","_orders","_hex_lifecycle"]:return false
			if not _private_free(value[key]):return false
	elif value is Array:
		for item in value:
			if not _private_free(item):return false
	return true
func _has_enemy(snapshot:Dictionary)->bool:
	for unit:Dictionary in snapshot.get("units",[]):
		if unit.get("unit_id")=="enemy":return true
	return false

func _run()->void:
	var server:=ENetMultiplayerPeer.new()
	var code:=server.create_server(0,1)
	_check(code==OK,"real ENet server binds an ephemeral UDP port")
	if code!=OK:quit(1);return
	var port:int=server.host.get_local_port()
	var host_api:=SceneMultiplayer.new()
	host_api.multiplayer_peer=server
	var client_api:=SceneMultiplayer.new()
	var peer:=ENetMultiplayerPeer.new()
	_check(peer.create_client("127.0.0.1",port)==OK,"real ENet client connects over loopback")
	client_api.multiplayer_peer=peer
	var host:Dictionary=_fixture("Host",host_api,true)
	var client:Dictionary=_fixture("Client",client_api,false)
	var deadline:int=Time.get_ticks_msec()+5000
	while (peer.get_connection_status()!=MultiplayerPeer.CONNECTION_CONNECTED or host_api.get_peers().is_empty()) and Time.get_ticks_msec()<deadline:await _pump(0.01)
	var connected:bool=peer.get_connection_status()==MultiplayerPeer.CONNECTION_CONNECTED and host_api.get_peers().size()==1
	_check(connected and host_api.is_server() and not client_api.is_server(),"two actual SceneMultiplayer peers complete ENet handshake")
	if not connected:
		server.close();peer.close();host.scope.free();client.scope.free();quit(1);return
	var client_id:int=client_api.get_unique_id()
	host.sim.set_peer_team_assignments({1:"blue",client_id:"blue"})
	host.sim.set_peer_role_assignments({1:"host",client_id:"commander"})
	host.sim.set_peer_fireteam_assignments({1:["blue_ft"],client_id:["blue_ft"]})
	var context:Dictionary={"schema":"multiplayer.runtime_context.v1","runtime_token":"ab".repeat(16),"map_id":"hex_enet_regression","map_hash":"a".repeat(64)}
	_check(host.sim.bind_multiplayer_runtime_context(context,"blue").get("ok",false) and client.sim.bind_multiplayer_runtime_context(context,"blue").get("ok",false),"host and replica bind the same explicit runtime lifetime")
	client.sim.multiplayer_snapshot_applied.connect(func(value:Dictionary):snapshots.append(value.duplicate(true)))
	client.sim.network_command_result_received.connect(func(value:Dictionary):results.append(value.duplicate(true)))
	host.sim.damage_effect_resolved.connect(func(value:Dictionary):resolutions.append(value.duplicate(true)))
	host.sim.set_multiplayer_snapshot_context({"commander_intents":[{"command_id":"enemy_reference","team_id":"blue","fireteam_id":"blue_ft","target_unit_id":"enemy","target_position":host.actors.enemy.position}]})
	host.sim._physics_process(0.1)
	await _pump()
	_check(not snapshots.is_empty() and not _has_enemy(snapshots.back()) and not client.actors.enemy.visible and _private_free(snapshots.back()),"real publisher/chunk RPC/receiver exclude rear enemy and host claims")
	var wire:Dictionary=client.sim.received_envelopes.back() if not client.sim.received_envelopes.is_empty() else {}
	var intents:Array=wire.get("snapshot",{}).get("commander_intents",[])
	_check(wire.get("runtime_context")==context and wire.get("recipient_team")=="blue" and _private_free(wire) and not _has_enemy(wire.get("snapshot",{})) and not intents.is_empty() and not intents[0].has("target_position") and not intents[0].has("target_unit_id"),"actual received ENet bytes exclude hidden enemy references before receiver normalization")
	var client_rng:int=client.sim._combat_rng.state
	var client_tick:int=client.sim.tick_counter
	client.sim.enqueue_effect({"effect_type":"damage","unit_id":"own","attacker_unit_id":"own","damage":7,"hit_chance":1.0})
	client.sim._physics_process(0.1)
	_check(client.sim._combat_rng.state==client_rng and client.sim.tick_counter==client_tick and client.actors.own.damage_count==0,"queued client damage cannot tick, reroll or mutate health")
	client.sim.clear_queues()
	var move:Dictionary={"command_type":"move_to_position","unit_id":"own","team_id":"blue","fireteam_id":"blue_ft","target_position":host.terrain.grid_to_world(Vector2i(2,0)),"command_token":"enet_move","requeue_until_target":true}
	var accepted_before:int=host.sim.get_network_command_contract_snapshot().accepted_count
	client.sim.submit_multiplayer_command(move)
	await _pump()
	_check(host.sim.get_network_command_contract_snapshot().accepted_count==accepted_before+1 and not results.is_empty() and results.back().get("accepted",false),"actual client submit traverses ENet request and reliable result RPC")
	for i in range(30):host.sim._physics_process(0.1)
	await _pump()
	_check(host.sim.get_hex_unit_state("own").get("grid")==Vector2i(2,0) and client.actors.own.position==host.actors.own.position and client.sim.get_hex_unit_state("own").is_empty(),"host alone executes opt-in Hex move and replica reads its network pose")
	var wrong:Dictionary=context.duplicate(true)
	wrong.runtime_token="cd".repeat(16)
	var count:int=host.sim.get_network_command_contract_snapshot().accepted_count
	client.sim.rpc_id(1,"request_command",move,wrong)
	var enemy_move:Dictionary=move.duplicate(true)
	enemy_move.unit_id="enemy"
	enemy_move.team_id="red"
	client.sim.submit_multiplayer_command(enemy_move)
	await _pump()
	_check(host.sim.get_network_command_contract_snapshot().accepted_count==count and host.sim.get_hex_unit_state("enemy").grid==Vector2i(4,0),"actual RPC rejects foreign lifetime and unowned enemy command")
	host.sim.queue_hex_facing_intent("own",0,"enet_front","security_assignment")
	host.sim._physics_process(0.1)
	await _pump()
	if not _has_enemy(snapshots.back()):print("ENET_FRONT_DIAGNOSTIC sight=",host.driver.get_multiplayer_visible_unit_ids("blue")," own=",host.sim.get_hex_unit_state("own"))
	_check(_has_enemy(snapshots.back()) and client.actors.enemy.visible and _private_free(snapshots.back()),"real logical facing exposes only visible enemy display over ENet")
	var visible_wire:Dictionary=client.sim.received_envelopes.back()
	var display_only:=false
	for unit:Dictionary in visible_wire.get("snapshot",{}).get("units",[]):
		if unit.unit_id=="enemy":display_only=not unit.has("fireteam_id") and not unit.has("target_position")
	_check(display_only and _private_free(visible_wire),"visible enemy is display-only in actual pre-normalization ENet envelope")
	host.sim.set_combat_rng_seed(71539)
	for i in range(3):host.sim.get_next_combat_roll()
	var exported:Dictionary=host.sim.export_hex_checkpoint_state()
	if not exported.get("ok",false):
		print("ENET_CHECKPOINT_DIAGNOSTIC ",exported)
		for order:Dictionary in host.sim._hex_movement_runtime._orders.values():
			for key in order.command:
				if key!="_hex_lifecycle" and host.sim._hex_movement_runtime._save_command_kind(key).is_empty():print("ENET_UNSUPPORTED_COMMAND ",key,"=",order.command[key])
	_check(exported.get("ok",false),"actual Root checkpoint exports after network move")
	if exported.get("ok",false):
		var canonical:Dictionary=JSON.parse_string(JSON.stringify(exported.state))
		var movement:RefCounted=host.sim._hex_movement_runtime
		var bad_type:Dictionary=canonical.movement.duplicate(true)
		var unknown_field:Dictionary=canonical.movement.duplicate(true)
		var preserved_field:=false
		for field:Dictionary in bad_type.accepted_intents[0].command_intent:
			if field.key=="fireteam_id":field.value=17;preserved_field=true
		unknown_field.accepted_intents[0].command_intent.append({"key":"unrecognized_remote_field","kind":"string","value":"reject"})
		_check(preserved_field and not movement.prepare_restore_state(bad_type).get("ok",true) and not movement.prepare_restore_state(unknown_field).get("ok",true),"portable accepted command retains fireteam field while wrong type and unknown field reject")
		var expected:Array=[]
		for i in range(6):expected.append(host.sim.get_next_combat_roll())
		var prepared:Dictionary=host.sim.prepare_hex_checkpoint_restore(canonical)
		var restored:bool=prepared.get("ok",false)
		if restored:restored=host.sim.validate_prepared_hex_checkpoint_restore(prepared.prepared).get("ok",false)
		if restored:restored=host.sim.commit_hex_checkpoint_restore(prepared.prepared,false).get("ok",false)
		if restored:restored=host.sim.finalize_hex_checkpoint_restore(prepared.prepared).get("ok",false)
		var actual:Array=[]
		for i in range(6):actual.append(host.sim.get_next_combat_roll())
		_check(restored and actual==expected,"JSON Root restore preserves exact six future authority rolls after an advanced RNG state")
		var restored_fields:Array=host.sim.export_hex_checkpoint_state().state.movement.accepted_intents[0].command_intent
		_check(restored_fields==canonical.movement.accepted_intents[0].command_intent,"actual network fireteam command survives complete Root JSON restore unchanged")
	var rng_before:int=host.sim._combat_rng.state
	var reference:=RandomNumberGenerator.new()
	reference.state=rng_before
	var expected_roll:float=reference.randf()
	host.sim.enqueue_effect({"effect_type":"damage","unit_id":"own","attacker_unit_id":"own","attacker_team_id":"blue","damage":7,"hit_chance":1.0})
	host.sim._physics_process(0.1)
	await _pump()
	_check(resolutions.size()==1 and resolutions[0].get("roll")==expected_roll and host.sim._combat_rng.state==reference.state,"queued host damage consumes exactly one canonical authority roll")
	if client.actors.own.vital.health_points!=host.actors.own.vital.health_points:print("ENET_HEALTH_DIAGNOSTIC host=",host.actors.own.vital.health_points," replica=",client.actors.own.vital.health_points," remote=",client.actors.own.remote_count)
	_check(client.sim._combat_rng.state==client_rng and client.actors.own.damage_count==0 and client.actors.own.vital.health_points==host.actors.own.vital.health_points and client.actors.own.remote_count>0,"real snapshot/vitals replicate health without client damage or RNG execution")
	var before_snapshots:int=snapshots.size()
	host.sim.rpc_id(client_id,"_receive_vital_state_updates",[{"unit_id":"own","health":1,"vital_tick":9999}],wrong,"blue")
	host.sim.rpc_id(client_id,"_receive_tick_state_chunk",9999,0,1,1,false,PackedByteArray([0]),wrong)
	await _pump()
	_check(snapshots.size()==before_snapshots and client.actors.own.vital.health_points==host.actors.own.vital.health_points and client.sim.get_snapshot_transport_debug_snapshot().pending_tick_count==0,"foreign-context real chunk/vitals RPC rejected before replica mutation")
	host.sim.queue_hex_facing_intent("own",3,"enet_rear","security_assignment")
	host.sim._physics_process(0.1)
	await _pump()
	_check(not _has_enemy(snapshots.back()) and not client.actors.enemy.visible,"subsequent actual full projection hides a formerly visible enemy")
	server.close()
	peer.close()
	host.scope.free()
	client.scope.free()
	await process_frame
	print("HEX_ENET_REGRESSION checks=%d failures=%d real_enet=true processes=1 peers=2 native=false"%[passed+failed,failed])
	if failed==0:print("HEX_ENET_REGRESSION_PASS")
	quit(0 if failed==0 else 1)
