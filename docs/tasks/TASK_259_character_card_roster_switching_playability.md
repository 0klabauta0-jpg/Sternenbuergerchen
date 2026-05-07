# TASK_259 - Character Card Roster Switching Playability

## Ziel
Der Spieler soll ueberall sinnvoll an Charakterkarten kommen und Roster-/Fireteam-Umstellungen ohne verlorene Daten durchfuehren koennen. Der Task prueft Charakterkarten-Zugriff, Auswahlwechsel, Teamtransfer, Fireteam-Zuweisung, Character Sheet, Mission-/Debrief-Rueckwege und Persistenz.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_073 - Homebase: Charakterbogen und Drag-and-Drop-Teamstaging
- TASK_080 - Meta-Layer: Transfer-Sichtbarkeit Pool-DnD und Charakterbogen-Toggle
- TASK_175 - NPC Loadout Attachments
- TASK_232 - Start Roster Generation Contract
- TASK_233 - Portrait Identity Catalog and Roster Presentation
- TASK_235 - Character Sheet Roster Gameplay Expansion
- TASK_256 - Automated Playability Coverage Contract
- TASK_258 - Fixed Window Clipping Scrollbar Playability Audit

## Kontext
Charakter-Gameplay wird nur gut, wenn der Spieler nicht suchen muss: Wer ist das, welche Werte hat die Person, wo ist sie im Team, kann ich sie umstellen, was passiert mit Loadout und Gewicht, und bleibt das beim Screenwechsel erhalten?

## Umfang
1. Charakterkarten-Zugriff:
   - Homebase-Roster.
   - Transfer-Team.
   - FOB-Fireteams.
   - Loadout-Slots.
   - Mission-Selected-Fireteam.
   - Debrief/Progression soweit vorgesehen.
2. Auswahlverhalten:
   - Klick auf NPC oeffnet/aktualisiert Character Card.
   - Wechsel zwischen NPCs verliert Auswahl nicht unerwartet.
   - Rueckwege bringen den Spieler in den erwarteten Screen/Slot zurueck.
3. Umstellen:
   - Pool -> Team.
   - Team -> Fireteam.
   - Fireteam -> anderer Slot.
   - Entfernen/Zuruecklegen.
   - Unzulaessige Umstellung gibt klares Feedback und verliert keine Unit.
4. Persistenz:
   - Screenwechsel Homebase -> FOB -> Mission -> Debrief -> Homebase.
   - Roster-Save/Load.
   - Fireteam-Zuweisungen bleiben erhalten oder werden bewusst zurueckgesetzt.
5. Datenintegritaet:
   - Keine doppelte Unit.
   - Keine verschwundene Unit.
   - Portrait/Name/Skills/Traits/Loadout bleiben konsistent.
   - Character Card zeigt dieselbe Unit-ID wie Auswahl/Slot.
6. Bericht:
   - Verlorener State, doppelte IDs, fehlende Character Card, tote Rueckwege.

## Nicht-Ziele
- Kein finales Character-Balancing.
- Keine neue Relationship-Mechanik.
- Keine komplette Drag-and-Drop-Neuimplementierung.
- Kein manueller Volltest jedes NPC-Portraits.

## Akzeptanzkriterien
- [x] Character Card ist von allen Pflichtorten erreichbar.
- [x] NPC-Auswahl und Character Card bleiben synchron.
- [x] Fireteam-/Roster-Umstellungen verlieren oder duplizieren keine Units.
- [x] Unzulaessige Umstellungen blocken sauber mit Feedback.
- [x] Screenwechsel und Save/Load erhalten erwartete Roster-Daten.
- [x] Ein automatisierter Report nennt offene manuelle Restchecks.

## Umsetzung
- `scripts/tests/task_259_character_card_roster_switching_playability.gd` prueft Homebase-Roster, Homebase-Transfer-Team, FOB-Fireteams, FOB-Loadout-Slots, Mission-Selected-Fireteam und Debrief-Progression ueber die bestehenden Card-Signale und Screen-APIs.
- Der Verifier deckt Pool -> Team, Team -> Pool, Fireteam -> Fireteam, Clear-to-Pool, Pool -> Fireteam, blockierte Duplikate/ungueltige Umstellungen, Character-Sheet-Synchronitaet, Save/Load und Mission-Progression ohne Unit-Verlust ab.
- `docs/reports/playability_character_card_roster_switching_report.md` dokumentiert abgedeckte Screens, State-Integrity-Regeln, automatische Findings und manuelle Restpunkte.

## Erwartete Dateien
- `scripts/tests/task_259_character_card_roster_switching_playability.gd`
- `docs/reports/playability_character_card_roster_switching_report.md`
- `scripts/tests/playability/playability_test_harness.gd`
- `docs/tasks/TASK_259_character_card_roster_switching_playability.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_259_character_card_roster_switching_playability.gd` (51/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_241_character_gameplay_playability_smoke.gd` (34/0)
- [x] `git diff --check`

## Risiken
- Drag-and-drop ist headless schwerer zu pruefen als direkte API-/Signalwege; der Task soll deshalb beides trennen.
- Bestehende Testdaten muessen genug NPCs und lange Namen enthalten, sonst bleiben echte Roster-Probleme unsichtbar.

## Naechster Schritt
Nach TASK_259 prueft TASK_260 Loadout-Auswahl, Zierwaffen, keine Waffe und Gewichtsauswirkungen.
