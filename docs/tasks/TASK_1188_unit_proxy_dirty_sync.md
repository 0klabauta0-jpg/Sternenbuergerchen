# TASK_1188 - Unit Proxy Dirty Sync

## Ziel

Die taktische 3D-Map aktualisiert Unit-Proxies revision-getrieben. Statische
Node-Referenzen werden beim Proxy-Bau oder Modellwechsel gecacht; FireEvents
und sichtbare Kontakte werden je Payload-Revision indexiert. Darstellung bleibt
eine reine Leseschicht und erzeugt keine Gameplay-Wahrheit.

## Akzeptanz

- Zehn Proxies behalten durch Idle, Bewegung, Fire/Aim, Vitalwechsel,
  FOW-hide/show und einen Modellwechsel ihre eindeutige Proxy-Identitaet.
- Ohne neue Revision entstehen weder Proxy- noch Badge-Neubauten; rekursive
  Node-Suchen passieren nur beim Cache-Aufbau oder bei seiner Invalidierung.
- FireEvent- und Kontakt-Index werden nicht pro Unit und Frame linear gesucht.
- Der anschliessende TASK_1187-Serienlauf bewertet den echten `grid_sweep`-
  Hotpath weiter gegen p95 <= 3 ms und p99 <= 5 ms fuer den Proxy-Sync;
  28 Units duerfen p99 <= 8 ms nicht uebersteigen.

## Architekturgrenzen

### Review 2026-11-03: unabhaengige Badge-Revision
Badge-Text, Farbe, Stil, Declutter-Unterdrueckung und Proxy-Sichtbarkeit werden
unabhaengig vom Waffen-/Vital-Payload gecacht. Kontakt, Runtime-Command/Status,
Overwatch-Shot-Readiness und Respawnsekunden muessen im normalen naechsten
Visual-Sync den vorhandenen Badge aktualisieren und ein Viewport-Redraw anfordern.
Reine Badge-Revisionen loesen weder Aim-/Skeleton-/Vitalarbeit noch Modell- oder
Label-Neubauten aus. Verifier: `review46_20261103_unit_badge_verifier.gd`.

- `TerrainMap3DView` liest Unit-, Runtime-, FOW- und Order-Payloads. Es
  mutiert keine Commands, Units, Combat- oder Missionszustand.
- Der Runtime-Cache gehoert nur zur Visualinstanz und wird beim Proxy-Abbau
  geloescht. Er ist keine zweite Registry oder Gameplay-Autoritaet.
- FOW-Updates duerfen Sichtbarkeit aendern, aber keine Unit-Proxies wegen
  einer reinen Sichtrevision neu erzeugen.

## Verifikation

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1188_unit_proxy_dirty_sync.gd
pwsh -NoProfile -File scripts/tests/run_task_1187_tactical_map_frame_budget.ps1 -Mode Measure -ColdRuns 3 -WarmRuns 5
git diff --check
```

Ergebnis auf dem lokalen Ryzen-7-7800X3D-Baselineprofil:

- Der Taskverifier bestand mit 31/31 Assertions. Er deckt zehn Proxies fuer
  Revisionen, Events, Vitalstatus, FOW und Modellwechsel ab und misst zusaetzlich
  28 Proxies fuer mindestens 3.600 Frames und 60 Sekunden.
- Die TASK_1187-Vollserie mit drei Kalt- und fuenf Warmlauefen bestand fuer den
  echten `grid_sweep`-Proxy-Hotpath in 8/8 Laeufen: p95 2.265-2.806 ms bei
  einer Grenze von 3 ms sowie p99 2.763-3.314 ms bei einer Grenze von 5 ms.
- Der finale 28-Proxies-Skalierungslauf sammelte 8.695 Frames in 60.005 Sekunden
  und erreichte p99 5.003 ms bei einer Grenze von 8 ms.
- Die bekannten invaliden Homebase-UID-Warnungen traten weiterhin auf; neue
  Scriptfehler oder Harness-Fehler traten nicht auf.
