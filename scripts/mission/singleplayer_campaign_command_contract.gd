extends RefCounted

const PAYLOAD_VALIDATOR: GDScript = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")

const CATEGORY := "singleplayer_campaign"
const OPERATIONS := ["accept_job", "select_destination", "bind_departure", "activate_job", "complete_job", "fail_job", "retry_failed_job", "upload_job", "claim_recruit", "load_crate", "deliver_crate", "build_pad"]

static func build_command(operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	if not OPERATIONS.has(operation) or request_id.strip_edges().is_empty():
		return {}
	return {"contract_category": CATEGORY, "operation": operation, "payload": payload.duplicate(true), "request_id": request_id.strip_edges()}

static func build_accept_job_command(job_id: String, request_id: String) -> Dictionary:
	return build_command("accept_job", {"job_id": job_id}, request_id)

static func build_select_destination_command(location_id: String, job_id: String, request_id: String) -> Dictionary:
	return build_command("select_destination", {"location_id": location_id, "job_id": job_id}, request_id)

static func validate_command(command: Dictionary) -> bool:
	return String(command.get("contract_category", "")) == CATEGORY and OPERATIONS.has(String(command.get("operation", ""))) and typeof(command.get("payload")) == TYPE_DICTIONARY and PAYLOAD_VALIDATOR._finite_payload(command.payload) and typeof(command.get("request_id")) == TYPE_STRING and not String(command.get("request_id", "")).strip_edges().is_empty()
