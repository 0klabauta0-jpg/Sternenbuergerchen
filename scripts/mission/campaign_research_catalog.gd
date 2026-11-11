extends RefCounted
## Immutable development definitions and pure prerequisite projection.
const DATA_PATH := "res://data/singleplayer/research.json"
static var _catalog: Dictionary = {}

static func definitions() -> Dictionary:
	if _catalog.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary and parsed.get("schema_version") == 1 and parsed.get("nodes") is Dictionary and parsed.get("fabrication") is Dictionary:
			_catalog = parsed
	return _catalog.duplicate(true)

static func fabrication(blueprint_id: String) -> Dictionary:
	return Dictionary(Dictionary(definitions().get("fabrication", {})).get(blueprint_id, {})).duplicate(true)

static func item_label(item: String) -> String:
	return String({"salvage":"Bergungsgut", "backpack":"Rucksack"}.get(item, item))

static func fabricated_blueprints(requests: Dictionary) -> Dictionary:
	var result := {}
	for request: Dictionary in requests.values():
		var signature: Variant = JSON.parse_string(String(request.get("signature", "{}")))
		if not signature is Dictionary or signature.get("operation") != "campaign_fabricate": continue
		var payload: Dictionary = signature.get("payload", {})
		var receipt: Dictionary = request.get("result", {})
		if receipt.get("ok") == true:
			result[String(payload.get("blueprint_id", ""))] = String(receipt.get("item_id", ""))
	return result

static func missing_requirement(node: Dictionary, developed: Dictionary, rewards: Dictionary, fabricated: Dictionary) -> String:
	for job_id: String in node.get("requires_jobs", []):
		if not rewards.has(job_id + ":completed"): return "Zuerst den gesicherten Außenposten-Chip heimbringen und hochladen."
	for research_id: String in node.get("requires_research", []):
		if not developed.has(research_id):
			var parent: Dictionary = definitions().get("nodes", {}).get(research_id, {})
			return "Voraussetzung: " + String(parent.get("title", research_id))
	for blueprint_id: String in node.get("requires_fabricated", {}):
		if String(fabricated.get(blueprint_id, "")) != String(node.requires_fabricated[blueprint_id]):
			var label := String(Dictionary(node.get("requires_fabricated_labels", {})).get(blueprint_id, blueprint_id))
			return "Zuerst %s in der Werkstatt herstellen." % label
	return ""

static func build_snapshot(developed: Dictionary, rewards: Dictionary, requests: Dictionary, credits: int) -> Dictionary:
	var result := {}
	var fabricated := fabricated_blueprints(requests)
	for id: String in definitions().get("nodes", {}):
		var node: Dictionary = definitions().nodes[id].duplicate(true)
		var done := developed.has(id)
		var reason := missing_requirement(node, developed, rewards, fabricated)
		if reason.is_empty() and credits < int(node.cost): reason = "Credits reichen für die Entwicklung nicht."
		node.merge({"id": id, "developed": done, "available": not done and reason.is_empty(),
			"message": "Bereits entwickelt" if done else reason}, true)
		result[id] = node
	return {"nodes": result, "developed_ids": developed.keys(), "balance_status": "initial_values"}

static func validate_receipts(receipts: Variant, rewards: Dictionary, requests: Dictionary) -> bool:
	if not receipts is Dictionary: return false
	var nodes: Dictionary = definitions().get("nodes", {})
	var fabricated := fabricated_blueprints(requests)
	for id: Variant in receipts:
		if not id is String or not nodes.has(id) or not receipts[id] is Dictionary: return false
		var receipt: Dictionary = receipts[id]
		var node: Dictionary = nodes[id]
		if receipt.size() != 4 or receipt.get("schema_version") != 1 or receipt.get("research_id") != id or receipt.get("cost") != node.cost or not receipt.get("request_id") is String: return false
		var request: Dictionary = requests.get(receipt.request_id, {})
		var signature: Variant = JSON.parse_string(String(request.get("signature", "{}")))
		var result: Dictionary = request.get("result", {})
		if not signature is Dictionary or signature.get("operation") != "campaign_research" or not signature.get("payload") is Dictionary: return false
		if signature.payload.get("research_id") != id or result.get("research_id") != id or result.get("cost") != node.cost or result.get("changed") != true or result.get("development_receipt") != receipt: return false
		if not missing_requirement(node, receipts, rewards, fabricated).is_empty(): return false
	# A save may not lose the ledger but keep successful development requests.
	for request: Dictionary in requests.values():
		var signature: Variant = JSON.parse_string(String(request.get("signature", "{}")))
		if not signature is Dictionary or signature.get("operation") != "campaign_research": continue
		var id := String(Dictionary(signature.get("payload", {})).get("research_id", ""))
		var result: Dictionary = request.get("result", {})
		if not nodes.has(id) or not receipts.has(id) or result.get("research_id") != id or not result.get("changed") is bool: return false
		if result.get("changed") == false and result.get("cost") != 0: return false
		if result.get("changed") == true and receipts[id].request_id != result.get("request_id"): return false
	return true
