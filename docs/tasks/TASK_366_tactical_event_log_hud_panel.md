# TASK_366 - Tactical Event Log HUD Panel

## Ziel
Das taktische Ereignis-Log als kompaktes, scrollbares HUD-Panel in der Mission anzeigen.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll, sobald TASK_365 die Daten sauber liefert. Das Panel sollte nicht die bisherigen Comms-Bubbles ersetzen, sondern eine ruhige Nachlese-Schicht sein.

## Problem
Spieler verpassen kurze Funk-/Bubble-Meldungen. Ohne Log ist schwer nachvollziehbar, warum ein Fireteam langsam reagiert, einen Kontakt verloren hat oder ein Befehl blockiert wurde.

## Ursache
Mission-HUD hat feste Fenster und Feedback-Labels, aber kein dediziertes Panel fuer persistente Ereignisse.

## Umfang
- Kompaktes Panel fuer die rechte oder strategische HUD-Zone pruefen.
- Maximal sichtbare Eintraege begrenzen, z. B. 6 bis 8 Zeilen plus Scroll.
- Severity-Farben sparsam einsetzen: critical, warning, tactical, info.
- Filter fuer selected fireteam und mission-wide Events vorbereiten.
- Keine sichtbaren Tutorialtexte oder erklaerende In-App-Beschreibungen hinzufuegen.

## Akzeptanzkriterien
- [x] Panel zeigt newest-first Ereignisse aus TASK_365.
- [x] Overflow bleibt scrollbar und verschiebt keine festen Missionsfenster.
- [x] Critical/Warning/Tactical/Info sind visuell unterscheidbar, aber nicht grell.
- [x] Selected-Fireteam-Filter kann bekannte Fireteam-IDs aus dem Feedback-Snapshot verwenden.
- [x] Layout-Verifier prueft, dass #17/#18 und Command-Buttons nicht verdeckt werden.

## Umsetzung
- `TacticalEventLogPanel` rendert TASK_365-Eintraege als kompaktes, scrollbar begrenztes HUD-Panel mit Severity-Streifen, Zeitlabel und kurzem Eventtext.
- Das Panel sitzt im Mission-Canvas links unter der Fireteam-Miniuebersicht, weil die rechte HUD-Zone bereits vom dynamischen Dropship-Panel belegt werden kann.
- `mission_tactical_sandbox_controller.gd` aktualisiert das Panel aus dem bestehenden Command-Feedback-Snapshot; der Panel-Filter liest `selected_fireteam_ids`, schreibt aber keinen Gameplay-Zustand.
- Der Fixed-Window-Audit wurde auf den aktuellen Homebase-Direct-Vertrag nachgezogen und prueft jetzt zusaetzlich das Mission-Event-Log.

## Erwartete Dateien
- `scripts/ui/tactical_event_log_panel.gd`
- `scenes/tests/mission_reactivity_test.tscn`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_366_tactical_event_log_hud_panel.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_366_tactical_event_log_hud_panel.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_365_tactical_event_log_data_layer.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Der rechte HUD-Bereich bleibt fuer Dropship-Karten frei; das Event-Log belegt deshalb bewusst die linke Karten-/Uebersichtszone.
- Es wird kein BBCode genutzt; Eventtext landet in normalen Labels und muss daher nicht als RichText escaped werden.
