class_name UpdateManager
extends Node

const MAX_BATCH_SIZE: int = 20

var _ai_dirty: Array = []
var _hud_dirty: Array = []


func mark_ai_dirty(node: Node) -> void:
	_mark_dirty(_ai_dirty, node, "mark_ai_dirty")


func mark_hud_dirty(node: Node) -> void:
	_mark_dirty(_hud_dirty, node, "mark_hud_dirty")


# Only a bounded batch is processed per frame; hooks remain opt-in on the target nodes.
func _process(delta: float) -> void:
	_process_queue(_ai_dirty, "ai_update")
	_process_queue(_hud_dirty, "refresh_hud")


func _mark_dirty(queue: Array, node: Node, source: String) -> void:
	if not _is_valid_node(node):
		push_warning("UpdateManager.%s expects a valid Node." % source)
		return

	if queue.has(node):
		return

	queue.append(node)


func _process_queue(queue: Array, method_name: String) -> void:
	var remaining: int = mini(queue.size(), MAX_BATCH_SIZE)

	for _index in remaining:
		var node: Node = queue.pop_front()
		if not _is_valid_node(node):
			continue

		if node.has_method(method_name):
			node.call(method_name)


func _is_valid_node(node: Node) -> bool:
	return node != null and is_instance_valid(node)
