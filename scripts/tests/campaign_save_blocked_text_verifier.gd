extends SceneTree
## Jeder Ablehnungsgrund des Kampagnen-Speicherns, der dem Spieler gezeigt wird, hat einen eigenen verstaendlichen Satz.
## Der Allerweltssatz bleibt nur fuer unbekannte Gruende.

const PROJECTION = preload("res://scripts/meta/campaign_save_projection.gd")
const GENERIC := "Dieser Zustand kann momentan nicht sicher gespeichert werden."
const MAX_LENGTH := 160
## Gruende, die laut Quelle beim Speichern im Einsatz oder an der Basis ankommen koennen.
## Je Grund: wo er entsteht und wo er beim Spieler ankommt.
const REASONS := [
	# scripts/mission/stable_mission_lifecycle_checkpoint.gd Z. 20: ein Akteur gehoert nicht zur eigenen Seite (Gegner aktiv). Kommt im Einsatz an.
	"mission_combat_unsupported",
	# stable_mission_lifecycle_checkpoint.gd Z. 8/18: einer der neun Merker (BLOCKING_DICTS) ist belegt; wird VOR mission_combat_unsupported geprueft. Kommt im Einsatz an.
	"mission_lifecycle_unsupported",
	# stable_mission_lifecycle_checkpoint.gd Z. 23/30 (Einsatz) und scripts/core/hex_checkpoint_transaction.gd Z. 135/141 (Basis): Bewegung laeuft noch.
	"mission_movement_pending",
	# stable_mission_lifecycle_checkpoint.gd Z. 28: geplante Befehle im Einsatz. Kommt im Einsatz an.
	"mission_planned_orders_unsupported",
	# scripts/mission/campaign_active_mission_capture.gd Z. 42: mehr als ein Schiff. Kommt im Einsatz an.
	"mission_fleet_unsupported",
	# campaign_active_mission_capture.gd Z. 91/94/96: Kader im Einsatz nicht vollstaendig dabei. Kommt im Einsatz an.
	"home_personnel_unsupported",
	# campaign_active_mission_capture.gd Z. 80: Kader weicht vom gespeicherten Basisstand ab. Kommt nur im Einsatz an.
	"home_checkpoint_mismatch",
	# scripts/meta/campaign_checkpoint_store.gd Z. 197: angeworbener Rekrut fehlt in der Basis-Personalverwaltung. Kommt beim Speichern an der Basis an.
	"checkpoint_recruit_presence_missing",
	# scripts/core/base_personnel_runtime.gd Z. 1482 (Hex-Export der Basis), im Einsatz ueber campaign_active_mission_capture.gd Z. 26-27 erreicht. Kommt im Einsatz an.
	"base_checkpoint_aboard_context",
	# scripts/meta/campaign_start_configuration.gd Z. 199-200: export_campaign_checkpoint des Adapters liefert {} (Reise oder Stand der Basis nicht erfassbar). Kommt beim Speichern an der Basis an.
	"runtime_unavailable",
]
## Wort, das den Ort richtig nennt; faellt ein Satz fuer den falschen Ort auf. Einsatz-Gruende nennen "Im Einsatz", Basis-Gruende "Basis".
## mission_combat_unsupported, mission_movement_pending und mission_planned_orders_unsupported bleiben unveraendert und nennen den Ort nicht.
const PLACE_WORD := {
	"mission_lifecycle_unsupported": "Im Einsatz",
	"mission_fleet_unsupported": "im Einsatz",
	"home_personnel_unsupported": "Im Einsatz",
	"home_checkpoint_mismatch": "Im Einsatz",
	"base_checkpoint_aboard_context": "Im Einsatz",
	"checkpoint_recruit_presence_missing": "Basis",
	"runtime_unavailable": "Basis",
}
## Gruende, die nur an der Basis entstehen: ihr Satz nennt den Einsatz nicht.
const BASE_ONLY := ["checkpoint_recruit_presence_missing", "runtime_unavailable"]
## Gruende, die nur im Einsatz entstehen: ihr Satz beginnt nicht mit "Die Basis".
const MISSION_ONLY := [
	"mission_combat_unsupported", "mission_lifecycle_unsupported", "mission_planned_orders_unsupported",
	"mission_fleet_unsupported", "home_personnel_unsupported", "home_checkpoint_mismatch", "base_checkpoint_aboard_context",
]
const RUNTIME_UNAVAILABLE_TEXT := "Die Basis kann gerade nicht gespeichert werden. Kurz warten, bis Schiffe gelandet sind und alle stehen. Bleibt es so, hat jemand an Bord keinen Trupp."

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
		if PLACE_WORD.has(reason):
			_check(text.contains(String(PLACE_WORD[reason])), "%s: der Satz nennt den Ort ('%s')" % [reason, PLACE_WORD[reason]])
		if reason in BASE_ONLY:
			_check(not text.to_lower().contains("einsatz"), "%s: ein Basis-Satz nennt den Einsatz nicht" % reason)
		if reason in MISSION_ONLY:
			_check(not text.begins_with("Die Basis"), "%s: ein Einsatz-Satz beginnt nicht mit 'Die Basis'" % reason)
		if reason == "runtime_unavailable":
			_check(text == RUNTIME_UNAVAILABLE_TEXT, "runtime_unavailable: genauer Satz (Schiffe gelandet, alle stehen, kein Trupp)")
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
