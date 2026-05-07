# TASK_276 - Tactical Breakout and Exception Behavior

## Ziel
Fireteams sollen bei definierten Ausbruechen sinnvoll reagieren koennen: Kontakt, Unterdrueckung, Verletzte, blockierter Pfad, falsche Reichweite, niedrige Munition, Leader down, LZ bedroht, Dropship/Frachter bedroht oder Plan widerspricht aktiver Regel.

Der Spieler muss sehen, wann ein Team abweicht, warum es abweicht und ob Rueckfrage oder automatische Anpassung laeuft.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_103 - Suppression Interruption und Return-to-Plan
- TASK_105 - Leader-Nachfolge Lead-Rueckgabe und UI-Synchronisierung
- TASK_111 - FireteamSecurityController und Overwatch
- TASK_189 - Medic Adjacent Tile Healing Rule
- TASK_270 - Commander to Fireteam Leader Delegation Contract
- TASK_271 - Tactical Command Modes ROE Fire Rules
- TASK_274 - Tactical Communication Feedback Layer

## Kontext
Dynamik entsteht nicht nur durch neue Befehle, sondern durch kontrollierte Ausnahmen. Ein gutes Fireteam soll nicht blind in eine blockierte LZ laufen. Aber es darf auch nicht den Commander ignorieren. Deshalb braucht es klare Ausbruchsklassen.

## Umfang
1. Ausbruchsklassen:
   - `auto_adapt`: Route leicht anpassen, Deckung nehmen.
   - `hold_and_report`: anhalten, sichern, Meldung.
   - `request_orders`: Rueckfrage an Spieler.
   - `abort_to_safe`: kritischer Abbruch bei Luftfahrzeug-/Teamverlust.
2. Trigger:
   - Contact.
   - Suppressed/pinned.
   - Casualty/medic needed.
   - Blocked route/no path.
   - Out of weapon range.
   - Low ammo/no weapon.
   - Leader down.
   - Air asset threatened/destroyed.
3. FTL-Skill:
   - Hoher Skill erkennt und kommuniziert frueher.
   - Niedriger Skill reagiert spaeter oder braucht eher Rueckfrage.
4. UI/Feedback:
   - Kurze Ausbruchlabels.
   - #17 zeigt Ursache und Status.
   - #18 zeigt Spieleroptionen: confirm, override, abort, regroup.
5. Verifier:
   - Jeder Trigger erzeugt erwartete Ausbruchsklasse.
   - Keine Ausbrueche ohne Event-ID.
   - Return-to-plan nach geloester Blockade.

## Nicht-Ziele
- Keine vollstaendige autonome KI.
- Kein Moral-Paniksystem.
- Kein komplexes Munitionssystem, falls noch nicht vorhanden.
- Keine echten Militaerdrills.

## Akzeptanzkriterien
- [x] Ausbruchsklassen und Trigger sind datengetrieben definiert.
- [x] FTL-Ausbrueche bleiben innerhalb Commander-Regeln oder fragen sichtbar rueck.
- [x] Spieler sieht Ursache, Status und naechste Option.
- [x] Return-to-plan funktioniert nach geloesten einfachen Ausbruechen.
- [x] Leader down und Medic-Fall bleiben konsistent.
- [x] Ein Verifier prueft alle Kerntrigger und Feedback.

## Erwartete Dateien
- `docs/dev/tactical_breakout_exception_contract.md`
- `scripts/tactical/tactical_breakout_resolver.gd`
- `scripts/tactical/fireteam_execution_plan.gd`
- `scripts/tests/task_276_tactical_breakout_and_exception_behavior.gd`
- `docs/tasks/TASK_276_tactical_breakout_and_exception_behavior.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_276_tactical_breakout_and_exception_behavior.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_103_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_189_medic_adjacent_tile_healing_rule.gd`
- [x] `git diff --check`

## Risiken
- Zu viele automatische Ausbrueche koennen Commander-Kontrolle verwaessern.
- Zu viele Rueckfragen koennen das Spiel stocken lassen.

## Naechster Schritt
Nach TASK_276 kann TASK_277 Luftfahrzeuge als taktische Ziele und Risiken sauber einbauen.
