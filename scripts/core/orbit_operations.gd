extends RefCounted
const Regions=preload("res://scripts/core/regions.gd")
const Catalog=preload("res://scripts/core/catalog.gd")
const Stage=preload("res://scripts/core/stage_state.gd")
const Flight=preload("res://scripts/core/flight_navigation.gd")
var _path: Array=[]
var _path_key:= ""
var s: Dictionary
var log_event: Callable
func bind(state: Dictionary, logger: Callable) -> void:
	s=state;log_event=logger;_path=[];_path_key=""
	if not s.ship.has("order"):s.ship.order={}
	if s.ship.mode=="flying":
		var position:=_v(s.ship.position)
		var safe:=Flight.safe_near(s.region,s.ship.model,position)
		if safe.is_finite() and not safe.is_equal_approx(position):
			s.ship.position=[safe.x,safe.y];board_crew()
			log_event.call("Alter Flugstand an neue Hindernisse angepasst: Schiff auf freien Nachbarpunkt gesetzt.")
		if not Flight.clear(s.region,s.ship.model,_v(s.ship.target),_v(s.ship.target)):
			s.ship.target=s.ship.position.duplicate();s.ship.order={}
			log_event.call("Altes Flugziel liegt in einem Hindernis. Pilot hält; neues Ziel wählen.")

func dispatch(c: Dictionary,sender: int) -> String:
	var kind: String=c.type
	if s.travel.active:return "Crew befindet sich auf Reise."
	match kind:
		"ship_move":
			if not s.region in (Regions.DESTINATIONS+["orbit","space"]) or s.ship.mode!="flying":return "Das Shuttle ist nicht im freien Flug."
			if not _point(c.get("position"),Catalog.bounds(s.region)):return "Flugziel liegt außerhalb der Karte."
			var route:=Flight.path(s.region,s.ship.model,_v(s.ship.position),_v(c.position))
			if route.is_empty():return "Flugziel blockiert oder nicht sicher erreichbar. Einen freien Punkt neben dem Hindernis wählen."
			s.ship.order={};s.ship.target=c.position.duplicate();_path=route;_path_key=_key()
		"ship_order":
			return _order(c)
		"radar_scan":
			if Regions.archetype(s.region)!="rust" or s.ship.mode!="flying":return "Radar im Suchflug benutzen."
			if not s.discovery.radar_scanned:
				s.discovery.radar_scanned=true;s.discovery.signals=Catalog.radar_contacts(s.region)
				log_event.call("Radar: drei unbekannte Kontakte. Zur Identifikation nahe heranfliegen.")
		"land":
			if not Catalog.destination_info().has(s.region) or s.ship.mode!="flying":return "Landung ist hier nicht möglich."
			var candidate: Dictionary=s.ship.duplicate(true)
			candidate.mode="landed";candidate.yaw=0.0
			if not preload("res://scripts/core/ground_navigation.gd").landing_clear(s.region,candidate):return "Landefläche oder Zugang blockiert. Weiter entfernt landen."
			land_here();log_event.call("Schiff gelandet. Crew kann ausdrücklich aussteigen.")
		"fire_turret":
			if not s.encounter.active:return "Kein Raumkontakt aktiv."
			if s.ship.model=="vulture" or s.ship.roles.gunner.is_empty() or s.crew[s.ship.roles.gunner].assignment!="aboard":return "Ein besetzter Kampfturm wird benötigt."
			if not c.get("target_id") is String or not c.target_id in ["pirate",""]:return "Unbekanntes Turmziel."
			s.encounter.turret_target=c.target_id
		"flee":
			if not s.encounter.active:return "Kein Raumkontakt aktiv."
			if s.encounter.escape_remaining>0:return "Rückzug läuft bereits."
			s.encounter.escape_remaining=7.0;s.encounter.turret_target=""
			log_event.call("Pilot leitet Rückzug ein. Flug bleibt ausweichbar.")
		_:return "Unbekannter Flugauftrag."
	return ""
func roll_station_contact() -> int:
	s.random_seed=(int(s.random_seed)*48271)%2147483647
	return int(s.random_seed)%100
