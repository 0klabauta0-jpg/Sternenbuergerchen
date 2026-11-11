# Editor: explizite Hex-Rampen

Isolierter task/native-glut-maps-20261110 auf aktueller Rampengrundlage;
kein Commit/Push durch Teilagent, keine Main-/EXE-Freigabe.

## Sichtbare Bedienung
Auf bereits versionierten explicit_hex_ramps_v1-Hexkarten erscheint direkt
unter der Hoehe ein Terrainbereich: Plateau/Rampe, sechs Aufwaertsrichtungen,
Auf Auswahl anwenden und Auswahl +/-60Grad drehen. H bezeichnet die untere
Rampenhoehe. Der Hoehenpinsel verwendet seinen bestehenden Modus Anheben,
Absenken oder exakt H=0..8; Rampen werden auf untereH7 begrenzt.

Ohne bewusste Formwahl veraendert blosses Anheben/Absenken die vorhandene
Rampenrichtung nicht. Die bewusste Formwahl wird als Pinselparameter gehalten.
Ein Radius1-Hoehenpinsel schreibt7Hexzellen, nicht die9Zellen des alten
Quadratpinsels. Mehrfachauswahl kann gemeinsam angewendet/gedreht werden.
Objektrotation wird dabei nie verwendet. Vorschau/Darstellung bleibt bei der
vorhandenen Root-View, kein separater Terrain-Visualowner.

Legacykarten werden nicht konvertiert und behalten ihre bisherigen Controls.
Die neue Autorierung setzt ein bereits versioniertes Dokument voraus;
es gibt hier bewusst keinen stillen Konvertierungsbutton oder MapData-Mutator.

## Daten und Historie
Patch, Kontext und Undo konservieren ramp_direction, explicit_hex_ramps und
regional_grade. Fuer explizite Karten nutzt Redo inverse Tiletransaktionen,
inklusive Gebaeude-Untergrunddaten und Auswahl; Strg+Umschalt+Z und sichtbarer
Wiederholen-Button. Neue Aenderungen leeren die Redohistorie. Legacy-Undo bleibt
im bisherigen Modus ohne behaupteten neuen Legacy-Redo-Vertrag.

Viernachbar-Huegel-Reconciliation und alte Cliff-Overlay-Erzeugung werden bei
expliziten Karten ausgelassen. Der bestehende Registry-notify-Pfad entwertet
abgeleitete Navigation. Keine neue Registry-Mutation und keine Kartenregel im UI.
BuildingLayoutAuthoring konserviert Rampenfelder im Untergrund und lehnt
Gebaeudebau auf jeder Rampenzelle des Footprints ab, auch bei gleicher untererH.

## Enge lokale Pruefung
Godot4.6.2 headless, private APPDATA unter output/native_glut_maps.
Ein kleiner tatsaechlicher Editor-SceneFixture mit256Zellen besteht19/0;
finales check-only exit0. Keine Engine-/Scriptfehler oder Warnungen in den
akzeptierten Logs. Geprueft: sichtbare Apply-/Richtungs-/Rotatecontrols,
Mehrfachauswahl/Transaktion/Revision, Richtungserhalt, Undo/Redo/Selektion,
H8-Guard, Reconcile-Sperre, Gebaeude-Untergrund/Rampenabweisung,7Hex-Pinsel,
Save/Reload und Legacy ohne Konversion. Kein GPU/Native-/Gefechts-/Benchmarklauf.

Grosse Editor-Klick-/Layoutmatrix, durchgehende breite Kurven in A/B/C,
Transport-/Gebaeude-Neuplaetze, Savevarianten und allgemeine Regressionen
bleiben auf Nutzerwunsch spaeter. Diese kleinen Checks sind keine vollstaendige
Editor-, Multiplayer- oder Framerateabnahme.
