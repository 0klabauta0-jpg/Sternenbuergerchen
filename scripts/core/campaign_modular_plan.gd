extends RefCounted
## Pure contract: a six-metre orthogonal module grid projected into base plane.
const ORIGIN := Vector2(15.0, 36.0)
const CELL_SIZE := 6.0
const ROOM_COST := {"sleep":300, "storage":300, "corridor":100}
const BED_COST := 100
const STORAGE_CAPACITY := 100
const GRID_LIMIT := 8

static func center(x: int, y: int) -> Vector2:
	return ORIGIN + Vector2(x, y) * CELL_SIZE

static func empty() -> Dictionary:
	return {"rooms": [], "beds": []}

static func validate_room(plan: Dictionary, payload: Dictionary) -> Dictionary:
	if payload.size() != 4 or not ROOM_COST.has(String(payload.get("type", ""))): return _reject("invalid_room", "Ungültiger Raumtyp")
	for key in ["x", "y", "rotation"]:
		var v: Variant = payload.get(key)
		if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(v)) or float(v) != floor(float(v)): return _reject("invalid_room", "Ungültige Raumposition")
		if absf(float(v)) > GRID_LIMIT: return _reject("invalid_room", "Raumposition außerhalb des Baugebiets")
	var x := int(payload.x); var y := int(payload.y); var rotation := int(payload.rotation)
	if absi(x) > GRID_LIMIT or absi(y) > GRID_LIMIT or rotation < 0 or rotation > 3: return _reject("invalid_room", "Raumposition außerhalb des Baugebiets")
	var rooms: Array = plan.get("rooms", [])
	var connected := rooms.is_empty() and x == 0 and y == 0
	for room: Dictionary in rooms:
		var dx := absi(int(room.x) - x); var dy := absi(int(room.y) - y)
		if dx == 0 and dy == 0: return _reject("room_occupied", "Bauplatz bereits belegt")
		if dx + dy == 1: connected = true
	if not connected: return _reject("room_disconnected", "Raum muss am Bauanker oder an einem vorhandenen Modul anschließen")
	return {"ok":true}

static func validate_bed(plan: Dictionary, payload: Dictionary) -> Dictionary:
	if payload.size() != 2 or typeof(payload.get("room_id")) != TYPE_STRING: return _reject("invalid_bed", "Ungültiger Bettplatz")
	var slot: Variant = payload.get("slot")
	if typeof(slot) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(slot)) or float(slot) != floor(float(slot)) or float(slot) < 0.0 or float(slot) > 1.0: return _reject("invalid_bed", "Ungültiger Bettplatz")
	var found := false
	for room: Dictionary in plan.get("rooms", []):
		if room.id == payload.room_id and room.type == "sleep": found = true; break
	if not found: return _reject("sleep_room_required", "Ein Schlafraum wird benötigt")
	for bed: Dictionary in plan.get("beds", []):
		if bed.room_id == payload.room_id and int(bed.slot) == int(slot): return _reject("bed_slot_occupied", "Bettplatz bereits belegt")
	return {"ok":true}

static func room_doors(room: Dictionary) -> Array:
	return Array(room.get("doors", [true, true, true, true])).duplicate()

static func append_room(plan: Dictionary, record: Dictionary, modern: bool) -> void:
	var room := record.duplicate(true)
	if not modern:
		room.doors = [true,true,true,true]
		plan.rooms.append(room)
		return
	room.doors = [false,false,false,false]
	if plan.rooms.is_empty():
		room.doors[0] = true
	else:
		for existing: Dictionary in plan.rooms:
			var dx := int(room.x)-int(existing.x); var dy := int(room.y)-int(existing.y)
			if absi(dx)+absi(dy) != 1: continue
			var direction := 0 if dy == -1 else (1 if dx == 1 else (2 if dy == 1 else 3))
			var old_side := posmod(direction + int(existing.rotation), 4)
			var new_side := posmod(direction + 2 + int(room.rotation), 4)
			var old_doors := room_doors(existing)
			old_doors[old_side] = true; existing.doors = old_doors
			room.doors[new_side] = true
			break
	plan.rooms.append(room)

