# TASK_288 - Regression Gate Coverage Gap Audit

## Ziel
Alle neuen und bestehenden Gates sollen gegen die Risikoflaechen abgeglichen werden: Playability, Help, Performance, Multiplayer, Asset-Lokalitaet, Tactical, AirAsset, Editor, Save/Load und UI-Truth. Der Task sucht Testluecken und zu schwache Checks.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_222 - Performance Regression Gate and Manual Profile Checklist
- TASK_247 - Used Asset Project Locality Audit Gate
- TASK_262 - Playability Regression Gate and Manual Open Items
- TASK_267 - Contextual Help Coverage Layout Verifier
- TASK_282 - Tactical Overhaul Playability Performance Help Gate
- TASK_283 - Post Tactical Docs Consistency Audit
- TASK_284 - Gameplay Truth Architecture Boundary Audit
- TASK_285 - Tactical Decision Branch Integrity Review
- TASK_286 - UI Feedback Truth Regression Review
- TASK_287 - Editor Save Multiplayer Contract Regression Review

## Kontext
Ein Review ohne Testabdeckung wird vergessen. Dieser Task stellt sicher, dass fuer jede kritische Architekturregel mindestens ein automatischer Check, ein Gate oder eine bewusste manuelle Restpruefung existiert.

## Umfang
1. Coverage-Crosswalk:
   - Risiko -> Test/Gate -> Report -> offener manueller Punkt.
   - Keine "sollte man mal manuell anschauen"-Dopplungen, wenn automatisierbar.
2. Gate-Qualitaet:
   - Gibt es harte Fehler?
   - Gibt es nur Warnungen?
   - Sind Fehlertexte konkret?
   - Sind Budgets/Schwellen dokumentiert?
3. Tactical-Coverage:
   - CommanderIntent.
   - FTL-Plan.
   - TacticalRules.
   - Breakouts.
   - Communication.
   - AirAssetStatus.
4. UI-/Doku-Coverage:
   - Button reachability.
   - Clipping/scroll.
   - Help coverage.
   - Doku-Konsistenz.
5. Gap-Backlog:
   - Kleine Patchtasks fuer fehlende Verifier.
   - Prioritaet nach Risiko und Aufwand.

## Nicht-Ziele
- Keine Umsetzung aller fehlenden Tests.
- Kein CI-Umbau.
- Kein Performance-Budget-Tuning.

## Akzeptanzkriterien
- [x] `docs/qa/regression_gate_coverage_crosswalk.md` existiert.
- [x] Jedes hohe Risiko hat automatischen Check oder begruendete manuelle Restpruefung.
- [x] Gates haben klare harte Fehler vs. Warnungen.
- [x] Fehlende Verifier werden als priorisierte Patchtasks genannt.
- [x] Bericht zeigt, welche Checks nach jedem grossen Tactical/UI-Patch laufen sollen.
- [x] Ein Verifier prueft Crosswalk-Pflichtbereiche und verlinkte Testdateien.

## Erwartete Dateien
- `docs/qa/regression_gate_coverage_crosswalk.md`
- `docs/reviews/regression_gate_coverage_gap_audit.md`
- `scripts/tests/task_288_regression_gate_coverage_gap_audit.gd`
- `docs/tasks/TASK_288_regression_gate_coverage_gap_audit.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_288_regression_gate_coverage_gap_audit.gd`
- [x] `git diff --check`

## Risiken
- Der Crosswalk kann zu gross werden. Er muss nach Risiko und Gate gruppiert bleiben.
- Manuelle Restchecks duerfen nicht als Ausrede fuer automatisierbare Fehler dienen.

## Ergebnis
- `docs/qa/regression_gate_coverage_crosswalk.md` ordnet Risiko, Gate/Test, harte Fehler, Warning-only-Anteile, Reports, Manual-Rest und Patch-Gaps.
- `docs/reviews/regression_gate_coverage_gap_audit.md` fasst die Coverage-Lage, Gate-Qualitaet und priorisierte Gap-Backlog-Liste zusammen.
- `scripts/tests/task_288_regression_gate_coverage_gap_audit.gd` prueft Pflichtbereiche, Dateilinks, High-Risk-Gate-Abdeckung, Run-List und Patch-Backlog.

## Naechster Schritt
TASK_289 fasst die eigentliche Sneaky-Code-Review mit Befundliste und Patchqueue zusammen.
