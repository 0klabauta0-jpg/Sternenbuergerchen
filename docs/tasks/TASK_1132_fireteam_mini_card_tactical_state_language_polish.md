# TASK_1132 - Fireteam Mini-Card Tactical State Language Polish

## Ziel / Problem
Die Fireteam-Mini-Cards sollen taktische Zustaende als Spielinformation statt als Diagnosecode zeigen. `EX -`, `C0` und `RDY N/A` sind zwar technisch kompakt, aber ohne Vorwissen nicht verstaendlich.

## Ursache
Die sichtbare Zeile verwendet direkt die historischen Snapshot-Kuerzel fuer Execution, Contact und Readiness. Fehlende Daten werden als Minus oder `N/A` dargestellt, obwohl fuer Spieler ein neutraler Zustand oder das Ausblenden ehrlicher ist.

## Umfang
- Neutrale Ausfuehrung als `WARTET` statt `EX -`.
- Kontakt als `KEIN KONTAKT`, `BESTAETIGT`, `GESICHTET`, `VERMUTET` oder `VERLOREN`.
- Gesundheit sichtbar als `FIT n/n`, mit kompakten Warnungen bei Verwundeten oder Ausfaellen.
- Readiness-Footer nur bei echten Readiness-Daten; spielsprachliche Labels statt `RDY HIGH/MED/LOW/N/A`.
- Vollstaendige technische Werte bleiben im Tooltip und Snapshot erhalten.

## Nicht-Ziele
- Keine Aenderung an ContactTracker, Combat, Fireteam-Profilen oder Readiness-Berechnung.
- Keine neuen Snapshotfelder, RPCs, Commands oder Effects.
- Kein weiterer Layoutumbau.

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK_1131_fireteam_mini_card_header_contrast_status_compression.md`
- `docs/tasks/TASK_369_fireteam_status_card_enhancement.md`

## Akzeptanzkriterien
- Neutraler Start zeigt `WARTET | KEIN KONTAKT | FIT n/n`.
- Aktive Profile zeigen eine lesbare Ausfuehrung mit Prozentwert.
- Kontaktzahl und Confidence werden ohne `C0/C1`-Kuerzel lesbar.
- Fehlende Readiness erzeugt keinen sichtbaren `N/A`-Footer.
- Tooltip und Snapshot behalten technische Detaildaten read-only.
- Multiplayer-, Karten- und Performance-Vertraege bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1132_fireteam_mini_card_tactical_state_language_polish.gd`
- Status-, Roadmap- und HTML-Berichtsdokumente

## Lokale Pruefung
- TASK_1132 Runtime-Verifier
- TASK_1131, TASK_369, TASK_431, TASK_503 und TASK_773
- TASK_222 Performance-Gate
- TASK_1128 Full-HD-Real-Window-Capture

## Risiken / offene Punkte
Die sichtbare Zeile bleibt absichtlich kurz. Detaildiagnose gehoert weiter in Tooltip/Snapshot und darf nicht als zweite Gameplay-Wahrheit in die UI wandern.
