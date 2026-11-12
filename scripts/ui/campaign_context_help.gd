extends Control
## Contextual help is presentation only. Targets and catalog own their meaning.
const SERVICE = preload("res://scripts/ui/contextual_help_service.gd")
const POPUP = preload("res://scripts/ui/contextual_help_popup.gd")
const SETTINGS = preload("res://scripts/ui/game_settings_contract.gd")
var _service = SERVICE.new()
var _popup: Control
var _hover: Timer
var _detail: Timer
var _target: Control
var _help_id := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_service.load_catalog()
	_service.set_help_mode(String(SETTINGS.load_settings().get("contextual_help_mode", "compact")))
	_popup = POPUP.new()
	_popup.z_index = 100
	add_child(_popup)
	_hover = Timer.new()
	_hover.one_shot = true
	_hover.wait_time = SERVICE.DEFAULT_COMPACT_DELAY_SECONDS
	_hover.timeout.connect(_show_compact)
	add_child(_hover)
	_detail = Timer.new()
	_detail.one_shot = true
	_detail.wait_time = SERVICE.DEFAULT_DETAIL_DELAY_SECONDS
	_detail.timeout.connect(_show_detail)
	add_child(_detail)

func category_help_id(category: String) -> String:
	return {"infantry":"polisa.weapons", "armor":"polisa.armor", "commodities":"polisa.cargo", "ships":"polisa.ship", "ship_equipment":"polisa.ship"}.get(category, "")

func bind_target(target: Control, id: String) -> void:
	if target == null or id.is_empty(): return
	_service.register_control(target, id)
	target.mouse_entered.connect(_enter.bind(target, id))
	target.mouse_exited.connect(_leave.bind(target))
	target.focus_entered.connect(_enter.bind(target, id))
	target.focus_exited.connect(_leave.bind(target))
	target.tree_exiting.connect(_leave.bind(target))

func _enter(target: Control, id: String) -> void:
	_target = target
	_help_id = id
	_hover.start()
	_detail.stop()
	if _service.get_help_mode() == "expanded": _detail.start(SERVICE.DEFAULT_COMPACT_DELAY_SECONDS + SERVICE.DEFAULT_DETAIL_DELAY_SECONDS)

func _leave(target: Control) -> void:
	if target != _target: return
	_target = null
	_hover.stop()
	_detail.stop()
	_popup.hide_help()

func _show_compact() -> void:
	_show(false)

func _show_detail() -> void:
	_show(true)

func _show(detail: bool) -> void:
	if not is_instance_valid(_target) or not _target.is_visible_in_tree(): return
	var elapsed: float = SERVICE.DEFAULT_DETAIL_DELAY_SECONDS if detail else SERVICE.DEFAULT_COMPACT_DELAY_SECONDS
	var payload: Dictionary = _service.request_help(_help_id, elapsed)
	if payload.get("level") == "none": return
	_popup.show_help(payload, _target.get_global_rect(), get_viewport_rect().size, detail)
