# TASK_774 - Station Reentry Next Playable Slice Acceptance

## Ziel / Problem
Nach TASK_773 ist der sichtbare Reentry-Host/Client-Pfad technisch und visuell deutlich stabiler. Es fehlt jetzt eine enge Entscheidung: Ist dieser kleine Reentry-Slice gut genug, um als naechster spielbarer Schritt weitergefuehrt zu werden, oder muss er zurueck in gezielten Polish?

## Sinnhaftigkeit / Ursache
Die letzten Tasks haben Preview, Performance-Gefuehl, Host/Client-Sync, sichtbaren Export und Fireteam-Identity-Cues einzeln gehaertet. Ohne Acceptance-Schicht bleiben wir in Findings-/Polish-Schleifen. Das Spiel soll aber wieder in Richtung angenehm spielbarer Zustand kommen; deshalb braucht der Slice eine klare, eng begrenzte Abnahme.

## Umfang
- Read-only Acceptance-Helper fuer den Station-Reentry-Slice.
- Bewertung der aktuellen Gates:
  - erste Mission-Preview vor `GO`
  - Performance-Feel-Gate
  - Host/Client-Next-Order-/Route-/Cue-Sync
  - TASK_772-Findings bereit fuer naechste Iteration
  - TASK_773-Fireteam-Identity-Cue vorhanden
  - echter Zwei-Fenster-Re-Capture geschrieben
- Status unterscheidet blockiert, braucht Re-Capture/Polish oder eng akzeptiert.
- HTML-Iststand/Handbuch, Roadmap, Status und Contract werden aktualisiert.

## Nicht-Ziele
- Keine Gesamtspiel-Abnahme.
- Kein neuer Gameplay-State.
- Keine neue Multiplayer-Authority.
- Keine Command-, Movement-, Combat- oder Navigation-Mutation.
- Keine Behauptung, dass ein menschlicher Langzeit-Playtest abgeschlossen ist.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_773_station_reentry_host_client_identity_cue_polish.md`
- `docs/tasks/TASK_772_station_reentry_host_client_export_findings.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Ohne gruene Preview-/Performance-/Sync-/Findings-/Identity-Cue-Gates bleibt Acceptance blockiert.
- Ohne echten Re-Capture bleibt Acceptance bei `needs_reentry_recapture`.
- Mit allen Gates und Re-Capture meldet der Snapshot `accepted_for_next_playable_slice`.
- Der Snapshot nennt explizit `accepted_scope = station_reentry_next_playable_slice_only` und `not_full_game_acceptance = true`.
- Snapshot, Tests und Report bleiben read-only und setzen keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_reentry_next_playable_slice_acceptance.gd`
- `scripts/tests/task_774_station_reentry_next_playable_slice_acceptance.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_774_station_reentry_next_playable_slice_acceptance.gd`
- Regression: TASK_773
- `git diff --check`

## Risiken / offene Punkte
TASK_774 akzeptiert nur den engen Reentry-Slice fuer den naechsten spielbaren Schritt. Danach bleiben echtes Spielgefuehl, bessere Command-Dichte, Mission-Ende, Kampfspannung und laengerer Host/Client-Playtest weiter relevant.
