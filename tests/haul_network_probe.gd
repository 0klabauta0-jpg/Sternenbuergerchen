extends SceneTree
var game:Node
var host:=false
var websocket:=false
var out:=""
var elapsed:=0.0
var stage:=0
func _initialize() -> void:call_deferred("start")
func write(name:String,data:Dictionary) -> void:
 var f:=FileAccess.open(out.path_join(name),FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
func start() -> void:
 for arg:String in OS.get_cmdline_user_args():
  if arg=="--host":host=true
  if arg=="--websocket":websocket=true
  if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
 game=load("res://scenes/game.tscn").instantiate();game.team_mode=host;game.load_on_start=false;game.simulation_seed=3;game.save_path=out.path_join("unused.json");root.add_child(game)
 if host:
  if websocket:game.session.start_websocket_host(28379)
  else:game.session.start_host(28379)
  write("ready.json",{"invitation":game.session.internet_invitation() if websocket else "lan"})
 elif websocket:game.session.join_internet(JSON.parse_string(FileAccess.get_file_as_string(out.path_join("ready.json"))).invitation)
 else:game.session.join_host("127.0.0.1",28379)
func _process(delta:float) -> bool:
 if not is_instance_valid(game):return false
 elapsed+=delta
 if elapsed>65:finish(false,"timeout stage %d"%stage);return false
 var s:Dictionary=game.session.current_snapshot()
 if not s.has("campaign"):return false
 if host:
  if stage==0 and s.campaign.members.size()==2:
   for peer:Variant in s.campaign.members:
    if int(peer)!=1:game.send_command({"type":"assign_team","peer_id":int(peer),"team":1})
   for core:Node in game.simulation._cores:
    core._state.region="station";core._state.ship.position=[0.0,28.0];core._state.ship.target=[0.0,28.0]
    for unit:Dictionary in core._state.crew.values():unit.position=[0.0,20.0];unit.target=[0.0,20.0]
   if not game.send_command({"type":"start_match"}).ok:finish(false,"start");return false
   stage=1
  elif stage==1 and FileAccess.file_exists(out.path_join("dropped.json")):
   var crates:Dictionary=s.freight_world.crates
   if crates.size()!=1:finish(false,"shared dropped crate missing");return false
   if not game.send_command({"type":"pickup_freight","unit_id":"ida","crate_id":crates.keys()[0]}).ok:finish(false,"host pickup");return false
   stage=2
  elif stage==2 and int(s.cargo.food)==1:
   if game.simulation._cores[1]._state.cargo.food!=0:finish(false,"duplicated cargo");return false
   var saved:Dictionary=game.simulation.save_game(out.path_join("freight-save.json"))
   if not saved.ok:finish(false,saved.reason);return false
   write("delivered.json",{"ok":true});stage=3
  elif stage==3 and FileAccess.file_exists(out.path_join("client.json")):
   var result:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(out.path_join("client.json")))
   finish(bool(result.ok),"network purchase, carried crate, cancel/drop, rival delivery, save and both projections")
 else:
  if stage==0 and s.campaign.started and s.campaign.team==1:
   game.send_command({"type":"trade","side":"buy","item":"food","amount":1});stage=1
  elif stage==1 and not s.hauling.jobs.is_empty() and s.hauling.jobs[0].held==1:
   if s.cargo.food!=0:finish(false,"teleported cargo");return false
   game.send_command({"type":"cancel_hauling"});stage=2
  elif stage==2 and s.hauling.jobs.is_empty() and s.freight_world.crates.size()==1:
   write("dropped.json",{"ok":true});stage=3
  elif stage==3 and FileAccess.file_exists(out.path_join("delivered.json")) and s.freight_world.crates.is_empty():
   write("client.json",{"ok":int(s.cargo.food)==0,"saw_carrier":true,"saw_drop":true});stage=4
 return false
func finish(ok:bool,reason:String) -> void:
 write("host.json" if host else "client.json",{"ok":ok,"reason":reason})
 print("HAUL NETWORK ",ok," ",reason);quit(0 if ok else 1)
