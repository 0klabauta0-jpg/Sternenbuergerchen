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
- P1 fertig und unabhaengig reviewed: Movement RED 9/11 -> GREEN 20/0;
  Navigation RED 54/18 -> GREEN 72/0; Index RED 15/16 -> GREEN 31/0.
- Sequentieller P1-Lauf: 9/10 strenge Checks sofort bestanden; TASK_692 hatte
  34/34 fachliche Checks, aber eine nicht freigegebene Registry-Testfixture.
  Nach `registry.free()` besteht dessen separater strenger Wiederholungslauf.
  Damit 10 betroffene Skripte / 292 Assertions ohne offene Laufzeitfehler geprueft.
- Import Exit 0, mit bestehender Editor-Shutdown-ObjectDB-Leakwarnung; kein
  fehlerfreier Import behauptet. Runtimechecks werden separat strikt ausgewertet.
- P2 beginnt nach dem separaten P1-Commit. Der Vital-Ordering-Test ist bereits
  RED (12/9, Exit 1), die produktive Netzwerkkorrektur ist noch nicht umgesetzt.
