# Grafikpaket: aktive Familien und finale Nachweise

Arbeitsbasis: Main `dc2ca9aca`, eigener Integrations-Taskbranch. Grafikstand:
Snapshot `bc620e4d57334503b3b69f3101953ee9`. Produktquellen sind eingefroren.
Kein eigener Commit, Main-, HTML- oder Websiteeingriff dieses Pakets.

Die konkreten Darstellungsfehler sind in den unten genannten nativen Kameras
korrigiert: Stationsachsen und Anschluesse, duenne helle Floors, Hoehenraster,
Personenpalette, Bodenfarbroute und getrennt diagnostizierte Schattenstreifen.
Der echte Station192-Rendererabbruch ist ebenfalls geschlossen. Alle 37 finalen
Haupt-/Karten-/Stations-/Ensemble-/Schatten-/Oberflaechenbilder wurden geoeffnet.
Dies ist keine allgemeine aesthetische Freigabe. Der Nutzer hat Wandwinkel und
Steinformen ausdruecklich positiv beurteilt; geschuetzte grosse Blockerreihen
bleiben erkennbar. Andere Renderer, Langzeit-FPS und Releaseabnahme folgen
nicht aus diesen Einzelbildern oder begrenzten Regressionen.

## Umfang und Referenzen

`graphics_inventory.json` enthaelt **40 Galerieeintraege**, **17 aktive Dateien**
(14 Spiel-/Sandboxkarten plus drei Basis-/Navigationsdateien), **91 Modell-/
Texturquellen** und **46 kanonische Portraetidentitaeten**. Die Gruppen Karten,
Terrain, Gebaeude, Personen, Fahrzeuge und Props wurden einzeln beurteilt.
Originalbinaermodelle und Texturen bleiben unveraendert. Zwei abgeleitete
Gebaeude-TSCNs aendern ausschliesslich Materialbindungen; Geometrie- und
Transformnachweise samt Vorher-SHA stehen im Migrationsaudit.

A/B/C 512x256 besitzen jeweils Objective-/Arrivalansichten. Station64 und
Station192 verwenden dieselbe Modellfamilie, sind aber nicht durch eine einzige
Zentralaufnahme abgenommen: 64 hat eine Region mit 76 Wand-/Tuermodulen; 192 hat
neun Regionen mit 684 Modulen. Alle sind eindeutig gebunden und mit importierten
Bounds geprueft. Fuenf native Kameras zeigen 64 sowie Zentrum und drei gedrehte
Aussenanlagen von 192. `station_module_coverage.json` nennt diese Grenze explizit.
Polisa, Basis, GM01, GM02 und die produktiven Sandbox-/Drill-/Wall-/Workyard-
Dateien stehen mit ihren tatsaechlichen Quellen im Inventar. Historische reine
Import-/Testkarten werden nicht als neue gestalterische Ziele ausgegeben.

Geoeffnete Referenzen umfassen Rostgrenze-/Freihafen-/Gesamtweltziele,
Menschenstudie, Charakterkarte, Cutlass-Wimmelbild, Sternkartenentwurf und alle
zwoelf Originalportraetatlanten. Der dunkle KI-Deckentwurf ist ausdruecklich
abgelehnt; nur sein vom Nutzer positiv benanntes weisses Lagerhaus dient als
Teilreferenz fuer Ton und Ausrichtung. Die rechte Bruchsteinvariante ist die
gewaehlte Richtung fuer reale Hoehenfaces, kein exakter Kartenplan und keine
native Aufnahme. Referenzstatus und SHA sind getrennt von echten Bildern.

## Umgesetzte Darstellung

- **Praktischer Stationssubset:** 27 verwendete Typen: vier Floors, neun
  Wand-/Rahmen-/Ecktypen, vier Tuerblaetter und zehn erhaltene Raumprops.
  Warehouseachsen bleiben erhalten. Wandfugen und L-Ecken passen, das Tuerblatt
  liegt in der physischen Rahmenhuelle mit originaler Sturzhoehe. Der vorhandene
  Doorowner liefert den einzigen Oeffnungszustand; kein visueller Zweitstate.
  Floor liegt auch unter Waenden/Props. Rot/helle Randteilung folgt expliziten
  Baugrenzen ohne neue Hoehe oder Walkability. Die unnoetigen Rohrstrecken sind
  vom Contentowner samt ihren echten Blockerfakten entfernt. Die gruene
  Editor-Patrouillenlinie wird im normalen Spiel nicht mehr gezeigt.
- **Hexkontur und Stuetzhöhe:** abgeleitete Bodenmodelle liegen innerhalb der
  zugewiesenen Hexhuelle und sind nur 0,028 m dick. Konturen folgen den echten
  sechs Rampenprofilen, Terrainhoehen, Bruecken und bemalten Pads. Keine
  irrefuehrenden Linien auf senkrechten Klippen oder blockiertem/unbekanntem
  Boden. Die reale Figuren-/Auswahlhoehe folgt dem vorhandenen Groundsegment,
  auch vor/nach Zellhandoff; kein zweiter Bewegungsowner. Chunkcache, stabile
  Meshes und Registry-Revisionsluecken sind geprueft. Moebel und Figuren werden
  nicht global verformt und ihre AABB-Oberseite wird nicht als Boden erfunden.
