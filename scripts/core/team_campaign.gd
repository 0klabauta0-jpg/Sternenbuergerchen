extends Node
## Authoritative aggregate for independent team careers. UI receives its own projection.
signal state_changed
signal notice(message:String)
const Core=preload("res://scripts/core/simulation_root.gd")
const Validator=preload("res://scripts/core/save_validator.gd")
const Combat=preload("res://scripts/core/team_combat.gd")
const Roster=preload("res://scripts/core/team_roster.gd")
const PLANETS:Dictionary={"rust":"Rostwelt","ice":"Frostmark","basalt":"Schlacke","mineral":"Grünschiefer"}
var auto_tick:=true
var roster:RefCounted=Roster.new()
var _cores:Array[Node]=[]
var _homes:Array[String]=["rust","ice"]
var _planets:Array[String]=["rust","ice"]
var _revision:=0
var _receipts:Dictionary={}
var _combat:RefCounted=Combat.new()
var _pending_planets:Array[String]=["",""]
var _worlds:Dictionary={}
var _personal:Array[Dictionary]=[{},{}]
var _ai:Array[bool]=[false,false]
var _ai_elapsed:=0.0
var _started:=false
var _paused:=true

func _init(seed_value:int=-1) -> void:
	for team in 2:
		var core:Node=Core.new(seed_value+team if seed_value>=0 else -1)
		core.auto_tick=false
		_cores.append(core)
func _bind_world(team:int,planet:String) -> void:
	var state:Dictionary=_cores[team]._state
	_personal[team][_planets[team]]={"discovery":state.discovery.duplicate(true),"wreck_remaining":state.wreck_remaining}
	_planets[team]=planet
	state.resources=_worlds[planet].resources
	state.ground.enemies=_worlds[planet].enemies
	var personal:Dictionary=_personal[team].get(planet,{})
	if personal.is_empty():
		var seed_core:Node=Core.new(3)
		personal={"discovery":seed_core._state.discovery.duplicate(true),"wreck_remaining":8}
		seed_core.free()
	state.discovery=personal.discovery.duplicate(true);state.wreck_remaining=personal.wreck_remaining

func _ready() -> void:
	for team in 2:
		var core:Node=_cores[team];core.name="Team%d"%team;add_child(core)
		core.notice.connect(func(message:String):
			if roster.team_for(1)==team:notice.emit("Team %d · %s"%[team+1,message]))
	for planet:String in PLANETS:
		_worlds[planet]={"resources":_cores[0]._state.resources.duplicate(true),"enemies":_cores[0]._state.ground.enemies.duplicate(true)}
	for team in 2:_bind_world(team,_planets[team])
func _physics_process(delta:float) -> void:
	if auto_tick:advance(delta)
func _changed() -> void:
	_revision+=1;state_changed.emit()
func set_guest(peer:int) -> void:
	var team:=0 if roster.count(0)<8 else 1
	var reason:String=roster.join(peer,team)
	if not reason.is_empty():notice.emit(reason)
	_changed()
func accepts_peer(peer:int) -> bool:return roster.team_for(peer)>=0
func clear_guest(peer:int=0) -> void:
	if peer==0:
		for id:int in roster.members():
			if id!=1:roster.leave(id)
	else:roster.leave(peer)
	_paused=true
	for core:Node in _cores:core._state.paused=true
	_changed()
func snapshot() -> Dictionary:return snapshot_for(1)
func snapshot_for(peer:int) -> Dictionary:
	var team:int=roster.team_for(peer)
	if team<0:return {}
	var state:Dictionary=_cores[team].snapshot()
	state.revision=_revision;state.paused=_paused
	state.campaign={"team":team,"home":_homes[team],"planet":_planets[team],"started":_started,"lobby_open":not roster.locked,"members":roster.members(),"homes":_homes.duplicate(),"planets":PLANETS.duplicate(),"max_per_team":8,"ai":_ai.duplicate()}
	_combat.project(state,_cores,_planets,team)
	return state
