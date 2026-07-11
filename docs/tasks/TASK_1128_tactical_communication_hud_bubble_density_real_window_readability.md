# TASK_1128 - Tactical Communication HUD Bubble Density and Real-Window Readability

## Status: IMPLEMENTIERT

## Ziel / Problem
TASK_1127 beweist zwei unabhaengige eventgebundene Fireteam-Bubbles im Daten- und Render-Snapshot. Noch nicht bewiesen ist, dass beide im Full-HD-Missionsfenster gleichzeitig lesbar bleiben, nicht kollidieren und eindeutig auf ihre linke Fireteam-Mini-Card zeigen.

## Sinnhaftigkeit / Ursache
Der HUD-Visualpfad loest Bubblepositionen nacheinander auf und weicht bei Kollisionen vertikal aus. Das ist funktional plausibel, aber ohne sichtbaren Zwei-Fireteam-Beleg koennen kurze Mini-Card-Abstaende, Bildschirm-Clamping oder lange Texte eine falsche Zuordnung erzeugen.

## Umfang
- Full-HD-Missionsfixture mit BLUE und GOLD und gleichzeitigem Area-Order-Feedback.
- Render-Snapshot prueft zwei unterschiedliche Event-IDs, Fireteam-IDs, Mini-Card-Anker und Bubble-Rechtecke.
- Bubble-Rechtecke duerfen einander nicht schneiden und muessen vollstaendig im Viewport liegen.
- Tail und Bubble muessen auf derselben Seite der linken Mini-Card bleiben.
- Optionaler echter Fensterlauf schreibt einen PNG-Sichtbeleg unter `tmp/`.
- Nur bei belegter visueller Kollision wird die bestehende Positionierungslogik minimal korrigiert.

## Nicht-Ziele
- Kein neues Bubble-Designsystem.
- Keine Aenderung an Command-, Event-, Simulation- oder Multiplayer-Wahrheit.
- Kein Drei-Peer-Capture als Voraussetzung fuer den lokalen Layoutfix.
- Keine neuen Texte oder Gameplayregeln.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1127_tactical_communication_hud_bubble_event_mini_card_anchor_repair.md`
- `docs/dev/tactical_communication_feedback_layer_design.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- BLUE und GOLD besitzen gleichzeitig jeweils genau eine aktuelle HUD-Bubble.
- Beide Eintraege tragen unterschiedliche bekannte Tactical-Communication-Event-IDs.
- Beide Bubble-Rechtecke liegen vollstaendig in 1920x1080 und ueberlappen sich inklusive Sicherheitsabstand nicht.
- Jede Bubble bleibt ihrem eigenen Mini-Card-Anker naeher als dem Anker des anderen Fireteams.
- Ein echter Full-HD-PNG-Capture kann erzeugt werden.
- TASK_1127, TASK_274, TASK_1119, TASK_1104 und TASK_222 bleiben gruen.

## Betroffene Dateien
- `scripts/tests/task_1128_tactical_communication_hud_bubble_density_real_window_readability.gd`
- nur bei RED-Befund: `scripts/terrain/terrain_map_3d_view.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
1. Verifier zuerst gegen den aktuellen TASK-1127-Stand ausfuehren und den konkreten Layoutbefund protokollieren.
2. Minimalen Visualfix nur bei korrekt reproduziertem RED implementieren.
3. TASK_1128 headless und mit `STERNEN_TASK1128_CAPTURE=1` im echten Fenster ausfuehren.
4. Regressionsgates aus den Akzeptanzkriterien ausfuehren.
5. `git diff --check`.

## Risiken / offene Punkte
Ein Fixture-Capture beweist die lokale Full-HD-Geometrie, aber noch nicht jede Skalierungs-/Aufloesungsvariante. Weitere Viewportgroessen werden nur aufgenommen, wenn Full HD einen echten Befund zeigt oder spaetere Spielerbeobachtung dies verlangt.

Der Full-HD-Beleg zeigt keine Kollision, aber die aktuelle Bubble-Schriftgroesse von 8 px ist fuer einen entspannten Spieleindruck klein. Typografie und die veralteten TASK-214-Modusannahmen werden als eigener Folge-Slice behandelt, damit dieser reine Sichtbeleg keine funktionierende Layoutlogik auf Verdacht aendert.

## Ergebnis
- Der bestehende Visualpfad rendert genau zwei eventgebundene HUD-Bubbles.
- BLUE und GOLD besitzen getrennte bekannte Event-IDs und Mini-Card-Anker.
- Beide Bubble-Rechtecke liegen innerhalb 1920x1080, halten mindestens 6 px Sicherheitsabstand und bleiben ihrem eigenen Anker am naechsten.
- Der echte D3D12-Fensterlauf schreibt `tmp/task_1128_tactical_communication_hud_bubble_density.png`.
- Es war keine Produktionscode-Aenderung notwendig.

## Lokale Pruefergebnisse
- TASK_1128 headless: 7/7.
- TASK_1128 Real Window: 8/8.
- Sichtbeleg: `tmp/task_1128_tactical_communication_hud_bubble_density.png`.
