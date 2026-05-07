# TASK_238 - Personnel Events Recruit Leave Dismiss Notifications

## Ziel
Das Roster soll sich spaeter veraendern koennen: neue Leute kommen dazu, andere gehen, werden entlassen, pausieren oder reagieren auf Team-/Missionsverlauf. V1 definiert den Ereignisvertrag und einfache Nachrichten.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_096 - Recovery Loop
- TASK_114 - Meta Recovery Integration
- TASK_234 - Persistent Player Roster Save and Reset
- TASK_237 - Mission Progression XP Morale Frustration

## Kontext
Der User hat einen Modus erwaehnt, z. B. nach drei Spielen mit dem Team, Personal wechseln/rauswerfen und Nachrichten. Das sollte nicht direkt als hartes Management-Monster starten, sondern als kleiner Event-Vertrag.

## Umfang
1. Personnel-Event-Modell:
   - recruit_available.
   - joins_roster.
   - leaves_roster.
   - dismissed.
   - unavailable.
   - returns.
   - requests_change.
2. Trigger V1:
   - Nach X Missionen, z. B. 3.
   - Hoher Frust.
   - Verletzung/Recovery.
   - Story-/Debug-Trigger fuer Tests.
3. Nachrichten:
   - Kurze Homebase-/Debrief-Nachricht.
   - Beispiel: `Mara bittet um Versetzung aus Fireteam Blau.`
   - Keine langen Dialogketten.
4. Entlassen/Personal schieben:
   - Dismiss/Remove nur mit Bestaetigung.
   - Auswirkungen auf Beziehung/Morale spaeter klein und testbar.
5. Recruiting:
   - Neue Kandidaten aus Generator/Katalog.
   - Kein Markt/Shop.
6. Verifier:
   - 3-Missionen-Trigger.
   - High-frustration request.
   - Dismiss confirmation.
   - Save/Load nach Event.

## Nicht-Ziele
- Kein komplettes HR-/Base-Management.
- Kein Wirtschaftssystem.
- Kein zufaelliges Story-Event-Deck.
- Kein Permadeath-Entscheid.

## Akzeptanzkriterien
- [x] Personnel-Events haben stabile IDs und Payloads.
- [x] Nach mehreren Missionen koennen Roster-Events ausgeloest werden.
- [x] Nachrichten erscheinen in Homebase/Debrief knapp.
- [x] Dismiss/Remove braucht Bestaetigung.
- [x] Roster-Save bleibt konsistent nach Join/Leave/Dismiss.
- [x] Ein TASK_238-Verifier prueft Trigger, Nachrichten und Save-Roundtrip.

## Erwartete Dateien
- `scripts/meta/personnel_event_model.gd`
- `scripts/meta/personnel_event_resolver.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/debrief_screen.gd`
- `scripts/meta/player_roster_store.gd`
- `scripts/tests/task_238_personnel_events_recruit_leave_dismiss_notifications.gd`
- `docs/tasks/TASK_238_personnel_events_recruit_leave_dismiss_notifications.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_238_personnel_events_recruit_leave_dismiss_notifications.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_237_mission_progression_xp_morale_frustration.gd`
- [x] Homebase-/Debrief-Nachrichtencheck laeuft im TASK_238-Verifier ueber beide Szenen.
- [x] `git diff --check`

## Risiken
- Zu frueh zu viele Events fuehlen sich willkuerlich an.
- Entlassen/Verlust muss klar kommuniziert werden, sonst wirkt es wie Datenverlust.

## Naechster Schritt
TASK_239 bindet Character-Gameplay in Mission, Bubbles und Gedanken an.