func submit(command:Dictionary,sender_id:int=1) -> Dictionary:
	var id:Variant=command.get("request_id")
	if not id is String or id.is_empty() or id.length()>120:return _result(false,"Eindeutige Anfrage-ID fehlt.","")
	var key:=str(sender_id)+":"+str(id)
	if _receipts.has(key):return _receipts[key].duplicate(true)
	var team:int=roster.team_for(sender_id)
	var reason:=""
	if team<0:reason="Absender ist nicht Teil der Sitzung."
	elif not command.get("type") is String:reason="Befehlstyp fehlt."
	else:
		match str(command.type):
			"assign_team":
				if not Validator.whole(command.get("peer_id"),1,2147483647) or not Validator.whole(command.get("team"),0,1):reason="Teilnehmer oder Team ungültig."
				else:reason=roster.assign(sender_id,int(command.peer_id),int(command.team))
			"select_home":
				if sender_id!=1 or _started:reason="Heimatwahl nur durch den Host vor Partiebeginn."
				elif not Validator.whole(command.get("team"),0,1) or not PLANETS.has(command.get("planet")):reason="Startwelt ungültig."
				elif _homes[1-int(command.team)]==command.planet:reason="Gegner brauchen unterschiedliche Startwelten."
				else:_homes[int(command.team)]=command.planet;_bind_world(int(command.team),command.planet)
			"set_team_ai":
				if sender_id!=1 or roster.locked:reason="KI nur durch den Host in der offenen Lobby wählen."
				elif not Validator.whole(command.get("team"),0,1) or not command.get("enabled") is bool:reason="KI-Zuordnung ungültig."
				else:_ai[int(command.team)]=command.enabled
			"start_match":
				if sender_id!=1:reason="Nur der Host startet die Partie."
				elif (roster.count(0)==0 and not _ai[0]) or (roster.count(1)==0 and not _ai[1]):reason="Beide Teams brauchen mindestens einen Commander oder eine KI."
				else:
					_started=true;roster.locked=true;_paused=false
					for core:Node in _cores:core._state.paused=false
			"open_lobby":
				if sender_id!=1:reason="Nur der Host öffnet die Lobby."
				else:roster.locked=false;_paused=true
			"toggle_pause":
				if not _started or not roster.locked:reason="Zuerst die Partie bei geschlossener Lobby starten."
				else:_paused=not _paused
			"travel_planet":
				if not _started or not roster.locked:reason="Zuerst die Partie starten."
				elif not PLANETS.has(command.get("planet")):reason="Unbekannter Planet."
				else:
					var result:Dictionary=_cores[team].submit({"type":"travel","destination":"rust","request_id":key.sha256_text()},1)
					if result.ok:_pending_planets[team]=command.planet
					else:reason=result.reason
			_:
				if not _started or not roster.locked:reason="Zuerst die Partie in der Team-Lobby starten."
				elif command.type=="attack" and command.get("target_id") is String and str(command.target_id).begins_with("team"):
					reason=_combat.attack(_cores,_planets,team,str(command.get("unit_id","")),command.target_id)
				else:
					var request:Dictionary=command.duplicate(true)
					# A verified peer selects a team. Payload fields cannot select another core.
					request.request_id=key.sha256_text()
					var result:Dictionary=_cores[team].submit(request,1)
					if not result.ok:reason=str(result.reason)
					else:
						if command.get("unit_id") is String:_combat.cancel(team,str(command.unit_id))
						if command.type=="travel" and command.get("destination")=="base":_pending_planets[team]=_homes[team]
	for core:Node in _cores:core._state.paused=_paused
	var result:=_result(reason.is_empty(),reason if not reason.is_empty() else "Bestätigt.",str(id))
	_receipts[key]=result
	if result.ok:_changed()
	return result.duplicate(true)