static func validate_door(plan: Dictionary, payload: Dictionary) -> Dictionary:
	if payload.size() != 3 or typeof(payload.get("room_id")) != TYPE_STRING or typeof(payload.get("open")) != TYPE_BOOL:
		return _reject("invalid_door", "Ungültiger Türbauauftrag")
	var side: Variant = payload.get("side")
	if typeof(side) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(side)) or float(side) != floor(float(side)) or int(side) < 0 or int(side) > 3:
		return _reject("invalid_door", "Ungültige Raumseite")
	for room: Dictionary in plan.get("rooms", []):
		if room.id != payload.room_id: continue
		if bool(room_doors(room)[int(side)]) == payload.open: return _reject("door_unchanged", "Diese Raumseite hat bereits den gewünschten Zustand")
		return {"ok":true}
	return _reject("invalid_door", "Raum nicht gefunden")

static func apply_door(plan: Dictionary, payload: Dictionary) -> void:
	for room: Dictionary in plan.rooms:
		if room.id != payload.room_id: continue
		var doors := room_doors(room)
		doors[int(payload.side)] = bool(payload.open)
		room.doors = doors
		return

static func replay(requests: Dictionary) -> Dictionary:
	var actions: Array = []
	for request_id in requests:
		var entry: Dictionary = requests[request_id]
		var result: Dictionary = entry.get("result", {})
		var operation := String(result.get("operation", ""))
		if operation not in ["campaign_build_room", "campaign_place_room_bed", "campaign_set_room_door"]: continue
		var signature: Variant = JSON.parse_string(String(entry.get("signature", "")))
		if typeof(signature) != TYPE_DICTIONARY or signature.get("operation") != operation or typeof(signature.get("payload")) != TYPE_DICTIONARY: return _reject("invalid_modular_receipts", "Raumbeleg ungültig")
		if typeof(result.get("sequence")) not in [TYPE_FLOAT, TYPE_INT] or float(result.sequence) != floor(float(result.sequence)) or int(result.sequence) < 1: return _reject("invalid_modular_receipts", "Raumbeleg ohne Reihenfolge")
		actions.append({"op":operation,"payload":signature.payload,"result":result,"seq":int(result.sequence)})
	actions.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.seq < b.seq)
	var plan := empty()
	for index in range(actions.size()):
		var action: Dictionary = actions[index]
		if action.seq != index + 1: return _reject("invalid_modular_receipts", "Raumbelege widersprechen sich")
		var payload: Dictionary = action.payload; var result: Dictionary = action.result
		if action.op == "campaign_build_room":
			if not validate_room(plan,payload).get("ok",false) or result.get("cost") != ROOM_COST.get(payload.get("type")) or result.get("room_id") != "room_%04d" % (plan.rooms.size()+1): return _reject("invalid_modular_receipts", "Raumbeleg widerspricht Bauplan")
			if result.has("door_schema") and result.door_schema != 1: return _reject("invalid_modular_receipts", "Ungültige Türversion")
			append_room(plan, {"id":result.room_id,"type":payload.type,"x":int(payload.x),"y":int(payload.y),"rotation":int(payload.rotation)}, result.has("door_schema"))
		elif action.op == "campaign_place_room_bed":
			if not validate_bed(plan,payload).get("ok",false) or result.get("cost") != BED_COST or result.get("bed_id") != "modular_bed_%04d" % (plan.beds.size()+1): return _reject("invalid_modular_receipts", "Bettbeleg widerspricht Bauplan")
			plan.beds.append({"id":result.bed_id,"room_id":payload.room_id,"slot":int(payload.slot)})
		else:
			if not validate_door(plan,payload).get("ok",false) or result.get("cost") != 0: return _reject("invalid_modular_receipts", "Türbeleg widerspricht Bauplan")
			apply_door(plan,payload)
	return {"ok":true,"plan":plan,"sequence":actions.size()}

static func _reject(reason: String, message: String) -> Dictionary:
	return {"ok":false,"reason":reason,"message":message}
