# TASK_786 - Station Reentry Firefight Host Client Polished Surface Check

## Ziel / Problem
TASK_785 kann sichtbare Findings zur polierten Command-Surface sammeln. Als Multiplayer-naechster Schritt muss geprueft werden, ob Host und Client dieselbe polierte Surface lesen, ohne Peer-/Team-Kontext zu vermischen.

## Sinnhaftigkeit / Ursache
Die Firefight-Command-Surface ist nur hilfreich, wenn beide Fenster dieselbe naechste Entscheidung zeigen: Interaction-Line, Primary-Lane, Quick-Action-Rail, Guard-Line, Summary-Line, No-Auto-Command und Existing-Buttons muessen gleich bleiben. Gleichzeitig duerfen Host und Client nicht wie ein kopierter Single-Peer-Snapshot wirken.

## Umfang
- Neuer read-only Service `StationReentryFirefightHostClientPolishedSurfaceCheck`.
- Vergleich zweier TASK_785-Snapshots als Host-/Client-Views.
- Pruefung von:
  - TASK_785-Quellen bereit und read-only
  - Style-ID
  - Surface-Reihenfolge
  - Interaction-Line
  - Primary-Action-Label
  - Quick-Action-Labels
  - Guard-Line
  - Summary-Line
  - No-Auto-Command und Existing-Commands-only
  - getrenntem Peer-Kontext und vorhandenem Team-Kontext
  - kleinem Textbudget
- Manifestpfad `tmp/station_reentry_firefight_host_client_polished_surface_check.json`.
- Status, Roadmap, Contract und HTML-Handbuch auf TASK_786 aktualisieren.

## Nicht-Ziele
- Kein echter Netzwerktransport.
- Kein neues Command-UI-System.
- Kein automatischer Screenshot- oder Sichtentscheid.
- Keine Navigation, Commands, FireEvents, DamageEvents oder Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_785_station_reentry_firefight_command_surface_visible_findings_refresh.md`
- `docs/tasks/TASK_770_station_reentry_host_client_next_order_sync.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Der Snapshot nutzt Schema `sternenbuergerchen.station_reentry_firefight_host_client_polished_surface_check.v1`.
- Nicht bereite oder nicht read-only TASK_785-Quellen blockieren.
- Gleiche Host-/Client-Surface passiert den Gate.
- Unterschiede in Quick-Actions, Summary, Guard-Line oder Style-ID werden als `needs_host_client_polished_surface_alignment` gemeldet.
- Peer- und Team-Kontext bleiben getrennt und vorhanden.
- Der Snapshot bleibt read-only und erzeugt keine Gameplay-Mutation.
- Ein sauberer Check routet zu TASK_787 - Station Reentry Firefight Player Decision Readability Pass.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_host_client_polished_surface_check.gd`
- `scripts/tests/task_786_station_reentry_firefight_host_client_polished_surface_check.gd`
- `docs/tasks/TASK_786_station_reentry_firefight_host_client_polished_surface_check.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_786_station_reentry_firefight_host_client_polished_surface_check.gd`
- Regression: TASK_785, TASK_784, TASK_770
- Reentry-Block TASK_769 bis TASK_786
- `git diff --check`

## Risiken / offene Punkte
TASK_786 ist ein Contract-/Verifier-Schritt, kein echter Fensterlauf. Ohne echte manuelle Sichtdaten aus TASK_785 bleibt der Check blockiert. Der naechste sinnvolle Schritt ist TASK_787, der die naechste Spielerentscheidung nach der synchronen polierten Surface verdichtet.
