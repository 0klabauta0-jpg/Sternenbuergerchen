# Native UI Design Contract · R1 / R2 / R3 / R4

Gültig für den vom Nutzer am 01.11.2026 beauftragten Umsetzungsschritt auf Basis der bestätigten UI-Konzepte. Die Bilder bestimmen Formsprache und Gruppierung; bestehende Runtime-/Datenverträge bestimmen Inhalt und erlaubte Aktionen.

## Gestaltungsautorität / Fortschreibung 02.11.2026
- Aktuelle Nutzeranweisungen und die zuletzt bestätigten Original-2D-Ziele bestimmen die Gestaltung. Für diese UI-Familie sind das `menu_fob_loadout.png`, `menu_heimatbasis.png`, `menu_debrief.png` und `mockup_a5_mission_zweireihig.png` unter `docs/reports/assets/ui-2026-11-01/`. Spätere Brückenbilder und native Zwischenstände ersetzen diese Ziele nicht.
- Frühere Pixelwerte, schlichte Rahmen, Portraitgrößen und Bühnenanteile beschreiben den Ausgangsstand R1–R4. Sie sind keine unveränderlichen Stilgrenzen. Referenzgeführte Anpassungen sind nach echtem Bildvergleich zulässig; kompakte quadratische Aktionen mit Innenbeschriftung, zwei Reihen, Lesbarkeit und erreichbare bestehende Funktionen bleiben Ziel.
- Echte native Controls und Texte dürfen dekorative Rasterelemente, Nine-Patch-Rahmen und mehrschichtige Flächen erhalten. Kein Vollbildmockup mit unsichtbaren Buttons: Fokus, Hover, Disabled, Layout und Eingabe bleiben an den tatsächlichen Controls nachvollziehbar. Zustandsbesitz, IDs und Callback-Gates bleiben unverändert.
- Dokumentaudit vor erneutem Engine-/2D-Bildvergleich, danach eine begrenzte visuelle Runde; siehe `docs/tasks/UI_2026_11_02_zielbild_abgleich.md`. Ein technischer Strukturcheck ist keine gestalterische Nutzerabnahme.

## Gemeinsame Sprache
- Aktuelle Petrolflächen `071f29` / `102f3b`, gewählte Fläche `092630`; die frühe graue R1-Palette ist historisch.
- Creme-Haupttext `f4f2e9`, Nebeninformation `a8c0ca`; kein dunkler Text auf dunkler Fläche.
- Cyan `29e1e7`: Interaktion/primäre Aktion. Gelb `ffd348`: ausgewählter Datensatz oder Team. Fokus erhält eine sichtbare eigene Kontur; Auswahl, Hover und Fokus bleiben unterscheidbar.
- Statusfarben ergänzen Text/Form. Normaler Transit ist kein Fehlerzustand.
- Ausgangsstand: 8px-Basisabstand, schmale einheitliche Rahmen, kleine Eckradien, zurückhaltender Schatten. Rahmenprofil, Ebenen und Abstände werden am zugeordneten 2D-Ziel geprüft; native StyleBoxes und dekorative Raster-/Nine-Patch-Elemente dürfen gemeinsam verwendet werden.
- Gemeinsame Regeln in `TacticalUITheme`, bestehende `MetaUISkin` delegiert/übersetzt. Keine zweite Theme- oder Gameplay-Architektur.

## Öffentliche Darstellungs-API
- `TacticalUITheme.get_theme() -> Theme`: wiederverwendetes natives Theme für vererbende Controls/Popups.
- `TacticalUITheme.apply_screen(root: Control) -> void`: Theme am UI-Root anwenden, bei Bedarf einmalige optische Vorbereitung; niemals pro Frame SceneTree durchsuchen.
- Bestehende `style_card`, `style_command_button`, `style_label`, `style_progress_bar` bleiben kompatibel.
- `TacticalUITheme.style_action_tile(button: Button, selected: bool = false, primary: bool = false) -> void`: kompakte quadratische Missionsaktionen, vorhandenen Zustand ausschließlich anzeigen.
- Screenfamilien können erforderliche kleine Textgrößen/Abstände setzen. Neue pauschale Mindestgrößen dürfen bestehende Controls nicht unbemerkt aus Panels drücken.
- `TacticalUITheme.decorate_panel(control, variant, selected)` bindet passive Rahmenzeichnung an vorhandene Controls. Sie verändert keine Eingabeflächen, Mindestgrößen, Containerkinder oder Zustandsbesitzer.

