# TASK_336 - Combat Loop Tick Budget System Split

## Ziel
Der Combat-Loop-Tick soll besser budgetierbar und wartbarer werden. Der Task trennt die grossen Tick-Phasen in klar benannte Systeme oder eine explizite Phasenliste, ohne Kampfregeln fachlich neu zu balancen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_218 - Simulation Combat AI Tick Budget Pass
- TASK_282 - Tactical Overhaul Playability Performance Help Gate

## Kontext
`MissionCombatLoopDriver._on_tick_processed()` ruft viele Systeme in einem grossen Tick-Pfad auf: Bleedout, Leadership, Detection, Kontakte, Enemy Security/Tactics, Flank Vulnerability, Cooldowns, Medic, Advance, Overwatch, Angriffe, Resolution und Snapshot-Kontext. Profilbereiche existieren teilweise, aber die Struktur bleibt schwer zu lesen und schwer einzeln zu budgetieren.

## Umfang
1. Phaseninventar:
   - Bestehende Tick-Schritte in Reihenfolge dokumentieren.
   - Harte Reihenfolge-Abhaengigkeiten sichtbar machen.
2. System-Schnitt:
   - Kleine interne Phasenliste oder Helper-Methoden/Komponenten einfuehren.
   - Bestehende Reihenfolge und Ergebnisse erhalten.
3. Budget-Telemetrie:
   - Pro Phase Dauer/Zaehler in einem Headless-Report erfassen.
   - Kandidaten fuer spaetere Every-N-Ticks-Ausfuehrung markieren, aber nur umsetzen, wenn fachlich risikofrei.
4. Regression:
   - Combat-, Tactical- und Performance-Gates gegen Verhaltensdrift absichern.

## Nicht-Ziele
- Keine Kampf- oder AI-Balance-Aenderung.
- Kein neuer Enemy-Tactics-Entwurf.
- Keine Threading- oder Job-System-Einfuehrung.
- Kein Verschieben der Autoritaet aus `SimulationRoot`.

## Akzeptanzkriterien
- [x] Combat-Tick-Phasen sind klar benannt und im Code leichter isolierbar.
- [x] Ein Report zeigt Phase-Dauer, Hauptzaehler und offene Kandidaten fuer spaetere Budgetierung.
- [x] Bestehende taktische Smokes bleiben gruen.
- [x] Keine Snapshot- oder Multiplayer-Authority-Regression.

## Erwartete Dateien
- `scripts/mission/**` oder der aktuelle Combat-Loop-Driver-Pfad
- optional kleine neue Helper unter `scripts/mission/combat/`
- `scripts/tests/task_336_combat_loop_tick_budget_system_split.gd`
- `docs/reports/combat_loop_tick_budget_system_split.md`
- `docs/tasks/TASK_336_combat_loop_tick_budget_system_split.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_336_combat_loop_tick_budget_system_split.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_218_simulation_combat_ai_tick_budget_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_282_tactical_overhaul_playability_performance_help_gate.gd`
- [x] `git diff --check`

## Risiken
- Reine Methoden-Extraktion kann trotzdem Reihenfolgefehler erzeugen. Deshalb muss der Task sehr kleine Schritte und einen Reihenfolge-Report erzwingen.

## Naechster Schritt
Falls einzelne Phasen auffaellig teuer bleiben, folgt ein gezielter Every-N-Ticks- oder AI-Budget-Task.
