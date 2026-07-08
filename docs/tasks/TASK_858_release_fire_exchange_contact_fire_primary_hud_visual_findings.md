# TASK_858 - Release Fire Exchange Contact-Fire Primary HUD Visual Findings

## Ziel / Problem
TASK_857 hat den echten Fenster-Recapture nach TASK_856 technisch sauber erzeugt. Der Screenshot liest sich aber weiterhin eher als `NO FIRE NO_LOS` / `CONTACT PRESSURE` statt als klarer CONTACT-FIRE-Moment. Dieser belegte Befund soll als read-only Findings-Schnitt festgehalten werden, bevor gezielt poliert wird.

## Sinnhaftigkeit / Ursache
TASK_856 beweist im Snapshot, dass die CONTACT-FIRE-Primaerzeile vorhanden sein soll. TASK_857 beweist, dass der echte Release-Fensterpfad trotzdem noch eine andere Spielerlesung zeigt. Damit ist der naechste sinnvolle Schritt nicht ein breiter Combat- oder HUD-Umbau, sondern ein enger Befund ueber die Abweichung zwischen Contract-Snapshot und Real-Window-Wirkung.

## Umfang
- `ReleaseFireExchangeContactFirePrimaryHudVisualFindings` wertet den TASK_857-Recapture als read-only Findings-Snapshot aus.
- Positive Befunde: echter Fenster-Capture vorhanden, TASK_856-Style erwartet, Command-/Mission-Surfaces weiter lesbar.
- Offene Findings: #17/#18 zeigen weiter `NO FIRE NO_LOS`/LOS-Korrektur, CONTACT FIRE ist nicht primaer sichtbar, Event Log bestaetigt eher Contact Pressure, und Headless-/Window-Pfad divergieren.
- Status-, Roadmap-, Contract- und Berichtssync.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands, Navigation oder Multiplayer-Wahrheit.
- Kein UI-Polish in diesem Task.
- Kein Pixel-/OCR-Autourteil.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_857_release_fire_exchange_contact_fire_primary_hud_recapture.md`
- `docs/tasks/TASK_856_release_fire_exchange_contact_fire_primary_hud_polish.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- Der Findings-Snapshot meldet Schema `sternenbuergerchen.release_fire_exchange_contact_fire_primary_hud_visual_findings.v1` und `task_id = TASK_858`.
- Der Snapshot akzeptiert TASK_857 als Quelle und prueft TASK_856-Primary-HUD-Style-ID.
- Der Primaerbefund ist `primary_hud_still_no_fire_no_los_visible`.
- Der Snapshot empfiehlt TASK_859 als engen Folge-Polish.
- Der Snapshot bleibt read-only und erzeugt keine UI-, Command-, Combat-, Damage-, Movement-, Multiplayer- oder Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_fire_exchange_contact_fire_primary_hud_visual_findings.gd`
- `scripts/tests/task_858_release_fire_exchange_contact_fire_primary_hud_visual_findings.gd`
- `docs/tasks/TASK_858_release_fire_exchange_contact_fire_primary_hud_visual_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_858_release_fire_exchange_contact_fire_primary_hud_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_857_release_fire_exchange_contact_fire_primary_hud_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_858 ist bewusst nur Befund. Der naechste Task muss eng klaeren, warum der Real-Window-HUD-Pfad die TASK_856-Primaerzeile nicht sichtbar genug durchsetzt.
