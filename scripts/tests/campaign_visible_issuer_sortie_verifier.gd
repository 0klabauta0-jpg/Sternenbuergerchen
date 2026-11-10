extends "res://scripts/tests/compact_team_actual_boarding_verifier.gd"
func _prepare_initial_base()->bool:
 var presenter:Node=_screen.get("_operations_presenter")
 presenter.call("_navigate_from_sidebar","jobs")
 var board:Node=presenter.get("_job_board")
 _check(board.get("_visible_job_ids")==PackedStringArray(["satellite_recovery"]),"new campaign offers only satellite recovery")
 _check(String(board.get("_details").text).contains("Fragwürdige Geschäftsleute"),"first mission names its authored issuer")
 presenter.call("_close_workspace_flyout")
 return await super._prepare_initial_base()
func _finish()->void:
 if _runtime!=null and String(_campaign().jobs.satellite_recovery.status)=="completed":
  var presenter:Node=_screen.get("_operations_presenter")
  presenter.call("_navigate_from_sidebar","jobs")
  var board:Node=presenter.get("_job_board")
  _check(board.get("_visible_job_ids")==PackedStringArray(["satellite_recovery","outpost_recovery"]),"real home upload reveals only next outpost mission and completed history")
  _check(bool(_campaign().jobs.benit_delivery.locked) and bool(_campaign().jobs.buccaneer_rescue.locked),"later campaign missions remain locked after first real upload")
 await super._finish()
