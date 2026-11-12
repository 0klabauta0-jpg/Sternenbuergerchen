extends RefCounted
## Point wallet and purchase receipts. Live roster, gear and craft state remain
## in their existing owners. SimulationRoot commits the transaction callback.
const CATALOG = preload("res://scripts/meta/skirmish_points_catalog.gd")

var _budget := 0
var _remaining := 0
var _revision := 0
var _next_person := 1
var _next_craft := 1
var _infrastructure := {"paid": true, "habitat": 0, "workshop": 0, "bed": 0, "beds": 0, "pads": 0}
var _person_refunds: Dictionary = {}
var _craft_refunds: Dictionary = {}
var _receipts: Dictionary = {}


func configure(budget: int) -> void:
	_budget = budget if CATALOG.BUDGETS.has(budget) else 0
	_remaining = _budget


func get_snapshot() -> Dictionary:
	return {"budget": _budget, "remaining": _remaining, "spent": _budget - _remaining,
		"next_person_id": "skirmish_points_recruit_%03d" % _next_person,
		"revision": _revision, "infrastructure": _infrastructure.duplicate(true),
		"person_refunds": _person_refunds.duplicate(), "craft_refunds": _craft_refunds.duplicate()}


func apply_command(command: Dictionary, transaction: Callable) -> Dictionary:
	if not command.get("payload") is Dictionary or typeof(command.get("request_id")) != TYPE_STRING or typeof(command.get("operation")) != TYPE_STRING:
		return _reject("invalid_request", "Punkteanfrage ist ungültig")
	var request_id := String(command.get("request_id", ""))
	if request_id.is_empty() or not transaction.is_valid() or _budget == 0:
		return _reject("invalid_request", "Punktekauf ist noch nicht bereit")
	var operation := String(command.get("operation", ""))
	var payload: Dictionary = Dictionary(command.get("payload", {})).duplicate(true)
	var fingerprint := JSON.stringify([operation, payload])
	if _receipts.has(request_id):
		var receipt: Dictionary = _receipts[request_id]
		if receipt.fingerprint != fingerprint:
			return _reject("request_id_conflict", "Diese Anfrage wurde bereits anders verwendet")
		var replay: Dictionary = receipt.result.duplicate(true)
		replay["replayed"] = true
		return replay
	var cost := 0
	match operation:
		"person":
			cost = CATALOG.get_person_cost(payload)
			payload["unit_id"] = "skirmish_points_recruit_%03d" % _next_person
		"dismiss":
			var id := String(payload.get("unit_id", ""))
			if not _person_refunds.has(id):
				return _reject("unknown_purchase", "Person ist kein eigener Punktekauf")
			cost = -int(_person_refunds[id])
		"ship":
			var id := String(payload.get("item_id", ""))
			cost = int(CATALOG.SHIPS[id].cost) if CATALOG.SHIPS.has(id) else -1
			payload["craft_id"] = "skirmish_points_craft_%03d" % _next_craft
		"return_ship":
			var id := String(payload.get("craft_id", ""))
			if not _craft_refunds.has(id):
				return _reject("unknown_purchase", "Schiff ist kein eigener Punktekauf")
			cost = -int(_craft_refunds[id])
		"equipment":
			var id := String(payload.get("item_id", ""))
			cost = int(CATALOG.EQUIPMENT[id].cost) if CATALOG.EQUIPMENT.has(id) else -1
		"build":
			var id := String(payload.get("item_id", ""))
			if not CATALOG.BUILDINGS.has(id):
				return _reject("unknown_item", "Bauvorhaben fehlt")
			var key := "pads" if id == "pad" else id
			if int(_infrastructure[key]) >= int(CATALOG.BUILDINGS[id].limit):
				return _reject("capacity_limit", "Alle vorgesehenen Bauplätze sind belegt")
			cost = int(CATALOG.BUILDINGS[id].cost)
		_:
			return _reject("unknown_operation", "Punkteaktion fehlt")
	if cost == -1 and operation not in ["dismiss", "return_ship"]:
		return _reject("invalid_purchase", "Auswahl ist ungültig")
	if cost > _remaining:
		return _reject("insufficient_points", "Das Punktebudget reicht dafür nicht")
	var next_infrastructure := _infrastructure.duplicate(true)
	if operation == "build":
		var id := String(payload.item_id)
		var key := "pads" if id == "pad" else id
		next_infrastructure[key] = int(next_infrastructure[key]) + 1
		next_infrastructure.beds = int(next_infrastructure.habitat) * 2 + int(next_infrastructure.bed)
		payload["infrastructure"] = next_infrastructure.duplicate(true)
	var result: Dictionary = transaction.call(operation, payload)
	if not bool(result.get("ok", false)):
		return result
	_remaining -= cost
	_infrastructure = next_infrastructure
	if operation == "person":
		_person_refunds[payload.unit_id] = int(CATALOG.ROLES[payload.role].cost) + int(CATALOG.EXPERIENCE[payload.experience].cost)
		_next_person += 1
	elif operation == "dismiss":
		_person_refunds.erase(String(payload.unit_id))
	elif operation == "ship":
		_craft_refunds[payload.craft_id] = cost
		_next_craft += 1
	elif operation == "return_ship":
		_craft_refunds.erase(String(payload.craft_id))
	_revision += 1
	result["remaining"] = _remaining
	result["revision"] = _revision
	_receipts[request_id] = {"fingerprint": fingerprint, "result": result.duplicate(true)}
	return result


func _reject(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message}
