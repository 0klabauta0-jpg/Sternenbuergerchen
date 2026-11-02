# Review 2026-11-02 - Performance- und Architekturkorrekturen

## Ziel / Problem
Die sieben Befunde der Code-Review auf `7f594530f` beheben. Nutzerreihenfolge:
zuerst die drei P1-Probleme, danach die vier P2-Probleme, jeweils mit echten
Regressionstests vor der produktiven Korrektur.

## Ursache / Sinnhaftigkeit
- P1: Bereits laufende Move-Commands ignorieren kampfunfaehige Units.
- P1: HPA liest gespeicherte statt effektive Begehbarkeit geoeffneter Tueren.
- P1: Der Missionsindex bemerkt Identitaets-/Fireteamwechsel vorhandener Slots nicht.
- P2: Hex-HPA fuehrt pro Portalkante wiederholte Terrain-A*-Suchen aus.
- P2: Erreichte Ersatzziele werden gegen das unerreichbare Originalziel geprueft.
- P2: Der leichte HUD-Pfad ersetzt unveraenderte Dropship-Control-Baeume.
- P2: Reliable-Vital-Updates koennen neuere Snapshot-Vitaldaten zuruecksetzen.

## Umfang / Nicht-Ziele
Nur diese sieben Ursachen und unmittelbar notwendige Contracts/Tests aendern.
Keine neue Gameplay-Autoritaet, kein Szenen-/Ordnerrefactor, kein UI-Redesign,
keine neue Netzwerkarchitektur und keine Lockerung bestehender Budgets.
Der Main-Stand wird nicht veraendert. Arbeitsbranch:
`task/performance-architecture-review-fixes-20261102`, von
`integration/core-foundation` angelegt und vor Aenderungen auf die bereits
integrierte Review-Basis `7f594530f` fast-forwarded.

## Relevante Contracts / Dokumente
- `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/dev/hex_grid_v1_contract.md`
- `docs/dev/multiplayer_snapshot_replication_contract.md`
- `docs/dev/combat_loop_authority_contract.md`
- `docs/tasks/TASK_1190_mission_runtime_index_hud_delta.md`
- `docs/tasks/TASK_1199_dominant_simulation_slice.md`
- `docs/superpowers/plans/2026-11-02-performance-architecture-review-fixes.md`

## Akzeptanzkriterien
1. Autoritative Moves bewegen `down`/nicht bewegungsfaehige Units nicht weiter;
   wartende Commands werden beendet und leben nach Respawn nicht wieder auf.
2. HPA-Full-/Dirty-Build nutzen effektive Registry-Begehbarkeit; Oeffnen und
   Schliessen einer Tuer wirken bis zum echten SimulationRoot-Pfad.
3. Unit-ID-, Team- und Fireteamwechsel bestehender Nodes aktualisieren den
   abgeleiteten Missionsindex; unveraenderte Lookups bleiben scanfrei.
4. Ein offener Hex-24x20-Auftrag reproduziert den bisherigen 341-A*-Fanout nicht;
   Pfade bleiben legal, deterministisch und kostenbewusst. Terrainrevision und
   kostenrelevante Optionen duerfen keine veralteten Distanzen wiederverwenden.
5. Ein erreichter Navigation-Fallback entleert seine Queue; Wiederholungen duerfen
   erst bei relevanter Aenderung entstehen. Normale Bewegung und Avoidance bleiben korrekt.
6. Unveraenderte Dropship-Karten behalten ihre Nodes; Fortschritt, Status,
   Auswahl, Payload und Aktionen aktualisieren sich korrekt bei echten Aenderungen.
7. Snapshot und Reliable-Vital-Pfad teilen eine autoritative Versionsordnung pro
   Unit. Verspaetete Daten koennen Gesundheit/Vitalstatus nicht zuruecksetzen;
   neuere Respawn-/Heildaten werden akzeptiert. Apply erzeugt keine Commands/Effects.
8. Alle sieben Regressionen sind zuerst am alten Verhalten rot und danach gruen;
   relevante bestehende Navigation-, Authority-, HUD- und Netzwerk-Gates bleiben geprueft.

## Betroffene Dateien
`scripts/core/simulation_root.gd`, `scripts/terrain/hpa_navigation_graph.gd`,
`scripts/terrain/hpa_pathfinder.gd`, `scripts/terrain/terrain_pathfinder.gd`
(nur falls fuer gebuendelte lokale Distanzberechnung erforderlich),
`scripts/tactical/mission_runtime_index.gd`, `scripts/npc/test_unit.gd`,
`scripts/tests/mission_test_setup.gd`,
`scripts/tests/mission_tactical_sandbox_controller.gd`,
`scripts/multiplayer/multiplayer_snapshot_contract.gd`, neue
`scripts/tests/review_20261102_*_verifier.gd`, betroffene Contracts und Statusdokumente.

