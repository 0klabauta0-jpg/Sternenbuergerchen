# R4: Was die Bild-KI beigetragen hat und wie es nativ weitergeht

## Verbindliche Eingaben
Der Nutzer bezeichnet R3 als noch deutlich zu weit von den vorhandenen 2D-Bildern entfernt. Die finalen vier Referenzen sind `menu_fob_loadout.png`, `menu_heimatbasis.png`, `menu_debrief.png` und `mockup_a5_mission_zweireihig.png` unter `docs/reports/assets/ui-2026-11-01/`. Die späteren Brückenentwürfe ersetzen weder diese Richtung noch vorhandene Charakter-, Schiffs- oder Gameplaydaten.

Vier getrennte Aufrufe des integrierten Bildgenerators verwendeten jeweils die finale 2D-Vorlage als Stilautorität, den tatsächlichen R3-Screenshot als Funktions-/Belegungsreferenz und den aktuellen Main-Außenpostenrender als Material-/Umgebungsreferenz. Alle exakten Prompts stehen in `prompts.json`, Dateien und SHA-256 in `manifest.json`. Die Originalausgaben wurden unverändert in dieses Projekt kopiert.

## Fortschreibung nach Dokumentaudit · 02.11.2026
Die folgenden R4-Entscheidungen und Bildbefunde dokumentieren den damaligen Durchgang. Sie sind kein neuer Auftrag, dessen native Pixelmaße oder vereinfachte Rahmen dauerhaft festzuschreiben. Die oben genannten bestätigten Original-2D-Ziele bleiben Gestaltungsautorität; Brückenbilder erläutern nur eine Übersetzung. Referenzgetreue Raster-/Nine-Patch-/mehrschichtige Rahmen sind um echte native Controls zulässig. Größen und Bühnenanteile dürfen weiter an die Zielbilder angenähert werden, solange Kompaktheit, lesbare Beschriftung, Fokus/Eingabe und tatsächliche Funktionen erhalten bleiben. Aktueller Vertrag: `docs/dev/ui_native_design_contract.md`.

Die unten genannte Square8-Basis ist historisch: Der aktuelle Task-Stand besitzt die ausdrücklich beauftragte GM01 mit48×48Hex nach `docs/dev/gm01_frontier_map_contract.md`. Eine Mainintegration wird damit nicht behauptet. Aktivierte Hexgeometrie ist noch kein menschlicher Lesbarkeitsnachweis; tatsächliche1280×720- und1920×1080-Spielansichten müssen die Hexfelder dezent, aber erkennbar zeigen. Die Terrain-Bodenmaske besteht weiterhin; entfernt wurde im bekannten Terrainmodus der schwarze Aufbau-Schutzkasten. Dynamische Gegnerdarstellung bleibt davon unabhängig sichtgefiltert.

Reihenfolge der nächsten Runde: Dokumentaudit/Korrektur abschließen, dann echte Enginebilder und ihre Original-2D-Ziele direkt vergleichen, daraus begrenzte visuelle Änderungen ableiten und nativ nachprüfen. Keine zufälligen KI-Gesichter oder neu interpretierten Schiffe übernehmen; exakte Cutlass und Zustandsbesitz bleiben verbindlich.

## Erklärung statt behaupteter interner Gedanken
Die drei kurzen Erläuterungen im Bildfuß wurden ausdrücklich als sichtbare Designbegründungen angefordert. Die internen Gedanken des Bildgenerators sind nicht zugänglich. Folgende Zuordnung beschreibt Vorgabe, sichtbares Ergebnis und unsere technische Entscheidung:

