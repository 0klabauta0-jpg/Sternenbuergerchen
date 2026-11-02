# R3 · Befunde, Gründe und Nachweisgrenzen

## Sichtbar überarbeitete Ursachen
- Inhaltsunabhängige Vollhöhen reservierten leere Team-/Transportflächen. R3 verwendet vorhandene Belegung für kurze leere Arbeitsorte und größer werdende belegte Listen. Dropziele und bestehende Aktionen bleiben erhalten; keine Füllbilder oder erfundenen Personen.
- Der kompakte Basisbriefingkopf zeigte einen angeschnittenen Detailrahmen. Details werden nun bewusst gefaltet; verspätete Personal-/Ergebnishinweise bleiben gespeichert und nach explizitem Öffnen lesbar.
- Bei mehreren Schiffen war die zweite Kartenbreite in 1280×720 nicht immer sichtbar. Die vorhandene Schiffsliste verwendet passende Spalten und bei vielen Karten echten vertikalen Scroll.
- Die Mission stellte Rohblöcke mit internen Nummern, Host-/NPC-/LZ-Codes und allgemeinem „Route prüfen“ in den Vordergrund. Eine reine Projektion vorhandener Objective-/Transport-/Planwerte liefert kurze Spieleranzeigen. Vollständige Quellen bleiben in Details.
- Geplante und bereits laufende Befehle waren im neuen Kurztext zunächst nicht getrennt. Die Darstellung liest nun bestehende Ausführungs-Owners; GO setzt weiterhin denselben Runtimepfad in Gang.

## Unabhängige Gegenprüfung
Ein frischer Reviewer ohne übernommenen Chatkontext hat den Diff gegen `b1342b939` auf aktuelle State-/Callback-/Eingabegrenzen geprüft. Zwei materielle Befunde wurden gegen bestehende Quellen und RED-Verifier bestätigt:

1. **Abgeschlossener Rückflug:** Der neue Kurzstatus zählte eine alte leere Rückflugkarte weiter. Er nutzt jetzt den vorhandenen Abschlussfilter mit ausdrücklich deaktiviertem Kontaktfokus. Aktive Abflüge bleiben erhalten. RED: acht Fehler bei 86 Checks; nach Anschluss war der Fall im gemeinsamen Missionslauf grün.
2. **Teilbericht:** Fehlende Zeit und fehlender Zielstatus wurden aus alten Defaults als gemessene Null bzw. negatives Ergebnis dargestellt. Die Primäranzeige muss stattdessen die Feldabwesenheit ausdrücklich benennen. Die ergänzte Teilbericht-Fixture enthält außerdem unbekannte Gesundheit und eine nicht angewandte Award-Vorschau; diese darf keine bestätigten EP erzeugen.

Beim zentralen Debrief-Test wurden zusätzlich ein tatsächlicher Mausklick durch das geöffnete Originalbericht-Overlay und fehlende Tab-/Shift-Tab-Abgrenzung reproduziert. Beide Eingabepfade und die knappe 1280-Sparsehöhe sind korrigiert. Das Overlay schränkt die zugrunde liegende GUI temporär ein und stellt sie exakt wieder her; Gameplaygates bleiben unverändert. Teilbericht-/Eingabefälle liefen danach mit 268 bestandenen Assertions ohne Fehler.

Die native Bildprüfung bestätigte drei weitere konkrete Darstellungsfehler, die anschließend mit vorher scheiternden Regressionen behoben wurden:
- Hintergrund-Lightrefreshes setzten die Haltung auf kleine Kürzel zurück. Die bekannte Haltungsgruppe erhält nun ihre vollständigen Wörter und ursprüngliche Schriftgröße zurück, ohne Layoutschreibzugriffe oder neuen Baumscan. Missions-R3: 92/92.
- Eigenbeschuss-/Unterdrückungs-Chips schnitten ihre Zahlen ab. Der vollständige Wert steht jetzt vorne; der Tooltip erhält den ganzen Kontext. Die Prüfung verwendet tatsächliche Content-/Fontbreiten.
- Im umfangreichen Bericht stand die echte Rückwegzeile 21px unter ihrem Slot. Einmalige, deduplizierte Signale der begrenzten Control-Ancestorkette aktualisieren die bestehenden Top-Level-Controls auch bei reinen Panelverschiebungen. Kein Polling. Der deterministische Verschiebungsfall lief RED mit 342 bestanden/2 Fehlern und anschließend GREEN mit 344/0. Alle fünf erneuerten Debrief-Captures prüfen außerdem Row=Slot und vollständige Kartenumschließung anhand echter nativer Rects.

Die abschließende unabhängige Source-/Bildgegenprüfung bestätigte die sichtbaren Chipwerte, vollständig eingerahmten Rückwege und begrenzten Signalanschlüsse ohne weitere konkrete Regression. Der finale Einzelstatus steht ausschließlich in `VERIFIKATION.json`, nicht in einem älteren GREEN-/RED-Log. Abschluss: 19 gezielte Checks, 1.617 Assertions, 13 native Aufnahmen und 10 Offline-HTML-Prüfungen bestanden.

## Warum die Darstellung so aufgebaut ist
Weniger Leerraum entsteht durch kleinere leere Rahmen und nach Inhalt bemessene Ergebnisfenster. Häufig benötigte Werte bleiben vorne; rohe Diagnose bleibt auffindbar. Die Schrift wird nicht zum Platzersatz kleiner gemacht. Eine fehlende Meldung ist keine Erfolgsmeldung, ein geplanter Befehl keine laufende Ausführung, eine Vorschau keine bestätigte Entwicklung.

Die Daten bleiben bei vorhandenen Runtime-, Transport- und Fortschritts-Owners. Neue Summaryfelder sind sofort verwendete lesende Darstellungen. Layoutsignaturen reagieren auf Belegung und Viewport; Fortschrittswerte lösen keine fortlaufenden Baumrebuilds aus.

## Grenzen
Native Renderbilder belegen die tatsächliche Darstellung von Produktionscontrols. Die Eingabeverifier prüfen konkrete Maus-/Tastaturpfade, Owners und Callbacks; sie ersetzen keinen menschlichen vollständigen Durchspieltest. Empty/sparse/partial/rich sind ausdrücklich konstruierte Datenfixtures. Der umfangreiche Bericht stresst vorhandene Listen-/AAR-Verträge und behauptet keinen real durchgeführten Einsatz. Kein physischer Flugnachweis, kein Netzwerk-End-to-End, kein Release/EXE-Export und keine Langzeit-Performanceabnahme.

Die vorhandene Lobby-Kartenpayload-Netzwerklücke ist nicht Gegenstand dieses Passes. Alte R1-/R2-Bilder bleiben historische Vergleichsdaten. Die Konzept-Workbench erhält nur einen aktuellen Link; ihr JavaScript und ihre Export-/Notizfelder sind unverändert.
