extends PanelContainer
## Embedded preview shares the same read-only system map as the orbital view.

var _screen: WeakRef
var _map: Control

func configure(screen: Control) -> void:
	_screen = weakref(screen)
	name = "RegionMap"
	_map = load("res://scripts/ui/star_map_screen.gd").new()
	add_child(_map)
	_map.call("configure", _snapshot, _request)
	# Operations already refreshes its visible workspace at 4 Hz.
	_map.set_process(false)

func _snapshot() -> Dictionary:
	var screen: Control = _screen.get_ref()
	return Dictionary(screen.call("get_operations_snapshot").get("singleplayer", {})) if screen != null else {}

func _request(operation: String, payload: Dictionary = {}) -> Dictionary:
	var screen: Control = _screen.get_ref()
	if screen == null:
		return {"ok": false, "message": "Sternkarte noch nicht bereit."}
	return screen.call("request_operation", operation, payload)

func refresh() -> void:
	if _map != null:
		_map.call("refresh")
