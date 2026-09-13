extends Node
class_name RestartSimulation

const Catalog = preload("res://scripts/core/catalog.gd")
const Validator = preload("res://scripts/core/save_validator.gd")
const LegacyValidator = preload("res://scripts/core/legacy_validator_v1.gd")
const Stage = preload("res://scripts/core/stage_state.gd")
const Orbit = preload("res://scripts/core/orbit_operations.gd")
signal state_changed
signal notice(message: String)
var auto_tick: bool = true
var _guest_id: int = 0
var _receipts: Dictionary = {}
var _state: Dictionary = {}
var _orbit: RefCounted = Orbit.new()

func _init(seed_value: int = -1) -> void:
	_state = {
		"schema_version":1,"revision":0,"time":0.0,"paused":false,"region":"base","credits":180,
		"inventory":_empty_items(),"cargo":_empty_items(),"blueprints":["toolkit","repair"],
		"ship":{"condition":72.0,"capacity":12},
		"crew":{
			"ida":{"id":"ida","name":"Ida","skill":3,"owner":1,"position":[-1.0,1.0],"target":[-1.0,1.0],"assignment":"idle"},
			"jaro":{"id":"jaro","name":"Jaro","skill":1,"owner":1,"position":[1.0,2.0],"target":[1.0,2.0],"assignment":"idle"}},
		"contract":{"status":"available","reward":260},"work":_empty_work(),"salvage":_empty_salvage(),"travel":_empty_travel(),
		"wreck_remaining":8,"log":["Willkommen daheim. Ein Bergungsauftrag wartet an der Konsole."]}
	_state.inventory.scrap = 8
	_state.inventory.parts = 3
	Stage.extend(_state,seed_value)
	_state.crew.ida.position=[0.0,0.0];_state.crew.ida.target=[0.0,0.0]
	_state.crew.jaro.position=[1.0,1.0];_state.crew.jaro.target=[1.0,1.0]
	_orbit.bind(_state,_log)

func _empty_items() -> Dictionary:
	return {"scrap":0,"parts":0,"toolkit":0,"cutter":0,"blackbox":0}

func _empty_work() -> Dictionary:
	return {"active":false,"unit_id":"","recipe_id":"","remaining":0.0,"total":0.0,"phase":"idle","reserved":{}}

func _empty_salvage() -> Dictionary:
	return {"active":false,"unit_id":"","remaining":0.0,"total":0.0,"phase":"idle"}

func _empty_travel() -> Dictionary:
	return {"active":false,"from":"","to":"","remaining":0.0,"total":0.0,"phase":"idle","kind":"intermap","encounter_decided":false,"encounter_roll":-1}

func snapshot() -> Dictionary:
	return _state.duplicate(true)

func _physics_process(delta: float) -> void:
	if auto_tick:
		advance(delta)

func _changed() -> void:
	_state.revision += 1
	state_changed.emit()

func _log(message: String) -> void:
	_state.log.append(message)
	if _state.log.size() > 30:
		_state.log.pop_front()
	notice.emit(message)

func _result(ok: bool, reason: String, request_id: String = "") -> Dictionary:
	return {"ok":ok,"reason":reason,"request_id":request_id}

func submit(command: Dictionary, sender_id: int = 1) -> Dictionary:
	var request: Variant = command.get("request_id", "")
	if not request is String or request.is_empty() or request.length() > 120:
		return _result(false, "Eindeutige Anfrage-ID fehlt.")
	var receipt_key: String = str(sender_id) + ":" + request
	if _receipts.has(receipt_key):
		return _receipts[receipt_key].duplicate(true)
	var reason: String = ""
	if sender_id != 1 and (sender_id != _guest_id or _guest_id == 0):
		reason = "Absender ist nicht Teil der Sitzung."
	elif not command.get("type") is String:
		reason = "Befehlstyp fehlt."
	else:
		reason = _dispatch(command, sender_id)
	var result: Dictionary = _result(reason.is_empty(), reason if not reason.is_empty() else "Bestätigt.", request)
	_receipts[receipt_key] = result
	if result.ok:
		_changed()
	else:
		notice.emit(reason)
	return result.duplicate(true)

