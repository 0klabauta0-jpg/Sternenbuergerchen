# Native UI Design Contract · R1 / R2 / R3

Gültig für den vom Nutzer am 01.11.2026 beauftragten Umsetzungsschritt auf Basis der bestätigten UI-Konzepte. Die Bilder bestimmen Formsprache und Gruppierung; bestehende Runtime-/Datenverträge bestimmen Inhalt und erlaubte Aktionen.

## Gemeinsame Sprache
- Dunkle matte Flächen `151c21` / `252d33`, tiefer Hintergrund `0c1114`.
- Haupttext `edf3f6`, Nebeninformation `a9b4bc`; kein dunkler Text auf dunkler Fläche.
- Cyan `63d1d2`: Interaktion/primäre Aktion. Gelb `f2c94c`: ausgewählter Datensatz oder Team. Fokus erhält eine sichtbare eigene Kontur; Auswahl, Hover und Fokus bleiben unterscheidbar.
- Statusfarben ergänzen Text/Form. Normaler Transit ist kein Fehlerzustand.
- 8px-Basisabstand, schmale einheitliche Rahmen, kleine Eckradien, zurückhaltender Schatten. Native StyleBoxes statt gerasterter Vollbildrahmen.
- Gemeinsame Regeln in `TacticalUITheme`, bestehende `MetaUISkin` delegiert/übersetzt. Keine zweite Theme- oder Gameplay-Architektur.

## Öffentliche Darstellungs-API
- `TacticalUITheme.get_theme() -> Theme`: wiederverwendetes natives Theme für vererbende Controls/Popups.
- `TacticalUITheme.apply_screen(root: Control) -> void`: Theme am UI-Root anwenden, bei Bedarf einmalige optische Vorbereitung; niemals pro Frame SceneTree durchsuchen.
- Bestehende `style_card`, `style_command_button`, `style_label`, `style_progress_bar` bleiben kompatibel.
- `TacticalUITheme.style_action_tile(button: Button, selected: bool = false, primary: bool = false) -> void`: kompakte quadratische Missionsaktionen, vorhandenen Zustand ausschließlich anzeigen.
- Screenfamilien können erforderliche kleine Textgrößen/Abstände setzen. Neue pauschale Mindestgrößen dürfen bestehende Controls nicht unbemerkt aus Panels drücken.

## Mission
- Band beginnt an der linken unteren Viewportkante; Aktionen in zwei sichtbaren Reihen. Ziel/Auftrag als eigener nächster Block; danach Teamheader und Haltung/Feuerregeln.
- Native Referenzgröße für Aktionstasten 64×64 bei 1920×1080, Abstand 4–8px, Text innen. Die 50–52px im Generatorbrief waren Rasterziele, keine verbindlichen Laufzeitmaße.
- Keine aktive leere Reservekachel. Kontextaktionen wie Türsturm bleiben nur im richtigen Kontext erreichbar. Alle bestehenden Feuerregeln und Planwerkzeuge bleiben bedienbar. GO führt aus, keine Pause.
- Teamkarten und Protokoll liegen vollständig über dem Band. Missionsziel und Transport/LZ bleiben oben rechts. Keine Titelillustration oben links.
- Layoutänderung verändert keine Commands, Zustandsbesitzer, Callback-Gates oder Feindinformation.

## Weitere Screenfamilien
- Hauptmenü, Bibliothek und Creator behalten Aktivieren/Bearbeiten/Löschen/Speichern/Laden sowie bestehende Bestätigungen.
- Heimatbasis/FOB: Zuweisung, Pilot, Kapazität, Boarding und Transit stammen aus denselben bestehenden IDs/Owners. Keine Bildbeispielzahlen übernehmen.
- Kompaktkarten zeigen Identität und Zustand; der volle Bogen liest Daten. Nur der vorgesehene Creator bietet Metrik-/Budgetbearbeitung.
- Lobby: verbunden, bereit, Karte angenommen und Startfreigabe bleiben getrennt. Settings-Hilfe erfindet kein Rebinding. Escape pausiert nicht.
- Editor behält Authoring-Funktionen und Wertebereiche (Deckung 0–100). Kein Rasterwechsel durch Bildreferenzen.

## Nachweis
Native Strukturchecks prüfen Controls, Quadrate, Positionen, Erreichbarkeit und Zustandsgrenzen. Echte nicht-headless Viewport-Captures prüfen das gerenderte Ergebnis. Kein simuliertes Capture-/Ersatzboard gilt als Bildbeleg. Menschliche Verständlichkeitsprüfung bleibt offen.

## Verdichtung R2
- Mission: Randband höchstens 160px hoch, Teamparameter als begrenzte Gruppe bis 560px; Mitgliederstreifen höchstens 112px. 64px-Aktionstasten bleiben lesbar und quadratisch. Lange Diagnose erhält einen erreichbaren Detailpfad.
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
