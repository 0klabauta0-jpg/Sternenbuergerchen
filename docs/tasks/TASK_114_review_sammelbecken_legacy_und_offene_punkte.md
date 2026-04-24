# TASK_114 - Review-Sammelbecken: Legacy, offene Punkte und Nacharbeiten

## Ziel
Dieser Task sammelt die im tiefen Review vom 2026-04-21 verifizierten Altlasten, Legacy-Kompatibilitaetsstellen, Behelfspfade, Doku-Drift und bewusst offen gelassenen Restpunkte in einem zentralen Abarbeitungsdokument.

## Status: IMPLEMENTIERT

## Herkunft
- Review-Durchlauf ueber Pflicht-Dokus, `IMPLEMENTATION_STATUS.md`, Task-Dateien, Legacy-Marker im Code und headless Verifier.
- Verifiziert mit:
  - `scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
  - `scripts/tests/task_103_verifier.gd`
  - `scripts/tests/task_111_verifier.gd`
  - `scripts/tests/task_112_verifier.gd`
  - `scripts/tests/task_113_verifier.gd`

## Bereits im Review behoben
- [x] Homebase-Missionsslots zaehlen zugewiesene Piloten jetzt konsistent mit.
  - Dateien: `scripts/meta/homebase_screen.gd`, `scripts/meta/meta_layer_flow.gd`
  - Verifikation: `bugfix_dropship_mission_flow_verifier.gd`

- [x] Explizite Missions-Timer-Startzeit funktioniert jetzt auch bei negativem monotonic Offset.
  - Datei: `scripts/tests/mission_combat_loop_driver.gd`
  - Verifikation: `bugfix_dropship_mission_flow_verifier.gd`

- [x] Inbound-/Transit-Dropships werden im FOB korrekt als Transit-Zustand mit ETA gezeigt.
  - Dateien: `scripts/meta/meta_layer_flow.gd`, `scripts/meta/fob_screen.gd`
  - Verifikation: `bugfix_dropship_mission_flow_verifier.gd`

- [x] Preview-Mission behaelt bei missionsseitigem Dropship-State den versteckten Host sauber bei, statt den Statuspfad zu verlieren.
  - Dateien: `scripts/meta/meta_layer_flow.gd`, `scripts/tests/mission_tactical_sandbox_controller.gd`
  - Verifikation: `bugfix_dropship_mission_flow_verifier.gd`

- [x] Missions-Minicard fuer das Dropship nutzt wieder den vorgesehenen kompakten HUD-Footprint, die korrekten Pilottexte und den read-only Shared-Card-Aufbau.
  - Dateien: `scripts/meta/transport_craft_card_ui.gd`, `scripts/meta/npc_compact_card.gd`, `scripts/tests/mission_tactical_sandbox_controller.gd`
  - Verifikation: `bugfix_dropship_mission_flow_verifier.gd`

- [x] Preview-Drop bleibt vor Missionsstart non-authoritative und registriert keine Fireteams als echte Runtime-Aktivierung.
  - Datei: `scripts/tests/mission_tactical_sandbox_controller.gd`
  - Verifikation: `bugfix_dropship_mission_flow_verifier.gd`

- [x] Doku-Drift im Terrain-/Editor-Bereich ist bereinigt.
  - Dateien: `docs/IMPLEMENTATION_STATUS.md`, `docs/tasks/TASK_060_terrain_json.md`, `docs/tasks/TASK_061_map_editor_szene.md`, `docs/tasks/TASK_062_map_editor_properties.md`, `docs/tasks/TASK_063_map_editor_speichern.md`, `docs/tasks/TASK_064_mission_terrain_aus_json.md`, `docs/tasks/TASK_065_tile_typ_katalog_und_palette.md`, `docs/tasks/TASK_066_corridor_wall_typen_typ_texturen_auto_cliff.md`, `docs/tasks/TASK_067_fix_map_editor_64x64_flat_ground.md`, `docs/tasks/TASK_068_zoom_inversion_und_auto_wall_overlays.md`, `docs/tasks/TASK_068b_drag_painting_und_hover_preview.md`, `docs/tasks/TASK_068c_gitternetz_overlay_und_himmelsrichtungen.md`, `docs/tasks/TASK_069_map_editor_auswahl_save_as_workflow_polish.md`, `docs/tasks/TASK_082_gemeinsamer_terrain_renderer_editor_und_mission.md`
  - Umfang: fehlende `TASK_060` bis `TASK_064`-Eintraege in `IMPLEMENTATION_STATUS.md` nachgezogen, doppelte Altsektionen fuer `TASK_020` bis `TASK_023` entfernt und veraltete `Status: offen`-Marker auf `implementiert` angehoben.

- [x] Legacy-Hide-/Fallback-Pfade im Meta- und Tactical-Glue sind dort entfernt, wo keine Alt-Szene mehr darauf angewiesen ist.
  - Dateien: `scenes/meta/homebase_test_screen.tscn`, `scenes/meta/fob_test_screen.tscn`, `scripts/meta/homebase_screen.gd`, `scripts/meta/fob_screen.gd`, `scripts/meta/meta_ui_skin.gd`, `scenes/tests/mission_reactivity_test.tscn`, `scripts/tests/mission_tactical_sandbox_controller.gd`, `scripts/tests/mission_command_flow_driver.gd`
  - Umfang: alte Homebase-/FOB-Placeholder-Knoten aus den Test-Szenen entfernt und durch feste Generated-Hosts ersetzt; tote Legacy-Phase-Buttons im Tactical-Test entfernt; alte UI-Hide-Hooks und Phase-Namens-Fallbacks im Szenen-Glue entfernt. Beibehalten bleiben nur die echten Alt-Daten-Migrationen fuer `selected_phase`-Planungsdaten sowie der beobachtende Flow-Driver-Mirror, damit neue Movement-Execution und bestehende Verifier/Glue-Pfade konsistent bleiben.
  - Verifikation: `scripts/tests/task_100_verifier.gd`, `scripts/tests/task_101_verifier.gd`, `scripts/tests/bugfix_dropship_mission_flow_verifier.gd`

- [x] Verifier-/Cleanup-Hygiene fuer `TASK_111` und `TASK_113` ist bereinigt.
  - Dateien: `scripts/tests/task_111_verifier.gd`, `scripts/tests/task_113_verifier.gd`
  - Umfang: der asynchrone Leadership-Delay-Test in `task_111_verifier.gd` wird jetzt korrekt awaited statt einen `SceneTreeTimer`-/Coroutine-Leak bis zum Prozessende offen zu lassen; in `task_113_verifier.gd` wird der nur fuer den Signalvertrag erzeugte `EventRouter` wieder freigegeben.
  - Verifikation: `scripts/tests/task_111_verifier.gd`, `scripts/tests/task_112_verifier.gd`, `scripts/tests/task_113_verifier.gd`

- [x] Verwaiste Legacy-Reste fuer den alten `meta_map_screen`-Pfad und reine Worktree-Formatdiffs sind bereinigt.
  - Dateien: `docs/IMPLEMENTATION_STATUS.md`, `docs/tasks/TASK_096_meta_missionmap_dropship_und_charactersheet_recovery.md`, `scenes/meta/meta_map_screen.tscn`
  - Umfang: die ungenutzte lokale Alt-Szene `meta_map_screen.tscn` ist entfernt; die Status- und Task-Doku verweist stattdessen wieder auf die echte eingebettete Missionsvorschau in `MissionHost`. Zusaetzlich wurden zwei versehentliche reine Newline-Diffs in `maps/wall_test_4x4.json` und `scripts/meta/npc_meta_card.gd` aus dem Worktree zurueckgesetzt.

- [x] Legacy-Wandkarten und alte `selected_phase`-Planungsdaten folgen jetzt einer expliziten Ausstiegsstrategie statt stiller Migration.
  - Dateien: `scripts/terrain/terrain_map_data.gd`, `scripts/editor/map_editor.gd`, `scripts/tests/phase_controller.gd`, `scripts/tests/mission_tactical_sandbox_controller.gd`, `maps/legacy_wall_type_unsupported.json`, `tests/fixtures/legacy_selected_phase_planning_state.json`, `scripts/tests/task_114_legacy_guard_verifier.gd`
  - Umfang: Karten mit altem Tile-Typ `wall` werden beim Laden jetzt klar als alte Datei markiert und nicht mehr mit einer geratenen Standardwand dargestellt; der Editor faellt stattdessen auf eine saubere neue Leerkartengrundlage zurueck. Alte Planungsdaten mit `selected_phase` ohne nummerierten Phasenstand werden nicht mehr auf das neue System gemappt oder um einen Schritt verschoben, sondern explizit als nicht mehr unterstuetzt abgewiesen. Fuer beide Faelle liegen kleine Alt-Beispieldateien plus headless Verifier vor.
  - Verifikation: `scripts/tests/task_114_legacy_guard_verifier.gd`

- [x] Die spaeten Recovery-Restpunkte aus `TASK_096` sind abgeschlossen.
  - Dateien: `scenes/tests/mission_reactivity_test.tscn`, `scenes/meta/fob_test_screen.tscn`, `scripts/tests/task_096_recovery_verifier.gd`, `docs/tasks/TASK_096_meta_missionmap_dropship_und_charactersheet_recovery.md`
  - Umfang: die sichtbaren Block-Nummern stehen jetzt auch direkt in der echten Tactical-UI, ein eigener Verifier prueft ausgegraute FOB-Transitkarten samt Fortschrittsbalken und den Character-Sheet-Aufbau, und der Dropship-Kontext ist abschliessend auf einen fachlich falschen `tracked`-Button geprueft.
  - Verifikation: `scripts/tests/task_096_recovery_verifier.gd`, `scripts/tests/bugfix_dropship_mission_flow_verifier.gd`

- [x] Der Meta-Recovery-Restpunkt fuer per-Mitglied-Loadouts und sichtbare Homebase-Transfer-Routen auf der Meta-Map ist abgeschlossen.
  - Dateien: `scripts/meta/meta_layer_flow.gd`, `scripts/tests/mission_tactical_sandbox_controller.gd`, `scripts/tests/task_114_meta_recovery_verifier.gd`
  - Umfang: die eingebettete Missionsvorschau auf der Meta-Map zeigt auf den Fireteam-Karten jetzt den individuellen Kit-Stand jedes Teammitglieds statt nur den groben teamweiten Default. Laufende Homebase->FOB-Transfers werden zusaetzlich als eigene Kartenroute mit separaten Markern fuer Team- und Pilot/Craft-Transfers dargestellt und im Mission-Control-Statustext gespiegelt.
  - Verifikation: `scripts/tests/task_114_meta_recovery_verifier.gd`, `scripts/tests/bugfix_dropship_mission_flow_verifier.gd`

- [x] Der `TASK_095`-Restpunkt fuer slotgebundenes Medic-Equipment, aktive Sanitaeter-Bewegung und tiefere Zielpriorisierung ist abgeschlossen.
  - Dateien: `scripts/core/weapon_data.gd`, `scripts/meta/fob_screen.gd`, `scripts/command/loadout_modifier_resolver.gd`, `scripts/npc/unit_roster_presets.gd`, `scripts/npc/test_unit.gd`, `scripts/tests/mission_combat_loop_driver.gd`, `scripts/tests/medic_support_verifier.gd`
  - Umfang: `medictool` ist jetzt als Loadout-Gegenstand im FOB-Dropdown auswaehlbar und belegt einen Waffenslot. Combat-Medics duerfen nur noch mit diesem Tool heilen, behalten aber bei einer zusaetzlichen Schusswaffe ihren aktiven Kampfslot sauber auf der echten Waffe. Ausserhalb der Heal-Reichweite laufen Medics auf downed oder stark verwundete Ziele zu; bei mehreren Kandidaten gewinnt nicht mehr nur Reichweite, sondern der dringlichere Verwundungsgrad.
  - Verifikation: `scripts/tests/medic_support_verifier.gd`, `scripts/tests/task_087_verifier.gd`, `scripts/tests/task_107_verifier.gd`, `scripts/tests/test_weapon_data.gd`

- [x] Die `TASK_109`-Restpunkte fuer In-World-Stance-Badges und feinere Sync-Vorbereitung sind abgeschlossen.
  - Dateien: `scripts/tactical/tactical_stance_controller.gd`, `scripts/tests/mission_tactical_sandbox_controller.gd`, `scripts/npc/test_unit.gd`, `scripts/core/simulation_root.gd`, `scripts/tests/task_109_verifier.gd`
  - Umfang: Units zeigen die angeforderte Haltung jetzt direkt als kleines `C`-/`N`-/`A`-Badge neben Fireteam und Phase. Der Stance-Controller liefert zusaetzlich einen versionierten `tactical_stance_sync`-Stand fuer Preview-/Runtime-Bruecken und spaetere Multiplayer-Pfade; der bestehende Observer-Snapshot transportiert diese Badge-Daten direkt mit.
  - Verifikation: `scripts/tests/task_109_verifier.gd`

- [x] Der `TASK_113`-Restpunkt fuer tieferes Richtungs-/Morale-Follow-up ist abgeschlossen.
  - Dateien: `scripts/tactical/flank_vulnerability_resolver.gd`, `scripts/tests/mission_combat_loop_driver.gd`, `scripts/tests/mission_tactical_sandbox_controller.gd`, `scripts/core/simulation_root.gd`, `scripts/tests/task_113_verifier.gd`
  - Umfang: Flanken behalten jetzt ihre relative Richtung (`left`, `right`, `rear`) als kurzes Richtungsgedaechtnis und koennen Fireteams in ein kleines Morale-Folgefenster (`alerted`, `shaken`) schieben. Ein Heckentreffer wirkt sofort `shaken`, wiederholte Seitenflanken koennen denselben Zustand nachziehen. Das Folgefenster senkt den effektiven Suppression-Schwellenwert weiter, wird im Statusbereich sichtbar und laeuft ueber den bestehenden Flank-/Damage-Pfad statt ueber eine zweite Sonderlogik.
  - Verifikation: `scripts/tests/task_113_verifier.gd`

- [x] Der verbliebene Terrain-Marker-Restpunkt aus `TASK_082` ist jetzt als expliziter Folge-Task geschnitten.
  - Dateien: `docs/tasks/TASK_082_gemeinsamer_terrain_renderer_editor_und_mission.md`, `docs/tasks/TASK_114_review_sammelbecken_legacy_und_offene_punkte.md`, `docs/tasks/TASK_115_gemeinsames_markersystem_fuer_editor_und_taktikkarte.md`
  - Umfang: Die offenen Marker-Themen werden nicht mehr nur als vager Rest in `TASK_082` weitergetragen, sondern als eigener Folge-Task `TASK_115` festgehalten. Der neue Task trennt klar zwischen authorbaren Editor-/Systemmarkern und spielerseitigen Befehlsmarkern in der Mission, fordert eine Typ-Liste statt freier Marker-Namen und haelt direkte Karteninteraktion, Tile-Snap und Ueberlappungsblock fest.

- [x] Der ausgelagerte Marker-Folge-Task `TASK_115` ist umgesetzt.
  - Dateien: `scripts/terrain/terrain_marker_catalog.gd`, `scripts/terrain/terrain_map_data.gd`, `scripts/editor/map_editor.gd`, `scripts/tactical/visuals/fireteam_order_visualizer.gd`, `scripts/tests/mission_tactical_sandbox_controller.gd`, `scripts/tests/task_115_verifier.gd`, `docs/tasks/TASK_082_gemeinsamer_terrain_renderer_editor_und_mission.md`, `docs/tasks/TASK_115_gemeinsames_markersystem_fuer_editor_und_taktikkarte.md`, `docs/IMPLEMENTATION_STATUS.md`
  - Umfang: Marker laufen jetzt ueber einen gemeinsamen Typkatalog mit Name, Farbe, Symbol und Kontext. Der Map-Editor besitzt eine echte Marker-Liste mit direkter Kartenplatzierung, Drag, Delete, Doppelklick-Umbenennen, Tile-Snap und Ueberlappungsblock. Die Taktikkarte konsumiert fuer Spielermarker denselben `mission_player`-Katalog und rastet Wegpunkte auf Tile-Mitten ein.
  - Verifikation: `scripts/tests/task_115_verifier.gd`, `scripts/tests/task_099_verifier.gd`, `scripts/tests/task_109_verifier.gd`, `scripts/tests/task_113_verifier.gd`, `scripts/tests/task_096_recovery_verifier.gd`, `scripts/tests/task_114_meta_recovery_verifier.gd`, `scripts/tests/bugfix_dropship_mission_flow_verifier.gd`

## Folge-Tasks aus dem Review

- Aus dem urspruenglichen TASK_114-Durchlauf blieben keine offenen Review-Restpunkte.
- Aus dem anschliessenden Code-/Design-/Architektur-Review vom 2026-04-24 wurden neue Folge-Tasks geschnitten:
  - `TASK_116` - Runtime-Systeme aus `scripts/tests` herausloesen
  - `TASK_117` - Dropship-Deploy als `SimulationRoot`-Effects
  - `TASK_118` - Combat-Entscheidungen aus `MissionCombatLoopDriver` herausloesen
  - `TASK_119` - Seeded Combat RNG und `roll_override` begrenzen
  - `TASK_120` - Teamqualitaet als FTL-Ausfuehrungsfaktor

## Empfehlung fuer die naechste Abarbeitung
1. Zuerst `TASK_116` bearbeiten, damit produktive Tactical-/Runtime-Systeme klare Pfade haben.
2. Danach `TASK_117` bis `TASK_119` als Architektur-Stabilisierung vor weiteren Gameplay-Erweiterungen bearbeiten.
3. `TASK_120` anschliessend als Design-/Spielgefuehl-Slice auf der bereinigten Runtime-Basis umsetzen.
4. Neue Marker- oder Terrain-Erweiterungen nur noch als neu benannte Folge-Tasks schneiden.

## Nicht-Ziele
- kein stiller Grossrefactor des Meta-Layers
- keine neue Missions- oder Fahrzeugarchitektur
- keine direkte Erweiterung der Reihe `109` bis `113` ohne neue klar benannte Folge-Tasks

## Lokale Pruefung aus dem Review
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_103_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_111_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_112_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_113_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_114_legacy_guard_verifier.gd`