func _dispatch(command: Dictionary, sender: int) -> String:
	var kind: String = command.type
	if kind in ["accept_contract","travel","claim_contract","trade","transfer","toggle_pause"] and sender != 1:
		return "Nur der Host steuert Reise, Handel und Sitzung."
	if kind == "toggle_pause":
		_state.paused = not _state.paused
		return ""
	if kind in ["launch","ship_move","radar_scan","land","fire_turret","flee","equip"]:
		return _orbit.dispatch(command,sender)
	if _state.travel.active:
		return "Crew befindet sich auf Reise."
	match kind:
		"move":
			var error: String = _unit_error(command.get("unit_id"), sender)
			if not error.is_empty(): return error
			if not Validator.position_valid(command.get("position"), Catalog.bounds(_state.region)):
				return "Ziel liegt außerhalb der Karte."
			_state.crew[command.unit_id].target = command.position.duplicate()
		"accept_contract":
			if _state.region != "base" or _state.contract.status != "available": return "Kein neuer Auftrag verfügbar."
			_state.contract.status = "active"
			_log("Satellitenbergung angenommen. Die Rostwelt ist bereit.")
		"assign_work": return _start_work(command, sender)
		"upgrade_workbench":
			if sender!=1:return "Nur der Host baut die Werkbank aus."
			var request: Dictionary=command.duplicate(true)
			request.recipe_id="upgrade_workbench"
			return _start_work(request,sender)
		"cancel_work":
			if not _state.work.active: return "Keine Arbeit aktiv."
			if _state.crew[_state.work.unit_id].owner != sender: return "Diese Arbeit gehört dem anderen Spieler."
			for item: String in _state.work.reserved:
				_state.inventory[item] += _state.work.reserved[item]
			_release(_state.work.unit_id)
			_state.work = _empty_work()
			_log("Arbeit abgebrochen. Material zurück im Lager.")
		"travel": return _start_travel(command)
		"salvage": return _start_salvage(command, sender)
		"cancel_salvage":
			if not _state.salvage.active: return "Keine Bergung aktiv."
			if _state.crew[_state.salvage.unit_id].owner != sender: return "Diese Bergung gehört dem anderen Spieler."
			_release(_state.salvage.unit_id)
			_state.salvage = _empty_salvage()
			_log("Bergung abgebrochen.")
		"claim_contract":
			if _state.region != "base" or _state.contract.status != "recovered" or _state.inventory.blackbox != 1:
				return "Blackbox muss zuerst zur Basis zurück."
			_state.inventory.blackbox = 0
			_state.contract.status = "claimed"
			_state.credits += _state.contract.reward
			_state.blueprints.append("cutter")
			_log("Auftrag bezahlt: 260 Credits und Bauplan Schneidwerkzeug.")
		"trade": return _trade(command)
		"transfer": return _transfer(command)
		_: return "Unbekannter Befehl."
	return ""

func _unit_error(unit_id: Variant, sender: int) -> String:
	if not unit_id is String or not _state.crew.has(unit_id): return "Person nicht gefunden."
	var unit: Dictionary = _state.crew[unit_id]
	if unit.owner != sender: return "Diese Person gehört dem anderen Spieler."
	if unit.assignment != "idle": return "Person ist bereits gebunden."
	return ""

func _start_work(command: Dictionary, sender: int) -> String:
	if _state.region != "base": return "Die Werkbank steht in der Basis."
	if _state.work.active: return "Werkbank ist belegt."
	var error: String = _unit_error(command.get("unit_id"), sender)
	if not error.is_empty(): return error
	var recipe_id: Variant = command.get("recipe_id")
	if not recipe_id is String or not Catalog.recipes().has(recipe_id): return "Unbekanntes Rezept."
	if not _state.blueprints.has(recipe_id): return "Bauplan fehlt."
	var recipe: Dictionary = Catalog.recipes()[recipe_id]
	if _state.base.workbench_tier < recipe.tier:return "Werkbankstufe reicht nicht. Erst die Werkbank ausbauen."
	if recipe_id=="upgrade_workbench" and _state.base.workbench_tier>=2:return "Werkbank ist bereits auf Stufe 2."
	if recipe_id=="upgrade_workbench" and sender!=1:return "Nur der Host baut die Werkbank aus."
	var unit: Dictionary = _state.crew[command.unit_id]
	if unit.skill < recipe.min_skill: return "Technikkenntnis reicht nicht. Ida kann helfen."
	if recipe_id == "repair" and _state.ship.condition >= 100.0: return "Shuttle ist bereits repariert."
	for item: String in recipe.materials:
		if _state.inventory[item] < recipe.materials[item]: return "Material im Basislager fehlt."
	for item: String in recipe.materials:
		_state.inventory[item] -= recipe.materials[item]
	unit.assignment = "work"
	unit.target = Catalog.interaction_point("base", "workbench")
	_state.work = {"active":true,"unit_id":command.unit_id,"recipe_id":recipe_id,"remaining":recipe.duration,"total":recipe.duration,"phase":"walking","reserved":recipe.materials.duplicate(true)}
	_log(unit.name + " geht zur Werkbank. Material reserviert.")
	return ""

