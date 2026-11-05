# REVIEW8: Hallendach nach der A5-Vorlage

## Ziel / Problem
Die aktive geschlossene Frontier-Halle liest im nativen Spielbild als flacher
Kasten mit aufgesetzter Platte. Die geneigten blaugruenen Hauptdachflaechen und
hellen konstruktiven Kanten des A5-Ziels sind dadurch kaum wiedererkennbar.

## Referenzen und Ursache
Primaeres eigenes 2D-Ziel ist
`docs/reports/assets/ui-2026-11-01/mockup_a5_mission_zweireihig.png`, Halle vorne
rechts, SHA256 `fc9edb8b1d28921653ba5b438e7be8da4db3e0b32b8c751e9b18c4ef94918149`.
Ergaenzend fuer industrielle Konstruktion und Materialhierarchie:
`docs/reports/assets/grafik-2026-11-01/references/current/02_freihafen_distribution_center.png`,
SHA256 `463a74527ef36b38cf819039a35725aa21b33c0f44cf5146213327dcd9473530`.
Die zweite Vorlage ersetzt die A5-Dachform nicht. Beide Originale und vorhandene
native Bilder wurden geoeffnet. Die frischen Main-Vorherbilder werden vor der
Produktionsaenderung erneut beurteilt und im uebergeordneten Evidencepaket erfasst.

`frontier_gm01_layout.gd` und die Grafikprobe laden die bisherigen GLBs fuer ihre
Bounds, zeigen bei geschlossenem Zustand aber die prozedurale `ClosedExterior`.
Die sichtbare Form wird daher in deren Builder korrigiert.

## Umfang / Nicht-Ziele
Nur geschlossene Halle: breite geneigte Teal-Dachmassen, heller Rahmen und wenige
konstruktive Rippen innerhalb bestehender Bounds. Habitat, Schiffe, Beleuchtung,
Kamera, UI, Fenster-/Tuerpositionen, Access-Anker, Karte und Gameplay unveraendert.
Keine Blender-/GLB-Revision, keine Tor-/Innenraumfunktion und keine neuen Collider.

## Contracts
`REVIEW8_2026_11_05_code_ux_graphics.md`, `graphics_reference_revision_contract.md`,
`ui_native_design_contract.md`, `gm01_frontier_map_contract.md` sowie die dort
genannten Architektur-/Terrainvertraege. Grafikstatus: aktive native Darstellung;
technische Pruefung und gestalterisches Nutzerurteil bleiben getrennt.

## Akzeptanz
- Native Vorher-/Nachherbilder bei gleichen Kameras, Licht, Renderer und Groessen.
- Geneigte Hauptform und helle Einfassung im Hallen- und Ensemblebild erkennbar;
  weitere Detaildichte ist kein Ersatz fuer die Hauptform.
- Originale Bounds plus vorhandene 0,22m XZ-/0,20m Hoehenmarge einhalten.
- Endliche, nicht entartete, korrekt orientierte geschlossene Meshes und
  konservativ zusammenhaengende Baugruppe; keine neuen Runtimezustandsbesitzer.
- Je Gebaeude maximal 65 Meshes/3000 Dreiecke; urspruenglicher Access-Anker gleich.
- Normale native Mission und relevante Nachbarchecks getrennt durch Root pruefen.

## Dateien / lokale Pruefung
`scripts/terrain/frontier_closed_buildings.gd` und
`scripts/tests/review8_graphics_verifier.gd`. Der Verifier erbt den vorhandenen
Pass05-Topologieaudit, schreibt ausschliesslich in ein neues Evidenceverzeichnis
und bietet mit `--render --graphics-output <neuer Pfad>` vier echte Geometriesichten.
Diese Sichten sind synthetische Modellpruefung, kein normaler Missionsnachweis.

## Risiken / offene Punkte
Schraegflaechen duerfen keine Dachanschluesse schweben lassen. Das A5-Ziel besitzt
reichere Materialien und eine andere Szenendichte; dieser Pass ist keine gesamte
Modell-/Umgebungsabnahme.

