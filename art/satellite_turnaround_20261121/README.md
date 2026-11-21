# Satellit der ersten Mission - Vierseitenreferenz

Nutzerkorrektur: Fuer Tripo gibt es jetzt vier EINZELNE PNG-Dateien unter
`single_views/`: `Satellit_01_Vorne.png`, `Satellit_02_Rechts.png`,
`Satellit_03_Hinten.png`, `Satellit_04_Links.png`.
Die Quadranten der V3 sind unveraendert ausgeschnitten, nicht neu generiert,
nicht retuschiert und nicht skaliert. Jeweils 32 transparente Randpixel ergeben
691 x 691 Pixel. Die Pixelgleichheit mit der Quelle ist nach PNG-Readback geprueft.
Kopien und ein ZIP mit genau vier PNGs liegen in Downloads.

Ausgabe: `satellite_mission01_four_views_v3.png`, transparentes RGBA-PNG.
Anordnung: oben links vorne, oben rechts rechts, unten links hinten, unten rechts links.

Mit der eingebauten Bilder-KI aus dem vorhandenen Missionsmodell und der
Missionsillustration erzeugt. Wimmelbild-Look mit cremefarbenem Rumpf, goldenen
Rahmen, einem geknickten blauen Solarfluegel, gegenueberliegendem abgebrochenem
Anschluss, beschaedigter Schuessel und bergbarem Datenmodul.

V3 korrigiert die Blickrichtung der Schuessel in beiden Seitenansichten und den
doppelt auftauchenden Fluegelstumpf. Die Hauptbaugruppen sind jetzt konsistenter.
Die Ansichten bleiben eine KI-Modellierungsreferenz; kleine Lage- und Perspektiv-
abweichungen muessen beim 3D-Aufbau beurteilt werden. Kein vermessener Bauplan.
Das Missionsasset wurde nicht ausgetauscht.

`provenance.json` enthaelt Werkzeug, alle Prompts, Eingabebilder und SHA-256.
`final_consistency_prompt.txt` enthaelt den letzten Korrekturprompt lesbar.
Eingabebilder liegen unter `references/`, die fruehere Fassung bleibt erhalten.