func _start_travel(command: Dictionary) -> String:
	if _state.encounter.active:return "Raumkontakt erst lösen oder fliehen."
	var destination: Variant = command.get("destination")
	if not destination is String or not destination in ["base","rust","station"] or destination == _state.region:
		return "Ungültiges Reiseziel."
	if _state.work.active or _state.salvage.active: return "Erst laufende Arbeit beenden oder abbrechen."
	if _state.ship.condition < 20.0: return "Shuttle muss repariert werden."
	for unit_id: String in _state.crew:
		var unit: Dictionary = _state.crew[unit_id]
		unit.assignment = "boarding"
		unit.target = _state.ship.position.duplicate()
	var roll: int = _orbit.roll_station_contact() if destination=="station" else 99
	_state.travel = {"active":true,"from":_state.region,"to":destination,"remaining":5.0,"total":5.0,"phase":"flying" if _state.ship.mode=="flying" else "boarding","kind":"intermap","encounter_decided":true,"encounter_roll":roll}
	_log("Crew sammelt sich am Shuttle Entersäbel.")
	return ""

func _start_salvage(command: Dictionary, sender: int) -> String:
	if _state.region != "rust": return "Bergung ist nur am Satelliten möglich."
	if not _state.discovery.satellite_found:return "Satellit zuerst mit dem Shuttle und Radar finden."
	if _state.ship.mode!="landed":return "Vor der Bergung landen."
	if _state.contract.status == "available": return "Zuerst den Bergungsauftrag annehmen."
	if _state.salvage.active: return "Am Satelliten wird bereits gearbeitet."
	if _state.wreck_remaining <= 0: return "Wrack ist vollständig geborgen."
	if _cargo_count() >= _state.ship.capacity: return "Frachtraum ist voll."
	var error: String = _unit_error(command.get("unit_id"), sender)
	if not error.is_empty(): return error
	var unit: Dictionary = _state.crew[command.unit_id]
	unit.assignment = "salvage"
	unit.target = Catalog.interaction_point("rust", "satellite")
	_state.salvage = {"active":true,"unit_id":command.unit_id,"remaining":8.0,"total":8.0,"phase":"walking"}
	_log(unit.name + " geht zum Satellitenwrack.")
	return ""

func _cargo_count() -> int:
	var count: int = 0
	for item: String in _state.cargo: count += int(_state.cargo[item])
	return count

func _trade(command: Dictionary) -> String:
	if _state.region != "station": return "Handel ist an der Station möglich."
	var side: Variant = command.get("side")
	var item: Variant = command.get("item")
	var amount: Variant = command.get("amount")
	if not side is String or not side in ["buy","sell"] or not item is String or not Catalog.prices().has(item): return "Ungültiges Handelsangebot."
	if not Validator.whole(amount, 1, 10000): return "Menge muss eine positive ganze Zahl sein."
	var quantity: int = int(amount)
	var cost: int = int(Catalog.prices()[item][side]) * quantity
	if side == "buy":
		if _state.credits < cost: return "Nicht genug Credits."
		if _cargo_count() + quantity > _state.ship.capacity: return "Frachtraum ist voll."
		_state.credits -= cost
		_state.cargo[item] += quantity
	else:
		if _state.cargo[item] < quantity: return "Ware fehlt im Frachtraum."
		_state.cargo[item] -= quantity
		_state.credits += cost
	_log("Handel abgeschlossen: %d × %s." % [quantity, Catalog.item_name(item)])
	return ""

func _release(unit_id: String) -> void:
	var unit: Dictionary = _state.crew[unit_id]
	unit.assignment = "idle"
	unit.target = unit.position.duplicate()

