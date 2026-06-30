# TASK_703 - Door Authority Button Affordance

## Ziel / Problem
Door-Authority liefert inzwischen klare Status- und Severity-Daten, aber der Door-Breach-Button sieht noch weitgehend wie ein normaler Command-Button aus. Der Spieler soll `ready`, `blocked`, `accepted` und `open` schneller am Buttonzustand erkennen.

## Sinnhaftigkeit / Ursache
TASK_701 und TASK_702 haben die Text- und HUD-Zeile verbessert. Fuer ein angenehmeres, schneller lesbares Spielgefuehl braucht der aktive Command-Button eine kleine, konsistente Status-Affordance, ohne dass UI Gameplay-Wahrheit setzt.

## Umfang
- Door-Breach-Button bekommt ein read-only Affordance-Mapping aus `door_authority_ui_severity`.
- Button-Snapshot exportiert `door_authority_affordance_style_id`, `door_authority_affordance_tone` und `door_authority_affordance_visual_weight`.
- Ready/Open/Blocked bekommen unterscheidbare sichtbare Button-Tones.
- Inaktive/pending Zustaende fallen auf neutral zurueck.
- Bestehende Door-Feedback- und Compact-HUD-Tests bleiben gruen.

## Nicht-Ziele
- Kein neuer Door-Command-Pfad.
- Keine Aenderung an `SimulationRoot`, Multiplayer-Authority, TerrainRegistry oder Runtime-Progress.
- Kein grosses Command-Panel-Layout-Redesign.
- Kein echter Host/Client-Fensterklicktest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_702_door_authority_compact_hud_surface.md`
- `docs/tasks/TASK_701_door_authority_feedback_polish.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Door-Breach-Button setzt Affordance-Metadaten aus Severity.
- `action`/ready ist sichtbar als aktive Command-Affordance markiert.
- `success`/open ist sichtbar als Success-Affordance markiert.
- `warning`/blocked ist sichtbar als Warn-Affordance markiert.
- `muted`/pending bleibt neutral und unaufdringlich.
- Button-Affordance setzt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_703_door_authority_button_affordance.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_703_door_authority_button_affordance.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_702_door_authority_compact_hud_surface.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_701_door_authority_feedback_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die echte FullHD-Wirkung muss spaeter im Fenster beurteilt werden; dieser Task macht nur den Status sichtbar und testbar.
- Falls der Button zu laut wirkt, braucht es danach visuellen Feinschliff anhand eines echten Screenshots.
