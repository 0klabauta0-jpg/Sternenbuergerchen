# TASK_1133 - Fireteam Mini-Card Stance Control Readability

## Ziel / Problem
Die direkte Stance-Steuerung der Fireteam-Mini-Card soll ohne Vorwissen lesbar sein. `C / N / A` ist kompakt, erklaert aber weder vorsichtig, normal und offensiv noch deren taktische Auswirkung.

## Ursache
Die drei Buttons verwenden historische Ein-Buchstaben-Kuerzel. Tooltip und aktiver Theme-State sind vorhanden, reichen fuer den ersten Blick aber nicht aus.

## Umfang
- Segmentierte Buttons `VORS`, `NORM`, `OFF`.
- Bestehende kuratierte CC0-Icons fuer Beobachten/Zielen, Bewegung und Angriff.
- Tooltip nennt die konkrete Wirkung auf Tempo, Waffenhaltung und Sicht.
- Genau ein Segment ist pro Fireteam aktiv und optisch hervorgehoben.
- Bestehender Command-/Sync-Pfad bleibt unveraendert.

## Nicht-Ziele
- Keine Aenderung an Stance-Wirkung, Movement-Resolver oder Simulation.
- Keine neuen RPCs, Commands, Effects oder Snapshotfelder.
- Keine Aenderung an Welt-Badges der Units.

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK_1132_fireteam_mini_card_tactical_state_language_polish.md`
- `docs/tasks/TASK_109_tactical_stance.md`
- `docs/tasks/TASK_421_move_stance_posture_speed_sight.md`

## Akzeptanzkriterien
- Jede Mini-Card zeigt `VORS`, `NORM`, `OFF` mit unterscheidbaren Icons.
- Tooltips erklaeren die echte taktische Wirkung.
- Genau ein Button ist aktiv; Auswahl bleibt Fireteam-spezifisch.
- Buttons passen ohne Clipping in die Kartenbreite.
- Bestehende Stance-, Multiplayer-, Karten- und Performance-Verifier bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1133_fireteam_mini_card_stance_control_readability.gd`
- `scripts/tests/task_109_verifier.gd`
- Status-, Roadmap- und HTML-Berichtsdokumente

## Lokale Pruefung
- TASK_1133 Runtime-Verifier
- TASK_109, TASK_421, TASK_425 und TASK_431
- TASK_503, TASK_773 und TASK_222
- TASK_1128 Full-HD-Real-Window-Capture

## Risiken / offene Punkte
Die Mini-Card bleibt schmal. Icons und Texte muessen deshalb feste, stabile Abmessungen behalten und duerfen die Statuszeile oder Portraits nicht verschieben.
