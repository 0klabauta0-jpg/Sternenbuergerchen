# Unit Facing Visual Contract

## Zweck
Dieser Contract verankert den bestehenden Weg fuer Unit-Facing, Sichtlinie, Waffen-/Schusslinie und sichtbare 3D-Modellrotation. Er gilt fuer Friendly- und Enemy-NPCs in Missionen und verhindert, dass UI-, Plan- oder Overlay-Code eine zweite Facing-Wahrheit einfuehrt.

## Wahrheit
- Gameplay- und Runtime-Facing liegt auf der Unit als `facing_angle`, `map_facing_angle` oder bei Gegnern zusaetzlich `enemy_facing_angle`.
- `UnitRuntimeStatus` und `UnitCommand` tragen `movement_posture`, `weapon_posture` und `target_position`, aber keine eigene 3D-Modellrotation.
- Combat-Fire-Events duerfen Angreifer-Facing setzen, bleiben aber Runtime-/VFX-Payloads und ersetzen nicht die Unit als sichtbare Live-Quelle.

## Controller- und Plan-Pfad
- `MissionTacticalSandboxController` baut Fireteam-Orientation-Payloads aus Movement, Security, Unit-Facing oder geplantem Target.
- Bestehende Plaene, Ad-hoc-Orders, Area-Orders und Post-Drop-Security duerfen Facing nur ueber Unit-Metadaten, Movement-State oder Anchor-Payloads beschreiben.
- UI-Karten und Panels duerfen selektieren, Befehle ausloesen und Payloads spiegeln, aber keine eigene Modell-/Sichtlinienrotation speichern.

## Primary3DView-Pfad
- `TerrainMap3DView` liest Unit-Nodes live aus `_unit_nodes` und bevorzugt explizites Unit-Facing vor Movement, Fire-Event und Target-Fallbacks.
- Unit-Proxies nutzen `_get_unit_world_direction_yaw()` fuer die importierte Character-Forward-Achse. Die allgemeine `_get_world_direction_yaw()` bleibt fuer Nicht-Unit-Pfade wie Dropships reserviert.
- `_get_world_direction_from_proxy_yaw()` ist der inverse Unit-Proxy-Pfad und darf nicht wieder auf die alte allgemeine World-Yaw-Annahme zurueckfallen.
- Fireteam-Orientation und Fire-Sector-/Weapon-Linie nutzen die vorhandenen Primary3DView-Snapshots und lesen bei gueltigem Anchor aktuelle Unit-Position/Facing live.

## Waffenanker
- Das Waffen-Root bleibt am Socket (`RightHandSocket` oder Loadout-Socket). Aim-/Ready-Pose darf Rotation/Pitch und Child-Yaw setzen, aber den Root nicht vom Socket weg verschieben.
- Die sichtbare Aim-/Anschlag-Pose kommt aus dem vorhandenen importierten `0_Targeting Pose`-Clip und wird im Primary3DView nur auf Oberkoerper-/Arm-Bones gelegt. Idle/Walk bleiben Basisanimationen; die Unit-Animation laeuft im bestehenden Visualpfad kontrolliert, damit die Aim-Pose nicht wieder von der Laufanimation ueberschrieben wird.
- Asset-Pivot-Korrekturen gehoeren in die bestehende Attachment-Visual-Schicht (`visual_offset`, `visual_rotation_degrees`) und nicht in Runtime-Posture-Offsets.
- Die sichtbare Fire-Sector-/Weapon-Linie darf am sichtbaren Weapon-Visual beginnen, aber nicht durch einen verschobenen Gameplay-Anker eine zweite Schussrichtung erzeugen.

## Enemy-Pfad
- Gegner setzen Security- und Combat-Facing ueber `enemy_facing_angle` sowie dieselben Runtime-Posture-Felder.
- Enemy-Proxies laufen durch denselben Primary3DView-Unit-Proxy-Pfad wie Friendly-Proxies; es gibt keine separate Gegner-Modellrotation.

## Regressionen
- `task_401_facing_sightline_debug_map.gd` prueft Friendly-Facing, Move-Commands, Skeleton-Forward, Weapon-/Shot-Linie, Waffenroot am Socket und die angelegte Oberkoerper-/Waffenhand-Pose.
- `task_344_ground_mission_default_enemy_visuals.gd` prueft Enemy-Fire-Events gegen sichtbares Skeleton-Facing, Waffenroot am Socket und die angelegte Oberkoerper-/Waffenhand-Pose.
- `task_364_mission_fireteam_orientation_indicators.gd`, `bugfix_mission_fire_sector_overlay.gd`, `task_371_fire_sector_security_arc_overlay_toggle.gd` und `task_372_mission_los_debug_overlay_toggle.gd` sichern die bestehenden Overlay-Pfade.
