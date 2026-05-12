# TASK_338 - Portrait Asset Intake Catalog Sync

## Ziel
Neu hinzugefuegte Portraits unter `Assets/Char` muessen vollstaendig ins Projekt uebernommen, importiert, inventarisiert und fuer Roster-/Team-UI sichtbar gemacht werden. Der Portrait-Katalog darf nicht hinter dem echten Asset-Stand zurueckfallen.

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Voraussetzung
- TASK_233 - Portrait Identity Catalog and Roster Presentation
- TASK_247 - Used Asset Project Locality Audit Gate
- Aktueller Portrait-Asset-Stand unter `Assets/Char`

## Kontext
Die erneute Code-Review hat eine Drift im Portrait-Pfad gefunden: Der Katalog und das Inventar melden weiter 87 PNG-Quellen, waehrend im Projekt mehr Portrait-PNGs liegen. Zusaetzlich koennen neue Godot-Importdateien ungetrackt bleiben. Dadurch brechen Katalog-Gates und neue Portraits tauchen nicht automatisch im Team-Editor oder Start-Roster auf.

## Umfang
1. Asset Intake:
   - Alle neuen `Assets/Char/*.png` und zugehoerigen `*.png.import`-Dateien erfassen.
   - Godot-Import ausfuehren, falls Importmetadaten fehlen.
   - Keine absoluten lokalen Pfade oder externen Quellen referenzieren.
2. Inventar-Sync:
   - Tatsaechliche PNG-Anzahl, Aufloesungen, Dateigroessen und grobe Diagnosen neu scannen.
   - `docs/assets/portrait_identity_inventory.md` mit dem echten Stand synchronisieren.
3. Katalog-Sync:
   - `data/portrait_identity_catalog.json` `source_inventory` aktualisieren.
   - Verwertbare neue Portraits als stabile IDs mit `res://Assets/Char/...`-Pfaden aufnehmen.
   - Tags, Kandidatenstatus und Diagnosen nachvollziehbar setzen.
4. UI-/Generator-Anbindung:
   - Sicherstellen, dass Team-Editor, Start-Roster und Character-Sheet nur ueber den Katalog gehen.
   - Grosse Quellen duerfen kompakte Karten nicht sprengen.
5. Regression:
   - TASK_233 und Asset-Locality-Gate muessen den neuen Stand akzeptieren.

## Nicht-Ziele
- Keine Bildbearbeitung oder KI-Neugenerierung.
- Kein Art-Style-Finalpass.
- Kein neues Portrait-Crop-System, ausser ein kleiner Fix ist zwingend fuer den Katalog-Gate.
- Keine Gameplay- oder Skill-Wirkung aus Portrait-Tags.

## Akzeptanzkriterien
- [x] Keine ungetrackten neuen Portrait-PNGs oder zugehoerigen `.png.import`-Dateien bleiben offen.
- [x] `scanned_png_count` und Inventar-Doku stimmen mit dem echten `Assets/Char/*.png`-Stand ueberein.
- [x] Neue verwertbare Portraits haben stabile Katalog-IDs und `res://`-Pfade.
- [x] Team-Editor/Start-Roster koennen neue Portrait-Kandidaten ueber den bestehenden Katalogpfad erreichen.
- [x] Der Katalog-Gate erkennt Drift kuenftig klar statt still weiterzulaufen.

## Erwartete Dateien
- `Assets/Char/*.png`
- `Assets/Char/*.png.import`
- `data/portrait_identity_catalog.json`
- `docs/assets/portrait_identity_inventory.md`
- `maps/new_map.json`
- `scripts/tests/task_338_portrait_asset_intake_catalog_sync.gd`
- `docs/tasks/TASK_338_portrait_asset_intake_catalog_sync.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_338_portrait_asset_intake_catalog_sync.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_233_portrait_identity_catalog_and_roster_presentation.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_247_used_asset_project_locality_audit_gate.gd`
- [x] `git diff --check`

## Ergebnis
- `Assets/Char` ist auf 118 PNGs und 118 `.png.import`-Dateien synchronisiert.
- Der Portrait-Katalog fuehrt jetzt 61 Start-Roster-Kandidaten. Die neuen May-12/12.-Mai-Portraits liegen stabil als `char_portrait_031` bis `char_portrait_061` im Katalog.
- Inventar und Katalog melden denselben echten PNG-Stand; der neue TASK_338-Verifier prueft zusaetzlich Import-Sidecars und die vollstaendige Katalogaufnahme der neuen Portrait-Batch.
- Der Asset-Locality-Gate hatte eine bestehende produktive Referenz auf `res://maps/new_map.json` gefunden; der Task legt dafuer einen kleinen projektlokalen Default-Map-Placeholder an, statt die Gate-Regel zu schwaechen.

## Risiken
- Neue Portraits koennen unterschiedliche Ausschnitte, Dateigroessen oder Stilrichtungen haben. Dieser Task synchronisiert den Katalog; finale visuelle Kuratierung bleibt ein eigener kleiner Art-/Crop-Task.

## Naechster Schritt
Nach dem Sync kann ein kurzer manueller Team-Editor-/Roster-Sichtcheck pruefen, ob die neuen Portraits optisch in den kompakten Karten funktionieren.
