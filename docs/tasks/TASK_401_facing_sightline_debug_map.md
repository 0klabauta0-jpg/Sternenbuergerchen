# TASK_401 - Facing Sightline Debug Map

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Ziel / Problem
Facing, Sichtlinie und Waffen-/Schussrichtung sollen auf einer kleinen Mission-Map sofort sichtbar pruefbar sein, ohne dass zuerst ein Overlay angeklickt oder eine Unit manuell selektiert werden muss.

## Sinnhaftigkeit / Ursache
Die bestehenden Visual-Systeme fuer Fireteam-Orientation, Fire-Sector/LOS-Linie, Unit-Facing und Weapon-Posture existieren bereits. Fuer manuelle Sichtchecks fehlt aber eine kleine, eindeutige Fixture, in der ein NPC mit Waffe im Anschlag und ein NPC mit gesenkter Waffe direkt auseinandergezogen sichtbar sind. Die Playtests zeigten zusaetzlich, dass die importierten Character-Modelle visuell 180 Grad zur Proxy-/Facing-Rotation verdreht standen, der Aim-Yaw die sichtbare Waffe aus dem Handanker ziehen konnte, die Fire-Sector-Linie besser an die Blick-/Facing-Richtung statt an eine separate Target-Position gebunden wird und Map-NPC-Klicks nicht die Kamera neu zentrieren duerfen.

## Umfang
- 12x12-Testmap mit Compass-Markern an den Kartenecken.
- Zwei Friendly-NPCs in der Kartenmitte als Debug-Fireteam-Fixture.
- Bestehende TacticalController-/Primary3DView-Overlays beim Szenenstart aktivieren.
- Vorhandene Unit-Metadaten und Runtime-Posture nutzen, statt neue LOS- oder Facing-Logik einzufuehren.
- Bestehende NPC-Visual-Mapping-Rotation so korrigieren, dass das Modell selbst mit der Proxy-/Facing-Richtung uebereinstimmt.
- Bestehende Weapon-Posture-Visuals so nutzen, dass die Schusslinie am sichtbaren Waffenvisual beginnt, wenn die Waffe nicht gesenkt ist, ohne den Handanker sichtbar vom NPC wegzuziehen.
- Fire-Sector-/Weapon-Linie im sichtbaren Overlay an Facing/Blickrichtung binden, nicht an separate Target-Positionen.
- Auswahlanzeige fuer selektierte NPCs auf Boden-/Fusshoehe absenken.
- Map-NPC-Klicks als reine Auswahl behandeln; nur die bestehende Fireteam-Karte im linken HUD darf den Primary-View-Fokus zentrieren.
- Fireteam-Mini-Karten ueber dem read-only Tactical-Event-Log halten, damit auch die untere Karte direkt klickbar bleibt.
- Primary3DView-Proxy-/Weapon-Pose nutzt explizites Facing und Runtime-Movement-Facing vor Fire-Event-/Target-Fallbacks.
- Der importierte Walk-Clip darf keine eigene Heading-Control-/Body-Root-Rotation ueber die Runtime-Facing-Achse legen.
- Primary3DView-Fireteam-Orientation liest bei gueltigem vorhandenen Anchor-Payload die aktuelle Unit-Position und das aktuelle Unit-Facing live aus den registrierten Unit-Nodes, damit Bewegung keine stale Sichtlinie zeichnet.
- Headless-Verifier fuer Map, Szene, Compass-Marker, Posture und Render-Snapshot.

## Nicht-Ziele
- Kein neues LOS-System.
- Keine neue Combat-Entscheidungslogik.
- Keine zweite Gameplay-Wahrheit in UI oder Visuals.
- Keine Aenderung am Standard-Ground-Mission-Flow.

