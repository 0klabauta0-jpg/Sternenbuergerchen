extends SceneTree
var passed := 0
var failed := 0
var calls: Array = []
var snapshot := {"mode":"campaign","onboarding":{"stage_index":1},
	"campaign":{"locations":{},"jobs":{},"selected_location_id":"","selected_job_id":""},
	"space_travel":{"phase":"approach","craft_id":"craft","orbit_id":"planet_orbit","progress":0.8,"position":[0.5,0.5]},
	"map_preparation":{"status":"loading_data","progress":0.0,"ready":false,"cancel_available":true,"expected_chunks":2161,"prepared_chunks":0}}
func _init() -> void: call_deferred("run")
func provide() -> Dictionary: return snapshot.duplicate(true)
func command(operation: String, payload: Dictionary = {}) -> Dictionary:
	calls.append({"operation":operation,"payload":payload.duplicate(true)})
	return {"ok":true}
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ",label)
func run() -> void:
	var view = load("res://scripts/ui/star_map_screen.gd").new()
	root.add_child(view)
	view.configure(provide,command)
	view.set_process(false)
	var abort: Button = view.find_child("AbortQuantum",true,false)
	var progress: ProgressBar = view.find_child("QuantumProgress",true,false)
	var initial_children: int = view.get_child_count()
	check(String(view.get_ui_snapshot().status).contains("Ortskarte wird geladen"),"Data loading is shown from the owner snapshot")
	check(abort.visible and abort.text == "Anflug abbrechen","Approach has its own explicit cancellation action")
	abort.pressed.emit()
	check(not calls.is_empty() and calls.back() == {"operation":"space_cancel_approach","payload":{"craft_id":"craft"}},"Approach cancel sends the real owner command for the craft")
	check(snapshot.space_travel.phase == "approach" and not snapshot.map_preparation.ready,"A UI command does not manufacture readiness or phase completion")
	snapshot.map_preparation.merge({"status":"preparing_resources","progress":0.37,"prepared_chunks":800},true)
	var untouched := snapshot.duplicate(true)
	view.refresh()
	check(String(view.get_ui_snapshot().status).contains("37 %"),"Preparation label uses actual owner progress")
	check(progress.visible and is_equal_approx(progress.value,37.0),"Same owner progress drives the progress bar")
	check(not String(view.get_ui_snapshot().status).contains("2161") and not String(view.get_ui_snapshot().status).contains("Chunk"),"Normal UI omits implementation counters")
	check(snapshot == untouched,"Refresh never mutates the source snapshot")
	check(view.get_child_count() == initial_children,"Progress refresh retains the existing control tree")
	snapshot.map_preparation.cancel_available = false
	view.refresh()
	var before := calls.size()
	abort.pressed.emit()
	check(not abort.visible and calls.size() == before,"Unavailable approach cancel stays hidden and sends no command")
	snapshot.map_preparation.merge({"status":"ready","progress":1.0,"ready":true},true)
	view.refresh()
	check(snapshot.space_travel.phase == "approach" and is_equal_approx(progress.value,100.0),"Ready is projected while phase remains owner controlled")
	snapshot.space_travel.phase = "orbit"
	snapshot.map_preparation.merge({"status":"failed","ready":false,"error":"Ortskarte konnte nicht vorbereitet werden."},true)
	view.refresh()
	check(String(view.get_ui_snapshot().error).contains("konnte nicht"),"Preparation failure survives the actual return-to-orbit refresh")
	snapshot.map_preparation = {"status":"cancelled","cancel_available":false}
	view.refresh()
	check(String(view.get_ui_snapshot().status).contains("Anflug abgebrochen"),"Cancellation status comes from the returned owner snapshot")
	snapshot.space_travel.phase = "quantum"
	snapshot.space_travel.progress = 0.42
	snapshot.map_preparation = {"status":"failed","error":"Alter Ladefehler"}
	view.refresh()
	check(String(view.get_ui_snapshot().status).contains("Quantum") and is_equal_approx(progress.value,42.0),"Old load result does not obscure a new quantum phase")
	check(abort.visible and abort.text == "Sprung abbrechen","Quantum retains its existing abort action")
	abort.pressed.emit()
	check(calls.back().operation == "space_abort_quantum","Quantum cancellation command remains unchanged")
	view.free()
	print("STAR_MAP_TERRAIN_PREPARATION_UI ",passed," passed, ",failed," failed")
	quit(0 if failed == 0 else 1)
