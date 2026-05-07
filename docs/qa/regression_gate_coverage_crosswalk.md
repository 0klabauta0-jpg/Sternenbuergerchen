# Regression Gate Coverage Crosswalk

TASK_288 ordnet die kritischen Risikoflaechen den vorhandenen automatischen Gates, Reports und bewussten manuellen Restchecks zu. Ein Risiko darf nur dann rein manuell bleiben, wenn der relevante Befund Sicht-, Audio-, LAN- oder Spielgefuehl braucht.

## Gate Quality Legend

| Begriff | Bedeutung |
| --- | --- |
| Hard failure | Der Verifier oder Runner endet mit Exit-Code 1 und blockt den Task. |
| Warning-only | Das Gate erzeugt Diagnose/Warnung, aber ein Mensch muss die Relevanz bewerten. |
| Manual rest | Sicht-, Audio-, LAN-, Drag-/Drop- oder Balance-Pruefung, die headless nicht verlaesslich ist. |
| Patch backlog | Kleine, priorisierte Folgearbeit fuer TASK_289 oder spaeter. |

## Coverage Crosswalk

| Risk ID | Risiko | Severity | Automated Gate/Test | Hard failure vs warning | Report/Doc | Manual rest | Gap/Patch |
| --- | --- | --- | --- | --- | --- | --- | --- |
| perf_budget | Render-, Navigation-, Simulation-, UI-, Asset- oder Snapshot-Budget driftet. | High | `res://scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd`; `res://scripts/tests/run_task_222_performance_gate.ps1` | Hard failure fuer Budget- und Leak-Pattern; machine-dependent Baselines sind dokumentiert. | `res://docs/performance/performance_regression_gate.md`; `res://data/performance_budget_contract.json` | Profiler-/VRAM-/Stutter-Sichtcheck nach `res://docs/dev/performance_manual_profile_checklist.md`. | Kein TASK_288-Patch; Budget-Tuning bleibt eigener Task. |
| asset_locality | Runtime oder Katalog referenziert lokale User-/Source-Pfade statt Projektassets. | High | `res://scripts/tests/task_247_used_asset_project_locality_audit_gate.gd`; `res://scripts/tests/run_task_247_asset_locality_scan.ps1` | Hard failure fuer Runtime-Offender und unaufloesbare `res://`-Pfade; Docs/Import-Source-Notes werden getrennt. | `res://docs/reviews/used_asset_project_locality_audit.md` | Keine manuelle Wiederholung noetig, nur sichtbarer Asset-Smoke bei neuen Imports. | Kein TASK_288-Patch. |
| playability_routes | Buttons, feste Fenster, Cross-Screen-State oder Basisrouten werden unbenutzbar. | High | `res://scripts/tests/task_262_playability_regression_gate_and_manual_open_items.gd`; `res://scripts/tests/task_257_button_reachability_and_interaction_verifier.gd`; `res://scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd` | Hard failure fuer fehlende/unerreichbare Controls, falsche Rechtegruende, Clipping-/Scrollbar-Vertrag und Stateverlust. | `res://docs/reports/playability_regression_gate_report.md`; `res://docs/qa/playability_coverage_matrix.md` | Drag-and-drop feel, Hover, echte Uebergaenge nach `res://docs/manual_checks/playability_manual_open_items.md`. | Kein TASK_288-Patch. |
| help_coverage | Help-ID fehlt, Help-Text ist leer/zu lang oder Popups laufen aus dem Viewport. | High | `res://scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd`; `res://scripts/tests/task_268_post_help_popup_playability_regression_smoke.gd` | Hard failure fuer Catalog/Form/Layout/Timing; bekannte fixture-spezifische Sichtbarkeitswarnungen bleiben Warning-only. | `res://docs/reports/contextual_help_coverage_layout_report.md`; `res://docs/reports/post_help_popup_playability_regression_report.md` | Lesbarkeit und Timing-Gefuehl nach `res://docs/manual_checks/post_help_popup_manual_readability_checklist.md`. | Kein TASK_288-Patch. |
| tactical_e2e | CommanderIntent, FTL-Plan, TacticalRules, Breakout, Communication oder AirAssetStatus fallen auseinander. | High | `res://scripts/tests/task_282_tactical_overhaul_playability_performance_help_gate.gd`; `res://scripts/tests/task_279_lz_security_air_asset_tactical_playability_smoke.gd`; `res://scripts/tests/task_281_tactical_command_multiplayer_authority_snapshot.gd` | Hard failure fuer Contract-Payload, Dedupe, Snapshot-Kompaktheit, Help-Anker und Authority-Felder. | `res://docs/reports/tactical_overhaul_playability_performance_help_gate.md`; `res://docs/manual_checks/tactical_overhaul_manual_playability_checklist.md` | Full-HD-Mission, AirAsset-Fairness, Balance und echte LAN-Runde bleiben manuell. | P1 in TASK_289: Diagnosefelder fuer CommanderIntent-/AirAssetStatus-Fallbacks pruefen und ggf. patchen. |
| multiplayer_authority | Client setzt Tactical-/AirAsset-State direkt oder Role/Team-Ownership wird umgangen. | High | `res://scripts/tests/task_281_tactical_command_multiplayer_authority_snapshot.gd`; `res://scripts/tests/task_287_editor_save_multiplayer_contract_regression_review.gd`; `res://scripts/tests/task_228_multiplayer_editor_map_manifest_download_consent.gd` | Hard failure fuer State-Mutation-Keys, Host-only Role Override, LZ-from-editor, Snapshot-Apply-Side-Effects und Download-Consent. | `res://docs/dev/tactical_multiplayer_authority_snapshot.md`; `res://docs/dev/multiplayer_editor_map_transfer_contract.md` | Realer Zwei-Instanzen-LAN-Smoke bleibt manuell. | Kein TASK_288-Patch; TASK_289 kann LAN-Checklist priorisieren. |
| gameplay_truth | UI, Meta, Editor oder Visualizer schreibt Gameplay-Wahrheit direkt. | High | `res://scripts/tests/task_284_gameplay_truth_architecture_boundary_audit.gd`; `res://scripts/tests/run_task_284_truth_boundary_scan.ps1`; `res://scripts/tests/task_286_ui_feedback_truth_regression_review.gd` | Hard failure fuer bekannte Runtime-Mutationsmuster und Snapshot-/Help-/Bubble-Side-Effects; Warning-only: statische Suche kann neue Muster nur finden, wenn Tokens gepflegt werden. | `res://docs/reviews/gameplay_truth_architecture_boundary_audit.md`; `res://docs/reviews/ui_feedback_truth_regression_review.md` | Manual rest: Code-Review fuer neue Runtime-Adapter bleibt noetig. | P2: Forbidden-token-Liste bei neuen Runtime-APIs pflegen. |
| ui_feedback_truth | Selection, Disabled-Reasons, Bubble-Cooldowns oder Character/Loadout-Displays werden zu eigener Wahrheit. | High | `res://scripts/tests/task_286_ui_feedback_truth_regression_review.gd`; `res://scripts/tests/task_257_button_reachability_and_interaction_verifier.gd`; `res://scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd` | Hard failure fuer Selection-Snapshot-Abgleich, Visual-only Payload-Filter, no-SimulationRoot-Side-Effects und konkrete disabled reasons. | `res://docs/reviews/ui_feedback_truth_regression_review.md`; `res://docs/reports/playability_button_reachability_report.md` | Sicht- und Lesbarkeitsgefuehl bleibt manuell. | P2: Neue UI-Panels muessen Selection/Disabled-Reason in diesen Gate aufnehmen. |
| editor_save_multiplayer | Scenario-Authoring, Roster-Save, Settings, AirAssetMeta, Snapshot oder Downloaded-Map-Payload vermischen ihre Lebensdauer. | High | `res://scripts/tests/task_287_editor_save_multiplayer_contract_regression_review.gd`; `res://scripts/tests/task_240_multiplayer_player_roster_ownership_contract.gd`; `res://scripts/tests/task_228_multiplayer_editor_map_manifest_download_consent.gd` | Hard failure fuer LZ-/Runtime-Bleed, Settings-Unknown-Keys, private Snapshot-Felder, Client-State-Mutation, unsafe Download-Payloads. | `res://docs/reviews/editor_save_multiplayer_contract_regression_review.md`; `res://docs/dev/player_roster_save_contract.md`; `res://docs/dev/multiplayer_player_roster_ownership_contract.md` | Keine manuelle Wiederholung noetig, ausser sichtbarer Editor-/Lobby-Smoke. | Kein TASK_288-Patch. |
| docs_truth | Roadmap, Task-Status, Reports oder Dev-Dokumente widersprechen dem implementierten Stand. | Medium | `res://scripts/tests/task_283_post_tactical_docs_consistency_audit.gd`; `res://scripts/tests/task_288_regression_gate_coverage_gap_audit.gd` | Hard failure fuer Status-/Roadmap-/Link-/Begriffsdrift. | `res://docs/reviews/post_tactical_docs_consistency_audit.md`; `res://docs/reviews/regression_gate_coverage_gap_audit.md` | Kein manueller Rest ausser Review neuer Texte. | Kein TASK_288-Patch. |