- **Schatten:** H0 und duenne regionale Kappen werfen keinen Selbstschatten.
  Sichtbare volle Hoehensaeulen empfangen Schatten; gecachte reine Seitenhuellen
  ohne Kappe liefern ihren Wurf. Separate echte Klippen und Rampen bleiben
  Caster. Nur die duenne abgeleitete importierte Floorhaut wirft ebenfalls
  keinen eigenen Schatten; originale Square-/massive Deckmodelle bleiben
  unveraendert. Die finalen Kontrollbilder reproduzieren die beiden frueheren
  Ursachen getrennt, waehrend die aktuelle Produktansicht ruhig bleibt.
- **Arides Gestein:** gemeinsame Rost/Ockerroute auf semantisch passenden
  Karten; vorhandene Baumblocker erscheinen nur in den authored Wuestenstationen
  als Sandstein. Terrain-only alte Square-Klippenornamente entfallen nur ohne
  eigene Objektfunktion; echte Blocker bleiben sichtbar. Reale Hoehenkanten
  benutzen deterministische Bruchsteinfaces. Grosse geschuetzte Steinreihen
  bleiben sichtbar; gezielte Inhaltscluster und begrenzte Zellvariation sind
  keine vollstaendig natuerliche Streuung. Sehr wenige winzige Kiesel erscheinen
  auch auf freien flachen ariden Zellen im bestehenden statischen Batchpfad.
  Marker, Pads, Floors, Rampen und Hoehenkanten bleiben frei; keine Physik,
  LOS, Deckung oder Gameplay-RNG-Nutzung. Helle Bodenflecken bleiben auf
  ausdruecklichen Nutzerwunsch. Keine weitere optionale Stilrevision.
- **Farben und Personen:** die bestehende korrekte sRGB-Route gilt auch fuer
  Missionsboeden im Compatibilityrenderer. Alle 46 Portraet-IDs besitzen eine
  authored Haut-/Haar-/Uniformpalette aus ihren Originalen, gemeinsam fuer
  Basis, taktisches Modell und Vorschau. Keine Zuordnung nach Unit-Slot oder
  Name. Unknown verwendet die Originalroute. Mesh, Rig, UV und Ausruestung
  bleiben erhalten; individuelle Gesichter, Baerte und Frisuren sind keine
  neuen Geometriemodelle. Die violett/weisse Waffe ist schon vorher identisch
  und stammt aus der separat geoeffneten Original-Blaster-Colormap.
- **Lesbarkeit und Kosten:** Sternkartenraster blendet zoomabhaengig zurueck,
  Marker behalten Mindestgroesse/Trefferflaeche. Personenvisuals lesen vier
  Ownerfelder statt voller Action-/Layoutdictionaries; Bewegung bleibt direkt.
  Appearance- und Materialcaches vermeiden unveraenderte Traversierung.

## Aktuelle technische und native Nachweise

Alle folgenden finalen Laeufe verwenden `bc620e4d...`; Reports enthalten null
Engine-/Scriptfehler und gruene Quell-, Originalprofil- und private Canaryguards.

| Nachweis | Assertions | Lauf unter docs/qa/review_completion_20261113 |
| --- | ---: | --- |
| Grafik, 91 Quellen / 89 importierte Bounds | 519/0 | final_graphics/8827f4c969d84e34a4bcbdcbfa55d71e |
| Gebaeudematerial und echter Station192-Aufbau | 30/0 | final_building_material/f65a7f8a49f7408e8e0c9e2b56c59c60 |
| Waende/Tore/Floorgrenzen/Kiesel/Batchcaster | 282/0 | final_station_building/1b36648b56d942f3be69ed7b58702802 |
| Hoehenraster, reale Bewegung/Export und Floorcaster | 245/0 | final_hex_surface/ddd7f196a6ff475bbe2175a4bbf4ab30 |
| Vollstaendige Startressourcen aller 17 Dateien | 50/0 | final_map_preparation/6bbd9f0122224b4ea1e488b4e3eb971a |
| Statischer Cache und Live-FoW-Gridrestore | 12/0 | final_grid_cache/3d9f9702e7cd4b55ae21974d715191cd |
| Stationen, vier Bilder geoeffnet | 13/0 | final_station_capture/b4e116cf3e6046bc911bc65d3c6b8428 |
| 64 + vier echte 192-Ensembles, alle geoeffnet | 16/0 | station_ensembles_after/13cf6169f94b4e1fb9a48090d584b3bd |
| Oberflaechen, sieben Bilder geoeffnet | 23/0 | hex_surface_after/48f1b28f5ab64bb59eb92671ea588301 |
| Schatten-A/B, vier Bilder geoeffnet | 13/0 | station_shadow_after/8a04aea01cb24a188297d05befcfb3ce |
| Karten mit vollstaendigem Streaming, neun Bilder geoeffnet | 40/0 | maps_after/cae55c4ff80241289d9fb5983163d564 |
| Basis/Gebaeude/GM01/Person/Sternkarte, acht Bilder geoeffnet | 24/0 | graphics_after/c3aa86fb815f4272b0e81c030985ca9b |

