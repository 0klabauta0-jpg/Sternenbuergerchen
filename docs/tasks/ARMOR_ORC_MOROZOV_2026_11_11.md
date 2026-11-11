# Drei Rüstungsstufen nach ORC-/Morozov- und Kenney-Vorgabe

## Ziel / Ursache
Der Nutzer lehnt die aktuelle Rüstung weiter ab. Mittel und schwer unterscheiden
sich bisher hauptsächlich durch Umfang und ein paar zusätzliche Segmente.
Neue verbindliche Richtung: leichte und mittlere Ausrüstung an ORC Armor,
schwere an Morozov-SH aus Star Citizen orientieren (gesprochen „Matsorov“). Fahrzeuge
ausdrücklich zurückgestellt; später voraussichtlich Caterpillar zuerst.

## Umfang / Nicht-Ziele
Neue versionierte eigene Modelle auf vorhandenen Rigs und bestehendem
Equipmentprojektor. Leicht: reduzierte ORC-Platten und schmaler Körperumriss.
Mittel: deutlich dickere kantige Brustplatten, segmentierter Bauch,
kräftigere Schulterkappen und Beinschutz. Leicht und mittel erhalten feste
Wangen-/Kinnschalen und eine geschlossene klare Visierfläche mit erkennbarem
Dichtrand; die Gesichter bleiben sichtbar. Schwer:
breite Schutzweste, hoher gepolsterter Kragen, große Schulterschalen,
kräftige Beinpanzer, geschlossener Helm mit integriertem Visier und flachem
Kinnschutz. Aufgesetzte Schweißerbrille und großer Mundblock entfernt.
Silhouette muss auch ohne
Farbunterschied klar abweichen. Neutrale Palette, kein grüner Überwurf.
Der Anzug erhält keine neuen Rüstungsteile. Keine neuen Schutzwerte,
Inventarregeln, Käufe, Forschungsregeln oder Fahrzeuge. Pakethelme bleiben
Referenzen, werden nicht als neue Rüstung übernommen.

## Quellen / Vertrag
graphics_reference_revision_contract.md, personnel_inventory_contract.md,
vorheriger Task ARMOR_VISUAL_REVISION_2026_11_11.md und QA armor_revision_20261111.
Aktuell betrachtete ORC-/Morozov-Abbildungen mit URLs und SHA-256 zuordnen.
Ältere Personen-Stilstudie im Repo gefunden; sie ist keine belegte verlorene
Rüstungsreferenz. Frühere und aktuelle Kandidaten erhalten.

Nachfolgende Präzisierung: Bilder-KI ausdrücklich für Vorder-, Rück-, Seiten-
und Draufsichten der Rüstungen nutzen. Das vorhandene Kenney-Modell ist die
verbindliche Proportions-/Stilvorgabe; die jeweiligen Star-Citizen-Rüstungen sind
Konstruktionsreferenzen. Generierte Mehransichten sind Modellvorlagen, kein
Nachweis der nativen Umsetzung. Identität zwischen den Ansichten prüfen.

## Akzeptanz / Prüfung
- Zwei unterschiedliche Formfamilien, kein bloß vergrößertes gemeinsames Mesh.
- Drei unterscheidbare Stufen; leicht sparsamer als mittel, beide mit
  geschlossenem klarem Visier und festen Wangen-/Kinnschalen; schwer hoher Kragen/Visierhelm;
  keine doppelten Pakethelme, Kopf beim Ablegen wiederhergestellt.
- Gleiche Kamera/Licht für Vorher/Nachher und Mittel/Schwer, auch Spielabstand
  und Graustufensilhouette. Bilder tatsächlich öffnen.
- Blender-Geometrie/UV/Normalen-QA, editierbare Quellen/GLBs/Manifest.
- Ein gecachter geskinnten Mesh je Outfit, maximal fünf Materialflächen.
- Frischer Godotimport, beide Rigs, Stand/Lauf/Feuer/Rückseite/Kopfdrehung,
  tatsächlicher Ausrüsten-/Ablegenweg im privaten Profil; gezielte Regressionen.

## Dateien / Risiken
Neue art/armor_orc_morozov_20261111 und Assets/curated/personnel-Version,
personnel_armor_visual.gd, gezielter Verifier und QA/Status. Großkopfproportionen
des bestehenden Figurenstils bleiben; Fotos/Vorlagen sind keine bereits
spielbaren Modelle. Stilabnahme und Sitz-/Transportextreme getrennt ausweisen.