## Post Tactical Patch Run List

Nach jedem groesseren Tactical-, UI-, Asset-, Editor/Save- oder Multiplayer-Patch sollte mindestens dieser Satz laufen:

1. `godot_console.exe --headless --path . --script scripts/tests/task_282_tactical_overhaul_playability_performance_help_gate.gd`
2. `godot_console.exe --headless --path . --script scripts/tests/task_284_gameplay_truth_architecture_boundary_audit.gd`
3. `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
4. `godot_console.exe --headless --path . --script scripts/tests/task_287_editor_save_multiplayer_contract_regression_review.gd`
5. `godot_console.exe --headless --path . --script scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd`
6. `godot_console.exe --headless --path . --script scripts/tests/task_257_button_reachability_and_interaction_verifier.gd`
7. `godot_console.exe --headless --path . --script scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd`
8. `godot_console.exe --headless --path . --script scripts/tests/task_247_used_asset_project_locality_audit_gate.gd`
9. `git diff --check`

## Patch Backlog

| Priority | Backlog item | Reason | Suggested owner task |
| --- | --- | --- | --- |
| P1 | CommanderIntent normalization warnings als echte Payload-Diagnose pruefen und ggf. patchen. | TASK_285 fand Fallbacks ohne eigene Diagnose; Risiko fuer still ersetzte Befehle. | TASK_289 |
| P1 | AirAssetStatus-State-Fallback diagnostizieren. | TASK_285 fand Fallback ohne sichtbare Warnung; Risiko fuer still korrigierte Statusdaten. | TASK_289 |
| P2 | Forbidden-token-Listen fuer Truth-/UI-Boundary-Gates bei neuen Runtime-APIs nachziehen. | Statische Scans schuetzen nur bekannte Mutationspfade. | Folgepatch |
| P2 | Neue UI-Panels automatisch an Selection-/Disabled-Reason-Gates anbinden. | Verhindert stale Selection und generische Disabled-Gruende. | Folgepatch |