func advance(delta:float) -> void:
	if not _started or not roster.locked or _paused or not is_finite(delta) or delta<=0:return
	var remaining:=minf(delta,3600)
	while remaining>0.00001:
		var step:=minf(remaining,0.05)
		for team in 2:
			_cores[team].advance(step)
			var state:Dictionary=_cores[team]._state
			if not _pending_planets[team].is_empty() and not state.travel.active and state.region in ["base","rust"]:
				_bind_world(team,_pending_planets[team]);_pending_planets[team]=""
		for core:Node in _cores:
			var activity:Dictionary=core._state.ground.activity
			if activity.active and int(core._state.resources[activity.site_id].remaining)<=0:core._ground.stop_activity()
		_combat.tick(_cores,_planets,step)
		remaining-=step
	_ai_elapsed+=delta
	if _ai_elapsed>=2:
		_ai_elapsed=0
		for team in 2:
			if not _ai[team]:continue
			var command:Dictionary=preload("res://scripts/core/team_ai.gd").decide(_cores[team].snapshot())
			if command.is_empty():continue
			command.request_id="ai-%d-%d"%[_revision,int(_cores[team]._state.revision)]
			_cores[team].submit(command,1)
	_changed()
func _result(ok:bool,reason:String,id:String="") -> Dictionary:return {"ok":ok,"reason":reason,"request_id":id}

func _payload() -> Dictionary:
	for team in 2:
		var state:Dictionary=_cores[team]._state
		_personal[team][_planets[team]]={"discovery":state.discovery.duplicate(true),"wreck_remaining":state.wreck_remaining}
	return {"format":"sternen-team-campaign","version":2,"host_team":roster.team_for(1),"worlds":_worlds.duplicate(true),"personal":_personal.duplicate(true),"teams":[_cores[0].export_payload(),_cores[1].export_payload()],"homes":_homes.duplicate(),"planets":_planets.duplicate(),"started":_started,"paused":_paused,"receipts":_receipts.duplicate(true),"ai":_ai.duplicate(),"combat":_combat.orders.duplicate(true),"pending_planets":_pending_planets.duplicate()}
func _validate(value:Variant) -> String:
	if not value is Dictionary or value.get("format")!="sternen-team-campaign" or value.get("version")!=2:return "Teamformat ungültig."
	if not value.get("teams") is Array or value.teams.size()!=2:return "Zwei Teamzustände erforderlich."
	for team:Variant in value.teams:
		var reason:String=Validator.validate(team)
		if not reason.is_empty():return reason
	for key:String in ["homes","planets"]:
		if not value.get(key) is Array or value[key].size()!=2:return "Planetenzuordnung fehlt."
		for id:Variant in value[key]:
			if not PLANETS.has(id):return "Unbekannte Welt."
	if not value.get("ai",[false,false]) is Array or value.get("ai",[false,false]).size()!=2:return "KI-Zuordnung fehlt."
	for entry:Variant in value.get("ai",[false,false]):
		if not entry is bool:return "KI-Zuordnung ungültig."
	if not Validator.whole(value.get("host_team"),0,1):return "Host-Team fehlt."
	if not value.get("worlds") is Dictionary or value.worlds.size()!=4 or not value.get("personal") is Array or value.personal.size()!=2:return "Planetenstände fehlen."
	for planet:String in PLANETS:
		var world:Variant=value.worlds.get(planet)
		if not world is Dictionary or not world.get("resources") is Dictionary or not world.get("enemies") is Dictionary:return "Planetenstand ungültig."
		var probe:Dictionary=value.teams[0].duplicate(true)
		# Verify world records without unrelated active crew bindings.
		var seed_core:Node=Core.new(3);probe=seed_core.export_payload();seed_core.free()
		probe.state.resources=world.resources;probe.state.ground.enemies=world.enemies
		if not Validator.validate(probe).is_empty():return "Weltbestand ungültig."
	for team in 2:
		if not value.personal[team] is Dictionary or value.personal[team].size()>4:return "Erkundungsstände ungültig."
		for planet:Variant in value.personal[team]:
			if not PLANETS.has(planet):return "Erkundungswelt ungültig."
			var record:Variant=value.personal[team][planet]
			if not record is Dictionary or not record.has("discovery") or not Validator.whole(record.get("wreck_remaining"),0,8):return "Erkundung ungültig."
			var seed_core:Node=Core.new(3)
			var probe:Dictionary=seed_core.export_payload();seed_core.free()
			probe.state.discovery=record.discovery;probe.state.wreck_remaining=record.wreck_remaining
			if not Validator.validate(probe).is_empty():return "Erkundung widersprüchlich."
		if value.teams[team].state.resources!=value.worlds[value.planets[team]].resources or value.teams[team].state.ground.enemies!=value.worlds[value.planets[team]].enemies:return "Team und Weltbestand widersprechen sich."
	if value.homes[0]==value.homes[1]:return "Startplätze doppelt belegt."
	if not value.get("started") is bool or not value.get("paused") is bool or not value.get("receipts") is Dictionary:return "Sitzungszustand ungültig."
	if value.receipts.size()>1000000:return "Zu viele Anfragebelege."
	for key:Variant in value.receipts:
		var receipt:Variant=value.receipts[key]
		if not key is String or key.length()>150 or not receipt is Dictionary or not receipt.get("ok") is bool or not receipt.get("reason") is String or not receipt.get("request_id") is String:return "Anfragebeleg ungültig."
	if not _combat.validate(value.get("combat",{}),_cores):return "Kampfauftrag ungültig."
	if not value.get("pending_planets",[]) is Array or value.get("pending_planets",[]).size()!=2:return "Reisezielzuordnung fehlt."
	for planet:Variant in value.pending_planets:
		if planet!="" and not PLANETS.has(planet):return "Reiseziel ungültig."
	return ""
