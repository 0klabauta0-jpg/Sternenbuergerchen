extends RefCounted
## Progress consumes trusted adapter evidence only. Facts cannot cross stage boundaries.
const STAGE_FACTS := [["base_ready"], ["satellite_completed", "satellite_home"], ["trade_departed", "trade_used", "bought", "refueled", "trade_home"]]
var _stage_index: int = 0
var _facts: Dictionary = {}
var _revision: int = 0
func configure() -> Dictionary:
	_stage_index = 0
	_facts = {}
	_revision = 0
	return {"ok":true}
func get_snapshot() -> Dictionary:
	var next_step := "completed"
	if _stage_index < 3:
		for fact in STAGE_FACTS[_stage_index]:
			if not bool(_facts.get(fact, false)):
				next_step = fact
				break
	return {"stage_index":_stage_index,"next_step_id":next_step,"completed":_stage_index == 3,"revision":_revision,"facts":_facts.duplicate(true)}
func apply_command(command: Dictionary, trusted_context: Dictionary = {}) -> Dictionary:
	if String(command.get("contract_category", "")) != "campaign_onboarding" or String(command.get("operation", "")) != "observe":
		return {"ok":false,"reason":"invalid_command"}
	if typeof(trusted_context.get("runtime_evidence", {})) != TYPE_DICTIONARY:
		return {"ok":false,"reason":"invalid_evidence"}
	if _stage_index == 3:
		return {"ok":true,"changed":false}
	var evidence: Dictionary = trusted_context.get("runtime_evidence", {})
	var before := _facts.duplicate(true)
	for fact in STAGE_FACTS[_stage_index]:
		# Ordered trip facts: purchase/refuel only after actual use; home only after both.
		if _stage_index == 1 and fact == "satellite_home" and not _facts.get("satellite_completed", false):
			continue
		if _stage_index == 2:
			if fact != "trade_departed" and not _facts.get("trade_departed", false):
				continue
			if fact in ["bought", "refueled", "trade_home"] and not _facts.get("trade_used", false):
				continue
			if fact == "trade_home" and not (_facts.get("bought", false) and _facts.get("refueled", false)):
				continue
		if typeof(evidence.get(fact)) == TYPE_BOOL and evidence[fact]:
			_facts[fact] = true
	var complete := true
	for fact in STAGE_FACTS[_stage_index]:
		complete = complete and bool(_facts.get(fact, false))
	var changed := before != _facts
	if complete:
		_stage_index += 1
		_facts = {}
		changed = true
	if changed:
		_revision += 1
	return {"ok":true,"changed":changed,"snapshot":get_snapshot()}
func export_state() -> Dictionary:
	return {"schema_version":1,"stage_index":_stage_index,"facts":_facts.duplicate(true),"revision":_revision}
func restore_state(data: Dictionary) -> Dictionary:
	if data.get("schema_version") != 1 or typeof(data.get("stage_index")) not in [TYPE_INT, TYPE_FLOAT] or float(data.stage_index) != floor(float(data.stage_index)) or float(data.stage_index) < 0 or float(data.stage_index) > 3 or typeof(data.get("facts")) != TYPE_DICTIONARY or typeof(data.get("revision")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(data.revision)) or float(data.revision) > 2147483647 or float(data.revision) < 0 or float(data.revision) != floor(float(data.revision)):
		return {"ok":false,"reason":"invalid_onboarding_state"}
	var stage := int(data.stage_index)
	var facts: Dictionary = data.facts
	for key in facts:
		if stage == 3 or not STAGE_FACTS[stage].has(key) or typeof(facts[key]) != TYPE_BOOL or not facts[key]:
			return {"ok":false,"reason":"invalid_onboarding_facts"}
	if (facts.has("trade_home") and not (facts.has("trade_departed") and facts.has("trade_used") and facts.has("bought") and facts.has("refueled"))) or (facts.has("satellite_home") and not facts.has("satellite_completed")) or (stage == 2 and ((facts.has("trade_used") and not facts.has("trade_departed")) or ((facts.has("bought") or facts.has("refueled")) and not facts.has("trade_used")))):
		return {"ok":false,"reason":"invalid_onboarding_order"}
	if stage < 3:
		var all_facts := true
		for fact in STAGE_FACTS[stage]:
			all_facts = all_facts and facts.has(fact)
		if all_facts:
			return {"ok":false,"reason":"uncommitted_onboarding_transition"}
	_stage_index = stage
	_facts = facts.duplicate(true)
	_revision = int(data.revision)
	return {"ok":true}
