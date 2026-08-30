class_name MissionRuntimeIndex
extends Node

## Read-only membership lookup for direct mission-root unit children.
##
## The controller owns gameplay decisions. This helper only rebuilds its cached
## lookup when the mission root reports a direct child membership change.

signal membership_revision_changed(revision: int)

var _mission_root: Node = null
var _local_team_id: String = ""
var _membership_dirty: bool = true
var _membership_revision: int = 0
var _membership_scan_count: int = 0
var _friendly_units: Array = []
var _enemy_units: Array = []
var _units_by_id: Dictionary = {}
var _units_by_fireteam: Dictionary = {}


func bind_mission_root(mission_root: Node, local_team_id: String) -> void:
	if _mission_root == mission_root and _local_team_id == local_team_id.strip_edges():
		return
	_disconnect_mission_root()
	_mission_root = mission_root
	_local_team_id = local_team_id.strip_edges()
	if _mission_root != null:
		_mission_root.child_entered_tree.connect(_on_mission_child_membership_changed)
		_mission_root.child_exiting_tree.connect(_on_mission_child_membership_changed)
	_membership_dirty = true


func get_friendly_units(include_hidden: bool = true) -> Array:
	_ensure_membership()
	return _filter_visible_units(_friendly_units, include_hidden)


func get_enemy_units(include_hidden: bool = true) -> Array:
	_ensure_membership()
	return _filter_visible_units(_enemy_units, include_hidden)


func get_fireteam_units(fireteam_id: String, include_hidden: bool = true) -> Array:
	_ensure_membership()
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return []
	return _filter_visible_units(Array(_units_by_fireteam.get(normalized_fireteam_id, [])), include_hidden)


func get_unit_by_id(unit_id: String):
	_ensure_membership()
	return _units_by_id.get(unit_id.strip_edges(), null)


func get_available_fireteam_ids(configured_fireteam_ids: PackedStringArray = PackedStringArray()) -> PackedStringArray:
	_ensure_membership()
	var result: PackedStringArray = []
	for fireteam_id_variant in configured_fireteam_ids:
		_append_fireteam_id_once(result, String(fireteam_id_variant))
	for unit in _friendly_units:
		_append_fireteam_id_once(result, _get_fireteam_id(unit))
	return result


func get_diagnostics_snapshot() -> Dictionary:
	_ensure_membership()
	return {
		"membership_revision": _membership_revision,
		"membership_scan_count": _membership_scan_count,
		"friendly_unit_count": _friendly_units.size(),
		"enemy_unit_count": _enemy_units.size(),
		"read_only": true,
		"index_owns_gameplay_truth": false,
	}


func _exit_tree() -> void:
	_disconnect_mission_root()


func _disconnect_mission_root() -> void:
	if _mission_root == null:
		return
	if _mission_root.child_entered_tree.is_connected(_on_mission_child_membership_changed):
		_mission_root.child_entered_tree.disconnect(_on_mission_child_membership_changed)
	if _mission_root.child_exiting_tree.is_connected(_on_mission_child_membership_changed):
		_mission_root.child_exiting_tree.disconnect(_on_mission_child_membership_changed)
	_mission_root = null


func _on_mission_child_membership_changed(_child: Node) -> void:
	_membership_dirty = true


func _ensure_membership() -> void:
	if not _membership_dirty:
		return
	_rebuild_membership()


func _rebuild_membership() -> void:
	_friendly_units.clear()
	_enemy_units.clear()
	_units_by_id.clear()
	_units_by_fireteam.clear()
	_membership_dirty = false
	_membership_scan_count += 1
	if _mission_root == null:
		_membership_revision += 1
		membership_revision_changed.emit(_membership_revision)
		return
	for child in _mission_root.get_children():
		if not _is_indexable_unit(child):
			continue
		var unit_id: String = _get_unit_id(child)
		if unit_id.is_empty():
			continue
		_units_by_id[unit_id] = child
		var team_id: String = String(child.call("get_team_id")).strip_edges()
		if team_id == _local_team_id:
			_friendly_units.append(child)
			var fireteam_id: String = _get_fireteam_id(child)
			if not fireteam_id.is_empty():
				if not _units_by_fireteam.has(fireteam_id):
					_units_by_fireteam[fireteam_id] = []
				var fireteam_units: Array = Array(_units_by_fireteam[fireteam_id])
				fireteam_units.append(child)
				_units_by_fireteam[fireteam_id] = fireteam_units
		elif not team_id.is_empty() and team_id != "team_unused":
			_enemy_units.append(child)
	_friendly_units.sort_custom(Callable(self, "_sort_units_by_id"))
	_enemy_units.sort_custom(Callable(self, "_sort_units_by_id"))
	for fireteam_id_variant in _units_by_fireteam.keys():
		var fireteam_units: Array = Array(_units_by_fireteam[fireteam_id_variant])
		fireteam_units.sort_custom(Callable(self, "_sort_units_by_id"))
		_units_by_fireteam[fireteam_id_variant] = fireteam_units
	_membership_revision += 1
	membership_revision_changed.emit(_membership_revision)


func _is_indexable_unit(candidate: Node) -> bool:
	return candidate != null and candidate.has_method("get_team_id") and candidate.has_method("get_unit_id") and candidate.has_method("get_fireteam_id")


func _get_unit_id(unit: Node) -> String:
	return String(unit.call("get_unit_id")).strip_edges() if unit != null and unit.has_method("get_unit_id") else ""


func _get_fireteam_id(unit: Node) -> String:
	return String(unit.call("get_fireteam_id")).strip_edges().to_lower() if unit != null and unit.has_method("get_fireteam_id") else ""


func _filter_visible_units(units: Array, include_hidden: bool) -> Array:
	if include_hidden:
		return units.duplicate()
	var result: Array = []
	for unit in units:
		if unit is CanvasItem and not (unit as CanvasItem).visible:
			continue
		result.append(unit)
	return result


func _append_fireteam_id_once(target: PackedStringArray, raw_fireteam_id: String) -> void:
	var fireteam_id: String = raw_fireteam_id.strip_edges().to_lower()
	if not fireteam_id.is_empty() and not target.has(fireteam_id):
		target.append(fireteam_id)


func _sort_units_by_id(left: Node, right: Node) -> bool:
	return _get_unit_id(left) < _get_unit_id(right)