func save_game(path:String) -> Dictionary:
	var data:=_payload();var error:=_validate(data)
	if not error.is_empty():return _result(false,error)
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:return _result(false,"Speicherdatei nicht schreibbar.")
	file.store_string(JSON.stringify(data));file.flush();var status:=file.get_error();file.close()
	if status!=OK or not _validate(JSON.parse_string(FileAccess.get_file_as_string(path+".tmp"))).is_empty():return _result(false,"Team-Speicherprüfung fehlgeschlagen.")
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))!=OK:return _result(false,"Team-Spielstand nicht atomar ersetzbar.")
	return _result(true,"Team-Partie gespeichert.")
func load_game(path:String) -> Dictionary:
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>32000000:return _result(false,"Team-Spielstand nicht lesbar.")
	var data:Variant=JSON.parse_string(file.get_as_text());file.close()
	var error:=_validate(data)
	if not error.is_empty():return _result(false,error)
	# All participants and receipts validate before either core is changed.
	if roster.team_for(1)!=int(data.host_team) and roster.count(int(data.host_team))>=8:return _result(false,"Gespeichertes Host-Team ist voll. Erst einen Platz freimachen.")
	roster.locked=false;roster.assign(1,1,int(data.host_team))
	for i in 2:_cores[i].restore_payload(data.teams[i])
	_worlds=data.worlds.duplicate(true);_personal.assign(data.personal.duplicate(true))
	_ai.assign(data.get("ai",[false,false]))
	_homes.assign(data.homes);_planets.assign(data.planets);_started=data.started;_paused=data.paused
	_receipts=data.receipts.duplicate(true)
	_combat.orders=data.get("combat",{}).duplicate(true)
	_pending_planets.assign(data.pending_planets)
	for team in 2:
		_cores[team]._state.resources=_worlds[_planets[team]].resources
		_cores[team]._state.ground.enemies=_worlds[_planets[team]].enemies
	roster.locked=_started
	if _started and roster.members().size()==1 and not _ai[1-roster.team_for(1)]:
		roster.locked=false;_paused=true
	for core:Node in _cores:core._state.paused=_paused
	_changed()
	return _result(true,"Team-Partie geladen.")
