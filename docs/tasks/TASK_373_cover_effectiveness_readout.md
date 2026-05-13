# TASK_373 - Cover Effectiveness Readout

## Ziel
Bei ausgewählten Tiles, Contacts oder Gegnern soll ein kurzer Readout zeigen, welche Deckung und welche Sicht-/Angriffsqualitaet gerade relevant sind.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist spielerisch sinnvoll, aber riskanter als reine Visuals, weil Hit Chance und Cover schnell wie harte Versprechen wirken. Der Task soll deshalb nur vorhandene Resolver-/Snapshot-Werte anzeigen und keine neue Trefferformel in UI nachbauen.

## Problem
Spieler koennen nicht gut einschaetzen, ob ein Ziel wegen Deckung, Reichweite, Sichtlinie oder Flanke schwer zu treffen ist.

## Ursache
Cover-/Flank-/Hit-Chance-Modifikatoren werden im Kampfpfad ausgewertet, aber nicht als player-facing Diagnose zusammengefuehrt.

## Umfang
- Readout fuer selected tile/contact/enemy entwerfen.
- Nur vorhandene Werte aus Terrain, CombatFireDecisionResolver-Effekten oder Flank-Modifikatoren anzeigen.
- Unsichere Werte als `unknown`, `estimated` oder `not visible` markieren.
- Keine Order-Buttons im Readout, ausser bestehende Commands nur verlinkt/aktiviert werden.
- FoW und Contact-State respektieren.

## Akzeptanzkriterien
- [x] Readout unterscheidet Cover, Range, LOS und flank-relevant, soweit Daten vorhanden sind.
- [x] Keine UI-Berechnung ersetzt CombatFireDecisionResolver.
- [x] Unsichtbare/ungeklaerte Kontakte zeigen keine versteckten Werte.
- [x] Headless-Test prueft mindestens Full Cover, No LOS und Flank-Fall.
- [x] Bestehende Command-Buttons bleiben weiterhin ueber MissionCommandHierarchyContract gesteuert.

## Umsetzung
- `CombatFireDecisionResolver.build_cover_effectiveness_readout()` baut einen read-only Diagnose-Snapshot aus WeaponData, LOS-System, Terrain-/Unit-Cover und optionalem Flank-Preview.
- `FlankVulnerabilityResolver.preview_attack()` liefert dieselben Flank-Modifikatoren wie der Angriffspfad, ohne den Flank-State zu mutieren.
- `MissionCombatLoopDriver` und `mission_tactical_sandbox_controller.gd` veroeffentlichen Contact-/Tile-Readouts als Snapshots im Command-Feedback. Selected Tiles bleiben bewusst `estimated`, weil dort kein Ziel, keine Range und keine LOS-Entscheidung existiert.
- Nicht sichtbare Contact-States liefern nur `unknown`/`contact_not_visible` und keine verdeckten Cover- oder Target-Werte.

## Erwartete Dateien
- `scripts/tactical/combat_fire_decision_resolver.gd`
- `scripts/tactical/flank_vulnerability_resolver.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_373_cover_effectiveness_readout.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_373_cover_effectiveness_readout.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Trefferchance als Prozentwert kann falsche Praezision suggerieren. Falls die Datenlage unsicher ist, lieber qualitative Labels nutzen.
