# TASK_864 - Release Fire Exchange Runtime Text Visual Findings

## Ziel / Problem
TASK_863 hat den frischen Release-Fenster-Capture nach TASK_862 technisch sauber erzeugt. Der Screenshot liest sich aber weiterhin nicht als klare CONTACT-FIRE-Erstlesung: #17/#18 zeigen primaer `NEXT LOS/RANGE KORRIGIEREN` und `Kampf NO FIRE NO_LOS`, waehrend #19 eher `CONTACT PRESSURE` bestaetigt.

TASK_864 haelt diesen belegten Real-Window-Befund als read-only Findings-Schnitt fest.

## Sinnhaftigkeit / Ursache
TASK_862 beweist den Runtime-Textpfad headless, und TASK_863 beweist den echten Fenster-Capture. Der echte Spielerblick widerspricht der gewuenschten Lesung aber weiter. Der naechste sinnvolle Schritt ist deshalb kein Combat-Rewrite, sondern ein enger Befund ueber die Abweichung zwischen TASK_862-Runtime-Text-Snapshot und sichtbarer #17/#18-Window-Erstlesung.

## Umfang
- `ReleaseFireExchangeRuntimeTextVisualFindings` wertet den TASK_863-Recapture als read-only Findings-Snapshot aus.
- Positive Befunde: echter TASK_863-Fenster-Capture vorhanden, TASK_862-Runtime-Text-Schema/Style erwartet, TASK_856/TASK_859-Contracts noch im Manifest, Command-/Mission-Surfaces weiter lesbar.
- Offene Findings: #17/#18 zeigen weiter `NEXT LOS/RANGE KORRIGIEREN` / `Kampf NO FIRE NO_LOS`, Event Log bestaetigt `CONTACT PRESSURE`, und die Headless-Runtime-Text-Lesung divergiert vom sichtbaren Real-Window-Status.
- Status-, Roadmap-, Contract- und Berichtssync.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands, Navigation oder Multiplayer-Wahrheit.
- Kein UI-Polish in diesem Task.
- Kein Pixel-/OCR-Autourteil.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_863_release_fire_exchange_runtime_text_recapture.md`
- `docs/tasks/TASK_862_release_fire_exchange_real_window_primary_hud_runtime_text_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- Der Findings-Snapshot meldet Schema `sternenbuergerchen.release_fire_exchange_runtime_text_visual_findings.v1` und `task_id = TASK_864`.
- Der Snapshot akzeptiert TASK_863 als Quelle und prueft TASK_862-Runtime-Text-Style-ID.
- Der Primaerbefund ist `runtime_text_window_still_los_no_fire_first_reading`.
- Der Snapshot empfiehlt TASK_865 als engen Folge-Polish.
- Der Snapshot bleibt read-only und erzeugt keine UI-, Command-, Combat-, Damage-, Movement-, Multiplayer- oder Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_fire_exchange_runtime_text_visual_findings.gd`
- `scripts/tests/task_864_release_fire_exchange_runtime_text_visual_findings.gd`
- `docs/tasks/TASK_864_release_fire_exchange_runtime_text_visual_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_864_release_fire_exchange_runtime_text_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_863_release_fire_exchange_runtime_text_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_864 ist bewusst nur Befund. Der naechste Task muss eng klaeren, warum die TASK_862-CONTACT-FIRE-Runtime-Zeile im echten #17/#18-Fenster weiter von Decision-/LOS-/NO-FIRE-Text ueberstimmt wird.
