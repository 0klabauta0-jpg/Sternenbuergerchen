# Polisa R08: gezielte Folge der bestaetigten Grundform

Verbindliche Grundform/Massstab aus R07 erhalten: S8x6 wie Heimatbasis, M12x12/L16x24, ein Globusraum, fuenf Shops, sieben Pads, lokale Map512x256; Figuren unveraendert. Die Userkorrekturen betreffen Ringe, Achse, Solar-/Dockarme und bauliche Zugaenge.

Ringe jetzt Durchmesser56 statt48 mit unveraendert kraeftigem Querschnitt, gemeinsame geradeX-Achse aufY-12/Z19 unter der rueckwaertigen Weghaelfte. Solarzellen14x22 statt12x18, verlaengerte gerade Arme und deutlich beschriftete DOCK L/R-Koepfe. Niedrige Hull-/Glaswaende fassen die Padzugaenge ein, fuenf offene2.5breite Padportale und ein4breiter Lobbyeingang mit Seitenruecklaeufen. Sichtbare Geometrie und153zusaetzlich gesperrte Zellen stammen aus denselben Layoutfakten; kein freies Umgehen der Lobbyfrontmauer.

Die Portale sind bewusst OFFENE statische Durchgaenge, keine neue interaktive Tuersimulation. Dockingkoepfe sind sichtbare Geometrie/Reserve ohne neue grosse Schiffsdockingfunktion. Bestehende Stationmenue-/Service-/Kaufcommands und die Schiffsgrenzen aus polisa_ship_equipment_contract.md bleiben unveraendert.

Root-Produktion nutzt maps/polisa_station.json, bestehende Produkt-Scene und scripts/terrain/polisa_station_visual.gd mit R08-Facts. Buildtool ergaenzt Produktpfad/Name, Layoutkamera, Kamerafokus und aus Layout abgeleitete presentation-Kamerabounds; keine eigene Terrainwahrheit. Historisches Artmanifest bleibt unveraendert; root_integration_manifest.json belegt die integrierten Bytes.

Frisch selbst ausgefuehrter Build:20 Offlinechecks gruen;4486Tiles,2205begehbar in einer Komponente,2281gesperrt. Alle7Pads/5Raeume/Globusumlauf erreichbar, alle6Portale lokal querbar; dies ist ein kleiner Authoringgraphcheck, keine echte Laufwegabnahme.

Root-Nativlauf auf echter PRODUKTKARTE/-SCENE: native_product_station, D3D12/Forward+, Exit0/errors0/warnings0, drei Ansichten. Standardnahbild zeigt Waren ohne Drehung, echte Hexe und gefasste Zugaenge; Stationsueberblick zeigt beide DOCK-Koepfe, Ring-/Solaranordnung; WholeMap zeigt den ganzen512x256Rahmen. Alle drei Bilder wurden vor Abschluss geoeffnet. Keine GPU-/Frameratefreigabe aus Bildern;23.136statischeDreiecke/10Batches plus22.472bestehende R07-Schaukastendreiecke/6Meshes, Raster14.956Dreiecke/einMesh. Keine neuen Actor-/Kollisionsowner.

Grosse Reise-/Kauf-/Save-/Gefechts-/Netztests bleiben wie beauftragt spaeter, ebenso Main/EXE. AP4-Ownerpaket c69269578+8eabf50cd ist parallel nach konkretem Reviewfix und drei frischen Compilechecks integriert, ohne Actorbewegung oder Kartenaktivierung; Grenzen im separaten AP4-Integrationsreport.
