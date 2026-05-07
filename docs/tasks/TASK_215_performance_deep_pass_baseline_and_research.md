# TASK_215 - Performance Deep Pass Baseline and Research

## Ziel
Ein dicker Performance-Pass braucht zuerst eine harte Baseline: aktuelle Godot-Version, feste Testfenster, wiederholbare Szenen, Performance-Monitore, Profiler-Checkliste und ein Forschungsabgleich mit Godot-Doku/Forum.

Dieser Task misst und dokumentiert. Er optimiert noch nichts grob, damit spaetere Tasks echte Vorher/Nachher-Werte haben.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_160 - Tactical Mission Playability Smoke
- TASK_170 - Performance and Warning Budget Gate
- TASK_181 - Drop Light Fixed Window Audit Patch
- TASK_188 - Fireteam Advance Styles Map Readability
- TASK_208 - Enemy Team Tactics Playability Smoke
- TASK_214 - Comic Bubble Feedback Playability Smoke

## Kontext
TASK_170 ist ein gutes kleines Gate, aber noch kein umfassender Performance-Test. Der aktuelle lokale Lauf war gruen mit 62/0, Live-Primary-Render 39 ms, Render-Spike 42 ms und Open-HPA-Benchmark ca. 4208.5 usec. Diese Werte sind Startwerte, keine Zielgarantie.

Godot-Doku und Forum bestaetigen denselben Ansatz: messen, Bottleneck finden, dann gezielt optimieren. Besonders wichtig sind Profiler, Visual Profiler, `Performance.get_monitor()`, konstante Viewportgroessen, Pipeline-Compilation-Zaehler und gezielte Hotpath-Zeitmessung.

## Umfang
1. Baseline-Dokument:
   - Godot-Version.
   - Hardware/OS soweit lokal sinnvoll.
   - Viewportgroessen: 1920x1080 Fixed-UI, Mission 2.5D, optional kleines Fillrate-Vergleichsfenster.
   - Aktuelle TASK_170-Werte uebernehmen.
2. Mess-Harness:
   - Runtime-Messung ueber `Performance.get_monitor()`.
   - `Time.get_ticks_usec()`-Scopes fuer Projekt-Hotpaths.
   - Wiederholungen und Median/P95/P99 statt Einzelwert-Glaskugel.
3. Szenenliste:
   - Homebase.
   - FOB.
   - Live Mission 2.5D.
   - Render-Spike.
   - 32x32 und 64x64 Mission.
   - Enemy/NPC/Bubble stress scenario, sobald die Tasks vorhanden sind.
4. Metriken:
   - Frame ms, physics ms, idle/script ms.
   - FPS, draw calls, object/node count, orphan count.
   - memory/static, VRAM, pipeline compilations.
   - map render duration.
   - path query count/time.
   - snapshot build/apply time and size.
5. Godot-Abgleich:
   - `docs/dev/performance_deep_pass_research_notes.md` aktualisieren.
   - Forumshinweise als Hypothesen markieren, nicht als blinde Regeln.
6. Bericht:
   - `docs/performance/performance_baseline_report.md` mit Ampel: okay, beobachten, optimieren.

## Nicht-Ziele
- Keine Optimierung ohne Messwert.
- Keine CI-Pflicht.
- Kein Renderer-Wechsel.
- Kein grosses Refactoring.

## Akzeptanzkriterien
- [x] Baseline-Bericht mit Godot-Version, Testfenstern, Szenen und aktuellen Messwerten existiert.
- [x] Performance-Harness kann Monitore und Projekt-Hotpaths headless erfassen.
- [x] Mindestens TASK_170, Mission 2.5D, Homebase und FOB sind in der Messmatrix.
- [x] Median/P95/P99 oder vergleichbare Wiederholungswerte werden gespeichert.
- [x] Godot-Doku-/Forum-Abgleich ist dokumentiert.
- [x] Ein TASK_215-Verifier prueft, dass Baseline-Daten strukturell vorhanden und nicht leer sind.

## Erwartete Dateien
- `docs/dev/performance_deep_pass_research_notes.md`
- `docs/performance/performance_baseline_report.md`
- `scripts/tests/performance_deep_pass_harness.gd`
- `scripts/tests/task_215_performance_deep_pass_baseline_and_research.gd`
- `docs/tasks/TASK_215_performance_deep_pass_baseline_and_research.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_215_performance_deep_pass_baseline_and_research.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_170_performance_warning_gate_verifier.gd`
- [ ] Manueller Godot-Profiler/Visual-Profiler-Lauf bei fester Viewportgroesse.
- [x] `git diff --check`

## Umsetzung
- `scripts/tests/performance_deep_pass_harness.gd` misst Homebase, FOB, Live Mission 2.5D, Render Spike, Navigation und Multiplayer-Snapshot-Roundtrip mit wiederholten Samples.
- `docs/performance/performance_baseline_report.md` dokumentiert lokale Umgebung, Testfenster, Szenenmatrix, TASK_170-Anker, Harness-Metriken und manuelle Profiler-Checkliste.
- `docs/dev/performance_deep_pass_research_notes.md` enthaelt den Godot-Doku-/Forum-Abgleich und markiert Forumshinweise als Hypothesen.

## Risiken
- Performancewerte sind maschinenabhaengig. Der Bericht muss lokale Werte klar von Projektbudgets trennen.
- Zu fruehe Optimierung kann gute Architektur verschlechtern. Erst messen.

## Naechster Schritt
Nach TASK_215 kann TASK_216 gezielt den 2.5D-Renderingpfad untersuchen.
