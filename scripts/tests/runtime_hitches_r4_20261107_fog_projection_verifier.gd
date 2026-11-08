extends SceneTree
## Small real renderer consumer fixture. No actors, commands, timers or live LOS.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")

class FogProbe extends "res://scripts/terrain/terrain_map_3d_view.gd":
	var contact_rebuilds := 0
	var order_rebuilds := 0
	func _rebuild_contact_visuals() -> void:
		contact_rebuilds += 1
		super._rebuild_contact_visuals()
	func _rebuild_order_visuals() -> void:
		order_rebuilds += 1
		super._rebuild_order_visuals()
	func reset_observations() -> void:
		contact_rebuilds = 0
		order_rebuilds = 0

var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var data = MAP.create_empty("r4_fog_projection_fixture", Vector2i(4, 4), Vector2.ZERO, 64.0, 32.0, 3)
	var tiles: Array = data.get_tiles()
	var ids: Array = []
	for tile in tiles:
		ids.append(String(tile.tile_id))
	var position: Vector2 = tiles[5].world_position
	var next_position: Vector2 = tiles[6].world_position
	var source_before := tile_facts(tiles)
	var view := FogProbe.new()
	root.add_child(view)
	view.set_process(false)
	view.configure_from_map(data)
	var order := {"phase_index": 1, "selected_fireteam_ids": PackedStringArray(["ft1"]),
		"fireteam_anchors": [{"fireteam_id": "ft1", "position": position}],
		"plan_dicts": [{"fireteam_id": "ft1", "phase": 1, "waypoints": [{"target_position": next_position, "command_type": "move", "status": "pending"}]}]}
	view.set_order_visual_payload(order)
	var state := fog_state(ids, position, 100, 1)
	view.set_fog_of_war_state(state)
	for _frame in range(4):
		if not bool(view.get("_fow_overlay_full_rebuild_pending")):
			break
		view.call("_process", 1.0 / 60.0)
	check(not bool(view.get("_fow_overlay_full_rebuild_pending")), "Small real terrain overlay completed")
	var contact_root := view.get("_contact_root") as Node
	var order_root := view.get("_order_root") as Node
	check(contact_root != null and contact_root.get_child_count() > 0, "Fixture contains actual last-known contact geometry")
	check(order_root != null and order_root.get_child_count() > 0, "Fixture contains actual planned-order geometry")
	var contacts_before := node_ids(contact_root)
	var orders_before := node_ids(order_root)
	var visual_before: Array = view.call("_get_contact_visual_entries")
	var next := state.duplicate(true)
	next["last_known_contacts"][0]["last_seen_tick"] = 101
	var input_before := var_to_bytes(next)
	view.reset_observations()
	view.set_fog_of_war_state(next)
	var published: Dictionary = view.get("_fog_of_war_state")
	check(int(published["last_known_contacts"][0]["last_seen_tick"]) == 101, "Fresh timestamp is published even when visuals are unchanged")
	check(view.contact_rebuilds == 0 and node_ids(contact_root) == contacts_before, "Timestamp-only update retains actual contact nodes without rebuilding")
	check(view.order_rebuilds == 0 and node_ids(order_root) == orders_before, "Timestamp-only update retains actual order nodes without rebuilding")
	check(Array(view.call("_get_contact_visual_entries")) == visual_before, "Timestamp-only update retains the full contact visual receipt")
	check(var_to_bytes(next) == input_before, "Consumer does not mutate caller snapshot")
	view.reset_observations()
	next["visibility_revision"] = 2
	view.set_fog_of_war_state(next)
	check(int(Dictionary(view.get("_fog_of_war_state")).get("visibility_revision", 0)) == 2, "Fresh revision is published independently of visual reuse")
	check(view.contact_rebuilds == 0 and view.order_rebuilds == 0 and node_ids(contact_root) == contacts_before and node_ids(order_root) == orders_before, "Revision-only update retains both actual node groups")
	var metadata_only := next.duplicate(true)
	metadata_only["visibility_delta"] = {"from_revision": 1, "to_revision": 2, "visible_added_tile_ids": []}
	view.reset_observations()
	view.set_fog_of_war_state(metadata_only)
	check(Dictionary(view.get("_fog_of_war_state")).get("visibility_delta", {}) == metadata_only["visibility_delta"], "Complete latest source metadata is published even when geometry is unchanged")
	check(view.contact_rebuilds == 0 and view.order_rebuilds == 0 and node_ids(contact_root) == contacts_before and node_ids(order_root) == orders_before, "Metadata-only source update retains actual geometry")
	var changed_detection := metadata_only.duplicate(true)
	changed_detection["last_known_contacts"][0]["detection_state"] = "confirmed"
	view.reset_observations()
	view.set_fog_of_war_state(changed_detection)
	check(String(Dictionary(view.get("_fog_of_war_state"))["last_known_contacts"][0]["detection_state"]) == "confirmed", "Same-tick detection change remains fresh in the full source snapshot")
	check(view.contact_rebuilds > 0 and String(Array(view.call("_get_contact_visual_entries"))[0]["detection_state"]) == "confirmed", "Same-tick detection change updates the actual contact projection")
	var subcentimeter_move := changed_detection.duplicate(true)
	subcentimeter_move["last_known_contacts"][0]["last_known_position"] = position + Vector2(0.001, 0.0)
	view.reset_observations()
	view.set_fog_of_war_state(subcentimeter_move)
	check(view.contact_rebuilds > 0 and Vector2(Array(view.call("_get_contact_visual_entries"))[0]["last_known_position"]) == position + Vector2(0.001, 0.0), "Exact source coordinates invalidate contact geometry without display rounding")
	view.reset_observations()
	var moved := next.duplicate(true)
	moved["last_known_contacts"][0]["last_known_position"] = next_position
	view.set_fog_of_war_state(moved)
	var visual_moved: Array = view.call("_get_contact_visual_entries")
	check(view.contact_rebuilds > 0 and visual_moved.size() == 1 and Vector2(visual_moved[0]["last_known_position"]) == next_position, "Moved last-known contact rebuilds to its actual new position")
	var unknown := moved.duplicate(true)
	unknown["visibility_revision"] = 3
	unknown["terrain_knowledge"] = {"visible_tile_ids": [], "explored_tile_ids": []}
	unknown["last_known_contacts"] = []
	view.set_fog_of_war_state(unknown)
	check(contact_root.get_child_count() == 0 and Array(view.call("_get_contact_visual_entries")).is_empty(), "Blackout contact removal leaves no stale actual marker")
	var current_contact := {"target_id": "enemy", "unit_id": "enemy", "fireteam_id": "ft1", "approximate_position": position, "last_known_position": position, "detection_state": "spotted", "report_state": "current", "confidence": 1.0, "enemy_profile_revealed": true, "enemy_profile_label": "GUARD"}
	view.set_contact_entries([current_contact], PackedStringArray(["ft1"]))
	check(contact_root.get_child_count() == 0, "Unknown current contact remains filtered without invented knowledge")
	var visible_by_position := unknown.duplicate(true)
	visible_by_position["terrain_knowledge"]["visible_tile_ids"] = [String(tiles[5].tile_id)]
	view.reset_observations()
	view.set_fog_of_war_state(visible_by_position)
	check(contact_root.get_child_count() > 0 and view.order_rebuilds > 0, "Changed terrain visibility invalidates dynamic admission even at the same revision and target IDs")
	view.set_fog_of_war_state(unknown)
	check(contact_root.get_child_count() == 0, "Losing terrain visibility removes the formerly admitted current contact")
	var visible_by_target := unknown.duplicate(true)
	visible_by_target["current_visibility"]["visible_target_ids"] = ["enemy"]
	view.set_fog_of_war_state(visible_by_target)
	check(contact_root.get_child_count() > 0, "Actual current target visibility admits its existing contact without terrain reveal")
	view.set_fog_of_war_state(unknown)
	check(contact_root.get_child_count() == 0, "Losing target visibility removes the formerly admitted current contact")
	var off := unknown.duplicate(true)
	off["mode"] = "off"
	view.set_fog_of_war_state(off)
	check(contact_root.get_child_count() > 0, "Off mode refreshes and admits the existing current contact")
	var contact_receipt: Array = view.call("_get_contact_visual_entries")
	check(contact_receipt.size() == 1 and bool(contact_receipt[0]["enemy_profile_revealed"]) and String(contact_receipt[0]["enemy_profile_label"]) == "GUARD", "Full current contact profile/confidence payload is preserved")
	var other_team := unknown.duplicate(true)
	other_team["team_id"] = "other_team"
	view.set_fog_of_war_state(other_team)
	check(contact_root.get_child_count() == 0, "New blackout team cannot retain old off-mode admission")
	view.set_fog_of_war_state(off)
	view.set_contact_entries([current_contact], PackedStringArray(["different_fireteam"]))
	check(contact_root.get_child_count() == 0, "Changed selected-fireteam payload still filters existing contacts")
	view.set_contact_entries([current_contact], PackedStringArray(["ft1"]))
	check(contact_root.get_child_count() > 0, "Returning selection reprojects the same actual contact")
	check(tile_facts(tiles) == source_before, "All source tile values remain unchanged")
	check(Dictionary(view.get("_order_payload")) == order, "Existing order payload remains unchanged")
	view.free()
	await process_frame
	await process_frame
	print("R4_FOG_PROJECTION: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_FOG_PROJECTION_PASS")
	quit(1 if failed else 0)

func fog_state(ids: Array, position: Vector2, tick: int, revision: int) -> Dictionary:
	return {"mode": "unexplored_blackout", "team_id": "team_alpha", "visibility_revision": revision,
		"terrain_knowledge": {"visible_tile_ids": ids.duplicate(), "explored_tile_ids": ids.duplicate()},
		"current_visibility": {"visible_target_ids": [], "visible_event_ids": []},
		"last_known_contacts": [{"target_id": "enemy", "team_id": "team_bravo", "last_known_position": position, "last_seen_tick": tick, "detection_state": "lost"}]}

func node_ids(parent: Node) -> Array:
	var result: Array = []
	if parent != null:
		for child in parent.get_children():
			result.append(child.get_instance_id())
	return result

func tile_facts(tiles: Array) -> Array:
	var result: Array = []
	for tile in tiles:
		result.append([tile.tile_id, tile.grid_position, tile.world_position, tile.walkable, tile.blocks_los, tile.height_level, tile.surface_type, tile.object_type_id])
	return result

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("PASS: " if ok else "FAIL: ", message)
