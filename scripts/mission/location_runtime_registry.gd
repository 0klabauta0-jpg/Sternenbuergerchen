extends RefCounted
## Lookup only. Local SimulationRoots remain gameplay owners.
var _instances: Dictionary={}
func register_location(location_id: String, instance: Node) -> bool:
	if location_id.is_empty() or instance==null: return false
	var current: Node=get_location(location_id)
	if current!=null and current!=instance: return false
	_instances[location_id]=weakref(instance); return true
func get_location(location_id: String) -> Node:
	return _instances[location_id].get_ref() if _instances.has(location_id) else null
func unregister_location(location_id: String, expected_instance_id: int) -> bool:
	if not _instances.has(location_id): return false
	var current: Node = get_location(location_id)
	if current != null and current.get_instance_id() != expected_instance_id: return false
	_instances.erase(location_id)
	return true
func location_ids() -> Array:
	var result: Array=[]
	for id in _instances:
		if get_location(id)!=null: result.append(id)
	return result
