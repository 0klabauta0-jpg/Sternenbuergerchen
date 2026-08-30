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
