extends Node3D
## Bounded transient presentation. Receives existing events; never creates them.
const PULSE: GDScript = preload("res://scripts/terrain/weapon_fire_feedback_pulse.gd")
const SOURCE_LIMIT: int = 8
var _owner_view: Node = null
var _map_instance_id: int = -1
var _active: Dictionary = {}

func set_context(view: Node, map_data: Object) -> void:
	_owner_view = view
	var next_map_id: int = map_data.get_instance_id() if map_data != null else 0
	if _map_instance_id == next_map_id:
		return
	for key in _active.keys():
		_remove(String(key))
	_map_instance_id = next_map_id
	# No ingestion here: the previous order payload belongs to its old context.

static func _event_key(event: Dictionary) -> String:
	return "%s__%s__%d" % [String(event.get("event_id", "")), String(event.get("attacker_unit_id", "")), int(event.get("tick", 0))]

static func select_current_source_events(events: Array) -> Array:
	var candidates: Array = []
	for item in events:
		if not item is Dictionary:
			continue
		var event: Dictionary = Dictionary(item)
		if not String(event.get("event_id", "")).is_empty() and not bool(event.get("presentation_history_only", false)):
			candidates.append(event)
	# The controller may append one old first-exchange evidence row. It is
	# not newer simply because it is last, nor is its wrapper's wall clock a
	# simulation tick. The actual fire events use the same authoritative tick.
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_tick: int = int(a.get("tick", 0))
		var b_tick: int = int(b.get("tick", 0))
		return a_tick > b_tick if a_tick != b_tick else String(a.get("event_id", "")) > String(b.get("event_id", ""))
	)
	var selected: Array = []
	var seen_sources: Dictionary = {}
	for event_variant in candidates:
		var event: Dictionary = Dictionary(event_variant)
		var source: String = String(event.get("attacker_unit_id", "")).strip_edges()
		if source.is_empty():
			source = _event_key(event)
		if seen_sources.has(source):
			continue
		seen_sources[source] = true
		selected.append(event)
		if selected.size() >= SOURCE_LIMIT:
			break
	return selected

func ingest(events: Array) -> void:
	_prune()
	var first_receipt: Dictionary = {}
	# Stamp every receipt, including history and unselected rows. Selection is
	# shared with the pose projection, while pulse TTL/admission stays local.
	for item in events:
		if not item is Dictionary:
			continue
		var event: Dictionary = Dictionary(item)
		if String(event.get("event_id", "")).is_empty():
			continue
		var key: String = _event_key(event)
		if not PULSE.has_received_event(_owner_view, key):
			first_receipt[key] = true
		PULSE.remember_event(_owner_view, key)
	for event_variant in select_current_source_events(events):
		var event: Dictionary = Dictionary(event_variant)
		var source: String = String(event.get("attacker_unit_id", "")).strip_edges()
		if source.is_empty():
			source = _event_key(event)
		var key: String = _event_key(event)
		# A rejected, hidden, superseded or already played receipt is consumed.
		# Visibility gain can admit a NEW event, never replay the same old key.
		if _active.has(key) or not first_receipt.has(key) or not bool(_owner_view.call("_fow_allows_weapon_fire_source", event)):
			continue
		var started_msec: int = PULSE.remember_event(_owner_view, key)
		if Time.get_ticks_msec() - started_msec >= PULSE.ICON_DURATION_MSEC:
			continue
		var anchor: Dictionary = _owner_view.call("_build_weapon_fire_feedback_anchor", event)
		if anchor.is_empty():
			continue
		for previous_key in _active.keys():
			if String(Dictionary(_active[previous_key]).get("source", "")) == String(source):
				_remove(String(previous_key))
		while _active.size() >= SOURCE_LIMIT:
			_remove(String(_active.keys()[0]))
		var pulse: Node3D = PULSE.add_for_event(_owner_view, self, key, anchor.get("texture") as Texture2D, Vector3(anchor.muzzle_position), Vector3(anchor.source_position))
		if pulse == null:
			continue
		var muzzle_node: Node3D = anchor.get("muzzle_node") as Node3D
		var source_node: Node3D = anchor.get("source_node") as Node3D
		pulse.set("_muzzle_anchor", muzzle_node)
		pulse.set("_source_anchor", source_node)
		if source_node != null:
			pulse.set("_source_offset", Vector3(anchor.source_position) - source_node.global_position)
		_active[key] = {"pulse": pulse, "source": source, "event": event.duplicate(true), "anchor_kind": anchor.get("kind", "catalog_fallback"), "muzzle_node": muzzle_node, "aim_direction": anchor.get("aim_direction", Vector3.ZERO)}
	refresh_visibility()

func refresh_visibility() -> void:
	_prune()
	for key in _active.keys():
		if not bool(_owner_view.call("_fow_allows_weapon_fire_source", Dictionary(_active[key]).event)):
			_remove(String(key))

func _remove(key: String) -> void:
	var pulse: Variant = Dictionary(_active.get(key, {})).get("pulse")
	if is_instance_valid(pulse):
		pulse.visible = false
		pulse.queue_free()
	_active.erase(key)

func _prune() -> void:
	for key in _active.keys():
		var pulse: Variant = Dictionary(_active[key]).get("pulse")
		if not is_instance_valid(pulse) or pulse.is_queued_for_deletion() or not pulse.visible:
			_active.erase(key)

func get_pulse(event: Dictionary) -> Node3D:
	_prune()
	return Dictionary(_active.get(_event_key(event), {})).get("pulse") as Node3D

func get_snapshot() -> Dictionary:
	_prune()
	var entries: Array = []
	for key in _active:
		var record: Dictionary = Dictionary(_active[key])
		var pulse: Node3D = record.pulse as Node3D
		var flash: Sprite3D = pulse.get_node_or_null("MuzzleFlash") as Sprite3D
		var icon: Sprite3D = pulse.get_node_or_null("FiringIcon") as Sprite3D
		var muzzle: Variant = record.get("muzzle_node")
		var forward: Vector3 = -muzzle.global_transform.basis.z.normalized() if is_instance_valid(muzzle) else Vector3.ZERO
		entries.append({"event_id": String(Dictionary(record.event).get("event_id", "")), "event_key": key, "attacker_unit_id": record.source, "tick": Dictionary(record.event).get("tick", 0), "age_msec": Time.get_ticks_msec() - int(pulse.get("_started_msec")), "source_allowed": _owner_view.call("_fow_allows_weapon_fire_source", record.event), "flash_visible": flash != null and flash.is_visible_in_tree() and flash.modulate.a > 0.0, "icon_visible": icon != null and icon.is_visible_in_tree() and icon.modulate.a > 0.0, "muzzle_position": flash.global_position if flash != null else Vector3.ZERO, "muzzle_anchor_position": muzzle.global_position if is_instance_valid(muzzle) else Vector3.ZERO, "anchor_kind": record.anchor_kind, "weapon_forward_dot": forward.dot(Vector3(record.aim_direction)), "pulse_instance_id": pulse.get_instance_id()})
	return {"active_pulse_count": entries.size(), "source_limit": SOURCE_LIMIT, "entries": entries, "map_instance_id": _map_instance_id, "read_only": true, "creates_fire_event": false}
