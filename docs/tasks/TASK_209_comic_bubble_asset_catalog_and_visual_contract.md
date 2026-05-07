# TASK_209 - Comic Bubble Asset Catalog and Visual Contract

## Ziel
Die Comic-Sprechblasen unter `res://Assets/Comic/` sollen als kleiner, stabiler Bubble-Katalog verfuegbar werden. Sie dienen fuer Fireteamleader-Rueckmeldungen und NPC-Gedanken, bleiben aber reine Anzeige.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_160 - Tactical Mission Playability Smoke
- TASK_164 - UI Theme and Component Library
- TASK_197 - Curated Asset Catalog and Usage Mapping

## Kontext
Im Projekt liegen bereits `comic-1.png` bis `comic-10.png` sowie `preview.png`. Bevor Gameplay- oder UI-Pfade sie nutzen, braucht es einen Vertrag: Welche Bubble-ID meint welche Form, wie gross darf sie sein, wo wird Text gesetzt, wie verhaelt sie sich auf der 2.5D-Mission-Map und wie wird verhindert, dass die Karte voller Text steht?

## Quellen
- `res://Assets/Comic/comic-1.png`
- `res://Assets/Comic/comic-2.png`
- `res://Assets/Comic/comic-3.png`
- `res://Assets/Comic/comic-4.png`
- `res://Assets/Comic/comic-5.png`
- `res://Assets/Comic/comic-6.png`
- `res://Assets/Comic/comic-7.png`
- `res://Assets/Comic/comic-8.png`
- `res://Assets/Comic/comic-9.png`
- `res://Assets/Comic/comic-10.png`
- `res://Assets/Comic/preview.png`

## Umfang
1. Bubble-Katalog:
   - Stabile IDs fuer die zehn Bubble-Varianten definieren.
   - Zweck markieren: FTL-Antwort, NPC-Gedanke, Warnung, leise Meldung, kurzer Befehl.
   - `preview.png` nur als Inventar-/Doku-Preview nutzen, nicht als Runtime-Bubble.
2. Visual-Vertrag:
   - Maximalgroesse in Screen- oder Canvas-Pixeln festlegen.
   - Text-Inset, Tail-/Anchor-Position und z-Order dokumentieren.
   - Bubbles duerfen Units, wichtige Marker und HUD-Fenster nicht dauerhaft verdecken.
3. Text-Vertrag:
   - Kurze Zeilen, maximal 1 bis 2 Zeilen pro Bubble.
   - Lange Saetze werden gekuerzt oder auf Statuspanel ausgelagert.
   - Keine Tutorialtexte in die Mission Map schreiben.
4. Laufzeitgrenze:
   - Bubble-Assets sind Anzeige.
   - Kein Bubble-Pfad erzeugt `SimulationRoot`-Commands oder Effects.
   - Kein lokaler absoluter Pfad in Daten, Tests oder Runtime.
5. Verifier:
   - Alle PNGs sind loadbar.
   - Alle Katalog-IDs zeigen auf `res://Assets/Comic/...`.
   - Keine Bubble-Definition ueberschreitet die Maximalgroesse.

## Nicht-Ziele
- Keine Fireteamleader-Dialoglogik.
- Keine NPC-Gedankenlogik.
- Keine Settings/Toggles.
- Kein neues Dialogsystem.
- Kein Asset-Redesign.

## Akzeptanzkriterien
- [x] Ein Bubble-Katalog listet `comic-1.png` bis `comic-10.png` mit stabilen IDs.
- [x] `preview.png` ist dokumentiert, aber nicht als Runtime-Bubble erforderlich.
- [x] Text-Inset, Anchor, Maximalgroesse und z-Order sind definiert.
- [x] Alle Bubble-Pfade sind `res://`-Projektpfade.
- [x] Bubble-Assets erzeugen keine Gameplay-Commands oder Effects.
- [x] Ein TASK_209-Verifier prueft Loadbarkeit, Katalog und Groessengrenzen.

## Umsetzung
- `data/comic_bubble_asset_catalog.json` definiert zehn Runtime-Bubbles mit stabilen IDs, Purpose, Anchor, Tail-Offset, Text-Inset, Maximalgroesse und z-Order; `preview.png` bleibt Doku-Preview.
- `scripts/ui/comic_bubble_visual_contract.gd` laedt und validiert den Katalog, liefert Runtime-IDs, baut reine Display-Payloads und kuerzt Text auf den vereinbarten 1-2-Zeilen-Vertrag.
- `docs/assets/comic_bubble_inventory.md` dokumentiert Quelle, Purpose-IDs, Runtime-IDs, Textregeln und Folgepfad.
- `scripts/tests/task_209_comic_bubble_asset_catalog_and_visual_contract.gd` prueft Loadbarkeit, Katalogstabilitaet, Groessengrenzen, Preview-Regel, Display-only-Payloads und lokale Pfadgrenze.

## Erwartete Dateien
- `data/comic_bubble_asset_catalog.json`
- `docs/assets/comic_bubble_inventory.md`
- `scripts/ui/comic_bubble_visual_contract.gd`
- `scripts/tests/task_209_comic_bubble_asset_catalog_and_visual_contract.gd`
- `docs/tasks/TASK_209_comic_bubble_asset_catalog_and_visual_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_209_comic_bubble_asset_catalog_and_visual_contract.gd`
- [x] `git diff --check`

## Risiken
- Bubbles koennen die Mission Map schnell unruhig machen. Der Vertrag muss klein und streng bleiben.
- Wenn Text nicht begrenzt wird, werden die Grafiken gedehnt oder ueberdecken Einheiten.

## Naechster Schritt
Nach TASK_209 kann TASK_210 Fireteamleader-Rueckmeldungen auf den Katalog setzen.
