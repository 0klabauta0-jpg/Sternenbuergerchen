class_name MissionPrimaryViewBridge
extends RefCounted

const PRIMARY_VIEW_NODE_NAME: String = "Primary3DView"
const LEGACY_DROP_NODE_PATHS: Array[String] = ["LZMarker", "DropshipPlanMarker"]
const LEGACY_READABILITY_BRIDGE_PATHS: Array[String] = ["CombatLoopDriver", "ObjectiveStatusView", "EnemyWaveController"]
const LEGACY_READABILITY_NODE_PATHS: Array[String] = ["StatusLabel", "CombatContactLine", "CombatEventLabel", "CombatWinnerLabel", "WaveStatusLabel"]


func get_primary_view(mission_root: Node) -> Node:
	if mission_root == null:
		return null
	return mission_root.get_node_or_null(PRIMARY_VIEW_NODE_NAME)


func has_primary_view(mission_root: Node) -> bool:
	return get_primary_view(mission_root) != null


func screen_to_world_position(mission_root: Node, viewport: Viewport, screen_position: Vector2) -> Vector2:
	var primary_view := get_primary_view(mission_root)
	if primary_view != null and primary_view.has_method("screen_to_world_position"):
		var world_position = primary_view.call("screen_to_world_position", screen_position)
		if typeof(world_position) == TYPE_VECTOR2:
			return Vector2(world_position)
	if viewport == null:
		return screen_position
	var canvas_transform: Transform2D = viewport.get_canvas_transform()
	return canvas_transform.affine_inverse() * screen_position


func world_to_screen_position(mission_root: Node, viewport: Viewport, world_position: Vector2) -> Vector2:
	var primary_view := get_primary_view(mission_root)
	if primary_view != null and primary_view.has_method("world_to_screen_position"):
		var screen_position = primary_view.call("world_to_screen_position", world_position)
		if typeof(screen_position) == TYPE_VECTOR2:
			return Vector2(screen_position)
	if viewport == null:
		return world_position
	return viewport.get_canvas_transform() * world_position


func snap_world_position_to_tile_center(mission_root: Node, world_position: Vector2) -> Vector2:
	var primary_view := get_primary_view(mission_root)
	if primary_view != null and primary_view.has_method("snap_world_position_to_tile_center"):
		var snapped_position = primary_view.call("snap_world_position_to_tile_center", world_position)
		if typeof(snapped_position) == TYPE_VECTOR2:
			return Vector2(snapped_position)
	return world_position


func sync_mission_drop_visual_state(mission_root: Node, drop_payload: Dictionary) -> bool:
	var primary_view := get_primary_view(mission_root)
	if primary_view == null or not primary_view.has_method("set_mission_drop_visual_state"):
		return false
	primary_view.call("set_mission_drop_visual_state", drop_payload)
	hide_legacy_drop_nodes(mission_root)
	return true


func sync_mission_status_payload(mission_root: Node, status_payload: Dictionary) -> bool:
	if status_payload.is_empty():
		return false
	var primary_view := get_primary_view(mission_root)
	if primary_view == null or not primary_view.has_method("set_mission_status_payload"):
		return false
	primary_view.call("set_mission_status_payload", status_payload)
	return true


func sync_order_visual_payload(mission_root: Node, order_payload: Dictionary) -> bool:
	var primary_view := get_primary_view(mission_root)
	if primary_view == null or not primary_view.has_method("set_order_visual_payload"):
		return false
	primary_view.call("set_order_visual_payload", order_payload)
	return true


func sync_contact_entries(mission_root: Node, contact_entries: Array, selected_fireteam_ids: PackedStringArray = PackedStringArray()) -> bool:
	var primary_view := get_primary_view(mission_root)
	if primary_view == null or not primary_view.has_method("set_contact_entries"):
		return false
	primary_view.call("set_contact_entries", contact_entries, selected_fireteam_ids)
	return true


func hide_canvas_item_when_primary(mission_root: Node, canvas_item: CanvasItem) -> void:
	if canvas_item == null or get_primary_view(mission_root) == null:
		return
	canvas_item.visible = false


func hide_legacy_drop_nodes(mission_root: Node) -> void:
	_hide_canvas_items(mission_root, LEGACY_DROP_NODE_PATHS)


func suppress_legacy_readability_overlays(mission_root: Node) -> void:
	if get_primary_view(mission_root) == null:
		return
	for bridge_path in LEGACY_READABILITY_BRIDGE_PATHS:
		var bridge_node := mission_root.get_node_or_null(bridge_path) if mission_root != null else null
		if bridge_node != null and bridge_node.has_method("set_overlay_visible"):
			bridge_node.call("set_overlay_visible", false)
	_hide_canvas_items(mission_root, LEGACY_READABILITY_NODE_PATHS)


func _hide_canvas_items(mission_root: Node, node_paths: Array[String]) -> void:
	if mission_root == null:
		return
	for node_path in node_paths:
		var node := mission_root.get_node_or_null(node_path)
		if node is CanvasItem:
			(node as CanvasItem).visible = false
