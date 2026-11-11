extends SceneTree
const CONTRACT = preload("res://scripts/mission/space_combat_command_contract.gd")

func _initialize() -> void:
	var context := {"authorized": true, "revision": 1, "phase": "tactical", "owned_wings": ["w1"], "owned_crafts": ["c1"], "wing_members": {"w1": ["c1"]}, "known_targets": ["enemy1"]}
	var command := {"contract_category": "space_combat", "operation": "wing_assign", "request_id": "r1", "expected_revision": 1, "payload": {"wing_id": "w1", "craft_id": "c1"}}
	var failures := 0
	if not CONTRACT.validate(command, context).ok: failures += 1
	var bad := command.duplicate(true)
	bad.operation = "damage"
	if CONTRACT.validate(bad, context).reason != "unknown_operation": failures += 1
	bad = command.duplicate(true)
	bad.payload.craft_id = "foreign"
	if CONTRACT.validate(bad, context).reason != "not_owned": failures += 1
	bad = command.duplicate(true)
	bad.expected_revision = 0
	if CONTRACT.validate(bad, context).reason != "stale_revision": failures += 1
	bad = command.duplicate(true)
	bad.payload["value"] = INF
	if CONTRACT.validate(bad, context).reason != "invalid_payload": failures += 1
	bad = command.duplicate(true)
	bad.payload["target_hex"] = Vector2i(9999, 9999)
	if CONTRACT.validate(bad, context).reason != "invalid_hex": failures += 1
	bad = command.duplicate(true)
	bad.payload["runtime_authorized"] = true
	if CONTRACT.validate(bad, context).reason != "untrusted_authority": failures += 1
	var untrusted := context.duplicate(true)
	untrusted.authorized = false
	if CONTRACT.validate(command, untrusted).reason != "authority_required": failures += 1
	bad = command.duplicate(true)
	bad.operation = "order_issue"
	bad.payload = {"wing_ids": ["w1"], "verb": "attack_target", "target_id": "hidden"}
	if CONTRACT.validate(bad, context).reason != "unknown_target": failures += 1
	bad.payload.target_id = "enemy1"
	bad.payload["area_hexes"] = [Vector2i(9999, 9999)]
	if CONTRACT.validate(bad, context).reason != "invalid_hex": failures += 1
	bad = command.duplicate(true)
	bad.payload["extra"] = {"runtime_authorized": true}
	if CONTRACT.validate(bad, context).reason != "untrusted_authority": failures += 1
	bad = command.duplicate(true)
	bad.payload = {"wing_id": "w1"}
	if CONTRACT.validate(bad, context).reason != "missing_field": failures += 1
	var before := command.duplicate(true)
	var before_context := context.duplicate(true)
	CONTRACT.validate(command, context)
	if command != before or context != before_context: failures += 1
	var replay_context := context.duplicate(true)
	replay_context.receipts = {"r1": {"signature": CONTRACT.request_signature(command), "result": {"ok": true, "revision": 2}}}
	replay_context.revision = 2
	if not CONTRACT.validate(command, replay_context).get("replayed", false): failures += 1
	bad = command.duplicate(true)
	bad.payload.craft_id = "c2"
	if CONTRACT.validate(bad, replay_context).reason != "request_id_conflict": failures += 1
	bad = command.duplicate(true)
	bad.operation = "order_issue"
	bad.payload = {"wing_ids": ["w1"], "verb": "move", "target_hex": Vector2i.ZERO, "contact_response": "avoid", "fire_rule": "free"}
	if CONTRACT.validate(bad, context).reason != "incompatible_rules": failures += 1
	bad.payload.fire_rule = "hold"
	if not CONTRACT.validate(bad, context).ok: failures += 1
	bad.payload.wing_ids = ["w1", "w1"]
	if CONTRACT.validate(bad, context).reason != "duplicate_wing": failures += 1
	bad = command.duplicate(true)
	bad.payload = "bad"
	if CONTRACT.validate(bad, context).reason != "invalid_envelope": failures += 1
	var profile_root := OS.get_environment("APPDATA").replace("\\", "/").to_lower()
	var fixture_path := ProjectSettings.globalize_path("user://space_ap00_fixture.txt").replace("\\", "/").to_lower()
	if profile_root.is_empty() or not fixture_path.begins_with(profile_root + "/"):
		failures += 1
	else:
		var fixture := FileAccess.open("user://space_ap00_fixture.txt", FileAccess.WRITE)
		if fixture == null:
			failures += 1
		else:
			fixture.store_string("isolated")
			fixture.close()
			if FileAccess.get_file_as_string("user://space_ap00_fixture.txt") != "isolated": failures += 1
	var target_command := {"contract_category":"space_combat", "operation":"order_issue", "request_id":"r2", "expected_revision":1, "payload":{"wing_ids":["w1"], "verb":"move", "target_hex":Vector2i.ZERO}}
	var target_context := context.duplicate(true)
	target_context.receipts = {"r2":{"signature":CONTRACT.request_signature(target_command), "result":{"ok":true}}}
	var different_type := target_command.duplicate(true)
	different_type.payload.target_hex = "(0, 0)"
	if CONTRACT.validate(different_type, target_context).reason != "request_id_conflict": failures += 1
	var reordered := {"payload":target_command.payload.duplicate(true), "expected_revision":1, "request_id":"r2", "operation":"order_issue", "contract_category":"space_combat"}
	if not CONTRACT.validate(reordered, target_context).get("replayed", false): failures += 1
	print("SPACE_COMBAT_AP00 passed=", 22 - failures, " failed=", failures)
	quit(1 if failures else 0)
