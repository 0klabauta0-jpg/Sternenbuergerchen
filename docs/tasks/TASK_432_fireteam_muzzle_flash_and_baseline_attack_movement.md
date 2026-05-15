# TASK_432 - Fireteam Muzzle Flash And Baseline Attack Movement

## Ziel / Problem

- Schuesse brauchen einen gut sichtbaren Muzzle Flash, damit Feuerkontakt im Playtest eindeutig lesbar ist.
- `Engage` und `Take` sollen zuerst als normale, gemeinsame Angriffsbewegung laufen. Autonome Flank-/Fancy-Abweichungen sollen diese Basisrunde nicht ueberdecken.
- `Engage Area` darf nicht wie `Take Area` automatisch eine Besitz-/Besetzungsphase erzwingen.
- Drill- und Auswahlvisuals sollen zeigen, dass alle vier eigenen und gegnerischen NPCs als 3D-Proxies vorhanden sind, ohne doppelte blaue Auswahlmarker.

## Sinnhaftigkeit / Ursache

- Bisher sind Muzzle-Texturen vorhanden, aber in der 2.5D-Sicht sehr klein.
- Der Bewegungsresolver hat nur `Move` auf direkten Gruppen-Travel gezwungen; `Engage`/`Take` konnten noch Bounding/Caterpillar und Fidelity-Zielversatz erben.
- Ein autonomer Leader-Flank-Trigger kann im Kontakt aus dem normalen Angriffspfad heraus ein Flank-Verhalten starten.
- `Engage Area` und `Take Area` nutzten dieselbe zweite Occupy-/Secure-Phase, obwohl `Engage` nur Kampf ohne Besitzpflicht sein soll.

## Umfang

- Muzzle-Flash in `TerrainMap3DView` sichtbarer machen, ohne neue Combat-Entscheidungen in die Visualschicht zu legen.
- `Move`, `Engage`, `Take`, `Defend` und `Hold` im sichtbaren Mission-Tactical-Pfad auf gemeinsame Baseline-Rush-Bewegung setzen.
- Ziel-Fidelity-Offsets und breite Trailing-Slots fuer diese Baseline-Befehle deaktivieren; explizites `flank` bleibt separat.
- Autonome Leader-Flanks fuer die aktuelle Basisrunde abschalten.
- `Engage Area` als Kampf-/Halt am Approach behandeln; `Take Area` bleibt Besitz/Kontrolle mit Occupy.
- Headless-Gates fuer vier sichtbare Friendly-/Enemy-Proxies, Muzzle-Flash-Diagnose und Baseline-Bewegung ergaenzen.

## Nicht-Ziele

- Kein finales Flank-System.
- Kein neuer Pathfinding-Algorithmus.
- Kein Charakterbogen-/Skill-Balance-Pass.
- Kein Entfernen des Flank-Buttons oder alter Legacy-Dateien ausserhalb der betroffenen Runtime-Schalter.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/tasks/TASK_429_fireteam_behavior_modes_runtime.md`
- `docs/tasks/TASK_431_fireteam_aim_pose_and_card_ui_hotfix.md`

## Akzeptanzkriterien

- [ ] Fire-Events erzeugen weiter genau einen VFX-Token pro Schuss, enthalten aber einen sichtbaren Flash-/Bloom-Hinweis und groessere Flash-Diagnose.
- [ ] `Engage` und `Take` starten mit allen fitten Mitgliedern gleichzeitig, ohne Covering-/Hold-Untergruppe und ohne Zielversatz.
- [ ] Normale Baseline-Befehle nutzen kompakte, parallele Slots; kein Mitglied wird fuer Engage/Take weit aus der Formation geschickt.
- [ ] Autonom ausgeloste Leader-Flanks sind in dieser Basisrunde aus.
- [ ] `Engage Area` wartet nach dem Approach auf Kampf-/Clear-Zustand und besetzt danach nicht automatisch die Area; `Take Area` besetzt weiterhin.
- [ ] Nach abgeschlossenem Area-Angriff kann `GO` den naechsten Area-Auftrag starten.
- [ ] Die Drill-Szene meldet vier sichtbare eigene und vier sichtbare gegnerische Unit-Proxies mit 3D-Modellen.
- [ ] Der 3D-Selected-Unit-Marker bleibt bodennah; alte 2D-Auswahlringe werden nach Auswahlwechseln erneut unterdrueckt und tauchen nicht als zweites blaues Rechteck auf Huefthoehe auf.

## Betroffene Dateien

- `scripts/tactical/fireteam_behavior_resolver.gd`
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_432_fireteam_muzzle_flash_and_baseline_attack_movement.gd`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_432_fireteam_muzzle_flash_and_baseline_attack_movement.gd`
- Relevante Fireteam-Regressionen: TASK_205, TASK_424, TASK_426, TASK_429, TASK_431
- `git diff --check`

## Risiken / offene Punkte

- Der Muzzle Flash bleibt Visualfeedback aus vorhandenen Fire-Events; er beweist keinen Treffer.
- Flank bleibt fachlich offen und soll spaeter als explizit koordinierter Befehl wieder kontrolliert aufgebaut werden.