| Entscheidung | Warum sie hilft | Im generierten Bild sichtbar | Native Umsetzung / Grenze |
|---|---|---|---|
| Tiefes Petrol als zusammenhängende Oberfläche | Inhalte gehören optisch zur selben Instrumentenfamilie | Alle vier Brücken bündeln Gruppen mit Petrol statt grauem Formularhintergrund | Gemeinsames gecachtes Theme; echte native Controls und Schrift bleiben erhalten |
| Cyan-Kontur für Gruppen, Gelb für Auswahl | Gruppierung und aktuelle Auswahl lassen sich unterscheiden | Leuchtendere dünne Umrisse, gelber ausgewählter Trupp | Sichtbarer Fokus/Hover/Disabled bleiben eigene native Zustände; kein generiertes Enable übernehmen |
| Kräftige schmale Titel, klare Personenidentität | Abschnitt, Name und Datenzeile bekommen unterschiedliches Gewicht | Deutlich fette Titel und portraitgeführte Karten | Gebündelte Barlow Condensed Bold statt der ersten zu gesperrten Kenney-Schrift; Body- und Buttonschrift behalten ihre Größen |
| Rechte Außenposten-/Flugdeckbühne | Verbindet Formulare mit der Spielwelt und den cremefarbenen Modulen | Heimatbasis/FOB geben dem Schauplatz eine sichtbare Fläche | Kuratierter tatsächlicher Main-Render ausschließlich im freien Bereich, input-ignore/visual_only; bei Platzmangel ausgeblendet |
| Markantes Ergebnis mit Personenfolgen | Ergebnis und betroffene Menschen werden vor Rohkennzahlen erfasst | Debrief zeigt große Ergebniszeile, Portraitkarten und Szenenbezug | Tatsächlicher Ergebniscode und vorhandene Portraitmetadaten; unbekannte Werte/Vorschau bleiben ausdrücklich erkennbar |
| Kompaktes zweireihiges Befehlsband | Befehle bleiben schnell erreichbar und bieten Platz für vorhandene Werkzeuge | Missionsbrücke erhält zwei Reihen mit Innenbeschriftung | Vorhandene 64px-Aktionen und 160px-Band; passiver deckender Hintergrund folgt exakt denselben Layoutgrenzen |

## Tatsächlich beobachtete Bildabweichungen
- Der Generator hat vorhandene Pixelportraits zu anderen illustrativen Gesichtern umgezeichnet. Das wird **nicht** als neue Identität oder Assetersatz übernommen.
- Mehrere deaktivierte Transportknöpfe erscheinen im Bild optisch aktiv. Ihre echten Runtimegates werden unverändert behalten.
- Die Missionsbrücke verwendet den sauberen Außenpostenrender als vermeintliches Spielfeld. Das ist ein Vorschlag, kein Beleg für das reguläre Missionsgelände. Der native R4-Nachweis startet separat den normalen Menü-/Homebase-/GM01-Pfad.
- Die Homebase-Brücke verschiebt die Bühnen-/Transportreihenfolge. Nativ bleiben kompakte reale Transportaktionen erreichbar; freie Fläche darunter erhält die Bühne. Die Illustration darf keine Drop-/Inputwege verdrängen.
- Rich-Debrief-Beispielwerte und allgemeine Personenlabels stammen aus der erklärten Testfixture. Sie werden nicht als real durchgespielte Mission ausgegeben.

## Übergabe für den nächsten Chat
Zuerst die R4-Workbench und tatsächlichen nativen Bilder ansehen, dann Vorlage und Brücke daneben vergleichen. Layout/State nicht aus einem KI-Bild ablesen: IDs, Portraits, Bereitschaft, Planstatus, Gesundheitswerte und bestätigte Entwicklung müssen weiterhin vom vorhandenen Owner kommen. Eine dekorative Szene ist kein transportiertes Schiff und kein Nachweis eines Missionsereignisses.

Historischer R4-Stand: Die Main-Basis war `7f594530f`, Grafikübernahme `177991ac4`: gespeicherte GM01 wählte `frontier_illustrated_v1`, behielt aber Square8. Die neue Hex-Werft war separat. R4 führte diese Basis im eigenen UI-Branch mit R3 zusammen; Main selbst wurde nicht geändert. Aktueller GM01-Hexstand siehe Fortschreibung oben.

Visuelle Restabstände ehrlich prüfen: vorhandene echte Pixelportraits gegenüber illustrierten Portraittafeln, native Rendererwirkung gegenüber gemalten Szenen und belegungsabhängiger Bildanteil. Technische Checks allein sind keine Bestätigung, dass der Nutzer die Stilnähe jetzt ausreichend findet.

## Aktuelle Cutlass-Präzisierung des Nutzers
Das erste Spielerdropship ist das bereits bekannte exakte Cutlass-Modell. Die generischen oder vom Bildgenerator veränderten Schiffe in den Brückenbildern sind deshalb ausschließlich Stilbeispiele. Native Karten lesen jetzt die bestehende Rolle `dropship → cutlass_01` und zeigen ein direkt aus dem aktiven Ref03-GLB gerendertes transparentes PNG. Quelle/SHA und Renderbedingungen: `Assets/curated/ui_native_r4/cutlass_ref03_preview.json`. Originale Modellgeometrie und Materialien wurden nicht ersetzt. Eigene Namen und gespeicherte Craft-/Typ-IDs bleiben bestehen; Klassenbeschriftung und Bild sind reine UI-Projektion.
