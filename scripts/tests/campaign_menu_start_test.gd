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
func _run() -> void:
	var path := "res://scripts/meta/game_start_contract.gd"
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
	var dialog: ConfirmationDialog = menu.get("_campaign_dialog")
	var continue_button: Button = menu.get("_campaign_continue_button")
	check(dialog.visible and continue_button.disabled, "Missing checkpoint opens dialog with Continue disabled")
	check(menu.routed.is_empty(), "Campaign entry does not launch immediately")
	dialog.hide()
	dialog.confirmed.emit()
	check(contract.consume_start(self) == {"mode": "campaign", "action": "new"}, "New campaign with no file starts directly")
	menu.routed = ""
	menu.existing_invalid = true
	campaign.pressed.emit()
	dialog.confirmed.emit()
	check(menu.get("_campaign_replace_dialog").visible and menu.routed.is_empty(), "Invalid existing checkpoint also requires replacement confirmation")
	menu.get("_campaign_replace_dialog").hide()
	menu.existing_invalid = false
	menu.checkpoint_result = {"ok": true, "payload": {}}
	campaign.pressed.emit()
	check(not continue_button.disabled, "Validated checkpoint enables Continue")
	continue_button.pressed.emit()
	check(menu.routed.ends_with("meta_layer_test.tscn"), "Continue uses existing Flow scene")
	check(contract.consume_start(self) == {"mode": "campaign", "action": "continue"}, "Actual Continue button requests campaign continue")
	menu.routed = ""
	menu.checkpoint_result = {"ok": false, "reason": "corrupt"}
	continue_button.pressed.emit()
	check(menu.routed.is_empty(), "Continue revalidates checkpoint at activation")
	menu.checkpoint_result = {"ok": true, "payload": {}}
	campaign.pressed.emit()
	dialog.confirmed.emit()
	var confirm: ConfirmationDialog = menu.get("_campaign_replace_dialog")
	check(confirm.visible and menu.routed.is_empty(), "New campaign requires explicit replacement confirmation")
	confirm.hide()
	confirm.canceled.emit()
	check(menu.routed.is_empty(), "Cancel replacement leaves session untouched")
	campaign.pressed.emit()
	dialog.confirmed.emit()
	confirm.confirmed.emit()
	check(contract.consume_start(self) == {"mode": "campaign", "action": "new"}, "Confirmed replacement requests new campaign")
	menu.get_node("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton").pressed.emit()
	check(contract.consume_start(self).mode == "skirmish", "Existing Singleplayer button starts Skirmish")
	check(menu.get_node("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton").text == "Skirmish", "Skirmish is visible label")
	contract.request_start(self, "campaign", "continue")
	menu.get_node("MenuRail/MenuMargin/MenuVBox/MenuButtons/MultiplayerButton").pressed.emit()
	check(contract.consume_start(self).mode == "skirmish", "Actual Multiplayer button clears campaign context")
	check(menu.routed.ends_with("multiplayer_lobby.tscn"), "Multiplayer route unchanged")
	var deeplink: Dictionary = menu.get_release_singleplayer_deeplink_snapshot(PackedStringArray(["--release-singleplayer"]))
	check(deeplink.requested and deeplink.would_route_to.ends_with("meta_layer_test.tscn"), "Legacy release deeplink retains existing Flow route")
	check(String(menu.get("_team_editor_toggle_button").text).contains("Skirmish"), "Team editor visibly belongs to Skirmish")
	check(menu.find_child("TeamLibraryHeaderLabel", true, false).text.contains("Skirmish"), "Team library visibly belongs to Skirmish")
	menu.free()
	print("Campaign menu: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
