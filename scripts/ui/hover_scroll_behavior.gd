class_name HoverScrollBehavior
extends RefCounted


static func install(root_node: Node) -> Dictionary:
	var summary: Dictionary = {
		"installed": 0,
		"scroll_nodes": PackedStringArray(),
	}
	_install_recursive(root_node, summary)
	return summary


static func _install_recursive(node: Node, summary: Dictionary) -> void:
	if node == null:
		return
	var scroll := node as ScrollContainer
	if scroll != null:
		_configure_scroll_container(scroll, summary)
	for child in node.get_children():
		_install_recursive(child, summary)


static func _configure_scroll_container(scroll: ScrollContainer, summary: Dictionary) -> void:
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.follow_focus = true
	scroll.set_meta("hover_scroll_enabled", true)
	var scroll_nodes: PackedStringArray = PackedStringArray(summary.get("scroll_nodes", PackedStringArray()))
	scroll_nodes.append(String(scroll.get_path()))
	summary["scroll_nodes"] = scroll_nodes
	summary["installed"] = int(summary.get("installed", 0)) + 1
	var focus_callable := Callable(scroll, "grab_focus")
	if not scroll.mouse_entered.is_connected(focus_callable):
		scroll.mouse_entered.connect(focus_callable)
