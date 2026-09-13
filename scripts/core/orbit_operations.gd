extends RefCounted
const Catalog=preload("res://scripts/core/catalog.gd")
const Stage=preload("res://scripts/core/stage_state.gd")
var s: Dictionary
var log_event: Callable
func bind(state: Dictionary, logger: Callable) -> void:s=state;log_event=logger
func dispatch(c: Dictionary,sender: int) -> String:
	var kind: String=c.type
	if kind!="fire_turret" and kind!="equip" and sender!=1:return "Nur der Host führt das Shuttle."
	if s.travel.active:return "Crew befindet sich auf Reise."
	match kind:
		"launch":
			if s.region!="rust" or s.ship.mode!="landed":return "Start ist auf der Rostkarte möglich."
			if s.work.active or s.salvage.active:return "Laufende Arbeit zuerst beenden."
			for id: String in s.crew:
				s.crew[id].assignment="boarding";s.crew[id].target=s.ship.position.duplicate()
			s.travel={"active":true,"from":"rust","to":"rust","remaining":0.0,"total":0.0,"phase":"boarding","kind":"launch","encounter_decided":true,"encounter_roll":99}
			log_event.call("Crew geht zum Shuttle für den Suchflug.")
		"ship_move":
			if not s.region in ["rust","space"] or s.ship.mode!="flying":return "Das Shuttle ist nicht im freien Flug."
			if not _point(c.get("position"),Catalog.bounds(s.region)):return "Flugziel liegt außerhalb der Karte."
			s.ship.target=c.position.duplicate()
		"radar_scan":
			if s.region!="rust" or s.ship.mode!="flying":return "Radar im Suchflug benutzen."
			if not s.discovery.radar_scanned:
				s.discovery.radar_scanned=true;s.discovery.signals=Catalog.radar_contacts()
				log_event.call("Radar: drei unbekannte Kontakte. Zur Identifikation nahe heranfliegen.")
		"land":
			if s.region!="rust" or s.ship.mode!="flying":return "Landung ist hier nicht möglich."
			land_here();log_event.call("Entersäbel gelandet. Crew kann aussteigen.")
		"fire_turret":
			if not s.encounter.active:return "Kein Raumkontakt aktiv."
			if s.crew.jaro.owner!=sender:return "Nur Jaros Commander bedient den Turm."
			if not c.get("target_id") is String or not c.target_id in ["pirate",""]:return "Unbekanntes Turmziel."
			s.encounter.turret_target=c.target_id
		"flee":
			if not s.encounter.active:return "Kein Raumkontakt aktiv."
			if s.encounter.escape_remaining>0:return "Rückzug läuft bereits."
			s.encounter.escape_remaining=7.0;s.encounter.turret_target=""
			log_event.call("Pilot leitet Rückzug ein. Flug bleibt ausweichbar.")
		"equip":return equip(c,sender)
		_:return "Unbekannter Flugauftrag."
	return ""
func equip(c: Dictionary,sender: int) -> String:
	if s.region!="base":return "Ausrüstung wird im Basislager gewechselt."
	var id: Variant=c.get("unit_id")
	var item: Variant=c.get("item")
	if not id is String or not s.crew.has(id):return "Person nicht gefunden."
	if s.crew[id].owner!=sender:return "Diese Person gehört dem anderen Spieler."
	if s.crew[id].assignment!="idle":return "Person ist bereits gebunden."
	if not item is String or not item in ["helmet","toolkit","cutter"]:return "Ungeeignete Ausrüstung."
	if s.inventory[item]<1:return "Ausrüstung fehlt im Lager."
	var slot: String="helmet" if item=="helmet" else "tool"
	var previous: String=s.crew[id].equipment[slot]
	if previous==item:return "Ausrüstung ist bereits angelegt."
	s.inventory[item]-=1
	if previous in ["helmet","toolkit","cutter"]:s.inventory[previous]+=1
	s.crew[id].equipment[slot]=item
	log_event.call(s.crew[id].name+" hat "+Catalog.item_name(item)+" angelegt.")
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
	s.ship.mode="landed";s.ship.target=s.ship.position.duplicate()
	var offset: float=-3.7
	var bound: float=Catalog.bounds(s.region)
	for id: String in s.crew:
		s.crew[id].position=[clampf(s.ship.position[0]+offset,-bound,bound),clampf(s.ship.position[1]+3.8,-bound,bound)]
		s.crew[id].target=s.crew[id].position.duplicate();s.crew[id].assignment="idle";offset+=7.4
func tick(delta: float) -> String:
	if s.ship.mode!="flying":return ""
	var position: Vector2=_v(s.ship.position)
	position=position.move_toward(_v(s.ship.target),(36.0 if s.region=="space" else 42.0)*delta)
	s.ship.position=[position.x,position.y];board_crew()
	if s.region=="rust" and s.discovery.radar_scanned:
		for contact: Dictionary in s.discovery.signals:
			if not contact.identified and position.distance_to(_v(contact.position))<=30.0:
				contact.identified=true
				if contact.id=="signal_01":
					contact.kind="satellite";contact.label="Satellit Signal 07";s.discovery.satellite_found=true
					log_event.call("Satellit identifiziert. Landen und die Crew zur Bergung schicken.")
				else:contact.kind="debris";contact.label="Inaktive Metallreste"
	if not s.encounter.active:return ""
	var e: Dictionary=s.encounter
	var enemy: Vector2=_v(e.enemy.position)
	enemy=enemy.move_toward(position,18.0*delta)
	e.enemy.position=[enemy.x,enemy.y];e.enemy.target=s.ship.position.duplicate()
	var distance: float=position.distance_to(enemy)
	e.fire_cooldown=maxf(0,e.fire_cooldown-delta);e.enemy_cooldown=maxf(0,e.enemy_cooldown-delta)
	if e.turret_target=="pirate" and distance<=125.0 and e.fire_cooldown<=0:
		e.enemy.hull=maxf(0,e.enemy.hull-10.0);e.fire_cooldown=0.8
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
