# MissionBriefing Contract

## Zweck
Mission-Briefings sind Szenario-Autorendaten. Sie erklaeren dem Spieler vor Missionsstart Zielbild, erwartete Bedrohung, optionale Loadout-Empfehlungen und die spaetere Karten-/Minimap-Darstellung.

## Besitz
- `MissionScenarioData.briefing` ist die persistierte Quelle fuer Briefing-Daten.
- Map Editor und spaetere Briefing-UI schreiben beziehungsweise lesen diesen Contract.
- Simulation, Runtime-Units, Registries und Loadout-System bleiben Gameplay-Wahrheit. Briefing-Empfehlungen mutieren keine Loadouts.

## Schema V1
- `title`: kurze Missionsueberschrift.
- `summary`: Freitext fuer die Lage.
- `background_image_path`: optionaler projektlokaler `res://`-Pfad zu einem Bild.
- `minimap_mode`: `terrain_only` oder `none`.
- `objectives`: Textzeilen oder `{ text, target_id }`-Eintraege.
- `threats`: Textzeilen oder `{ text, target_id }`-Eintraege.
- `recommended_loadout`: optionale, rein beratende Eintraege mit `label`, `role_id`, `armor_id`, `weapon_ids`, `count` und `reason`.
- `annotations`: vorbereiteter Platz fuer spaetere Briefing-Minimap-Hinweise. V1 erlaubt `kind`, `text`, `target_id`, `position` und `radius`, aber keine Terrain-Kopien.
- Team-Spawn-Overlays: UI-/Presenter-Schichten duerfen aus `vertical_slice.team_slots` read-only `team_spawn`-Eintraege fuer die Minimap ableiten. Diese Eintraege werden nicht als zweite Wahrheit in `briefing` gespeichert, sondern referenzieren bestehende Map-Marker wie `spawn_alpha` und `spawn_bravo`. Seit TASK_529 duerfen diese abgeleiteten Eintraege zusaetzlich kompakte Anzeige-Felder wie `icon_text`, `compact_label`, `compact_text`, `spawn_icon_text`, `icon_tooltip` und `visual_priority` enthalten.
- Briefing-Panel-Renderer: UI-Schichten duerfen aus Szenario, Terrain und den abgeleiteten Overlay-Snapshots einen read-only Panel-Snapshot fuer Titel, Lage, Ziele, Risiken, Team-Spawns und Loadout-Empfehlungen bauen. Der Panel-Snapshot ist Anzeigezustand und setzt `ui_sets_gameplay_truth = false`.
- Briefing-Minimap-Visuals: UI-Schichten duerfen aus `TerrainMapData` grob gesampelte Preview-Daten und aus `MissionBriefingMinimapOverlayPresenter` Marker-/Overlay-Daten zeichnen. Diese Visual-Snapshots sind bewusst verdichtete Anzeige-Samples und keine persistierte Terrain- oder Marker-Wahrheit.
- Briefing-Bild-/Loadout-Polish: UI-Schichten duerfen `background_image_path` als kleine Vorschau und `recommended_loadout` als passive Empfehlungskarten rendern. Diese Karten sind keine Loadout-Befehle und erzeugen keine `apply_loadout`-/`set_loadout`-Mutation.

## Regeln
- Briefings duplizieren keine Map-Daten wie `tiles`, `markers` oder `patrol_paths`.
- `background_image_path` muss leer oder ein vorhandener `res://`-Projektpfad sein.
- `weapon_ids` werden strikt gegen `WeaponData` normalisiert. Visuelle Loadout-IDs wie `heavy_blaster` werden nicht zu Gameplay-Waffen.
- `minimap_mode = terrain_only` bedeutet: spaetere UI darf eine aus der aktuellen Map abgeleitete Gelaendedarstellung zeigen, speichert aber kein zweites Terrain.
- Briefing-Minimap-Overlays lesen Markerpositionen aus `TerrainMapData`; Briefing-Daten duplizieren weiterhin keine Marker- oder Tile-Daten.
- Kompakte Team-Icons sind Anzeigehilfen. Vollstaendige Marker-IDs und Ownership bleiben in den bestehenden Feldern/Tooltips erhalten.
- Briefing-Panel-Renderer duerfen kompakte Textzeilen aus Objectives, Threats, Team-Spawns und Loadout-Empfehlungen erzeugen, speichern aber keine zweite Missions-, Loadout-, Team- oder Terrain-Wahrheit.
- Briefing-Minimap-Visuals duerfen aus Performancegruenden gesampelte Terrain-Farbzellen statt vollstaendiger Tile-Daten rendern. Sie duplizieren keine `tiles`, `markers` oder `patrol_paths`-Schluessel in Briefing-Daten.
- Briefing-Loadout-Empfehlungen bleiben beratend, bis ein eigener bestaetigter Loadout-Workflow-Task sie an bestehende Loadout-Contracts anschliesst.
- Annotation Painting, Bildauswahl-UI und Pre-Mission-Dialog sind Folgetasks auf diesem Datencontract.
