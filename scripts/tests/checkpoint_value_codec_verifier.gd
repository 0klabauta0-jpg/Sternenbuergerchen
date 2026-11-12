extends SceneTree
func _initialize() -> void:
 var codec = load("res://scripts/mission/checkpoint_value_codec.gd")
 if codec == null:
  printerr("checkpoint codec absent")
  quit(1)
  return
 var source := {"position":Vector2(4.5,-2), "grid":Vector2i(-3,7), "nested":[null, true, 7, 2.5, "ä", {"x":"vector2"}]}
 var encoded: Dictionary = codec.encode_value(source)
 assert(encoded.ok)
 var json: Variant = JSON.parse_string(JSON.stringify(encoded.value))
 var decoded: Dictionary = codec.decode_value(json)
 assert(decoded.ok and decoded.value == source)
 assert(not codec.encode_value({"bad":INF}).ok)
 assert(not codec.encode_value({"node":RefCounted.new()}).ok)
 assert(not codec.decode_value(["vector2", ["bad", 1]]).ok)
 assert(not codec.decode_value(["unknown", 1]).ok)
 assert(not codec.decode_value(["int", 9007199254740992.0]).ok)
 assert(not codec.decode_value(["dictionary", {"x":["vector2i", [2147483648, 0]]}]).ok)
 var min_cell: Dictionary = codec.decode_value(["vector2i", [-2147483648, 0]])
 assert(min_cell.ok and min_cell.value == Vector2i(-2147483648, 0))
 print("CHECKPOINT_VALUE_CODEC_PASS")
 quit(0)