## Zielbildrunde 02.11.2026
- Nach dem Dokumentaudit Originale und native Ausgangsbilder direkt vergleichen. Der aktuelle Umsetzungsschritt verwendet 52px-Aktionen in zwei Reihen und ein 128px-Randband mit engerem Ziel-/Teamblock. Diese Maße sind ein geprüfter Zwischenstand, keine neue unveränderliche Stilgrenze.
- Gemeinsame gestufte Rahmen und abgesetzte Köpfe betonen vorhandene Arbeitsbereiche; transparente Missionsbandmodule behalten ihre Divider. Normale kompakte Personenkarten gewichten Namen mit 14px stärker; explizite kleine Pilot-/Spezialslots behalten ihre eigenen Werte.
- Das Protokoll verwendet dieselbe Petrolfamilie. Die Hexkanten der festen GM01 erhalten einen dunklen Rand und einen warmen hellen Kern. Kartenfakten, Maskenmodus, Gegnerfilter und aktuelle Cutlass-Bytes ändern sich dadurch nicht.
- Die weiterhin vereinfachten Gebäude, Felsstaffelung, heterogenen Pixelportraits und entfernten Bühnenausschnitte bleiben ausdrücklich offene Abstände zum 2D-Ziel. Eine Rahmenrunde ist keine vollständige Zielbildabnahme.

## Mission
- Band beginnt an der linken unteren Viewportkante; Aktionen in zwei sichtbaren Reihen. Ziel/Auftrag als eigener nächster Block; danach Teamheader und Haltung/Feuerregeln.
- Bisherige native Referenzgröße: Aktionstasten64×64 bei1920×1080, Abstand4–8px, Text innen. Die50–52px im Generatorbrief waren Rasterziele. Keine dieser Zahlen ersetzt die Prüfung von Zielnähe, Kompaktheit und lesbarer Innenbeschriftung im tatsächlichen Viewport.
- Keine aktive leere Reservekachel. Kontextaktionen wie Türsturm bleiben nur im richtigen Kontext erreichbar. Alle bestehenden Feuerregeln und Planwerkzeuge bleiben bedienbar. GO führt aus, keine Pause.
- Teamkarten und Protokoll liegen vollständig über dem Band. Missionsziel und Transport/LZ bleiben oben rechts. Keine Titelillustration oben links.
- Layoutänderung verändert keine Commands, Zustandsbesitzer, Callback-Gates oder Feindinformation.

## Weitere Screenfamilien
- Hauptmenü, Bibliothek und Creator behalten Aktivieren/Bearbeiten/Löschen/Speichern/Laden sowie bestehende Bestätigungen.
- Heimatbasis/FOB: Zuweisung, Pilot, Kapazität, Boarding und Transit stammen aus denselben bestehenden IDs/Owners. Keine Bildbeispielzahlen übernehmen.
- Kompaktkarten zeigen Identität und Zustand; der volle Bogen liest Daten. Nur der vorgesehene Creator bietet Metrik-/Budgetbearbeitung.
- Lobby: verbunden, bereit, Karte angenommen und Startfreigabe bleiben getrennt. Settings-Hilfe erfindet kein Rebinding. Escape pausiert nicht.
- Editor behält Authoring-Funktionen und Wertebereiche (Deckung 0–100). Kein impliziter Rasterwechsel allein durch Bildreferenzen. Der anschließend ausdrücklich beauftragte aktuelle GM01-Stand ist48×48Hex nach `gm01_frontier_map_contract.md`; dessen feste Layout-ID besitzt die dort dokumentierten Authoring-Grenzen.

## Nachweis
Native Strukturchecks prüfen Controls, Quadrate, Positionen, Erreichbarkeit und Zustandsgrenzen. Echte nicht-headless Viewport-Captures prüfen das gerenderte Ergebnis. Kein simuliertes Capture-/Ersatzboard gilt als Bildbeleg. Menschliche Verständlichkeitsprüfung bleibt offen.

