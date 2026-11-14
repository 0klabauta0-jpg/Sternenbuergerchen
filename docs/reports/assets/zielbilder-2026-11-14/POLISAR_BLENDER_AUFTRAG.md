# Arbeitsauftrag: Polisar in Blender überarbeiten

Überarbeite die Raumstation **Polisar** für das Godot-Spiel
**SternenBuergerchen** als editierbares Blender-Asset. Verbessere zuerst den
vorhandenen Stationsentwurf, statt eine beliebige neue Station zu erfinden.
Erhalte seine gelungene Padaufteilung und entwickle Bauweise, Proportionen,
Innenbereich und Details nach den folgenden Vorgaben weiter.

Liefere einen separaten Modellkandidaten mit `.blend`, Export und überprüfbaren
Ansichten. Ändere in diesem Auftrag keine Runtime, produktive Karten,
Navigation, Savegames, Gameplay-Owner oder bestehende Integration. Der
Bildname lautet Polisar; die vorhandene Code-ID `polisa` wird nicht umbenannt.

## 1. Arbeitsbasis und verbindliche Quellen

Lies zuerst die geltenden `AGENTS.md`-Regeln sowie
`docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`,
`docs/IMPLEMENTATION_STATUS.md` und
`docs/dev/graphics_reference_revision_contract.md`. Prüfe Branch und lokale
Änderungen. Arbeite in einem eigenen Assetordner auf einem geeigneten
Task-Branch/Worktree. Überschreibe keine bestehenden Modelle, Referenzen,
Generatoren oder fremden Änderungen.

Das aktuelle Grafikpaket liegt hier:

`C:/dev/SternenBuergerchen-worktrees/visual-targets-20261114/docs/reports/assets/zielbilder-2026-11-14/`

Öffne daraus vor dem Modellieren:

- `sources/native/polisa_r08_station_near.png` – tatsächliche native
  Ausgangsansicht: Padaufteilung, Innenhof, Shops, vorhandener Maßstab.
- `sources/native/polisa_r08_whole_map.png` – Station am oberen Kartenrand
  und freier Raum davor.
- `sources/star-citizen/port_olisar_user_topview.png` – vom Nutzer angehängte
  maßgebliche Geometriereferenz, insbesondere Ringstellung und Querachse.
- Das zuletzt vom Nutzer **annotierte Stationsbild** konkretisiert die
  Änderungen an Nabe, Querachse, Ringen, Seitenanbauten und Dockarmen nach
  Abschnitt 4. Seine blauen Markierungen bezeichnen **Nabe/Querachse**;
  „Narbe“ ist eine Diktatabweichung und kein Oberflächen- oder Schadensdetail.
- `sources/star-citizen/ScreenShot-2026-01-31_14-40-04-D50.jpg` – ergänzende
  Port-Tressler-Referenz für glaubwürdige industrielle Stationsbauweise.
- `RAUMKARTEN_RECHERCHE.md` – Quellen, Maßstabsregeln und genaue Grenzen.
- `prompts.json` – verwende beim Motiv 16 ausschließlich die dort aktuell
  zugeordnete `file` als aktives KI-Zielbild. Aktuell ist R04
  (`16_orbitalstation_r04.png`) nach dem annotierten Nutzerbild erzeugt und
  zugeordnet. Prüfe bei späterer Weiterarbeit dennoch die aktuelle Datei
  und die Generation-Metadaten. Ältere Fassungen bleiben erhalten.

**Die aktuell erzeugten KI-Bilder sind noch nicht
vom Nutzer freigegeben.** Verwende sie als Material-/Detailstudien. Falls ein
KI-Bild Ringe, Padaufteilung, Maßstab oder Kartengrenze widersprüchlich zeigt,
haben dieser Arbeitsauftrag, der Nutzer-Topview und die native Ausgangsform
Vorrang. Die jüngste Nutzerannotation und ihre ausdrücklich festgehaltenen
Korrekturen präzisieren dabei die ältere Geometriereferenz. Ein neues KI-Bild
ist keine automatische Modellabnahme. R04 zeigt die größeren, auf die
Dockachse zentrierten Ringe mit Streben, linke Solarflügel und vier rechte
Tanks. Beschriftung und Raster wurden sichtbar korrigiert. Konstruiere
dennoch mathematisch korrekte Geometrie und ein sauberes Raster: eine
KI-Linie ersetzt keine gemessene Modellprüfung.

