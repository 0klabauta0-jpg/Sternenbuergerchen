extends SceneTree
const PANEL = preload("res://scripts/ui/space_wing_panel.gd")
const OWNER = preload("res://scripts/core/space_wing_state.gd")
var owner = OWNER.new()
var context := {"authorized":true, "actor_id":"singleplayer", "phase":"grounded", "owned_crafts":["a","b"], "craft_pilots":{"a":"p1", "b":"p2"}}
var crafts := [{"craft_id":"a", "display_name":"Alpha"}, {"craft_id":"b", "display_name":"Beta"}]

func _initialize() -> void:
	var panel = PANEL.new()
	root.add_child(panel)
	panel.configure(_snapshot, _command)
	var failed := 0
	if not panel.submit("wing_create", {"wing_id":"w"}).get("ok", false): failed += 1
	if not panel.submit("wing_assign", {"wing_id":"w", "craft_id":"a"}).get("ok", false): failed += 1
	if not panel.submit("wing_assign", {"wing_id":"w", "craft_id":"b"}).get("ok", false): failed += 1
	if owner.get_snapshot().wings.w.craft_ids != ["a", "b"]: failed += 1
	if panel.submit("wing_assign", {"wing_id":"w", "craft_id":"a"}).get("ok", false): failed += 1
	if panel.get_feedback().is_empty(): failed += 1
	if not panel.submit("wing_remove", {"wing_id":"w", "craft_id":"b"}).get("ok", false): failed += 1
	if owner.get_snapshot().wings.w.craft_ids != ["a"]: failed += 1
	panel.free()
	print("SPACE_COMBAT_AP05_PANEL passed=", 8 - failed, " failed=", failed)
	quit(1 if failed else 0)

func _snapshot() -> Dictionary:
	return {"space_wings":owner.get_snapshot(), "crafts":crafts}

func _command(operation: String, payload: Dictionary) -> Dictionary:
	if operation != "space_wing_command": return {"ok":false}
	return owner.apply_command(payload.command, context)