## Verdichtung R2
- R2-Ausgangsstand der Mission: Randband höchstens160px hoch, Teamparameter als begrenzte Gruppe bis560px; Mitgliederstreifen höchstens112px, Aktionstasten64px. Anpassungen an bestätigte 2D-Ziele bleiben kompakt, lesbar und quadratisch; lange Diagnose erhält einen erreichbaren Detailpfad.
- Haltung verwendet verständliche volle Wörter. Ein nativer Feuerregel-Selektor delegiert an dieselben vorhandenen Buttons/Callbacks und übernimmt deren Sperren. Die Anzeige folgt dem bestätigten Konsens; Pending-, Gemischt- und Leerzustand dürfen keine erfolgreiche Änderung vortäuschen.
- Löschziel-/Ordnungsmarkierungen lesen den bestehenden Controllerzustand, nicht `button_pressed` eines gewöhnlichen Aktionsbuttons.
- Heimatbasis/FOB priorisieren drei Arbeitsbereiche. Briefingdetails sind explizit erreichbar. Eine Person oder ein Team kann seinen Arbeitsort wechseln; eine zweite bearbeitbare Zuordnungsinstanz entsteht dadurch nicht.
- Nachbesprechung gliedert vorhandene Resultate in Karten. Fehlende Gesundheit, Entwicklung oder Ereignisse bleiben als fehlend erkennbar; keine erfundenen Auszeichnungen, Zeitstempel oder Kennzahlen.
- Settings zeigen Audiokanal und aktuellen Entwurfswert. Abbrechen speichert diesen Entwurf nicht. Bibliotheksauswahl behält Controls und Tastaturfokus; ein bloßer Auswahlwechsel baut nicht die ganze Liste neu.
- Lobby hält Verbindungs-/Sitzungsaktionen außerhalb des scrollbaren Setupkörpers. Host-, Client-, Bereitschafts- und Kartenannahmegates bleiben unverändert. Verschobene Setuptexte behalten Kontexthilfe; die vorhandene Payload-Netzwerklücke wird dadurch nicht als behoben ausgegeben.
- Die FOB-Teamkontextzeile aktualisiert sich am bestehenden Zustandsrefresh, auch bei reinem Fokuswechsel ohne Größenänderung. Mindestgrößensignale sind keine State-Änderungsquelle.
- R2-Captures bei 1280×720 verwenden ausdrücklich auch diese logische Viewportgröße. R1-Bildskalierung wird nicht rückwirkend als kleiner Reflow ausgegeben.
- Die Roster-Prüfung folgt dem bestehenden effektiven 0..1-Wertevertrag nach Traits, siehe `character_roster_generation_contract.md`. UI-Save-Fixtures dürfen gültige problematische Werte nicht neutralisieren.

## Verdichtung und Klarheit R3
- Leere Arbeitsorte erhalten kurze native Karten statt voller Listenhöhe. Sichtbare Belegung darf die vorhandenen Bereiche bis zur verfügbaren Höhe wachsen lassen; bei vielen Einträgen wird echt gescrollt. Dropziele, Add-/Auswahlaktionen und Ortszuordnung bleiben vorhanden. Inhaltssignaturen reagieren auf Belegung/Viewport, nicht auf jeden Fortschrittswert.
- Heimatbasis: leere Truppfläche bis 168px, leerer Transport bis 192px. Kompakte Briefingdetails sind vollständig gefaltet; verspätete Hinweise bleiben erhalten und nach explizitem Öffnen lesbar. Schiffskartenspalten passen sich der tatsächlichen Breite an.
- FOB: ohne Transport kurze Flugdeck-/Einschiffhinweise, leerer ausgelagerter Teamort bis 144px. Ausrüstungsarbeit rückt entsprechend nach oben. Bestehende Boarding-/Transportgates ändern sich dadurch nicht.
- Der Debrief wird aus tatsächlicher nativer Mindestgröße und Viewport begrenzt zentriert. Wenige Daten strecken keine leeren Auswertungs-/Ereigniskarten auf volle Höhe; viele Personen/AAR-Zeilen haben native Scrollflächen. Vollständige ursprüngliche Resultate bleiben in einem lesenden Originalbericht zugänglich.
- Fehlende Zeit, Zielangaben, Gesundheit oder Awardwerte sind unbekannt/nicht angegeben. Sie werden nicht als gemessene Null oder negatives Ergebnis ausgegeben. Bestätigte Entwicklung erfordert den bestehenden angewandten/read-only Resolververtrag; Vorschau bleibt ausdrücklich Vorschau.
- Der Originalbericht blockiert Maus und Tastatur gegenüber darunter liegenden Aktionen. Tab/Shift-Tab bleiben im Detailbereich; Enter/Schließen/Hide/Rückweg stellen GUI-Einstellungen wieder her. Keine Änderung von Gameplaygates oder Pausenzustand.
- Primäre Missionsanzeigen projizieren vorhandene Objective-, Routen-, Transport- und Planwerte. Ausstehende Anfragen bleiben ausstehend. Laufende Befehle lesen vorhandene Ausführungs-Owners und verlangen keinen erneuten GO-Start. Abgeschlossene leere Rückflüge verwenden denselben Abschlussfilter wie die bestehende Schiffskarte; aktive Abflüge bleiben enthalten.
- Legacy-Rohtexte und v1-Diagnoseformate bleiben getrennt von sichtbaren Spielerlabels erhalten. Haltungswörter und mindestens 13px-Schrift werden auch nach echten Lightrefreshes restauriert. Die Restaurierung durchsucht nur bekannte Controls und schreibt keine Layoutrects.
- Zahlen in Auswertungs-Chips stehen sichtbar vor gegebenenfalls gekürzter Beschreibung. Tatsächliche Contentbreite und Fontbreite müssen den vollständigen Wert aufnehmen; der volle Kontext ist per Tooltip erreichbar. Keine kleinere Schrift als Platzersatz.
- Separat platzierte Debrief-Controls folgen ihren nativen Slots auch nach reinen Bewegungen übergeordneter Container. Die begrenzte Ancestorkette wird einmal beim Aufbau signalgebunden, nicht pro Frame durchsucht. Rückwegzeile und Slot müssen nach Layoutabschluss übereinstimmen und vollständig in der Rückwegkarte liegen.

