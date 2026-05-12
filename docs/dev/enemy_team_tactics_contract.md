# Enemy Team Tactics Contract

TASK_200 definiert Enemy-Team-Taktiken als kleine Datenobjekte. Die Profile sind noch keine neue KI-Architektur; sie sind der gemeinsame Vertrag fuer Editor, Missiondaten, Mapdaten, Runtime-Glue und spaetere Multiplayer-Snapshots.

## Profil-IDs

Stabile IDs liegen in `scripts/tactical/enemy_team_tactics_profile.gd`:

- `guard_hold`
- `patrol_probe`
- `aggressive_push`
- `defensive_cover`
- `sniper_watch`

## Felder

Jede normalisierte Konfiguration enthaelt:

- `profile_id`
- `security_mode`
- `facing`
- `stance`
- `cover_behavior`
- `advance_style`
- `allowed_weapon_roles`
- `sight_behavior`
- `contact_behavior`
- `weapon_profile`
- `visual_archetype`
- `movement_posture_policy`
- `ready_distance_world`
- `travel_speed_factor`
- `ready_speed_factor`
- `aim_move_speed_factor`

Optionale Authoring-Felder:

- `patrol_area_id`
- `hold_area_id`
- `heavy_weapon_role`
- `weapon_id`
- `anti_armor_threat`
- `air_asset_risk_profile`
- `lz_threat_zone_id`
- `communication_intensity`

Posture-Policies ab TASK_345:

- `travel_until_threat`: Patrouille/Marsch laeuft schneller mit gesenkter Waffe, wechselt nahe Threat/Objective auf Tactical/Ready.
- `always_ready`: Team bleibt beim Vorruecken grundsaetzlich Tactical/Ready.
- `hold_ready`: Verteidiger und haltende Teams starten Overwatch/Ready.
- `aggressive_ready`: Push-Teams ruecken Ready vor, aber schneller als defensive Teams.
- `overwatch`: Wachposten/Sniper bleiben stationaer Overwatch/Ready.

## Defaults

- Karten bis einschliesslich 32x32 nutzen `guard_hold`.
- Karten ab 64x64 nutzen `patrol_probe`.
- Fehlende oder unbekannte IDs werden auf den Kartendefault normalisiert und ueber `diagnostics` gemeldet.

## Runtime-Abstraktion

- `advance_style` wird fuer die Runtime auf `hold`, `probe`, `push` oder `bounding` normalisiert.
- `movement_posture_policy` leitet Runtime-Posture und Speed ab: `travel/lowered`, `tactical/ready`, `engage/aimed` oder `overwatch/ready`.
- Die wirksame Bewegungsgeschwindigkeit kommt ab TASK_345 aus der Posture-Policy (`travel_speed_factor`, `ready_speed_factor`, `aim_move_speed_factor`) und nicht mehr nur aus `advance_style`.
- `rush`/`aggressive_push` werden als `push` ausgefuehrt.
- `bound_to_cover` und cover-orientierte Varianten werden als `bounding` ausgefuehrt.
- `visual_archetype` referenziert ab TASK_206 stabile NPC-Faction-Archetypen, aktuell `enemy_space_suit_orange` fuer das Standard-Gegenteam.
- Diese Werte sind kleine Taktiklabels und Zielgruppen, keine neue monolithische Gegner-KI.

## Speicherorte

- Missiondaten speichern die Teamtaktik pro `enemy_groups[].tactics`.
- Scenario-Authoring speichert missionsweite Defaults unter `tactical_authoring`, darunter Kommunikation, Fireteam-Defaults und Air-Asset-Risikoprofil.
- Mapdaten speichern Default- oder Preset-Konfigurationen unter `enemy_team_configs`.
- Editor-UI darf die Werte setzen, bleibt aber nicht die Gameplay-Wahrheit.
- Runtime liest normalisierte Dictionaries, setzt Unit-Metadaten im Enemy-Wave-Controller und baut daraus autoritative Security-/Team-Tactics-Snapshots im Missionsloop.
- Anti-Armor-/Air-Asset-Felder bleiben Authoring-Kontext: Treffer, Warnung, VFX/SFX und Verlustfolgen laufen weiter ueber AirAssetThreatResolver, SimulationRoot und MetaLayerFlow.
- Multiplayer-Snapshots transportieren `enemy_security`, `enemy_team_tactics` und `fire_events` nur als Anzeige-/VFX-Daten. Clients duerfen daraus keine Enemy-Entscheidungen oder Damage-Effects ableiten.

## Folge-Tasks

TASK_201 bis TASK_208 duerfen die Profilfelder fuer Waffenreichweite, LOS, Cover-Verhalten, Multiplayer-Snapshots, Visuals und Playability-Smokes auswerten. Neue Felder sollen zuerst in diesem Vertrag landen, bevor sie in Runtime-Logik benutzt werden.
