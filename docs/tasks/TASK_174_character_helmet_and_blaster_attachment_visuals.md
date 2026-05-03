# TASK_174 - Character Helmet and Blaster Attachment Visuals

## Ziel
Helme und ein kleines Blaster-Waffen-Subset werden als saubere visuelle Attachments an die in TASK_173 definierten Character-Sockets gehaengt. Ziel ist, dass Helme nicht schweben und Blaster passend in der Hand sitzen, ohne Gameplay-State, Loadout-Logik oder Combat-Balance zu veraendern.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Arbeite auf einem neuen Branch, z. B. `task/character-helmet-blaster-attachments`.
- Lies `AGENTS.md`.
- Lies `docs/PROJECT_BRIEF.md`.
- Lies `docs/ARCHITECTURE.md`.
- Lies `docs/CODEX_RULES.md`.
- Lies `docs/IMPLEMENTATION_STATUS.md`.
- Lies `docs/TASK_ROADMAP.md`.
- Lies `docs/tasks/TASK_171_npc_model_replacement_animated_characters.md`.
- Lies `docs/tasks/TASK_172_npc_animation_scale_helmets_and_enemy_visuals.md`.
- Lies `docs/tasks/TASK_173_npc_animation_skeleton_socket_contract.md`.
- Lies `docs/assets/local_asset_curation_import_plan.md`.
- Pruefe den Git-Status.
- Fasse unrelated Aenderungen nicht an, insbesondere nicht:
  - `maps/wall_test_4x4.json`
  - `scripts/meta/npc_meta_card.gd`

## Kontext
- Der Helm-Sichtcheck aus TASK_172 zeigt: reine Scale-/Bounds-Fits reichen nicht; Helme muessen auf stabile `HeadSocket`-Daten kalibriert werden.
- Der lokale Waffenpfad ist `C:\Users\bjoer\Pictures\Sternenbuerger\Blaster Kit`.
- Der Blaster Kit enthaelt parallele GLB/FBX/OBJ-Dateien. Fuer diesen Task gilt GLB-only und kleines Subset.
- TASK_173 muss vorher einen stabilen Socket-Vertrag bereitstellen.

## Umfang
1. Blaster Kit inventarisieren:
   - Dateitypen und relevante Modelle.
   - Lizenz aus `License.txt` lesen und dokumentieren.
2. Kleines Blaster-Subset importieren:
   - maximal 3 GLB-Blaster.
   - optional 1 Preview-PNG, falls fuer Dokumentation oder spaetere UI nuetzlich.
   - Zielpfad bevorzugt `Assets/used/npc/blaster_kit/`.
   - keine FBX/OBJ/MTL-Duplikate importieren.
3. Helm-Attachments kalibrieren:
   - bestehende `astroHelmet.fbx` und `militaryHelmet.fbx` an `HeadSocket` haengen.
   - pro Modell explizite Offset-/Rotation-/Scale-Werte im Mapping/Manifest halten.
   - Helme duerfen nicht sichtbar ueber den Koepfen schweben.
4. Blaster-Attachments kalibrieren:
   - friendly und enemy Proxies bekommen mindestens einen sichtbaren Blaster an `RightHandSocket`.
   - Blaster-Offset, Rotation und Scale pro Modell/Weapon-Visual explizit halten.
   - Optional: bei Idle/Walk darf die Waffe am Hand-Socket folgen; keine Feueranimation noetig.
5. Visual-Mapping erweitern:
   - friendly/default Helm + Blaster.
   - enemy Helm + Blaster.
   - Missing-Asset-Marker und Snapshot-Zaehler fuer fehlende Weapon-Assets.
6. Verifier ergaenzen:
   - importierte GLB-Blaster sind loadbar.
   - Live-Proxies besitzen HeadSocket/RightHandSocket aus TASK_173.
   - Helm sitzt am HeadSocket, Blaster am RightHandSocket.
   - Visual-Refresh erzeugt keine `SimulationRoot`-Commands oder -Effects.

## Nicht-Ziele
- Keine Combat-Waffenwerte.
- Keine Loadout-Pipeline-Aenderung.
- Keine Ballistik, Projektile, Trefferlogik oder Munitionslogik.
- Kein Import des ganzen Blaster Kits.
- Keine Meta-/FOB-Loadout-UI-Aenderung.
- Keine neuen Gegnerverhalten.

