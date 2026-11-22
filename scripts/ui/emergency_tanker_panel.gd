extends VBoxContainer
## Nottankdienst bedienen und anzeigen (T3 des Tanker-Auftrags, 22.11.2026).
##
## Reine Anzeige und Befehlsweg: die Auskunft kommt fertig vom Adapter (get_emergency_tanker_view), jeder Befehl geht ueber den
## vorhandenen Befehlsweg (request_operation: emergency_tanker_order / emergency_tanker_cancel). Hier wird nichts gerechnet:
## Menge, Preis, Wartezeit, Restzeit und Erstattung stehen in der Auskunft; die Oberflaeche setzt sie nur in Saetze.
## Die Wahrheit liegt im Dienst, nicht hier: ein neuer Host zeigt sofort denselben Zustand mit derselben Restzeit.
##
## Der Knopf "Tanker rufen" ist nur sichtbar, wenn die Auskunft ein Treibstoffproblem oder einen offenen Auftrag meldet.
## Ein Klick klappt das Angebot an Ort und Stelle auf (kein neues Fenster); erst "Verbindlich bestellen" bucht.

const SERVICE = preload("res://scripts/core/emergency_tanker_service.gd")
const CREDIT_TEXT = preload("res://scripts/core/credit_text.gd")
const HELP_ID := "campaign.emergency_tanker"
const POLL_SECONDS := 0.2

var _view_provider: Callable
var _command: Callable
var _font_size := 13
var _since_poll := 0.0
var _view: Dictionary = {}
var _offer_open := false
var _request_id := ""
var _call_button: Button
var _reason_label: Label
var _offer_box: VBoxContainer
var _offer_label: Label
var _confirm_button: Button
var _dismiss_button: Button
var _state_label: Label
var _cancel_row: HBoxContainer
var _cancel_button: Button
var _cancel_note: Label
var _result_label: Label
var _feedback_label: Label

## view_provider: Callable ohne Argument, liefert die Auskunft (Dictionary). command: Callable(operation, payload) -> Dictionary.
func configure(view_provider: Callable, command: Callable, font_size: int = 13) -> void:
	_view_provider = view_provider
	_command = command
	_font_size = font_size
	if _call_button == null: _build()
	poll()

func _build() -> void:
	name = "EmergencyTankerPanel"
	add_theme_constant_override("separation", 4)
	visible = false
	_call_button = _button("TankerCall", "Tanker rufen", _on_call_pressed)
	_call_button.tooltip_text = "Notlösung: Ein Tanker bringt Treibstoff zum Schiff. Teurer als normales Tanken; wo getankt werden kann, ist Tanken günstiger."
	add_child(_call_button)
	_reason_label = _label("TankerReason", Color("ffb1a5"))
	add_child(_reason_label)
	_offer_box = VBoxContainer.new()
	_offer_box.name = "TankerOffer"
	_offer_box.add_theme_constant_override("separation", 3)
	add_child(_offer_box)
	_offer_label = _label("TankerOfferText", Color("f2ca86"))
	_offer_box.add_child(_offer_label)
	var offer_buttons := HBoxContainer.new()
	offer_buttons.name = "TankerOfferButtons"
	_offer_box.add_child(offer_buttons)
	_confirm_button = _button("TankerOrderConfirm", "Verbindlich bestellen", _on_confirm_pressed)
	offer_buttons.add_child(_confirm_button)
	_dismiss_button = _button("TankerOfferDismiss", "Abbrechen", _on_dismiss_pressed)
	offer_buttons.add_child(_dismiss_button)
	_state_label = _label("TankerState", Color("b4dae8"))
	add_child(_state_label)
	_cancel_row = HBoxContainer.new()
	_cancel_row.name = "TankerCancelRow"
	add_child(_cancel_row)
	_cancel_button = _button("TankerCancelOrder", "Stornieren", _on_cancel_pressed)
	_cancel_row.add_child(_cancel_button)
	_cancel_note = _label("TankerCancelNote", Color("b5c9d3"))
	_cancel_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cancel_row.add_child(_cancel_note)
	_result_label = _label("TankerResult", Color("9be3a8"))
	add_child(_result_label)
	_feedback_label = _label("TankerFeedback", Color("ffb1a5"))
	add_child(_feedback_label)
	_offer_box.hide()
	_cancel_row.hide()
	_bind_help()

func _bind_help() -> void:
	var help: Control = load("res://scripts/ui/campaign_context_help.gd").new()
	help.name = "TankerHelp"
	add_child(help)
	help.call("bind_target", _call_button, HELP_ID)

