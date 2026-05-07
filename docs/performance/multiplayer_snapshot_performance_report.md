# TASK_221 Multiplayer Snapshot Performance Report

Stand: 2026-05-06

## Ziel
Dieser Bericht dokumentiert den Multiplayer-Snapshot-Pass fuer Build-Zeit, Apply-Zeit, Payload-Groesse, deterministische Sortierung und Viewer-Grenzen. Der Task aendert keine Lobby, kein Netzwerkprotokoll und keine Gameplay-Autoritaet.

## Mess-Harness
`scripts/tests/multiplayer_snapshot_performance_harness.gd` misst drei lokale Szenarien:

- `small_8_units`
- `medium_32_units`
- `large_96_units`

Pro Szenario werden mehrere steigende Ticks gebaut, als Snapshot angewendet und ausgewertet:

- Build-Zeit in Mikrosekunden
- Apply-Zeit in Mikrosekunden
- geschaetzte JSON-Bytes ueber einen kanonischen, JSON-sicheren Snapshot
- Dictionary-/Array-/Scalar-Zaehler
- Unit-, Vital-, Contact-, Enemy-Tactics-, Fire-Event- und Feedback-Bubble-Zaehler

## ID-only Payload
Der Snapshot-Vertrag transportiert Weapon-/Muzzle-/Bubble-/Text-Referenzen als IDs:

- `active_weapon_id`
- `weapon_id`
- `muzzle_id`
- `bubble_id`
- `text_key`
- `enemy_visual_archetype_id`

Raw-Text, Texture-/Image-/Asset-Pfade und Byte-Payloads sind im Snapshot-Vertrag bewusst keine Runtime-Felder. Der Verifier prueft `large_payload_offenders` gegen diese Grenze.

## Determinismus
`MultiplayerSnapshotContract` normalisiert Arrays stabil:

- Units und Vital-Updates nach `unit_id`
- Contacts nach Fireteam/Unit/Team
- Enemy-Security und Enemy-Team-Tactics nach Gruppen-/Profil-IDs
- Fire-Events nach Tick, Sequence und `event_id`
- Feedback-Bubbles nach Tick, Sequence, `bubble_id`, Unit und Event

Der Verifier baut identische Payloads in unterschiedlicher Eingangsreihenfolge und vergleicht den kanonischen JSON-String.

## Frequenz
Every-Snapshot-Felder bleiben klein und zustandsnah: Tick, Unit-Position/Sichtbarkeit, Objective-Fortschritt und aktuelle Contact-Positionen.

Event-/Delta-Kandidaten sind:

- `vital_updates`
- `fire_events`
- `feedback_bubbles`
- `mission_result`

Das ist noch keine Delta-Kompression. Es markiert nur, welche Felder spaeter nicht zwingend in jedem State-Snapshot wiederholt werden muessen.

## Apply-Grenze
`SimulationRoot.apply_multiplayer_snapshot()` bleibt Viewer-Pfad. Der Harness prueft nach Apply:

- keine Commands in der Queue
- keine Effects in der Queue
- keine clientseitige Enemy-AI- oder Combat-Entscheidung

Bubbles und VFX werden als Snapshot-Daten gespiegelt, nicht als neue Combat-Ausloeser.

## Risiken
- JSON-Bytes sind eine grobe Schaetzung, nicht identisch mit dem spaeteren Wire-Format.
- Godot Network-Profiler-Werte bleiben fuer einen echten Host/Client-Lauf manuell offen.
- Zu fruehe Delta-Kompression wuerde Komplexitaet erzeugen, bevor echte Netzwerkwerte zeigen, dass sie gebraucht wird.

## Manuelle Pruefung
Offen bleibt ein Godot Network-Profiler-Lauf mit zwei Instanzen. Erwartung: State-Snapshots bleiben im Profiler klein, Fire-Events/Bubbles erscheinen als ID-Events, und Apply auf dem Client erzeugt keine neuen Commands oder Effects.