## 2. Konkrete vorhandene Modell- und Buildquellen

Die geprüfte vorhandene R08-Quelle liegt unter:

`C:/dev/SternenBuergerchen-worktrees/space-air-parent-20261112/art/polisa_r08_20261111/`

Verwende insbesondere:

- `README.md`, `TASK.md`, `manifest.json` – Herkunft, Maßstab, Baugruppen,
  vorhandene Prüfung und bisherige Grenzen.
- `layout.json` – editierbare Layoutdefinition für Decks, Räume, Möbel,
  Pads, Ringachse, technische Bereiche und Dockköpfe.
- `layout_compiled.json` – abgeleitete gemeinsame Geometriefakten.
- `polisa_r08_visual.gd` und `polisa_r08_visual.tscn` – vorhandene
  prozedurale Modellquelle aus gebatchten Godot-Primitives.
- `author_layout.py`, `build_candidate.py`, `build_layout_svg.py` –
  nachvollziehbare Layout-/Kompilierungsquellen. Lies sie; führe sie nicht
  ungeprüft am Original aus, denn sie schreiben in bestehende Paketpfade.
- `layout_target.svg`, `layout_final.svg` – Layoutzeichnungen, keine
  fotografischen oder nativen Modellnachweise.
- `capture_r08.gd` – dokumentierte Vergleichskameras.

Die entsprechende Runtime-Darstellungsquelle, in diesem Auftrag nur lesen:

`C:/dev/SternenBuergerchen-worktrees/space-air-parent-20261112/scripts/terrain/polisa_station_visual.gd`

Die native private Kartenquelle als Maßstabs-/Platzierungskontrolle, ebenfalls
nicht verändern:

`C:/dev/SternenBuergerchen-worktrees/space-air-parent-20261112/output/native_glut_maps/polisa_r08_20261111/polisa_station_candidate.json`

In den untersuchten Stationsquellen wurde kein eigenständiges Polisa-`.blend`
oder Stations-`.glb` gefunden. Behaupte deshalb nicht, bereits eine solche
Quelldatei geöffnet zu haben. Prüfe zunächst, ob inzwischen eine aktuelle
Blenderquelle vorliegt. Wenn nicht, überführe die bestehende prozedurale
Geometrie beziehungsweise ihre Layoutdefinition in eine editierbare
Blenderquelle. Bewahre dabei das vorhandene Layout und die nachvollziehbare
Herkunft; ein völliger gestalterischer Neustart ist nicht das Ziel.

## 3. Koordinaten und Maßstab

Arbeite mit einer einheitlichen, überprüfbaren Hexreferenz. Erfinde keine
Meterzahl und übernimm keine realen Star-Citizen-Abmessungen.

Die vorhandene Kartenquelle verwendet `hex_axial_v1`. Im R08-Compiler
`build_candidate.py` ist die Ebenenabbildung:

```text
x = q + r / 2
z = r * sqrt(3) / 2
Hexradius = 1 / sqrt(3)
Abstand benachbarter Zellzentren = 1 vorhandene Ebeneneinheit
```

Die Station wird dort mit `scale = 1.0` und einem einmaligen Layout-Origin
platziert. Dies sind Projekt-/Ebeneneinheiten, keine hier bestätigten Meter.
Bewahre die Skalierung bei der Überführung nach Blender und prüfe sie mit
einem Hexraster, einer vorhandenen Figur und vorhandenen Schiffsproxies.
Personen dürfen nicht verkleinert werden, um künstlich mehr Platz zu schaffen.

Verbindlicher Schiffsmaßstab für die Raumkarte:

