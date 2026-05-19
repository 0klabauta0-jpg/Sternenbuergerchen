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

## Regeln
- Briefings duplizieren keine Map-Daten wie `tiles`, `markers` oder `patrol_paths`.
- `background_image_path` muss leer oder ein vorhandener `res://`-Projektpfad sein.
- `weapon_ids` werden strikt gegen `WeaponData` normalisiert. Visuelle Loadout-IDs wie `heavy_blaster` werden nicht zu Gameplay-Waffen.
- `minimap_mode = terrain_only` bedeutet: spaetere UI darf eine aus der aktuellen Map abgeleitete Gelaendedarstellung zeigen, speichert aber kein zweites Terrain.
- Annotation Painting, Bildauswahl-UI und Pre-Mission-Dialog sind Folgetasks auf diesem Datencontract.
