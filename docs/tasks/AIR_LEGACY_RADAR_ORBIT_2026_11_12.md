# Luftunterstützung auf regulären Bodenkarten

## Ziel und Ursache

Ab Main `95abade90` soll die vorhandene Cutlass mit echtem Flugowner in der
regulären Satellitenmission starten, fliegen, feuern, zurückkehren und landen.
Die reale Karte verwendet Hexgeometrie, aber den Legacy-Bodenowner; der
bisherige Luftpfad verlangt `hex_tactical_v1` und meldet `ground_unavailable`.
Das private Hex-Opt-in soll ebenfalls einen echten Rückweg ermöglichen.

## Umfang und Grenzen

Bestehende Fleet-, Flight-, Wing-, Combat-, Transport- und Bodenowner nutzen;
keine Produktionskarte still auf einen anderen Bodenmodus schalten. Radar
erfasst im Raum und auf Bodenkarten Luftziele; Bodenfeuer behält Bodensicht.
Der bestätigte automatische Orbitdurchflug und seine Abschaltung gehören zum
Auftrag. Companion besitzt Mission-Save/Continue und integriert Main;
Save-/Restore-Methoden und gemeinsame Dateien nur nach Abstimmung verbinden.
Keine EXE durch diesen Task.

## Akzeptanz und Prüfung

Regulärer Missionsstart und physisches Boarding, Start, Bewegung, sicht- und
waffengeprüftes Feuer, Rückflug, Landung und Boarding mit realen Identitäten;
Legacy- und privater Hexpfad getrennt prüfen. Radar-Reichweite und Luft-Luft-
Grenze sowie Orbit-Durchflugrichtung und Abschaltung gezielt prüfen. Keine
Fixtures als nativen Gesamtspielnachweis ausgeben. Tests in isolierten
Profilen bündeln und auf nötige Regressionen beschränken.

## Betroffene Dateien und Risiken

Insbesondere Air-Methoden in `scripts/core/simulation_root.gd`, bestehende
Registries und Bodenschadenspfade, Flug-/Combat-Owner, Missionscontroller,
Radar-/Orbitresolver und gezielte Verifier. Große gemeinsame Dateien nicht
als Ganzes portieren. Sichtbarkeit, Mehrfachbelegung und Landekollision auf
Legacykarten sowie Persistenz- und Indexvalidierung sind ausdrücklich offen.
