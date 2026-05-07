# TASK_196 - Rank and Particle Asset Subset Import

## Ziel
Rank-/Role-Badges und Particle-Visuals sollen als kleine kuratierte Subsets ins Projekt uebertragen und verfuegbar gemacht werden.

Ranks dienen UI-/Status-Lesbarkeit. Particles dienen reinen Effekten fuer LZ, Kontakt, Suppression, Objective und Trefferfeedback. Beides darf keine Gameplay-Wahrheit werden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_164 - UI Theme and Component Library
- TASK_171 bis TASK_176 - NPC-Visuals und Loadout-Attachments
- TASK_188 - Fireteam Advance Styles Map Readability
- TASK_193 - Asset Source Inventory and Availability Matrix

## Quellen
- `C:\Users\bjoer\Pictures\Sternenbürger\kenney_ranks-pack`
- `C:\Users\bjoer\Pictures\Sternenbürger\kenney_particle-pack`

## Zielpfade
- `Assets/curated/kenney/ranks/`
- `Assets/curated/kenney/particles/`
- `docs/assets/rank_particle_inventory.md`

## Umfang
1. Rank-/Role-Badges:
   - Maximal 16 PNG.
   - FTL, Medic, Rifle/Assault, Heavy/Special, Pilot, Engineer, Enemy, Down, Ready, Suppressed.
   - Kleine und grosse Varianten nur, wenn wirklich gebraucht.
2. Particle-Subset:
   - Maximal 16 PNG.
   - LZ/Drop, Contact, Suppression, Objective, Hit, Heal, Warning.
   - Reine Visuals, keine Damage- oder Heal-Wahrheit.
3. Manifest:
   - Quelle, Lizenz, Projektpfad, Zweck, Zielscreen.
   - Eindeutige IDs fuer spaetere Nutzung.
4. UI-/Mission-Verfuegbarkeit:
   - Badges koennen in NPC-Karten, #17 Selected Fireteam, Mission-Map-Snapshots und Statuszeilen genutzt werden.
   - Particles koennen von Visualizern oder Effekt-Layern referenziert werden, ohne SimulationRoot-Effects zu ersetzen.
5. Verifier:
   - Maximalmengen.
   - `res://`-Pfadgueltigkeit.
   - PNGs loadbar.
   - Keine lokalen Quellpfade.

## Nicht-Ziele
- Keine neuen Gameplay-Status.
- Keine neuen Damage-/Heal-Effects.
- Kein Partikelsystem-Rewrite.
- Kein vollstaendiger Import aller Rank-/Particle-Dateien.

## Akzeptanzkriterien
- [x] Rank-/Role-Badge-Subset ist importiert und dokumentiert.
- [x] Particle-Subset ist importiert und dokumentiert.
- [x] Badges und Particles haben stabile IDs.
- [x] Alle Assets liegen unter `Assets/curated/kenney/...`.
- [x] Keine Runtime-Datei nutzt lokale absolute Pfade.
- [x] Ein TASK_196-Verifier prueft Manifest, Loadbarkeit und Maximalmengen.

## Erwartete Dateien
- `Assets/curated/kenney/ranks/`
- `Assets/curated/kenney/particles/`
- `docs/assets/rank_particle_inventory.md`
- optional `data/rank_particle_asset_catalog.json`
- `scripts/tests/task_196_rank_particle_asset_subset_import_verifier.gd`
- `docs/tasks/TASK_196_rank_particle_asset_subset_import.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_196_rank_particle_asset_subset_import_verifier.gd`
- [x] `git diff --check`

## Umsetzung
- `Assets/curated/kenney/ranks/` enthaelt ein kuratiertes 10-PNG-Subset fuer FTL, Medic, Rifle/Assault, Heavy/Special, Pilot, Engineer, Enemy, Down, Ready und Suppressed.
- `Assets/curated/kenney/particles/` enthaelt ein kuratiertes 12-PNG-Subset fuer LZ/Drop, Contact, Suppression, Objective, Hit, Heal, Warning, Trace, Impact, Movement/Dust, Scorch und Command-Ping.
- `data/rank_particle_asset_catalog.json` definiert stabile IDs, `res://`-Pfade, Quell-Relativpfade, Zielscreen und Visual-only-Regeln.
- `docs/assets/rank_particle_inventory.md` dokumentiert Quelle, Lizenz, Mengenlimit, Verbrauchsorte und die klare Grenze zu Gameplay-State.
- `scripts/tests/task_196_rank_particle_asset_subset_import_verifier.gd` prueft Maximalmengen, Lizenz/README, Manifest, Pflicht-IDs, Kategorien, Texture2D-Loadbarkeit, PNG-only-Regel und lokale-Pfad-Freiheit.

## Risiken
- Particles duerfen nicht heimlich Combat- oder Heal-Effects ersetzen. Sie sind Anzeige.
- Zu viele Badges machen NPC-Karten unruhig; Ziel ist kleine Rollen-/Status-Lesbarkeit.

## Naechster Schritt
Nach TASK_196 kann TASK_197 Ranks, Particles, UI und Setpieces in einem zentralen Asset-Katalog zusammenfuehren.
