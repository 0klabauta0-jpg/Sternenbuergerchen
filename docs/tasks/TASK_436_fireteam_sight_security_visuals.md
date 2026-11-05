# TASK_436 - Fireteam Sight Security Visuals

Fortsetzungsstand 05.11.2026: Die spaetere A5-Truppkarte aus
`UI_2026_11_02_a5_kartenrand.md` und `ui_native_design_contract.md` ersetzt
die sichtbaren Diagnosezeilen durch Portraits und einen primaeren Zustand.
Die Security-Coverage bleibt als lesender, ausgeblendeter Diagnose-Snapshot
erhalten. Der Verifier prueft diesen aktuellen Darstellungsvertrag und den
Parent-Profil-/Securityrefresh statt eines direkten Resolvereingriffs.
Einordnung: `../qa/continue_20261105_air_hud_audit.md`.

## Ziel / Problem

- Der manuelle Fireteam-Playtest zeigt mehrere sichtbare Baseline-Luecken: zu lange/unklare Sicht- und Feuerlinien, Defense-Facing wirkt gebuendelt, FTL-Bubbles lesen sich zu mittig, Muzzle Flash ist zu dezent, Gegner wirken ueberlagert und Busch-Cover sitzt falsch als Bodenvariante.

## Sinnhaftigkeit / Ursache

- Die neue Fireteam-Baseline ist funktional abgesichert, aber die Fenster-Signale muessen dem gleichen Vertrag folgen: Kopf/Sicht, Waffe/Feuer, Defense-Sektoren und Drillmap-Cover muessen fuer Playtests eindeutig lesbar sein.
- Security-Snapshots liefern bereits `member_assignments`, wurden aber noch nicht sauber als sichtbares Unit-Facing genutzt.

## Umfang

- Sight-/Fire-Sector-Linien im 3D-Overlay an Kopf-/Unit-Anker und die tatsaechliche Waffenreichweite binden.
- Defense-Facing fuer `360` und directional Defense sichtbar auf die Mitglieder verteilen.
- Eine kleine Security-Coverage-Anzeige an der Fireteam-Mini-Card ergaenzen.
- FTL-HUD-Bubbles linksbuendig/oben ausrichten und eher in Zeilen umbrechen.
- Muzzle-Flash/Trace besser sichtbar machen, ohne Combat-Wahrheit in die Visualschicht zu verschieben.
- Drillmap-Buesche wieder als Objekt-Cover auf Boden-Tiles setzen und Gegner im Drill sichtbarer verteilen/patrouillieren lassen.

## Nicht-Ziele

- Kein neues Flank-System.
- Kein neues Combat-/Ballistikmodell.
- Keine vollstaendige Enemy-AI-Iteration.
- Kein allgemeines UI-Redesign.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_435_fireteam_manual_visual_regression_pass.md`

## Akzeptanzkriterien

- [x] Friendly sight/fire visual entries haben einen Kopf-/Sichtanker und eine auf Waffenreichweite begrenzte Linienlaenge.
- [x] Muzzle Flash und Trace sind im Render-Snapshot sichtbar groesser/lesbarer.
- [x] Directional Defense verteilt vier Mitglieder als zwei Front-Sicherer plus linke/rechte Flanke; `360` bleibt kardinal verteilt.
- [x] Das sichtbare Unit-Facing folgt den Security-Assignments, wenn Defense aktiv ist.
- [x] Die Fireteam-Mini-Card liefert eine Security-Coverage-Bar mit Front-/Flanken-/360-Diagnose.
- [x] FTL-HUD-Bubbles sind oben/linksbuendig, umbrechen eher in Zeilen und bleiben nur moderat groesser.
- [x] Drillmap-Buesche sind Objekt-Cover auf Boden-Tiles; Gegner sind als vier getrennte Proxies lesbar und erhalten Patrol-Bindings.

## Betroffene Dateien

- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tactical/fireteam_security_controller.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/mission_test_setup.gd`
- `scripts/tools/generate_fireteam_command_drill_24x24.gd`
- `data/mission_scenarios/fireteam_command_drill_24x24.json`
- `maps/fireteam_command_drill_24x24.json`
- `scripts/tests/task_436_fireteam_sight_security_visuals.gd`
- `docs/tasks/TASK_436_fireteam_sight_security_visuals.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tools/generate_fireteam_command_drill_24x24.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_436_fireteam_sight_security_visuals.gd`
- Relevante Regressionen: TASK_401, TASK_424, TASK_429, TASK_435
- `git diff --check`

## Risiken / offene Punkte

- Fireline-Laenge bleibt ein Visual-Readability-Slice; Combat-Reichweite selbst bleibt in `WeaponData`/CombatLoop unveraendert.
- Gegner-Patrol ist nur fuer die Drillmap sichtbar gemacht und ersetzt keine vollstaendige Enemy-Team-Taktik.
