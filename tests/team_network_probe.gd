extends SceneTree
var game:Node
var host:=false
var websocket:=false
var out:=""
var index:=0
var elapsed:=0.0
var began:=false
var sent:=false
var replies:=0
var failed:=false
func _initialize() -> void:call_deferred("start")
func start() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg=="--team-host":host=true
		if arg=="--websocket":websocket=true
		if arg.begins_with("--probe-out="):out=arg.trim_prefix("--probe-out=")
		if arg.begins_with("--index="):index=int(arg.trim_prefix("--index="))
	game=load("res://scenes/game.tscn").instantiate()
	game.team_mode=host;game.load_on_start=false;game.simulation_seed=3
	game.save_path=out.path_join("unused-%d.json"%index)
	root.add_child(game)
	game.session.command_result.connect(result)
	if host:
		if websocket:game.session.start_websocket_host(28379)
		else:game.session.start_host(28379)
		var file:=FileAccess.open(out.path_join("ready.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"invitation":game.session.internet_invitation() if websocket else "lan"}));file.close()
	elif websocket:
		var invitation:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(out.path_join("ready.json")))
		game.session.join_internet(invitation.invitation)
	else:game.session.join_host("127.0.0.1",28379)
func _process(delta:float) -> bool:
	if not is_instance_valid(game):return false
	elapsed+=delta
	if elapsed>80:finish(false,"timeout");return false
	var state:Dictionary=game.session.current_snapshot()
	if not state.has("campaign"):return false
	var campaign:Dictionary=state.campaign
	if host and campaign.members.size()==16 and not began:
		began=true
		var response:Dictionary=game.send_command({"type":"start_match"})
		if not response.ok:finish(false,"start failed")
	if not host and campaign.started and not sent:
		sent=true
		if campaign.members.size()!=16:finish(false,"incomplete roster");return false
		game.send_command({"type":"move","unit_id":"ida","position":state.crew.ida.position.duplicate()})
		game.send_command({"type":"assign_team","peer_id":1,"team":1-int(campaign.team)})
	if host and began:
		var count:=0
		for i in range(1,16):
			var path:=out.path_join("client-%d.json"%i)
			if FileAccess.file_exists(path):
				var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
				if not data.ok:finish(false,"guest failure");return false
				count+=1
		if count==15:finish(true,"16 real product processes; 8 commanders per team; authority and projections verified")
	return false
func result(value:Dictionary) -> void:
	if host or not sent or value.get("pending",false):return
	print("REPLY ",value)
	replies+=1
	if replies==1 and not value.ok:failed=true
	if replies==2 and value.ok:failed=true
	if replies==2:
		var state:Dictionary=game.session.current_snapshot()
		var file:=FileAccess.open(out.path_join("client-%d.json"%index),FileAccess.WRITE)
		file.store_string(JSON.stringify({"ok":not failed,"team":state.campaign.team,"home":state.campaign.home,"members":state.campaign.members.size()}));file.close()
		# Remain connected while the host collects every participant's evidence.
func finish(ok:bool,reason:String) -> void:
	var file:=FileAccess.open(out.path_join("host.json" if host else "client-%d.json"%index),FileAccess.WRITE)
	file.store_string(JSON.stringify({"ok":ok,"reason":reason}));file.close()
	print("TEAM_NETWORK ",ok," ",reason)
	quit(0 if ok else 1)