## Architekturregeln
- Gameplay-State bleibt bei `SimulationRoot`.
- Helm und Blaster sind reine 2.5D-Visual-Attachments.
- Keine SceneTree-Vollscans im Hotpath.
- Asset-Mapping bleibt klein, explizit und testbar.
- Fehlende Assets erzeugen sichtbare Marker oder Snapshot-Zaehler.

## Akzeptanzkriterien
- [x] Blaster-Kit-Inventar und Lizenz sind dokumentiert.
- [x] Maximal 3 GLB-Blaster wurden importiert.
- [x] Helme haengen an `HeadSocket`; Mapping zentriert sie auf dem Socket und verkleinert sie fuer den naechsten manuellen Sichtcheck.
- [x] Friendly und enemy NPC-Proxies tragen sichtbare Blaster an der Hand.
- [x] Missing-Helm/Missing-Blaster-Faelle sind sichtbar oder im Snapshot gezaehlt.
- [x] Kein Gameplay-State wird ausserhalb `SimulationRoot` mutiert.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_174_character_helmet_blaster_attachment_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_173_npc_animation_skeleton_socket_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_172_npc_animation_scale_helmet_enemy_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `git diff --check`
- [ ] Manueller Godot-Sichtcheck: Helm-Sitz, Blaster-Sitz, Idle/Walk-Follow, friendly/enemy Lesbarkeit.

## Umsetzung
- Importiert wurden nur `blaster-a.glb`, `blaster-f.glb`, `blaster-p.glb`, die gemeinsame `models/Textures/colormap.png`, optional `previews/blaster-a.png` und die Lizenz.
- `TerrainMap3DView` haengt Helme jetzt bevorzugt an `HeadSocket` und Blaster an `RightHandSocket`; Bone-/Anchor-Fallbacks bleiben nur Reserve.
- Neue Snapshot-Zaehler: `unit_blaster_attachment_count` und `unit_blaster_error_count`.
- `data/npc_unit_visual_mapping.json` haelt Helm-/Blaster-Offsets, Rotation und Scale explizit im Visual-Mapping.
- Nach manuellem Sichtbefund wurden die Blaster stark verkleinert (`scale: 0.014`) und der Griffbereich per lokalem Mesh-Offset weiter zum Hand-Socket nachgezogen, damit sie nicht als weisse Balken ueber der Formation liegen oder am Magazin gehalten wirken.
- Nach weiterem Sichtbefund bleiben Helm- und Blaster-Offsets auf `[0, 0, 0]`: der FBX-Skeletonraum verstaerkt lokale Offsets stark, wodurch Helme unter die Karte und Blaster aus der Hand rutschen.
- Die sichtbaren Attachment-Meshes werden separat kalibriert: Helm-Meshes werden lokal weiter angehoben; beim Blaster werden die sichtbaren Achsen genutzt (`-Z` als Lauf, `+Y` als Magazin-/Griffseite), sodass der Lauf in Idle nach unten, das Magazin nach hinten vom NPC und der Griff zur Hand zeigt; die gemeinsame Blaster-`colormap.png` wird explizit als Material gesetzt.
- Die Runtime-Animationsauswahl bevorzugt jetzt namentlich passende `Idle`-/`Walk`-Clips und ignoriert importierte `0_Targeting Pose`-Clips, damit die Units nicht in der statischen T-Pose bleiben.

## Voraussichtlich betroffene Dateien
- `Assets/used/npc/blaster_kit/`
- `Assets/used/npc/animated_characters/`
- `data/npc_unit_visual_mapping.json` oder neues Attachment-Manifest
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/assets/local_asset_curation_import_plan.md`
- ggf. `docs/assets/blaster_kit_inventory.md`
- `scripts/tests/task_174_character_helmet_blaster_attachment_verifier.gd`
- `docs/IMPLEMENTATION_STATUS.md`

## Risiken
- Blaster-Modelle koennen andere Achsen/Origins haben und brauchen pro Asset Kalibrierung.
- Hand-Socket-Follow haengt von TASK_173 ab; ohne stabilen Socket wird dieser Task nicht sauber.
- Zu viele sichtbare Waffen koennen die 2.5D-Lesbarkeit verschlechtern; daher kleines Subset und manuelle Sichtpruefung.
