# TASK_888 - Release First Exchange Player Readability Polish Review

## Ziel / Problem
TASK_887 beweist, dass der echte Post-Final-Fensterframe #17 Selected Fireteam, #18 Mission Control und #19 Event Log synchron mit CONTACT FIRE lesen kann. Damit ist die alte technische Frame-/Source-Reibung geloest, aber noch nicht die Spielerfrage: Ist der erste Feuerwechsel schnell, angenehm und schoen genug lesbar?

## Sinnhaftigkeit / Ursache
Der aktuelle Screenshot zeigt die richtige Information, aber die visuelle Last ist hoch. Bottom-HUD, Member-Cards, Mission-Control-Text, Event-Log-Overlay, kleine Weltlabels und FireTrace/Impact konkurrieren um Aufmerksamkeit. Der naechste Schritt darf deshalb nicht erneut Combat-Wahrheit in HUD-Text schichten, sondern muss den echten Spielerblick als read-only Review schneiden und daraus einen kleinen Polish-Task ableiten.

## Umfang
- TASK_887-Manifest als technische Quelle pruefen.
- Spielerlesbarkeitsbefund als read-only Snapshot festhalten.
- Positive Punkte benennen: CONTACT FIRE erreicht #17/#18/#19, Event Log zeigt den Kontakt, Welt-FIRE/CONTACT und FireTrace/Impact sind vorhanden, Command-Surfaces bleiben bedienbar.
- Reibungen benennen: Bottom-HUD-Dichte, #18-Clipping/Zeilenstau, zu kleines/ueberlagertes Event Log, subtile FireTrace-/Impact-Lesbarkeit, Member-Cards konkurrieren mit Status.
- Folgearbeit als konkreten TASK_889 vorschlagen.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein neuer HUD-Text-Override.
- Keine neue UI-, Command-, Combat-, Damage-, Contact-, Movement- oder Multiplayer-Wahrheit.
- Keine neue VFX-/Layout-Implementierung in diesem Task.
- Kein Screenshot-OCR und kein neuer Capture-Pfad.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_887_release_first_exchange_real_window_hud_render_frame_sync_fix.md`
- `docs/tasks/TASK_886_release_first_exchange_real_window_hud_render_frame_trace.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- TASK_888-Analyzer nennt TASK_887 als Quelle und prueft, dass der CONTACT-FIRE-Frame technisch synchron ist.
- Snapshot enthaelt positive Spielerlesbarkeitsbefunde und konkrete Reibungen.
- Snapshot meldet `player_readability_ok = false`, wenn Dichte/Clipping/Subtilitaet den ersten Blick noch stoeren.
- Snapshot empfiehlt `TASK_889 - Release First Exchange HUD Density And Fire Visual Polish`.
- Analyzer bleibt read-only und erzeugt keine Commands, FireEvents, DamageEvents, Movement, Multiplayer-Wahrheit oder Shortcut-Aenderungen.
- Verifier prueft den Contract, die Docs, den optionalen echten TASK_887-Manifestpfad und einen JSON-Roundtrip.

## Betroffene Dateien
- `docs/tasks/TASK_888_release_first_exchange_player_readability_polish_review.md`
- `scripts/mission/release_first_exchange_player_readability_polish_review.gd`
- `scripts/tests/task_888_release_first_exchange_player_readability_polish_review.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_888_release_first_exchange_player_readability_polish_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_887_release_first_exchange_hud_render_frame_sync_fix.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_888 ist ein Review-/Planungs-Slice. Er verbessert noch nicht die sichtbare HUD-Dichte oder FireTrace-Wirkung selbst. Die konkrete Umsetzung gehoert in TASK_889, damit der Review-Befund nicht mit Runtime-Polish vermischt wird.
