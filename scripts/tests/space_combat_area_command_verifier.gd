extends SceneTree
const CONTRACT = preload("res://scripts/mission/space_combat_command_contract.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var context := {"authorized":true, "revision":0, "phase":"tactical", "owned_wings":["w"], "coordinate_frame":"local", "space_area_id":"orbit_approach:moon"}
	var command := {"contract_category":"space_combat", "operation":"order_issue", "request_id":"1", "expected_revision":0, "payload":{"wing_ids":["w"], "verb":"move", "target_hex":GRID.from_offset(Vector2i(400,100))}}
	var failed := 0
	if not CONTRACT.validate(command, context).get("ok", false): failed += 1
	command.payload.target_hex = GRID.from_offset(Vector2i(512,100))
	if CONTRACT.validate(command, context).get("reason") != "invalid_hex": failed += 1
	command.payload.target_hex = GRID.from_offset(Vector2i(400,100))
	context.coordinate_frame = "strategic"
	context.space_area_id = ""
	if CONTRACT.validate(command, context).get("reason") != "invalid_hex": failed += 1
	context.coordinate_frame = "local"
	context.space_area_id = ""
	if CONTRACT.validate(command, context).get("reason") != "invalid_hex": failed += 1
	print("SPACE_COMBAT_AREA_COMMAND passed=", 4 - failed, " failed=", failed)
	quit(1 if failed else 0)
