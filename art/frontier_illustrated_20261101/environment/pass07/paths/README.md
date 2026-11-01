# P07 Wege und Anschluesse

Die Sourcekopien sind bytegleiche editierbare Godot-Quellen. Habitat- und
Hallenanker stammen in der Preview aus echten GLB-Bounds und derselben
Tuerformel wie die geschlossene Huelle. Die Halle hatte zuvor37cm Versatz;
Bezier-Kontrollpunkte kroemmten auch das letzte Habitat-Wegstueck.

Die dunkle Unterkante war kein Schatten-/SSAO-Problem: Die native Ablation
mit unveraenderten Vertices belegt, dass geglaettete gegenorientierte
Mikro-Sliver-Normalen den Saum erzeugten. Explizite UP-Normalen fuer die
planaren Weglagen beseitigen ihn. Kein pauschales Abschalten von Beleuchtung.

23/23Pruefpunkte decken Default- und gemessene Previewanker, echte Rampenvertices,
Trittbruecken in beiden C-Zustaenden, flache Normallagen und Fact-Invarianz ab.
Pad-Rails separat56/56. Neue endgueltige Bilder/Hashes und gesamte strenge
Pruefserie: output/grafik_20261101/pass07_paths_verification_manifest.json.

Offene generelle Integrationsarbeit: mehrzellige Gebaeude/Pads und gespeicherte
Rampenfakten im regulaeren Kartenpfad, vollstaendige Hex-Authoringwerkzeuge,
Kampagnenmigration und weitere Anpassung an die2D-Ziele. Keine neuen Schiffe.
