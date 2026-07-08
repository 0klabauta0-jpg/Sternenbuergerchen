# TASK_870 - Release First Exchange Post-LOS Visual Findings

## Ziel / Problem
TASK_869 hat nach TASK_868 einen echten Release-Fenster-Recapture erzeugt. Der technische Capture-Pfad ist jetzt strenger, aber der sichtbare Screenshot ist kein gueltiger Sternenbuergerchen-First-Exchange-Beweis: `tmp/release_first_exchange_los_setup_real_window_recapture.png` zeigt eine World-at-War/TripleA-Kartenansicht statt der erwarteten Missions-/Fireteam-/CONTACT-FIRE-Oberflaeche.

## Sinnhaftigkeit / Ursache
Nach den LOS-/HUD-/Runtime-Text-Polishes darf der naechste Schritt nicht wieder ein Combat- oder HUD-Polish sein, solange der Release-Fensterblick nicht einmal sicher das richtige Spielbild zeigt. TASK_870 schneidet den Befund read-only, damit der naechste Task gezielt Release-Fensteridentitaet, Capture-Ziel oder Export-/Startpfad prueft.

## Umfang
- TASK_869-Manifest als Quelle auswerten.
- Positive Evidence festhalten: EXE gestartet, Deep-Link gesetzt, Screenshot geschrieben, `window_crop_trusted=true`.
- Sichtbefund festhalten: Screenshot-Inhalt zeigt nicht Sternenbuergerchen-Mission.
- Naechste Richtung benennen: Release Window Identity / Capture Target Fix.
- Doku, Roadmap, Status und Bericht synchronisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein HUD-Text-Override.
- Keine neue Movement-, FireEvent-, Damage-, Contact- oder Multiplayer-Wahrheit.
- Kein neuer Export in diesem Task.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_869_release_first_exchange_real_window_recapture_after_los_setup.md`
- `docs/reports/spielstand_zwischenbericht_task869_in_progress_2026_07_08.html`

## Akzeptanzkriterien
- Findings-Snapshot akzeptiert TASK_869 als Quelle.
- Snapshot unterscheidet technische Capture-Evidence von manuellem Sichtbefund.
- Snapshot benennt `trusted_capture_content_not_sternenbuergerchen` als primaere Reibung.
- Snapshot empfiehlt TASK_871 fuer Release-Fensteridentitaet / Capture-Ziel.
- Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_exchange_post_los_visual_findings.gd`
- `scripts/tests/task_870_release_first_exchange_post_los_visual_findings.gd`
- `docs/tasks/TASK_870_release_first_exchange_post_los_visual_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task869_in_progress_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_870_release_first_exchange_post_los_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_869_release_first_exchange_real_window_recapture_after_los_setup.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_870 ist ein Findings-Schnitt. Die eigentliche Reparatur folgt in TASK_871: klaeren, warum ein formal gestarteter `Sternenbuergerchen_rel.exe`-Prozess im Screenshot eine fremde World-at-War/TripleA-Karte sichtbar macht oder warum der Capture-Zielinhalt nicht zum Release-Prozess passt.