- leichter Jäger: **ein Hex**;
- mittlerer Jäger: **ein Hex**;
- Cutlass: **zwei benachbarte Hexfelder** als vorhandener Transporter-Footprint.

Der vorhandene R08-Stand nennt S-Pads 8×6, M-Pads 12×12 und L-Pad 16×24
in den bestehenden Ebeneneinheiten. Diese Werte sind eine Vergleichsbasis,
keine neue feste Zielgröße und keine Meterangabe. Der Nutzer wünscht die Pads
kompakter. Bestimme die Reduktion anhand plausibler Schiffsauflage,
Sicherheitsfläche, Zugänge und sichtbarer Proportionen; dokumentiere Vorher und
Nachher. Ein M-Pad ist eine Padklasse und nicht automatisch ein Mehr-Hex-Jäger.

Blender: Kartenebene XY, vertikal Z, Stationsquerachse horizontal X.
Godot verwendet in der bisherigen Modellquelle die XZ-Kartenebene mit Y nach
oben. Dokumentiere die angewendete Achsenumrechnung und den Export-Pivot;
vermeide doppelte Drehungen oder einen zweimal angewendeten Layout-Origin.

## 4. Verbindliche Stationstopologie

Erhalte die vom Nutzer positiv bewertete Ausgangsaufteilung:

```text
              hintere Station / nicht begehbare Dekoration
       obere Kartengrenze hinter Achse UND vollständiger Raumkontur
            ------------------------------------------
          Querachse in X-Richtung durch die Zentren stehender Ringe

             vollständige vordere Räume / größerer Innenbereich
                            Shops
                         blaue Kugel

         2 × M links       1 × L zentral       4 × S rechts
                                               als 2 × 2

                    freier Anflugraum der Karte
```

Das Schema beschreibt die Lesereihenfolge, keine neuen exakten Koordinaten.
Oben bedeutet hinten, unten bedeutet vorn. Die Grenze verläuft auf der
hinteren Seite von Achse und vorderer Raumkontur; sie liegt nicht zwischen
Achse und vorderen Räumen und wird durch die jüngsten Anbauänderungen nicht
verschoben. Die native R08-Nahaufnahme bestimmt die vorhandene Padaufteilung.

### Ringe und tragende Achse

- Stelle die Ringe **senkrecht zur Kartenebene** auf. In Blender liegen
  ihre Ringebenen in YZ und stehen damit normal zur horizontalen X-Achse.
- **Vergrößere die Ringe** gegenüber dem annotierten Ausgangsbild und
  **dehne/verlängere die blau markierte Nabe und Querachse**. Leite die
  Proportionen aus der Nutzerannotation ab; erfinde keine Metermaße.
- Die gerade X-Querachse läuft **exakt durch die geometrischen Mittelpunkte
  beider Ringe**. Ringzentrum und jeweiliges Achs-/Nabenkreuz fallen zusammen.
  In Blender stimmen die Y- und Z-Koordinaten der Ringmittelpunkte mit denen
  der Hauptachse überein. Eine Achse unterhalb der Ringmitte ist falsch;
  kaschiere einen solchen Versatz nicht durch zusätzliche Streben.
- Verbinde Ring, Nabe und Querachse durch plausible radiale beziehungsweise
  querlaufende Verstrebungen. Die Lastwege und Anschlusspunkte müssen
  erkennbar sein; keine geknickte Hauptachse oder lose Ringsegmente.
- In echter Draufsicht müssen die Ringe zu schmalen Strichen werden;
  aus leicht schräger Sicht erscheinen sie als schmale Ellipsen. Sie dürfen
  niemals wie flach auf dem Boden liegende Kreisplattformen aussehen.
- Behalte getrennte editierbare Ring-, Achsen-, Stütz- und Technikbaugruppen.
  Sichtbare Konstruktion muss verbunden sein; keine schwebenden Ringsegmente.

### Seitenanbauten nach der jüngsten Annotation

- **Links:** Verlängere die Struktur und ergänze Solarzellen beziehungsweise
  Paneelflügel **oberhalb und unterhalb der Querachse in der Referenzansicht**.
  Montiere sie mit nachvollziehbaren Trägern an Nabe/Querstruktur.