func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0 or _state.paused: return
	# Fixed upper step prevents work time being counted before the worker arrives.
	var remaining: float = minf(delta, 3600.0)
	while remaining > 0.00001:
		var step: float = minf(remaining, 0.05)
		_tick(step)
		remaining -= step
	_changed()

func _tick(delta: float) -> void:
	_state.time += delta
	if not _state.travel.active and _state.ship.mode=="flying":
		var destination: String=_orbit.tick(delta)
		if not destination.is_empty():_arrive(destination)
		return
	if not (_state.travel.active and _state.travel.phase == "flying"):
		for unit_id: String in _state.crew:
			var unit: Dictionary = _state.crew[unit_id]
			var point: Vector2 = Vector2(unit.position[0], unit.position[1])
			var target: Vector2 = Vector2(unit.target[0], unit.target[1])
			point = point.move_toward(target, Catalog.WALK_SPEED * delta)
			unit.position = [point.x, point.y]
	if _state.travel.active:
		_tick_travel(delta)
		return
	if _state.work.active:
		var unit: Dictionary = _state.crew[_state.work.unit_id]
		if _arrived(unit):
			_state.work.phase = "working"
			_state.work.remaining = maxf(0.0, _state.work.remaining - delta)
			if _state.work.remaining <= 0.0:
				var recipe: Dictionary = Catalog.recipes()[_state.work.recipe_id]
				for item: String in recipe.output: _state.inventory[item] += recipe.output[item]
				if _state.work.recipe_id == "repair": _state.ship.condition = minf(100.0, _state.ship.condition + 28.0)
				if _state.work.recipe_id == "upgrade_workbench":_state.base.workbench_tier=2
				_log(recipe.label + " fertig.")
				_release(_state.work.unit_id)
				_state.work = _empty_work()
	if _state.salvage.active:
		var unit: Dictionary = _state.crew[_state.salvage.unit_id]
		if _arrived(unit):
			_state.salvage.phase = "working"
			_state.salvage.remaining = maxf(0.0, _state.salvage.remaining - delta)
			if _state.salvage.remaining <= 0.0:
				var room: int = int(_state.ship.capacity) - _cargo_count()
				if _state.contract.status == "active" and room > 0:
					_state.cargo.blackbox = 1
					_state.contract.status = "recovered"
					room -= 1
				var recovered: int = mini(mini(4, int(_state.wreck_remaining)), room)
				_state.cargo.scrap += recovered
				_state.wreck_remaining -= recovered
				_log("Bergung beendet. Fracht im Shuttle; Rückkehr zur Basis möglich.")
				_release(_state.salvage.unit_id)
				_state.salvage = _empty_salvage()

func _arrived(unit: Dictionary) -> bool:
	return Vector2(unit.position[0], unit.position[1]).distance_to(Vector2(unit.target[0], unit.target[1])) < 0.02

func _tick_travel(delta: float) -> void:
	if _state.travel.phase == "boarding":
		for unit_id: String in _state.crew:
			if not _arrived(_state.crew[unit_id]): return
		if _state.travel.kind=="launch":
			_state.travel=_empty_travel();_state.ship.mode="flying";_orbit.board_crew()
			_log("Suchflug gestartet. Radar nach unbekannten Kontakten absuchen.")
			return
		_state.travel.phase = "flying"
		_log("Entersäbel ist unterwegs.")
		return
	_state.travel.remaining = maxf(0.0, _state.travel.remaining - delta)
	if _state.travel.remaining > 0.0: return
	var destination: String=_state.travel.to
	if destination=="station" and _state.travel.encounter_roll<35:
		_state.travel=_empty_travel();_orbit.start_encounter(destination)
		return
	_arrive(destination)

func _arrive(destination: String) -> void:
	_state.region = destination
	# N1 has no fuel attrition: repeated flights must not strand the first crew.
	var landing: Array = Catalog.landmarks(_state.region).shuttle
	_state.ship.mode="landed";_state.ship.position=landing.duplicate();_state.ship.target=landing.duplicate()
	var offset: float = -3.7
	for unit_id: String in _state.crew:
		var unit: Dictionary = _state.crew[unit_id]
		unit.position = [landing[0] + offset, landing[1] + 3.8]
		_release(unit_id)
		offset += 7.4
	_state.travel = _empty_travel()
	if _state.region == "base":
		for item: String in _state.cargo:
			_state.inventory[item] += _state.cargo[item]
			_state.cargo[item] = 0
	_log("Gelandet: " + {"base":"Heimatbasis","rust":"Rostwelt","station":"Handelsstation"}[_state.region] + ".")

