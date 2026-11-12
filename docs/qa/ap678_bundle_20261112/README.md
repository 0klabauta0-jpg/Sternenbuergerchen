# Vorbereiteter AP6/AP7/AP8-Prüfblock

**Noch nicht ausgeführt.** Dieser Ordner enthält Plan und Aufrufhilfe, keine
grüne Gameplayevidenz. Codeblöcke zuerst abschließen und gemeinsam einfrieren.

Plan anzeigen, ohne Godot oder Ergebnisdateien zu starten:

```powershell
python scripts/tests/run_ap678_bundle.py
```

Erst für den später autorisierten gemeinsamen Lauf:

```powershell
python scripts/tests/run_ap678_bundle.py --execute
```

Der Wrapper ruft ausschließlich die im Manifest genannten vorhandenen isolierten
Runner mit aktuellen Workspacequellen auf. Keine `--flow-ref`-Abhängigkeit, keine
historische Gesamtmatrix und keine Hauptszene. Die Fälle laufen nacheinander;
je Fall gilt eine äußere 240-Sekunden-Grenze einschließlich privater Projektkopie
und der bereits enger begrenzten Import-/Scriptprozesse des Kindrunners. Bei
Timeout wird dessen Prozessbaum beendet und kein weiterer Fall gestartet.

Default: nur neuer AP6-Selectionpfad und unmittelbar betroffener BaseV2-Nachbar.
BaseV2 enthält den Preparedverbund; deshalb keine zusätzliche historische
Prepared-Einzelmatrix. Rootcheckpoint und AP8-Netzverbund stehen noch im Manifest
unter `pending`. Sie werden nach dem tatsächlichen API-/Fixturefreeze ergänzt.
Der frühere AP8-Partialpass wird nicht als Ersatz dafür aufgerufen.

Nur mit zusätzlichem ausdrücklichem `--extended` werden bereits früher geprüfte
Missionstart-/Wellen-/Medizin-/FMC-/Visit-/Unboard- und Movement-/Ground-Nachbarn
aufgenommen. Diese Liste ist für spätere konkrete Regressionsanlässe vorbereitet
und gehört nicht zum jetzigen Defaultauftrag. Auch `--extended` allein führt
ohne `--execute` keinen Prozess aus.

## Ergebnisse und Grenzen

Späterer neuer Report: `output/native_glut_maps/ap678_bundle_20261112/<uuid>/report.json`.
Er enthält HEAD, Manifest-/Wrapperhash, Engineversion, genaue Commands,
Originalreportpfade/-hashes, Exitcodes, Laufzeiten, kopierte Originallogs und die
von den Kindrunnern tatsächlich geprüften Quellhashes. Ein Ergebnis gilt nur mit
Exit 0, frischem Kindreport und allen vorgeschriebenen Pass-/Profil-/Canary-/
Quellguards. Enginefehler/Leaks in vollständigen Kindlogs lehnen es zusätzlich
ab. Historische Reports oder fremde Gitpins werden nicht als Parentpass gelesen.

Exitcodes: 0 = alle ausgewählten Checks bestanden und keine pending-Anbindung;
1 = fehlgeschlagen/blockiert; 2 = ausgewählte Checks bestanden, aber weitere
explizite Pflichtanbindungen noch pending. Bei Fehler endet der Block und listet
die nicht gestarteten Fälle. Keine automatische Wiederholung oder Baselinepflege.
Falls ein später ergänzter Spezialrunner feste QA-Dateien überschreibt, müssen
diese im Manifest unter `archive_before` genannt werden; der Wrapper archiviert
sie vor dem Aufruf. Die jetzigen ausgewählten Runner erzeugen UUID-Ergebnisse.

Ein selektiver Pass ist keine vollständige AP7/AP8-, Multiplayer-, Native-,
Performance- oder große Kartenabnahme; entsprechende Reportfelder bleiben false.
Die Tests verwenden echte Owner mit den jeweils dokumentierten kontrollierten
Fixturegrenzen. Keine Animation-/Pfad-/Rundflugbehauptung aus Headlesslogs.

## Vorbereitung geprüft

Nur Python-AST, JSON, Eindeutigkeit und vorhandene Command-/Fixturepfade werden
statisch gelesen. Weder Wrapper noch Godot noch Kindrunner wurden gestartet.
Aktuelle Source-APIs können nach dem Freeze weitere konkrete Pfad-/Fallaufnahme
erfordern; diese wird im Manifest kenntlich ergänzt, nicht still übersprungen.
