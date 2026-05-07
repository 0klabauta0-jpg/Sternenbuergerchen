# TASK_242 - Audio SFX Source Inventory and Curated Import

## Ziel
Die lokale Kenney-Audioquelle soll inventarisiert und als kleines, nutzbares SFX-Subset ins Projekt uebernommen werden. Wichtig sind Schuesse, Schritte/Laufen, Explosionen, Impacts, kurze Sci-Fi-Effekte und Button-Klicks.

Nur Sounds, die wirklich geplant genutzt werden, werden in den Projektordner kopiert. Runtime, Szenen und Daten duerfen keine lokalen User-Pfade referenzieren.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_193 - Asset Source Inventory and Availability Matrix
- TASK_195 - UI Input Cursor Asset Integration Pass
- TASK_205 - Muzzle Flash Particle Effects
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- lokale Quelle `%USERPROFILE%\Pictures\Kenney Game Assets All-in-1 3.4.0\Audio`

## Quellenliste
- `Casino Audio`
- `Digital Audio`
- `Foley Sounds`
- `Impact Sounds`
- `Interface Sounds`
- `Music Jingles`
- `Music Loops`
- `Retro Sounds 1`
- `Retro Sounds 2`
- `RPG Audio`
- `Sci-Fi Sounds`
- `Synth Voice 1`
- `Synth Voice 2`
- `UI Audio`
- `Voiceover Pack`
- `Voiceover Pack Fighter`

## Kontext
Im Projekt liegen bereits wenige UI-Sounds unter `Assets/kenney_ui-pack/Sounds/`. Fuer Kampf, Bewegung, Explosionen und weitere UI-Rueckmeldungen fehlt aber ein kuratierter Projektbestand. Der neue Bestand soll nicht als Pack-Massenimport entstehen, sondern als kleines Audio-Set mit klarer Herkunft, Zweck, Lautstaerke und Verbrauchsort.

## Umfang
1. Quelle inventarisieren:
   - Ordner, Dateitypen, grobe Mengen und Lizenzdateien erfassen.
   - Kandidaten fuer UI, Combat, Movement, Impact, Explosion und kurze Sci-Fi-Effekte markieren.
   - Bestehende Projekt-UI-Sounds gegen die neue Quelle abgleichen.
2. Kuratiertes Subset waehlen:
   - UI: click, hover, confirm, cancel, switch, warning.
   - Combat: blaster/laser, rifle, smg, sniper, heavy/rocket, impact.
   - Movement: walk/run fuer metal, sand/rock und neutralen Boden.
   - Explosion/Impact: kleine Explosion, grosse Explosion, Treffer, Debris.
   - Optional nur kurze Voice-/Funk-Pips, keine langen Voiceover-Pakete.
3. Projektimport:
   - Zielpfad `Assets/used/audio/kenney_all_in_one/`.
   - Kategorie-Unterordner fuer `ui`, `combat`, `movement`, `impact`, `explosion`, `ambient_short`.
   - Nur `.ogg`/Godot-kompatible Dateien kopieren.
   - Lizenz-/Quellhinweis mitkopieren oder dokumentieren.
4. Audio-Katalog erstellen:
   - Stabile `audio_id`.
   - Quelle, Projektpfad, Kategorie, geplanter Event, Dauer, Loop-Flag, Standardlautstaerke.
   - Hinweise auf Varianten und Pitch-/Volume-Randomisierung.
5. Importregeln festlegen:
   - Kurze One-Shots als Sample, laengere Ambiences/Musik als Stream.
   - Keine riesigen Loops fuer diesen Task.
   - Keine absoluten User-Pfade ausser in reiner Quellen-Doku.

## Nicht-Ziele
- Keine finale Soundmischung.
- Keine Musik-Auswahl.
- Keine Sprachausgabe fuer NPCs.
- Kein Combat-/UI-Code-Hook; das kommt in TASK_243 und TASK_244.
- Kein Komplettimport der All-in-1-Audioquelle.

## Akzeptanzkriterien
- [x] `docs/assets/audio_sfx_inventory.md` listet Quelle, Lizenzlage, Kandidaten und Importentscheidung.
- [x] `data/audio_sfx_catalog.json` enthaelt stabile Audio-IDs fuer das kuratierte Subset.
- [x] Alle genutzten Sounds liegen unter `Assets/used/audio/kenney_all_in_one/` oder sind bewusst als bestehende Projektkopie referenziert.
- [x] Keine Runtime-Datei braucht `%USERPROFILE%`, `C:\Users`, `file://` oder externe lokale Pfade.
- [x] Mindestens UI-Klicks, Schuesse, Schritte, Explosionen und Impacts sind abgedeckt.
- [x] Ein Verifier prueft Katalog, Projektpfade, Dateiexistenz und fehlende lokale Runtime-Pfade.

## Umsetzung
- Die lokale Kenney-All-in-1-Audioquelle wurde als Inventar mit Pack-Mengen, Lizenzlage und Importentscheidungen dokumentiert.
- 29 kurze, kuratierte SFX wurden nach `Assets/used/audio/kenney_all_in_one/` kopiert: UI, Combat, Movement, Impact, Explosion und kurze Sci-Fi-Ambiences.
- Die genutzten Pack-Lizenzen liegen projektlokal unter `Assets/used/audio/kenney_all_in_one/licenses/`.
- `data/audio_sfx_catalog.json` definiert stabile Audio-IDs, geplante Events, Varianten, Lautstaerke, Pitch-Randomisierung, Loop-Flags und Importhinweise.
- `scripts/tests/task_242_audio_sfx_inventory_import_verifier.gd` prueft Katalogstruktur, Eventabdeckung, Projektpfade, Godot-Importe, Dateiexistenz, Lizenzdateien und lokale Pfad-Leaks.

## Erwartete Dateien
- `docs/assets/audio_sfx_inventory.md`
- `data/audio_sfx_catalog.json`
- `Assets/used/audio/kenney_all_in_one/...`
- `scripts/tests/task_242_audio_sfx_inventory_import_verifier.gd`
- `docs/tasks/TASK_242_audio_sfx_source_inventory_and_curated_import.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_242_audio_sfx_inventory_import_verifier.gd`
- [x] `git diff --check`

## Risiken
- Zu viele Sounds blaehen Importzeit, Projektgroesse und spaetere Misch-Entscheidungen auf.
- Zu wenige Varianten lassen Schuesse und Schritte schnell repetitiv wirken.
- Lokale User-Pfade duerfen nicht unbemerkt in Runtime-Daten landen.

## Naechster Schritt
TASK_243 baut den Audio-Event-Vertrag und die Godot-Bus-/Player-Schicht.
