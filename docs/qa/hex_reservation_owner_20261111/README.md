# Hexreservierungsowner: begrenzter AP4-Zwischenstand

Basis161d62dff, eigener Taskbranch auf dem noch nicht integrierten nativen
Rampenstand97e00aba1. Keine Mainintegration, keine EXE oder aktivierte Karte.

## Ergebnis und Reproduktion

Godot4.6.2, echte Produktionsquellen in frischen Minimalprojekten und privaten
Profilen. `python scripts/tests/run_hex_tactical_check.py --case CASE` mit:

| Case | Bestanden / fehlgeschlagen |
|---|---:|
| ground |25 /0|
| owner |51 /0|
| reservation_owner |33 /0|
| reservation |26 /0|
| topology |23 /0|
| facing |24 /0|
| consumers |39 /0|

Alle finalen Läufe: Prozess0, Isolationscanary, unveränderte echte Quellen und
unverändertes Originalprofil. Manifest enthält die74 tatsächlich kopierten
Quellen und deren SHA256. Consumer nutzt die echte Windows-Limbo-Erweiterung.
Kein Start der Hauptszene. Normale Terrainfixtures höchstens zwölf Felder;
Cachekapazitätscheck fragt4097 fehlende Koordinaten ab, erzeugt keine große Karte.

Belegt: atomare Zusagen mit unabhängiger Belegungs-/Gegenkanten-/Gruppenprüfung,
begrenzter Horizont, SourcebisHandoff/TargetabHandoff, ganze aktive Kante bisEnde,
gemeinsame logische Feldwechsel, präzise Rampenhöhe, Rootclock/Authority,
Release, Revisionen und wiederholungsfeste Ticks. Kein sichtbarer Actor bewegt.

Rein abgeleiteter Nachbarcache ist auf4096 Einträge begrenzt, revisioniert und
kopiergeschützt. Runtime-Türgates teilen den kanonischen Rampenkern mit dem
unveränderten Authoringdefault. Actual A*, HPA über Clusterportal und Rootguard
akzeptieren die offene Rampenachse, verwerfen Flanke und geschlossene Tür.
Sechs Authoring-/Runtime-Rampenrichtungen und H8-Grenze sind zusätzlich geprüft.

## RED/GREEN und Review

Ownerkern zunächst0/1, dann20/0; Zukunftszulassung/Horizont und Gruppenprüfungen
erweitert. Frischer Review schloss Split-/fehlende neue Gruppen und unerreichbare
Segmentenden:26/3, danach29/0. Gefälschte breite Engstelle:28/2, danach30/0.
Türübersteuerung: Topologie15/1, danach20/0 und zuletzt23/0. Erste HPA-Fixture
verlangte fälschlich Komponentengleichheit über eine Clustergrenze:50/1;
Prüfung auf tatsächlichen HPA-Pfad korrigiert, kein HPA-Produktpatch dafür.

Weiterer Review reproduzierte alte aktive Gruppe nach Seitentüröffnung:31/2,
danach33/0. Gemeinsame Geometrieprüfung verwirft unbrauchbare Gruppen und meldet
hex_corridor_invalidated; sichere Segmente bleiben. Enge frische Nachprüfung
ohne verbleibenden Befund. Reviewer selbst startete keine Engine.

Alle43 AP4-Versuche seit importiertem Planer sind mit Originalreport und Log
in reservation_owner_runs.zip archiviert, einschließlich Fehlversuchen.
Historische AP1–3-Manifeste bleiben unverändert an ihren damaligen Commits.

## Offene Grenzen

Noch lokaler64-Graph des Planers, kein vollständig angebundener persistenter
Korridorcache. Keine allgemeine Deadlockfreiheit. Actorprojektion, echte
Move-Commands, vollständiges Ankunfts-/Abbruchverhalten, Lifecycle und Restore
folgen AP5–8. Bewegungsschussbalance und Gameplay-Geräuschproducer bleiben
offen. Große Karten-, Gefechts-, GPU-, Save-/Netzwerk- und Performanceabnahme
sind ausdrücklich später; keine FPSverbesserung aus diesen Checks ableiten.
