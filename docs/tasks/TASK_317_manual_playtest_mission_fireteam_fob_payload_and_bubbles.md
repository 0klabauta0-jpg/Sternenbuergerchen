# TASK_317 - Manual Playtest Mission Fireteam FOB Payload and Bubbles

## Ziel
Die Mission Map soll die in der FOB zusammengestellten Fireteams korrekt uebernehmen. Fireteam-Karten, Leader-Portraits und Sprechblasen duerfen nicht mehr auf generische Preset- oder Debug-NPCs zurueckfallen.

## Status: IMPLEMENTIERT

## Kontext
Im manuellen Playtest zeigte `#17 SELECTED FIRETEAM` teilweise falsche Mitglieder und falsche Leader. Die Fireteam-Minikarte spiegelte nicht die FOB-Zusammenstellung, und mehrere Sprechblasen ueberlagerten sich bzw. zeigten ihren Haken in die falsche Richtung.

## Umfang
1. Mission Payload:
   - MissionStart uebergibt die FOB-Unit-Konfigurationen an den Mission-Setup-Pfad.
   - Fireteam-Mitgliedschaft, Namen, Profile und Portraits kommen aus der FOB-Zusammenstellung.
2. Fireteam Leader:
   - Die Fireteam-Karte priorisiert den konfigurierten Fireteam-Lead.
   - Das Lead-Portrait in der Minikarte folgt dem FOB-Lead.
3. Sprechblasen:
   - Feedback-Bubbles an Fireteam-Karten sind kleiner.
   - Der Bubble-Haken sitzt links an der Fireteam-Karte.
   - Mehrere Bubbles werden vertikal versetzt, statt unlesbar uebereinanderzuliegen.

## Nicht-Ziele
- Keine neue Fireteam-Wahrheit in HUD-Skripten.
- Keine Aenderung an Combat-, Pathfinding- oder SimulationRoot-Entscheidungen.
- Keine finale Art-Direction der Bubble-Grafik.

## Akzeptanzkriterien
- [x] Mission-Fireteams spiegeln FOB-Mitglieder.
- [x] Leader-Portrait kommt vom FOB-Fireteam-Lead.
- [x] Generische `Player Sternbergerchen xx`-Fallbacks werden im FOB-Transferpfad vermieden.
- [x] Bubbles bleiben lesbar und vermeiden direkte Ueberlagerung.

## Erwartete Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/bugfix_mission_fireteam_fob_payload_and_bubbles.gd`
- `scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- `docs/tasks/TASK_317_manual_playtest_mission_fireteam_fob_payload_and_bubbles.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `bugfix_mission_fireteam_fob_payload_and_bubbles.gd`
- [x] `task_210_fireteamleader_command_feedback_bubbles.gd`
- [x] `task_087_verifier.gd`
- [x] `task_160_tactical_playability_verifier.gd`
- [x] `task_316_fob_fireteam_staging_migration.gd`
- [x] `bugfix_dropship_mission_flow_verifier.gd`
- [x] `git diff --check`

## Risiken
- Finales Bubble-Spacing bleibt ein manueller FullHD-Sichtcheck.
- Weitere Mission-HUD-Politur darf diese Datenuebergabe nicht wieder durch Preset-Fallbacks ueberdecken.
