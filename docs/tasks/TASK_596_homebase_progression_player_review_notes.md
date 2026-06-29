# TASK_596 - Homebase Progression Player Review Notes

## Ziel / Problem
TASK_595 hebt Post-Mission-Awards im Homebase-Character-Sheet als `MISSION GAIN`-Highlight hervor. Ob diese Hervorhebung im echten Fenster angenehm, auffaellig genug und nicht stoerend wirkt, ist noch kein belegter Spielerblick.

## Sinnhaftigkeit / Ursache
Der Core Loop lebt davon, dass der Spieler nach dem Einsatz Fortschritt erkennt und versteht. Ein automatisierter Style-Gate beweist die Existenz der Row, aber nicht das Spielgefuehl. Dafuer braucht der laufende HTML-Bericht einen strukturierten Review-Ort mit Screenshotpfad, Pflichtchecks, Ratings, Follow-up und freier Notiz.

## Umfang
- `docs/reports/project_review_status_2026_06_28.html` bekommt einen TASK_596-Reviewblock fuer Homebase-Progression.
- Der Block exportiert Screenshot-/Viewport-/Operator-Kontext, Pflichtchecks, Ratings, konkrete Follow-up-Prioritaet und freie Notiz.
- Status, Roadmap und Contract nennen TASK_596 als erledigten Report-/Review-Notes-Slice.
- Ein statischer Verifier prueft alle Export-Keys, Choice-Groups und die Follow-up-Kette.

## Nicht-Ziele
- Kein neuer Screenshot-Capture.
- Keine Runtime-, Homebase-, Character-Sheet- oder Progressionslogik.
- Kein Gameplay-State im HTML-Bericht.
- Keine automatische Behauptung, dass der menschliche Sichttest erledigt wurde.

## Relevante Contracts / Dokumente
- `docs/dev/html_report_workbench_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_595_homebase_progression_visual_polish.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der Bericht enthaelt einen sichtbaren `TASK_596 Homebase-Progression Player-Review`-Block.
- Der JSON-Export enthaelt `homebase_progression_manual.*`-Felder fuer Screenshot, Checks, Ratings, Notizen und Follow-up.
- Freitext wird ueber `notes.homebase_progression_manual_review` exportiert.
- Der Bericht markiert TASK_596 als erledigt und TASK_597 als naechsten sinnvollen Anschluss.
- Der Block bleibt eindeutig Arbeitsnotiz und erzeugt keine Runtime- oder Gameplay-Wahrheit.

## Betroffene Dateien
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/tasks/TASK_596_homebase_progression_player_review_notes.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/tests/task_596_homebase_progression_player_review_notes.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_596_homebase_progression_player_review_notes.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_595_homebase_progression_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task schafft den Review-Ort, fuehrt aber noch keinen echten Sichttest aus.
- Ein spaeterer TASK_597 kann daraus eine reproduzierbare Homebase-Progression-F6-/Screenshot-Evidence ableiten.
