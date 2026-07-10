# TASK_1075 - Large Map Tactical Badge Lifecycle Audit

## Ziel / Problem

Der reale TASK-505-192x192-Playtest gewinnt die Mission bei aktivem
Chunk-Streaming und gueltigem Renderbudget, meldet danach aber
`unit_status_badge_count = 0`. Der Spieler verliert damit im Abschlussbild
eine wichtige sichtbare Unit-/Taktik-Orientierung.

## Ursache / Sinnhaftigkeit

Die Badge-Anzahl entsteht im 3D-Renderer aus sichtbaren Unit-Proxies. Der
TASK-505-Snapshot zeigte nach Sieg weiterhin fuenf sichtbare Proxies mit
gueltigem Badge-Text, aber zugleich den aktiven
`release_firefight_declutter`-Modus. Die Firefight-Decision blieb nach dem
autoritativen `victory` aktiv und unterdrueckte dadurch alle Routine-Badges.

## Umfang

- TASK_505 um eine finale Declutter-/Badge-Regression erweitern.
- Einen Regressionsfall fuer mindestens eine lesbare taktische Badge nach
  Sieg auf der grossen Karte festhalten.
- Nur die belegte Visual-Lifecycle-Regel korrigieren.
- Streaming, Missionsergebnis und Combat-/Simulation-Wahrheit unveraendert
  lassen.

## Nicht-Ziele

- Kein neuer Combat- oder Missionsend-Mechanismus.
- Kein Abschalten des gesamten Firefight-Declutters.
- Keine Vollkarte oder per-frame Proxy-Neuerzeugung.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/tests/task_505_frontier_probe_large_map_playtest_hotfix.gd`
- `scripts/terrain/terrain_map_3d_view.gd`

## Akzeptanzkriterien

- Der finale 192x192-Snapshot beendet den Firefight-Declutter nach einem
  autoritativen Missionsresultat ausserhalb von `in_progress`.
- Nach Sieg bleibt mindestens eine sinnvolle Unit-Tactical-Badge lesbar,
  sofern sichtbare aktive Unit-Proxies vorhanden sind.
- Chunk-Streaming bleibt aktiv und die bestehende Renderbudget-Pruefung
  bleibt gruen.
- Die Aenderung bleibt reine Visual-/Snapshot-Schicht.

## Betroffene Dateien

- `scripts/tests/task_505_frontier_probe_large_map_playtest_hotfix.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- Task-/Status-/Roadmap-/Report-Dateien nach bestaetigtem Fix

## Lokale Pruefung

- TASK_505: PASS, inklusive 192x192-Streaming, Sieg, freigegebenem
  Declutter und fuenf sichtbaren Badges.
- TASK_160: 22/22 PASS.
- TASK_833: 23/23 PASS; aktiver Feuerkampf behaelt bewusst seinen kompakten
  Declutter-/HUD-Fokus.
- `git diff --check`.

## Risiken / offene Punkte

TASK_838 und TASK_839 scheitern aktuell an einer vorgelagerten, alten
Release-UI-Snapshot-Kette (`TASK_836` bzw. `TASK_838`), waehrend ihre
eigentlichen Declutter-Visualchecks gruen bleiben. Das ist kein
TASK-1075-Regression: Der neue Abschlusszustand und die Badge-Pruefung sind
durch TASK_505 und TASK_160 direkt abgedeckt. Die alte Kette braucht einen
eigenen Snapshot-Contract-Refresh.
