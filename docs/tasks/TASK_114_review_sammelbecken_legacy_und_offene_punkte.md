# TASK_114 - Review-Sammelbecken: Legacy, offene Punkte und Nacharbeiten

## Ziel
Dieser Task sammelt die im tiefen Review vom 2026-04-21 verifizierten Altlasten, Legacy-Kompatibilitaetsstellen, Behelfspfade, Doku-Drift und bewusst offen gelassenen Restpunkte in einem zentralen Abarbeitungsdokument.

## Status: OFFEN

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

## Offene Punkte

### 1. Legacy-Kompatibilitaet im Code
- `scripts/editor/map_editor.gd` haelt einen Legacy-Fallback fuer den alten Tile-Typ `wall`.
  - Das ist sinnvoll fuer Altdateien, sollte aber irgendwann durch eine kontrollierte Map-Migration oder ein sauberes Upgrade-Skript ersetzt werden.

- `scripts/tests/phase_controller.gd` und `scripts/tests/mission_tactical_sandbox_controller.gd` behalten weiter die Migration fuer alte `selected_phase`-Planungsdaten.
  - Der Pfad ist bewusst erhalten, weil er noch alte Planungsstaende lesen kann; entfernt wurden nur die toten Szenen-/UI-Hooks.

### 2. Noch offene Fachpunkte aus bestehenden Tasks
- `TASK_096`
  - Sichtbare Nummern direkt in der echten Tactical-UI nachziehen.
  - Kleinen Verifier fuer FOB-Transitkarten und Character-Sheet-Layout nachziehen.
  - Final pruefen, ob irgendwo noch ein fachlich falscher `tracked`-Button uebrig ist.

- `IMPLEMENTATION_STATUS.md` / Meta-Recovery
  - Die Meta-Map spiegelt per-Mitglied-Loadouts noch nicht vollstaendig und zeigt laufende Homebase-Transfers noch nicht als eigene Kartenroute oder grafische Flugspur.

- `TASK_095` / Medic Support
  - Noch keine Sanitaeter-Bewegung, Ressourcen oder tiefere Priorisierung ausser Reichweite/Zustand.

- `TASK_109`
  - Noch keine In-World-Unit-Badges fuer Stances.
  - Noch keine feinere Netzwerk-Synchronisierung fuer spaetere Multiplayer-Stance-Aenderungen.

- `TASK_113`
  - Noch keine tieferen Richtungs-/Morale-Folgesysteme jenseits der aktuellen Flank- und Suppression-Modifier.

- `TASK_082` / Terrain-Metadaten
  - Markerbearbeitung bleibt auf feste IDs begrenzt.
  - Keine freien Marker-Typen oder Handle-basierte Platzierung direkt auf der Karte.

## Empfehlung fuer die naechste Abarbeitung
1. Verbleibende Legacy-Migrationen (`map_editor.gd` fuer alten Tile-Typ `wall`, `phase_controller.gd` fuer `selected_phase`) nur mit expliziter Upgrade-Strategie oder Alt-Daten-Testfaellen anfassen.
2. Fachliche Restpunkte aus TASK_096, TASK_109 und TASK_113 in kleine Folge-Tasks schneiden statt still weiter in bestehende Monsterdateien zu wachsen.

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