## Visuelle Referenznähe R4
- Die finale 2D-Menüfamilie und A5 bleiben visuelle Grundlage. Neue Brückenbilder erklären Übersetzung; ihre Beispielgesichter, Enable-Zustände und Szenen sind keine Runtimeautorität.
- R4 überschreibt die frühe graue Palette: Petrol `071f29`/`102f3b`, dunkel gewählte Fläche `092630`, Cyanrahmen `2e7b8a`, Interaktion `29e1e7`, Auswahl `ffd348`, Creme-Schrift `f4f2e9`, Nebeninformation `a8c0ca`. Cremefarbene Modulgehäuse gehören zur Illustration, UI-Panels bleiben dunkel.
- Abschnitt und Identität erhalten die gebündelte Barlow Condensed Bold (SIL-OFL, Quelle/Hash/Lizenz unter `Assets/curated/ui_native_r4/`). Körper-/Buttonschrift und64px-Aktionen sind der R4-Ausgangsstand; die zugeordnete 2D-Vorlage bestimmt die nächste Form-/Typografieprüfung. Große Überschriften dürfen native Breiten nicht erzwingen; lange Leerzustände umbrechen. Lesbarkeit nicht durch kleinere Schrift als Platzersatz umgehen.
- Heimatbasis/FOB zeigen im R4-Ausgangsstand den kuratierten Main-Außenposten im tatsächlich freien rechten Bereich. Anteil und Platzierung der Bühne dürfen anhand der 2D-Ziele überarbeitet werden. Sie bleibt input-ignore/visual_only; Zuordnungs-/Transportwege müssen auch bei Platzmangel vollständig erreichbar bleiben. Debrief hat eine eigene explizite Frontier-Hintergrundebene, ohne alte Katalogsnapshotfelder umzudeuten.
- MetaFlow ergänzt vorhandene Portraitpfade in Ergebnis-Personendaten ausschließlich über denselben bestehenden Unit-/Rosterlookup. Keine zufälligen Ersatzgesichter aus Bildtafeln. Bisherige kompakte Portraitgrößen38px beziehungsweise bis36px in Missions-Teamreihen sind Ausgangswerte. Eine referenzgeführte Größenänderung muss echte Identität, Kompaktheit, Lesbarkeit und belegte Controls erhalten.
- Das Missionsband erhält eine eigene passive deckende Oberfläche, weil der vorhandene BottomDock ein Control ist. Hintergrund und Module nutzen dieselben berechneten Layoutgrenzen (R4-Ausgangsstand160px); kein neuer per-frame Geometriepfad und keine veränderten Input-/Sichtbarkeitsregeln.
- Neutrale Ergebnis-/AAR-Chips verwenden dunkle Flächen mit heller Schrift; gefüllte semantische Chips verwenden dunkle Schrift. Werte bleiben sichtbar vorne, Originalkontext erreichbar.
- Historische R4-Basis: Main `7f594530f` lieferte die damalige Square8-GM01 und Ref03-Schiffe. Der aktuelle Task-Stand verwendet die ausdrücklich beauftragte GM01 mit48×48Hex nach `gm01_frontier_map_contract.md`; daraus folgt keine Mainintegration. Die tatsächliche normale Start-/Transport-/LZ-/GO-Route und Fixture-Renderbilder werden separat gekennzeichnet und geprüft.

- Nutzerpräzisierung Cutlass: Das erste Spielerdropship projiziert Klasse und statische UI-Vorschau aus derselben bestehenden Visualrolle wie das aktive Ref03-Modell. Kein neuer Crafttyp, keine Umbenennung gespeicherter Namen/IDs und keine Bild-KI-Neuinterpretation. Die Vorschau ist ein nativer transparenter Render exakt dieser GLB-Bytes; aktuelle Quelle und SHA stehen daneben. Homebase wählt 94×62 / Position 0 vor dem ersten Größenwrite, damit kein alter Speeder-Minimumcache/Crop die Silhouette abschneidet. FOB und Missionskarten behalten die ganze Silhouette. Welt-Richtungssprites bleiben vom UI-Preview getrennt.
- Bei kleiner Viewporthöhe bleibt das Protokoll unter der einzelnen Transportkarte:1280×720 Log y344–440/Höhe96, FullHD unverändert. Gleicher nativer Scroll, gleiche Schrift und Eingabe; reine Rectberechnung ohne Runtime-State.
