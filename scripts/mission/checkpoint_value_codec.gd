extends RefCounted
## Bounded, typed JSON representation for gameplay values. Never creates Objects.
const MAX_DEPTH := 16
const MAX_ITEMS := 4096
const MAX_SAFE_INTEGER := 9007199254740991.0

## Exact comparison across JSON's numeric representation, never an epsilon or
## a field-dropping migration. Keep booleans, strings, structure and keys typed.
static func equal_json_values(left: Variant, right: Variant, depth: int = 0) -> bool:
	if depth > MAX_DEPTH: return false
	var left_type := typeof(left)
	var right_type := typeof(right)
	if left_type in [TYPE_INT,TYPE_FLOAT] and right_type in [TYPE_INT,TYPE_FLOAT]:
		if not is_finite(float(left)) or not is_finite(float(right)): return false
		if (left_type == TYPE_INT and abs(float(left)) > MAX_SAFE_INTEGER) or (right_type == TYPE_INT and abs(float(right)) > MAX_SAFE_INTEGER): return false
		return float(left) == float(right)
	if left_type != right_type: return false
	if left_type == TYPE_DICTIONARY:
		if left.size() != right.size() or left.size() > MAX_ITEMS: return false
		for key in left:
			if typeof(key) != TYPE_STRING or not right.has(key) or not equal_json_values(left[key],right[key],depth+1): return false
		return true
	if left_type == TYPE_ARRAY:
		if left.size() != right.size() or left.size() > MAX_ITEMS: return false
		for index in range(left.size()):
			if not equal_json_values(left[index],right[index],depth+1): return false
		return true
	return left_type in [TYPE_NIL,TYPE_BOOL,TYPE_STRING] and left == right

static func encode_value(value: Variant, depth: int = 0) -> Dictionary:
	if depth > MAX_DEPTH: return _bad()
	match typeof(value):
		TYPE_NIL: return {"ok":true, "value":["nil", null]}
		TYPE_BOOL: return {"ok":true, "value":["bool", value]}
		TYPE_STRING: return {"ok":true, "value":["string", value]}
		TYPE_INT:
			if abs(float(value)) > MAX_SAFE_INTEGER: return _bad()
			return {"ok":true, "value":["int", value]}
		TYPE_FLOAT:
			if not is_finite(value): return _bad()
			return {"ok":true, "value":["float", value]}
		TYPE_VECTOR2:
			if not is_finite(value.x) or not is_finite(value.y): return _bad()
			return {"ok":true, "value":["vector2", [value.x, value.y]]}
		TYPE_VECTOR2I: return {"ok":true, "value":["vector2i", [value.x, value.y]]}
		TYPE_ARRAY:
			if value.size() > MAX_ITEMS: return _bad()
			var items: Array = []
			for entry in value:
				var encoded := encode_value(entry, depth + 1)
				if not encoded.ok: return encoded
				items.append(encoded.value)
			return {"ok":true, "value":["array", items]}
		TYPE_DICTIONARY:
			if value.size() > MAX_ITEMS: return _bad()
			var items := {}
			for key in value:
				if typeof(key) != TYPE_STRING: return _bad()
				var encoded := encode_value(value[key], depth + 1)
				if not encoded.ok: return encoded
				items[key] = encoded.value
			return {"ok":true, "value":["dictionary", items]}
	return _bad()

static func decode_value(encoded: Variant, depth: int = 0) -> Dictionary:
	if depth > MAX_DEPTH or not encoded is Array or encoded.size() != 2 or typeof(encoded[0]) != TYPE_STRING: return _bad()
	var value: Variant = encoded[1]
	match encoded[0]:
		"nil":
			if value == null: return {"ok":true, "value":null}
		"bool":
			if typeof(value) == TYPE_BOOL: return {"ok":true, "value":value}
		"string":
			if typeof(value) == TYPE_STRING: return {"ok":true, "value":value}
		"int":
			if _integer(value): return {"ok":true, "value":int(value)}
		"float":
			if _number(value): return {"ok":true, "value":float(value)}
		"vector2", "vector2i":
			if not value is Array or value.size() != 2: return _bad()
			if encoded[0] == "vector2" and _number(value[0]) and _number(value[1]): return {"ok":true, "value":Vector2(value[0], value[1])}
			if encoded[0] == "vector2i" and _integer(value[0]) and _integer(value[1]) and float(value[0]) >= -2147483648.0 and float(value[0]) <= 2147483647.0 and float(value[1]) >= -2147483648.0 and float(value[1]) <= 2147483647.0: return {"ok":true, "value":Vector2i(int(value[0]), int(value[1]))}
		"array":
			if not value is Array or value.size() > MAX_ITEMS: return _bad()
			var items: Array = []
			for entry in value:
				var decoded := decode_value(entry, depth + 1)
				if not decoded.ok: return decoded
				items.append(decoded.value)
			return {"ok":true, "value":items}
		"dictionary":
			if not value is Dictionary or value.size() > MAX_ITEMS: return _bad()
			var items := {}
			for key in value:
				if typeof(key) != TYPE_STRING: return _bad()
				var decoded := decode_value(value[key], depth + 1)
				if not decoded.ok: return decoded
				items[key] = decoded.value
			return {"ok":true, "value":items}
	return _bad()

static func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))
static func _integer(value: Variant) -> bool:
	return _number(value) and abs(float(value)) <= MAX_SAFE_INTEGER and floor(float(value)) == float(value)
static func _bad() -> Dictionary:
	return {"ok":false, "reason":"invalid_checkpoint_value"}