Die fruehere 3134/0-Pruefung aller 76/684 echten Stationsmodule und Bruchfaces
liegt unter `final_cliff_station/4599c1fb17f7417fb720b0b153a382c0`; ihre belegte
Geometrie bleibt unveraendert. Der enge Ownerread besteht mit16/0. Begrenzte
CPU-Diagnose bei zwei Personen/1000 Reads: Vollprojektion8060us gegen5589us,
serialisierte Daten5396 gegen163Bytes. Das ist kein FPS- oder GPU-Vergleich.
Die 14 geoeffneten Personenbilder unter
`personnel_after/a072eeb3c66d417db0f1a013223c706d` bestehen mit81/0 und zeigen
Startduo plus alle46 Portraet-/Koerperpaare; Originalatlanten und gleiche
Vorherkamera wurden verglichen.

Die finalen acht Haupt- und neun Kartenbilder sind geoeffnet und im Inventar
gebunden. A/B/C zeigen vollstaendige Arrivalbereiche, sichtbare Terrainkonturen
und erhaltene weisse Gebaeude. Polisa behaelt seine vorhandene Innenraumroute.
Basis, Cutaways, Schiff und Figurenidentitaet bleiben erhalten. GM01 zeigt
keine frueheren diagonalen Baender auf ebenem Boden; Sternkartenuebersicht und
Nahzoom bestaetigen die unterschiedliche Rasterstaerke. Alte fehlerhafte
Zwischenaufnahmen stehen nur noch als ausdrueckliche Herkunft in den Daten.

## Zwei echte Integrationsfehler und ihre Nachweise

Der native192-Lauf `station_ensembles_after/c933f72485e241d1aa37f20ec1d3b228`
brach am4096-Instanzuniformlimit ab. 18 Gebaeude erzeugen783 Wear-Meshteile;
konstante lokale Bounds belegen darin keine Instanzparameter mehr, sondern86
geteilte Materialvarianten. Shaderformel und Werte bleiben identisch. Beide
abgeleiteten TSCNs sind idempotent textuell migriert; Geometrie-/Transformhashes
stehen in `frontier_wear_material_migration.json`. Kein Limit wurde erhoeht.
Die aktuellen30/0 und echten16/0-Nativbilder belegen den reparierten Pfad.

Die volle512x256-Missionsvorbereitung scheiterte am256MiB-Budget, obwohl kleine
Kameraausschnitte funktionierten. Der Cache hielt komplette dynamische Grid-
Meshes, die Restore ohnehin anhand Live-FoW neu erstellt. Der zustaendige
Content-/Cacheowner entfernte genau diesen doppelten Payload mit Restore-
Regression; Budget und Wahrheitsgrenzen blieben gleich. Vollstaendige2161/2161
Chunks sind wieder vorbereitbar, und die aktuelle17er-Matrix besteht50/0.
Kein Prozentgewinn fuer allgemeine Bildrate wird daraus abgeleitet.

## Vergleichsregeln und historische Grenzen

Alle nativen Bilder: Godot4.6.2, GL Compatibility,1280x720, gleiche Kameras je
Vergleich, private Profile, niemals aktivierter Windows-Desktop. Kein Bild
zeigt den Nutzerdesktop. Referenzen/Before/After und ihre SHA bleiben getrennt.
Vier neue192-Galerieeintraege vergleichen dieselbe Kamera vor/nach dem letzten
Floorcasterfix; ihr Before ist bereits nach Achsen-/Materialmigration und wird
nicht als Beleg der urspruenglichen Geometrie ausgegeben.

Die unsichtbare erste Basisbaseline und zwei noch streamende Arrivalbilder
sind verworfen. Gueltige Kartenbaseline:
`maps_before_settled/f6700739111c4eaebca18a829924cc4b`,40/0,neun Bilder geoeffnet.
Die dickweissen Floors unter `hex_surface_after/985bbe...` und der isolierte
Kenneytest wurden vom Nutzer abgelehnt. Sie bleiben gekennzeichnetes Vorher,
keine Designvorlage. Die damalige affine Anschlussrevision `c4fdfb...` und
weitere Zwischenbilder bleiben historisch. Die735-Serie begruendet die
freigegebenen Wandachsen; ihre Restfehler werden durch die aktuelle Serie
ersetzt. Technische Modul-/Sechsrampengruppen bleiben ausschliesslich QA.

Die aktuelle Schattenserie trennt Produkt, alte Vollsaeulen, fehlende
Saeulencaster und ausschliesslich wieder eingeschaltete alte Floorcaster.
Die frueheren regionalen Kappen-A/B-Bilder bleiben historische Ursachenbelege.
Eine Kontrollvariante mit abgeschalteten Schatten ist nicht das Produkt und
keine gestalterische Freigabe. Persoenliches Gesamturteil, alle anderen
Kamerapositionen und andere Renderer werden nicht als erledigt behauptet.
