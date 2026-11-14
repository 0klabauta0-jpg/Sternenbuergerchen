# Kartenoberflächen, Stationsräume und Bodendienste

## Ziel / Ursache
Nach Auslieferung des Windows-Pakets a377c7346 das neue Bildfeedback umsetzen.
Die helle Karte wirkt ausgewaschen; Stationsböden/-wände sind nicht kohärent;
begehbare und landbare Felsoberseiten brauchen dieselbe Hex-/Höhenwahrheit wie
der Boden. Der Handelsposten soll seine Fracht- und Servicefunktionen zeigen.

## Basis / Umfang / Nicht-Ziele
Aktueller integrierter Main mit Buildnachweisen 144b0953a, eigener Taskbranch.
Keine Änderung des bereits ausgelieferten EXE-Pakets, keine breite Reviewrunde,
keine Desktopübernahme, keine fremden Branches oder echten Spielstände anfassen.
Bestehende Terrain-, Transport-, Inventory-, Service- und Editorowner nutzen.
Keine zweite UI-Gameplaywahrheit; keine neue Renderer- oder Assetpipeline.

## Referenzen und Dokumente
- Nutzerbilder aus Temp: codex-clipboard-bb85874c-2211-43f3-9672-4a19b72f7559.png
  (abgelehnte weiße Karte), codex-clipboard-8492a6c5-87ad-4fd2-a1ef-d655af240dcc.png
  (Stationsgrundriss), codex-clipboard-70721c38-4bd2-4c36-b5e1-7af262f57e86.png
  (gute große Felsen, fehlendes Oberseitengrid, brauner Streifen, Handelsposten).
- docs/dev/graphics_reference_revision_contract.md
- docs/dev/terrain_truth_visual_audit_contract.md
- docs/dev/productive_hex_rollout_contract.md
- Bestehende Landing-/Inventory-/Service-/Editorcontracts vor Eingriff lesen.

## Akzeptanz
1. Bildquellen gegen aktuelle produktive Karten identifizieren; nur noch aktuelle
   Fehler beheben. Weiße Karte erhält eine stimmige, unterscheidbare Palette.
2. Stationsboden mit sauberen Rändern; ein geschlossenes Kreuz als vierteilige
   Raumaufteilung, echte einzelne Türen, geschlossene Außenecken. Seitliche
   rautenförmige Flächen erhalten eine erkennbare Funktion und klare Übergänge.
3. Weiße blumenähnliche Wüstensprenkel entfernen (ersetzt früheres Belassen).
   Bestehende passende Felsen erhalten; ruhige Bodenflächen und glaubhafte Wege.
4. Große Felsformationen behalten ihre Formensprache; flache Oberseiten mit
   durchgängigem Hexgrid auf tatsächlicher Standhöhe. Landing nur bei gültiger
   zusammenhängender, ebener und ausreichend großer freier Schiffsfläche.
   Terrain und Hindernisse dürfen nicht nur optisch auseinanderlaufen.
5. Passende Fels-/Hügelvarianten auf geeigneten weiteren Karten, editierbar;
   kein identisches Dekorationsmuster überall.
6. Handelsposten: mindestens drei Gebäude und ein bis zwei lesbare Landepads,
   eines mit Frachtaufzug. Waren über bestehenden autoritativen Fracht-/Handelspfad
   einlagern/verkaufen und bereitstellen/laden; zugehörige Darstellung folgt State.
7. Landen auf beliebigen geeigneten Flächen. Reparatur und Betankung nur an
   zugelassenen Pads oder Mechanikern, mit Ort-, Zugriff- und Berechtigungsprüfung.
   Kaufen/Verkaufen und Service dürfen kein beliebig entferntes Schiff bedienen.

