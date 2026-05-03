# TASK_165 - Local Asset Curation and Import Plan

## Ziel
Die lokalen Assets aus `C:\Users\bjoer\Pictures\Sternenbürger` werden kuratiert, dedupliziert und in einen kleinen Importplan ueberfuehrt. Nur konkret benoetigte Assets sollen ins Projekt wandern.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/reviews/strategic_review_ui_assets_multiplayer_2026_05_03.md`
- Pruefe den Git-Status

## Kontext
- Lokaler Bestand: ueber 8000 PNG, 2100 SVG, 900+ GLB und viele FBX/OBJ/DAE/STL.
- Projekt nutzt bereits Kenney-Space-Kit und kalibrierte GLB-Mappings.
- Ohne Kuratierung droht Asset-Sprawl, lange Importzeiten und unklare Lizenz-/Quellenlage.

## Umfang
1. Asset-Katalog als Markdown oder JSON unter `docs/assets/` erstellen.
2. Kandidatenlisten bilden:
   - UI/Theme
   - Rank-/Role-Badges
   - Input Prompts
   - Cursor
   - Dropship/Valkyrie-Bilder
   - Portraits
   - Weapon/Blaster Previews
   - Space Station / FOB Setpieces
3. Deduplizierung pruefen:
   - `3d` vs. `Space Kit`
   - GLB vs. FBX/OBJ
   - Root-Zips vs. entpackte Ordner
4. Importregeln definieren:
   - Quelle
   - Lizenz
   - Zielpfad
   - Verwendungszweck
   - maximale erste Importmenge
5. Optional erste kleine Asset-Auswahl importieren, falls der Task das explizit abgrenzt.

## Nicht-Ziele
- Kein Massencopy aller Assets.
- Kein neues 3D-Asset-Mapping fuer Terrain.
- Kein Portrait-Generator.
- Kein Austausch der bestehenden 2.5D-Primary-Assets.

## Architekturregeln
- Assets sind Darstellung, nicht Gameplay-State.
- Asset-Auswahl darf keine neuen Fallbacks verstecken.
- 3D-Primary-Pfad nutzt weiterhin sichtbare Missing-Asset-Marker.

## Akzeptanzkriterien
- Ein dokumentierter Asset-Katalog existiert.
- Erste Importkandidaten sind priorisiert und mit Zweck versehen.
- Deduplizierte Zielpfade sind vorgeschlagen.
- Keine grossen binaeren Massenimporte ohne explizite Task-Freigabe.

## Lokale Pruefung
- [x] Git-Diff enthaelt fuer TASK_165 nur Katalog/Plan und Statusdokumentation; es wurden keine neuen binaeren Assets importiert.
- [x] Asset-Bestand lokal aggregiert und Deduplizierung `Space Kit` vs. `3d\Space Kit` geprueft.
- [x] `git diff --check`
- [ ] Falls Assets importiert werden: Godot importiert sie ohne Fehlermeldungen. Nicht zutreffend fuer diesen Durchlauf.
- [ ] Falls UI-Assets importiert werden: eine manuelle Sichtpruefung bestaetigt Skalierung/Lesbarkeit. Nicht zutreffend fuer diesen Durchlauf.

## Ergebnis
- `docs/assets/local_asset_curation_import_plan.md` dokumentiert Bestand, bestehende Projekt-Assets, Deduplizierung, Importregeln, priorisierte Kandidatenlisten und kleine Folge-Tasks.
- Es wurden keine neuen Asset-Dateien importiert.
- `Space Kit` und `3d\Space Kit` wurden als strukturelle Duplikate mit jeweils 924 Dateien und 924 gleichen relativen Pfaden bewertet; `3d\Space Kit` ist damit kein Importkandidat.
- Grosse Pack-Importe bleiben blockiert. Erlaubt sind nur spaetere Micro-Subsets mit Maximalmenge und Zielpfad, z. B. Ranks, Valkyrie-Transportbilder oder kleine Weapon-Previews.

## Risiken
- Lokale Bilder im `Char`-Ordner sind gross; vor Import zuschneiden und Metadaten klaeren.
- FBX-Import ist riskanter als GLB; GLB bevorzugen.
