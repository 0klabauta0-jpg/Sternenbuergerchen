# Playtest: Details, Kontextcursor und Kamera

## Ziel / Ursache
NPC-Karten sollen per Doppelklick vollständige Details öffnen: lesbare Werte untereinander, Inventar rechts. Weltziele müssen die passende Aktion unter dem Mauszeiger zeigen (eigenes Schiff: Einsteigen; Satellit: Daten sichern; entdeckte Quelle: Abbauen/Bergen). Kamera am Mauszeiger zoomen, mittlere Taste verschiebt die Karte, flacherer isometrischer Blick.

## Umfang und Entscheidungen
Bestehende Godot-4.6.2-Owner und Commands wiederverwenden. UI/Cursor geben keine Spielbelege vor und erzeugen kein neues Lootsystem. Nur echte erreichbare/entdeckte Ziele anbieten; gesperrte Ziele mit Grund. Linke Auswahl und GO-Commandpfad bewahren, Kontextaktion per rechtem Klick anlegen; Basisaktionen benutzen vorhandenen Personnel-Owner. Kamerablick etwa isometrisch statt steil, Ausgangswert nach aktueller Projektion wählen. Weltpunkt unter Cursor beim Zoom auf fixer gewählter Bodenebene erhalten, kein Tile-Snap. Q/E-Drehung erhalten; MMB-Pan durchgängig bis Loslassen auch über UI, Fokusverlust beendet Drag. Sternkarte hat bereits Cursorzoom/Pan und wird nur bei nachgewiesener Lücke geändert.

## Quellen / Architektur
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, aktuelle IMPLEMENTATION_STATUS/ROADMAP; personnel_inventory_contract, mission_interaction_point_contract; CharacterSheetView/Formatter, HomebaseOperationsPresenter/HomebaseScreen, PersonnelInventoryPanel; TerrainMap3DView, MissionMapCameraController; vorhandene Snapshot-/Order-/Use-/Boardingpfade.

## Plan und Dateien
- [x] NPC-Details: Kartenkinder dürfen Doppelklick nicht verschlucken. CharacterSheetView: Ableitungen vertikal statt zusammengesetzter Zeile. Homebase-Popup: links Charakter, rechts vorhandenes endliches Inventarpanel; tatsächliche fokussierte Person und Zugriffsgrenzen.
- [x] Kamera: TerrainMap3DView erhält präzisen Cursorzoom und Bodenanker-Pan; MissionMapCameraController benutzt ihn und MMB-Pan statt Rotation. Basisinput verwendet dieselben Methoden. Zielorientierte Regressionen zu Cursoranker, Drag, Grenzen und Fokus.
- [x] Kontextcursor: abgeleitete Hoveraktion und lesbarer Aktionstext, deterministische Zielpriorität Schiff/gebundene Interaktion/entdeckte Ressource. Kein Vollscan im Hotpath, getakteter Refresh. Rechtsklick an Ziel benutzt existierenden Intent/Boardingweg. Unbekannte/gesperrte Ziele führen keine Aktion aus. Basis und Einsatz konsistent anbinden, bestehende UI-Eingaben nicht abfangen.
- [x] Gemeinsame gezielte Verifier, UI-/Kamera-/Inventar-/Interaktionsregressionen; Status/QA dokumentieren, Taskbranch committen/pushen. Kein automatischer Mainmerge/EXE-Ersatz in diesem Folgeauftrag.

## Akzeptanz / Prüfung
Doppelklick auf Portrait/Name/Kartenfläche öffnet richtige Person. Rechte Inventarseite liest echte Bestände/Loadout; gelagerte/unterwegs befindliche Person erhält denselben Ablehnungsgrund. Abgeleitete Werte wie Wahrnehmung und Disziplin untereinander. Cursor passt zu echtem Ziel und leert sich über HUD/bei Abwahl; Hover allein erteilt keinen Befehl. Bodenpunkt unter Cursor bleibt bei Zoom und Pan geometrisch stabil; keine Rotation bei MMB. Native Probe nach Bedarf; technische Checks ersetzen keine menschliche Stilabnahme.

## Risiken / offene Punkte
Kameraansicht ist subjektiv: Winkel als veränderbarer Startwert, keine Stilfreigabe behaupten. 'Sichern' kann Datenaufnahme oder Spielstand meinen; bestehende Basischeckpoints bleiben unverändert. Mehrort-Speichern und zukünftiges Loot sind keine Erweiterung dieses Pakets. Fremdes WIP im Ursprungsarbeitsbaum bleibt erhalten.

## Ergänzungen aus Screenshot / Folgefeedback
Rechte Schiff-/Versorgungsanzeige in der Basis nur bei ausdrücklich ausgewähltem Schiff oder geöffnetem Servicebereich. Linksklick wählt NPC/Schiff, Doppelklick NPC öffnet Details direkt in der Welt, leerer Linksklick wählt ab und löst keine Bewegung aus. Rechtsklick geht zum Boden/zur erlaubten Zielaktion. Lesbare Bildschirmbeschriftungen unabhängig vom Zoom, kein absichtliches Herunterrendern. Ein-/Abflugvorschau soll Landepad und echte Entermesser mit vorhandener Rampe zeigen; keine schwarze Fläche. Engerer Gebäudeabstand als eigener Authoringpunkt: Kollisions-/Innenraumnavigation nicht allein optisch versetzen.

## Flugdarstellung / Quellen
Vorhandenes Cutlass-Ref03-Mesh unverändert, vier an realen Düsen verankerte zweischichtige Abgasstrahlen ohne Drift der Düsenmündung. Gemeinsame rein visuelle Manöverkurve: erst anheben, dann vorwärts beschleunigen; Anflug bremst vor dem finalen senkrechten Aufsetzen ab. Bestehende Flug-/Boardingtimer und Payloadfakten bleiben unverändert. Native Vergleichsbilder und Test der glatten Endpunkte/Phasen. Erkul als datierte Referenz mit Einheiten sichern, keine stillschweigende Übernahme von Star-Citizen-Geschwindigkeiten in die kompakte Spielkarte.

## Abschlussbefund
Umsetzung und gezielte Quellprüfungen abgeschlossen; QA unter docs/qa/playtest_details_cursor_camera_20261110/. Unabhängige Reviewbefunde zu unsichtbarer Eingabe, Previewbeschriftung und Service-Schiffsauswahl korrigiert. Gebäudeabstand ausdrücklich eigener offener Authoring-Nachtrag. Kein neuer EXE-Export/Mainmerge im Folgeauftrag. Abschließend eigene Taskdateien committen/pushen, fremdes WIP erhalten.