func start_encounter(destination: String) -> void:
	s.region="space";s.ship.mode="flying";s.ship.position=[-85.0,0.0];s.ship.target=s.ship.position.duplicate()
	s.encounter={"active":true,"status":"active","pending_destination":destination,"enemy":{"id":"pirate","name":"Freibeuter","model":"buccaneer","position":[55.0,-25.0],"target":[-85.0,0.0],"hull":40.0,"max_hull":40.0},"turret_target":"","fire_cooldown":0.0,"enemy_cooldown":2.5,"escape_remaining":0.0}
	board_crew();log_event.call("Raumkontakt: ein Freibeuter nähert sich. Ausweichen, Turm nutzen oder fliehen.")
func board_crew() -> void:
	for id: String in s.crew:
		s.crew[id].assignment="aboard";s.crew[id].position=s.ship.position.duplicate();s.crew[id].target=s.ship.position.duplicate()
func land_here() -> void:
	s.ship.order={};_path=[];s.ship.mode="landed";s.ship.yaw=0.0;s.ship.target=s.ship.position.duplicate()
func tick(delta: float) -> String:
	if s.ship.mode!="flying":return ""
	var position: Vector2=_v(s.ship.position)
	var order: Dictionary=s.ship.get("order",{})
	if not order.is_empty() and order.region!=s.region:s.ship.order={};order={}
	if position.distance_to(_v(s.ship.target))<0.1 and not order.is_empty():
		if order.kind=="search" and int(order.index)+1>=order.points.size():
			s.ship.order={};log_event.call("Suchraster abgeflogen. Neue Hinweise im Radar prüfen.")
		else:
			order.index=(int(order.index)+1)%order.points.size()
			s.ship.target=order.points[int(order.index)].duplicate()
	if position.distance_to(_v(s.ship.target))>0.1:
		if _path_key!=_key():_path=Flight.path(s.region,s.ship.model,position,_v(s.ship.target));_path_key=_key()
		if _path.is_empty():
			s.ship.target=s.ship.position.duplicate();s.ship.order={}
			log_event.call("Pilot hält an: kein sicherer Flugweg. Neues Ziel wählen.")
		else:
			var budget: float=(36.0 if s.region=="space" else 42.0)*Catalog.skill_effects(s.crew[s.ship.roles.pilot]).flight_multiplier*delta
			while budget>0 and not _path.is_empty():
				var next: Vector2=_path[0];var distance:=position.distance_to(next)
				if distance>0.01:s.ship.yaw=atan2(position.x-next.x,position.y-next.y)
				position=position.move_toward(next,budget);budget-=distance
				if position.distance_to(next)<0.01:_path.pop_front()

	s.ship.position=[position.x,position.y];board_crew()
	if Regions.archetype(s.region)=="rust" and s.discovery.radar_scanned:
		for contact: Dictionary in s.discovery.signals:
			if not contact.identified and position.distance_to(_v(contact.position))<=30.0:
				contact.identified=true
				if contact.id=="signal_01":
					contact.kind="satellite";contact.label="Satellit Signal 07";s.discovery.satellite_found=true
					log_event.call("Satellit identifiziert. Landen und die Crew zur Bergung schicken.")
				else:
					contact.kind="mining_site" if contact.id=="signal_02" else "derelict"
					contact.label="Erzvorkommen" if contact.id=="signal_02" else "Verlassenes Schiffswrack"
	if not s.encounter.active:return ""
	var e: Dictionary=s.encounter
	var enemy: Vector2=_v(e.enemy.position)
	enemy=enemy.move_toward(position,18.0*delta)
	e.enemy.position=[enemy.x,enemy.y];e.enemy.target=s.ship.position.duplicate()
	var distance: float=position.distance_to(enemy)
	if e.turret_target=="pirate":s.ship.turret_yaw=atan2(position.x-enemy.x,position.y-enemy.y)
	e.fire_cooldown=maxf(0,e.fire_cooldown-delta);e.enemy_cooldown=maxf(0,e.enemy_cooldown-delta)
	if e.turret_target=="pirate" and s.ship.model!="vulture" and not s.ship.roles.gunner.is_empty() and distance<=125.0 and e.fire_cooldown<=0:
		e.enemy.hull=maxf(0,e.enemy.hull-Catalog.skill_effects(s.crew[s.ship.roles.gunner]).turret_damage);e.fire_cooldown=0.8
	if e.enemy.hull<=0:
		e.active=false;e.status="won";e.turret_target=""
		log_event.call("Freibeuter ausgeschaltet. Reise wird fortgesetzt.")
		return e.pending_destination
	if distance<=105.0 and e.enemy_cooldown<=0:
		s.ship.condition=maxf(0,s.ship.condition-5.0);e.enemy_cooldown=2.5
	if s.ship.condition<=0:
		e.active=false;e.status="rescued";e.turret_target="";e.escape_remaining=0.0
		s.ship.condition=50.0
		log_event.call("Notbergung: beide Crewmitglieder und Shuttle zurück zur Basis. Keine dauerhaften Verluste.")
		return "base"
	if e.escape_remaining>0:
		e.escape_remaining=maxf(0,e.escape_remaining-delta)
		if e.escape_remaining<=0:
			e.active=false;e.status="escaped"
			log_event.call("Rückzug gelungen. Reise wird fortgesetzt.")
			return e.pending_destination
	return ""