## Ergebnis
Zwei erste KI-Mehransichten, danach drei vom Nutzerfeedback abgeleitete Tafeln
für leicht/mittel/schwer erstellt und samt Prompts/Eingaben/Originalen erhalten.
Der Nutzer lobte die ersten Bilder und den schweren Körper, verlangte aber eine
schlankere leichte, stärkere mittlere und keine Schweißerbrille. Diese Korrektur
bestimmt die drei neuen Tafeln und die native Übertragung. Noch keine pauschale
Stilfreigabe der nativen Modelle. QA unter armor_orc_morozov_20261111.

## Kreative Überarbeitung / Vergleich
Der Nutzer bestätigt die drei 2D-Vorlagen, sieht die native Übertragung noch
zu weit davon entfernt und wünscht einen spezialisierten Agenten. Nach
ausdrücklich übertragener Wahl arbeitet Astra Ultra an einer neuen Blender-
Revision05. R04 ist ein technischer Draft, keine gestalterisch abgeschlossene
Integration. Der Root baut parallel einen Offline-Vergleich nach dem HTML-
Workbench-Vertrag: Vorlage/Modell, Blickrichtung, R04/R05, Graustufen,
Prüfnotizen und JSON-Export. Keine Runtime-Wahrheit in dieser Seite.

## Letzte Sitz- und Helmpraezisierung
Mit „verrutscht“ meint der Nutzer falsch sitzende Ruestungsteile, nicht den
Bildausschnitt. Die lokalen Fits muessen deshalb an den tatsaechlichen
Original-Koerperoberflaechen und anatomischen Achsen ausgerichtet werden,
auch in den echten Laufphasen auf beiden Rigs. Uebermaessige Plattendicke
und Luftabstaende reduzieren; schwere Ruestung ueber Abdeckung und
Schichtung unterscheiden, nicht durch aufgeblasene Bloecke.
Der mittlere Kinnschutz muss eine feste Helmschale bilden, keinen Riemen.
Auch der leichte Helm benoetigt Backen-/Kinnschutz und soll als Mischung
aus vorhandenem Spacehelm und ORC-Formen geschlossen und weltraumtauglich
wirken. Dies ist eine visuelle Vorgabe, keine neue Lebenserhaltungsmechanik.
Als wahrscheinlich gemeinte Scout-Referenz wurde der leichte Field Recon Suit
von Clark Defense Systems recherchiert; die genaue Nutzerzuordnung bleibt
unbestaetigt. Quelle: https://starcitizen.tools/Field_Recon_Suit und
https://starcitizen.tools/Field_Recon_Suit_Helmet (11.11.2026).

## Koerperfolgende Schalen statt flacher Tafeln
Nach der nativen R05-Aufnahme mit klaren Visieren kritisiert der Nutzer
weiterhin zu flache Panzerplatten. Die Geometrie selbst muss sich leicht
gerundet an die Koerperrundung anpassen: gewoelbte Brust- und Schulterflaechen,
koerperfolgende Querprofile an Unterarmen und Beinen, mit zur Seite
zuruecklaufenden Randschalen. Wenige lesbare Facetten erhalten den Kenney-Stil.
Mehr Woelbung darf weder durch blosses Aufdicken noch durch groessere
Luftabstaende erzeugt werden. Flacher Vorderplattenkandidat bleibt Vergleich;
nach der Aenderung wieder Front/Seite/Dreiviertel und bewegte Posen pruefen.
Beim Walk-Test gefundene untere Bauchplatten duerfen nicht weiter pauschal
dem Brustkorb folgen und in die Huefte schneiden. Zusammenhaengende starre
Platten erhalten eine passende bestehende Spine-/Hips-Zuordnung, ohne
Knochen oder Koerperrig neu aufzubauen.

## Übernahme R05
30 finale GLBs samt editierbarer Blenderquelle übernommen, produktiver
importierter PackedScene-Pfad. Headless/native Rüstungsverifier132/0, echter
Inventar-/Basisweg nativ16/0. Gewölbte Schalen, lokale anatomische Fits und
Spine-/Hips-Zuordnung der Bauchplatten; klare geschlossene Visiere mit
Wangen-/Kinnschutz. Quellen/Kandidat/R04/Produktionsbilder getrennt erhalten.
QA unter armor_kenney_r05_20261111; keine ästhetische Nutzerfreigabe, kein
Main-/EXE-Schritt.
