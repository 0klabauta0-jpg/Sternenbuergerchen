extends RefCounted
## Finite per-place resources. Supply owns this object across scene/view changes.
var _sites: Dictionary={}
func configure(definitions: Dictionary) -> void:
	_sites=definitions.duplicate(true)
	for id in _sites:
		_sites[id].remaining=int(_sites[id].quantity)
		_sites[id].discovered=false
func discover(id: String) -> bool:
	if not _sites.has(id) or _sites[id].discovered: return false
	_sites[id].discovered=true
	return true
func get_site_snapshot(id: String) -> Dictionary:
	return Dictionary(_sites.get(id,{})).duplicate(true)
func get_snapshot() -> Dictionary: return _sites.duplicate(true)
func consume(id: String) -> void: _sites[id].remaining=0
func export_state() -> Dictionary:
	var saved: Dictionary={}
	for id in _sites: saved[id]={"remaining":_sites[id].remaining,"discovered":_sites[id].discovered}
	return saved
func restore_state(data: Dictionary) -> bool:
	if data.size()!=_sites.size(): return false
	for id in data:
		if not _sites.has(id) or typeof(data[id])!=TYPE_DICTIONARY: return false
		var amount: Variant=data[id].get("remaining")
		if typeof(amount) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(amount)) or float(amount) not in [0.0,float(_sites[id].quantity)] or typeof(data[id].get("discovered"))!=TYPE_BOOL: return false
	for id in data:
		_sites[id].remaining=int(data[id].remaining); _sites[id].discovered=data[id].discovered
	return true
