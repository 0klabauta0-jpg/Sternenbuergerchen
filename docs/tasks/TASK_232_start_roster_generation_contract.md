# TASK_232 - Start Roster Generation Contract

## Ziel
Beim ersten Spielstart oder ueber einen Button `Neues Team generieren` soll ein individuelles Startteam erzeugt werden: etwa 20 bis 30 NPCs mit Namen, Portrait, Callsign, Skills, Traits, Rollen und ersten Fireteam-Vorschlaegen.

Das Startteam ist nicht nur Testdaten, sondern die Grundlage fuer Character-Gameplay und Fortschritt.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_046 - Unit-Skill-Werte
- TASK_048 - Einfache Persoenlichkeitsmerkmale
- TASK_049 - Heimatbasis Skills UI
- TASK_207 - NPC Rank Skill Badge Derivation
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay

## Kontext
Aktuell gibt es `MetaUnitProfile`, Profile Builder, Character Sheet, Skills und Traits. Es fehlt aber ein persistenter Roster-Start: Spieler sollen nicht immer frei die "besten" NPCs aus einer beliebigen Liste nehmen, sondern mit einem eigenen Startteam leben und dieses weiterentwickeln.

## Umfang
1. Roster-Generator-Vertrag:
   - Seeded Generator mit reproduzierbarem Output.
   - Defaultgroesse: 24 NPCs.
   - erlaubter Bereich: 20 bis 30 NPCs.
   - stabile NPC-IDs, Namen, Callsigns und Profile.
2. Rollenmix:
   - Medic, Shooter, Leader, Engineer, Pilot, Heavy/Support, Scout/Sniper als Startkategorien.
   - Keine perfekte Verteilung; kleine Staerken und Schwaechen sind gewollt.
3. Skillwerte:
   - Aus vorhandenen Skill-/Trait-Systemen aufbauen.
   - Werte in sinnvollen Bereichen clampen.
   - Top-3-Badges aus TASK_207 ableitbar halten.
4. Fireteam-Vorschlaege:
   - Generator kann erste feste Fireteams vorschlagen.
   - Spieler darf spaeter umbauen, aber nicht automatisch immer optimiert bekommen.
5. UI-Trigger:
   - Erster Spielstart prueft, ob ein Roster existiert.
   - Button `Neues Team generieren` nur mit klarer Reset-/Bestaetigungsgrenze.
6. Multiplayer:
   - Roster ist pro Spieler/Profil, nicht global fuer alle Peers.
   - Host kann eigene Roster haben; Join kann eigenes Roster haben, wenn der Modus das erlaubt.

## Nicht-Ziele
- Kein komplettes Progressionssystem.
- Kein Recruiting-/Entlassungsflow.
- Keine Balance-Perfektion.
- Kein Online-Profilservice.

## Akzeptanzkriterien
- [x] Ein Start-Roster-Generator erzeugt 20 bis 30 gueltige Meta-Unit-Profile.
- [x] Seeded Runs sind reproduzierbar.
- [x] Rollenmix, Skills, Traits und Badges sind plausibel verteilt.
- [x] Roster-Erzeugung kann beim ersten Spielstart und per Button angestossen werden.
- [x] Multiplayer-Grenze pro Spieler/Profil ist dokumentiert.
- [x] Ein TASK_232-Verifier prueft Groesse, Eindeutigkeit, Seed-Stabilitaet und Profilvaliditaet.

## Erwartete Dateien
- `scripts/meta/start_roster_generator.gd`
- `scripts/meta/meta_unit_profile.gd`
- `scripts/meta/meta_unit_profile_builder.gd`
- `scripts/ui/main_menu_screen.gd`
- `docs/dev/character_roster_generation_contract.md`
- `scripts/tests/task_232_start_roster_generation_contract.gd`
- `docs/tasks/TASK_232_start_roster_generation_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_232_start_roster_generation_contract.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_207_npc_rank_skill_badge_derivation.gd`
- [x] `git diff --check`

## Risiken
- Wenn der Generator zu perfekt ausbalanciert, wird Teamzusammenstellung uninteressant.
- Wenn er zu zufaellig ist, kann ein Startteam unspielbar werden. Es braucht Plausibilitaetsgrenzen.
- Persistentes Speichern, Archivieren und echter Reset sind bewusst TASK_234, nicht Teil dieses Vertrags.

## Naechster Schritt
Nach TASK_232 ordnet TASK_233 die vorhandenen Portraits und Identity-Assets sauber zu.
