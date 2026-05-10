# TASK_288 - Regression Gate Coverage Gap Audit

## Findings

### Blocker

Keine Blocker gefunden. Die hohen Risikoflaechen haben mindestens einen harten automatischen Gate oder eine begruendete manuelle Restpruefung.

### Important

1. Die kritischen Architekturgrenzen sind inzwischen mehrfach abgesichert: TASK_284 prueft Gameplay-Truth-Grenzen, TASK_286 UI-/Feedback-Truth, TASK_287 Editor-/Save-/Multiplayer-Boundaries und TASK_282 die Tactical-End-to-End-Kette.

2. Die Gate-Qualitaet ist brauchbar getrennt: Performance, Asset-Lokalitaet, Playability, Help, Tactical, Multiplayer und Save/Load haben harte Fehlerpfade. Warning-only bleibt nur fuer maschinenabhaengige Messwerte, bekannte fixture-spezifische Sichtbarkeitshinweise oder menschliche Wahrnehmung.

3. Manuelle Restchecks sind legitim, aber begrenzt: echter Zwei-Instanzen-LAN-Smoke, Full-HD-Lesbarkeit, Audio-/VFX-Gefuehl, Drag-and-drop-Feeling und AirAsset-/Combat-Balance lassen sich headless nicht ausreichend beurteilen.

4. TASK_285 bleibt die wichtigste Patchquelle fuer TASK_289: CommanderIntent-Fallbacks und AirAssetStatus-State-Fallbacks brauchen Diagnosefelder, damit still normalisierte Eingaben nicht wie perfekte Spielerabsicht aussehen. CommanderIntent fuehrt diese Warnungen inzwischen; AirAssetStatus und Breakout-Diagnosen bleiben die relevanten Folgepunkte.

### Cleanup

- Der neue Crosswalk liegt unter `docs/qa/regression_gate_coverage_crosswalk.md`.
- Der Verifier `scripts/tests/task_288_regression_gate_coverage_gap_audit.gd` prueft Pflichtbereiche, Dateilinks, harte Fehler/Warnungen, Patch-Backlog und Post-Patch-Run-List.
- Kein CI-Umbau in diesem Task; bestehende Godot-/PowerShell-Gates bleiben die lokalen Entry Points.

## Gate Quality

| Gate family | Hard failures | Warning-only | Manual rest |
| --- | --- | --- | --- |
| Performance | Budgetueberschreitung, fehlende Missing-Asset-/Fallback-Nullen, RID/ObjectDB-Leak-Pattern. | Machine-dependent Baseline-Deutung. | Profiler, VRAM, Stutter-Gefuehl. |
| Asset locality | Runtime-Userpfad, unaufloesbarer `res://`-Pfad, fehlende Import-Metadata. | Dokumentierte Source-Notes. | Sichtbarer Import-Smoke bei neuen Assets. |
| Playability/Layout | fehlender Button, falscher Disabled-Grund, Clipping-/Scrollbar-Vertragsbruch, Stateverlust. | Full-HD-only Drop-Light-Warnprofile. | Drag/drop, Hover, Uebergangsgefuehl. |
| Help | fehlender `help_id`, leerer/zu langer Text, Popup ausserhalb Viewport. | fixture-spezifische Sichtbarkeitshinweise. | Lesbarkeit und Timing. |
| Tactical/AirAsset | Contract-Payload fehlt, Snapshot nicht kompakt, Authority-Feld falsch, AirAsset-Loss-Smoke bricht. | Balance-/Fairness-Bewertung. | Full-HD-Mission und LAN-Runde. |
| Truth/UI/Save | bekannte Runtime-Mutationsmuster, Side-Effects, private Snapshot-Felder, Settings-/Download-Bleed. | statische Scan-Listen muessen gepflegt bleiben. | Review neuer Adapter/Panels. |

## Recommended Patch Run

Nach groesseren Tactical-/UI-/Editor-/Multiplayer-Patches:

1. `task_282_tactical_overhaul_playability_performance_help_gate.gd`
2. `task_284_gameplay_truth_architecture_boundary_audit.gd`
3. `task_286_ui_feedback_truth_regression_review.gd`
4. `task_287_editor_save_multiplayer_contract_regression_review.gd`
5. `task_267_contextual_help_coverage_layout_verifier.gd`
6. `task_257_button_reachability_and_interaction_verifier.gd`
7. `task_222_performance_regression_gate_and_manual_profile_checklist.gd`
8. `task_247_used_asset_project_locality_audit_gate.gd`
9. `git diff --check`

## Gap Backlog

| Priority | Gap | Why it matters | Next |
| --- | --- | --- | --- |
| P1 | CommanderIntent normalization warnings. | Unknown verbs/rules can fall back silently. | TASK_289 review/patch. |
| P1 | AirAssetStatus fallback diagnostics. | Unknown states can normalize without visible reason. | TASK_289 review/patch. |
| P2 | Boundary scan token maintenance. | New Runtime APIs need new forbidden tokens. | Add when APIs appear. |
| P2 | Selection/Disabled-Reason coverage for future panels. | Prevents stale UI truth and generic disabled feedback. | Add with panel tasks. |
