# TASK_345 - NPC Standard Movement Posture Policy

## Ziel
NPCs sollen ein klares Standardverhalten fuer Bewegung und Waffenhaltung bekommen. Das System unterscheidet danach sauber zwischen normalem schnellen Bewegen mit gesenkter Waffe, taktischem Vorruecken in M-Position und aktivem Zielen/Schiessen.

Die Gameplay-Wahrheit liegt bei Simulation/Taktik. Die 3D-Ansicht darf diese Haltung nur darstellen.

## Status: IMPLEMENTIERT

## Ausgangslage
- `scripts/tests/mission_combat_loop_driver.gd` nutzt bereits `move_speed_factor`.
- Aktuelle Bewegungswerte:
  - `enemy_advance_speed_factor = 0.3`
  - `enemy_reposition_move_speed_factor = 0.45`
  - `push` etwa `0.3`
  - `bounding` etwa `0.246`
  - `probe` etwa `0.21`
  - `hold` etwa `0.15`
- `scripts/tactical/enemy_team_tactics_profile.gd` kennt bereits Taktikfelder wie `stance`, `security_mode`, `advance_style`, `cover_behavior`, `sight_behavior`, `contact_behavior` und `weapon_profile`.
- Es fehlt ein expliziter Laufzeitvertrag fuer `weapon_posture` und `movement_posture`.
- TASK_344 erzeugt eine sichtbare Aim-Pose beim Schiessen, aber nur waehrend eines aktiven Fire-Events. Fuer taktisches Vorruecken braucht es einen persistenten Zustand vor dem Schuss.

## Standardverhalten

### 1. Travel Move
- Waffe unten.
- Schnellste NPC-Bewegung.
- Verwendung bei Patrouille, Marsch und Verlegen ohne Feindkontakt.
- Beispielzustand:
  - `movement_posture = "travel"`
  - `weapon_posture = "lowered"`

### 2. Tactical Move / M-Position
- Waffe im Anschlag oder ready-low.
- Langsamer als Travel.
- Aktiv ab taktischem Schwellwert:
  - Naehe zum Zielgebiet.
  - Kontaktverdacht.
  - moegliche Sichtlinie.
  - letzter bekannter Gegnerpunkt.
  - Verteidigungsbereich.
- Beispielzustand:
  - `movement_posture = "tactical"`
  - `weapon_posture = "ready"`

### 3. Engage / Aim
- Waffe zielt aktiv auf ein Ziel.
- Sehr langsam oder stationaer.
- Nur bei LOS, Schussbefehl, aktivem Fire-Event oder unmittelbar bevorstehendem Angriff.
- Beispielzustand:
  - `movement_posture = "engage"`
  - `weapon_posture = "aimed"`

### 4. Overwatch / Defense
- Waffe ready oder aimed.
- Kaum Bewegung.
- Verwendung fuer Verteidiger, Sniper, Wachposten und Objective-Sicherung.
- Beispielzustand:
  - `movement_posture = "overwatch"`
  - `weapon_posture = "ready"`

## Umfang

### 1. Taktik-/Profilvertrag erweitern
Fuege optionale Felder fuer NPC-Posture-Policy hinzu, ohne bestehende Profile zu brechen:

```json
{
  "movement_posture_policy": "travel_until_threat",
  "ready_distance_world": 640.0,
  "travel_speed_factor": 0.55,
  "ready_speed_factor": 0.30,
  "aim_move_speed_factor": 0.18
}
```

Erwartete Policies fuer V1:
- `travel_until_threat`
- `always_ready`
- `hold_ready`
- `aggressive_ready`
- `overwatch`

### 2. Runtime-Posture ableiten
Leite `movement_posture`, `weapon_posture` und den wirksamen `move_speed_factor` aus bestehenden Taktikdaten ab:
- `enemy_patrol` ohne Kontakt: `travel` / `lowered` / schneller.
- Patrouille nahe Zielgebiet oder Kontaktbereich: `tactical` / `ready` / langsamer.
- `defensive_cover`: von Beginn an `ready` oder `overwatch`.
- `aggressive_push`: `ready` beim Vorruecken, aber schneller als Defense.
- aktiver Schuss oder Fire-Event: `engage` / `aimed`; Facing zeigt auf Ziel.

### 3. Laufzeitstatus bereitstellen
Der NPC-Laufzeitstatus soll die abgeleitete Haltung sichtbar machen:
- `movement_posture`
- `weapon_posture`
- `posture_policy_id` oder gleichwertige Diagnose
- wirksamer `move_speed_factor`

Der Zustand muss aus Simulation/Taktik kommen. UI oder Render-Code duerfen ihn nicht als Gameplay-Wahrheit setzen.