## Dateien / lokale Prüfung
Konkrete Owner und Karten nach Bestandsaufnahme hier ergänzen. Begrenzte
Regressionen für Oberflächenhöhe, begehbare/landbare Footprints, Stationswände/
Türen und Service-/Cargo-Autorität; bestehende Profile schützen. Native Vorher/
Nachher-Bilder derselben Kamera auf nie aktiviertem privatem Desktop öffnen und
beurteilen; Tests und sichtbare Qualität getrennt dokumentieren. QA-Nachweise
unter docs/qa/map_services_20261114/; Websitebericht mit tatsächlich erreichtem
Stand aktualisieren. Kein erneuter Kompletttest unveränderter Spielsysteme.

## Risiken / offene Punkte
Screenshots können älter als Main sein. Modellkappen sind bisher teilweise
Visuals mit blockierten Footprints; Änderungen benötigen echte Terrainfakten.
Vorhandener Polisa-Frachtaufzug ist wiederzuverwenden, nicht blind als bereits
funktionsfähiger Ground-Service auszugeben. Keine Form- oder Spielabnahme allein
aus Quelltextprüfungen ableiten.

## Konkretisierung nach nativem Bestand
Bilder 1/2 sind exakt GM02 und Station64; Bild3 ist GM01, nicht trade_outpost.
Native Vorherkameras: scripts/tests/map_services_capture_20261114.gd;
private Aufnahme map_services_before/2bf53c3cebd4413da5406e823c50ec25 (13/0).
GM01-Geologie bleibt eigenstaendig, Handelsort wird separat am Servicekern gebuendelt.
Owner: TerrainMapData/TileData/Registry fuer Standhoehen und Begehbarkeit;
StationModuleProjection und TerrainMap3DView lesen Daten. SingleplayerRuntimeAdapter
prueft lokale Schiffe, SupplyState bucht, AutomaticCargoTransfer plant begrenzt.
Felsoberseiten werden nur vollstaendig von realen flachen Kappen getragene Hexzellen;
keine Felskollision ueber einen blossen Visualoffset vortaeuschen.

## Erreichter Umfang und gezielte Pruefung

GM02-Palette umfasst Boden, Wege, Zielauflage und Naturmodelle in den tatsaechlichen
Materialrouten. Station64 und alle neun Station192-Ensembles haben geschlossene
vier Aussenecken, Kreuz und vier passierbare Einzeltueren. Seitliche Flaechen
sind blockerfreie, neutral bezeichnete Lager-/Reserveaprons, keine erfundenen
Tankstellen. GM01 hat83 echte Kappenzellen einschliesslich genau einer neuen
breiten Landemesa; alte Silhouetten bleiben abgesehen von kleiner quantisierter
Kappenhoehenanpassung erhalten. Workyard erhaelt26 echte erhoehte Tiles; am
Handelsort entsteht separat eine61-Zellen-Huegelgruppe. Kein Kopieren eines
identischen Dekorationsmusters ueber alle Karten.

Produktowner und Dateien: TerrainTileData/RegionalHexSurface, FrontierArtGeology,
FrontierGM01Layout, TerrainMap3DView; sechs geaenderte Karten (GM01, GM02-Palette
ueber View, Station64/192, Workyard, Trade/Satellite-Service-Metadaten),
FieldLandingContract/HexGroundShipFootprint und TacticalController;
SingleplayerRuntimeAdapter/SupplyState/SimulationRoot/SpaceCombatState,
MetaLayerFlow-Recoveryclock, ServicesPresenter und bestehende Liftvisuals.
Editor verwendet dieselben gespeicherten Terrain-/Hoehenfelder bis16, keine
versteckte Mesh-Gameplaywahrheit. Die neue generierte Mesa liegt auf GM01 bei
Plane(41,42); die anderen Varianten sind in den vorhandenen Karten-/Editorwegen.

QA: docs/qa/map_services_20261114/. Quell-/Profilguards, native Bilder und
Headless-Assertions getrennt. Vollstaendiger Fuenf-Missionen-Sieg, WAN und eine
persoenliche Gestaltungsgenehmigung bleiben ausserhalb dieses Pakets.
