# TASK_369 - Fireteam Status Card Enhancement

## Ziel
Die Missions-Fireteam-Karten sollen mehr als nur Execution-Label zeigen: Readiness, Contact-State, Modus, Position und Health-Zusammenfassung sollen kompakt sichtbar werden.

## Status: GEPLANT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll, weil die Fireteam-Karten die natuerliche Stelle fuer Statuslesbarkeit sind. Er sollte aber auf TASK_367/TASK_368 aufbauen und nicht eigene Metriken in der Karte berechnen.

## Problem
Aktuelle Fireteam-HUD-Karten erklaeren nicht ausreichend, warum ein Team langsam, blockiert, unter Kontakt oder stabil ist.

## Ursache
Statusdaten existieren verteilt in FTL-Profilen, TacticalCommunicationEvents, Movement-State und Unit-Snapshots. Die Karte hat noch keinen gemeinsamen Anzeige-Snapshot.

## Umfang
- Kleinen Fireteam-Status-Snapshot fuer Karte zusammenstellen oder vorhandenen Feedback-Snapshot erweitern.
- Execution Label, Readiness-Gauge/Badge, Contact Count, Movement/Advance Mode, Grid/Position und Health Count anzeigen.
- Selection und Multi-Fireteam-Kontext erhalten.
- Nur sichtbare Zeilen, die in das vorhandene feste Mission-HUD passen.
- Keine Statusberechnung direkt in UI-Controls.

## Akzeptanzkriterien
- [ ] Karte zeigt mindestens Execution, Reaction/Readiness, Contact und Health Count.
- [ ] Kartenhoehe bleibt in FullHD ohne horizontales oder vertikales Ueberlaufen bedienbar.
- [ ] Selected Fireteam bleibt klar markiert.
- [ ] Snapshot/Verifier prueft mind. zwei Fireteams mit unterschiedlichen Contact-/Readiness-Zustaenden.
- [ ] TASK_286 UI-Feedback-Truth bleibt gruen.

## Erwartete Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/ui/ftl_readiness_gauge.gd`
- ggf. `scripts/ui/enhanced_fireteam_card.gd`
- `scenes/tests/mission_reactivity_test.tscn`
- `scripts/tests/task_369_fireteam_status_card_enhancement.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_369_fireteam_status_card_enhancement.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Zu viele Werte koennen die Karte ueberladen. Falls noetig muss der Task harte Prioritaeten setzen: Status zuerst, Detail nur im Tooltip/Selection.

