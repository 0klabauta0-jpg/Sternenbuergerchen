class_name MapEditorPrimaryViewAdapter
extends RefCounted

const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const PRIMARY_VIEW_NAME: String = "Primary3DView"


static func ensure_primary_view(editor: Node, current_view, legacy_node_names: PackedStringArray, hover_preview: CanvasItem = null):
	var primary_view = get_primary_view(editor, current_view)
	if primary_view == null:
		primary_view = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
		primary_view.name = PRIMARY_VIEW_NAME
		editor.add_child(primary_view)
	set_legacy_2d_map_visible(editor, legacy_node_names, false, hover_preview)
	return primary_view


static func get_primary_view(editor: Node, current_view):
	if current_view != null and is_instance_valid(current_view):
		return current_view
	if editor == null:
		return null
	return editor.get_node_or_null(PRIMARY_VIEW_NAME)


static func refresh_map_view(primary_view, terrain_map_data, selected_grids: Array, selected_grid_position: Vector2i) -> void:
	if primary_view == null:
		return
	primary_view.call("render_map", terrain_map_data)
	update_selection_visual(primary_view, selected_grids, selected_grid_position)


static func update_selection_visual(primary_view, selected_grids: Array, selected_grid_position: Vector2i) -> void:
	if primary_view == null:
		return
	var grids := selected_grids.duplicate()
	if grids.is_empty() and selected_grid_position != Vector2i(-1, -1):
		grids = [selected_grid_position]
	primary_view.call("set_selected_grid_positions", grids)


static func set_legacy_2d_map_visible(editor: Node, node_names: PackedStringArray, is_visible: bool, hover_preview: CanvasItem = null) -> void:
	if editor == null:
		return
	for node_name in node_names:
		var node := editor.get_node_or_null(node_name)
		if node is CanvasItem:
			(node as CanvasItem).visible = is_visible
	var camera := editor.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.enabled = is_visible
	if hover_preview != null:
		hover_preview.visible = is_visible and hover_preview.visible


static func clear_legacy_2d_map_children(editor: Node, node_names: PackedStringArray) -> void:
	if editor == null:
		return
	for node_name in node_names:
		var node := editor.get_node_or_null(node_name)
		if node == null:
			var container := Node2D.new()
			container.name = node_name
			editor.add_child(container)
			node = container
		if node == null:
			continue
		for child in node.get_children():
			child.queue_free()


static func screen_to_editor_world_position(primary_view, screen_position: Vector2, fallback_world_position: Vector2) -> Vector2:
	if primary_view != null and primary_view.has_method("screen_to_world_position"):
		var world_position = primary_view.call("screen_to_world_position", screen_position)
		if typeof(world_position) == TYPE_VECTOR2:
			return Vector2(world_position)
	return fallback_world_position
