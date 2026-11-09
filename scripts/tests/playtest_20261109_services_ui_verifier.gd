extends SceneTree

const SUPPLY: GDScript = preload("res://scripts/core/singleplayer_supply_state.gd")
const SIMULATION: GDScript = preload("res://scripts/core/simulation_root.gd")
const PATH := "res://scripts/meta/singleplayer_services_presenter.gd"
var _supply: RefCounted
var _sim: Node
var _location: String = "trade_outpost"
var _busy: bool = false
var _calls: Array[Dictionary] = []
var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(ResourceLoader.exists(PATH), "Service controls can be instantiated")
	if not ResourceLoader.exists(PATH):
		_finish()
		return
	_supply = SUPPLY.new()
	_check(bool(_supply.configure([{"craft_id": "craft_one"}]).get("ok", false)), "Real finite supply owner configures")
	_sim = SIMULATION.new()
	root.add_child(_sim)
	_sim.set_physics_process(false)
	_sim.configure_singleplayer_owners(null, _supply)
	var services: Control = load(PATH).new()
	root.add_child(services)
	services.size = Vector2(340, 570)
	services.call("configure", _snapshot, _command)
	for frame in range(4):
		await process_frame
	_check(services.get_combined_minimum_size().y <= 570.0, "Compact service panel fits bounded mission overlay height: " + str(services.get_combined_minimum_size()))
	var buy: Button = services.find_child("BuySupply", true, false)
	var refuel: Button = services.find_child("RefuelCraft", true, false)
	_check(buy != null and not buy.disabled, "Landed trade craft exposes one real purchase")
	_check(refuel != null and not refuel.disabled, "Landed craft exposes finite refuel action")
	var credit_label: Label = services.find_child("SupplyCredits", true, false)
	_check(credit_label != null and credit_label.text.contains("500"), "Visible credits read confirmed owner snapshot")
	buy.pressed.emit()
	buy.pressed.emit()
	_check(_supply.get_supply_snapshot().credits == 450, "Rapid double purchase debits exactly fifty credits")
	_check(int(_supply.get_supply_snapshot().item_quantities.get("medictool", 0)) == 1, "Rapid double purchase grants exactly one existing item")
	_check(_calls.size() >= 1 and String(_calls[0].payload.get("craft_id", "")) == "craft_one", "Purchase carries actual craft ID")
	_check(buy.disabled, "Purchase remains locked until acknowledgement debounce")
	await create_timer(0.45).timeout
	_check(not buy.disabled, "Acknowledged purchase permits an intentional next action")
	buy.pressed.emit()
	_check(_supply.get_supply_snapshot().credits == 400 and int(_supply.get_supply_snapshot().item_quantities.get("medictool", 0)) == 2, "Intentional second purchase uses new request ID")
	_check(_calls.size() == 2 and String(_calls[0].payload.request_id) != String(_calls[1].payload.request_id), "Acknowledged next action uses a distinct real request ID")
	refuel.pressed.emit()
	refuel.pressed.emit()
	_check(is_equal_approx(float(_supply.get_supply_snapshot().fuel_by_craft_id.craft_one), 70.0), "Rapid double refuel adds ten fuel once")
	_check(_supply.get_supply_snapshot().credits == 380, "Refuel debits confirmed data price exactly once")
	await create_timer(0.45).timeout
	_location = "homebase"
	services.call("refresh")
	_check(buy.disabled and not refuel.disabled, "Homebase offers refuel without inventing a trade service")
	_check(not bool(services.call("set_selected_craft", "invented")), "Unknown craft cannot become selected service target")
	_busy = true
	services.call("refresh")
	_check(buy.disabled and refuel.disabled, "Actual busy context blocks service actions")
	var reason: Label = services.find_child("ServiceFeedback", true, false)
	_check(reason != null and not reason.text.strip_edges().is_empty(), "Unavailable service displays concrete reason")
	_busy = false
	_location = "trade_outpost"
	services.call("refresh")
	buy.pressed.emit()
	await create_timer(0.45).timeout
	buy.pressed.emit()
	await create_timer(0.45).timeout
	_check(int(_supply.get_supply_snapshot().stock_by_offer_id.medictool_supply) == 0 and buy.disabled, "Finite offer sells out and disables purchase")
	var before: Dictionary = _supply.get_supply_snapshot()
	buy.pressed.emit()
	_check(_supply.get_supply_snapshot() == before, "Programmatic sold-out click cannot debit or mint goods")
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/trade_offers.json"))
	definitions.initial_credits = 0
	_supply.configure([{"craft_id": "craft_one"}], definitions)
	services.call("refresh")
	_check(buy.disabled and refuel.disabled, "Insufficient real credits disable both paid actions")
	before = _supply.get_supply_snapshot()
	refuel.pressed.emit()
	_check(_supply.get_supply_snapshot() == before, "Programmatic unpaid refuel cannot change owner")
	definitions.initial_credits = 500
	definitions.initial_fuel = 100.0
	_supply.configure([{"craft_id": "craft_one"}], definitions)
	services.call("refresh")
	_check(refuel.disabled and refuel.tooltip_text.contains("0"), "Full real tank disables refuel with concrete capacity reason")
	services.call("configure", _snapshot, Callable())
	_check(buy.disabled and refuel.disabled, "Unbound command bridge cannot claim working services")
	services.hide()
	_check(not services.is_processing(), "Hidden service panel has no continuous polling")
	services.queue_free()
	_sim.queue_free()
	await process_frame
	_finish()

func _snapshot() -> Dictionary:
	return {"campaign": {}, "supply": _supply.get_supply_snapshot(), "crafts": [{"craft_id": "craft_one", "location_id": _location, "busy": _busy}], "service_contexts_by_craft_id": {"craft_one": {"location_id": _location, "craft_busy": _busy}} if not _busy else {}}

func _command(operation: String, payload: Dictionary) -> Dictionary:
	_calls.append({"operation": operation, "payload": payload.duplicate(true)})
	var data: Dictionary = payload.duplicate(true)
	var request_id: String = String(data.get("request_id", ""))
	data.erase("request_id")
	return _sim.request_singleplayer_command({"contract_category": "singleplayer_supply", "operation": operation, "payload": data, "request_id": request_id}, {"location_id": _location, "craft_busy": _busy})

func _check(value: bool, message: String) -> void:
	if value:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		printerr("FAIL: " + message)

func _finish() -> void:
	print("SERVICES_UI_RESULTS passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
