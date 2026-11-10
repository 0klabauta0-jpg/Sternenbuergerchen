extends RefCounted
## Ordered campaign presentation facts, supplied only by the bound runtime.
const STAGE_FACTS := [["base_ready"], ["satellite_uploaded"], ["outpost_completed", "outpost_recruited", "crate_loaded"], ["delivery_completed"], ["outpost_chip_uploaded"], ["rescue_completed", "pilot_recruited"], ["second_pad_built"]]
var _stage_index := 0
var _facts: Dictionary = {}
var _revision := 0
func configure() -> Dictionary:
	_stage_index = 0
	_facts = {}
	_revision = 0
	return {"ok":true}
func get_snapshot() -> Dictionary:
	var next := "completed"
	if _stage_index < STAGE_FACTS.size():
		for fact in STAGE_FACTS[_stage_index]:
			if not bool(_facts.get(fact,false)):
				next = fact
				break
	return {"stage_index":_stage_index,"stage_count":STAGE_FACTS.size(),"next_step_id":next,"completed":_stage_index == STAGE_FACTS.size(),"revision":_revision,"facts":_facts.duplicate(true)}
func apply_command(command: Dictionary, trusted_context: Dictionary = {}) -> Dictionary:
	if command.get("contract_category") != "campaign_onboarding" or command.get("operation") != "observe" or typeof(trusted_context.get("runtime_evidence",{})) != TYPE_DICTIONARY:
		return {"ok":false,"reason":"invalid_command"}
	if _stage_index >= STAGE_FACTS.size(): return {"ok":true,"changed":false}
	var evidence: Dictionary = trusted_context.get("runtime_evidence",{})
	var before := _facts.duplicate(true)
	for fact in STAGE_FACTS[_stage_index]:
		if evidence.get(fact) == true: _facts[fact] = true
	var complete := true
	for fact in STAGE_FACTS[_stage_index]: complete = complete and bool(_facts.get(fact,false))
	var changed := before != _facts
	if complete:
		_stage_index += 1
		_facts = {}
		changed = true
	if changed: _revision += 1
	return {"ok":true,"changed":changed,"snapshot":get_snapshot()}
func export_state() -> Dictionary:
	return {"schema_version":2,"stage_index":_stage_index,"facts":_facts.duplicate(true),"revision":_revision}
func restore_state(data: Dictionary) -> Dictionary:
	if data.get("schema_version") != 2 or not _integer(data.get("stage_index")) or int(data.stage_index) > STAGE_FACTS.size() or not _integer(data.get("revision")) or typeof(data.get("facts")) != TYPE_DICTIONARY:
		return {"ok":false,"reason":"invalid_onboarding_state"}
	var stage := int(data.stage_index)
	for key in data.facts:
		if stage == STAGE_FACTS.size() or not STAGE_FACTS[stage].has(key) or data.facts[key] != true:
			return {"ok":false,"reason":"invalid_onboarding_facts"}
	if stage < STAGE_FACTS.size() and data.facts.size() == STAGE_FACTS[stage].size():
		return {"ok":false,"reason":"uncommitted_onboarding_transition"}
	_stage_index = stage
	_facts = data.facts.duplicate(true)
	_revision = int(data.revision)
	return {"ok":true}
func _integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0 and float(value) == floor(float(value)) and float(value) <= 2147483647
