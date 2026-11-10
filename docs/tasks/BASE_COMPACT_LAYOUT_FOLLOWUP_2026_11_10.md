# Basis kompakter anordnen — offener Authoring-Nachtrag

## Ziel / Ursache
Nutzerfeedback10.11: die beiden Basisgebäude können näher nebeneinander stehen. Das ist ein gewünschter weiterer räumlicher Entwurf, keine Abnahme des aktuellen Abstands.

## Umfang und Grenze
Gemeinsame Koordinaten von sichtbaren Gebäuden, feiner Innenraumnavigation, Türwegen, Betten/Terminals, Pads und Erweiterungsflächen anpassen. Keine rein visuelle Verschiebung. Schiffs-/Gebäudequellen erhalten; keine Save- oder Kampagnenprogress-Änderung nebenbei.

## Quellen / betroffene Dateien
base_interior_navigation_contract (soweit vorhanden), campaign_introduction_contract; maps/campaign_intro_base.json, maps/homebase_frontier_exploration.json, aktuelle Basis-Navigationskarte, base_interior_navigation.gd und Authoringwerkzeuge zunächst lesen. graphics_reference_revision_contract und Quelle des Furnished-Cutaway beachten.

## Akzeptanz / Prüfung
Vorher/Nachher bei identischer Kamera; kurze Wege und tatsächliche AStar-Verbindungen zu jedem Bett, Terminal und Pad. Ursprüngliche2Personen und vorbereitete8/20/30Personen-Skirmishkapazität funktionieren. Bestehende Basis-/Boarding-/Savegates grün.

## Status / Risiken
Offen, nicht implementiert. Erst Gebäudekoordinaten und Navigation gemeinsam entwerfen; sonst drohen unsichtbare Wände, falsche Türpositionen und unzugängliche Betten. Der aktuelle UI-/Kamera-Task verschiebt diese Geometrie nicht.