### 4. Visuals anbinden
`TerrainMap3DView` soll die Posture lesen und rein visuell darstellen:
- `lowered`: Waffe beim Travel sichtbar abgesenkt.
- `ready`: M-Position / ready-low beim taktischen Vorruecken.
- `aimed`: bestehende TASK_344-Aim-Pose waehrend Fire-Events oder Engage.

Fire-Event-Aim bleibt staerker als die allgemeine Posture, damit Schuesse weiterhin eindeutig lesbar bleiben.

### 5. Tests und Diagnose
Erstelle einen Headless-Verifier fuer den Vertrag:
- Taktikprofile normalisieren neue Posture-Felder.
- Patrol ohne Kontakt laeuft mit Travel/Lowered.
- Patrol nahe Threat-/Objective-Bereich wechselt auf Tactical/Ready.
- Defense startet Ready/Overwatch.
- Fire-Event setzt Aimed und Ziel-Facing.
- Visual-Snapshot meldet die gelesene Posture, ohne SimulationRoot-Commands zu erzeugen.

## Nicht-Ziele
- Kein neues KI-System.
- Kein neuer Combat-Resolver.
- Kein Umbau der LOS- oder Damage-Wahrheit.
- Keine neuen Animationsassets als Pflicht.
- Kein finaler Balance-Pass fuer alle Geschwindigkeiten.
- Keine UI-Steuerung fuer NPC-Posture in diesem Task.

## Umsetzung
- `EnemyTeamTacticsProfile` normalisiert `movement_posture_policy`, `ready_distance_world`, `travel_speed_factor`, `ready_speed_factor` und `aim_move_speed_factor` fuer bestehende Profile.
- `UnitCommand` und `UnitRuntimeStatus` tragen `movement_posture`, `weapon_posture` und `posture_policy_id` als autoritativen Runtime-Vertrag.
- `MissionCombatLoopDriver` leitet aus Taktikprofil, Threat-Distanz und Fire-Events Travel/Lowered, Tactical/Ready, Engage/Aimed und Overwatch/Ready ab.
- `SimulationRoot` uebernimmt Move-/Hold-Kommandos in den Unit-Runtime-Status, bevor Bewegung ausgefuehrt wird.
- `TerrainMap3DView` liest die Runtime-Posture nur fuer Snapshot und Weapon-Pose; Fire-Events duerfen Ready visuell zu Aimed uebersteuern.
- `ground_mission01_default` setzt die Patrol-Fireteam-Policy auf `travel_until_threat` und die Defense-Fireteam-Policy auf `hold_ready`.

## Akzeptanzkriterien
- [x] NPC-Taktikprofile koennen eine Movement-Posture-Policy definieren.
- [x] Ohne explizite Policy gibt es konservative Defaults.
- [x] `move_speed_factor` wird aus Posture und Taktik abgeleitet, nicht nur aus `advance_style`.
- [x] Normale Patrouille nutzt Waffe unten und schnelleren Travel-Move.
- [x] Taktisches Vorruecken nutzt M-Position und langsamere Bewegung.
- [x] Aktives Schiessen nutzt Aimed-Posture, Facing zum Ziel und bleibt kompatibel mit TASK_344-Muzzle-/Aim-Visuals.
- [x] Verteidiger und Overwatch-Profile starten mit ready/overwatch statt Travel.
- [x] Render-Code liest Posture nur als Darstellung und setzt keine Gameplay-Wahrheit.
- [x] Headless-Verifier deckt Standardfaelle ab.

## Erwartete Dateien
- `scripts/tactical/enemy_team_tactics_profile.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/npc/test_unit.gd`
- `scripts/npc/unit_runtime_status.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `data/mission_scenarios/ground_mission01_default.json`
- `scripts/tests/task_345_npc_standard_movement_posture_policy.gd`
- `docs/tasks/TASK_345_npc_standard_movement_posture_policy.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_345_npc_standard_movement_posture_policy.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_344_ground_mission_default_enemy_visuals.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_202_enemy_security_direction_and_los_patch.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_201_weapon_range_scale_and_tile_distance_patch.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_204_enemy_tactics_multiplayer_authority_snapshot_patch.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_208_enemy_team_tactics_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_200_enemy_team_tactics_contract_and_editor_config.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_233_portrait_identity_catalog_and_roster_presentation.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Die konkreten Speed-Werte brauchen spaeter manuellen Playtest.
- `ready_distance_world = 640.0` ist ein V1-Startwert und muss gegen Map-Groesse, Sichtweite und Zielgebiet geprueft werden.
- Interner Name sollte technisch eindeutig sein (`ready`, `ready_low`, `aimed`); "M-Position" kann als Design-/UI-Begriff erhalten bleiben.
- Ohne echte Arm-/Schulteranimation bleibt die Darstellung zunaechst ein Weapon-Pose-Offset wie bei TASK_344.