func set_guest(peer_id: int) -> void:
	if peer_id <= 1: return
	_guest_id = peer_id
	_state.crew.jaro.owner = peer_id
	_changed()

func clear_guest() -> void:
	_guest_id = 0
	_state.crew.jaro.owner = 1
	_state.paused = true
	_changed()

func save_game(path: String) -> Dictionary:
	var payload: Dictionary = {"schema_version":2,"state":snapshot(),"receipts":_receipts.duplicate(true)}
	var reason: String = Validator.validate(payload)
	if not reason.is_empty(): return _result(false, "Speichern abgelehnt: " + reason)
	var temporary: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return _result(false, "Speicherdatei nicht schreibbar.")
	file.store_string(JSON.stringify(payload))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK: return _result(false, "Speichern fehlgeschlagen.")
	var verification: Variant = JSON.parse_string(FileAccess.get_file_as_string(temporary))
	if not Validator.validate(verification).is_empty(): return _result(false, "Speicherprüfung fehlgeschlagen.")
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) != OK:
		return _result(false, "Speicherdatei konnte nicht atomar ersetzt werden.")
	return _result(true, "Spiel gespeichert.")

func load_game(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return _result(false, "Kein Spielstand gefunden.")
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 16000000: return _result(false, "Spielstand nicht lesbar oder zu groß.")
	var payload: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if payload is Dictionary and payload.get("schema_version")==1:
		var legacy_error: String=LegacyValidator.validate(payload)
		if not legacy_error.is_empty():return _result(false,"Alter Spielstand abgelehnt: "+legacy_error)
		payload=Stage.migrate(payload)
	var reason: String = Validator.validate(payload)
	if not reason.is_empty(): return _result(false, "Spielstand abgelehnt: " + reason)
	var previous_revision: int = int(_state.revision)
	_state = payload.state.duplicate(true)
	_normalize_loaded_numbers()
	_state.revision = maxi(previous_revision, int(_state.revision))
	_receipts = payload.receipts.duplicate(true)
	_state.crew.ida.owner = 1
	_state.crew.jaro.owner = _guest_id if _guest_id > 1 else 1
	_orbit.bind(_state,_log)
	_changed()
	return _result(true, "Spiel geladen.")

func _normalize_loaded_numbers() -> void:
	for key: String in ["schema_version","revision","credits","wreck_remaining"]:
		_state[key] = int(_state[key])
	_state.ship.capacity = int(_state.ship.capacity)
	_state.contract.reward = int(_state.contract.reward)
	_state.random_seed=int(_state.random_seed)
	_state.base.workbench_tier=int(_state.base.workbench_tier)
	_state.travel.encounter_roll=int(_state.travel.encounter_roll)
	for container: String in ["inventory","cargo"]:
		for item: String in _state[container]: _state[container][item] = int(_state[container][item])
	for item: String in _state.work.reserved: _state.work.reserved[item] = int(_state.work.reserved[item])
	for unit_id: String in _state.crew:
		_state.crew[unit_id].skill = int(_state.crew[unit_id].skill)
		_state.crew[unit_id].owner = int(_state.crew[unit_id].owner)

func _transfer(command: Dictionary) -> String:
	if _state.region != "base": return "Fracht wird am Basislager verladen."
	var direction: Variant = command.get("direction")
	var item: Variant = command.get("item")
	var amount: Variant = command.get("amount")
	if not direction is String or not direction in ["load","unload"] or not item is String or not Catalog.ITEMS.has(item):
		return "Ungültiger Frachtauftrag."
	if not Validator.whole(amount,1,10000000): return "Menge muss eine positive ganze Zahl sein."
	var quantity: int = int(amount)
	var source: Dictionary = _state.inventory if direction == "load" else _state.cargo
	var destination: Dictionary = _state.cargo if direction == "load" else _state.inventory
	if source[item] < quantity: return "Ware fehlt im Lager oder Frachtraum."
	if direction == "load" and _cargo_count() + quantity > _state.ship.capacity: return "Frachtraum ist voll."
	source[item] -= quantity
	destination[item] += quantity
	_log("%d × %s %s." % [quantity,Catalog.item_name(item),"eingeladen" if direction == "load" else "ausgeladen"])
	return ""
