# Unit Facing Visual Contract

## Zweck
Dieser Contract verankert den bestehenden Weg fuer Unit-Facing, Sichtlinie, Waffen-/Schusslinie und sichtbare 3D-Modellrotation. Er gilt fuer Friendly- und Enemy-NPCs in Missionen und verhindert, dass UI-, Plan- oder Overlay-Code eine zweite Facing-Wahrheit einfuehrt.

## Wahrheit
- Gameplay- und Runtime-Facing liegt auf der Unit als `facing_angle`, `map_facing_angle` oder bei Gegnern zusaetzlich `enemy_facing_angle`.
- `UnitRuntimeStatus` und `UnitCommand` tragen `movement_posture`, `weapon_posture` und `target_position`, aber keine eigene 3D-Modellrotation.
- Combat-Facing wird ueber die bestehenden Effects in `SimulationRoot` committed. Fire-Events bleiben Runtime-/VFX-Payloads; die Anzeige liest sie zusammen mit aktuellem Unit-/Contact-State, ohne selbst Gameplay-Facing zu schreiben.

## Controller- und Plan-Pfad
- `MissionTacticalSandboxController` baut Fireteam-Orientation-Payloads aus Movement, Security, Unit-Facing oder geplantem Target.
- Bestehende Plaene, Ad-hoc-Orders, Area-Orders und Post-Drop-Security duerfen Facing nur ueber Unit-Metadaten, Movement-State oder Anchor-Payloads beschreiben.
- UI-Karten und Panels duerfen selektieren, Befehle ausloesen und Payloads spiegeln, aber keine eigene Modell-/Sichtlinienrotation speichern.

## Primary3DView-Pfad
- `TerrainMap3DView` liest Unit-Nodes live aus `_unit_nodes`. Fuer Modell, Waffenpose, Sichtlinie und Fireteam-Orientation gilt derselbe Quellenrang nach `fireteam_behavior_modes_contract.md` TASK_459/461/464: aktives Fire-Event, bestaetigter/spotted Kontakt, aktuelle Bewegung beziehungsweise aktives Commandziel, aktiver Securityscan, statisches Unit-Facing, danach blosse Target-/Proxy-Fallbacks.
- Ein von der letzten Runtime-Aktion uebriges `target_position` ist allein kein aktiver Bewegungsauftrag. Der Vorrang vor Security-/Unit-Facing gilt fuer das vorhandene aktive `UnitCommand` mit `move_to_position` oder `engage_area`, die `SimulationRoot` tatsaechlich als Bewegung verarbeitet. Die abstrakten Legacytypen `retreat`/`seek_cover` werden im Root nicht direkt ausgefuehrt und erzeugen allein keinen aktiven Movementvorrang. Ein `hold_position` behaelt ohne Fire-Event/Kontakt die Security-/Facing-Richtung. Tatsaechliche Positionsaenderung bleibt auch ohne Commandziel als aktuelle Bewegung erkennbar.
- Bei einem aktiven committed Bewegungscommand ist `facing_angle` der von `SimulationRoot` geschriebene tatsaechliche Pfad-/Avoidancewinkel. Mehrere Visualsyncs innerhalb desselben Simulationsticks duerfen nach Verbrauch des Positionsdeltas nicht zum entfernten Endziel zurueckdrehen. Der View liest dieses Facing ohne den Securityscan-Override; fehlt es, bleibt das aktive Commandziel der Fallback.
- Fireteam-Orientation und deren Dirtysignatur lesen dieselbe aktuelle Aim-Richtung wie die Unit-Proxies. Eine alte statische Anchor-/Facing-Richtung darf einen aktuellen Schuss, Kontakt oder Move nicht widersprechend ueberschreiben. Bei einem Team aus mehreren Mitgliedern bleibt der bestehende erste sichtbare Richtungsanker erhalten; es wird kein neuer Gameplay-Teamwinkel berechnet.
- Pulse und aktive Firepose lesen dieselbe bounded Latest-current-Auswahl nach autoritativem Tick und bei Gleichstand gepaddeter Driver-Event-ID. `presentation_history_only` ist ausschliesslich Evidence und erzeugt keine aktive Firepose. Die Poseindexrevision beruecksichtigt alle acht aktuellen Quellen am Payloadeingang unabhaengig vom bestehenden Dreierbudget fuer Heavy-Traces/Text; FoW-Admit bleibt im jeweiligen bestehenden Visualpfad.
- Unit-Proxies nutzen `_get_unit_world_direction_yaw()` fuer die importierte Character-Forward-Achse. Die allgemeine `_get_world_direction_yaw()` bleibt fuer Nicht-Unit-Pfade wie Dropships reserviert.
- `_get_world_direction_from_proxy_yaw()` ist der inverse Unit-Proxy-Pfad und darf nicht wieder auf die alte allgemeine World-Yaw-Annahme zurueckfallen.
- Fireteam-Orientation und Fire-Sector-/Weapon-Linie nutzen die vorhandenen Primary3DView-Snapshots und lesen bei gueltigem Anchor aktuelle Unit-Position/Facing live.
- Der Runtime-AnimationPlayer der Unit-Proxies laedt die importierten Animated-Characters-Rohclips aus dem Visual-Mapping und baut die datengetriebenen `animation_combat_cases` aus importierten Basisclips plus importierten `shoot.fbx`-Posespuren. Die Showcase-Map ist damit nur Pruefstand, nicht der einzige Besitzer dieser Animationen.
- Auch `standShoot` baeckt die importierte `shoot`-Oberkoerper-Holdpose bei der Clipkonstruktion ueber den bestehenden `shoot_upper_body`-Baker als konstante Rotationstracks. Der Originalrohclip, Bein-/Basisbewegung und fortlaufende Clipzeit bleiben erhalten. So darf ein normales AnimationAdvance die bestehende Anschlagpose bei gleichbleibender Payload nicht ueberschreiben; dafuer wird kein zweiter per-Frame-Poseowner eingefuehrt.

