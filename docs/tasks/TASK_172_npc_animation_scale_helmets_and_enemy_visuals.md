# TASK_172 - NPC Animation Scale Helmets and Enemy Visuals

## Ziel
Die in `TASK_171` importierten Animated-Characters-NPC-Modelle werden im 2.5D-Visual-Pfad spielbar gemacht: sichtbar deutlich kleiner, mit Idle-/Walk-Animationen, mit Helm-Attachments und auch fuer Gegner-NPCs.

## Status: IMPLEMENTIERT

## Ergebnis
- Die Animated-Character-Unit-Visuals sind im 2.5D-Pfad von `0.66` auf `0.22` skaliert und damit ca. zwei Drittel kleiner als in TASK_171.
- `idle.fbx` und `walk.fbx` werden in einen rein visuellen `UnitVisualAnimationPlayer` uebernommen.
- Stehende Proxies spielen `idle`, sichtbar bewegte Proxies wechseln auf `walk`.
- `astroHelmet.fbx` und `militaryHelmet.fbx` wurden als kleines Accessory-Subset importiert.
- Helme werden rein visuell ueber `BoneAttachment3D` am Kopf-Bone befestigt; falls kein Kopf-Bone gefunden wird, nutzt der Visual-Pfad einen dokumentierten `HeadAnchor`. Nach manuellem Sichtcheck wird der Helm per `fit_to_model` aus Character- und Helm-Mesh-Bounds berechnet und zusaetzlich auf `max_scale: 0.016` begrenzt, damit der bisher noch zu grosse Helm um ca. zwei Drittel kleiner wird.
- Gegner-IDs `enemy_delta` und `enemy_echo` haben explizite Enemy-Visual-Mappings und nutzen ebenfalls Animated-Character-Modelle mit Helm.
- `TerrainMap3DView.get_render_snapshot()` meldet AnimationPlayer-, Animation-Error-, Helmet-Attachment-, Helmet-Error- und Enemy-Animated-Model-Zaehler.
- `scripts/tests/task_172_npc_animation_scale_helmet_enemy_verifier.gd` prueft Mapping, Ressourcen, Live-2.5D-Proxies, Enemy-Visuals, Scale, Idle/Walk, Helm-Attachments und dass keine `SimulationRoot`-Commands oder -Effects entstehen.

## Pflicht vor Beginn
- Arbeite auf einem neuen Branch, z. B. `task/npc-animation-scale-helmets-enemies`.
- Lies `AGENTS.md`.
- Lies `docs/PROJECT_BRIEF.md`.
- Lies `docs/ARCHITECTURE.md`.
- Lies `docs/CODEX_RULES.md`.
- Lies `docs/IMPLEMENTATION_STATUS.md`.
- Lies `docs/TASK_ROADMAP.md`.
- Lies `docs/tasks/TASK_171_npc_model_replacement_animated_characters.md`.
- Lies `docs/assets/animated_characters_bundle_inventory.md`.
- Lies `docs/assets/local_asset_curation_import_plan.md`.
- Pruefe den Git-Status.
- Fasse unrelated Aenderungen nicht an, insbesondere nicht:
  - `maps/wall_test_4x4.json`
  - `scripts/meta/npc_meta_card.gd`

## Kontext
- `TASK_171` hat ein kleines Subset aus dem lokalen `Animated Characters Bundle` importiert.
- Aktuelles Mapping: `data/npc_unit_visual_mapping.json`.
- Aktuelle Default-Skalierung: `0.66`.
- Die Modelle wirken in der manuellen Sichtpruefung zu gross und muessen nach User-Vorgabe "2/3 kleiner" werden.
- Idle-/Walk-FBX-Dateien sind bisher nur Import-Probes und noch nicht als echte Runtime-Animation eingebunden.
- Im lokalen Bundle existieren Helm-/Accessory-Dateien, u. a.:
  - `Accessories/astroHelmet.fbx`
  - `Accessories/militaryHelmet.fbx`
  - `Accessories/racingHelmet.fbx`
- Gegner-NPCs laufen in den Missionsdaten typischerweise ueber `team_bravo` und Enemy-IDs wie `enemy_delta` / `enemy_echo`.

## Umfang
1. Modellgroesse korrigieren:
   - `data/npc_unit_visual_mapping.json` oder einen Visual-Wrapper so anpassen, dass die neuen NPC-Modelle ca. zwei Drittel kleiner wirken.
   - Ausgangspunkt ist `0.66`; als erster Zielwert gilt ca. `0.22`, falls keine bessere visuelle Kalibrierung im Godot-Sichtcheck entsteht.
   - Nur den 2.5D-Visual-Pfad aendern, keine `Node2D`-Runtime-Anker, Kollisionsdaten oder SimulationRoot-Positionen.
2. Animationen produktiv einbinden:
   - `idle.fbx` und `walk.fbx` in einen Godot-kompatiblen Visual-Wrapper integrieren.
   - Wenn Skeleton-/Bone-Namen kompatibel sind, Animationen auf das Modell mappen oder in eine `AnimationPlayer`-/`AnimationTree`-Struktur ueberfuehren.
   - Idle abspielen, wenn die Unit steht.
   - Walk abspielen, wenn der 2.5D-Proxy sichtbare Bewegung spiegelt.
   - Fehlende oder inkompatible Animationen sichtbar melden und im Snapshot zaehlen; kein stiller statischer Fallback als "fertig" verkaufen.
3. Helm-Import als kleines Accessory-Subset:
   - Nur die benoetigten Helm-FBX-Dateien importieren, bevorzugt `astroHelmet.fbx` und optional `militaryHelmet.fbx`.
   - Quelle, Lizenz und Zielpfad dokumentieren.
   - Kein Import aller Accessories.
