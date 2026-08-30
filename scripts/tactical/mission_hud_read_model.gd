class_name MissionHudReadModel
extends Node

## Read-only revision tracker for HUD surfaces.
##
## Values remain in their existing controller/runtime owners. This object merely
## records whether a visible light surface or a specific heavy fireteam surface
## needs to be read again.

var _light_state: Dictionary = {}
var _light_revision: int = 0
var _heavy_revision: int = 0
var _fireteam_heavy_revisions: Dictionary = {}


func set_light_state(surface_id: String, value: Variant) -> bool:
	var normalized_surface_id: String = surface_id.strip_edges()
	if normalized_surface_id.is_empty():
		return false
	if _light_state.has(normalized_surface_id) and _light_state[normalized_surface_id] == value:
		return false
	_light_state[normalized_surface_id] = value
	_light_revision += 1
	return true


func mark_heavy_state_changed() -> void:
	_heavy_revision += 1


func mark_fireteam_heavy_state_changed(fireteam_id: String) -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return
	_fireteam_heavy_revisions[normalized_fireteam_id] = int(_fireteam_heavy_revisions.get(normalized_fireteam_id, 0)) + 1
	_heavy_revision += 1


func get_light_revision() -> int:
	return _light_revision


func get_heavy_revision() -> int:
	return _heavy_revision


func get_fireteam_heavy_revision(fireteam_id: String) -> int:
	return int(_fireteam_heavy_revisions.get(fireteam_id.strip_edges().to_lower(), 0))


func get_diagnostics_snapshot() -> Dictionary:
	return {
		"light_revision": _light_revision,
		"heavy_revision": _heavy_revision,
		"fireteam_heavy_revisions": _fireteam_heavy_revisions.duplicate(),
		"read_only": true,
		"hud_read_model_owns_gameplay_truth": false,
	}
