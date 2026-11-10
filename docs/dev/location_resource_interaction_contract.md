# Ortsressourcen — begrenzter Mining-/Salvage-Slice

Stand 10.11.2026. Satellitenauftrag, Erzader und Wrack sind drei voneinander
unabhaengige Besuchsgruende. Nur die vorhandenen beiden Auftragssteps bestaetigen
den Satellitenauftrag; Ressourcenentnahme erfuellt keinen dieser Steps.

`data/singleplayer/location_resources.json` definiert stabile site_id, Ertrag,
Werkzeug, Dauer, Interaktionsradius und Entdeckungsradius. Erster Inhalt:
Erzader mit vier Erz, vier Sekunden und Miningwerkzeug; groesseres Wrack mit acht
Bergungsgut, sechs Sekunden und Bergungswerkzeug. Eine Entnahme leert jeweils
diese kleine Quelle. Das ist keine vollstaendige Berufssimulation.

SingleplayerSupplyState besitzt je Ort genau einen LocationRuntimeState fuer
Restbestaende, Entdeckungen und Ertragsbelege. Die lokale Szene benutzt denselben
Owner; Sicht-, Trupp- und Jobwechsel erzeugen keinen zweiten Vorrat. Supply speichert
diesen Zustand zusammen mit den Containern auch im sicheren Basischeckpoint.
Alte Saves ohne Ortsressourcen starten diese neuen Quellen erstmalig; bestehende
Items, Credits und Belege bleiben unveraendert. Neue Werkzeugangebote duerfen alte
unveraenderte Angebote ergaenzen; abweichende alte Preise/Definitionen bleiben
weiterhin ein Restorefehler.

Entdeckung erfolgt durch eine lebende tatsaechlich aktive lokale Person in
384 Welteinheiten bei freier Terrain-Sichtlinie. Vorher keine Ressourcenziele in
Auswahlliste, Weltlabels oder Ortsmarkern. Sichtbare Landschaft bleibt davon
unabhaengig. Ein entdecktes Vorkommen bleibt dem laufenden Spiel bekannt.

Anwendung benutzt den vorhandenen zeitgesteuerten Use-Befehl. Der Runtimepfad
prueft Person, lokalen Ort, Entdeckung, Distanz96, abgeschlossene Dauer und ein
echtes Werkzeug in ihrem Rucksack erneut vor dem Commit. Miningwerkzeug und
Bergungswerkzeug sind konkrete Inventaritems ohne eigene Kampf-/Ruestungswirkung.
Je eines liegt in der endlichen neuen Startausstattung; Nachkauf am Handel.

Ertrag geht in den Rucksack der ausfuehrenden Person. Vor Entnahme werden freie
Kapazitaet und Bestand geprueft. Volles Inventar, fehlendes Werkzeug oder Abbruch
verbrauchen nichts. Eine erfolgreiche Anfrage/Quelle liefert genau einmal.
Zum Umladen in ein gelandetes eigenes Schiff muss die Person physisch innerhalb
128 Welteinheiten am Schiff sein. Kein Basislagerzugriff vom fernen Ort und kein
Ferngriff auf andere Schiffe. Ausruestungstausch im Feld bleibt gesperrt, solange
der aktive Unit-Loadoutowner dafuer nicht angebunden ist; Transfers sind erlaubt.

Pruefung: Ertrag/Bestand zusammen erhalten, Retry und zweiter Besucher duplizieren
nichts, Kapazitaetsfehler unveraendert, Job unabhaengig, sicherer Checkpoint behaelt
Restbestand. Native getrennte Routen zeigen die drei Besuchsgruende.
