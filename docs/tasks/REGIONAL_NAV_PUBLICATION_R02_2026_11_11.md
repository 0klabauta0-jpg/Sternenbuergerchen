# Regionale Chunk-/FoW-Publikation in begrenzten Schritten

## Ziel / Ursache
Im echten B-Gefecht verbraucht die visuelle Veröffentlichung eines neuen
regionalen Ausschnitts27–37ms zusätzlich zum weichen Chunkbaubudget.
Der Name ist keine Navigationseigentümerschaft: betroffen sind TerrainMap3DView
und dessen Overlayprojektion, keine Pfadsuch- oder Walkability-Wahrheit.

## Basis / Umfang / Nicht-Ziele
Isolierter bestehender Taskbranch task/native-glut-maps-20261110 auf85fd00afc.
Zunächst vorhandenen Publish-Pfad in kleine CPU-Scopes zerlegen und prüfen.
Nur den belegten Engpass gezielt cachen oder in begrenzte Vorbereitungsstücke
teilen. Bisheriger gültiger Ausschnitt bleibt bis zu sicherer Freigabe erhalten.
A/B/C bleiben512×256; keine Detail-, Gegner-, Sichtweiten- oder Temporeduktion.
Keine Armor-, Kampagnen-, UI-, Navigations- oder Gameplayänderung.

## Quellen / Verträge
AGENTS.md, ARCHITECTURE.md, CODEX_RULES.md;
docs/dev/fog_of_war_modes_contract.md;
docs/tasks/COMBAT_FRAME_ACCOUNTING_2026_11_11.md;
docs/qa/combat_frame_accounting_20261111/README.md;
docs/qa/navigation_first_go_20261111/README.md.

## Akzeptanz
- Gleicher veröffentlichter Ausschnitt, exakte ID-/Slot-/Transform-/Farben-
  Zuordnung und aktuelle FoW-Revision nach Fertigstellung.
- Kein unbekanntes Terrain ohne Blackout; Mode-/Team-/Mapwechsel bleiben
  unmittelbar geschützt. Neue Sichtdaten während Vorbereitung bleiben aktuell.
- Kameraumkehr oder neuer Zielausschnitt verwirft veraltete Vorbereitung.
- Keine per-frame Vollscans oder unbeschränkte Publikationsschleifen.
- Nur visuelle Vorbereitung, Terrain-/Simulationseigentümer unverändert.
- Gezielter Verifier deckt Veröffentlichung und Abbruch/Umkehr ab;
  gemessene CPU-Unterkosten und Arbeitsmengen mit Kontext dokumentieren.

## Dateien / Prüfung
scripts/terrain/terrain_map_3d_view.gd; gezielter regional_fow_publication_test.gd;
QA regional_publication_r02_20261111. Bestehende regionale Streaming- und
FoW-Regressionen. Private APPDATA unter output/native_glut_maps.
Headless-Diagnose ist kein nativer Pixel-/FPS-Nachweis. Native Messung erst
nach exklusiver Freigabe des koordinierenden Root-Agenten; keine konkurrierenden
Renderer/Importe/Benchmarks. Keine Commits/Pushes durch Teilagent.

## Risiken / offene Punkte
Einzelne GPU-/Resourceallokationen bleiben nicht unterbrechbar; ein weiches
Zeitbudget allein garantiert keine harte Framegrenze. Vorher/Nachher bei
laufender Artarbeit sind nur explorativ, keine isolierte Leistungsfreigabe.

## Kandidat / begrenztes Ergebnis
Befund lokalisiert: Overlay-Metadatenbau dominiert, daher kein neuer
Vorbereitungsjob. IDs/Lookups/Bounds/Höhen werden statisch je Chunk
vorbereitet und mit dessen Lebensdauer entfernt. Publish führt sie zusammen.
Auf echter B0 statt6912 wiederholte Geometrieabfragen; geordnete Ergebnisse
exakt wie ungecacht. Neuer Verifier RED0/1→GREEN13/0, Streaming3/0,
R4-FoW-Projektion29/0 und Task225Overlay34/0. Paartiming und Nativefreigabe
stehen bewusst noch aus, bis Root/Astra ein isoliertes Fenster freigeben.
Keine Commits/Pushes durch Teilagent.
