# TASK_861 - Release Fire Exchange Real Window Contact-Fire Visual Findings

## Ziel / Problem
TASK_860 hat den echten Fenster-Recapture nach TASK_859 technisch sauber erzeugt. Der Screenshot liest sich aber weiterhin nicht als klare CONTACT-FIRE-Erstlesung: #17/#18 zeigen weiter `NEXT LOS/RANGE KORRIGIEREN` und `Kampf NO FIRE NO_LOS`, waehrend #19 eher `CONTACT PRESSURE` bestaetigt. TASK_861 haelt diesen belegten Befund als read-only Findings-Schnitt fest.

## Sinnhaftigkeit / Ursache
Die TASK_859-Source-Bindung ist im Snapshot gruen, aber der echte Real-Window-Pfad priorisiert im sichtbaren Moment noch andere Textquellen. Damit ist der naechste sinnvolle Schritt kein Combat-Rewrite, sondern ein enger Befund ueber die Abweichung zwischen Source-Binding-Snapshot und echter Window-Lesung.

## Umfang
- `ReleaseFireExchangeRealWindowContactFireVisualFindings` wertet den TASK_860-Recapture als read-only Findings-Snapshot aus.
- Positive Befunde: echter Fenster-Capture vorhanden, TASK_859-Source-Binding-Style erwartet, Command-/Mission-Surfaces weiter lesbar.
- Offene Findings: #17/#18 zeigen weiter `NO FIRE NO_LOS`/LOS-Range-Korrektur als Primaerlesung, CONTACT FIRE ist nicht sichtbar dominant, Event Log bestaetigt eher Contact Pressure, und Source-Binding-/Window-Pfad divergieren.
- Status-, Roadmap-, Contract- und Berichtssync.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands, Navigation oder Multiplayer-Wahrheit.
- Kein UI-Polish in diesem Task.
- Kein Pixel-/OCR-Autourteil.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_860_release_fire_exchange_real_window_contact_fire_recapture.md`
- `docs/tasks/TASK_859_release_fire_exchange_real_window_primary_hud_source_binding_polish.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- Der Findings-Snapshot meldet Schema `sternenbuergerchen.release_fire_exchange_real_window_contact_fire_visual_findings.v1` und `task_id = TASK_861`.
- Der Snapshot akzeptiert TASK_860 als Quelle und prueft TASK_859-Source-Binding-Style-ID.
- Der Primaerbefund ist `real_window_still_no_fire_no_los_first_reading`.
- Der Snapshot empfiehlt TASK_862 als engen Folge-Polish.
- Der Snapshot bleibt read-only und erzeugt keine UI-, Command-, Combat-, Damage-, Movement-, Multiplayer- oder Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_fire_exchange_real_window_contact_fire_visual_findings.gd`
- `scripts/tests/task_861_release_fire_exchange_real_window_contact_fire_visual_findings.gd`
- `docs/tasks/TASK_861_release_fire_exchange_real_window_contact_fire_visual_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_861_release_fire_exchange_real_window_contact_fire_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_860_release_fire_exchange_real_window_contact_fire_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_861 ist bewusst nur Befund. Der naechste Task muss eng klaeren, warum der TASK_859-gebundene CONTACT-FIRE-Text nicht in der echten #17/#18-Window-Erstlesung landet.