func _label(node_name: String, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", _font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.hide()
	return label

func _button(node_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.add_theme_font_size_override("font_size", _font_size)
	button.pressed.connect(action)
	return button

func _process(delta: float) -> void:
	if _call_button == null or not _view_provider.is_valid(): return
	_since_poll += delta
	if _since_poll < POLL_SECONDS: return
	_since_poll = 0.0
	var host: Node = get_parent()
	if host is CanvasItem and (host as CanvasItem).is_visible_in_tree(): poll()

## Liest die Auskunft und setzt die Anzeige. Wird vom Host und vom eigenen Takt gerufen.
func poll() -> void:
	if _call_button == null: return
	var raw: Variant = _view_provider.call() if _view_provider.is_valid() else {}
	apply_view(Dictionary(raw) if raw is Dictionary else {})

func apply_view(view: Dictionary) -> void:
	_view = view
	var order: Dictionary = Dictionary(view.get("order", {}))
	var finished: Dictionary = Dictionary(view.get("finished", {}))
	var offer: Dictionary = Dictionary(view.get("offer", {}))
	var show_panel: bool = bool(view.get("visible", false))
	visible = show_panel
	if not show_panel:
		_offer_open = false
		_request_id = ""
		_feedback_label.text = ""
		return
	var has_order: bool = not order.is_empty()
	if has_order: _offer_open = false
	if not bool(offer.get("ok", false)): _offer_open = false
	var callable_now: bool = not has_order and bool(view.get("fuel_problem", false)) and not offer.is_empty()
	_call_button.visible = callable_now
	_call_button.disabled = not bool(offer.get("ok", false))
	_set_text(_reason_label, _blocked_text(offer) if callable_now and not bool(offer.get("ok", false)) else "")
	_offer_box.visible = _offer_open and not has_order
	if _offer_box.visible: _set_text(_offer_label, _offer_text(offer, view))
	_set_text(_state_label, _state_text(order) if has_order else "")
	_cancel_row.visible = has_order and bool(order.get("can_cancel", false))
	if _cancel_row.visible: _set_text(_cancel_note, _cancel_text(order))
	_set_text(_result_label, _result_text(finished) if not has_order and not finished.is_empty() else "")
	_feedback_label.visible = not _feedback_label.text.is_empty()

func _set_text(label: Label, text: String) -> void:
	if label.text != text: label.text = text
	label.visible = not text.is_empty()

# --- Saetze (nur Formatierung der Zahlen aus der Auskunft) ------------------------------------------------------------

func _blocked_text(offer: Dictionary) -> String:
	if offer.is_empty(): return ""
	var text: String = String(offer.get("message", ""))
	if String(offer.get("reason", "")) == "insufficient_credits":
		text += " Guthaben: %d Cr." % int(offer.get("credits", 0))
	return text

func _number(value: Variant) -> String:
	return String.num(float(value), 2).trim_suffix("0").trim_suffix("0").trim_suffix(".")

func _offer_text(offer: Dictionary, view: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append("Lieferung: %d Einheiten" % int(offer.get("quantity", 0)))
	lines.append("Preis: Anfahrt %d Cr + %d × %s Cr = %d Cr" % [int(offer.get("callout_fee", 0)), int(offer.get("quantity", 0)), _number(offer.get("unit_price", 0)), int(offer.get("price", 0))])
	if bool(offer.get("on_credit", false)):
		lines.append(CREDIT_TEXT.credit_offer_line(int(offer.get("credits_after", 0)), float(offer.get("interest_rate", 0.0)), float(offer.get("interest_period_seconds", 0.0))))
	lines.append("Wartezeit: etwa %d s bis zur Ankunft, dann %d s Betankung" % [int(ceil(float(offer.get("wait_seconds", 0.0)))), int(ceil(float(offer.get("refuel_seconds", 0.0))))])
	lines.append(_reach_text(offer))
	if bool(view.get("free_home_landing", false)):
		lines.append("Die Heimlandung kostet keinen Treibstoff.")
	return "\n".join(lines)

const LEG_NAMES: Dictionary = {"launch": "Abheben", "jump": "Sprung", "approach": "Anflug", "landing": "Heimlandung", "surface_exit": "Ortsabflug"}

## Wie weit die Menge reicht: Treibstoff danach und welche naechsten Etappen dann bezahlt sind (Zahlen aus der Auskunft).
func _reach_text(offer: Dictionary) -> String:
	var parts: PackedStringArray = []
	for leg: Dictionary in Array(offer.get("reach", [])):
		var leg_name: String = String(LEG_NAMES.get(String(leg.get("leg", "")), String(leg.get("leg", ""))))
		parts.append("%s (%s)" % [leg_name, "kostenlos" if float(leg.get("cost", 0.0)) <= 0.0 else _number(leg.get("cost", 0)) + (" ✓" if bool(leg.get("reachable", false)) else " ✕")])
	var text: String = "Danach: Treibstoff %d von %d" % [int(floor(float(offer.get("fuel_after", 0.0)))), int(offer.get("capacity", 0))]
	return text + (". Nächste Etappen: " + ", ".join(parts)) if not parts.is_empty() else text

func _clock(seconds: float) -> String:
	var total: int = int(ceil(maxf(seconds, 0.0)))
	return "%d:%02d" % [total / 60, total % 60]

func _state_text(order: Dictionary) -> String:
	var label: String = String(order.get("state_label", ""))
	match String(order.get("state", "")):
		"en_route": return "%s - noch %s" % [label, _clock(float(order.get("eta_seconds", 0.0)))]
		"refuelling": return "%s - noch %d s" % [label, int(ceil(float(order.get("remaining", 0.0))))]
	return label

func _cancel_text(order: Dictionary) -> String:
	var refund: int = int(order.get("refund_if_cancelled", 0))
	if String(order.get("state", "")) == "requested": return "gibt alles zurück (%d Cr)" % refund
	return "gibt den Mengenpreis zurück (%d Cr), die Anfahrt (%d Cr) ist verloren" % [refund, int(order.get("callout_fee", 0))]

func _result_text(finished: Dictionary) -> String:
	var refund: int = int(finished.get("refund", 0))
	match String(finished.get("state", "")):
		"completed":
			var text: String = "Betankt: %d Einheiten" % int(finished.get("delivered", 0))
			if refund > 0: text += "\n%d Credits erstattet" % refund
			return text
		"cancelled": return "Tankerruf storniert - %d Credits erstattet" % refund
		"expired":
			var why: String = String(finished.get("reason", ""))
			var text: String = "Tankerruf verfallen - %d Credits erstattet" % refund
			if SERVICE.REASON_TEXTS.has(why): text += "\n" + SERVICE.message_for(why)
			elif not why.is_empty(): text += "\nDie Lieferung war nicht buchbar."
			return text
	return ""

# --- Knoepfe ---------------------------------------------------------------------------------------------------------

func _on_call_pressed() -> void:
	if _call_button.disabled: return
	_offer_open = true
	# Jeder Ruf bekommt eine neue Anfrage-ID (K-T2-4); ein Doppelklick auf "Verbindlich bestellen" sendet dieselbe.
	_request_id = "ui-tanker:%d:%d" % [get_instance_id(), Time.get_ticks_usec()]
	_feedback_label.text = ""
	poll()

func _on_dismiss_pressed() -> void:
	_offer_open = false
	_request_id = ""
	poll()

func _on_confirm_pressed() -> void:
	if _request_id.is_empty() or not _command.is_valid(): return
	var craft_id: String = String(_view.get("craft_id", ""))
	var result: Variant = _command.call("emergency_tanker_order", {"craft_id": craft_id, "request_id": _request_id})
	if result is Dictionary and not bool(result.get("ok", false)):
		_feedback_label.text = String(result.get("message", "Tankerruf abgelehnt."))
		_offer_open = false
	else:
		_feedback_label.text = ""
	poll()

func _on_cancel_pressed() -> void:
	if not _command.is_valid(): return
	var result: Variant = _command.call("emergency_tanker_cancel", {"craft_id": String(_view.get("craft_id", ""))})
	_feedback_label.text = String(result.get("message", "Stornieren nicht möglich.")) if result is Dictionary and not bool(result.get("ok", false)) else ""
	poll()

func get_ui_snapshot() -> Dictionary:
	# Nur was der Spieler sieht: ist das ganze Feld versteckt, ist nichts davon sichtbar.
	var on: bool = visible and _call_button != null
	return {"visible": visible, "call_visible": on and _call_button.visible, "call_disabled": on and _call_button.disabled,
		"reason": _reason_label.text if on and _reason_label.visible else "", "offer_visible": on and _offer_box.visible,
		"offer": _offer_label.text if on and _offer_box.visible else "", "state": _state_label.text if on and _state_label.visible else "",
		"cancel_visible": on and _cancel_row.visible, "cancel_note": _cancel_note.text if on and _cancel_note.visible else "",
		"result": _result_label.text if on and _result_label.visible else "", "feedback": _feedback_label.text if on and _feedback_label.visible else "", "request_id": _request_id}
