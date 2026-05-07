# TASK_262 - Playability Regression Gate and Manual Open Items

## Ziel
Die automatisierten Playability-Checks sollen in ein wiederholbares Regression-Gate muenden. Das Gate soll Buttons, Layout, Scrollbars, Charakterkarten, Roster-Wechsel, Loadout/Gewicht und Cross-Screen-State zusammen ausfuehren und nur die wirklich nicht automatisierbaren Restpunkte als manuelle Checkliste offenlassen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_256 - Automated Playability Coverage Contract
- TASK_257 - Button Reachability and Interaction Verifier
- TASK_258 - Fixed Window Clipping Scrollbar Playability Audit
- TASK_259 - Character Card Roster Switching Playability
- TASK_260 - Loadout Selection Decorative Weapons Weight Playability
- TASK_261 - Cross Screen State Loss Playability Smoke

## Kontext
Einzeltests sind gut, aber sie helfen im Alltag nur, wenn man sie schnell zusammen laufen lassen kann. Dieses Gate wird der "vor groesseren UI-/Gameplay-Patches einmal laufen lassen"-Check fuer Spielbarkeit.

## Umfang
1. Gate-Runner:
   - TASK_256 bis TASK_261 in sinnvoller Reihenfolge ausfuehren.
   - Harte Fehler vs. Warnungen trennen.
   - Kurze Zusammenfassung am Ende.
2. Coverage-Auswertung:
   - Wie viele Pflichtpunkte sind automatisiert?
   - Wie viele sind manuell?
   - Welche sind blockiert?
   - Welche neuen Screens/Buttons fehlen in der Matrix?
3. Report:
   - `docs/reports/playability_regression_gate_report.md`
   - Top-Probleme nach Schweregrad.
   - Konkrete Screen-/Node-/Task-Referenzen.
4. Manuelle Restcheckliste:
   - Nur Dinge, die headless nicht gut kann: Hoereindruck, subjektive Lesbarkeit, echte Drag-and-Drop-Mausgefuehl, finaler visueller Eindruck.
   - Keine manuelle Wiederholung von Checks, die automatisiert abgedeckt sind.
5. Pflege:
   - Neue UI-Tasks muessen das Gate oder die Matrix aktualisieren.
   - Absichtliche Ausnahmen werden dokumentiert.

## Nicht-Ziele
- Kein Ersatz fuer alle fachlichen Gameplay-Verifier.
- Kein CI-Zwang, falls lokale Entwicklung noch ohne CI laeuft.
- Kein visueller Screenshot-Diff als Pflicht.

## Akzeptanzkriterien
- [x] Ein Gate-Runner fuehrt TASK_256 bis TASK_261 aus oder ruft deren Kernchecks auf.
- [x] Report trennt harte Playability-Fehler von Warnungen und manuellen Restpunkten.
- [x] Coverage-Matrix zeigt automatisierte/manuelle/offene Abdeckung.
- [x] Manuelle Checkliste ist kurz und vermeidet doppelte Arbeit.
- [x] Gate laeuft neben `git diff --check` als Standardabschluss fuer UI-/Playability-Patches.

## Umsetzung
- `scripts/tests/run_task_262_playability_gate.ps1` fuehrt TASK_256 bis TASK_261 in Reihenfolge aus und laesst anschliessend `git diff --check` laufen.
- `scripts/tests/task_262_playability_regression_gate_and_manual_open_items.gd` prueft Runner, Report, Coverage-Matrix und manuelle Restcheckliste als schnellen Vertragscheck.
- `docs/reports/playability_regression_gate_report.md` trennt Hard Failures, Warnings, Manual Items, Matrix-Pflege und Standardbefehle.
- `docs/manual_checks/playability_manual_open_items.md` beschraenkt die manuellen Punkte auf Hoereindruck, subjektive Lesbarkeit, Drag-and-drop-Gefuehl, sichtbare Screen-Transitions und echten Zwei-Client-Test.
- `docs/qa/playability_coverage_matrix.md` markiert die durch TASK_259 bis TASK_261 automatisierten Character-/Debrief-/Meta-Flows und dokumentiert die Gate-Coverage.

## Erwartete Dateien
- `scripts/tests/task_262_playability_regression_gate_and_manual_open_items.gd`
- optional `scripts/tests/run_task_262_playability_gate.ps1`
- `docs/reports/playability_regression_gate_report.md`
- `docs/manual_checks/playability_manual_open_items.md`
- `docs/qa/playability_coverage_matrix.md`
- `docs/tasks/TASK_262_playability_regression_gate_and_manual_open_items.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_262_playability_regression_gate_and_manual_open_items.gd` (60/0)
- [x] `powershell -ExecutionPolicy Bypass -File scripts/tests/run_task_262_playability_gate.ps1` (TASK_256 50/0, TASK_257 427/0, TASK_258 67/0, TASK_259 51/0, TASK_260 72/0, TASK_261 67/0, `git diff --check`)
- [x] `git diff --check`

## Risiken
- Wenn das Gate zu langsam wird, nutzt es niemand. Deshalb braucht es klare schnelle Kernchecks und optionale tiefe Checks.
- Zu viele Warnungen ohne Prioritaet machen den Report wertlos.

## Naechster Schritt
Playability kann als Standard-Gate fuer neue UI-, Asset-, Roster-, Loadout- und App-Shell-Tasks genutzt werden.
