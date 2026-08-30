# TASK_1187 - Tactical Map Frame Budget

## Ziel

Dieser Task führt einen separaten, zunächst ausschließlich messenden
Tactical-Map-Vertrag ein. Die Messung verändert weder Gameplay- noch UI-Wahrheit
und lässt rote Budgets als Befund stehen.

## Messvertrag

- `grid_sweep`: Prozess-Frame-Samples aus dem echten Tactical-Scene-Graph;
  der Harness protokolliert die tatsächlich aktive Unit-Zahl.
- Active-movement: mindestens 600 Simulation- und Combat-Ticks über die
  bestehende 16v12-Referenzfixture.
- Jeder Process-Lauf sammelt mindestens 3.600 Frames und 60 Sekunden
  Wandzeit. Conditional Scopes enthalten einen Invocation Counter, damit ein
  nicht aufgerufener Scope keine Quantile vortäuscht.
- Ausgabe ist eine kanonische JSON-Zeile mit Git-SHA, Godot-Version,
  Maschinenprofil, Samplezahlen, Quantilen, Maxima und Budgetstatus.

## Ausführung

```powershell
pwsh -NoProfile -File scripts/tests/run_task_1187_tactical_map_frame_budget.ps1 -Mode Measure -ColdRuns 3 -WarmRuns 5
```

Die bekannte Baseline gilt für Ryzen 7 7800X3D, 64 GB RAM, Windows 10 19045
und Godot 4.6.2. GPU-Werte bleiben im Headless-Harness absichtlich leer und
werden nur durch ein separates Fensterprofil belegt.

## Verifizierte Baseline

- Finaler Serienlauf auf `72ac241651ced0ec8ee1174a2e9d03aa67755327`: 3 Kalt-
  plus 5 Warmstarts ohne Harness- oder Contract-Fehler, nach der
  SimulationRoot- und Combat-Posture-Autoritaetsumstellung.
- Der reale `grid_sweep`-Lauf hatte 11 aktive Runtime-Units, mindestens 600
  Physik-Ticks je Fixture und 6.075 gemessene Process-Frames im letzten
  Warmstart.
- Die roten Baseline-Budgets bleiben absichtlich sichtbar: Simulation/Combat,
  FoW, Proxy-Sync und LZ-Eingabe. Sie sind die Ausgangswerte für die
  nachfolgenden Hotpath-Tasks, nicht die Bedingung für einen grünen
  Harness-Vertrag. Im letzten Warmstart lag der Proxy-Sync bei 3,815 ms p95
  und 5,466 ms p99; damit ist er ein eng abgegrenzter, reproduzierbar
  vermessener Startpunkt für TASK_1188.
