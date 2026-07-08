# TASK_875 - Release First Exchange CONTACT-FIRE Visual Findings

## Ziel / Problem
TASK_874 hat den echten Release-Fenster-Capture nach TASK_873 technisch sauber erzeugt. Der Screenshot ist trusted und zeigt Sternenbuergerchen, aber der sichtbare First-Exchange ist weiterhin nicht als CONTACT FIRE lesbar: #17/#18 zeigen `NEXT LOS/RANGE KORRIGIEREN` und `Kampf NO FIRE NO_LOS`, #19 zeigt `CONTACT PRESSURE`.

## Sinnhaftigkeit / Ursache
Der Befund ist jetzt kein Capture-Zielproblem mehr und auch kein fehlender Exportbeweis. Die Reibung liegt zwischen der TASK_873-Readability-Evidence und dem real sichtbaren HUD-/Event-Log-Pfad. TASK_875 schneidet diesen Befund read-only, damit der naechste Fix gezielt die sichtbare Statusquelle/Timing-Kopplung klaert.

## Umfang
- TASK_874-Manifest als Quelle auswerten.
- Positive Evidence festhalten: trusted Window-Handle-Capture, Sternenbuergerchen-Missionsfenster, Command-Surfaces sichtbar.
- Sichtbefund festhalten: #17/#18 weiter `NO_FIRE/NO_LOS`, #19 weiter `CONTACT PRESSURE`.
- Primaere Reibung benennen: TASK_873-Evidence kommt nicht als erste reale Fensterlesung an.
- Naechste Richtung benennen: sichtbare Statusquellen und TASK_873-Persistenz im echten Fenster versoehnen.
- Doku, Roadmap, Status und Contract synchronisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein HUD-Text-Override ohne Runtime-Evidence.
- Keine neue Movement-, FireEvent-, Damage-, Contact-, UI- oder Multiplayer-Wahrheit.
- Kein neuer Export in diesem Task.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_874_release_first_exchange_contact_fire_real_window_recapture.md`
- `docs/tasks/TASK_873_release_first_exchange_contact_fire_readability_fix.md`
- `docs/reports/spielstand_zwischenbericht_task874_recapture_2026_07_08.html`

## Akzeptanzkriterien
- Findings-Snapshot akzeptiert TASK_874 als Quelle.
- Snapshot unterscheidet trusted Capture von verbleibender CONTACT-FIRE-Lesbarkeitsreibung.
- Snapshot benennt `task_873_evidence_not_real_window_first_reading` als primaere Reibung.
- Snapshot empfiehlt TASK_876 fuer sichtbare Statusquellen-/Timing-Reconciliation.
- Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_exchange_contact_fire_visual_findings.gd`
- `scripts/tests/task_875_release_first_exchange_contact_fire_visual_findings.gd`
- `docs/tasks/TASK_875_release_first_exchange_contact_fire_visual_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_875_release_first_exchange_contact_fire_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_874_release_first_exchange_contact_fire_real_window_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_875 aendert keine Runtime. Der naechste sinnvolle Fix ist TASK_876: Im echten Fenster muss geklaert werden, welche sichtbare Statusquelle TASK_873 ueberstimmt oder ob die TASK_873-Persistenz zu frueh/zu spaet refreshed wird.
