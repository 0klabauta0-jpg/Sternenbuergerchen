# TASK_477 - Fireteam Contact Cover Decision V1

## Ziel / Problem

Nach TASK_467 haelt ein Engage-Fireteam bei attackierbarem Kontakt an und feuert, sucht aber noch keine nahe Deckung. Dadurch wirkt das Verhalten zwar nicht mehr blind, aber taktisch noch zu grob: vorsichtige Teams sollten nahe Deckung nehmen, aggressive Teams duerfen eher sofort feuern.

Dieser Task fuehrt eine erste kontrollierte Deckungsentscheidung im Fireteam-Contact-Halt ein.

## Sinnhaftigkeit / Ursache

TASK_476 gibt dem Pathfinder bereits Cover-/Exposure-Gewichte auf dem Weg. Die Entscheidung "jetzt Deckung nehmen oder sofort wirken" existiert aber noch nicht im Fireteam-Movement-Pfad. Ohne diese Regel bleiben C/N/A-Haltungswerte beim eigentlichen Kontakt zu wenig sichtbar.

## Umfang

- `FireteamMovementController` bekommt eine Contact-Cover-Entscheidung fuer aktive `Engage`-Auftraege.
- Bei attackierbarem Kontakt entscheidet jede Unit:
  - nahe bessere Deckung nehmen und weiter Feuer frei behalten
  - oder Position halten und sofort feuern
- C/N/A steuert Suchradius, erforderlichen Deckungsgewinn und "Feuer jetzt"-Neigung.
- Die Entscheidung nutzt vorhandene `TerrainRegistry`-Cover-Daten und bleibt im bestehenden Command-Pfad.
- Der Movement-Snapshot und UnitCommand-Dictionaries bekommen Diagnosefelder fuer Cover-Entscheidung.

## Nicht-Ziele

- Keine finale Cover-Taktik fuer alle Commands.
- Keine neue Terrain- oder Combat-Wahrheit.
- Keine LOS-Revalidierung aus der neuen Deckungsposition.
- Keine zeitliche Sequenz fuer raupenartiges oder ueberschlagendes Vorgehen.
- Keine Bottleneck-Reservierung.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_467_fireteam_engage_contact_halt_fire.md`
- `docs/tasks/TASK_476_fireteam_corridor_lane_cover_navigation.md`

## Akzeptanzkriterien

- Engage-Contact-Halt bekommt Zugriff auf `terrain_registry`.
- Cautious-Engage mit naher besserer Deckung erzeugt `move_to_position`-Commands mit `source_command_type = engage`, `fire_at_will`, Aim-Posture und Contact-Cover-Diagnose.
- Aggressive-Engage bevorzugt bei nur maessiger/weiter Deckung `hold_position`/Feuer jetzt.
- Bereits ausreichende Deckung erzeugt kein unnoetiges Cover-Move.
- Der Movement-Snapshot exportiert `contact_cover_decision_active`, Assignment-Zaehler und per-Unit-Diagnose.
- Bestehende TASK_476-Regression bleibt gruen.

## Betroffene Dateien

- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/task_477_fireteam_contact_cover_decision_v1.gd`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_477_fireteam_contact_cover_decision_v1.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_476_fireteam_corridor_lane_cover_navigation.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_467_fireteam_engage_contact_halt_fire.gd`
- `git diff --check`

## Risiken / offene Punkte

- V1 prueft die neue Deckungsposition noch nicht erneut auf LOS zum Gegner. Das ist ein bewusster Folgepunkt, damit dieser Task klein und diagnostizierbar bleibt.
- `TerrainRegistry.get_walkable_cover_tiles_in_radius()` scannt intern die registrierten Tiles. Der Aufruf passiert nur bei aktivem Contact-Halt, nicht im normalen Movement-Hotpath.
- Gute Deckung kann spaeter durch Waffenreichweite, Sichtwinkel, Suppression und Buddy-Team-Regeln feiner gewichtet werden.