- **Rechts:** Montiere **genau vier Treibstofftanks**, zwei oberhalb und zwei
  unterhalb der Querachse in der Referenzansicht. Halterungen, Leitungen und
  Anschlussstellen binden die Tanks sichtbar an die verlängerte Struktur an.
- „Oberhalb/unterhalb“ bezeichnet hier die Bild-/Layoutanordnung um die
  Querachse, keine neu erfundene Gameplay-Höhenebene. Bewahre die aufrechte
  Ringstellung und den durch die Ringzentren laufenden Achsverlauf.
- Halte Solarflügel, Tanks und ihre Streben aus Anflugvolumen, Dockklammern,
  vorderen Räumen und Laufwegen heraus. Kernräume, Padaufteilung und
  Kartengrenze bleiben bei dieser Revision erhalten.

### Pads und Innenbereich

- Zwei M-Pads links vorn, ein L-Pad zentral, vier S-Pads rechts in einem
  klaren 2×2-Block. Behalte insgesamt sieben Landepads.
- Mache die Pads kompakter und die Station innen großzügiger. Erhalte die
  freie Zuordnung von Schiff, Landefläche, Fußweg und Stationszugang.
- Vergrößere den Hub/Innenhof mit seiner **blauen Kugel** als lesbarem
  Mittelpunkt. Arbeite die Shops und ihre unterschiedlichen Funktionen aus,
  ohne die Durchgänge mit Waren, Stützen oder Displays zu verstellen.
- Räume und Türen haben plausible menschliche Proportionen. Zeige lesbare
  Übergänge zwischen Ankunft, Hof, Ladenfronten und technischen Bereichen.
- Gestalte Außenhülle und Innenraum so, dass eine spätere Dach-/Schnittansicht
  möglich bleibt; Dachbauteile getrennt halten. Implementiere hier keine
  automatische Dachlogik oder neue Interaktionen.

### Zwei Großschiff-Dockports

- Ergänze **zwei funktional glaubwürdige Dockports für Großschiffe** als
  eigene Anschlüsse zusätzlich zu den sieben Pads.
- Verwende plausible Dockklammern, Schleusen und Verbindungsgänge mit
  mechanischer Befestigung an der Station. Prüfe vorhandene linke/rechte
  R08-Dockköpfe zuerst als Ansatz und arbeite sie gezielt aus.
- Setze **Dock 1 und Dock 2 etwas weiter nach außen**, indem du ihre
  tragenden Dockarme verlängerst. Erhalte je einen mechanisch verbundenen
  Anschluss; die neuen Solarflügel und Tanks dürfen die Klammern und ihre
  freien Anflugkorridore nicht blockieren.
- Halte Anflugvolumen und Ausrichtung sichtbar frei. Kein Großschiff soll
  für den Anschluss durch einen Ring, eine Solarfläche oder ein Landepad
  fliegen müssen.
- Dockports sind keine weiteren Landepads. Liefere nur Geometrie und
  benannte Anschluss-/Anflughilfen; keine vorgetäuschte Dockingmechanik.

### Obere Kartengrenze

- Die Station sitzt am oberen Kartenrand. Die Grenze liegt knapp **hinter**
  der Querachse und der vollständigen hinteren Kontur der vorderen Räume,
  sodass diese Räume innerhalb der Karte bleiben. Gemeint ist die hintere
  Seite dieser gemeinsamen Kontur, keine Schnittlinie durch Achse oder
  Räume. Die Achsenverlängerung erfolgt seitlich in X-Richtung; sie ist
  kein Anlass, die bestätigte Grenze oder die Kernräume zu verschieben.
- Schneide keine vorderen Räume, Türbereiche oder vorgesehenen Laufwege
  mit der Kartengrenze ab.
- Die obere/hintere Stationshälfte liegt außerhalb der spielbaren Karte
  oder ist ausdrücklich nicht begehbare Dekoration. Trenne sie als eigene
  Baugruppe. Keine dort eingezeichneten Lauf-/Auswahlflächen, die eine
  vorhandene Begehbarkeit behaupten.