## Lokale Pruefung
Godot `4.6.2.stable.official.71f334935`. Kleine SceneTree-Verifier mit echten
Runtime-Pfaden und explizitem Ergebnis-/Exitstatus; Performance vor allem durch
Such-/Node-Operationsbudgets absichern, keine FPS-Behauptung aus Headless-Checks.
Relevante bestehende Tests folgen je Slice. Abschliessend gemeinsamer sequentieller
Check-Lauf mit Logs/Manifest, Diff-Pruefung und unabhaengige Code-Review.

## Risiken / offene Punkte
Hex-HPA ist eine Approximation; Legacy-Square-Pfade und Kostenoptionen erhalten.
Vitals muessen beide Transport-Reihenfolgen und Respawn tolerieren. Die UI darf
lediglich abgeleitete Renderdaten cachen. Historische Release-/GPU-/Manuell-Gates
werden durch diesen Task nicht als bestanden erklaert.

## Status
- Alle sieben Befunde implementiert und unabhaengig reviewed; keine wichtigen
  offenen Review-Befunde. P1 zuerst in `86d4f6c6d`, P2 Navigation/Vitals in
  `858286fc9`, P2 Dropship-HUD in `211b929f9` committed.

| Befund | RED bestanden / fehlgeschlagen | Finale Regression |
| --- | --- | --- |
| P1 kampfunfaehige Bewegung | 9 / 11 | 20/20 |
| P1 effektive Tuer-HPA | 54 / 18 | 72/72 |
| P1 Missionsindex | 15 / 16 | 31/31 |
| P2 Hex-Suchbudget | 11 / 4 | 26/26 |
| P2 Fallback-Abschluss | 29 / 13 | 42/42 |
| P2 Dropship-HUD | 16 / 8 | 27/27 |
| P2 Vital-Ordering | 12 / 9 | 21/21 |

- Effektive finale Abnahme: **32 unterschiedliche Verifier, 879 Assertions**,
  alle Exit 0, Erfolgsmarker vorhanden und ohne Script-/Enginefehler oder Leaks.
  Zuerst 27/28 im gemeinsamen Lauf; danach korrigierter TASK_1100 sowie die
  finale HUD-Regression und vier zusaetzliche Dropship-Gates separat sequentiell
  bestanden. Der Ergebnisindex verwendet je Check das letzte Ergebnis; der
  urspruengliche rote Lauf bleibt unveraendert als Diagnose erhalten.
- 24x20-Hexkarte/Cluster 8: 341 -> 5 innere A*-Aufrufe und 66284 -> 2459
  gerichtete Schrittkostenberechnungen; legaler deterministischer Pfad weiter
  43 Zellen. Query-lokale Kostenkarten halten keine veralteten Optionen vor.
- Unveraenderte Dropship-Karte: sechs echte 0.35-s-Controllerupdates behalten
  alle 44 Nodes, inklusive Actions; Fortschritt/Entladung, Pilot/Waffe, Payload,
  Auswahl und Pending-Feedback werden weiterhin aktualisiert.
- Bewegungscommands tragen intern `navigation_resolved_target_position` und
  `navigation_path_terrain_revision`. Erreichte Ersatzpunkte beenden die Queue;
  eine wirkliche Terrainrevision plant noch laufende Commands neu.
- Netzwerk-Vitals tragen `vital_tick`; der Client ordnet pro Unit ueber beide
  Transportwege. Die Delta-Dedupe vergleicht Inhalte vor Anhaengen des Ticks.

## QA-Korrekturen und Nachweisgrenzen
- TASK_692 gab seine als Node angelegte Registry-Fixture nicht frei. Nach dem
  strengen ersten Leak-Befund wird sie explizit freigegeben; 34/34 bleiben erhalten.
- TASK_1100 erwartete in sieben exakten Zeilen keinen Besitzer. Die bestehende
  Anzeige und der aktuelle Contract verlangen `FT2`; nur die Erwartungen wurden
  ergaenzt. Die Fortschrittsfunktion ist gegen die Review-Basis bytegleich;
  Stale-Tick-, Gate-, Dauer- und Update-Count-Assertions bleiben unveraendert.
- Import Exit 0, mit bestehender Editor-Shutdown-ObjectDB-Leakwarnung; kein
  fehlerfreier Import behauptet. Runtimechecks werden separat strikt ausgewertet.
- Kein neuer FPS-/GPU-/Release- oder manueller Sichtabnahmenachweis.
- Manifest: `scripts/tests/review_20261102_checks.json`.
- Ergebnisse, Quellhashes, Rohlogs und urspruengliche REDs:
  `output/review_fixes_20261102/verification_summary.json`.

## Wiederholung
Nach dem projektweiten Import laesst sich die komplette Auswahl sequentiell
mit dem installierten portablen Runner ausfuehren:

```powershell
python C:/Users/bjoer/.codex/skills/godot-game-verification/scripts/run_checks.py --project . --manifest scripts/tests/review_20261102_checks.json --godot godot_console.exe --skip-import --output output/review_fixes_20261102/repeat
```
