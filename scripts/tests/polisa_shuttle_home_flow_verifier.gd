extends SceneTree
var adapter: Node
var service: RefCounted
class Base extends Node:
	var arrived := false
	var service: RefCounted
	func get_snapshot() -> Dictionary: return {"layout":{"landing_pads":[{"id":"homebase_pad_01","grid":[1,1],"built":true}],"interiors":[{"id":"habitat_cutaway_01","door_grid":[2,2]}]}}
	func get_shuttle_person_status(_id: String) -> Dictionary: return {"ok":true,"has_bed":arrived,"has_task":false}
	func admit_polisa_shuttle_home(id: String, receipt: Dictionary, _grid: Vector2i) -> Dictionary:
		var prepared: Dictionary = service.prepare_home_disembark(receipt)
		if not prepared.get("ok", false) or prepared.get("person_id") != id: return {"ok":false}
		var valid: Dictionary = service.validate_prepared_home_disembark(prepared)
		if not valid.get("ok", false): return valid
		arrived = true
		service._publish_prepared_home_disembark(prepared, valid)
		return {"ok":true}
func _verify(kind: String, person: String, craft: String, receipt: Dictionary) -> bool:
	if kind == "boarding_polisa": return true
	return adapter._verify_polisa_service_evidence(kind, person, craft, receipt)
func _init() -> void: call_deferred("_run")
func _run() -> void:
	adapter = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new()
	var base := Base.new(); adapter._base_personnel = base
	var home = load("res://scripts/core/polisa_shuttle_home_lifecycle.gd").new()
	if not home.configure(adapter._reserve_service_home_pad, adapter._validate_service_home_pad, adapter._release_service_home_pad).ok: printerr("FAIL: home configure"); quit(1); return
	adapter._polisa_shuttle_home = home
	service = load("res://scripts/core/polisa_shuttle_service.gd").new(); adapter._polisa_shuttle = service; base.service = service
	if not service.configure(_verify, base.get_shuttle_person_status).ok or not service.begin("person", "shuttle", {}).get("ok", false): printerr("FAIL: shuttle start"); quit(1); return
	for i in range(30):
		service.advance(1.0)
		adapter._advance_polisa_shuttle_home(1.0)
		if base.arrived: break
	if not base.arrived or service.get_snapshot().phase != "home_waiting": printerr("FAIL: home handoff"); quit(1); return
	service.advance(1.0)
	if service.get_snapshot().phase != "settled": printerr("FAIL: bed settles"); quit(1); return
	base.free(); adapter.free()
	print("PASS: FleetTravel to timed home pad and passenger handoff fixture")
	quit(0)
