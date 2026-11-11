# Editor: explizite Hex-Rampen und Plateaus

## Ziel / Ursache
Vom Nutzer bestaetigte gerichtete Hex-Rampen muessen im Editor bearbeitbar
sein. Manuelle Undo- und Gebaeude-Untergrundfelder lassen neue Rampenfelder
sonst fallen; alte Viernachbar-Huegelkorrektur darf neue Hexkarten nicht umbauen.

## Basis / Vertraege
Isolierter task/native-glut-maps-20261110 auf e55206832 plus aktuelle
Rampenruntime/Kompositions-WIP. explicit_hex_ramps_contract.md,
terrain_truth_visual_audit_contract.md, PROJECT_BRIEF/ARCHITECTURE/CODEX_RULES.

## Umfang / Nicht-Ziele
Nur map_editor.gd, building_layout_authoring.gd und bei Bedarf kleiner
HeightToolhelper. Keine Runtime/View/Shader/Compiler/Kampfkern-Aenderung.
Neue UI nur fuer bereits explizit versionierte Hexkarten; keine stille
Migration alter Karten. Plateau/Rampe und6Richtungen als Hoehenpinselparameter,
Auswahl anwenden und Auswahlrotation +/-60Grad, vorhandene Patch-/Dirtypfade.
Undo/Redo halten die Rampendaten; Gebaeude auf Rampen werden abgelehnt.

## Akzeptanz / Schritte
- Neue Controls fuer explizite Karten, H ist untere Rampenhoehe (max7).
- Breiter Hex-Hoehenpinsel und Mehrfachauswahl erhalten eigene Richtungen;
  Objektrotation wird fuer Terrain nie verwendet.
- Patch und manuelle Snapshots/Undo konservieren bool, regional_grade, Richtung.
- Alte Autoedge-/Cliff-Reconcilepfade in expliziten Karten auslassen.
- Gebaeude-Untergrundliste erhaelt Rampendaten, Rampenbau wird abgewiesen.
- Enges check-only und kleiner Datenfixture, keine grossen/nativen Tests.

## Risiken / spaeter
Vollstaendige Editor-Klick-/Layoutmatrix, Save-/Netzspiel-/Gefechtsrunden spaeter.
Der Altstand besitzt nur Undo, keinen Redo-Pfad; fuer die neuen Bearbeitungen
wird ein begrenzter inverser Tile-Transaktionspfad ergaenzt, der alte Tiles
und Gebaeude-Untergrundmetadaten ueber dieselben Owner wiederherstellt.


## Ergebnis
Implementiert, kleiner Editorfixture19/0 und finales check-only0 ohne
Warnungen/Fehler. Dateien map_editor.gd, map_editor_height_tool.gd,
building_layout_authoring.gd und explicit_hex_ramp_editor_test.gd.
QA docs/qa/explicit_hex_ramp_editor_20261111. MapData unveraendert;
kein Commit/Push und keine native/grosse Testmatrix durch Teilagent.


## Ergaenzung: echte Hoehenpinselvorschau / 2026-11-11
Problem: 3D deaktivierte den generischen Spritehover; Hoehenwerkzeug wurde nicht
als Preview-Anlass eingeplant. Ziel ist ein nichtmutierender 3D-Geisterumriss der
geplanten Plateau-/Rampenflaechen mit Hexradius, Richtung und geplanter Hoehe.
Gemeinsame HeightTool-Patchplanung und RegionalHexSurface.profile verwenden;
begrenzte Tilekopien plus Nachbarschaft, bestehender View-WorldRoot, keine
Registrywrites/Pickkollisionen. Hover/Parameter/Dirtywechsel erneuern, UI/Tool/
Mapwechsel verbergen. Legacy unveraendert. Betroffene Dateien map_editor.gd,
map_editor_height_tool.gd, neuer map_editor_height_preview.gd und kleiner Verifier.
Nur Compile und enge Vorschau-Datenprobe; native Maus-/Kamerapruefung spaeter.

Breiter Raise/Lower-Stroke: auf expliziten Karten wird jede Zielzelle pro
Transaktion einmal bearbeitet. Visited-Fakten werden bei Begin/Commit/Cancel,
Tool-/Mapwechsel verworfen; die Vorschau zeigt besuchte Zellen unveraendert.
Legacy-Pinselverhalten bleibt erhalten. Enger Zwei-Mittelpunkte-Overlap-Check
mit einem Undo/Redo prueft diesen konkreten Fehler.

UI-Lifecycle: passiver _input-Beobachter sieht Release vor STOP-Controls, beendet
nur den expliziten Hoehenstroke und konsumiert keine GUI-Events. UI-Hover verbirgt
den Ghost deferred nach GUI-Hoveraufloesung. Root aktualisiert parallel die drei
zugehoerigen Eintraege in data/contextual_help_catalog.json (Root-Dateibesitz).

Root-Reviewkorrektur: _pick_regional_surface in terrain_map_3d_view.gd verwendete noch H statt H+.5 als Rampenzentrum, waehrend Rendercap und Vorschau stand_height lesen. Derselbe Standhoehenhelper muss auch die Ray-Pickflaeche tragen; enges Viewfix innerhalb Editor-Hover/Klickauftrag, kein Terrain-/Sichtregelumbau.
