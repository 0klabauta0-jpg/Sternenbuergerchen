# TASK_222 - Performance Regression Gate and Manual Profile Checklist

## Ziel
Alle Performance-Pass-Ergebnisse sollen in ein dauerhaft nutzbares Regression-Gate und eine manuelle Godot-Profiling-Checkliste muenden. Danach soll man vor groesseren Gameplay-/Asset-/UI-Patches schnell sehen, ob etwas unschoen geworden ist.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_215 - Performance Deep Pass Baseline and Research
- TASK_216 - 2.5D Rendering Node and Draw Budget Pass
- TASK_217 - Navigation Pathfinding LOS Performance Pass
- TASK_218 - Simulation Combat AI Tick Budget Pass
- TASK_219 - UI HUD Meta Comic Bubble Performance Pass
- TASK_220 - Asset Import VRAM Shader Pipeline Stutter Pass
- TASK_221 - Multiplayer Snapshot Serialization Performance Pass

## Kontext
Einmalige Profiling-Berichte sind nuetzlich, aber sie schuetzen nicht vor Rueckfall. TASK_222 macht daraus ein Gate: Headless schnell, manuell klar, Budgets versioniert und mit Hinweisen, wann ein Budget absichtlich geaendert werden darf.

## Umfang
1. Regression-Gate:
   - TASK_170 erweitern oder neues TASK_222-Gate bauen.
   - Alle Kernbereiche in einem zusammenfassenden Lauf.
   - Klare Fehlertexte mit Messwert, Budget und Szene.
2. Budgetdatei:
   - Lokale Baselines.
   - Breite Projektbudgets.
   - Pro Bereich: render, navigation, simulation, UI, assets, snapshot.
   - Maschinenabhaengige Werte getrennt markieren.
3. Trend-/Reportformat:
   - JSON oder Markdown-Ausgabe fuer letzte Messung.
   - Keine riesigen Logs im Repo erzwingen.
   - Optional lokale Artefakte unter `docs/performance/runs/` nur wenn bewusst gewuenscht.
4. Manuelle Checkliste:
   - Godot Profiler: Script/Physics/Frame.
   - Visual Profiler: gleiche Viewportgroesse, gleiche Szene.
   - Monitors: FPS, memory, object/node count, orphan count.
   - Video RAM Tab.
   - Network Profiler fuer Multiplayer.
   - Stutter-Test fuer erstmalige VFX/Asset-Instanzierung.
5. Warnungs-Gate:
   - RID/ObjectDB/Resource-Leak-Muster aus TASK_170 behalten.
   - Fallback-/Missing-Asset-Zaehler behalten.
6. Pflege-Regeln:
   - Budget nur mit Bericht anheben.
   - Optimierung nur mit Vorher/Nachher.

## Nicht-Ziele
- Keine vollstaendige CI-Infrastruktur, falls nicht vorhanden.
- Kein absoluter FPS-Garant fuer jede Maschine.
- Kein automatischer Ersatz fuer manuelle Visual-Profiler-Laeufe.

## Akzeptanzkriterien
- [x] Ein TASK_222-Gate fasst alle Performance-Bereiche mit klaren Budgets zusammen.
- [x] Budgetdatei trennt lokale Baseline und Projektbudget.
- [x] Manual-Profiler-Checkliste existiert und ist auf Godot 4.6 ausgerichtet.
- [x] Gate blockiert bekannte Leak-/Fallback-Warnungen.
- [x] Gate nennt konkrete Messwerte bei Fehlern.
- [x] Bestehende TASK_170-Pruefung bleibt integriert oder bewusst ersetzt.

## Erwartete Dateien
- `data/performance_budget_contract.json`
- `docs/performance/performance_regression_gate.md`
- `docs/dev/performance_manual_profile_checklist.md`
- `scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd`
- optional `scripts/tests/run_task_222_performance_gate.ps1`
- `docs/tasks/TASK_222_performance_regression_gate_and_manual_profile_checklist.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd`
- [x] `powershell -ExecutionPolicy Bypass -File scripts/tests/run_task_222_performance_gate.ps1`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_170_performance_warning_gate_verifier.gd`
- [ ] Manueller Profiling-Lauf nach Checkliste.
- [x] `git diff --check`

## Risiken
- Zu harte Budgets koennen lokale Entwicklung nerven. Anfangs breit, nach mehreren Laeufen schaerfen.
- Zu weiche Budgets finden keine echten Regressionen. Budgetpflege braucht Disziplin.

## Umsetzung
- `data/performance_budget_contract.json` trennt lokale Baseline, Projektbudgets, Warning-Gate und manuelle Checks.
- `task_222_performance_regression_gate_and_manual_profile_checklist.gd` fasst render, navigation, simulation, UI, assets und snapshot in einem Headless-Gate zusammen.
- `run_task_222_performance_gate.ps1` fuehrt das Gate aus und blockiert echte RID-/ObjectDB-/Resource-Leak-Muster.
- `docs/performance/performance_regression_gate.md` dokumentiert Gate, Budgetpflege und TASK_170-Integration.
- `docs/dev/performance_manual_profile_checklist.md` beschreibt Godot Profiler, Visual Profiler, Monitors, Video RAM, Network Profiler und Stutter-Test.

## Naechster Schritt
Neue groessere Gameplay-/UI-/Asset-Patches sollen den TASK_222-Gate-Lauf als Pflichtpruefung nutzen.
