class_name HomebaseCardPool
extends RefCounted

var _cards_by_key: Dictionary = {}
var _created_total: int = 0
var _reused_total: int = 0
var _retired_total: int = 0
var _configured_total: int = 0
var _last_created_count: int = 0
var _last_reused_count: int = 0
var _last_retired_count: int = 0
var _last_configured_count: int = 0


func reconcile(container: Node, card_specs: Array, factory: Callable, configure: Callable) -> Dictionary:
	_last_created_count = 0
	_last_reused_count = 0
	_last_retired_count = 0
	_last_configured_count = 0
	if container == null or not factory.is_valid() or not configure.is_valid():
		return get_snapshot()

	var next_keys: Dictionary = {}
	var insert_index: int = 0
	for spec_variant in card_specs:
		if typeof(spec_variant) != TYPE_DICTIONARY:
			continue
		var spec: Dictionary = Dictionary(spec_variant)
		var key: String = String(spec.get("key", "")).strip_edges()
		if key.is_empty():
			continue
		next_keys[key] = true
		var card = _cards_by_key.get(key, null)
		if card == null or not is_instance_valid(card):
			card = factory.call(spec)
			if card == null:
				continue
			_cards_by_key[key] = card
			_created_total += 1
			_last_created_count += 1
		else:
			_reused_total += 1
			_last_reused_count += 1

		if card.get_parent() != container:
			var previous_parent: Node = card.get_parent()
			if previous_parent != null:
				previous_parent.remove_child(card)
			container.add_child(card)
		if card.get_index() != insert_index:
			container.move_child(card, insert_index)
		card.set_meta("homebase_card_pool_key", key)
		configure.call(card, spec)
		_configured_total += 1
		_last_configured_count += 1
		insert_index += 1

	for key_variant in _cards_by_key.keys():
		var key: String = String(key_variant)
		if next_keys.has(key):
			continue
		var retired_card = _cards_by_key.get(key, null)
		_cards_by_key.erase(key)
		if retired_card != null and is_instance_valid(retired_card):
			var parent: Node = retired_card.get_parent()
			if parent != null:
				parent.remove_child(retired_card)
			retired_card.queue_free()
		_retired_total += 1
		_last_retired_count += 1
	return get_snapshot()


func clear() -> void:
	for card_variant in _cards_by_key.values():
		if card_variant != null and is_instance_valid(card_variant):
			var parent: Node = card_variant.get_parent()
			if parent != null:
				parent.remove_child(card_variant)
			card_variant.queue_free()
	_cards_by_key.clear()


func get_card(key: String):
	return _cards_by_key.get(key.strip_edges(), null)


func get_snapshot() -> Dictionary:
	var active_keys: PackedStringArray = PackedStringArray()
	for key_variant in _cards_by_key.keys():
		active_keys.append(String(key_variant))
	active_keys.sort()
	return {
		"active_count": _cards_by_key.size(),
		"active_keys": Array(active_keys),
		"created_total": _created_total,
		"reused_total": _reused_total,
		"retired_total": _retired_total,
		"configured_total": _configured_total,
		"last_created_count": _last_created_count,
		"last_reused_count": _last_reused_count,
		"last_retired_count": _last_retired_count,
		"last_configured_count": _last_configured_count,
	}
