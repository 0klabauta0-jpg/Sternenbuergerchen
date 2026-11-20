extends SceneTree
## Verifies the setting "Respawns je Person (Kampagne)" (R2): contract, load/save and the main menu row.
## This test WRITES settings files under user://. It runs only with a throwaway profile:
## the isolation guard is asked first; without a verified profile it ends with exit code 2 and writes nothing.
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const CONTRACT = preload("res://scripts/ui/game_settings_contract.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/main_menu.tscn"
const SPIN_NAME := "RespawnLimitSpinBox"
const LABEL_NAME := "RespawnLimitLabel"
const TEST_PATH := "user://sb_r2_respawn_limit_contract.cfg"
const MENU_PATH := "user://sb_r2_respawn_limit_menu.cfg"
const HINT := "So oft kommt eine zurückgelassene Person wieder. Danach ist ihr nächster Tod endgültig. 0 = kein Respawn."
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _run() -> void:
	var verdict: Dictionary = GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_RESPAWN_LIMIT_SETTING refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	_remove(TEST_PATH)
	_remove(MENU_PATH)
	_test_defaults_and_normalizing()
	_test_roundtrip()
	await _test_menu()
	_remove(TEST_PATH)
	_remove(MENU_PATH)
	print("CAMPAIGN_RESPAWN_LIMIT_SETTING passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

func _test_defaults_and_normalizing() -> void:
	check(CONTRACT.KEY_CAMPAIGN_RESPAWN_LIMIT == "campaign_respawn_limit", "key name")
	check(CONTRACT.get_default_settings().get("campaign_respawn_limit") == 3, "default is 3")
	var cases: Array = [[0, 0], [9, 9], [-10, 0], [12, 9], [2.4, 2], [2.6, 3], ["abc", 3], [null, 3], [true, 3], [false, 3], [[1], 3], [{}, 3], [9999999999, 9], [INF, 3], [NAN, 3]]
	for c in cases:
		var raw: Dictionary = {"campaign_respawn_limit": c[0]}
		var n: Variant = CONTRACT.normalize_settings(raw).get("campaign_respawn_limit")
		check(typeof(n) == TYPE_INT and n == c[1], "normalize_settings %s -> %s (got %s)" % [str(c[0]), str(c[1]), str(n)])
		var g: Variant = CONTRACT.get_campaign_respawn_limit(raw)
		check(typeof(g) == TYPE_INT and g == c[1], "get_campaign_respawn_limit %s -> %s (got %s)" % [str(c[0]), str(c[1]), str(g)])
	var missing: Variant = CONTRACT.normalize_settings({"music_volume": 10.0}).get("campaign_respawn_limit")
	check(typeof(missing) == TYPE_INT and missing == 3, "normalize_settings without the key -> 3")
	check(CONTRACT.get_campaign_respawn_limit({}) == 3, "get_campaign_respawn_limit without the key -> 3")
	var snap: Dictionary = CONTRACT.build_snapshot({"campaign_respawn_limit": 5})
	check(snap.get("campaign_respawn_limit") == 5 and Dictionary(snap.get("gameplay", {})).get("campaign_respawn_limit") == 5, "build_snapshot carries 5 (top level and gameplay)")
	check(CONTRACT.build_snapshot({}).get("campaign_respawn_limit") == 3, "build_snapshot default 3")
	check(CONTRACT.build_snapshot({"campaign_respawn_limit": "x"}).get("campaign_respawn_limit") == 3, "build_snapshot bad value -> 3")

func _test_roundtrip() -> void:
	var err: int = CONTRACT.save_settings({"campaign_respawn_limit": 5, "music_volume": 41.0}, TEST_PATH)
	check(err == OK, "save with 5 ok")
	var loaded: Dictionary = CONTRACT.load_settings(TEST_PATH)
	check(loaded.get("campaign_respawn_limit") == 5, "reload gives 5")
	check(is_equal_approx(float(loaded.get("music_volume", 0.0)), 41.0), "music_volume keeps its value next to the new key")
	check(is_equal_approx(float(loaded.get("master_volume", 0.0)), 80.0) and loaded.get("window_mode") == "windowed", "other settings keep their defaults")
	# load_campaign_respawn_limit reads the default path user://sternenbuergerchen_settings.cfg: write it inside the throwaway profile.
	var default_path: String = CONTRACT.CONFIG_PATH
	var had_file: bool = FileAccess.file_exists(default_path)
	check(not had_file, "throwaway profile starts without a settings file")
	if had_file:
		return
	check(CONTRACT.load_campaign_respawn_limit() == 3, "no file -> load_campaign_respawn_limit is 3")
	check(CONTRACT.save_settings({"campaign_respawn_limit": 5}) == OK, "save to the default path (throwaway profile)")
	check(CONTRACT.load_campaign_respawn_limit() == 5, "load_campaign_respawn_limit gives 5")
	# A text instead of a number under the key
	var cfg := ConfigFile.new()
	cfg.load(default_path)
	cfg.set_value("gameplay", "campaign_respawn_limit", "viele")
	check(cfg.save(default_path) == OK, "file edited by hand: text under the key")
	check(CONTRACT.load_campaign_respawn_limit() == 3, "text in the file -> 3, no script error")
	check(CONTRACT.load_settings().get("campaign_respawn_limit") == 3, "load_settings with text -> 3")
	# Old file without the key
	var old := ConfigFile.new()
	old.set_value("audio", "music_volume", 20.0)
	check(old.save(default_path) == OK, "old file without the key written")
	check(CONTRACT.load_campaign_respawn_limit() == 3 and CONTRACT.load_settings().get("campaign_respawn_limit") == 3, "old file without the key -> 3")
	_remove(default_path)

func _test_menu() -> void:
	var packed := ResourceLoader.load(MAIN_MENU_SCENE_PATH) as PackedScene
	check(packed != null, "main menu scene loads")
	if packed == null:
		return
	var menu := packed.instantiate()
	root.add_child(menu)
	await process_frame
	menu.call("set_settings_path_for_tests", MENU_PATH)
	await process_frame
	menu.call("open_settings_panel")
	await process_frame
	var spin := menu.find_child(SPIN_NAME, true, false) as SpinBox
	check(spin != null, "menu has the SpinBox %s" % SPIN_NAME)
	if spin == null:
		menu.queue_free()
		await process_frame
		return
	check(spin.min_value == 0.0 and spin.max_value == 9.0 and spin.step == 1.0, "range 0..9, step 1")
	check(int(spin.value) == 3, "shows the default 3 on open")
	check(spin.tooltip_text == HINT, "tooltip carries the hint text")
	check(spin.custom_minimum_size.x >= 160.0 and spin.custom_minimum_size.y >= 30.0, "click area at least 160 x 30 (got %s)" % str(spin.custom_minimum_size))
	var label := menu.find_child(LABEL_NAME, true, false) as Label
	check(label != null and label.text == "Respawns je Person (Kampagne)", "label text")
	check(spin.get_parent() == label.get_parent() if label != null else false, "label and control share the settings column")
	# Change and apply
	spin.value = 1
	check(menu.call("apply_settings") == OK, "apply ok")
	check(CONTRACT.load_settings(MENU_PATH).get("campaign_respawn_limit") == 1, "apply saves 1")
	# Change and cancel
	menu.call("open_settings_panel")
	await process_frame
	check(int(spin.value) == 1, "reopen shows the saved 1")
	spin.value = 7
	menu.call("cancel_settings_changes")
	await process_frame
	check(CONTRACT.load_settings(MENU_PATH).get("campaign_respawn_limit") == 1, "cancel keeps the saved 1")
	menu.call("open_settings_panel")
	await process_frame
	check(int(spin.value) == 1, "after cancel the control shows 1 again")
	# Reset
	spin.value = 6
	menu.call("reset_settings_defaults")
	check(int(spin.value) == 3, "reset shows 3")
	check(menu.call("apply_settings") == OK and CONTRACT.load_settings(MENU_PATH).get("campaign_respawn_limit") == 3, "reset and apply save 3")
	# The settings snapshot lists the value
	var shot: Dictionary = menu.call("get_settings_ui_snapshot")
	check(Dictionary(Dictionary(shot.get("sections", {})).get("gameplay", {})).has("fog_of_war"), "settings snapshot still builds")
	menu.queue_free()
	await process_frame
