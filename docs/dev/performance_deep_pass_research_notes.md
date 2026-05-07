# Performance Deep Pass Research Notes

Stand: 2026-05-06

Godot-Version im lokalen Gate-Lauf: `Godot Engine v4.6.2.stable.official.71f334935`

## Aktueller lokaler Anker
`scripts/tests/task_170_performance_warning_gate_verifier.gd` lief lokal gruen:

- Ergebnis: 62 passed, 0 failed.
- Live Primary 3D: `tile_count = 1024`, `asset_model_count = 53`, `unit_model_count = 10`.
- Live Primary 3D: `map_render_duration_msec = 39`.
- Render Spike: `tile_count = 1024`, `asset_model_count = 53`, `map_render_duration_msec = 42`.
- Navigation: `budget_limit = 1`, `new_path_queries_this_tick = 1`, `delayed_this_tick = 2`, `pending_query_count = 2`.
- Open HPA Benchmark: `avg_query_time_usec = 4208.5`.

Diese Werte sind kein finales Performance-Ziel. Sie sind die aktuelle lokale Baseline, gegen die TASK_215 bis TASK_222 erst sauberere Messungen und danach engere Budgets aufbauen.

## Godot-Doku-Abgleich
- Godot empfiehlt, Performance erst ueber Bottlenecks zu messen, statt breit zu optimieren. Fuer CPU ist der eingebaute Profiler der erste Einstieg; fuer enge Stellen koennen `Time.get_ticks_usec()`-Messungen helfen.
- Der Profiler misst Frame Time, Idle Time, Physics Time und Script Functions. Rendering kann in Frame Time als Spike auftauchen, auch wenn Script/Physics unauffaellig wirken.
- Der Visual Profiler ist fuer Rendering-Bottlenecks gedacht und misst CPU-Zeit von Rendering-Aufgaben; Script und Physics gehoeren in den normalen Profiler. Vergleichslaeufe muessen dieselbe Viewportgroesse nutzen.
- `Performance.get_monitor()` kann FPS, Memory, Draw Calls, Navigation-Zaehler und Pipeline-Compilation-Zaehler aus Runtime-Code lesen. Das passt gut fuer Headless-/Smoke-Harnesses.
- In 3D sind Material-/Shader-Wiederverwendung, Draw-Call-Reduktion, transparente Objekte, LOD/Visibility Ranges, Occlusion Culling, Schatten/Lichter und Animation/Skinning wichtige Prueffelder.
- Fuer viele gleiche 3D-Objekte sind automatische Instancing-Pfade oder MultiMesh Kandidaten. MultiMesh ist stark fuer viele identische Instanzen, aber einzelne Instanzen werden nicht separat gefrustum-cullt.
- Shader-/Pipeline-Stutter kann entstehen, wenn Effekte oder Mesh-/Material-Varianten erst im Gameplay auftauchen. Godot 4.4+ kann durch fruehes Instanzieren/Warmup vieler Effekte Pipeline-Stutter abmildern.

## Godot-Forum-Abgleich
Forumshinweise sind keine Projektregeln, aber gute Hypothesen fuer Audits:

- Viele Nodes mit eigenem `_process`, Areas oder Collider koennen schnell teuer werden. Fuer tile-/gridlastige Systeme lohnt sich Daten-/TileMap-/Array-Logik statt tausender aktiver Node-Objekte.
- Node-Lookups wie `$Path` oder `%Name` in sehr grossen Schleifen sind klein, aber messbar. Hotpaths sollten Referenzen cachen und nicht pro Element neu suchen.
- Fuer "was kostet dieser Node?" gibt es keine magische Prozentanzeige pro Node. Praktisch sind Profiler-Script-Functions, Performance-Monitore, gezielte On/Off-Vergleiche und kleine Time-Scope-Messungen.

## TASK_215 Messrahmen
- `scripts/tests/performance_deep_pass_harness.gd` nutzt `Performance.get_monitor()` fuer wiederholbare Headless-Samples und `Time.get_ticks_usec()` fuer Projekt-Hotpaths.
- Die Szenenmatrix besteht aus Homebase, FOB, Live Mission 2.5D und Render Spike. Navigation und Multiplayer-Snapshot laufen als separate Hotpath-Proben.
- Alle aggregierten Harness-Werte liefern `Median`, `P95`, `P99`, `min`, `max` und `count`. Bei wenigen lokalen Samples sind P95/P99 obere Sample-Werte, nicht statistisch belastbare Produktionsperzentile.
- Der manuelle Profiler-/Visual-Profiler-Lauf bleibt bewusst separat, weil Headless-Werte den echten Viewport-/GPU-Eindruck nicht ersetzen.
- TASK_216 bis TASK_222 sollen die hier markierten Beobachtungspunkte einzeln untersuchen, statt pauschal umzubauen.

## Quellen
- Godot Performance overview: https://docs.godotengine.org/en/stable/tutorials/performance/index.html
- Godot CPU optimization: https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html
- Godot Profiler: https://docs.godotengine.org/en/4.4/tutorials/scripting/debug/the_profiler.html
- Godot Debugger/Visual Profiler: https://docs.godotengine.org/en/4.5/tutorials/scripting/debug/debugger_panel.html
- Godot Performance monitors: https://docs.godotengine.org/en/stable/classes/class_performance.html
- Godot 3D optimization: https://docs.godotengine.org/en/4.5/tutorials/performance/optimizing_3d_performance.html
- Godot GPU optimization: https://docs.godotengine.org/en/4.5/tutorials/performance/gpu_optimization.html
- Godot MultiMesh: https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html
- Godot pipeline compilations: https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html
- Godot Forum, many nodes: https://forum.godotengine.org/t/slowdown-with-many-nodes/133487
- Godot Forum, `$`/`%` lookup in loops: https://forum.godotengine.org/t/is-there-any-performance-issue-when-using-and/125733
- Godot Forum, node impact/profiler scope: https://forum.godotengine.org/t/how-to-get-nodes-impact-on-the-performance/69598
