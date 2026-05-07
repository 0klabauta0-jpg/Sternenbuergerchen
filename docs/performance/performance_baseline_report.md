# TASK_215 Performance Baseline Report

Stand: 2026-05-06

## Ziel
Dieser Bericht ist die Messbasis fuer TASK_215 bis TASK_222. Er dokumentiert, was gemessen wird, welche lokalen Startwerte bekannt sind und welche Szenen in Folge-Optimierungen als Vorher/Nachher-Anker dienen.

TASK_215 optimiert bewusst noch nichts. Auffaellige Werte werden nur markiert.

## Lokale Umgebung
- Godot: `Godot Engine v4.6.2.stable.official.71f334935`
- Projektziel laut AGENTS.md: Godot 4.6.1
- OS: Windows, lokale Entwicklerumgebung
- Messart: Headless-Harness plus manueller Profiler-/Visual-Profiler-Folgecheck
- Werte: lokal und maschinenabhaengig, keine globale Projektgarantie

## Testfenster
- Fixed UI FullHD: 1920 x 1080 fuer Homebase, FOB und Drop-Light-Fenster.
- Live Mission 2.5D: 1920 x 1080 als Hauptsicht fuer Mission-Map.
- Optionaler Fillrate-Vergleich: 1280 x 720 fuer manuelle GPU-/Viewport-Vergleiche.

## Szenenmatrix
| Szenario | Pfad | Zweck | Ampel |
|---|---|---|---|
| Homebase | `res://scenes/meta/homebase_test_screen.tscn` | Fixed-UI, Roster, Panels, Flightdeck | beobachten |
| FOB | `res://scenes/meta/fob_test_screen.tscn` | Fixed-UI, Loadout, Flightdeck, Bottom-Actions | beobachten |
| Live Mission 2.5D | `res://scenes/tests/mission_reactivity_test.tscn` | Runtime-Mission, Primary3DView, Units, Overlays | beobachten |
| Render Spike | `res://scenes/tests/mission_map_3d_render_spike.tscn` | 32x32/Renderlast-Anker fuer 2.5D | beobachten |
| Navigation Benchmark | `scripts/tests/navigation_benchmark_harness.gd` | A*/HPA, Cover, Budget, Avoidance | okay |
| Snapshot Roundtrip | `PerformanceDeepPassHarness` | Build/Apply-Zeit und Snapshot-Groesse | okay |

## Bekannte TASK_170-Anker
Diese Werte stammen aus lokalen TASK_170-Gates und werden als Startanker uebernommen. Der letzte TASK_215-Lauf am 2026-05-06 bestaetigte das Gate erneut mit 62/0.

| Metrik | Wert | Ampel |
|---|---:|---|
| TASK_170 Ergebnis | 62 passed / 0 failed | okay |
| Live Primary 3D Tiles | 1024 | beobachten |
| Live Primary 3D Asset Models | 53 | beobachten |
| Live Primary 3D Unit Models | 10 | beobachten |
| Live Primary Render | 36-47 ms lokal beobachtet | beobachten |
| Render Spike Render | 36-45 ms lokal beobachtet | beobachten |
| Navigation Budget Limit | 1 neue Query/Tick | okay |
| Navigation Delayed This Tick | 2 | beobachten |
| Navigation Pending Query Count | 2 | beobachten |
| Open HPA Avg Query | 2625.75-4208.5 usec lokal beobachtet | okay |

## Harness-Metriken
`scripts/tests/performance_deep_pass_harness.gd` erfasst pro Szene wiederholte Runs und speichert:

| Feld | Bedeutung |
|---|---|
| `scene_ready_usec` | Zeit vom Instanziieren bis nach Warteframes/Physics-Frames |
| `node_count` | rekursiver Node-Zaehler der Szene |
| `map_render_duration_msec` | Primary3DView-Renderdauer, falls vorhanden |
| `draw_calls_in_frame` | `Performance.get_monitor()` fuer Draw Calls, falls verfuegbar |
| `monitor_snapshot` | FPS, Frame/Physics, Memory, Object/Node, Render, VRAM, Pipeline-Zaehler |

Jedes Statistikfeld liefert `Median`, `P95`, `P99`, `min`, `max` und `count`. Bei zwei bis drei lokalen Wiederholungen sind P95/P99 konservative obere Sample-Werte, keine belastbare Produktionsverteilung.

## Hotpaths
- 2.5D Map Render: `TerrainMap3DView.get_render_snapshot()` und `map_render_duration_msec`.
- Navigation: `NavigationBenchmarkHarness` fuer A*/HPA, Cover-Aware, Budget-Delay und Avoidance.
- Multiplayer Snapshot: Build-/Apply-Zeit und JSON-Groesse des V1-Snapshots.
- UI Shell: Homebase/FOB-Nodecount und scene-ready samples.

## Manuelle Profiler-Checkliste
1. Godot mit fester 1920 x 1080 Viewportgroesse starten.
2. Homebase, FOB, Live Mission und Render Spike einzeln oeffnen.
3. Normalen Profiler fuer Frame Time, Idle Time, Physics Time und Script Functions laufen lassen.
4. Visual Profiler fuer Live Mission und Render Spike laufen lassen.
5. Auffaellige Spikes mit Screenshot/Notiz festhalten.
6. Pipeline-Compilation-Zaehler beobachten, besonders beim ersten Anzeigen von Units, VFX, Bubbles und Assets.
7. Erst nach wiederholbarem Befund in TASK_216+ optimieren.

## Ampel-Regeln
- Okay: Wert ist stabil, strukturell erwartet oder durch bestehendes Gate abgesichert.
- Beobachten: Wert ist plausibel, aber fuer Folge-Tasks als Optimierungskandidat relevant.
- Optimieren: Wert ist wiederholt hoch, verursacht sichtbare Stalls oder bricht ein Gate.

## Offene Punkte
- Manueller Godot-Profiler-/Visual-Profiler-Lauf steht noch aus.
- Headless-Werte ersetzen keine GPU-/Viewport-Sichtmessung.
- Spaetere TASK_216 bis TASK_222 sollen nur gezielt optimieren, wenn dieser Bericht oder der Harness einen messbaren Engpass zeigt.
