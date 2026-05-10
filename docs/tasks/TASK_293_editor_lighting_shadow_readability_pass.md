# TASK_293 - Editor Lighting Shadow Readability Pass

## Ziel
Die 2.5D-Editor-Beleuchtung soll die taktisch relevanten Kanten, Props, Waende und NPC-/Objekt-Anker sichtbar machen. Schatten duerfen den wichtigen Kartenbereich nicht verschlucken und sollen den 3D-Eindruck unterstuetzen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_292 - Editor Hill Cliff Grid Depth Repair
- bestehende 2.5D-Licht-/Materiallogik in `TerrainMap3DView`

## Kontext
Der aktuelle Schattenwurf wirkt unguenstig: Relevante Teile koennen in Schatten liegen, waehrend die Karte sowieso schon durch Hoehenlinien und Props schwer lesbar ist. Gewuenscht ist eine Beleuchtung, die die spielrelevante Seite betont und Schatten als Tiefenhinweis nutzt, nicht als Tarnung fuer wichtige Details.

## Umfang
1. Lichtquellen-Audit:
   - Welche DirectionalLight/Environment/Material-Overrides erzeugen Editor-Licht?
   - Welche Werte sind shared mit Mission-View und welche sind editor-only?
2. Licht-Richtung kalibrieren:
   - Varianten testen: Licht aus rechts-unten, rechts-vorne, links-oben.
   - Ziel: relevante Vorder-/Spielseite bleibt hell; Schatten fallen weg von wichtigen Tile-Kanten und UI.
   - Die finale Richtung dokumentieren und nicht im Code verstreuen.
3. Schatten:
   - Kontakt-/Schlagschatten pruefen, falls Godot/Materialpfad es sauber hergibt.
   - Schatten weich genug fuer Lesbarkeit, aber stark genug fuer 3D-Eindruck.
   - Wand- und Hangar-Seiten duerfen nicht als schwarze Flaechen kippen; Ambient-Fill und Shadow-Opacity sind Teil der zentralen Kalibrierung.
   - Keine massiven Schatten auf Tile-Property-Panel oder Overlay.
4. Debug-/Settings-Haken:
   - Editor-Sichtcheck soll Licht/Schatten bei Bedarf testweise deaktivieren koennen.
   - Keine neue Spieler-Option, solange es nur Editor-Kalibrierung ist.
5. Verifier/Manual:
   - Snapshot meldet Lichtparameter.
   - Manual-Check prueft H=2, Wand, Rock, Cactus/Bush und Cliff mit Licht.

## Nicht-Ziele
- Keine globale Grafiksettings-UI.
- Kein Realtime-Day/Night-System.
- Keine Gameplay-Sichtlinien aus Schatten.

## Akzeptanzkriterien
- [x] Lichtquelle ist zentral konfiguriert und dokumentiert.
- [x] Waende, Rocks, Cliffs, Rampen und Nature-Props bleiben im Editor erkennbar.
- [x] Schatten verbessern Tiefe, verdecken aber keine wesentlichen Kanten.
- [ ] Manueller Screenshot-Vergleich bestaetigt bessere Lesbarkeit gegen den aktuellen Problem-Screenshot.
- [x] Performance-Budget bleibt stabil.

## Erwartete Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- optional `data/editor_visual_settings.json`
- `scripts/tests/task_293_editor_lighting_shadow_readability_pass.gd`
- `docs/manual_checks/editor_lighting_shadow_readability_checklist.md`
- `docs/tasks/TASK_293_editor_lighting_shadow_readability_pass.md`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_293_editor_lighting_shadow_readability_pass.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_170_performance_warning_gate_verifier.gd`
- [ ] Manueller Editor-Sichtcheck mit mindestens zwei Kamerawinkeln.
- [ ] `git diff --check`

## Risiken
- Zu starke Schatten lassen kleine Props verschwinden.
- Zu flaches Licht macht Hoehen wieder unlesbar.
- Editor-Licht darf Mission-Licht nicht ungewollt veraendern.

## Naechster Schritt
TASK_294 kalibriert Nature-Props, damit Cactus/Bush/Tree/Rock nach dem Lichtpass sichtbar und taktisch lesbar bleiben.