## Waffenanker
- Das Waffen-Root bleibt am Socket (`RightHandSocket` oder Loadout-Socket). Aim-/Ready-Pose darf Rotation/Pitch und Child-Yaw setzen, aber den Root nicht vom Socket weg verschieben.
- Die sichtbare Aim-/Anschlag-Pose kommt aus der importierten `shoot.fbx` und wird im Primary3DView-Skeleton-Pfad nur auf Oberkoerper-/Arm-Bones gelegt. Der importierte `0_Targeting Pose`-Clip darf dafuer nicht verwendet werden, weil er sichtbar eine T-/A-Pose setzt. Idle/Walk bleiben Basisanimationen; die Unit-Animation laeuft im bestehenden Visualpfad kontrolliert, damit die Aim-Pose nicht wieder von der Laufanimation ueberschrieben wird.
- Importierte Animated-Characters-Clips haben Vorrang vor handgebauten Ersatzposen, wenn beide denselben sichtbaren Zweck erfuellen. Combat-Mischfaelle wie `walkShoot`, `runShoot`, `crouchShoot`, `crouchWalkShoot` und `crouchRunShoot` duerfen importierte `shoot.fbx`-Oberkoerperspuren ueber vorhandene importierte Bewegungsclips legen. Der getestete rechte-Waffenarm-only-Mix ist fuer Crouch verworfen, weil er den Arm sichtbar nach hinten kippt. Keiner dieser Faelle darf eine konkurrierende Zielpose neu erfinden.
- Asset-Pivot-Korrekturen gehoeren in die bestehende Attachment-Visual-Schicht (`visual_offset`, `visual_rotation_degrees`) und nicht in Runtime-Posture-Offsets.
- Die belegten `blaster-a`/`blaster-f`-Loadouts korrigieren den alten umgekehrten sichtbaren Meshchild lokal ueber `blaster_attachment.visual_rotation_degrees=[0,0,0]` und erben dabei explizit alle bisherigen Defaultattachmentwerte. Das gilt fuer die sichtbare Meshfront in Idle, Ready und Aim; es gibt keinen zusaetzlichen bedingten Aimed-Pivotowner. Andere Loadouts behalten ihre bisherige Attachmentkonfiguration. Muzzle-Marker bleiben an der echten negativen-Z-Meshfront, Root-/Socketoffsets und Skalierung werden dafuer nicht verschoben. Idle-Richtungspruefungen verwenden ActualMeshfront, kanonischen Body-Back und die geometrische Magazine-Y-Achse statt WaffenROOT/Proxy+Z/positivemY.
- Die sichtbare Fire-Sector-/Weapon-Linie darf am sichtbaren Weapon-Visual beginnen, aber nicht durch einen verschobenen Gameplay-Anker eine zweite Schussrichtung erzeugen.

