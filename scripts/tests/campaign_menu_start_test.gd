extends SceneTree

class MenuProbe:
	extends "res://scripts/ui/main_menu_screen.gd"
	var routed: String = ""
	var checkpoint_result: Dictionary = {"ok": false}
	var existing_invalid: bool = false
	func _change_scene(path: String) -> void:
		routed = path
	func _campaign_checkpoint_exists() -> bool:
		return existing_invalid or bool(checkpoint_result.get("ok", false))
	func _load_campaign_checkpoint() -> Dictionary:
		return checkpoint_result

var failures: int = 0
var checks: int = 0
func _init() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: " + message)
func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame
func _run() -> void:
	var path :="res://scripts/meta/game_start_contract.gd"
	check(ResourceLoader.exists(path), "Explicit one-shot game start contract exists")
	if not ResourceLoader.exists(path):
		quit(1)
		return
	var contract = load(path)
	check(contract.consume_start(self) == {"mode": "skirmish", "action": "new"}, "Legacy default is Skirmish")
	check(contract.request_start(self, "campaign", "continue").ok, "Valid campaign continue request accepted")
	check(contract.consume_start(self) == {"mode": "campaign", "action": "continue"}, "Mode and action survive once")
	check(contract.consume_start(self).mode == "skirmish", "Second consume defaults")
	contract.request_start(self, "campaign", "new")
	check(not contract.request_start(self, "invalid", "new").ok, "Invalid request rejected")
	check(contract.consume_start(self).mode == "skirmish", "Invalid request clears stale context")
	root.set_meta(contract.META_KEY, {"mode": "campaign", "action": "teleport"})
	check(contract.consume_start(self).mode == "skirmish", "Malformed metadata safely defaults")
	check(not root.has_meta(contract.META_KEY), "Malformed metadata consumed once")
	check(not contract.request_start(self, "skirmish", "continue").ok, "Skirmish continue rejected")
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	menu.set_script(MenuProbe)
	menu.set("_start_roster_profile_id", "campaign_menu_test")
	menu.set("_start_roster_save_path", "user://profiles/campaign_menu_test/roster_v1.json")
	root.add_child(menu)
	await process_frame
	var campaign = menu.find_child("CampaignButton", true, false)
	check(campaign != null, "Actual menu exposes Campaign button")
	if campaign == null:
		menu.free()
		quit(1)
		return
	campaign.pressed.emit()
	var new_button: Button = menu.get("_campaign_new_button")
	var continue_button: Button = menu.get("_campaign_continue_button")
	check(new_button.is_visible_in_tree() and continue_button.disabled, "Missing checkpoint opens the Campaign section with Continue disabled")
	check(menu.routed.is_empty(), "Campaign entry does not launch immediately")
	new_button.pressed.emit()
	check(contract.consume_start(self) == {"mode": "campaign", "action": "new"}, "New campaign with no file starts directly")
	check(menu.get("_launching") and menu.get_node("LoadingCurtain").visible and String(menu.get_node("LoadingCurtain/LoadingCenter/LoadingLabel").text).contains("wird geladen"), "Start covers the menu with the loading curtain")
	check(menu.get("_campaign_new_button").disabled, "All menu buttons are locked while loading")
	check(menu.routed.is_empty(), "Scene changes only after two frames")
	await _frames(3)
	check(menu.routed.ends_with("meta_layer_test.tscn"), "New campaign routes to the Flow scene after the curtain")
	check(menu.get_main_menu_snapshot().pending_tip_context == "kampagne", "Campaign start passes the campaign tip context")
	menu.call("_cancel_launch")
	check(not menu.get("_campaign_new_button").disabled and not menu.get_node("LoadingCurtain").visible, "A failed start frees the buttons and removes the curtain")
	menu.routed = ""
	menu.existing_invalid = true
	new_button.pressed.emit()
	check(menu.get("_campaign_replace_dialog").visible and menu.routed.is_empty(), "Invalid existing checkpoint also requires replacement confirmation")
	menu.get("_campaign_replace_dialog").hide()
	menu.existing_invalid = false
	menu.checkpoint_result = {"ok": true, "payload": {}}
	campaign.pressed.emit()
	check(not continue_button.disabled and continue_button.visible, "Validated checkpoint enables Continue")
	check(String(menu.get_main_menu_snapshot().continue_info).contains("Credits"), "Continue shows place, time and credits")
	continue_button.pressed.emit()
	await _frames(3)
	check(menu.routed.ends_with("meta_layer_test.tscn"), "Continue uses existing Flow scene with one click")
	check(contract.consume_start(self) == {"mode": "campaign", "action": "continue"}, "Actual Continue button requests campaign continue")
	menu.call("_cancel_launch")
	menu.routed = ""
	menu.checkpoint_result = {"ok": false, "reason": "corrupt"}
	continue_button.pressed.emit()
	await _frames(3)
	check(menu.routed.is_empty(), "Continue revalidates checkpoint at activation")
	menu.checkpoint_result = {"ok": true, "payload": {}}
	new_button.pressed.emit()
	var confirm: ConfirmationDialog = menu.get("_campaign_replace_dialog")
	check(confirm.visible and menu.routed.is_empty(), "New campaign requires explicit replacement confirmation")
	confirm.hide()
	confirm.canceled.emit()
	await _frames(3)
	check(menu.routed.is_empty(), "Cancel replacement leaves session untouched")
	new_button.pressed.emit()
	confirm.confirmed.emit()
	check(contract.consume_start(self) == {"mode": "campaign", "action": "new"}, "Confirmed replacement requests new campaign")
	await _frames(3)
	menu.call("_cancel_launch")
	menu.routed = ""
	var gefecht_button: Button = menu.get_node("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton")
	check(gefecht_button.text == "Gefecht", "Gefecht is the visible label of the single-battle entry")
	gefecht_button.pressed.emit()
	check(menu.get_main_menu_snapshot().open_section == "gefecht" and menu.find_child("SkirmishOwnTeam", true, false).is_visible_in_tree(), "Gefecht unfolds its entries in place")
	menu.find_child("SkirmishOwnTeam", true, false).pressed.emit()
	check(contract.consume_start(self).mode == "skirmish", "Gefecht own-team start requests Skirmish")
	check(menu.get_main_menu_snapshot().pending_tip_context == "gefecht", "Gefecht start passes the gefecht tip context")
	await _frames(3)
	menu.call("_cancel_launch")
	menu.routed = ""
	var free_button: Button = menu.get_node("MenuRail/MenuMargin/MenuVBox/MenuButtons/FreePlayButton")
	free_button.pressed.emit()
	var cpu_button: Button = menu.find_child("FreePlayVsComputerButton", true, false)
	check(cpu_button.disabled and cpu_button.tooltip_text == "Kommt noch: Computergegner im freien Spiel", "Free play vs computer is shown but locked with a tooltip")
	menu.find_child("FreePlaySoloButton", true, false).pressed.emit()
	check(contract.consume_start(self).mode == "skirmish" and menu.get_main_menu_snapshot().pending_tip_context == "frei", "Free play alone starts the open world without campaign guidance")
	await _frames(3)
	menu.call("_cancel_launch")
	menu.routed = ""
	contract.request_start(self, "campaign", "continue")
	menu.get_node("MenuRail/MenuMargin/MenuVBox/MenuButtons/FreePlaySubMenu/MultiplayerButton").pressed.emit()
	check(contract.consume_start(self).mode == "skirmish", "Actual Multiplayer button clears campaign context")
	await _frames(3)
	check(menu.routed.ends_with("multiplayer_lobby.tscn"), "Multiplayer route unchanged")
	menu.call("_cancel_launch")
	var save_button: Button = menu.find_child("SaveButton", true, false)
	check(save_button.disabled and save_button.tooltip_text == "Speichern geht im Spiel über Esc", "Saving is locked in the main menu with a tooltip")
	var quit_dialog: ConfirmationDialog = menu.get("_quit_dialog")
	menu.find_child("QuitButton", true, false).pressed.emit()
	check(quit_dialog.visible and quit_dialog.ok_button_text == "Beenden" and quit_dialog.cancel_button_text == "Weiterspielen", "Quit asks first with Beenden / Weiterspielen")
	quit_dialog.hide()
	check(menu.find_child("MissionSaveButton", true, false) == null and menu.find_child("MissionLoadButton", true, false) == null, "Scene bookmark buttons are gone from the main menu")
	var deeplink: Dictionary = menu.get_release_singleplayer_deeplink_snapshot(PackedStringArray(["--release-singleplayer"]))
	check(deeplink.requested and deeplink.would_route_to.ends_with("meta_layer_test.tscn"), "Legacy release deeplink retains existing Flow route")
	check(String(menu.get("_team_editor_toggle_button").text).contains("Skirmish"), "Team editor visibly belongs to Skirmish")
	check(menu.find_child("TeamLibraryHeaderLabel", true, false).text.contains("Skirmish"), "Team library visibly belongs to Skirmish")
	menu.free()
	print("Campaign menu: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
