extends RefCounted
const Regions=preload("res://scripts/core/regions.gd")
const Catalog=preload("res://scripts/core/catalog.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
const SEATS=["pilot","gunner","passenger_1","passenger_2"]
var s: Dictionary
var logger: Callable
func bind(state: Dictionary,log_event: Callable) -> void:s=state;logger=log_event
static func empty_travel() -> Dictionary:
	return {"active":false,"from":"","to":"","remaining":0.0,"total":0.0,"phase":"idle","kind":"intermap","encounter_decided":false,"encounter_roll":-1}
func all_aboard() -> bool:
	for unit: Dictionary in s.crew.values():
		if unit.assignment!="aboard" or unit.health<=0:return false
	return not s.ship.seats.pilot.is_empty() and s.crew[s.ship.seats.pilot].assignment=="aboard"
func dispatch(c: Dictionary) -> String:
	if s.travel.active:return "Crew befindet sich auf Reise."
	if c.type=="board_crew":return _auto_board(c.get("unit_ids"))
	if c.type=="board" and c.get("role","auto")=="auto":return _auto_board([c.get("unit_id")])
	if c.type in ["board","cancel_board","disembark"]:
		if not c.get("unit_id") is String or not s.crew.has(c.unit_id):return "Person nicht gefunden."
		var unit: Dictionary=s.crew[c.unit_id]
		if s.ship.mode!="landed" or Regions.underground(s.region):return "Einstieg und Ausstieg brauchen ein gelandetes Schiff."
		if c.type=="board":
			if unit.assignment!="idle" or unit.health<=0:return "Person ist bereits gebunden."
			var role: Variant=c.get("role")
			if not role is String or not role in ["pilot","gunner","passenger"]:return "Unbekannter Sitz."
			var seat: String=role
			if role=="passenger":seat="passenger_1" if s.ship.seats.passenger_1.is_empty() else "passenger_2"
			if not s.ship.seats[seat].is_empty():return "Dieser Sitz ist belegt oder reserviert."
			var access: Array=Catalog.ship_access(s.ship)
			if Nav.path(s.region,_v(unit.position),_v(access),s.ship).is_empty():return "Schiffszugang nicht erreichbar."
			unit.seat=seat;s.ship.seats[seat]=c.unit_id;_roles()
			unit.assignment="boarding";unit.attack_target="";unit.target=access
		elif c.type=="cancel_board":
			if unit.assignment!="boarding":return "Kein Einstieg läuft."
			_free(unit);unit.assignment="idle";unit.target=unit.position.duplicate()
		else:
			if unit.assignment!="aboard":return "Person ist nicht an Bord."
			var point: Vector2=Nav.safe_near(s.region,_v(Catalog.ship_access(s.ship))+Vector2(1.4 if unit.seat=="pilot" else -1.4,1.0),s.ship)
			if not point.is_finite():return "Ausstieg ist blockiert."
			_free(unit);unit.assignment="idle";unit.position=[point.x,point.y];unit.target=unit.position.duplicate()
		return ""
	if not all_aboard():return "Alle Crewmitglieder müssen eingestiegen sein; ein Pilot wird benötigt."
	if c.type=="launch":
		if not Catalog.destination_info().has(s.region) or s.ship.mode!="landed":return "Start nur von einer Oberfläche."
		if s.ship.condition<20:return "Schiff muss repariert werden."
		s.ship.mode="flying";s.ship.target=s.ship.position.duplicate();logger.call("Schiff gestartet. Crew bleibt an Bord.");return ""
	if s.ship.mode!="flying":return "Zuerst starten."
	var destination: String
	if c.type=="enter_orbit":
		if not Catalog.destination_info().has(s.region):return "Orbitaufstieg nur von einer Oberfläche."
		destination="orbit"
	elif c.type=="travel":
		if s.region!="orbit":return "Ortsreise ist nur aus dem Orbit möglich."
		if not c.get("destination") is String or not Catalog.destination_info().has(c.destination):return "Ungültiges Reiseziel."
		destination=c.destination
	else:return "Unbekannter Reisebefehl."
	s.random_seed=(int(s.random_seed)*48271)%2147483647
	s.ship.target=s.ship.position.duplicate()
	s.travel={"active":true,"from":s.region,"to":destination,"remaining":5.0,"total":5.0,"phase":"flying","kind":"orbit" if destination=="orbit" else "intermap","encounter_decided":true,"encounter_roll":int(s.random_seed)%100}
	return ""
func tick_boarding() -> void:
	for unit: Dictionary in s.crew.values():
		if unit.assignment=="boarding" and _v(unit.position).distance_to(_v(unit.target))<0.02:unit.assignment="aboard"
		if unit.assignment=="aboard":unit.position=s.ship.position.duplicate();unit.target=unit.position.duplicate()
func arrive(destination: String) -> void:
	s.region=destination;s.ship.mode="flying"
	s.ship.position=[0.0,0.0] if destination=="orbit" else Catalog.arrival_point(destination)
	s.ship.target=s.ship.position.duplicate();s.travel=empty_travel();tick_boarding()
	logger.call("Ankunft im Flug: "+destination+". Landen und ausdrücklich aussteigen.")
func _free(unit: Dictionary) -> void:
	if s.ship.seats.has(unit.seat):s.ship.seats[unit.seat]=""
	unit.seat="";_roles()
func _roles() -> void:s.ship.roles={"pilot":s.ship.seats.pilot,"gunner":s.ship.seats.gunner}
func _auto_board(ids: Variant) -> String:
	if not ids is Array or ids.is_empty() or ids.size()>s.crew.size():return "Ungültige Crew-Auswahl."
	var pending: Array[String]=[]
	var seen: Dictionary={}
	for id: Variant in ids:
		if not id is String or not s.crew.has(id) or seen.has(id):return "Ungültige Crew-Auswahl."
		seen[id]=true
		if not s.crew[id].assignment in ["boarding","aboard"]:pending.append(id)
	# Preview the complete operation on an isolated state before reserving any seat.
	var preview: RefCounted=get_script().new()
	preview.bind(s.duplicate(true),logger)
	var commands: Array[Dictionary]=[]
	for role: String in ["pilot","gunner","passenger_1","passenger_2"]:
		if pending.is_empty():break
		if not preview.s.ship.seats[role].is_empty():continue
		var chosen: String=pending[0]
		var skill: String="pilot" if role=="pilot" else "gunnery"
		if role in ["pilot","gunner"]:
			for id: String in pending:
				if s.crew[id].skills[skill]>s.crew[chosen].skills[skill]:chosen=id
		var command: Dictionary={"type":"board","unit_id":chosen,"role":role if role in ["pilot","gunner"] else "passenger"}
		var error: String=preview.dispatch(command)
		if not error.is_empty():return error
		commands.append(command);pending.erase(chosen)
	if not pending.is_empty():return "Nicht genügend freie Sitze."
	for command: Dictionary in commands:dispatch(command)
	return ""
func _v(a: Array) -> Vector2:return Vector2(a[0],a[1])
