class_name UpdateManager
extends Node

const MAX_BATCH_SIZE: int = 20

var _ai_dirty: Dictionary = {}
var _ai_dirty_order: Array = []
var _hud_dirty: Dictionary = {}
var _hud_dirty_order: Array = []


func mark_ai_dirty(node: Node) -> void:
	if node == null or _ai_dirty.has(node):
		return

	_ai_dirty[node] = true
	_ai_dirty_order.append(node)


func mark_hud_dirty(node: Node) -> void:
	if node == null or _hud_dirty.has(node):
		return

	_hud_dirty[node] = true
	_hud_dirty_order.append(node)


func _process(_delta: float) -> void:
	_process_batch(_ai_dirty, _ai_dirty_order, "ai_update")
	_process_batch(_hud_dirty, _hud_dirty_order, "refresh_hud")


func _process_batch(dirty: Dictionary, queue: Array, method_name: String) -> void:
	var processed: int = 0

	while processed < MAX_BATCH_SIZE and not queue.is_empty():
		var node = queue.pop_front()
		dirty.erase(node)
		if node != null and is_instance_valid(node) and node.has_method(method_name):
			node.call(method_name)
		processed += 1
