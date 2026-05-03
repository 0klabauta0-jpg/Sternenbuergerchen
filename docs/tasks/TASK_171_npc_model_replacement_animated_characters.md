# TASK_171 - NPC Model Replacement Animated Characters

## Ziel
Die vorhandenen NPC-/Unit-Visuals werden testweise durch ein kleines, kuratiertes Subset aus `C:\Users\bjoer\Pictures\Sternenbürger\Animated Characters Bundle` ersetzt oder vorbereitet.

## Status: IMPLEMENTIERT

## Ergebnis
- Das lokale Bundle wurde inventarisiert und die CC0-Lizenz aus `License.txt` dokumentiert.
- Ein kleines Subset wurde nach `Assets/used/npc/animated_characters/` importiert:
  - `characterMedium.fbx`
  - `characterSmall.fbx`
  - `astroMaleA.png`
  - `astroFemaleA.png`
  - `idle.fbx`
  - `walk.fbx`
  - `License.txt`
- `data/npc_unit_visual_mapping.json` mappt Team Alpha und Team Bravo explizit auf die neuen Character-Modelle und Astro-Skins.
- `TerrainMap3DView` nutzt dieses Mapping nur fuer 2.5D-Unit-Visuals und zaehlt `animated_unit_model_count`, `unit_visual_error_count` und `unit_visual_mapping_loaded` im Render-Snapshot.
- Fehlende Modelle oder Skins erzeugen sichtbare Missing-Asset-Marker und werden nicht still auf alte Astronaut-Assets zurueckgebogen.
- `scripts/tests/task_171_npc_model_replacement_verifier.gd` prueft Import-Subset, Resource-Ladung, Live-2.5D-Unit-Proxies und dass der Visual-Refresh keine `SimulationRoot`-Commands oder -Effects enqueued.

## Pflicht vor Beginn
- Arbeite auf Branch `task/replace-npc-models-animated-characters`.
- Lies `AGENTS.md`.
- Lies `docs/PROJECT_BRIEF.md`.
- Lies `docs/ARCHITECTURE.md`.
- Lies `docs/CODEX_RULES.md`.
- Lies `docs/IMPLEMENTATION_STATUS.md`.
- Lies `docs/assets/local_asset_curation_import_plan.md`.
- Lies relevante 2.5D-/UI-/Asset-Dokumentation.
- Pruefe den Git-Status.
- Fasse unrelated Aenderungen nicht an, insbesondere nicht:
  - `maps/wall_test_4x4.json`
  - `scripts/meta/npc_meta_card.gd`

## Kontext
- TASK_159/TASK_160 haben die 2.5D-Primary-View als sichtbaren Runtime-Pfad etabliert.
- TASK_165 blockiert Massenimporte und verlangt kleine, nachvollziehbare Asset-Slices.
- Der aktuelle Runtime-Pfad nutzt vorhandene Astronaut-/Unit-Visuals; Gameplay-State bleibt bei `SimulationRoot`.
- Das lokale `Animated Characters Bundle` enthaelt Modelle, Animationen, Skins, Preview-Material und eine Lizenzdatei.

## Umfang
1. Inventar des lokalen Bundles erstellen:
   - Modelle
   - Animationen
   - Skins
   - Lizenz
2. `License.txt` lesen und kurz in der Importdoku dokumentieren.
3. Importstrategie dokumentieren:
   - Quelle
   - Lizenzhinweis
   - Zielpfad
   - Auswahlgrund
   - Verbrauchsort
4. Nur ein minimales Subset importieren:
   - 1-2 Character-Modelle
   - passende Skins
   - nur wenn Godot sie sauber importiert: Idle-/Walk-Testanimationen
5. Bevorzugter Zielpfad:
   - `assets/used/npc/animated_characters/`
6. Einen kleinen Godot-kompatiblen Visual-Wrapper bauen:
   - `.tscn`, Resource-Mapping oder ein schlanker Visual-Factory-/Manifest-Pfad
7. Bestehende Runtime-NPC-/Unit-Visuals nur im 2.5D-/Visual-Pfad testweise auf das neue Modell mappen.
8. Bestehende Astronaut-/Fallback-Assets nicht loeschen.
9. Fehlende oder kaputte Imports sichtbar melden, nicht still fallbacken.
10. Einen kleinen Verifier oder Smoke-Test ergaenzen.
11. Dokumentation aktualisieren:
   - diese Task-Datei
   - `docs/IMPLEMENTATION_STATUS.md`
   - ggf. `docs/assets/local_asset_curation_import_plan.md`

## Nicht-Ziele
- Kein Massenimport des ganzen Bundles.
- Keine Entfernung vorhandener Astronaut-/Fallback-Assets.
- Keine Aenderung an Gameplay-State, Combat, Navigation oder Multiplayer-Vertraegen.
- Keine neue NPC-Identity-, Skill- oder Loadout-Logik.
- Keine Meta-Karten-Ueberarbeitung ausser einem rein visuellen Verweis, falls unbedingt noetig.

## Architekturregeln
- Gameplay-State bleibt unveraendert bei `SimulationRoot`.
- UI, Meta-Karten und 2.5D-View duerfen nur Visuals spiegeln, keine Wahrheit halten.
- Der Importpfad darf keine stillen Fallbacks einfuehren.
- Neue Visual-Komponenten duerfen keine SceneTree-Vollscans im Hotpath erzwingen.
- Asset-Mapping muss klein, explizit und testbar bleiben.

## Akzeptanzkriterien
- Das Bundle-Inventar ist dokumentiert.
- Lizenzhinweis aus `License.txt` ist kurz dokumentiert.
- Nur ein kleines, nachvollziehbares Subset wurde importiert.
- Ein Godot-kompatibler Visual-Wrapper oder ein Resource-Mapping existiert.
- Mindestens ein Runtime-Unit-Proxy kann das neue Modell im 2.5D-/Visual-Pfad referenzieren.
- Fehlende oder fehlerhafte neue Assets werden sichtbar gemeldet.
- Bestehende Astronaut-/Fallback-Assets bleiben erhalten.
- Ein Verifier oder Smoke-Test prueft:
  - neues Modell wird referenziert/importiert
  - 2.5D Unit-Proxy bleibt sichtbar
  - keine Gameplay-State-Mutation ausserhalb `SimulationRoot`

## Lokale Pruefung
- [x] Inventar und Lizenzdokumentation erstellt.
- [x] Import-Subset unter `Assets/used/npc/animated_characters/` bleibt klein.
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_171_npc_model_replacement_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_159_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_170_performance_warning_gate_verifier.gd`
- [x] `powershell -ExecutionPolicy Bypass -File scripts/tests/run_task_170_warning_gate.ps1`
- [x] `git diff --check`
- [ ] Manueller Sichtcheck in Godot, falls neue 3D-Imports visuell beurteilt werden muessen.

## Risiken
- FBX-/Animationsimporte koennen in Godot versions- oder importabhaengig instabil sein.
- Animationen koennen ein eigenes Retargeting-/Skeleton-Thema erfordern; dann nur Modell-/Skin-Wrapper vorbereiten und Animation als Folge-Task schneiden.
- Zu grosse Asset-Imports koennen das Repo unnoetig aufblaehen; deshalb Maximalmenge strikt klein halten.
- Neue NPC-Modelle duerfen die bestehende 2.5D-Kalibrierung nicht verdecken oder den Unit-Proxy unlesbar machen.
