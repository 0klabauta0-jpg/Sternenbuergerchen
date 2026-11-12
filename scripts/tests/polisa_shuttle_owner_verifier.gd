extends SceneTree
var status := {"has_bed":false, "has_task":false}
var evidence := {}
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _verify(kind: String, _person: String, _craft: String, proof: Dictionary) -> bool:
	return evidence.get(kind, "") != "" and evidence[kind] == proof.get("receipt", "")

func _person_status(_person: String) -> Dictionary:
	var result := status.duplicate(true)
	result["ok"] = true
	return result

func _invalid_validator(_kind: String, _person: String, _craft: String, _proof: Dictionary) -> Dictionary:
	return {"ok":false}

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _run() -> void:
	var owner = load("res://scripts/core/polisa_shuttle_service.gd").new()
	var wrong = load("res://scripts/core/polisa_shuttle_service.gd").new()
	wrong.configure(Callable(self,"_invalid_validator"), Callable(self,"_person_status"))
	_check(not wrong.begin("p", "c", {}).ok, "invalid validator return cannot authorize boarding")
	_check(owner.configure(Callable(self,"_verify"), Callable(self,"_person_status")).ok, "configure")
	_check(not owner.begin("p1", "service_1", {"receipt":"fake"}).ok, "unverified boarding rejected")
	evidence["boarding_polisa"] = "station-boarded"
	_check(owner.begin("p1", "service_1", {"receipt":"station-boarded"}).ok, "start journey")
	_check(owner.get_snapshot().phase == "to_home", "homeward flight")
	_check(owner.advance(1).ok, "advance")
	_check(float(owner.get_snapshot().route.progress) > 0.0, "real travel progress")
	owner.advance(60)
	_check(owner.get_snapshot().phase == "home_landing_required", "home orbit waits on physical landing")
	_check(not owner.confirm_landing({"receipt":"fake"}).ok, "unverified landing rejected")
	evidence["landing_home"] = "home-landed"
	_check(owner.confirm_landing({"receipt":"home-landed"}).ok, "home landing")
	_check(owner.get_snapshot().phase == "home_disembark_required", "waits on disembark")
	_check(not owner.validate_disembark({"receipt":"fake"}).ok, "invalid disembark preview rejected")
	evidence["disembark_home"] = "home-exited"
	_check(owner.validate_disembark({"receipt":"home-exited"}).ok, "disembark preview succeeds")
	_check(owner.get_snapshot().phase == "home_disembark_required", "preview is read only")
	var prepared: Dictionary = owner.prepare_home_disembark({"receipt":"home-exited"})
	_check(prepared.get("ok", false), "prepare real disembark")
	var forged := prepared.duplicate(true); forged.person_id = "intruder"
	_check(not owner.validate_prepared_home_disembark(forged).ok, "forged prepared disembark rejected")
	var valid: Dictionary = owner.validate_prepared_home_disembark(prepared)
	_check(valid.ok and owner._publish_prepared_home_disembark(prepared, valid).ok, "home disembark")
	for _i in range(4): owner.advance(60)
	owner.advance(59)
	_check(owner.get_snapshot().phase == "home_waiting", "five minute grace")
	owner.advance(1)
	_check(owner.get_snapshot().phase == "return_boarding_required", "return needs actual boarding")
	_check(not owner.begin_return({"receipt":"fake"}).ok, "unverified return boarding rejected")
	evidence["boarding_home"] = "home-boarded"
	_check(owner.begin_return({"receipt":"home-boarded"}).ok, "return journey")
	owner.advance(60)
	_check(owner.get_snapshot().phase == "station_landing_required", "station landing required")
	_check(not owner.confirm_station_landing({"receipt":"fake"}).ok, "station landing receipt required")
	evidence["landing_polisa"] = "station-landed"
	_check(owner.confirm_station_landing({"receipt":"station-landed"}).ok, "station landing")
	evidence["disembark_polisa"] = "station-exited"
	_check(owner.confirm_station_disembark({"receipt":"station-exited"}).ok, "station disembark")
	_check(owner.get_snapshot().phase == "returned", "return finished")
	_check(not owner.get_snapshot().checkpoint_safe, "remote returned person is not yet restorable")
	_check(not owner.retire_station({"receipt":"fake"}).ok, "remote retirement needs actor and teardown proof")
	evidence["shuttle_retired_polisa"] = "station-retired"
	_check(owner.retire_station({"receipt":"station-retired"}).ok and owner.get_snapshot().checkpoint_safe, "verified station retirement")
	for key in ["has_bed", "has_task"]:
		status = {"has_bed":false,"has_task":false}
		var second = load("res://scripts/core/polisa_shuttle_service.gd").new()
		second.configure(Callable(self,"_verify"), Callable(self,"_person_status"))
		second.begin("p2", "service_" + key, {"receipt":"station-boarded"})
		second.advance(60)
		second.confirm_landing({"receipt":"home-landed"})
		status[key] = true
		second.confirm_disembark({"receipt":"home-exited"})
		second.advance(0)
		_check(second.get_snapshot().phase == "settled", key + " stops return")
		second.advance(60)
		_check(second.get_snapshot().phase == "settled", key + " stays settled")
		_check(not second.retire_home({"receipt":"fake"}).ok, "cannot retire without shuttle teardown proof")
		evidence["shuttle_retired_home"] = "shuttle-removed"
		status = {"has_bed":false,"has_task":false}
		_check(second.retire_home({"receipt":"shuttle-removed"}).ok, "verified home retirement")
		_check(second.get_snapshot().checkpoint_safe, "home retirement allows checkpoint")
	for failure in failures: printerr("FAIL: " + failure)
	print("PASS: real fleet travel, receipts and waiting" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
