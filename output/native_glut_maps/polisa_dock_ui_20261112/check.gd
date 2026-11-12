extends SceneTree
const SCREEN = preload("res://scripts/ui/star_map_screen.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
var checks := 0
var failures := 0
var commands: Array = []
var area := {}
var runtime := {"space_travel":{"phase":"orbit","craft_id":"own","orbit_id":"polisa_orbit","routes":{}},"crafts":[{"craft_id":"own","display_name":"Own"}]}
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label)
func snapshot() -> Dictionary: return runtime.duplicate(true)
func projection(_id: String) -> Dictionary: return area.duplicate(true)
func command(operation: String,payload: Dictionary) -> Dictionary:
	commands.append({"operation":operation,"payload":payload.duplicate(true)})
	return {"ok":false,"message":"Actual owner decides"}
func _init() -> void: call_deferred("run")
func run() -> void:
	var screen = SCREEN.new(); root.add_child(screen)
	screen.configure(Callable(self,"snapshot"),Callable(self,"command"),Callable(self,"projection"))
	screen.set_process(false)
	area = {"ok":true,"space_area_id":"orbit_approach:glut_2","dock_targets":[{"target_id":"polisa_station_dock","revision":"polisa_glut2_dock_v1"}],"actors":[{"craft_id":"own","flight":{"craft_id":"own","coordinate_frame":"local","space_area_id":"orbit_approach:glut_2","motion_mode":"tactical","position_plane":Vector2(256,150),"heading_rad":0.0}}]}
	var button: Button = screen.find_child("BeginStationDock",true,false)
	check(button != null,"actual Screen builds dock button")
	if button == null: screen.free(); finish(); return
	screen._refresh_orbit_projection()
	check(not button.visible and commands.is_empty(),"no automatic craft selection or dock command")
	screen._on_fleet_craft_selected(0); commands.clear()
	screen._show_orbit_view()
	check(button.is_visible_in_tree() and not button.disabled,"explicit selected local Root actor enables button in orbit view")
	var area_before := area.duplicate(true); var runtime_before := runtime.duplicate(true)
	button.pressed.emit()
	var sent: Dictionary = commands.back() if not commands.is_empty() else {}
	var payload: Dictionary = sent.get("payload",{})
	check(commands.size()==1 and sent.get("operation")=="space_begin_station_dock" and payload.size()==5 and payload.get("craft_id")=="own" and payload.get("location_id")=="polisa" and payload.get("target_id")=="polisa_station_dock" and payload.get("layout_revision")=="polisa_glut2_dock_v1" and not String(payload.get("request_id","")).is_empty() and screen._error.text=="Actual owner decides" and area==area_before and runtime==runtime_before,"button uses actual command handler with exact fields; no gameplay mutation")
	var first_id := String(payload.get("request_id","")); button.pressed.emit()
	check(commands.size()==2 and commands.back().payload.request_id != first_id,"distinct explicit requests use distinct IDs")
	commands.clear(); area.dock_targets[0].revision="unknown"
	button.pressed.emit()
	check(commands.is_empty() and not button.visible and button.disabled,"click rechecks fresh DTO before sending stale revision")
	area=area_before.duplicate(true); screen._refresh_orbit_projection(); screen._show_system_view()
	button.pressed.emit()
	check(not button.visible and button.disabled and commands.is_empty(),"system view cannot request dock")
	screen._show_orbit_view(); area.actors.clear(); screen._refresh_orbit_projection()
	button.pressed.emit()
	check(not screen._orbit_visible and not button.visible and button.disabled and commands.is_empty(),"removed actor closes local view and disables stale request")
	area=area_before.duplicate(true); screen._show_orbit_view(); screen.hide(); button.pressed.emit()
	check(button.disabled and commands.is_empty(),"hidden Screen cannot request dock")
	screen.show(); screen.configure(Callable(self,"snapshot"),Callable(self,"command"))
	screen._refresh_orbit_projection(); button.pressed.emit()
	check(button.disabled and not button.visible and commands.is_empty(),"missing Area provider fails closed")
	screen.free(); finish()
func finish() -> void:
	print("POLISA_DOCK_UI_RESULT checks=%d failures=%d native_approved=false"%[checks,failures])
	quit(1 if failures else 0)
