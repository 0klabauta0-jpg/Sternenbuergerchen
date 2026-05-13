# TASK_366 - Tactical Event Log HUD Panel

## Ziel
Das taktische Ereignis-Log als kompaktes, scrollbares HUD-Panel in der Mission anzeigen.

## Status: GEPLANT

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
- [ ] Panel zeigt newest-first Ereignisse aus TASK_365.
- [ ] Overflow bleibt scrollbar und verschiebt keine festen Missionsfenster.
- [ ] Critical/Warning/Tactical/Info sind visuell unterscheidbar, aber nicht grell.
- [ ] Selected-Fireteam-Filter kann bekannte Fireteam-IDs aus dem Feedback-Snapshot verwenden.
- [ ] Layout-Verifier prueft, dass #17/#18 und Command-Buttons nicht verdeckt werden.

## Erwartete Dateien
- `scripts/ui/tactical_event_log_panel.gd`
- `scenes/tests/mission_reactivity_test.tscn`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_366_tactical_event_log_hud_panel.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_366_tactical_event_log_hud_panel.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Das Panel braucht einen klaren Platz im bestehenden Fixed-Layout. Wenn der rechte Bereich zu eng ist, muss der Task stoppen und Layout-Optionen dokumentieren.
- RichTextLabel-BBCode darf nicht mit unescaped Eventtext gefuettert werden.

