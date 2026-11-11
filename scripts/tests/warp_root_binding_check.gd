extends SceneTree
## Tiny trust-boundary check; no mission, rendering or real user save.
const ROOT = preload("res://scripts/core/simulation_root.gd")
class Receiver extends RefCounted:
	var seen := {}
	func apply_command(_command: Dictionary, context: Dictionary) -> Dictionary:
		seen = context
		return {"ok": true}
class Equipment extends RefCounted:
	var asked := ""
	func prepare_install(_craft: String, _slot: String, _item: String, _revision: int) -> Dictionary:
		return {"ok": true, "proof": "bound_owner"}
	func commit_prepared_install(_prepared: Dictionary, _request: String) -> Dictionary:
		return {"ok": true}
	func get_quantum_effect(craft_id: String) -> Dictionary:
		asked = craft_id
		return {"quantum_duration_multiplier": 0.75 if craft_id == "equipped" else 1.0}
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)
func _initialize() -> void:
	var sim = ROOT.new()
	var receiver := Receiver.new()
	sim.configure_singleplayer_owners(null, receiver, null, receiver)
	var fake := func(_a = null, _b = null, _c = null, _d = null): return {"ok": true, "proof": "unbound"}
	var injected := {"quantum_duration_multiplier":0.001, "prepare_ship_component_install":fake, "commit_ship_component_install":fake}
	var command := {"contract_category":"singleplayer_space_travel", "operation":"start_quantum", "payload":{"craft_id":"equipped", "quantum_duration_multiplier":0.001}, "request_id":"jump"}
	sim.request_singleplayer_command(command, injected)
	check(receiver.seen.get("quantum_duration_multiplier") == 1.0, "ownerless preserves baseline despite injected context")
	check(not receiver.seen.has("prepare_ship_component_install"), "unrelated command never forwards callback injection")
	var install := {"contract_category":"singleplayer_supply", "operation":"station_install_ship_component", "payload":{}, "request_id":"install"}
	check(not sim.request_singleplayer_command(install, injected).get("ok", false), "install requires bound owner")
	var equipment := Equipment.new()
	sim.configure_ship_equipment(equipment)
	sim.request_singleplayer_command(command, injected)
	check(equipment.asked == "equipped" and receiver.seen.quantum_duration_multiplier == 0.75, "exact craft derives bound effect")
	command.payload.craft_id = "other"
	sim.request_singleplayer_command(command, injected)
	check(receiver.seen.quantum_duration_multiplier == 1.0, "other craft cannot borrow equipped effect")
	sim.request_singleplayer_command(install, injected)
	var prepare: Callable = receiver.seen.get("prepare_ship_component_install", Callable())
	check(prepare.is_valid() and prepare.call("equipped", "quantum_drive", "drive", 0).get("proof") == "bound_owner", "install callback is bound owner rather than injected capability")
	check(Callable(receiver.seen.get("commit_ship_component_install", Callable())).get_object() == equipment, "commit capability belongs to same owner")
	sim.free()
	print("WARP_ROOT_BINDING checks=", checks, " failures=", failures)
	quit(int(failures > 0))