## Enemy-Pfad
- Gegner setzen Security- und Combat-Facing ueber `enemy_facing_angle` sowie dieselben Runtime-Posture-Felder.
- Enemy-Proxies laufen durch denselben Primary3DView-Unit-Proxy-Pfad wie Friendly-Proxies; es gibt keine separate Gegner-Modellrotation.

## Regressionen
- `task_174_character_helmet_blaster_attachment_verifier.gd` misst im normalen Idle die echte primaere Meshfront (-Z), die geometrische Magazinrichtung (-Y) und den kanonischen Body-Back bei unveraenderten Richtungsschwellen0.85/0.70. Der alte ROOT-/Proxy+Z-/Magazine+Y-Vergleich war kein gueltiges Mesh-Oracle.
- `runtime_hitches_r4_20261107_pose_stability_verifier.gd` prueft reale importierte Hold-Bonequaternionen bei Frame0/3/10 und fortlaufende Clipzeit; `runtime_hitches_r4_20261107_muzzle_anchor_verifier.gd` prueft echte Mesh-/Sockettransforms, Richtung, Nachfuehrung und Aim/Idle/Aim-Reset ohne Actorpatch. Diese Rendererfixtures ersetzen keine native Pixelabnahme.
- `runtime_hitches_r4_20261107_fire_pose_feed_verifier.gd` prueft mit originalem Human-/Waffenmesh Current gegen alte History, geshuffelte Ticks und eine erneuerte fruehe Quelle bei unveraenderter letzter Dreiergruppe; Heavy-Nodeidentitaeten und Actorstate bleiben dabei gleich.
- `task_401_facing_sightline_debug_map.gd` prueft Friendly-Facing, Move-Commands, Skeleton-Forward, Weapon-/Shot-Linie, Waffenroot am Socket, die aus `shoot.fbx` uebernommene Oberkoerper-/Waffenhand-Pose und Q/E-Kamerarotation ohne Aim-Pose-Verlust.
- `task_344_ground_mission_default_enemy_visuals.gd` prueft Enemy-Fire-Events gegen sichtbares Skeleton-Facing, Waffenroot am Socket und die aus `shoot.fbx` uebernommene Oberkoerper-/Waffenhand-Pose.
- `task_402_npc_animation_showcase_map.gd` prueft alle 17 importierten Rohclips und die sechs datenverankerten Combat-Cases aus importierten Basisclips plus fallweise importierten `shoot`-Posespuren.
- `task_403_runtime_animation_combat_cases.gd` prueft, dass dieselben Rohclips und Combat-Cases im Spiel-Visualpfad der Unit-Proxies verfuegbar sind und aus `movement_posture`/`weapon_posture` ausgewaehlt werden.
- `task_364_mission_fireteam_orientation_indicators.gd`, `bugfix_mission_fire_sector_overlay.gd`, `task_371_fire_sector_security_arc_overlay_toggle.gd` und `task_372_mission_los_debug_overlay_toggle.gd` sichern die bestehenden Overlay-Pfade.
- `bugfix_mission_fire_sector_overlay.gd` trennt Hold mit abweichenden Target-Metadaten, aktiven Scan, ueber `SimulationRoot` committed Move, bestaetigten Kontakt und Fire-Event. Die synthetischen Kontakt-/Event-Fixtures sind Datenflussregressionen; physisches Schiessen wird separat im nativen normalen Missionspfad belegt.
