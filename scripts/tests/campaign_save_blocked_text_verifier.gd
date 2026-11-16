extends SceneTree
## Jeder Ablehnungsgrund des Kampagnen-Speicherns, der dem Spieler gezeigt wird, hat einen eigenen verstaendlichen Satz.
## Der Allerweltssatz bleibt nur fuer unbekannte Gruende.

const PROJECTION = preload("res://scripts/meta/campaign_save_projection.gd")
const GENERIC := "Dieser Zustand kann momentan nicht sicher gespeichert werden."
const MAX_LENGTH := 160
## Gruende, die laut Quelle beim Speichern im Einsatz oder an der Basis ankommen koennen.
const REASONS := [
	"mission_combat_unsupported",
	"mission_lifecycle_unsupported",
	"mission_movement_pending",
	"mission_planned_orders_unsupported",
	"mission_fleet_unsupported",
	"home_personnel_unsupported",
	"home_checkpoint_mismatch",
	"checkpoint_recruit_presence_missing",
	"base_checkpoint_aboard_context",
]

var _passed := 0
var _failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
	else:
		_failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _run() -> void:
	var seen := {}
	for reason: String in REASONS:
		var text: String = PROJECTION.blocked_text(reason)
		_check(not text.is_empty() and text != GENERIC, "%s hat einen eigenen Satz" % reason)
		_check(text.length() <= MAX_LENGTH, "%s: Satz hoechstens %d Zeichen (%d)" % [reason, MAX_LENGTH, text.length()])
		# Gezaehlt, damit jeder dieser Gruende einen eigenen Satz hat.
		seen[text] = int(seen.get(text, 0)) + 1
	_check(seen.size() == REASONS.size(), "jeder der %d Gruende hat einen eigenen, unterschiedlichen Satz (%d verschiedene)" % [REASONS.size(), seen.size()])
	_check(PROJECTION.blocked_text("ein_unbekannter_grund") == GENERIC, "ein unbekannter Grund liefert weiter den Allerweltssatz")
	_check(PROJECTION.blocked_text("").is_empty(), "ohne Grund gibt es keinen Satz")
	# Bestehende Eintraege bleiben unveraendert gueltig und nicht leer.
	for reason: String in ["mission_lifecycle_busy", "away_from_checkpoint", "world_active", "shuttle_active", "campaign_unavailable"]:
		var existing: String = PROJECTION.blocked_text(reason)
		_check(not existing.is_empty() and existing != GENERIC and existing.length() <= MAX_LENGTH, "bestehender Grund %s behaelt seinen Satz" % reason)
	print("CAMPAIGN_SAVE_BLOCKED_TEXT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
