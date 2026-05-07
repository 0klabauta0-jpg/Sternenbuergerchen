# TASK_271 - Tactical Command Modes ROE Fire Rules

## Ziel
Der Commander braucht klare Regeln, die er Fireteam-Leadern mitgibt: Tempo, Feuerregel, Kontaktverhalten, Deckungsprioritaet, Sicherung und Risiko. Diese Regeln sollen im UI knapp waehltbar und in Runtime/Feedback testbar sein.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_093 - Discipline Hold-Fire-Disziplinbrueche
- TASK_109 - TacticalStanceController und TacticalStancePanel
- TASK_111 - FireteamSecurityController und Overwatch
- TASK_119 - Seeded Combat RNG und roll_override begrenzen
- TASK_270 - Commander to Fireteam Leader Delegation Contract

## Kontext
Der Spieler soll nicht nur "geh dahin" klicken. Er soll festlegen koennen, wie das Fireteam sich verhalten soll: vorsichtig, schnell, verdeckt, aggressiv, Feuer nur bei Freigabe, Feuer erwidern, unterdruecken, Kontakt vermeiden oder Ziel priorisieren.

## Umfang
1. Regelgruppen:
   - Tempo: cautious, normal, rapid.
   - Feuerregel: hold, return, free, suppress.
   - Kontakt: avoid, report, fix, assault, withdraw.
   - Deckung: low, normal, high.
   - Security: 360, facing, sector, none-in-transit.
2. UI-Vertrag:
   - Regeln als kompakte segmented controls oder kleine Buttons.
   - Nicht alle Regeln gleichzeitig sichtbar, wenn Kontext sie nicht braucht.
   - Help-Popup-IDs fuer jede Regel vorbereiten.
3. Runtime-Wirkung:
   - Regeln beeinflussen FTL-ExecutionPlan, nicht direkt einzelne NPCs im UI.
   - Discipline/Recognition/Leadership koennen Abweichungen erzeugen.
   - Waffenrange und Munition/Status werden respektiert.
4. Snapshot/Feedback:
   - #17 zeigt aktive Regeln knapp.
   - Map-Overlay zeigt nur starke Statusaenderungen.
   - FTL-Bubble/Radio meldet Regelkonflikte.
5. Validierung:
   - Unerlaubte Kombinationen blocken oder normalisieren.
   - Beispiel: `avoid contact` plus `free fire` braucht Warnung oder klare Prioritaet.

## Nicht-Ziele
- Keine echte Rules-of-Engagement-Simulation.
- Kein politischer/legaler ROE-Begriff im Spiel.
- Keine neuen Waffenwerte.
- Keine UI-Textwand.

## Akzeptanzkriterien
- [x] Taktische Regeln sind als kleine Datenstruktur definiert.
- [x] UI kann Tempo, Feuerregel, Kontaktverhalten, Deckung und Security setzen.
- [x] FTL-ExecutionPlan liest diese Regeln.
- [x] Ungueltige Kombinationen werden sichtbar verhindert oder normalisiert.
- [x] #17/#18 und Help-Popups erklaeren aktive Regeln kompakt.
- [x] Ein Verifier prueft Regelkombinationen, Snapshot und keine UI-Unit-Mutation.

## Erwartete Dateien
- `docs/dev/tactical_command_rules_contract.md`
- `scripts/tactical/tactical_command_rules.gd`
- `scripts/tests/task_271_tactical_command_modes_roe_fire_rules.gd`
- `data/contextual_help_catalog.json`
- `docs/tasks/TASK_271_tactical_command_modes_roe_fire_rules.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_271_tactical_command_modes_roe_fire_rules.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_109_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_111_verifier.gd`
- [x] `git diff --check`

## Risiken
- Zu viele Regeln machen das UI schwer. Defaults muessen gut sein.
- Feuerregeln duerfen Combat-Authority und RNG-Pfad nicht umgehen.

## Naechster Schritt
Nach TASK_271 kann TASK_272 mehrere Fireteams koordiniert auf ein gemeinsames Ziel planen lassen.
