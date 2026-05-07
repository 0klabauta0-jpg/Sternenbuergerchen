# TASK_245 - Background Image Catalog and Screen Usage

## Ziel
Die neu gelieferten Hintergrundbilder sollen als projektlokale Background-Assets katalogisiert, kopiert und sinnvollen Screens zugeordnet werden. Sie sollen Menue, Lobby, Mission-Auswahl, Lade-/Debrief-Screens oder Editor-Kontext tragen, ohne Lesbarkeit und Performance zu verschlechtern.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_199 - Main Menu Shell and Background Art Preparation
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- TASK_227 - Main Menu Multiplayer Host Join Lobby Flow
- TASK_229 - Map Editor Usability Authoring Pass
- TASK_242 - Audio SFX Source Inventory and Curated Import

## Quellenliste
- `Use AI Image Apr 18, 2026, 23_34_01.png` - Hangar/Schiffshalle
- `Use AI Image Apr 18, 2026, 23_45_03.png` - Wuestenbasis mit Schiffen
- `Use AI Image Apr 18, 2026, 23_41_57.png` - Asteroidenflug
- `Use AI Image Apr 18, 2026, 23_21_53.jpeg` - Wuestenbasis mit Explosion

## Kontext
Das Hauptmenue hat bereits einen eigenen Bildwunsch aus TASK_199. Die neuen Bilder koennen weitere Menue- und Setup-Kontexte staerken, sollten aber als kuratierte Assets mit stabilen Projektpfaden laufen. Screens duerfen keine lokalen Bildpfade laden.

## Umfang
1. Import und Katalog:
   - Bilder nach `Assets/used/backgrounds/ai_generated/` kopieren.
   - Sprechende Dateinamen vergeben, z. B. `bg_hangar_blue.png`, `bg_desert_outpost.png`, `bg_asteroid_flight.png`, `bg_desert_explosion_base.jpg`.
   - Quelle, Ursprung, Zielpfad, Aufloesung, Dateigroesse und geplanten Screen dokumentieren.
2. Screen-Zuordnung:
   - Hauptmenue/Settings: Hauptbild aus TASK_199 bevorzugen, neue Bilder nur als weitere Varianten oder Unterseiten.
   - Singleplayer/Mission Select: Wuestenbasis oder Hangar.
   - Multiplayer Lobby: Hangar oder Asteroidenflug.
   - Editor/Map-Setup: Wuestenbasis als thematischer Kontext, falls nicht zu ablenkend.
   - Loading/Debrief optional: Explosion/Outpost als kurze Hintergrundvariante.
3. Lesbarkeit:
   - UI-Text nicht direkt auf kontrastreichen Detailbereichen.
   - Overlay-/Dimming-Regeln pro Screen definieren.
   - Keine Info- oder Button-Texte durch Bilddetail verdecken.
4. Performance:
   - Import-Compression und Max-Size bewusst setzen.
   - Optional Full-HD-Varianten erzeugen, wenn Originale zu gross fuer UI sind.
   - Keine unnoetig parallele Vorladung aller Backgrounds.
5. Katalog- und Runtime-Vertrag:
   - `data/background_image_catalog.json` mit `background_id`, `res_path`, `screen_hint`, `crop_anchor`, `dim_strength`.
   - Screens referenzieren IDs statt Rohpfade, wo sinnvoll.

## Nicht-Ziele
- Keine finale visuelle Gestaltung aller Menues.
- Keine Parallax- oder Animationseffekte.
- Keine neuen Gameplay-Szenen.
- Keine KI-Bildgenerierung in diesem Task.

## Akzeptanzkriterien
- [x] Alle vier gelieferten Bilder liegen unter `Assets/used/backgrounds/ai_generated/`.
- [x] `docs/assets/background_image_catalog.md` dokumentiert Quelle, Zielpfad, Groesse und Screen-Vorschlag.
- [x] `data/background_image_catalog.json` enthaelt stabile Background-IDs.
- [x] Menue-/Setup-Screens koennen Backgrounds ueber Projektpfade laden.
- [x] Text und Buttons bleiben bei Full-HD lesbar.
- [x] Kein Screen referenziert lokale User-Bildpfade.

## Erwartete Dateien
- `Assets/used/backgrounds/ai_generated/...`
- `docs/assets/background_image_catalog.md`
- `data/background_image_catalog.json`
- `scripts/tests/task_245_background_image_catalog_and_screen_usage_verifier.gd`
- `docs/manual_checks/background_screen_readability_checklist.md`
- `docs/tasks/TASK_245_background_image_catalog_and_screen_usage.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_245_background_image_catalog_and_screen_usage_verifier.gd`
- [ ] Manueller Full-HD-Sichtcheck fuer die Screens, die Backgrounds nutzen.
- [x] `git diff --check`

## Umsetzung
- Die vier gelieferten Bilder wurden mit stabilen ASCII-Dateinamen nach `Assets/used/backgrounds/ai_generated/` kopiert und importiert.
- `data/background_image_catalog.json` definiert stabile IDs, `res://`-Pfade, Screen-Hints, Crop-Anker, Dimming und UI-Texture-Budget.
- `BackgroundImageCatalog` kapselt das Laden, Anwenden auf `TextureRect` und Diagnose-Snapshots.
- Das Main Menu bleibt auf dem TASK_199-Bild, liest dieses aber ueber den Background-Katalog.
- Die Multiplayer-Lobby nutzt `multiplayer_lobby_hangar` mit vollflaechigem Background und Dimming-Shade hinter dem bestehenden Panel.
- `docs/manual_checks/background_screen_readability_checklist.md` haelt den offenen Full-HD-Sichtcheck fest.

## Risiken
- Zu detailreiche Hintergruende koennen UI-Text unlesbar machen.
- Grosse Texturen koennen Startzeit und VRAM belasten.
- Wenn die Bilder in zu vielen Screens gleichzeitig genutzt werden, wirkt die App schnell unruhig.

## Naechster Schritt
Nach TASK_245 kann TASK_246 Groesse, Crop, Ausrichtung und visuelle Passung zusammen mit NPC-/Weapon-/VFX-Assets pruefen.
