# TASK_222 Performance Regression Gate

Stand: 2026-05-06

## Ziel
TASK_222 fasst die Deep-Pass-Ergebnisse in ein lokales Regression-Gate zusammen. Das Gate ist bewusst breit gestartet: Es soll klare Rueckfaelle finden, ohne jede kleine lokale Abweichung zu blockieren.

## Budgetvertrag
`data/performance_budget_contract.json` trennt:

- `local_baseline`: lokale, maschinenabhaengige Reports und Messumgebung.
- `project_budget`: breite Grenzwerte fuer render, navigation, simulation, UI, assets und snapshot.
- `warning_gate`: bekannte RID-/ObjectDB-/Resource-Leak-Muster und Missing-/Fallback-Zaehler.
- `manual_checks`: manuelle Godot 4.6 Profiling-Werkzeuge.

Budgets werden nur mit Bericht angehoben. Optimierungen sollen Vorher/Nachher-Werte nennen.

## Headless Gate
`scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd` prueft:

- render: Render-Spike, `map_render_duration_msec`, Missing-/Fallback-Zaehler und Pipeline-Snapshot.
- navigation: Query-, LOS-, Cover- und Budget-Delay-Metriken.
- simulation: SimulationRoot- und CombatLoop-P99 plus Scope-Timings und Hotpath-Audit.
- UI: Fixed Window, Node-Zaehler, Bubble-Cap und Theme-Reuse.
- assets: Katalogbreite, `res://`-Grenzen, Ladbarkeit, VRAM-Schaetzung, GLB-Groesse und Warmup.
- snapshot: Build-/Apply-Zeit, JSON-Groesse, deterministische Sortierung, ID-only Payload und side-effect-freies Apply.

Der PowerShell-Wrapper `scripts/tests/run_task_222_performance_gate.ps1` blockiert zusaetzlich bekannte Leak-/Warning-Muster in der Godot-Ausgabe.

## TASK_170 Integration
TASK_170 bleibt als eigenes Warning-/Render-Gate erhalten und wird nicht ersetzt. TASK_222 referenziert die gleichen Leak-Muster und die Missing-/Fallback-Nullgrenze, laeuft aber breiter ueber alle Deep-Pass-Bereiche.

## Fehlertexte
Budget-Fehler nennen Messwert, Budget und Bereich, z. B. `Snapshot large_96_units JSON p99 bytes value ... <= budget ...`.

## Manuell Offen
Headless bleibt strukturell. Godot Profiler, Visual Profiler, Video RAM und Network Profiler muessen fuer sichtbare Stutter, GPU-Kosten und echte Host/Client-Netzwerkdaten manuell nach `docs/dev/performance_manual_profile_checklist.md` laufen.