4. Helme anziehen:
   - Helme nicht als Gameplay-Loadout behandeln.
   - Helme als rein visuelles Attachment am NPC-Modell befestigen.
   - Bevorzugter Godot-Weg: `BoneAttachment3D` am `Skeleton3D`-Kopfknochen, daran die Helm-Scene haengen.
   - Wenn kein stabiler Kopf-Bone gefunden wird: festen `HeadAnchor` im Visual-Wrapper verwenden und den Grund dokumentieren.
   - Helm-Offsets, Rotation und Scale explizit im Mapping oder Wrapper halten, nicht per Szene-Suche raten.
5. Gegner-NPCs auf neue Modelle mappen:
   - Sicherstellen, dass `team_bravo` und konkrete Enemy-IDs wie `enemy_delta` / `enemy_echo` im 2.5D-Pfad die neuen Animated-Character-Visuals nutzen.
   - Gegner duerfen eine andere Skin-/Helm-Kombination bekommen, aber keine neue Gegnerlogik.
   - Alte `astronautB`-/Fallback-Assets bleiben erhalten, werden im Primary-Pfad aber nicht still genutzt, wenn das neue Mapping erwartet wird.
6. Visual-Diagnose erweitern:
   - Snapshot-Zaehler fuer animierte Units, fehlende Animationen, Helm-Attachments und Enemy-Visual-Mapping pruefbar machen.
   - Missing-Asset-Marker fuer fehlende Modelle, Skins, Animationen oder Helme beibehalten.
7. Verifier/Smoke-Test ergaenzen:
   - Freundliche Unit und Gegner-Unit werden im 2.5D-Pfad mit Animated-Character-Modell erzeugt.
   - Skalierungswert wird aus Mapping/Wrapper gelesen und liegt im erwarteten Bereich.
   - Idle-/Walk-Animationen sind referenziert und mindestens ein `AnimationPlayer` oder kompatibler Animationspfad ist vorhanden.
   - Helm-Visual ist an Kopf-Bone oder dokumentiertem HeadAnchor angehaengt.
   - Visual-Refresh enqueued keine `SimulationRoot`-Commands oder -Effects.

## Nicht-Ziele
- Keine Aenderung an Gameplay-State, Combat, Navigation, LOS, Damage oder Multiplayer-Vertraegen.
- Keine Loadout-Mechanik fuer Helme.
- Keine Ruestungswerte, Hitbox-Aenderungen oder Friendly-Fire-Erkennung durch Helme.
- Kein Massenimport des gesamten Accessory-Ordners.
- Kein kompletter Character-Customizer.
- Keine Meta-Karten-Ueberarbeitung ausser einem rein visuellen Hinweis, falls noetig.

## Architekturregeln
- Gameplay-Wahrheit bleibt bei `SimulationRoot`.
- 2.5D-View und Visual-Wrapper spiegeln nur Darstellung.
- Keine SceneTree-Vollscans im Hotpath.
- Asset-Mapping bleibt explizit, klein und testbar.
- Fehlerhafte Visuals muessen sichtbar und zaehlbar sein.
- Animation darf Bewegung nur anzeigen, nicht Bewegung entscheiden.

## Akzeptanzkriterien
- [x] Neue NPC-Modelle sind im 2.5D-Pfad ca. zwei Drittel kleiner als in TASK_171.
- [x] Idle-Animation laeuft sichtbar bei stehenden Units.
- [x] Walk-Animation laeuft sichtbar bei bewegten Units.
- [x] Mindestens ein Helm ist importiert und an friendly NPCs sichtbar angehaengt.
- [x] Gegner-NPCs nutzen ebenfalls Animated-Character-Modelle und bekommen ein eigenes sichtbares Visual-Mapping.
- [x] Fehlende Modelle, Skins, Animationen oder Helme erzeugen sichtbare Missing-Asset-Marker oder klare Snapshot-Zaehler.
- [x] Bestehende Astronaut-/Fallback-Assets bleiben im Repo erhalten.
- [x] Der Verifier beweist, dass der Visual-Pfad keine Gameplay-State-Mutation ausserhalb `SimulationRoot` ausloest.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_172_npc_animation_scale_helmet_enemy_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_171_npc_model_replacement_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_159_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_170_performance_warning_gate_verifier.gd`
- [x] `powershell -ExecutionPolicy Bypass -File scripts/tests/run_task_170_warning_gate.ps1`
- [x] `git diff --check`
- [ ] Manueller Godot-Sichtcheck: Mission starten, friendly Units und Gegner betrachten, Skalierung, Idle, Walk und Helm-Sitz pruefen.

## Voraussichtlich betroffene Dateien
- `data/npc_unit_visual_mapping.json`
- `Assets/used/npc/animated_characters/`
- `docs/assets/animated_characters_bundle_inventory.md`
- `docs/assets/local_asset_curation_import_plan.md`
- `scripts/terrain/terrain_map_3d_view.gd`
- ggf. neuer Visual-Wrapper unter `scenes/` oder `scripts/terrain/`
- `scripts/tests/task_172_npc_animation_scale_helmet_enemy_verifier.gd`
- `docs/IMPLEMENTATION_STATUS.md`

## Risiken
- FBX-Animationen koennen andere Skeleton-/Bone-Namen nutzen als die Character-Modelle.
- Helm-Modelle koennen ohne Offset-Kalibrierung schweben, clipping erzeugen oder mit Animationen nicht sauber folgen.
- Zu kleine Modelle koennen aus der 2.5D-Kamera schlecht lesbar werden; die Zielskalierung muss manuell gegengeprueft werden.
- Gegner-Visuals duerfen nicht ueber Team-/Enemy-Mapping versehentlich Friendly/Enemy-Gameplay-Semantik veraendern.