## Relevante Contracts / Dokumente
- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/enemy_team_tactics_contract.md`
- `docs/dev/combat_loop_authority_contract.md`
- `docs/dev/fog_of_war_modes_contract.md`
- `docs/tasks/TASK_364_mission_fireteam_orientation_indicators.md`
- `docs/tasks/TASK_371_fire_sector_security_arc_overlay_toggle.md`
- `docs/tasks/TASK_372_mission_los_debug_overlay_toggle.md`

## Akzeptanzkriterien
- [x] Die neue 12x12-Map laedt mit genau den Compass-Labels Nord/Ost/Sued/West.
- [x] Die Debug-Szene zeigt zwei Friendly-NPCs in der Kartenmitte.
- [x] Ein NPC steht mit `weapon_posture = aimed`, ein NPC mit `weapon_posture = lowered`.
- [x] Der obere NPC faced nach Nord, der untere nach Sued; die Modelle nutzen denselben vorhandenen Proxy-/Visual-Mapping-Pfad.
- [x] Die NPCs stehen weit genug auseinander, damit Facing- und Schusslinien manuell lesbar sind.
- [x] Die Waffen-/Schusslinie beginnt am sichtbaren Waffenvisual, wenn die Waffe im Anschlag ist.
- [x] Die sichtbare Waffe bleibt am Handanker; Aim-Yaw dreht nur das Weapon-Child-Visual, nicht den ganzen Root-Anker aus der Unit heraus.
- [x] Die Waffen-/Schusslinie folgt der Facing-/Blickrichtung statt einer separaten Target-Position.
- [x] Der blaue Selected-Unit-Marker liegt an den Fuessen auf Bodenniveau.
- [x] Ein Map-Klick auf einen NPC selektiert nur und laesst den Primary-View-Fokus unveraendert.
- [x] Ein Klick auf die bestehende linke Fireteam-Karte bleibt der explizite Pfad zum Zentrieren der Kamera.
- [x] Die untere Fireteam-Mini-Karte bleibt vor dem Event-Log klickbar.
- [x] Modell- und Weapon-Pose priorisieren Facing-/Movement-Richtung vor alten Fire-Event-/Target-Fallbacks.
- [x] Die Walk-Animation entfernt die importierten `HipsCtrl`- und `Hips`-Heading-Rotationen, damit das Modell beim Gehen der Lauf-/Facing-Richtung nicht den Ruecken zudreht.
- [x] Primary3DView rendert Fireteam-Orientation bei Bewegung aus aktueller Unit-Position und aktuellem Unit-Facing statt aus stale Anchor-Richtung.
- [x] Fireteam-Orientation/Facing und Fire-Sector/Weapon-Linie laufen ueber die bestehenden Primary3DView-Snapshots.
- [x] Die sichtbaren Debug-Visuals erzeugen keine SimulationRoot-Commands oder -Effects.

## Betroffene Dateien
- `data/npc_unit_visual_mapping.json`
- `maps/facing_sightline_debug_12x12.json`
- `data/mission_scenarios/facing_sightline_debug_12x12.json`
- `scenes/tests/facing_sightline_debug_map.tscn`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/facing_sightline_debug_fixture_setup.gd`
- `scripts/tests/task_401_facing_sightline_debug_map.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_401_facing_sightline_debug_map.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_171_npc_model_replacement_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_190_weapon_visual_loadout_expansion_and_scale.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_344_ground_mission_default_enemy_visuals.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_364_mission_fireteam_orientation_indicators.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_fire_sector_overlay.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_371_fire_sector_security_arc_overlay_toggle.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_372_mission_los_debug_overlay_toggle.gd`
- [x] `git diff --check`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_174_character_helmet_blaster_attachment_verifier.gd` hat einen stale Live-Node-Namen-Teil (`UnitProxy_unit_alpha`/`UnitProxy_enemy_delta`); Mapping-/Socket-/Attachment-Zaehler laufen, aber der alte Direkt-Node-Abschnitt bleibt rot.
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_246_visual_scale_alignment_asset_pass_verifier.gd` bleibt an zwei bestehenden Multiplayer-Lobby-Panel-Abmessungen rot; keine der fehlenden Assertions betrifft NPC-Facing, Weapon-Posture oder Fire-Sector-Visuals.

## Risiken / offene Punkte
- Der Headless-Test prueft Datenfluss und Render-Snapshot, nicht den subjektiven optischen Sitz der Pfeile in einer echten Godot-Fensteransicht.
- Die Fixture darf spaeter nicht als Gameplay-Sonderfall missbraucht werden.
