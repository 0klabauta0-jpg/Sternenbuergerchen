# TASK_619 - Host Client Role Peer Badge HUD

## Problem
TASK_618-Crops zeigen Host und Client mit sichtbarer Mission-Welt, aber im eigentlichen Missionsfenster sind beide Ansichten fast nicht unterscheidbar. Fuer Multiplayer-Review und spaetere Spielerlesbarkeit muss sofort sichtbar sein, ob ein Fenster Host oder Client ist und welchem Peer/Team es gehoert.

## Ursache
Der Launchplan uebergibt bereits `--review-role`, `--peer-id` und `--team`, aber `MissionTacticalSandboxController` zeigt diese Review-/Session-Identitaet nicht als stabilen HUD-Hinweis. Die Information steckt im Startkontext, wird aber nicht im Spielerblick sichtbar.

## Umfang
- Review-/Session-Argumente aus `OS.get_cmdline_user_args()` read-only lesen.
- Im Mission-HUD einen kompakten Badge mit Role, Peer und Team anzeigen.
- Badge in Snapshot/Verifier/HTML-Bericht als Anzeigevertrag dokumentieren.
- Keine Runtime-, Peer-, Command-, Objective-, Cargo-, Combat- oder Movement-Wahrheit veraendern.

## Nicht-Ziele
- Kein Netcode-Fix.
- Keine Multiplayer-Lobby-Aenderung.
- Keine serverseitige Authority-Aenderung.
- Kein Persistieren der Review-Argumente in Gameplay-State.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_618_host_client_standard_capture_crop_review.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Host-Fenster kann sichtbar `HOST`, `P1` und `team_alpha`/Alpha anzeigen.
- Client-Fenster kann sichtbar `CLIENT`, `P2` und `team_bravo`/Bravo anzeigen.
- Anzeige bleibt read-only und setzt keine Gameplay-Wahrheit.
- Verifier prueft Script, Snapshot, Report, Contract und Roadmap.

## Betroffene Dateien
- `docs/tasks/TASK_619_host_client_role_peer_badge_hud.md`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_619_host_client_role_peer_badge_hud.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_619_host_client_role_peer_badge_hud.gd`
- Regression: `task_618_host_client_standard_capture_crop_review.gd`
- Regression: `task_617_host_client_standard_window_layout_hardening.gd`
- `git diff --check`

## Risiken / offene Punkte
- In echten nicht-Review-Sessions koennen spaeter robustere Multiplayer-Sessiondaten statt Launch-Args sinnvoll sein.
- Der Badge darf keine Authority-Entscheidung treffen; er ist nur Sichtbarkeit.
