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
- Der Runtime-AnimationPlayer der Unit-Proxies laedt die importierten Animated-Characters-Rohclips aus dem Visual-Mapping und baut die datengetriebenen `animation_combat_cases` aus importierten Basisclips plus importierten `shoot.fbx`-Posespuren. Die Showcase-Map ist damit nur Pruefstand, nicht der einzige Besitzer dieser Animationen.

## Waffenanker
- Das Waffen-Root bleibt am Socket (`RightHandSocket` oder Loadout-Socket). Aim-/Ready-Pose darf Rotation/Pitch und Child-Yaw setzen, aber den Root nicht vom Socket weg verschieben.
- Die sichtbare Aim-/Anschlag-Pose kommt aus der importierten `shoot.fbx` und wird im Primary3DView-Skeleton-Pfad nur auf Oberkoerper-/Arm-Bones gelegt. Der importierte `0_Targeting Pose`-Clip darf dafuer nicht verwendet werden, weil er sichtbar eine T-/A-Pose setzt. Idle/Walk bleiben Basisanimationen; die Unit-Animation laeuft im bestehenden Visualpfad kontrolliert, damit die Aim-Pose nicht wieder von der Laufanimation ueberschrieben wird.
- Importierte Animated-Characters-Clips haben Vorrang vor handgebauten Ersatzposen, wenn beide denselben sichtbaren Zweck erfuellen. Combat-Mischfaelle wie `walkShoot`, `runShoot`, `crouchShoot`, `crouchWalkShoot` und `crouchRunShoot` duerfen importierte `shoot.fbx`-Oberkoerperspuren ueber vorhandene importierte Bewegungsclips legen. Der getestete rechte-Waffenarm-only-Mix ist fuer Crouch verworfen, weil er den Arm sichtbar nach hinten kippt. Keiner dieser Faelle darf eine konkurrierende Zielpose neu erfinden.
- Asset-Pivot-Korrekturen gehoeren in die bestehende Attachment-Visual-Schicht (`visual_offset`, `visual_rotation_degrees`) und nicht in Runtime-Posture-Offsets.
- Die sichtbare Fire-Sector-/Weapon-Linie darf am sichtbaren Weapon-Visual beginnen, aber nicht durch einen verschobenen Gameplay-Anker eine zweite Schussrichtung erzeugen.

## Enemy-Pfad
- Gegner setzen Security- und Combat-Facing ueber `enemy_facing_angle` sowie dieselben Runtime-Posture-Felder.
- Enemy-Proxies laufen durch denselben Primary3DView-Unit-Proxy-Pfad wie Friendly-Proxies; es gibt keine separate Gegner-Modellrotation.

## Regressionen
- `task_401_facing_sightline_debug_map.gd` prueft Friendly-Facing, Move-Commands, Skeleton-Forward, Weapon-/Shot-Linie, Waffenroot am Socket, die aus `shoot.fbx` uebernommene Oberkoerper-/Waffenhand-Pose und Q/E-Kamerarotation ohne Aim-Pose-Verlust.
- `task_344_ground_mission_default_enemy_visuals.gd` prueft Enemy-Fire-Events gegen sichtbares Skeleton-Facing, Waffenroot am Socket und die aus `shoot.fbx` uebernommene Oberkoerper-/Waffenhand-Pose.
- `task_402_npc_animation_showcase_map.gd` prueft alle 17 importierten Rohclips und die sechs datenverankerten Combat-Cases aus importierten Basisclips plus fallweise importierten `shoot`-Posespuren.
- `task_403_runtime_animation_combat_cases.gd` prueft, dass dieselben Rohclips und Combat-Cases im Spiel-Visualpfad der Unit-Proxies verfuegbar sind und aus `movement_posture`/`weapon_posture` ausgewaehlt werden.
- `task_364_mission_fireteam_orientation_indicators.gd`, `bugfix_mission_fire_sector_overlay.gd`, `task_371_fire_sector_security_arc_overlay_toggle.gd` und `task_372_mission_los_debug_overlay_toggle.gd` sichern die bestehenden Overlay-Pfade.