func _v(point: Array) -> Vector2:return Vector2(point[0],point[1])
func _point(value: Variant,bound: float) -> bool:
	return value is Array and value.size()==2 and (value[0] is float or value[0] is int) and (value[1] is float or value[1] is int) and is_finite(float(value[0])) and is_finite(float(value[1])) and absf(value[0])<=bound and absf(value[1])<=bound

func _key() -> String:return str(s.region)+str(s.ship.model)+str(s.ship.target)

func _order(c: Dictionary) -> String:
	if s.ship.mode!="flying":return "Flugauftrag erst nach dem Abheben."
	var mode: Variant=c.get("mode")
	if not mode is String or not mode in ["patrol","search","stop"]:return "Unbekannter Flugauftrag."
	if mode=="stop":
		s.ship.order={};s.ship.target=s.ship.position.duplicate();_path=[];log_event.call("Schiff hält Position.");return ""
	var start:=_v(s.ship.position)
	var points: Array=[]
	if mode=="patrol":
		if not _point(c.get("position"),Catalog.bounds(s.region)):return "Patrouillenpunkt auf der Karte wählen."
		if start.distance_to(_v(c.position))<10:return "Patrouillenpunkte mindestens 10 m auseinander wählen."
		points=[c.position.duplicate(),s.ship.position.duplicate()]
	else:
		# Local 180 m sweep, not an unexplained omniscient flight to hidden contacts.
		var limit: float=Flight.data(s.region,s.ship.model).bound-10
		var center: Vector2=_v(c.position) if _point(c.get("position"),limit) else start
		for row in range(5):
			for side: float in ([-1.0,1.0] if row%2==0 else [1.0,-1.0]):
				var at:=Vector2(clampf(center.x+side*90,-limit,limit),clampf(center.y-90+row*45,-limit,limit))
				if Flight.clear(s.region,s.ship.model,at,at):points.append([at.x,at.y])
	if points.size()<2:return "Kein freies Suchgebiet. Anderen Mittelpunkt wählen."
	var previous:=start
	for point: Array in points:
		if Flight.path(s.region,s.ship.model,previous,_v(point)).is_empty():return "Auftrag enthält nicht erreichbare Flugpunkte. Anderes Gebiet wählen."
		previous=_v(point)
	s.ship.order={"kind":mode,"region":str(s.region),"points":points,"index":0}
	s.ship.target=points[0].duplicate();_path_key=""
	if mode=="search" and Regions.archetype(s.region)=="rust":dispatch({"type":"radar_scan"},1)
	log_event.call("Patrouille aktiv. Rechtsklick ersetzt den Auftrag." if mode=="patrol" else "Suchraster aktiv: 180 × 180 m, Radar und Identifikation beim Vorbeiflug.")
	return ""
