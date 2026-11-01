# ART Pass06: Relief, feinere Erosion und malerischer Abrieb

## Ziel / Ursache
Der Nutzer beauftragt die im Pass05 benannten Luecken: echte Bodenunebenheiten,
feinere Erosion und malerischen Materialabrieb. Die 2D-Ziele bleiben Rostgrenze,
Freihafen und die taktische Rostwelt. Native P05-Bilder sind die Vorherbasis.
Flacher Boden, grosse glatte Felswaende und homogene saubere Materialfelder
verhindern bisher die Naehe zu den Illustrationen.

## Umfang und Grenzen
- Geometrisches, abgestuftes Felsfuss-/Randrelief in den vorhandenen gesperrten
  Geologiehuellen; keine verdeckte Aenderung an begehbaren Hexzentren, Wegen,
  Padauflagen, Picking, Hoehen-/LOS-Fakten oder TerrainMap3DView.
- Feinere unregelmaessige Rinnen, ausgewitterte Kanten und Ablagerungen an
  vorhandenen Felsmassen; Hauptformen erhalten, keine gleichmaessige Ringzierde.
- Gerichtete, mehrskalige Pigment-/Staubfelder auf Boden/Fels/Wegebelag und
  abgegriffene Kanten, ausgebleichte Lackfelder und Ablagerungen an Gebaeuden.
- Keine Schiffs-/Citizen-/Kenney-Quelldateiaenderung, keine Astra-Adoption,
  Gameplay-, Kampagnen-, Topologie- oder Beleuchtungsumstellung.

## Basis / Dokumente
Bewusste Fortsetzung des unintegrierten task/grafikreferenzen-20261101 auf
04e934f60. PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS;
graphics_reference_revision_contract, terrain_truth_visual_audit_contract,
hex_grid_v1_contract und html_report_workbench_contract gelten weiter.

## Dateien / Besitz
Geologie: frontier_art_geology.gd und zugehoeriger Pass06-Quell-/Pruefnachweis.
Gebaeude: frontier_closed_buildings.gd, eigener Wear-Shader und Pruefnachweis.
Root: Boden-/Kontaktshader, Preview/Capture, Integrationstests/Status/Git.
Report: eigener P06-Workbench-Bereich, bytegleiches P05-Archiv, BrowserQA.

## Akzeptanz / lokale Pruefung
- 2D und native Vorherbilder wirklich ansehen. Relief und Erosion aus normalem
  Spielabstand sowie in vorhandenen Detailkameras erkennbar verbessern.
- Alte14 Geologiehuellen bleiben erhalten; alle neuen Reliefvertices liegen
  innerhalb dieser Huellen und nur dort. Begehbare Zentren und Crew bleiben
  eben/aufgesetzt; keine neuen schwebenden Reste, offenen Boeden oder Z-Fights.
- Endliche Geometrie, brauchbare Normalen, geteilte Materialien, Aufbau nur
  einmalig. Keine SceneTree-Scans oder Rebuilds im Hotpath.
- Gleiche Paarkameras, Licht, Renderer und Aufloesung wie P05. Veraenderte
  Materialroute deutlich als Gegenstand des Vergleichs angeben.
- Unveraenderte primaere GLBs hashpruefen; C, Hexgrid/Picking und Bewegung
  regressionspruefen. Bedeutungsvolle neue Relief-/Materialtests ergaenzen.
- Neue native PNGs oeffnen und vor Freeze unabhaengig pruefen. Offline-HTML
  mit Notizen/JSON exportieren auf Desktop/Mobil frisch pruefen.
- Quell-/Capturebelege, Task/Status committen und pushen; Techniknachweis von
  kuenstlerischer Nutzerabnahme und Main-Integration unterscheiden.

## Risiken / offene Punkte
Relief bleibt bewusst an gesperrte Felsbereiche gebunden; dies ist kein Umbau
der spielbaren Flaeche in frei hoehenmodelliertes Terrain. Illustrationen
bleiben reicher komponiert. Keine allgemeine Performance-/Releasefreigabe.

## Umgesetzt / native Pruefung
- 68Geometriemeshes:54Felsen mit begrenzten, ungleich langen Rinnen und14echte
  Sediment-/Talusfaecher.42363Vertices/14121Tris; alte14Huellen identisch.
  Relief mindestens20.26cm Hoehenspanne, mindestens72.68% Huellenflaeche;
  aeusserer Rand endet unter Grund. Steilste schmale Faecherstelle abgeflacht,
  Normalengrenze0.45 beibehalten, erreicht mindestens0.47185.
- Gebaeudegeometrie unveraendert, aber eigene rollenbezogene Materialroute:
  Dachbleichung, Pigmentfelder, Sockelstaub, selektiver Abrieb. Glas/Emissivwerte
  erhalten.39/39Geometrie-/Materialchecks und6/6isolierte Bildantwortchecks.
- Boden, Felsen und Pflaster erhalten weichere mehrskalige Pigment-/Staubfelder;
  lokale staubige Wegschultern und78selektiv abgegriffene Weg-/Vorplatzmarken.
  Prozedurale Shader, keine handgemalte Texture-Bake. Keine globale Lichtaenderung.
- Finale21/21strenge Godot-Laeufe auf4.6.2; Quelle:
  output/grafik_20261101/pass06_environment_check_runs/20261101T192055Z-pid105384/metadata/report.json.
  20nativeVulkan-PNGs fehlerfrei erzeugt,12identische Kamera-/Sichtzustandspaare
  gegen P05. NeunprimaereGLBs bytegleich,10Runtimequellen hashgeprueft.
- Root und unabhaengiger Reviewer haben finale Bilder geoeffnet: keine
  konkreten neuen Blocker bei Kontakten, fehlenden Teilen, Normalen oder Z-Fights.
  Sichtpruefung an Standbildern ist keine zeitliche oder kuenstlerische Abnahme.
- Offene Referenzluecken: breite/prismatische Grossfelsen und Kronen, frei
  begehbare Bodenflaechen weiterhin eben, weniger kleine Senken und reichere
  materialbezogene Gebrauchsspuren als in den2D-Zielen. Originale Cutaways,
  Citizens und Schiffe bleiben unangetastet; kein Main-/Kampagnenumbau.

## HTML-Abschluss
Schlanke P06-Workbench mit35eingebettetenBildern,12festen Vergleichspaaren,
Wischregler,3Zielbildern,Quellen/Katalog,Notizen/Entscheidungen undJSONexport.
P05 ist bytegleich als eigener Archivbericht erreichbar.171/171frische
Browserchecks samt Sichtpruefung PASS,70Decodes,27geoeffneteScreenshotlayouts,
2echte unterschiedlicheDownloads,0Console-/Pagefehler/externenRequests.
ExakterHTML-SHA256:75064afec11b66510846cd4679008fb3247ace2c71ac2a3d558aa1cb42662602.
Code5929d3dabf8535ba5652065110ae2252d5f38b69 erfolgreich gepusht;
Bericht/Pruefnachweise als eigenes Uebergabepaket, weiterhin keine Main-Integration.
