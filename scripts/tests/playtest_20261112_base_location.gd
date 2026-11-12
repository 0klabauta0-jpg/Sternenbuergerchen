extends "res://scripts/tests/reference_polish_r3_20261106_homebase_verifier.gd"
class BaseOwner extends SnapshotOwner:
 var _character_sheet_open := false
func _run() -> void:
 var owner := BaseOwner.new(); owner.snapshot = _snapshot(_craft())
 owner.snapshot.mode = "base"
 owner.snapshot["singleplayer"] = {"space_travel":{"bodies":{"moon":{"name":"Mare Nostrum C · Heimatbasis"}}}}
 root.add_child(owner)
 var presenter: Control = PRESENTER.new(); owner.add_child(presenter); presenter.configure(owner)
 presenter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 await process_frame; presenter.call("refresh"); await process_frame
 var label: Label = presenter.find_child("HomebaseLocation",true,false)
 var ok: bool = label != null and label.visible and label.text.contains("Mare Nostrum C")
 if not ok: printerr("FAIL: Heimatstandort fehlt")
 owner.free(); print("PLAYTEST_BASE_LOCATION checks=1 failed=%d" % (0 if ok else 1)); quit(0 if ok else 1)
