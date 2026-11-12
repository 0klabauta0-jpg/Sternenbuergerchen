extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var projection = load("res://scripts/ui/polisa_service_route_projection.gd")
	var source := {"craft_id":"own", "routes":{"own":{"phase":"orbit"}}}
	var shuttle := {"craft_id":"service_1", "route":{"phase":"quantum", "position":[1.0,2.0]}}
	var result: Dictionary = projection.merge(source, shuttle)
	assert(result.routes.has("own") and result.routes.has("service_1"))
	assert(not source.routes.has("service_1"), "Projection must not mutate fleet owner")
	assert(result.craft_id == "own", "Service craft must not become the selected craft")
	assert(projection.merge(source, {"craft_id":"own", "route":{"phase":"quantum"}}).routes.own.phase == "orbit")
	assert(not projection.merge(source, {"craft_id":"service_1", "route":{}}).routes.has("service_1"))
	var single := {"craft_id":"own", "phase":"orbit", "position":[3.0, 4.0]}
	var single_result: Dictionary = projection.merge(single, shuttle)
	assert(single_result.routes.has("own") and single_result.routes.has("service_1"))
	assert(projection.describe({"phase":"home_landing_required"}) == "Stationsshuttle: wartet auf einen freien Landeplatz")
	assert(projection.describe({"phase":"home_landing_required"}, {"phase":"inbound"}) == "Stationsshuttle: landet an der Heimatbasis")
	assert(projection.describe({"phase":"idle"}).is_empty())
	assert(projection.describe({"phase":"idle"}, {}, {"phase":"pilot_pending"}) == "Stationsshuttle: wird auf Polisa vorbereitet")
	print("PASS: service route projection preserves player fleet")
	quit(0)
