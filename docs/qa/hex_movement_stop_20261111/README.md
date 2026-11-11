# AP5: gemeinsamer Stoppkern, noch kein Actoranschluss

Basis e96672da0. Interne Stopps nehmen transitive Freigabeabhängigkeiten
zusammen zurück; kein Viewwechselhook. Ground hält die exklusiven aktuellen
Hexfelder. Zentrierphase bewegt Darstellung innerhalb des Feldes stetig zur
Mitte und zählt bis Ende als Bewegung. Keine echte Move-/Wunden-/UIanbindung.

## Kleine Prüfung

Godot4.6.2, isolierte Privatprojekte, echte Produktionsquellen:
`python scripts/tests/run_hex_tactical_check.py --case CASE`.

| Case | Bestanden / fehlgeschlagen |
|---|---:|
| movement_stop |34 /0|
| owner |56 /0|
| projection |56 /0|
| reservation_owner |36 /0|
| reservation |26 /0|
| corridor_integration |15 /0|
| topology |23 /0|
| locations |9 /0|

Alle finalen Prozesse0, Canary-/Quell-/Originalprofilguards grün, keine
Script-/Leakfehler. Manifest dokumentiert ausgeführte Quellhashes. Originale
Reports/Logs einschließlich Fehlversuchen in stop_runs.zip. Bewegungsfixtures
höchstens zwölf Felder. Korridorregression nutzt wie ihr Vorpaket nur eine
schematische80/81-Felder-Linie, keine große Szene oder Gefechtslast.

Geprüft: Prä-/Posthandoff-Kolonne mit unabhängiger vierter Route, atomare
Fehlbatchablehnung, stetige Startpose, Wiederholung, erlaubtes/gefälschtes
frühes Resume, Release/IDwiederverwendung und vergangene Quellzelle. Illegale
Rampe wird vor Eintritt gestoppt, Zentrierung läuft im eigenen Feld. Metric-
Revision und vollständige Geometrieauffrischung, auch nach leerem Commit.
Root prüft Authority/Clock und publiziert Cancellationevents. Kleine Zwei-
Root-Probe mit vier Feldern belegt getrennte IDs/Belegung/Ticks, Readwechsel,
lokalen Stop und lokalen Teardown. Sie prüft keine echte Meta-/UI-Navigation.

## RED/GREEN und Review

Fehlender Stop0/1, erster Kern25/0. Terrain-/Metricfälle27/2→29/0;
Rootadapter0/1→56/0. Frischer Review fand leeren Commit als Refreshmaskierung:
29/1→30/0. Alter Weltstart bei verkleinerter Metrik:30/1→31/0, nun intrinsisch.
Float-Ceil driftete bei Dauer10/Stop7 auf vier statt drei Restticks:
31/1→32/0, nun exakte Integerdifferenzen. Enge Nachreviews ohne verbleibende
Befunde. Zwei fehlerhafte neue Phasenpayloads sauber32/2→34/0 abgelehnt;
keine Runtime-Typeerrors. Reviewer führte keine Engine aus und änderte nichts.

## Grenzen

Der Stoppindex wird pro gebündelter Absicht aus aktiven Routen gebaut; kein
SceneTree-/Vollkartenscan. Segmentprofil wird bei Commit/Revisionswechsel
vorberechnet; Renderreads würfeln und entscheiden nichts. Kein gemessenes
CPU-/GPU-/FPSversprechen und keine native Aussage über Bewegungseindruck.

Weiter AP5: echte gebündelte Commands und sichere Producer, Ankunft/Continuation,
Bewegungsschussabzug, Türmutationsguard, Legacy-Avoidance/Spacingausschluss,
View-/Actorprojektion. AP6/7 müssen Lifecycle und Zentrierphase beim Restore
mitführen; private Geometriecaches werden nicht serialisiert. Große Karten,
Save-/Netzwerk-/Gefechts-/Performancetests und Aktivierung bleiben später.
