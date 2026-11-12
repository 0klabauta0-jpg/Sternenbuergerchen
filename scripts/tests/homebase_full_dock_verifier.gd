extends SceneTree
const BADGES = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
var failed := 0
func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value: failed += 1
func _init() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1024,768)
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	for i in range(6): await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	screen.call("request_operation", "navigate", {"mode":"base"})
	for i in range(12): await process_frame
	var base: Node = screen.get("_operations_presenter").get("_base")
	var panel: Control = base.get("_person_panel")
	var area := panel.get_global_rect(); var viewport := root.get_visible_rect()
	check(absf(area.position.x - viewport.position.x) < 2 and absf(area.end.x - viewport.end.x) < 2, "command band spans viewport width")
	check(absf(area.end.y - viewport.end.y) < 2, "command band ends at lower viewport edge")
	var rest: Control = base.get("_person_buttons").auto_rest
	check(viewport.encloses(rest.get_global_rect()), "automatic rest remains inside viewport")
	var id: String = base.get("_selected_person_id")
	var profile: Variant = Dictionary(screen.get("_profiles_by_id")).get(id)
	var expected: Array = BADGES.get_badges_for_profile(profile)
	var container: HBoxContainer = base.get("_person_badges")
	var visible_count := 0
	for badge: Dictionary in expected:
		var path: String = String(badge.get("path", ""))
		if not path.is_empty() and ResourceLoader.exists(path): visible_count += 1
	check(container.get_child_count()==visible_count and visible_count>0, "displayed rank badges derive from selected actual profile")
	# Keep the synthetic card fixture stable while Godot lays out its scroll bar.
	# The normal periodic owner refresh would otherwise replace it with the real roster.
	base.set_process(false)
	var units: Array = base._personnel_runtime().get_snapshot().units.duplicate(true)
	for n in range(20): units.append({"unit_id":"fixture_%d" % n,"name":"Person %d" % n})
	base.call("_refresh_person_cards",units)
	for i in range(12): await process_frame
	var scroll: ScrollContainer = base.get("_other_people_scroll")
	var bar: HScrollBar = scroll.get_h_scroll_bar()
	print("SCROLL_DIAG size=",scroll.size," max=",bar.max_value," page=",bar.page," cards=",base.get("_other_people").get_child_count()," visible=",scroll.is_visible_in_tree())
	check(bar.max_value > bar.page, "many people produce horizontal scroll")
	bar.value = bar.max_value - bar.page
	check(scroll.scroll_horizontal > 0, "horizontal scrolling is actionable")
	flow.queue_free(); await process_frame
	if failed==0: print("HOMEBASE_FULL_DOCK_PASS")
	quit(0 if failed==0 else 1)
