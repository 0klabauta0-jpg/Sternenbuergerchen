extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
var adapter: Node
var base: Node
var failed := 0
func check(value: bool, label: String) -> void:
	print(("PASS: " if value else "FAIL: ") + label)
	if not value: failed += 1
func verify(kind: String, person: String, craft: String, receipt: Dictionary) -> bool:
	if kind == "boarding_polisa": return true # station departure fixture only
	return adapter._verify_polisa_service_evidence(kind, person, craft, receipt)
func start_service() -> RefCounted:
	var home = load("res://scripts/core/polisa_shuttle_home_lifecycle.gd").new()
	home.configure(adapter._reserve_service_home_pad, adapter._validate_service_home_pad, adapter._release_service_home_pad)
	adapter._polisa_shuttle_home = home
	var service = load("res://scripts/core/polisa_shuttle_service.gd").new()
	service.configure(verify, base.get_shuttle_person_status)
	adapter._polisa_shuttle = service
	service.begin("campaign_leader", "service-test", {})
	return service
func _init() -> void: call_deferred("run")
func run() -> void:
	START.request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	adapter = flow.get("_singleplayer_runtime"); base = adapter.get_base_personnel_runtime()
	var sim: Node = base.get_simulation_root(); sim.set_physics_process(false)
	var actor: Node2D = base.get_actor("campaign_leader")
	# The player ship is away; station departure is a fixture, not a second scene.
	adapter._pad_by_craft.clear()
	base._states.campaign_leader.status = "station"; actor.visible = false
	var service := start_service()
	for i in range(60):
		service.advance(1.0); adapter._advance_polisa_shuttle_home(1.0)
		if service.get_snapshot().phase == "home_waiting": break
	check(service.get_snapshot().phase == "home_waiting" and actor.visible, "actual service and campaign base complete home handoff")
	base._states.campaign_leader.status = "moving"
	base._states.campaign_leader.action = {"type":"move"}
	service.advance(1.0)
	check(service.get_snapshot().phase == "settled", "assigned work ends waiting")
	adapter._polisa_shuttle_home.release()
	base._states.campaign_leader.status = "station"; base._states.campaign_leader.action = {}; actor.visible = false
	service = start_service()
	for i in range(60):
		service.advance(1.0); adapter._advance_polisa_shuttle_home(1.0)
		if service.get_snapshot().phase == "home_waiting": break
	check(service.get_snapshot().phase == "home_waiting", "second service passenger arrives")
	for i in range(5): service.advance(60.0)
	check(service.get_snapshot().phase == "return_boarding_required", "300 seconds without bed or work requests return")
	for i in range(8000):
		sim._physics_process(0.05)
		if service.get_snapshot().phase == "to_station": break
	check(service.get_snapshot().phase == "to_station" and not actor.visible and base._states.campaign_leader.status == "station", "walking, boarding and departure start actual return fleet travel")
	adapter._polisa_shuttle_home.release()
	service = start_service()
	for i in range(60):
		service.advance(1.0); adapter._advance_polisa_shuttle_home(1.0)
		if service.get_snapshot().phase == "home_waiting": break
	var bed: String = str(base.get_snapshot().layout.beds[0].id)
	var occupant := String(base._beds.get(bed, ""))
	if not occupant.is_empty(): base.apply_operation("base_cancel", {"unit_id":occupant})
	var sleep: Dictionary = base.request_operation("base_sleep", {"unit_id":"campaign_leader","bed_id":bed})
	service.advance(1.0)
	if not sleep.get("ok", false): print("BED_DIAG ", sleep)
	check(sleep.get("ok", false) and service.get_snapshot().phase == "settled", "real bed assignment ends waiting")
	flow.queue_free(); await process_frame
	if failed == 0: print("POLISA_REAL_HOME_SHUTTLE_PASS")
	quit(0 if failed == 0 else 1)
