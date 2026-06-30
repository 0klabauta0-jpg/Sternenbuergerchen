# TASK_715 - Station Route Empty Event Log Polish

## Ziel / Problem
Der echte Zwei-Fenster-Capture nach TASK_714 zeigt, dass Host/Client-Identitaet und Station sichtbar sind, aber das leere Event-Log als grosse dunkle Flaeche unten links die Karte ueberdeckt. Wenn keine Events vorhanden sind, hilft diese Flaeche dem Spieler nicht und verschlechtert Lesbarkeit und Bediengefuehl.

## Sinnhaftigkeit / Ursache
Der Spielerblick ist jetzt der Engpass. Der technische Multiplayer-Guard ist gruen, also sollte die sichtbare Mission weniger UI-Reibung erzeugen. Ein leeres Event-Log darf keine Kartenflaeche und keinen Mausinput fressen.

## Umfang
- `TacticalEventLogPanel` klappt im leeren Zustand visuell ein.
- Im leeren Zustand ist das Panel fuer Mausinput durchlaessig.
- Sobald Events vorhanden sind, wird das Panel wieder sichtbar und nutzt den bestehenden Scroll-/Filterpfad.
- Snapshot-Felder dokumentieren `empty_state_collapsed`, `visibility_mode`, `visible` und `mouse_filter`.
- Neuer Verifier fuer Standalone-Panel und Mission-Testszene.
- Status, Roadmap, Contract und HTML-Handbuch-Refresh werden aktualisiert.

## Nicht-Ziele
- Kein neues Event-Log-Datenmodell.
- Keine Aenderung an TacticalEventLog-Inhalten oder Event-Erzeugung.
- Keine Aenderung an Gameplay-State, Multiplayer-State oder SimulationRoot.
- Kein Ersatz fuer den echten Door/Computer/Cargo-Klicklauf.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_714_station_route_multiplayer_scenario_guard.md`
- `docs/tasks/TASK_712_station_route_host_client_acceptance_packet.md`
- `docs/tasks/TASK_366_tactical_event_log_hud_panel.md`

## Akzeptanzkriterien
- Leeres Event-Log meldet `empty_state_collapsed = true`.
- Leeres Event-Log ist nicht sichtbar und setzt `mouse_filter = MOUSE_FILTER_IGNORE`.
- Mit Events klappt das Panel wieder auf und rendert Eintraege.
- Der bestehende Event-Log-Scrollpfad bleibt intakt.
- Mission-Initialzustand hat keine sichtbare leere Event-Log-Flaeche.
- Snapshot bleibt UI-lesend und setzt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/ui/tactical_event_log_panel.gd`
- `scripts/tests/task_715_station_route_empty_eventlog_polish.gd`
- `docs/tasks/TASK_715_station_route_empty_eventlog_polish.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_715_station_route_empty_eventlog_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_366_tactical_event_log_hud_panel.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_714_station_route_multiplayer_scenario_guard.gd`
- `git diff --check`

## Risiken / offene Punkte
Das Event-Log ist bei leerem Zustand bewusst nicht sichtbar. Wenn spaeter gewuenscht ist, immer einen kleinen Log-Anker zu zeigen, sollte das als separater UI-Designschritt mit echtem Fensterbild entschieden werden.
