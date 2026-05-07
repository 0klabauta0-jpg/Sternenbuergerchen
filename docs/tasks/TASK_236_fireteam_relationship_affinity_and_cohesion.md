# TASK_236 - Fireteam Relationship Affinity and Cohesion

## Ziel
NPCs sollen Sympathien, Asympathien und Fireteam-Cohesion bekommen. Dadurch ist Teamzusammenstellung nicht nur "beste Werte addieren", sondern eine Entscheidung mit Menschen, Routinen und Reibung.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_048 - Einfache Persoenlichkeitsmerkmale
- TASK_088 - Leadership Bonus
- TASK_111 - Fireteam Security Direction and Overwatch
- TASK_188 - Fireteam Advance Styles Map Readability
- TASK_232 - Start Roster Generation Contract
- TASK_235 - Character Sheet Roster Gameplay Expansion

## Kontext
Der Spieler soll mit einem Startteam arbeiten muessen. Manche NPCs funktionieren gut zusammen, manche schlecht, manche brauchen feste Fireteams. Das kann spaeter Bubbles, Gedanken, Advance-Stile, Moral und Progression beeinflussen.

## Umfang
1. Relationship-Modell:
   - Pairwise affinity: -100 bis +100 oder kleiner normierter Wert.
   - Tags: friend, rival, trusts, avoids, mentor, tension.
   - Asymmetrie erlauben, aber V1 kann symmetrisch starten.
2. Cohesion:
   - Fireteam-Cohesion aus gemeinsamer Mission, Affinity, Leadership und Stabilitaet.
   - Neue Teams starten niedriger, feste Teams koennen besser werden.
3. Generator:
   - Start-Roster bekommt einige kleine Beziehungen.
   - Nicht jeder kennt jeden.
   - Keine extremen Werte ohne Grund.
4. Gameplay-Wirkung V1:
   - Kleine Modifikatoren auf morale/communication/coordination oder Advance-Lesbarkeit.
   - Keine massiven Combat-Boni.
   - Resolver zentral, nicht ueberall verteilt.
5. UI:
   - Character Sheet zeigt beste/schlechteste Beziehungen knapp.
   - Fireteam Card zeigt Cohesion/Teamfit.
6. Verifier:
   - Relationship-Roundtrip.
   - Cohesion berechnet deterministisch.
   - Falsches Team kann kleine Nachteile erzeugen.

## Nicht-Ziele
- Kein Dating-/Dialogsystem.
- Keine langen Social-Szenen.
- Keine zufaelligen Mission-Drama-Events.
- Kein grosser Balance-Pass.

## Akzeptanzkriterien
- [x] NPC-Paare koennen Sympathie/Asympathie-Werte tragen.
- [x] Fireteam-Cohesion wird aus Beziehungen und gemeinsamer Nutzung abgeleitet.
- [x] UI zeigt Teamfit knapp und verstaendlich.
- [x] Gameplay-Modifikatoren sind klein, zentral und testbar.
- [x] Beziehungen werden im Roster-Save gespeichert.
- [x] Ein TASK_236-Verifier prueft Roundtrip, Cohesion und kleine Gameplaywirkung.

## Umsetzung
- `RosterRelationshipModel` normalisiert pairwise Affinity von `-1.0` bis `+1.0`, Tags wie `trusts`, `friend`, `rival`, `tension` und symmetrische V1-Links.
- `StartRosterGenerator` erzeugt deterministisch milde Startbeziehungen, ohne ein vollstaendiges Jeder-kennt-jeden-Netz zu bauen.
- `FireteamCohesionResolver` berechnet Cohesion aus Affinity, bekannter Paarzahl, gemeinsamer Fireteam-Historie und Leadership. Die Gameplay-Modifikatoren bleiben auf kleine Morale-/Communication-/Coordination-/Advance-Readability-Werte begrenzt.
- `PlayerRosterStore` validiert Relationship-Daten beim Save-Payload und speichert `relationship_pairs` sowie Unit-`relationship_links`.
- Character Sheet zeigt Teamfit, beste Beziehung und groesste Spannung. Die FOB-Fireteam-Card rendert eine kurze Teamfit-/Cohesion-Zeile.

## Erwartete Dateien
- `scripts/meta/roster_relationship_model.gd`
- `scripts/meta/fireteam_cohesion_resolver.gd`
- `scripts/meta/player_roster_store.gd`
- `scripts/meta/character_sheet_formatter.gd`
- `scripts/meta/fob_fireteam_card.gd`
- `scripts/tests/task_236_fireteam_relationship_affinity_and_cohesion.gd`
- `docs/tasks/TASK_236_fireteam_relationship_affinity_and_cohesion.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_236_fireteam_relationship_affinity_and_cohesion.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_235_character_sheet_roster_gameplay_expansion.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_234_persistent_player_roster_save_and_reset.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_232_start_roster_generation_contract.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_176_fob_loadout_weapon_preview_selector_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_178_fob_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] Headless Fireteam-Card-Sichtcheck im TASK_236-Verifier.
- [x] `git diff --check`

## Risiken
- Zu starke Relationship-Boni koennen Loadout/Skill-System entwerten.
- Zu viel sichtbare Soziallogik macht die UI unruhig. V1 bleibt knapp.

## Naechster Schritt
Nach TASK_236 kann TASK_237 Missionserfahrung und Progression auswerten.
