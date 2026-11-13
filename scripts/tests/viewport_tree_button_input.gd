extends RefCounted
## Godot 4.6 Tree reads get_local_mouse_position during native button presses.
## Root Windows source that from the OS pointer, even for push_input events.
## A private SubViewport uses the pushed event position; no OS cursor is moved.
static func click(tree: Tree, item: TreeItem, button_id: int = 0) -> Dictionary:
	var scene: SceneTree = tree.get_tree()
	var original_parent: Node = tree.get_parent()
	var original_index := tree.get_index()
	var original_rect := tree.get_rect()
	var original_global_rect := tree.get_global_rect()
	var themed_ancestor: Node = tree
	var inherited_theme: Theme
	while themed_ancestor != null:
		if themed_ancestor is Control and themed_ancestor.theme != null:
			inherited_theme = themed_ancestor.theme; break
		themed_ancestor = themed_ancestor.get_parent()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(tree.get_viewport_rect().size)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	scene.root.add_child(viewport)
	var host := Control.new()
	host.theme = inherited_theme
	viewport.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tree.reparent(host, false)
	tree.position = original_global_rect.position
	tree.size = original_global_rect.size
	var ancestor := item.get_parent()
	while ancestor != null: ancestor.collapsed = false; ancestor = ancestor.get_parent()
	tree.scroll_to_item(item)
	for frame in range(3): await scene.process_frame
	var row := tree.get_item_area_rect(item)
	var first := -1
	var last := -1
	for x in range(int(tree.size.x)):
		var local_point := Vector2(float(x), row.get_center().y)
		if tree.get_item_at_position(local_point) == item and tree.get_button_id_at_position(local_point) == button_id:
			if first < 0: first = x
			last = x
	var receipts: Array = []
	var observe := func(clicked: TreeItem, column: int, id: int, button: int): receipts.append({"item":clicked.get_metadata(0),"column":column,"id":id,"button":button})
	tree.button_clicked.connect(observe)
	var result := {"ok":false,"hit":first >= 0}
	if first >= 0:
		var point := tree.global_position + Vector2((first + last) * 0.5, row.get_center().y)
		var motion := InputEventMouseMotion.new()
		motion.position = point; motion.global_position = point
		viewport.push_input(motion,true)
		await scene.process_frame
		result["event_local"] = point - tree.global_position
		result["pointer_local"] = tree.get_local_mouse_position()
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true; event.button_mask = MOUSE_BUTTON_MASK_LEFT
		viewport.push_input(event,true)
		event = event.duplicate(); event.pressed = false; event.button_mask = 0
		viewport.push_input(event,true)
		result["ok"] = receipts.size() == 1 and receipts[0].id == button_id and receipts[0].button == MOUSE_BUTTON_LEFT
	result["receipts"] = receipts
	tree.button_clicked.disconnect(observe)
	tree.reparent(original_parent, false)
	original_parent.move_child(tree, original_index)
	tree.position = original_rect.position
	tree.size = original_rect.size
	if tree.is_visible_in_tree(): tree.grab_focus()
	viewport.queue_free()
	for frame in range(4): await scene.process_frame
	return result
