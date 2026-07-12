# TASK_1159 - Tactical Event Log 1280 Readability

## Ziel / Problem

Das Ereignisprotokoll links ist nach TASK 1157/1158 die kleinste primaere
HUD-Schrift im exportierten 1280x720-Fenster. Zeit, Team und Meldung sind im
laufenden Gefecht nur schwer lesbar.

## Ursache / Sinnhaftigkeit

Der feste 240x184-Bereich wird aus dem 1920er HUD herunterskaliert. Die
First-Exchange-Dichte verwendet intern 11 Pixel fuer Meldungen und 10 Pixel
fuer Zeit; fuenf 30-Pixel-Zeilen konkurrieren mit Header und Innenabstand.

## Umfang

- First-Exchange-Log auf vier sichtbare, groessere Zeilen begrenzen.
- Meldung 13 Pixel, Zeit 12 Pixel, Header 13 Pixel und Filter 10 Pixel.
- Zeilenhoehe auf 32 Pixel stabilisieren.
- Im First-Exchange-Fokus eine ruhige, nahezu opake Panel-Flaeche verwenden,
  damit Kartenraster und Weltobjekte nicht durch Meldungen laufen.
- Severity-Streifen, Sortierung, Auswahlfilter und Scrollbarkeit erhalten.
- Bestehenden Feedback-Snapshot-Dedupe unveraendert nutzen.

## Nicht-Ziele

- Keine Aenderung an TacticalEventLog-Daten, Event-Erzeugung oder Dedupe-Regeln.
- Keine Aenderung an Combat, FireEvents, Commands, RPC oder Multiplayer-State.
- Kein groesseres Panel und kein zusaetzlicher Refresh.

## Relevante Contracts / Dokumente

- `docs/tasks/TASK_366_tactical_event_log_hud_panel.md`
- `docs/tasks/TASK_1043_mission_hud_hotpath_event_log_guard.md`
- `docs/tasks/TASK_1120_connected_first_contact_event_log_dedupe_hud_declutter.md`
- `docs/tasks/TASK_1158_selected_fireteam_member_cards_1280_readability.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien

- First Exchange zeigt hoechstens vier neueste Eintraege.
- Meldung mindestens 13 Pixel, Zeit mindestens 12 Pixel, Header mindestens 13 Pixel.
- Vier Zeilen passen in den bestehenden 240x184-Vertrag.
- Der Panel-Hintergrund besitzt mindestens 0,94 Alpha.
- Severity und Auswahlfilter bleiben sichtbar.
- Ein identischer Feedback-Snapshot baut keine Rows neu und erhoeht den Skip-Zaehler.
- Panel und Snapshot setzen keine Gameplay- oder Multiplayer-Wahrheit.

## Betroffene Dateien

- `scripts/ui/tactical_event_log_panel.gd`
- `scripts/tests/task_1159_tactical_event_log_1280_readability.gd`
- Status, Roadmap, Contract und HTML-Arbeitsbericht

## Lokale Pruefung

- TASK_1159 isoliert bei 1280x720.
- TASK_366, TASK_1043, TASK_1120 und TASK_180.
- Aktuelle Host/Client- und Performance-Gates.
- Exportierter First-Contact-Recapture.
- `git diff --check`.

## Risiken / offene Punkte

Weitere Eintraege bleiben in normalen Logzustaenden scrollbar. Im dichten
First-Exchange-Fokus priorisiert das HUD die vier neuesten taktischen Fakten.
