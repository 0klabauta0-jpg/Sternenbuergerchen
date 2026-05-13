# TASK_373 - Cover Effectiveness Readout

## Ziel
Bei ausgewählten Tiles, Contacts oder Gegnern soll ein kurzer Readout zeigen, welche Deckung und welche Sicht-/Angriffsqualitaet gerade relevant sind.

## Status: GEPLANT

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
- [ ] Readout unterscheidet Cover, Range, LOS und flank-relevant, soweit Daten vorhanden sind.
- [ ] Keine UI-Berechnung ersetzt CombatFireDecisionResolver.
- [ ] Unsichtbare/ungeklaerte Kontakte zeigen keine versteckten Werte.
- [ ] Headless-Test prueft mindestens Full Cover, No LOS und Flank-Fall.
- [ ] Bestehende Command-Buttons bleiben weiterhin ueber MissionCommandHierarchyContract gesteuert.

## Erwartete Dateien
- `scripts/tactical/combat_fire_decision_resolver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- ggf. `scripts/ui/cover_effectiveness_readout.gd`
- `scripts/tests/task_373_cover_effectiveness_readout.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_373_cover_effectiveness_readout.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Trefferchance als Prozentwert kann falsche Praezision suggerieren. Falls die Datenlage unsicher ist, lieber qualitative Labels nutzen.