## Umsetzung und native Bildpruefung
Die bisherige flache Dachplatte samt dominantem Monitoraufsatz ist durch ein
gefuelltes Giebelprofil, zwei geneigte Tealflaechen und helle Trauf-/Firstfassung
ersetzt. Drei schmale Querrippen gliedern die grossen Flaechen. Das niedrigere
Traufniveau macht die Dachschraegen bei nahezu gleicher Gesamthoehe lesbar;
Office, Eingang und Portal bleiben eigenstaendige, vorhandene Funktionsformen.

Frische feste Vorherbilder:
`output/review_graphics_20261105/graphics_before/20261105T051729Z-783d83cd/hall/`.
Frische Nachherbilder:
`output/review_graphics_20261105/graphics_after/20261105T052207Z-cf8e35df/hall/`.
Beide Pakete enthalten `geometry.json` und native Front-, Rueck-, Seiten- und
Ensemblebilder bei 1280x900, Forward+/Vulkan. Alle acht PNGs wurden tatsaechlich
geoeffnet. Je Bild sind Kamera, Groesse, Aufloesung, Renderer und Bildhash erfasst;
die vier Kamera-/Licht-/Aufloesungsdatensaetze stimmen vor/nach exakt ueberein.
ArtProfile, Wear-Shader, Access, Parentprobe und Verifier bleiben hashgleich.
`project.godot` unterscheidet sich durch die jeweils neue isolierte Profilkennung.

Sichturteil: Die Halle unterscheidet sich nun auch in der kleineren Ensembleansicht
vom flachen Habitat. Beide blaugruenen Dachschraegen, heller First und die
Frontgiebelkontur sind sichtbar. Die grosse geschlossene Torflaeche und das tiefere
Seitenbuero bleiben klar; an den geprueften Anschluessen wurde kein schwebendes
Bauteil oder neues Loch erkannt. Das ist eine begrenzte Annaeherung an die
A5-Hauptform, keine gestalterische Nutzerabnahme.

Offene Referenzdifferenzen: Die Vorlage besitzt staerker gefaste/segmentierte
Tragboegen, ein offenes Werkstattportal mit sichtbarer Nutzung, reichere
Materialabnutzung und mehr funktionale Ausstattung. Der neue helle First und die
Rippen wirken weiterhin regelmaessiger und sauberer. Torzustand, Fassadenkassetten,
Habitat, Felsstaffelung, Portraits und Gesamtkomposition wurden nicht revidiert.

## Lokales Ergebnis
Root fuehrte den nativen Geometrie-/Darstellungsverifier seriell in isolierten
Profilen aus: vorher 30/30, nachher 30/30, jeweils ohne Enginefehler. Endliche
Normalen/Vertices, geschlossene orientierte Meshes, keine entarteten Dreiecke,
konservative Baugruppenverbindung, Fenster-/Torabstand und Access-Anker bestanden.
Halle 58 -> 53 Meshes und 2508 -> 2304 Dreiecke; keine FPS-Behauptung daraus.
Hoehe 1,6168 -> 1,6550m, damit 0,1850m Erweiterung innerhalb der bestehenden
0,20m-Marge. XZ-Huelle bleibt innerhalb der bisherigen 0,22m-Marge und wird in der
Tiefe um 0,005m kleiner. Habitat bleibt bei 57 Meshes/2588 Dreiecken mit identischen
Bounds. Produktions-Builder nachher SHA256
`e3842f9623bf917bcac12ab211764c64dc82bc6e04caa81b0280790c4afdea02`.

Normale Missionsroute bei 1920x1080 und 1280x720, allgemeine Nachbarchecks und
abschliessende Integration werden durch Root im uebergeordneten Reviewpaket
separat dokumentiert. Diese vier Modellkameras sind synthetische Geometriebelege
und beweisen keine Kampagne, Gesamtperformance oder menschliche Bildabnahme.
