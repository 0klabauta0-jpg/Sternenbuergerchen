# TASK_484 - Map Editor Palette Browser Layout

## Ziel / Problem
Die Map-Editor-Palette zeigt zwar mehr Assets, aber die Vorschauen sind im echten Editorfenster weiterhin zu klein und die Kategorien verbrauchen zu viel vertikalen Platz. Dadurch sieht man im Asset-Bereich nur wenige Eintraege und kann die Assets kaum unterscheiden.

## Sinnhaftigkeit / Ursache
TASK_483 hat die technische Basis fuer groessere Previews gelegt. Im realen Layout druecken aber die langen Kategorie-Buttons die Asset-Liste nach unten. Die Kategorie-Auswahl muss kompakter und scrollbar werden, waehrend die Asset-Liste den Hauptplatz bekommt.

## Umfang
- Palette-Panel weiter verbreitern.
- Asset-Previews in der Liste sichtbar groesser machen.
- Asset-Liste als zweispaltigen Icon-Browser statt schmaler Textliste darstellen.
- Kategorien in einen eigenen kompakten Scrollbereich verschieben.
- Snapshot-Felder fuer Panelbreite, Previewgroesse, Kategorie-Scrollbereich und Asset-Browser-Layout ergaenzen.

## Nicht-Ziele
- Keine neue Suche/Favoriten-Verwaltung.
- Keine Aenderung an Asset-Wahrheit, Save/Load oder Gameplay-State.
- Kein Floor-/Asset-Hoehenfix; das bleibt ein separater Follow-up.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/map_editor_asset_workflow_contract.md`

## Akzeptanzkriterien
- Palette-Snapshot meldet Preview-Icons mit mindestens 64 px Kantenlaenge.
- Asset-Liste nutzt mindestens zwei Spalten mit Top-Icons.
- Kategorie-Auswahl ist als eigener Scrollbereich vorhanden.
- Kategorie-Buttons bleiben kompakt und nehmen nicht den Hauptbereich weg.
- Sichtbare Asset-Liste hat eine deutlich groessere Mindesthoehe.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `scripts/tests/task_484_map_editor_palette_browser_layout.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_484_map_editor_palette_browser_layout.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_483_map_editor_asset_workflow_polish.gd`
- relevante Map-Editor-Palette-Regressionen
- `git diff --check`

## Risiken / offene Punkte
- Bei sehr kleinen Fenstern muss die Palette weiterhin gegen den Viewport geprueft werden.
- Suche, Favoriten und echte Unterkategorien bleiben der naechste UX-Schritt.
