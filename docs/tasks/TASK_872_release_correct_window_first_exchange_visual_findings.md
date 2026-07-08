# TASK_872 - Release Correct Window First Exchange Visual Findings

## Ziel / Problem
TASK_871 hat den Capture-Zielkonflikt geloest: Der neue Release-Recapture kommt mit `window_capture_method=window_handle_print`, `window_capture_trusted=true` und zeigt wieder das Sternenbuergerchen-Missionsfenster. Im richtigen Fenster liest der erste Exchange aber weiterhin `NEXT LOS/RANGE KORRIGIEREN`, `Kampf NO FIRE NO_LOS` und Event-Log `CONTACT PRESSURE`.

## Sinnhaftigkeit / Ursache
Vor TASK_871 war unklar, ob der Befund aus dem Spiel oder aus einem falschen Screenshot kam. Diese Verwechslung ist weg. TASK_872 schneidet deshalb read-only den echten Spielbefund: Der Release-First-Exchange ist im korrekten Fenster noch nicht als klare CONTACT-FIRE-/FireTrace-/Impact-Situation lesbar.

## Umfang
- TASK_869-Manifest nach TASK_871 als Quelle auswerten.
- Positive Evidence festhalten: `window_handle_print`, trusted Capture, Sternenbuergerchen-Fenster sichtbar.
- Sichtbefund festhalten: #17/#18/#19 zeigen weiter `NO_LOS` / `CONTACT PRESSURE`.
- Naechste Richtung benennen: CONTACT-FIRE-/LOS-Lesbarkeit im richtigen Fenster fixen.
- Doku, Roadmap, Status und Contract synchronisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein HUD-Text-Override.
- Keine neue Movement-, FireEvent-, Damage-, Contact- oder Multiplayer-Wahrheit.
- Kein neuer Export in diesem Task.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_871_release_window_identity_capture_target_fix.md`
- `docs/tasks/TASK_869_release_first_exchange_real_window_recapture_after_los_setup.md`
- `docs/reports/spielstand_zwischenbericht_task871_window_capture_2026_07_08.html`

## Akzeptanzkriterien
- Findings-Snapshot akzeptiert TASK_869 nach TASK_871 als Quelle.
- Snapshot unterscheidet korrekten Fensterinhalt von verbleibender CONTACT-FIRE-/LOS-Reibung.
- Snapshot benennt `correct_window_first_exchange_still_no_los` als primaere Reibung.
- Snapshot empfiehlt TASK_873 fuer den eigentlichen CONTACT-FIRE-/LOS-Lesbarkeitsfix.
- Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_correct_window_first_exchange_visual_findings.gd`
- `scripts/tests/task_872_release_correct_window_first_exchange_visual_findings.gd`
- `docs/tasks/TASK_872_release_correct_window_first_exchange_visual_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_872_release_correct_window_first_exchange_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_871_release_window_identity_capture_target_fix.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_872 ist ein Findings-Schnitt. Die eigentliche Spielverbesserung folgt in TASK_873: Dort muss geklaert werden, ob der Deep-Link trotz TASK_868 im echten Fenster noch ein anderes Zielpaar/Timing erwischt, ob CONTACT PRESSURE korrekt aber schlecht erklaert ist, oder ob die CONTACT-FIRE-Persistenz nicht bis in die sichtbare Erstlesung kommt.
