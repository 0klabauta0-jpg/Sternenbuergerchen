# TASK_193 - Asset Source Inventory and Availability Matrix

## Ziel
Die neu benannten lokalen Asset-Quellen werden als verbindliche Quellenliste inventarisiert. Der Task klaert, welche Packs bereits im Projekt vorhanden sind, welche kuratiert importiert werden sollen und welche nur als lokale Quelle fuer spaetere Tasks dienen.

Das Ergebnis ist eine Availability-Matrix: Quelle, Lizenz, vorhandene Projektkopie, Zielpfad, erlaubter Verbrauchsort und naechster Import-Task.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_165 - Local Asset Curation and Import Plan
- bestehende Projekt-Assets unter `Assets/`
- User-Quellenliste aus dem Asset-Auftrag

## Quellenliste
- `C:\Users\bjoer\Pictures\Sternenbürger\Modular Space Kit`
- `C:\Users\bjoer\Pictures\Sternenbürger\Space Station Kit`
- `C:\Users\bjoer\Pictures\Sternenbürger\kenney_ui-pack-space-expansion`
- `C:\Users\bjoer\Pictures\Sternenbürger\kenney_ui-pack`
- `C:\Users\bjoer\Pictures\Sternenbürger\kenney_space-kit`
- `C:\Users\bjoer\Pictures\Sternenbürger\kenney_ranks-pack`
- `C:\Users\bjoer\Pictures\Sternenbürger\kenney_particle-pack`
- `C:\Users\bjoer\Pictures\Sternenbürger\kenney_input-prompts_1.4.1\Keyboard & Mouse`
- `C:\Users\bjoer\Pictures\Sternenbürger\kenney_cursor-pixel-pack`

## Kontext
Ein Teil der genannten Packs existiert bereits im Projekt:

- `Assets/kenney_space-kit`
- `Assets/kenney_ui-pack`
- `Assets/kenney_ui-pack-space-expansion`
- `Assets/kenney_input-prompts_1.4.1`
- `Assets/kenney_cursor-pixel-pack`

Diese Packs sollen nicht blind doppelt kopiert werden. Der Task entscheidet je Quelle: bestehende Projektkopie freischalten, fehlende Subsets kuratiert importieren oder nur als lokale Reserve dokumentieren.

## Umfang
1. Quellen pruefen:
   - Existenz der lokalen Ordner.
   - Dateitypen und Groessen grob zaehlen.
   - Lizenzdateien finden und dokumentieren.
   - GLB/PNG/SVG-Prioritaeten festhalten.
2. Projektbestand abgleichen:
   - Vorhandene `Assets/...`-Kopien gegen lokale Quellen pruefen.
   - Doppelte Kopien vermeiden.
   - Fehlende Subsets fuer TASK_194 bis TASK_196 markieren.
3. Availability-Matrix erstellen:
   - `docs/assets/asset_source_availability_matrix.md`
   - Spalten: Quelle, Projektpfad, Lizenz, Dateitypen, Importstatus, Maximalmenge, geplanter Verbrauchsort.
4. Importregeln nachziehen:
   - GLB vor FBX/OBJ/DAE/STL.
   - PNG fuer Godot-UI bevorzugen, SVG nur bei klarer Skalierungsanforderung.
   - Keine absoluten Benutzerpfade in Runtime, Mapping, Tests oder UI.
   - Jede importierte Datei braucht Quelle/Lizenz/Zweck im Manifest.
5. Folgeaufgaben referenzieren:
   - TASK_194 fuer Modular/Space Station/Space-Kit-Setpieces.
   - TASK_195 fuer UI/Input/Cursor.
   - TASK_196 fuer Ranks und Particles.
   - TASK_197 fuer zentralen Asset-Katalog.

## Nicht-Ziele
- Kein binaerer Asset-Import in diesem Task.
- Kein Massencopy ganzer Packs.
- Keine Runtime-Renderer-Umbauten.
- Keine UI-Neugestaltung.

## Akzeptanzkriterien
- [x] Alle neun lokalen Quellen sind in `docs/assets/asset_source_availability_matrix.md` aufgefuehrt.
- [x] Bereits vorhandene Projektkopien sind als `reuse existing` markiert.
- [x] Fehlende oder neue Subsets sind einem Folge-Task zugeordnet.
- [x] Lizenz-/Quellenlage ist pro Pack dokumentiert oder als offen markiert.
- [x] Keine Runtime-Datei referenziert absolute lokale Benutzerpfade.
- [x] Ein TASK_193-Verifier prueft, dass die Matrix alle Pflichtquellen und Pflichtspalten enthaelt.

## Erwartete Dateien
- `docs/assets/asset_source_availability_matrix.md`
- `scripts/tests/task_193_asset_source_inventory_availability_verifier.gd`
- `docs/tasks/TASK_193_asset_source_inventory_and_availability_matrix.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_193_asset_source_inventory_availability_verifier.gd`
- [x] `git diff --check`

## Umsetzung
- `docs/assets/asset_source_availability_matrix.md` listet alle neun Pflichtquellen mit Source-ID, lokaler Quelle, Projektpfad, CC0-Lizenzlage, Dateitypen/Groesse, Importstatus, Maximalmenge, Verbrauchsort und Folge-Task.
- Vorhandene Projektkopien sind als `reuse existing project copy` markiert: UI-Pack, Sci-Fi-UI-Pack, Space-Kit, Keyboard-&-Mouse-Input-Prompts und Cursor-Pixel-Pack.
- Fehlende Subsets sind nur Folgeaufgaben zugeordnet: Modular/Space Station zu TASK_194, Ranks/Particles zu TASK_196, zentraler Katalog zu TASK_197.
- Alte absolute `C:/Users/...`-Quellhinweise in Runtime-Mapping-Daten wurden auf `%USERPROFILE%/...` normalisiert; Test-Suchmuster bauen absolute Pfade dynamisch, damit Tests selbst keine lokalen Benutzerpfade enthalten.
- Es wurden keine neuen binaeren Assets importiert.

## Risiken
- Wenn vorhandene Projektkopien erneut importiert werden, entstehen doppelte Assets, laengere Importzeiten und unklare Quellen.
- Wenn Lizenz-/Quellinfos fehlen, duerfen die Assets noch nicht als Runtime-Abhaengigkeit verwendet werden.

## Naechster Schritt
Nach TASK_193 koennen die konkreten Import- und Verfuegbarkeits-Slices TASK_194 bis TASK_197 starten.
