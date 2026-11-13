extends SceneTree
const SHELL=preload("res://scripts/ui/global_escape_menu.gd")
const MENU=preload("res://scripts/ui/main_menu_screen.gd")
const ISOLATION=preload("res://scripts/tests/review2_isolated_user_guard.gd")
var passed:=0
var failed:=0

class QuietShell extends SHELL:
	func _play_ui_sfx(_kind:String,_id:String)->void:pass
	func _ensure_audio_event_bus():return null
class Campaign extends Node:
	var saves:=0
	var allowed:=true
	func is_campaign_start()->bool:return true
	func request_campaign_save()->Dictionary:
		saves+=1
		return {"ok":allowed,"message":"Kampagne gespeichert." if allowed else "Owner wartet auf Missionsruhe."}
class QuietMenu extends MENU:
	var checkpoint_valid:=true
	var start_action:=""
	func _ready()->void:pass
	func _play_ui_sfx(_kind:String,_id:String)->void:pass
	func _load_campaign_checkpoint()->Dictionary:return {"ok":checkpoint_valid}
	func _start_campaign(action:String)->void:start_action=action

func _init()->void:
	if ISOLATION.require_isolated_user_data():call_deferred("_run")
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failed+=1
	print("PASS " if value else "FAIL ",label)
func _control_at(parent:Node,path:String,leaf:Control)->void:
	var parts:=path.split("/")
	var holder:=parent
	for i in range(parts.size()-1):
		var next:=holder.get_node_or_null(NodePath(parts[i]))
		if next==null:
			next=VBoxContainer.new()
			next.name=parts[i]
			holder.add_child(next)
		holder=next
	leaf.name=parts[-1]
	holder.add_child(leaf)
func _run()->void:
	var shell:=QuietShell.new()
	shell.set_test_mode(true)
	shell.set_save_path_for_tests("user://main_hex_ui_slot.cfg")
	shell.set_settings_path_for_tests("user://main_hex_ui_settings.cfg")
	root.add_child(shell)
	var bookmark:=Node.new()
	bookmark.scene_file_path="res://scenes/tests/main_hex_ui_slot.tscn"
	root.add_child(bookmark)
	current_scene=bookmark
	shell.open_menu()
	check(not paused and shell.is_menu_visible(),"escape overlay keeps simulation unpaused")
	check(shell._save_button.text=="Szenenstart merken" and shell._load_button.text=="Gemerkte Szene neu starten" and shell._save_button.tooltip_text.contains("Fortschritt"),"noncampaign buttons disclose scene bookmark semantics")
	var saved:Dictionary=shell.save_current_mission_slot()
	var config:=ConfigFile.new()
	var loaded:int=config.load("user://main_hex_ui_slot.cfg")
	check(saved.get("ok",false) and loaded==OK and config.get_value("mission_shell_slot","save_kind")=="scene_path_v1" and config.get_value("mission_shell_slot","scene_path")==bookmark.scene_file_path,"real bookmark file keeps scene_path_v1 and explicit private path")
	shell._on_save_pressed()
	check(shell._status_label.text.contains("Fortschritt") and shell._status_label.text.contains("nicht"),"bookmark save callback cannot claim gameplay progress")
	check(shell.load_mission_slot(false).get("ok",false) and shell._status_label.text.contains("neu gestartet"),"bookmark load stays restart rather than campaign continue")
	var campaign:=Campaign.new()
	campaign.scene_file_path="res://scenes/tests/main_hex_ui_slot.tscn"
	root.add_child(campaign)
	current_scene=campaign
	shell.open_menu()
	check(shell._save_button.text=="Kampagne speichern" and shell._save_button.tooltip_text.contains("Kampagnenstand") and not shell._save_button.disabled,"campaign save button describes its actual owning saver")
	check(shell._load_button.disabled and shell._load_button.text=="Im Hauptmenü fortsetzen","campaign load retains main-menu continue guidance")
	shell._on_save_pressed()
	check(campaign.saves==1 and shell._status_label.text=="Kampagne gespeichert.","campaign save callback delegates once and preserves owner success message")
	campaign.allowed=false
	shell._on_save_pressed()
	check(campaign.saves==2 and shell._status_label.text=="Owner wartet auf Missionsruhe.","owner save rejection remains visible without bookmark fallback")
	check(shell.load_mission_slot(false).get("reason")=="campaign_continue_from_main_menu" and current_scene==campaign,"campaign load never restarts scene through legacy bookmark")
	var menu:=QuietMenu.new()
	menu.scene_file_path=SHELL.MAIN_MENU_SCENE_PATH
	_control_at(menu,"Background",TextureRect.new())
	for name in ["SingleplayerButton","MultiplayerButton","EditorButton","SettingsButton"]:_control_at(menu,"MenuRail/MenuMargin/MenuVBox/MenuButtons/"+name,Button.new())
	_control_at(menu,"MenuRail/MenuMargin/MenuVBox/StatusLabel",Label.new())
	_control_at(menu,"SettingsPanel/SettingsMargin/SettingsVBox/SettingsBackButton",Button.new())
	_control_at(menu,"SettingsPanel/SettingsMargin/SettingsVBox/MasterVolumeSlider",HSlider.new())
	_control_at(menu,"SettingsPanel/SettingsMargin/SettingsVBox/FullscreenCheckButton",CheckButton.new())
	root.add_child(menu)
	menu._mission_save_button=Button.new()
	menu._mission_load_button=Button.new()
	menu._campaign_continue_button=Button.new()
	menu._campaign_dialog=ConfirmationDialog.new()
	for control in [menu._mission_save_button,menu._mission_load_button,menu._campaign_continue_button,menu._campaign_dialog]:menu.add_child(control)
	current_scene=menu
	shell.open_menu()
	menu._refresh_mission_save_load_buttons()
	check(shell._save_button.disabled and menu._mission_save_button.disabled,"main menu cannot save itself despite an available shell")
	check(menu._mission_save_button.text=="Szenenstart merken" and menu._mission_load_button.text=="Gemerkte Szene neu starten" and menu._mission_load_button.tooltip_text.to_lower().contains("fortschritt"),"main-menu optional shell slot is explicitly a bookmark")
	menu._on_mission_load_pressed()
	check(menu._status_label.text.contains("Gemerkte Szene") and current_scene==menu,"main-menu bookmark callback preserves test-mode scene boundary")
	menu._on_campaign_continue_pressed()
	check(menu.start_action=="continue","actual campaign continue entry delegates to existing campaign start action")
	menu.start_action=""
	menu.checkpoint_valid=false
	menu._on_campaign_continue_pressed()
	check(menu.start_action.is_empty() and menu._campaign_continue_button.disabled,"campaign continue revalidates checkpoint before delegation")
	check(not paused,"save/load/continue UI never pauses simulation")
	current_scene=null
	menu.free()
	campaign.free()
	bookmark.free()
	await process_frame
	shell.free()
	await process_frame
	print("MAIN_HEX_SAVE_UI passed=%d failed=%d"%[passed,failed])
	if failed==0:print("MAIN_HEX_SAVE_UI_PASS")
	quit(0 if failed==0 else 1)
