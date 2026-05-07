# TASK_191 - Command Chain Selection and Area Feedback Pass

## Ziel
Auswahl, Befehlskette, Area-Einnahme und Feedback auf der Mission Map sollen einmal zusammenhaengend geprueft und geglaettet werden.

Der Spieler soll kurz und eindeutig sehen: Wer ist ausgewaehlt, welcher Befehl laeuft, welches Gebiet wird bearbeitet, was macht das Fireteam gerade, und wo wird das im UI angezeigt.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_121 - Area Order Marker
- TASK_122 - Defend Area Semantik
- TASK_123 - Attack Area Semantik
- TASK_124 - Area Feedback in #17 Selected Fireteam
- TASK_160 - Tactical Mission Playability Smoke
- TASK_188 - Fireteam Advance Styles Map Readability
- TASK_190 - Weapon Visual Loadout Expansion and Scale

## Kontext
Viele Teile existieren bereits: Commander Commands, Area Orders, TacticalController, #16 Command Matrix, #17 Selected Fireteam, #18 Mission Control, Map-Overlays und 2.5D-Snapshots. Dieser Task schaut nicht auf ein einzelnes Feature, sondern auf die Frage, ob der Ablauf fuer `Move`, `Defend`, `Take`, `Engage/Attack Area` und Auswahlwechsel zusammenpasst.

## Umfang
1. Befehlskette dokumentieren:
   - UI-Input in #16/#18 oder Map.
   - TacticalController/Planning-State.
   - CommanderCommand/AreaOrder/FireteamWaypoint.
   - FTL-/Fireteam-Controller.
   - SimulationRoot/Effects.
   - Snapshot/Visualizer/#17.
2. Auswahl-Pass:
   - Einzelnes Fireteam.
   - Mehrfachauswahl.
   - Unit-/NPC-Auswahl innerhalb Fireteam.
   - Enemy-Auswahl oder Enemy-Inspect, falls vorhanden, klar vom Friendly-Befehlspfad trennen.
3. Area einnehmen:
   - `take` muss zeigen, welche Tiles gesichert sind und was als Fortschritt gilt.
   - Capture/Objective-Status muss aus Runtime-State kommen.
   - Map zeigt Flaeche/Fortschritt knapp; #17 zeigt Details; #18 zeigt naechste erlaubte Aktionen.
4. Copy- und Fenster-Regel:
   - Lange Erklaertexte aus der Map fernhalten.
   - #17 fuer Ausfuehrungsstatus.
   - #18 fuer Missions-/Command-Control.
   - #16 fuer kurze Commands.
   - Texte kurz halten und Begriffe vereinheitlichen.
5. Code-Aehnlichkeit:
   - Move/Defend/Take/Engage sollen denselben Datenfluss verwenden, wo sinnvoll.
   - Keine parallelen Sonderpfade nur fuer ein Fenster.
   - UI liest Snapshots, aber verwaltet keine Gameplay-Wahrheit.
6. Verifier:
   - Erstellt Befehle fuer Move, Defend, Take und Attack/Engage Area.
   - Prueft Datenfluss und Statusstrings.
   - Prueft, dass Map-Overlay, #17 und #18 nicht widersprechen.

## Nicht-Ziele
- Keine neue Area-Semantik.
- Keine neue KI.
- Keine neuen Waffenregeln.
- Kein grosses HUD-Redesign.
- Keine langen Tutorialtexte.

## Akzeptanzkriterien
- [x] Auswahlzustand ist in Map-Snapshot, #17 und Command-Controls konsistent.
- [x] Move/Defend/Take/Engage Area laufen ueber nachvollziehbare, aehnliche Datenpfade.
- [x] Take Area zeigt Fortschritt und gesicherte Tiles kurz und eindeutig.
- [x] #16, #17 und #18 haben klare Rollen und zeigen keine widerspruechlichen Status.
- [x] Welt-Overlay bleibt kurz und verdeckt NPCs nicht.
- [x] Ein TASK_191-Verifier prueft Command Chain, Auswahlwechsel, Area Take und UI-Statusstrings.

## Erwartete Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/command/commander_command.gd`
- `scripts/command/area_order.gd`
- `scripts/command/fireteam_waypoint.gd`
- `scripts/tactical/area_order_resolver.gd`
- `scripts/tactical/visuals/fireteam_order_visualizer.gd`
- `scripts/tests/task_191_command_chain_selection_area_feedback_pass.gd`
- optional `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_191_command_chain_selection_area_feedback_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_191_command_chain_selection_area_feedback_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_121_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_122_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_123_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_124_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [ ] Manueller Mission-Map-Sichtcheck: Auswahl, Take Area, GO, Fortschritt, Kontakt.
- [x] `git diff --check`

## Umsetzung
- `MissionTacticalSandboxController.get_command_feedback_snapshot()` fasst Auswahl, #16-Command-Buttons, #17/#18-Texte, Waypoint-/Area-Zaehler und aktive Area-Snapshots fuer Headless-Tests zusammen.
- `TerrainMap3DView.get_render_snapshot()` spiegelt `order_selected_fireteam_ids` und `order_phase_index`, damit Map-Auswahl gegen UI-Auswahl testbar ist.
- `docs/dev/mission_command_feedback_contract.md` dokumentiert Datenfluss und Fensterrollen fuer #16, #17, #18 und Map.
- `task_191_command_chain_selection_area_feedback_pass.gd` prueft Auswahlwechsel, Multi-Selection, Move/Defend/Take-Waypoints, Take-/Engage-Areas, kompakte Texte und Map-Snapshot-Konsistenz.

## Risiken
- Der Task kann leicht zu einem HUD-Redesign werden. Ziel ist Feedback-Konsistenz, nicht neue Fensterarchitektur.
- Zu ausfuehrliche Texte machen die Mission langsamer lesbar. Lieber wenige stabile Statuszeilen.

## Naechster Schritt
Nach TASK_191 sollte die Mission Map als Bedienfluss stabil wirken. TASK_192 fasst danach die ganze Reihe in einem Playability-Smoke zusammen.
