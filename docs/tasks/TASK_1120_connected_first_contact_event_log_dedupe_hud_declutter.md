# TASK_1120 - Connected First Contact Event Log Dedupe and HUD Declutter

## Ziel / Problem
Der echte TASK-1119-Produktcapture zeigt den richtigen BLUE-/GOLD-Erstkontakt, aber wiederholte Contact-Reports und leere, bereits zur FOB zurueckgekehrte Dropship-Karten konkurrieren mit der aktuellen Entscheidung.

## Sinnhaftigkeit / Ursache
Die Event-Historie dedupliziert nur identische Event-IDs. Wiederholte Wahrnehmungsberichte besitzen absichtlich neue IDs und erscheinen deshalb mehrfach. Das Produktfenster startet das Event Log global statt fireteambezogen. Transportkarten bleiben sichtbar, obwohl sie leer, ohne Pilot und bei `to_fob 0s` funktional inaktiv sind.

## Umfang
- Verbundene aktive Peers starten das Event Log mit lokalem Fireteam-Filter; manueller Toggle bleibt erhalten.
- Semantisch gleiche Contact-Reports werden nur in der Display-Leseschicht gruppiert.
- Neueste Zeile bleibt sichtbar und meldet die Zahl zusammengefasster Wiederholungen.
- `CONTACT FIRE` wird vor normalen Contact-Reports priorisiert.
- Vollstaendig inaktive `to_fob 0s`-Karten werden waehrend First Contact ausgeblendet.

## Nicht-Ziele
- Keine Aenderung an ContactTracker, Fire-Events oder TacticalEventLog-Rohhistorie.
- Keine Aenderung an Transportstate, Dropship-Commands oder Snapshotwahrheit.
- Kein genereller Umbau des Mission-HUD-Layouts.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1119_connected_first_contact_three_peer_product_visual_playtest.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/tactical/tactical_event_log.gd`
- `scripts/ui/tactical_event_log_panel.gd`

## Akzeptanzkriterien
- Drei gleiche Contact-Reports ergeben eine Displayzeile mit `repeat_count = 3`.
- Rohhistorie und Event-IDs bleiben unveraendert.
- Contact Fire steht vor normalem Contact Report.
- Produkt-Event-Log startet selected-only, kann aber danach manuell auf global umgeschaltet werden.
- Leere `to_fob 0s`-Karten verschwinden nur bei aktivem First Contact; aktive/beladene/pending Karten bleiben.
- Keine Commands, Effects oder Gameplay-State-Mutationen entstehen.
- TASK_1119 und Performance-Gate bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/ui/tactical_event_log_panel.gd`
- `scripts/tests/task_1120_connected_first_contact_event_log_dedupe_hud_declutter.gd`
- Status-, Roadmap- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1120 headless und Real-Window.
- TASK_1119 Drei-Peer-Produktlauf.
- TASK_366/TASK_627/TASK_715 Event-Log-Regressionen.
- TASK_1109/TASK_1110 Dropship-HUD-Regressionen.
- TASK_222 Performance-Gate.
- `git diff --check`.

## Risiken / offene Punkte
Die Gruppierung darf nur Darstellung verdichten. AAR, Debug und autoritative Eventdaten muessen weiterhin alle einzelnen Ereignisse behalten.

## Ergebnis / Verifikation
- Die Rohhistorie bleibt vollstaendig; nur die Release-Displayleseschicht gruppiert gleiche Contact-Reports innerhalb eines Fuenf-Sekunden-Fensters.
- Die neueste Meldung behaelt alle Quell-Event-IDs und zeigt Wiederholungen als `xN`; ein spaeter Wiederkontakt erzeugt wieder eine eigene Zeile.
- Verbundene aktive Spieler starten fireteambezogen. Ein manueller Wechsel auf die globale Ansicht bleibt ueber weitere Snapshot-Refreshes erhalten.
- Bei aktivem `CONTACT FIRE` verschwinden ausschliesslich leere, abgeschlossene `to_fob 0s`-Karten. Beladene, bemannte, aktive oder wartende Crafts bleiben sichtbar.
- Echter GOLD-Produktcapture: Event Log zeigt eine priorisierte Contact-Fire-Zeile und keine inaktiven Dropship-Karten; TASK_1119 Real-Window bleibt 22/22 gruen.
- TASK_1120: 11/11. TASK_366: 19/19. TASK_1109: 18/18. TASK_1110: 20/20. TASK_222: 82/82. `git diff --check`: gruen.
- TASK_627 und TASK_715 besitzen veraltete Baseline-Annahmen: feste historische Panel-Koordinaten beziehungsweise eine leere Initialhistorie trotz heutiger echter Start-Combat-Events. Die von TASK_1120 betroffenen Runtime-Checks bleiben dort gruen; die Altverifier wurden bewusst nicht in diesem Task umgeschrieben.
