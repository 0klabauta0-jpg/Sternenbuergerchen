extends SceneTree
const WING = preload("res://scripts/core/space_wing_state.gd")
var _sequence := 0
var _state: RefCounted
var _context := {"authorized":true, "actor_id":"player", "phase":"grounded", "owned_crafts":["c1","c2","c3","c4","c5","c6","c7","c8"], "craft_pilots":{"c1":"p1","c2":"p2","c3":"p3","c4":"p4","c5":"p5","c6":"p6","c7":"p7","c8":"p1"}}

func command(operation: String, payload: Dictionary) -> Dictionary:
	_sequence += 1
	return {"contract_category":"space_combat", "operation":operation, "request_id":"r%d" % _sequence, "expected_revision":_state.get_snapshot().revision, "payload":payload}

func _initialize() -> void:
	var failed := 0
	_state = WING.new()
	var create := command("wing_create", {"wing_id":"w1"})
	if not _state.apply_command(create, _context).get("ok", false): failed += 1
	if not _state.apply_command(create, _context).get("replayed", false): failed += 1
	for i in range(1, 7):
		if not _state.apply_command(command("wing_assign", {"wing_id":"w1", "craft_id":"c%d" % i}), _context).get("ok", false): failed += 1
	if _state.get_snapshot().wings.w1.craft_ids.size() != 6: failed += 1
	if _state.apply_command(command("wing_assign", {"wing_id":"w1", "craft_id":"c7"}), _context).reason != "wing_full": failed += 1
	_state.apply_command(command("wing_create", {"wing_id":"w2"}), _context)
	if _state.apply_command(command("wing_assign", {"wing_id":"w2", "craft_id":"c1"}), _context).reason != "craft_already_assigned": failed += 1
	if _state.apply_command(command("wing_assign", {"wing_id":"w2", "craft_id":"c8"}), _context).reason != "pilot_already_assigned": failed += 1
	if not _state.apply_command(command("wing_remove", {"wing_id":"w1", "craft_id":"c1"}), _context).get("ok", false): failed += 1
	if _state.get_snapshot().wings.w1.leader_craft_id != "c2": failed += 1
	var other := _context.duplicate(true)
	other.actor_id = "other"
	if _state.apply_command(command("wing_rename", {"wing_id":"w1", "name":"foreign"}), other).reason != "not_owned": failed += 1
	if not _state.apply_command(command("wing_create", {"wing_id":"w3"}), _context).get("ok", false): failed += 1
	if not _state.apply_command(command("wing_assign", {"wing_id":"w3", "craft_id":"c7"}), _context).get("ok", false): failed += 1
	if not _state.apply_command(command("wing_remove", {"wing_id":"w3", "craft_id":"c7"}), _context).get("ok", false): failed += 1
	if _state.get_snapshot().wings.has("w3"): failed += 1
	print("SPACE_COMBAT_AP04 passed=", 19 - failed, " failed=", failed)
	quit(1 if failed else 0)
