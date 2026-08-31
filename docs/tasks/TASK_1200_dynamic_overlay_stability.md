# TASK_1200 - Dynamic Overlay Stability

## Ziel / Problem

`terrain.dynamic_overlay_usec` soll im echten TASK-1187-Harness in acht von
acht Laeufen einen p99 von hoechstens 1.000 usec erreichen. Der periodische
Dynamic-Order-Pfad darf bei unveraenderten Quellen weder die Signatur neu
zusammensetzen noch Order-Visuals neu aufbauen.

## Ursache / Sinnhaftigkeit

`TerrainMap3DView._refresh_dynamic_order_visuals_if_needed()` prueft derzeit
periodisch eine neu zusammengesetzte Signatur. Dabei werden auch bei nur vier
relevanten Units alle `_unit_nodes` betrachtet. Der unmittelbar davor laufende
Proxy-Sync kennt relevante Positions-, Rotations-, Sicht- und Proxy-Aenderungen
bereits und kann einen rein abgeleiteten Renderindex gezielt invalidieren.

## Umfang und Nicht-Ziele

- Read-only Relevanzindex aus der sortierten Union der ausgewaehlten und der
  Orientation-Fireteam-IDs.
- Dirty-getriebener Dynamic-Order-Refresh mit Diagnosezaehlern fuer
  Signaturaufbau, Unit-Scans, Rebuilds und Skips.
- Unveraenderte Darstellung fuer Order, Fire Sector, LOS, Contacts und FoW.
- Keine Gameplay-, SimulationRoot-, Command-, Snapshot- oder
  Multiplayer-Wahrheit im Renderer.
- Keine Budgetanhebung und keine menschliche TASK-1193-Evidence.

## Relevante Contracts / Dokumente

- `docs/tasks/TASK_1187_tactical_map_frame_budget.md`
- `docs/tasks/TASK_1188_unit_proxy_dirty_sync.md`
- `docs/tasks/TASK_225_fog_of_war_2_5d_visual_overlay_and_contacts.md`
- `docs/tasks/TASK_364_mission_fireteam_orientation_indicators.md`
- `docs/tasks/TASK_371_fire_sector_security_arc_overlay_toggle.md`

## Akzeptanzkriterien

- Eine 28-Unit-Fixture indexiert exakt die vier Units aus ausgewaehlten oder
  Orientation-Fireteams fuer den Dynamic-Signaturpfad.
- Nach dem ersten Aufbau erzeugen 120 stabile Frames weder einen weiteren
  Signaturaufbau noch einen Order-Rebuild.
- Eine relevante Unit-Bewegung erzeugt genau einen geaenderten Zustand und
  einen Rebuild; eine irrelevante Unit-Bewegung erzeugt keinen sichtbaren
  Rebuild.
- Fire-Sector-, LOS-/Contact-, Orientation-, FoW- und Proxy-Vertraege bleiben
  gruen.
- `terrain.dynamic_overlay_usec` liegt in 8/8 SHA-identischen TASK-1187-Laeufen
  bei p99 hoechstens 1.000 usec.

## Betroffene Dateien

- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_1200_dynamic_overlay_stability.gd`
- `scripts/tests/tactical_map_frame_budget_harness.gd` nur falls fuer
  Diagnosezaehler erforderlich
- `docs/tasks/TASK_1200_dynamic_overlay_stability.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- TASK-1200-Verifier mit 28 Units und vier relevanten Units.
- TASK-1188, TASK-225 und TASK-1157.
- Ein kalter TASK-1187-Lauf; bei Budgetpass eine serielle 3-kalt/5-warm-Serie.
- `git diff --check`.

## Risiken / offene Punkte

Ein zu enger Index koennte visuelle Eingaben uebersehen. Deshalb bleiben
Selection, Fire-Sector-Modus, LOS-/Contact-Revision, sichtbare Unit-Position
und -Rotation sowie Live-Orientation Teil des Signaturvertrags. Ein visueller
Full-HD-Sichtcheck ist nur Zusatz und ersetzt nicht die spaetere menschliche
TASK-1193-Evidence.

## Abschluss-Evidence

- Produktions-/Mess-SHA: `d319e3c2b268ca900fd65da8e17c3bbb137c9e59`; Basis: `9027f2a97793a53d3af2f9936f3496de291c50d9`.
- Umgebung: Godot 4.6.2 official, Ryzen 7 7800X3D, 64 GB RAM, Windows 10 19045.
- Verifikation: TASK-1200 44/44, TASK-1188 31/31, TASK-225 34/34, TASK-1157 35/35 und `git diff --check` gruen. TASK-1188 Proxy-Sync p99 `5380 usec <= 8 ms`.
- Cold-Control: 6247 Frames / 165077 ms; Dynamic p99 `3 usec`, Maximum `79 usec`.
- Offizielle 3-cold/5-warm-Serie: Frames `[5782,5814,5704,5757,5855,5791,5887,5922]`, Dauer `[164907,166448,167907,164181,163399,163912,163550,162323]` ms, Dynamic p99 `[3,3,3,3,3,3,3,3]` usec, Maximum `[209,208,372,44,28,50,43,12]` usec; Status 8/8 PASS, p99-Range `3-3`, Maximum-Range `12-372` usec.
- Proxy p95 `[3247,3231,3243,3236,3200,3312,3161,3099]` und p99 `[3774,3834,3720,3678,3760,3795,3638,3544]` usec bleiben getrennt; p95 liegt in 8/8 ueber 3 ms, p99 unter 5 ms. FoW p99 `[2073,2047,2286,2766,2198,2447,2149,2411]` usec liegt in 8/8 Laeufen ueber 2 ms; das ist echter P06-Reparaturbedarf, kein `VERIFIED_NO_CODE`.
- Ein erster Cold-Versuch ohne JSON mit transientem native exit `-1` bei gleichzeitigem fremdem Godot-Lauf wurde verworfen; Fast-Diagnose, Full-Control und Vollserie waren danach gruen.
- FullHD-Zusatz-Smoke: D3D12/RTX4070TiSUPER, PNG 1920x1080, Fire enabled count 5, LOS enabled line count 5, selected/order marker count 48; keine offensichtliche Blank-/Clipping-/Linienregression. Windows-Capture API `0x80004002`, daher repo-native Viewport-Capture; dies ist ausdruecklich keine TASK-1193-Manuell-Evidence.
- Architektur: abgeleiteter sortierter eindeutiger Index, Dirty-Refresh, genau ein relevanter Single-Pass und bewahrte Live-Orientation-Schwerpunkt-/erste-Richtung-Semantik; keine Gameplay-Truth. Release bleibt blockiert. Naechster Schritt: TASK-1201 P06.
