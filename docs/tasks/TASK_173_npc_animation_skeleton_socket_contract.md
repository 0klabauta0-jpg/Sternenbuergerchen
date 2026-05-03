# TASK_173 - NPC Animation Skeleton Socket Contract

## Ziel
Die Animated-Characters-NPCs bekommen einen stabilen visuellen Skeleton-/Socket-Vertrag fuer Idle/Walk und spaetere Attachments. Dieser Task beendet das Rate-Scaling fuer Helme nicht direkt, sondern schafft die Grundlage: welche Bones existieren, welche Animationen laufen darauf, und welche stabilen visuellen Sockets koennen Folge-Tasks verwenden.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Arbeite auf einem neuen Branch, z. B. `task/npc-animation-skeleton-sockets`.
- Lies `AGENTS.md`.
- Lies `docs/PROJECT_BRIEF.md`.
- Lies `docs/ARCHITECTURE.md`.
- Lies `docs/CODEX_RULES.md`.
- Lies `docs/IMPLEMENTATION_STATUS.md`.
- Lies `docs/TASK_ROADMAP.md`.
- Lies `docs/tasks/TASK_171_npc_model_replacement_animated_characters.md`.
- Lies `docs/tasks/TASK_172_npc_animation_scale_helmets_and_enemy_visuals.md`.
- Lies `docs/assets/animated_characters_bundle_inventory.md`.
- Pruefe den Git-Status.
- Fasse unrelated Aenderungen nicht an, insbesondere nicht:
  - `maps/wall_test_4x4.json`
  - `scripts/meta/npc_meta_card.gd`

## Kontext
- TASK_171 importierte Character-Modelle, Skins und Idle-/Walk-FBX-Dateien.
- TASK_172 bindet Animationen und Helme bereits im 2.5D-Pfad an, aber Helm-Sitz und Scale zeigen im manuellen Sichtcheck, dass feste Offsets und Bounds-Fits nicht reichen.
- Helme und spaeter Waffen brauchen stabile Attachments an Bones oder expliziten Anchors.

## Umfang
1. Skeleton-/Bone-Inventar erstellen:
   - `characterMedium.fbx`
   - `characterSmall.fbx`
   - `idle.fbx`
   - `walk.fbx`
   - relevante Skeleton-/Bone-Namen dokumentieren.
2. Animation-Vertrag pruefen:
   - Idle und Walk laufen auf beiden Character-Modellen.
   - Falls Animations-Track-Pfade nicht direkt passen, eine kleine, explizite Retarget-/Path-Mapping-Schicht fuer den Visual-Pfad einfuehren.
   - Kein Gameplay-Movement aus Animation ableiten.
3. Socket-Konzept definieren:
   - `HeadSocket`
   - `RightHandSocket`
   - optional `LeftHandSocket`
   - optional `BackSocket`
4. Sockets als rein visuelle Node-Struktur bereitstellen:
   - bevorzugt `BoneAttachment3D` an echten Bones.
   - fallback nur als dokumentierter Anchor, wenn ein Bone fehlt.
   - Socket-Offsets pro Modell in Mapping/Manifest halten, nicht im Code hart raten.
5. Visual-Diagnose erweitern:
   - Snapshot-Zaehler fuer erkannte Skeletons, verfuegbare Sockets, Socket-Fallbacks und Animation-Retarget-Fallbacks.
6. Verifier ergaenzen:
   - beide Character-Modelle haben Skeleton oder dokumentierten Fallback.
   - Idle/Walk sind auf beiden Modellen abspielbar.
   - `HeadSocket` und `RightHandSocket` existieren pro Live-Proxy.
   - Visual-Pfad erzeugt keine `SimulationRoot`-Commands oder -Effects.

## Nicht-Ziele
- Kein neuer Helm-/Waffen-Import.
- Keine finalen Helm- oder Waffen-Offsets.
- Keine Loadout-, Ruestungs-, Damage- oder Ballistik-Logik.
- Keine Aenderung an `SimulationRoot`, Combat, Navigation oder Multiplayer-Vertraegen.
- Kein Character-Customizer.

## Architekturregeln
- Gameplay-Wahrheit bleibt bei `SimulationRoot`.
- Animation und Sockets sind reine Darstellung.
- Keine SceneTree-Vollscans im Hotpath.
- Socket-Mapping bleibt explizit, klein und testbar.
- Fallbacks muessen sichtbar oder diagnostizierbar sein.

## Akzeptanzkriterien
- [x] Skeleton-/Bone-Inventar ist dokumentiert.
- [x] Idle und Walk laufen sichtbar auf beiden importierten Character-Modellen.
- [x] `HeadSocket` und `RightHandSocket` sind pro 2.5D-Live-Proxy vorhanden.
- [x] Socket-Fallbacks sind explizit dokumentiert und werden gezaehlt.
- [x] Keine Gameplay-State-Mutation ausserhalb `SimulationRoot`.
- [x] Bestehende TASK_171/TASK_172-Visual-Smokes bleiben gruen oder werden nur an den neuen Socket-Vertrag angepasst.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_173_npc_animation_skeleton_socket_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_172_npc_animation_scale_helmet_enemy_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_171_npc_model_replacement_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `git diff --check`
- [ ] Manueller Godot-Sichtcheck: Idle/Walk, Skeleton-Follow, Socket-Positionen sichtbar pruefen.

## Umsetzung
- `data/npc_unit_visual_mapping.json` definiert jetzt `HeadSocket`, `RightHandSocket`, `LeftHandSocket` und `BackSocket` mit Bone-Kandidaten, Offsets und dokumentierten Fallback-Ankern.
- `TerrainMap3DView` erzeugt die Sockets rein visuell als `BoneAttachment3D`, wenn der passende Bone existiert. Fallback-Anker werden nur bei fehlendem Bone erzeugt und im Snapshot gezaehlt.
- Neue Snapshot-Zaehler: `unit_skeleton_count`, `unit_socket_count`, `unit_socket_fallback_count`, `unit_head_socket_count`, `unit_right_hand_socket_count`, `unit_animation_retarget_fallback_count`.
- Die TASK_171-Modelle und Idle-/Walk-FBX-Dateien nutzen denselben Kern-Skeleton-Vertrag: `Hips`, `Spine`, `Head`, `RightHand`, `LeftHand`. Deshalb ist fuer diesen Slice keine Retarget-Fallback-Schicht aktiv.

## Voraussichtlich betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `data/npc_unit_visual_mapping.json` oder neues kleines Socket-Manifest
- `docs/assets/animated_characters_bundle_inventory.md`
- `scripts/tests/task_173_npc_animation_skeleton_socket_verifier.gd`
- `docs/IMPLEMENTATION_STATUS.md`

## Risiken
- FBX-Animationen koennen Track-Pfade nutzen, die nicht direkt zum Character-Skeleton passen.
- Bone-Namen koennen zwischen `characterMedium` und `characterSmall` variieren.
- Fallback-Anchors sind sichtbar, aber nicht so robust wie echte Bone-Attachments.