- Die Referenzkarte umfasst 512 Spalten×256 Reihen. Für Modellprüfung und
  Bilder genügen korrekte Ausschnitte; ein dekoratives Raster ist kein Ersatz
  für spätere echte MapData-/Registry-Fakten.

## 5. Gestaltung und Detailgrad

Ziel ist eine glaubwürdige industrielle Science-Fiction-Station mit
Star-Citizen-Anmutung, umgesetzt in der klaren illustrierten Wimmelbildsprache
des Spiels. Baue keine maßgetreue Kopie einer fremden Station.

Verwende eine klare Staffelung großer, mittlerer und kleiner Formen:
Druckkörper, Rahmen, Fasen, Panelsegmente, wartbare Leitungsführungen,
Lüftungsflächen, ausgewählte Streben, Arbeitsmarkierungen und kleine
Gebrauchsspuren. Details konzentrieren sich an glaubwürdigen Funktionsstellen.
Eine hohe Nietenzahl ersetzt keine gute Silhouette oder plausible Konstruktion.

Palette: gebrochenes Weiß, Graphit und gedämpftes Blaugrau/Türkis; sparsame
gelbe/ockerfarbene Sicherheitsakzente und kleine cyanfarbene Funktionsleuchten.
Die blaue Kugel im Hub bleibt der deutliche räumliche Mittelpunkt. Material
und Licht dürfen die Räume und Wege auch aus normalem Spielabstand nicht
verschlucken. Vermeide übermäßig dunkle Fotorealistik, Spielzeugplastik,
flächige Neonbeleuchtung und visuelles Kleinteilrauschen.

Nutze gemeinsame Materialien und wiederverwendbare Details. Miss Geometrie,
Materialanzahl und Drawcall-relevante Teile vor und nach der Überarbeitung.
Erfinde keine pauschale Performancefreigabe aus einem stillen Renderbild.

## 6. Arbeitsweise und Lieferumfang

Arbeite reversibel und versioniert, zum Beispiel in einem neuen eigenen
Ordner `art/polisar_blender_revision_20261114/r01/` innerhalb des gewählten
Worktrees. Übernimm Quellen nur als ausdrücklich benannte Arbeitskopien.

1. Öffne die Referenzen, prüfe die tatsächliche Quelle und dokumentiere
   die Ausgangsbounds, Achsen, Skalierung und wichtigen Baugruppen.
2. Sichere einen unveränderten Vorherstand mit denselben Vergleichskameras.
3. Überführe bei Bedarf die vorhandene R08-Geometrie nach Blender. Prüfe
   zunächst den unveränderten Transfer, bevor du Proportionen gestaltest.
4. Überarbeite zuerst Ringstellung, Grundform, Raum-/Padproportion und
   Dockanschlüsse; erst danach Materialien und kleine Details.
5. Liefere eine editierbare `.blend` mit verständlich benannten Collections,
   mindestens Struktur/Innenbereich, Dächer, Pads, Ringe/Achse,
   linke Solarflügel, rechte Treibstofftanks, Großschiff-Docks und hintere
   nicht begehbare Dekoration.
6. Liefere einen GLB-/glTF-Kandidaten samt dokumentiertem Pivot,
   Achsenumrechnung, Skalierung und Materialroute. Prüfe den frischen
   Export-Reimport in einer separaten Kontrollszene.
7. Halte sichtbare Meshes, nicht begehbare Dekoration und gegebenenfalls
   vorgeschlagene Kollisions-/Footprint-Hilfen getrennt. Kennzeichne letztere
   als Entwurf: Sie schreiben in diesem Auftrag keine Gameplay-Fakten und
   werden nicht als fertige Navigation oder Runtime-Collision eingebaut.
8. Erhalte eine kleine README/Manifest-Datei mit verwendeten Quellen,
   SHA-256 der lokalen Referenzen/Exporte, vorgenommenen Änderungen,
   Messungen, offenen Abweichungen und reproduzierbaren Schritten.

