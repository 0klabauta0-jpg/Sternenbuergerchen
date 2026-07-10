# TASK_1050 - LZ Drop and Deboard Flow Timing Breakdown

## Befund

Nach TASK_1049 erreicht der echte Spielerflow LZ/Drop. LZ-Setzen dauerte rund 13,8 Sekunden; der opt-in Teilpfad-Timer misst rund 13,2 Sekunden davon in `_emit_planning_state_changed()`. Tile-Kontext, Auswahl, World-Overlay und HUD liegen jeweils deutlich darunter.

## Ergebnis

Der naechste echte Blocker ist der Planning-State-Signal-Fanout, nicht Dropship-Bewegung oder Deboarding. TASK_1051 muss Empfaenger und wiederholte UI-/Planungsarbeit dieses Signals auditieren und begrenzen, ohne Planning-Wahrheit zu verdoppeln.

## Lokale Pruefung

`TASK_1045` meldet `lz_timing` mit read-only Teilzeiten und beendet kontrolliert an `lz_drop_and_deboard`.
