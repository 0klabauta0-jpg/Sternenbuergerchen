extends RefCounted
## Lossless canonicalization of string-like dictionary keys for Godot JSON.
## All other non-JSON values remain rejected; no silent object stringification.
static func normalize(value: Variant, depth: int = 0) -> Dictionary:
	if depth > 32: return _bad()
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING, TYPE_INT: return {"ok":true,"value":value}
		TYPE_STRING_NAME: return {"ok":true,"value":String(value)}
		TYPE_FLOAT:
			return {"ok":true,"value":value} if is_finite(value) else _bad()
		TYPE_ARRAY:
			if value.size()>65536: return _bad()
			var result: Array = []
			for child in value:
				var entry := normalize(child,depth+1)
				if not entry.ok: return entry
				result.append(entry.value)
			return {"ok":true,"value":result}
		TYPE_DICTIONARY:
			if value.size()>65536: return _bad()
			var result := {}
			for key in value:
				if typeof(key) not in [TYPE_STRING,TYPE_STRING_NAME]: return _bad()
				var text := String(key)
				if result.has(text): return _bad()
				var entry := normalize(value[key],depth+1)
				if not entry.ok: return entry
				result[text] = entry.value
			return {"ok":true,"value":result}
	return _bad()

static func _bad() -> Dictionary:
	return {"ok":false,"reason":"active_json_value_unsupported"}
