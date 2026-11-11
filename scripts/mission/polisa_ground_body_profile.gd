extends RefCounted
## Pure value validation. Position remains with the existing landing/sequence owner.
const VISUALS = preload("res://scripts/terrain/frontier_ship_visuals.gd")
const KEYS := ["craft_id","model_id","asset_id","bounds","model_scale","cell_size","yaw_degrees"]

static func from_projection(craft: Dictionary, projection: Dictionary) -> Dictionary:
	if projection.get("ok") != true: return _reject()
	var profile := {"craft_id":craft.get("craft_id")}
	for key in KEYS:
		if key != "craft_id": profile[key] = projection.get(key)
	return read_bound(craft, profile)

static func read_bound(craft: Dictionary, value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY or value.size() != KEYS.size(): return _reject()
	for key in KEYS:
		if not value.has(key): return _reject()
	for key in ["craft_id","model_id","asset_id"]:
		if typeof(value[key]) != TYPE_STRING or String(value[key]).strip_edges().is_empty(): return _reject()
	if value.craft_id != craft.get("craft_id") or value.model_id != craft.get("model_id") or value.model_id not in ["cutlass","buccaneer"]: return _reject()
	var identity: Dictionary = VISUALS.get_ui_identity(craft)
	if identity.is_empty() or value.asset_id != identity.get("asset_id"): return _reject()
	if typeof(value.bounds) != TYPE_AABB: return _reject()
	var bounds: AABB = value.bounds
	if not bounds.position.is_finite() or not bounds.size.is_finite() or bounds.size.x <= 0.0 or bounds.size.y <= 0.0 or bounds.size.z <= 0.0: return _reject()
	for key in ["model_scale","cell_size","yaw_degrees"]:
		if typeof(value[key]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value[key])): return _reject()
	if float(value.model_scale) <= 0.0 or float(value.cell_size) <= 0.0: return _reject()
	# Construct new values explicitly; no aliases to caller arrays/dictionaries/objects.
	return {"ok":true,"profile":{"craft_id":String(value.craft_id),"model_id":String(value.model_id),
		"asset_id":String(value.asset_id),"bounds":bounds,"model_scale":float(value.model_scale),
		"cell_size":float(value.cell_size),"yaw_degrees":float(value.yaw_degrees)}}

static func _reject() -> Dictionary:
	return {"ok":false,"reason":"ground_ship_geometry_unbound"}
