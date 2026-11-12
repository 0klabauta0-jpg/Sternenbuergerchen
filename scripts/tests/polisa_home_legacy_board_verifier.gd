extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
var failed := 0
class Shuttle extends RefCounted:
	var phase := "home_disembark_required"
	func get_snapshot() -> Dictionary: return {"phase":phase,"person_id":"campaign_leader","craft_id":"service"}
	func advance(_delta: float) -> Dictionary: return {"ok":true}
	func prepare_home_disembark(_receipt: Dictionary) -> Dictionary: return {"ok":true,"person_id":"campaign_leader"}
	func validate_prepared_home_disembark(_handle: Dictionary) -> Dictionary: return {"ok":true}
	func _publish_prepared_home_disembark(_handle: Dictionary, _validation: Dictionary) -> void: phase = "home_waiting"
class Home extends RefCounted:
	func get_snapshot() -> Dictionary: return {"phase":"landed","craft_id":"service","landing_pad_id":"homebase_pad_01"}
	func landing_receipt() -> Dictionary: return {"craft_id":"service","pad_id":"homebase_pad_01"}
	func verify_pad_binding(craft: String, pad: String) -> bool: return craft == "service" and pad == "homebase_pad_01"
	func begin_departure(_craft: String) -> Dictionary: return {"ok":true}
	func advance(_delta: float) -> Dictionary: return {"ok":true}
	func departure_receipt() -> Dictionary: return {}
func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value: failed += 1
func _init() -> void: call_deferred("run")
func run() -> void:
	START.request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var adapter: Node = flow.get("_singleplayer_runtime")
	var base: Node = adapter.get_base_personnel_runtime()
	var sim: Node = base.get_simulation_root()
	sim.set_physics_process(false)
	var person := "campaign_leader"
	var actor: Node2D = base.get_actor(person)
	base._states[person].status = "station"
	actor.visible = false
	var shuttle := Shuttle.new()
	adapter._polisa_shuttle = shuttle
	adapter._polisa_shuttle_home = Home.new()
	check(not base._requires_hex_ground(), "actual campaign base uses non-hex movement")
	var layout: Dictionary = base.get_snapshot().layout
	var anchor: Array = layout.avatar_spawn_grid
	var arrival: Dictionary = base.admit_polisa_shuttle_home(person, {}, Vector2i(anchor[0], anchor[1]))
	check(arrival.get("ok", false) and actor.visible and shuttle.phase == "home_waiting", "service passenger enters real campaign base")
	if arrival.get("ok", false):
		shuttle.phase = "return_boarding_required"
		var raw: Array = layout.landing_pads[0].get("interaction_grid", layout.landing_pads[0].grid)
		var board: Dictionary = base.request_polisa_shuttle_return_board(person,"service",Vector2i(raw[0],raw[1]),"legacy-board")
		check(board.get("ok", false), "actual campaign passenger starts walking to shuttle")
		for i in range(6000):
			sim._physics_process(0.05)
			if not base.get_polisa_shuttle_return_board_receipt(person,"service","legacy-board").is_empty(): break
		check(not base.get_polisa_shuttle_return_board_receipt(person,"service","legacy-board").is_empty() and not actor.visible, "receipt follows actual walking and boarding")
	flow.queue_free()
	await process_frame
	if failed == 0: print("POLISA_HOME_LEGACY_BOARD_PASS")
	quit(0 if failed == 0 else 1)
