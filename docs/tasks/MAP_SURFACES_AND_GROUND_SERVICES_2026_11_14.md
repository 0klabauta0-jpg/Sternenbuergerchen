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
