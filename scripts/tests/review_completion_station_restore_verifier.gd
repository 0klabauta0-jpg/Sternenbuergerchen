extends "res://scripts/tests/review_completion_maps_verifier.gd"
func _run() -> void:
	if not GUARD.require_isolated_user_data(): return
	for path in ["res://maps/station_outpost_64x64.json","res://maps/station_outpost_192x192.json"]:
		_test_map(path)
		await process_frame
	print("REVIEW_COMPLETION_STATION_RESTORE passed=%d failed=%d" % [passed,failed])
	quit(1 if failed else 0)
