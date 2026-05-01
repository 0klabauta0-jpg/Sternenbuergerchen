# TASK_154 - Gameloop Smoke Test

## Ziel
Ein kontrollierter End-to-End-Smoke-Test prueft, ob der aktuelle V1-Gameloop einmal komplett durchlaufbar ist: Homebase -> Team -> FOB -> Dropship/LZ -> Mission -> Ergebnis -> Rueckkehr.

## Status: GEPLANT

## Voraussetzung
- `TASK_150 - Legacy 2D Mission Asset Retirement`

## Kontext
- Die 3D/2.5D-Missionsdarstellung ist nach `TASK_146` bis `TASK_150` der normale Missionsblick.
- Viele Einzelsysteme sind per Task-Verifier abgesichert, aber der zusammenhaengende Spielerfluss braucht einen eigenen Smoke-Test.

## Umfang
1. Startpfad pruefen:
   - Homebase laedt.
   - Team-/Roster-Auswahl ist bedienbar.
   - FOB zeigt gewaehltes Team und Dropship-/Loadout-Status.
2. Missionspfad pruefen:
   - Mission startet aus dem Meta-Layer.
   - 3D-Mission ist primaer sichtbar.
   - LZ/Target/Waypoint setzen funktioniert.
   - Fireteam-Befehl erreicht `SimulationRoot`.
3. Einsatzverlauf pruefen:
   - Insertion/Dropship-Aktivierung laeuft.
   - Units bewegen/kaempfen/koennen fallen oder respawnen.
   - Mission kann ein Ergebnis erzeugen.
4. Rueckkehr pruefen:
   - Debrief/FOB/Homebase-Rueckfluss bleibt erreichbar.
   - Keine offensichtlichen Nullrefs oder blockierten UI-Zustaende.
5. Verifier/Smoke:
   - automatisierter Headless-Smoke soweit sinnvoll.
   - manuelle Checkliste fuer die Teile, die echte Bedienung brauchen.

## Nicht-Ziele
- Kein Balancing.
- Keine neuen Features.
- Keine finale UI-Politur.
- Kein Asset-Loeschen.

## Architekturregeln
- Smoke-Test darf keine Gameplay-Wahrheit in UI verschieben.
- Test-Glue muss bestehende Meta-/Missionseinstiegspunkte nutzen.
- Fehler werden dokumentiert und als Folgetasks geschnitten, statt im Smoke-Test gross refaktoriert zu werden.

## Akzeptanzkriterien
- [ ] Ein definierter V1-Gameloop-Pfad ist dokumentiert.
- [ ] Automatisierter Smoke prueft die wichtigsten Szenenuebergaenge ohne Gameplay-Mutation ausserhalb bestehender Systeme.
- [ ] Manuelle Checkliste beschreibt konkrete Klick-/Hotkey-Schritte.
- [ ] Bekannte Blocker fuer echten Playtest sind klar benannt.

## Erwartetes Ergebnis
Nach diesem Task ist klar, ob der aktuelle Stand als erster zusammenhaengender Gameloop spielbar ist oder welche kleinen Blocker noch vor dem eigentlichen Playtest entfernt werden muessen.

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_154_verifier.gd`
- [ ] Manuell Homebase -> FOB -> Mission -> Rueckkehr durchspielen.

## Dateien (voraussichtlich)
- `scripts/tests/task_154_verifier.gd`
- `docs/tasks/TASK_154_gameloop_smoke_test.md`
- optional: `docs/gameloop_smoke_checklist.md`

## Risiken
- Der Smoke-Test darf nicht zum Ersatz fuer echte Systemtests werden. Er soll den Loop pruefen, nicht alle Einzelsysteme neu absichern.
