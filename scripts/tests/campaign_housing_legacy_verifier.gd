extends SceneTree
## Alter Bettbeleg (Einzelbett, 100/500 Cr) an der ECHTEN Hex-Basis: der Beleg laedt ohne neue Abbuchung, wird zum
## Alt-Gebaeude (zwei Betten, Einzelkopie auf Stellplatz 1), Schlaefer und Personen bleiben gueltig und nie im Fussabdruck.
## Die Basis-Personalliste liegt im Hex-Stand unter hex_tactical.base_personnel (nicht oben im Stand).
const START = preload("res://scripts/meta/game_start_contract.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const CAPACITY = preload("res://scripts/meta/base_capacity_layout.gd")
var failed := 0
var flow: Node
var adapter: Node
var base: Node
var sim: Node
func check(value: bool, label: String) -> void:
	print(("PASS: " if value else "FAIL: ") + label)
	if not value: failed += 1
func _init() -> void: call_deferred("run")

var last_error := ""
var old_bed_cell := Vector2i.ZERO
var old_bed_world := Vector2.ZERO
func _boot(mode: String, expect_failure := false) -> bool:
	START.request_start(self, "campaign", mode)
	flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	adapter = flow.get("_singleplayer_runtime")
	if adapter == null:
		last_error = String(flow.get("_campaign_start").get("error_message"))
		if not expect_failure: check(false, "Stand (%s) laedt (Fehler: %s)" % [mode, last_error])
		return false
	base = adapter.get_base_personnel_runtime()
	sim = base.get_simulation_root()
	sim.set_physics_process(false)
	return true

func _free() -> void:
	flow.queue_free(); await process_frame

## Frischer Stand, dann der alte Beleg (Einzelbett) eingeschrieben; `before` darf die Basis vorher veraendern.
func _write_legacy_checkpoint(before: Callable) -> bool:
	if not await _boot("new"): return false
	if before.is_valid(): before.call()
	var saved: Dictionary = flow.get("_campaign_start").save_home_checkpoint(flow, adapter, true)
	check(saved.get("ok", false), "frischer Stand gespeichert: " + str(saved.get("reason", "")))
	var loaded: Dictionary = STORE.load_checkpoint()
	if not loaded.get("ok", false): check(false, "frischer Stand lesbar"); await _free(); return false
	var payload: Dictionary = loaded.payload
	var signature := JSON.stringify({"operation":"campaign_build_bed","payload":{}}, "", true)
	payload.supply.requests["old-bed-1"] = {"signature":signature,"result":{"ok":true,"operation":"campaign_build_bed","request_id":"old-bed-1","bed_count":3,"cost":100}}
	var modified: Dictionary = STORE.save_checkpoint(payload)
	check(modified.get("ok", false), "alter Bettbeleg-Stand akzeptiert: " + str(modified.get("reason", "")))
	await _free()
	return modified.get("ok", false)

func _in_footprint(unit_id: String) -> bool:
	var blocked := {}
	for cell in base.get_ground_ship_blocked_cells().blocked_cells: blocked[cell] = true
	return blocked.has(base.get_terrain_registry().world_to_grid(base.get_actor(unit_id).position))

func _check_old_purchase() -> void:
	check(adapter._supply.get_campaign_housing_count() == 1 and adapter._supply.get_campaign_bed_count() == 4, "alter Beleg wird Alt-Gebaeude ohne neue Abbuchung (1 Gebaeude, 4 Betten)")
	var snapshot: Dictionary = base.get_snapshot()
	check(Array(snapshot.layout.beds).size() == 4 and base.get_recruitment_bed_capacity().beds == 4, "Bettenzahl im Layout und in der Anwerbekapazitaet: 4 (2 + 2 je Alt-Gebaeude)")
	check(Array(snapshot.layout.campaign_housing).size() == 1 and String(snapshot.layout.campaign_housing[0].id) == "campaign_habitat_01", "genau ein Alt-Gebaeude (Einzelkopie) auf Stellplatz 1")
	var ids: Array = Array(snapshot.layout.beds).map(func(bed): return String(bed.id))
	check(ids.has("field_bed_01") and ids.has("field_bed_02"), "Alt-Betten field_bed_01/02 vorhanden (%s)" % str(ids))

## Vor dem Speichern: die Person steht genau dort, wo spaeter die Wand des Alt-Gebaeudes liegt.
func _place_leader_on_future_wall() -> void:
	var terrain: Node = base.get_terrain_registry()
	var infrastructure := {"campaign_housing":1, "campaign_housing_beds":[2], "hex_containers":true}
	var houses: Array = CAPACITY.hex_container_housing(base._source_layout, terrain, infrastructure).houses
	var before_mask := {}
	for cell in base.get_ground_ship_blocked_cells().blocked_cells: before_mask[cell] = true
	base._navigation_graph.set_campaign_housing(houses)
	var after: Array = Array(base.get_ground_ship_blocked_cells().blocked_cells)
	base._navigation_graph.set_campaign_housing([])
	var wall := Vector2i(-99999, -99999)
	for cell: Vector2i in after:
		if not before_mask.has(cell) and terrain.is_walkable(cell): wall = cell; break
	check(wall != Vector2i(-99999, -99999), "Fixture: Wandzelle des kuenftigen Alt-Gebaeudes gefunden (%s)" % str(wall))
	var moved: Dictionary = sim._hex_ground_runtime.relocate_unit("campaign_leader", wall, sim.get_hex_ground_revision())
	check(moved.get("ok", false), "Fixture: Person auf die Wandzelle gesetzt: " + str(moved))
	for i in range(3): sim._physics_process(0.05)
	print("FIXTURE Person auf Wandzelle ", wall, " Actor-Zelle ", terrain.world_to_grid(base.get_actor("campaign_leader").position))

## Stand, wie ihn das ALTE Spiel (vor dem Wohncontainer-Umbau) geschrieben haette: der Schlaefer liegt in `bed_id`
## und steht an der ALTEN Lage des ersten Alt-Bettes (Quellbett 1 + Versatz (0,120)). Der Stand wird real erzeugt
## (Laden, Schlafen, Speichern) und dann nur die Zelle der Person im Hex-Stand auf die alte Lage umgeschrieben.
func _write_old_sleeper_checkpoint(bed_id: String) -> bool:
	if not await _write_legacy_checkpoint(Callable()): return false
	if not await _boot("continue"): return false
	var terrain: Node = base.get_terrain_registry()
	var source_grid: Array = base._source_layout.beds[0].grid
	old_bed_cell = Vector2i(int(source_grid[0]), int(source_grid[1])) + Vector2i(0, 120)
	old_bed_world = terrain.grid_to_world(old_bed_cell)
	check(terrain.is_walkable(old_bed_cell), "Fixture: alte Bettlage %s ist begehbar" % str(old_bed_cell))
	var sleep: Dictionary = base.request_operation("base_sleep", {"unit_id":"campaign_leader", "bed_id":bed_id})
	check(sleep.get("ok", false), "Fixture: Person geht ins Bett %s: %s" % [bed_id, str(sleep)])
	for i in range(6000):
		sim._physics_process(0.05)
		if base._states.campaign_leader.status == "sleeping": break
	check(base._states.campaign_leader.status == "sleeping", "Fixture: Person schlaeft in %s" % bed_id)
	var saved: Dictionary = flow.get("_campaign_start").save_home_checkpoint(flow, adapter, true)
	check(saved.get("ok", false), "Fixture: Schlaefer gespeichert: " + str(saved.get("reason", "")))
	await _free()
	var loaded: Dictionary = STORE.load_checkpoint()
	if not loaded.get("ok", false): check(false, "Fixture: Schlaefer-Stand lesbar"); return false
	var payload: Dictionary = loaded.payload
	var unit: Dictionary = payload.hex_tactical.base_personnel.units.campaign_leader
	check(unit.status == "sleeping" and unit.bed_id == bed_id, "Fixture: im Stand schlaeft die Person in %s" % bed_id)
	var rewritten := false
	for ground_unit: Dictionary in payload.hex_tactical.ground.units:
		if ground_unit.unit_id == "campaign_leader": ground_unit.grid = [old_bed_cell.x, old_bed_cell.y]; rewritten = true
	check(rewritten, "Fixture: Zelle der Person auf die alte Bettlage %s umgeschrieben" % str(old_bed_cell))
	# Das alte Spiel haette auch den Schlafbefehl (Ziel = Bett, angekommen) an der alten Lage gespeichert.
	var intent_rewritten := false
	for intent: Dictionary in payload.hex_tactical.movement.accepted_intents:
		if intent.unit_id != "campaign_leader": continue
		intent.goal_grid = [old_bed_cell.x, old_bed_cell.y]
		var keys: Array = []
		for field: Dictionary in intent.command_intent:
			keys.append(field.key)
			if field.key == "target_position": field.value = [old_bed_world.x, old_bed_world.y]; intent_rewritten = true
		print("FIXTURE Schlafbefehl-Felder: ", keys, " Status ", intent.status)
	check(intent_rewritten, "Fixture: Ziel des Schlafbefehls auf die alte Bettlage umgeschrieben")
	var modified: Dictionary = STORE.save_checkpoint(payload)
	check(modified.get("ok", false), "Fixture: Altstand mit Schlaefer an der alten Bettlage akzeptiert: " + str(modified.get("reason", "")))
	return modified.get("ok", false)

func run() -> void:
	# A: Schlaefer im Alt-Bett field_bed_01 (Beleg alt, Schlaf im neuen Alt-Gebaeude), Speichern und erneut Laden.
	if not await _write_legacy_checkpoint(Callable()): quit(1); return
	if not await _boot("continue"): quit(1); return
	_check_old_purchase()
	var sleep: Dictionary = base.request_operation("base_sleep", {"unit_id":"campaign_leader", "bed_id":"field_bed_01"})
	check(sleep.get("ok", false), "Person geht ins Alt-Bett field_bed_01: " + str(sleep))
	for i in range(6000):
		sim._physics_process(0.05)
		if base._states.campaign_leader.status == "sleeping": break
	check(base._states.campaign_leader.status == "sleeping" and base.get_snapshot().bed_occupants.get("field_bed_01") == "campaign_leader", "Person schlaeft im Alt-Bett field_bed_01")
	var saved: Dictionary = flow.get("_campaign_start").save_home_checkpoint(flow, adapter, true)
	check(saved.get("ok", false), "Speichern mit Schlaefer im Alt-Bett: " + str(saved.get("reason", "")))
	await _free()
	if not await _boot("continue"): quit(1); return
	_check_old_purchase()
	check(base.get_snapshot().bed_occupants.get("field_bed_01") == "campaign_leader" and base._states.campaign_leader.status == "sleeping", "Schlaefer liegt nach dem Laden weiter im Alt-Bett field_bed_01")
	await _free()
	# B: Person steht beim Speichern dort, wo jetzt die Wand des Alt-Gebaeudes steht.
	if not await _write_legacy_checkpoint(_place_leader_on_future_wall): quit(1); return
	if not await _boot("continue"): quit(1); return
	_check_old_purchase()
	var leader_cell: Vector2i = base.get_terrain_registry().world_to_grid(base.get_actor("campaign_leader").position)
	print("NACH LADEN Person: Zelle ", leader_cell, " Status ", base._states.campaign_leader.status, " Hex-Zelle ", sim._hex_ground_runtime.get_unit_grid("campaign_leader"))
	check(not _in_footprint("campaign_leader") and base._states.campaign_leader.status in ["outside", "sleeping"], "Person steht nach dem Laden NICHT im Fussabdruck des Alt-Gebaeudes")
	await _free()
	# C: Altstand mit Schlaefer im Alt-Bett an der ALTEN Lage: der Stand laedt, die Person ist geweckt (W3).
	if not await _write_old_sleeper_checkpoint("field_bed_01"): quit(1); return
	if not await _boot("continue"): quit(1); return
	_check_old_purchase()
	var woken: Dictionary = base._states.campaign_leader
	check(woken.status == "outside" and String(woken.bed_id) == "" and not bool(woken.rest_automatic) and Dictionary(woken.action).is_empty(), "Schlaefer im Alt-Bett ist beim Laden geweckt (outside, Bett frei, keine Automatik-Ruhe): " + str(woken.status))
	check(not base.get_snapshot().bed_occupants.has("field_bed_01"), "Alt-Bett field_bed_01 ist nach dem Wecken frei")
	check(not _in_footprint("campaign_leader"), "Geweckte Person steht nicht in einer Sperrzelle")
	var again: Dictionary = base.request_operation("base_sleep", {"unit_id":"campaign_leader", "bed_id":"field_bed_01"})
	check(again.get("ok", false), "Geweckte Person kann per Schlafbefehl ins Alt-Bett: " + str(again))
	for i in range(6000):
		sim._physics_process(0.05)
		if base._states.campaign_leader.status == "sleeping": break
	check(base._states.campaign_leader.status == "sleeping" and base.get_snapshot().bed_occupants.get("field_bed_01") == "campaign_leader", "Geweckte Person schlaeft danach wieder in field_bed_01")
	await _free()
	# D: Gegenprobe: Schlaefer mit falscher Lage in einem HABITAT-Bett bleibt ein kaputter Stand (abgelehnt).
	if not await _write_old_sleeper_checkpoint("habitat_bed_01"): quit(1); return
	var booted := await _boot("continue", true)
	print("GEGENPROBE Habitat-Bett: geladen=", booted, " Fehler=", last_error)
	check(not booted and last_error.contains("base_checkpoint_bed_pose"), "Schlaefer in Habitat-Bett mit falscher Lage: Stand wird weiter abgelehnt (base_checkpoint_bed_pose)")
	if flow != null: await _free()
	if failed == 0: print("CAMPAIGN_HOUSING_LEGACY_PASS")
	quit(0 if failed == 0 else 1)