Verwendest du Hasgahas ergänzende Port-Olisar-Bilder, erhalte den Credit:
**Hasgaha – https://hasgaha.com**, Quelle
https://robertsspaceindustries.com/community-hub/post/screenshots-of-port-olisar-over-the-years-03Z7D1CWw5L2H.
Kennzeichne eigene Modelle, externe Screenshots, KI-Zielbilder und native
Spielaufnahmen getrennt. Keine öffentliche Veröffentlichung als Teil dieses
Auftrags.

## 7. Verbindliche Ansichten und Abnahmekriterien

Erzeuge und öffne mindestens diese fünf Ansichten des tatsächlichen
Modellkandidaten, keine ersatzweise KI-Illustration:

1. **Orthografische Draufsicht** mit gleichmäßigem Hexraster, eingezeichneter
   Kartengrenze und maßstäblichen Jäger-/Cutlass-Proxies. Die aufrechten
   Ringe erscheinen schmal; sieben Pads, vier rechte Tanks und zwei
   Dockports sind zählbar. Zeige die linken Paneelflügel und ihre Befestigung.
2. **Gesamte Karte/Stationslage**, ungefähr nach R08 yaw0°/pitch68°:
   Station am oberen Rand, vordere Räume vollständig innerhalb, freier Raum
   davor. Kein riesiges bildfüllendes Stationsmodell.
3. **Nahe taktisch-isometrische Ansicht** mit lesbarer Padaufteilung,
   Ringstellung und Gebäudemaßstab. R08 yaw24°/pitch50° dient als Ausgangspunkt;
   dokumentiere nach Achsenumrechnung die tatsächlich verwendete Blenderkamera.
4. **Hub-/Shopdetail** mit blauer Kugel, vergrößertem Innenbereich,
   menschlichem Maßstab und freien Durchgängen.
5. **Dockdetail** mit beiden Anschlusspositionen beziehungsweise nachvollziehbar
   getrennten Nahansichten; Befestigung, Schleuse, Gang und freier Anflugraum
   müssen erkennbar sein.

Ergänze eine orthografische Kontrollansicht entlang X beziehungsweise eine
messbare Blender-Prüfung, die den exakten Durchgang der Hauptachse durch beide
Ringmittelpunkte bestätigt. Die schräge Beautyansicht allein genügt dafür nicht.

Halte Vorher/Nachher-Paare bei Kamera, Bildausschnitt, Auflösung, Licht und
Materialroute vergleichbar. Zusätzliche Beautyansichten dürfen die
Prüfansichten ergänzen, nicht ersetzen.

Prüfe am Ergebnis:

- vergrößerte senkrechte Ringe, verlängerte Nabe/Querachse, X-Achse exakt
  durch beide Ringzentren und plausible Ring-/Nabenverstrebungen;
- linke Solarflügel ober- und unterhalb der Achse, rechts genau vier
  strukturell befestigte Tanks in der Anordnung zwei plus zwei;
- sieben Pads in der geforderten Aufteilung, kompakter als vorher;
- sichtbar größerer Innenbereich mit Kugel und Shops;
- zwei nach außen versetzte plausible Großschiff-Dockports mit verlängerten
  Armen, frei zugänglichen Klammern und freiem Anflug;
- richtige Kartengrenze, vollständig erhaltene vordere Räume, getrennte
  hintere Dekoration;
- korrekter und einheitlicher Hex-/Figuren-/Schiffsmaßstab;
- keine schwebenden Teile, auffälligen Durchdringungen, kaputten Normalen
  oder exportbedingten Material-/Achsfehler;
- gute Lesbarkeit aus Spielabstand, nicht nur im Detailrender.

Berichte am Ende klar, welche Modelländerungen tatsächlich vorliegen,
welche Prüfungen ausgeführt wurden und welche gestalterischen Punkte offen
bleiben. Ein sauberer Export ist keine Nutzerfreigabe. Stoppe nach der
Übergabe des prüfbaren Assetkandidaten; keine automatische Runtimeintegration,
kein Mainmerge und kein EXE-Build.
