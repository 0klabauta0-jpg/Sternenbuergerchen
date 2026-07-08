# TASK_878 - Release First Exchange Visible Status Visual Findings

## Ziel / Problem
TASK_877 hat nach TASK_876 einen frischen echten Window-Handle-Capture erzeugt. Der Capture ist technisch `review_ready`, aber der sichtbare Spielerblick zeigt weiter nicht die erwartete CONTACT-FIRE-Erstlesung: #17 und #18 starten mit `NEXT LOS/RANGE KORRIGIEREN` / `Kampf NO FIRE NO_LOS`, #19 zeigt `CONTACT PRESSURE: Position korrigieren`.

## Sinnhaftigkeit / Ursache
TASK_876 beweist den Headless-/MetaLayer-Statusquellenpfad. TASK_877 beweist den exportierten Fensterblick. Die beiden Evidenzen widersprechen sich sichtbar. TASK_878 haelt diesen Befund read-only fest, damit der naechste Fix nicht wieder kosmetisch am Text dreht, sondern den Export-/Runtime-Refresh-Pfad findet, der CONTACT FIRE im echten Fenster ueberstimmt oder gar nicht aktiviert.

## Umfang
- TASK_877-Manifest als Quelle auswerten.
- Positive Evidence festhalten: trusted Window-Handle-Capture, Sternenbuergerchen-Missionsfenster, sichtbare Command-Surfaces.
- Sichtbefund festhalten: #17/#18 weiter NO_LOS-first, #19 weiter CONTACT PRESSURE.
- Primaere Reibung benennen: TASK_876-Headless-Statusquelle erreicht den exportierten Real-Window-Ersttext nicht.
- Naechste Richtung benennen: Exported-runtime Status-source trace / Refresh-Override isolieren.
- Doku, Roadmap, Status und Contract synchronisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein HUD-Text-Override ohne exportierte Runtime-Evidence.
- Keine neue Movement-, FireEvent-, Damage-, Contact-, UI- oder Multiplayer-Wahrheit.
- Kein neuer Export in diesem Task.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_877_release_first_exchange_visible_status_recapture.md`
- `docs/tasks/TASK_876_release_first_exchange_visible_status_source_reconciliation.md`

## Akzeptanzkriterien
- Findings-Snapshot akzeptiert TASK_877 als Quelle.
- Snapshot unterscheidet trusted Capture von verbleibender CONTACT-FIRE-Lesbarkeitsreibung.
- Snapshot benennt `task_876_status_source_not_real_window_first_reading` als primaere Reibung.
- Snapshot empfiehlt TASK_879 fuer exportierte Runtime-Statusquellen-/Refresh-Trace.
- Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_exchange_visible_status_visual_findings.gd`
- `scripts/tests/task_878_release_first_exchange_visible_status_visual_findings.gd`
- `docs/tasks/TASK_878_release_first_exchange_visible_status_visual_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_878_release_first_exchange_visible_status_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_877_release_first_exchange_visible_status_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_878 aendert keine Runtime. Der naechste sinnvolle Fix ist TASK_879: Im exportierten echten Fenster muss geklaert werden, ob die TASK_876-Statusquelle nicht aktiviert wird, vor dem sichtbaren Refresh ablaeuft oder nachtraeglich von Decision-/Combat-HUD-Refresh ueberschrieben wird.
